classdef PMMovieController < handle
    %PMMOVIETRACKINGSTATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        
    end
    
    properties (Access = private)
        LoadedMovie
        Views
        
        
        
        MouseAction =                        'No action';
        
        LoadedImageVolumes   =                          cell(0,1) % saving image information (saves actual images and settings for how many images should be loaded)
        DefaultNumberOfLoadedFrames =                   40
        PressedKeyValue 
        MouseDownRow =                                  NaN
        MouseDownColumn =                               NaN
        MouseUpRow =                                    NaN
        MouseUpColumn =                                 NaN
        
        MaskLocalizationSize =                          5; % info for segmentation (this could potentially be expanded or moved to MovieTracking
      
        TrackingViews
        TrackingAutoTrackingController =                PMTrackingNavigationAutoTrackController
        TrackingNavigationEditViewController =          PMTrackingNavigationEditViewController
        AutoCellRecognitionController
        
        
        MaskColor =                                     [NaN NaN 150]; % some settings for how 

        
    end
    
    methods
        
        
        function obj =          PMMovieController(varargin)
            fprintf('@Create PMMovieController ')
            if ~isempty(varargin) % input should be movie controller views
                switch length(varargin)
                    case 0 
                    case 1 % only connected movies
                        Input =     varargin{1};
                        if strcmp(class(Input), 'PMImagingProjectViewer')
                            fprintf('from PMImagingProjectViewer\n')
                            obj.Views =                                                   Input.MovieControllerViews;
                            obj.Views.Figure =                                            Input.Figure;   
                            
                            obj.TrackingViews =                                           Input.TrackingViews.ControlPanels;
                            obj.Views.changeAppearance;

                            obj.Views.disableAllViews;
                            obj.Views =                                                         obj.Views.deleteAllTrackLineViews;

                     
                            
                        else
                            ViewObject =                                                         Input;
                            obj.Views =                                                     ViewObject;
                            obj.Views.Figure =                                              ViewObject.Figure;  
                        end
                        
                        obj =   obj.setCallbacks;
                        
                    case 2 % connected views and movie
                         ViewObject =                                                         varargin{1};
                         if isnumeric(ViewObject) || isempty(ViewObject) 
                         else
                            obj.Views =                                                     ViewObject;
                            obj.Views.Figure =                                              ViewObject.Figure;  
                            obj =   obj.setCallbacks;
                         end
                        obj.LoadedMovie =                                           varargin{2};
                end
                
                if ~isempty(obj.LoadedMovie)
                    obj    =                obj.emptyOutLoadedImageVolumes; 
                    obj.LoadedMovie =       obj.LoadedMovie.setImageMapDependentProperties;
                end
                
            end
        end
        
        %% updateWith
        function obj = updateWith(obj, Value)
            if isempty(obj.LoadedMovie)
                warning('Could not update LoadedMovie because the property was not set yet.')
            else
                 Type = class(Value);
                switch Type
                    case 'PMMovieLibrary'
                        obj.LoadedMovie = obj.LoadedMovie.setImageAnalysisFolder(Value.getPathForImageAnalysis);
                    otherwise
                        error('Cannot parse input.')

                end
                
            end
            
           
            
            
        end
        
        %% accessors:
        function Value = getNickName(obj)
            Value = obj.LoadedMovie.getNickName;
        end
        
        
        function obj = setNickName(obj, Value)
            obj.LoadedMovie =       obj.LoadedMovie.setNickName(Value);
            obj =                   obj.updateSaveStatusView;  
        end
        
        function view = getViews(obj)
           view = obj.Views; 
        end
        
         function obj = setKeywords(obj, Value)
             obj.LoadedMovie = obj.LoadedMovie.setKeywords(Value); 
          end

          function obj = setChannels(obj, Value)
              obj.LoadedMovie = obj.LoadedMovie.setChannels(Value);
          end
        
        %% saveMovie
        function obj = saveMovie(obj)
               if ~isempty(obj.LoadedMovie)  && strcmp(class(obj.LoadedMovie), 'PMMovieTracking')
                    obj.LoadedMovie =           obj.LoadedMovie.saveMovieDataWithOutCondition;
                    obj =                       obj.updateSaveStatusView;  
                    
               else
                    fprintf('No valid LoadedMovie available: therefore no action taken.\n')
               end
   
        end
        
        %% exportTrackCoordinates
        function obj = exportTrackCoordinates(obj)
             [file,path] =                   uiputfile([obj.LoadedMovie.getNickName, '.csv']);
            TrackingAnalysisCopy =         obj.LoadedMovie.getTrackingAnalysis;
            TrackingAnalysisCopy =         TrackingAnalysisCopy.convertDistanceUnitsIntoUm;
            TrackingAnalysisCopy =         TrackingAnalysisCopy.convertTimeUnitsIntoSeconds;
            TrackingAnalysisCopy.exportTracksIntoCSVFile([path, file], obj.LoadedMovie.getNickName)
            
            
        end
        
        %% changeLinkedMoviesClicked
          function [obj] =            setNamesOfMovieFiles(obj, Value)
              obj.LoadedMovie =       obj.LoadedMovie.setNamesOfMovieFiles(Value);
           end
        
        function movie = getLoadedMovie(obj)
            movie = obj.LoadedMovie;
        end
      
        %% goOneFrameDown
        function obj = goOneFrameDown(obj)
            if obj.LoadedMovie.getActiveFrames > 1
                obj =             obj.resetFrame(obj.LoadedMovie.getActiveFrames - 1);
            end
        end
                    
        
       %% goOneFrameUp
       function obj = goOneFrameUp(obj)
            if obj.LoadedMovie.getActiveFrames < obj.LoadedMovie.getMaxFrame
                obj =                       obj.resetFrame(obj.LoadedMovie.getActiveFrames + 1);
            else
                obj =                       obj.resetFrame( 1);
            end

       end
       
        function [obj]  =                       resetFrame(obj, newFrame)
                if isnan(newFrame) || newFrame<1 || newFrame>obj.LoadedMovie.getMaxFrame
                else
                    PlaneAndCropShouldBeReset =                length( obj.Views.Figure.CurrentModifier)== 1 && strcmp(obj.Views.Figure.CurrentModifier{1}, 'shift');
                    if PlaneAndCropShouldBeReset
                        obj.LoadedMovie =        obj.LoadedMovie.setFrameAndAdjustPlaneAndCropByTrack(newFrame); 
                        obj =                    obj.updateCroppingLimitView;
                        obj =                    obj.resetLimitsOfImageAxesWithAppliedCroppingGate;
                    else
                        obj.LoadedMovie =        obj.LoadedMovie.setFrameTo(newFrame);       
                    end

                    obj =      obj.updateImageView; 
                    obj =      obj.updateNavigationViews;    
                end
        end
            
        %%  setManualDriftCorrectionByTimeSpaceCoordinates  
         function [obj]  =                setManualDriftCorrectionByTimeSpaceCoordinates(obj, coordinates)
                NewDriftCorrection =        obj.LoadedMovie.getDriftCorrection.updateManualDriftCorrectionByValues(coordinates(2), coordinates(3), coordinates(4), coordinates(1));
                obj.LoadedMovie =           obj.LoadedMovie.setDriftCorrection(NewDriftCorrection);
                obj  =                      obj.updateManualDriftCorrectionView;
         end
        
         %% setDefaultCroppingGate
         function obj = setDefaultCroppingGate(obj)
                obj.LoadedMovie =         obj.LoadedMovie.resetCroppingGate;
                obj =                     obj.updateCroppingLimitView;
                                            
         end
            
        %%    setCroppingGateByMouseDrag
        function obj = setCroppingGateByMouseDrag(obj)
                obj.LoadedMovie =       obj.LoadedMovie.setCroppingGateWithRectange(obj.getRectangleFromMouseDrag);
                obj =                   obj.updateCroppingLimitView;
        end
                                        
         
         %% other:
          function obj =        setMovieTracking(obj, Value)
                assert(isa(Value, 'PMMovieTracking') && isscalar(Value), 'Wrong argument type.')
                obj.LoadedMovie = Value;
          end

          function obj =        setLoadedImageVolumes(obj, Value)
              if isempty(Value)
                  
              else
                   assert(iscell(Value) && size(Value, 1) == obj.LoadedMovie.getMaxFrame && size(Value, 2) == 1, 'Invalid argument type.')
                  obj.LoadedImageVolumes =      Value; 
              end
          end
             
          %% various
          function action = getMouseAction(obj)
             action = obj.MouseAction;
          end
          
          function obj = setMouseAction(obj, Value)
             obj.MouseAction = Value;
          end
          
          function obj = setMouseDownRow(obj, Value)
             obj.MouseDownRow = Value;
          end
          
          function Value = getMouseDownRow(obj)
             Value = obj.MouseDownRow;
          end
          
          function Value = getMouseDownColumn(obj)
             Value = obj.MouseDownColumn;
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
          
          function Value = getMouseUpColumn(obj)
             Value = obj.MouseUpColumn;
          end
          
           function Value = getMouseUpRow(obj)
             Value = obj.MouseUpRow;
          end
          
               
          %% finalizeMovieController:
            function [obj] =      finalizeMovieController(obj)
                obj =           obj.initializeNavigationViews;
                obj =           obj.updateChannelSettingView; % changes the display of settings of selected channel;
                obj =           obj.updateAllTrackingViews;
                obj =           obj.updateSaveStatusView;
          end
        
            function obj =        initializeNavigationViews(obj)
                if isempty( obj.Views.Navigation)
                    return 
                end
                obj = obj.initializeTimeNavigation;
                obj = obj.initializePlaneNavigation;
                obj = obj.intializeChannelNavigation;
          end
          
            function obj =        initializeTimeNavigation(obj)
                obj.Views = obj.Views.setMaxTime(obj.LoadedMovie.getMaxFrame);
          end
          
            function obj =       initializePlaneNavigation(obj)
                [~, ~, planes ] =                                       obj.LoadedMovie.getImageDimensionsWithAppliedDriftCorrection;
                obj.Views.Navigation.CurrentPlane.String =              1:planes;
                if obj.Views.Navigation.CurrentPlane.Value<1 || obj.Views.Navigation.CurrentPlane.Value>length(obj.Views.Navigation.CurrentPlane.String)
                    obj.Views.Navigation.CurrentPlane.Value = 1;
                end
           end
          
            function obj =          updateChannelSettingView(obj)
              obj.Views =     obj.Views.resetChannelViewsByMovieTracking(obj.LoadedMovie);
            
       
            end
        
            function obj =        intializeChannelNavigation(obj)
                obj.Views.Channels.SelectedChannel.String =            1:obj.LoadedMovie.getMaxChannel;
                if obj.Views.Channels.SelectedChannel.Value<1 || obj.Views.Channels.SelectedChannel.Value>length(obj.Views.Channels.SelectedChannel.String)
                    obj.Views.Channels.SelectedChannel.Value = 1;
                end
          end
          
            function obj =      updateAllTrackingViews(obj)
                fprintf('\nEnter PMMovieController:@updateAllTrackingViews:\n')
                obj.TrackingViews.ShowMaximumProjection.Value =    obj.LoadedMovie.getCollapseAllTracking;
                obj =         obj.updateCentroidVisibility;
                obj =         obj.updateMaskVisibility;
                obj =         obj.updateTrackVisibility;
                obj =         obj.updateHighlightingOfActiveTrack;
                obj =         obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
                fprintf('Exit PMMovieController:@updateAllTrackingViews.\n\n')

            end
            
             %% other:
            function obj =      updateHighlightingOfActiveTrack(obj)
                ActiveTrackShouldBeHighlighted =                                      obj.LoadedMovie.getActiveTrackIsHighlighted;
                obj.TrackingViews.ActiveTrack.Value =                                ActiveTrackShouldBeHighlighted;
                if isnan(obj.LoadedMovie.getIdOfActiveTrack)
                   obj.Views.MovieView.CentroidLine_SelectedTrack.Visible =         false;
                else
                   obj.Views.MovieView.CentroidLine_SelectedTrack.Visible =         ActiveTrackShouldBeHighlighted;

                end
            end
            
            %% setTrackLineViews
            function obj =       setTrackLineViews(obj, TrackNumbersInModel)
                obj.Views =     obj.Views.addMissingTrackLineViews(TrackNumbersInModel);
                obj.Views =     obj.Views.deleteNonMatchingTrackLineViews(TrackNumbersInModel);
                obj =           obj.setTrackLines(obj.Views.getHandlesForTrackIDs(obj.LoadedMovie.getIdOfActiveTrack), 3);
                obj =           obj.setTrackLines(obj.Views.getHandlesForTrackIDs(obj.LoadedMovie.getTracking.getIdsOfRestingTracks), 0.5);
                obj =           obj.setTrackLines(obj.Views.getHandlesForTrackIDs(obj.LoadedMovie.getSelectedTrackIDs), 1);
            end

            function obj =      setTrackLines(obj, TrackHandles, Width)
                cellfun(@(x) obj.setLineWidthTo(x, Width), TrackHandles)
                CoordinatesSelected =               arrayfun(@(x) obj.getCoordinatesForTrack(x), obj.Views.getIdsFromTrackHandles(TrackHandles), 'UniformOutput', false);
                if ~isempty(CoordinatesSelected)
                    cellfun(@(handles, coordinates) obj.Views.updateTrackLineCoordinatesForHandle(handles, coordinates), TrackHandles, CoordinatesSelected);
                end
            end

            function            setLineWidthTo(obj,Handle,Width)
                Handle.LineWidth =          Width; 
            end
            
            function coordinates =           getCoordinatesForTrack(obj,TrackID)  
                coordinates = obj.LoadedMovie.getCoordinatesForTrack(TrackID);
            end
          
            
            function obj =           resetAllTrackViews(obj)  
                obj =      obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs); % this should not be necessary anymore because the updates are made right away;
            end
            
            
            %% updateSaveStatusView
             function obj =                  updateSaveStatusView(obj)
            
                 fprintf('PMMovieController:@updateSaveStatusView: ')
                 if isempty(obj.LoadedMovie)
                     fprintf('No active movie detected: no action taken.\n')
                     
                 else
                    switch obj.LoadedMovie.getUnsavedDataExist
                        case true
                            fprintf('Unsaved data exist: Set color to red.\n')
                            obj.TrackingViews.TrackingTitle.ForegroundColor = 'red';

                        otherwise
                            fprintf('All relevant data are already saved: Set color to green.\n')
                            obj.TrackingViews.TrackingTitle.ForegroundColor = 'green';

                    end
                 end
             end
             
             
             %% toggleCroppingOn
             function obj = toggleCroppingOn(obj)
                obj.LoadedMovie =       obj.LoadedMovie.setCroppingStateTo(~obj.Views.Navigation.CropImageHandle.Value);
                obj =                   obj.resetViewsForCurrentCroppingState;
             end
             
               function obj =       resetViewsForCurrentCroppingState(obj)
                obj =          obj.resetLimitsOfImageAxesWithAppliedCroppingGate; % reset applied cropping limit (dependent on drift correction)
                obj =          obj.updateCroppingLimitView; % crop position may change
                obj =          obj.updateAnnotationViews;  % adjust position of annotation within views
                obj =          obj.updateImageHelperViewsMore;

             end

             function obj =       resetLimitsOfImageAxesWithAppliedCroppingGate(obj)
                    obj.Views.MovieView.ViewMovieAxes.XLim =    PMRectangle(obj.LoadedMovie.getAppliedCroppingRectangle).getXLimits;
                    obj.Views.MovieView.ViewMovieAxes.YLim =     PMRectangle(obj.LoadedMovie.getAppliedCroppingRectangle).getYLimits;

             end

             function [obj] =      updateCroppingLimitView(obj)
                MyRectangleView =           obj.Views.MovieView.Rectangle;
                MyRectangleView.Visible =   'on';
                MyRectangleView.YData=      obj.LoadedMovie.getYPointsForCroppingRectangleView;
                MyRectangleView.XData=      obj.LoadedMovie.getXPointsForCroppingRectangleView;
                MyRectangleView.Color =     'w';
             end

        
            %%   togglePlaneAnnotationVisibility
             function obj = togglePlaneAnnotationVisibility(obj)
                    obj.LoadedMovie =      obj.LoadedMovie.setPlaneVisibility( ~obj.LoadedMovie.getPlaneVisibility);
                    obj =                  obj.updateAnnotationViews;            
             end
                 
             %% toggleTimeVisibility
             function obj = toggleTimeVisibility(obj)
                        obj.LoadedMovie =   obj.LoadedMovie.setTimeVisibility(~obj.LoadedMovie.getTimeVisibility);
                        obj =               obj.updateAnnotationViews; 
             end

            %% toggleCentroidVisibility
            function obj = toggleCentroidVisibility(obj)
                obj.LoadedMovie =   obj.LoadedMovie.toggleCentroidVisibility;
                obj =               obj.updateCentroidVisibility;  
                
            end
                                    
            
            function obj =      updateCentroidVisibility(obj)
                fprintf('PMMovieController:@updateCentroidVisibility.\n')
                obj.TrackingViews.ShowCentroids.Value =        obj.LoadedMovie.getCentroidVisibility;
                obj.Views.MovieView.CentroidLine.Visible =      obj.LoadedMovie.getCentroidVisibility;

            end
          
            %% toggleMaskVisibility
            function obj = toggleMaskVisibility(obj)
                obj.LoadedMovie =      obj.LoadedMovie.toggleMaskVisibility  ; 
                obj =                  obj.updateMaskVisibility;
                
            end

            function obj =      updateMaskVisibility(obj)
                obj.TrackingViews.ShowMasks.Value =                 obj.LoadedMovie.getMaskVisibility;
                obj =                                               obj.updateImageView; 
            end
            
            %% toggleTrackVisibility
            function obj =    toggleTrackVisibility(obj)
                obj.LoadedMovie =          obj.LoadedMovie.toggleTrackVisibility;
                obj =                      obj.updateTrackVisibility;
                
            end

            function obj =      updateTrackVisibility(obj)
                function track = changeTrackVisibility(track, state)
                    track.Visible = state;
                end
                obj.TrackingViews.ShowTracks.Value =        obj.LoadedMovie.getTrackVisibility;
                cellfun(@(x) changeTrackVisibility(x, obj.LoadedMovie.getTrackVisibility), obj.Views.ListOfTrackViews);
            end
            
           
           
        %% callbacks:

        function obj = setCentroidVisibility(obj, Value)
            assert(islogical(Value), 'Wrong input type')
            obj.LoadedMovie = obj.LoadedMovie.setCentroidVisibility(Value);
            obj =             obj.updateCentroidVisibility;
        end

        function obj = setCallbacks(obj)

            obj = obj.setChannelCallbacks;

            obj.Views.Navigation.CurrentPlane.Callback =             @obj.planeViewClicked;
            obj.Views.Navigation.CurrentTimePoint.Callback =         @obj.frameViewClicked;
            obj.Views.Navigation.ShowMaxVolume.Callback =            @obj.maximumProjectionClicked;
            obj.Views.Navigation.CropImageHandle.Callback =          @obj.croppingOnOffClicked;
            obj.Views.Navigation.ApplyDriftCorrection.Callback =     @obj.driftCorrectionOnOffClicked;


            obj.Views.Annotation.ShowScaleBar.Callback =             @obj.annotationScaleBarOnOffClicked;
            obj.Views.Annotation.SizeOfScaleBar.Callback =           @obj.annotationScaleBarSizeClicked;


            obj.TrackingViews.ActiveTrackTitle.Callback =            @obj.trackingActiveTrackButtonClicked;
            obj.TrackingViews.ShowCentroids.Callback =               @obj.trackingCentroidButtonClicked;
            obj.TrackingViews.ShowMasks.Callback =                   @obj.trackingShowMaskButtonClicked;
            obj.TrackingViews.ShowTracks.Callback =                  @obj.trackingShowTracksButtonClicked;
            obj.TrackingViews.ShowMaximumProjection.Callback =       @obj.trackingShowMaximumProjectionButtonClicked;
            obj.TrackingViews.ListWithFilteredTracks.Callback =      @obj.trackingTrackListClicked;  


        end

        %% planeViewClicked
        function [obj] =           planeViewClicked(obj,~,~)
            newPlane =      obj.Views.Navigation.CurrentPlane.Value;
            obj  =          obj.resetPlane(newPlane);
        end
        
         function [obj]  =                       resetPlane(obj, newPlane)
            obj.LoadedMovie =      obj.LoadedMovie.setSelectedPlaneTo(newPlane);
            obj =                   obj.updateImageView;  
            obj =                   obj.updateNavigationViews;
        end
        
         
         function obj =                  updateNavigationViews(obj)

           if isempty(obj.Views.Navigation) % only set when this actually an object (the controller can be used without these views);
           else
                obj.Views.Navigation.CurrentPlane.Value =           obj.LoadedMovie.getActivePlanes;
                obj.Views.Navigation.CurrentTimePoint.Value =       obj.LoadedMovie.getActiveFrames;  
           end     
         end

        
         %% frameViewClicked
          function [obj] =           frameViewClicked(obj,~,~)
             newFrame =            obj.Views.Navigation.CurrentTimePoint.Value;
             obj  =                obj.resetFrame(newFrame);
          end
          
           

         
          function [obj] =          maximumProjectionClicked(obj,~,~)
              obj.LoadedMovie =     obj.LoadedMovie.setCollapseAllPlanes(logical(obj.Views.Navigation.ShowMaxVolume.Value));
              obj =                                   obj.updateImageView;
  
          end
          
          %% croppingOnOffClicked:
         function [obj] =    croppingOnOffClicked(obj,~,~)
                NewCroppingState =              obj.Views.Navigation.CropImageHandle.Value;
                obj.LoadedMovie =               obj.LoadedMovie.setCroppingStateTo(NewCroppingState);
                obj =                           obj.resetViewsForCurrentCroppingState;
          end

       
        
        %% driftCorrectionOnOffClicked
           function [obj] =          driftCorrectionOnOffClicked(obj,~,~)
               OnOrOffValue =       obj.Views.Navigation.ApplyDriftCorrection.Value;
               obj =                obj.setDriftCorrectionTo(OnOrOffValue);  
           end
          
             function [obj] =       trackingActiveTrackButtonClicked(obj,~,~)
              obj.LoadedMovie =     obj.LoadedMovie.setActiveTrackIsHighlighted(logical(obj.TrackingViews.ActiveTrackTitle.Value));
              obj =       obj.updateHighlightingOfActiveTrack;
              obj =       obj.updateImageView;
          end
          
          function [obj] =      trackingCentroidButtonClicked(obj,~,~)
              obj =     obj.setCentroidVisibility(logical(obj.TrackingViews.ShowCentroids.Value));
          end
          
          function [obj] =      trackingShowMaskButtonClicked(obj,~,~)
              obj.LoadedMovie =       obj.LoadedMovie.setMaskVisibility(logical(obj.TrackingViews.ShowMasks.Value));
              obj =                                           obj.updateMaskVisibility;
          end

          function [obj] =      trackingShowTracksButtonClicked(obj,~,~)
              obj.LoadedMovie =      obj.LoadedMovie.setTrackVisibility(logical(obj.TrackingViews.ShowTracks.Value));
              obj =                                   obj.updateTrackVisibility;
          end
          
          function [obj] =      trackingShowMaximumProjectionButtonClicked(obj,~,~)
              obj = obj.resetPlaneTrackingByMenu;   
          end

          function [obj] =      trackingTrackListClicked(obj,~,~)
              obj =                           obj.changActiveTrackByTableView;
          end

          %% toggleScaleBarVisibility
          function obj =  toggleScaleBarVisibility(obj)
                obj.LoadedMovie =      obj.LoadedMovie.toggleScaleBarVisibility;
                obj =                  obj.updateAnnotationViews; 
                obj =                  obj.updateImageHelperViewsMore;
              
          end
                              
          %% annotationScaleBarOnOffClicked
          function [obj] =         annotationScaleBarOnOffClicked(obj,~,~)
              obj.Views =       obj.Views.setScaleBarVisibility(obj.Views.Annotation.ShowScaleBar.Value);
              obj =             obj.updateAnnotationViews;  
              
          end
          
          %% annotationScaleBarSizeClicked
          function [obj] =         annotationScaleBarSizeClicked(obj,~,~)
              
              obj.LoadedMovie =                         obj.LoadedMovie.setScaleBarSize(obj.Views.Annotation.SizeOfScaleBar.Value);
              obj.LoadedMovie =                         obj.LoadedMovie.updateScaleBarString;
              obj.Views.MovieView.ScalebarText.String =              obj.LoadedMovie.ScalebarStamp;
              obj =                                                   obj.updateAnnotationViews;  
              
          end
          
      
        
        %% channelViewClicked:
          function [obj] =           channelViewClicked(obj,~,~)
               obj.LoadedMovie =        obj.LoadedMovie.setActiveChannel(obj.Views.Channels.SelectedChannel.Value);
               obj =                   obj.updateChannelSettingView;
          end
         
          function obj = toggleVisibilityOfChannelIndex(obj, Index)
              
              if Index <= obj.LoadedMovie.getMaxChannel
                    obj.LoadedMovie =        obj.LoadedMovie.setVisibleOfChannelIndex(Index,   ~obj.LoadedMovie.getVisibleOfChannelIndex(Index));    
                    obj.LoadedMovie =        obj.LoadedMovie.setActiveChannel(Index);
                    obj =                    obj.updateChannelSettingView;
                    obj =                    obj.updateImageView;  
               end

              
          end
          
          
          %% channels:
         function [obj] =           channelLowIntensityClicked(obj,~,~)
            Value =                 str2double(obj.Views.Channels.MinimumIntensity.String);
            obj.LoadedMovie =       obj.LoadedMovie.resetChannelSettings(Value, 'ChannelTransformsLowIn');
            obj =                   obj.updateImageView;
            obj =                   obj.updateChannelSettingView;
         end
         
          function [obj] =           channelHighIntensityClicked(obj,~,~)
             Value =             str2double(obj.Views.Channels.MaximumIntensity.String);
             obj.LoadedMovie  =               obj.LoadedMovie.resetChannelSettings(Value, 'ChannelTransformsHighIn');
             obj =          obj.updateImageView;
            obj =          obj.updateChannelSettingView;
         end
         
          function [obj] =          channelColorClicked(obj,~,~)
              Value =               obj.Views.Channels.Color.String{obj.Views.Channels.Color.Value};
             obj.LoadedMovie  =               obj.LoadedMovie.resetChannelSettings(Value, 'ChannelColors');
             obj =          obj.updateImageView;
            obj =          obj.updateChannelSettingView;
          end
          
          function [obj] =          channelCommentClicked(obj,~,~)
                obj.LoadedMovie  =          obj.LoadedMovie.resetChannelSettings(obj.Views.Channels.Comment.String, 'ChannelComments');
                obj =          obj.updateImageView;
                obj =          obj.updateChannelSettingView;
          end
          
          function [obj] =          channelOnOffClicked(obj,~,~)
                Value =             logical(obj.Views.Channels.OnOff.Value);
                obj.LoadedMovie  =  obj.LoadedMovie.resetChannelSettings(Value, 'SelectedChannels');   
                obj =               obj.updateImageView;
                obj =               obj.updateChannelSettingView;
          end
          
          function [obj] =              channelReconstructionClicked(obj,~,~)
                
                 
                
                obj.LoadedMovie  =      obj.LoadedMovie.resetChannelSettings(obj.Views.getFilterTypeOfSelectedChannel, 'ChannelReconstruction');
                obj =                   obj.emptyOutLoadedImageVolumes;
                obj =                   obj.updateRgbImage;
                
                obj =                   obj.updateImageView;
                obj =                   obj.updateChannelSettingView;
                            
          end
          
          
        %% image volumes
        function volumes = getLoadedImageVolumes(obj)
           volumes =  obj.LoadedImageVolumes;
        end
        
        function Volume = getActiveImageVolumeForChannel(obj, ChannelIndex)
            activeVolume =    obj.LoadedImageVolumes{obj.LoadedMovie.getActiveFrames,1};
             Volume =         activeVolume(:, :, :, 1, ChannelIndex);

        end
          
          function rgbImage = highlightPixelsInRgbImage(~, rgbImage, CoordinateList, Channel, Intensity)
                NumberOfPixels =                        size(CoordinateList,1);
                if ~isnan(Intensity)
                    for CurrentPixel =  1:NumberOfPixels
                        rgbImage(CoordinateList(CurrentPixel, 1), CoordinateList(CurrentPixel, 2), Channel)= Intensity;
                    end
                end
              
          end

        function obj =                              resetAxesCenter(obj, xShift, yShift)
             obj.Views.MovieView.ViewMovieAxes.XLim = obj.Views.MovieView.ViewMovieAxes.XLim - xShift;
             obj.Views.MovieView.ViewMovieAxes.YLim = obj.Views.MovieView.ViewMovieAxes.YLim - yShift;
             
             
        end
        
        
        function [obj] =                            resetWidthOfMovieAxesToMatchAspectRatio(obj)
            XLength =                                           obj.Views.MovieView.ViewMovieAxes.XLim(2)- obj.Views.MovieView.ViewMovieAxes.XLim(1);
            YLength =                                           obj.Views.MovieView.ViewMovieAxes.YLim(2)- obj.Views.MovieView.ViewMovieAxes.YLim(1);
            LengthenFactorForX =                                XLength/  YLength;
            obj.Views.MovieView.ViewMovieAxes.Position(3) =     obj.Views.MovieView.ViewMovieAxes.Position(4) * LengthenFactorForX;
        end
        
   
        %% update drift marker view:
          function obj =                  updateImageHelperViewsMore(obj)
                obj =                                               obj.updateNavigationViews;
                obj.Views.Navigation.ShowMaxVolume.Value =          obj.LoadedMovie.getCollapseAllPlanes ;
                obj.Views.Navigation.ApplyDriftCorrection.Value =   obj.LoadedMovie.getDriftCorrectionStatus;
                obj.Views.Navigation.CropImageHandle.Value =        obj.LoadedMovie.getCroppingOn;
                obj.Views.Annotation.ShowScaleBar.Value =           obj.LoadedMovie.getScaleBarVisibility;
       
          end
        
         
    
           %% Trackline Views:
         
          
           function setLineColorTo(~,Handle,Color)
               Handle.Color =          Color;
               
           end
    
            
         
          
       
   
       %% set model and view:
       function obj =           resetNumberOfExtraLoadedFrames(obj,Number)
            obj.DefaultNumberOfLoadedFrames =                   Number;    
       end
       
      
       %% unMapMovie:
       function obj =           unMapMovie(obj)
            obj    =            obj.emptyOutLoadedImageVolumes;
            obj.LoadedMovie =   obj.LoadedMovie.unmap;
            obj.Views=          obj.Views.blackOutMovieView;
       end
       
          function obj    =        emptyOutLoadedImageVolumes(obj)
            if isempty(obj.LoadedMovie) 
                obj.LoadedImageVolumes =                           cell(0,1);
            else
                obj.LoadedImageVolumes =                            cell(obj.LoadedMovie.getMaxFrame,1);
            end     
          end
         
       %% manageResettingOfImageMap
       function obj =           manageResettingOfImageMap(obj)
           
           assert(~isempty(obj.LoadedMovie), 'Loaded movie not set')
             obj.LoadedMovie =        obj.LoadedMovie.setImageMapFromFiles;
             obj    =                 obj.emptyOutLoadedImageVolumes;
             obj =                    obj.updateRgbImage;
       end
       

        % navigation
      

        
    
      
        function obj =  turnOffAllChannels(obj)
            obj.LoadedMovie =   obj.LoadedMovie.turnOffAllChannels; 
            obj =               obj.updateChannelSettingView;
            obj =               obj.updateImageView;  
        end
        
        
      
        
        
        %% set drift correction:
        function obj  =        setDriftCorrectionTo(obj, state)
            obj.LoadedMovie =               obj.LoadedMovie.setDriftCorrectionTo(state); % the next function should be incoroporated into this function
            obj =                           obj.resetDriftDependentParameters;
        end
        
        function obj =         resetDriftCorrectionByManualClicks(obj)
            obj.LoadedMovie =     obj.LoadedMovie.setDriftCorrection(obj.LoadedMovie.getDriftCorrection.setByManualDriftCorrection);
            obj =                  obj.resetDriftDependentParameters;
        end
        
        function obj =         resetDriftCorrectionToNoDrift(obj)
            obj.LoadedMovie =     obj.LoadedMovie.setDriftCorrection(obj.LoadedMovie.getDriftCorrection.eraseDriftCorrection);
            obj =                                 obj.resetDriftDependentParameters;
            
        end
        
        function obj =         resetDriftDependentParameters(obj)
            obj.LoadedMovie =              obj.LoadedMovie.setDriftDependentParameters;
            obj =                          obj.resetViewsForCurrentDriftCorrection;
            
          
        end  
        
        function obj =         resetViewsForCurrentDriftCorrection(obj)
            
                obj =                       obj.resetLimitsOfImageAxesWithAppliedCroppingGate; % reset applied cropping limit (dependent on drift correction)
                obj =                       obj.shiftImageByDriftCorrection; % reset image shift (dependent on drift correction)
                obj =                       obj.initializeNavigationViews; % plane number may change
                obj =                       obj.updateCroppingLimitView; % crop position may change

                obj =                       obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);% change drift correction of tracks
                obj =                       obj.updateNavigationViews; % plane number may change
                obj =                       obj.updateImageHelperViewsMore; % drift setting may change
                obj =                       obj.updateAnnotationViews;  % adjust position of annotation within views

             end
         
            
       
        %% tracks:
         function obj =                         setFinishStatusOfTrackTo(obj, Input)
             obj.LoadedMovie =                              obj.LoadedMovie.setFinishStatusOfTrackTo(Input); 
             obj.TrackingNavigationEditViewController =     obj.TrackingNavigationEditViewController.resetModelWith(obj.LoadedMovie.getTracking);
         end

         function [obj] =                        resetPlaneTrackingByMenu(obj) % maximum projection for tracking
                MaximumProjOfTracking =     obj.TrackingViews.ShowMaximumProjection.Value;
                obj = obj.setCollapseAllTrackingTo(MaximumProjOfTracking);
         end

         function obj = setCollapseAllTrackingTo(obj, Value)
            obj.LoadedMovie =           obj.LoadedMovie.setCollapseAllTrackingTo(Value);
            obj =                       obj.updateImageView;  
            obj =                       obj.updateNavigationViews;
            obj.TrackingViews.ShowMaximumProjection.Value = Value;
         end

        function [obj] =                        mergeSelectedTracks(obj)
               obj.LoadedMovie.Tracking =   obj.LoadedMovie.Tracking.mergeSelectedTracks;
              obj =                         obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
        end

        %% splitSelectedTrack
        function obj = splitSelectedTrack(obj)
            obj.LoadedMovie.Tracking  =               obj.LoadedMovie.Tracking.splitSelectedTrackAtActiveFrame;
            obj =                                     obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
        end
                     
        
     
         
        %% deleteActiveMask               
        function obj =              deleteActiveMask(obj)
            obj.LoadedMovie.Tracking =      obj.LoadedMovie.Tracking.deleteActiveMask;
            obj =                           obj.setTrackLineViews;
        end
        
                         

         
         %% splitTrackAtFrameAndDeleteFirst
        function [obj] =         splitTrackAtFrameAndDeleteFirst(obj)
                obj.LoadedMovie.Tracking =   obj.LoadedMovie.Tracking.splitTrackAtFrameAndDeleteFirst(obj.LoadedMovie.getActiveFrames, obj.LoadedMovie.getSelectedTrackIDs);
                obj =                        obj.Views.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
        end
        

        %% splitSelectedTracksAndDeleteSecondPart     
        function [obj] =             splitSelectedTracksAndDeleteSecondPart(obj)   
            obj.LoadedMovie.Tracking =     obj.LoadedMovie.Tracking.splitTrackAtFrameAndDeleteSecond(obj.LoadedMovie.getActiveFrames, obj.LoadedMovie.getSelectedTrackIDs);
            obj =                          obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
        end

        %% connectSelectedTrackToActiveTrack
        function obj =                              connectSelectedTrackToActiveTrack(obj)
            IDOfTrackToMerge =  obj.getTrackIDFromMousePosition;
            obj.LoadedMovie =   obj.LoadedMovie.mergeActiveTrackWithTrack(IDOfTrackToMerge);
            obj =               obj.updateImageView;
        end
            
        function SelectedTrackID =   getTrackIDFromMousePosition(obj)
           frame =                                          obj.LoadedMovie.getActiveFrames;
            [ClickedColumn, ClickedRow, ClickedPlane] =            obj.LoadedMovie.removeDriftCorrection(obj.MouseUpColumn, obj.MouseUpRow, obj.LoadedMovie.getActivePlanes);
            [ClickedRow, ClickedColumn, ClickedPlane, ~] =     obj.roundCoordinates(ClickedRow, ClickedColumn, ClickedPlane, frame);
            SelectedTrackID= obj.LoadedMovie.getIdOfTrackThatIsClosestToPoint([ClickedRow, ClickedColumn, ClickedPlane]);
        end
        
        %% gotToFirstTrackedFrameFromCurrentPoint
        function obj =   gotToFirstTrackedFrameFromCurrentPoint(obj)
                         obj =              obj.resetFrame(obj.LoadedMovie.getLastTrackedFrame('down'));
        end
        
        function obj = goToLastContiguouslyTrackedFrameInActiveTrack(obj)
            obj =      obj.resetFrame(obj.LoadedMovie.getLastTrackedFrame('up'));
        end
        
        %% goToLastFrame
        function obj = goToLastFrame(obj)
                 obj =        obj.resetFrame(obj.LoadedMovie.getMaxFrame);
        end
        
        %% goOnePlaneDown
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
                    
                    
     %% get rectnagle from mouse drag

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

        function [rowFinal, columnFinal, planeFinal, frame] =     roundCoordinates(~, rowFinal, columnFinal, planeFinal, frame)
            rowFinal =          round(rowFinal);
            columnFinal =       round(columnFinal);
            planeFinal =        round(planeFinal);
            frame =             round(frame);
        end
        
        function [rowFinal, columnFinal, planeFinal, frame] =               getCoordinatesOfCurrentMousePosition(obj)
            [columnFinal, rowFinal, planeFinal] =            obj.LoadedMovie.removeDriftCorrection(obj.MouseUpColumn, obj.MouseUpRow, obj.LoadedMovie.getActivePlanes);
            [rowFinal, columnFinal, planeFinal, frame] =     obj.roundCoordinates(rowFinal, columnFinal, planeFinal, obj.LoadedMovie.getActiveFrames);
            [rowFinal, columnFinal, planeFinal]  =           obj.LoadedMovie.verifyCoordinates(rowFinal, columnFinal,planeFinal);
        end
     
            %% other 
            function obj =                     usePressedCentroidAsMask(obj)
                  if isnan(obj.LoadedMovie.getIdOfActiveTrack)
                     return
                  end
                  [rowFinal, columnFinal, planeFinal, ~] =   obj.getCoordinatesOfCurrentMousePosition;

                if ~isnan(rowFinal)
                      mySegmentationObject =                     PMSegmentationCapture(obj, [rowFinal, columnFinal, planeFinal]);
                      mySegmentationObject.SegmentationType =    'MouseClick';
                      obj.LoadedMovie =                          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                      obj =                                      obj.updateAllViewsThatDependOnActiveTrack;
                end

            end

            function obj = updateAllViewsThatDependOnActiveTrack(obj)
                obj =                   obj.updateNavigationViews;
                obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
                obj.LoadedMovie =       obj.LoadedMovie.setFocusOnActiveTrack;  
                obj =                   obj.updateCroppingLimitView;
                obj =                   obj.resetLimitsOfImageAxesWithAppliedCroppingGate;

            end
            
              function obj = updateAllViewsThatDependOnSelectedTracks(obj)
                obj =       obj.updateCentroidsOfSelectedMasksView;
                obj =       obj.upCentroidOfActiveTrackView;
                obj =       obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
                obj =       obj.updateRgbImage;
                obj.TrackingViews.ActiveTrack.String =        num2str(obj.LoadedMovie.getIdOfActiveTrack);
                obj.TrackingNavigationEditViewController =    obj.TrackingNavigationEditViewController.resetModelWith(obj.LoadedMovie.getTracking);

          end
            
         %%     setTrackingNavigationEditViewController
         function obj = setTrackingNavigationEditViewController(obj, varargin)
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
         
            function obj = updateHandlesForTrackingNavigationEditView(obj)

                obj.TrackingNavigationEditViewController = obj.TrackingNavigationEditViewController.setCallbacks(...
                        @obj.respondToTrackTableActivity, @obj.respondToActiveFrameClicked, ...
                        @obj.respondToActiveTrackSelectionClicked, @obj.respondToActiveTrackActivity, ...
                        @obj.respondToEditSelectedTrackSelectionClicked, @obj.respondToSelectedTrackActivity ...
                        );
            end
       
            function obj =   respondToTrackTableActivity(obj,~,a)
                PressedCharacter =               obj.TrackingNavigationEditViewController.View.MainFigure.CurrentCharacter;
                MySelectedTrackIds =             a.Source.Data{a.Indices(:,1),1};
                switch PressedCharacter
                    case {'a'}
                        obj =         obj.resetModelWithActiveTrackNumber(MySelectedTrackIds)   ;
                    case {'N','n'}
                        obj =         obj.resetSelectedTracksWithTrackIDs(MySelectedTrackIds)   ;
                    case {'s','S'}
                        obj =         obj.addToSelectedTracksTrackIDs(MySelectedTrackIds)   ;
                end
            end
            
            function obj = respondToActiveFrameClicked(obj,~,~)
                    newFrame =                                   str2double(obj.TrackingNavigationEditViewController.View.ActiveFrame.Value);
                     obj  =                                       obj.resetFrame(newFrame);
            end
            
           function obj = respondToActiveTrackSelectionClicked(obj,~,~)



           end
            
                   
       function obj = respondToActiveTrackActivity(obj,~,~)
           
                CurrentlyShownActionSelection =  obj.TrackingNavigationEditViewController.View.EditActiveTrackSelection.Value;
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
       
         function obj = respondToEditSelectedTrackSelectionClicked(obj,~,~)
            obj.TrackingNavigationEditViewController =                               obj.TrackingNavigationEditViewController.resetSelectedTracksAction;
         end
        
        function obj =   respondToSelectedTrackActivity(obj,~,~)
               CurrentlyShownActionSelection =  obj.TrackingNavigationEditViewController.View.EditSelectedTrackSelection.Value;
               switch CurrentlyShownActionSelection
                   case 'Delete tracks'
                        obj  =               obj.deleteSelectedTracks;
                   case 'Merge tracks'  
                        obj  =               obj.mergeSelectedTracks;
                   case 'Split tracks'
                       obj =          obj.splitSelectedTrack;
               end
                obj =  obj.setTrackingNavigationEditViewController;
        end
                
         function obj = deleteSelectedTracks(obj)
             obj.LoadedMovie =          obj.LoadedMovie.deleteSelectedTracks;
             obj =                      obj.updateAllViewsThatDependOnActiveTrack;
         end
             
          %% removeHighlightedPixelsFromMask
          function [obj] =                   removeHighlightedPixelsFromMask(obj)
             
                if isnan(obj.LoadedMovie.getIdOfActiveTrack)
                else
                     Coordinates =     obj.getCoordinateListByMousePositions;
                     
                     RectangleImage(min(Coordinates(:, 2)): max(Coordinates(:, 2)), min(Coordinates(:, 1)): max(Coordinates(:, 1))) = 1;
                     [y, x] = find(RectangleImage);

                    pixelListWithoutSelected =     obj.LoadedMovie.getPixelsFromActiveMaskAfterRemovalOf([y,x]);
                    obj.LoadedMovie =              obj.LoadedMovie.resetActivePixelListWith(PMSegmentationCapture(pixelListWithoutSelected, 'Manual'));
                    obj =                          obj.updateAllViewsThatDependOnActiveTrack;
                end
 
          end
          
           function SpaceCoordinates =           getCoordinateListByMousePositions(obj)

                myRectangle =       PMRectangle(obj.getRectangleFromMouseDrag);
                Coordinates_2D =    myRectangle.get2DCoordinatesConfinedByRectangle;
                
                [ ~, ~,  planeWithoutDrift, ~ ] =    obj.getCoordinatesOfCurrentMousePosition;
                zListToAdd =    (linspace(planeWithoutDrift, planeWithoutDrift, length(xListToAdd)))';

                SpaceCoordinates = [Coordinates_2D, zListToAdd];

            end
            
         %% add highlighte pixels
         function obj =                     addHighlightedPixelsFromMask(obj)
            Coordinates =   obj.getCoordinateListByMousePositions;
            obj =           obj.highLightRectanglePixelsByMouse([Coordinates(:, 2), Coordinates(:, 1)]);
            
             if isnan(obj.LoadedMovie.getIdOfActiveTrack)
                obj.LoadedMovie =     obj.LoadedMovie.updateMaskOfActiveTrackByAdding(yListToAdd, xListToAdd, zListToAdd);
                obj =                 obj.updateAllViewsThatDependOnActiveTrack;
             end
             
         end
         
        function [obj] =                            highLightRectanglePixelsByMouse(obj, coordinates)
            HighlightedChannel =       1;
            yCoordinates =       coordinates(:,1);
            xCoordinates =       coordinates(:,2);
            obj.Views.MovieView.MainImage.CData(: , :, HighlightedChannel) =                  0;
            obj.Views.MovieView.MainImage.CData( round(min([yCoordinates]):max([yCoordinates])),round(min(xCoordinates):max(xCoordinates)), HighlightedChannel) = 200;

        end
            
         %% addExtraPixelRowToCurrentMask
         function obj =                     addExtraPixelRowToCurrentMask(obj)
                mySegmentationObject =       PMSegmentationCapture(obj);
                mySegmentationObject =       mySegmentationObject.addRimToActiveMask;
                obj.LoadedMovie =          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                obj =                      obj.updateAllViewsThatDependOnActiveTrack;    
         end
         
         %% removePixelRimFromCurrentMask
          function obj =                    removePixelRimFromCurrentMask(obj)
                mySegmentationObject =     PMSegmentationCapture(obj);
                mySegmentationObject =     mySegmentationObject.removeRimFromActiveMask;
                obj.LoadedMovie =          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                obj =                      obj.updateAllViewsThatDependOnActiveTrack;
          end
         
         
          
          %% showAutoCellRecognitionWindow  
          function obj =   showAutoCellRecognitionWindow(obj)
                if isempty(obj.LoadedMovie)

                else
                    myModel =                                   PMAutoCellRecognition(obj.getLoadedImageVolumes, find(obj.LoadedMovie.getActiveChannelIndex));
                    obj.AutoCellRecognitionController =         PMAutoCellRecognitionController(myModel);   
          
                    obj.AutoCellRecognitionController =         obj.AutoCellRecognitionController.setCallBacks(@obj.AutoCellRecognitionChannelChanged, @obj.AutoCellRecognitionFramesChanged, @obj.AutoCellRecognitionTableChanged, @obj.startAutoCellRecognitionPushed);
                    
                end
            
          end
          
          function obj = AutoCellRecognitionChannelChanged(obj, ~,third)
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
                    obj =                           obj.askUserToDeleteTrackingData;
                    obj.LoadedMovie.Tracking =      obj.LoadedMovie.Tracking.setTrackingAnalysis(obj.LoadedMovie.getTrackingAnalysis);
                    obj.LoadedMovie =               obj.LoadedMovie.executeAutoCellRecognition(obj.AutoCellRecognitionController.getAutoCellRecognition);
                    
                    obj = updateAllViewsThatDependOnSelectedTracks(obj);
                    
            end
           
            
        end

     
          
          
          %% autoDetectMasksByCircleRecognition
          function obj = autoDetectMasksByCircleRecognition(obj)
               fprintf('\nPMMovieController: @autoDetectMasksByCircleRecognition.\n');
                
                [myCellRecognition, MyFrames] =     obj.getAutoCellRecognitionObject;
                if isempty(myCellRecognition) 
                else
                    obj.LoadedMovie =   obj.LoadedMovie.executeAutoCellRecognition(myCellRecognition, MyFrames);
                    obj =   obj.updateAllViewsThatDependOnSelectedTracks;
                end
                     
          end
          
          function obj = askUserToDeleteTrackingData(obj)
                DeleteAllAnswer = questdlg('Do you want to delete all existing tracks before autodetection?', 'Cell autodetection');
                switch DeleteAllAnswer
                    case 'Yes'
                        obj =         obj.deleteAllTracks;
                end
          end
          
            function [obj] =                             deleteAllTracks(obj)
                obj.LoadedMovie.Tracking =     PMTrackingNavigation(0,0);
                obj.LoadedMovie.Tracking =     obj.LoadedMovie.Tracking.fillEmptySpaceOfTrackingCellTime(obj.LoadedMovie.getMaxFrame);
                obj =                          obj.setActiveTrack(NaN)   ;   
            end
            
            function obj =  setActiveTrack(obj, SelectedTrackIDs)    
                    obj.LoadedMovie =         obj.LoadedMovie.setActiveTrackWith(SelectedTrackIDs);
                    obj =                       obj.updateAllViewsThatDependOnActiveTrack;
            end
            
    
          
  
          
        
          
          %% autoDetectMasksOfCurrentFrame
          function obj =                    autoDetectMasksOfCurrentFrame(obj)
                StartFrame =            obj.LoadedMovie.getActiveFrames;
                mySegmentationCapture =     PMSegmentationCapture(obj);
                mySegmentationCapture =     mySegmentationCapture.setSizeForFindingCellsByIntensity(obj.MaskLocalizationSize);
                
                for PlaneIndex = 1:obj.LoadedMovie.getMaxPlane
                    for FrameIndex = 1:obj.LoadedMovie.getMaxFrame
                      obj =                     obj.resetFrame(FrameIndex);
                      mySegmentationCapture =   mySegmentationCapture.emptyOutBlackedOutPixels;
                      ContinueLoop = true;
                      while ContinueLoop

                        mySegmentationCapture =     mySegmentationCapture.resetWithMovieController(obj);
                        mySegmentationCapture =     mySegmentationCapture.setActiveZCoordinate(PlaneIndex);
                        mySegmentationCapture =     mySegmentationCapture.performAutothresholdSegmentationAroundBrightestAreaInImage;

                        if mySegmentationCapture.testPixelValidity  
                           obj =        obj.createNewTrackWithSegmentationCapture(mySegmentationCapture);
                        elseif mySegmentationCapture.getAccumulatedSegmentationFailures <= 10
                         else
                                ContinueLoop = false;
                        end
                        
                        
                      end
                      obj.PressedKeyValue  = '';
                    end
                end
                obj =         obj.resetFrame( StartFrame);
              
          end
          
          function obj = createNewTrackWithSegmentationCapture(obj, mySegmentationCapture)
                obj.LoadedMovie =      obj.LoadedMovie.setActiveTrackWith(obj.LoadedMovie.findNewTrackID);
                obj.LoadedMovie =      obj.LoadedMovie.resetActivePixelListWith(mySegmentationCapture);
                obj          =         obj.setActiveTrack(obj.LoadedMovie.getIdOfActiveTrack);  
                obj =                  obj.resetPlane(PlaneIndex);
                drawnow
          end
          
          %% minimizeMasksOfCurrentTrackForFrames
          function obj = minimizeMasksOfCurrentTrack(obj)
                obj =                   obj.minimizeMasksOfCurrentTrackForFrames(obj.getFollowingFramesOfCurrentTrack); 
          end
          
          function frames = getFollowingFramesOfCurrentTrack(obj)
              frames =                obj.LoadedMovie.getTracking.getAllFrameNumbersOfTrackID(obj.LoadedMovie.getIdOfActiveTrack);
                frames(frames < obj.LoadedMovie.getActiveFrames) =     [];
          end
                                             
          
          function obj =                    minimizeMasksOfCurrentTrackForFrames(obj, SourceFrames)
              
                for FrameIndex = 1:length(SourceFrames)
                    obj =                      obj.resetFrame(SourceFrames(FrameIndex));
                    obj.LoadedMovie =          obj.LoadedMovie.minimizeMasksOfActiveTrackAtFrame(FrameIndex);
                    obj =                      obj.updateCroppingLimitView;
                    obj =                      obj.resetLimitsOfImageAxesWithAppliedCroppingGate;
                    obj =                      obj.updateAllViewsThatDependOnActiveTrack;

                    drawnow  

                end
                
          end
          
          %% recreateMasksOfCurrentTrackForFrames
          function obj = recreateMasksOfCurrentTrack(obj)
                    obj =             obj.recreateMasksOfCurrentTrackForFrames(obj.getFollowingFramesOfCurrentTrack);
          end
          
           
          
          
          
          function  obj =                   recreateMasksOfCurrentTrackForFrames(obj,SourceFrames)
              
                AllowedXYShift =               3;
                StopObject =                   obj.createStopButtonForAutoTracking;
              
                 SegmentationObjOfReferenceFrame =         PMSegmentationCapture(obj);
                 SegmentationObjOfReferenceFrame.PixelShiftForEdgeDetection =       1;
                 SegmentationObjOfReferenceFrame.AllowedExcessSizeFactor =      3;
                 
                 fprintf('\nRecreating masks of track %i has a maximum size of %i pixels\n', SegmentationObjOfReferenceFrame.CurrentTrackId);
                 fprintf('The masks are allowed a maximum of %i pixels\n.', SegmentationObjOfReferenceFrame.getMaximumPixelNumber);
                 fprintf('The allowed shift in X and Y is %i.\n\n', AllowedXYShift);

                NumberOfFrames =     length(SourceFrames);
                for FrameIndex = 1:NumberOfFrames

                    if ~ishandle(StopObject.Button)
                        break
                    end
                    
                    PixelShift = 1;
                    obj =                   obj.resetFrame(SourceFrames(FrameIndex));
                    OriginalX =             mean(PMSegmentationCapture(obj).MaskCoordinateList(:,2));
                    OriginalY =             mean(PMSegmentationCapture(obj).MaskCoordinateList(:,1));
                    SegmentationObject =    PMSegmentationCapture(obj);
                    
                    SegmentationObject =    SegmentationObject.generateMaskByEdgeDetectionForceSizeBelow(SegmentationObjOfReferenceFrame.getMaximumPixelNumber);
                    
                   fprintf('New X= %6.2f. New Y= %6.2f.\n', SegmentationObject.getXCentroid, SegmentationObject.getXCentroid)
                   XYDistance = max([abs(OriginalX- SegmentationObject.getXCentroid)], [abs(OriginalY- SegmentationObject.getXCentroid)]);
                   if XYDistance< AllowedXYShift && SegmentationObject.getNumberOfPixels > 1 && SegmentationObject.getNumberOfPixels <= SegmentationObjOfReferenceFrame.getMaximumPixelNumber
                       fprintf('For frame %i: %i pixels were added\n', FrameIndex, SegmentationObject.getNumberOfPixels);
                        obj.LoadedMovie =                           obj.LoadedMovie.resetActivePixelListWith(SegmentationObject);
                   else
                       fprintf('For frame %i: %i pixels were found. Not added because size too large or XY off too much\n', FrameIndex, SegmentationObject.getNumberOfPixels)
                   end
                   
                    obj.LoadedMovie =    obj.LoadedMovie.setFrameAndAdjustPlaneAndCropByTrack(SourceFrames(FrameIndex)); 
                    obj =                obj.updateCroppingLimitView;
                    obj =                obj.resetLimitsOfImageAxesWithAppliedCroppingGate;
          
                    obj =                obj.updateAllViewsThatDependOnActiveTrack;
                    drawnow  
                  
                end
                delete(StopObject.ParentFigure)
          end
          
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
          
            
            %% autoBackwardTrackingOfActiveTrack
            function obj =                    autoBackwardTrackingOfActiveTrack(obj)
                [SourceFrames,TargetFrames] =       obj.LoadedMovie.getFramesForTracking('backward');
                obj =                               obj.autoTrackCurrentCellForFrames(SourceFrames,TargetFrames);  
                
            end
                            
            %% autoForwardTrackingOfActiveTrack
            function obj =                    autoForwardTrackingOfActiveTrack(obj)
                [SourceFrames,TargetFrames] =           obj.LoadedMovie.getFramesForTracking('forward');
                obj =                   obj.autoTrackCurrentCellForFrames(SourceFrames, TargetFrames);
            end
                                     
          %% autoTrackingWhenNoMaskInNextFrame
          function obj =                    autoTrackingWhenNoMaskInNextFrame(obj)
              
                TrackingStartFrame =       obj.LoadedMovie.getActiveFrames;
                TrackingEndFrame =         obj.LoadedMovie.getMaxFrame - 1;
                TrackingFrames =           TrackingStartFrame:TrackingEndFrame;
                TargetFrames =             TrackingFrames + 1;

                TrackIDsForTracking =      obj.LoadedMovie.getTrackIDsWhereNextFrameHasNoMask;
                NumberOfTracks =           size(TrackIDsForTracking,1);

                  for TrackIDIndex = 1:NumberOfTracks

                        obj =                   obj.resetFrame(TrackingStartFrame);  
                        obj.LoadedMovie =       obj.LoadedMovie.setActiveTrackWith(TrackIDsForTracking(TrackIDIndex,1));
                        obj.LoadedMovie =       obj.LoadedMovie.setFocusOnActiveTrack;
                         [obj]          =       obj.setActiveTrack(obj.LoadedMovie.getIdOfActiveTrack);  
                        drawnow
                        obj =                   obj.autoTrackCurrentCellForFrames(TrackingFrames,TargetFrames);

                  end
              
          end
          
          function obj =                    autoTrackCurrentCellForFrames(obj, SourceFrames, TargetFrames)
                StopObject =                      obj.createStopButtonForAutoTracking;
                obj.PressedKeyValue =             'a';
                for FrameIndex = 1:length(SourceFrames)
                    [~,SegementationObjOfTargetFrame] =         obj.performTrackingBetweenTwoFrames(SourceFrames(FrameIndex), TargetFrames(FrameIndex));

                    if SegementationObjOfTargetFrame.testPixelValidity && ishandle(StopObject.Button) %% if the pixels are supicious or the user closed the stop button: stop tracking;
                        obj.LoadedMovie =     obj.LoadedMovie.resetActivePixelListWith(SegementationObjOfTargetFrame);
      
                        obj =                 obj.updateAllViewsThatDependOnActiveTrack;
                        drawnow
                    else
                         
                        break
                    end
                end
                obj.PressedKeyValue  =          '';
                delete(StopObject.ParentFigure)
          end
         
          
          
        
          
          
          function [SegmentationObjOfSourceFrame,SegementationObjOfTargetFrame] =                    performTrackingBetweenTwoFrames(obj,sourceFrameNumber,targetFrameNumber)
              
                    obj =                                          obj.resetFrame(sourceFrameNumber);
                    SegmentationObjOfSourceFrame =                 PMSegmentationCapture(obj, obj.LoadedMovie.getActiveChannelIndex);
                    
                    obj =                                          obj.resetFrame(targetFrameNumber);
                    SegementationObjOfTargetFrame =                PMSegmentationCapture(obj, obj.LoadedMovie.getActiveChannelIndex);    
                    SegementationObjOfTargetFrame.MaskCoordinateList =  SegmentationObjOfSourceFrame.MaskCoordinateList;
                    SegementationObjOfTargetFrame.CurrentTrackId =      obj.LoadedMovie.getIdOfActiveTrack; % not sure if this is necessary

                    SegementationObjOfTargetFrame =                     SegementationObjOfTargetFrame.setActiveCoordinateByBrightestPixels;
                    SegementationObjOfTargetFrame =                     SegementationObjOfTargetFrame.generateMaskByAutoThreshold;
                    
          end
          
           %% resetActiveTrackByMousePosition
           function obj=     resetActiveTrackByMousePosition(obj)
                    obj =    obj.setActiveTrack(obj.getTrackIDFromMousePosition)   ;
           end
           
           %% deleteActiveTrack
          function obj =              deleteActiveTrack(obj)
               obj.LoadedMovie =     obj.LoadedMovie.deleteActiveTrack;
               obj =                 obj.updateAllViewsThatDependOnActiveTrack;
                
          end
        
         
          
          %% addMaskToNewTrackByButtonClick
          function obj = addMaskToNewTrackByButtonClick(obj)
                obj =     obj.activateNewTrack;
                obj =     obj.updateActiveMaskByButtonClick;
          end

          function obj = activateNewTrack(obj)
               obj.LoadedMovie =     obj.LoadedMovie.setActiveTrackToNewTrack;
               obj =                 obj.updateAllViewsThatDependOnActiveTrack;
          end                                  
          
          function [obj] =                   updateActiveMaskByButtonClick(obj)
              
                [rowPos, columnPos, planePos, ~] =   obj.getCoordinatesOfCurrentMousePosition;
                if ~isnan(rowPos)
                    obj =                       obj.highlightMousePositionInImage;
                    mySegmentationObject =      PMSegmentationCapture(obj, [rowPos, columnPos, planePos, obj.LoadedMovie.getActiveChannelIndex]);
                    mySegmentationObject =      mySegmentationObject.generateMaskByClickingThreshold;
                    if mySegmentationObject.getActiveShape.testShapeValidity
                        obj.LoadedMovie =   obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                         obj =               obj.updateAllViewsThatDependOnActiveTrack;
                    else
                        fprintf('Button click did not lead to recognition of valid cell. No action taken.')
                    end
                   

                end
                
                figure(obj.Views.Figure)
                
          end
          
          
        function obj =             highlightMousePositionInImage(obj)
            [rowPos, columnPos, ~, ~] =   obj.getCoordinatesOfCurrentMousePosition;
            obj.Views.MovieView.MainImage.CData(rowPos,columnPos,:) =       255;
        end
        
         %% setImageMaximumProjection
        function obj = setImageMaximumProjection(obj, Value)
            obj.LoadedMovie =                           obj.LoadedMovie.setCollapseAllPlanes(Value);
            obj.Views.Navigation.ShowMaxVolume.Value =   Value;
            obj =                                        obj.updateImageView;  
            obj =                                        obj.updateNavigationViews;

        end

         %% addToSelectedTracksTrackIDs
         function obj =      addToSelectedTracksTrackIDs(obj, TracksToAdd)
            obj.LoadedMovie =       obj.LoadedMovie.addToSelectedTrackIds(TracksToAdd);
            obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
         end
         
         function obj =      removeMasksWithNoPixels(obj)
              obj.LoadedMovie =     obj.LoadedMovie.removeMasksWithNoPixels;  
         end
         %% selectAllTracks
         function obj =      selectAllTracks(obj)
             obj.LoadedMovie = obj.LoadedMovie.selectAllTracks;
             obj =                      obj.setTrackLineViews(obj.LoadedMovie.getAllTrackIDs);
         end
         
         %% resetSelectedTracksWithTrackIDs:
          function obj =      resetSelectedTracksWithTrackIDs(obj, TrackIds)
                obj.LoadedMovie =  obj.LoadedMovie.setSelectedTrackIdsTo(TrackIds);
                obj =                       obj.updateAllViewsThatDependOnActiveTrack;
          end
             
         %% resetModelWithActiveTrackNumber
          function obj = resetModelWithActiveTrackNumber(obj, TrackIds)
              obj.LoadedMovie =  obj.LoadedMovie.setActiveTrackWith(TrackIds);
              obj =              obj.updateAllViewsThatDependOnActiveTrack;
          end
          
        
           %% other          
          function verifiedStatus =                     verifyActiveMovieStatus(obj)
              verifiedStatus = ~isempty(obj)  && ~isempty(obj.LoadedMovie) && ~isempty(obj.Views) ;
          end
              
          function [Category] =                         interpretMouseMovement(obj)
              if isempty(obj) || isempty(obj.MouseDownRow) || isempty(obj.MouseDownColumn) 
                  Category =      'Invalid';
              elseif isnan(obj.MouseDownRow) || isnan(obj.MouseDownColumn)
                  Category = 'Free movement';
              else

                    obj.MouseUpRow=           obj.Views.MovieView.ViewMovieAxes.CurrentPoint(1,2);
                    obj.MouseUpColumn=        obj.Views.MovieView.ViewMovieAxes.CurrentPoint(1,1);

                    CurrentRows(1,1) =              obj.MouseDownRow;
                    CurrentRows(2,1) =              obj.MouseUpRow;

                    CurrentColumns(1,1) =           obj.MouseDownColumn;
                    CurrentColumns(2,1) =           obj.MouseUpColumn;

                    if obj.pointIsWithinImageAxesBounds(CurrentRows, CurrentColumns)
                        if (obj.MouseDownRow == obj.MouseUpRow) && (obj.MouseDownColumn ==  obj.MouseUpColumn)
                            Category = 'Stay';
                        else
                            Category = 'Movement';
                        end
                    else
                        Category = 'Out of bounds';
                        obj.MouseDownRow =       NaN;
                        obj.MouseDownColumn =    NaN;
                        obj.MouseUpRow =         NaN;
                        obj.MouseUpColumn =      NaN;
                    end
              end
          end

                function [check] =            pointIsWithinImageAxesBounds(obj, CurrentRow, CurrentColumn)
              XLimMin =                 obj.Views.MovieView.ViewMovieAxes.XLim(1);
              XLimMax =                 obj.Views.MovieView.ViewMovieAxes.XLim(2);
              YLimMin =                 obj.Views.MovieView.ViewMovieAxes.YLim(1);
              YLimMax =                 obj.Views.MovieView.ViewMovieAxes.YLim(2);
              
              if min(CurrentColumn >= XLimMin) && min(CurrentColumn <= XLimMax) && min(CurrentRow >= YLimMin) && min(CurrentRow <= YLimMax)
                 check = true;
              else
                  check = false;
              end
              
                end
      
                
                            
                                       
                                        
                
         %% mouse interactions:
            function obj = mouseMoved(obj)    %% get mouse action (defined by key press during button down); 
                 mouseController =      PMMovieController_MouseAction(obj);
                 obj =                  mouseController.mouseMoved;
            end
            
            function obj = mouseButtonPressed(obj)    %% get mouse action (defined by key press during button down); 
                 mouseController =      PMMovieController_MouseAction(obj);
                 obj =                  mouseController.mouseButtonPressed;
            end
            
            function obj = mouseButtonReleased(obj)    %% get mouse action (defined by key press during button down); 
                 mouseController =      PMMovieController_MouseAction(obj);
                 obj =                  mouseController.mouseButtonReleased;
            end
             
             
          function obj = deleteImageAnalysisFile(obj)
              obj.LoadedMovie = obj.LoadedMovie.deleteFile;
          end
            
        %% interpret key
        function [obj] =    interpretKey(obj, PressedKey, CurrentModifier)
            obj.PressedKeyValue =       PressedKey;  
            obj =                       PMMovieController_Keypress(obj).processKeyInput(PressedKey, CurrentModifier);
            obj.PressedKeyValue = '';
        end
        
          %% update image:
        function obj =                              updateImageView(obj)
            obj =       obj.setViewsForCurrentEditingActivity;
            obj =       obj.updateAnnotationViews;
            
            obj =       obj.updateCentroidsOfSelectedMasksView;
            obj =       obj.upCentroidOfActiveTrackView;
            
            obj =       obj.updateManualDriftCorrectionView;
            obj.Views.enableAllViews;
            obj =       obj.shiftImageByDriftCorrection;
            
            obj.LoadedMovie =       obj.LoadedMovie.showEdgeDetectionInView(obj.Views.MovieView.MainImage);
            obj =                   obj.updateRgbImage;
            obj.Views.MovieView.ViewMovieAxes.Color =       [0.1 0.1 0.1];
            
        end
        
        %% showAutoTrackingController
        function obj = showAutoTrackingController(obj)
             obj.TrackingAutoTrackingController =         obj.TrackingAutoTrackingController.resetModelWith(obj.LoadedMovie.getTracking, 'ForceDisplay');
             obj =                                        obj.updateHandlesForAutoTrackingController;
        end
            
             
             
        
       
    end
    
    methods (Access = private)
        
        %% showAutoTrackingController
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
                        obj =                           obj.trackByMinimizingDistancesOfTracks;
                        
                  case 'Delete tracks'
                        obj =                           obj.unTrack;
                        
                  case 'Connect exisiting tracks with each other'
                       obj.LoadedMovie.Tracking =      obj.LoadedMovie.Tracking.performSerialTrackReconnection;
                       
                  case 'Track-Delete-Connect'
                       obj.LoadedMovie.Tracking =     obj.LoadedMovie.Tracking.autTrackingProcedure(obj.LoadedMovie.getTrackingAnalysis);
                       
              end
              obj =       obj.updateAllTrackingViews;

          end
          
         
        
        %%  mergeTracksByProximity
        function obj = mergeTracksByProximity(obj)
            answer=            inputdlg('How much overlap for track merging? Negative: tracks overlap; Positive gaps');
            obj.LoadedMovie =  obj.LoadedMovie.mergeTracksWithinDistance(round(str2double(answer{1})));   
            obj =              obj.updateAllViewsThatDependOnActiveTrack;
        end
                                     

        %% setChannelCallbacks
        function obj = setChannelCallbacks(obj)
            
            obj.Views.Channels.SelectedChannel.Callback =         @obj.channelViewClicked;
            obj.Views.Channels.MinimumIntensity.Callback =        @obj.channelLowIntensityClicked;
            obj.Views.Channels.MaximumIntensity.Callback =        @obj.channelHighIntensityClicked;
            obj.Views.Channels.Color.Callback =                   @obj.channelColorClicked;
            obj.Views.Channels.Comment.Callback =                 @obj.channelCommentClicked;
            obj.Views.Channels.OnOff.Callback =                   @obj.channelOnOffClicked;
            obj.Views.Channels.ChannelReconstruction.Callback =   @obj.channelReconstructionClicked;
 
            
        end
        
        %% other:
            function obj =       setViewsForCurrentEditingActivity(obj)
               index =      find(strcmp(obj.Views.getEditingType, obj.LoadedMovie.getPossibleEditingActivities));
               obj.Views =  obj.Views.setEditingTypeToIndex(index);   
           end
        
            function obj =      updateAnnotationViews(obj)
                % update annotation within image view:
                switch obj.LoadedMovie.getTimeVisibility                  
                      case 1
                          obj.Views.MovieView.TimeStampText.Visible = 'on';
                      otherwise
                          obj.Views.MovieView.TimeStampText.Visible = 'off';
                end

                switch obj.LoadedMovie.getPlaneVisibility
                      case 1
                          obj.Views.MovieView.ZStampText.Visible = 'on';
                      otherwise
                          obj.Views.MovieView.ZStampText.Visible = 'off';
                end

                obj.Views.MovieView.ZStampText.String =             obj.LoadedMovie.getActivePlaneStamp;
                obj.Views.MovieView.TimeStampText.String =          obj.LoadedMovie.getActiveTimeStamp;

                obj.Views =   obj.Views.setScaleBarVisibility(obj.LoadedMovie.getScaleBarVisibility);
                obj.Views =   obj.Views.setScaleBarSize(obj.LoadedMovie.getDistanceBetweenXPixels_MicroMeter);
                
          end
        
            function obj =      updateCentroidsOfSelectedMasksView(obj)

            if isempty(obj.LoadedMovie.getTrackingNavigationOfSelectedTracks)
            else
                obj.Views.MovieView.CentroidLine.XData =    obj.LoadedMovie.getTrackingNavigationOfSelectedTracks.getAllCentroidXCoordinates;
                obj.Views.MovieView.CentroidLine.YData =    obj.LoadedMovie.getTrackingNavigationOfSelectedTracks.getAllCentroidYCoordinates;
            end

        end
        
            function obj =      upCentroidOfActiveTrackView(obj)
                if isempty(obj.LoadedMovie.getTrackingNavigationOfActiveTrack)
                else
                obj.Views.MovieView.CentroidLine_SelectedTrack.XData =      obj.LoadedMovie.getTrackingNavigationOfActiveTrack.getAllCentroidXCoordinates;
                obj.Views.MovieView.CentroidLine_SelectedTrack.YData =      obj.LoadedMovie.getTrackingNavigationOfActiveTrack.getAllCentroidYCoordinates;

                end
            end

            function [obj] =    updateManualDriftCorrectionView(obj)

            obj.Views.MovieView.ManualDriftCorrectionLine.XData =    obj.LoadedMovie.getActivePositionsOfManualDriftcorrectionFor('X');
            obj.Views.MovieView.ManualDriftCorrectionLine.YData =    obj.LoadedMovie.getActivePositionsOfManualDriftcorrectionFor('Y');;

            if ismember(obj.LoadedMovie.getActivePlanes,   obj.LoadedMovie.getActivePositionsOfManualDriftcorrectionFor('Z') )
                obj.Views.MovieView.ManualDriftCorrectionLine.LineWidth =           3;
            else
                obj.Views.MovieView.ManualDriftCorrectionLine.LineWidth =          1;
            end

            end

            function obj =      shiftImageByDriftCorrection(obj)
            obj.Views.MovieView.MainImage.XData =       obj.getXLimitsOfImage;
            obj.Views.MovieView.MainImage.YData =       obj.getYLimitsOfImage;

            end

            function xLimits =  getXLimitsOfImage(obj)
             [~, columnsInImage, ~] =       obj.LoadedMovie.getImageDimensions;
            CurrentColumnShift=             obj.LoadedMovie.getAplliedColumnShiftsForActiveFrames;
            xLimits =                       [1+  CurrentColumnShift, columnsInImage + CurrentColumnShift];
            end

            function yLimits =  getYLimitsOfImage(obj)
             [rowsInImage, ~, ~] =      obj.LoadedMovie.getImageDimensions;
             CurrentRowShift =          obj.LoadedMovie.getAplliedRowShiftsForActiveFrames;
             yLimits = [1+  CurrentRowShift, rowsInImage + CurrentRowShift];
            end

            function obj =      updateRgbImage(obj)
                 obj =                   obj.updateLoadedImageVolumes;
                 rgbImage =              obj.LoadedMovie.convertImageVolumeIntoRgbImage(obj.getActiveImageVolume); 
                if obj.LoadedMovie.getMaskVisibility 
                    rgbImage =                                                          obj.addMasksToImage(rgbImage);
                end
                obj.Views.MovieView.MainImage.CData=                                    rgbImage;

            end

            function obj =      updateLoadedImageVolumes(obj)
                
                 numericalNeededFrames =   obj.getFramesThatNeedToBeLoaded;
                 if isempty(numericalNeededFrames)

                 else
                      obj.LoadedImageVolumes(numericalNeededFrames,1 ) = obj.LoadedMovie.loadImageVolumesForFrames(numericalNeededFrames);
                 end
                  obj.Views.enableAllViews;
            end

            function [requiredFrames] =     getFramesThatNeedToBeLoaded(obj)
                obj =                                       obj.resetLoadedImageVolumesIfInvalid;
                requiredFrames =                            obj.getFrameNumbersThatMustBeInMemory;
                alreadyLoadedFrames =                       obj.getFramesThatAreAlreadyInMemory;

                requiredFrames(alreadyLoadedFrames,1) =     false;
                requiredFrames = find(requiredFrames);

            end

            function obj =              resetLoadedImageVolumesIfInvalid(obj)
            if ~iscell(obj.LoadedImageVolumes) || length(obj.LoadedImageVolumes) ~= obj.LoadedMovie.getMaxFrame
               obj.LoadedImageVolumes =                            cell(obj.LoadedMovie.getMaxFrame,1);
            end
            end

            function requiredFrames =   getFrameNumbersThatMustBeInMemory(obj)
                    requiredFrames(1: obj.LoadedMovie.getMaxFrame, 1) = false;
                    range =                 obj.LoadedMovie.getActiveFrames - obj.getLimitForLoadingFrames : obj.LoadedMovie.getActiveFrames + obj.getLimitForLoadingFrames;
                    range(range<=0) =       [];
                    range(range > obj.LoadedMovie.getMaxFrame) =       [];
                    requiredFrames(range,1) =                                     true;
            end

             function frames =          getLimitForLoadingFrames(obj)
                   PressedKey =                            obj.PressedKeyValue;  
                    PressedKeyAsciiCode=                    double(PressedKey);
                    if PressedKeyAsciiCode == 29 
                        frames =        obj.DefaultNumberOfLoadedFrames;
                    else
                        frames =        0;
                    end
             end

             function framesThatHaveTheMovieAlreadyLoaded = getFramesThatAreAlreadyInMemory(obj)
                  framesThatHaveTheMovieAlreadyLoaded =         cellfun(@(x)  ~isempty(x),     obj.LoadedImageVolumes);   

                  %framesWithMatchingImageSize =                 cellfun(@(x)  obj.LoadedMovie.imageMatchesDimensions(x),     obj.LoadedImageVolumes);  
                 % neededFrames =                                min([framesThatHaveTheMovieAlreadyLoaded, framesWithMatchingImageSize], [], 2);
             end

            function activeVolume = getActiveImageVolume(obj)
                activeVolume =     obj.LoadedImageVolumes{obj.LoadedMovie.getActiveFrames,1};
            end
             
             function [rgbImage] =                addMasksToImage(obj, rgbImage)
                  if isempty(obj.LoadedMovie.getTrackingNavigationOfSelectedTracks)

                  else
                       IntensityForRedChannel =          obj.MaskColor(1);
                    IntensityForGreenChannel =        obj.MaskColor(2);
                    IntensityForBlueChannel =         obj.MaskColor(3);
                    if strcmp(class(rgbImage), 'uint16')
                        IntensityForRedChannel =        IntensityForRedChannel * 255;
                        IntensityForGreenChannel =      IntensityForGreenChannel * 255;
                        IntensityForBlueChannel =       IntensityForBlueChannel * 255;
                    end

                    rgbImage = obj.highlightPixelsInRgbImage(rgbImage, obj.LoadedMovie.getTrackingNavigationOfSelectedTracks.getAllMaskCoordinates, 1, IntensityForRedChannel);
                    rgbImage = obj.highlightPixelsInRgbImage(rgbImage, obj.LoadedMovie.getTrackingNavigationOfSelectedTracks.getAllMaskCoordinates, 2, IntensityForGreenChannel);
                    rgbImage = obj.highlightPixelsInRgbImage(rgbImage, obj.LoadedMovie.getTrackingNavigationOfSelectedTracks.getAllMaskCoordinates, 3, IntensityForBlueChannel);


                    CoordinateListActive =    obj.LoadedMovie.getTrackingNavigationOfActiveTrack.getAllMaskCoordinates;

                    if isempty( CoordinateListActive)
                    else

                        Intensity =    255;
                        if strcmp(class(rgbImage), 'uint16')
                            Intensity = Intensity * 255;
                        end


                        CoordinateListActive(isnan(CoordinateListActive(:,1)),:) = [];
                        rgbImage = obj.highlightPixelsInRgbImage(rgbImage, CoordinateListActive, 1:3, Intensity);

                    end
              end




               end



    end
    
end

