classdef PMMask
    %PMMASKQUANTIFICATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
        CellWithData
        
        %PixelList
        %ActiveChannel
        
        % Centroid
        % Area
        % Length
        
        %PixelIntensities
        %MassDeviationFromCentroid
        
    end
    
    properties (Access = private, Constant)
        TrackIDColumn = 1;
        FrameColumn =                           2;
        
    end
    
    methods
        function obj = PMMask(varargin)
            %PMMASKQUANTIFICATION Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    obj.CellWithData = varargin{1};
                    
                    
            end
        end
        
        function trackID = getTrackID(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            trackID = obj.CellWithData{obj.TrackIDColumn};
        end
        
        function lastFrame = getFrame(obj)
            lastFrame = obj.CellWithData{obj.FrameColumn};
        end
        
        function Centroid = getCentroidYX(obj)
            Centroid = cell2mat(obj.CellWithData(1,3:4));
        end
        
        function ZPositions = getAllUniqueZPositions(obj)
             ZPositions = unique(obj.CellWithData{6}(:,3));  
        end
        
    end
    
    methods (Access = private)
        
        
    end
end

