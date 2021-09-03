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
        TrackIDColumn =         1;
        FrameColumn =           2;
        XColumn =               4;
        YColumn =               3;
        ZColumn =               5;
        PixelColmun =           6;
        SegmentationInfo =      7;
        
    end
    
    methods % initialization
        
        function obj = PMMask(varargin)
            %PMMASKQUANTIFICATION Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    obj.CellWithData = varargin{1};
                otherwise
                    error('Wrong input.')
                    
                    
            end
        end
        
      
    end
    
    methods %getters
        
        function obj = showSummary(obj)
            
            fprintf('\n*** This PMMask object contains three-dimensional information about a segmented mask.\n')
            
            obj.getSegmentationInfo.showSummary;
        end
        
        function obj = showTable(obj)
            
            fprintf('%i %6.2f %6.2f %6.2f %6.2f\n', ...
                obj.CellWithData{obj.TrackIDColumn}, ...
                obj.CellWithData{obj.FrameColumn}, ...
                obj.CellWithData{obj.XColumn}, ...
                obj.CellWithData{obj.YColumn}, ...
                obj.CellWithData{obj.ZColumn}...
                );
                
        end
        
          function data = getData(obj)
           data = obj.CellWithData; 
        end
        
        function trackID = getTrackID(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            trackID = obj.CellWithData{obj.TrackIDColumn};
        end
        
        function lastFrame = getFrame(obj)
            if isempty(obj.CellWithData)
                lastFrame = NaN;
            else
                lastFrame = obj.CellWithData{obj.FrameColumn};
            end
        end
        
        function X = getX(obj)
            X = cell2mat(obj.CellWithData(1,4));
        end
        
         function X = getY(obj)
            X = cell2mat(obj.CellWithData(1,3));
         end
        
          function X = getZ(obj)
            X = cell2mat(obj.CellWithData(1,5));
        end
        
        function Centroid = getCentroidYX(obj)
            Centroid = cell2mat(obj.CellWithData(1,3:4));
        end
        
        function ZPositions = getAllUniqueZPositions(obj)
             ZPositions = unique(obj.CellWithData{6}(:,3));  
        end
        
        function info = getSegmentationInfo(obj)
            info = obj.CellWithData{obj.SegmentationInfo};
            info = info.SegmentationType;
        end
        
    end
    
    methods (Access = private)
        
        
    end
end

