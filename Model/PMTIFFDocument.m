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
        function obj =                                                          PMTIFFDocument(FileName)
            
            %% reading from file: get header and image directories: this should be the same for all TIFF-files:
            obj.FileName =                                      FileName;
            obj.FilePointer =                                   fopen(FileName,'r','l');
 
            if obj.FilePointer == -1
                return
            end
            
            obj.Header =                                        GetTIFFHeader(obj);
            obj.ImageFileDirectories =                          GetImageFileDirectories(obj);
            
            
            
            %% get specific TIFF-type and parse specifically for type:
            obj.Type =                                          DetermineTIFFType(obj);
            
            switch obj.Type
                
                case 'LSM'

                    %% extract metadata:
                    obj.MetaData =                                          ExtractLSMMetaData(obj);

                    %% remove thumbnails from image-directories:
                    DimensionX=                                             obj.MetaData.EntireMovie.NumberOfRows;
                    DimensionY=                                             obj.MetaData.EntireMovie.NumberOfColumns;
                    [obj] =                                                 TIFF_KeepOnlySizedImages(obj, DimensionX, DimensionY);

                    %% extract image map:
                    [OrderOfImages] =                                       LSM_ExtractImageOrder(obj );  
                    
                    
                    
                   [CellMapContents, CellMapTitles] =              cellfun(@(dir,x,y) obj.ExtractFieldsForImageReading(dir,x,y), obj.ImageFileDirectories, OrderOfImages(:,1), OrderOfImages(:,2), 'UniformOutput', false);
                   ListWithAllDirectories =                                vertcat(CellMapContents{:});
                    obj.ImageMap=                                       [CellMapTitles{1,1};ListWithAllDirectories];


                case 'OME'
                    
                    
                    
                    
                    ParsedOMEMetaData =                                      ExtractOMESpecificMappingData(obj);
                    
                     obj.MetaData =                                         obj.ExtractMetaDataFromOMEContent(ParsedOMEMetaData);
                     
                     
                    [ OrderOfImages ] =                                        obj.OME_ExtractImageOrder(ParsedOMEMetaData );

                      
                   
                    [CellMapContents, CellMapTitles] =              cellfun(@(dir,x,y,z) obj.ExtractFieldsForImageReading(dir,x,y,z), obj.ImageFileDirectories, OrderOfImages(:,1), OrderOfImages(:,2), OrderOfImages(:,3), 'UniformOutput', false);
                   ListWithAllDirectories =                                vertcat(CellMapContents{:});
                    obj.ImageMap=                                       [CellMapTitles{1,1};ListWithAllDirectories];

                    disp('test')
                    
                otherwise
                    
                    error('TIFF type not supported')
                
                
                
            end
            
            
            
           
            fclose(obj.FilePointer);
            
            
            
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

             if ContainsLSMInfo % first check whether file is an LSM TIFF
                 Type = 'LSM';
                 
             else %then check whether it is an OME file
                 
                 
            %% check whether this is an OME-file (each image description contains OME):

            ContentOfAllImageDescriptionFields =        obj.getAllImageDescriptionFieldContents;
            ContainOMEString =                    cellfun(@(x)  ~isempty(strfind(x, 'OME')), ContentOfAllImageDescriptionFields);

            AllRowsContainOMEString=                                                 min(ContainOMEString)==1;
            if AllRowsContainOMEString
                Type=                                                   'OME';
            else
                error('Unsupported TIFF type')
            end

           
                
             end


        end
        
        function [ContentOfAllImageDescriptionFields] = getAllImageDescriptionFieldContents(obj)
            
             DirectoryList =                  obj.ImageFileDirectories;
            ContentOfAllImageDescriptionFields =  cellfun(@(x) x{cell2mat(x(:,1))==270,4}, DirectoryList, 'UniformOutput', false);
            
        end
        
        function [MetaData] =                    ExtractLSMMetaData(obj)
            
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
                    
                    
                    [MetaData] =                                                   obj.AutoCompleteTimeFrameMetaData(MetaData, ListWithAbsoluteTimeStamps_Sec);

            
            
        end

        %% extract meta-data:
        function [ParsedOMEMetaData] =                                                       ExtractOMESpecificMappingData(obj)

            
            
            %% get first image-description content (contains information for entire file);
                     ContentOfAllImageDescriptionFields =        obj.getAllImageDescriptionFieldContents;
                     ImageDescriptionField_FirstEntry=               ContentOfAllImageDescriptionFields{1,1};

                   
                     %% parse OME-XML field:
                    ElementName =                       'Image';
                    
                    StartTag=                           ['<' ElementName];
                    EndTag=                             ['</' ElementName '>'];

                    StartPositions=                     (strfind(ImageDescriptionField_FirstEntry, StartTag))';
                    EndPositions=                       (strfind(ImageDescriptionField_FirstEntry, EndTag))';

                    ImageElements_EachTimeFrame=       arrayfun(@(start, stop) ImageDescriptionField_FirstEntry(start:stop), StartPositions, EndPositions, 'UniformOutput', false);


    
                    [ name_pixels, value_pixels ] =                                 cellfun(@(x) XML_GetAttributes( x,  'Pixels'), ImageElements_EachTimeFrame, 'UniformOutput', false);
                    [ name_tiff, value_tiff ] =                                     cellfun(@(x) XML_GetAttributes( x,  'TiffData'), ImageElements_EachTimeFrame, 'UniformOutput', false);
                    [ uuid_contents ] =                                             cellfun(@(x) XML_GetElementContents( x, 'UUID' ), ImageElements_EachTimeFrame, 'UniformOutput', false);
                    [AcquisitionDates]=                                             cellfun(@(x) XML_GetElementContents( x, 'AcquisitionDate' ), ImageElements_EachTimeFrame, 'UniformOutput', false);


                    %% extract from time-frame cells:
                    uuid_contents=                                              vertcat(uuid_contents{:});
                    AcquisitionDates=                                           vertcat(AcquisitionDates{:});

                    %% extract from time-frame cells cell (two times)
                    value_tiff=                                                 vertcat(value_tiff{:});
                    name_tiff=                                                  vertcat(name_tiff{:});

                    value_tiff=                                                 vertcat(value_tiff{:});
                    name_tiff=                                                  vertcat(name_tiff{:});

                    name_pixels=                                                vertcat(name_pixels{:});
                    value_pixels=                                               vertcat(value_pixels{:});

                    name_pixels=                                                vertcat(name_pixels{:});
                    value_pixels=                                               vertcat(value_pixels{:});

                    ParsedOMEMetaData.uuid_contents=                            uuid_contents;
                    ParsedOMEMetaData.AcquisitionDates=                         AcquisitionDates;

                    ParsedOMEMetaData.value_tiff=                               value_tiff;
                    ParsedOMEMetaData.name_tiff=                                name_tiff;

                    ParsedOMEMetaData.name_pixels=                              name_pixels;
                    ParsedOMEMetaData.value_pixels=                             value_pixels;


                    

        end
        
        function [MetaData]=        ExtractMetaDataFromOMEContent(obj,ParsedOMEMetaData)
            
            
             %% get meta-data that describe the entire image-sequence:

                    FirstRowForDimensionsName=                                      ParsedOMEMetaData.name_pixels(1,:);
                    FirstRowForDimensionsValues=                                    ParsedOMEMetaData.value_pixels(1,:);

                    ColumnForVoxelSizeX=                                            strcmp(FirstRowForDimensionsName, 'PhysicalSizeX');
                    ColumnForVoxelSizeY=                                            strcmp(FirstRowForDimensionsName, 'PhysicalSizeY');
                    ColumnForVoxelSizeZ=                                            strcmp(FirstRowForDimensionsName, 'PhysicalSizeZ');

                    ColumnForNumberOfChannels=                                      strcmp(FirstRowForDimensionsName, 'SizeC');
                    % ColumnForSizeT=                                               strcmp(FirstRowForDimensionsName, 'SizeT');
                    ColumnForNumberOfColumns=                                       strcmp(FirstRowForDimensionsName, 'SizeX');
                    ColumnForNumberOfRows=                                          strcmp(FirstRowForDimensionsName, 'SizeY');
                    ColumnForSizeZ=                                                 strcmp(FirstRowForDimensionsName, 'SizeZ');

                    VoxelSizeX=                                                     str2double(FirstRowForDimensionsValues{ColumnForVoxelSizeX})/10^6; % convert to m
                    VoxelSizeY=                                                     str2double(FirstRowForDimensionsValues{ColumnForVoxelSizeY})/10^6; % convert to m
                    VoxelSizeZ=                                                     str2double(FirstRowForDimensionsValues{ColumnForVoxelSizeZ})/10^6; % convert to m

                    NumberOfChannels=                                               str2double(FirstRowForDimensionsValues{ColumnForNumberOfChannels});
                    NumberOfPlanes=                                                 str2double(FirstRowForDimensionsValues{ColumnForSizeZ});
                    %NumberOfFrames=                                                FirstRowForDimensionsValues(ColumnForVoxelSizeX);
                    NumberOfRows=                                                   str2double(FirstRowForDimensionsValues{ColumnForNumberOfRows});
                    NumberOfColumns=                                                str2double(FirstRowForDimensionsValues{ColumnForNumberOfColumns});

                    NumberOfFrames=                                                 size(ParsedOMEMetaData.AcquisitionDates,1);


                    %% get timestamps
                    ListWithDates=                                                  ParsedOMEMetaData.AcquisitionDates;

                    ListWithDates_Reformatted=                                      cellfun(@(x) [ x(1:10) ' ' x(12:end)], ListWithDates, 'UniformOutput', false);
                    ListWithAbsoluteTimeStamps_Sec=                                 cell2mat(cellfun(@(x) datenum(x)*3600*24, ListWithDates_Reformatted, 'UniformOutput', false));


                    %% assign results to appropriate meta-data fields:
                    MetaData.EntireMovie.NumberOfRows=                              NumberOfRows; 
                    MetaData.EntireMovie.NumberOfColumns=                           NumberOfColumns; 
                    MetaData.EntireMovie.NumberOfPlanes=                            NumberOfPlanes;
                    MetaData.EntireMovie.NumberOfTimePoints=                        NumberOfFrames;
                    MetaData.EntireMovie.NumberOfChannels=                          NumberOfChannels;

                    MetaData.EntireMovie.VoxelSizeX=                                VoxelSizeX; 
                    MetaData.EntireMovie.VoxelSizeY=                                VoxelSizeY;  
                    MetaData.EntireMovie.VoxelSizeZ=                                VoxelSizeZ; 

                   [MetaData] =                                                   obj.AutoCompleteTimeFrameMetaData(MetaData, ListWithAbsoluteTimeStamps_Sec);

            
            
            
        end
        
        function [MetaData] =       AutoCompleteTimeFrameMetaData(obj, MetaData, ListWithAbsoluteTimeStamps_Sec)
            
            SecondsOfFirstFrame=                                            ListWithAbsoluteTimeStamps_Sec(1,1);
            NumberOfFrames =                                             MetaData.EntireMovie.NumberOfTimePoints;
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

        function [ OrderOfImages ] =                                LSM_ExtractImageOrder(obj )
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
                    
                    
                     
                     

        end
        
        
        function [OrderOfImages] =         OME_ExtractImageOrder(obj, ParsedOMEMetaData)
            
            
            %% check that header and each IFD match:

            MetaDataInternal =                                  obj.MetaData;
            
            
            
            ContentOfAllImageDescriptionFields =        obj.getAllImageDescriptionFieldContents;
            
            
            [ name_ome, value_ome ] =                cellfun(@(x) XML_GetAttributes( x,  'OME'), ContentOfAllImageDescriptionFields, 'UniformOutput', false);
         
             %  [ name_ome, value_ome ] =                cellfun(@(x) XML_GetAttributes( x,  'OME'), ImageDescriptionEntries, 'UniformOutput', false);
         
             
                name_ome=                               vertcat(name_ome{:});
                name_ome=                               vertcat(name_ome{:});
                
                value_ome=                              vertcat(value_ome{:});
                value_ome=                              vertcat(value_ome{:});
             
                ListWithCorrectRows=                    strcmp(name_ome, 'UUID');
                
                ListWithFileNamesInOMEHeader=           ParsedOMEMetaData.uuid_contents;
                ListWithFileNamesInEachIFD=             value_ome(ListWithCorrectRows);
                
                ListWithMatchedFileNames=               [ListWithFileNamesInOMEHeader ListWithFileNamesInEachIFD];
                
                CompareIFDHeaderAndEachIFDFileName= strcmp(ListWithMatchedFileNames(:,1), ListWithMatchedFileNames(:,2));
                
                if min(CompareIFDHeaderAndEachIFDFileName)==0
                    input('Not all filenames of individual IFDs match. Do you want to continue?')
                end

                %% get matrix that specifices where in the images-sequence the read files should be placed:
                NumberOfFrames=                         MetaDataInternal.EntireMovie.NumberOfTimePoints;
                NumberOfPlanes=                         MetaDataInternal.EntireMovie.NumberOfPlanes;
                NumberOfChannels=                       MetaDataInternal.EntireMovie.NumberOfChannels;
                
                % timeframes need to be reconstructed because they are not explictly written down in Prairie-OME;
                ListWithTimeFrames =                    1:NumberOfFrames;
                ListWithTimeFramesForAllIFD =           repmat(ListWithTimeFrames,NumberOfPlanes*NumberOfChannels,1);
                ListWithTimeFramesForAllIFD=            reshape(ListWithTimeFramesForAllIFD, numel(ListWithTimeFramesForAllIFD), 1);
                
                OrderOfImages(:,3)=                     str2double(ParsedOMEMetaData.value_tiff(:,1))+1;   % channel
                OrderOfImages(:,2)=                     str2double(ParsedOMEMetaData.value_tiff(:,3))+1;      % Z;      
                OrderOfImages(:,1)=                     ListWithTimeFramesForAllIFD;
                
            
                OrderOfImages =                         num2cell(OrderOfImages);
            
            
        end
        
        function [CellMapContents, CellMapTitles] =                                 ExtractFieldsForImageReading(obj, CurrentDirectory, FrameNumber, PlaneNumber, varargin)
            
            
            if length(varargin) == 1
                
                ChannelNumber = varargin{1};
                
            end
            
            
                          RowWithPlanarConfiguration=                                 find(cell2mat(CurrentDirectory(:,1))== 284); %'PlanarConfiguration'
                        if isempty(RowWithPlanarConfiguration)
                            PlanarConfiguration=                                    0;
                        else
                            PlanarConfiguration =                                   CurrentDirectory{RowWithPlanarConfiguration,4};
                        end
            
                        %% collect information for reading images
                           % get offsets and sizes of strips:
                        RowWithOffsets=                                                     cell2mat(CurrentDirectory(:,1))== 273; %'StripOffsets'
                        FieldsForImageReading.ListWithStripOffsets(:,1)=                     	CurrentDirectory{RowWithOffsets, 4};

                        RowWithOffsetsByteCounts=                                           cell2mat(CurrentDirectory(:,1))== 279; %'StripByteCounts'
                        FieldsForImageReading.ListWithStripByteCounts(:,1)=                      CurrentDirectory{RowWithOffsetsByteCounts, 4};

                        NumberOfStrips =                                                    length(FieldsForImageReading.ListWithStripOffsets);
                        
                 
                        
                        FieldsForImageReading.FilePointer =                         obj.FilePointer;
                        FieldsForImageReading.ByteOrder =                           obj.Header.byteOrder;
                        
               
                        
                        
                      
            
                        
                        


                        % read bits per sample: (it could become tricky if multiple different bits per sample would be allowed: therefore insist they are all the same).
                        RowWithBitsPerSample=                                       find(cell2mat(CurrentDirectory(:,1))== 258); %'BitsPerSample'
                        assert(~isempty(RowWithBitsPerSample), 'Cannot read this file. Reason: BitsPerSample information missing')
                        BitsPerSample=                                              CurrentDirectory{RowWithBitsPerSample, 4};

                        if length(BitsPerSample)>= 2
                            Identical=                                              unique(BitsPerSample(1:end));
                            assert(length(Identical)== 1, 'Cannot read this file. Reason: All samples must have identical bit number')
                        end

                        FieldsForImageReading.BitsPerSample=                        BitsPerSample(1);
                        


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
                                FieldsForImageReading.Precisision =                  sprintf('uint%i', BitsPerSample(1));

                            case 2
                                FieldsForImageReading.Precisision =                  sprintf('int%i', BitsPerSample(1));

                            case 3

                                if ( FieldsForImageReading.BitsPerSample(1) == 32 )
                                    FieldsForImageReading.Precisision =  'single';

                                else
                                    FieldsForImageReading.Precisision = 'double';
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
                        
                        FieldsForImageReading.SamplesPerPixel =                             SamplesPerPixel;

                        
                        RowOfImageWidth=                                                   cell2mat(CurrentDirectory(:,1))== 256;% 'ImageWidth'); 
                        FieldsForImageReading.TotcalColumnsOfImage=                        CurrentDirectory{RowOfImageWidth,4};                   
                        

                        
                        RowForImageLength=                                                  cell2mat(CurrentDirectory(:,1))== 257; %'ImageLength');
                        TotalRowsOfImage =                                                  CurrentDirectory{RowForImageLength,4};
                        FieldsForImageReading.TotalRowsOfImage=                             TotalRowsOfImage;
                        

                       
                        
                        %% specific information for reading image data
                       
                        %% collect "target information": where in the image do we need to place the read information:
                        FieldsForImageReading.TargetFrameNumber =                           FrameNumber;
                        FieldsForImageReading.TargetPlaneNumber =                           PlaneNumber;
                       
                        RowOfRowsPerStrip=                                                  cell2mat(CurrentDirectory(:,1))== 278; %'RowsPerStrip')
                        if sum(RowOfRowsPerStrip)==0 % if there are no strips, act like the whole image is a single strip;
                            RowsPerStrip=                                                   TotalRowsOfImage;

                        else
                            RowsPerStrip=                                                   CurrentDirectory{RowOfRowsPerStrip,4};

                        end

                         FieldsForImageReading.RowsPerStrip =                          RowsPerStrip;
                         
                        
                       FieldsForImageReading.TargetStartRows(:,1)=                              1:RowsPerStrip:TotalRowsOfImage;
                        
                     
                       FieldsForImageReading.TargetEndRows(:,1)=                               RowsPerStrip:RowsPerStrip:TotalRowsOfImage;
                        
                       
                       
                      
                         switch PlanarConfiguration
                             
                             case 0 
                                FieldsForImageReading.TargetChannelIndex=                       ChannelNumber;
                                
                            case 2
                                assert(SamplesPerPixel == length(FieldsForImageReading.ListWithStripOffsets), 'Cannot read file. Reason: number of strips must be identical to number of samples per pixel')
                                
                                FieldsForImageReading.TargetChannelIndex=                       (num2cell(1:SamplesPerPixel))';
                               % FieldsForImageReading.TargetStartRows=                          repmat(FieldsForImageReading.TargetStartRows,length(FieldsForImageReading.ListWithStripOffsets),1);
                               % FieldsForImageReading.TargetEndRows=                            repmat(FieldsForImageReading.TargetEndRows,length(FieldsForImageReading.ListWithStripOffsets),1);
        
                            otherwise
                                
                                error('Chosen planar-configuration is not supported')
                                
                                   
                         end
                        
                          [CellMapContents] = (struct2cell(FieldsForImageReading))';
                          CellMapTitles =    (fieldnames(FieldsForImageReading))';
                        
                          
                    
            
            
            
        end

        
    end
    
end
    
