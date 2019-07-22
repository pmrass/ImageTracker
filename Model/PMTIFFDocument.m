classdef PMTIFFDocument
    

    properties

        FileName
        FilePointer
        Header
        ImageFileDirectories
        Type
        MetaData
        ImageMap
        
    end


    methods
        
        %% initialize
        function TIFFDoc =                                                          PMTIFFDocument(FileName)
            
            %% reading from file
            TIFFDoc.FileName =                                      FileName;
            TIFFDoc.FilePointer =                                   fopen(FileName,'r','l');
 
            if TIFFDoc.FilePointer == -1
                return
            end
            
            TIFFDoc.Header =                                        GetTIFFHeader(TIFFDoc);
            TIFFDoc.ImageFileDirectories =                          GetImageFileDirectories(TIFFDoc);
            
            
            
            %% parsing and refinding read data:
            TIFFDoc.Type =                                          DetermineTIFFType(TIFFDoc);
            TIFFDoc.MetaData =                                      ExtractMetaData(TIFFDoc);
            
             DimensionX=                                            TIFFDoc.MetaData.EntireMovie.NumberOfRows;
             DimensionY=                                            TIFFDoc.MetaData.EntireMovie.NumberOfColumns;
            [TIFFDoc] =                                             TIFF_KeepOnlySizedImages(TIFFDoc, DimensionX, DimensionY);
            
            [CellMapContents, CellMapTitles] =                      LSM_ExtractImageOrder(TIFFDoc );  
            ListWithAllDirectories =                                vertcat(CellMapContents{:});
            
            TIFFDoc.ImageMap=                                       [CellMapTitles{1,1};ListWithAllDirectories];
            
            fclose(TIFFDoc.FilePointer);
            
            
            
        end
        
       
        
        %% get header info:
        function [ Header ] =                                                       GetTIFFHeader( obj )
            
            %GETTIFFHEADER Summary of this function goes here
            %   Detailed explanation goes here

                %% Header Bytes 0 and 1: ---- read byte order: II = little endian, MM = big endian
                byte_order =                                (fread(obj.FilePointer, 2, '*char'))';
                switch byte_order

                    case 'II'
                        byteOrder =                       'ieee-le'; 

                    case 'MM'
                        byteOrder =                       'ieee-be';

                    otherwise
                        error('Invalid byte order')

                end


                %% Header Bytes 2 and 3: ---- must be "42" if TIFF file:
                TIFFVersionNumber =                         fread(obj.FilePointer,1,'uint16', byteOrder);
                assert(TIFFVersionNumber == 42, 'Invalid TIFF version')


                %% Header Bytes 4 to 7: ---- offset of first image file directory (IFD) location:
                offestOfFirstIFD   =                        fread(obj.FilePointer, 1, 'uint32', byteOrder);

                Header.byteOrder=                           byteOrder;
                Header.TIFFVersionNumber=                   TIFFVersionNumber;
                Header.offestOfFirstIFD=                    offestOfFirstIFD;


        end
        
        
        %% get image file directory:
        function [ ListWithIFDs ] =                                                 GetImageFileDirectories(obj)
            %GETIFDDIRECTORIES Summary of this function goes here
            %   Detailed explanation goes here


                 OffsetOfCurrentIFD=                                                    obj.Header.offestOfFirstIFD;
                 byteOrder=                                                             obj.Header.byteOrder;
                 DirectoryIndex=                                                        1;

                while  OffsetOfCurrentIFD ~= 0 % loop while ifd_pos is not 0 (if 0 this indicates that the last IFD of this file has been reached);


                    [ ListWithIFDs_CurrentDirectory ]=                                  IFD_ReadAllEntries(obj,OffsetOfCurrentIFD );

                    NumberOfFieldsInCurrentIFD=                                         size(ListWithIFDs_CurrentDirectory,2);

                    OffsetOfCurrentIFD=                                                 ListWithIFDs_CurrentDirectory{1,end, 1};
                    %ListWithIFDs(DirectoryIndex,1:NumberOfFieldsInCurrentIFD, :)=       ListWithIFDs_CurrentDirectory;

                    ListWithIFDs{DirectoryIndex,1}(1:NumberOfFieldsInCurrentIFD, :)=       ListWithIFDs_CurrentDirectory;
                    
                    DirectoryIndex=                                                     DirectoryIndex+ 1;

                end

            end

        function [ ListWithIFDs_CurrentDirectory ] =                                IFD_ReadAllEntries(obj, OffsetOfCurrentIFD )
                %IFD_READALLENTRIES Summary of this function goes here
                %   Detailed explanation goes here


                 % move in the file to the next IFD

                 byteOrder = obj.Header.byteOrder;

                 fseek(obj.FilePointer, OffsetOfCurrentIFD, -1);
                 numberOfFields =                                                   fread(obj.FilePointer,1,'uint16', byteOrder);

                 FieldOffsets=                                                      ((OffsetOfCurrentIFD+2):12:OffsetOfCurrentIFD+12*(numberOfFields-1)+2)';
                 DirectoryIndex=                                                        1;


                 ListWithIFDs_CurrentDirectory{DirectoryIndex,1, 1}=                numberOfFields;

                 for FieldIndex=1:numberOfFields


                    %% read current IFD Entry:
                    % Each 12-byte IFD entry has the following format:

                    % Bytes 0-1: The Tag that identifies the field.
                    % Bytes 2-3: The field Type.
                    % Bytes 4-7: The number of values, Count of the indicated Type.
                    % Bytes 8-11: The value or the offset of the value.

                    OffSetOfField=                  FieldOffsets(FieldIndex);
                    [ FieldContents] =              ReadIFDField(obj, OffSetOfField );

                    Tag=                            FieldContents.Tag;
                    FieldType=                      FieldContents.FieldType;
                    Count=                          FieldContents.Count;
                    Value=                          FieldContents.Value;
                    OffsetOfFieldValue=             FieldContents.OffsetOfValue;


                    %% collect field-contents ;

                    % move to offset after all fields of current IFD:
                    % this shows offset of next IFD:
                    % if this value is zero, this indicates that the current IFD is the last IFD in this file;

                    ListWithIFDs_CurrentDirectory{DirectoryIndex,FieldIndex+1, 1}=                   Tag;
                    % field offsets are not written into file: they follow from offset and "count" of current IFD;

                    ListWithIFDs_CurrentDirectory{DirectoryIndex,FieldIndex+1, 2}=                   FieldType;

                    ListWithIFDs_CurrentDirectory{DirectoryIndex,FieldIndex+1, 3}=                   Count;
                    ListWithIFDs_CurrentDirectory{DirectoryIndex,FieldIndex+1, 4}=                   Value;
                    ListWithIFDs_CurrentDirectory{DirectoryIndex,FieldIndex+1, 5}=                   OffsetOfFieldValue;

                 end

                OffSetForOffsetOfNextIFD=                                                   OffsetOfCurrentIFD + 12 * numberOfFields + 2;
                fseek(obj.FilePointer, OffSetForOffsetOfNextIFD, -1);
                OffsetOfCurrentIFD =                                                        fread(obj.FilePointer, 1, 'uint32', byteOrder);

                ListWithIFDs_CurrentDirectory{DirectoryIndex,numberOfFields+2, 1}=          OffsetOfCurrentIFD;


        end


        function [ FieldContents ] =                                                ReadIFDField(obj, OffSetOfField )
    %READIFDFIELD read TIFF image file directory:
    %   Detailed explanation goes here


           byteOrder = obj.Header.byteOrder;

            fseek(obj.FilePointer, OffSetOfField, -1);


            %sprintf('offset: %i', OffSetOfField)
            %% Bytes 0-1 of field (tag):
            Tag =                                           fread(obj.FilePointer, 1, 'uint16', byteOrder);

            %% Bytes 2-3 of field (type)
            FieldType =                                     fread(obj.FilePointer, 1, 'uint16', byteOrder);

            %% Bytes 4-7 of field (length/count)
            Count      =                                    fread(obj.FilePointer, 1, 'uint32', byteOrder);



            %% get value and/or offset:
            OffSetForReadingField=                          OffSetOfField+8;
            [ Value, OffsetOfFieldValue] =                  IFD_GetValue( obj, OffSetForReadingField, Tag, FieldType, Count);


            %% collect field-contents ;
            FieldContents.Tag=                              Tag;
            FieldContents.FieldType=                        FieldType;
            FieldContents.Count=                            Count;
            FieldContents.Value=                            Value;
            FieldContents.OffsetOfValue=                    OffsetOfFieldValue;


        end


        function [ Value, OffsetOfFieldValue] =                                     IFD_GetValue( obj, OffSetForReadingField, Tag, FieldType, Count)
    %IFD_GETVALUE Summary of this function goes here
    %   Detailed explanation goes here

                byteOrder = obj.Header.byteOrder;
                fileID = obj.FilePointer;

            switch (FieldType)

                case 1 %byte
                    NumberOfBytes=      1;
                    MatLabType=         'uint8';

                case 2 %ascii string
                    NumberOfBytes=      1;
                    MatLabType=         'uchar';

                case 3 % word
                    NumberOfBytes=      2;
                    MatLabType=         'uint16';

                case 4 %dword/uword
                    NumberOfBytes=      4;
                    MatLabType=         'uint32';

                case 5 % rational
                    NumberOfBytes=      8;
                    MatLabType=         'uint32';

                case 7
                    NumberOfBytes=      1;
                    MatLabType=         'uchar';

                case 11
                    NumberOfBytes=      4;
                    MatLabType=         'float32';

                case 12
                    NumberOfBytes=      8;
                    MatLabType=         'float64';

                otherwise
                    input(['tiff type %i not supported', FieldType])

            end


             %% read bytes 8-11 
             fseek(fileID, OffSetForReadingField, -1);
            if NumberOfBytes * Count <= 4 % if the value "fits" into the field: read value (in this case: offset is not relevant)

                 Value =                        fread(fileID, Count, MatLabType, byteOrder);
                 OffsetOfFieldValue=            NaN;  

            else % if the value does not fit: read two times: first the "value" which acutally represents the offset of the value:
                %read two times: first offset of field, then actual value (at
                %indicated offset)

               %% if the value is larger than 4 bytes
                %% in that case bytes 8 to 11 contain the offset for the value:
                % read and reset offset
                %next field contains an offset:

                OffsetOfFieldValue =                fread(fileID, 1, 'uint32', byteOrder);

                % go to offset position and read value:
                fseek(fileID, OffsetOfFieldValue, -1);


                if Tag == 33629         % metamorph stack plane specifications
                    Value =                         fread(fileID, 6*Count, MatLabType, byteOrder);

                elseif Tag == 34412     %TIF_CZ_LSMINFO
                    TIF.fileID=                     fileID;
                    TIF.BOS=                        byteOrder;  
                    Value =                         readLSMinfo(obj,TIF);

                else

                    if FieldType == 5   % TIFF 'rational' type
                        val =                       fread(fileID, 2*Count, MatLabType, byteOrder);
                        Value=                     [val(1) val(1)];

                    else

                        if ( FieldType == 2 )
                            fseek(fileID, OffsetOfFieldValue, -1);
                            Value =                        fread(fileID, Count, 'uint8', byteOrder);

                        else
                            fseek(fileID, OffsetOfFieldValue, -1);
                            Value =                        fread(fileID, Count, MatLabType, byteOrder);

                        end


                    end

                end

            end

            if ( FieldType == 2 )
                Value =                         char(Value');
            end

        end

        function R =                                                                readLSMinfo(obj,TIF)

        % Read part of the LSM info table version 2
        % this provides only very partial information, since the offset indicate that
        % additional data is stored in the file

        R.MagicNumber          =        sprintf('0x%09X',fread(TIF.fileID, 1, 'uint32', TIF.BOS));

        R.StructureSize        =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);

        R.DimensionX           =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.DimensionY           =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.DimensionZ           =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.DimensionChannels    =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.DimensionTime        =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.IntensityDataType    =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.ThumbnailX           =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.ThumbnailY           =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);


        R.VoxelSizeX           =        fread(TIF.fileID, 1, 'float64', TIF.BOS);
        R.VoxelSizeY           =        fread(TIF.fileID, 1, 'float64', TIF.BOS);
        R.VoxelSizeZ           =        fread(TIF.fileID, 1, 'float64', TIF.BOS);
        R.OriginX              =        fread(TIF.fileID, 1, 'float64', TIF.BOS);
        R.OriginY              =        fread(TIF.fileID, 1, 'float64', TIF.BOS);
        R.OriginZ              =        fread(TIF.fileID, 1, 'float64', TIF.BOS);

        R.ScanType             =        fread(TIF.fileID, 1, 'uint16', TIF.BOS);
        R.SpectralScan         =        fread(TIF.fileID, 1, 'uint16', TIF.BOS);

        R.DataType             =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetVectorOverlay  =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetInputLut       =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetOutputLut      =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetChannelColors  =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);

        R.TimeInterval         =        fread(TIF.fileID, 1, 'float64', TIF.BOS);

        R.OffsetChannelDataTypes =      fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetScanInformatio =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetKsData         =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetTimeStamps     =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetEventList      =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetRoi            =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetBleachRoi      =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);
        R.OffsetNextRecording  =        fread(TIF.fileID, 1, 'uint32', TIF.BOS);

        % There is more information stored in this table, which is skipped here

        %read real acquisition times:
        if ( R.OffsetTimeStamps > 0 )

            status =  fseek(TIF.fileID, R.OffsetTimeStamps, -1);
            if status == -1
                warning('tiffread:TimeStamps', 'Could not locate LSM TimeStamps');
                return;
            end

            StructureSize          = fread(TIF.fileID, 1, 'int32', TIF.BOS);
            NumberTimeStamps       = fread(TIF.fileID, 1, 'int32', TIF.BOS);
            for i=1:NumberTimeStamps
                R.TimeStamp(i,1)     = fread(TIF.fileID, 1, 'float64', TIF.BOS);
            end

            %calculate elapsed time from first acquisition:
            R.TimeOffset = R.TimeStamp - R.TimeStamp(1,1);

        end

        % anything else assigned to S is discarded

        end


        %% check TIFF-type

        function Type = DetermineTIFFType(obj)

            DirectoryList =                  obj.ImageFileDirectories;

             ContainsLSMInfo=                           max(max(cellfun(@(x) x==34412, DirectoryList{1}(:,1))));    %check first IFD for lsm

             if ContainsLSMInfo
                 Type = 'LSM';
             else
                 Type = '';
             end


        end

        %% extract meta-data:
        function [MetaData] =                                                       ExtractMetaData(obj)

            TIFFType = obj.Type;

             switch TIFFType

                case 'LSM'

                    RowWithLSMData=                                             cell2mat(obj.ImageFileDirectories{1,1}(:,1))==34412;
                    LSMFieldData=                                               obj.ImageFileDirectories{1,1}{RowWithLSMData, 4};

                    NumberOfRows=                                                   LSMFieldData.DimensionY;
                    NumberOfColumns=                                                LSMFieldData.DimensionX;
                    NumberOfPlanes=                                                 LSMFieldData.DimensionZ;
                    NumberOfFrames=                                                 LSMFieldData.DimensionTime;
                    NumberOfChannels=                                               LSMFieldData.DimensionChannels;

                    VoxelSizeX=                                                     LSMFieldData.VoxelSizeX;
                    VoxelSizeY=                                                     LSMFieldData.VoxelSizeY;
                    VoxelSizeZ=                                                     LSMFieldData.VoxelSizeZ;

                    % get meta-data for each frame;
                    ListWithAbsoluteTimeStamps_Sec=                                 LSMFieldData.TimeStamp';


                    %% assign results to appropriate meta-data fields:
                    MetaData.EntireMovie.NumberOfRows=                              NumberOfRows; 
                    MetaData.EntireMovie.NumberOfColumns=                           NumberOfColumns; 
                    MetaData.EntireMovie.NumberOfPlanes=                            NumberOfPlanes;
                    MetaData.EntireMovie.NumberOfTimePoints=                        NumberOfFrames;
                    MetaData.EntireMovie.NumberOfChannels=                          NumberOfChannels;

                    MetaData.EntireMovie.VoxelSizeX=                                VoxelSizeX; 
                    MetaData.EntireMovie.VoxelSizeY=                                VoxelSizeY; 
                    MetaData.EntireMovie.VoxelSizeZ=                                VoxelSizeZ;




                 otherwise
                     error('TIFF type is not supported')



             end


              SecondsOfFirstFrame=                                            ListWithAbsoluteTimeStamps_Sec(1,1);
            for FrameIndex=1:NumberOfFrames

                CurrentFrame=                                               ListWithAbsoluteTimeStamps_Sec(FrameIndex);
                MetaData.TimeStamp(FrameIndex,1)=                    CurrentFrame;
                MetaData.RelativeTimeStamp(FrameIndex,1)=           CurrentFrame- SecondsOfFirstFrame;

            end



        end

        
        function [obj] =                                                            TIFF_KeepOnlySizedImages(obj, DimensionX, DimensionY)
            % remove all directories that do not match image-size (presumably ;

            IFD =                                               obj.ImageFileDirectories;
            
            %% remove all IFD rows with size that does match general movie size (thumbnails etc.);
            
            ListWithWidth =                                     cell2mat(cellfun(@(x) x(cell2mat(x(:,1))==256,4), IFD));
            ListWithHeight =                                    cell2mat(cellfun(@(x) x(cell2mat(x(:,1))==257,4), IFD));
           
            
            RowsWithMaximumWidth=                               ListWithWidth==DimensionX;
            RowsWithMaximumColumn=                              ListWithHeight==DimensionY;

            RowAndColumnWidthCorrect=                           min([RowsWithMaximumWidth RowsWithMaximumColumn], [], 2);

            IFD(~RowAndColumnWidthCorrect,:,:)=                 [];
            
            obj.ImageFileDirectories =                          IFD;
            
            
      
           


        end

        function [ CellMapContents, CellMapTitles ] =                                LSM_ExtractImageOrder(obj )
        %LSM_EXTRACTIMAGEORDER Summary of this function goes here
        %   Detailed explanation goes here

                    InternalMetaData  =                     obj.MetaData;
                    ImageFileDirectory =                    obj.ImageFileDirectories;
                    %% the LSM files that I use have the following order:

                    % one Z-plane after another;
                    % then one time plane after another;
                    % the channel information is in one strip per IF:

                    NumberOfImages=                         size(ImageFileDirectory,1);

                    NumberOfPlanes=                         InternalMetaData.EntireMovie.NumberOfPlanes;
                    NumberOfFrames=                         InternalMetaData.EntireMovie.NumberOfTimePoints;
                    NumberOfChannels=                       1; % there may be multiple channels but they are within each IFD and don't count here

                    OrderOfImages=                          nan(NumberOfImages,3);


                    %% get list of planes:
                    ListWithPlanes=                         repmat((1:NumberOfPlanes)',1,NumberOfFrames);
                    ListWithPlanes=                         reshape(ListWithPlanes, numel(ListWithPlanes), 1);

                    %% based on number of planes/frames/channels: get list with time-frames
                    ListWithTimeFrames =                    1:NumberOfFrames;
                    ListWithTimeFramesForAllIFD =           repmat(ListWithTimeFrames,NumberOfPlanes*NumberOfChannels,1);
                    ListWithTimeFramesForAllIFD=            reshape(ListWithTimeFramesForAllIFD, numel(ListWithTimeFramesForAllIFD), 1);


                    %OrderOfImages(:,1)=                     nan;   % channel remains nan (no relevant information here; all channels get filled up for each IFD) ;
                    OrderOfImages(:,2)=                     ListWithPlanes;      % Z;      
                    OrderOfImages(:,1)=                     ListWithTimeFramesForAllIFD;

                    
                    OrderOfImages =                         num2cell(OrderOfImages);
                    
                    
            
                    [CellMapContents, CellMapTitles] =              cellfun(@(x,y,z) ExtractFieldsForImageReading(obj,x,y,z), obj.ImageFileDirectories, OrderOfImages(:,1), OrderOfImages(:,2), 'UniformOutput', false);
                    
                     
                     

        end
        
        function [CellMapContents, CellMapTitles] =                                 ExtractFieldsForImageReading(obj, CurrentDirectory, FrameNumber, PlaneNumber)
            
            
                          RowWithPlanarConfiguration=                                 find(cell2mat(CurrentDirectory(:,1))== 284); %'PlanarConfiguration'
                        if isempty(RowWithPlanarConfiguration)
                            PlanarConfiguration=                                    0;
                        else
                            PlanarConfiguration =                                   CurrentDirectory{RowWithPlanarConfiguration,4};
                        end
            
                        %% collect information for reading images
                           % get offsets and sizes of strips:
                        RowWithOffsets=                                                     cell2mat(CurrentDirectory(:,1))== 273; %'StripOffsets'
                        FieldsForImageReading.ListWithStripOffsets=                     	num2cell(CurrentDirectory{RowWithOffsets, 4});

                        RowWithOffsetsByteCounts=                                           cell2mat(CurrentDirectory(:,1))== 279; %'StripByteCounts'
                        FieldsForImageReading.ListWithStripByteCounts=                      num2cell(CurrentDirectory{RowWithOffsetsByteCounts, 4});

                        NumberOfStrips =                                                    length(FieldsForImageReading.ListWithStripOffsets);
                        
                 
                        
                        FieldsForImageReading.FilePointer =                         (arrayfun(@(x) obj.FilePointer, 1:NumberOfStrips, 'UniformOutput', false))';
                        FieldsForImageReading.ByteOrder =                           (arrayfun(@(x) obj.Header.byteOrder, 1:NumberOfStrips, 'UniformOutput', false))';
                        
               
                        
                        
                      
            
                        
                        


                        % read bits per sample: (it could become tricky if multiple different bits per sample would be allowed: therefore insist they are all the same).
                        RowWithBitsPerSample=                                       find(cell2mat(CurrentDirectory(:,1))== 258); %'BitsPerSample'
                        assert(~isempty(RowWithBitsPerSample), 'Cannot read this file. Reason: BitsPerSample information missing')
                        BitsPerSample=                                              CurrentDirectory{RowWithBitsPerSample, 4};

                        if length(BitsPerSample)>= 2
                            Identical=                                              unique(BitsPerSample(1:end));
                            assert(length(Identical)== 1, 'Cannot read this file. Reason: All samples must have identical bit number')
                        end

                        FieldsForImageReading.BitsPerSample=                        (arrayfun(@(x) BitsPerSample(1), 1:NumberOfStrips, 'UniformOutput', false))';
                        


                        % read SampleFormat of TIFF file
                        RowWithSampleFormat=                                        find(cell2mat(CurrentDirectory(:,1))== 339); %'SampleFormat'
                        if isempty(RowWithSampleFormat)
                            SampleFormat=                                           1;
                        else
                            SampleFormat =                                          CurrentDirectory{RowWithSampleFormat,4};
                        end

                        % read precision:
                        switch( SampleFormat )

                            case 1
                                FieldsForImageReading.Precisision =                 (arrayfun(@(x) sprintf('uint%i', BitsPerSample(1)), 1:NumberOfStrips, 'UniformOutput', false))';

                            case 2
                                FieldsForImageReading.Precisision =                 (arrayfun(@(x) sprintf('int%i', BitsPerSample(1)), 1:NumberOfStrips, 'UniformOutput', false))';

                            case 3

                                if ( FieldsForImageReading.BitsPerSample(1) == 32 )
                                    FieldsForImageReading.Precisision = (arrayfun(@(x) 'single', 1:NumberOfStrips, 'UniformOutput', false))';

                                else
                                    FieldsForImageReading.Precisision = (arrayfun(@(x) 'double', 1:NumberOfStrips, 'UniformOutput', false))';
                                end

                            otherwise
                                error('unsuported TIFF sample format %i', SampleFormat);

                        end

                     

                        %% general information about image-resolution:
                        
                        ListWithSamplesPerPixelRows=                                        find(cell2mat(CurrentDirectory(:,1))== 277);
                        if isempty(ListWithSamplesPerPixelRows)
                            SamplesPerPixel=                          1;
                        else
                            SamplesPerPixel =                         CurrentDirectory{ListWithSamplesPerPixelRows,4};
                        end
                        
                        FieldsForImageReading.SamplesPerPixel =                             (arrayfun(@(x) SamplesPerPixel, 1:NumberOfStrips, 'UniformOutput', false))';

                        
                        RowOfImageWidth=                                                   cell2mat(CurrentDirectory(:,1))== 256;% 'ImageWidth'); 
                        FieldsForImageReading.TotcalColumnsOfImage=                        (arrayfun(@(x) CurrentDirectory{RowOfImageWidth,4}, 1:NumberOfStrips, 'UniformOutput', false))';                   
                        

                        
                        RowForImageLength=                                                  cell2mat(CurrentDirectory(:,1))== 257; %'ImageLength');
                        TotalRowsOfImage =                                                  CurrentDirectory{RowForImageLength,4};
                        FieldsForImageReading.TotalRowsOfImage=                             (arrayfun(@(x) TotalRowsOfImage, 1:NumberOfStrips, 'UniformOutput', false))';
                        

                       
                        
                        %% specific information for reading image data
                       
                        %% collect "target information": where in the image do we need to place the read information:
                        FieldsForImageReading.TargetFrameNumber =                           (arrayfun(@(x) FrameNumber, 1:NumberOfStrips, 'UniformOutput', false))';
                        FieldsForImageReading.TargetPlaneNumber =                           (arrayfun(@(x) PlaneNumber, 1:NumberOfStrips, 'UniformOutput', false))';
                       
                        RowOfRowsPerStrip=                                                  cell2mat(CurrentDirectory(:,1))== 278; %'RowsPerStrip')
                        if sum(RowOfRowsPerStrip)==0 % if there are no strips, act like the whole image is a single strip;
                            RowsPerStrip=                                                   TotalRowsOfImage;

                        else
                            RowsPerStrip=                                                   CurrentDirectory{RowOfRowsPerStrip,4};

                        end

                         FieldsForImageReading.RowsPerStrip =                          (arrayfun(@(x) RowsPerStrip, 1:NumberOfStrips, 'UniformOutput', false))';
                         
                        
                       FieldsForImageReading.TargetStartRows=                              (arrayfun(@(x) 1:RowsPerStrip:TotalRowsOfImage, 1:NumberOfStrips, 'UniformOutput', false))';
                        
                     
                       FieldsForImageReading.TargetEndRows=                               (arrayfun(@(x) RowsPerStrip:RowsPerStrip:TotalRowsOfImage, 1:NumberOfStrips, 'UniformOutput', false))';
                        
                       
                       
                      
                         switch PlanarConfiguration
                            
                            case 2
                                assert(SamplesPerPixel == length(FieldsForImageReading.ListWithStripOffsets), 'Cannot read file. Reason: number of strips must be identical to number of samples per pixel')
                                
                                FieldsForImageReading.TargetChannelIndex=                       (num2cell(1:SamplesPerPixel))';
                               % FieldsForImageReading.TargetStartRows=                          repmat(FieldsForImageReading.TargetStartRows,length(FieldsForImageReading.ListWithStripOffsets),1);
                               % FieldsForImageReading.TargetEndRows=                            repmat(FieldsForImageReading.TargetEndRows,length(FieldsForImageReading.ListWithStripOffsets),1);
        
                            otherwise
                                
                                error('Chosen planar-configuration is not supported')
                                
                                   
                         end
                        
                          [Cell] = (struct2cell(FieldsForImageReading))';
                          CellMapTitles =    (fieldnames(FieldsForImageReading))';
                        
                        %  this is not elegant: need to change at some point:
                        NumberOfColumns =   size(Cell,2);
                        CellMapContents = cell(0,NumberOfColumns);
                        
                        for CurrentColumn = 1:NumberOfColumns
                            CellMapContents(1:size(Cell{1,CurrentColumn},1),CurrentColumn) =      Cell{1,CurrentColumn};
                        end
                        
                        
                       
                        a =      cellfun(@(x) squeeze(x), Cell, 'UniformOutput' , false);
                       
                        
                     %   FieldsForImageReading.PlanarConfiguration =                             PlanarConfiguration;
                       
            
            
            
        end

        
    end
    
end
    
