classdef PMMovieController < handle
    %PMMOVIECONTROLLER manages visual representation of linked PMMovieTrackingData;
    %   use key short-cuts to navigate and annotated active movie;
    % has a cache of loaded images to facilitate rapid tracking to movie-sequences;
    

    properties (Access = private) % data-source and influences on model;
        LoadedMovie
        MaskLocalizationSize =                  5; % info for segmentation (this could potentially be expanded or moved to MovieTracking

    end
    
    properties (Access = private) % filemanagement
        InteractionsFolder
        ExportFolder
        
    end
    
    properties (Access = private) % data-cash
        LoadedImageVolumes  
        DefaultNumberOfLoadedFrames =           40
    end
    
    properties (Access = private) % relevant for viewer
        
        Views 
        TrackingAutoTrackingController =        PMTrackingNavigationAutoTrackController
        TrackingNavigationEditViewController =  PMTrackingNavigationEditViewController
        AutoCellRecognitionController
        
        MaskColor =                             [NaN NaN 150]; % some settings for how 
        
    end
    
    properties (Access = private) % user input
        
        MouseAction =                           'No action';
        
        PressedKeyValue 
        MouseDownRow =                          NaN
        MouseDownColumn =                       NaN
        MouseUpRow =                            NaN
        MouseUpColumn =                         NaN
        
    end
    
    properties (Access = private)
       % help for interaction analysis
       InteractionImageVolume
        
    end
    
    methods % initialziation
        
        function obj =          PMMovieController(varargin)
            % PMMOVIECONTROLLER allows construction of movie-controller with 1 and 2 arguments;
            % 1 argument: 
            %   option 1: PMImagingProjectViewer, no data, but setup all views;
            %   option 2: PMMovieTracking
            % 2 arguments: 
            %    1: PMImagingProjectViewer;
            %    2: PMMovieTracking;
             switch length(varargin)

                    case 1 % only connected movies
                        
                        assert(isscalar(varargin{1}), 'Wrong input.')

                        switch class(varargin{1})
                            
                            case 'PMImagingProjectViewer'
                                obj = obj.setViewsByProjectView(varargin{1});
                                
                            case 'PMMovieControllerView'
                                
                                obj.Views =        varargin{1};
                                obj.Views =        setFigure(obj.Views, varargin{1}.Figure);  
                                
                             case 'PMMovieTracking'
                                 obj.LoadedMovie =                                           varargin{1};
                                
                                
                                
                            otherwise
                                error('Input not supported.')
                             
                                


                        end


                       

                    case 2 % connected views and movie
                       
                        assert(isscalar(varargin{1}) && isscalar(varargin{2}), 'Wrong input.')
                        
                        switch class(varargin{1})
                            
                             case 'PMImagingProjectViewer'
                                obj = obj.setViewsByProjectView(varargin{1});
                                
                            
                            case 'PMMovieControllerView'
                                obj.Views =       varargin{1};
                                obj.Views =       setFigure(obj.Views, varargin{1}.Figure); 
                                
                            otherwise
                                error('Wrong input.')
                                
                                
                        end
                        
                         switch class(varargin{2})
                             
                             case 'PMMovieTracking'
                                 obj.LoadedMovie =                                           varargin{2};
                             otherwise
                                 error('Wrong input.')
                         end
                             
                       
             end
                
              obj =   obj.setCallbacks;
              

                if ~isempty(obj.LoadedMovie) % this will slow down changes between movies: check if this is necessary or introduce some check to avoid it if not needed;
                   % obj    =                obj.emptyOutLoadedImageVolumes; 
                   % obj.LoadedMovie =       obj.LoadedMovie.setImageMapDependentProperties;
                end



        end

        function set.LoadedMovie(obj, Value)
            assert(isa(Value, 'PMMovieTracking') && isscalar(Value), 'Wrong argument type.')
            obj.LoadedMovie = Value;
        end

        function set.Views(obj, Value)
            assert(isa(Value, 'PMMovieControllerView') && isscalar(Value), 'Wrong input.')
            obj.Views = Value;
        end

        function set.ExportFolder(obj, Value)
            assert(ischar(Value), 'Wrong input.')
            obj.ExportFolder = Value;

        end

        function set.InteractionsFolder(obj, Value)
            assert(ischar(Value), 'Wrong input.')
            obj.InteractionsFolder = Value;

        end
        
        function set.LoadedImageVolumes(obj, Value)
            assert(iscell(Value) && isvector(Value), 'Wrong input.')
            if isempty(obj.LoadedMovie)
                assert(isempty(Value), 'Wrong input.')
                
            else
                assert(length(Value) == obj.LoadedMovie.getMaxFrame, 'Wrong input.')
                
                
            end

            obj.LoadedImageVolumes = Value;
            
        end
        
        
        

    end
    
    methods (Access = private) % intialization
        
        function obj = setViewsByProjectView(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMImagingProjectViewer'), 'Wrong input.')
            
            
            obj.Views =         Value.getMovieControllerView;
            obj.Views =         setFigure(obj.Views, Value.getFigure);   

            obj.Views =        setTrackingViews(obj.Views, Value.getTrackingViews.ControlPanels);
            obj.Views.changeAppearance;
            obj.Views.disableAllViews;

            obj.Views =        deleteAllTrackLineViews(obj.Views);

            
        end
        
        
    end
    
    methods % summary
        
        function obj = showSummary(obj)
            
            fprintf('\n*** This PMMovieController object mediates graphical display of movie data (original and annotated).\n')
            fprintf('\nThe following user inputs are currently registered:\n')
            fprintf('Mouse action = "%s".\n', obj.MouseAction)
            fprintf('Pressed key value = "%s".\n', obj.PressedKeyValue)
            fprintf('Mouse down row = "%6.2f".\n', obj.MouseDownRow)
            fprintf('Mouse down colun = "%6.2f".\n', obj.MouseDownColumn)
            fprintf('Mouse up row = "%6.2f".\n', obj.MouseUpRow)
            fprintf('Mouse up column = "%6.2f".\n', obj.MouseUpColumn)
            
            fprintf('\nDefault number frames to load is "%i". (This number of frames +/- current frame are loaded when the forward-press button initiated the interaction.\n', obj.DefaultNumberOfLoadedFrames)

            fprintf('\nThe following movie-tracking is the data-source for the MovieController:\n')
            obj.LoadedMovie = obj.LoadedMovie.showSummary;
            
        end
        
        function obj = exportCurrentFrameAsImage(obj)
                Image =         frame2im(getframe(obj.getViews.getMovieAxes));
                exportImageToExportFolder(obj, Image);
            
        end
        
        function [Folder, File] = exportImageToExportFolder(obj, Image, varargin)
             
            switch length(varargin)
               
                case 0
                    Pre = '';
                case 1
                    Pre = ['No_', num2str(varargin{1}), '_'];
                  
                
            end
            
            Folder = obj.ExportFolder;
            File =  [Pre, obj.getNickName, '_', PMTime().getCurrentTimeString, '.jpg'];
                FileName =      [Folder, '/', File];

                imwrite(Image, FileName)
            
        end
        
    end
    
    methods % setter tracking
        
        function obj = setSpaceAndTimeLimits(obj, Space, TimeMax, TimeMin)
            obj.LoadedMovie = obj.LoadedMovie.setSpaceAndTimeLimits(Space, TimeMax, TimeMin);
        end
        
        function obj = toggelListWithTrackIDs(obj, TrackIdsToToggle, Gaps, ForwardBackward)

            [SelectedTrackId , Row]=   obj.selectTrackIdForTogglingFromList(TrackIdsToToggle);

            assert(~isempty(SelectedTrackId), 'Could not find target track Id.')

            obj =              obj.setActiveTrackTo(SelectedTrackId); 
            if ~isempty(Gaps)

                switch ForwardBackward
                    case 'Forward'
                        Position = min(Gaps{Row}) - 1;
                        
                    case 'Backward'
                        Position = max(Gaps{Row}) + 1;
                        
                end

                obj =      obj.focusOnActiveTrackAtFrame(Position);

            end

            drawnow 
          

        end
        
        function obj = trackGapsForAllTracks(obj, Value)
            [Gaps, TrackIds]=     obj.(['getLimitsOfUnfinished', Value, 'Gaps']);
            for TrackIndex = 1 : length(TrackIds)
                [StartFrames, EndFrames]=   obj.(['get', Value, 'TrackingFramesFromGapLimits'])(Gaps{TrackIndex});
                if ~isnan(StartFrames)
                    obj =     obj.setActiveTrackTo(TrackIds(TrackIndex)); 
                    obj =     obj.focusOnActiveTrackAtFrame(StartFrames(1));
                    obj =     obj.autoTrackCurrentCellForFrames(StartFrames, EndFrames);
                end
            end
            obj =           obj.saveMovie;
        end
        
        function obj =  setActiveTrackTo(obj, Input)  
          
            Type = class(Input);
            switch Type
             case 'double'
                 SelectedTrackIDs = Input;
                 
             case 'char'
                 switch Input
                     case 'byMousePositition'
                         SelectedTrackIDs = obj.getTrackIDFromMousePosition;
                     case 'firstForwardGapInNextTrack'
                          obj = obj.toggleTrackForwardGapsIgnoreComplete;
                     case 'firstForwardGapInNextUnfinishedTrack'
                         obj = obj.toggleTrackForwardGaps;
                     case 'backWardGapInNextUnfinishedTrack'
                         obj = obj.toggleTrackBackwardGaps;
                     case 'nextUnfinishedTrack'
                          obj = obj.toggleUnfinishedTracks(Value);
                     otherwise
                        error('Wrong input.')
                 end

             otherwise
                 error('Wrong input.')
            end

            assert(isnumeric(SelectedTrackIDs) && isscalar(SelectedTrackIDs), 'Wrong input.')

            obj.LoadedMovie =       obj.LoadedMovie.setActiveTrackWith(SelectedTrackIDs);
            
            obj =                   obj.updateAllViewsThatDependOnActiveTrack;
            

            obj.TrackingNavigationEditViewController =     obj.TrackingNavigationEditViewController.resetForActiveTrackWith(obj.LoadedMovie.getTracking);


        end

    end
    
    methods (Access = private) % track line views
        
              function obj =                   tracking_updateActiveMaskByButtonClick(obj)
                  % UPDATEACTIVEMASKBYBUTTONCLICK: create mask of active track based on mouse click;
                  % mouse click selecs pixel that serves as threshold for detecting mask;
                  % mask is stored in PMMovieTracking and views are updated;
                   obj.LoadedMovie =  obj.LoadedMovie.setPreventDoubleTracking(false, [0.5 0.5 1]);

                    [rowPos, columnPos, planePos, ~] =   obj.getCoordinatesOfCurrentMousePosition;
                    if ~isnan(rowPos)

                        obj =                       obj.highlightMousePositionInImage;
                        mySegmentationObject =      PMSegmentationCapture(obj, [rowPos, columnPos, planePos, obj.LoadedMovie.getActiveChannelIndex]);

                        try 
                            mySegmentationObject =      mySegmentationObject.generateMaskByClickingThreshold;
                        catch E
                            throw(E) 
                        end


                        if mySegmentationObject.getActiveShape.testShapeValidity
                            obj.LoadedMovie =   obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);  
                                obj =                               obj.setTrackViews;
                            obj =               obj.updateAllViewsThatDependOnActiveTrack;

                        else
                            fprintf('Button click did not lead to recognition of valid cell. No action taken.')
                        end


                    end

                    figure(obj.Views.getFigure)
                
              end
              
              
            function obj = tracking_setSelectedTracks(obj, Value)
                Type = class(Value);
                switch Type
                    case 'char'
                        switch Value
                            case 'byMousePosition' 
                                    obj =         obj.resetSelectedTracksWithTrackIDs(obj.getTrackIDFromMousePosition);
                                    
                            case 'all'
                                    obj.LoadedMovie =         obj.LoadedMovie.selectAllTracks;
                                    obj =                    obj.updateAllViewsThatDependOnSelectedTracks;
                                         obj =                               obj.setTrackViews;
                            otherwise
                                error('Input not supported.')
                        end
                        
                    case 'double'
                        
                    otherwise
                        
                        error('Wrong input.')
                
                end
                
                
            end
            
          function obj =      resetSelectedTracksWithTrackIDs(obj, TrackIds)
                obj.LoadedMovie =  obj.LoadedMovie.setSelectedTrackIdsTo(TrackIds);
                obj =                       obj.updateAllViewsThatDependOnActiveTrack;
          end
             
          
            
            function obj = tracking_addSelectedTracks(obj, Value)
                Type = class(Value);
                switch Type
                    case 'char'
                        switch Value
                            case 'byMousePosition' 
                                    obj =         obj.addToSelectedTracksTrackIDs(obj.getTrackIDFromMousePosition);
                            
                            otherwise
                                error('Input not supported.')
                        end
                        
                       
                    otherwise
                        
                        error('Wrong input.')
                
                end
                
                
            end
            
             
             
        
        
    end
    
    methods (Access = private) % tracking
          
          function [obj] =                   tracking_removeHighlightedPixelsFromActiveMask(obj)             
                [UserSelectedY, UserSelectedX] =    obj.findUserEnteredCoordinatesFromImage;
                pixelListWithoutSelected =          obj.LoadedMovie.getPixelsFromActiveMaskAfterRemovalOf([UserSelectedY, UserSelectedX]);
                obj.LoadedMovie =                   obj.LoadedMovie.resetActivePixelListWith(PMSegmentationCapture(pixelListWithoutSelected, 'Manual'));
                obj =                               obj.updateAllViewsThatDependOnActiveTrack;
          end
          
          function obj =                    tracking_removePixelRimFromActiveMask(obj)
                mySegmentationObject =     PMSegmentationCapture(obj);
                mySegmentationObject =     mySegmentationObject.removeRimFromActiveMask;
                obj.LoadedMovie =          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                obj =                      obj.updateAllViewsThatDependOnActiveTrack;
          end
          
            function obj = tracking_deleteSelectedTracks(obj)
                obj.LoadedMovie =          obj.LoadedMovie.deleteSelectedTracks;
                obj =                      obj.updateAllViewsThatDependOnActiveTrack;
            end
             
            function obj =              tracking_deleteActiveTrack(obj)
                obj.LoadedMovie =     obj.LoadedMovie.deleteActiveTrack;
                obj =                 obj.updateAllViewsThatDependOnActiveTrack;

            end
            
            function [obj] =            tracking_deleteAllTracks(obj)
                obj.LoadedMovie =     obj.LoadedMovie.deleteAllTracks;
                obj =                 obj.setActiveTrackTo(NaN)   ; 
                obj =                 obj.updateAllViewsThatDependOnActiveTrack;
                
            end
          
            function obj =              tracking_deleteActiveMask(obj)
                obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('deleteActiveMask');
                obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
            end
        
            function obj = tracking_splitSelectedTrack(obj)
                obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('splitSelectedTrackAtActiveFrame');
                obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
            end
            
            function obj = tracking_mergeSelectedTracks(obj)
                try
                    obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('mergeSelectedTracks');
                    obj =                   obj.updateAllViewsThatDependOnActiveTrack;
                catch ME
                    throw(ME)
                end  

            end
               
            function obj = tracking_fillGapsOfActiveTrack(obj)
                try
                    obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('fillGapsOfActiveTrack');
                    obj =                   obj.updateAllViewsThatDependOnActiveTrack;
                catch ME
                    throw(ME)
                end
            end

          function obj = tracking_addButtonClickMaskToNewTrack(obj)
                obj.LoadedMovie =     obj.LoadedMovie.setActiveTrackToNewTrack;
                obj =                 obj.tracking_updateActiveMaskByButtonClick;
          end
          
       
            function obj =                     tracking_addHighlightedPixelsFromMask(obj)
                [ ~, ~,  z, ~ ] =    obj.getCoordinatesOfCurrentMousePosition;
                [y, x] =             obj.findUserEnteredCoordinatesFromImage;
                obj.LoadedMovie =     obj.LoadedMovie.updateMaskOfActiveTrackByAdding(y, x, z);
                obj =                 obj.updateAllViewsThatDependOnActiveTrack;

            end
            

            function [y, x] = findUserEnteredCoordinatesFromImage(obj)
                Coordinates =     obj.getCoordinateListByMousePositions;

                RectangleImage(min(Coordinates(:, 2)): max(Coordinates(:, 2)), min(Coordinates(:, 1)): max(Coordinates(:, 1))) = 1;
                [y, x] = find(RectangleImage);


            end

         
      
            function obj =                     tracking_usePressedCentroidAsMask(obj)

                [rowFinal, columnFinal, planeFinal, ~] =   obj.getCoordinatesOfCurrentMousePosition;
                if ~isnan(rowFinal)
                      mySegmentationObject =    PMSegmentationCapture(obj, [rowFinal, columnFinal, planeFinal]);
                      mySegmentationObject =    mySegmentationObject.setSegmentationType('MouseClick');
                      obj.LoadedMovie =         obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                      obj =                     obj.updateAllViewsThatDependOnActiveTrack;
                end

            end
            
            function obj =                     tracking_addPixelRimToActiveMask(obj)
                mySegmentationObject =     PMSegmentationCapture(obj).addRimToActiveMask;
                obj.LoadedMovie =          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                obj =                      obj.updateAllViewsThatDependOnActiveTrack;    
            end
            
            
            function obj = tracking_autoTracking(obj, varargin)
                
                if length(varargin) == 2
                    obj = obj.performAutoTracking(varargin{1}, varargin{2});
                    
                else
                    error('Input not supported')
                    
                end
                
                
                
            end
            
              
        function obj = tracking_splitTrackAfterActiveFrame(obj)
            obj.LoadedMovie =       obj.LoadedMovie.splitTrackAfterActiveFrame;
             obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end
         
        
        function [obj] =       tracking_splitTrackAtFrameAndDeleteFirstPart(obj)
                obj.LoadedMovie =       obj.LoadedMovie.deleteActiveTrackBeforeActiveFrame;
                 obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end
        
       
        function [obj] =       tracking_splitSelectedTracksAndDeleteSecondPart(obj) 
            obj.LoadedMovie =   obj.LoadedMovie.deleteActiveTrackAfterActiveFrame;
             obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        
        
        
        
    end
    
    methods % setter tracking frames
        
        function obj = setFrame(obj, Value)
            % setFrame; sets model and view with new active frame;
            % one argument accepted:
            % argument can be either a string: 'first', 'last', 'next', 'previous';
            % or a number: if number is out of range it is ignored;
            Type = class(Value);
            switch Type
                case 'char'
                    obj = setFrameByString(obj, Value);
                case 'double'
                    obj = setFrameByNumber(obj, Value);
                otherwise
                    error('Wrong input.')
                    
                    
            end
            
            
            
        end
        
        function obj = focusOnActiveTrackAtFrame(obj, newFrame)
            % FOCUSONACTIVETRACKATFRAME sets movie to chosen frame and changes PMMovieTracking and vies so that focus is on active track;
            obj.LoadedMovie =   obj.LoadedMovie.setFrameTo(newFrame); 
            obj.LoadedMovie =   obj.LoadedMovie.setFocusOnActiveTrack; 
            obj =               obj.setActiveCropOfMovieView;
            obj =               obj.updateMovieView;
            obj =               obj.setNavigationControls;
        end  
        
    end
    
    methods (Access = private) % autotracking
        
          function obj = updateHandlesForAutoTrackingController(obj)

              obj.TrackingAutoTrackingController  = obj.TrackingAutoTrackingController.setCallbacks(...
                    @obj.respondToMaximumAcceptedDistanceForAutoTracking, ...
                    @obj.respondToFirstPassDeletionFrameNumber, ...
                    @obj.respondToConnectionGapsValueChanged, ...
                    @obj.respondToConnectionGapsXYLimitChanged, ...
                    @obj.respondToConnectionGapsZLimitValueChanged, ...
                    @obj.respondToShowMergeInfoValueChanged, ...
                    @obj.startAutoTrackingPushed ...
                    );
              
          end
        
          function obj = respondToMaximumAcceptedDistanceForAutoTracking(obj, ~, ~)
                obj = obj.setTrackingNavigationByAutoTrackingView;
          end
          
          function obj = respondToFirstPassDeletionFrameNumber(obj, ~, ~)
              obj = obj.setTrackingNavigationByAutoTrackingView;
          end
          
          function obj = respondToShowMergeInfoValueChanged(obj,~,~)
              obj = obj.setTrackingNavigationByAutoTrackingView;
          end
          
          function obj = setTrackingNavigationByAutoTrackingView(obj)
              obj.LoadedMovie =                         obj.LoadedMovie.updateTrackingWith(obj.TrackingAutoTrackingController.getView);
              obj.TrackingAutoTrackingController =      obj.TrackingAutoTrackingController.resetModelWith(obj.LoadedMovie.getTracking);
          end
          
          
          function obj =respondToConnectionGapsValueChanged(obj,~,~)
              obj = obj.setTrackingNavigationByAutoTrackingView;
          end
          
          function obj = respondToConnectionGapsXYLimitChanged(obj,~,~)
              obj = obj.setTrackingNavigationByAutoTrackingView;
          end
          
           function obj = respondToConnectionGapsZLimitValueChanged(obj,~,~)
                 obj = obj.setTrackingNavigationByAutoTrackingView;
          end
          
          function obj = startAutoTrackingPushed(obj,~,~)

                switch obj.TrackingAutoTrackingController.getUserSelection

                    case 'Tracking by minimizing object distances'
                        obj =             obj.trackByMinimizingDistancesOfTracks;

                    case 'Delete tracks'
                        obj =             obj.unTrack;

                    case 'Connect exisiting tracks with each other'
                        obj.LoadedMovie =   obj.LoadedMovie.performTrackingMethod('performSerialTrackReconnection');

                    case 'Track-Delete-Connect'
                        obj.LoadedMovie =   obj.LoadedMovie.performAutoTrackingOfExistingMasks;

                end

               
                obj =           obj.initializeViews;
                obj =           obj.updateMovieView;
                obj =           obj.setTrackViews;

          end
          
        
        
    end
    
    methods (Access = private) % set tracking frames
        
        function obj = setFrameByNumber(obj, newFrame)

                if isnan(newFrame) || newFrame<1 || newFrame>obj.LoadedMovie.getMaxFrame
                else
                    
                    
                    if isempty(obj.Views) ||  ~isvalid(obj.Views.getFigure)
                         obj.LoadedMovie =           obj.LoadedMovie.setFrameTo(newFrame);
                        
                    else 
                        
                        switch obj.Views.getModifier
                            case 'shift'
                                obj = obj.focusOnActiveTrackAtFrame(newFrame);

                            otherwise
                                obj.LoadedMovie =   obj.LoadedMovie.setFrameTo(newFrame);  
                                obj =               obj.updateMovieView;
                                obj =               obj.setNavigationControls;
                                
                        end


                        
                    end
                   
                end
            
          end
        
        function obj = setFrameByString(obj, Value)
            
            switch Value
                case 'first'
                        obj =      obj.setFrameByNumber(1);
                        obj =      obj.focusOnActiveTrackAtFrame(1);
                case 'last'
                        obj =        obj.setFrameByNumber(obj.LoadedMovie.getMaxFrame);
                case 'next'
                    if obj.LoadedMovie.getActiveFrames < obj.LoadedMovie.getMaxFrame
                        obj =      obj.setFrameByNumber(obj.LoadedMovie.getActiveFrames + 1);
                    else
                        obj =      obj.setFrameByNumber( 1);
                    end
                case 'previous'
                     if obj.LoadedMovie.getActiveFrames > 1
                        obj =     obj.setFrameByNumber(obj.LoadedMovie.getActiveFrames - 1);
                    else
                        obj =     obj.setFrameByNumber(obj.LoadedMovie.getMaxFrame);
                     end
                case 'firstFrameOfActiveTrack'
                    obj = obj.goToFirstFrameOfActiveTrack;
                    
                case 'firstFrameOfCurrentTrackStretch'
                    obj =   gotToFirstTrackedFrameFromCurrentPoint(obj);
                case 'lastFrameOfCurrentTrackStretch'
                    obj = goToLastContiguouslyTrackedFrameInActiveTrack(obj);
                otherwise
                    error('Wrong input.')
                    
            end
            
            
        end
        
        function obj =   gotToFirstTrackedFrameFromCurrentPoint(obj)
                  obj =              obj.setFrameByNumber(obj.LoadedMovie.getLastTrackedFrame('down'));
        end
        
        function obj = goToLastContiguouslyTrackedFrameInActiveTrack(obj)
            LastTrackedFrame = obj.LoadedMovie.getLastTrackedFrame('up');
            if isnan(LastTrackedFrame)
                warning('Could not find gap. Therefore no action taken.')
            else
                obj =      obj.setFrameByNumber(LastTrackedFrame);
            end
            
        end
        
        function obj = goToFirstFrameOfActiveTrack(obj)
            Frames = min(obj.LoadedMovie.getTracking.getFramesOfActiveTrack);
             obj =      obj.setFrameByNumber(Frames);
        end
            
    end
    
    methods % setter image view
        
        function obj = setImageMaximumProjection(obj, Value)
            % SETIMAGEMAXIMUMPROJECTION shows all image planes (true) or only the currently selected one (false);
            obj.LoadedMovie =  obj.LoadedMovie.setCollapseAllPlanes(Value);
            obj =               obj.setViewsAfterChangeOfMaximumProjection(Value);
            

        end
        
       
        
         function obj = setCollapseTracking(obj, Value)
                obj.LoadedMovie =   obj.LoadedMovie.setCollapseAllTrackingTo(Value);
                obj =               obj.setViewsAfterChangeOfMaximumProjection(Value);
              

            
         end
            
         function obj = setCroppingGate(obj, Rectangle)
                obj.LoadedMovie =   obj.LoadedMovie.setCroppingGateWithRectange(Rectangle);
                  obj =               obj.setCroppingRectangle;
        end
        
        
        
    end
    
    methods (Access = private) % track manipulation
        
        function obj =         connectSelectedTrackToActiveTrack(obj)
            % not sure if this is helpful:
            IDOfTrackToMerge =  obj.getTrackIDFromMousePosition;
            obj.LoadedMovie =   obj.LoadedMovie.mergeActiveTrackWithTrack(IDOfTrackToMerge);
            obj =               obj.updateMovieView;
        end
          
        
        function obj = toggleTrackForwardGaps(obj)
            [Gaps, TrackIdsToToggle] =       obj.getLimitsOfUnfinishedForwardGaps;
            obj =                               obj.toggelListWithTrackIDs(TrackIdsToToggle, Gaps, 'Forward');
        end
        
        function [Gaps, TrackIdsToToggle] = getLimitsOfUnfinishedBackwardGaps(obj)
            [Gaps, TrackIdsToToggle] =            obj.LoadedMovie.getLimitsOfFirstBackwardGapOfAllTracks;
            Indices =                           obj.LoadedMovie.getIndicesOfFinishedTracksFromList(TrackIdsToToggle);
            TrackIdsToToggle(Indices, :) =      [];  
            Gaps(Indices, :) = [];
        end

        function [Gaps, TrackIdsToToggle] = getLimitsOfUnfinishedForwardGaps(obj)
            [Gaps, TrackIdsToToggle] =        obj.LoadedMovie.getLimitsOfFirstForwardGapOfAllTracks;
            Indices =                         obj.LoadedMovie.getIndicesOfFinishedTracksFromList(TrackIdsToToggle);
            TrackIdsToToggle(Indices, :) =    [];  
            Gaps(Indices, :) =               [];

        end

        function [Gaps, TrackIDs] = getLimitsOfUnfinishedTracks(obj)
            TrackIDs =             obj.LoadedMovie.getUnfinishedTrackIDs;

        end
        
        function obj = toggleTrackForwardGapsIgnoreComplete(obj)
            [Gaps, TrackIdsToToggle] =        obj.LoadedMovie.getLimitsOfSurroundedFirstForwardGapOfAllTracks;
            obj =                               obj.toggelListWithTrackIDs(TrackIdsToToggle, Gaps, 'Forward');
        end

        function obj = toggleTrackBackwardGaps(obj)
            [Gaps, TrackIdsToToggle] =       obj.getLimitsOfUnfinishedBackwardGaps;
            obj =                           obj.toggelListWithTrackIDs(TrackIdsToToggle, Gaps, 'Backward');

        end

        function obj = toggleUnfinishedTracks(obj, Value)
            TrackIDs =       obj.LoadedMovie.getUnfinishedTrackIDs;
            obj =          obj.toggelListWithTrackIDs(TrackIDs, '', Value); 
        end

      

        
      
        
        
        
    end
    
    methods %  filemanagement
        
        function obj = setExportFolder(obj, Value)
           obj.ExportFolder = Value; 
        end
        
        function folder = getExportFolder(obj)
            
           folder = obj.ExportFolder; 
        end
        
        function obj = setInteractionsFolder(obj, Value)
           obj.InteractionsFolder = Value; 
        end
       
         
          
    end
    
    methods % file management loaded movie
       
         
         function obj = createDerivativeFiles(obj)
            obj.LoadedMovie = obj.LoadedMovie.saveDerivativeData;
          
         end
         
          function obj = saveMovie(obj)
            % SAVEMOVIE: saves attached PMMovieTracking into file and updates save-status view;
               if ~isempty(obj.LoadedMovie)  && isa(obj.LoadedMovie, 'PMMovieTracking')
                    obj.LoadedMovie =   obj.LoadedMovie.save;
                    obj =           obj.updateSaveStatusView;

               else
                    warning('No valid LoadedMovie available: therefore no action taken.\n')

               end
   
        end
        
        
         
          function [obj] =            setNamesOfMovieFiles(obj, Value)
                obj.LoadedMovie =       obj.LoadedMovie.setNamesOfMovieFiles(Value);
          end
        
         
        function obj = exportTrackCoordinates(obj)
             [file,path] =                   uiputfile([obj.LoadedMovie.getNickName, '.csv']);
            TrackingAnalysisCopy =         obj.LoadedMovie.getTrackingAnalysis;
            TrackingAnalysisCopy =         TrackingAnalysisCopy.setSpaceUnits('µm');
            TrackingAnalysisCopy =         TrackingAnalysisCopy.setTimeUnits('minutes');
            TrackingAnalysisCopy.exportTracksIntoCSVFile([path, file], obj.LoadedMovie.getNickName)
            
        end
        
        function obj = deleteImageAnalysisFile(obj)
            obj.LoadedMovie = obj.LoadedMovie.deleteFiles;
        end

        
        
        
        
        
    end
    
    methods % loaded movie
        
        function obj = setLoadedMovie(obj, Value)
           obj.LoadedMovie = Value; 
        end
        
         function obj =        setMovieTracking(obj, Value)
             % this is not good; this should be just done at the beginning when initiaing the object, later this should be left in piece;
             error('Do not use this. Include the movie tracking when initializing the object.')   
             obj.LoadedMovie = Value;
         end
  
         function movie = getLoadedMovie(obj)
            movie = obj.LoadedMovie;
         end
        
       
       


          
          
        
        
        
        
    end
      
    methods % getters image volumes
       
        function volumes = getLoadedImageVolumes(obj)
            % GETLOADEDIMAGEVOLUMES get access to all image-volumes that are current stored in cash;
            % this is used by PMMovieLibrary which keeps track of all movies so that the movie does not have to be reloaded as soon as the user changes the movie;
           volumes =  obj.LoadedImageVolumes;
        end
        
        function Volume = getActiveImageVolumeForChannel(obj, ChannelIndex)
            activeVolume =  obj.getActiveImageVolume;
            Volume =         activeVolume(:, :, :, 1, ChannelIndex);
        end
        
         function activeVolume = getActiveImageVolume(obj)
             obj =             obj.updateLoadedImageVolumes;
             activeVolume =     obj.LoadedImageVolumes{obj.LoadedMovie.getActiveFrames, 1};
         end

    end
    
    methods % get processed images:
        
        function croppedRgbImage = getCroppedRgbImage(obj)

            RgbImage =          obj.getRbgImage;

            Rectangle =         obj.LoadedMovie.getCroppingRectangle;

            croppedRgbImage =   RgbImage(Rectangle(2): Rectangle(2) + Rectangle(4)-1,Rectangle(1): Rectangle(1) + Rectangle(3) - 1, :);

            figure(100)
            imshow(croppedRgbImage)

        end

        function rgbImage = getRbgImage(obj)

            rgbImage =       obj.LoadedMovie.convertImageVolumeIntoRgbImage(obj.getActiveImageVolume); 

            ThresholdedImage = obj.getInteractionImage;
            if isempty(ThresholdedImage)

            else
                rgbImage = PMRGBImage().addImageWithColor(rgbImage, ThresholdedImage, 'Red');
            end

            if obj.LoadedMovie.getMaskVisibility 
                rgbImage =            obj.addMasksToImage(rgbImage);
            end

        end
        
          function image = getInteractionImage(obj)
                  ThresholdedImage =  obj.InteractionImageVolume * 150;
              
                  if isempty(ThresholdedImage)
                      image = ThresholdedImage;
                      
                  else
                        filtered =      obj.LoadedMovie.filterImageVolumeByActivePlanes(ThresholdedImage);
                        image =         max(filtered, [], 3);
                  end
                 
          end
            

       


    end
    
    methods % getters
        
        function Value = getNickName(obj)
            Value = obj.LoadedMovie.getNickName;
        end
        
         function view = getViews(obj)
           view = obj.Views; 
         end
        
         function action = getMouseAction(obj)
             action = obj.MouseAction;
         end
         
         function verifiedStatus =                     verifyActiveMovieStatus(obj)
              verifiedStatus = ~isempty(obj.LoadedMovie) &&   isa(obj.LoadedMovie, 'PMMovieTracking') && isscalar(obj.LoadedMovie) &&  obj.LoadedMovie.verifyExistenceOfPaths;
              
             
              
         end
          
    end
    
    methods % setters
        
          function obj = updateWith(obj, Value)
            % UPDATEWITH update state of PMMovieController
            % this function will be ignored if currently no PMMovieTracking is attached;
            % takes 1 argument:
            % option 1: PMMovieLibrary: this will set the image-analysis folder of PMMovieTracking;
            % option 2: PMInteractionsManager: this will update the attached PMMovieTracking;
        
            assert(~isempty(obj.LoadedMovie), 'No loaded movie available.')
                 Type = class(Value);
                switch Type
                    case 'PMMovieLibrary'
                        obj.LoadedMovie = obj.LoadedMovie.setImageAnalysisFolder(Value.getPathForImageAnalysis);
                        obj.LoadedMovie = obj.LoadedMovie.setMovieFolder(Value.getMovieFolder);
                        
                    case 'PMInteractionsManager'
                        obj =   obj.updateControlElements;
                   
                        
                    otherwise
                        error('Cannot parse input.')
                end
           
    
        end
        
        function obj = setNickName(obj, Value)
            obj.LoadedMovie =   obj.LoadedMovie.setNickName(Value);
            obj =           obj.updateSaveStatusView;
        end
        
        function obj = setKeywords(obj, Value)
            obj.LoadedMovie = obj.LoadedMovie.setKeywords(Value); 
        end

        function obj  = setInteractionImageVolume(obj, Value)
            obj.InteractionImageVolume =        Value; 
            obj =           obj.updateMovieView;
        end
        
          function obj = setMouseAction(obj, Value)
             obj.MouseAction = Value;
          end
          
       function obj =           resetNumberOfExtraLoadedFrames(obj,Number)
            obj.DefaultNumberOfLoadedFrames =                   Number;    
       end

    end
    
    methods % setters image-volumes
        
        
        function obj =                  updateLoadedImageVolumes(obj)
            
            if isempty(obj.getFramesThatNeedToBeLoaded)

            else
              obj.LoadedImageVolumes(obj.getFramesThatNeedToBeLoaded,1 ) = obj.LoadedMovie.loadImageVolumesForFrames(obj.getFramesThatNeedToBeLoaded);
            end

            obj = obj.activateViews;

        end
        
        function requiredFrames =     getFramesThatNeedToBeLoaded(obj)
            obj =                                       obj.resetLoadedImageVolumesIfInvalid;
            requiredFrames =                            obj.getFrameNumbersThatMustBeInMemory;
            alreadyLoadedFrames =                       obj.getFramesThatAreAlreadyInMemory;

            requiredFrames(alreadyLoadedFrames,1) =     false;
            requiredFrames = find(requiredFrames);

        end
        
          function obj =                  resetLoadedImageVolumesIfInvalid(obj)
              % RESETLOADEDIMAGEVOLUMESIFINVALID sets LoadedImageVolumes to
              % the rigth format, if invalid;
              % this should not be necessary if the setters work correctly
            if ~iscell(obj.LoadedImageVolumes) || length(obj.LoadedImageVolumes) ~= obj.LoadedMovie.getMaxFrame
               obj.LoadedImageVolumes =                            cell(obj.LoadedMovie.getMaxFrame,1);
            end
          end
          
             
        function requiredFrames =       getFrameNumbersThatMustBeInMemory(obj)
            requiredFrames(1: obj.LoadedMovie.getMaxFrame, 1) = false;
            range =                 obj.LoadedMovie.getActiveFrames - obj.getLimitForLoadingFrames : obj.LoadedMovie.getActiveFrames + obj.getLimitForLoadingFrames;
            range(range<=0) =       [];
            range(range > obj.LoadedMovie.getMaxFrame) =       [];
            requiredFrames(range,1) =                                     true;
        end
        
        function frames =               getLimitForLoadingFrames(obj)  
            PressedKeyAsciiCode=                    double(obj.PressedKeyValue);
            if PressedKeyAsciiCode == 29 % if the user goes forward load multiple frames
                frames =        obj.DefaultNumberOfLoadedFrames;
            else % otherwise just one frame is loaded:
                frames =        0;
            end
        end

      
        
        
      function framesThatHaveTheMovieAlreadyLoaded = getFramesThatAreAlreadyInMemory(obj)
        framesThatHaveTheMovieAlreadyLoaded =         cellfun(@(x)  ~isempty(x),     obj.LoadedImageVolumes);   
      end
        

        

        
        
        
          function obj =        setLoadedImageVolumes(obj, Value)
              % SETLOADEDIMAGEVOLUMES sets LoadedImageVolumes (which contains stored images of source files so that they don't have to be loaded from file each time);
              if isempty(Value)
                  
              else
               %    assert(iscell(Value) && size(Value, 1) == obj.LoadedMovie.getMaxFrame && size(Value, 2) == 1, 'Invalid argument type.')
                  obj.LoadedImageVolumes =      Value; 
              end
          end
          
        function obj    =        emptyOutLoadedImageVolumes(obj)
            if isempty(obj.LoadedMovie) 
                obj.LoadedImageVolumes =        cell(0,1);
            else
                obj.LoadedImageVolumes =        cell(obj.LoadedMovie.getMaxFrame,1);
            end     
        end
        
      
        
          
        
        
        
    end
    
    methods % setters mouse positions
        
           function obj = setCurrentDownPositions(obj)
                obj =       obj.setMouseDownRow(obj.getViews.getMovieAxes.CurrentPoint(1,2));
                obj =       obj.setMouseDownColumn(obj.getViews.getMovieAxes.CurrentPoint(1,1)); 
          end
     
          function obj =      blackOutMousePositions(obj)
                obj =       obj.blackOutStartMousePosition;
                obj =       obj.setMouseUpRow(NaN);
                obj =       obj.setMouseUpColumn(NaN); 
          end
          
          function obj = blackOutStartMousePosition(obj)
                obj =     obj.setMouseDownRow(NaN);
                obj =     obj.setMouseDownColumn(NaN);
          end
                        
     
       
          
        
    end
    
    methods % setters navigation
       
          function obj = goOnePlaneDown(obj)
            CurrentPlane =        obj.LoadedMovie.getActivePlanes;
            [~, ~, MaximumPlane]=  obj.LoadedMovie.getImageDimensionsWithAppliedDriftCorrection;
            if CurrentPlane < MaximumPlane  
                [obj]  = obj.resetPlane(CurrentPlane + 1);
            end
        end
        
        function obj = goOnePlaneUp(obj)
            CurrentPlane =                          obj.LoadedMovie.getActivePlanes;
            if CurrentPlane > 1
                obj  = obj.resetPlane(CurrentPlane - 1);
            end
        end
        
             function obj  =     resetPlane(obj, newPlane)
                obj.LoadedMovie =       obj.LoadedMovie.setSelectedPlaneTo(newPlane);
                obj =                   obj.updateMovieView;
                obj =                   obj.setNavigationControls;
                obj =                               obj.setTrackViews;

        end
        
    end
    
    methods % setters channels

        function obj = setChannels(obj, Value)
            Type = class(Value);
            switch Type
                case 'PMMovieTracking'
                    obj.LoadedMovie = obj.LoadedMovie.setChannels(Value);

                case 'char'
                    switch  Value
                        case 'off'
                            obj =  turnOffAllChannels(obj);
                        otherwise
                            error('Wrong input.')
                    end
                otherwise
                    error('Wrong input.')

            end

        end
        
        function obj = setActiveChannel(obj, Value)
            obj.LoadedMovie =        obj.LoadedMovie.setActiveChannel(Value);
            
        end
        
        function obj = resetChannelSettings(obj, Value, Type)
             obj.LoadedMovie =       obj.LoadedMovie.resetChannelSettings(Value, Type);
            
        end
        
          function obj = setVisibilityOfChannels(obj, Value)

            assert(islogical(Value) && isvector(Value) && length(Value) == obj.LoadedMovie.getMaxChannel, 'Wrong input')
            for index = 1 : length(Value)
                obj.LoadedMovie =        obj.LoadedMovie.setVisibleOfChannelIndex(index, Value(index));    
            end

        end


        function obj = toggleVisibilityOfChannelIndex(obj, Index)
              if Index <= obj.LoadedMovie.getMaxChannel
                    obj.LoadedMovie =        obj.LoadedMovie.setVisibleOfChannelIndex(Index,   ~obj.LoadedMovie.getVisibleOfChannelIndex(Index));    
                    obj.LoadedMovie =        obj.LoadedMovie.setActiveChannel(Index);
                    obj =           obj.updateControlElements;
                    obj =           obj.updateMovieView;

               end

        end

      

         function obj =  turnOffAllChannels(obj)
            obj.LoadedMovie =   obj.LoadedMovie.turnOffAllChannels; 
            obj =               obj.updateControlElements;
            obj =               obj.updateMovieView;
         end


    end
    
    
    methods (Access = private) % channel-callbacks

        function obj = setChannelCallbacks(obj)
                   obj.Views  =    setChannelCallbacks(obj.Views, ...
                                 @obj.channelViewClicked, ...
                                 @obj.channelLowIntensityClicked, ...
                                 @obj.channelHighIntensityClicked, ...
                                 @obj.channelColorClicked, ...
                                 @obj.channelCommentClicked, ...
                                 @obj.channelOnOffClicked, ...
                                @obj.channelReconstructionClicked ...
                );
        end

        function [obj] =           channelViewClicked(obj,~,~)
           obj.LoadedMovie =    obj.LoadedMovie.setActiveChannel(getSelectedChannel(obj.Views));
           obj =                obj.updateControlElements;
        end

        function [obj] =           channelLowIntensityClicked(obj,~,~)
                obj.LoadedMovie =       obj.LoadedMovie.resetChannelSettings(getMinimumIntensityOfSelectedChannel(obj.Views), 'ChannelTransformsLowIn');
                obj =                   obj.updateMovieView;
                obj =                   obj.updateControlElements;
        end

        function [obj] =           channelHighIntensityClicked(obj,~,~)
            obj.LoadedMovie  =      obj.LoadedMovie.resetChannelSettings(getMaximumIntensityOfSelectedChannel(obj.Views), 'ChannelTransformsHighIn');
            obj =                   obj.updateMovieView;
            obj =                   obj.updateControlElements;
        end

        function [obj] =          channelColorClicked(obj,~,~)
            obj.LoadedMovie  =      obj.LoadedMovie.resetChannelSettings(getColorOfSelectedChannel(obj.Views), 'ChannelColors');
            obj =           obj.updateMovieView;
            obj =           obj.updateControlElements;
        end

        function [obj] =          channelCommentClicked(obj,~,~)
            obj.LoadedMovie  =      obj.LoadedMovie.resetChannelSettings(getCommentOfSelectedChannel(obj.Views), 'ChannelComments');
            obj =           obj.updateMovieView;
            obj =           obj.updateControlElements;
        end

        function [obj] =          channelOnOffClicked(obj,~,~)
            obj.LoadedMovie  =      obj.LoadedMovie.resetChannelSettings(getVisibilityOfSelectedChannel(obj.Views), 'SelectedChannels');   
            obj =           obj.updateMovieView;
            obj =           obj.updateControlElements;

        end

        function [obj] =         channelReconstructionClicked(obj,~,~)
            obj.LoadedMovie  =      obj.LoadedMovie.resetChannelSettings(getFilterTypeOfSelectedChannel(obj.Views), 'ChannelReconstruction');
            obj =                   obj.emptyOutLoadedImageVolumes;
            obj =           obj.updateMovieViewImage;
            obj =           obj.updateMovieView;

            obj =           obj.updateControlElements;    
        end





    end
    

    methods % image map
        
       function obj =           resetLoadedMovieFromImageFiles(obj)
            obj    =            obj.emptyOutLoadedImageVolumes;
            obj.LoadedMovie =   obj.LoadedMovie.setPropertiesFromImageFiles;
            obj =               obj.updateMovieViewImage;
       end
       
     

       function obj =           manageResettingOfImageMap(obj)
            error('Not supported anymore. Use resetLoadedMovieFromImageFiles instead.')
       end


       
        
    end
    
    methods % set drift -correction
        
        
        function obj = setDriftCorrection(obj, Value, varargin)
            
            Type = class(Value);
            switch Type
                case 'char'
                    switch Value
                        case 'Manual'
                            obj = obj.setManualDriftCorrection(varargin{1});
                        case 'remove'
                            obj = obj.resetDriftCorrectionToNoDrift;
                        case 'byManualEntries'
                            obj = obj.resetDriftCorrectionByManualClicks;
                       
                        otherwise
                            error('Wrong input.')
                    end
                    
                otherwise
                    error('Wrong input.')
                
                
            end
            
            
        end
        
 
   

        
    end
    
    methods % setters tracking
       
         function obj =                         setFinishStatusOfTrackTo(obj, Input)
             obj.LoadedMovie =                              obj.LoadedMovie.setFinishStatusOfTrackTo(Input); 
             obj.TrackingNavigationEditViewController =     obj.TrackingNavigationEditViewController.resetForFinishedTracksWith(obj.LoadedMovie.getTracking);
             
             switch Input
                 case 'Finished'
                       obj = obj.toggleUnfinishedTracks('Forward');
                 case 'Unfinished'
                      obj = obj.toggleUnfinishedTracks('Backward');
                 otherwise
                     error('Wrong input.')
             end
         
              fprintf('toggleUnfinishedTracks: %6.2f seconds.\n', toc)
             
         end

     

         
    
         function obj = performTrackingMethod(obj, Value, varargin)
             % performTrackingMethod
            assert(ischar(Value), 'Wrong input')
          NameOfTrackingFunction =    ['tracking_', Value];
            if length(varargin) >= 2
                obj =                      obj.(NameOfTrackingFunction)(varargin{1}, varargin{2});
            elseif length(varargin) >= 1
                obj =                      obj.(NameOfTrackingFunction)(varargin{1});
            elseif isempty(varargin)
                obj =                      obj.(NameOfTrackingFunction);
            else
                error('Wrong input')
            end
         end
         

      
        function obj = truncateActiveTrackToFit(obj)
            try
                obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('truncateActiveTrackToFit');
                obj =                   obj.updateAllViewsThatDependOnActiveTrack;
            catch ME
                throw(ME)
            end
            
        end
        
        
        
    end
 
    methods
            
        function obj = setTrackingNavigationEditViewController(obj, varargin)
            %    obj.LoadedMovie = obj.LoadedMovie.generalCleanup;
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                 case 0
                     obj.TrackingNavigationEditViewController =   obj.TrackingNavigationEditViewController.resetModelWith(obj.LoadedMovie.getTracking);
                 case 1
                     obj.TrackingNavigationEditViewController =   obj.TrackingNavigationEditViewController.resetModelWith(obj.LoadedMovie.getTracking, varargin{1});
                 otherwise
                     error('Wrong input.')
            end

            obj =                          obj.updateHandlesForTrackingNavigationEditView;
        end

        function obj =   showAutoCellRecognitionWindow(obj)

            if isempty(obj.LoadedMovie)

            else
                myModel =                                   PMAutoCellRecognition(obj.getLoadedImageVolumes, find(obj.LoadedMovie.getActiveChannelIndex));
                obj.AutoCellRecognitionController =         PMAutoCellRecognitionController(myModel);   

                obj.AutoCellRecognitionController =         obj.AutoCellRecognitionController.setCallBacks(@obj.AutoCellRecognitionChannelChanged, @obj.AutoCellRecognitionFramesChanged, @obj.AutoCellRecognitionTableChanged, @obj.startAutoCellRecognitionPushed);

            end

        end

     

        function obj = showAutoTrackingController(obj)
             obj.TrackingAutoTrackingController =         obj.TrackingAutoTrackingController.resetModelWith(obj.LoadedMovie.getTracking, 'ForceDisplay');
             obj =                                        obj.updateHandlesForAutoTrackingController;
        end
            
        function summary = getMetaDataSummary(obj)
           summary = obj.LoadedMovie.getMetaDataSummary;
            
        end
        
        function obj = saveMetaData(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    obj.LoadedMovie = obj.LoadedMovie.saveMetaData(varargin{1});
                    
                otherwise
                    error('Wrong input.')
                
            end
 
        end
           
    end
         
    methods (Access = private) % highLightRectanglePixelsByMouse
        
       
        
         function SpaceCoordinates =           getCoordinateListByMousePositions(obj)

                myRectangle =       PMRectangle(obj.getRectangleFromMouseDrag);
                Coordinates_2D =    myRectangle.get2DCoordinatesConfinedByRectangle;
                
                [ ~, ~,  planeWithoutDrift, ~ ] =    obj.getCoordinatesOfCurrentMousePosition;
                zListToAdd =    (linspace(planeWithoutDrift, planeWithoutDrift, length(Coordinates_2D(:, 1))))';

                SpaceCoordinates = [Coordinates_2D, zListToAdd];

         end
         
         
         function [Rectangle] =                 getRectangleFromMouseDrag(obj)
            [ startrow, startcolumn,  ~, ~ ] =   obj.getCoordinatesOfButtonPress;
            [ endrow, endcolumn,  ~, ~ ] =       obj.getCoordinatesOfCurrentMousePosition;
            Rectangle =                         [startcolumn, startrow, endcolumn - startcolumn, endrow - startrow];
         end
         
           function [rowFinal, columnFinal, planeFinal, frame] =      getCoordinatesOfButtonPress(obj)
            [columnFinal, rowFinal, planeFinal] =            obj.LoadedMovie.removeDriftCorrection(obj.MouseDownColumn, obj.MouseDownRow, obj.LoadedMovie.getActivePlanes);
            [rowFinal, columnFinal, planeFinal, frame] =     obj.roundCoordinates(rowFinal, columnFinal, planeFinal, obj.LoadedMovie.getActiveFrames);
            [rowFinal, columnFinal, planeFinal]  =            obj.LoadedMovie.verifyCoordinates(rowFinal, columnFinal,planeFinal);
           end

      
        
        
            
          
           
        
        function [rowFinal, columnFinal, planeFinal, frame] =               getCoordinatesOfCurrentMousePosition(obj)
            [columnFinal, rowFinal, planeFinal] =            obj.LoadedMovie.removeDriftCorrection(obj.MouseUpColumn, obj.MouseUpRow, obj.LoadedMovie.getActivePlanes);
            [rowFinal, columnFinal, planeFinal, frame] =     obj.roundCoordinates(rowFinal, columnFinal, planeFinal, obj.LoadedMovie.getActiveFrames);
            [rowFinal, columnFinal, planeFinal]  =           obj.LoadedMovie.verifyCoordinates(rowFinal, columnFinal,planeFinal);
        end
        
       
            
        
        
    end

    methods % reset axes by mouse movment
       
          function obj = resetAxesCenterByMouseMovement(obj)
                XMovement =     obj.getMouseUpColumn - obj.getMouseDownColumn;
                YMovement =     obj.getMouseUpRow - obj.getMouseDownRow;
                obj =           obj.resetAxesCenter(XMovement, YMovement);
            
         end
        
    end
    
    methods (Access = private) % reset axes by mouse movement;
       
       
        
        
        
        
          function Value = getMouseDownRow(obj)
             Value = obj.MouseDownRow;
          end
          
          function Value = getMouseDownColumn(obj)
             Value = obj.MouseDownColumn;
          end
          
          function Value = getMouseUpColumn(obj)
             Value = obj.MouseUpColumn;
          end
          
           function Value = getMouseUpRow(obj)
             Value = obj.MouseUpRow;
           end
           
        
        
    end
    
    
    methods (Access = private) % drift correction
        
        
            function obj =         resetDriftCorrectionByManualClicks(obj)
                obj.LoadedMovie =     obj.LoadedMovie.setDriftCorrection(obj.LoadedMovie.getDriftCorrection.setByManualDriftCorrection);
                obj =                  obj.resetDriftDependentParameters;
            end

            function obj =         resetDriftDependentParameters(obj)
                obj.LoadedMovie =         obj.LoadedMovie.setDriftDependentParameters;
                obj =                     obj.resetViewsForCurrentDriftCorrection; 
            end 

            function obj =         resetDriftCorrectionToNoDrift(obj)
                obj.LoadedMovie =     obj.LoadedMovie.setDriftCorrection(obj.LoadedMovie.getDriftCorrection.setBlankDriftCorrection);
                obj =                 obj.resetDriftDependentParameters;   
            end
        
        function obj  =        setDriftCorrectionTo(obj, state)
            obj.LoadedMovie =   obj.LoadedMovie.setDriftCorrectionTo(state); % the next function should be incoroporated into this function
            obj =               obj.resetDriftDependentParameters;
        end
        

        
        
        function obj = setManualDriftCorrection(obj, Value)

            switch Value
                case 'currentFrameByButtonPress'
                   [rowFinal, columnFinal, planeFinal, frame] =     obj.getCoordinatesOfButtonPress;
                   obj =               obj.setManualDriftCorrectionByTimeSpaceCoordinates(frame, columnFinal, rowFinal,  planeFinal );

                case 'currentAndConsecutiveFramesByButtonPress'
                       [rowFinal, columnFinal, planeFinal, frame] =     obj.getCoordinatesOfButtonPress;
                       Frames = frame : obj.LoadedMovie.getMaxFrame;
                       
                   obj =               obj.setManualDriftCorrectionByTimeSpaceCoordinates(Frames, columnFinal, rowFinal,  planeFinal );

                otherwise
                    error('Wrong input.')
            end

        end
        
         function [obj]  =                setManualDriftCorrectionByTimeSpaceCoordinates(obj, frames, columnFinal, rowFinal,  planeFinal)
            NewDriftCorrection =    obj.LoadedMovie.getDriftCorrection.updateManualDriftCorrectionByValues(columnFinal, rowFinal,planeFinal, frames);

            Manual =                NewDriftCorrection.getManualDriftCorrectionValues;
            obj.LoadedMovie =       obj.LoadedMovie.setDriftCorrection(NewDriftCorrection);
            obj =                   obj.setDriftCorrectionIndicators;
                
         end
        
         
        
    end
    
    methods (Access = private) % getters tracks
       
          
            function [StopTracks, GoTracks, StopTrackMetric, GoTracksMetric] = getStopGoTrackSegments(obj, DistanceLimit, MinTimeLimit, MaxTimeLimit)
       
                MyTrackingAnalysisMetric =      obj.LoadedMovie.getTrackingAnalysis;
                MyTrackingAnalysisMetric =      MyTrackingAnalysisMetric.setSpaceUnits('µm');
                MyTrackingAnalysisMetric =      MyTrackingAnalysisMetric.setTimeUnits('minutes');

                MyTrackingAnalysisPixels =      MyTrackingAnalysisMetric.setSpaceUnits('pixels');
                MyTrackingAnalysisPixels =      MyTrackingAnalysisPixels.setTimeUnits('frames');


                MyStopSeries =                  PMStopTrackingSeries(MyTrackingAnalysisMetric.getTrackCell, DistanceLimit,  MyTrackingAnalysisPixels.getTrackCell);

                StopTrackMetric=                MyStopSeries.getGoTracks;
                GoTracksMetric =                MyStopSeries.getStopTracks;


                StopTracks=                     MyStopSeries.getGoTracksPixels;
                GoTracks =                      MyStopSeries.getStopTracksPixels;

            end
        
    end
    
    
    
    methods (Access = private)
        
       
        function [TrackId, RowOfSelection] = selectTrackIdForTogglingFromList(obj, TrackIdsToToggle)
            
            if isempty(TrackIdsToToggle)
                TrackId = '';
                RowOfSelection = '';
            else
                RowOfSelection =            find(obj.LoadedMovie.getIdOfActiveTrack == TrackIdsToToggle);
                if isempty(RowOfSelection)
                     [TrackId, RowOfSelection] = obj.getNextTrackIdAfterActiveTrackFromList(TrackIdsToToggle);
                elseif length(RowOfSelection) == 1
                     [TrackId, RowOfSelection] = obj.getTrackIdAfterCurrentRowFromList(TrackIdsToToggle, RowOfSelection);
                else
                     TrackId = '';
                     RowOfSelection = '';
                end
            end  
            
        end
        
        function frames = getFollowingFramesOfCurrentTrack(obj)
            frames =                obj.LoadedMovie.getTracking.getFrameNumbersForTrackID(obj.LoadedMovie.getIdOfActiveTrack);
            frames(frames < obj.LoadedMovie.getActiveFrames) =     [];
        end
                
          function [StartFrames, EndFrames] = getForwardTrackingFramesFromGapLimits(obj, GapLimits)
            
                if isempty(GapLimits)
                    StartFrames = NaN;
                elseif GapLimits(1) == GapLimits(2)
                   StartFrames =    GapLimits;
                else
                    StartFrames =   (GapLimits(1) : GapLimits(2)) - 1;
                end

               StartFrames = obj.removeInvalidFrames(StartFrames);
             EndFrames = StartFrames + 1;
            
           end
           
             function [StartFrames, EndFrames] = getBackwardTrackingFramesFromGapLimits(obj, GapLimits)
            
                if isempty(GapLimits)
                    StartFrames = NaN;
                elseif GapLimits(1) == GapLimits(2)
                   StartFrames =    GapLimits;
                else
                    StartFrames =   (GapLimits(2) : -1: GapLimits(1)) + 1;
                end

               StartFrames = obj.removeInvalidFrames(StartFrames);
             EndFrames = StartFrames - 1;
            
           end
           
           function StartFrames = removeInvalidFrames(obj, StartFrames)
                StartFrames(StartFrames < 0, :) = [];
                StartFrames(StartFrames > obj.LoadedMovie.getMaxFrame, :) = [];
                if isempty(StartFrames)
                   StartFrames = NaN; 
                end
           end
           
         function [TrackId, CandidateRow] = getNextTrackIdAfterActiveTrackFromList(obj, TrackIdsToToggle)
             CandidateRow = find(TrackIdsToToggle > obj.LoadedMovie.getIdOfActiveTrack, 1, 'first');
             if isempty(CandidateRow)
                 CandidateRow = 1;
             end
             
                 TrackId = TrackIdsToToggle(CandidateRow);
             
        end
        
        function [TrackId, RowOfSelection] = getTrackIdAfterCurrentRowFromList(~, TrackIdsToToggle, RowOfSelection)
             if RowOfSelection == length(TrackIdsToToggle)
               RowOfSelection = 1;
            else
                RowOfSelection = RowOfSelection + 1;
             end
             TrackId = TrackIdsToToggle(RowOfSelection);

        end
        
        function StartFrames = getStartFramesForForwardGapTracking(obj)
             GapLimits =        obj.LoadedMovie.getLimitsOfFirstForwardGapOfAllTracks;
            StartFrames =       obj.getForwardTrackingFramesFromGapLimits(GapLimits);
            if isnan(StartFrames)
               StartFrames = 1; 
            end
        end



        function StartFrames = getStartFramesForBackwardGapTracking(obj)
             GapLimits =        obj.LoadedMovie.getLimitsOfFirstBackwardGapOfAllTracks;
            StartFrames =       obj.getBackwardTrackingFramesFromGapLimits(GapLimits);
            if isnan(StartFrames)
               StartFrames = 1; 
            end
        end

   
        %% getTrackIDFromMousePosition:
        function SelectedTrackID =   getTrackIDFromMousePosition(obj)
           frame =                                          obj.LoadedMovie.getActiveFrames;
            [ClickedColumn, ClickedRow, ClickedPlane] =         obj.LoadedMovie.removeDriftCorrection(obj.MouseUpColumn, obj.MouseUpRow, obj.LoadedMovie.getActivePlanes);
            [ClickedRow, ClickedColumn, ClickedPlane, ~] =      obj.roundCoordinates(ClickedRow, ClickedColumn, ClickedPlane, frame);
            SelectedTrackID=                                    obj.LoadedMovie.getIdOfTrackThatIsClosestToPoint([ClickedRow, ClickedColumn, ClickedPlane]);
        end
        
        
        function [rowFinal, columnFinal, planeFinal, frame] =     roundCoordinates(~, rowFinal, columnFinal, planeFinal, frame)
            rowFinal =          round(rowFinal);
            columnFinal =       round(columnFinal);
            planeFinal =        round(planeFinal);
            frame =             round(frame);
        end
        
         
          

  
        
        %%  mergeTracksByProximity
        function obj = mergeTracksByProximity(obj)
            answer=            inputdlg('How much overlap for track merging? Negative: tracks overlap; Positive gaps');
            obj.LoadedMovie =  obj.LoadedMovie.mergeTracksWithinDistance(round(str2double(answer{1})));   
            obj =              obj.updateAllViewsThatDependOnActiveTrack;
        end
        
                                

        
           
           
            
            
          

         
             
             function [rgbImage] =          addMasksToImage(obj, rgbImage)
                    ColorOfSelectedTracks =     obj.getColorOfSelectedMasksForImage(rgbImage);
                    MyFrame =                   obj.LoadedMovie.getActiveFrames;
                    MyPlanes =                  obj.LoadedMovie.getTargetMoviePlanesForSegmentationVisualization;
                    MyDriftCorrection =         obj.LoadedMovie.getDriftCorrection;
                    
                    MasksSelected =             obj.LoadedMovie.getTracking.getSelectedMasksAtFramePlaneDrift(MyFrame, MyPlanes, MyDriftCorrection);
                    rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, MasksSelected, 1, ColorOfSelectedTracks(1));
                    rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, MasksSelected, 2, ColorOfSelectedTracks(2));
                    rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, MasksSelected, 3, ColorOfSelectedTracks(3));

                    ActiveMask =                obj.LoadedMovie.getTracking.getActiveMasksAtFramePlaneDrift(MyFrame, MyPlanes, MyDriftCorrection);
                    Intensity =                 obj.getColorOfActiveMaskForImage(rgbImage);
                    rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, ActiveMask, 1:3, Intensity);

             end
             
             function MaskColor = getColorOfSelectedMasksForImage(obj, rgbImage)
                MaskColor(1) =          obj.MaskColor(1);
                MaskColor(2) =        obj.MaskColor(2);
                MaskColor(3) =         obj.MaskColor(3);

                if strcmp(class(rgbImage), 'uint16')
                    MaskColor(1) =        MaskColor(1) * 255;
                    MaskColor(2) =      MaskColor(2) * 255;
                    MaskColor(3) =       MaskColor(3) * 255;
                end
             end
             
             function Intensity = getColorOfActiveMaskForImage(~, rgbImage)
                Intensity =    255;
                if strcmp(class(rgbImage), 'uint16')
                    Intensity = Intensity * 255;
                end
                
             end
             
             function rgbImage = highlightPixelsInRgbImage(~, rgbImage, CoordinateList, Channel, Intensity)
                 
                 if isempty(CoordinateList)
                     
                 else
                     CoordinateList(isnan(CoordinateList(:,1)),:) = []; % this should not be necessary if everything works as expected;
                     NumberOfPixels =                        size(CoordinateList,1);
                    if ~isnan(Intensity)
                        for CurrentPixel =  1:NumberOfPixels
                            rgbImage(CoordinateList(CurrentPixel, 1), CoordinateList(CurrentPixel, 2), Channel)= Intensity;
                        end
                    end
                     
                 end
                 
                
              
             end
           
            
      
        
            %% autoTrackCurrentCellForFrames:
           function obj =                    autoTrackCurrentCellForFrames(obj, SourceFrames, TargetFrames)
            
            obj.LoadedMovie =                   obj.LoadedMovie.setPreventDoubleTracking(true, 2);
            
            StopObject =                        obj.createStopButtonForAutoTracking;
            obj.PressedKeyValue =               'a';

            obj =                               obj.setFrameByNumber(SourceFrames(1)); 
            SegementationOfReference =          obj.getReferenceSegmentation;

            for FrameIndex = 1 : length(SourceFrames)
                
                
                try
                    [~, SegementationObjOfTargetFrame] =         obj.performTrackingBetweenTwoFrames(SourceFrames(FrameIndex), TargetFrames(FrameIndex), SegementationOfReference);
                catch E
                    Text = [E.message, 'Going to next track.'];
                    warning(Text)
                    break
                end
                
                try
                    obj.LoadedMovie =    obj.LoadedMovie.resetActivePixelListWith(SegementationObjOfTargetFrame);
                    fprintf('New mask added.\n');
                catch E
                    Text = [E.message, 'Going to next track.'];
                    warning(Text)
                    break
                end
                obj.LoadedMovie =  obj.LoadedMovie.setPreventDoubleTracking(false, 2);

            end
            
            obj.PressedKeyValue  =          '';
            delete(StopObject.ParentFigure)
            
            obj =                               obj.setTrackViews;
        end
        
            
                       

        function [SourceSegmentation,TargetSegmentation] =                    performTrackingBetweenTwoFrames(obj, sourceFrameNumber, targetFrameNumber, SegementationOfReference)

            fprintf('Tracking from frame %i for segmentation of frame %i.\n', sourceFrameNumber, targetFrameNumber)
            
            obj =                         obj.setFrameByNumber(sourceFrameNumber);
            SourceSegmentation =          PMSegmentationCapture(obj); 
            SourceSegmentation =          obj.applyStandardValuesToSegmentation(SourceSegmentation);

            if isempty(SourceSegmentation.getMaskCoordinateList)
                ME = MException('MATLAB:performTrackingBetweenTwoFramesFailed', 'No source pixels found.');
                    throw(ME)
            else

                obj =                       obj.focusOnActiveTrackAtFrame(targetFrameNumber);
                TargetSegmentation =        PMSegmentationCapture(obj); 
                
                
                TargetSegmentation =        obj.applyStandardValuesToSegmentation(TargetSegmentation);
                TargetSegmentation =        TargetSegmentation.setMaskCoordinateList(SourceSegmentation.getMaskCoordinateList);
                TargetSegmentation =        TargetSegmentation.generateMaskByEdgeDetectionForceSizeBelow(SegementationOfReference.getMaximumPixelArea);
            
                XYDistance =                obj.getXYDistanceBetween(SourceSegmentation, TargetSegmentation);
                ZDistance =                 obj.getZDistanceBetween(SourceSegmentation, TargetSegmentation);
                
                if XYDistance > 8 || ZDistance > 1
                    ME = MException('MATLAB:performTrackingBetweenTwoFramesFailed', 'Distance beyond limit.');
                    throw(ME)
                elseif isempty(TargetSegmentation) || TargetSegmentation.getNumberOfPixels < 1 
                   ME = MException('MATLAB:performTrackingBetweenTwoFramesFailed', 'Target segmentation too small.');
                    throw(ME)
                elseif TargetSegmentation.getPixelArea > (SegementationOfReference.getMaximumPixelArea + 20)
                     ME = MException('MATLAB:performTrackingBetweenTwoFramesFailed', 'Target segmentation too large.');
                    throw(ME)
                end
             
            end
           

        end
        
             %% createStopButtonForAutoTracking
            function StopObject =            createStopButtonForAutoTracking(obj)
                 %% create a stop-button: its only function is to let the user stop the tracking when something goes wrong;
                MyFigure = figure;
                MyFigure.MenuBar = 'none';
                MyFigure.Position = [40 630 100 50 ];

                ButtonHandle = uicontrol(MyFigure,'Style', 'PushButton', ...
                'String', 'Stop tracking', ...
                'Callback', 'delete(gcbf)');

                ButtonHandle.Units = 'normalized';
                ButtonHandle.Position = [ 0 0 1 1 ];

                StopObject.ParentFigure = MyFigure;
                StopObject.Button = ButtonHandle;

            end

            
         
            
            
            %% performAutoTracking:
            function obj = performAutoTracking(obj, varargin)
                
                if length(varargin) == 2
                    
                    switch varargin{1}
                        case 'activeTrack'
                            switch varargin{2}
                                case 'forwardInFirstGap'
                                    obj =    obj.autoForwardTrackingOfActiveTrack;
                                case 'backwardInLastGap'
                                    obj =    obj.autoBackwardTrackingOfActiveTrack;
                                        %% minimizeMasksOfCurrentTrackForFrames
                                case 'convertAllMasksToMiniMasks'
                                    obj = minimizeMasksOfCurrentTrack(obj);
                                case 'convertAllMasksByCurrentSettings'
                                    obj = recreateMasksOfCurrentTrack(obj);
          
                                  
          
     
                                otherwise
                                    error('Input not supported.')
                            end
                            
                        case 'allTracks'
                            switch varargin{2}
                               
                                case 'forwardFromActiveFrame'
                                    obj =                    obj.autoTrackingWhenNoMaskInNextFrame;
                                otherwise
                                    error('Input not supported')
                                
                                
                            end
                            
                        case 'newMasks'
                            switch varargin{2}
                                case  'circle'
                                    obj = autoDetectMasksByCircleRecognition(obj);
                                case 'thresholdingInBrightAreas'
                                    obj =                    autoDetectMasksOfCurrentFrame(obj);
                                    
                                otherwise
                                    error('Input not supported.')
                                    
                                    
                            end
                                
                            
                            
                        otherwise
                            error('Input not supported.')
                    end
                    
                    
                else
                   error('Input not supported.') 
                end
                
                
                
            end
            
  
            function obj =                    autoBackwardTrackingOfActiveTrack(obj)
                %  autoBackwardTrackingOfActiveTrack: backward tracking of active track;
                % tracks from already tracked start mask that is used as a reference for all untracked frames until tracked frame is hit;
                GapFrames =   obj.LoadedMovie.getGapFrames('backward');
                try
                    obj =         obj.autoTrackCurrentCellForFrames(GapFrames + 1, GapFrames);  
                catch E
                       throw(E)
                end
            end
                            

        function obj =                    autoForwardTrackingOfActiveTrack(obj)
            %  AUTOFORWARDTRACKINGOFACTIVETRACK: forward tracking of active track;
            % tracks from already tracked start mask that is used as a reference for all untracked frames until tracked frame is hit;
            GapFrames =      obj.LoadedMovie.getGapFrames('forward');
             if isempty(GapFrames)
                 warning('No gap found. Therefore no autotracking. You have to find a gap before autotracking is allowed.')
             else
                obj =            obj.autoTrackCurrentCellForFrames(GapFrames - 1, GapFrames );  
             end
        end
        
        
            %% autoTrackingWhenNoMaskInNextFrame
          function obj =                    autoTrackingWhenNoMaskInNextFrame(obj)
              
                TrackingFrames =     obj.LoadedMovie.getActiveFrames : obj.LoadedMovie.getMaxFrame - 1;
                for TrackID = (obj.LoadedMovie.getTrackIDsWhereNextFrameHasNoMask)'
                    obj =                obj.setFrameByNumber(min(TrackingFrames));  
                    obj          =       obj.setActiveTrackTo(TrackID);  
                    drawnow
                    obj =                obj.autoTrackCurrentCellForFrames(TrackingFrames, TrackingFrames + 1);   
                end
                
                obj =              obj.saveMovie;
              
          end
          

          function obj = autoDetectMasksByCircleRecognition(obj)
               fprintf('\nPMMovieController: @autoDetectMasksByCircleRecognition.\n');
                
                [myCellRecognition, MyFrames] =     obj.getAutoCellRecognitionObject;
                if isempty(myCellRecognition) 
                else
                    obj.LoadedMovie =       obj.LoadedMovie.executeAutoCellRecognition(myCellRecognition, MyFrames);
                    obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
                end          
          end
          
           %% autoDetectMasksOfCurrentFrame
          function obj =                    autoDetectMasksOfCurrentFrame(obj)
              
                StartFrame =                obj.LoadedMovie.getActiveFrames;
                mySegmentationCapture =     PMSegmentationCapture(obj);
                mySegmentationCapture =     mySegmentationCapture.setSizeForFindingCellsByIntensity(obj.MaskLocalizationSize);
                for PlaneIndex = 1 : obj.LoadedMovie.getMaxPlane
                    obj =                  obj.resetPlane(PlaneIndex);
                    
                    for FrameIndex = 1 : obj.LoadedMovie.getMaxFrame
                      obj =                     obj.setFrameByNumber(FrameIndex);
                      mySegmentationCapture =   mySegmentationCapture.emptyOutBlackedOutPixels; % don't understand what this does
                     
                     ContinueLoop = true;
                      while ContinueLoop

                        mySegmentationCapture =     mySegmentationCapture.resetWithMovieController(obj);
                        mySegmentationCapture =     mySegmentationCapture.setActiveZCoordinate(PlaneIndex);
                        mySegmentationCapture =     mySegmentationCapture.performAutothresholdSegmentationAroundBrightestAreaInImage;

                        if mySegmentationCapture.testPixelValidity  
                            obj.LoadedMovie =       obj.LoadedMovie.setActiveTrackWith(obj.LoadedMovie.findNewTrackID);
                            obj.LoadedMovie =       obj.LoadedMovie.resetActivePixelListWith(mySegmentationCapture);

                        elseif mySegmentationCapture.getAccumulatedSegmentationFailures <= 10
                        
                        else
                                ContinueLoop = false;
                        end
                        
                      end
                      obj.PressedKeyValue  = '';
                    end
                end
                
                obj =      obj.setFrameByNumber( StartFrame);
                obj =      obj.updateAllViewsThatDependOnActiveTrack;
                
          end
          
               
       
              %% minimizeMasksOfCurrentTrackForFrames
          function obj = minimizeMasksOfCurrentTrack(obj)
                obj =                   obj.minimizeMasksOfCurrentTrackForFrames(obj.getFollowingFramesOfCurrentTrack); 
          end
          
                                  
          
          function obj =                    minimizeMasksOfCurrentTrackForFrames(obj, SourceFrames)
              
                for FrameIndex = 1:length(SourceFrames)
                        obj =                   obj.setFrameByNumber(SourceFrames(FrameIndex));
                        obj.LoadedMovie =       obj.LoadedMovie.minimizeMasksOfActiveTrackAtFrame(FrameIndex);
                        obj =                obj.setActiveCropOfMovieView;
                        obj =                   obj.updateAllViewsThatDependOnActiveTrack;

                    drawnow  

                end
                
          end
    
            %% recreateMasksOfCurrentTrackForFrames
          function obj = recreateMasksOfCurrentTrack(obj)
                    obj =             obj.recreateMasksOfCurrentTrackForFrames(obj.getFollowingFramesOfCurrentTrack);
          end
          

            
                %% addToSelectedTracksTrackIDs
         function obj =      addToSelectedTracksTrackIDs(obj, TracksToAdd)
            obj.LoadedMovie =       obj.LoadedMovie.addToSelectedTrackIds(TracksToAdd);
            obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
         end
         
            

            
            %% recreateMasksOfCurrentTrackForFrames:
            function  obj =                   recreateMasksOfCurrentTrackForFrames(obj, SourceFrames)
              
                AllowedXYShift =            5;
                StopObject =                obj.createStopButtonForAutoTracking;

               SegementationOfReference = obj.getReferenceSegmentation;

                fprintf('\nRecreating masks of track %i has a maximum size of %i pixels\n', SegementationOfReference.getTrackId);
                fprintf('The masks are allowed a maximum of %i pixels\n.', SegementationOfReference.getMaximumPixelNumber);
                fprintf('The allowed shift in X and Y is %i.\n\n', AllowedXYShift);

                for FrameIndex = 1 : length(SourceFrames)

                    fprintf('For frame %i: ', FrameIndex)
                    if ~ishandle(StopObject.Button)
                        break
                    end
                    
                    obj =                               obj.setFrameByNumber(SourceFrames(FrameIndex));
                    SegmentationForPreviousMask =       PMSegmentationCapture(obj);
                    SegmentationForCurrentMask =        obj.getSegmentationByEdgeWithMaxSize(SegementationOfReference);
                    XYDistance =                        obj.getXYDistanceBetween(SegmentationForPreviousMask, SegmentationForCurrentMask);
                    
                    if SegmentationForCurrentMask.getNumberOfPixels < 1 || SegmentationForCurrentMask.getNumberOfPixels > SegementationOfReference.getMaximumPixelNumber
                        
                    elseif XYDistance > AllowedXYShift
                        
                    else
                           fprintf('New mask added.\n');
                           obj.LoadedMovie =                           obj.LoadedMovie.resetActivePixelListWith(SegmentationForCurrentMask);
                    end

                end
                delete(StopObject.ParentFigure)
                obj.LoadedMovie =   obj.LoadedMovie.setFocusOnActiveTrack; 
                obj =               obj.updateAllViewsThatDependOnActiveTrack;
          end
          
          function SegementationOfReference = getReferenceSegmentation(obj)
                SegementationOfReference =   PMSegmentationCapture(obj, obj.LoadedMovie.getActiveChannelIndex);
                SegementationOfReference = applyStandardValuesToSegmentation(obj, SegementationOfReference);
                
          end
          
          function SegementationOfReference = applyStandardValuesToSegmentation(~, SegementationOfReference)
                SegementationOfReference =  SegementationOfReference.setPixelShiftForEdgeDetection(1);
                SegementationOfReference =  SegementationOfReference.setAllowedExcessSizeFactor(1.3);
                SegementationOfReference =  SegementationOfReference.setMaximumCellRadius(15);
                SegementationOfReference =  SegementationOfReference.setMaximumDisplacement(15);
                SegementationOfReference =  SegementationOfReference.setFactorForThreshold(1);
                
          end
          
      
          
          function XYDistance = getXYDistanceBetween(~, SegmentationForPreviousMask, SegmentationForCurrentMask)
                XYDistance = max([abs(SegmentationForPreviousMask.getXCentroid- SegmentationForCurrentMask.getXCentroid)], [abs(SegmentationForPreviousMask.getYCentroid - SegmentationForCurrentMask.getYCentroid)]);
                fprintf('XY distance %6.2.\n', XYDistance)
          end
          
           function ZDistance = getZDistanceBetween(~, SegmentationForPreviousMask, SegmentationForCurrentMask)
                ZDistance = abs(SegmentationForPreviousMask.getZCentroid- SegmentationForCurrentMask.getZCentroid);
                fprintf('Z distance %6.2.\n', ZDistance)
          end
          
          
     
            function SegmentationForCurrentMask = getSegmentationByEdgeWithMaxSize(obj, SegementationOfReference)
                SegmentationForCurrentMask =    PMSegmentationCapture(obj);
                SegmentationForCurrentMask =    SegmentationForCurrentMask.generateMaskByEdgeDetectionForceSizeBelow(SegementationOfReference.getMaximumPixelNumber);
                fprintf('New X= %6.2f. New Y= %6.2f.\n', SegmentationForCurrentMask.getXCentroid, SegmentationForCurrentMask.getYCentroid)
                fprintf('%i pixels.\n', SegmentationForCurrentMask.getNumberOfPixels)
            end
            
            
            
        
    
           function obj = updateHandlesForTrackingNavigationEditView(obj)

                obj.TrackingNavigationEditViewController = obj.TrackingNavigationEditViewController.setCallbacks(...
                        @obj.respondToTrackTableActivity, @obj.respondToActiveFrameClicked, ...
                        @obj.respondToActiveTrackSelectionClicked, @obj.respondToActiveTrackActivity, ...
                        @obj.respondToEditSelectedTrackSelectionClicked, @obj.respondToSelectedTrackActivity ...
                        );
           end

            function obj =   respondToTrackTableActivity(obj,~,a)
                PressedCharacter =               obj.TrackingNavigationEditViewController.getCurrentCharacter;
                
                SelectedIndices = a.Indices(:,1);
                MySelectedTrackIds =             a.Source.Data{SelectedIndices, 1};
                 assert(isnumeric(MySelectedTrackIds) && isvector(MySelectedTrackIds), 'Wrong input.')
                switch PressedCharacter
                        case {'a'}
                             if size(SelectedIndices, 1) == 1
                                 obj =         obj.setActiveTrackTo(MySelectedTrackIds) ;
                             else
                                warning('Active track not reset because multiple selections made.')
                             end
                
                           
                        case {'N','n'}
                            obj =         obj.resetSelectedTracksWithTrackIDs(MySelectedTrackIds);
                        case {'s','S'}
                            obj =         obj.addToSelectedTracksTrackIDs(MySelectedTrackIds);
                end
                    
                
                
               
                
            end

            function obj = respondToActiveFrameClicked(obj,~,~)
                newFrame =        str2double(obj.TrackingNavigationEditViewController.getSelectedFrame);
                 obj  =           obj.setFrameByNumber(newFrame);
            end

            function obj = respondToEditSelectedTrackSelectionClicked(obj,~,~)

            end

            function obj = respondToSelectedTrackActivity(obj,~,~)
                CurrentlyShownActionSelection =  obj.TrackingNavigationEditViewController.getSelectedActionForSelectedTracks;
                switch CurrentlyShownActionSelection
                   case 'Delete tracks'
                        obj  =               obj.tracking_deleteSelectedTracks;
                   case 'Merge tracks'  
                        obj  =               obj.mergeSelectedTracks;
                   case 'Split tracks'
                       obj =                obj.splitSelectedTrack;
                end
                obj =  obj.setTrackingNavigationEditViewController;
            end
            
            function obj = respondToActiveTrackSelectionClicked(obj,~,~)



            end

            function obj = respondToActiveTrackActivity(obj,~,~)

                CurrentlyShownActionSelection =  obj.TrackingNavigationEditViewController.getSelectedActionForActiveTrack;

                switch CurrentlyShownActionSelection

                   case 'Delete active mask'
                       obj = obj.deleteActiveMask;
                   case 'Forward tracking'

                   case 'Backward tracking'

                   case 'Label finished'
                        obj =                             obj.setFinishStatusOfTrackTo('Finished');
                   case 'Label unfinished'
                        obj =                             obj.setFinishStatusOfTrackTo('Unfinished');
                end

            end

            function obj = setMouseDownRow(obj, Value)
                obj.MouseDownRow = Value;
            end

            function obj = setMouseDownColumn(obj, Value)
             obj.MouseDownColumn = Value;
            end

            function obj = setMouseUpRow(obj, Value)
                obj.MouseUpRow = Value;
            end

            function obj = setMouseUpColumn(obj, Value)
                obj.MouseUpColumn = Value;
            end

            
    end
    
    methods (Access = private) % auto cell recognition
        

           function obj = AutoCellRecognitionChannelChanged(obj, ~, third)
               obj.AutoCellRecognitionController = setActiveChannel(obj.AutoCellRecognitionController, third.DisplayIndices(1));
          end
          
          function obj = AutoCellRecognitionFramesChanged(obj, ~, third)
              myFrames =  third.DisplayIndices(:, 1);
              obj.AutoCellRecognitionController = setSelectedFrames(obj.AutoCellRecognitionController, myFrames);
              
          end
          
             function obj = AutoCellRecognitionTableChanged(obj,src,~)
                 obj.AutoCellRecognitionController = obj.AutoCellRecognitionController.setCircleLimitsBy(src.Data);

             end
             
        function obj = startAutoCellRecognitionPushed(obj,~,~)

            switch obj.AutoCellRecognitionController.getUserSelection
                case 'Interpolate plane settings'
                    obj.AutoCellRecognitionController = obj.AutoCellRecognitionController.interpolateCircleRecognitionLimits;

                case 'Circle recognition'
                    obj =                  obj.askUserToDeleteTrackingData;
                    obj.LoadedMovie =      obj.LoadedMovie.setTrackingAnalysis;
                    obj.LoadedMovie =      obj.LoadedMovie.executeAutoCellRecognition(obj.AutoCellRecognitionController.getAutoCellRecognition);
                    
                    obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
                    
            end
           
            
        end
    
          function obj = askUserToDeleteTrackingData(obj)
                DeleteAllAnswer = questdlg('Do you want to delete all existing tracks before autodetection?', 'Cell autodetection');
                switch DeleteAllAnswer
                    case 'Yes'
                        obj =         obj.tracking_deleteAllTracks;
                end
          end
          
          
        
        
    end
    
    methods % vies
       
         function obj =    initializeViews(obj)
            % INITIALIZEVIEWS: updates views of movie controller by state of current LoadedMovie property;
            % sets numerouse views including centroid-visibility, tracking views, movie-view, track-visibility and save-status;

             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                 
                    obj  =          obj.updateControlElements;
                    obj.Views =     setCentroidVisibility(obj.Views, obj.LoadedMovie.getCentroidVisibility);
                    obj.Views =     setTrackingViewsWith(obj.Views, obj.LoadedMovie);
                    % ERROR: THIS LINE SHOULD WORK BUT CAUSES AN ERROR
                  obj.Views =     obj.Views.updateMovieViewWith( obj.LoadedMovie, obj.getRbgImage);
                   %  obj.Views =   updateMovieViewWith(  obj.Views, obj.LoadedMovie, obj.getRbgImage);
                    obj.Views =     updateTrackVisibilityWith(obj.Views, obj.LoadedMovie);
                    obj.Views =     setTrackLineViewsWith(obj.Views, obj.LoadedMovie); 
                    obj =           obj.updateSaveStatusView;
            
             end

         end
        
              function obj =      updateMovieViewImage(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
           obj.Views =     setMovieImagePixels(obj.Views, obj.getRbgImage);
             end
              end
        
                 function obj = blackOutViews(obj)
            if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views=          blackOutMovieView(obj.Views); 
            end
        end
        
        
    end
    
    methods (Access = private) % views

       
        
     
        function obj = activateViews(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
           obj.Views = enableAllViews(obj.Views);
             end
        end
        
        function obj = setDriftCorrectionIndicators(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
            obj.Views =            updateManualDriftIndicatorsWith( obj.Views, obj.LoadedMovie);
             end
        end
         
         
        
        function obj = updateSaveStatusView(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
            obj.Views =     updateSaveStatusWith(obj.Views, obj.LoadedMovie);
             end
        end
        
         function obj = setViewsAfterChangeOfMaximumProjection(obj, Value)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views =     setShowMaximumProjection(obj.Views, Value);
                obj =               obj.updateMovieView;
                obj =               obj.setNavigationControls;
                obj =               obj.setTrackViews;
             end
         end
        
        
        function obj = setNavigationControls(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views =               setNavigationWith(obj.Views, obj.LoadedMovie);
             end
        end

        function obj =      updateMovieView(obj)
             if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                    obj.Views =     updateMovieViewWith(obj.Views, obj.LoadedMovie, obj.getRbgImage);
             end

        end

   
        
        function obj =      resetViewsForCurrentDriftCorrection(obj)

            obj.Views =     setLimitsOfMovieViewWith(obj.Views, obj.LoadedMovie); % reset applied cropping limit (dependent on drift correction)
            obj.Views =     updateDriftWith(obj.Views, obj.LoadedMovie);
            obj  =          obj.updateControlElements; % plane number may change
            obj =           obj.setCroppingRectangle;% crop position may change

            obj =           obj.setNavigationControls;
            obj =           obj.updateMovieView;
            obj.Views =     setTrackLineViewsWith(obj.Views, obj.LoadedMovie);   

            obj.Views =    setSelectedCentroidsWith( obj.Views, obj.LoadedMovie);
            obj.Views =     setActiveCentroidWith(obj.Views, obj.LoadedMovie);
        end

        function obj =      updateAllViewsThatDependOnActiveTrack(obj)
            
         %    obj.LoadedMovie =   obj.LoadedMovie.setFocusOnActiveTrack; 
             
             if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                obj =               obj.setNavigationControls;
                obj.Views =         setTrackingViewsWith(obj.Views, obj.LoadedMovie);
                obj =               obj.updateAllViewsThatDependOnSelectedTracks;
                
                obj =                obj.setActiveCropOfMovieView;
                
             end

        end

        function obj =      setActiveCropOfMovieView(obj)
            obj =               obj.setCroppingRectangle;
            obj.Views =         obj.Views.setLimitsOfMovieViewWith(obj.LoadedMovie);
        end
        
        function obj = setCroppingRectangle(obj)
            if ~isempty(obj.Views)  && isvalid(getFigure(obj.Views))
                obj.Views =        setRectangleWith(obj.Views, obj.LoadedMovie);
            end
        end

        function obj =      updateAllViewsThatDependOnSelectedTracks(obj)

        %   obj.LoadedMovie = obj.LoadedMovie.generalCleanup;

            obj.Views =     setSelectedCentroidsWith(obj.Views, obj.LoadedMovie);
            obj.Views =     setActiveCentroidWith(obj.Views, obj.LoadedMovie);

            obj.Views =     setTrackingViewsWith(obj.Views, obj.LoadedMovie);
            obj =           obj.updateMovieViewImage;

            obj.TrackingNavigationEditViewController =     obj.TrackingNavigationEditViewController.resetModelWith(obj.LoadedMovie.getTracking);

        end

        function obj =      setTrackViews(obj)
            %  obj.LoadedMovie =   obj.LoadedMovie.generalCleanup; % should be removed when confidence that this is not necessary
            if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
              obj.Views =         setTrackLineViewsWith(obj.Views, obj.LoadedMovie); 
                obj =                 obj.updateAllViewsThatDependOnActiveTrack;
            end

        end

        function obj =      updateControlElements(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
         obj.Views  =    setControlElements(obj.Views, obj.LoadedMovie); % plane number may change
             end
        end

        function obj =      highlightMousePositionInImage(obj)

            [rowPos, columnPos, ~, ~] =   obj.getCoordinatesOfCurrentMousePosition;
            OldImage =                              obj.Views.getMovieImage.CData;
            OldImage(rowPos, columnPos,:) =         255;
            obj.Views =                             obj.Views.setMovieImagePixels(OldImage);

        end

        function [check] =  pointIsWithinImageAxesBounds(obj, CurrentRow, CurrentColumn)

        if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))

            XLimMin =                 obj.Views.getMovieAxes.XLim(1);
            XLimMax =                 obj.Views.getMovieAxes.XLim(2);
            YLimMin =                 obj.Views.getMovieAxes.YLim(1);
            YLimMax =                 obj.Views.getMovieAxes.YLim(2);

            if min(CurrentColumn >= XLimMin) && min(CurrentColumn <= XLimMax) && min(CurrentRow >= YLimMin) && min(CurrentRow <= YLimMax)
                check = true;

            else
                check = false;

            end

        else
          check = false;

        end


        end

        function obj =                            highLightRectanglePixelsByMouse(obj)

                if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)

                    coordinates =        obj.getCoordinateListByMousePositions;

                    yCoordinates =       coordinates(:,2);
                    xCoordinates =       coordinates(:,1);

                    HighlightedChannel =       1;
                    OldImage =      obj.Views.getMovieImage.CData;
                    OldImage(:, :, HighlightedChannel) = 0;
                    OldImage(round(min(yCoordinates) : max(yCoordinates)), round(min(xCoordinates) : max(xCoordinates)), HighlightedChannel) = 200;

                    obj.Views =         obj.Views.setMovieImagePixels(OldImage);

                end

         end
         
        function obj =             resetWidthOfMovieAxesToMatchAspectRatio(obj)
            if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                XLength =                   obj.Views.getMovieAxes.XLim(2)- obj.Views.getMovieAxes.XLim(1);
                YLength =                   obj.Views.getMovieAxes.YLim(2)- obj.Views.getMovieAxes.YLim(1);
                LengthenFactorForX =        XLength/  YLength;
                obj.Views =                 obj.Views.setMovieAxesWidth(obj.Views.getMovieAxes.Position(4) * LengthenFactorForX);
            end
        end
        
        function obj = resetAxesCenter(obj, xShift, yShift)
            obj.Views = obj.shiftAxes(xShift, yShift);
            
        end
        
        function obj = setFrameBySlider(obj)
            MyNumber = round(obj.Views.Navigation.TimeSlider.Value);
            obj = obj.setFrameByNumber(MyNumber);
        end
         
        
        





    end

    methods% views: set mouse positions
       
         function obj = setMouseEndPosition(obj)
                if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                    obj =          obj.setMouseUpRow(obj.getCurrentMouseRow);
                    obj =          obj.setMouseUpColumn(obj.getCurrentMouseColumn);
                end
            end
        
    end
    
    methods (Access = private) % views: set mouse positions
        
           

            function position = getCurrentMouseRow(obj)
                position =  obj.Views.getMovieAxes.CurrentPoint(1,2);
            end

            function position = getCurrentMouseColumn(obj)
                position =  obj.Views.getMovieAxes.CurrentPoint(1,1);
            end

    end
    
    methods % mouse action

    function [Category] =                         interpretMouseMovement(obj)

        if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)


          if isempty(obj) || isempty(obj.MouseDownRow) || isempty(obj.MouseDownColumn) 
              Category =      'Invalid';

          elseif isnan(obj.MouseDownRow) || isnan(obj.MouseDownColumn)
              Category = 'Invalid';

          else

                if obj.pointIsWithinImageAxesBounds([obj.MouseDownRow, obj.getCurrentMouseRow], [obj.MouseDownColumn, obj.getCurrentMouseColumn])
                    if (obj.MouseDownRow == obj.MouseUpRow) && (obj.MouseDownColumn ==  obj.MouseUpColumn)
                        Category = 'Stay';
                    else
                        Category = 'Movement';
                    end

                else
                    Category = 'Out of bounds';

                end
          end

        else
            Category =      'NoActiveView';

        end

    end

    function [obj] =          myMouseButtonWasJustPressed(obj,~,~)
        obj = obj.mouseButtonPressed(obj.Views.getPressedKey, obj.Views.getRawModifier);
    end

    function obj = mouseButtonPressed(obj, PressedKey, Modifier)    %% get mouse action (defined by key press during button down); 
         mouseController =      PMMovieController_MouseAction(obj, PressedKey, Modifier);
         obj =                  mouseController.mouseButtonPressed;
    end

    function [obj] =          myMouseJustMoved(obj,~,~)
        obj = obj.mouseMoved(obj.Views.getPressedKey, obj.Views.getRawModifier);
    end

    function obj = mouseMoved(obj, PressedKey, Modifier)    %% get mouse action (defined by key press during button down); 
        if strcmp(obj.getMouseAction, 'No action')
        else
               mouseController =      PMMovieController_MouseAction(obj, PressedKey, Modifier);   
                obj =                  mouseController.mouseMoved;
        end
    end

    function [obj] =          myMouseButtonWasJustReleased(obj,~,~)
        obj = obj.mouseButtonReleased(obj.Views.getPressedKey, obj.Views.getRawModifier);
    end

    function obj = mouseButtonReleased(obj, PressedKey, Modifier)    %% get mouse action (defined by key press during button down); 
         mouseController =      PMMovieController_MouseAction(obj, PressedKey, Modifier);
         obj =                  mouseController.mouseButtonReleased;
    end




    end

    methods (Access = private)% callbacks

    function obj = setCallbacks(obj)

        if isempty(obj.Views)
            % sometimes no controller without views is more useful: in this case do not attempt to set callbacks;
        else
            obj = obj.setNavigationCallbacks;
            obj = obj.setChannelCallbacks;
            obj = obj.setAnnotationCallbacks;
            obj = obj.setTrackingCallbacks;
        end

    end

    end

    methods (Access = private) % navigation callbacks

        function obj =      setNavigationCallbacks(obj)
             obj.Views  =    obj.Views.setNavigationCallbacks(...
                                 @obj.editingOptionsClicked, ...
                                @obj.planeViewClicked, ...
                                 @obj.frameViewClicked, ...
                                 @obj.maximumProjectionClicked, ...
                                 @obj.croppingOnOffClicked, ...
                                 @obj.driftCorrectionOnOffClicked ...
                );

        end

        function obj =      editingOptionsClicked(obj, ~, ~)
           obj =           obj.updateMovieView;

        end

        function obj =      planeViewClicked(obj,~,~)
            obj  =          obj.resetPlane(obj.Views.getCurrentPlanes);
        end

   

        function obj =      frameViewClicked(obj,~,~)
            obj  =                  obj.setFrameByNumber(obj.Views.getCurrentFrames);
        end

        function obj =      maximumProjectionClicked(obj,~,~)
          obj.LoadedMovie =     obj.LoadedMovie.setCollapseAllPlanes(obj.Views.getShowMaximumProjection);
          obj =           obj.updateMovieView;

        end

        function obj =      croppingOnOffClicked(obj,~,~)
            obj.LoadedMovie =    obj.LoadedMovie.setCroppingStateTo(obj.Views.getCropImage);
            obj =                obj.resetViewsForCurrentCroppingState;
        end

        function obj =      resetViewsForCurrentCroppingState(obj)
            obj.Views =     obj.Views.setLimitsOfMovieViewWith(obj.LoadedMovie); % reset applied cropping limit (dependent on drift correction)
             obj =               obj.setCroppingRectangle; % crop position may change
            obj =           obj.updateMovieView;
        end

        function obj =      driftCorrectionOnOffClicked(obj,~,~)
           obj =                obj.setDriftCorrectionTo(obj.Views.getApplyDriftCorrection);  
        end

    end


    methods % callbacks for key and mouse (optional: can be taken over from other sides

        function obj = setKeyAndMouseCallbacks(obj)
            obj.Views = obj.Views.setKeyMouseCallbacks(@obj.keyPressed, @obj.myMouseButtonWasJustPressed, @obj.myMouseButtonWasJustReleased, @obj.myMouseJustMoved);

        end

        function [obj] =           keyPressed(obj,~,~)

            obj.interpretKey(obj.Views.getPressedKey, obj.Views.getRawModifier);
            obj.Views = obj.Views.setCurrentCharacter('0');

        end
        
         function [obj] =    interpretKey(obj, PressedKey, CurrentModifier)
                obj.PressedKeyValue =       PressedKey;  
               obj =                       PMMovieController_Keypress(obj).processKeyInput(obj.PressedKeyValue, CurrentModifier);

                obj.PressedKeyValue = '';
         end
      
        

    end

    methods (Access = private) % tracking callbacks:

        function obj = setTrackingCallbacks(obj)
         obj.Views  =    obj.Views.setTrackingCallbacks(...
                                @obj.trackingActiveTrackButtonClicked, ...
                                @obj.trackingCentroidButtonClicked, ...
                                @obj.trackingShowMaskButtonClicked, ...
                                @obj.trackingShowTracksButtonClicked, ...
                                @obj.trackingShowMaximumProjectionButtonClicked ...
                                 );
        end

        function [obj] =       trackingActiveTrackButtonClicked(obj,~,~)
        obj.LoadedMovie =   obj.LoadedMovie.setActiveTrackIsHighlighted(obj.Views.getShowTrackingOfActiveTrack);
        obj =          obj.initializeViews;
        obj =           obj.updateMovieView;

        end

        function [obj] =      trackingCentroidButtonClicked(obj,~,~)
            obj =               obj.setCentroidVisibilityByLogical(obj.Views.getShowCentroids);
        end
        
        function obj = setCentroidVisibilityByLogical(obj, Value)
            assert(islogical(Value), 'Wrong input type')
            obj.LoadedMovie =   obj.LoadedMovie.setCentroidVisibility(Value);
            obj =           obj.initializeViews;
        end
 
        function [obj] =      trackingShowMaskButtonClicked(obj,~,~)
        obj.LoadedMovie =       obj.LoadedMovie.setMaskVisibility(obj.Views.getShowMasks);
         obj =          obj.initializeViews;
         obj =           obj.updateMovieView;

        end

        function [obj] =      trackingShowTracksButtonClicked(obj,~,~)
            obj.LoadedMovie =   obj.LoadedMovie.setTrackVisibility(obj.Views.getShowTracks);
             obj =               obj.initializeViews;
        end

        function [obj] =      trackingShowMaximumProjectionButtonClicked(obj,~,~)
         obj =            obj.setCollapseTracking(obj.Views.getShowMaxProjectionOfTrackingData);
        end

    end

    methods (Access = private) % annotation callbacks

    function obj = setAnnotationCallbacks(obj)
        obj.Views  =        obj.Views.setAnnotationCallbacks(...
                                @obj.annotationScaleBarOnOffClicked, @obj.annotationScaleBarSizeClicked);
    end

    function [obj] =         annotationScaleBarOnOffClicked(obj,~,~)
        obj =           obj.updateMovieView;
    end

    function [obj] =         annotationScaleBarSizeClicked(obj,~,~)
        obj.LoadedMovie =       obj.LoadedMovie.setScaleBarSize(obj.Views.getScalbarSize);
        obj =                   obj.updateMovieView;

    end




    end

    
    methods % view setters
         function obj = setViews(obj, Value, varargin)
           
                FunctionName = ['view_', Value];
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 1
                        obj = obj.(FunctionName)(varargin{1});
                    otherwise
                        error('Wrong input.')
                end

         end 
        
    end
    methods (Access = private) % different view setters:

       
             
        function obj = view_trackVisibility(obj, Value)
            switch Value
             case 'toggle'
                obj =  obj.toggleTrackVisibility;
             otherwise
                 error('Wrong input.')
            end


        end
        
         function obj =    toggleTrackVisibility(obj)
            obj.LoadedMovie =   obj.LoadedMovie.toggleTrackVisibility;
            obj =               obj.initializeViews;

         end
         

        function obj = view_CroppingGate(obj, Value)
            switch Value
             case 'changePositionByMouseDrag'
                obj =       obj.setCroppingGateByMouseDrag;
              case 'changeToDefault'
                  obj = setDefaultCroppingGate(obj);
              otherwise
                  error('Wrong input.')
            end

        end

        function obj = setDefaultCroppingGate(obj)
            obj.LoadedMovie =         obj.LoadedMovie.resetCroppingGate;
             obj =               obj.setCroppingRectangle;
        end


        function obj = setCroppingGateByMouseDrag(obj)
            obj.LoadedMovie =   obj.LoadedMovie.setCroppingGateWithRectange(obj.getRectangleFromMouseDrag);
             obj =               obj.setCroppingRectangle;
        end

        function obj = view_CroppingOn(obj, Value)
            switch Value
             case 'toggle'
                obj.LoadedMovie =       obj.LoadedMovie.setCroppingStateTo(~obj.Views.getCropImage);
                obj =                   obj.resetViewsForCurrentCroppingState;
              otherwise
                  error('Wrong input.')
            end

        end

        function obj = view_channelVisibility(obj, Value)
            switch Value
             case 'toggleByKeyPress'

                 PressedKey = obj.PressedKeyValue;
                 obj = toggleVisibilityOfChannelIndex(obj, str2double(PressedKey));

             otherwise
                 error('Wrong input.')
            end


        end

        function obj = view_timeAnnotationVisibility(obj, Value)
            switch Value
             case 'toggle'
                obj =  toggleTimeVisibility(obj);
             otherwise
                 error('Wrong input.')
            end


        end

        function obj = toggleTimeVisibility(obj)
            obj.LoadedMovie =   obj.LoadedMovie.setTimeVisibility(~obj.LoadedMovie.getTimeVisibility);
            obj =           obj.updateMovieView;
        end

        function obj =  toggleScaleBarVisibility(obj)
            obj.LoadedMovie =      obj.LoadedMovie.toggleScaleBarVisibility;
            obj =           obj.updateMovieView;

        end

        function obj = view_planeAnnotationVisibility(obj, Value)

            switch Value
                case 'toggle'
                    obj.LoadedMovie =      obj.LoadedMovie.setPlaneVisibility( ~obj.LoadedMovie.getPlaneVisibility);
                    obj =           obj.updateMovieView;
                otherwise
                    error('Wrong input.')
            end


        end

        function obj = view_maskVisibility(obj, Value)
            Type = class(Value);
            switch Type
            case 'char'
                switch Value
                    case 'toggle'
                        obj = obj.toggleMaskVisibility;
                    otherwise
                        error('Wrong input.')

                end

            otherwise
                error('Wrong input.')
            end



        end

        function obj = view_centroidVisibility(obj, Value)
            Type = class(Value);
            switch Type
            case 'char'
                switch Value
                    case 'toggle'
                        obj = obj.toggleCentroidVisibility;
                    otherwise
                        error('Wrong input.')

                end
            case 'logical'
                obj = setCentroidVisibilityByLogical(obj, Value);
            otherwise
                error('Wrong input.')
            end



        end

        function obj = toggleMaskVisibility(obj)
            obj.LoadedMovie =      obj.LoadedMovie.toggleMaskVisibility  ; 
            obj =          obj.initializeViews;
            obj =           obj.updateMovieView;


        end

        function obj = toggleCentroidVisibility(obj)
            obj.LoadedMovie =   obj.LoadedMovie.toggleCentroidVisibility;
            obj =           obj.initializeViews;

        end

    end

    methods (Access = private) % track views
       
        function obj = setSegmentLineViews(obj, DistanceLimit, MinTimeLimit, MaxTimeLimit, Visibility)
            % SETSEGMENTLINEVIEWS: graphically depcits stop- and go-segments of tracks;
            % takes for arguments:
            % 1: stop-distance limit
            % 2: minimum time-limit for stop
            % 3: maximum time-limit
            % 4: visibility(true/false; false: no segments are depcicted)

            if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)

                if ~Visibility
                    MyStopCoordinates = cell(0, 3);
                    MyGoCoordinates = cell(0, 3);

                else
                    [StopTracks, GoTracks] = obj.getStopGoTrackSegments(DistanceLimit, MinTimeLimit, MaxTimeLimit);
                    MyGoCoordinates=       cellfun(@(x) cell2mat([x(:,4), x(:, 3), x(:, 5)]), StopTracks, 'UniformOutput', false);
                    MyStopCoordinates =    cellfun(@(x) cell2mat([x(:,4), x(:, 3), x(:, 5)]),  GoTracks, 'UniformOutput', false);
                end

                obj.Views = obj.Views.setSegmentLineViews(MyStopCoordinates, MyGoCoordinates);

            end

        end

        function setLineColorTo(~,Handle,Color)
            Handle.Color =          Color;
        end

    end
  
end

