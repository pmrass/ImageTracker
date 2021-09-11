classdef PMCellInteractionAnalysisProcessing
    %PMCELLINTERACTIONANALYSISPROCESSING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
        MovieTrackingFolder
        MovieNickNames
        RawMovieTrackingData            % these are the original tracking movie data; this is mostly for time-stamps and voxel sizes; the actual tracking data come mostly from the pre-procssed TrackingInteraction data;

        % settings:
        DistanceLimitForContact_um =    2; %5 is normal value;
        MinimumContactDuration_sec =    10; % minimum contact duration can be set manually but is actully related to frame rates; for example if a frame is captured every 40 seconds, and a cell is interacting at only one frame the duration could be between "instant" to 40 seconds;
        LowSpeedRange =                 [0 2];
        HighSpeedRange =                [5 20];
        
        % data:
        BinsForObjectDistancesFromTarget
        BinsForObjectEccentricity
        BinsForObjectSpeeds

        % contact data:
        
        %%
        % column 1: movie nickname
        % column 2: track ID
        % column 3: first frame
        % column 4: distance between cell at beginning and flu
        % column 5: closest flu coordinate (µm)
        % column 6: speed (µm/min)
        % column 7: net movement towards flu (µm)
        % column 8: eccentricity of cell (first frame)
        % column 9: needs to be added: cell position coordinates in µm
    
        SourceTrackNumbers
        FrameNumbers
        DistancesFromTarget                       
        ClosestTargetPositions        
        ObjectSpeeds          
        MovementsTowardsTarget    
        Eccentricities 
        
        ListsWithRowIndicesOfUniqueTracks

        ListOfForeGroundPixels % currently not used %needs to be used in a movie-specific manner;;
        
        

    end
    
    methods
        function obj = PMCellInteractionAnalysisProcessing(varargin)
            %PMCELLINTERACTIONANALYSISPROCESSING Construct an instance of this class
            %   Detailed explanation goes here
            
                obj.MovieTrackingFolder =                    varargin{2};
            
                
                % interaction tracking data is a modification of regular MovieTracking;
                % it is created by another function based on "raw tracks" and thresholded images;
                InteractionTrackingData =                   varargin{1};
            
              
                obj.SourceTrackNumbers =                    cellfun(@(x) cell2mat(x.AllTrackDataPooled(:,2)), InteractionTrackingData, 'UniformOutput', false);
                obj.FrameNumbers =                          cellfun(@(x) cell2mat(x.AllTrackDataPooled(:,3)), InteractionTrackingData, 'UniformOutput', false);
                obj.DistancesFromTarget =                   cellfun(@(x) cell2mat(x.AllTrackDataPooled(:,4)), InteractionTrackingData, 'UniformOutput', false);
                obj.ClosestTargetPositions  =               cellfun(@(x) x.AllTrackDataPooled(:,5), InteractionTrackingData, 'UniformOutput', false);
                obj.ObjectSpeeds =                          cellfun(@(x) cell2mat(x.AllTrackDataPooled(:,6)), InteractionTrackingData, 'UniformOutput', false);
                obj.MovementsTowardsTarget =                cellfun(@(x) cell2mat(x.AllTrackDataPooled(:,7)), InteractionTrackingData, 'UniformOutput', false);
                obj.Eccentricities =                        cellfun(@(x) cell2mat(x.AllTrackDataPooled(:,8)), InteractionTrackingData, 'UniformOutput', false);
            
                  
                RawMovieNickNames =                         cellfun(@(x) unique(x.AllTrackDataPooled(:,1)), InteractionTrackingData, 'UniformOutput', false);
                
                NumberOfNickNames =                         cellfun(@(x) size(x,1),RawMovieNickNames);
                NumberOfNickNames = unique(NumberOfNickNames);
                assert(NumberOfNickNames==1, 'Some interaction tracking data contain data from different movies. This is not supported.')
                
                obj.MovieNickNames =                        cellfun(@(x) x{1},  RawMovieNickNames, 'UniformOutput', false);              
                
                % default settings for bins:
                      obj =                                       obj.setTrackRows;
                
                obj =                                       obj.setMovieTracking;
                
        end
        
        function obj = setMovieTracking(obj)
            %METHOD1 get movie and original track info;
            %  this is mostly for getting meta-data (time stamps and space calibration);
                
                global InternalMovieTrackingCell
               
                if isempty(InternalMovieTrackingCell)
                    InternalMovieTrackingCell =                                                         cellfun(@(x) PMMovieTracking(x,{'',obj.MovieTrackingFolder},1), obj.MovieNickNames,'UniformOutput', false);
                end

                obj.RawMovieTrackingData =                                                              InternalMovieTrackingCell;     
        end
        
        function obj = setTrackRows(obj)
            
            
            TrackIDForEachMovie = obj.SourceTrackNumbers;
            NumberOfMovies =    size(TrackIDForEachMovie,1);
            for MovieIndex = 1:NumberOfMovies
                
                AllTrackIdsOfCurrentMovie =     TrackIDForEachMovie{MovieIndex,1};
                
                
                  DifferentTracks =               unique(AllTrackIdsOfCurrentMovie);

                Number =                        size(DifferentTracks,1);

                

                for TrackIndex = 1:Number

                    TrackID =                   DifferentTracks(TrackIndex,1); 
                    Rows =                      AllTrackIdsOfCurrentMovie == TrackID;

                   
                    obj.ListsWithRowIndicesOfUniqueTracks{MovieIndex,1}{TrackIndex,1} = Rows;

                end
                
                
            end
            
            
           
            
            
            
        end
      
        
        
        %% get contact durations:
        
        function VoxelSizeX = getXVoxelSize(obj)
            
            
            MovieTrackingCell =                                                             obj.RawMovieTrackingData;
            VoxelSizeX =                                                                    unique(cell2mat(cellfun(@(x) x.MetaData.EntireMovie.VoxelSizeX, MovieTrackingCell, 'UniformOutput', false)));
            assert(length(VoxelSizeX) == 1 ,  'All pixel sizes need to be the same')

            
            
        end
        
          function VoxelSizeY = getYVoxelSize(obj)
            
                MovieTrackingCell = obj.RawMovieTrackingData;
                VoxelSizeY =                                                                unique(cell2mat(cellfun(@(x) x.MetaData.EntireMovie.VoxelSizeY, MovieTrackingCell, 'UniformOutput', false)));
                assert(length(VoxelSizeY) == 1 ,  'All pixel sizes need to be the same')

            
          end
        
         function VoxelSizeZ = getZVoxelSize(obj)
            
            MovieTrackingCell = obj.RawMovieTrackingData;
            VoxelSizeZ =                                                                unique(cell2mat(cellfun(@(x) x.MetaData.EntireMovie.VoxelSizeZ, MovieTrackingCell, 'UniformOutput', false)));
            assert(length(VoxelSizeZ) == 1,  'All pixel sizes need to be the same')

            
        end
        
        
        function TimeStamps = getTimeStampsForEachMovie(obj)
            
            MovieTrackingCell = obj.RawMovieTrackingData;
            TimeStamps =                                                                cellfun(@(x) x.MetaData.RelativeTimeStamps, MovieTrackingCell, 'UniformOutput', false);

            
            
        end
        
        
      
        
        function [movementTowardsFlu]= getMovementTowardsTargetInDistanceBins(obj)
            
            
            
            
            movementTowardsFlu =                      PMXVsYDataContainer(vertcat(obj.DistancesFromTarget{:}), vertcat(obj.MovementsTowardsTarget{:}), obj.BinsForObjectDistancesFromTarget);
            movementTowardsFlu.XParameter =           'Shortest distance between object and target (µm)';
            movementTowardsFlu.YParameter =           'Movement towards target';
            
                
            
        end
        

        function [speedPerShape]= getSpeedInShapeBins(obj)
            
            speedPerShape =                      PMXVsYDataContainer(vertcat(obj.Eccentricities{:}), vertcat(obj.ObjectSpeeds{:}), obj.BinsForObjectEccentricity);
            speedPerShape.XParameter =           'Eccentriciy';
            speedPerShape.YParameter =           'Speed (µm/min)';

        end
        
        
        function [shapePerSpeed]= getShapeInSpeedBins(obj)
           
            shapePerSpeed =                      PMXVsYDataContainer(vertcat(obj.ObjectSpeeds{:}), vertcat(obj.Eccentricities{:}), obj.BinsForObjectSpeeds);
            shapePerSpeed.XParameter =           'Speed (µm/min)';
            shapePerSpeed.YParameter =           'Eccentricity';

        end
        
        
        function [shapePerDistance] = getShapeInDistanceBins(obj)
            
            
            SelectedSpeeds =        vertcat(obj.DistancesFromTarget{:});
            SelectedShapes =             vertcat(obj.Eccentricities{:});
            MyBins =                obj.BinsForObjectDistancesFromTarget;
            
             shapePerDistance =                      PMXVsYDataContainer(SelectedSpeeds,SelectedShapes, MyBins);
            shapePerDistance.XParameter =            'Shortest distance between object and target (µm)';
            shapePerDistance.YParameter =           'Eccentricity';
            
            
          
            
        end
          
 
        function shapePerDistance_Slow = getShapeInDistanceBinsForSlowObjects(obj)
            
            %% prefilter:
            AllSpeeds =                                 vertcat(obj.ObjectSpeeds{:});
            AllShapes =                                 vertcat(obj.Eccentricities{:});
            
            SpeedLimit =                                obj.LowSpeedRange;
            OkRows  =                                   min([AllSpeeds>=SpeedLimit(1)  AllSpeeds<SpeedLimit(2)], [], 2);
            
            %% get source data for XY-container:
            SelectedSpeeds =                            AllSpeeds(OkRows);
            SelectedShapes =                            AllShapes(OkRows);
            MyBins =                                    obj.BinsForObjectDistancesFromTarget;
            
            %% create XY object:
            shapePerDistance_Slow =                      PMXVsYDataContainer(SelectedSpeeds,SelectedShapes, MyBins);
            shapePerDistance_Slow.XParameter =            'Shortest distance between object and target (µm)';
            shapePerDistance_Slow.YParameter =           'Eccentricity';
            
        end
        
        
          function shapePerDistance_Fast = getShapeInDistanceBinsForFastObjects(obj)

              %% prefilter:
                AllSpeeds =                                 vertcat(obj.ObjectSpeeds{:});
                AllShapes =                                 vertcat(obj.Eccentricities{:});

                SpeedLimit =                                obj.HighSpeedRange;

                OkRows  =                                   min([AllSpeeds>=SpeedLimit(1)  AllSpeeds<SpeedLimit(2)], [], 2);

                 %% get source data for XY-container:
                SelectedSpeeds =                            AllSpeeds(OkRows);
                SelectedShapes =                            AllShapes(OkRows);
                MyBins =                                    obj.BinsForObjectDistancesFromTarget;
                
                %% create XY object:
                shapePerDistance_Fast =                      PMXVsYDataContainer(SelectedSpeeds,SelectedShapes, MyBins);
                shapePerDistance_Fast.XParameter =            'Shortest distance between object and target (µm)';
                shapePerDistance_Fast.YParameter =           'Eccentricity';
      
          end
        
     
        
        function [PercentageInContact] =     getPercentageOfInteractingObjects(obj)
            
                ListWithAllDistances =          vertcat(obj.DistancesFromTarget{:});
                InteractionLimit =              obj.DistanceLimitForContact_um;
                PercentageInContact =           sum(ListWithAllDistances<InteractionLimit)/length(ListWithAllDistances)*100;

            
        end
        
        function [contactDurations] =   getContactDurations(obj)
            
            TimeStamps =                                obj.getTimeStampsForEachMovie;
            NumberOfMovies =                            obj.getNumberOfMovies;
            ListWithContactDurations_Minutes =          cell(NumberOfMovies,1);
            
            for MovieIndex = 1:NumberOfMovies
                
                TrackRowPositions  =                                        obj.ListsWithRowIndicesOfUniqueTracks{MovieIndex,1};

                TimeStampsOfCurrentMovie =                                  TimeStamps{MovieIndex};
                
                AllAbsoluteFramesOfCurrentInteractionEvents =               obj.FrameNumbers{MovieIndex,1};
                [FramesPerTrack] =                                          getDataSplitByTrack(obj,AllAbsoluteFramesOfCurrentInteractionEvents,TrackRowPositions);
                
                AllDistancedOfCurrentInteractionEvents =                    obj.DistancesFromTarget{MovieIndex,1};
                [DistancesPerTrack] =                                       getDataSplitByTrack(obj,AllDistancedOfCurrentInteractionEvents,TrackRowPositions);
                
                ListWithContactDurations_Minutes{MovieIndex,1} =                 cellfun(@(distances,frames) obj.computeContactDurationsForTrack(distances,frames,TimeStampsOfCurrentMovie), DistancesPerTrack, FramesPerTrack, 'UniformOutput', false);

            end

            ContactDurations_AllMoviesPooled =                     vertcat(ListWithContactDurations_Minutes{:});
            
            % now also pool different contact durations per movie;
            contactDurations =                                      vertcat(ContactDurations_AllMoviesPooled{:});
   
        end
        
         
        function [SplitData] = getDataSplitByTrack(obj,DataList,TrackRows)
            %SPLITINTOTRACKDATA Summary of this function goes here
            %   Detailed explanation goes here

                NumberOfTracks =                size(TrackRows,1);
                SplitData =                     cell(NumberOfTracks,1);
                for TrackIndex =1:NumberOfTracks
                    CurrentTrackRows =          TrackRows{TrackIndex,1};
                    SplitData{TrackIndex,1} =        DataList(CurrentTrackRows,:);
                    
                end   

         end
        
       
        function pooledData = getPooledData(obj)
           
            AllData =                                                                               cellfun(@(x) x.AllTrackDataPooled, DataForSeparateMovies, 'UniformOutput', false);
            AllContactDataPooled =                                                             vertcat(AllData{:});

            
        end
        
        function numberOfMovies = getNumberOfMovies(obj)
            
            numberOfMovies = size(obj.MovieNickNames,1);
            
        end
        
        
        function [ListOfDurationsForAllContacts] = computeContactDurationsForTrack(obj,ContactDistances,FrameNumbers,TimeStampsForEachFrameOfMovie)
            %COMPUTECONTACTDURATIONS Summary of this function goes here
            %   Detailed explanation goes here

           
                RowsThatAreInContact =              ContactDistances<obj.DistanceLimitForContact_um;

                StartIndices =                      strfind([0,RowsThatAreInContact'==1],[0 1]);
                StartFramesOfContacts =             FrameNumbers( StartIndices);
                
                EndIndices =                        strfind([RowsThatAreInContact'==1,0],[1 0]);
                EndFramesOfConcacts =               FrameNumbers( EndIndices);
                
                if isempty(StartIndices)
                    ListOfDurationsForAllContacts =     NaN;
                    
                else
                    ListOfDurationsForAllContacts =     arrayfun(@(first,last) TimeStampsForEachFrameOfMovie(last)-TimeStampsForEachFrameOfMovie(first),StartFramesOfContacts,EndFramesOfConcacts);
                    ListOfDurationsForAllContacts =     ListOfDurationsForAllContacts + obj.MinimumContactDuration_sec; % account for imprecision because capturing between consecutive frames:
                    ListOfDurationsForAllContacts =     ListOfDurationsForAllContacts/60; % convert to minutes
            
                end

            end
        
        function [randomDistances] =    calculateRandomDistancesBetweenCellsAndFlu(RealTracks,FluPixels,  Plane ,VoxelSizeX,VoxelSizeY,VoxelSizeZ)


            
            
            
                    FluPixelsForEachMovie =                                             cellfun(@(x) x.ThresholdedCoordinatesWithoutDrift, DataForSeparateMovies, 'UniformOutput', false);

                    TrackDataForEachMovie =                                             cellfun(@(x)   x.AllTrackDataPooled, DataForSeparateMovies, 'UniformOutput', false);

                    Plane = 5;

                    AllTrackData =                                                      TrackDataForEachMovie{1,1};
                    FluPixels =                                                         FluPixelsForEachMovie{1,1};

                    %% I don't fully understand this part;
                    % it seems this is just to compare the flu-track data with the actual track, but this may not be necessary;



                     MyMovieTrackingCell =                                                              obj.RawMovieTrackingData{1,1};

                    MaximumFrameForFluLimits =                                                  10;
                    RealTracks =                                                                vertcat( MyMovieTrackingCell.Tracking.TrackingCellForTime{:});

                    RealTracks(cell2mat(RealTracks(:,2))> MaximumFrameForFluLimits,:) = [];

                    RealTracks=                                                                 cell2mat(RealTracks(:,3:5));

                    % this control may not be necessary and takes a long time to calculate;
                   % [randomDistances] =                                                 calculateRandomDistancesBetweenCellsAndFlu(RealTracks,FluPixels,  Plane ,VoxelSizeX,VoxelSizeY,VoxelSizeZ);


                    %cellfun(@(x,y) norm(x - y), 


            % I have never used this. 
            % The idea was to used "randomized controls" for the measurements;
            % this is actually tricky and the approach is not finished yet;
            % this could serve as a starting point for the future;

            FluPixels(FluPixels(:,3) == Plane, :) = [];


            RealTracks(round(RealTracks(:,3)) ~= Plane, :) = [];






            FluPixels(:,1) =            FluPixels(:,1) * VoxelSizeX*1e6;
            FluPixels(:,2) =            FluPixels(:,2) * VoxelSizeY*1e6;
            FluPixels(:,3) =            FluPixels(:,3) * VoxelSizeZ*1e6;

               RealTracks(:,1) =            RealTracks(:,1) * VoxelSizeX*1e6;
            RealTracks(:,2) =            RealTracks(:,2) * VoxelSizeY*1e6;
            RealTracks(:,3) =            RealTracks(:,3) * VoxelSizeZ*1e6;


            MaxRow =                    max(FluPixels(:,1)) ;
            MaxColumn =                 max(FluPixels(:,2));
            MaxPlane =                  max(FluPixels(:,3));



            NumberOfCells =             size(RealTracks,1);

            DistanceList =            zeros(NumberOfCells,1);

            for CurrentCellIndex = 1:NumberOfCells

                    disp([num2str(CurrentCellIndex) ' of ' num2str(NumberOfCells)]);

                    RandomCellRow =                                                   rand*MaxRow;
                    RandomCellColumn =                                                rand*MaxColumn;

                    [k,dist] =                                              dsearchn([RandomCellRow,RandomCellColumn],FluPixels(:,1:2));

                    [CurrentMinDistance,rowWithSmallestDistance] =          min(dist);



                    DistanceList(CurrentCellIndex,2) =                    CurrentMinDistance;


                     [k,dist] =                                              dsearchn([RealTracks(CurrentCellIndex,1),RealTracks(CurrentCellIndex,2)],FluPixels(:,1:2));

                    [CurrentMinDistance,rowWithSmallestDistance] =          min(dist);



                     DistanceList(CurrentCellIndex,1) =                    CurrentMinDistance;

            end


        end
        
      
        
        
    end
end

