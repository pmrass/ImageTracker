classdef PMNavigation 
    %PMNAVIGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
        MaximumRow
        MaximumColumn
        MaximumFrame
        MaximumPlane
        MaximumChannel
    end
    
    properties
        ActiveRows
        ActiveColumns
        ActiveFrames = 1
        ActivePlanes = 1
        ActiveChannels = 1
    end
    
    methods
        function obj = PMNavigation(varargin)
            %PMNAVIGATION Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfInputArguments =    length(varargin);
            switch NumberOfInputArguments
                case 0
                case 5
                    obj.MaximumRow  =       varargin{1};
                    obj.MaximumColumn =     varargin{2};
                    obj.MaximumPlane =      varargin{3};
                    obj.MaximumFrame =      varargin{4};
                    obj.MaximumChannel =    varargin{5};
                    
                otherwise
                    error('Wrong number of input arguments.')
            end
        end
        
        function obj = setMaximumRow(obj, Value)
             obj.MaximumRow =  Value;
        end
        
        function obj = setMaximumColumn(obj, Value)
            obj.MaximumColumn =  Value;
        end
        
        function obj = setMaximumPlane(obj, Value)
            obj.MaximumPlane =  Value;
        end

        function obj = set.MaximumRow(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.MaximumRow =  Value;
        end
        
        function obj = set.MaximumColumn(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.MaximumColumn =  Value;
        end        
        
        function obj = set.MaximumFrame(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.MaximumFrame =  Value;
        end
        
        function obj = set.MaximumPlane(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.MaximumPlane =  Value;
         end
        
        function obj = set.MaximumChannel(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.MaximumChannel =  Value;
        end
        
        function obj = set.ActiveRows(obj,Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input format.')
            obj.ActiveRows =  Value;
        end
        
        function obj = set.ActiveColumns(obj,Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input format.')
            if Value >= 1 && Value <= obj.getMaxFrame
                obj.ActiveColumns =  Value;
            else
                disp('PMNavigation.set.ActiveColumns: Value out of range, no action taken.')
            end
        end
        
        function obj = setActiveFrames(obj, Value)
             obj.ActiveFrames =  Value;
        end
        
     
        
        function obj = set.ActiveFrames(obj,Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input format.')
            if Value >= 1 && Value <= obj.getMaxFrame
                obj.ActiveFrames =  Value;
            else
                error('PMNavigation.set.ActiveFrames: Value out of range, no action taken.')
            end
        end
        
        function obj = setActivePlanes(obj, Value)
            if Value >= 1% && Value <= obj.getMaxPlane
                obj.ActivePlanes =  Value;
            elseif isnan(Value)
                
            else
                error('PMNavigation.set.ActiveColumns: Value out of range, no action taken.')
            end
            
        end
        
        function obj = set.ActivePlanes(obj,Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input format.')
            arrayfun(@(x) assert(mod(x, 1) == 0, 'Wrong input.'),  Value)
              
        
            obj.ActivePlanes =  Value;
        end
        
        function obj = set.ActiveChannels(obj,Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input format.')
            obj.ActiveChannels =  Value;
        end
        
        function maxFrame = getMaxFrame(obj)
           maxFrame =   obj.MaximumFrame;
        end
        
        function maxFrame = getMaxColumn(obj)
           maxFrame =   obj.MaximumColumn;
        end
         
        function maxFrame = getMaxRow(obj)
           maxFrame =   obj.MaximumRow;
        end
        
        function maxFrame = getMaxPlane(obj)
           maxFrame =   obj.MaximumPlane;
        end
        
        function maxFrame = getMaxChannel(obj)
           maxFrame =   obj.MaximumChannel;
        end
        
        function frame = getActiveFrames(obj)
           frame = obj.ActiveFrames; 
        end
        
        function frame = getActivePlanes(obj)
           frame = obj.ActivePlanes; 
        end
        
        function summary = getDimensionSummary(obj)
            summary{1,1} = sprintf('%i rows', obj.getMaxRow);
            summary{2,1} = sprintf('%i columns', obj.getMaxColumn);
            summary{3,1} = sprintf('%i planes', obj.getMaxPlane);
            summary{4,1} = sprintf('%i frames', obj.getMaxFrame);
            summary{5,1} = sprintf('%i channels', obj.getMaxChannel);
        end
  
    end
end

