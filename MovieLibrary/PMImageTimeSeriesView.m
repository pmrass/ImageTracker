classdef PMImageTimeSeriesView
    %MULTIPLEFRAMEVIEW data source for creating views of tracked movie-sequences;
    %   functions as an interface between PMMovieLibrary and the final figure;
    % each panel gets its own movie-controller that can retrieve specific data for its data;
    % the movie-controllers can be from the same movie at different timepoints, or can show images from different movies;
    
    properties (Access = private) % numerical settings
        
        StopDistanceLimit =                    15;
        MaxStopDurationForGoSegment =          5;
        MinStopDurationForStopSegment =        20; 
        
    end
    
    properties (Access = private)
        
        MovieLibrary
        ListWithNickNames
        
        MovieControllers =              PMMovieController.empty   
        
        
        NumberOfPanels
        
        FramesForMainTrack
        ListOfFramesForEachSegment % segments of main track
        
        % used to set MovieController
        ShownTrackIDs
        ShownTimeFrames
        
        AppliedCroppingRectangles
        MaximumProjection
        
    end
    
    properties (Access = private) % channel properties
        ShownChannels =             true
        ChannelsLowIntensities
        ChannelsHighIntensities
        ChannelsColors
        VisiblePlanes
        
    end
    
    properties (Access = private) % track annotation views
        CentroidsAreVisible = false
        ActiveTrackIsVisible = false
        SelectedTracksAreVisible = false
        RestingTracksAreVisible = false
        MasksAreVisible = false
        
        
       
        
    end
    
    properties (Access = private) % annotation views
        TimeAnnotationIsVisible = true
        ZAnnotationIsVisible = false
        ScaleBarAnnotationIsVisible = true
        ScaleBarSize = 50
       
    end
    
    methods     % INITIALIZE
        
        function obj = PMImageTimeSeriesView(varargin)
            %PMIMAGETIMESERIESVIEW Construct an instance of this class
            %   takes 3 arguments:
            % 1: number of panels: numeric scalar
            % 2: PMMovieLibrary OR path of used movie-library: character string
            % 3: list with nicknames: character or cell-stirng
            % the specific states that are desired need to be set with setTimeLapse and refreshMovieControllers;
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments

                case 3

                    if isnumeric(varargin{1})
                        obj.NumberOfPanels =        varargin{1};
                        obj.MovieLibrary =          varargin{2};
                        obj.ListWithNickNames =     varargin{3};
                        
                    else
                        obj.MovieLibrary =          varargin{2};
                        obj.ListWithNickNames =     varargin{3};

                    end
                    
                otherwise
                    error('Wrong input.')
                    
            end
            
              obj =          obj.initializeMovieControllersFromFile;

        end
        
        function obj = set.NumberOfPanels(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value), 'Wrong input.')  
           obj.NumberOfPanels = Value; 
        end
        
        function obj = set.ListWithNickNames(obj, Value)
            assert(ischar(Value) || (iscellstr(Value) && isvector(Value)), 'Wrong input');
            obj.ListWithNickNames = Value;
        end
        
        function obj = set.MovieLibrary(obj, Value)
        
            assert(isa(Value, 'PMMovieLibrary') && isscalar(Value), 'Wrong input');
            obj.MovieLibrary = Value;
        end
        
        function obj = set.ShownTrackIDs(obj, Value)
           assert(isnumeric(Value) && isvector(Value), 'Wrong input.')
           if isscalar(Value)
              obj.ShownTrackIDs = repmat(Value,  obj.NumberOfPanels, 1); %#ok<*MCSUP>
           else
               assert(length(Value) == obj.getNumberOfPanels, 'Wrong input.');
                obj.ShownTrackIDs = Value;
           end
           
            
        end
            
    end
    
    methods     % INITIALIZATION of "optional" properties
         
        function obj = set.ShownChannels(obj, Value)

                switch class(Value)
                     case 'char'
                        switch Value
                            case 'Auto'
                                MaximumChannels =         arrayfun(@(x) x.getMaxChannel, obj.getMovieTrackingForEachPanel);
                                obj.ShownChannels =  arrayfun(@(x) true(1, x), MaximumChannels, 'UniformOutput', false);
                            otherwise
                                error('Input not supported.')
                        end
                        
                    case 'logical'
                        assert(isvector(Value) , 'Wrong input.')
                        obj.ShownChannels = repmat({Value}, obj.getNumberOfPanels, 1);
                        
                    case 'cell'
                        assert(isvector(Value) && length(Value) == obj.getNumberOfPanels, 'Wrong input.')
                        obj.ShownChannels = Value;
                        
                    otherwise
                        error('Wrong input.')
                end

         end
            
        function obj = set.ShownTimeFrames(obj, Value)
            
            switch class(Value)
                case 'char'
                    switch Value
                        case 'Auto'
                         obj.ShownTimeFrames = ones(obj.getNumberOfPanels, 1);
                        otherwise
                            error('Input not supported.')
                    end
                    
                case 'double'
                    assert(isvector(Value) , 'Wrong input.')
                    if isscalar(Value)
                        obj.ShownTimeFrames = repmat(Value, obj.getNumberOfPanels, 1);
                    else
                        assert(length(Value) == obj.getNumberOfPanels, 'Wrong input.')
                        obj.ShownTimeFrames = Value(:);
                    end
                    
                otherwise
                    error('Wrong input.')
            end
            
            
        end
        
        function obj = set.VisiblePlanes(obj, Value)
            
            if isempty(Value)
                
                
            else
                  assert(iscell(Value) && isvector(Value), 'Wrong input.')
            assert(length(Value) == obj.getNumberOfPanels, 'Wrong input.')
            
           obj.VisiblePlanes = Value; 
            end
          
        end
        
        function obj = set.ListOfFramesForEachSegment(obj, Value)
            
            switch class(Value)
             
                case 'cell'
                     obj.ListOfFramesForEachSegment = Value;
                     
                case 'char'
                    switch Value
                        case 'Auto' 
                            MaximumFrames = arrayfun(@(x) x.getMaxFrame, obj.getMovieTrackingForEachPanel);
                            obj.ListOfFramesForEachSegment = arrayfun(@(x) 1 : x, MaximumFrames, 'UniformOutput', false);
                        case {'GoTracks'; 'StopTracks'}
                             obj.ListOfFramesForEachSegment =  repmat({Value}, obj.getNumberOfPanels, 1);
                        otherwise
                            error('Input not supported.')
                        
                    end
                       
            end
           
        end
        
        function obj = set.AppliedCroppingRectangles(obj, Value)
            
            switch class(Value)
                
                 case 'char'
                    switch Value
                        case 'Auto'
                             [rows, columns] = arrayfun(@(x) x.getImageDimensions, obj.getMovieTrackingForEachPanel);
                            obj.AppliedCroppingRectangles = arrayfun(@(x, y) [1, 1, x, y], columns, rows, 'UniformOutput', false);
                        otherwise
                            error('Input not supported.')
                    end
                    
                case 'double'
                    assert(isvector(Value) && length(Value) == 4, 'Wrong input.')
                    obj.AppliedCroppingRectangles =    repmat({Value}, obj.getNumberOfPanels, 1);  
                    
                case 'cell'
                    assert(isvector(Value) && length(Value) == obj.getNumberOfPanels, 'Wrong input.')
                    obj.AppliedCroppingRectangles = Value(:);
                    
                otherwise
                    error('Wrong input.')
                    
            end
          
             
            
            
            
        end
        
        function obj = set.MaximumProjection(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.MaximumProjection = Value;
        end
        
    end
    
    methods     % INITIALIZATION TRACK ANNOTATION VIEWS
        
        function obj = set.CentroidsAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CentroidsAreVisible = Value;
        end
        
        function obj = set.ActiveTrackIsVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ActiveTrackIsVisible = Value;
        end
        
        function obj = set.SelectedTracksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.SelectedTracksAreVisible = Value;
        end
        
        function obj = set.RestingTracksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.RestingTracksAreVisible = Value;
        end
        
        function obj = set.MasksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.MasksAreVisible = Value;
        end
        
        
        
        
        
        
        
    end
    
    methods     % INITIALIZATION ANNOTATION
        
        function obj = set.TimeAnnotationIsVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.TimeAnnotationIsVisible = Value;
        end
        
        function obj = set.ZAnnotationIsVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ZAnnotationIsVisible = Value;
        end
        
        function obj = set.ScaleBarAnnotationIsVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ScaleBarAnnotationIsVisible = Value;
        end 
        
        function obj = set.ScaleBarSize(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.ScaleBarSize = Value;
        end
        
        
        
    end
    
    methods     % SUMMARY

        function obj = showSummary(obj)

        fprintf('\n*** This PMImageTimeSeriesView object enables retrieval of track information from a movie library.\n')
        fprintf('It allows retrieval of coordinate of tracks or track-segments, cropping rectangles etc.\n')
        fprintf('This particular object is linked to a MovieLibrary (add summary here when available.)\n')
        fprintf('This image series will allow retrieval of this type information for %i panels.\n', obj.getNumberOfPanels)
        AllNickNames = obj.getNickNameOfEachPanel;
        for index = 1 : obj.getNumberOfPanels

            fprintf('\nPanel "%i" shows track "%i" from movie "%s".\n', index,  obj.ShownTrackIDs(index), AllNickNames{index});
            fprintf('This panel focuses on time-frame: %i (e.g. when extracting image of movie).\n', obj.ShownTimeFrames(index))

             obj =      obj.showSummaryForSegmentForPanelIndex(index);

            fprintf('Channel visibility:')
            arrayfun(@(x) fprintf('%i ', x), obj.ShownChannels{index})

            fprintf('\nCropping rectangle: Left: %i Top: %i Width: %i Height: %i\n', obj.AppliedCroppingRectangles{index}(1), obj.AppliedCroppingRectangles{index}(2), obj.AppliedCroppingRectangles{index}(3), obj.AppliedCroppingRectangles{index}(4));
            fprintf('It has a specific movie-controller linked. Add summary when available.\n')

        end

    end

    end

    methods     % SETTERS:

        function obj = setSpaceAndTimeLimits(obj, Space, TimeMax, TimeMin)
            obj.StopDistanceLimit =                   Space;
            obj.MaxStopDurationForGoSegment =         TimeMax;
            obj.MinStopDurationForStopSegment =       TimeMin;
         end

        function obj = setTrackSegments(obj, Value)
            obj.ListOfFramesForEachSegment = Value;
        end

        function obj = setShownTrackIDs(obj, Value)
           obj.ShownTrackIDs = Value; 
        end

        function obj = setCroppingRectangles(obj, Value)
           obj.AppliedCroppingRectangles = Value; 
        end

        function obj = setChannelVisibility(obj, Value)
           obj.ShownChannels = Value; 
        end
        
    end

    methods     % SETTERS: multiple states/ movie controllers
        
        function obj = setTimeLapse(obj, varargin)
                % SETTIMELAPSE: main function: allows user detailed control over what tracks are shown, cropping, images etc;
                % takes 5 or 6 arguments:
                % 1: ShownChannels: control over what channels are shown:
                %     3 possible inputs: 
                %       a) 'Auto': will turn on all channels
                %       b) numeric vector for each channel in one image, will be applied to all panels;
                %       c) cell array with numeric vectors: specifically set each channel in each panel;
                % 2: ShownTimeFrames: control over what time-frames are shown in each panel;
                 %      a) 'Auto': first frame in each panel
                %       b) scalar: number of frame; will be applied to all panels;
                %       c) nuermic vector: specify frame number for each panel;
                % 3: ShownTrackIDs: control over what track ID is shown in each panel;
                %      scalar or vector: setting all panels the same or specifically;
                % 4: ListOfFramesForEachSegment:
                %       a) 'Auto': highlight entire track
                %       b) 'GoTracks': highlight all go segments:
                %       c) 'StopTracks': highlight all stop seggments:
                %       d) cell array for each panel: numerical vector with number of frames for each panel;
                % 5: AppliedCroppingRectangles:
                %       a) 'Auto':
                %       b) numerical vector of 4: use to set rectangle for all panels ;
                %       c) cell array: for each panel numerical vector of 4;
                % 6: MaximumProjection:
                %     logical scalar: set maximum projection on or off for all panels;
                switch length(varargin)

                    case 5

                        obj.ShownChannels  =                varargin{5}; 
                        obj.ShownTimeFrames =               varargin{1};
                        obj.ShownTrackIDs =                 varargin{2};
                        obj.ListOfFramesForEachSegment =    varargin{3};
                        obj.AppliedCroppingRectangles =     varargin{4};
                        obj.MaximumProjection =             true;

                          obj.CentroidsAreVisible =         false;
                        obj.ActiveTrackIsVisible =        true;
                        obj.SelectedTracksAreVisible =     false;
                        obj.RestingTracksAreVisible =      false;
                        obj.MasksAreVisible =              false;
                        
                        obj.TimeAnnotationIsVisible =       false;
                        obj.ZAnnotationIsVisible =          false;
                        obj.ScaleBarAnnotationIsVisible =   true;
                        obj.ScaleBarSize =                  25;
                        
                         obj.VisiblePlanes =  '';

                    case 6

                        obj.ShownChannels  =              varargin{5}; 
                        obj.ShownTimeFrames =             varargin{1};
                        obj.ShownTrackIDs =               varargin{2};
                        obj.ListOfFramesForEachSegment =  varargin{3};
                        obj.AppliedCroppingRectangles =   varargin{4};
                        obj.MaximumProjection =           varargin{6};
                        
                        
                    case 10
                        
                        obj.ShownChannels  =                varargin{5}; 
                        obj.ShownTimeFrames =               varargin{1};
                        obj.ShownTrackIDs =                 varargin{2};
                        obj.ListOfFramesForEachSegment =    varargin{3};
                        obj.AppliedCroppingRectangles =     varargin{4};
                        obj.MaximumProjection =             varargin{6};
                        
                        obj.ChannelsLowIntensities =        varargin{7};
                        obj.ChannelsHighIntensities =       varargin{8};
                        obj.ChannelsColors =                varargin{9};
                        obj.VisiblePlanes =                 varargin{10};
                        
                    case 12
                        
                        obj.ShownChannels  =                varargin{5}; 
                        obj.ShownTimeFrames =               varargin{1};
                        obj.ShownTrackIDs =                 varargin{2};
                        obj.ListOfFramesForEachSegment =    varargin{3};
                        obj.AppliedCroppingRectangles =     varargin{4};
                        obj.MaximumProjection =             varargin{6};
                        
                        obj.ChannelsLowIntensities =        varargin{7};
                        obj.ChannelsHighIntensities =       varargin{8};
                        obj.ChannelsColors =                varargin{9};
                        obj.VisiblePlanes =                 varargin{10};
                        
                        obj.CentroidsAreVisible =          varargin{11}(1);
                        obj.ActiveTrackIsVisible =         varargin{11}(2);
                        obj.SelectedTracksAreVisible =     varargin{11}(3);
                        obj.RestingTracksAreVisible =      varargin{11}(4);
                        obj.MasksAreVisible =               varargin{11}(5);
                         
                        
                        obj.TimeAnnotationIsVisible =       varargin{12}{1};
                        obj.ZAnnotationIsVisible =          varargin{12}{2};
                        obj.ScaleBarAnnotationIsVisible =   varargin{12}{3};
                        obj.ScaleBarSize =                  varargin{12}{4};


                    otherwise
                        error('Wrong input.')

                end

           end

        function obj = refreshMovieControllers(obj)
            % REFRESHMOVIECONTROLLERS sets MovieControllers with the settings of the object;
            % necessary to use this method, otherwise movie-controllers will have all the settings from the saved movie-sequence;
            obj.MovieControllers=           cellfun(@(x, y) x.setVisibilityOfChannels(y), num2cell(obj.MovieControllers), obj.getChannelFilter);
            obj.MovieControllers=           arrayfun(@(x, y) x.setActiveTrackTo(y), obj.MovieControllers, obj.getTrackIDs);
            obj.MovieControllers=           arrayfun(@(x, y) x.setFrame(y), obj.MovieControllers, obj.getShownFrames);
            obj.MovieControllers=           cellfun(@(x, y) x.setCroppingGate(y), num2cell(obj.MovieControllers), obj.getCroppingRectangle);
            
            obj.MovieControllers =          arrayfun(@(x) x.setCollapseTracking(obj.MaximumProjection), obj.MovieControllers);
            obj.MovieControllers =          arrayfun(@(x) x.setSpaceAndTimeLimits(obj.StopDistanceLimit, obj.MaxStopDurationForGoSegment, obj.MinStopDurationForStopSegment), obj.MovieControllers);
            
            
            
            if isempty(obj.VisiblePlanes)
                 obj.MovieControllers =      arrayfun(@(x) x.setImageMaximumProjection(obj.MaximumProjection), obj.MovieControllers);  
            else
                obj.MovieControllers =      cellfun(@(x, y) x.resetPlane(y), num2cell(obj.MovieControllers), obj.VisiblePlanes(:));
                obj.MovieControllers =      arrayfun(@(x) x.setImageMaximumProjection(false), obj.MovieControllers);  
                obj =                       obj.setMovieControllerChannelSettings;
            end
            
            
           obj =                        obj.refreshMovieTrackingOfControllers;
                
         

            
        end
        
        function obj = loadAllImages(obj)
            movieTracking =                 obj.getMovieTrackingForEachPanel;
            movieTracking =                 arrayfun(@(x)                 x.updateLoadedImageVolumes('All'), movieTracking);
            obj.MovieControllers =          arrayfun(@(x, y) x.setLoadedMovie(y, 'DoNotEmtpyOut'), obj.MovieControllers, movieTracking);
             
        end
        
    end
    
    methods     % GETTERS

       function Rectangle =         getCroppingRectangle(obj)
           Rectangle = obj.AppliedCroppingRectangles;

       end

        function calibrations =     getCalibrationForEachPanel(obj)
           calibrations =  arrayfun(@(x) x.getLoadedMovie.getSpaceCalibration, obj.MovieControllers);
        end

        function list =             getNickNameOfEachPanel(obj)
            Type = class(obj.ListWithNickNames);
            switch Type
                case 'char' 
                    CurrentNickname =           obj.ListWithNickNames;
                    list =                      repmat({ CurrentNickname}, obj.getNumberOfPanels, 1);
                case 'cell'
                    list =                      obj.ListWithNickNames;
                otherwise
                    error('Nickname format not supported')
            end

        end

        function Frames =           getShownFrames(obj)
            Frames = obj.ShownTimeFrames;
        end

        function TimeStamps =       getTimeStamps(obj)
            % GETTIMESTAMPS returns vector of time-stamp strings;
            % one string for selected time-frame of each panel;
            TimeStamps =                cellfun(@(x,y)   ...
                                            x.getLoadedMovie.getTimeStamps{y}, ...
                                            num2cell(obj.MovieControllers), ...
                                            num2cell(obj.ShownTimeFrames), ....
                                            'UniformOutput',false);  
        end

        function id =               getTrackIDs(obj)
           id = obj.ShownTrackIDs; 
        end

        function rectangles =       getMetricCroppingRectangles(obj)

            rectangles = cellfun(@(x, y) ...
                round([x.convertXPixelsIntoUm(y(1)), x.convertYPixelsIntoUm(y(2)), x.convertXPixelsIntoUm(y(3)), x.convertYPixelsIntoUm(y(4))]), ...
                num2cell(obj.getCalibrationForEachPanel), obj.AppliedCroppingRectangles, 'UniformOutput', false); 
        end

        function filter =           getChannelFilter(obj)
           filter = obj.ShownChannels; 
        end

         function NumberOfPanels =  getNumberOfPanels(obj)
            NumberOfPanels =    obj.NumberOfPanels;
        end

        function con =              getMovieControllers(obj)
           con = obj.MovieControllers; 
        end

        function movieTracking =    getMovieTrackingForEachPanel(obj)
            movieTracking =     arrayfun(@(x) x.getLoadedMovie, obj.MovieControllers);
        end

    end
    
    methods     % GETTERS TRACK INFORMATION
        
        function rgbImages =                        getRgbImages(obj) 
            % GETRGBIMAGES returns vector rgb-images; one for each movie controller;
           obj.MovieControllers =   arrayfun(@(x) x.setDefaultNumberOfLoadedFrames(0), obj.MovieControllers);
           rgbImages =              arrayfun(@(x) x.getCroppedRgbImage, obj.MovieControllers, 'UniformOutput', false);

        end
        
        function completeCoordinateLists =          getCoordinatesOfCompleteTracks(obj)
            % GETCOORDINATESOFCOMPLETETRACKS returns vector with metric coordinates of active track for each panel;
            if isempty(obj.ShownTrackIDs)
                    completeCoordinateLists = '';
            else
                    completeCoordinateLists =       arrayfun(@(x)       x.getMetricCoordinatesOfActiveTrack, obj.getMovieTrackingForEachPanel,  'UniformOutput', false); 
            end
            
        end
        
        function CoordinateListForTrackSegments=    getCoordinatesOfTrackSegments(obj)
            % GETCOORDINATESOFTRACKSEGMENTS
            if isempty(obj.ListOfFramesForEachSegment)
                CoordinateListForTrackSegments = cell(0,3);
                
            else
                SegmentsForEachPanel =      obj.getFramesForTrackSegmentsOfEachPanel;
                MoviePanels =               obj.getMovieTrackingForEachPanel;
                
                for index = 1 : length(SegmentsForEachPanel)
                    CurrentSegments = SegmentsForEachPanel{index};
                    
                    switch class(CurrentSegments)
                        case 'double'
                                CoordinateListForTrackSegments{index, 1} =        {MoviePanels(index).getMetricCoordinatesOfActiveTrackFilteredForFrames(CurrentSegments)};
                        case 'cell'
                                CoordinateListForTrackSegments{index, 1} =       cellfun(@(x)       MoviePanels(index).getMetricCoordinatesOfActiveTrackFilteredForFrames(x),  CurrentSegments , 'UniformOutput', false);
           
                        otherwise
                            error('Wrong input.')
                        
                        
                    end
                    
                        end
                
               
            end   
        end
        
        function ListWithDurations =                getTotalDurationOfTrackSegments(obj, varargin)
            
            switch length(varargin)
                case 0
                    
                case 1
                    Modifier = varargin{1};
                
            end
            
            MinuteFrames = obj.getFramesForTrackSegmentsOfEachPanel(Modifier);
            Pooled = cell(length(MinuteFrames), 1);
            for index = 1 : length(MinuteFrames)
                    Pooled{index, 1} = cellfun(@(x) max(x) - min(x), MinuteFrames{index});
            end
            ListWithDurations = cellfun(@(x) sum(x), Pooled);

        end
        
     end
   
    methods (Access = private) % set movie controller properties
        
        function obj = setMovieControllerChannelSettings(obj)
            
            for index = 1 : length(obj.MovieControllers)
                
                 NumberOfChannels = obj.MovieControllers(index).getLoadedMovie.getNumberOfChannels;
                 
                 for channelIndex = 1 : NumberOfChannels
                     
                    obj.MovieControllers(index) = obj.MovieControllers(index).setActiveChannel(channelIndex);

                    obj.MovieControllers(index) = obj.MovieControllers(index).resetChannelSettings(obj.ChannelsLowIntensities{index}(channelIndex),'ChannelTransformsLowIn');
                    obj.MovieControllers(index) = obj.MovieControllers(index).resetChannelSettings(obj.ChannelsHighIntensities{index}(channelIndex),'ChannelTransformsHighIn');
                    obj.MovieControllers(index) = obj.MovieControllers(index).resetChannelSettings(obj.ChannelsColors{index}{channelIndex},'ChannelColors');
  
                 end
                   
                        
                
            end
            
           
            
            
        end
        
        function obj = refreshMovieTrackingOfControllers(obj)
            
            movieTracking =              obj.getMovieTrackingForEachPanel;
            movieTracking =              arrayfun(@(x)                 x.setCroppingStateTo(true), movieTracking);
            
            movieTracking =              arrayfun(@(x)                 x.setCentroidVisibility(obj.CentroidsAreVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setTrackVisibility(obj.ActiveTrackIsVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setSelectedTracksAreVisible(obj.SelectedTracksAreVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setRestingTracksAreVisible(obj.RestingTracksAreVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setMaskVisibility(obj.MasksAreVisible), movieTracking);
         
            
            movieTracking =              arrayfun(@(x)                 x.setTimeVisibility(obj.TimeAnnotationIsVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setPlaneVisibility(obj.ZAnnotationIsVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setScaleBarVisibility(obj.ScaleBarAnnotationIsVisible), movieTracking);
            movieTracking =              arrayfun(@(x)                 x.setScaleBarSize(obj.ScaleBarSize), movieTracking);
            
            obj.MovieControllers =      arrayfun(@(x, y) x.setLoadedMovie(y, 'DoNotEmtpyOut'), obj.MovieControllers, movieTracking);
 
        end
        
    end
 
    methods (Access = private) % summary
        
        function obj = showSummaryForSegmentForPanelIndex(obj, index)
            
            fprintf('Track segments will be shown ')
            switch class(obj.ListOfFramesForEachSegment{index})
                case 'double'
                    fprintf('at frames ')
                    arrayfun(@(x) fprintf('%i ', x), obj.ListOfFramesForEachSegment{index})
                    fprintf(' of the original track.\n')
                    
                case 'char'
                    switch obj.ListOfFramesForEachSegment{index}
                        case 'GoTracks'
                            fprintf(' for all go (sub) tracks.\n')
                            myTrackCoordinates =        obj.getCoordinatesOfCompleteTracks{index};
                        case 'StopTracks'
                             fprintf(' for all stop (sub) tracks.\n')
                        otherwise
                            error('Segment type not supported.')
                    end
            end
         
                
            
        end
        
    end

    methods  % retrieve model data;
        
        function HighlightedFramesForEachPanel = getFramesForTrackSegmentsOfEachPanel(obj, varargin)
            % GETFRAMESFORTRACKSEGMENTSOFEACHPANEL
            % takes 0, or 1 arguments:
            % 1: 
            
            MyMovieTrackings =      obj.getMovieTrackingForEachPanel;
            NumberOfArguments =     length(varargin);
            switch NumberOfArguments
                case 0
                    Modifier = 'NoModifier';
                    
                case 1
                    Modifier = varargin{1};
                    
                otherwise
                    error('Wrong input.')
                    
            end
                
            
            HighlightedFramesForEachPanel = cell(length(obj.ListOfFramesForEachSegment), 1);
            for panelIndex = 1 : length(obj.ListOfFramesForEachSegment)
                
                switch class(obj.ListOfFramesForEachSegment{panelIndex})
                    
                    case 'double'
                       HighlightedFramesForEachPanel{panelIndex, 1} = obj.ListOfFramesForEachSegment{panelIndex};

                    case 'char'
                        
                        switch obj.ListOfFramesForEachSegment{panelIndex}
                            
                            case 'GoTracks'
                                
                                switch Modifier
                                    case 'NoModifier'
                                        HighlightedFramesForEachPanel{panelIndex, 1} =         MyMovieTrackings(panelIndex).getFramesOfGoSegmentsOfActiveTrack;
                                    case 'metric'
                                        HighlightedFramesForEachPanel{panelIndex, 1} =        MyMovieTrackings(panelIndex).getMetricFramesOfGoSegmentsOfActiveTrack;
                                           
                                    otherwise
                                   error('Modifier not supported.')     
                                end
                                
                            case 'StopTracks'
                                    switch Modifier
                                    case 'NoModifier'
                                        HighlightedFramesForEachPanel{panelIndex, 1} =       MyMovieTrackings(panelIndex).getFramesOfStopSegmentsOfActiveTrack;
                                    case 'metric'
                                           HighlightedFramesForEachPanel{panelIndex, 1}  =       MyMovieTrackings(panelIndex).getMetricFramesOfStopSegmentsOfActiveTrack;
                                           
                                    otherwise
                                   error('Modifier not supported.')     
                                end 
                                
                            otherwise
                                error('Track ranges not supported.')
                        end
                            
                end
                
            end
            
        end
        
    end
    
    methods (Access = private) % set model
        
         function obj = initializeMovieControllersFromFile(obj)
             % this is simply to load the movies from file into the controllers
             
                Type = class(obj.ListWithNickNames); % if the movies are all the same, no need to load movie multiple times
                switch Type
                    
                    case 'char' 
                        obj.MovieLibrary =                          obj.MovieLibrary.switchActiveMovieByNickName(obj.ListWithNickNames);
                        obj.MovieControllers =                      arrayfun(@(x) obj.MovieLibrary.getActiveMovieController, (1 : obj.NumberOfPanels)');

                    case 'cell'
                        
                        for Index = 1 : length(obj.ListWithNickNames)
                            obj.MovieLibrary =                      obj.MovieLibrary.switchActiveMovieByNickName(obj.ListWithNickNames{Index} );
                            obj.MovieControllers(Index, 1) =        obj.MovieLibrary.getActiveMovieController;
                        end

                    otherwise
                        error('Nickname format not supported')
                end
                
         end
        
    end
    
    methods (Access = private) % DEPRECATED
         
        %% remove?
         function obj = updateView(obj)
            
            % I am now using SVG directly to make views;
            % this part is probably not that relevant anymore, and I am not
            % maintaining it now, this class is still useful for data retrieval of track and image data and convenient access to library data in general;
            
                    %% first get the libary and leave it there (unless changes occur this is faster):
                  
                    obj.FigureObject  =                                                             PMFigureView(figureTitle);
                    
                    %METHOD1 Summary of this method goes here
                    obj.FigureObject =                                                          obj.FigureObject.calculateAxesPositions;
                    obj.FigureObject =                                                          obj.FigureObject.resetAxes;
                    obj.FigureObject =                                                          obj.FigureObject.resetAxesLabels;

                    
                    %% create and initialize movie-controllers:
                    myMovieControllerViewList =                                                 cellfun(@(x) PMMovieControllerView(x), obj.FigureObject.Axes, 'UniformOutput', false);
                    obj.MovieControllers =                                                      cellfun(@(x) PMMovieController(x,obj.LibraryManager.ActiveMovieController.getLoadedMovie), myMovieControllerViewList,  'UniformOutput', false);
                    obj =                                                                       obj.resetMovieControllers;
                   
                    FontSize =                                                                  5;
                    cellfun(@(x) x.Views.resetNavigationFontSize(FontSize), obj.MovieControllers,  'UniformOutput', false);

                    obj.MovieControllers =                                                      cellfun(@(x) obj.resetImageViewAppearance(x), obj.MovieControllers,  'UniformOutput', false);
                    obj.MovieControllers =                                                     cellfun(@(x) x.updateAnnotationViews, obj.MovieControllers,  'UniformOutput', false);
                  
  
                     %% set axes size according to crop-limits and update view ;
                     obj.MovieControllers =                                                 cellfun(@(controller) controller.resetLimitsOfImageAxesWithAppliedCroppingGate, obj.MovieControllers,'UniformOutput', false);
                     obj.MovieControllers =                                                 cellfun(@(controller,frame) controller.setFrame(frame), obj.MovieControllers,  num2cell(obj.ShownTimeFrames),'UniformOutput', false);
                      
                     
                     
                     %% draw 'complete track"
                     completeCoordinateLists =                                          obj.getCoordinatesOfCompleteTracks;
                     
                     HandlesForCompleteTracks =                                          cellfun(@(x,y) line(x.Views.MovieView.ViewMovieAxes), obj.MovieControllers, 'UniformOutput', false);
                     cellfun(@(controller,lineHandle,coordinates) controller.updateTrackLineCoordinatesForHandle(lineHandle,coordinates), obj.MovieControllers, HandlesForCompleteTracks, completeCoordinateLists,'UniformOutput', false);

                     %% filter tracks for short tracks and draw lines for the short tracks:
                    CoordinateListForTrackSegments =                obj.getCoordinatesOfTrackSegments;
                    HandlesForTrackSegments =                       cellfun(@(x,y) line(x.Views.MovieView.ViewMovieAxes), obj.MovieControllers, 'UniformOutput', false);
                    cellfun(@(controller,lineHandle,coordinates) controller.updateTrackLineCoordinatesForHandle(lineHandle,coordinates), obj.MovieControllers, HandlesForTrackSegments, CoordinateListForTrackSegments,'UniformOutput', false);
                    cellfun(@(controller,lineHandle,coordinates) controller.setLineWidthTo(lineHandle,3), obj.MovieControllers, HandlesForTrackSegments,'UniformOutput', false);
                    cellfun(@(controller,lineHandle,coordinates) controller.setLineColorTo(lineHandle,'b'), obj.MovieControllers, HandlesForTrackSegments,'UniformOutput', false);

                    
                    %% more formatting of axes
                     obj.MovieControllers =                                                      cellfun(@(x) x.resetWidthOfMovieAxesToMatchAspectRatio, obj.MovieControllers,  'UniformOutput', false);
                   % [obj.FigureObject] =                                                        obj.FigureObject.alignAllAxesInSameRowWithDistance( 0);
                   
                    if ~isempty(obj.FigureSize)
                        obj.FigureObject.FigureInfo.ParentFigure.Position =   obj.FigureSize;
                    
                    end
                   
                    

         end
         
         
         function [Controller] = resetImageViewAppearance(obj, Controller)
            Controller.Views.MovieView.TimeStampText.FontSize =                         10;
            Controller.Views.MovieView.TimeStampText.Color =                            'w';
            Controller.Views.MovieView.TimeStampText.Position =                         [0.05 0.05 ];
            Controller.Views.MovieView.TimeStampText.HorizontalAlignment =              'left';
            Controller.Views.MovieView.TimeStampText.VerticalAlignment =                'base';
            Controller.Views.MovieView.ViewMovieAxes.Visible =                           'off';
                        
         end
        
        
    end
         
end