classdef PMMovieControllerView
    %PMMOVIECONTROLLERVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties




    end
    
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
    
    methods % track lines
        
        
        function obj = setTrackLineViewsWith(obj, MovieTracking)
            tic
            obj =             obj.addMissingTrackLineViews(MovieTracking.getAllTrackIDs);
            
            if obj.ShowLog
                fprintf('addMissingTrackLineViews: %6.2f seconds.\n', toc)
            end
            tic
            obj =             obj.deleteNonMatchingTrackLineViews(MovieTracking.getAllTrackIDs);
            
             if obj.ShowLog
                fprintf('deleteNonMatchingTrackLineViews: %6.2f seconds.\n', toc)
             end
            tic
            obj =             obj.updateTrackLinesWithIDAndSize(MovieTracking, MovieTracking.getIdOfActiveTrack, 3);
            
             if obj.ShowLog
                fprintf('updateTrackLinesWithIDAndSize: %6.2f seconds.\n', toc)
             end
            tic
            
            obj =             obj.updateTrackLinesWithIDAndSize(MovieTracking, MovieTracking.getIdsOfRestingTracks, 0.5);
            
             if obj.ShowLog
                fprintf('updateTrackLinesWithIDAndSize: %6.2f seconds.\n', toc)
             end
            tic
            obj =             obj.updateTrackLinesWithIDAndSize(MovieTracking, MovieTracking.getSelectedTrackIDs, 1);
            
             if obj.ShowLog
                fprintf('updateTrackLinesWithIDAndSize: %6.2f seconds.\n', toc)
             end
        end

        function obj = updateTrackLinesWithIDAndSize(obj, MovieTracking, TrackIDs, Size)
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

        function obj = setTrackLines(obj, TrackHandles, Coordinates, Width)
            %CoordinatesSelected =               arrayfun(@(x) obj.getCoordinatesForTrack(x), obj.Views.getIdsFromTrackHandles(TrackHandles), 'UniformOutput', false);
            if ~isempty(TrackHandles)
                cellfun(@(x) obj.setLineWidthTo(x, Width), TrackHandles)
                cellfun(@(handles, coordinates) obj.updateTrackLineCoordinatesForHandle(handles, coordinates), TrackHandles, Coordinates);
            end
        end
        
        function  setLineWidthTo(~, Handle, Width)
            Handle.LineWidth =          Width; 
        end

        function                                    updateTrackLineCoordinatesForHandle(~, HandleForCurrentTrack, Coordinates)
            if isempty(Coordinates)
                Coordinates = [0, 0, 0];
            end
            
            HandleForCurrentTrack.XData=            Coordinates(:, 1);    
            HandleForCurrentTrack.YData=            Coordinates(:, 2);  
            HandleForCurrentTrack.ZData=            Coordinates(:, 3);  
            HandleForCurrentTrack.Color=            'w';  
        end

         
        %% updateTrackVisibilityWith
        function obj = updateTrackVisibilityWith(obj, MovieTracking)

            function track = changeTrackVisibility(track, state)
                track.Visible = state;
            end
            obj.TrackingViews.ShowTracks.Value =        MovieTracking.getTrackVisibility;
            cellfun(@(x) changeTrackVisibility(x, MovieTracking.getTrackVisibility), obj.ListOfTrackViews);

        end
        

        function [obj] =        addMissingTrackLineViews(obj, allTrackIdsInModel)

            function TrackLine = setTagOfTrackLines(TrackLine, TrackLineNumber)
                TrackLine.Tag = num2str(TrackLineNumber);
            end

            obj =                   obj.removeInvalidTrackLines;

            rowsOfMissingTrackIDs = ~ismember(allTrackIdsInModel, obj.getIdsFromTrackHandles( obj.ListOfTrackViews));
            missingTrackIds =       allTrackIdsInModel(rowsOfMissingTrackIDs);

            if isempty(missingTrackIds)
            else
                CellWithNewLineHandles =    (arrayfun(@(x) line(obj.MovieView.getAxes), 1:length(missingTrackIds), 'UniformOutput', false))';
                CellWithNewLineHandles =    cellfun(@(x,y) setTagOfTrackLines(x,y), CellWithNewLineHandles, num2cell(missingTrackIds), 'UniformOutput', false);
                obj.ListOfTrackViews =      [obj.ListOfTrackViews; CellWithNewLineHandles];   
            end


        end

        function obj = removeInvalidTrackLines(obj)
          InvalidRows = cellfun(@(x) ~isvalid(x), obj.ListOfTrackViews);
          obj.ListOfTrackViews(InvalidRows, :) = [];
        end


        function [obj] =       deleteNonMatchingTrackLineViews(obj, TrackNumbers)
            if isempty(TrackNumbers)
                obj =           obj.deleteAllTrackLineViews;
            else                    
                rowsThatMustBeDeleted =       ~ismember(obj.getTrackIdsOfTrackHandles, TrackNumbers);
                cellfun(@(x) delete(x), obj.ListOfTrackViews(rowsThatMustBeDeleted))
                obj.ListOfTrackViews(rowsThatMustBeDeleted,:) = [];
            end

        end


        function TrackHandles =          getHandlesForTrackIDs(obj, TrackID)
        if isempty(TrackID)
            TrackHandles = cell(0,1);
        else
            TrackHandles =      obj.ListOfTrackViews(ismember(obj.getTrackIdsOfTrackHandles,  TrackID), :);
        end    
        end

        function ListWithTrackIDsThatHaveAHandle =     getTrackIdsOfTrackHandles(obj)
         ListWithTrackIDsThatHaveAHandle =           cellfun(@(x) str2double(x.Tag), obj.ListOfTrackViews); 
        end

        function ListWithTrackIDsThatAlreadyHaveAHandle   =        getIdsFromTrackHandles(~, ListWithWithCurrentTrackHandles)
          ListWithTrackIDsThatAlreadyHaveAHandle =               cellfun(@(x) str2double(x.Tag), ListWithWithCurrentTrackHandles);
        end

       





        function [obj] =                            deleteAllTrackLineViews(obj)

            fprintf('PMMovieController:@deleteAllTrackLineViews: find all currently existing track lines and deleted them.\n')
            AllLines =           findobj(obj.MovieView.getAxes, 'Type', 'Line');
            TrackLineRows  =     arrayfun(@(x) ~isnan(str2double(x.Tag)), AllLines);
            TrackLines=          AllLines(TrackLineRows,:);
            if ~isempty(TrackLines)
                arrayfun(@(x) delete(x),  TrackLines);
            end
            obj.ListOfTrackViews =  cell(0,1);

        end

        
        
        
    end
    
    methods % initialization
        
        function obj = PMMovieControllerView(varargin)
            %PMMOVIECONTROLLERVIEW Construct an instance of this class
            %   Creation of views that support navigating through the loaded image-sequences;
     
            NumberOfArguments = length(varargin);
            switch NumberOfArguments

                case 1
                    switch class(varargin{1})
                        case 'matlab.graphics.axis.Axes'
                              obj.Figure =    varargin{1}.Parent;  
                              obj =           obj.createMovieView(varargin{1});
                            
                        case 'PMImagingProjectViewer'
                            obj =       obj.CreateNavigationViews(varargin{1});
                            obj =       obj.CreateChannelViews(varargin{1});
                            obj =       obj.CreateAnnotationViews(varargin{1});
                            obj =       obj.createMovieView(varargin{1});
                            
                        otherwise
                            error('Input not supported.')
                        
                    end
                        
                otherwise
                    error('Wrong input.')
                
            end

        end
        
        function obj = set.MovieView(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMMovieView'), 'Wrong input.')
            obj.MovieView = Value;
        end
        
    end
    
    methods % set movie-view
        
        function obj = updateMovieViewWith(obj, varargin)

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    assert(isa(varargin{1}, 'PMMovieTracking'))
                    
                    obj =     obj.setEditingTypeDependentPropertiesWith(varargin{1});
                    obj =     obj.setAnnotationWith(varargin{1});
                    obj =     obj.setSelectedCentroidsWith(varargin{1});
                    obj =     obj.setActiveCentroidWith(varargin{1});
                    obj =     obj.updateManualDriftIndicatorsWith(varargin{1});
                    obj =     obj.enableAllViews;
                    obj =     obj.updateDriftWith(varargin{1});  
                    
                case 2
                    
                    MyMovieTracking=varargin{1};
                    MyImage = varargin{2};
                    
                    assert(isa(MyMovieTracking, 'PMMovieTracking'))
                    assert(isnumeric(MyImage), 'Wrong input.')
                    
                    
                    obj =     obj.setEditingTypeDependentPropertiesWith(MyMovieTracking); 
                    obj =     obj.setAnnotationWith(MyMovieTracking);
                    obj =     obj.setSelectedCentroidsWith(MyMovieTracking);
                    obj =     obj.setActiveCentroidWith(MyMovieTracking);
                    obj =     obj.updateManualDriftIndicatorsWith(MyMovieTracking);
                    obj =     obj.enableAllViews;
                    obj =     obj.updateDriftWith(MyMovieTracking);  
                   
                    obj =     obj.setMovieImagePixels(MyImage);
                    obj =     obj.setDefaults;
                    obj =     obj.addEdgeDetectionToMovieMovie(MyMovieTracking);
                    
                otherwise
                    error('Wrong input.')
                 
            end

        end
       
        function obj = shiftAxes(obj, xShift, yShift)
            NewXCenter =    obj.getMovieAxes.XLim - xShift;
            NewYCenter =    obj.getMovieAxes.YLim - yShift;
            obj =     obj.setMovieAxesLimits(NewXCenter, NewYCenter);
        end
        
    end
    
    methods (Access = private) % movie view
         function obj = setAnnotationWith(obj, Value)
              Type = class(Value);
                switch Type
                   case 'PMMovieTracking'
                       
                        obj.MovieView =            obj.MovieView.setAnnotationWith(Value);
                        obj.Annotation.ShowScaleBar.Value =           Value.getScaleBarVisibility;
                        obj =               obj.setScaleBarVisibility(Value.getScaleBarVisibility);
                   otherwise
                       error('Type not supported.')
                end
            
        end
        
        function obj = setScaleBarVisibility(obj, ScaleBarVisible)
           obj.MovieView = obj.MovieView.setScaleBarVisibility(ScaleBarVisible);
        end
        
   
        
    end
    
    methods % setters cropping and axes
        
        function obj = setRectangleWith(obj, Value)
            
            Type = class(Value);
            
            switch Type
                
               case 'PMMovieTracking'

                    obj.getRectangle.Visible =   'on';
                    obj.getRectangle.YData=      Value.getYPointsForCroppingRectangleView;
                    obj.getRectangle.XData=      Value.getXPointsForCroppingRectangleView;
                    obj.getRectangle.Color =     'w';

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
               obj.MovieView=    obj.MovieView.setAxesWidth(Width);
        end
          
    end
    
    methods % setters navigation controls
        
        
        function obj = setNavigationWith(obj, Value)
            Type = class(Value);
            switch Type
               case 'PMMovieTracking'
                    obj = obj.setNavigationWithMovieTracking(Value);        
               otherwise
                   error('Type not supported.')
            end
        end

        function obj = setNavigationWithMovieTracking(obj, MovieTracking)

            assert(~isempty(obj.getNavigation), 'Could not update Navigation panels because they do not exist.')

            [~, ~, planes ] =                                       MovieTracking.getImageDimensionsWithAppliedDriftCorrection;
            obj.Navigation.CurrentPlane.String =              1:planes;


            obj.Navigation.CurrentPlane.Value =           MovieTracking.getActivePlanes;
            obj.Navigation.CurrentTimePoint.Value =       MovieTracking.getActiveFrames;  
            obj.Navigation.ShowMaxVolume.Value =          MovieTracking.getCollapseAllPlanes ;
            obj.Navigation.ApplyDriftCorrection.Value =   MovieTracking.getDriftCorrectionStatus;
            obj.Navigation.CropImageHandle.Value =        MovieTracking.getCroppingOn;


            if obj.Navigation.CurrentPlane.Value < 1 || obj.Navigation.CurrentPlane.Value > length(obj.Navigation.CurrentPlane.String)
            obj.Navigation.CurrentPlane.Value = 1;

            end

            obj =   obj.setMaxTime(MovieTracking.getMaxFrame);

        end

        function obj = setMaxTime(obj, Value)
            obj.Navigation.CurrentTimePoint.String =          1 : Value; 
            if obj.Navigation.CurrentTimePoint.Value<1 || obj.Navigation.CurrentTimePoint.Value>length(obj.Navigation.CurrentTimePoint.String)
            obj.Navigation.CurrentTimePoint.Value = 1;
            end


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

        end
        
        
        
    end
    
    
    methods % setters
        
        function obj = setTrackingViewsWith(obj, Value)

            Type = class(Value);
            switch Type
               case 'PMMovieTracking'
                    obj.TrackingViews.ShowMaximumProjection.Value =    Value.getCollapseAllTracking;
                     obj.TrackingViews.ActiveTrack.Value =                                Value.getActiveTrackIsHighlighted;
                    obj.TrackingViews.ActiveTrack.String =        num2str(Value.getIdOfActiveTrack);
                    obj.TrackingViews.ShowMasks.Value =                 Value.getMaskVisibility;
                    obj.TrackingViews.ShowCentroids.Value =        Value.getCentroidVisibility;
                otherwise
                    error('Input not supported.')

            end
            
            if isnan(Value.getIdOfActiveTrack)
                obj =     obj.setVisibilityOfActiveTrack(false);

            else
                obj =     obj.setVisibilityOfActiveTrack(Value.getActiveTrackIsHighlighted);

            end


        end
        
        function obj = setControlElements(obj, Value)
            Type = class(Value);
            switch Type
               case 'PMMovieTracking'

                    obj =   obj.setNavigationWith(Value);
                    obj =   obj.setChannelsWith(Value);


               otherwise
                   error('Type not supported.')


            end



        end


        function obj = setChannelsWith(obj, MovieTracking)



        if isempty(obj.Channels) || isempty(MovieTracking.Channels)
        else

          obj.Channels.SelectedChannel.String =            1 : MovieTracking.getMaxChannel;
        if obj.Channels.SelectedChannel.Value<1 || obj.Channels.SelectedChannel.Value>length(obj.Channels.SelectedChannel.String)
            obj.Channels.SelectedChannel.Value = 1;
        end


        obj.Channels.SelectedChannel.String =                 1 : MovieTracking.getMaxChannel;
        obj.Channels.SelectedChannel.Value =                  MovieTracking.getIndexOfActiveChannel;
        obj.Channels.MinimumIntensity.String =                MovieTracking.getIntensityLowOfActiveChannel;
        obj.Channels.MaximumIntensity.String =                MovieTracking.getIntensityHighOfActiveChannel;
        obj.Channels.Color.Value =                            find(strcmp(MovieTracking.getColorStringOfActiveChannel, obj.Channels.Color.String));
        obj.Channels.Comment.String =                         MovieTracking.getCommentOfActiveChannel;
        obj.Channels.OnOff.Value =                            MovieTracking.getVisibleOfActiveChannel;
        obj.Channels.ChannelReconstruction.Value =         obj.getActiveChannelReconstructionIndexFromMovieTracking(MovieTracking);

        end


        end

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
                    obj.Navigation.EditingOptions.Value =          index;
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
                    
                    MyFrames =          Value.getActiveFrames;
                    PlanesThatArveVisibleForSegmentation = Value.getTargetMoviePlanesForSegmentationVisualization;
                    MyDriftCorrection = Value.getDriftCorrection;
                    
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
        function obj = setActiveCentroidWith(obj, Value)
            Type = class(Value);
            switch Type
                case 'PMMovieTracking'
                    Coordinates =  Value.getTracking.getActiveCentroidAtFramePlaneDrift(Value.getActiveFrames, Value.getTargetMoviePlanesForSegmentationVisualization, Value.getDriftCorrection);
                   if isempty(Coordinates)
                       obj =               obj.setCoordinatesOfActiveTrack(zeros(0,1), zeros(0,1));
                   else
                       
                    obj =               obj.setCoordinatesOfActiveTrack(Coordinates(:, 1), Coordinates(:, 2));
                   end
                otherwise
                    error('Wrong input.')
                    
            end

        end
        
        
        function obj = setCoordinatesOfActiveTrack(obj, XCoordinates, YCoordinates)
            
            obj.MovieView = obj.MovieView.setActiveCentroidCoordinates(XCoordinates, YCoordinates);
            
           
        end
        
        
          %% updateManualDriftIndicatorsWith
         function obj = updateManualDriftIndicatorsWith(obj, Value)
             
             
             obj.MovieView = obj.MovieView.setManualDriftCorrectionCoordinatesWith(Value);
             
             
            
            
         end
    

         %% updateDriftWith:
         function obj = updateDriftWith(obj, Value)
             
             obj.MovieView = obj.MovieView.updateDriftWith(Value);
             
            
        end
        
      
           
        %% setMovieImagePixels:
        function obj = setMovieImagePixels(obj,Image)
            
            obj.MovieView =     obj.MovieView.setImageContent(Image);
            
       
        end
        
         %% addEdgeDetectionToMovieMovie
        function obj = addEdgeDetectionToMovieMovie(obj, Movie)
              if Movie.getActiveTrackIsHighlighted 
                     segmentationOfActiveTrack  =               Movie.getSegmentationOfActiveTrack;
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
        
        
      
        
        
        
          
        
        %% blackOutMovieView
        function obj = blackOutMovieView(obj)

            obj.MovieView = obj.MovieView.inactivate;
            
       


        end

        %% setMaxTime

        

      

        function obj = setScalebarText(obj, Value)
          obj.MovieView.ScalebarText.String = Value;
        end

      
        %% changeAppearance
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

        function obj = disableViews(obj)

             [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                if ~isempty(ListWithAllViews{CurrentIndex,1}.Callback)
                    ListWithAllViews{CurrentIndex,1}.Enable = 'off';
                end

            end

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

        [ListWithAllViews] =               obj.getListWithAllViews;
        NumberOfViews = size(ListWithAllViews,1);
        for CurrentIndex=1:NumberOfViews
            CurrentView =   ListWithAllViews{CurrentIndex,1};
            CurrentView.Enable = 'on';

        end


        end

        %% enableViews
        function obj = enableViews(obj)
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                if ~isempty(CurrentView.Callback)
                    CurrentView.Enable = 'on';
                end

            end

        end
        
         function obj = adjustViews(obj)
            obj.MovieView =     obj.MovieView.adjustViews;
            obj.Navigation.TimeSlider.Units =             'centimeters';
            obj.Navigation.TimeSlider.Position =          [11.5 4 19 1];

        end
     
        
        function obj = setCurrentCharacter(obj, Value)
            
                 obj.Figure.CurrentCharacter =                   Value;
        end
        
           function obj = setTrackingViews(obj, Value)
            obj.TrackingViews = Value;
        end


        %% updateSaveStatusWith
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
        
        function obj = setSegmentLineViews(obj, StopTracks, GoTracks)
           obj.MovieView = obj.MovieView.setSegmentLineViews( StopTracks, GoTracks); 
            
        end
        
         function obj = setShowMaximumProjection(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.Navigation.ShowMaxVolume.Value =   Value;
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
        
        
        %% accessor for tracking views
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
            value  = logical(obj.TrackingViews.ShowTracks.Value);
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
            value  = obj.Annotation.SizeOfScaleBar.Value;
        end
        
        
    end
    
    methods
 

        function activeView = getActiveView(obj)
            if obj.Figure.CurrentObject == obj.getMovieImage
                activeView = 'MovieImage';
            else
                activeView = 'Unknown';
            end
            
        end
        
         function PressedKey = getPressedKey(obj)
              PressedKey=       get(obj.Figure,'CurrentCharacter');
         end
          
        
        function navi = getNavigation(obj)
           navi = obj.Navigation; 
        end
        
        function value = getCropImage(obj)
            value = logical(obj.Navigation.CropImageHandle.Value);
        end
        
        function value = getCurrentPlanes(obj)
            value =      obj.Navigation.CurrentPlane.Value;
        end
        
        function value = getCurrentFrames(obj)
            value =      obj.Navigation.CurrentTimePoint.Value;
        end
        
        function value = getShowMaximumProjection(obj)
            value =      logical(obj.Navigation.ShowMaxVolume.Value);
        end
        
       

        function value = getApplyDriftCorrection(obj)
            value =      logical(obj.Navigation.ApplyDriftCorrection.Value);
        end
        
        function CurrentModifier = getRawModifier(obj)
            CurrentModifier = obj.Figure.CurrentModifier;
            
        end
        
        
        function modifier = getModifier(obj)
            CurrentModifier = obj.Figure.CurrentModifier;
            if ischar(CurrentModifier)
               CurrentModifier = {CurrentModifier}; 
            end
             modifier = PMKeyModifiers(CurrentModifier).getNameOfModifier;
            
        end
        
        function myFigure = getFigure(obj)
            myFigure = obj.Figure;            
        end
        
        function axes = getMovieAxes(obj)
            axes = obj.MovieView.getAxes;
        end
        
         function axes = getMovieImage(obj)
            axes = obj.MovieView.getImage;
         end
        
         function rect = getRectangle(obj)
              rect = obj.MovieView.getRectangle;
         end
       

     
        function Index = getActiveChannelReconstructionIndexFromMovieTracking(obj, MovieTracking)
            Index = find(strcmp(MovieTracking.getReconstructionTypeOfActiveChannel, obj.ChannelFilterTypes_MovieTracking));
            if isempty(Index)
               Index = 1; 
            end
        end
        
        
        
        
        function string = getEditingType(obj)
            input =                        obj.Navigation.EditingOptions.String{obj.Navigation.EditingOptions.Value};
            switch input
                case 'Viewing only' % 'Visualize'
                    string =                                   'No editing';
                case 'Edit manual drift correction'
                    string =                                   'Manual drift correction';
                case 'Edit tracks' %  'Tracking: draw mask'
                    string =                                'Tracking';
            end

        end

  
         
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


            ListWithAllViews =          [NavigationViews; ChannelViews;AnnotationViews];

        end


   

        function Value = getTrackingViews(obj)
            Value = obj.TrackingViews;
        end
        
        
     

    end
    
    methods % callbacks
       
        
        %% set callbacks:
        function obj = setKeyMouseCallbacks(obj, varargin)
                obj.Figure.WindowKeyPressFcn =        varargin{1};
                obj.Figure.WindowButtonDownFcn =      varargin{2};
                obj.Figure.WindowButtonUpFcn =        varargin{3};
                obj.Figure.WindowButtonMotionFcn =    varargin{4};
        end
        
        
        function obj =  setNavigationCallbacks(obj, varargin)
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

        function obj =   setChannelCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 7
                    obj.Channels.SelectedChannel.Callback =         varargin{1};
                    obj.Channels.MinimumIntensity.Callback =        varargin{2};
                    obj.Channels.MaximumIntensity.Callback =        varargin{3};
                    obj.Channels.Color.Callback =                   varargin{4};
                    obj.Channels.Comment.Callback =                 varargin{5};
                    obj.Channels.OnOff.Callback =                  varargin{6};
                    obj.Channels.ChannelReconstruction.Callback =  varargin{7};

                otherwise
                    error('Wrong input.')
            end

        end

        function obj = setAnnotationCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 2
                obj.Annotation.ShowScaleBar.Callback =             varargin{1};
                obj.Annotation.SizeOfScaleBar.Callback =           varargin{2};

                otherwise
                    error('Wrong input.')
            end

            
        end
        
        function obj = setTrackingCallbacks(obj, varargin)
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
    
    methods (Access = private)
        
          function obj = CreateNavigationViews(obj, ProjectViews)
            
           
            %% set positions
            
            TopRowInside =                                                          ProjectViews.StartRowNavigation;
            
            ColumnShiftInside =                                                     ProjectViews.ColumnShift;
            ViewHeightInside =                                                      ProjectViews.ViewHeight;
            WidthOfFirstColumnInside =                                              ProjectViews.WidthOfFirstColumn;
            WidthOfSecondColumnInside =                                             ProjectViews.WidthOfSecondColumn;
               
            RowShiftInside =                                                        ProjectViews.RowShift;
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
            
            
            TopRow =                                                    ProjectViews.StartRowChannels;
            
            LeftColumnInside =                                          ProjectViews.LeftColumn;
            ColumnShiftInside =                                         ProjectViews.ColumnShift;
            ViewHeightInside =                                          ProjectViews.ViewHeight;
            
            WidthOfFirstColumnInside =                                  ProjectViews.WidthOfFirstColumn;
            WidthOfSecondColumnInside =                                 ProjectViews.WidthOfSecondColumn;
            
            RowShiftInside =                                            ProjectViews.RowShift;
           
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
            Color.String=                                           {'Empty','Red', 'Green', 'Blue', 'Yellow', 'Magenta', 'Cyan', 'White'};
           
          
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
            
              MainWindowNavigationHandle = ProjectViews.Figure;
             figure(MainWindowNavigationHandle)
   
            %% set positions
            ColumnShiftInside =                                             ProjectViews.ColumnShift;
            ViewHeightInside =                                              ProjectViews.ViewHeight;
            WidthOfFirstColumnInside  =                                     ProjectViews.WidthOfFirstColumn;
            WidthOfSecondColumnInside  =                                    ProjectViews.WidthOfSecondColumn;
            
            TopRow =                                                        ProjectViews.StartRowAnnotation;
            RowShiftInside =                                                      ProjectViews.RowShift;
            LeftColumnInside =                                                    ProjectViews.LeftColumn;
            
            
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
            SizeOfScaleBarHandle.String=                                    1:100;
            SizeOfScaleBarHandle.Value=                                     50;

            obj.Annotation.ShowScaleBar=                                ShowScaleBarHandle;
            obj.Annotation.SizeOfScaleBar=                              SizeOfScaleBarHandle;
   
        end
        
    end
    
end

