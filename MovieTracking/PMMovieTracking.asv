classdef PMMovieTracking < PMChannels
    %PMMOVIETRACKING manage viewing and tracking of movie
    %   This class manages viewing and tracking.
 
    properties (Access = private) % crucial to save these data:

         AnnotationFolder =          ''   % folder that contains files with annotation information added by user;
        NickName
        
        MovieFolder                      % movie folder:
        AttachedFiles =             cell(0,1) % list files that contain movie-information;
       

        DriftCorrection =           PMDriftCorrection
        Interactions      

    end

    properties (Access = private) % stop tracking settings:

        StopDistanceLimit =                 15 
        MaxStopDurationForGoSegment =       5
        MinStopDurationForStopSegment =     20

        Tracking =                  PMTrackingNavigation


    end

    properties (Access = private) % is saved but could also be reconstructed from original image file;

        ImageMapPerFile
        TimeCalibration =           PMTimeCalibrationSeries
        SpaceCalibration =          PMSpaceCalibrationSeries 

    end

    properties (Access = private) % movie view

        TimeVisible =                  true
        PlanePositionVisible =         true
        ScaleBarVisible =           1   
        ScaleBarSize =              50;

        CentroidsAreVisible =           false
        TracksAreVisible =              false
        MasksAreVisible =               false
        ActiveTrackIsHighlighted =      false
        CollapseAllTracking =          false

        CollapseAllPlanes =         1

        CroppingOn =                0
        CroppingGate =              [1 1 1 1]

    end

    properties (Access = private) % no need to save:

        Navigation =                        PMNavigationSeries
        AllPossibleEditingActivities =      {'No editing','Manual drift correction','Tracking'};
        Keywords =                          cell(0,1)   % is this property necessary?
        UnsavedTrackingDataExist =          true

    end

    properties (Access = private) % for view; this should be moved somewhere else
    EnforeMaxProjectionForTrackViews = true;

    end

    methods %initialization 
        
        function obj =                                                  PMMovieTracking(varargin)
            % very complicated; should be simplified if possible;
            fprintf('\n@Create PMMovieTracking.\n')
            NumberOfInputArguments = length(varargin);
            switch NumberOfInputArguments
                case 0
                    
                case 1
                    
                    switch class(varargin{1})
                       
                        case 'PMMovieTrackingSummary'
                            obj.NickName =          varargin{1}.getNickName;
                            obj.MovieFolder =       varargin{1}.getMovieFolder; 
                            obj.AttachedFiles =     varargin{1}.getAttachedFiles;
                            obj.Keywords =          varargin{1}.getKeywords;
                            
                        case 'char'
                             obj.NickName =          varargin{1};
                            
                        otherwise
                            error('Wrong input.')
                        
                        
                        
                    end
                    
                case 2
                    obj.AnnotationFolder =  varargin{1};
                    obj.NickName =          varargin{2};
        
              
                    
                case 3
                    StructureOrNickName =  varargin{1};
                    if ischar(varargin{3})
                          
                    else
                        
                       switch varargin{3}
                           
                        case 0 % this is a simple way to create a very basic object;
                            myFilesOrFolders =              StructureOrNickName.AttachedFiles;
                            EmptyRows =                     cellfun(@(x) isempty(x), myFilesOrFolders);
                            myFilesOrFolders(EmptyRows) =   [];

                            obj.NickName =              StructureOrNickName.NickName;
                            obj.MovieFolder =                varargin{2};
                            obj.AttachedFiles =         myFilesOrFolders;


                            % if the user input was a folder, this means a folder with subfiles was selected and the subfiles have to be extracted;
                            % currently only the .pic format is organized in this way;
                            FolderWasSelected =     cellfun(@(x) isfolder(x), obj.getPathsOfImageFiles);
                            FolderWasSelected =     unique(FolderWasSelected);
                            if length(FolderWasSelected) ~=1
                                error('Cannot select a mix of files and folder') 
                            end

                             if FolderWasSelected
                                 ListWithExtractedFiles =       obj.extractFileNameListFromFolder(myFilesOrFolders);
                                 obj.AttachedFiles =            ListWithExtractedFiles;
                             else

                             end

                            obj.DriftCorrection =                                       PMDriftCorrection(StructureOrNickName, varargin{3});
                            obj.Tracking =                                              PMTrackingNavigation(StructureOrNickName,varargin{3});

                        case 1 % for loading from file

                            error('Do not use. Instead set with 2 arguments (folder and nickname), and then use load method.')
                            fprintf('Set NickName, MovieFolder and AnnotationFolder.\n')
                            if isstruct(StructureOrNickName)
                                obj.NickName =      StructureOrNickName.NickName;
                            else
                                obj.NickName =      StructureOrNickName;
                            end
                            
                            obj.MovieFolder =             varargin{2}{1};
                            obj.AnnotationFolder =   varargin{2}{2};
                            obj =                   obj.loadLinkeDataFromFile;   
                            obj.AnnotationFolder =   varargin{2}{2}; %

                        case 2
                            obj.NickName =                       StructureOrNickName.NickName;
                            obj.Keywords{1,1}=                   StructureOrNickName.Keyword;
                            obj.MovieFolder =                    varargin{2};
                            obj.AttachedFiles =                  StructureOrNickName.FileInfo.AttachedFileNames;
                            obj.DriftCorrection =                PMDriftCorrection(StructureOrNickName, varargin{3});
                            obj =                               obj.setFrameTo(StructureOrNickName.ViewMovieSettings.CurrentFrame);
                            obj =                               obj.setSelectedPlaneTo(min(StructureOrNickName.ViewMovieSettings.TopPlane:StructureOrNickName.ViewMovieSettings.TopPlane+StructureOrNickName.ViewMovieSettings.PlaneThickness-1));
                            
                       
                            if isfield(StructureOrNickName.MetaData, 'EntireMovie') % without meta-data this field will stay empty; (need channel number to complete this; when using channels: this object must be completed);
                                 NumberOfChannels =     StructureOrNickName.MetaData.EntireMovie.NumberOfChannels;
                                obj.Channels =      obj.setDefaultChannelsForChannelCount(NumberOfChannels);
                             end

                            obj.CollapseAllPlanes =                     StructureOrNickName.ViewMovieSettings.MaximumProjection;
                            obj.PlanePositionVisible =                  StructureOrNickName.ViewMovieSettings.ZAnnotation;
                            obj.TimeVisible =                           StructureOrNickName.ViewMovieSettings.TimeAnnotation;
                            obj.ScaleBarVisible =                       StructureOrNickName.ViewMovieSettings.ScaleBarAnnotation;   

                            if isfield(StructureOrNickName.ViewMovieSettings, 'CropLimits')
                                obj =                      obj.setCroppingGateWithRectange(StructureOrNickName.ViewMovieSettings.CropLimits);
                            else
                                obj =                      obj.resetCroppingGate;
                            end
                            obj.CroppingOn =                            0;
                            obj.Tracking =                               PMTrackingNavigation(StructureOrNickName.TrackingResults,varargin{3});
                        
                           otherwise
                            error('Cannot create movie tracking. Reason: loaded version is not supported')
                       end   
                        
                   end
    
                case 4
                    fprintf('Set NickName, MovieFolder and AnnotationFolder.\n')
                    if isstruct(varargin{1})
                        obj.NickName =      varargin{1}.NickName;
                    else
                        obj.NickName =      varargin{1};
                    end

                    obj.MovieFolder =           varargin{2}{1};
                    obj.AnnotationFolder =      varargin{2}{2};
                    obj =                       obj.setActiveChannel(varargin{4});
                    obj =                       obj.loadLinkeDataFromFile;   
                    obj.AnnotationFolder =      varargin{2}{2}; % duplicate because in some files this information may not be tehre
            
                case 5
                    
                    assert(strcmp(varargin{5}, 'Initialize'), 'Wrong input.')
                    

                    obj.NickName = varargin{1};
                    obj.MovieFolder        = varargin{2};  
                    obj.AttachedFiles =    varargin{3}; 
                    obj.AnnotationFolder =   varargin{4};

                    obj = obj.setPropertiesFromImageFiles;
                    
                    
                    obj.DriftCorrection = obj.DriftCorrection.setBlankDriftCorrection;
                
                otherwise
                    error('Wrong number of arguments')
            end
            
            if ~isa(obj.Interactions, 'PMInteractionsCapture') % not sure if this is a good thing;
                obj.Interactions = PMInteractionsCapture;
            end

        end
        
         
        function obj = set.ImageMapPerFile(obj, Value)
            
            assert(isvector(Value) && length(Value) == obj.getNumberOfLinkedMovieFiles, 'Wrong input')
            cellfun(@(x) PMImageMap(x), Value) % run this simply to provoke an error if input is wrong;
            obj.ImageMapPerFile = Value;
            
        end
        function obj = set.AttachedFiles(obj, Value)
            assert(iscellstr(Value), 'Invalid argument type.')
            obj.AttachedFiles = Value;
        end

        function obj = set.NickName(obj, Value)
            assert(ischar(Value), 'Wrong argument type.')
            obj.NickName =   Value; 
        end

        function obj = set.Keywords(obj, Value)
            assert(iscellstr(Value) && isvector(Value), 'Invalid argument type.')
            obj.Keywords =   Value;
        end
        
        function obj = set.MovieFolder(obj, Value)
            assert(ischar(Value), 'Invalid argument type.')
            obj.MovieFolder = Value;   
        end
        
        function obj = set.AnnotationFolder(obj, Value)
              assert(ischar(Value), 'Wrong argument type.')
              obj.AnnotationFolder = Value;
        end
          
        function obj = set.DriftCorrection(obj, Value)
            assert(isa(Value, 'PMDriftCorrection') && isscalar(Value), 'Wrong input.')
            obj.DriftCorrection = Value;
        end

        function obj = set.SpaceCalibration(obj,Value)
            assert(isa(Value,'PMSpaceCalibrationSeries') , 'Wrong input format.')
            obj.SpaceCalibration =  Value;
        end
        
        function obj = set.Interactions(obj, Value)
            assert(isa(Value, 'PMInteractionsCapture') && isscalar(Value), 'Wrong input.')
            obj.Interactions =      Value;
        end
        
        

    end
    
    methods % initialize movie view
        
        function obj = set.ScaleBarSize(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.ScaleBarSize = Value;
        end

        function obj = set.CollapseAllPlanes(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CollapseAllPlanes = Value;
        end

        function obj = set.MasksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.MasksAreVisible = Value;
        end

        function obj = set.CentroidsAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CentroidsAreVisible = Value;
        end

        function obj = set.TracksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.TracksAreVisible = Value;
        end

        function obj = set.TimeVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.TimeVisible = Value;
        end

        function obj = set.PlanePositionVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.PlanePositionVisible = Value;
        end

        function obj = set.ScaleBarVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ScaleBarVisible = Value; 
        end

        function obj = set.ActiveTrackIsHighlighted(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ActiveTrackIsHighlighted = Value; 
        end
        
        function obj = set.CollapseAllTracking(obj, Value)
             assert(isscalar(Value) && islogical(Value), 'Wrong input.')
            obj.CollapseAllTracking = Value;
        end

        function obj = set.CroppingOn(obj, Value)
            assert(isscalar(Value) && islogical(Value), 'Wrong input.')
            obj.CroppingOn = Value;
        end
        
        function obj = set.CroppingGate(obj, Value)
            assert(isnumeric(Value) && isvector(Value) && length(Value) == 4, 'Wrong input.')
            obj.CroppingGate = Value;
        end
        
    end

    methods % initialize advanced tracking
        
       
        function obj = set.StopDistanceLimit(obj,Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.StopDistanceLimit = Value;
        end
        
        function obj = set.MaxStopDurationForGoSegment(obj,Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.MaxStopDurationForGoSegment = Value;
        end
        
        function obj = set.MinStopDurationForStopSegment(obj,Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.MinStopDurationForStopSegment = Value;
        end
        
        
    end
    
    methods % set advanced tracking
        function obj = setSpaceAndTimeLimits(obj, Space, TimeMax, TimeMin)
            obj.StopDistanceLimit =                     Space;
            obj.MaxStopDurationForGoSegment =         TimeMax;
            obj.MinStopDurationForStopSegment =        TimeMin;
        
         end
        
    end
    
    methods % SETTRACKING

        function obj =      setActiveTrackToNewTrack(obj)
            obj =     obj.setActiveTrackWith(obj.findNewTrackID);
        end

        function obj =      setActiveTrackWith(obj, NewTrackID)
            obj.Tracking =      obj.Tracking.setActiveTrackIDTo(NewTrackID);
        end

        function obj =      deleteActiveTrack(obj)
            obj.Tracking  =     obj.Tracking.removeActiveTrack;
        end

        function obj =      selectAllTracks(obj)
            obj.Tracking =  obj.Tracking.selectAllTracks;
        end

        function obj =      addToSelectedTrackIds(obj, TracksToAdd)
            obj.Tracking =    obj.Tracking.addToSelectedTrackIds(TracksToAdd);
        end

        function obj =      setSelectedTrackIdsTo(obj, Value)
            obj.Tracking =  obj.Tracking.setSelectedTrackIdsTo(Value);
        end

        function obj =      updateTrackingWith(obj, Value)
            obj.Tracking = obj.Tracking.updateWith(Value); 
        end

        function obj =      setTrackIndicesFromScratch(obj)
            obj.Tracking =           obj.Tracking.setTrackIndicesFromScratch;
        end

        function obj =      setCollapseAllTrackingTo(obj, Value)
            obj.CollapseAllTracking = Value;
        end

        function obj =      setFrameTo(obj, FrameNumber)
            obj.Navigation =     obj.Navigation.setActiveFrames(FrameNumber);
            obj.Tracking =       obj.Tracking.setActiveFrameTo(FrameNumber);
        end

        function obj=       setNumberOfFramesInSubTracks(obj, Frames)
            obj.Tracking.TrackNumberOfFramesInSubTracks =        Frames;
        end

        function obj =      setFinishStatusOfTrackTo(obj, input)
          obj.Tracking = obj.Tracking.setInfoOfActiveTrack(input);
          fprintf('Finish status of track %i was changed to "%s".\n', obj.getIdOfActiveTrack, input)
        end


    end
    
    methods (Access = private) % set tracking
        
         function newTrackID =             findNewTrackID(obj)
                newTrackID =    obj.Tracking.generateNewTrackID;
                fprintf('Tracking identified %i as new track ID.\n', newTrackID)
         end
          
    end
    
    methods % GETTRACKING
        
        function tracking = getTracking(obj)
            tracking = obj.Tracking; 
        end
        
        function [IdOfActiveTrack] =     getIdOfActiveTrack(obj)
            IdOfActiveTrack =            obj.Tracking.getIdOfActiveTrack;
        end

        function MySegmentation =   getUnfilteredSegmentationOfActiveTrack(obj)
            MySegmentation =        obj.Tracking.getSegmentationForTrackID(obj.getIdOfActiveTrack);
        end

        function [segmentationOfCurrentFrame ] =            getUnfilteredSegmentationOfCurrentFrame(obj)
        segmentationOfCurrentFrame =        obj.Tracking.getSegmentationOfFrame( obj.Navigation.getActiveFrames);
        end

        function trackIds = getAllTrackIDs(obj)
         trackIds =    obj.Tracking.getListWithAllUniqueTrackIDs;

        end

        function trackIds = getSelectedTrackIDs(obj)
         trackIds =    obj.Tracking.getIdsOfSelectedTracks;
        end

        function trackIds = getIdsOfRestingTracks(obj)
         trackIds =    obj.Tracking.getIdsOfRestingTracks;
        end

      
        function FramesInMinutesForGoSegments = getMetricFramesOfStopSegmentsOfActiveTrack(obj)
                frameList = obj.getFramesOfStopSegmentsOfActiveTrack;
                 TimeInMinutesForEachFrame=         obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;

            FramesInMinutesForGoSegments = cellfun(@(x)   TimeInMinutesForEachFrame(x),frameList, 'UniformOutput', false);
        end

        function FramesInMinutesForGoSegments = getMetricFramesOfGoSegmentsOfActiveTrack(obj)
         frameList =                        obj.getFramesOfGoSegmentsOfActiveTrack;
         TimeInMinutesForEachFrame=         obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;

            FramesInMinutesForGoSegments = cellfun(@(x)   TimeInMinutesForEachFrame(x),frameList, 'UniformOutput', false);

        end

        function frameList = getFramesOfStopSegmentsOfActiveTrack(obj)
             myStopTracking =     obj.getStopTrackingOfActiveTrack;
            frameList =         myStopTracking.getStartAndEndRowsOfStopTrackSegments;

        end

        function frameList = getFramesOfGoSegmentsOfActiveTrack(obj)
           myStopTracking =     obj.getStopTrackingOfActiveTrack;
            frameList =         myStopTracking.getStartAndEndRowsOfGoTrackSegments;


        end

        function myStopTracking = getStopTrackingOfActiveTrack(obj)
             metricCoordinates =             obj.getMetricCoordinatesOfActiveTrack;
             

            myStopTracking =                PMStopTracking([obj.getFramesInMinutesOfActiveTrack, metricCoordinates]);
            myStopTracking =                myStopTracking.setSpaceAndTimeLimits(obj.StopDistanceLimit, obj.MaxStopDurationForGoSegment, obj.MinStopDurationForStopSegment);

        end
        
        function TimeInMinutesForActiveTrack = getFramesInMinutesOfActiveTrack(obj)
            frames =                        obj.Tracking.getFramesOfActiveTrack;
            TimeInMinutesForEachFrame=      obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;
            TimeInMinutesForActiveTrack =   TimeInMinutesForEachFrame(frames);

        end

        function metricCoordinates = getMetricCoordinatesOfActiveTrack(obj)
            coordinates =           obj.getCoordinatesForActiveTrack;
            metricCoordinates =     obj.getSpaceCalibration.convertXYZPixelListIntoUm(coordinates);  
        end

        function metricCoordinatesForEachSegment = getMetricCoordinatesOfActiveTrackFilteredForFrames(obj, myFrames)
            MyTrackMatrix =                         [obj.Tracking.getFramesOfActiveTrack, obj.getMetricCoordinatesOfActiveTrack];
            metricCoordinatesForEachSegment =       obj.Tracking.filterMatrixByFirstColumnForValues(MyTrackMatrix, myFrames);
            metricCoordinatesForEachSegment =       metricCoordinatesForEachSegment(:, 2:4);
        end

        function coordinates = getCoordinatesForActiveTrack(obj)
            [coordinates] =        obj.Tracking.getCoordinatesForActiveTrackPlanes(obj.getPlanesThatAreVisibleForSegmentation, obj.DriftCorrection);
        end

        function Value =      getCollapseAllTracking(obj)
        Value = obj.CollapseAllTracking;
        end
        
         function coordinates = getCoordinatesForTrackIDs(obj, TrackIDs)
               
               if obj.EnforeMaxProjectionForTrackViews
                   %Planes =  obj.getMaxProjectionPlanesForCurrentView;
                
               else
                   
               end
               
               Planes = obj.getPlanesThatAreVisibleForSegmentation;
                coordinates =        obj.Tracking.getCoordinatesForTrackIDsPlanes(TrackIDs, Planes, obj.DriftCorrection);
         end

           
           
         function segmentationOfActiveTrack =                  getSegmentationOfActiveTrack(obj)
            segmentationOfActiveTrack =    obj.Tracking.getActiveSegmentationForFrames(obj.Navigation.getActiveFrames);
         end 

           function segmentationOfActiveTrack =                  getSegmentationOfActiveMask(obj)
            segmentationOfActiveTrack =    obj.Tracking.getActiveSegmentationForFrames(obj.Navigation.getActiveFrames);
           end 
         
             %% getNumberOfTracks
        function numberOfTracks =   getNumberOfTracks(obj)
            numberOfTracks = obj.Tracking.getNumberOfTracks;
        end
         
         
         
        
    end
    
    methods (Access = private) % get tracking
       
    end
    
    methods % interpret tracking data
        
        
           function SelectedTrackID = getIdOfTrackThatIsClosestToPoint(obj, Point)
                 
                TrackDataOfCurrentFrame =       obj.Tracking.getSegmentationOfFrame(obj.Navigation.getActiveFrames); 
                OVERLAP =                       find(cellfun(@(x)  ismember(round(Point), round(x(:,1:3)), 'rows'), TrackDataOfCurrentFrame(:,6)));

                 if length(OVERLAP) >= 1
                        SelectedTrackID =        TrackDataOfCurrentFrame{OVERLAP(1),1};
                 else
                     
                     YOfAllTracks = cell2mat(TrackDataOfCurrentFrame(:,3));
                     XOfAllTracks = cell2mat(TrackDataOfCurrentFrame(:,4));
                     ZOfAllTracks = cell2mat(TrackDataOfCurrentFrame(:,5));
                     
                     [~,row] =   obj.computeShortestDistance(Point, [YOfAllTracks,XOfAllTracks, ZOfAllTracks]);
                     
                     
                     
                     if ~isempty(row)
                         SelectedTrackID = TrackDataOfCurrentFrame{row,1};
                     else
                        SelectedTrackID = NaN ;
                         
                     end
                     
                 end
              end
              
            function [ShortestDistance,rowWithShortestDistance] = computeShortestDistance(~, Point, Coordinates)

                if isempty(Coordinates)
                    ShortestDistance = '';
                    rowWithShortestDistance = '';
                else
                    DistanceX=  Point(2)- Coordinates(:, 2);
                    DistanceY=  Point(1)- Coordinates(:, 1);
                    DistanceZ=  Point(3)- Coordinates(:, 3);

                if isempty(DistanceX) || isempty(DistanceY) || isempty(DistanceZ)
                    Distance=   nan;
                else
                    Distance=   sqrt(power(DistanceX,2) + power(DistanceY,2) + power(DistanceZ,2));
                end

                [ShortestDistance, rowWithShortestDistance]=  min(Distance);

                    
                end
                
               
            end
                
            
       
            
            
            
        
        
        
    end
    
    methods  % tracking views
        
        
          
         function TargetPlanes = getTargetMoviePlanesForSegmentationVisualization(obj)
            
            
            if obj.getDriftCorrectionStatus
                TargetPlanes =      obj.getPlanesThatAreVisibleForSegmentation - obj.getAplliedPlaneShiftsForActiveFrames;
                TargetPlanes =      obj.removeOutOfBoundsPlanesFromPlaneList( TargetPlanes);
               
            else
                TargetPlanes =      obj.getPlanesThatAreVisibleForSegmentation;
                
            end
            
         end
          
    end
    
    methods (Access = private) % tracking views
        
           function visiblePlanes = getPlanesThatAreVisibleForSegmentation(obj)
                switch obj.CollapseAllTracking
                    case 1
                        visiblePlanes = obj.getMaxProjectionPlanesForCurrentView;
                    otherwise
                        visiblePlanes = obj.getActivePlanes - obj.getAplliedPlaneShiftsForActiveFrames;
                end
           end
           
           function visiblePlanes = getMaxProjectionPlanesForCurrentView(obj)
               visiblePlanes =     1 : obj.getMaxPlaneWithAppliedDriftCorrection;
           end
           
           function TargetPlanes = removeOutOfBoundsPlanesFromPlaneList(obj, TargetPlanes)
                TargetPlanes(TargetPlanes < 1) =    [];
                TargetPlanes(TargetPlanes > obj.Navigation.getMaxPlane) = [];
               
           end
         
        
    end
    
    
    methods % autocell recognition
        
        
        function obj = executeAutoCellRecognition(obj, myCellRecognition)
            myCellRecognition =     myCellRecognition.performAutoDetection;
            obj.Tracking =          obj.Tracking.setAutomatedCellRecognition(myCellRecognition);
            fprintf('\nCell recognition finished!\n')
           
            setPreventDoubleTracking
            
            fprintf('\nAdding cells into track database ...\n')
            for CurrentFrame = myCellRecognition.getSelectedFrames' % loop through each frame 
                fprintf('Processing frame %i ...\n', CurrentFrame)
                obj =           obj.setFrameTo(CurrentFrame);
                
                PixelsOfCurrentFrame =      myCellRecognition.getDetectedCoordinates{CurrentFrame,1};
                for CellIndex = 1 : size(PixelsOfCurrentFrame,1) % loop through all cells within each frame and add to Tracking data
                    obj =      obj.setActiveTrackWith(obj.findNewTrackID);
                    obj =      obj.resetActivePixelListWith(PMSegmentationCapture(PixelsOfCurrentFrame{CellIndex,1}, 'DetectCircles'));
                end
            end
            fprintf('Cell were added into the database!\n')
        end
        
          function [obj] =             resetActivePixelListWith(obj, SegmentationCapture)
            
              assert(isscalar(SegmentationCapture) && isa(SegmentationCapture, 'PMSegmentationCapture'), 'Wrong input.')
              
            if isnan(obj.getIdOfActiveTrack)
                warning('No valid active track. Therefore no action taken.')
                
            else
                
               % obj.Tracking =
               % obj.Tracking.setTrackingAnalysis(obj.getTrackingAnalysis);
               % % this is done somewhere else now; otherwise too slow;
               % check if this is ok now;
                try 
                    obj.Tracking =      obj.Tracking.addSegmentation(SegmentationCapture);
                catch E
                    throw(E) 
                end

                obj =               obj.setSavingStatus(true);
                
            end
                
          end
        
        
          
        
    end
    
    methods % tracking that needs to be organized
        
          function obj =    mergeTracksWithinDistance(obj, distance)
                 obj.Tracking =             obj.Tracking.setDistanceLimitZForTrackingMerging(2);
                 obj.Tracking =             obj.Tracking.setShowDetailedMergeInformation(true);
                 if isnan(distance)
                 else
                    obj.Tracking =        obj.Tracking.trackingByFindingUniqueTargetWithinConfines(distance);
                 end
          end
          
          %% deleteSelectedTracks
          function obj = deleteSelectedTracks(obj)
              obj.Tracking  =         obj.Tracking.deleteAllSelectedTracks;
          end
             
          
          function obj = generalCleanup(obj)
               obj.Tracking = obj.Tracking.generalCleanup;
          end
          
          
         function obj =  deleteActiveTrackAfterActiveFrame(obj)
            obj.Tracking =     obj.Tracking.deleteActiveTrackAfterFrame(obj.getActiveFrames);
         end
         
         function obj = deleteActiveTrackBeforeActiveFrame(obj)
                obj.Tracking =   obj.Tracking.deleteActiveTrackBeforeFrame(obj.getActiveFrames);
         end
         
         function obj =  splitTrackAfterActiveFrame(obj)
            obj.Tracking =     obj.Tracking.splitActiveTrackAtFrame(obj.getActiveFrames);
         end
         
       function trackIds = getIndicesOfFinishedTracksFromList(obj, List)
            trackIds = obj.Tracking.getIndicesOfFinishedTracksFromList(List); 
       end
        
       function trackIDs = getUnfinishedTrackIDs(obj)
           trackIDs = obj.Tracking.getUnfinishedTrackIDs;
       end    
       
            
        %% getLimitsOfFirstGapOfActiveTrack
        function limits = getLimitsOfFirstGapOfActiveTrack(obj)
           limits = obj.Tracking.getLimitsOfFirstGapOfActiveTrackForLimitValue(obj.Navigation.getMaxFrame); 
        end
        
        function [limits, ids] = getLimitsOfSurroundedFirstForwardGapOfAllTracks(obj)
             [limits, ids] =    obj.Tracking.getLimitsOfSurroundedFirstForwardGapOfAllTracks;
        end
        
        function [limits, ids] = getLimitsOfFirstForwardGapOfAllTracks(obj)
            [limits, ids] =    obj.Tracking.getLimitsOfFirstForwardGapOfAllTracksForLimitValue( obj.Navigation.getMaxFrame);
        end
        
        function [limits, ids] = getLimitsOfFirstBackwardGapOfAllTracks(obj)
            [limits, ids] =    obj.Tracking.getLimitsOfFirstBackwardGapOfAllTracksForLimitValue( obj.Navigation.getMaxFrame);
            
        end
        
      
        
     
        
        
        
    end
    
    methods % navigation getters
        
         
      
         
        
        function Navigation = getNavigation(obj)
            Navigation = obj.Navigation;
        end
         
        function plane = getMaxPlane(obj)
            plane = obj.Navigation.getMaxPlane; 
        end
         
        function maxChannel = getMaxChannel(obj)
            maxChannel = obj.Navigation.getMaxChannel;
        end
         
        function [frameNumbers] =        getMaxFrame(obj)
            frameNumbers =      obj.Navigation.getMaxFrame;
        end
        
        function [rows, columns, planes] =    getImageDimensions(obj)
            planes =        obj.Navigation.getMaxPlane;
            rows =          obj.Navigation.getMaxRow;
            columns =       obj.Navigation.getMaxColumn;
        end
        
        function frames = getActivePlanes(obj)
            frames = obj.Navigation.getActivePlanes;
        end
        
        function frames = getActiveFrames(obj)
            frames = obj.Navigation.getActiveFrames;
        end

    end
    
    methods (Access = private) % navigation: get plane information
        
        function AplliedPlaneShifts = getMaxAplliedPlaneShifts(obj)
            AplliedPlaneShifts =  max(obj.getAplliedPlaneShifts);
        end 

        function AplliedPlaneShifts = getAplliedPlaneShifts(obj)
            AplliedPlaneShifts =  obj.DriftCorrection.getAplliedPlaneShifts;
        end
        
    end
    
    methods % space-calibration
       
         function calibration = getSpaceCalibration(obj)
            calibration = obj.SpaceCalibration.Calibrations(1);   
        end
        
        function Value = convertXYZPixelListIntoUm(obj, Value)
            Value = obj.SpaceCalibration.Calibrations.convertXYZPixelListIntoUm(Value);
        end
        
        function Value = convertYXZUmListIntoPixel(obj, Value)
            Value = obj.SpaceCalibration.Calibrations.convertYXZUmListIntoPixel(Value);
        end
        
        
        
    end
    
    methods % drift correction
        
         function final = getAplliedColumnShiftsForActiveFrames(obj)
            shifts =   obj.getAplliedColumnShifts;
            final =    shifts(obj.getActiveFrames);
         end
        
          function final = getAplliedRowShiftsForActiveFrames(obj)
            shifts = obj.getAppliedRowShifts;
            final =    shifts(obj.getActiveFrames);
          end
          
          
        function [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
            xCoordinates=       xCoordinates - obj.getAplliedColumnShiftsForActiveFrames;
            yCoordinates=       yCoordinates - obj.getAplliedRowShiftsForActiveFrames;
            zCoordinates=       zCoordinates - obj.getAplliedPlaneShiftsForActiveFrames;
        end
        
        
        
        %% setDriftCorrectionTo
         function obj =      setDriftCorrectionTo(obj,OnOff)
            obj.DriftCorrection = obj.DriftCorrection.setDriftCorrectionActive(OnOff);
         end
        
        %% getDriftCorrectionStatus
         function value = getDriftCorrectionStatus(obj) 
             value = obj.DriftCorrection.getDriftCorrectionActive;
         end
         
       
         
        
    
          function DriftCorrectionWasPerformed =             testForExistenceOfDriftCorrection(obj)
               if isempty(obj.DriftCorrection)
                    DriftCorrectionWasPerformed =           false;
               else
                    DriftCorrectionWasPerformed=            obj.DriftCorrection.testForExistenceOfDriftCorrection;
               end
          end
        
 
          function obj = applyManualDriftCorrection(obj)
             obj.DriftCorrection =  obj.DriftCorrection.updateByManualDriftCorrection;
          end
         

         function myDriftCorrection = getDriftCorrection(obj)
            myDriftCorrection = obj.DriftCorrection;
         end
         
         function obj = setDriftCorrection(obj, Value)
            obj.DriftCorrection = Value;
            obj.Tracking =  obj.Tracking.setTrackingCellForTimeWithDriftByDriftCorrection(obj.DriftCorrection);
         end
         
        
        
   
         function Coordinates = getActiveCoordinatesOfManualDriftCorrection(obj)
                ManualDriftCorrectionValues =   obj.DriftCorrection.getManualDriftCorrectionValues;
                ActiveFrame =                   obj.getActiveFrames;
                xWithoutDrift =                 ManualDriftCorrectionValues(ActiveFrame, 2);
                yWithoutDrift =                 ManualDriftCorrectionValues(ActiveFrame, 3);
                planeWithoutDrift =             ManualDriftCorrectionValues(ActiveFrame, 4);
                [xWithDrift, yWithDrift, zWithDrift ] =           obj.addDriftCorrection(xWithoutDrift, yWithoutDrift, planeWithoutDrift);

                Coordinates =   [xWithDrift, yWithDrift, zWithDrift ];
             
         end
         
     
     

        function obj =  setDriftDependentParameters(obj)
            obj.DriftCorrection =       obj.DriftCorrection.setNavigation(obj.Navigation);
              obj.Tracking =      obj.Tracking.setTrackingAnalysis(obj.getTrackingAnalysis);
            % obj.Tracking.setTrackingCellForTimeWithDriftByDriftCorrection(obj.getDriftCorrection);
            % % this really slow and not necessary I think;

        end
        
        
        
    end
    
    methods (Access = private) % drift correction
        
             function [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates) 
                xCoordinates=         xCoordinates + obj.getAplliedColumnShiftsForActiveFrames;
                yCoordinates=         yCoordinates + obj.getAplliedRowShiftsForActiveFrames;
                zCoordinates=         zCoordinates + obj.getAplliedPlaneShiftsForActiveFrames;
          end
          
     
        
          function AplliedColumnShifts = getAplliedColumnShifts(obj)
               AplliedColumnShifts =   obj.DriftCorrection.getAppliedColumnShifts;       
         end

       
        
         function AplliedPlaneShifts = getMaxAplliedRowShifts(obj)
            AplliedPlaneShifts =  max(obj.getAppliedRowShifts);
        end 

        function AplliedRowShifts = getAppliedRowShifts(obj)
            AplliedRowShifts = obj.DriftCorrection.getAppliedRowShifts;
        end

        function final = getAplliedPlaneShiftsForActiveFrames(obj)
            shifts = obj.getAplliedPlaneShifts;
            final =    shifts(obj.getActiveFrames);
        end
        
      

        
        
    end
    
    methods % summary
        
        function obj = showSummary(obj)
            
            fprintf('\n*** This PMMovieTracking object manages annotation of a movie-sequence.\n')
            fprintf('The most important functions are to track cells and to correct drift of movie-sequences.\n')
            fprintf('\nTracking is done with the following PMTrackingNavigation object:\n')
            
            obj.Tracking = obj.Tracking.showSummary;
            
            fprintf('\nAnother important feature is support for interaction analysis.\n')
            fprintf('The foundation for this support comes from the following object:\n')
            obj.Interactions = obj.Interactions.showSummary;
            
            fprintf('\nThis object also determines what type of annotation will be displayed.\n')
            if obj.TimeVisible
                fprintf('Captured time of the current frame will be shown.\n')
            else
                fprintf('Captured time of the current frame will not be shown.\n')
            end
            
            if obj.PlanePositionVisible
                fprintf('The depth of the selcted planes will be shown.\n')
            else
                 fprintf('The depth of the selcted planes will not be shown.\n')
            end
            
            if obj.ScaleBarVisible
                fprintf('A scale bar of a size of %i µm will be shown.\n', obj.ScaleBarSize)
            else
                 fprintf('A scale bar will not be shown.\n')
            end
            
            if obj.CollapseAllPlanes
                fprintf('Images are derived from a maximum projection of all planes.\n')
            else
                 fprintf('A scale bar will not be shown.\n')
            end
            
            if obj.CollapseAllTracking
                fprintf('Tracking from all planes will be shown.\n')
            else
                 fprintf('Tracking will be filtered so that only those form specific planes will be shown.\n')
            end
            
            if obj.CentroidsAreVisible
                fprintf('Centroids from tracked cells are shwon.\n')
            else
                fprintf('Centroids from tracked cells are not shwon.\n')
            end
            
            if obj.TracksAreVisible
                fprintf('Tracks are shown.\n')
            else
                 fprintf('Tracks are not shown.\n')
            end
  
            if obj.MasksAreVisible
                fprintf('Masks are shown.\n')
            else
                 fprintf('Masks are not shown.\n')
             end
         
            if obj.ActiveTrackIsHighlighted
                fprintf('Active tracks are highlighted.\n')
            else
                 fprintf('Active tracks are not highlighted.\n')
            end

            if obj.CroppingOn
                    fprintf('Field of view will be cropped by cropping gate.\n')
            else
                    fprintf('Entire field of view will be shown.\n')
            end

            fprintf('The cropping gate is set to X start = "%i", Y start = "%i", X width = "%i", Y width = "%i".\n', ...
            obj.CroppingGate(1), obj.CroppingGate(2), obj.CroppingGate(3), obj.CroppingGate(4));

            fprintf('\nChannel settings:\n')
            obj.showChannelSummary;
  

        
            
        end
        
        
    end
    
    methods %setters for image view
         function obj = toggleCollapseAllPlanes(obj)
            obj.CollapseAllPlanes = ~obj.CollapseAllPlanes;
        end
        
        function obj = setCollapseAllPlanes(obj, Value)
            obj.CollapseAllPlanes = Value;
        end
        
        
    end
    
    methods % cropping
       
         function croppingGate = getAppliedCroppingRectangle(obj)

            switch obj.CroppingOn
                case 1
                   croppingGate =   obj.getCroppingRectangle;

                otherwise
                    [rows,columns, ~] =     obj.getImageDimensionsWithAppliedDriftCorrection;
                    croppingGate =          [1 1 columns  rows];

            end

         end
         
         function croppingGate = getCroppingRectangle(obj)
              croppingGate =          obj.CroppingGate;
                    croppingGate(1) =       croppingGate(1) + obj.getAplliedColumnShiftsForActiveFrames;
                    croppingGate(2) =       croppingGate(2) + obj.getAplliedRowShiftsForActiveFrames;
             
         end
         
        function obj =             resetCroppingGate(obj)
            obj.CroppingGate=                 [ 1 1 obj.Navigation.getMaxColumn obj.Navigation.getMaxRow];
        end

        function obj =       setCroppingGateWithRectange(obj, Rectangle)
            obj.CroppingGate =       Rectangle;
        end

        function obj = setCroppingStateTo(obj, OnOff)
            obj.CroppingOn =                                    OnOff;  
        end
        
        function Value = getCroppingOn(obj)
            Value = obj.CroppingOn ;  
        end
        
        function [rows, columns, planes ] =     getImageDimensionsWithAppliedDriftCorrection(obj)
            rows =      obj.getMaxRowWithAppliedDriftCorrection;
            columns =   obj.getMaxColumnWithAppliedDriftCorrection;
            planes =    obj.getMaxPlaneWithAppliedDriftCorrection;
        end

        function rows = getMaxRowWithAppliedDriftCorrection(obj)
            rows =          obj.Navigation.getMaxRow + obj.getMaxAplliedRowShifts;
        end
        
        function columns = getMaxColumnWithAppliedDriftCorrection(obj)
            columns =       obj.Navigation.getMaxColumn +obj.getMaxAplliedColumnShifts;
        end
        
        function planes = getMaxPlaneWithAppliedDriftCorrection(obj)
            planes =        obj.Navigation.getMaxPlane + obj.getMaxAplliedPlaneShifts;
        end  
        
       
        function  XData = getXPointsForCroppingRectangleView(obj)
            StartColumn=    obj.CroppingGate(1) + obj.getAplliedColumnShiftsForActiveFrames;
            XData=          [StartColumn   StartColumn + obj.CroppingGate(3)     StartColumn + obj.CroppingGate(3)   StartColumn       StartColumn];   
        end

        function  YData = getYPointsForCroppingRectangleView(obj)
          StartRow=     obj.CroppingGate(2) + obj.getAplliedRowShiftsForActiveFrames;
          YData=        [StartRow  StartRow StartRow + obj.CroppingGate(4)  StartRow + obj.CroppingGate(4)  StartRow];
        end
        
         function obj =      moveCroppingGateToActiveMask(obj)
            Coordinates =   obj.Tracking.getCoordinatesOfActiveTrackForFrame(obj.getActiveFrames);
            if isempty(Coordinates)
            else
                obj =           obj.moveCroppingGateToNewCenter(Coordinates(1), Coordinates(2));
            end
            
        end
        
        function obj =           moveCroppingGateToNewCenter(obj, centerX, centerY)
            if ~isnan(centerX)
                obj.CroppingGate(1) =        centerX - obj.CroppingGate(3) / 2;
                obj.CroppingGate(2) =        centerY - obj.CroppingGate(4) / 2; 
            end
        end
  
        

        
           
    end
    
    methods % channels
       
            
      
       function obj = setChannels(obj, Value)
            assert(isa(Value, 'PMMovieTracking'), 'Wrong argument type.')
            obj.Channels = Value.Channels;

        end

       function [obj] =    resetChannelSettings(obj, Value, Field)

            switch Field
                case 'ChannelTransformsLowIn'
                    obj = setIntensityLow(obj, Value);
                    
                case 'ChannelTransformsHighIn'
                    obj = setIntensityHigh(obj, Value);
                    
                case 'ChannelColors'
                    obj = setColor(obj, Value);
                    
                case 'ChannelComments'     
                    obj = setComment(obj, Value);
                    
                case 'SelectedChannels'     
                     obj = setVisible(obj, Value);
                     
                case 'ChannelReconstruction'
                    obj = obj.setReconstructionType(Value);   
                    
                otherwise
                    error('Wrong input')

            end

       end
        
        
        
        
    end
    
    methods% derivative data
       
         
          function obj = saveDerivativeData(obj)
              
              if obj.isMapped
                  
              else
                   obj =   obj.setPropertiesFromImageFiles;
              end

            TrackingAnalysis =      obj.getTrackingAnalysis;
            TrackingAnalysis =      TrackingAnalysis.setSpaceUnits('µm');
            TrackingAnalysis =      TrackingAnalysis.setTimeUnits('minutes');
            TrackCell_Metric =      TrackingAnalysis.getTrackCell;
            TrackCell_Metric =      cellfun(@(x) x(:, 1 : 5), TrackCell_Metric, 'UniformOutput', false);

            SavePath = obj.getPathForTrackCell;
            save(SavePath, 'TrackCell_Metric')

            TrackingAnalysis =      TrackingAnalysis.setSpaceUnits('pixels');
            TrackingAnalysis =      TrackingAnalysis.setTimeUnits('frames');
            TrackCell_Pixels =      TrackingAnalysis.getTrackCell;
            TrackCell_Pixels =      cellfun(@(x) x(:, 1 : 5), TrackCell_Pixels, 'UniformOutput', false);

            SavePath = obj.getPathForTrackCell('TrackCell_Pixels');
            save(SavePath, 'TrackCell_Pixels')
  
          end
          
          
        
        function TrackingAnalysis =     getTrackingAnalysis(obj)
            TrackingAnalysis =  PMTrackingAnalysis(obj.Tracking, obj.DriftCorrection, obj.SpaceCalibration, obj.TimeCalibration);
        end
        
        
         function Data = getDerivedData(obj, Type)
              assert(ischar(Type), 'Wrong input.')
              switch Type
                  case 'TrackCell_Metric'
                      Data = load(obj.getPathForTrackCell, 'TrackCell_Metric');
                        Data = Data.TrackCell_Metric;
                  case 'TrackCell_Pixels'
                      try
                        Data = load(obj.getPathForTrackCell('TrackCell_Pixels'), 'TrackCell_Pixels');
                          Data = Data.TrackCell_Pixels;
                      catch
                          Data = load(obj.getPathForTrackCell('TrackCell_Metric'), 'TrackCell_Metric'); % not ideal; create the pixel dataset, as long as not filtering for planes might be ok;
                            Data = Data.TrackCell_Metric;
                      end
                      
                  otherwise
                      error('Type not supported.')
                  
              end
            
          end
        
    end
    
    methods (Access = private) % derivative data
        
       
        function fileName =     getPathForTrackCell(obj, varargin)

            if isempty(varargin)
                Name = '_TrackingCell_Metric';
            else
                assert(ischar(varargin{1}), 'Wrong input.')


                switch varargin{1}
                  case 'TrackCell_Pixels'
                      Name = '_TrackingCell_Pixels';
                    case 'TrackCell_Metric'
                         Name = '_TrackingCell_Metric';
                        
                  otherwise
                      error('Wrong input.')

                end
            end



            obj = obj.verifyAnnotationPaths;
            fileName = [obj.AnnotationFolder '_DerivativeData/' obj.NickName Name];
                if exist([obj.AnnotationFolder '_DerivativeData/']) ~=7
                    mkdir( [obj.AnnotationFolder '_DerivativeData/']);
                end
            
            
            
        end
        
        function obj = verifyAnnotationPaths(obj)
            assert(obj.verifyExistenceOfAnnotationPaths, 'Invalid annotation filepaths.')
            
        end
        
        function exist = verifyExistenceOfAnnotationPaths(obj)
           exist =  ~isempty(obj.AnnotationFolder) &&  ~isempty(obj.NickName);  
        end
        
 
    end
    
    methods % FILE SETTERS
        
        function exist = verifyExistenceOfPaths(obj)
           
                existOne = obj.verifyExistenceOfAnnotationPaths;

                existTwo = ~isempty(obj.MovieFolder);
                existThree = ~isempty(obj.AttachedFiles);

                exist = existOne && existTwo && existThree;

            
        end
        
        function [obj] =    setImageAnalysisFolder(obj, FolderName)
                obj.AnnotationFolder =  FolderName;
                obj = obj.setPathsThatDependOnAnnotationFolder;
        end

        function obj =      setMovieFolder(obj, Value)
        obj.MovieFolder = Value;   
        end

        
    end
    
    methods % FILE SETTERS
             
        function obj = setPathsThatDependOnAnnotationFolder(obj)
             obj.Tracking =  obj.Tracking.setMainFolder(obj.getTrackingFolder);
        end

       

        function obj =                                  setPropertiesFromImageFiles(obj)

            fprintf('\nPMMovieTracking:@setPropertiesFromImageFiles.\n')
            if isempty(obj.getPathsOfImageFiles)
                error('Files not connected. Attempt to create image map incomplete.\n')

            else
                % usually this will done only a single time for each file;
                % then the map and meta-data are saved in file enabling faster reading, still using other functions for retrieving data from file (with the help of this map);

                myImageFiles = PMImageFiles(obj.getPathsOfImageFiles);

                if myImageFiles.notAllFilesCouldBeRead
                    warning('At least one source file could not be read. No action taken.\n')

                else

                    fprintf('All source files could be accessed. Retrieving MetaData and ImageMaps.\n')

                    obj.ImageMapPerFile =              myImageFiles.getImageMapsPerFile; 
                    obj.SpaceCalibration =             myImageFiles.getSpaceCalibration; 
                    obj.TimeCalibration =              myImageFiles.getTimeCalibration; 
                    obj.Navigation =                   myImageFiles.getNavigation; 

                    obj.DriftCorrection =               obj.DriftCorrection.setNavigation(obj.Navigation);
                    obj =                               obj.setImageMapDependentProperties;

                    if obj.getNumberOfChannels ~= obj.Navigation.getMaxChannel
                        obj = obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);

                    end

                end

            end

        end
  
    end
    
    methods % FILE GETTERS
        
         function linkeFiles = getLinkedMovieFileNames(obj)
              linkeFiles =  obj.AttachedFiles;  
         end
         
           function test = isMapped(obj)
                test(1) = ~isempty(obj.ImageMapPerFile);

                test(2) = isa(obj.TimeCalibration, 'PMTimeCalibrationSeries');
                test(3) = isa(obj.SpaceCalibration, 'PMSpaceCalibrationSeries');
                test(4) = obj.checkCompletenessOfNavigation;
                test = min(test);

           end
        
            function extension = getMovieFileExtension(obj)
               [~, ~, NickNames] = cellfun(@(x) fileparts(x), obj.AttachedFiles, 'UniformOutput', false);
               extension = unique(NickNames);
               assert(length(extension) == 1, 'Cannot process diverse extensions.')
               extension = extension{1};
            end

        
        
    end
    
    methods (Access = private) % FILE GETTERS
        
        function number = getNumberOfLinkedMovieFiles(obj)
           number = length(obj.getLinkedMovieFileNames);
        end

       

     

      
 
    end
    
    
    methods % ANNOTATION FILE GETTERS
         function fileName =     getPathOfMovieTrackingForSingleFile(obj)
            obj = obj.verifyAnnotationPaths;
            fileName = [obj.AnnotationFolder '/' obj.NickName  '.mat'];
        end
        
    end
    
    methods (Access = private) % ANNOTATION FILE GETTERS
        
        function paths = getAllAnnotationPaths(obj)
            
            paths{1,1 } = obj.getPathOfMovieTrackingForSingleFile;
            paths{2,1 } = obj.getPathOfMovieTrackingForSmallFile;
            paths{3,1 } = obj.getTrackingFolder;
            
        end
        
        function fileName = getBasicMovieTrackingFileName(obj)
            if isempty(obj.AnnotationFolder) || isempty(obj.NickName)
               error('Filename not specified')
            else
                fileName = [obj.AnnotationFolder '/' obj.NickName];
            end

        end

       

        function fileName =     getPathOfMovieTrackingForSmallFile(obj)
            obj = obj.verifyAnnotationPaths;
            fileName = [obj.AnnotationFolder '/' obj.NickName  '_Small.mat'];

        end

        function Folder = getTrackingFolder(obj)
             obj = obj.verifyAnnotationPaths;
            Folder = [obj.AnnotationFolder '/' obj.NickName '_Tracking'];
        end

        
        
    end
    
    methods % FILE IMPORT
        
      
        
        function value = canConnectToSourceFile(obj)
            
              version = obj.detectVersionFromFileFormat;
              
              if ~isempty(version)
                  
                  value = true;
              else
                  value = false;
                  
                  
              end
            
        end
        
        
        function obj = load(obj)

            version = obj.detectVersionFromFileFormat;

            
            
            switch version
                
                case ''
                    error('File does not exist or has row version.')

                case 'BeforeAugust2021'
                    OriginalAnnotationFolder = obj.AnnotationFolder;
                    OriginalMovieFolder =       obj.MovieFolder;

                    obj =       obj.loadDataForFileFormatBefore_August2021;

                    obj =       obj.setImageAnalysisFolder(OriginalAnnotationFolder);
                    obj =       obj.setMovieFolder(OriginalMovieFolder);

                    obj =       obj.save;

                case 'AfterAugust2021'


                otherwise
                    error('Format not supported.')



            end

            obj =           obj.loadDataForFileFormat_AfterAugust2021;
            obj.Tracking =  PMTrackingNavigation(obj.getTrackingFolder);

            try
                obj.Tracking = obj.Tracking.load;
            catch
                % if no file is available, simply use the "blank" tracking
            end


            obj.Tracking = obj.Tracking.setTrackingCellForTimeWithDriftByDriftCorrection(obj.DriftCorrection);

        end

        function version = detectVersionFromFileFormat(obj)


            if exist(obj.getPathOfMovieTrackingForSmallFile) == 2 
                   version = 'AfterAugust2021';
            elseif exist(obj.getPathOfMovieTrackingForSingleFile) == 2
                version = 'BeforeAugust2021';
            else
                version = '';

            end


        end

        function obj = loadDataForFileFormat_AfterAugust2021(obj)

            load(obj.getPathOfMovieTrackingForSmallFile, 'MovieTrackingInfo');

            obj.NickName  = MovieTrackingInfo.File.NickName         ;
            obj.MovieFolder = MovieTrackingInfo.File.MovieFolder   ;                % movie folder:
            obj.AttachedFiles =  MovieTrackingInfo.File.AttachedFiles     ;
            obj.AnnotationFolder = MovieTrackingInfo.File.AnnotationFolder   ;

            obj.DriftCorrection  =  MovieTrackingInfo.File.DriftCorrection     ;
            obj.Interactions = MovieTrackingInfo.File.Interactions        ;

            obj.StopDistanceLimit = MovieTrackingInfo.StopTracking.StopDistanceLimit            ;
            obj.MaxStopDurationForGoSegment =  MovieTrackingInfo.StopTracking.MaxStopDurationForGoSegment;    
            obj.MinStopDurationForStopSegment = MovieTrackingInfo.StopTracking.MinStopDurationForStopSegment  ;

            obj.ImageMapPerFile = MovieTrackingInfo.ImageMapPerFile        ;
            obj.TimeCalibration = MovieTrackingInfo.TimeCalibration         ;
            obj.SpaceCalibration = MovieTrackingInfo.SpaceCalibration        ;
            obj.Navigation =                MovieTrackingInfo.Navigation   ;  

            obj.TimeVisible = MovieTrackingInfo.MovieView.TimeVisible         ;
            obj.PlanePositionVisible = MovieTrackingInfo.MovieView.PlanePositionVisible  ;
            obj.ScaleBarVisible = logical(MovieTrackingInfo.MovieView.ScaleBarVisible        );
            obj.ScaleBarSize = MovieTrackingInfo.MovieView.ScaleBarSize         ;

            obj.CentroidsAreVisible =  MovieTrackingInfo.MovieView.CentroidsAreVisible  ;
            obj.TracksAreVisible = MovieTrackingInfo.MovieView.TracksAreVisible      ;
            obj.MasksAreVisible = MovieTrackingInfo.MovieView.MasksAreVisible        ;
            obj.ActiveTrackIsHighlighted = MovieTrackingInfo.MovieView.ActiveTrackIsHighlighted ;
            obj.CollapseAllTracking =  MovieTrackingInfo.MovieView.CollapseAllTracking    ;

            obj.CollapseAllPlanes =  logical(MovieTrackingInfo.MovieView.CollapseAllPlanes );

            obj.CroppingOn =  logical(MovieTrackingInfo.MovieView.CroppingOn            );
            obj.CroppingGate = MovieTrackingInfo.MovieView.CroppingGate      ;

            obj.ActiveChannel = MovieTrackingInfo.Channels.ActiveChannel  ;

            if isempty(MovieTrackingInfo.Channels.Channels)

            else
                obj.Channels = MovieTrackingInfo.Channels.Channels ;
            end


        end

        function obj =       loadDataForFileFormatBefore_August2021(obj)

         % control what is transferred to new object after loading from
            % file:
            fprintf('PMMovieTracking: Load from file.\n')
            assert(exist(obj.getPathOfMovieTrackingForSingleFile) == 2, 'File not found.')
            tic
            Data =              load(obj.getPathOfMovieTrackingForSingleFile, 'MovieAnnotationData');
            LoadedMovieTracking =        Data.MovieAnnotationData;

            fprintf('Loading took %5.1f seconds.\n', toc)

            tic 
            obj.ImageMapPerFile =           LoadedMovieTracking.getImageMapsPerFile;
            obj.DriftCorrection =           LoadedMovieTracking.getDriftCorrection;

            obj.Tracking =                  LoadedMovieTracking.getTracking;
            if isstruct(obj.Tracking) || isempty(obj.Tracking)
                obj.Tracking = PMTrackingNavigation(0,0);
            end


            fprintf('Setting properties and getting tracking took %5.1f seconds.\n', toc)

            tic
            obj.Interactions =              LoadedMovieTracking.getInteractions;
            if ~isempty(LoadedMovieTracking.Channels)
                obj.Channels =              LoadedMovieTracking.Channels  ;  
            end

            obj.Navigation =                LoadedMovieTracking.Navigation   ;        
            obj.TimeCalibration =           LoadedMovieTracking.TimeCalibration  ;  
            obj.SpaceCalibration =          LoadedMovieTracking.SpaceCalibration  ;  

            obj.DriftCorrection =           obj.DriftCorrection.setNavigation(obj.Navigation); % has to be after setting navigation
            if isempty(obj.DriftCorrection)
                obj.DriftCorrection =               PMDriftCorrection(0,0);
            end



        if ~obj.isMapped  
            obj =   obj.setPropertiesFromImageFiles;
        end

        obj.DriftCorrection =       obj.DriftCorrection.update;
        obj.DriftCorrection =       obj.DriftCorrection.setNavigation(obj.Navigation);

         fprintf('Setting interactions, channels, navigation, calibrations and drift correction took %5.1f seconds.\n', toc)


        obj.Tracking =              obj.Tracking.initializeWithDrifCorrectionAndFrame(obj.DriftCorrection, obj.Navigation.getMaxFrame);

        if isempty(obj.Interactions) || ~isa(obj.Interactions, 'PMInteractionsCapture')
            obj.Interactions =      PMInteractionsCapture;
            obj.Interactions =      obj.Interactions.setWith(obj);

        end

        obj = obj.setPathsThatDependOnAnnotationFolder;


        end

        function obj =       loadLinkeDataFromFile(obj)
            error('Method not supported anymore. Use load instead.')

        end

        function obj = save(obj)
            MovieTrackingInfo = obj.getStructureForStorage;
            tic

            save(obj.getPathOfMovieTrackingForSmallFile, 'MovieTrackingInfo')
            a = toc;
            fprintf('Saving of the movie-tracking file took %6.1f seconds.', a)

            obj.Tracking = obj.Tracking.saveBasic;

        end

        function MovieTrackingInfo = getStructureForStorage(obj)

            MovieTrackingInfo.File.NickName =           obj.NickName;
            MovieTrackingInfo.File.MovieFolder       =  obj.MovieFolder;                % movie folder:
            MovieTrackingInfo.File.AttachedFiles =      obj.AttachedFiles;
            MovieTrackingInfo.File.AnnotationFolder  =  obj.AnnotationFolder;

            MovieTrackingInfo.File.DriftCorrection  =   obj.DriftCorrection;
            MovieTrackingInfo.File.Interactions       = obj.Interactions;

            MovieTrackingInfo.StopTracking.StopDistanceLimit =              obj.StopDistanceLimit;
            MovieTrackingInfo.StopTracking.MaxStopDurationForGoSegment =    obj.MaxStopDurationForGoSegment;
            MovieTrackingInfo.StopTracking.MinStopDurationForStopSegment =  obj.MinStopDurationForStopSegment;

            MovieTrackingInfo.ImageMapPerFile =         obj.ImageMapPerFile;
            MovieTrackingInfo.TimeCalibration =         obj.TimeCalibration;
            MovieTrackingInfo.SpaceCalibration =        obj.SpaceCalibration;
            MovieTrackingInfo.Navigation =        obj.Navigation;


            MovieTrackingInfo.MovieView.TimeVisible =             obj.TimeVisible;
            MovieTrackingInfo.MovieView.PlanePositionVisible =    obj.PlanePositionVisible;
            MovieTrackingInfo.MovieView.ScaleBarVisible =         obj.ScaleBarVisible;
            MovieTrackingInfo.MovieView.ScaleBarSize =            obj.ScaleBarSize;

            MovieTrackingInfo.MovieView.CentroidsAreVisible =     obj.CentroidsAreVisible;
            MovieTrackingInfo.MovieView.TracksAreVisible =        obj.TracksAreVisible;
            MovieTrackingInfo.MovieView.MasksAreVisible =         obj.MasksAreVisible;
            MovieTrackingInfo.MovieView.ActiveTrackIsHighlighted =obj.ActiveTrackIsHighlighted;
            MovieTrackingInfo.MovieView.CollapseAllTracking =     obj.CollapseAllTracking;

            MovieTrackingInfo.MovieView.CollapseAllPlanes =       obj.CollapseAllPlanes;

            MovieTrackingInfo.MovieView.CroppingOn =              obj.CroppingOn;
            MovieTrackingInfo.MovieView.CroppingGate =            obj.CroppingGate;

             MovieTrackingInfo.Channels.ActiveChannel =            obj.ActiveChannel ;
              MovieTrackingInfo.Channels.Channels =          obj.Channels;



        end

        function  obj = saveMovieData(obj)
            error('Method not supported anymore. Use save instead.')
            fprintf('PMMovieTracking:@saveMovieData": ')
            if obj.UnsavedTrackingDataExist 
               obj =        obj.saveMovieDataWithOutCondition;
            else
                fprintf('Tracking data were already saved. Therefore no action taken.\n')
            end
        end

        function obj = saveMovieDataWithOutCondition(obj)
            error('Method not supported anymore. Use save instead.')
            fprintf('\nEnter PMMovieTracking:@saveMovieDataWithOutCondition:\n')
            fprintf('Get copy of PMMovieTracking object.\n')

            MovieAnnotationData =                obj;
            MovieAnnotationData.Tracking =       MovieAnnotationData.Tracking.removeRedundantData;

            save(obj.getPathOfMovieTrackingForSingleFile, 'MovieAnnotationData')
            fprintf('File %s was saved successfully.\n', obj.getPathOfMovieTrackingForSingleFile)
            obj =                               obj.setSavingStatus(false);

            fprintf('Exit PMMovieTracking:@saveMovieDataWithOutCondition.\n\n')

        end

        function obj = deleteFiles(obj)
           
            ListWithFiles = obj.getAllAnnotationPaths;
            
            ListWithFiles = ['Are you sure you want to delete the following files? This is irreversible.'; ListWithFiles];
            
           Answer =  questdlg(ListWithFiles);
          
           if strcmp(Answer, 'Yes')
                for index = 1 : length(ListWithFiles)
                    CurrentPath =   ListWithFiles{index};
                    if exist(CurrentPath) == 2
                        delete(CurrentPath);
                    elseif exist(CurrentPath) == 7
                        rmdir(CurrentPath);
                    end


                end
           end
           

        end 

        function obj=     renameMovieDataFile(obj, OldPath)

            if isequal(OldPath, obj.getPathOfMovieTrackingForSingleFile)

            else

                status =            movefile(OldPath, obj.getPathOfMovieTrackingForSingleFile);
                if status ~= 1
                    error('Renaming file failed.') 
                else
                    fprintf('File %s was renamed successfully to %s.\n', OldPath, obj.getPathOfMovieTrackingForSingleFile)
                end

                obj =      obj.setSavingStatus(false);
            end

        end

        function obj =    setSavingStatus(obj, Value)
            obj.UnsavedTrackingDataExist = Value;
        end

        function obj =    setNamesOfMovieFiles(obj, Value)
            obj.AttachedFiles =       Value;
        end

        function obj =      saveMetaData(obj, varargin)

         NumberOfArguments = length(varargin);
         switch NumberOfArguments

             case 1
                MetaDataString  =   obj.getMetaDataString;

                cd(varargin{1})
                [file, path] =               uiputfile([obj.getNickName, '_MetaDataString.text']);
                CurrentTargetFilename =      [path, file];
                if CurrentTargetFilename(1) == 0
                else
                    fprintf(fopen(CurrentTargetFilename, 'w'), '%s', MetaDataString);
                end


                if 1== 2 % this crashes the program to much text

                currentFigure =    figure;
                currentFigure.Units = 'normalized';
                currentFigure.Position = [0 0 0.8 0.8];

                textBox = uicontrol(currentFigure);
                textBox.Style = 'edit';
                textBox.Units = 'normalized';
                textBox.Position = [0 0 1 1 ];
                textBox.Max = 2;
                textBox.Min = 0;  

                textBox.String =  MetaDataString;

                end

         end

        end
    
        
    end
  
      
    methods % image map
        
         function obj = unmap(obj)
             error('Not allowed to unmap. Only remapping allowed. Use resetFromImageFiles.')
                obj.ImageMapPerFile =                   [];
         end
         
         function obj = resetFromImageFiles(obj)
             error('Not supported anymore. Use setPropertiesFromImageFiles instead.')
        
             
         end
        
        
    end
    
    methods (Access = private) % image map
        

         
        function Value = getImageMapsPerFile(obj)
            Value = obj.ImageMapPerFile; 
        end
        
        
        
        
    end
    
    methods
        
        function obj = setScaleBarSize(obj, Value)
            obj.ScaleBarSize = Value;
        end
         
        function Value = getScaleBarSize(obj)
            Value = obj.ScaleBarSize;
        end
        
        function interactions = getInteractions(obj)
            interactions = obj.Interactions;
        end
        
        function obj = updateWith(obj, Value)
          
            if ~isa(obj.Interactions, 'PMInteractionsCapture')
                obj.Interactions = PMInteractionsCapture;
            end
            
            obj.Interactions = obj.Interactions.setWith(Value);
            
        end
        
        function Value = getCollapseAllPlanes(obj)
            Value = obj.CollapseAllPlanes;
        end
        
        
        %% MasksAreVisible
         function obj = toggleMaskVisibility(obj)
            obj.MasksAreVisible = ~obj.MasksAreVisible;
        end
        
        function obj = setMaskVisibility(obj, Value)
            obj.MasksAreVisible = Value;
        end
        
       
        
        function Value = getMaskVisibility(obj)
            Value = obj.MasksAreVisible;
        end
        
        %% CentroidsAreVisible
        function obj = toggleCentroidVisibility(obj)
            obj.CentroidsAreVisible = ~obj.CentroidsAreVisible;
        end
        
        function obj = setCentroidVisibility(obj, Value)
            obj.CentroidsAreVisible = Value;
        end
        
        
        function Value = getCentroidVisibility(obj)
            Value = obj.CentroidsAreVisible;
        end
        
        %% TracksAreVisible
        function obj = toggleTrackVisibility(obj)
            obj.TracksAreVisible = ~obj.TracksAreVisible;
        end
        
        function obj = setTrackVisibility(obj, Value)
            obj.TracksAreVisible = Value;
        end
        
        function Value = getTrackVisibility(obj)
            Value = obj.TracksAreVisible;
        end
        
        %% UnsavedTrackingDataExist
        function status = getUnsavedDataExist(obj)
           status = obj.UnsavedTrackingDataExist; 
            
        end

        %% accessors:
      
        
          function obj = setTimeVisibility(obj, Value)
              obj.TimeVisible = Value;
          end
          
          function Visible = getTimeVisibility(obj)
             Visible = obj.TimeVisible;
          end
          
          function obj = hideTime(obj)
              obj.TimeVisible =     false;
          end
        
          function obj = showTime(obj)
            obj.TimeVisible =     true;
         end
        
          function obj = setPlaneVisibility(obj, Value)
             obj.PlanePositionVisible = Value;
          end
         
          function value = getPlaneVisibility(obj)
              value = obj.PlanePositionVisible;
          end
         
          function obj = hidePlane(obj)
              obj.PlanePositionVisible = false;
          end
        
          function obj = showPlane(obj)
              obj.PlanePositionVisible = true;  
          end
         
        
          %% scale-bar
          function obj = toggleScaleBarVisibility(obj)
             obj.ScaleBarVisible = ~obj.ScaleBarVisible; 
          end
          
          function obj = setScaleBarVisibility(obj, Value)
             obj.ScaleBarVisible = Value; 
          end
          
        
          
          function Value = getScaleBarVisibility(obj)
             Value = obj.ScaleBarVisible; 
          end
          
          
          %% hideScale
          function obj = hideScale(obj)
            obj.ScaleBarVisible =          false;
          end
        
          function obj = showScale(obj)
             obj.ScaleBarVisible =          tru;
         end
        

        %% setActiveTrackIsHighlighted
        function obj = setActiveTrackIsHighlighted(obj, Value)
           obj.ActiveTrackIsHighlighted = Value; 
        end
        
       
        
         function Value = getActiveTrackIsHighlighted(obj)
           Value = obj.ActiveTrackIsHighlighted ; 
        end
        
        %% other:
        function possibleActivities = getPossibleEditingActivities(obj)
            possibleActivities = obj.AllPossibleEditingActivities;
        end
        
        
           
        %% setNickName
        function [obj] =        setNickName(obj, String)
            obj.NickName =       String;

        end

       
   

       
        
        function name = getNickName(obj)
           name = obj.NickName;
            
        end

   
        
        %% setKeywords
           function obj =        setKeywords(obj, Value)
               if isempty(Value)
                  Value = 'Regular image'; 
               end
               
               if iscell(Value)
                  Value = Value{1,1}; 
               end
                obj.Keywords{1,1} =                   Value;
           end
          
           
           function keywords = getKeywords(obj)
               keywords = obj.Keywords; 
           end
        
          
       
        
        
         
        %% meta-data:
        function summary = getMetaDataSummary(obj)
            summary = PMImageFiles(obj.getPathsOfImageFiles).getMetaDataSummary;
        end
        
        function MetaDataString =   getMetaDataString(obj)
            myImageFiles =                          PMImageFiles(obj.getPathsOfImageFiles);
            MetaDataString =                        myImageFiles.getMetaDataString;
        end
        
        function StringOfTimeStamps = getTimeStamps(obj)
            
                TimeInSeconds=                obj.TimeCalibration.getRelativeTimeStampsInSeconds;

                TimeInMinutes=                TimeInSeconds / 60;
                MinutesInteger=               floor(TimeInMinutes);
                SecondsInteger=               round((TimeInMinutes- MinutesInteger)*60);
                SecondsString=                (arrayfun(@(x) num2str(x), SecondsInteger, 'UniformOutput', false));
                MinutesString=                (arrayfun(@(x) num2str(x), MinutesInteger, 'UniformOutput', false));
                StringOfTimeStamps=           cellfun(@(x,y) strcat(x, '''', y, '"'), MinutesString, SecondsString, 'UniformOutput', false);
          end
          
        function planeStamps = getPlaneStamps(obj) 
              PlanesAfterDrift =         obj.Navigation.getMaxPlane + max(obj.getAplliedPlaneShifts);
              planeStamps =             (arrayfun(@(x) sprintf('Z-depth= %i µm', int16((x-1) * obj.SpaceCalibration.getDistanceBetweenZPixels_MicroMeter)), 1:PlanesAfterDrift, 'UniformOutput', false))';;
        end
      
        function distance = getDistanceBetweenXPixels_MicroMeter(obj)
           distance = obj.SpaceCalibration.getDistanceBetweenXPixels_MicroMeter;
        end
            
        function string  = getActivePlaneStamp(obj)
             myPlaneStamps = obj.getPlaneStamps;
             string = myPlaneStamps{obj.getActivePlanes};
        end
         
    
         
        function string  = getActiveTimeStamp(obj)
              myTimeStamps = obj.getTimeStamps;
             string = myTimeStamps{obj.getActiveFrames};
        end
        
       function InfoText =              getMetaDataInfoText(obj)

               dimensionSummaries =          obj.Navigation.getDimensionSummary;
               spaceCalibrationSummary =    obj.SpaceCalibration.getSummary;

               dataPerMovie = cell(length(obj.getLinkedMovieFileNames), 1);
               for index = 1: length(obj.getLinkedMovieFileNames)
                   textForCurrentMovei = [obj.getLinkedMovieFileNames{index}; dimensionSummaries{index}; spaceCalibrationSummary{index}; ' '];
                   dataPerMovie{index, 1} = textForCurrentMovei;

               end
                InfoText =                                          vertcat(dataPerMovie{:});
       end
           
                    
     

      

        %% getLastTrackedFrame      
        function lastOrFirstTrackedFrame =                         getLastTrackedFrame(obj, parameter)
                % from a contiguous stretch of tracked frames: get first or last frame in this contiguous sequence;
                if ~ismember(obj.getActiveFrames, obj.Tracking.getFrameNumbersForTrackID(obj.getIdOfActiveTrack)) % perform this analysis only when the current position is tracked;
                      lastOrFirstTrackedFrame = NaN;
                else
                    AllFramesOfActiveTrack = obj.Tracking.getFrameNumbersForTrackID(obj.getIdOfActiveTrack);
                     switch parameter
                        case 'up' 
                                lastOrFirstTrackedFrame =      PMVector(AllFramesOfActiveTrack).getLastValueOfGaplessIntegerSeriesStartingFromValue(obj.getActiveFrames);
                        case 'down'
                            lastOrFirstTrackedFrame =          PMVector(AllFramesOfActiveTrack).getFirstValueOfGaplessIntegerSeriesStartingFromValue(obj.getActiveFrames);
                         otherwise
                             error('Input not supported') 
                    end
                    
                end   
        end
        
      
        
        %% getDataType
       function DataType =                                  getDataType(obj)
           if obj.Navigation.getMaxFrame > 1
               DataType =               'Movie';               
           elseif obj.Navigation.getMaxPlane > 1
               DataType =               'ZStack';
           elseif obj.Navigation.getMaxPlane == 1
                DataType =               'Snapshot';
           else
               DataType =               'Unspecified datatype';
           end

       end
           
       %% imageMatchesDimensions
       function value = imageMatchesDimensions(obj, Image)
           [rows, columns, planes] =                  obj.getImageDimensions;
           value(1) =   size(Image, 1) == rows;
           value(2) =   size(Image, 2) == columns;
           value(3) =   size(Image, 3) == planes;
           value =  min(value);  
       end
       
       
         
          
         function imageSource = getImageSource(obj)
             imageSource = PMImageSource(obj.ImageMapPerFile, obj.Navigation);
         end
         
         function AplliedPlaneShifts = getMaxAplliedColumnShifts(obj)
            AplliedPlaneShifts =  max(getAplliedColumnShifts(obj));
         end 
         
     

      
       
        
      
      
        
         
        
       
       
        
    
        
       
      
            
        
        %% geometry:
        
       
     
     
        
       

      

        %% setFocusOnActiveTrack
        function obj =       setFocusOnActiveTrack(obj)
            obj =   obj.setSelectedPlaneTo(obj.getPlaneOfActiveTrack); % direct change of model:
            obj =   obj.moveCroppingGateToActiveMask;
        end
        
        function [obj] =            setSelectedPlaneTo(obj, selectedPlanes)
            if isnan(selectedPlanes)

            else
                 obj.Navigation =        obj.Navigation.setActivePlanes(selectedPlanes);
            end

        end
        
        
        function planeOfActiveTrack =            getPlaneOfActiveTrack(obj)
            [~, ~, planeOfActiveTrack ] =       obj.addDriftCorrection( 0, 0, obj.Tracking.getPlaneOfActiveTrackForFrame(obj.getActiveFrames));
            planeOfActiveTrack =                round(planeOfActiveTrack);
        end
        
       
       
     
       
         
       
         
    end
    
    methods % tracking
        
        
        
        %% mediate tracking
        function obj = performTrackingMethod(obj, Value)
            try
                if ismethod(obj.Tracking, Value)
                     obj.Tracking =      obj.Tracking.(Value);
                end
            
               
             catch ME
                throw(ME)
            end
        end
        
        function obj = setTrackingAnalysis(obj)
            obj.Tracking =      obj.Tracking.setTrackingAnalysis(obj.getTrackingAnalysis);
        end
        
        function obj = deleteAllTracks(obj)
             obj.Tracking =     PMTrackingNavigation();
                obj.Tracking =     obj.Tracking.initializeWithDrifCorrectionAndFrame(obj.DriftCorrection, obj.getMaxFrame);
        end
        
        function obj = performAutoTrackingOfExistingMasks(obj)
             obj.Tracking =     obj.Tracking.autTrackingProcedure(obj.getTrackingAnalysis);
        end
        
        
        %% mergeActiveTrackWithTrack
        function obj = mergeActiveTrackWithTrack(obj, IDOfTrackToMerge)
            obj.Tracking =      obj.Tracking.splitTrackAtFrame(obj.getActiveFrames-1, obj.getIdOfActiveTrack, obj.Tracking.generateNewTrackID);
            obj.Tracking =      obj.Tracking.mergeTracks([obj.getIdOfActiveTrack,    IDOfTrackToMerge]);
        end
        
     
        
    
        function obj = setNavigation(obj, Value)
            obj.Navigation =        Value;
            obj.DriftCorrection =   obj.DriftCorrection.setNavigation(Value);
        end
        
        function obj = set.Navigation(obj,Value)
             assert(isa(Value,'PMNavigationSeries') && length(Value) == 1, 'Wrong input format.')
            obj.Navigation =  Value;
        end
        
        function thresholds = getDefaultThresholdsForAllPlanes(obj)
            thresholds(1: obj.getMaxPlane, 1) = 30;
            
        end
        
        
        
        %% testForExistenceOfTracking
        function Tracking =             testForExistenceOfTracking(obj)
           if isempty(obj.Tracking)
                Tracking =           false;
           else
                Tracking=            obj.Tracking.testForExistenceOfTracks;
           end
        end
          
       %% minimizeMasksOfActiveTrackAtFrame
       function obj = minimizeMasksOfActiveTrackAtFrame(obj, FrameIndex)
           
           obj.Tracking =       obj.Tracking.minimizeActiveTrack;
           
           
          
            obj =               obj.setFrameTo(SourceFrames(FrameIndex));
            obj =               obj.setFocusOnActiveTrack;
            
                 
       end
       
       
       
    
           
        %% getTrackingAnalysis:
      
        
        %% updateMaskOfActiveTrackByAdding:
        function [obj] =                                updateMaskOfActiveTrackByAdding(obj, yList, xList, plane)
            if isempty(yList) || isempty(xList)
            else
                pixelListToAdd =              [yList,xList];
                pixelListToAdd(:,3) =         plane;
                pixelList_AfterAdding =       unique([obj.Tracking.getPixelsOfActiveMaskFromFrame(obj.getActiveFrames); pixelListToAdd], 'rows');
                mySegementationCapture =      PMSegmentationCapture(pixelList_AfterAdding, 'Manual');
                obj =                        obj.resetActivePixelListWith(mySegementationCapture);
            end
            
        end
     
      
        
        function obj = setPreventDoubleTracking(obj, Value, Value2)
            obj.Tracking = obj.Tracking.setPreventDoubleTracking(Value, Value2);
        end
        
        
        
        %% getPixelsFromActiveMaskAfterRemovalOf:
        
          function pixelList_Modified =        getPixelsFromActiveMaskAfterRemovalOf(obj, pixelListToRemove)
            
              if ~(isempty(pixelListToRemove(:,1)) || isempty(pixelListToRemove(:,2)))  
                    pixelList_Original =        obj.Tracking.getPixelsOfActiveMaskFromFrame(obj.getActiveFrames);
                    deleteRows =             ismember(pixelList_Original(:,1:2), [pixelListToRemove(:,1) pixelListToRemove(:,2)], 'rows');
                    pixelList_Modified =        pixelList_Original;
                    pixelList_Modified(deleteRows,:) =               [];
              end
        end
  
        function numberOfFrames =       getUniqueFrameNumberFromImageMap(obj, ImageMap)
            ColumnWithTime =       10;
            numberOfFrames =       length(unique(cell2mat(ImageMap(2:end,ColumnWithTime))));   
        end

        
      
        
        
        %% get segmentation of active track:
        function [segmentationOfTrack] =                    getUnfilteredSegmentationOfTrack(obj, TrackID)
            segmentationOfTrack =       obj.Tracking.getSegmentationOfAllWithTrackID(TrackID);   
        end
        
     
     

       

      

        %% getGapFrames
          function [GapFrames] =                  getGapFrames(obj, Parameter)
              
                switch Parameter
                    case 'forward'
                    
                        GapFrames =    obj.getActiveFrames + 1 : obj.getLastUntrackedFrameAfterActiveFrame;
                        fprintf('Looking for gap immediately after active frame %i.', obj.getActiveFrames)
                        if isempty(GapFrames)
                            fprintf('There is no gap.\n')
                        else
                            fprintf('There is a gap between frames %i and %i.\n', min(GapFrames), max(GapFrames))
                        end
                             
                    case 'backward'
                        GapFrames =      obj.getActiveFrames - 1 : -1 : obj.firstUntrackedFrame;
                        fprintf('Looking for gap immediately before active frame %i.', obj.getActiveFrames)
                        if isempty(GapFrames)
                            fprintf('There is no gap.\n')
                        else
                            fprintf('There is a gap between frames %i and %i.\n', max(GapFrames), min(GapFrames))
                        end
                end
                
                  
                            
          end
          
          
         function lastUntrackedFrame = getLastUntrackedFrameAfterActiveFrame(obj)

            FramesOfActiveTrack  =          obj.Tracking.getFramesOfActiveTrack;

            Index = find(FramesOfActiveTrack > obj.getActiveFrames,  1, 'first');
            if isempty(Index)
                lastUntrackedFrame =        obj.Navigation.getMaxFrame;
            elseif FramesOfActiveTrack(Index) == obj.getActiveFrames + 1
                lastUntrackedFrame = zeros(0, 1);
            else
                lastUntrackedFrame =        FramesOfActiveTrack(Index) - 1;
            end

        end
        
            
        function [firstUntrackedFrame, lastUntrackedFrame] =                getFirstLastContiguousUntrackedFrame(obj)
              lastUntrackedFrame = obj.getLastUntrackedFrameAfterActiveFrame;
              firstUntrackedFrame = obj.firstUntrackedFrame;
        end
          

     
        
         function firstUntrackedFrame = firstUntrackedFrame(obj)
             
             
            FramesOfActiveTrack  =              obj.Tracking.getFramesOfActiveTrack;
            % get first untracked frame:
            BeforeFirstUntrackedFrame =             find(FramesOfActiveTrack < obj.getActiveFrames,  1, 'last');
            if isempty(BeforeFirstUntrackedFrame)
                firstUntrackedFrame =          1;
            else
                firstUntrackedFrame =          FramesOfActiveTrack(BeforeFirstUntrackedFrame) + 1;
            end
             
         end
        
        
        
      
   
           
        %% get track ID where next frame has no mask:
        
        function trackIDsWithNoFollowUp =                                 getTrackIDsWhereNextFrameHasNoMask(obj)

            if obj.getActiveFrames >= obj.Navigation.getMaxFrame 
                trackIDsWithNoFollowUp =                                  zeros(0,1);
            else                
                TrackIDsOfNextFrame =                                   obj.Tracking.getTrackIDsOfFrame(obj.getActiveFrames + 1);
                trackIDsWithNoFollowUp =                                setdiff(obj.getTrackIDsOfCurrentFrame, TrackIDsOfNextFrame);
            end
            
        end
        
        function trackIDs =                 getTrackIDsOfCurrentFrame(obj)
            TrackDataOfCurrentFrame =       obj.getTrackDataOfCurrentFrame;
            trackIDs =                      obj.Tracking.getTrackIDsFromSegmentationList(TrackDataOfCurrentFrame);
        end
        
        function TrackDataOfCurrentFrame =                  getTrackDataOfCurrentFrame(obj)
                TrackDataOfCurrentFrame =       obj.getTrackDataOfFrame(obj.getActiveFrames);
        end
          
        function segmentationOfCurrentFrame =              getTrackDataOfFrame(obj, FrameNumber)   
                segmentationOfCurrentFrame = obj.Tracking.getSegmentationOfFrame(FrameNumber);
        end

        %% unmap:
       
        
         %%
         
      
        
    end
     
    methods % verify user input
        
        function  [rowFinal, columnFinal, planeFinal] =                         verifyCoordinates(obj, rowFinal, columnFinal,planeFinal)
            rowFinal =      obj.verifyYCoordinate(rowFinal);
            columnFinal =   obj.verifyXCoordinate(columnFinal);
            planeFinal =    obj.verifyZCoordinate(planeFinal);

        end

    end
    
    methods  (Access = private) % verify user input
         
        function rowFinal = verifyYCoordinate(obj, rowFinal)
            if     rowFinal>=1 && rowFinal<=obj.Navigation.getMaxRow 
            else
                rowFinal = NaN;
            end
        end

        function columnFinal = verifyXCoordinate(obj, columnFinal)
            if    columnFinal>=1 && columnFinal<=obj.Navigation.getMaxColumn 
            else
              columnFinal = NaN;
            end
        end

        function planeFinal = verifyZCoordinate(obj, planeFinal)
            if    planeFinal>=1 && planeFinal<=obj.Navigation.getMaxPlane
            else
              planeFinal = NaN;
            end
        end
           
               
         
     end
    
    methods % load images from file:
       
        function TempVolumes = loadImageVolumesForFrames(obj, numericalNeededFrames)
            TempVolumes = obj.loadImageVolumesForFramesInternal(numericalNeededFrames);
        end
        
        function paths = getPathsOfImageFiles(obj)
            % cell-string to files for each image:
             if isempty(obj.getMovieFolder)
                 paths = '';
             else
                 paths = cellfun(@(x) [ obj.getMovieFolder '/' x], obj.getLinkedMovieFileNames, 'UniformOutput', false);
             end
            
        end
        
        function movieFolder = getMovieFolder(obj)
              movieFolder = obj.MovieFolder;   
        end
         
         function AllConnectionsOk = checkConnectionToImageFiles(obj)
             AllConnectionsOk = obj.checkWhetherAllImagePathsCanBeLinked;
         end
         
        
        
    end
    
    methods (Access = private) % load images from file
        
         function number = getNumberOfOpenFiles(obj)
             number = length(fopen('all'));
         end
         

            function TempVolumes = loadImageVolumesForFramesInternal(obj, ListOfFramesThatShouldBeLoaded)
                
                  TempVolumes =                   cell(length(ListOfFramesThatShouldBeLoaded), 1);
                  if obj.checkWhetherAllImagePathsCanBeLinked 
                         obj =   obj.replaceImageMapPaths;                         
                         TempVolumes =        ...
                             arrayfun(@(x) obj.getImageVolumeForFrame(x), ListOfFramesThatShouldBeLoaded, 'UniformOutput', false);
                  else
                      warning('Image files cannot be accessed. Image files are not updated right now. It is still possible to navigate the tracked cells without image information.')

                  end  
            end

            function obj =    replaceImageMapPaths(obj)

             
                PointerColumn =                     3;
                ListWithPathsToImageFiles = obj.getPathsOfImageFiles;
                for CurrentMapIndex = 1 : obj.getNumberOfLinkedMovieFiles
                    obj.ImageMapPerFile{CurrentMapIndex, 1}( 2 : end, PointerColumn) =       {ListWithPathsToImageFiles{CurrentMapIndex}};
                end

                
                 
            end
          
            
            
         function AllConnectionsOk = checkWhetherAllImagePathsCanBeLinked(obj)
             
                RetrievedPointers =         obj.getFreshPointersOfLinkedImageFilesInternal;
                
                ConnectionFailureList =     arrayfun(@(x) isempty(fopen(x)), RetrievedPointers);
                AllConnectionsOk =          ~max(ConnectionFailureList);
                
                RetrievedPointers(RetrievedPointers == -1) = [];
                if ~isempty(RetrievedPointers)
                    arrayfun(@(x) fclose(x), RetrievedPointers);

                end
                
         end

         function pointers = getFreshPointersOfLinkedImageFilesInternal(obj)

                if isempty( obj.getPathsOfImageFiles)
                    pointers =  '';
                else
                    pointers =        cellfun(@(x) fopen(x), obj.getPathsOfImageFiles);
                end

         end
         
        function ProcessedVolume = getImageVolumeForFrame(obj, FrameNumber)
            tic
            
                settings.SourceChannels =          [];
                settings.TargetChannels =          [];
                settings.SourcePlanes =            [];
                settings.TargetPlanes =            [];
                settings.TargetFrames =            1;
                settings.SourceFrames =         FrameNumber;
                
                VolumeReadFromFile =           PMImageSource(obj.ImageMapPerFile, obj.Navigation, settings).getImageVolume;
                ProcessedVolume =              PM5DImageVolume(VolumeReadFromFile).filter(obj.getReconstructionTypesOfChannels).getImageVolume;
                
                Time =  toc;
                fprintf('PMMovieTracking: @getImageVolumeForFrame. Loading frame %i from file. Duration: %8.5f seconds.\n', FrameNumber, Time)

        end
        
     
        
        
        
        
    end
    
    methods % GETTERS image map
        
          function imageMapOncell =        getSimplifiedImageMapForDisplay(obj)
               %% don't understand this one:
               function result =    convertMultiCellToSingleCell(input)
               
                   Dim =    size(input,1);
                   if Dim > 1
                       result = '';
                       for index = 1 : Dim
                           result = [result ' ' num2str(input(index))];
                       end
                   else
                       result = input;
                   end
               end
               
                myImageMap =        obj.getImageSource.getImageMap;
                imageMapOncell =    cellfun(@(x) convertMultiCellToSingleCell(x), myImageMap(2:end,:), 'UniformOutput', false);

          end
           

           
        
        
    end
    
    methods % GETTERS image content
       
           %% getCurrentFrame
        function [currentFrame] =        getCurrentFrame(obj) % this seems old and not functional anymore;
            currentFrame = obj.convertImageVolumeIntoRgbImageInternal;
        end
        
        function  rgbImage = convertImageVolumeIntoRgbImage(obj, SourceImageVolume)
            rgbImage = obj.convertImageVolumeIntoRgbImageInternal(SourceImageVolume);
        end
        
         function filtered = filterImageVolumeByActivePlanes(obj, Volume)
                filtered =    Volume(:, :, obj.getListOfVisiblePlanesWithoutDriftCorrection, :, :);
            end
        
    end
    
    methods (Access = private) % image processing for rgb-image presentation;
        
           function rgbImage = convertImageVolumeIntoRgbImageInternal(obj, SourceImageVolume)
               
                if isempty(SourceImageVolume)
                     rgbImage = 0;

                else

                        ImageVolume_Source = obj.filterImageVolumeByActivePlanes(SourceImageVolume);
                        
                        myRgbImage =    PMRGBImage(...
                                                ImageVolume_Source, ...
                                                obj.getIndicesOfVisibleChannels, ...
                                                obj.getIntensityLowOfVisibleChannels, ...
                                                obj.getIntensityHighOfVisibleChannels, ...
                                                obj.getColorStringOfVisibleChannels ...
                                                );

                        rgbImage =      myRgbImage.getImage;

                end

           end
            
           
            
            function VisiblePlanesWithoutDriftCorrection = getListOfVisiblePlanesWithoutDriftCorrection(obj)

                if obj.getDriftCorrectionStatus
                     VisiblePlanesWithoutDriftCorrection =      obj.removeDriftCorrectionFromPlaneList(obj.getListOfVisiblePlanesWithDriftCorrection);
                     
                else
                    VisiblePlanesWithoutDriftCorrection =       obj.getListOfVisiblePlanesWithDriftCorrection;
                    
                end


            end
            
            function PlanesWithoutDrift = removeDriftCorrectionFromPlaneList(obj, PlanesWithDrift)
                PlanesWithoutDrift =                            PlanesWithDrift - obj.getAplliedPlaneShiftsForActiveFrames;
                PlanesWithoutDrift(PlanesWithoutDrift < 1) =      [];
                PlanesWithoutDrift(PlanesWithoutDrift > obj.Navigation.getMaxPlane) = [];
            end

            function planesToBeShown = getListOfVisiblePlanesWithDriftCorrection(obj)
                switch obj.CollapseAllPlanes
                    case 1
                      planesToBeShown =     1 : obj.getMaxPlaneWithAppliedDriftCorrection;
                    otherwise
                      planesToBeShown = obj.getActivePlanes;
                end
            end

    end
    
    methods (Access = private)
        
        function complete = checkCompletenessOfNavigation(obj)
            if isempty(obj.Navigation.Navigations)
                complete = false;
            else
                complete = true;
            end
            
        end
        

        %% get planes as in source (i.e. without drift correction):
       

    
        function obj = setChannelsToDefault(obj)
            obj = obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);
        end
                    
        function obj = setImageMapDependentProperties(obj)


          end
        
        %% get filenames from Pic folder:
        function [ListWithFileNamesToAdd] =         extractFileNameListFromFolder(obj, UserSelectedFileNames)    
            
            if isempty(obj.getMovieFolder)
                ListWithFileNamesToAdd =           '';
            else
                 PicFolderObjects =                      (cellfun(@(x) PMImageBioRadPicFolder([obj.getMovieFolder x]), UserSelectedFileNames, 'UniformOutput', false))';
                ListWithFiles =                         cellfun(@(x) x.FileNameList(:,1), PicFolderObjects,  'UniformOutput', false);
                ListWithFileNamesToAdd =                vertcat(ListWithFiles{:});
            end
               
        end
           
        
      
          
        
         
    end
          
end