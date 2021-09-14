classdef PMCZIDocument
    %PMCZIDOCUMENT read data from CZI files
    %   retrieve metadata and get a map of image-data within file;
    
    properties
        

    end
    
    properties (Access = private)
        FileName
        
        SegmentList
        SegmentListColumns = {'ID';'OffsetHeader';'OffsetData';'AllocatedSize';'UsedSize'};
        
        FilePointer
        
        MetaData
        ImageMap
    end
    
    methods
        
        function obj = PMCZIDocument(FileName)
            
            fprintf('@Create PMCZIDocument for file %s.\n', FileName)
            
            %PMCZIDOCUMENT Construct an instance of this class
            %   Detailed explanation goes here
            obj.FileName =               FileName;
            obj.SegmentList =            obj.GetSegments;
            obj.MetaData =               obj.CreateMetaData;
            obj.ImageMap =               obj.CreateImageMap;
            
            obj =                       obj.AdjustMetaDataByImageMap;
            
        end
        
        function metaData = getMetaData(obj)
            metaData = obj.MetaData;
        end
        
        function imageMap = getImageMap(obj)
            imageMap = obj.ImageMap;
        end
        
        function string = getMetaDataString(obj)
                string =     obj.SegmentList{cellfun(@(x) contains(x, 'ZISRAWMETADATA'), obj.SegmentList(:,1)),6};
        end
        
        function Summary = getObjectiveSummary(obj)
            
                myString =          obj.getMetaDataString;
                xmlParser =         PMXML(myString);
                objectiveData =     xmlParser.getElementContentsWithTitle('Objectives');
                assert(length(objectiveData) == 1, 'Can parse only single used objective.')
                
                LensNA =                PMXML(objectiveData{1}).getElementContentsWithTitle('LensNA');
                NominalMagnification =  PMXML(objectiveData{1}).getElementContentsWithTitle('NominalMagnification');
                WorkingDistance =       PMXML(objectiveData{1}).getElementContentsWithTitle('WorkingDistance');
                PupilGeometry =         PMXML(objectiveData{1}).getElementContentsWithTitle('PupilGeometry');
                ImmersionRefractiveIndex = PMXML(objectiveData{1}).getElementContentsWithTitle('ImmersionRefractiveIndex');
                Immersion =             PMXML(objectiveData{1}).getElementContentsWithTitle('Immersion');

                 [ AttributeNames, AttributeValues ] = PMXML(objectiveData{1}).getAttributesForElementKey('Objective');

                 assert(length(AttributeNames) == 1, 'Cannot parse multiple inputs')
                 Index = strcmp(AttributeNames{1}, 'Name');

                 ObjectiveName = AttributeValues{1}{Index};

                pos = strfind(myString, ['<Objective Name="', ObjectiveName]);
                if length(pos)== 1
                    NewString = myString(pos:end);
                    Pos = strfind(NewString, 'UniqueName');
                    NewString = NewString(Pos:end);
                    Pos = strfind(NewString , '"');
                    Identifier = NewString(Pos(1) + 1: Pos(2) - 1);
                else
                   Identifier = 'Identifier not found.';
                end

                myObjective = PMObjective(...
                                ObjectiveName, ...
                                Identifier, ...
                                LensNA{1}, ...
                                NominalMagnification{1}, ...
                                WorkingDistance{1}, ...
                                PupilGeometry{1}, ...
                                ImmersionRefractiveIndex{1}, ...
                                Immersion{1} ...
                                );

                                     Summary =          myObjective.getSummary;
                  
     
        end
        
        function string = getImageCaptureSummary(obj)
            
            myString =      getMetaDataString(obj);
            xmlParser =     PMXML(myString);
            ImageData =     xmlParser.getElementContentsWithTitle('Image');
             
            assert(length(ImageData) == 1, 'Cannot process multiple Image fields.')
            ChannelData =   PMXML(ImageData{1}).getElementContentsWithTitle('Channels');
                
            string =        splitlines(ChannelData);
                    
        end
        
        function value = getFileCouldBeAccessed(obj)
            value =         obj.getPointer ~= -1;
        end
        
          function segmentList = GetSegments(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
             obj.FilePointer =            obj.getPointer;
            if obj.FilePointer == -1
                warning('Cannot access file. Segment retrieval interrupted.')
                return
            end

            counter = 0;
            
            while true %% go through one segment after another (until reaching eof);
               
                counter = counter + 1;
                segmentList(counter, 1:5) = obj.getSegmentDescription;
                
                if feof(obj.FilePointer)
                    break
                end
              
                if contains(segmentList{counter, 1}, 'ZISRAWFILE')
                    content = obj.getSegmentHeader;
                   
               elseif contains(segmentList{counter, 1}, 'ZISRAWDIRECTORY')
                   content = obj.getDirectoryEntries;
                     
                elseif contains(segmentList{counter, 1}, 'ZISRAWATTDIR')
                    content = obj.getAttachmentsDirectory;
                     
                elseif contains(segmentList{counter, 1}, 'ZISRAWMETADATA')
                    content = obj.getRawMetaData(segmentList{counter, 2});
                       
                elseif contains(segmentList{counter, 1}, 'ZISRAWSUBBLOCK')
                     content = obj.getImageSubBlock(segmentList{counter, 3});

                elseif contains(segmentList{counter, 1}, 'ZISRAWATTACH')
                    content = obj.getNamedAttachment;
                    
                else 
                    content = 'Content could not be parsed.';
                
                end
                
                  segmentList{counter,6} =    content;
                  clear content
                  fseek(obj.FilePointer, segmentList{counter, 3} + segmentList{counter, 4}, 'bof'); % jump to beginning of next segment;
                

            end
            
            fclose(obj.FilePointer);
            
          end
        

    end
    
    methods (Access = private)
        
        function segement = getSegmentDescription(obj)
               offsetHeaderStart =         ftell(obj.FilePointer);
                ReadSegmentID =             fread(obj.FilePointer, 16, '*char')'; % segment ID, up to 16 characters
                AllocatedSize =             fread(obj.FilePointer, 1, '*uint64');
                UsedSize =                  fread(obj.FilePointer, 1, '*uint64');
                offsetDataStart =           ftell(obj.FilePointer); % get current position; this is at the end of the SegmentHeader;

                segement{1, 1} =    ReadSegmentID;
                segement{1, 2} =    offsetHeaderStart;
                segement{1, 3} =    offsetDataStart;
                segement{1, 4} =    AllocatedSize;
                segement{1, 5} =    UsedSize;
        end
       
        function content = getSegmentHeader(obj)
            content.major =              fread(obj.FilePointer, 1, '*uint32');
            content.minor =              fread(obj.FilePointer, 1, '*uint32');
            fseek(obj.FilePointer, 8, 'cof');
            content.primaryFileGuid =    fread(obj.FilePointer, 2, '*uint64');
            content.fileGuid =           fread(obj.FilePointer, 2, '*uint64');
            content.filePart =           fread(obj.FilePointer, 1, '*uint32');
            content.dirPos =             fread(obj.FilePointer, 1, '*uint64');
            content.mDataPos =           fread(obj.FilePointer, 1, '*uint64');
            fseek(obj.FilePointer, 4, 'cof');
            content.attDirPos  =         fread(obj.FilePointer, 1, '*uint64');
        end
        
        
        %% getDirectoryEntries:
        function content =    getDirectoryEntries(obj)
               content.EntryCount =         fread(obj.FilePointer,1, '*uint32');
                fseek(obj.FilePointer, 124, 'cof');
                for directoryIndex = 1:content.EntryCount
                         content.Entries{directoryIndex,1} =                    obj.ReadDirectoryEntries;
                end
        end
        
            function DirectoryEntry =   ReadDirectoryEntries(obj)

                    DirectoryEntry.SchemaType =             fread(obj.FilePointer, 2, '*char');
                    pixelTypeNumber =                       fread(obj.FilePointer, 1, '*uint32');
                    DirectoryEntry.PixelType =              obj.convertIndexToPixelType(pixelTypeNumber);
                    DirectoryEntry.FilePosition =           fread(obj.FilePointer, 1, '*uint64');
                    DirectoryEntry.FilePart =               fread(obj.FilePointer, 1, '*uint32');

                    compressionNumber =                     fread(obj.FilePointer, 1, '*uint32');
                    DirectoryEntry.Compression =            obj.convertIndexToCompressionType(compressionNumber);
                    DirectoryEntry.PyramidType =            fread(obj.FilePointer, 1, '*uint8');
                   
                    fseek(obj.FilePointer, 5, 'cof');           % skip spare bytes
                    DirectoryEntry.DimensionCount =        fread(obj.FilePointer, 1, '*uint32');
                    
                    
                    DimensionEntryDV1 =         cell(DirectoryEntry.DimensionCount,1);
                     
                    for index = 1 : DirectoryEntry.DimensionCount
                        DimensionEntryDV1{index,1} =   obj.readDirectoryEntry;
                    end
                    
                    DirectoryEntry.DimensionEntries =  DimensionEntryDV1;

            end
            
     
            
                 
        function pixType = convertIndexToPixelType(obj, index)

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
        
        function compType = convertIndexToCompressionType(obj,index)

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
        
        function Entry = readDirectoryEntry(obj)
            Entry.Dimension =               fread(obj.FilePointer, 4, '*char');
            Entry.Start =                   fread(obj.FilePointer, 1, '*uint32');
            Entry.Size =                    fread(obj.FilePointer, 1, '*uint32');
            Entry.StartCoordinate =         fread(obj.FilePointer, 1, '*float32');
            Entry.StoredSize =              fread(obj.FilePointer, 1, '*uint32');

        end
            
        
        
        
        
        %% getAttachmentsDirectory
        function content = getAttachmentsDirectory(obj) 
                     content.EntryCount =         fread(obj.FilePointer,1, '*uint32');
                    fseek(obj.FilePointer, 252, 'cof');
                    for directoryIndex = 1:content.EntryCount
                             content.Entries{directoryIndex,1} =                    obj.ReadAttachmentEntryA1;
                        
                    end
                   
        end
        
        function AttachmentEntry =  ReadAttachmentEntryA1(obj)
            
            AttachmentEntry.SchemaType =                fread(obj.FilePointer, 2, '*char'); %2
            fseek(obj.FilePointer, 10, 'cof');                                                 %10
            AttachmentEntry.FilePosition =              fread(obj.FilePointer, 1, '*uint64'); %8
            AttachmentEntry.FilePart =                  fread(obj.FilePointer, 4, '*int8'); %4
            AttachmentEntry.ContentGuid =               fread(obj.FilePointer, 2, '*uint64'); %16
            AttachmentEntry.ContentFileType =           fread(obj.FilePointer, 8, '*char'); %8
            AttachmentEntry.Name =                      fread(obj.FilePointer, 80, '*char'); %80

        end
        
        %% getRawMetaData
        function content =          getRawMetaData(obj, offsetHeaderStart)
                    size =                      fread(obj.FilePointer, 1, '*uint32');
                    fseek(obj.FilePointer, offsetHeaderStart + 256, 'bof');
                    content =                    fread(obj.FilePointer, size, '*char')';
        end
        
        
        %% getImageSubBlock
        
        function content = getImageSubBlock(obj, offsetDataStart)
            
            content.MetadataSize =          fread(obj.FilePointer, 1, '*uint32');
            content.AttachmentSize =        fread(obj.FilePointer, 1, '*uint32');
            content.DataSize =              fread(obj.FilePointer, 1, '*uint64');
            content.Directory =                 obj.ReadDirectoryEntries;

            %% other content:
            DirectoryEntrySize =                32 + content.Directory.DimensionCount * 20;
            content.OffsetForMetaData =     offsetDataStart + max(256, DirectoryEntrySize + 16);
            content.OffsetForData =         content.OffsetForMetaData + content.MetadataSize;
            content.OffsetForAttachments =  uint64(content.OffsetForMetaData) + uint64(content.MetadataSize) + content.DataSize;

            fseek(obj.FilePointer, content.OffsetForMetaData, 'bof');
            content.MetaData =                  fread(obj.FilePointer, content.MetadataSize, '*char')';

            fseek(obj.FilePointer, content.OffsetForAttachments, 'bof');
            content.Attachment =                  fread(obj.FilePointer, content.AttachmentSize, '*char')';
            
        end
             
        
        %% getNamedAttachment
        function content = getNamedAttachment(obj)
            
            content.DataSize =                          fread(obj.FilePointer, 1, '*uint32'); %4
            fseek(obj.FilePointer, 12, 'cof'); 
            content.AttachmentEntryA1 =                 obj.ReadAttachmentEntryA1;
            fseek(obj.FilePointer, 112, 'cof');      

                if contains(content.AttachmentEntryA1.ContentFileType', 'CZEVL')
                    content.Data = obj.getEventListData;
                    

                elseif contains(content.AttachmentEntryA1.ContentFileType', 'CZTIMS')
                    content.Data =       obj.getTimeStampListData;
                    
                end
            
            
            
        end
        
        function Data = getEventListData(obj)
            Data.Size =                     fread(obj.FilePointer, 1, '*uint32');
            Data.NumberOfEvents =         fread(obj.FilePointer, 1, '*uint32');

             for eventIndex = 1:Data.NumberOfEvents
                Data.Event{eventIndex,1}.Size =               fread(obj.FilePointer, 1, '*uint32');
                Data.Event{eventIndex,1}.Time =               fread(obj.FilePointer, 1, 'double');
                Data.Event{eventIndex,1}.EventType =               fread(obj.FilePointer, 1, '*uint32');
                Data.Event{eventIndex,1}.DescriptionSize =               fread(obj.FilePointer, 1, '*uint32');
                Data.Event{eventIndex,1}.Description =               fread(obj.FilePointer, Data.Event{eventIndex,1}.DescriptionSize, '*char');
             end

        end
         
        function Data = getTimeStampListData(obj)
            Data.Size =                     fread(obj.FilePointer, 1, '*uint32');
            Data.NumberTimeStamps =         fread(obj.FilePointer, 1, '*uint32');

            for timeIndex = 1:Data.NumberTimeStamps
                Data.TimeStamps{timeIndex,1} =               fread(obj.FilePointer, 1, 'double');
            end

            
        end
        
        %% CreateMetaData
        function MetaData =         CreateMetaData(obj)
 
            MetaData.EntireMovie.NumberOfRows=                  obj.getRowMax;
            MetaData.EntireMovie.NumberOfColumns=               obj.getMaxColumn;
            MetaData.EntireMovie.NumberOfPlanes=                obj.getMaxPlane;
            MetaData.EntireMovie.NumberOfTimePoints=            obj.getMaxFrame;
            MetaData.EntireMovie.NumberOfChannels=              obj.getMaxChannel;

            ScalingString =                                    PMXML(obj.getMetaDataString).getElementContentsWithTitle('Scaling' ); 
            DistanceStrings =                                  PMXML(ScalingString{1,1}).getElementContentsWithTitle('Distance' ); 
            Values =                                           cellfun(@(x) str2double(PMXML(x).getElementContentsWithTitle('Value')),  DistanceStrings); 
            MetaData.EntireMovie.VoxelSizeX=                   Values(1); 
            MetaData.EntireMovie.VoxelSizeY=                   Values(2);  
            if length(Values) == 3
                MetaData.EntireMovie.VoxelSizeZ =              Values(3);  
            else
                MetaData.EntireMovie.VoxelSizeZ=               1e-6; 
            end

             MetaData.TimeStamp =               obj.getTimeStampsFromSegmentList;
             MetaData.RelativeTimeStamp =       MetaData.TimeStamp- MetaData.TimeStamp(1);
    
        end
        
        function rowMax = getRowMax(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeY'));
        end
        
        function myImageData = getImageMetaData(obj)
            xmlParser =             PMXML(obj.getMetaDataString);
            imageData =             xmlParser.getElementContentsWithTitle('Image');
            assert(length(imageData) == 1, 'Can parse only single used objective.')
            myImageData =           imageData{1};
        end
        
        function rowMax = getMaxColumn(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeX'));
        end
        
        function rowMax = getMaxPlane(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeZ'));
        end
        
        function rowMax = getMaxFrame(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeT'));
        end
        
        function rowMax = getMaxChannel(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeC'));
        end
        
        
        
        function TimeStamps = getTimeStampsFromSegmentList(obj)
              Attachmenets =         obj.SegmentList(cellfun(@(x) contains(x, 'ZISRAWATTACH'), obj.SegmentList(:,1)),:);
             Entries =              cellfun(@(x) x.AttachmentEntryA1, Attachmenets(:,6),  'UniformOutput', false);
             Row =                  cellfun(@(x) contains(x.ContentFileType', 'CZTIMS'), Entries);
            TimeStamps = cell2mat(Attachmenets{Row, 6}.Data.TimeStamps);
            
        end
        
        %% CreateImageMap
        function ImageMap =     CreateImageMap(obj)
            
            ImageMap(1,:) =      {'ListWithStripOffsets','ListWithStripByteCounts','FilePointer',...
                'ByteOrder','BitsPerSample','Precisision','SamplesPerPixel',...
                'TotcalColumnsOfImage','TotalRowsOfImage',...
                'TargetFrameNumber','TargetPlaneNumber','RowsPerStrip','TargetStartRows','TargetEndRows','TargetChannelIndex'};
       
            ByteOrder =             'ieee-le';
           
            
            
            %{179747,262144,18,'ieee-le',8,'uint8',1,
            %512,512,
            %1,1,512,1,512,1x1 cell}
            
            ImageSegments =        obj.SegmentList(cellfun(@(x) contains(x, 'ZISRAWSUBBLOCK'), obj.SegmentList(:,1)),:);

            NumberOfImages =     size(ImageSegments,1);
            for ImageIndex = 1:NumberOfImages
                
                PixelType =                    ImageSegments{1, 6}.Directory.PixelType;
                Compression =                   ImageSegments{1, 6}.Directory.Compression;
               
                assert(strcmp(Compression, 'Uncompressed'), 'Data format not supported')
               
                switch PixelType
                    case 'Gray8'
                        BitsPerSample =         8;
                        Precision =             'uint8';
                        SamplesPerPixel =       1;
                        
                    otherwise
                        error('Pixel type not supproted')
                end
                
                CurrentImage =                 ImageSegments{ImageIndex,6};
               
                ImageMap{ImageIndex+1,1} =   CurrentImage.OffsetForData;
                ImageMap{ImageIndex+1,2} =   CurrentImage.DataSize;
                
                ImageMap{ImageIndex+1,4} =   ByteOrder;
                ImageMap{ImageIndex+1,5} =   BitsPerSample;
                ImageMap{ImageIndex+1,6} =   Precision;
                ImageMap{ImageIndex+1,7} =   SamplesPerPixel;
                
                DimensionEntries =              CurrentImage.Directory.DimensionEntries;
                DimensionNames =                cellfun(@(x) x.Dimension(1), DimensionEntries, 'UniformOutput', false);

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
        
   
        function pointer = getPointer(obj)
            pointer = fopen(obj.FileName,'r','l');
            
        end
        
        function obj = AdjustMetaDataByImageMap(obj)
            
            myDirectory = PMImageMap(obj.ImageMap);
            MaxPlanes = myDirectory.getMaxPlaneForEachFrame;
            NoFit =  find(MaxPlanes~= obj.getMaxPlane);
           
            if length(NoFit) > 1
                 error('Cannot parse image directory.') % if the last frame is incomplete (only some planes captured) remove last frame; (same thing should be probably done for planes too;
            elseif length(NoFit) == 1 && NoFit == obj.getMaxFrame
                obj.MetaData.EntireMovie.NumberOfTimePoints = obj.getMaxFrame - 1;
                obj.MetaData.RelativeTimeStamp(end,:) = [];
                obj.MetaData.TimeStamp(end,:) = [];
                
                Rows = [false; myDirectory.getRowsForFrame(obj.getMaxFrame)];
                
                obj.ImageMap(Rows, :) = [];
                
            elseif isempty(NoFit)
                
            else
                error('Cannot parse image directory.')
                
                
            end
            
        end
        
        
        
    end
end

