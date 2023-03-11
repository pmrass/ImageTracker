classdef PMMovieControllerView
    %PMMOVIECONTROLLERVIEW Manages views of PMMovieController
    %   Detailed explanation goes here
    
    properties (Access = private)
        
       ShowLog = false;
       SelectedCentroidPlanePreference = 'OnlyCenter'; % 'AllOverlappingPlanes' 
        
    end
    
    properties (Access = private)

        Figure
        MovieView

        Navigation
        Channels
        Annotation
        TrackingViews

        ListOfTrackViews =          cell(0,1)
        BackgroundColor =           [0 0.1 0.2];
        ForegroundColor =           'c';
        
    end
    
    properties (Access = private) % unclear if this properties are real;
         Menu % is this needed?
        EditingType

    end
    
    properties (Constant, Access = private)
        ChannelFilterTypes = {'Raw','Median filter', 'Complex filter'};
        ChannelFilterTypes_MovieTracking =  {'Raw', 'Median', 'Complex'};
    end
    
    methods % setter TRACK LINES
        
        function obj =      setTrackLineViewsWith(obj, MovieTracking, varargin)
            % SETTRACKLINEVIEWSWITH set the position of track lines; 
            % this does not influence visibility; visibility is set with setTrackVisibility;
            % it takes 1 or 2 arguments:
            % 1: PMMovieTracking object
            % 2: logical vector with three values;
                % 1: show active track; % 2: show selected track; %  3:
                % show resting track:
                
            assert(isscalar(MovieTracking) && isa(MovieTracking, 'PMMovieTracking'), 'Wrong input.')
            
            switch length(varargin)
                case 0
                   
                    
                otherwise
                    error('Wrong input.')
   
            end
       
            ListWithAllVisibleTrackIDs =        MovieTracking.getIDsOfAllVisibleTracks;
            
            
            obj =       obj.deleteAllTrackLineViews;
            obj =       obj.addMissingTrackLineViews(ListWithAllVisibleTrackIDs);
           

            if MovieTracking.getTrackVisibility
                obj =       obj.updateTrackLinesWithIDAndSize(MovieTracking, MovieTracking.getIdOfActiveTrack, 3);
            end
            
            if MovieTracking.getSelectedTracksAreVisible
                obj =       obj.updateTrackLinesWithIDAndSize(MovieTracking, MovieTracking.getSelectedTrackIDs, 1);
            end
            
            if 0 % MovieTracking.getRestingTracksAreVisible
                obj =       obj.updateTrackLinesWithIDAndSize(MovieTracking, MovieTracking.getIdsOfRestingTracks, 0);
            end

        end

        function obj =      setTrackVisibility(obj, Input)
            % SETTRACKVISIBILITY turn track on or off;
            % takes 1 argument:
            % 1:  logical scalar

            function track = changeTrackVisibility(track, state)
                try 
                track.Visible = state;
                catch
                end
            end
            
            obj.TrackingViews.ShowTracks.Value =        Input;
            cellfun(@(x) changeTrackVisibility(x, Input), obj.ListOfTrackViews);

        end
        
    end
    
    methods % initialization
        
        function obj = PMMovieControllerView(varargin)
            %PMMOVIECONTROLLERVIEW Construct an instance of this class
            %   Creation of views that support navigating through the loaded image-sequences;
            % takes 0, or 1 argument:
            % 1:    either axes (into which movie movie will be places)
            %       or PMImagingProjectViewer, into which movie-view and navigation, channel, annotation, and tracking views are placed;
     
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                
                case 0

                case 1
                    switch class(varargin{1})
                        case 'matlab.graphics.axis.Axes'
                            
                            MyAxes = varargin{1};
                              obj.Figure =    varargin{1}.Parent;  
                              obj =           obj.createMovieView(MyAxes);
                            
                        case 'PMImagingProjectViewer'
                            
                            ImagingProjectViewer = varargin{1};
                            assert(isvalid(ImagingProjectViewer.getFigure), 'Valid figure needed.')
                            
                                obj =       obj.CreateNavigationViews(ImagingProjectViewer);
                                obj =       obj.CreateChannelViews(ImagingProjectViewer);
                                obj =       obj.CreateAnnotationViews(ImagingProjectViewer);
                                obj =       obj.createMovieView(ImagingProjectViewer);
                                obj =       obj.setFigure(ImagingProjectViewer.getFigure);  
                                obj =       obj.setTrackingViews(ImagingProjectViewer);

                                obj.changeAppearance;
                                %obj.disableAllViews;
                          
                
                              
                            
                        otherwise
                            error('Input not supported.')
                        
                    end
                        
                otherwise
                    error('Wrong input.')
                
            end

        end
        
        function obj = set.Channels(obj, Value)
            
           obj.Channels = Value; 
        end
        
        function obj = set.TrackingViews(obj, Value)
            obj.TrackingViews = Value;
        end
        
        function obj = set.MovieView(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMMovieView'), 'Wrong input.')
            obj.MovieView = Value;
        end
        
    end
    
    methods % getters
       
         function myFigure = getFigure(obj)
            myFigure = obj.Figure;            
        end
        
    end
    
    methods % SETTERS CLEAR
       
          function obj = clear(obj)
              % CLEAR deletes graphical elements
              % takes 0 arguments
            
              if isempty(obj.MovieView)
                  
              else
                   obj.MovieView =      obj.MovieView.clear;
                   ListWithAllViews =   obj.getListWithAllViews;
                   cellfun(@(x) delete(x), ListWithAllViews)
                   obj =                obj.deleteAllTrackLineViews;   
                   
              end
           
            
            
        end
        
        
    end
    
    methods % setters MOVIE-VIEW
        
        function obj = updateMovieViewWith(obj, varargin)

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    assert(isa(varargin{1}, 'PMMovieTracking'))
                    
                
                    obj = obj.setMovieViewWithLoadedMovie(varargin{1});
                    
                case 2
                    
                    MyMovieTracking=    varargin{1};
                    MyImage =           varargin{2};
                    
                    assert(isa(MyMovieTracking, 'PMMovieTracking'))
                    assert(isnumeric(MyImage), 'Wrong input.')
                    
                    obj =       obj.setMovieViewWithLoadedMovie(MyMovieTracking);
                    obj =       obj.setMovieImagePixels(MyImage);
                    obj =       obj.setDefaults;
                    obj =       obj.addEdgeDetectionToMovieMovie(MyMovieTracking);
                   
                    
                    
                otherwise
                    error('Wrong input.')
                 
            end

        end
       
        function obj = shiftAxes(obj, xShift, yShift)
            NewXCenter =    obj.getMovieAxes.XLim - xShift;
            NewYCenter =    obj.getMovieAxes.YLim - yShift;
            obj =     obj.setMovieAxesLimits(NewXCenter, NewYCenter);
        end
        
        function obj = setMovieImagePixels(obj,Image)
            obj.MovieView =     obj.MovieView.setImageContent(Image);
        end
        
        function obj = addEdgeDetectionToMovieMovie(obj, Movie)
              if Movie.getTrackVisibility 
                     segmentationOfActiveTrack  =               Movie.getSegmentationOfActiveMask;
                     if ~isempty(segmentationOfActiveTrack) && ~isempty(segmentationOfActiveTrack{1,7})
                        SegmentationInfoOfActiveTrack = segmentationOfActiveTrack{1,7};
                        
                        if  ismethod(SegmentationInfoOfActiveTrack, 'getSegmentationType')
                             if ischar(SegmentationInfoOfActiveTrack.getSegmentationType) || isempty(SegmentationInfoOfActiveTrack.getSegmentationType)
                            else
                                SegmentationInfoOfActiveTrack.getSegmentationType.highLightAutoEdgeDetection(obj.getMovieImage);

                            end
                            
                        else
                            if ischar(SegmentationInfoOfActiveTrack.SegmentationType) || isempty(SegmentationInfoOfActiveTrack.SegmentationType)
                            else
                                SegmentationInfoOfActiveTrack.SegmentationType.highLightAutoEdgeDetection(obj.getMovieImage);

                            end
                            
                        end
                        
                      
                     end
              end
        end    
   
        function obj = setVisibilityOfActiveTrack(obj, Value)
           obj.MovieView = obj.MovieView.setVisibilityOfActiveTrack(Value);
            
        end
 
        function obj = setCentroidVisibility(obj, Value)
            obj.MovieView = obj.MovieView.setCentroidVisibility(Value);
        end
        
        function obj = blackOutMovieView(obj)
            obj.MovieView = obj.MovieView.inactivate;
        end
 
        function obj = setCoordinatesOfActiveTrack(obj, XCoordinates, YCoordinates)
            
            obj.MovieView = obj.MovieView.setActiveCentroidCoordinates(XCoordinates, YCoordinates);
            
           
        end

        function obj = updateManualDriftIndicatorsWith(obj, Value)
             obj.MovieView = obj.MovieView.setManualDriftCorrectionCoordinatesWith(Value); 
         end
    
        function obj = updateDriftWith(obj, Value)
             obj.MovieView = obj.MovieView.updateDriftWith(Value);
             
            
        end
        
        function obj = setScalebarText(obj, Value)
          obj.MovieView.ScalebarText.String = Value;
        end

     
         
         
   
    end
    
    methods % getters MOVIE-VIEW
       
        function axes = getMovieAxes(obj)
            axes = obj.MovieView.getAxes;
        end
        
         function axes = getMovieImage(obj)
            axes = obj.MovieView.getImage;
         end
        
         function rect = getRectangle(obj)
              rect = obj.MovieView.getRectangle;
         end
         
    end
    
    methods % summary
        
        function view = getMovieView(obj)
           view = obj.MovieView; 
        end
        
      
        function obj = showSummary(obj)
           
         
        end
        
    end
    
    methods % setters cropping and axes
        
        function obj = setRectangleWith(obj, Value)
            
                Type = class(Value);

                switch Type

                   case 'PMMovieTracking'

                       MyRectangle = obj.getRectangle;
                        MyRectangle.Visible =   'on';
                        
                        YValues = Value.getYPointsForCroppingRectangleView;
                        XValues = Value.getXPointsForCroppingRectangleView;
                        MyRectangle.YData=      YValues;
                        MyRectangle.XData=      XValues;
                        MyRectangle.Color =     'w';

                   otherwise
                       error('Wrong input.')

                end
            
        end

        function obj = setLimitsOfMovieViewWith(obj, Value)
           Type = class(Value);
           switch Type
               case 'PMMovieTracking'
                    XLimits =   PMRectangle(Value.getAppliedCroppingRectangle).getXLimits;
                    YLimits =   PMRectangle(Value.getAppliedCroppingRectangle).getYLimits;
                    obj =       obj.setMovieAxesLimits(XLimits, YLimits);
                
               otherwise
                   error('Wrong input.')
           end
            
            
        end
        
        function obj = setMovieAxesLimits(obj, XLimits, YLimits)
            
            obj.MovieView=    obj.MovieView.setAxesLimits(XLimits, YLimits);
        end
        
        function obj = setMovieAxesWidth(obj, Width)
            error('Not supported anymore. Stop using it.')
            obj.MovieView=    obj.MovieView.setAxesWidth(Width);
        end
          
    end
    
    methods % SETTERS NAVIGATION AND CHANNELS
       
         function obj = setControlElements(obj, Value)
             % SETCONTROLELEMENTS sets navigation and channel panels;
             % takes 1 argument:
             % 1: PMMovieTracking
            Type = class(Value);
            switch Type
               case 'PMMovieTracking'
                    obj =   obj.setNavigationWith(Value);
                    obj =   obj.setChannelsWith(Value);

               otherwise
                   error('Type not supported.')

            end



         end
         
          function obj = setNavigationWith(obj, Value)
              
                Type = class(Value);
                switch Type
                   case 'PMMovieTracking'
                        obj = obj.setNavigationWithMovieTracking(Value);        
                   otherwise
                       error('Type not supported.')
                end
          end
          
            function obj = setChannelsWith(obj, MovieTracking)

                if isempty(obj.Channels) || isempty(MovieTracking.getChannels)
                    
                else

                    obj.Channels.SelectedChannel.String =            1 : MovieTracking.getMaxChannel;
                    if obj.Channels.SelectedChannel.Value<1 || obj.Channels.SelectedChannel.Value>length(obj.Channels.SelectedChannel.String)
                        obj.Channels.SelectedChannel.Value = 1;
                    end

                    obj.Channels.SelectedChannel.String =                 1 : MovieTracking.getMaxChannel;
                    obj.Channels.SelectedChannel.Value =                  MovieTracking.getIndexOfActiveChannel;
                    obj.Channels.MinimumIntensity.String =                MovieTracking.getIntensityLowOfActiveChannel;
                    obj.Channels.MaximumIntensity.String =                MovieTracking.getIntensityHighOfActiveChannel;
                    
                    Value=                                                  find(strcmp(MovieTracking.getColorStringOfActiveChannel, obj.Channels.Color.String));
                    assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
                    obj.Channels.Color.Value =                            Value;
                    obj.Channels.Comment.String =                         MovieTracking.getCommentOfActiveChannel;
                    obj.Channels.OnOff.Value =                            MovieTracking.getVisibleOfActiveChannel;
                    obj.Channels.ChannelReconstruction.Value =         obj.getActiveChannelReconstructionIndexFromMovieTracking(MovieTracking);

                end


            end

    
          
      
        

        
    end
    
    methods % setters TRACKING-PANEL
        
         function obj = setTrackingViewsWith(obj, Value)

            Type = class(Value);
            switch Type
               case 'PMMovieTracking'
                   
                    obj.TrackingViews.ShowMaximumProjection.Value =    Value.getCollapseAllTracking;
                     obj.TrackingViews.ActiveTrack.Value =                                Value.getTrackVisibility;
                    obj.TrackingViews.ActiveTrack.String =        num2str(Value.getIdOfActiveTrack);
                    obj.TrackingViews.ShowMasks.Value =                 Value.getMaskVisibility;
                    obj.TrackingViews.ShowCentroids.Value =        Value.getCentroidVisibility;
                otherwise
                    error('Input not supported.')

            end
            
            if isnan(Value.getIdOfActiveTrack)
                obj =     obj.setVisibilityOfActiveTrack(false);

            else
                obj =     obj.setVisibilityOfActiveTrack(Value.getTrackVisibility);

            end


         end
        
        
    end
    
    methods % save status
        
        
         function obj =   updateSaveStatusWith(obj, Value)

             Type = class(Value);
            switch Type
               case 'PMMovieTracking'

                    fprintf('PMMovieController:@updateSaveStatusView: ')
                     if isempty(Value)
                         fprintf('No active movie detected: no action taken.\n')

                     else
                        switch Value.getUnsavedDataExist
                            case true
                                fprintf('Unsaved data exist: Set color to red.\n')
                                obj.TrackingViews.TrackingTitle.ForegroundColor = 'red';

                            otherwise
                                fprintf('All relevant data are already saved: Set color to green.\n')
                                obj.TrackingViews.TrackingTitle.ForegroundColor = 'green';

                        end
                     end

                otherwise  

                    error('Input not supported.')

            end


        end
        
        
        
    end
    
    methods % SETTERS ANNOTATION:
       
         function obj = setScaleBarVisibility(obj, ScaleBarVisible)
           obj.MovieView = obj.MovieView.setScaleBarVisibility(ScaleBarVisible);
        end
        
        
    end
    
    methods % SETTERS: ACTIVE CENTROID
       
        function obj = setActiveCentroidWith(obj, Value)
            Type = class(Value);
            switch Type
                case 'PMMovieTracking'
                    
                    Coordinates =  Value.getTracking.getActiveCentroidAtFramePlaneDrift(...
                                                        Value.getActiveFrames, ...
                                                        Value.getVisibleTrackingPlanesWithoutDriftCorrection, ...
                                                        Value.getDriftCorrection...
                                                        );
                   if isempty(Coordinates)
                        obj =               obj.setCoordinatesOfActiveTrack(zeros(0,1), zeros(0,1));
                   else
                       
                        obj =               obj.setCoordinatesOfActiveTrack(Coordinates(:, 1), Coordinates(:, 2));
                   end
                otherwise
                    error('Wrong input.')
                    
            end

        end
        
    end
    
    methods % setters
        
       
    
        function obj = setFigure(obj, Value)
            obj.Figure = Value;
        end

        function obj = setDefaults(obj)
            obj.MovieView=      obj.MovieView.setDefaults;
        end
        
        function obj = resetNavigationFontSize(obj, FontSize)
           obj.MovieView = obj.MovieView.setAnnotationFontSize(FontSize);

        end

        function obj = setEditingTypeDependentPropertiesWith(obj, Value)
             Type = class(Value);
           switch Type
               case 'PMMovieTracking'
                    index =      find(strcmp(obj.getEditingType, Value.getPossibleEditingActivities));
                  %  obj.Navigation.EditingOptions.Value =          index;
                     switch index
                        case {1, 3} % 'Visualize', 'Tracking;
                            Value = 'off';
                        case 2
                            Value = 'on';
                     end
                    obj.MovieView =     obj.MovieView.setVisibilityOfManualDriftCorrection(Value);
                    
               otherwise
                   error('Wrong input.')
           end
 
        end

        %% setSelectedCentroidsWith:
        function obj = setSelectedCentroidsWith(obj, Value)
            
            Type = class(Value);
            switch Type
                case 'PMMovieTracking'
                    
                    MyFrames =                                  Value.getActiveFrames;
                    PlanesThatArveVisibleForSegmentation =      Value.getVisibleTrackingPlanesWithoutDriftCorrection;
                    MyDriftCorrection =                         Value.getDriftCorrection;
                    
                    Coordinates =  Value.getTracking.getSelectedCentroidsAtFramePlaneDrift(MyFrames, ...
                        PlanesThatArveVisibleForSegmentation, ...
                        MyDriftCorrection, obj.SelectedCentroidPlanePreference);
                    
                    obj = obj.setCentroidCoordinates(Coordinates(:, 1), Coordinates(:, 2));
                    
                otherwise
                   error('Wrong input.')

            end            
        end
        
        function obj = setCentroidCoordinates(obj, X, Y)
            obj.MovieView =     obj.MovieView.setSelectedCentroidCoordinates(X, Y);
            
          
        end
        
        %% setActiveCentroidWith:
        
        
        function obj = setCurrentCharacter(obj, Value)
            
                 obj.Figure.CurrentCharacter =                   Value;
        end
        
        function obj = setTrackingViews(obj, Value)
            MyTrackingView = PMTrackingView(Value);
            obj.TrackingViews = MyTrackingView.ControlPanels;
            
        end


        %% updateSaveStatusWith
       
        function obj = setSegmentLineViews(obj, StopTracks, GoTracks)
           obj.MovieView = obj.MovieView.setSegmentLineViews( StopTracks, GoTracks); 
            
        end
        
         function obj = setShowMaximumProjection(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.Navigation.ShowMaxVolume.Value =   Value;
        end

    end
    
    methods % SETTERS APPEARANCE AND ENABLED STATUS
        
        function obj = changeAppearance(obj)
            fprintf('PMMovieController:@changeAppearance: change foreground and background of view ')

            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                fprintf('%i of % %i ', CurrentIndex, NumberOfViews)
                if strcmp(ListWithAllViews{CurrentIndex,1}.Style, 'popupmenu')
                    ListWithAllViews{CurrentIndex,1}.ForegroundColor = 'r';
                else
                    ListWithAllViews{CurrentIndex,1}.ForegroundColor =      obj.ForegroundColor;
                end
                ListWithAllViews{CurrentIndex,1}.BackgroundColor =       obj.BackgroundColor;
            end
            fprintf('\n')

         end
        
        function obj = disableAllViews(obj)

            fprintf('PMMovieController:@disableAllViews ')
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews

                fprintf('%i of %i ', CurrentIndex, NumberOfViews)
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                CurrentView.Enable = 'off';

            end
            fprintf('\n')

        end

        function obj = enableAllViews(obj)

            ListWithAllViews =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                try
                if isvalid(CurrentView)
                    CurrentView.Enable = 'on';
                end
                catch
                    
                end

            end


        end

    end
    
    methods % getters channels
        
        function value = getSelectedChannel(obj)
            value = obj.Channels.SelectedChannel.Value;
        end
        
        function value = getMinimumIntensityOfSelectedChannel(obj)
            value = str2double(obj.Channels.MinimumIntensity.String);
        end

        function value = getMaximumIntensityOfSelectedChannel(obj)
            value = str2double(obj.Channels.MaximumIntensity.String);
        end
        
        function value = getColorOfSelectedChannel(obj)
            value = obj.Channels.Color.String{obj.Channels.Color.Value};
        end
        
        function value = getCommentOfSelectedChannel(obj)
            value = obj.Channels.Comment.String;
        end
        
        function value = getVisibilityOfSelectedChannel(obj)
            value = logical(obj.Channels.OnOff.Value);
        end
        
        function ChannelReconstructionType = getFilterTypeOfSelectedChannel(obj)
            ChannelReconstructionType =                 obj.ChannelFilterTypes_MovieTracking{obj.Channels.ChannelReconstruction.Value};
        end 
        
        
        
    end
    
    methods % getters tracking
        
        function value = getShowTrackingOfActiveTrack(obj)
            value  = logical(obj.TrackingViews.ActiveTrackTitle.Value);
        end
        
        function value = getShowCentroids(obj)
            value  = logical(obj.TrackingViews.ShowCentroids.Value);
        end
        
        function value = getShowMasks(obj)
            value  = logical(obj.TrackingViews.ShowMasks.Value);
        end
        
        function value = getShowTracks(obj)
            try
            value  = logical(obj.TrackingViews.ShowTracks.Value);
            catch
                warning('showTracks could not be retrieved from PMMovieControllerView.')
               value = true; 
            end
        end
        
        function value = getShowMaxProjectionOfTrackingData(obj)
            value  = logical(obj.TrackingViews.ShowMaximumProjection.Value);
        end

        
        
    end
    
    methods % getters annotation
       
       
        
        
        function value = getScalbarVisibility(obj)
            value  = obj.Annotation.ShowScaleBar.Value;
        end
        
        function value = getScalbarSize(obj)
            value  = str2double(obj.Annotation.SizeOfScaleBar.String(obj.Annotation.SizeOfScaleBar.Value, :));
        end
        
       function string = getEditingType(obj)
           
           try
            input =                        obj.Navigation.EditingOptions.String{obj.Navigation.EditingOptions.Value};
            
           catch
               input = 'Viewing only';
           end
           
          
            switch input
                case 'Viewing only' % 'Visualize'
                    string =                                   'No editing';
                case 'Edit manual drift correction'
                    string =                                   'Manual drift correction';
                case 'Edit tracks' %  'Tracking: draw mask'
                    string =                                'Tracking';
            end

        end
        
        
    end
    
    methods % GETTERS NAVIGATION
        
           function value = getCurrentFrames(obj)
            value =      obj.Navigation.CurrentTimePoint.Value;
           end
          
       
        function navi = getNavigation(obj)
            navi = obj.Navigation; 
        end
               
        function value = getCurrentPlanes(obj)
            value =      obj.Navigation.CurrentPlane.Value;
        end
        
         function planeRange = getPlaneRange(obj)
             % GETPLANERANGE returns range of planes as shown in view;
            
             try 
                CurrentPlaneHandle=              obj.Navigation.CurrentPlane(1);
                ShowMaxVolume=                   obj.Navigation.ShowMaxVolume.Value;

                if ShowMaxVolume
                    planeRange(1)=          1;
                    planeRange(2)=             size(CurrentPlaneHandle.String,1);

                else
                    planeRange(1)=          CurrentPlaneHandle.Value;
                    planeRange(2)=             length(obj.Navigation.CurrentPlane);


                end

             catch
                 warning('Plane range could not be retrieved from PMMovieControllerView.')
                 planeRange = [1, 1];
                 
             end
                
            
         end
        
        
        
    end
    
    methods % getters
        
          function TrackHandles =     getHandlesForTrackIDs(obj, TrackID)
            if isempty(TrackID)
                TrackHandles = cell(0,1);
            else
                TrackHandles =      obj.ListOfTrackViews(ismember(obj.getTrackIdsOfTrackHandles,  TrackID), :);
            end    
          end
        
          
        function activeView = getActiveView(obj)
            if obj.Figure.CurrentObject == obj.getMovieImage
                activeView = 'MovieImage';
            else
                activeView = 'Unknown';
            end
            
        end
       
         
        function modifier = getModifier(obj)
            CurrentModifier = obj.Figure.CurrentModifier;
            if ischar(CurrentModifier)
               CurrentModifier = {CurrentModifier}; 
            end
             modifier = PMKeyModifiers(CurrentModifier).getNameOfModifier;
            
        end
        
           function value = getCropImage(obj)
            value = logical(obj.Navigation.CropImageHandle.Value);
           end
        
         
        
        function value = getApplyDriftCorrection(obj)
            value =      logical(obj.Navigation.ApplyDriftCorrection.Value);
        end
        
        function value = getShowMaximumProjection(obj)
            value =      logical(obj.Navigation.ShowMaxVolume.Value);
        end

        
        
        
    end
    
    methods (Access = private) % 

         function PressedKey = getPressedKey(obj)
              PressedKey=       get(obj.Figure,'CurrentCharacter');
         end
          
        function CurrentModifier = getRawModifier(obj)
            CurrentModifier = obj.Figure.CurrentModifier;
            
        end

        function Index = getActiveChannelReconstructionIndexFromMovieTracking(obj, MovieTracking)
            Index = find(strcmp(MovieTracking.getReconstructionTypeOfActiveChannel, obj.ChannelFilterTypes_MovieTracking));
            if isempty(Index)
               Index = 1; 
            end
        end
        
    

        function Value = getTrackingViews(obj)
            Value = obj.TrackingViews;
        end

    end
    
    methods % callbacks
       
        function obj =      setKeyMouseCallbacks(obj, varargin)
                obj.Figure.WindowKeyPressFcn =        varargin{1};
                obj.Figure.WindowButtonDownFcn =      varargin{2};
                obj.Figure.WindowButtonUpFcn =        varargin{3};
                obj.Figure.WindowButtonMotionFcn =    varargin{4};
        end
        
        function obj =      setNavigationCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 6
                    obj.Navigation.EditingOptions.Callback =            varargin{1};
                    obj.Navigation.CurrentPlane.Callback =             varargin{2};
                    obj.Navigation.CurrentTimePoint.Callback =         varargin{3};
                    obj.Navigation.ShowMaxVolume.Callback =            varargin{4};
                    obj.Navigation.CropImageHandle.Callback =          varargin{5};
                    obj.Navigation.ApplyDriftCorrection.Callback =    varargin{6};

                otherwise
                    error('Wrong input.')

            end  


           end

        function obj =      setChannelCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 7
                    
                    if isempty(obj.Channels)
                        
                    else
                        obj.Channels.SelectedChannel.Callback =         varargin{1};
                        obj.Channels.MinimumIntensity.Callback =        varargin{2};
                        obj.Channels.MaximumIntensity.Callback =        varargin{3};
                        obj.Channels.Color.Callback =                   varargin{4};
                        obj.Channels.Comment.Callback =                 varargin{5};
                        obj.Channels.OnOff.Callback =                  varargin{6};
                        obj.Channels.ChannelReconstruction.Callback =  varargin{7};
                    
                    end

                otherwise
                    error('Wrong input.')
            end

        end

        function obj =      setAnnotationCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 2
                obj.Annotation.ShowScaleBar.Callback =             varargin{1};
                obj.Annotation.SizeOfScaleBar.Callback =           varargin{2};

                otherwise
                    error('Wrong input.')
            end

            
        end
        
        function obj =      setTrackingCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 5
                    obj.TrackingViews.ActiveTrackTitle.Callback =           varargin{1};
                    obj.TrackingViews.ShowCentroids.Callback =              varargin{2};
                    obj.TrackingViews.ShowMasks.Callback =                  varargin{3};
                    obj.TrackingViews.ShowTracks.Callback =                 varargin{4};
                    obj.TrackingViews.ShowMaximumProjection.Callback =      varargin{5};
                otherwise
                    error('Wrong input.')

            end  
        end
        
    end
    
    methods (Access = private)  % getListWithAllViews
       
        function [ListWithAllViews] =    getListWithAllViews(obj)


            if isempty(obj.Navigation)
                ListWithAllViews =       cell(0,1);
                return
            elseif isempty(obj.Channels)
                ListWithAllViews =       cell(0,1);
                return
            end

            FieldNames =                fieldnames(obj.Navigation);
            NavigationViews =           cellfun(@(x) obj.Navigation.(x), FieldNames, 'UniformOutput', false);

            FieldNames =                fieldnames(obj.Channels);
            ChannelViews =              cellfun(@(x) obj.Channels.(x), FieldNames, 'UniformOutput', false);

            FieldNames =                fieldnames(obj.Annotation);
            AnnotationViews =           cellfun(@(x) obj.Annotation.(x), FieldNames, 'UniformOutput', false);


             FieldNames = fieldnames(obj.TrackingViews);
              MyTrackingViews =           cellfun(@(x) obj.TrackingViews.(x), FieldNames, 'UniformOutput', false);
             
             
            ListWithAllViews =          [NavigationViews; ChannelViews;AnnotationViews; MyTrackingViews];

        end

     end
   
    methods (Access = private) % setters CONTROL ELEMENTS

    function obj = setNavigationWithMovieTracking(obj, MovieTracking)

    try
      
        obj.Navigation.CurrentPlane.String =        1 : MovieTracking.getMaxPlaneWithAppliedDriftCorrection;
        obj.Navigation.CurrentPlane.Value =         MovieTracking.getActivePlanesWithAppliedDriftCorrection;
        
        obj.Navigation.CurrentTimePoint.Value =     MovieTracking.getActiveFrames;  
        obj.Navigation.ShowMaxVolume.Value =        MovieTracking.getCollapseAllPlanes ;
        obj.Navigation.ApplyDriftCorrection.Value = MovieTracking.getDriftCorrection.getDriftCorrectionActive;
        obj.Navigation.CropImageHandle.Value =      MovieTracking.getCroppingOn;

        if length(obj.Navigation.CurrentPlane.Value) > 1
             obj.Navigation.CurrentPlane.Value = min(obj.Navigation.CurrentPlane.Value);
        else
              if obj.Navigation.CurrentPlane.Value < 1 || obj.Navigation.CurrentPlane.Value > length(obj.Navigation.CurrentPlane.String)
                obj.Navigation.CurrentPlane.Value = 1;

              end

        end



        obj =   obj.setMaxTime(MovieTracking.getMaxFrame);
        
    catch
        
    end

    end

  
    function obj = setMaxTime(obj, Value)
        obj.Navigation.CurrentTimePoint.String =          1 : Value; 
        if obj.Navigation.CurrentTimePoint.Value<1 || obj.Navigation.CurrentTimePoint.Value>length(obj.Navigation.CurrentTimePoint.String)
            obj.Navigation.CurrentTimePoint.Value = 1;
        end


        try
        Range = obj.Navigation.TimeSlider.Max -   obj.Navigation.TimeSlider.Min;
        if Range == 0
        obj.Navigation.TimeSlider.Visible = 'off';
        else
        Step =     1/ (Range);
        obj.Navigation.TimeSlider.Visible = 'on';
        if Step < 0 || Step > 1
           Step = 0.5; 
        end
        obj.Navigation.TimeSlider.SliderStep = [Step Step];
        end

        obj.Navigation.TimeSlider.Min =                 1;
        obj.Navigation.TimeSlider.Max =                 Value;  
        
        catch
            
        end

    end

    end

    methods (Access = private) % setter TRACK LINES
        
        function TrackHandles =     getAllTrackHandles(obj)
            AllLines =           findobj(obj.MovieView.getAxes, 'Type', 'Line');
            TrackLineRows  =     arrayfun(@(x) ~isnan(str2double(x.Tag)), AllLines);
            TrackHandles=          AllLines(TrackLineRows,:);
            if isempty(TrackHandles)
               TrackHandles = zeros(0,1); 
            end
            
        end
        
        function obj =              updateTrackLinesWithIDAndSize(obj, MovieTracking, TrackIDs, Size)
            tic
            Handles =           obj.getHandlesForTrackIDs(TrackIDs);
            
             if obj.ShowLog
                fprintf('getHandlesForTrackIDs: %6.2f seconds.\n', toc)
             end
            tic
            Coordinates =       MovieTracking.getCoordinatesForTrackIDs(TrackIDs);
            
             if obj.ShowLog
                fprintf('getCoordinatesForTrack: %6.2f seconds.\n', toc)
             end
             
            tic
            obj =               obj.setTrackLines(Handles, Coordinates, Size);
            
             if obj.ShowLog
                fprintf('setTrackLines: %6.2f seconds.\n', toc)
                end
        end

        function obj =              setTrackLines(obj, TrackHandles, Coordinates, Width)
            %CoordinatesSelected =               arrayfun(@(x) obj.getCoordinatesForTrack(x), obj.Views.getIdsFromTrackHandles(TrackHandles), 'UniformOutput', false);
            if ~isempty(TrackHandles)
                cellfun(@(x) obj.setLineWidthTo(x, Width), TrackHandles)
                cellfun(@(handles, coordinates) obj.updateTrackLineCoordinatesForHandle(handles, coordinates), TrackHandles, Coordinates);
            end
        end
        
        function  setLineWidthTo(~, Handle, Width)
            if Width == 0
                warning('Wrong line width.')
            else
                Handle.LineWidth =          Width; 
            end
            
        end

        function  updateTrackLineCoordinatesForHandle(~, HandleForCurrentTrack, Coordinates)
            if isempty(Coordinates)
                Coordinates = [0, 0, 0];
            end
            
            HandleForCurrentTrack.XData=            Coordinates(:, 1);    
            HandleForCurrentTrack.YData=            Coordinates(:, 2);  
            HandleForCurrentTrack.ZData=            Coordinates(:, 3);  
            HandleForCurrentTrack.Color=            'w';  
        end

        function obj =              addMissingTrackLineViews(obj, allTrackIdsInModel)

            function TrackLine = setTagOfTrackLines(TrackLine, TrackLineNumber)
                TrackLine.Tag = num2str(TrackLineNumber);
            end

            obj =                   obj.removeInvalidTrackLines;

            rowsOfMissingTrackIDs = ~ismember(allTrackIdsInModel, obj.getIdsFromTrackHandles( obj.ListOfTrackViews));
            missingTrackIds =       allTrackIdsInModel(rowsOfMissingTrackIDs);

            if isempty(missingTrackIds)
            else
                MyAxes = obj.MovieView.getAxes;
                CellWithNewLineHandles =    (arrayfun(@(x) line(MyAxes), 1:length(missingTrackIds), 'UniformOutput', false))';
                CellWithNewLineHandles =    cellfun(@(x,y) setTagOfTrackLines(x,y), CellWithNewLineHandles, num2cell(missingTrackIds), 'UniformOutput', false);
                obj.ListOfTrackViews =      [obj.ListOfTrackViews; CellWithNewLineHandles];   
            end


        end

        function obj =              removeInvalidTrackLines(obj)
          InvalidRows = cellfun(@(x) ~isvalid(x), obj.ListOfTrackViews);
          obj.ListOfTrackViews(InvalidRows, :) = [];
        end

        function obj =              deleteNonMatchingTrackLineViews(obj, TrackNumbers)
            if isempty(TrackNumbers)
                obj =           obj.deleteAllTrackLineViews;
            else                    
                rowsThatMustBeDeleted =       ~ismember(obj.getTrackIdsOfTrackHandles, TrackNumbers);
                cellfun(@(x) delete(x), obj.ListOfTrackViews(rowsThatMustBeDeleted))
                obj.ListOfTrackViews(rowsThatMustBeDeleted,:) = [];
            end

        end

      

        function ListWithTrackIDsThatHaveAHandle =     getTrackIdsOfTrackHandles(obj)
            ListWithTrackIDsThatHaveAHandle =           cellfun(@(x) str2double(x.Tag), obj.ListOfTrackViews); 
        end

        function ListWithTrackIDsThatAlreadyHaveAHandle   =        getIdsFromTrackHandles(~, ListWithWithCurrentTrackHandles)
            ListWithTrackIDsThatAlreadyHaveAHandle =               cellfun(@(x) str2double(x.Tag), ListWithWithCurrentTrackHandles);
        end
    
        function obj =      deleteAllTrackLineViews(obj)
            arrayfun(@(x) delete(x),   obj.getAllTrackHandles);
            obj.ListOfTrackViews =  cell(0,1);

        end
          
     end

    methods (Access = private) % movie view
        
        function obj = setMovieViewWithLoadedMovie(obj, Value)
            
                obj =     obj.setCentroidVisibility(Value.getCentroidVisibility);
                obj =     obj.setTrackingViewsWith(Value);

                obj =     obj.setEditingTypeDependentPropertiesWith(Value);
                obj =     obj.setAnnotationWith(Value);
                obj =     obj.setSelectedCentroidsWith(Value);
                obj =     obj.setActiveCentroidWith(Value);
                obj =     obj.updateManualDriftIndicatorsWith(Value);
                obj =     obj.enableAllViews;
                obj =     obj.updateDriftWith(Value);  
                obj =     obj.setTrackVisibility(Value.getTrackVisibility);
             %   obj =     obj.setTrackLineViewsWith(Value); 
  
        end
        
         function obj = setAnnotationWith(obj, Value)
              Type = class(Value);
                switch Type
                   case 'PMMovieTracking'
                        obj.MovieView =                         obj.MovieView.setAnnotationWith(Value);
                        obj.Annotation.ShowScaleBar.Value =     Value.getScaleBarVisibility;
                        obj =                                   obj.setScaleBarVisibility(Value.getScaleBarVisibility);
                        
                   otherwise
                       error('Type not supported.')
                end
            
        end
        
      
   
        
    end
    
    methods (Access = private)
        
        function obj = CreateNavigationViews(obj, ProjectViews)
            
           
            %% set positions
            
            TopRowInside =                                                          ProjectViews.getStartRowNavigation;
            
            ColumnShiftInside =                                                     ProjectViews.getColumnShift;
            ViewHeightInside =                                                      ProjectViews.getViewHeight;
            WidthOfFirstColumnInside =                                              ProjectViews.getWidthOfFirstColumn;
            WidthOfSecondColumnInside =                                             ProjectViews.getWidthOfSecondColumn;
               
            RowShiftInside =                                                        ProjectViews.getRowShift;
            LeftColumnStart =                                                       0.8;
           

            TitleRow =                                                              TopRowInside-0.11;
            
            HeightOfEditSelection =                                                 0.1;
            
            
            PositionRow1 =                                                          TitleRow-RowShiftInside;
            PositionRow2 =                                                          PositionRow1-RowShiftInside;
            PositionRow3 =                                                          PositionRow2-RowShiftInside;
            PositionRow4 =                                                          PositionRow3-RowShiftInside;
           
            PositionRow5 =                                                          PositionRow4-RowShiftInside;
            PositionRow6 =                                                          PositionRow5-RowShiftInside;

            FirstColumn =                                                           LeftColumnStart;
            SecondColumn =                                                          LeftColumnStart + ColumnShiftInside;

            

            %% list of options:
            EditingOptions=                                                         uicontrol;
            EditingOptions.Tag=                                                     'SelectDisplayOfImageAnalysis';
            EditingOptions.Style=                                                   'Listbox';
            EditingOptions.String=                                                  { 'Viewing only',  'Edit manual drift correction', 'Edit tracks'};
            EditingOptions.Units=                                                   'normalized';
            EditingOptions.Position=                                                [FirstColumn TitleRow (ColumnShiftInside + WidthOfSecondColumnInside) HeightOfEditSelection];


            CurrentTimePointTitle=                                                  uicontrol;
            CurrentTimePointTitle.Style=                                            'Text';
            CurrentTimePointTitle.FontWeight=                                       'normal';
            CurrentTimePointTitle.HorizontalAlignment=                              'left';
            CurrentTimePointTitle.Tag=                                              'CurrentTimePointText';
            CurrentTimePointTitle.String=                                           'Frame#:';
            CurrentTimePointTitle.Units=                                            'normalized';
            CurrentTimePointTitle.Position=                                         [ FirstColumn PositionRow1 WidthOfFirstColumnInside ViewHeightInside];
            
            CurrentTimePoint=                                                       uicontrol;
            CurrentTimePoint.Style=                                                 'PopupMenu';
            CurrentTimePoint.String =                                               'Empty';
            CurrentTimePoint.Tag=                                                   'CurrentTimePoint';
            CurrentTimePoint.Units=                                                 'normalized';
            CurrentTimePoint.Position=                                              [SecondColumn PositionRow1 WidthOfSecondColumnInside ViewHeightInside];

            TimeSlider =                                                            uicontrol;
            TimeSlider.Style =                                                      'slider';
             
            CurrentPlaneTitle=                                                      uicontrol;
            CurrentPlaneTitle.Style=                                                'Text';
            CurrentPlaneTitle.FontWeight=                                           'normal';
            CurrentPlaneTitle.HorizontalAlignment=                                  'left';
            CurrentPlaneTitle.Tag=                                                  'CurrentPlaneText';
            CurrentPlaneTitle.String=                                               'TopPlane#:';
            CurrentPlaneTitle.Units=                                                'normalized';
            CurrentPlaneTitle.Position=                                             [FirstColumn PositionRow2 WidthOfFirstColumnInside ViewHeightInside];

            CurrentPlane=                                                           uicontrol;
            CurrentPlane.Style=                                                     'PopupMenu';
                 CurrentPlane.String =                                               'Empty';
            CurrentPlane.Tag=                                                       'CurrentPlane';
            CurrentPlane.Units=                                                     'normalized';
            CurrentPlane.Position=                                                  [SecondColumn PositionRow2 WidthOfSecondColumnInside ViewHeightInside];

            ShowMaxVolumeHandle=                                                    uicontrol;
            ShowMaxVolumeHandle.Style=                                              'CheckBox';
            ShowMaxVolumeHandle.Tag=                                                'ShowMaxVolume';
            ShowMaxVolumeHandle.String=                                             'Maximum projection';
            ShowMaxVolumeHandle.Units=                                              'normalized';
            ShowMaxVolumeHandle.Position=                                           [FirstColumn PositionRow3 WidthOfFirstColumnInside ViewHeightInside];

            CropImageHandle=                                                        uicontrol;
            CropImageHandle.Style=                                                  'CheckBox';
            CropImageHandle.Tag=                                                    'CropImage';
            CropImageHandle.Units=                                                  'normalized';
            CropImageHandle.Position=                                               [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            CropImageHandle.String=                                                 'Crop image';
            
            ApplyDriftCorrectionHandle=                                             uicontrol;
            ApplyDriftCorrectionHandle.Style=                                       'CheckBox';
            ApplyDriftCorrectionHandle.Tag=                                         'DriftCorrectionHandle';
            ApplyDriftCorrectionHandle.Units=                                       'normalized';
            ApplyDriftCorrectionHandle.Position=                                    [FirstColumn PositionRow4 WidthOfFirstColumnInside ViewHeightInside];
            ApplyDriftCorrectionHandle.String=                                      'Apply drift';
            
            %% change settings of handles that are dependent on loaded movie;
            obj.Navigation.TimeSlider=                                              TimeSlider;
            obj.Navigation.EditingOptions=                                          EditingOptions;
            obj.Navigation.CurrentTimePointTitle=                                   CurrentTimePointTitle;
            obj.Navigation.CurrentTimePoint=                                        CurrentTimePoint;
            obj.Navigation.CurrentPlaneTitle=                                       CurrentPlaneTitle;
            obj.Navigation.CurrentPlane=                                            CurrentPlane;
            obj.Navigation.ShowMaxVolume=                                           ShowMaxVolumeHandle;
            obj.Navigation.CropImageHandle=                                         CropImageHandle;
            obj.Navigation.ApplyDriftCorrection=                                    ApplyDriftCorrectionHandle;
        


        end
        
        function obj = CreateChannelViews(obj, ProjectViews)
            
            
            TopRow =                                                    ProjectViews.getStartRowChannels;
            
            LeftColumnInside =                                          ProjectViews.getLeftColumn;
            ColumnShiftInside =                                         ProjectViews.getColumnShift;
            ViewHeightInside =                                          ProjectViews.getViewHeight;
            
            WidthOfFirstColumnInside =                                  ProjectViews.getWidthOfFirstColumn;
            WidthOfSecondColumnInside =                                 ProjectViews.getWidthOfSecondColumn;
            
            RowShiftInside =                                            ProjectViews.getRowShift;
           
            PositionRow0 =                                              TopRow-RowShiftInside*1;
            PositionRow1 =                                              TopRow-RowShiftInside*2;
            PositionRow2 =                                              TopRow-RowShiftInside*3;
            PositionRow3 =                                              TopRow-RowShiftInside*4;
            PositionRow4 =                                              TopRow-RowShiftInside*5;
            PositionRow5 =                                              TopRow-RowShiftInside*6;
            PositionRow6 =                                              TopRow-RowShiftInside*7;
            PositionRow7 =                                              TopRow-RowShiftInside*8;


            FirstColumn =                                               LeftColumnInside ;
            SecondColumn =                                              LeftColumnInside + ColumnShiftInside;

            SelectedChannelHandleTitle=                               uicontrol('Style', 'Text');
            SelectedChannelHandleTitle.Tag=                           'UseForDriftCorrectionComment';
            SelectedChannelHandleTitle.Units=                    'Normalized';
            SelectedChannelHandleTitle.Position=                 [FirstColumn PositionRow0 WidthOfFirstColumnInside ViewHeightInside];
            SelectedChannelHandleTitle.String=                   'Selected channel:';
            SelectedChannelHandleTitle.HorizontalAlignment=                     'left';
            
           

            SelectedChannelHandle=                      uicontrol;
            SelectedChannelHandle.Style=                'PopupMenu';
            SelectedChannelHandle.String =              'Empty';
            SelectedChannelHandle.Tag=                  'SelectedChannel';
            SelectedChannelHandle.Units=                'normalized';
            SelectedChannelHandle.Position=             [SecondColumn PositionRow0 WidthOfSecondColumnInside ViewHeightInside];

  

            SelectedChannelHandle.BackgroundColor =                     'k';

            %% fill content
            MinimumIntensityTitle=                                            uicontrol('Style', 'Text');
            MinimumIntensityTitle.Tag=                                   'TextMinimum';
            MinimumIntensityTitle.Units=                                              'Normalized';
            MinimumIntensityTitle.Position=                                           [FirstColumn PositionRow1 WidthOfFirstColumnInside ViewHeightInside];
            MinimumIntensityTitle.String=                                             'Intensity (min):';
            MinimumIntensityTitle.HorizontalAlignment=                                'left';

            MinimumIntensity=                                               uicontrol('Style', 'Edit');
            MinimumIntensity.Tag=                                           'MinimumIntensity';
            MinimumIntensity.Units=                                         'Normalized';
            MinimumIntensity.Position=                                      [SecondColumn PositionRow1 WidthOfSecondColumnInside ViewHeightInside];

            MaximumIntensityTitle=                                            uicontrol('Style', 'Text');
            MaximumIntensityTitle.Tag=                                   'TextMaximum';
            MaximumIntensityTitle.Units=                                              'Normalized';
            MaximumIntensityTitle.Position=                                           [FirstColumn PositionRow2 WidthOfFirstColumnInside ViewHeightInside];
            MaximumIntensityTitle.String=                                             'Intensity (max):';
            MaximumIntensityTitle.HorizontalAlignment=          'left';

            MaximumIntensity=                                       uicontrol('Style', 'Edit');
            MaximumIntensity.Tag=                                   'MaximumIntensity';
            MaximumIntensity.Units=                                         'Normalized';
            MaximumIntensity.Position=                                      [SecondColumn PositionRow2 WidthOfSecondColumnInside ViewHeightInside];
            
           
            
            ColorTitle=                                              uicontrol('Style', 'Text');
            ColorTitle.Tag=                                          'TextColor';
            ColorTitle.Units=                                        'Normalized';
            ColorTitle.Position=                                     [FirstColumn PositionRow3 WidthOfFirstColumnInside ViewHeightInside];
            ColorTitle.String=                                       {'Channel color:'};
            ColorTitle.HorizontalAlignment=                          'left';
            
                
            Color=                                                  uicontrol('Style', 'Popup');
            Color.Tag=                                              'Color';
            Color.Units=                                            'Normalized';
            Color.Position=                                         [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            Color.String=                                           {'Black','Red', 'Green', 'Blue', 'Yellow', 'Magenta', 'Cyan', 'White'};
           
          
            CommentTitle=                                            uicontrol('Style', 'Text');
            CommentTitle.Tag=                                            'TextComment';
            CommentTitle.Units=                                      'Normalized';
            CommentTitle.Position=                                   [FirstColumn PositionRow4 WidthOfFirstColumnInside ViewHeightInside];
            CommentTitle.String=                                     'Comment:';
            CommentTitle.HorizontalAlignment=                        'left';

            Comment=                                                uicontrol('Style', 'Edit');
            Comment.Tag=                                            'Comment';
            Comment.Units=                                          'Normalized';
            Comment.Position=                                       [SecondColumn PositionRow4 WidthOfSecondColumnInside ViewHeightInside];

           
            OnOffTitle=                                              uicontrol('Style', 'Text');
            OnOffTitle.Tag=                                        'OnOffComment';
            OnOffTitle.Units=                                     'Normalized';
            OnOffTitle.Position=                                  [FirstColumn PositionRow5 WidthOfFirstColumnInside ViewHeightInside];
            OnOffTitle.String=                                    'Channel on/off:';
            OnOffTitle.HorizontalAlignment=                       'left';


            OnOff=                                                  uicontrol('Style', 'CheckBox');
            OnOff.Tag=                                             'OnOff';
            OnOff.Units=                                            'Normalized';
            OnOff.Position=                                         [SecondColumn PositionRow5 WidthOfSecondColumnInside ViewHeightInside];
            
            
            ChannelReconstructionTitle=                                              uicontrol('Style', 'Text');
            ChannelReconstructionTitle.Tag=                                        'ChannelReconstructionTitle';
            ChannelReconstructionTitle.Units=                                     'Normalized';
            ChannelReconstructionTitle.Position=                                  [FirstColumn PositionRow6 WidthOfFirstColumnInside ViewHeightInside];
            ChannelReconstructionTitle.String=                                    'Image reconstruction type:';
            ChannelReconstructionTitle.HorizontalAlignment=                       'left';


            
              ChannelReconstructionHandle=                                                  uicontrol('Style', 'Popup');
            ChannelReconstructionHandle.Tag=                                              'ChannelReconstruction';
            ChannelReconstructionHandle.Units=                                            'Normalized';
            ChannelReconstructionHandle.Position=                                         [SecondColumn PositionRow6 WidthOfSecondColumnInside ViewHeightInside];
            ChannelReconstructionHandle.String=                                           obj.ChannelFilterTypes;
           
            

            obj.Channels.MinimumIntensityTitle =                    MinimumIntensityTitle;
            obj.Channels.MinimumIntensity =                         MinimumIntensity;
            
            obj.Channels.MaximumIntensityTitle =                    MaximumIntensityTitle;
            obj.Channels.MaximumIntensity =                         MaximumIntensity;
            
            obj.Channels.ColorTitle =                               ColorTitle;
            obj.Channels.Color =                                    Color;
            
            obj.Channels.CommentTitle =                             CommentTitle;
            obj.Channels.Comment =                                  Comment;
            
            obj.Channels.OnOffTitle =                               OnOffTitle;
            obj.Channels.OnOff =                                    OnOff;
            
            obj.Channels.SelectedChannelTitle =                     SelectedChannelHandleTitle;
            obj.Channels.SelectedChannel =                          SelectedChannelHandle;
            
            obj.Channels.ChannelReconstruction =                          ChannelReconstructionHandle;
     
            
           
            
        end
      
        function obj = createMovieView(obj,Input)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
           
            obj.MovieView = PMMovieView(Input);
            
              
                    
            
        end
          
        function obj = CreateAnnotationViews(obj, ProjectViews)
            
              MainWindowNavigationHandle = ProjectViews.getFigure;
             figure(MainWindowNavigationHandle)
   
            %% set positions
            ColumnShiftInside =                                             ProjectViews.getColumnShift;
            ViewHeightInside =                                              ProjectViews.getViewHeight;
            WidthOfFirstColumnInside  =                                     ProjectViews.getWidthOfFirstColumn;
            WidthOfSecondColumnInside  =                                    ProjectViews.getWidthOfSecondColumn;
            
            TopRow =                                                        ProjectViews.getStartRowAnnotation;
            RowShiftInside =                                                      ProjectViews.getRowShift;
            LeftColumnInside =                                                    ProjectViews.getLeftColumn;
            
            
            TitleRow =                                                  TopRow-RowShiftInside;
            PositionRow1 =                                              TopRow-RowShiftInside*2;
            PositionRow2 =                                              TopRow-RowShiftInside*3;
            PositionRow3 =                                              TopRow-RowShiftInside*4;
            PositionRow4 =                                              TopRow-RowShiftInside*5;
            PositionRow5 =                                              TopRow-RowShiftInside*6;
            PositionRow6 =                                              TopRow-RowShiftInside*7;

            
           

            FirstColumn =                                               LeftColumnInside;
            SecondColumn =                                              LeftColumnInside+ColumnShiftInside;
            ThirdColumn =                                               LeftColumnInside+2*ColumnShiftInside;

            %% get handles with graphics object
            ShowScaleBarHandle= uicontrol;
            ShowScaleBarHandle.Tag=                                    'ShowScaleBar';
            ShowScaleBarHandle.Style=                                       'CheckBox';
            ShowScaleBarHandle.Units=                                       'normalized';
            ShowScaleBarHandle.Position=                                    [FirstColumn PositionRow3 WidthOfFirstColumnInside ViewHeightInside];
            ShowScaleBarHandle.String=                                      { 'Scale bar'};


            SizeOfScaleBarHandle= uicontrol;
            SizeOfScaleBarHandle.Tag=                                  'SizeOfScaleBar';
            SizeOfScaleBarHandle.Style=                                     'PopupMenu';
             SizeOfScaleBarHandle.String=                                     'Empty';
            SizeOfScaleBarHandle.Units=                                     'normalized';
            SizeOfScaleBarHandle.Position=                                  [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            SizeOfScaleBarHandle.String=                                    [1:50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000];
            SizeOfScaleBarHandle.Value=                                     50;

            obj.Annotation.ShowScaleBar=                                ShowScaleBarHandle;
            obj.Annotation.SizeOfScaleBar=                              SizeOfScaleBarHandle;
   
        end
        
    end
    
end

