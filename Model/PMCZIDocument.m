classdef PMCZIDocument
    %PMCZIDOCUMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FileName
        FilePointer
        SegmentListColumns = {'ID';'OffsetHeader';'OffsetData';'AllocatedSize';'UsedSize'};
        SegmentList
        
        MetaData
        ImageMap
        
    end
    
    methods
        
        function obj = PMCZIDocument(FileName)
            
            fprintf('@Create PMCZIDocument for file %s.\n', FileName)
            
            %PMCZIDOCUMENT Construct an instance of this class
            %   Detailed explanation goes here
             obj.FileName =                                      FileName;
            obj.FilePointer =                                   fopen(FileName,'r','l');
 
            if obj.FilePointer == -1
                return
            end
            
            obj.SegmentList =                                        GetSegments(obj);
            obj.MetaData =                                          obj.CreateMetaData;
            obj.ImageMap =                                          obj.CreateImageMap;
            
        end
        
        function segmentList = GetSegments(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            fID =   obj.FilePointer;
            
            counter = 0;
            

            while true %% go through one segment after another (until reaching eof);
               
                counter = counter + 1;
                
                offsetHeaderStart =         ftell(fID);
                ID =                        fread(fID, 16, '*char')'; % segment ID, up to 16 characters
                AllocatedSize =             fread(fID, 1, '*uint64');
                UsedSize =                  fread(fID, 1, '*uint64');
                offsetDataStart =           ftell(fID); % get current position; this is at the end of the SegmentHeader;
                
                endOfFile =                 feof(fID);
                if endOfFile
                    break
                end
                
               
                
                segmentList{counter,1} =    ID;
                segmentList{counter,2} =    offsetHeaderStart;
                segmentList{counter,3} =    offsetDataStart;
                segmentList{counter,4} =    AllocatedSize;
                segmentList{counter,5} =    UsedSize;
                
              
                  %% read data 
                if strfind(ID, 'ZISRAWFILE')
               
                    content.major =              fread(fID, 1, '*uint32');
                    content.minor =              fread(fID, 1, '*uint32');
                    fseek(fID, 8, 'cof');
                    content.primaryFileGuid =    fread(fID, 2, '*uint64');
                    content.fileGuid =           fread(fID, 2, '*uint64');
                    content.filePart =           fread(fID, 1, '*uint32');
                    content.dirPos =             fread(fID, 1, '*uint64');
                    content.mDataPos =           fread(fID, 1, '*uint64');
                    fseek(fID, 4, 'cof');
                    content.attDirPos  =         fread(fID, 1, '*uint64');

               
               elseif strfind(ID, 'ZISRAWDIRECTORY')
                    
                   content.EntryCount =         fread(fID,1, '*uint32');
                    fseek(fID, 124, 'cof');
                    for directoryIndex = 1:content.EntryCount
                             content.Entries{directoryIndex,1} =                    ReadDirectoryEntry(obj);
                        
                    end
                    
                elseif strfind(ID, 'ZISRAWATTDIR')
                    
                    
                     content.EntryCount =         fread(fID,1, '*uint32');
                    fseek(fID, 252, 'cof');
                    for directoryIndex = 1:content.EntryCount
                             content.Entries{directoryIndex,1} =                    ReadAttachmentEntryA1(obj);
                        
                    end
              
                     
                elseif strfind(ID, 'ZISRAWMETADATA')
                    
                    size =                      fread(fID, 1, '*uint32');
                    fseek(fID, offsetHeaderStart+ 256, 'bof');
                    content =                    fread(fID, size, '*char')';
                    
                elseif strfind(ID, 'ZISRAWSUBBLOCK')
                    
                    
                    content.MetadataSize =          fread(fID, 1, '*uint32');
                    content.AttachmentSize =        fread(fID, 1, '*uint32');
                    content.DataSize =              fread(fID, 1, '*uint64');
                    
                    %% directory entry:
                    DirectoryEntry =                    ReadDirectoryEntry(obj);
                    
                    
                    content.Directory =                 DirectoryEntry;
                    
                    DirectoryEntrySize =                32 + content.Directory.DimensionCount * 20;
                    
                    
                    %% other content:
                    content.OffsetForMetaData =     offsetDataStart + max(256, DirectoryEntrySize + 16);
                    content.OffsetForData =         content.OffsetForMetaData + content.MetadataSize;
                    content.OffsetForAttachments =  uint64(content.OffsetForMetaData) + uint64(content.MetadataSize) + content.DataSize;
                    
                    
                     fseek(fID, content.OffsetForMetaData, 'bof');
                    content.MetaData =                  fread(fID, content.MetadataSize, '*char')';
                    
                      fseek(fID, content.OffsetForAttachments, 'bof');
                    content.Attachment =                  fread(fID, content.AttachmentSize, '*char')';
                    
                    
                elseif strfind(ID, 'ZISRAWATTACH')
                    
                    content.DataSize =                          fread(fID, 1, '*uint32'); %4
                       fseek(fID, 12, 'cof');
                  
                     
                    content.AttachmentEntryA1 =                 ReadAttachmentEntryA1(obj);
                    
                    fseek(fID, 112, 'cof');      
                
                        if strfind(content.AttachmentEntryA1.ContentFileType', 'CZEVL')
                            
                             content.Data.Size =                     fread(fID, 1, '*uint32');
                            content.Data.NumberOfEvents =         fread(fID, 1, '*uint32');
                            
                              for eventIndex = 1:content.Data.NumberOfEvents
                                content.Data.Event{eventIndex,1}.Size =               fread(fID, 1, '*uint32');
                                content.Data.Event{eventIndex,1}.Time =               fread(fID, 1, 'double');
                                content.Data.Event{eventIndex,1}.EventType =               fread(fID, 1, '*uint32');
                                content.Data.Event{eventIndex,1}.DescriptionSize =               fread(fID, 1, '*uint32');
                                content.Data.Event{eventIndex,1}.Description =               fread(fID, content.Data.Event{eventIndex,1}.DescriptionSize, '*char');
                                
                                
                            end
                            
                        elseif strfind(content.AttachmentEntryA1.ContentFileType', 'CZTIMS')
 
                            
                            content.Data.Size =                     fread(fID, 1, '*uint32');
                            content.Data.NumberTimeStamps =         fread(fID, 1, '*uint32');
                            
                            for timeIndex = 1:content.Data.NumberTimeStamps
                                content.Data.TimeStamps{timeIndex,1} =               fread(fID, 1, 'double');
                            
                            end
                            
                        end
                    
                    
                    
                else 
                    content = '';
                
                end
                
                  segmentList{counter,6} =    content;
                     
                  clear content
                
                 fseek(fID, offsetDataStart + AllocatedSize, 'bof'); % jump to beginning of next segment;
                
                
      
                
            end
        end
        
        function AttachmentEntry =  ReadAttachmentEntryA1(obj)
            
             fID =   obj.FilePointer;
            
               AttachmentEntry.SchemaType =                         fread(fID, 2, '*char'); %2
                     fseek(fID, 10, 'cof');                                                 %10
                    AttachmentEntry.FilePosition =                  fread(fID, 1, '*uint64'); %8
                    AttachmentEntry.FilePart =                      fread(fID, 4, '*int8'); %4
                    AttachmentEntry.ContentGuid =               fread(fID, 2, '*uint64'); %16
                    AttachmentEntry.ContentFileType =           fread(fID, 8, '*char'); %8
                    AttachmentEntry.Name =                      fread(fID, 80, '*char'); %80
                   
            
            
            
        end
        
        
        function DirectoryEntry =   ReadDirectoryEntry(obj)
            
                    fID =   obj.FilePointer;
            
                    DirectoryEntry.SchemaType =             fread(fID, 2, '*char');
                    pixelTypeNumber =                       fread(fID, 1, '*uint32');
                    DirectoryEntry.PixelType =             obj.getPixelType(pixelTypeNumber);
                    DirectoryEntry.FilePosition =          fread(fID, 1, '*uint64');
                    DirectoryEntry.FilePart =              fread(fID, 1, '*uint32');

                    compressionNumber =             fread(fID, 1, '*uint32');
                    DirectoryEntry.Compression =           obj.getCompressionType(compressionNumber);
                    DirectoryEntry.PyramidType =           fread(fID, 1, '*uint8');
                   
                    fseek(fID, 5, 'cof');           % skip spare bytes
                    DirectoryEntry.DimensionCount =        fread(fID, 1, '*uint32');
                    
                    
                    DimensionEntryDV1 =         cell(DirectoryEntry.DimensionCount,1);
                     
                    for index = 1 : DirectoryEntry.DimensionCount
                        
                        Entry.Dimension =               fread(fID, 4, '*char');
                        Entry.Start =                   fread(fID, 1, '*uint32');
                        Entry.Size =                    fread(fID, 1, '*uint32');
                        Entry.StartCoordinate =         fread(fID, 1, '*float32');
                        Entry.StoredSize =              fread(fID, 1, '*uint32');
                        
                        DimensionEntryDV1{index,1} =   Entry;
                     
                        
                        
                        
                    end
                    
                    DirectoryEntry.DimensionEntries =  DimensionEntryDV1;
                    
            
            
        end
        
        
        function MetaData =         CreateMetaData(obj)
            

            MetaDataString =        obj.SegmentList{cellfun(@(x) contains(x, 'ZISRAWMETADATA'), obj.SegmentList(:,1)),6};

            
            ElementName =                       'Image';
                    
                    StartTag=                           ['<' ElementName '>'];
                    EndTag=                             ['</' ElementName '>'];

                    StartPositions=                     (strfind(MetaDataString, StartTag))';
                    EndPositions=                       (strfind(MetaDataString, EndTag))';

                    ImageString=      MetaDataString(StartPositions:EndPositions);


 

            MetaData.EntireMovie.NumberOfRows=                              str2double(XML_GetElementContents( ImageString,  'SizeY'));; 
            MetaData.EntireMovie.NumberOfColumns=                           str2double(XML_GetElementContents( ImageString,  'SizeY'));; 
            MetaData.EntireMovie.NumberOfPlanes=                            str2double(XML_GetElementContents( ImageString,  'SizeZ'));; 
            MetaData.EntireMovie.NumberOfTimePoints=                        str2double(XML_GetElementContents( ImageString,  'SizeT'));; 
            MetaData.EntireMovie.NumberOfChannels=                         str2double(XML_GetElementContents( ImageString,  'SizeC'));; 

            
            ScalingString =                                                 XML_GetElementContents(MetaDataString, 'Scaling' ); 
            
            
          
            DistanceStrings =                                               XML_GetElementContents(ScalingString{1,1}, 'Distance' ); 
            
            Values =                                                        cellfun(@(x) str2double(XML_GetElementContents(x, 'Value' )),  DistanceStrings); 
            
            MetaData.EntireMovie.VoxelSizeX=                                Values(1); 
            MetaData.EntireMovie.VoxelSizeY=                                Values(2);  
            
            if length(Values) == 3
                MetaData.EntireMovie.VoxelSizez =                           Values(3);  
            else
                MetaData.EntireMovie.VoxelSizeZ=                                1e-6; 
            end

            
             Attachmenets =        obj.SegmentList(cellfun(@(x) contains(x, 'ZISRAWATTACH'), obj.SegmentList(:,1)),:);
           
             Entries =            cellfun(@(x) x.AttachmentEntryA1, Attachmenets(:,6),  'UniformOutput', false);
             
             
             
             Row = cellfun(@(x) contains(x.ContentFileType', 'CZTIMS'), Entries);
             
             
             
            
             MetaData.TimeStamp =      cell2mat(Attachmenets{Row, 6}.Data.TimeStamps);
             
             MetaData.RelativeTimeStamp =             MetaData.TimeStamp- MetaData.TimeStamp(1);
 
            
           
          
            
           
            
        end
        
        function ImageMap =     CreateImageMap(obj)
            
            ImageMap(1,:) =      {'ListWithStripOffsets','ListWithStripByteCounts','FilePointer',...
                'ByteOrder','BitsPerSample','Precisision','SamplesPerPixel',...
                'TotcalColumnsOfImage','TotalRowsOfImage',...
                'TargetFrameNumber','TargetPlaneNumber','RowsPerStrip','TargetStartRows','TargetEndRows','TargetChannelIndex'};
       
            ByteOrder =             'ieee-le';
            BitsPerSample =         8;
            Precision =             'uint8';
            SamplesPerPixel =       1;
            
            
            %{179747,262144,18,'ieee-le',8,'uint8',1,
            %512,512,
            %1,1,512,1,512,1x1 cell}
            
            ImageSegments =        obj.SegmentList(cellfun(@(x) contains(x, 'ZISRAWSUBBLOCK'), obj.SegmentList(:,1)),:);
            
            
            NumberOfImages =     size(ImageSegments,1);
            for ImageIndex = 1:NumberOfImages
                
                
                PixelType =                    ImageSegments{1, 6}.Directory.PixelType;
                Compression =                   ImageSegments{1, 6}.Directory.Compression;
               
                assert(strcmp(PixelType, 'Gray8') && strcmp(Compression, 'Uncompressed'), 'Data format not supported')
               
                 CurrentImage =                 ImageSegments{ImageIndex,6};
                
                DimensionEntries =              CurrentImage.Directory.DimensionEntries;
                
                DimensionNames =                cellfun(@(x) x.Dimension(1), DimensionEntries, 'UniformOutput', false);
               
                
               
                
                ImageMap{ImageIndex+1,1} =    CurrentImage.OffsetForData;
                ImageMap{ImageIndex+1,2} =   CurrentImage.DataSize;
                
                ImageMap{ImageIndex+1,4} =   ByteOrder;
                ImageMap{ImageIndex+1,5} =   BitsPerSample;
                ImageMap{ImageIndex+1,6} =   Precision;
                ImageMap{ImageIndex+1,7} =   SamplesPerPixel;
                
                
                XDimension =                strcmp(DimensionNames, 'X');
                XDimensionData =            DimensionEntries{XDimension};
                ImageMap{ImageIndex+1,8} =   XDimensionData.Size;
                
                 YDimension =                strcmp(DimensionNames, 'Y');
                YDimensionData =            DimensionEntries{YDimension};
                ImageMap{ImageIndex+1,9} =   YDimensionData.Size;
                
                
                TDimension =            strcmp(DimensionNames, 'T');
                TDimensionData =            DimensionEntries{TDimension};
                 ImageMap{ImageIndex+1,10} =   TDimensionData.Start + 1;
                 
                  ZDimension =            strcmp(DimensionNames, 'Z');
                ZDimensionData =            DimensionEntries{ZDimension};
                 ImageMap{ImageIndex+1,11} =   ZDimensionData.Start + 1;
                 
                 
                  ImageMap{ImageIndex+1,12} =   YDimensionData.Size;
                  
                  ImageMap{ImageIndex+1,13} =   1;
                  
                  ImageMap{ImageIndex+1,14} =   YDimensionData.Size;
            
                    CDimension =            strcmp(DimensionNames, 'C');
                CDimensionData =            DimensionEntries{CDimension};
                 ImageMap{ImageIndex+1,15} =   CDimensionData.Start + 1;
                 
              
                
                
            end
            
            
        end
        
        
        function pixType = getPixelType(obj,index)

            switch index
                case 0
                    pixType = 'Gray8';
                case 1
                    pixType = 'Gray16';
                case 2
                    pixType = 'Gray32Float';
                case 3
                    pixType = 'Bgr24';
                case 4
                    pixType = 'Bgr48';
                case 8
                    pixType = 'Bgr96Float';
                case 9
                    pixType = 'Bgra32';
                case 10
                    pixType = 'Gray64ComplexFloat';
                case 11
                    pixType = 'Bgr192ComplexFloat';
                case 12
                    pixType = 'Gray32';
                case 13
            pixType = 'Gray64';
            end

        end
        
        
        function compType = getCompressionType(obj,index)

            if index >= 1000
                compType = 'System-RAW';
            elseif index >= 100 && index < 999
                compType = 'Camera-RAW';
            else 
                switch index
                    case 0
                        compType = 'Uncompressed';
                    case 1
                        compType = 'JPEG';
                    case 2
                        compType = 'LZW';
                    case 4
                        compType = 'JPEG-XR';
                end

            end

        end

        
    end
end

