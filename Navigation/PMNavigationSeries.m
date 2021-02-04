classdef PMNavigationSeries < PMNavigation
    %PMNAVIGATIONSERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Navigations
    end
    
    methods
        function obj = PMNavigationSeries(varargin)
            %PMNAVIGATIONSERIES Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfInputArguments =     length(varargin);
            switch NumberOfInputArguments
                case 0
                case 1
                    obj.Navigations = varargin{1};
            end
        end
        
        function obj = set.Navigations(obj,Value)
            assert(isa(Value, 'PMNavigation'), 'Wrong input format.')
            obj.Navigations =  Value;
        end
        
        function maxRows = getMaxRow(obj)
            maxRows =         arrayfun(@(x) x.getMaxRow, obj.Navigations);
            maxRows =          unique(maxRows);
            assert(length(maxRows) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function maxColumn = getMaxColumn(obj)
            maxColumn =           arrayfun(@(x) x.getMaxColumn, obj.Navigations);
            maxColumn =             unique(maxColumn);
            assert(length(maxColumn) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function maxFrame = getMaxFrame(obj)
            maxFrames =         arrayfun(@(x) x.getMaxFrame, obj.Navigations);
            maxFrame =          sum(maxFrames);
        end
        
        function maxPlane = getMaxPlane(obj)
            maxPlane =         arrayfun(@(x) x.getMaxPlane, obj.Navigations);
            maxPlane =          unique(maxPlane);
            assert(length(maxPlane) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function maxChannel = getMaxChannel(obj)
            maxChannel =         arrayfun(@(x) x.getMaxChannel, obj.Navigations);
            maxChannel =          unique(maxChannel);
            assert(length(maxChannel) == 1, 'Max planes from different Navigation need to be identical.')
        end
        
        function summary = getDimensionSummary(obj)
            summary = arrayfun(@(x) x.getDimensionSummary, obj.Navigations, 'UniformOutput', false);
        end
        
    end
end