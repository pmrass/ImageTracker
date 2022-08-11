classdef PMCZIDocument
    %PMCZIDOCUMENT read data from CZI files
    %   retrieve metadata and get a map of image-data within file;
    
    
    properties (Access = private)
        FileName
        
        SegmentList
        SegmentListColumns = {'ID';'OffsetHeader';'OffsetData';'AllocatedSize';'UsedSize'};
        
        FilePointer
        
        MetaData
        ImageMap
        
        WantedPosition
    end
    
    methods % INITIALIZE
        
        function obj =          PMCZIDocument(varargin)
            %PMCZIDOCUMENT Construct an instance of this class
            %   takes 1 or 2 arguments:
            % 1: filename
            % 2: index of wanted scene (numerics scalar or empty);
            switch length(varargin)
               
                case 1
                    obj.FileName =          varargin{1};
                    
                case 2
                    obj.FileName =          varargin{1};
                    obj.WantedPosition =    varargin{2};
                
            end
            
            
            obj.SegmentList =       obj.getSegments;
            obj.ImageMap =          obj.getImageMapInternal;
            obj.MetaData =          obj.getMetaDataInternal;
            obj =                   obj.AdjustMetaDataByImageMap;
            
        end
        
        function obj = set.WantedPosition(obj, Value)
            assert(isempty(Value) || (isscalar(Value) && isnumeric(Value) && Value > 0 && mod(Value, 1) == 0), 'Wrong input.')
           obj.WantedPosition = Value; 
        end
        
        
        
    end
    
    methods % GETTERS
        
        function metaData =     getMetaData(obj)
            % GETMETADATA returns meta-data structure;
            metaData = obj.MetaData;
        end
        
        function string =       getMetaDataString(obj)
            % GETMETADATASTRING returns entire meta-data string of the file;
                string =     obj.SegmentList{cellfun(@(x) contains(x, 'ZISRAWMETADATA'), obj.SegmentList(:,1)),6};
        end
        
        function Summary =      getObjectiveSummary(obj)
            % GETOBJECTIVESUMMARY returns summary text describing objective;
            
                myString =                  obj.getMetaDataString;
                xmlParser =                 PMXML(myString);
                objectiveData =             xmlParser.getElementContentsWithTitle('Objectives');
                assert(length(objectiveData) == 1, 'Can parse only single used objective.')
                
                LensNA =                    PMXML(objectiveData{1}).getElementContentsWithTitle('LensNA');
                NominalMagnification =      PMXML(objectiveData{1}).getElementContentsWithTitle('NominalMagnification');
                WorkingDistance =           PMXML(objectiveData{1}).getElementContentsWithTitle('WorkingDistance');
                PupilGeometry =             PMXML(objectiveData{1}).getElementContentsWithTitle('PupilGeometry');
                ImmersionRefractiveIndex =  PMXML(objectiveData{1}).getElementContentsWithTitle('ImmersionRefractiveIndex');
                Immersion =                 PMXML(objectiveData{1}).getElementContentsWithTitle('Immersion');

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
        
        function string =       getImageCaptureSummary(obj)
            % GETIMAGECAPTURESUMMARY returns relevant XML text about image-capture;
            
            myString =      getMetaDataString(obj);
            xmlParser =     PMXML(myString);
            ImageData =     xmlParser.getElementContentsWithTitle('Image');
             
            assert(length(ImageData) == 1, 'Cannot process multiple Image fields.')
            ChannelData =   PMXML(ImageData{1}).getElementContentsWithTitle('Channels');
                
            string =        splitlines(ChannelData);
                    
        end
        
        function value =        getFileCouldBeAccessed(obj)
            value =         obj.getPointer ~= -1;
        end
        
        
    end
    
    methods % GETTERS IMAGE-MAP
        
          function imageMap =     getImageMap(obj, varargin)
            
                switch length(varargin)
                    case 0
                         obj.ImageMap =      obj.getImageMapInternal;
                         
               
                          
                    otherwise
                        error('Wrong input.')

                end


                imageMap = obj.ImageMap;
          end
           
    end
    
    methods % GETTERS DIMENSIONS
        
        function number =       getNumberOfScences(obj)
            % GETNUMBEROFSCENCES returns number of scenes (1 is default);
            DimensionEntries =      obj.getDimensionEntriesFor(obj.getAllImageSegments, 'S');
            if isempty(DimensionEntries)
                number = 1;
            else
                number =                max(cellfun(@(x) x.Start, DimensionEntries))  + 1;
            end

        end

    end
    
    methods (Access = private) % GETTERS DIMENSION
       
        function WantedDimensionEntries =   getAllDimensionEntries(obj, Character)
            
              WantedDimensionEntries = obj.getDimensionEntriesFor(obj.getAllImageSegments, Character);
        end
        
        function WantedDimensionEntries =   getDimensionEntriesFor(obj, ImageSegments, Character)
            AllDimensionEntries =         cellfun(@(x) x.Directory.DimensionEntries, ImageSegments(:, 6), 'UniformOutput', false);
              WantedDimensionEntries =      cellfun(@(x) obj.extractDimensionData(x, Character), AllDimensionEntries, 'UniformOutput', false);
          
              Empty =                       cellfun(@(x) isempty(x), WantedDimensionEntries);
              WantedDimensionEntries(Empty) = [];
            
        end
        
        function XDimensionData =           extractDimensionData(obj, DimensionEntries, Identifier)
                DimensionNames =       cellfun(@(x) x.Dimension(1), DimensionEntries, 'UniformOutput', false);
                Index =                strcmp(DimensionNames, Identifier); 
                if max(Index) == 0
                    XDimensionData = '';
                else
                    XDimensionData =       DimensionEntries{Index};
                end
                
        end
        
        
    end
    
    methods (Access = private) % GETTERS: IMAGE-SEGMENTS;
       
        function ImageSegments =    getAllImageSegments(obj)

          ImageSegments =        obj.SegmentList(cellfun(@(x) contains(x, 'ZISRAWSUBBLOCK'), obj.SegmentList(:,1)),:);


        end

        function ImageSegments =    getImageSegementsOfSelectedScenes(obj)


        ImageSegments =         obj.getAllImageSegments;
        if isempty(obj.WantedPosition)

        else
            SceneDimensionEntries =      obj.getDimensionEntriesFor(ImageSegments, 'S');
            SceneNumbers =              cellfun(@(x) x.Start + 1, SceneDimensionEntries);

            MatchingIndices = SceneNumbers == obj.WantedPosition;
            ImageSegments(~MatchingIndices, :) = [];

        end


        end

    end
    
    methods (Access = private) % GETTERS IMAGE MAP
        
        function ImageMap =         getImageMapInternal(obj)
            % CREATEIMAGEMAP returns image map
            
            ImageMap(1,:) =      {'ListWithStripOffsets','ListWithStripByteCounts','FilePointer',...
                'ByteOrder','BitsPerSample','Precisision','SamplesPerPixel',...
                'TotcalColumnsOfImage','TotalRowsOfImage',...
                'TargetFrameNumber','TargetPlaneNumber','RowsPerStrip','TargetStartRows','TargetEndRows','TargetChannelIndex'};
       
            ByteOrder =             'ieee-le';
           
            
            SelectedImageSegments =         obj.getImageSegementsOfSelectedScenes;
            XDimensionData =            obj.getDimensionEntriesFor(SelectedImageSegments, 'X');
            YDimensionData =            obj.getDimensionEntriesFor(SelectedImageSegments, 'Y');
            ZDimensionData =            obj.getDimensionEntriesFor(SelectedImageSegments, 'Z');
            TDimensionData =            obj.getDimensionEntriesFor(SelectedImageSegments, 'T');
            CDimensionData =            obj.getDimensionEntriesFor(SelectedImageSegments, 'C');
            
            NumberOfImages =     size(SelectedImageSegments,1);
            
            for ImageIndex = 1 : NumberOfImages
                
                CurrentImageStructure =     SelectedImageSegments{ImageIndex,6};
                
                switch CurrentImageStructure.Directory.Compression   
                    case 'Uncompressed'
                        Compression = 'NoCompression';
                    otherwise
                        error('Only uncompressed images supported.')
                    
                end
                
                
                switch CurrentImageStructure.Directory.PixelType
                    case 'Gray8'
                        BitsPerSample =         8;
                        Precision =             'uint8';
                        SamplesPerPixel =       1;
                        
                    otherwise
                        error('Pixel type not supproted')
                end
                
               
               
                ImageMap{ImageIndex + 1, 1} =   CurrentImageStructure.OffsetForData;
                ImageMap{ImageIndex + 1, 2} =   CurrentImageStructure.DataSize;

                ImageMap{ImageIndex + 1, 4} =   ByteOrder;
                ImageMap{ImageIndex + 1, 5} =   BitsPerSample;
                ImageMap{ImageIndex + 1, 6} =   Precision;
                ImageMap{ImageIndex + 1, 7} =   SamplesPerPixel;

                ImageMap{ImageIndex + 1, 8} =   XDimensionData{ImageIndex}.Size;
                ImageMap{ImageIndex + 1, 9} =   YDimensionData{ImageIndex}.Size;
                ImageMap{ImageIndex+1, 10} =    TDimensionData{ImageIndex}.Start + 1;
                ImageMap{ImageIndex+1, 11} =    ZDimensionData{ImageIndex}.Start + 1;
                ImageMap{ImageIndex+1, 12} =    YDimensionData{ImageIndex}.Size;
                ImageMap{ImageIndex+1, 13} =    1;
                ImageMap{ImageIndex+1, 14} =    YDimensionData{ImageIndex}.Size;
                ImageMap{ImageIndex+1, 15} =    CDimensionData{ImageIndex}.Start + 1;
                ImageMap{ImageIndex+1, 16} =    0;
                ImageMap{ImageIndex+1, 17} =    Compression;
                
                
            end
            
            
        end
        
    end
    
    methods (Access = private) % GETTERS METADATA
        
         function MetaData =         getMetaDataInternal(obj)
 
                ImageSegments =        obj.getImageSegementsOfSelectedScenes;

                XDimensionData =        max(cellfun(@(x) x.Size, obj.getDimensionEntriesFor(ImageSegments, 'X')));
                YDimensionData =        max(cellfun(@(x) x.Size, obj.getDimensionEntriesFor(ImageSegments, 'Y')));
                ZDimensionData =        max(cellfun(@(x) x.Start, obj.getDimensionEntriesFor(ImageSegments, 'Z'))) + 1;
                TDimensionData =        max(cellfun(@(x) x.Start, obj.getDimensionEntriesFor(ImageSegments, 'T'))) + 1;
                CDimensionData =        max(cellfun(@(x) x.Start, obj.getDimensionEntriesFor(ImageSegments, 'C'))) + 1;

                MetaData.EntireMovie.NumberOfRows=                  XDimensionData;
                MetaData.EntireMovie.NumberOfColumns=               YDimensionData;
                MetaData.EntireMovie.NumberOfPlanes=                ZDimensionData;
                MetaData.EntireMovie.NumberOfTimePoints=            TDimensionData;
                MetaData.EntireMovie.NumberOfChannels=              CDimensionData;

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
        
         function TimeStamps =      getTimeStampsFromSegmentList(obj)
              Attachmenets =         obj.SegmentList(cellfun(@(x) contains(x, 'ZISRAWATTACH'), obj.SegmentList(:,1)),:);
             Entries =              cellfun(@(x) x.AttachmentEntryA1, Attachmenets(:,6),  'UniformOutput', false);
             Row =                  cellfun(@(x) contains(x.ContentFileType', 'CZTIMS'), Entries);
            TimeStamps = cell2mat(Attachmenets{Row, 6}.Data.TimeStamps);
            
           end
        
    end

    methods (Access = private) % FILE-MANAGEMENT
        
        function pointer = getPointer(obj)
            pointer = fopen(obj.FileName,'r','l');
            
        end

    end
    
    methods (Access = private) % GETTERS SEGMENTS
        
         function segmentList =     getSegments(obj)
            %GETSEGMENTS returns segment-information of czi file
            
            obj.FilePointer =            obj.getPointer;
            if obj.FilePointer == -1
                warning('Cannot access file. Segment retrieval interrupted.')
                return
            end

            counter = 0;
            
            while true %% go through one segment after another (until reaching eof);
               
                counter = counter + 1;
                segmentList(counter, 1 : 5) = obj.getSegmentDescription;
                
                if feof(obj.FilePointer)
                    break
                end
              
                if contains(segmentList{counter, 1}, 'ZISRAWFILE')
                    segmentContent = obj.getSegmentHeader;
                   
               elseif contains(segmentList{counter, 1}, 'ZISRAWDIRECTORY')
                   segmentContent = obj.getDirectoryEntries;
                     
                elseif contains(segmentList{counter, 1}, 'ZISRAWATTDIR')
                    segmentContent = obj.getAttachmentsDirectory;
                     
                elseif contains(segmentList{counter, 1}, 'ZISRAWMETADATA')
                    segmentContent = obj.getRawMetaData(segmentList{counter, 2});
                       
                elseif contains(segmentList{counter, 1}, 'ZISRAWSUBBLOCK')
                     segmentContent = obj.getImageSubBlock(segmentList{counter, 3});

                elseif contains(segmentList{counter, 1}, 'ZISRAWATTACH')
                    segmentContent = obj.getNamedAttachment;
                    
                else 
                    segmentContent = 'Content could not be parsed.';
                
                end
                
                  segmentList{counter,6} =    segmentContent;
                  clear content
                  fseek(obj.FilePointer, segmentList{counter, 3} + segmentList{counter, 4}, 'bof'); % jump to beginning of next segment;
                

            end
            
            fclose(obj.FilePointer);
            
          end
       
         function segement =        getSegmentDescription(obj)
                offsetHeaderStart =         ftell(obj.FilePointer);
                ReadSegmentID =             fread(obj.FilePointer, 16, '*char')'; % segment ID, up to 16 characters
                AllocatedSize =             fread(obj.FilePointer, 1, '*uint64');
                UsedSize =                  fread(obj.FilePointer, 1, '*uint64');
                offsetDataStart =           ftell(obj.FilePointer); % get current position; this is at the end of the SegmentHeader;

                segement{1, 1} =            ReadSegmentID;
                segement{1, 2} =            offsetHeaderStart;
                segement{1, 3} =            offsetDataStart;
                segement{1, 4} =            AllocatedSize;
                segement{1, 5} =            UsedSize;
         end
       
         function content =         getSegmentHeader(obj)
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
        
    end
    
    methods (Access = private) % GETTERS SEGMENTS: DIRECTORY-ENTRIES;
       
        function content =          getDirectoryEntries(obj)
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
                     
        function pixType =          convertIndexToPixelType(obj, index)

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
        
        function compType =         convertIndexToCompressionType(obj,index)

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
        
        function Entry =            readDirectoryEntry(obj)
            Entry.Dimension =               fread(obj.FilePointer, 4, '*char');
            Entry.Start =                   fread(obj.FilePointer, 1, '*uint32');
            Entry.Size =                    fread(obj.FilePointer, 1, '*uint32');
            Entry.StartCoordinate =         fread(obj.FilePointer, 1, '*float32');
            Entry.StoredSize =              fread(obj.FilePointer, 1, '*uint32');

        end
            
        
    end
    
    methods (Access = private) % GETTERS SEGMENTS: ATTACHMENTS-ENTRIES;
        
        function content =              getAttachmentsDirectory(obj) 
                     content.EntryCount =         fread(obj.FilePointer,1, '*uint32');
                    fseek(obj.FilePointer, 252, 'cof');
                    for directoryIndex = 1 : content.EntryCount
                             content.Entries{directoryIndex,1} =                    obj.ReadAttachmentEntryA1;
                        
                    end
                   
        end
        
        function AttachmentEntry =      ReadAttachmentEntryA1(obj)
            
            AttachmentEntry.SchemaType =                fread(obj.FilePointer, 2, '*char'); %2
            fseek(obj.FilePointer, 10, 'cof');                                                 %10
            AttachmentEntry.FilePosition =              fread(obj.FilePointer, 1, '*uint64'); %8
            AttachmentEntry.FilePart =                  fread(obj.FilePointer, 4, '*int8'); %4
            AttachmentEntry.ContentGuid =               fread(obj.FilePointer, 2, '*uint64'); %16
            AttachmentEntry.ContentFileType =           fread(obj.FilePointer, 8, '*char'); %8
            AttachmentEntry.Name =                      fread(obj.FilePointer, 80, '*char'); %80

        end
  
    end
    
    methods (Access = private) % GETTERS SEGMENTS: RAW META-DATA;

        function content =          getRawMetaData(obj, offsetHeaderStart)
                    size =                      fread(obj.FilePointer, 1, '*uint32');
                    fseek(obj.FilePointer, offsetHeaderStart + 256, 'bof');
                    content =                    fread(obj.FilePointer, size, '*char')';
        end
        
        
        
    end
    
    methods (Access = private) % GETTERS SEGMENTS: IMAGE SUB-BLOCK;

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
       
        
    end
    
    methods (Access = private) % GETTERS SEGMENTS: NAME ATTACHEMENT;

        function content =      getNamedAttachment(obj)
            
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
        
        function Data =         getEventListData(obj)
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
         
        function Data =         getTimeStampListData(obj)
            Data.Size =                     fread(obj.FilePointer, 1, '*uint32');
            Data.NumberTimeStamps =         fread(obj.FilePointer, 1, '*uint32');

            for timeIndex = 1:Data.NumberTimeStamps
                Data.TimeStamps{timeIndex,1} =               fread(obj.FilePointer, 1, 'double');
            end

            
        end

    end
    
    methods (Access = private) %% SETTERS: AdjustMetaDataByImageMap
                
        function obj =              AdjustMetaDataByImageMap(obj)
            
            myDirectory =   PMImageMap(obj.ImageMap);
            MaxPlanes =     myDirectory.getMaxPlaneForEachFrame;
            NoFit =         find(MaxPlanes~= obj.getMaxPlaneFromMetaData);
           
            if length(NoFit) > 1
                 error('Cannot parse image directory.') % if the last frame is incomplete (only some planes captured) remove last frame; (same thing should be probably done for planes too;
        
            elseif length(NoFit) == 1 && NoFit == obj.getMaxFrameFromMetaData
                obj.MetaData.EntireMovie.NumberOfTimePoints = obj.getMaxFrameFromMetaData - 1;
                obj.MetaData.RelativeTimeStamp(end,:) = [];
                obj.MetaData.TimeStamp(end,:) = [];
                
                Rows = [false; myDirectory.getRowsForFrame(obj.getMaxFrameFromMetaData)];
                
                obj.ImageMap(Rows, :) = [];
                
            elseif isempty(NoFit)
                
            else
                error('Cannot parse image directory.')
                
                
            end
            
        end
        
        function rowMax =           getMaxRowFromMetaData(obj)
            % GETMAXROWFROMMETADATA return max row;
            % can be tricky when using image with multiple scences because this numbers is for the "entire" image;
            % for images with multiple scences it may be more meaningful to get max row for "individual" ;
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeY'));
        end
        
        function myImageData =      getImageMetaData(obj)
            xmlParser =             PMXML(obj.getMetaDataString);
            imageData =             xmlParser.getElementContentsWithTitle('Image');
            assert(length(imageData) == 1, 'Can parse only single used objective.')
            myImageData =           imageData{1};
        end
        
        function rowMax =           getMaxColumnFromMetaData(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeX'));
        end
        
        function rowMax =           getMaxPlaneFromMetaData(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeZ'));
        end
        
        function rowMax =           getMaxFrameFromMetaData(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeT'));
        end
        
        function rowMax =           getMaxChannelFromMetaData(obj)
            rowMax = str2double(PMXML(obj.getImageMetaData).getElementContentsWithTitle('SizeC'));
        end
     
        
    end
end

