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
       ShowInteractionsImageVolume
        
    end
    
    methods % INITIALZIATION
        
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
            
            if isempty(Value)
                obj.Views = obj.Views.clear;
            else
                assert(isa(Value, 'PMMovieControllerView') && isscalar(Value), 'Wrong input.')
                obj.Views = Value;
                
            end
            
            
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
        
        function set.DefaultNumberOfLoadedFrames(obj, Value)
            assert(iscalar(Value) && isnumeric(Value) && mod(Value, 1) == 0, 'Wrong input.')
           obj.DefaultNumberOfLoadedFrames = Value; 
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

            obj.Views = obj.Views.showSummary;
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

    methods % GETTERS
        
        function Value = getNickName(obj)
            Value = obj.LoadedMovie.getNickName;
        end

         function action = getMouseAction(obj)
             action = obj.MouseAction;
         end
         
         function verifiedStatus =                     verifyActiveMovieStatus(obj)
             % VERIFYACTIVEMOVIESTATUS tests whether object contains valid PMMovieTracking object;
             % returns 1 value:
             % 1: logical scalar;
              verifiedStatus = ~isempty(obj.LoadedMovie) &&   isa(obj.LoadedMovie, 'PMMovieTracking') && isscalar(obj.LoadedMovie) &&  obj.LoadedMovie.verifyThatEssentialPropertiesAreSet;
         end
         
        function CompleteFileName = getMovieFileNameForFrames(obj, varargin)
            % GETMOVIEFILENAMEFORFRAMES returns standard filename for movie sequences;
            % takes 2 arguments
            % 1: first frame (numeric integer scalar)
            % 2: last frame (numeric integer scalar)

            switch length(varargin)


                case 2
                    assert(isnumeric(varargin{1}) && isscalar(varargin{1}) && mod(varargin{1}, 1) == 0, 'Wrong input.')
                    assert(isnumeric(varargin{2}) && isscalar(varargin{2}) && mod(varargin{2}, 1) == 0, 'Wrong input.')
                    MyStartFrame =  varargin{1};
                    MyEndFrame =   varargin{2};

                otherwise
                    error('Wrong input.')

            end

            planeRange =            obj.Views.getPlaneRange;
            extension=              '.mp4';
            MyNickName =            obj.getNickName;
            ShowTracks =            obj.getViews.getShowTracks;

            if  ShowTracks   
                Traj=           'T_';
            else
                Traj=           '';
            end

            AdditionalName=                       [Traj, 'Frame_', num2str(MyStartFrame), 'to', num2str(MyEndFrame), ...
            '_Pl', num2str(planeRange(1)), 'to', ... 
            num2str(planeRange(1)+planeRange(2)-1), '_', PMTime().getCurrentTimeString, extension];

            CompleteFileName =           [MyNickName '_' AdditionalName];


        end

          
         
         
             
             
         
          
      end
    
    methods % SETTERS
        
        function obj =      updateWith(obj, Value)
            % UPDATEWITH update state of PMMovieController
            % this function will be ignored if currently no PMMovieTracking is attached;
            % takes 1 argument:
            % option 1: PMMovieLibrary: this will set the image-analysis folder of PMMovieTracking;
            % option 2: PMInteractionsManager: this will update the attached PMMovieTracking;
        
                assert(~isempty(obj.LoadedMovie), 'No loaded movie available.')
                 Type = class(Value);
                switch Type
                    case 'PMMovieLibrary'
                        MyLibrary = Value;
                        obj.LoadedMovie =       obj.LoadedMovie.setImageAnalysisFolder(MyLibrary.getPathForImageAnalysis);
                        obj.LoadedMovie =       obj.LoadedMovie.setMovieFolder(MyLibrary.getMovieFolder);
                        
                    case 'PMInteractionsManager'
                        
                        obj.LoadedMovie =       obj.LoadedMovie.updateWith(Value.getModel);
                        obj =                   obj.updateControlElements;
                        obj.ShowInteractionsImageVolume =   Value.getVisibilityOfTargetImage;
                        obj =                   obj.updateMovieView;
                        
                        
                    otherwise
                        error('Cannot parse input.')
                end
           
    
        end
        

        function obj =      setNickName(obj, Value)
            % SETNICKNAME set nickname of loaded movie
            obj.LoadedMovie =   obj.LoadedMovie.setNickName(Value);
            obj =               obj.updateSaveStatusView;
        end
        
        function obj =      setKeywords(obj, Value)
            % SETKEYWORDS set keywords of loaded movie
            obj.LoadedMovie = obj.LoadedMovie.setKeywords(Value); 
        end

        function obj =      setMouseAction(obj, Value)
            % SETMOUSEACTION set a descriptor for a mouse action type;
            % takes 1 argument
             obj.MouseAction = Value;
        end
          
        function obj =      resetNumberOfExtraLoadedFrames(obj,Number)
            % RESETNUMBEROFEXTRALOADEDFRAMES sets number of frames before and after current frame that should be loaded when navigating forward in movie;
            % takes 1 argument:
            % 1: numeric integer scalar
            obj.DefaultNumberOfLoadedFrames =                   Number;    
       end

    end
    
    methods % SETTERS NAVIGATION
        
        function obj = setFrame(obj, Value)
            % SETFRAME; sets model and view with new active frame;
            % takes 1 argument:
            % argument can be either a string: 'first', 'last', 'next', 'previous';
            % or a number: if number is out of range it is ignored;
            Type = class(Value);
            switch Type
                case 'char'
                    obj = obj.setFrameByString(Value);
                case 'double'
                    obj = obj.setFrameByNumber(Value);
                otherwise
                    error('Wrong input.')
                       
            end
  
        end
        
        function obj = goOnePlaneDown(obj)
            % GOONEPLANEDOWN set active plane one higher
           obj  = obj.resetPlane(obj.LoadedMovie.getActivePlanes + 1);
        end
        
        function obj = goOnePlaneUp(obj)
             % GOONEPLANEUP set active plane one lower
            obj  = obj.resetPlane(obj.LoadedMovie.getActivePlanes - 1);
        end
        
         function obj  =     resetPlane(obj, newPlane)
             % RESETPLANE set plane to new value
             % takes 1 argument:
             % 1: numerical scalar
              if CurrentPlane >= 1 
                   [~, ~, MaximumPlane]=  obj.LoadedMovie.getImageDimensionsWithAppliedDriftCorrection;
                  if CurrentPlane <= MaximumPlane
                        obj.LoadedMovie =       obj.LoadedMovie.setSelectedPlaneTo(newPlane);
                        obj =                   obj.updateMovieView;
                        obj =                   obj.setNavigationControls;
                  end
                  
              end 
           

         end
         
         function obj = focusOnActiveMask(obj)
             % FOCUSONACTIVEMASK change "zoom position" so that focus is on current frame of active mask;
            obj.LoadedMovie =   obj.LoadedMovie.setFocusOnActiveTrack; 
            obj =               obj.setActiveCropOfMovieView;
            obj =               obj.updateMovieView;
            obj =               obj.setNavigationControls;
         end
             
      
       
    end
  
    methods % SETTERS TRACK VIEWS
        
        function obj =         toggleTrackVisibility(obj)
             % TOGGLETRACKVISIBILITY switches visibility of tracks and updates views;
            obj.LoadedMovie =   obj.LoadedMovie.toggleTrackVisibility;
            obj.Views =         obj.Views.setTrackVisibility(obj.LoadedMovie.getTrackVisibility);

        end

        function obj =          setSegmentLineViews(obj, DistanceLimit, MinTimeLimit, MaxTimeLimit, Visibility)
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
    end

    methods % SETTERS VIEW
        
        function obj =      setViewsByProjectView(obj, ImagingProjectViewer)
              % SETVIEWSBYPROJECTVIEW sets views into figure of image project viewer ;
              % 1 argument PMImagingProjectViewer
                assert(isscalar(ImagingProjectViewer) && isa(ImagingProjectViewer, 'PMImagingProjectViewer'), 'Wrong input.')
                if ~isempty(obj.Views)
                    obj.Views = obj.Views.clear;
                end

                obj.Views =     PMMovieControllerView(ImagingProjectViewer);
                obj =           obj.initializeViews;

         end
      
        function obj =      initializeViews(obj)
            % INITIALIZEVIEWS: updates views of movie controller by state of current LoadedMovie property;
            % sets numerouse views including centroid-visibility, tracking views, movie-view, track-visibility and save-status;

             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views)) && ~isempty(obj.LoadedMovie)

                    obj  =          obj.updateControlElements; % channels and navigation

                    % ERROR: THIS LINE SHOULD WORK BUT CAUSES AN ERROR
                    %      obj.Views =     obj.Views.updateMovieViewWith( obj.LoadedMovie, obj.getRbgImage);

                    obj.Views =     updateMovieViewWith(obj.Views,  obj.LoadedMovie, obj.getRbgImage); % axes with image view:
                    obj =           obj.updateSaveStatusView;
                    obj =           obj.setCallbacks;

             end

        end
          
        function obj =      updateSaveStatusView(obj)
            % UPDATESAVESTATUSVIEW updated saved movie-status by LoadedMovie;
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                    obj.Views =     obj.Views.updateSaveStatusWith(obj.LoadedMovie);
             end
        end
        
        function obj =      updateMovieViewImage(obj)
            % UPDATEMOVIEVIEWIMAGE
            if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views =     setMovieImagePixels(obj.Views, obj.getRbgImage);
            end
        end
              
        function obj =      blackOutViews(obj)
            if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views=          blackOutMovieView(obj.Views); 
            end
        end
        
        function obj =      clear(obj)
            % CLEAR deletes all controlled views;
            if ~isempty(obj.Views)
                obj.Views = obj.Views.clear;
            end
        end

        function obj =      setViews(obj, Value, varargin)
            % SETVIEWS allows convenient setting of various view functions from outside;
            % takes 2 arguments:
            % 1: string with name of "second part" of function
            % 2: argument for function
           
                FunctionName = ['view_', Value];
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 1
                        obj = obj.(FunctionName)(varargin{1});
                    otherwise
                        error('Wrong input.')
                end

         end 
        
        function obj =      setImageMaximumProjection(obj, Value)
            % SETIMAGEMAXIMUMPROJECTION shows all image planes (true) or only the currently selected one (false);
            obj.LoadedMovie =  obj.LoadedMovie.setCollapseAllPlanes(Value);
            obj =               obj.setViewsAfterChangeOfMaximumProjection(Value);
  
        end
        
        function obj =      setCollapseTracking(obj, Value)
            % SETCOLLAPSETRACKING set whether all tracking data of only the ones in the selected planes should be visualize;
            % takes 1 argument:
            % 1: scalar logical;
            obj.LoadedMovie =   obj.LoadedMovie.setCollapseAllTrackingTo(Value);
            obj =               obj.setViewsAfterChangeOfMaximumProjection(Value);    
        end
        
        function obj =      updateMovieView(obj)
            % UPDATEMOVIEVIEW sets all views (including image) in axes containing movie-view;
            if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                obj.Views =     updateMovieViewWith(obj.Views, obj.LoadedMovie, obj.getRbgImage);
            end

        end

        function obj =      setNavigationControls(obj)
            if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views =               setNavigationWith(obj.Views, obj.LoadedMovie);
            end
        end 

        function obj =      setTrackingNavigationEditViewController(obj, varargin)
            % SETTRACKINGNAVIGATIONEDITVIEWCONTROLLER
            % set model of tracking edit view controller
            % takes 0 or 1 arguments:
            % 1: 
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

        function obj =      showAutoTrackingController(obj)
            % SHOWAUTOTRACKINGCONTROLLER show autotracking controller view
             obj.TrackingAutoTrackingController =         obj.TrackingAutoTrackingController.resetModelWith(obj.LoadedMovie.getTracking, 'ForceDisplay');
             obj =                                        obj.updateHandlesForAutoTrackingController;
        end
 
        function obj =      resetAxesCenterByMouseMovement(obj)
            % RESETAXESCENTERBYMOUSEMOVEMENT resets limits of movie-axis by how much mouse moved horizontally and vertically;
                XMovement =     obj.getMouseUpColumn - obj.getMouseDownColumn;
                YMovement =     obj.getMouseUpRow - obj.getMouseDownRow;
                obj =           obj.resetAxesCenter(XMovement, YMovement);
            
        end
         
        
    end
    
    methods % SETTERS SOURCE IMAGES
        
        function obj =     setLoadedImageVolumes(obj, Value)
          % SETLOADEDIMAGEVOLUMES sets LoadedImageVolumes (which contains stored images of source files so that they don't have to be loaded from file each time);
          obj.LoadedImageVolumes =      Value; 
        end

        function obj    =  emptyOutLoadedImageVolumes(obj)
            % EMPTYOUTLOADEDIMAGEVOLUMES delete loaded image volumes from memory;
            if isempty(obj.LoadedMovie) 
                obj.LoadedImageVolumes =        cell(0,1);
            else
                obj.LoadedImageVolumes =        cell(obj.LoadedMovie.getMaxFrame,1);
            end     
        end

        function obj =     resetLoadedMovieFromImageFiles(obj)
            % RESETLOADEDMOVIEFROMIMAGEFILES LoadedMovie reset completely from file (including meta-data, e.g. space calibration);
            obj    =            obj.emptyOutLoadedImageVolumes;
            obj.LoadedMovie =   obj.LoadedMovie.setPropertiesFromImageFiles;
            obj =               obj.updateMovieViewImage;
        end

        function obj =     manageResettingOfImageMap(obj)
            error('Not supported anymore. Use resetLoadedMovieFromImageFiles instead.')
        end

    end
    
    methods % GETTERS SOURCE IMAGES:
        
        function volumes =              getLoadedImageVolumes(obj)
            % GETLOADEDIMAGEVOLUMES get access to all image-volumes that are current stored in cash;
            % this is used by PMMovieLibrary which keeps track of all movies so that the movie does not have to be reloaded as soon as the user changes the movie;
            volumes =  obj.LoadedImageVolumes;
        end
        
        function rgbImage =             getRbgImage(obj)
            % GETRBGIMAGE returns active image (with cell masks);
            
            rgbImage =              obj.LoadedMovie.convertImageVolumeIntoRgbImage(obj.getActiveImageVolume); 
            ThresholdedImage =      obj.getInteractionImage;
            
            if isempty(ThresholdedImage)

            else
                rgbImage = PMRGBImage().addImageWithColor(...
                                                            rgbImage, ...
                                                            ThresholdedImage, ...
                                                            'Red'...
                                                            );
            end

            if obj.LoadedMovie.getMaskVisibility 
                rgbImage =            obj.addMasksToImage(rgbImage);
            end

         end
         
        function activeVolume =         getActiveImageVolume(obj)
            % GETACTIVEIMAGEVOLUME
            % returns 5D image volume of active time frame:
             obj =              obj.updateLoadedImageVolumes;
             activeVolume =     obj.LoadedImageVolumes{obj.LoadedMovie.getActiveFrames, 1};
        end

        function Volume =               getActiveImageVolumeForChannel(obj, ChannelIndex)
            % GETACTIVEIMAGEVOLUMEFORCHANNEL 
            % takes 1 argument:
            % 1: numeric integer scalar (number of channel)
            % returns 5D image volume of active frame and input channel;
            activeVolume =      obj.getActiveImageVolume;
            Volume =            obj.filterImageVolumeForChannel(activeVolume, ChannelIndex);
        end
        
        function Volume =               filterImageVolumeForChannel(obj, Volume, ChannelIndex)
            Volume =            Volume(:, :, :, 1, ChannelIndex);
            
        end

        function croppedRgbImage =      getCroppedRgbImage(obj)
            % GETCROPPEDRGBIMAGE returns active cropped image;
            RgbImage =          obj.getRbgImage;
            Rectangle =         obj.LoadedMovie.getCroppingRectangle;
            croppedRgbImage =   RgbImage(Rectangle(2): Rectangle(2) + Rectangle(4)-1,Rectangle(1): Rectangle(1) + Rectangle(3) - 1, :);

        end

    end
    
    methods % SETTERS FILE-MANAGEMENT
        
        function obj =      setNamesOfMovieFiles(obj, Value)
            % SETNAMESOFMOVIEFILES set names of attached movie files
            % takes 1 argument:
            % 1: list with filenames (cell string)
            obj.LoadedMovie =       obj.LoadedMovie.setNamesOfMovieFiles(Value);
        end
        
        function obj =      setExportFolder(obj, Value)
            % SETEXPORTFOLDER set export folder (default folder for data export);
            % takes 1 argument:
            % 1: name of export folder ('char')
           obj.ExportFolder = Value; 
        end
        
        function obj =      setInteractionsFolder(obj, Value)
            % SETINTERACTIONSFOLDER set interactions folder
            % takes 1 argument:
            % 1: name of export folder ('char')
           obj.InteractionsFolder = Value; 
        end
       
        function obj =      saveMovie(obj)
            % SAVEMOVIE: saves attached PMMovieTracking into file and updates save-status view;
            if ~isempty(obj.LoadedMovie)  && isa(obj.LoadedMovie, 'PMMovieTracking')
                obj.LoadedMovie =   obj.LoadedMovie.save;
                obj =               obj.updateSaveStatusView;

           else
                warning('No valid LoadedMovie available: therefore no action taken.\n')

           end

        end
        
        function obj =      deleteMovieAnnotation(obj)
            % DELETEMOVIEANNOTATION deletes files containing movie annotation data (only files of current version);
            obj.LoadedMovie = obj.LoadedMovie.delete;
        end
       
        function obj =      createDerivativeFiles(obj)
            % CREATEDERIVATIVEFILES uses saveDerivativeData method from PMMovieTracking object;
            obj.LoadedMovie = obj.LoadedMovie.saveDerivativeData;
          
        end
        
        function obj =      saveMetaData(obj, varargin)
            % SAVEMETADATA saves metadata of current movie
            % takes 1 argument:
            % 1: folder where to store the file;

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    obj.LoadedMovie = obj.LoadedMovie.saveMetaData(varargin{1});

                otherwise
                    error('Wrong input.')

            end

        end
        
        function obj =      exportTrackCoordinates(obj)
            % EXPORTTRACKCOORDINATES exports track-coordinates of movie to "Matthew Fricke" format;
            % user picks file before export;
           [file,path] =                   uiputfile([obj.LoadedMovie.getNickName, '.csv']);
            TrackingAnalysisCopy =         obj.LoadedMovie.getTrackingAnalysis;
            TrackingAnalysisCopy =         TrackingAnalysisCopy.setSpaceUnits('µm');
            TrackingAnalysisCopy =         TrackingAnalysisCopy.setTimeUnits('minutes');
            TrackingAnalysisCopy.exportTracksIntoCSVFile([path, file], obj.LoadedMovie.getNickName)

        end

    end
    
    methods % GETTERS FILE-MANAGEMENT
       
         function folder =   getExportFolder(obj)
             % GETEXPORTFOLDER returns 'char' of export-folder;
           folder = obj.ExportFolder; 
        end

    end
    
    methods % SETTERS TRACKING
        
        function obj =      setActiveTrackTo(obj, Code)  
             % SETACTIVETRACKTO sets selection of active track and views;
             % takes 1 argument:
             % 1: numeric scalar (track ID) or descriptive text ('char');
             obj.LoadedMovie =          obj.LoadedMovie.setActiveMaskTo(Code, obj.MouseUpColumn, obj.MouseUpRow);
            obj =                       obj.focusOnActiveMask;
            obj =                       obj.updateAllViewsThatDependOnActiveTrack;
            drawnow
            
        end
      
        function obj =      setSpaceAndTimeLimits(obj, Space, TimeMax, TimeMin)
            % SETSPACEANDTIMELIMITS set "confinemnt limit"; this is improtant so that LoadedMovie can accuratly create stop-tracking object;
            % takes 3 arguments:
            % 1: space-limit
            % 2: maximum-time allowed to be considered "go";
            % 3: minimum-time neeeded to be considered "stop";
            obj.LoadedMovie = obj.LoadedMovie.setSpaceAndTimeLimits(Space, TimeMax, TimeMin);
        end
        
        function obj =      setFinishStatusOfTrackTo(obj, Input)
            % SETFINISHSTATUSOFTRACKTO sets finished status of active track;
            % takes 1 argument:
            % 1: 'Finished' or 'Unfinished'
            % after setting goes to "next" unfinished track
               
                obj.LoadedMovie =                       obj.LoadedMovie.setFinishStatusOfTrackTo(Input); 
                obj.LoadedMovie =                       obj.LoadedMovie.setActiveMaskTo('nextUnfinishedTrack', obj.MouseUpColumn, obj.MouseUpRow);
                obj =                                   obj.focusOnActiveMask;
                obj =                                   obj.updateAllViewsThatDependOnActiveTrack;

             
         end

        function obj =      performTrackingMethod(obj, Value, varargin)
            % PERFORMTRACKINGMETHOD performs method of "tracking_" method with object;
            % takes 2 or more arguments:
            % 1: name of method
            % 2 : optional: arguments for functions
            % methods: 
            % removeHighlightedPixelsFromActiveMask
            % removePixelRimFromActiveMask
            % deleteSelectedTracks
            % deleteActiveTrack
            % deleteAllTracks
            % deleteActiveMask
            % splitSelectedTrack
            % mergeSelectedTracks
            % fillGapsOfActiveTrack
            % addButtonClickMaskToNewTrack
            % updateActiveMaskByButtonClick
            % setSelectedTracks
            % addHighlightedPixelsFromMask
            % usePressedCentroidAsMask
            % addPixelRimToActiveMask
            % autoTracking
            
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

        function obj =      truncateActiveTrackToFit(obj)
            % TRUNCATEACTIVETRACKTOFIT truncates active track so that there is no overlap with selected tracks;
            % only one selected track allowed;
            
            try
                obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('truncateActiveTrackToFit');
                obj =                   obj.updateAllViewsThatDependOnActiveTrack;
            catch ME
                throw(ME)
            end
            
        end
        
    end
         
    methods % SETTERS LOADEDMOVIE
        
        function obj =      setLoadedMovie(obj, Value, varargin)
            % SETLOADEDMOVIE sets loaded movie of controller;
            % takes 1 argument:
            % 1: PMMovieTracking
           
            obj.LoadedMovie = Value; 
           % probably should add update of dependent views here
           switch length(varargin)
               case 0
                    obj = obj.emptyOutLoadedImageVolumes;
               case 1
                   switch varargin{1}
                       case 'DoNotEmtpyOut'

                       otherwise
                            error('Wrong input.')
                    
                   end
                   
           end
               
          
        end
   
        function obj =      performMovieTrackingMethod(obj, Name, varargin)
             % PERFORMMOVIETRACKINGMETHOD allows execution of method from LoadedMovie object;
             % takes 1 to multiple arguments
             % 1: name of method ('char')
             % 2: multiple aditional arguments, as required by method;
             obj.LoadedMovie = obj.LoadedMovie.(Name)(varargin{:});
             
         end
        
    end
    
    methods % GETTERS LOADEDMOVIE
        
          function movie =    getLoadedMovie(obj)
             % GETLOADEDMOVIE returns loaded movie;
            movie = obj.LoadedMovie;
          end
       
    end
       
    methods % SETTERS MOUSE ACTION

        function obj = mouseButtonPressed(obj, PressedKey, Modifier) 
            % MOUSEBUTTONPRESSED manage response to mouse button pressed;
            % takes two arguments:
            % 1: current key
            % 2: current modifier
             mouseController =      PMMovieController_MouseAction(obj, PressedKey, Modifier);
             obj =                  mouseController.mouseButtonPressed;
        end

        function obj = mouseMoved(obj, PressedKey, Modifier)   
           % MOUSEMOVED manage response to mouse movement;
            % takes two arguments:
            % 1: current key
            % 2: current modifier
            if strcmp(obj.getMouseAction, 'No action')
            else
                   mouseController =      PMMovieController_MouseAction(obj, PressedKey, Modifier);   
                    obj =                  mouseController.mouseMoved;
            end
        end

        function obj = mouseButtonReleased(obj, PressedKey, Modifier)    
            % MOUSEBUTTONRELEASED manage response to mouse button release;
            % takes two arguments:
            % 1: current key
            % 2: current modifier
             mouseController =      PMMovieController_MouseAction(obj, PressedKey, Modifier);
             obj =                  mouseController.mouseButtonReleased;
        end
        
         function obj =      setCurrentDownPositions(obj)
             % SETCURRENTDOWNPOSITIONS stores mouse position for mouse button press;
            obj =       obj.setMouseDownRow(obj.getViews.getMovieAxes.CurrentPoint(1,2));
            obj =       obj.setMouseDownColumn(obj.getViews.getMovieAxes.CurrentPoint(1,1)); 
         end
        
          function obj = setMouseEndPosition(obj)
               % SETMOUSEENDPOSITION stores mouse position for mouse buttone release;
                if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                    obj =          obj.setMouseUpRow(obj.getCurrentMouseRow);
                    obj =          obj.setMouseUpColumn(obj.getCurrentMouseColumn);
                end
          end
        

        function obj =      blackOutMousePositions(obj)
            % BLACKOUTMOUSEPOSITIONS sets all mouse positions to NaN
            obj =       obj.blackOutStartMousePosition;
            obj =       obj.setMouseUpRow(NaN);
            obj =       obj.setMouseUpColumn(NaN); 
        end

        function obj =      blackOutStartMousePosition(obj)
             % BLACKOUTSTARTMOUSEPOSITION sets mouse press position to NaN;
            obj =     obj.setMouseDownRow(NaN);
            obj =     obj.setMouseDownColumn(NaN);
        end
        
      
       
        
        
     
        
         
        
            

    end
    
    methods % GETTERS MOUSE ACTION

      function [Category] =                         interpretMouseMovement(obj)
          % INTERPRETMOUSEMOVEMENT returns general description of current mouse action;
          % following returns possible: 'Invalid', 'Stay', 'Movement', 'Out of bounds', 'NoActiveView';

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


    end
  
    methods % SETTERS KEY CALLBACKS

        function obj =      setKeyAndMouseCallbacks(obj)
            % SETKEYANDMOUSECALLBACKS MovieController sets "own" callbacks;
            % alternativ: call from outside "interpretKey" and enter pressed key and modifier;
            obj.Views = obj.Views.setKeyMouseCallbacks(...
                @obj.keyPressed, ...
                @obj.myMouseButtonWasJustPressed, ...
                @obj.myMouseButtonWasJustReleased, ...
                @obj.myMouseJustMoved);

        end

        function obj =      keyPressed(obj,~,~)

            obj.interpretKey(obj.Views.getPressedKey, obj.Views.getRawModifier);
            obj.Views =     obj.Views.setCurrentCharacter('0');

        end
        
        function obj =      interpretKey(obj, PressedKey, CurrentModifier)
            % INTERPRETKEY actually performs action based on input
            % takes two arguments:
            % 1: key-code
            % 2: modifier code
               
             obj =              obj.updateLoadedImageVolumes; % is this necessary?
             
                obj.PressedKeyValue =           PressedKey;  
                obj =                       PMMovieController_Keypress(obj).processKeyInput(...
                                                        obj.PressedKeyValue, ...
                                                        CurrentModifier...
                                                        );
                obj.PressedKeyValue = '';
         end
      
       end
    
    methods % SETTERS CHANNELS

        function obj = setChannels(obj, Value)
            % SETCHANNELS set channel properties of LoadedMovie
            % takes 1 argument:
            % 1: either 'PMMovieTracking' (will then use its Channels-property to set Channels;
            %  alternative 'char': currently no option offered;
            
            Type = class(Value);
            switch Type
                case 'PMMovieTracking'
                    obj.LoadedMovie = obj.LoadedMovie.setChannels(Value);

                case 'char'
                    switch  Value
                       
                        otherwise
                            error('Wrong input.')
                    end
                otherwise
                    error('Wrong input.')

            end

        end
        
        function obj = setActiveChannel(obj, Value)
            % SETACTIVECHANNEL sets index of active channel
            % takes 1 argument
            obj.LoadedMovie =        obj.LoadedMovie.setActiveChannel(Value);
            
        end
        
        function obj = resetChannelSettings(obj, Value, Type)
            % RESETCHANNELSETTINGS allows setting of various Channel properties (of LoadedMovie property);
            % takes 2 arguments:
            % 1: value of property
            % 2; property name
             obj.LoadedMovie =       obj.LoadedMovie.resetChannelSettings(Value, Type);
            
        end
        
        function obj = setVisibilityOfChannels(obj, Value)
            % SETVISIBILITYOFCHANNELS sets visibility of channels
            % takes 1 argument:
            % 1: logical vector with wanted visibility for each channel

            assert(islogical(Value) && isvector(Value) && length(Value) == obj.LoadedMovie.getMaxChannel, 'Wrong input')
            for index = 1 : length(Value)
                obj.LoadedMovie =        obj.LoadedMovie.setVisibleOfChannelIndex(index, Value(index));    
            end

        end

        function obj = toggleVisibilityOfChannelIndex(obj, Index)
            % TOGGLEVISIBILITYOFCHANNELINDEX toggles visibility of channel for index;
            % takes 1 argument:
            % 1: number of channel number that should be toggled;
              if Index <= obj.LoadedMovie.getMaxChannel
                    obj.LoadedMovie =        obj.LoadedMovie.setVisibleOfChannelIndex(Index,   ~obj.LoadedMovie.getVisibleOfChannelIndex(Index));    
                    obj.LoadedMovie =        obj.LoadedMovie.setActiveChannel(Index);
                    obj =                    obj.updateControlElements;
                    obj =                    obj.updateMovieView;

               end

        end

       


    end

    methods % SETTERS DRIFTCORRECTION
        
        function obj = setDriftCorrection(obj, Value, varargin)
            % SETDRIFTCORRECTION sets drift correction
            % takes 1 argument:
            % 1: 'char':
            %       'Manual': adds current mouse position to drift-correction: 'currentFrameByButtonPress' or 'currentAndConsecutiveFramesByButtonPress';
            %       'remove':
            %       'byManualEntries':
            
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
       
    methods % SETTERS CROPPING
         
        function obj =          setCroppingGate(obj, Rectangle)
                % SETCROPPINGGATE allows setting the position of the cropping gate;
                assert(isnumeric(Rectangle) && isvector(Rectangle) && length(Rectangle) == 4, 'Wrong input.')
                obj.LoadedMovie =   obj.LoadedMovie.setCroppingGateWithRectange(Rectangle);
                obj =               obj.setCroppingRectangleView;
          end
          
        function obj =          setDefaultCroppingGate(obj)
                % SETDEFAULTCROPPINGGATE sets cropping gate to the entire image range;
                obj.LoadedMovie =       obj.LoadedMovie.resetCroppingGate;
                obj =                   obj.setCroppingRectangleView;
         end
            
        function obj =          setActiveCropOfMovieView(obj)
            % SETACTIVECROPOFMOVIEVIEW sets rectangle and axes view by current crop settings of LoadedMovie;
            obj =               obj.setCroppingRectangleView;
            obj.Views =         obj.Views.setLimitsOfMovieViewWith(obj.LoadedMovie);
        end
                
    end
   
    methods % AUTOCELLRECOGNITION
        
        function obj =      showAutoCellRecognitionWindow(obj)
            % SHOWAUTOCELLRECOGNITIONWINDOW makes auto cell recognition visible;
            % via the window it is possible to modifiy settings for auto-cell recognition;

            if isempty(obj.LoadedMovie)

            else
                myModel =                                   PMAutoCellRecognition(obj.getLoadedImageVolumes, find(obj.LoadedMovie.getActiveChannelIndex));
                obj.AutoCellRecognitionController =         PMAutoCellRecognitionController(myModel);   

                obj.AutoCellRecognitionController =         obj.AutoCellRecognitionController.setCallBacks(...
                                                            @obj.AutoCellRecognitionChannelChanged, ...
                                                            @obj.AutoCellRecognitionFramesChanged, ...
                                                            @obj.AutoCellRecognitionTableChanged, ...
                                                            @obj.startAutoCellRecognitionPushed, ...
                                                            @obj.changeOfAutoCellRecognitionView, ...
                                                            @obj.changeOfAutoCellRecognitionView...
                                                            );

            end

        end

        
       

    end
    
    methods % SETTERS AUTOTRACKING

        function obj = trackGapsForAllTracks(obj, Value)
            % TRACKGAPSFORALLTRACKS for all tracks: identify gaps and fill out the gaps by tracking in between;
            % takes 1 argument:
            % 1: number of frames to define gaps of interest
            [Gaps, TrackIds] =     obj.(['getLimitsOfUnfinished', Value, 'Gaps']);
            for TrackIndex = 1 : length(TrackIds)
                [StartFrames, EndFrames]=   obj.(['get', Value, 'TrackingFramesFromGapLimits'])(Gaps{TrackIndex});
                if ~isnan(StartFrames)
                    obj =                   obj.setActiveTrackTo(TrackIds(TrackIndex)); 
                    obj.LoadedMovie =       obj.LoadedMovie.setFrameTo(StartFrames(1)); 
                    obj =                   obj.focusOnActiveMask;
                    obj =                   obj.autoTrackActiveCellByEdgeForFrames(StartFrames, EndFrames);
                end
            end
            obj =           obj.saveMovie;
        end
    
    end
      
    methods (Access = private) % GETTERS VIEWS
       
        function view = getViews(obj)
             
             if isempty(obj.Views)
                  view = obj.Views; 
             elseif ~isvalid(obj.Views.getMovieView.getAxes)
                 view = '';
             else
                 view = obj.Views; 
             end
         
             
           
         end
        
    end
    
    methods (Access  = private) % GETTERS INTERACTION IMAGES
       
        function image = getInteractionImage(obj)
            % GETINTERACTIONIMAGE 
            % returns processed "interaction image";
            % thresholded image that contains all "target pixels" for interaction analysis;
            
             if ~obj.ShowInteractionsImageVolume
                 ThresholdedImage = '';
                 image = ThresholdedImage;
                 
             else
                MyInteractionsCapture =         obj.LoadedMovie.getInteractions;
                MyInteractionsCapture =         MyInteractionsCapture.setMovieController(obj);
                ThresholdedImage =              MyInteractionsCapture.getImageVolume * 150;
                filtered =                      obj.LoadedMovie.filterImageVolumeByActivePlanes(ThresholdedImage);
                image =                         max(filtered, [], 3);
                    
             end
                 
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
  
    methods (Access = private) % SETERS SOURCE IMAGES
        
        function obj =     updateLoadedImageVolumes(obj)
            % UPDATELOADEDIMAGEVOLUMES for all "empty" frames that are "needed", load image from file;

            if isempty(obj.getFramesThatNeedToBeLoaded)

            else
                obj.LoadedImageVolumes(obj.getFramesThatNeedToBeLoaded,1 ) = obj.LoadedMovie.loadImageVolumesForFrames(obj.getFramesThatNeedToBeLoaded);
            end

            obj = obj.activateViews;

        end

        function obj =             resetLoadedImageVolumesIfInvalid(obj)
              % RESETLOADEDIMAGEVOLUMESIFINVALID sets LoadedImageVolumes to
              % the rigth format, if invalid;
              % this should not be necessary if the setters work correctly
            if ~iscell(obj.LoadedImageVolumes) || length(obj.LoadedImageVolumes) ~= obj.LoadedMovie.getMaxFrame
               obj.LoadedImageVolumes =                            cell(obj.LoadedMovie.getMaxFrame,1);
            end
        end
        
        
        
        
        
    end
    
    methods (Access = private) % SETTERS SOURCE IMAGES
       
          function requiredFrames =  getFramesThatNeedToBeLoaded(obj)
            obj =                                       obj.resetLoadedImageVolumesIfInvalid;
            requiredFrames =                            obj.getFrameNumbersThatMustBeInMemory;
            alreadyLoadedFrames =                       obj.getFramesThatAreAlreadyInMemory;

            requiredFrames(alreadyLoadedFrames,1) =     false;
            requiredFrames = find(requiredFrames);

        end

        function requiredFrames =  getFrameNumbersThatMustBeInMemory(obj)
            requiredFrames(1: obj.LoadedMovie.getMaxFrame, 1) = false;
            range =                 obj.LoadedMovie.getActiveFrames - obj.getLimitForLoadingFrames : obj.LoadedMovie.getActiveFrames + obj.getLimitForLoadingFrames;
            range(range<=0) =       [];
            range(range > obj.LoadedMovie.getMaxFrame) =       [];
            requiredFrames(range,1) =                                     true;
        end

        function frames =          getLimitForLoadingFrames(obj)  
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

        
        
    end

    methods (Access = private) % track line views
        
          
     
          
            
            function obj = tracking_addSelectedTracks(obj, Value)
                Type = class(Value);
                switch Type
                    case 'char'
                        switch Value
                            case 'byMousePosition' 
                                    obj =         obj.addToSelectedTracksTrackIDs(obj.LoadedMovie.getTrackIDClosestToPosition(obj.MouseUpColumn, obj.MouseUpRow));
                            
                            otherwise
                                error('Input not supported.')
                        end
                        
                       
                    otherwise
                        
                        error('Wrong input.')
                
                end
                
                
            end
            
             
             
        
        
     end
    
    methods (Access = private) % setters FRAME
        
        function obj = setFrameByNumber(obj, newFrame)

                if isnan(newFrame) || newFrame<1 || newFrame>obj.LoadedMovie.getMaxFrame
                else
                    
                    
                    if isempty(obj.Views) ||  ~isvalid(obj.Views.getFigure)
                         obj.LoadedMovie =           obj.LoadedMovie.setFrameTo(newFrame);
                        
                    else 
                        
                        switch obj.Views.getModifier
                            case 'shift'
                                obj.LoadedMovie =                   obj.LoadedMovie.setFrameTo(newFrame); 
                                obj =               obj.focusOnActiveMask;

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
                    obj =   obj.gotToFirstTrackedFrameFromCurrentPoint;
                    
                case 'lastFrameOfCurrentTrackStretch'
                    obj = obj.goToLastContiguouslyTrackedFrameInActiveTrack;
                    
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
                obj =           obj.updateAllViewsThatDependOnActiveTrack;

          end
          
        
        
    end
    
    methods (Access = private) % track manipulation
        
        function obj =         connectSelectedTrackToActiveTrack(obj)
            % not sure if this is helpful:
            IDOfTrackToMerge =  obj.LoadedMovie.getTrackIDClosestToPosition(obj.MouseUpColumn, obj.MouseUpRow);
            obj.LoadedMovie =   obj.LoadedMovie.mergeActiveTrackWithTrack(IDOfTrackToMerge);
            obj =               obj.updateMovieView;
        end
          
        
       
        
        
        
        
    

        

        function [Gaps, TrackIDs] = getLimitsOfUnfinishedTracks(obj)
            TrackIDs =             obj.LoadedMovie.getUnfinishedTrackIDs;

        end
        
    


      

        
      
        
        
        
    end
    
    methods (Access = private) % getter reference PMSegmentationCapture
       
          function SegementationOfReference = getReferenceSegmentation(obj)
                SegementationOfReference =      PMSegmentationCapture(obj, obj.LoadedMovie.getActiveChannelIndex);
                SegementationOfReference =      obj.applyStandardValuesToSegmentation(SegementationOfReference);      
          end
          
          function SegementationOfReference = applyStandardValuesToSegmentation(~, SegementationOfReference)
                SegementationOfReference =  SegementationOfReference.setPixelShiftForEdgeDetection(1);
                SegementationOfReference =  SegementationOfReference.setAllowedExcessSizeFactor(1.3);
                SegementationOfReference =  SegementationOfReference.setMaximumCellRadius(7);
                SegementationOfReference =  SegementationOfReference.setMaximumDisplacement(15);
                SegementationOfReference =  SegementationOfReference.setFactorForThreshold(1);
                
          end

    end
     
    methods (Access = private) % CROP
        
       function obj = setCroppingGateByString(obj, Value)
            assert(ischar(Value), 'Wrong input.')
            switch Value
             case 'changePositionByMouseDrag'
                obj =       obj.setCroppingGateByMouseDrag;
              case 'changeToDefault'
                  obj =     obj.setDefaultCroppingGate;
              otherwise
                  error('Wrong input.')
            end
       end
        
        function obj = setCroppingGateByMouseDrag(obj)
            obj = obj.setCroppingGate(obj.getRectangleFromMouseDrag);
        end
        
        function SpaceCoordinates =           getCoordinateListByMousePositions(obj)
            myRectangle =               PMRectangle(obj.getRectangleFromMouseDrag);
            Coordinates_2D =            myRectangle.get2DCoordinatesConfinedByRectangle;

            [ ~, ~,  planeWithoutDrift, ~ ] =    obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
            zListToAdd =                (linspace(planeWithoutDrift, planeWithoutDrift, length(Coordinates_2D(:, 1))))';

            SpaceCoordinates =          [Coordinates_2D, zListToAdd];

        end

        function [Rectangle] =                 getRectangleFromMouseDrag(obj)
            [ startrow, startcolumn,  ~, ~ ] =   obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
            [ endrow, endcolumn,  ~, ~ ] =       obj.LoadedMovie.getCoordinatesForPosition(obj.MouseUpColumn, obj.MouseUpRow);
            Rectangle =                         [startcolumn, startrow, endcolumn - startcolumn, endrow - startrow];
        end

       

    
   
     
        
        function obj =          setCroppingRectangleView(obj)
            if ~isempty(obj.Views)  && isvalid(getFigure(obj.Views))
                obj.Views =        setRectangleWith(obj.Views, obj.LoadedMovie);
            end
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
                   [rowFinal, columnFinal, planeFinal, frame] =     obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
                   obj =               obj.setManualDriftCorrectionByTimeSpaceCoordinates(frame, columnFinal, rowFinal,  planeFinal );

                case 'currentAndConsecutiveFramesByButtonPress'
                       [rowFinal, columnFinal, planeFinal, frame] =     obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
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
    
    methods (Access = private) % movie view
        
        function rgbImage =     addMasksToImage(obj, rgbImage)
            
            ColorOfSelectedTracks =     obj.getColorOfSelectedMasksForImage(rgbImage);
            MyFrame =                   obj.LoadedMovie.getActiveFrames;
            MyPlanes =                  obj.LoadedMovie.getPlanesThatAreVisibleForSegmentation;
            MyDriftCorrection =         obj.LoadedMovie.getDriftCorrection;

            MasksSelected =             obj.LoadedMovie.getTracking.getSelectedMasksAtFramePlaneDrift(MyFrame, MyPlanes, MyDriftCorrection);
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, MasksSelected, 1, ColorOfSelectedTracks(1));
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, MasksSelected, 2, ColorOfSelectedTracks(2));
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, MasksSelected, 3, ColorOfSelectedTracks(3));

            ActiveMask =                obj.LoadedMovie.getTracking.getActiveMasksAtFramePlaneDrift(MyFrame, MyPlanes, MyDriftCorrection);
            Intensity =                 obj.getColorOfActiveMaskForImage(rgbImage);
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, ActiveMask, 1:3, Intensity);

        end

        function MaskColor =    getColorOfSelectedMasksForImage(obj, rgbImage)
            MaskColor(1) =          obj.MaskColor(1);
            MaskColor(2) =          obj.MaskColor(2);
            MaskColor(3) =          obj.MaskColor(3);

            if strcmp(class(rgbImage), 'uint16')
                MaskColor(1) =          MaskColor(1) * 255;
                MaskColor(2) =          MaskColor(2) * 255;
                MaskColor(3) =          MaskColor(3) * 255;
            end
        end

        function Intensity =    getColorOfActiveMaskForImage(~, rgbImage)
            Intensity =    255;
            switch(class(rgbImage))
                case 'uint8'
                case 'uint16'
                    Intensity = Intensity * 255;        
                otherwise
                    error('Input not supported.')
            end
        end

        function rgbImage =     highlightPixelsInRgbImage(~, rgbImage, CoordinateList, Channel, Intensity)

             if isempty(CoordinateList)

             else
                 
                assert(isnumeric(CoordinateList) && ismatrix(CoordinateList) && size(CoordinateList, 2) >=2, 'Wrong input.')    
                 CoordinateList(isnan(CoordinateList(:,1)),:) = []; % this should not be necessary if everything works as expected;
                 NumberOfPixels =                        size(CoordinateList,1);
                if ~isnan(Intensity)
                    for CurrentPixel =  1:NumberOfPixels
                        rgbImage(CoordinateList(CurrentPixel, 1), CoordinateList(CurrentPixel, 2), Channel)= Intensity;
                    end
                end

             end

        end
   
    end
    
    methods (Access = private) % SETTERS trakcking_- functions
          
        function [obj] =     tracking_removeHighlightedPixelsFromActiveMask(obj)             
            [UserSelectedY, UserSelectedX] =    obj.findUserEnteredCoordinatesFromImage;
            pixelListWithoutSelected =          obj.LoadedMovie.getPixelsFromActiveMaskAfterRemovalOf([UserSelectedY, UserSelectedX]);
            obj.LoadedMovie =                   obj.LoadedMovie.resetActivePixelListWith(PMSegmentationCapture(pixelListWithoutSelected, 'Manual'));
            obj =                               obj.updateAllViewsThatDependOnActiveTrack;
        end

        function obj =       tracking_removePixelRimFromActiveMask(obj)
            mySegmentationObject =     PMSegmentationCapture(obj);
            mySegmentationObject =     mySegmentationObject.removeRimFromActiveMask;
            obj.LoadedMovie =          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
            obj =                      obj.updateAllViewsThatDependOnActiveTrack;
        end

        function obj =      tracking_deleteSelectedTracks(obj)
            obj.LoadedMovie =          obj.LoadedMovie.deleteSelectedTracks;
            obj =                      obj.updateAllViewsThatDependOnActiveTrack;
        end

        function obj =      tracking_deleteActiveTrack(obj)
            obj.LoadedMovie =     obj.LoadedMovie.deleteActiveTrack;
            obj =                 obj.updateAllViewsThatDependOnActiveTrack;

        end

        function [obj] =    tracking_deleteAllTracks(obj)
            obj.LoadedMovie =     obj.LoadedMovie.deleteAllTracks;
            obj =                 obj.setActiveTrackTo(NaN)   ; 
            obj =                 obj.updateAllViewsThatDependOnActiveTrack;

        end

        function obj =      tracking_deleteActiveMask(obj)
            obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('deleteActiveMask');
            obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        function obj =      tracking_splitSelectedTrack(obj)
            obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('splitSelectedTrackAtActiveFrame');
            obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        function obj =      tracking_mergeSelectedTracks(obj)
            try
                obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('mergeSelectedTracks');
                obj =                   obj.updateAllViewsThatDependOnActiveTrack;
            catch ME
                throw(ME)
            end  

        end

        function obj =      tracking_fillGapsOfActiveTrack(obj)
            try
                obj.LoadedMovie =       obj.LoadedMovie.performTrackingMethod('fillGapsOfActiveTrack');
                obj =                   obj.updateAllViewsThatDependOnActiveTrack;
            catch ME
                throw(ME)
            end
        end

        function obj =      tracking_addButtonClickMaskToNewTrack(obj)
            obj.LoadedMovie =     obj.LoadedMovie.setActiveTrackToNewTrack;
            obj =                 obj.tracking_updateActiveMaskByButtonClick;
        end
        
        function obj =      tracking_updateActiveMaskByButtonClick(obj)
                  % UPDATEACTIVEMASKBYBUTTONCLICK: create mask of active track based on mouse click;
                  % mouse click selecs pixel that serves as threshold for detecting mask;
                  % mask is stored in PMMovieTracking and views are updated;

                [rowPos, columnPos, planePos, ~] =   obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
                if ~isnan(rowPos)

                    obj =                       obj.highlightMousePositionInImage;
                    
                    mySegmentationObject =      obj.getReferenceSegmentation;
                    mySegmentationObject =      mySegmentationObject.setShowSegmentationProgress(true);
                    mySegmentationObject =      mySegmentationObject.resetWithMovieController(obj);
                    mySegmentationObject =      mySegmentationObject.setActiveCoordinateBy(rowPos, columnPos, planePos);
                    
                    try 
                        mySegmentationObject =      mySegmentationObject.generateMaskByClickingThreshold;
                    catch E
                        throw(E) 
                    end

                    if mySegmentationObject.getActiveShape.testShapeValidity
                        obj.LoadedMovie =   obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);  
                        obj =               obj.updateAllViewsThatDependOnActiveTrack;
                        obj =               obj.updateAllViewsThatDependOnActiveTrack;

                    else
                        fprintf('Button click did not lead to recognition of valid cell. No action taken.')
                    end


                end

                figure(obj.Views.getFigure)

        end
          
        function obj =      highlightMousePositionInImage(obj)

            [rowPos, columnPos, ~, ~] =   obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
            OldImage =                              obj.Views.getMovieImage.CData;
            OldImage(rowPos, columnPos,:) =         255;
            obj.Views =                             obj.Views.setMovieImagePixels(OldImage);

        end

        function obj =      tracking_setSelectedTracks(obj, Value)
            Type = class(Value);
            switch Type
                case 'char'
                    switch Value
                        case 'byMousePosition' 
                               
                                TrackIds = obj.LoadedMovie.getTrackIDClosestToPosition(obj.MouseUpColumn, obj.MouseUpRow);
                                  obj.LoadedMovie =           obj.LoadedMovie.setSelectedTrackIdsTo(TrackIds);
                                  
                obj =                       obj.updateAllViewsThatDependOnActiveTrack;
                
                        case 'all'
                                obj.LoadedMovie =         obj.LoadedMovie.selectAllTracks;
                                obj =                    obj.updateAllViewsThatDependOnSelectedTracks;
                                     obj =                               obj.updateAllViewsThatDependOnActiveTrack;
                        otherwise
                            error('Input not supported.')
                    end

                case 'double'

                otherwise

                    error('Wrong input.')

            end


        end

        function obj =      tracking_setLoadedMovie(obj)
            [ ~, ~,  z, ~ ] =    obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
            [y, x] =             obj.findUserEnteredCoordinatesFromImage;
            obj.LoadedMovie =     obj.LoadedMovie.updateMaskOfActiveTrackByAdding(y, x, z);
            obj =                 obj.updateAllViewsThatDependOnActiveTrack;

        end

        function [y, x] =   findUserEnteredCoordinatesFromImage(obj)
            Coordinates =     obj.getCoordinateListByMousePositions;

            RectangleImage(min(Coordinates(:, 2)): max(Coordinates(:, 2)), min(Coordinates(:, 1)): max(Coordinates(:, 1))) = 1;
            [y, x] = find(RectangleImage);


        end

        function obj =      tracking_usePressedCentroidAsMask(obj)
            [rowFinal, columnFinal, planeFinal, ~] =   obj.LoadedMovie.getCoordinatesForPosition(obj.MouseDownColumn, obj.MouseDownRow);
            if ~isnan(rowFinal)
                  mySegmentationObject =    PMSegmentationCapture(obj, [rowFinal, columnFinal, planeFinal]);
                  mySegmentationObject =    mySegmentationObject.setSegmentationType('MouseClick');
                  obj.LoadedMovie =         obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                  obj =                     obj.updateAllViewsThatDependOnActiveTrack;
            end

        end

        function obj =      tracking_addPixelRimToActiveMask(obj)
            mySegmentationObject =     PMSegmentationCapture(obj).addRimToActiveMask;
            obj.LoadedMovie =          obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
            obj =                      obj.updateAllViewsThatDependOnActiveTrack;    
        end

        function obj =      tracking_autoTracking(obj, varargin)
            if length(varargin) == 2
                obj = obj.performAutoTracking(varargin{1}, varargin{2});

            else
                error('Input not supported')

            end



        end

      
    end
    
    methods (Access = private) % execute TRACKING: SPLIT and DELETE
        
        function obj =      tracking_splitTrackAfterActiveFrame(obj)
            obj.LoadedMovie =       obj.LoadedMovie.splitTrackAfterActiveFrame;
            obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        function obj =    tracking_splitTrackAtFrameAndDeleteFirstPart(obj)
            obj.LoadedMovie =       obj.LoadedMovie.deleteActiveTrackBeforeActiveFrame;
             obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        function obj =    tracking_splitSelectedTracksAndDeleteSecondPart(obj) 
            obj.LoadedMovie =   obj.LoadedMovie.deleteActiveTrackAfterActiveFrame;
            obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        
    end
    
    methods (Access = private) %% performAutoTracking:
       
        function obj =      performAutoTracking(obj, varargin)

            if length(varargin) == 2

                switch varargin{1}

                    case 'activeTrack'
                        switch varargin{2}
                            case 'forwardInFirstGap'
                                obj =       obj.autoForwardTrackingOfActiveTrack;
                            case 'backwardInLastGap'
                                obj =       obj.autoBackwardTrackingOfActiveTrack;
                            case 'convertAllMasksToMiniMasks'
                                obj =       obj.minimizeMasksOfCurrentTrack;
                            case 'convertAllMasksByCurrentSettings'
                                obj =       obj.recreateMasksOfCurrentTrack;

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
                                obj =       obj.autoDetectMasksByCircleRecognition;
                            case 'thresholdingInBrightAreas'
                                obj =      obj.autoDetectMasksOfCurrentFrame;
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

        function obj =      autoBackwardTrackingOfActiveTrack(obj)
            %  autoBackwardTrackingOfActiveTrack: backward tracking of active track;
            % tracks from already tracked start mask that is used as a reference for all untracked frames until tracked frame is hit;
            GapFrames =   obj.LoadedMovie.getGapFrames('backward');
            try
                obj =         obj.autoTrackActiveCellByEdgeForFrames(GapFrames + 1, GapFrames);  
            catch E
                throw(E)
            end
        end

        function obj =      autoForwardTrackingOfActiveTrack(obj)
            %  AUTOFORWARDTRACKINGOFACTIVETRACK: forward tracking of active track;
            % tracks from already tracked start mask that is used as a reference for all untracked frames until tracked frame is hit;
            GapFrames =      obj.LoadedMovie.getGapFrames('forward');
            if isempty(GapFrames)
                warning('No gap found. Therefore no autotracking. You have to find a gap before autotracking is allowed.')
            else
                obj =            obj.autoTrackActiveCellByEdgeForFrames(GapFrames - 1, GapFrames );  
            end
        end

        function obj =      autoTrackingWhenNoMaskInNextFrame(obj)

            TrackingFrames =     obj.LoadedMovie.getActiveFrames : obj.LoadedMovie.getMaxFrame - 1;
            for TrackID = (obj.LoadedMovie.getTrackIDsWhereNextFrameHasNoMask)'
                obj =                obj.setFrameByNumber(min(TrackingFrames));  
                obj          =       obj.setActiveTrackTo(TrackID);  
                drawnow
                obj =                obj.autoTrackActiveCellByEdgeForFrames(TrackingFrames, TrackingFrames + 1);   
            end

            obj =              obj.saveMovie;

        end

  
        function obj =      minimizeMasksOfCurrentTrack(obj)
            obj =                   obj.minimizeMasksOfCurrentTrackForFrames(obj.getFollowingFramesOfCurrentTrack); 
        end

        function obj =      minimizeMasksOfCurrentTrackForFrames(obj, SourceFrames)

            for FrameIndex = 1:length(SourceFrames)
                    obj =                   obj.setFrameByNumber(SourceFrames(FrameIndex));
                    obj.LoadedMovie =       obj.LoadedMovie.minimizeMasksOfActiveTrackAtFrame(FrameIndex);
                    obj =                   obj.setActiveCropOfMovieView;
                    obj =                   obj.updateAllViewsThatDependOnActiveTrack;

                drawnow  

            end

        end

        function obj =      recreateMasksOfCurrentTrack(obj)
                obj =             obj.recreateMasksOfCurrentTrackForFrames(obj.getFollowingFramesOfCurrentTrack);
        end

        function obj =      addToSelectedTracksTrackIDs(obj, TracksToAdd)
        obj.LoadedMovie =       obj.LoadedMovie.addToSelectedTrackIds(TracksToAdd);
        obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end

        function  obj =     recreateMasksOfCurrentTrackForFrames(obj, SourceFrames)

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
                SegmentationForCurrentMask =        obj.getSegmentationByEdgeWithMaxSize;
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

        function XYDistance = getXYDistanceBetween(~, SegmentationForPreviousMask, SegmentationForCurrentMask)
            XYDistance = max([abs(SegmentationForPreviousMask.getXCentroid- SegmentationForCurrentMask.getXCentroid)], [abs(SegmentationForPreviousMask.getYCentroid - SegmentationForCurrentMask.getYCentroid)]);
            fprintf('XY distance %6.2.\n', XYDistance)
        end

        function ZDistance = getZDistanceBetween(~, SegmentationForPreviousMask, SegmentationForCurrentMask)
            ZDistance = abs(SegmentationForPreviousMask.getZCentroid- SegmentationForCurrentMask.getZCentroid);
            fprintf('Z distance %6.2.\n', ZDistance)
        end

        function SegmentationForCurrentMask = getSegmentationByEdgeWithMaxSize(obj)
            SegmentationForCurrentMask =    PMSegmentationCapture(obj);
            SegmentationForCurrentMask =    SegmentationForCurrentMask.generateMaskByEdgeDetectionForceSizeBelowMaxSize;
            fprintf('New X= %6.2f. New Y= %6.2f.\n', SegmentationForCurrentMask.getXCentroid, SegmentationForCurrentMask.getYCentroid)
            fprintf('%i pixels.\n', SegmentationForCurrentMask.getNumberOfPixels)
        end

        function obj =      updateHandlesForTrackingNavigationEditView(obj)

            obj.TrackingNavigationEditViewController = obj.TrackingNavigationEditViewController.setCallbacks(...
                    @obj.respondToTrackTableActivity, @obj.respondToActiveFrameClicked, ...
                    @obj.respondToActiveTrackSelectionClicked, @obj.respondToActiveTrackActivity, ...
                    @obj.respondToEditSelectedTrackSelectionClicked, @obj.respondToSelectedTrackActivity ...
                    );
        end

        function obj =      respondToTrackTableActivity(obj,~,a)
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
                        
                         
                                  obj.LoadedMovie =           obj.LoadedMovie.setSelectedTrackIdsTo(MySelectedTrackIds);
                obj =                       obj.updateAllViewsThatDependOnActiveTrack;
                
                
                    case {'s','S'}
                        obj =         obj.addToSelectedTracksTrackIDs(MySelectedTrackIds);
            end





        end

        function obj =      respondToActiveFrameClicked(obj,~,~)
            newFrame =        str2double(obj.TrackingNavigationEditViewController.getSelectedFrame);
             obj  =           obj.setFrameByNumber(newFrame);
        end

        function obj =      respondToEditSelectedTrackSelectionClicked(obj,~,~)

        end

        function obj =      respondToSelectedTrackActivity(obj,~,~)
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

        function obj =      respondToActiveTrackSelectionClicked(obj,~,~)

        end

        function obj =      respondToActiveTrackActivity(obj,~,~)

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

      
    end
    
    methods (Access = private) % autotracking by edge detection

        function obj =                                          autoTrackActiveCellByEdgeForFrames(obj, SourceFrames, TargetFrames)

            obj.LoadedMovie =                   obj.LoadedMovie.setPreventDoubleTracking(true, 2);

            StopObject =                        obj.createStopButtonForAutoTracking;
            obj.PressedKeyValue =               'a';

            obj =                               obj.setFrameByNumber(SourceFrames(1)); 
            SegementationOfReference =          obj.getReferenceSegmentation;

            for FrameIndex = 1 : length(SourceFrames)

                try
                    [~, SegementationObjOfTargetFrame] =         obj.trackActiveTrackBetweenFrameByEdge(SourceFrames(FrameIndex), TargetFrames(FrameIndex), SegementationOfReference);
                catch E
                    Text = [E.message, 'Current track terminated.'];
                    warning(Text)
                    break

                end

                try
                    obj.LoadedMovie =    obj.LoadedMovie.resetActivePixelListWith(SegementationObjOfTargetFrame);
                    fprintf('New mask added.\n');

                catch E
                    Text = [E.message, 'Current track terminated.'];
                    warning(Text)
                    break

                end
                
                obj.LoadedMovie =  obj.LoadedMovie.setPreventDoubleTracking(false, 2);

            end

            obj.PressedKeyValue  =          '';
            delete(StopObject.ParentFigure)

            obj =                               obj.updateAllViewsThatDependOnActiveTrack;
        end

        function [SourceSegmentation,TargetSegmentation] =      trackActiveTrackBetweenFrameByEdge(obj, sourceFrameNumber, targetFrameNumber, SegementationOfReference)

            fprintf('Tracking from frame %i for segmentation of frame %i.\n', sourceFrameNumber, targetFrameNumber)

            obj =                         obj.setFrameByNumber(sourceFrameNumber);
            SourceSegmentation =          PMSegmentationCapture(obj); 
            SourceSegmentation =          obj.applyStandardValuesToSegmentation(SourceSegmentation);

            if isempty(SourceSegmentation.getMaskCoordinateList)
                ME = MException('MATLAB:performTrackingBetweenTwoFramesFailed', 'No source pixels found.');
                    throw(ME)
            else

                obj.LoadedMovie =                   obj.LoadedMovie.setFrameTo(targetFrameNumber); 
                obj =                   obj.focusOnActiveMask;
                TargetSegmentation =    PMSegmentationCapture(obj); 

                TargetSegmentation =    obj.applyStandardValuesToSegmentation(TargetSegmentation);
                TargetSegmentation =    TargetSegmentation.setMaskCoordinateList(SourceSegmentation.getMaskCoordinateList);
                TargetSegmentation =    TargetSegmentation.generateMaskByEdgeDetectionForceSizeBelowMaxSize;

                XYDistance =            obj.getXYDistanceBetween(SourceSegmentation, TargetSegmentation);
                ZDistance =             obj.getZDistanceBetween(SourceSegmentation, TargetSegmentation);

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

        function StopObject =                                   createStopButtonForAutoTracking(obj)
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

    end
    
    methods (Access = private)
        

           

            function frames = getFollowingFramesOfCurrentTrack(obj)
            frames =                obj.LoadedMovie.getTracking.getFrameNumbersForTrackID(obj.LoadedMovie.getIdOfActiveTrack);
            frames(frames < obj.LoadedMovie.getActiveFrames) =     [];
            end


          

            function StartFrames = removeInvalidFrames(obj, StartFrames)
                StartFrames(StartFrames < 0, :) = [];
                StartFrames(StartFrames > obj.LoadedMovie.getMaxFrame, :) = [];
                if isempty(StartFrames)
                   StartFrames = NaN; 
                end
            end

         



          



            %%  mergeTracksByProximity
            function obj = mergeTracksByProximity(obj)
                answer=            inputdlg('How much overlap for track merging? Negative: tracks overlap; Positive gaps');
                obj.LoadedMovie =  obj.LoadedMovie.mergeTracksWithinDistance(round(str2double(answer{1})));   
                obj =              obj.updateAllViewsThatDependOnActiveTrack;
            end


        
           
           
    end
 
    methods (Access = private) % CROPPING VIEWS
        
        
        function obj =          highLightRectanglePixelsByMouse(obj)

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
         
        
         
      
        
        function obj =          resetAxesCenter(obj, xShift, yShift)
            obj.Views = obj.Views.shiftAxes(xShift, yShift);
            
        end
        
        
        
        
    end
    
    methods (Access = private) % views

        function obj =      activateViews(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views = enableAllViews(obj.Views);
             end
        end
        
        function obj =      setDriftCorrectionIndicators(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
            obj.Views =            updateManualDriftIndicatorsWith( obj.Views, obj.LoadedMovie);
             end
        end
         
      
        
        function obj =      setViewsAfterChangeOfMaximumProjection(obj, Value)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                obj.Views =     setShowMaximumProjection(obj.Views, Value);
                obj =               obj.updateMovieView;
                obj =               obj.setNavigationControls;
                obj =               obj.updateAllViewsThatDependOnActiveTrack;
             end
         end

        function obj =      resetViewsForCurrentDriftCorrection(obj)

            obj.Views =     setLimitsOfMovieViewWith(obj.Views, obj.LoadedMovie); % reset applied cropping limit (dependent on drift correction)
            obj.Views =     updateDriftWith(obj.Views, obj.LoadedMovie);
            obj  =          obj.updateControlElements; % plane number may change
            obj =           obj.setCroppingRectangleView;% crop position may change

            obj =           obj.setNavigationControls;
            obj =           obj.updateMovieView;
            obj.Views =     setTrackLineViewsWith(obj.Views, obj.LoadedMovie);   

            obj.Views =    setSelectedCentroidsWith( obj.Views, obj.LoadedMovie);
            obj.Views =     setActiveCentroidWith(obj.Views, obj.LoadedMovie);
        end

        function obj =      updateAllViewsThatDependOnActiveTrack(obj)
            % UPDATEALLVIEWSTHATDEPENDONACTIVETRACK
            % updates track-lines, selected centroids, active centroid, tracking control  panels, movie image (masks);
            
         %    obj.LoadedMovie =   obj.LoadedMovie.setFocusOnActiveTrack; 
             
             if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                obj =                                           obj.updateAllViewsThatDependOnSelectedTracks;
                obj =                                           obj.setActiveCropOfMovieView;
                
                obj.TrackingNavigationEditViewController =      obj.TrackingNavigationEditViewController.resetForActiveTrackWith(obj.LoadedMovie.getTracking);

                
             end

        end

        function obj =      updateAllViewsThatDependOnSelectedTracks(obj)

        %   obj.LoadedMovie = obj.LoadedMovie.generalCleanup;

            obj.Views =         setSelectedCentroidsWith(obj.Views, obj.LoadedMovie);
            obj.Views =         setActiveCentroidWith(obj.Views, obj.LoadedMovie);

             obj.Views =        setTrackLineViewsWith(obj.Views, obj.LoadedMovie); 
            
            obj.Views =         setTrackingViewsWith(obj.Views, obj.LoadedMovie);
            obj =               obj.updateMovieViewImage;

            obj.TrackingNavigationEditViewController =     obj.TrackingNavigationEditViewController.resetModelWith(obj.LoadedMovie.getTracking);

        end

      

        function obj =      updateControlElements(obj)
             if ~isempty(obj.Views) && isvalid(getFigure(obj.Views))
                    obj.Views  =    setControlElements(...
                                                        obj.Views, ...
                                                        obj.LoadedMovie...
                                                        ); % plane number may change
             end
        end

   
        function [check] =      pointIsWithinImageAxesBounds(obj, CurrentRow, CurrentColumn)

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

        function obj =          setFrameBySlider(obj)
            MyNumber = round(obj.Views.Navigation.TimeSlider.Value);
            obj = obj.setFrameByNumber(MyNumber);
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
    
    methods (Access = private) % SETTERS MOUSE ACTION
        
        function obj =      setMouseDownRow(obj, Value)
            obj.MouseDownRow = Value;
        end

        function obj =      setMouseDownColumn(obj, Value)
            obj.MouseDownColumn = Value;
        end

        function obj =      setMouseUpRow(obj, Value)
            obj.MouseUpRow = Value;
        end

        function obj =      setMouseUpColumn(obj, Value)
            obj.MouseUpColumn = Value;
        end

        function obj =      myMouseButtonWasJustPressed(obj,~,~)
            obj = obj.mouseButtonPressed(obj.Views.getPressedKey, obj.Views.getRawModifier);
        end

        function obj =      myMouseJustMoved(obj,~,~)
            obj = obj.mouseMoved(obj.Views.getPressedKey, obj.Views.getRawModifier);
        end

        function obj =      myMouseButtonWasJustReleased(obj,~,~)
            obj = obj.mouseButtonReleased(obj.Views.getPressedKey, obj.Views.getRawModifier);
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
    
          obj =      obj.setImageMaximumProjection(obj.Views.getShowMaximumProjection);

        end

        function obj =      croppingOnOffClicked(obj,~,~)
            obj.LoadedMovie =    obj.LoadedMovie.setCroppingStateTo(obj.Views.getCropImage);
            obj =                obj.setActiveCropOfMovieView;
        end

       

        function obj =      driftCorrectionOnOffClicked(obj,~,~)
           obj =                obj.setDriftCorrectionTo(obj.Views.getApplyDriftCorrection);  
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
            obj =               obj.initializeViews;
        end
 
        function [obj] =      trackingShowMaskButtonClicked(obj,~,~)
            obj.LoadedMovie =   obj.LoadedMovie.setMaskVisibility(obj.Views.getShowMasks);
            obj =               obj.initializeViews;
            obj =               obj.updateMovieView;

        end

        function [obj] =      trackingShowTracksButtonClicked(obj,~,~)
            obj.LoadedMovie =       obj.LoadedMovie.setTrackVisibility(obj.Views.getShowTracks);
             obj =                  obj.initializeViews;
        end

        function [obj] =      trackingShowMaximumProjectionButtonClicked(obj,~,~)
            obj =              obj.setCollapseTracking(obj.Views.getShowMaxProjectionOfTrackingData);
        end

    end

    methods (Access = private) % CALLBACKS FOR ANNOTATION

        function obj = setAnnotationCallbacks(obj)
            obj.Views  =            obj.Views.setAnnotationCallbacks(...
                                    @obj.annotationScaleBarOnOffClicked, @obj.annotationScaleBarSizeClicked);
        end

        function [obj] =         annotationScaleBarOnOffClicked(obj,~,~)
            obj.LoadedMovie =           obj.LoadedMovie.toggleScaleBarVisibility;
            obj =                       obj.updateMovieView;
        end

        function [obj] =         annotationScaleBarSizeClicked(obj,~,~)
            obj.LoadedMovie =           obj.LoadedMovie.setScaleBarSize(obj.Views.getScalbarSize);
            obj =                       obj.updateMovieView;
        end




    end

    methods (Access = private) % different view setters:

        function obj =      view_CroppingGate(obj, Value)
            obj = obj.setCroppingGateByString(Value);

        end
             
        function obj =      view_trackVisibility(obj, Value)
            switch Value
             case 'toggle'
                obj =  obj.toggleTrackVisibility;
             otherwise
                 error('Wrong input.')
            end


        end
        
        function obj =      view_CroppingOn(obj, Value)
            switch Value
             case 'toggle'
                 Setting = ~obj.Views.getCropImage;
                obj.LoadedMovie =       obj.LoadedMovie.setCroppingStateTo(Setting);
                  obj.Views =         obj.Views.setNavigationWith(obj.LoadedMovie);
                obj =                   obj.setActiveCropOfMovieView;
              otherwise
                  error('Wrong input.')
            end

        end

        function obj =      view_channelVisibility(obj, Value)
            switch Value
             case 'toggleByKeyPress'

                 PressedKey =       obj.PressedKeyValue;
                 obj =              obj.toggleVisibilityOfChannelIndex(str2double(PressedKey));

             otherwise
                 error('Wrong input.')
            end


        end

        function obj =      view_timeAnnotationVisibility(obj, Value)
            
            switch Value
             case 'toggle'
                obj =  obj.toggleTimeVisibility;
             otherwise
                 error('Wrong input.')
            end

        end

        function obj =      toggleTimeVisibility(obj)
            obj.LoadedMovie =   obj.LoadedMovie.setTimeVisibility(~obj.LoadedMovie.getTimeVisibility);
            obj =               obj.updateMovieView;
        end

        function obj =      toggleScaleBarVisibility(obj)
            obj.LoadedMovie =      obj.LoadedMovie.toggleScaleBarVisibility;
            obj =           obj.updateMovieView;

        end

        function obj =      view_planeAnnotationVisibility(obj, Value)

            switch Value
                case 'toggle'
                    obj.LoadedMovie =      obj.LoadedMovie.setPlaneVisibility( ~obj.LoadedMovie.getPlaneVisibility);
                    obj =           obj.updateMovieView;
                otherwise
                    error('Wrong input.')
            end


        end

        function obj =      view_maskVisibility(obj, Value)
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

        function obj =      view_centroidVisibility(obj, Value)
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

        function obj =      toggleMaskVisibility(obj)
            obj.LoadedMovie =       obj.LoadedMovie.toggleMaskVisibility  ; 
            obj =                   obj.initializeViews;
            obj =                   obj.updateMovieView;


        end

        function obj =      toggleCentroidVisibility(obj)
            obj.LoadedMovie =   obj.LoadedMovie.toggleCentroidVisibility;
            obj =           obj.initializeViews;

        end

    end

    methods (Access = private) % SETTERS AUTOCELLRECOGNITION
       
         
        function obj =      AutoCellRecognitionChannelChanged(obj, ~, third)
           obj.AutoCellRecognitionController = setActiveChannel(obj.AutoCellRecognitionController, third.DisplayIndices(1));
        end

        function obj =      AutoCellRecognitionFramesChanged(obj, ~, third)
          myFrames =  third.DisplayIndices(:, 1);
          obj.AutoCellRecognitionController = setSelectedFrames(obj.AutoCellRecognitionController, myFrames);

        end

        function obj =      AutoCellRecognitionTableChanged(obj,src,~)
         obj.AutoCellRecognitionController = obj.AutoCellRecognitionController.setCircleLimitsBy(src.Data);

        end

        function obj =      startAutoCellRecognitionPushed(obj,~,~)

            switch obj.AutoCellRecognitionController.getUserSelection
                case 'Interpolate plane settings'
                    obj.AutoCellRecognitionController = obj.AutoCellRecognitionController.interpolateCircleRecognitionLimits;
                     obj.LoadedMovie =                         obj.LoadedMovie.updateTrackingWith(obj.AutoCellRecognitionController.getView);

                case 'Circle recognition'
                    obj =                  obj.askUserToDeleteTrackingData;
                     obj.LoadedMovie =     obj.LoadedMovie.updateTrackingWith(obj.AutoCellRecognitionController.getView);
                    obj.LoadedMovie =      obj.LoadedMovie.setTrackingAnalysis;
                    obj.LoadedMovie =      obj.LoadedMovie.executeAutoCellRecognition(obj.AutoCellRecognitionController.getAutoCellRecognition);

                    obj =                   obj.updateAllViewsThatDependOnSelectedTracks;

                case 'Intensity recognition'
                      obj =                 obj.askUserToDeleteTrackingData;
                     obj.LoadedMovie =      obj.LoadedMovie.updateTrackingWith(obj.AutoCellRecognitionController.getView);
                    obj.LoadedMovie =       obj.LoadedMovie.setTrackingAnalysis;
                    obj =                   obj.autoDetectMasksOfCurrentFrame(obj.AutoCellRecognitionController.getAutoCellRecognition);


                    obj =                   obj.updateAllViewsThatDependOnSelectedTracks;
        end


        end

        function obj =      askUserToDeleteTrackingData(obj)
            DeleteAllAnswer = questdlg('Do you want to delete all existing tracks before autodetection?', 'Cell autodetection');
            switch DeleteAllAnswer
                case 'Yes'
                    obj =         obj.tracking_deleteAllTracks;
            end
        end

        function obj =      changeOfAutoCellRecognitionView(obj, ~, ~)

           obj.LoadedMovie =                         obj.LoadedMovie.updateTrackingWith(obj.AutoCellRecognitionController.getView);
        end
        
    end
    
    methods (Access = private) % AUTOCELLRECOGNITION intensity

        function obj =                    autoDetectMasksOfCurrentFrame(obj, autoRecognition)
            % AUTODETECTMASKSOFCURRENTFRAME

            StartFrame =                obj.LoadedMovie.getActiveFrames;
            mySegmentationCapture =     obj.getReferenceSegmentation;
            mySegmentationCapture =     mySegmentationCapture.setSizeForFindingCellsByIntensity(obj.MaskLocalizationSize);
            mySegmentationCapture =     mySegmentationCapture.setShowSegmentationProgress(false);

            for PlaneIndex = 1 : obj.LoadedMovie.getMaxPlane

                obj =                  obj.resetPlane(PlaneIndex);

                for FrameIndex = 1 : autoRecognition.getSelectedFrames


                AccumulatedSegmentationFailures = 0;

                obj =                           obj.setFrameByNumber(FrameIndex);
                mySegmentationCapture =         mySegmentationCapture.emptyOutBlackedOutPixels; 

                ContinueLoop = true;
                while ContinueLoop

                    mySegmentationCapture =     mySegmentationCapture.resetWithMovieController(obj);
                    mySegmentationCapture =     mySegmentationCapture.resetMask;


                    mySegmentationCapture =     mySegmentationCapture.setActiveZCoordinate(PlaneIndex);
                    mySegmentationCapture =     mySegmentationCapture.blackoutAllPreviouslyTrackedPixels;

                    mySegmentationCapture =     mySegmentationCapture.setActiveCoordinateByBrightestArea;
                    mySegmentationCapture =     mySegmentationCapture.generateMaskByEdgeDetectionForceSizeBelowMaxSize;
                    mySegmentationCapture =     mySegmentationCapture.addActivePixelsToBlackedOutPixels;

                    DetectedCellOk =            mySegmentationCapture.testPixelValidity  ;

                    if DetectedCellOk
                        obj.LoadedMovie =   obj.LoadedMovie.setActiveTrackWith(obj.LoadedMovie.findNewTrackID);

                        try
                        obj.LoadedMovie =   obj.LoadedMovie.resetActivePixelListWith(mySegmentationCapture);
                        obj =               obj.updateAllViewsThatDependOnActiveTrack;
                        drawnow
                        catch
                        AccumulatedSegmentationFailures = AccumulatedSegmentationFailures + 1;
                        end

                    else 
                        AccumulatedSegmentationFailures = AccumulatedSegmentationFailures + 1;


                    end

                    if AccumulatedSegmentationFailures > 10
                        ContinueLoop = false;

                    end

                    fprintf('Number of failures for plane %i = %i.\n\n', PlaneIndex, AccumulatedSegmentationFailures)

                end
                obj.PressedKeyValue  = '';

                end
            end

            obj =      obj.setFrameByNumber( StartFrame);

        end

    end

    methods (Access = private) % DEPRACATED FUNCTIONS
       
          function obj =          resetWidthOfMovieAxesToMatchAspectRatio(obj)
            error('Not supported anymore. Stop using it.')
            if ~isempty(obj.Views) && isvalid(obj.Views.getFigure)
                XLength =                   obj.Views.getMovieAxes.XLim(2)- obj.Views.getMovieAxes.XLim(1);
                YLength =                   obj.Views.getMovieAxes.YLim(2)- obj.Views.getMovieAxes.YLim(1);
                LengthenFactorForX =        XLength/  YLength;
                obj.Views =                 obj.Views.setMovieAxesWidth(obj.Views.getMovieAxes.Position(4) * LengthenFactorForX);
            end
        end
        
    end
  
end