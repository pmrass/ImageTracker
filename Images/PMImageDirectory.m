classdef PMImageDirectory
    %PMIMAGEDIRECTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        RawData
        ActiveStripIndex
    end
    
    methods
        function obj = PMImageDirectory(varargin)
            %PMIMAGEDIRECTORY Construct an instance of this class
            %   Detailed explanation goes here
           NumberOfArguments = length(varargin);
           switch NumberOfArguments
               case 1
                   obj.RawData = varargin{1};
               otherwise
                   error('Wrong input.')
               
           end
        end
        
        function obj = set.RawData(obj,Value)
            assert(iscell(Value), 'Wrong input.')
            obj.RawData = Value;
        end
        
        function ImageVolume = drawOnImageVolume(obj, ImageVolume)
            for CurrentStripIndex = 1 : obj.getNumberOfStrips
                obj.ActiveStripIndex = CurrentStripIndex;
                ImageVolume(obj.getActiveUpperRow : obj.getActiveBottomRow, ...
                            1:obj.getNumberOfColumns, ...
                            obj.getPlanes, ...
                            obj.getFrames, ...
                            obj.getActiveChannel)=     obj.getImageForStripIndex;
                % fprintf('%i of %i (t:%i,z:%i,c:%i); ', CurrentStripIndex,NumberOfStrips, min(obj.getFrames), min(obj.getPlanes), min(CurrentChannel))
            end 
        end
        
       
                  
        
    end
    
    methods (Access = private)
        
        %% for transferring image
        
        function CurrentUpperRow = getActiveUpperRow(obj)
            ListWithUpperRows=          obj.getTopRowsPerStrip;
             CurrentUpperRow =                   ListWithUpperRows(obj.ActiveStripIndex,1);
        end
        
        function CurrentBottomRow = getActiveBottomRow(obj)
            ListWithLowerRows=          obj.getBottomRowsPerStrip;
             CurrentBottomRow =                  ListWithLowerRows(obj.ActiveStripIndex,1);
        end
        
        function CurrentChannel = getActiveChannel(obj)
            ChannelList =       obj.getChannelsPerStrip;
            CurrentChannel =    ChannelList(obj.ActiveStripIndex,1);
        end
        
        function bytesPerSample = getBytesPerSample(obj)
            bytesPerSample =                    obj.RawData{5}/8; 
        end
        
        function fileID = getFileID(obj)
            fileID =                fopen(obj.RawData{3});
        end
        
        function planes = getPlanes(obj)
            planes =                obj.RawData{11};
        end

        function frame = getFrames(obj)
            frame =                obj.RawData{10};
        end
        
         function precision = getPrecision(obj)
            precision =                obj.RawData{6};
         end
        
        function byteOrder = getByteOrder(obj)
            byteOrder =                obj.RawData{4};
        end

        function columns = getNumberOfColumns(obj)
            columns =                obj.RawData{8};
        end

        function rowPerStrip = getRowsPerStrip(obj)
            rowPerStrip =                obj.RawData{12};
        end
         
        function stripOffsets = getStripOffsets(obj)
            stripOffsets =                obj.RawData{1};
        end
        
         function NumberOfStrips = getNumberOfStrips(obj)
               NumberOfStrips =         size(getStripOffsets(obj),1); 
        end
        
        function byteCounts = getStripByteCounts(obj)
            byteCounts =                obj.RawData{2};
        end
        
        function ListWithUpperRows = getTopRowsPerStrip(obj)
            ListWithUpperRows=        obj.RawData{13};
            if length(ListWithUpperRows) ~= obj.getNumberOfStrips
                ListWithUpperRows(1:obj.getNumberOfStrips,1) = ListWithUpperRows;
            end
        end
        
        function ListWithLowerRows = getBottomRowsPerStrip(obj)
                ListWithLowerRows=                   obj.RawData{14};
                if length(ListWithLowerRows) ~= obj.getNumberOfStrips
                    ListWithLowerRows(1:obj.getNumberOfStrips,1) = ListWithLowerRows;
                end
        end
        
        function ChannelList = getChannelsPerStrip(obj)
            ChannelList =                    obj.RawData{15};
            if length(ChannelList) ~= obj.getNumberOfStrips
                ChannelList(1:obj.getNumberOfStrips,1) =   ChannelList;
            end
        end
        
        
        %% getImageForStripIndex
        function CurrentStripImage = getImageForStripIndex(obj)
            
        
            MyFileId =                  obj.getFileID;
            fseek(MyFileId,  obj.getActiveOffset, -1);
            CurrentStripData =        cast((fread(MyFileId, obj.getActiveStripLength, obj.getPrecision, obj.getByteOrder))', obj.getPrecision);    
            fclose(MyFileId);

            CurrentStripImage=        reshape(CurrentStripData, ...
                                        obj.getNumberOfColumns, ...
                                        obj.getRowsPerStrip, ...
                                        length(obj.getPlanes));                
            CurrentStripImage =         permute (CurrentStripImage, [2 1 3]);  % in image rows should come first, but reshape reads columns first that's why a switch is necessary;  

                        % fprintf('%i of %i (t:%i,z:%i,c:%i); ', CurrentStripIndex,NumberOfStrips, min(obj.getFrames), min(obj.getPlanes), min(CurrentChannel))

                    
        end
        
        function CurrentStripOffset = getActiveOffset(obj)
             ListWithStripOffsets =      obj.getStripOffsets;
            CurrentStripOffset =        ListWithStripOffsets(obj.ActiveStripIndex,1);
            
        end
        
        function CurrentStripByteCount = getActiveByteCount(obj)
               ListWithStripByteCounts=    obj.getStripByteCounts;
            CurrentStripByteCount =     ListWithStripByteCounts(obj.ActiveStripIndex,1);
        end
        
        function CurrentStripLength = getActiveStripLength(obj)
            CurrentStripLength =                obj.getActiveByteCount / obj.getBytesPerSample;
            
        end
        
            
    end
        
        
end


