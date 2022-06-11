classdef PMIntensityTracking 
    %PMINTENSITYTRACKING Measure pixel intensity of tracked cells over time
    
    properties (Access = private)
        MovieTracking
        
        
    end
    
    properties (Access = private)
       Intensities 
    end
    
    properties (Access = private) % DATA RETRIEVAL:
        
        FrameRange = 1 : 15
        
    end
    
    methods
        function obj = PMIntensityTracking(varargin)
            %PMINTENSITYTRACKING Construct an instance of this class
            %   Detailed explanation goes here
           switch length(varargin)
               
               case 1
                   obj.MovieTracking =          varargin{1};
                 
                  
                   obj =                        obj.setIntensities;
                   
               otherwise
                error('Wrong input.')
               
           end
           
           
        end
        
      
    end
    
    methods
        
       
        
        function dataContainers = getTimeSeriesDataContainers(obj)
            % GETTIMESERIES returns a vector of PMDataContainer objects with intensity lists;
            % each container contains a list
            MyIntensities = obj.Intensities;
            
            ToDelete =                  cellfun(@(x) size(x, 1) < max(obj.FrameRange), MyIntensities);
            MyIntensities(ToDelete) =   [];
            
            NumberOfTracks = length(MyIntensities);
              CollectedIntensities = nan(1, NumberOfTracks);
          
            for trackIndex = 1 : NumberOfTracks
                
                CurrentTrack = MyIntensities{trackIndex};
                IntensityList = CurrentTrack(obj.FrameRange, 3);
                
                CollectedIntensities(1 : length(IntensityList), trackIndex) = IntensityList; 
                
            end
            
            dataContainers = arrayfun(@(x) PMDataContainer(CollectedIntensities(x, :)), obj.FrameRange);
            
            
        end
        
        
    end
    
    methods (Access = private)
        
         function obj = setIntensities(obj)
            
            
            TrackIDs = obj.MovieTracking.getTracking.getListWithAllUniqueTrackIDs;
            
            for index = 1 : length(TrackIDs)
                
                currentSegmentation =                   obj.MovieTracking.getTracking.getSegmentationForTrackID(TrackIDs(index));
                obj.Intensities{index, 1} =             obj.getTrackIntensities(currentSegmentation);
                
            end
            
         end
        
        function intensities = getTrackIntensities(obj, currentSegementation)
            
            intensities = zeros(size(currentSegementation, 1), 1);
            
            for timeIndex = 1 : size(currentSegementation, 1)
                
                TrackID = currentSegementation{timeIndex, 1};
                Frame = currentSegementation{timeIndex, 2};

               
                
                Coordinates = currentSegementation{timeIndex, 6};
                
                MyImage = obj.MovieTracking.getLoadedImageVolumes(Frame);
                
                MedianIntensity = median(arrayfun(@(row, column) MyImage(row, column), Coordinates(:,1), Coordinates(:, 2)));
                
                intensities(timeIndex, 1) = TrackID;
                intensities(timeIndex, 2) = Frame;
                intensities(timeIndex, 3) = MedianIntensity;
                
            end
            
        end
        
        
    end
    
    
    
end

