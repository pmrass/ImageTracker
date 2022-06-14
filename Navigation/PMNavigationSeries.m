classdef PMNavigationSeries < PMNavigation
    %PMNAVIGATIONSERIES To track position within a 5-D space (row, column, plane, frame, channel);
    %  In addition returns maximum-limits for each dimension;
    
    properties (Access = private)
        Navigations
    end
    
    methods %INITIALIZATION
        
        function obj = PMNavigationSeries(varargin)
            %PMNAVIGATIONSERIES Construct an instance of this class
            %   Takes 0, or 1 arguments:
            % 1: vector of PMNavigation objects:
            % the different objects are "added" together to get limits of the entire series;
            NumberOfInputArguments =     length(varargin);
            switch NumberOfInputArguments
                case 0
                case 1
                    obj.Navigations = varargin{1};
            end
        end
        
        function obj = set.Navigations(obj,Value)
            assert(isvector(Value) && isa(Value, 'PMNavigation'), 'Wrong input format.')
            obj.Navigations =  Value;
        end
        
       
    end
    
    methods % SETTERS
        
        
    end
    
    methods % GETTERS MAX:
        
        function maxRows =          getMaxRow(obj)
            maxRows =         arrayfun(@(x) x.getMaxRow, obj.Navigations);
            maxRows =          unique(maxRows);
            if isempty(maxRows)
               maxRows = 1; 
            end
            assert(length(maxRows) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function maxColumn =        getMaxColumn(obj)
            maxColumn =           arrayfun(@(x) x.getMaxColumn, obj.Navigations);
            maxColumn =             unique(maxColumn);
             if isempty(maxColumn)
               maxColumn = 1; 
            end
            assert(length(maxColumn) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function maxFrame =         getMaxFrame(obj)
            maxFrames =         arrayfun(@(x) x.getMaxFrame, obj.Navigations);
            maxFrame =          sum(maxFrames);
        end
        
        function maxPlane =         getMaxPlane(obj)
            maxPlane =         arrayfun(@(x) x.getMaxPlane, obj.Navigations);
            maxPlane =          unique(maxPlane);
            if isempty(maxPlane)
               maxPlane = 1; 
            end
            assert(length(maxPlane) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function maxChannel =       getMaxChannel(obj)
            maxChannel =         arrayfun(@(x) x.getMaxChannel, obj.Navigations);
            maxChannel =          unique(maxChannel);
            if isempty(maxChannel)
               maxChannel = 1; 
            end
            assert(length(maxChannel) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function summary =          getDimensionSummary(obj)
            summary = arrayfun(@(x) x.getDimensionSummary, obj.Navigations, 'UniformOutput', false);
        end
       
        
        
    end
end