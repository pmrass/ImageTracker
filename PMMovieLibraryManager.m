classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties (Access = private)

        Viewer
        
        MovieLibrary 
        ActiveMovieController =                 PMMovieController()
        MovieTrackingFileController =           PMMovieTrackingFileController

        InteractionsManager
        FileManagerViewer
        
        TrackSegmentView
        
        XYLimitForNeighborArea =                50;
        ZLimitsForNeighborArea =                8;
        
        StopDistanceLimit =                     15;
        MaxStopDurationForGoSegment =           5;
        MinStopDurationForStopInterval =        20;
        
 
    end
    
    properties % add accessors and make private;
          DistanceLimits =      {[0, 8];  [2, 8]; [0, 1]};
          DistanceType =        'FractionFullPixels';
    end
    

    
    properties(Access = private, Constant)
        FileWithPreviousSettings =         [userpath,'/imans_PreviouslyUsedFile.mat'];
    end
    
    methods % INITIALIZATION
        
        function obj =          PMMovieLibraryManager(varargin)
            % PMMOVIELIBRARYMANAGER create instance of this class
            % takes 0 or 1 arguments:
            % with zero arguments: tries to retrieve file-name of previously used library stored in file;
            % 1: character string: complete path of library
        
            obj.InteractionsManager =   PMInteractionsManager(PMInteractionsView);
            obj.Viewer =                PMImagingProjectViewer;
            
            switch length(varargin)
                case 0
                    
                case 1
                    MyMovieLibrary =       obj.getMovieLibraryForInput( varargin{:});
                    obj =                  obj.setMovieLibrary(MyMovieLibrary);
                    
                
            end
            

        end
        
    
        
        function set.ActiveMovieController(obj, Value)
            assert(isa(Value,  'PMMovieController') && isscalar (Value), 'Wrong input type.')
           obj.ActiveMovieController = Value;
        end
        
        function set.MovieLibrary(obj, Value)
           assert(isa(Value,  'PMMovieLibrary') && isscalar(Value), 'Wrong input type.')
           obj.MovieLibrary = Value; 
        end
        
    end
    
    methods % VIEW
        
        function obj = show(obj)
            % SHOW show main figure
            % either puts main-figure in foreground (if it exists) or creates new figure from scracth;
            obj.Viewer =                    obj.Viewer.show;
            obj =                           obj.finalizeProjectViews;
            obj.ActiveMovieController =     obj.ActiveMovieController.setViewsByProjectView(obj.Viewer);
           
        end
         
    end
    
    methods % SETTERS
        
        function obj =      openSelectedMovie(obj)
            % OPENSELECTEDMOVIE activates currently selected movie;
            % only works when precisely one movie is selected
            
            SelectedNicknames =     obj.Viewer.getSelectedNicknames;
            if length(SelectedNicknames) == 1
                obj =    obj.saveActiveMovieAndLibrary;
                obj =    obj.setActiveMovieByNickName(SelectedNicknames{1});
            end
                    
        end
        
        function obj =      setActiveMovieByNickName(obj, varargin)
            % SETACTIVEMOVIEBYNICKNAME change active movie
            % takes 1 argument:
            % 1: character string with nickname
            % updates views and content including MovieTrackingFileController and InteractionsManager;
            % also updates callbacks;

            switch length(varargin)
                
                case 1
                    
                    obj.ActiveMovieController =             obj.ActiveMovieController.clear;
                    
                    obj.MovieLibrary=                       obj.MovieLibrary.switchActiveMovieByNickName(varargin{1});
                    obj.ActiveMovieController =             obj.MovieLibrary.getActiveMovieController;
                    assert(~isempty(obj.ActiveMovieController), 'Something went wrong. No active movie-controller could be retrieved')
                    
                    obj.Viewer =                            obj.Viewer.updateWith(obj.MovieLibrary);  
                    
                    obj.MovieTrackingFileController =       obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);

                    obj.ActiveMovieController =             obj.ActiveMovieController.setViewsByProjectView(obj.Viewer);

                    obj.InteractionsManager =               obj.InteractionsManager.resetModelByMovieController(obj.ActiveMovieController);
                    obj.InteractionsManager =               obj.InteractionsManager.setXYLimitForNeighborArea(obj.XYLimitForNeighborArea);
                    obj.InteractionsManager =               obj.InteractionsManager.setZLimitForNeighborArea(obj.ZLimitsForNeighborArea);

                  
                    obj.ActiveMovieController =             obj.ActiveMovieController.updateWith(obj.InteractionsManager);
                    
                    obj =                                   obj.setInfoTextView;
                    
                    obj =                                   obj.addCallbacksToInteractionManager;
                    obj =                                   obj.addCallbacksToFileAndProject;
           
                otherwise
                    error('Invalid number of arguments')
            end


        end

        function obj =      setLoadedMovie(obj, LoadedMovie)
            % SETLOADEDMOVIE allows visualization of a user-defined PMMovieTracking object:
            % takes 1 argument:
            % 1: PMMovieTracking
            obj.ActiveMovieController =                 obj.ActiveMovieController.clear;
            obj.ActiveMovieController =                 obj.ActiveMovieController.setViewsByProjectView(obj.getViews);
            obj.ActiveMovieController  =                obj.ActiveMovieController.setLoadedMovie(LoadedMovie);
            obj.ActiveMovieController =                 obj.ActiveMovieController.setNavigationControls;
            obj.ActiveMovieController =                 obj.ActiveMovieController.updateMovieView;
            obj.ActiveMovieController =                 obj.ActiveMovieController.setActiveCropOfMovieView;

        end
        
        function obj =      setActiveMovieController(obj, Value)
           % SETACTIVEMOVIECONTROLLER set active movie-controller
           % takes 1 argument:
           % 1: scalar PMMovieController
           obj.ActiveMovieController  = Value;
        end
        
        function obj =      callMovieControllerMethod(obj, varargin)
            % CALLMOVIECONTROLLERMETHOD allows usage of method from active movie-controller;
            % takes 1 or more arguments:
            % 1: name of method
            % 2: arguments for method (number depends on method)
            obj.ActiveMovieController = obj.ActiveMovieController.(varargin{1})(varargin{2:end});
            
        end
        
        function obj =      performMovieLibraryMethod(obj, varargin)
           % PERFORMMOVIELIBRARYMETHOD allows usage of method from movie-library;
            % takes 1 or more arguments:
            % 1: name of method
            % 2: arguments for method (number depends on method)
            switch length(varargin)
               
                case 1
                    assert(ischar(varargin{1}), 'Wrong input.')
                    Output = obj.MovieLibrary.(varargin{1});
                    if isa(Output, 'PMMovieLibrary')
                        obj.MovieLibrary = Output;
                    end
                    
                otherwise
                    error('Input not supported.')
                
            end
               
        end
        
    end
   
    methods % SETTERS MOVIE-LIBRARY
       
         function obj =      setMovieLibrary(obj, Value)
             % SETMOVIELIBRARY set movie-library
             % takes 1 argument:
             % 1: scalar 'PMMovieLibrary'
             % updates project movies and movie controller
            obj.MovieLibrary =          Value;
            obj =                       obj.finalizeProjectViews;
            obj =                       obj.setEmpyActiveMovieController;       
            obj.savePreviousSettings; 
            
        end
        
    end
    
    methods % GETTERS
        
          function library =        getMovieLibrary(obj)
              % GETMOVIELIBRARY returns movie-library
                library = obj.MovieLibrary;
           end
       
          function controller =     getActiveMovieController(obj)
                % GETACTIVEMOVIECONTROLLER returns active movie controller
                assert(~isempty(obj.ActiveMovieController), 'No movie controller set.')
                controller  = obj.ActiveMovieController ;
         end
         
     end
    
    methods % SETTERS BATCH-PROCESSING
        
          function obj =        batchProcessingOfNickNames(obj, NickNames, ActionType, varargin)
              % BATCHPROCESSINGOFNICKNAMES
              % takes 2 or 3 arguments:
              % 1: list with nicknames that should be modified (cell-string array);
              % 2: descriptor of wanted action 'MapImages', 'SetChannelsByActiveMovie', 'createDerivativeFiles', 'saveInteractionMap', 'changeKeywords';
              % 3:
            
            originalNickName =          obj.MovieLibrary.getSelectedNickname;  
            OriginalController =        obj.ActiveMovieController;
              
            obj =                       obj.saveActiveMovieAndLibrary;
            
            for CurrentMovieIndex = 1 : size(NickNames,1)
                
                obj =        obj.setActiveMovieByNickName( NickNames{CurrentMovieIndex});
                
                switch ActionType                    
                    case 'MapImages'
                         obj.ActiveMovieController =       obj.ActiveMovieController.resetLoadedMovieFromImageFiles;
                         
                    case 'SetChannelsByActiveMovie'
                        obj.ActiveMovieController =         obj.ActiveMovieController.setChannels(OriginalController.getLoadedMovie);
                        
                    case 'createDerivativeFiles'
                        obj.ActiveMovieController =         obj.ActiveMovieController.createDerivativeFiles;
                        obj =                               obj.saveInteractionsMapForActiveMovie;
                        
                    case 'saveInteractionMap'
                         obj =                               obj.saveInteractionsMapForActiveMovie;
                         
                    case 'changeKeywords'
                       obj.ActiveMovieController =         obj.ActiveMovieController.setKeywords(varargin{1});
                         
                    otherwise
                        error('Batch analysis not specified.')
                 
                end
                
                obj =                           obj.saveActiveMovieAndLibrary;
                obj.ActiveMovieController =     obj.ActiveMovieController.updateSaveStatusView;
                
                
  
                obj =                           obj.setInfoTextView;
                obj=                            obj.callbackForFilterChange;
                
            end
            
            obj =         obj.setActiveMovieByNickName(originalNickName);
            
          end
           
    end
    
    methods % interaction
        
        function obj =          saveInteractionsMapsForAllShownMovies(obj)
            % SAVEINTERACTIONSMAPSFORALLSHOWNMOVIES save interaction map for all selected movies;
            SelectedNicknames =     obj.Viewer.getSelectedNicknames;
            obj =                   obj.batchProcessingOfNickNames(SelectedNicknames, 'saveInteractionMap');

        end

        function obj =          saveInteractionsMapForActiveMovie(obj, varargin) 
            % SAVEINTERACTIONSMAPFORACTIVEMOVIE saves interaction map for active movie;
            % takes 0 or 2 arguments;
            % 1: limit for XY neighbor area
            % 2: limit for Z neighbor area

             switch length(varargin)
                 case 0

                 case 2
                        obj.XYLimitForNeighborArea = varargin{1};
                        obj.ZLimitsForNeighborArea =  varargin{2};

                 otherwise
                     error('Wrong input.')

             end

           
            obj.InteractionsManager =       obj.InteractionsManager.setExportFolder(obj.MovieLibrary.getInteractionFolder); % specify folder if you want to export detailed interaction measurement specifications
            InteractionObject =             obj.InteractionsManager.getInteractionsMap;
            save(obj.getFileNameWithInteractionAnalysis, 'InteractionObject');

        end

        function obj =          exportDetailedInteractionInfoOfActiveTrack(obj, varargin)
            % EXPORTDETAILEDINTERACTIONINFOOFACTIVETRACK export detailed interaction of active track;
            % takes 0 or 2 arguments;
            % 1: limit for XY neighbor area
            % 2: limit for Z neighbor area


             switch length(varargin)
                 case 0

                 case 2

                      obj.XYLimitForNeighborArea =      varargin{1};
                      obj.ZLimitsForNeighborArea =      varargin{2};


                 otherwise
                     error('Wrong input.')



             end

            obj.InteractionsManager =       obj.InteractionsManager.setExportFolder(obj.MovieLibrary.getInteractionFolder);
            obj.InteractionsManager =       obj.InteractionsManager.exportDetailedInteractionInfoForTrackIDs(obj.ActiveMovieController.getLoadedMovie.getIdOfActiveTrack);
        end

        function obj =          showTrackSummaryOfActiveMovie(obj)

            fprintf('\n*** Summary of tracking data of active movie:\n')
            mySuite = obj.getTrackingSuiteOfActiveMovie;

            fprintf('\n2) Summary of active track:\n')
            mySuite = mySuite.showSummaryOfTrackID(obj.ActiveMovieController.getLoadedMovie.getIdOfActiveTrack);

            fprintf('\n3) Summary of tracks, segments, etc. by distance to target:\n')
            for index = 1 : length(obj.DistanceLimits)
              mySuite = mySuite.showTrackSummaryForDistanceRange(obj.DistanceLimits{index}, obj.DistanceType);

            end

        end

        function mySuite =      getTrackingSuiteOfActiveMovie(obj)
            % initialize tracking-suite:
            mySuite =   PMTrackingSuite(...
                                            obj.MovieLibrary.getFileName, ...
                                            'CurrentMovieInManager', ...
                                            {obj.ActiveMovieController.getNickName}, ...
                                            {obj.getFileNameWithInteractionAnalysis}...
                                            );
            
            mySuite =   mySuite.setSpaceTimeLimitsOfSuites(...
                                obj.StopDistanceLimit, ...
                                obj.MinStopDurationForStopInterval, ...
                                obj.MaxStopDurationForGoSegment...
                                );
                            
            fprintf('\n1) Summary of tracking suite:\n')
            mySuite.showSummary;

        end
        
         function fileName =     getFileNameWithInteractionAnalysis(obj)
            Nickname =                obj.ActiveMovieController.getNickName;
            fileName =                [obj.MovieLibrary.getInteractionFolder , Nickname, '_Map.mat'];

         end

        

    end
    
    methods % EXPORT DATA
       
        function obj = exportMovieToFile(obj)
            % EXPORTMOVIETOFILE allows export of current source into movie;
            % user can select target file-name and frame range and fps;
          
              myMovieManager =                PMImagerViewerMovieManager(obj.ActiveMovieController);
              myMovieManager.exportMovie;
                 
        end
        
     end
     
    methods (Access = private) % SETTERS

        function obj =      setMovieFolders(obj, Value)
            obj.MovieLibrary =              obj.MovieLibrary.setMovieFolders(Value);
            obj =                           obj.saveActiveMovieAndLibrary;
            obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController;
            obj.ActiveMovieController =     obj.ActiveMovieController.setViewsByProjectView(obj.Viewer);
            obj =                           obj.setInfoTextView;
        end
        
        function obj=       setInfoTextView(obj)
             obj.Viewer =   obj.Viewer.setInfoView(obj.MovieLibrary.getProjectInfoText);  
        end
        
        function obj =      setInfoTextViewWith(obj, Value)
             obj.Viewer =   obj.Viewer.setInfoView(Value);  
            
        end
        
       


        function obj =      setExportFolder(obj, UserSelectedFolder)
                obj.MovieLibrary =              obj.MovieLibrary.setExportFolder(UserSelectedFolder);
                % obj =                           obj.Viewer.getSelectedNicknames;
                %    obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                obj =                           obj.setInfoTextView;

        end

        function obj =      addNewMovie(obj, Nickname, AttachedFiles)

                if obj.MovieLibrary.checkWheterNickNameAlreadyExists(Nickname)
                    warning('Nickname already exists and could therefore not be added.')

                else
                    
                    obj =                   obj.saveActiveMovieAndLibrary;
                        
                    
                    NewMovieTracking =      PMMovieTracking(...
                                                            Nickname, ...
                                                            obj.MovieLibrary.getMovieFolder, ...
                                                            AttachedFiles, ...
                                                            obj.MovieLibrary.getPathForImageAnalysis, ...
                                                            );
                                                        
                    NewMovieTracking =                       NewMovieTracking.setPropertiesFromImageMetaData;

                    NewMovieController =    PMMovieController(...
                                                                    obj.Viewer, ...
                                                                    NewMovieTracking...
                                                                    );

                    obj.MovieLibrary =      obj.MovieLibrary.addNewEntryToMovieList(NewMovieController);
                    obj.MovieLibrary =      obj.MovieLibrary.sortByNickName;
                    obj =                   obj.setActiveMovieByNickName(Nickname);
                    obj =                   obj.callbackForFilterChange;



                end


        end

    end
    
    methods (Access = private) % getter
        
        function views = getViews(obj)
           views = obj.Viewer; 
        end
        
        function obj = showSummary(obj)
            obj.ActiveMovieController = obj.ActiveMovieController.showSummary;
        end

        function PressedKey = getPressedKey(obj)
          PressedKey=       get(obj.Viewer.getFigure,'CurrentCharacter');
        end

        function Modifier = getModifier(obj)
          Modifier =   obj.Viewer.getFigure.CurrentModifier;

        end

        function verifiedStatus =                     verifyActiveMovieStatus(obj)
            verifiedStatus = obj.ActiveMovieController.verifyActiveMovieStatus;
        end
 
    end
    
    methods (Access = private) % getters FILE
       
          function fileName = getPreviouslyUsedFileName(obj)
              
                if exist(obj.FileWithPreviousSettings,'file')==2
                    
                    load(obj.FileWithPreviousSettings, 'FileNameOfProject')
                    if exist(FileNameOfProject)==2
                        fileName =  FileNameOfProject;
                    else
                        fileName =  '';
                    end

                else
                    error('Previous settings not found.')
                    
                end
            
        end
          
        
        
    end
    
    methods (Access = private) % SETTERS FOR KEY AND MOUSE ACTION
        
        function obj =          keyPressed(obj,~,~)

             if isempty(obj.getPressedKey) || ~obj.ActiveMovieController.verifyActiveMovieStatus

             else

                if strcmp(obj.getPressedKey, 's') && length(obj.getModifier) == 1 && strcmp(obj.getModifier, 'command')
                     obj = obj.saveActiveMovieAndLibrary;
                else

                    try
                        
                        obj.ActiveMovieController.interpretKey(obj.getPressedKey, obj.getModifier);

                    catch ME
                        obj =   obj.setInfoTextViewWith(ME.message);
                    end        
                end


             end

             obj.Viewer = obj.Viewer.setCurrentCharacter('0');


        end

        function obj =          mouseButtonPressed(obj,~,~)
          obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonPressed(obj.getPressedKey, obj.getModifier);
        end

        function obj =          mouseMoved(obj,~,~)
          obj.ActiveMovieController = obj.ActiveMovieController.mouseMoved(obj.getPressedKey, obj.getModifier);
        end

        function obj =          mouseButtonReleased(obj,~,~)

          try 
                obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonReleased(obj.getPressedKey, obj.getModifier);    
          catch E
               throw(E) 
          end

        end

        function obj =          sliderActivity(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setFrameBySlider;
        end

        
    end
    
    methods (Access = private) % SETTERS VIEWS
        
       
        function obj = finalizeProjectViews(obj)
            obj.Viewer =                obj.Viewer.adjustViews([11.5 0.1 21 3.5]);
            obj =                       obj.setMenus;
            obj =                       obj.addCallbacksToFileAndProject;
            obj =                       obj.updateFilterView;
            
        end
        
        function obj = setMenus(obj)
            obj =                       obj.setFileMenu;
            obj =                       obj.setProjectMenu;
            obj =                       obj.setMovieMenu;
            obj =                       obj.setDriftMenu;
            obj =                       obj.setTrackingMenu;
            obj =                       obj.setInteractionsMenu;
            obj =                       obj.setHelpMenu;
        end
       
     
        
    end
    
    methods (Access = private) % callbacks file menu
        
          function obj = setFileMenu(obj)
              
                 
   
                              MenuLabels = { 'New', 'Save', 'Load'};
                     
                     
              CallbackList = {...
                            @obj.newProjectClicked, ...
                            @obj.saveProjectClicked, ...
                            @obj.loadProjectClicked...
                            };
                        
                        
              obj.Viewer =    obj.Viewer.setMenu('FileMenu', 'File', MenuLabels, CallbackList);
              
              
          end
          
             function [obj] =    newProjectClicked(obj,~,~)
                [FileName, SelectedPath] =    uiputfile;
                if SelectedPath== 0
                    else
                    obj =       obj.saveActiveMovieAndLibrary;
                    obj =       obj.changeToNewLibraryWithFileName([SelectedPath, FileName]);
                end
             end

        function [obj] =    saveProjectClicked(obj,~,~)
               obj =        obj.saveActiveMovieAndLibrary;
        end
        
        function [obj] =    loadProjectClicked(obj,~,~)
            obj =   obj.userLoadsExistingLibrary;
        end
                    
       
        
     
        
        
    end
    
    methods (Access = private) % project menu
             
        function obj =          setProjectMenu(obj)

            MenuLabels = {...
                    'Change image analysis folder'; ...
                    'Add movie-folder'; ...
                    'Change export-folder'; ...
                    'Movie sources: Add single new entry'; ...
                    'Add entries for all images/movies in movie directory'; ...
                    'Delete entry of active movie'; ...
                    'Delete all entries in library'; ...
                    'Batch: Remap all movies'; ...
                    'Replace keywords'; ...
                    'Update movie summaries from file'; ...
                    'Set channels of selected movies by active movie'; ...
                    'Create derivative files'; ...
                    'Views: Show image/movie files that have already been imported'; ...
                    'Views: Show image/movie files that have not yet been imported'; ...
                    'Show general info'...
                 };


        CallbackList = {...
                            @obj.setPathForImageAnalysis, ...
                            @obj.changeMovieFolderClicked, ...
                            @obj.changeExportFolderClicked,...
                            @obj.addMovieClicked,...
                            @obj.addAllMissingCaptures,...
                            @obj.removeMovieClicked,...
                            @obj.removeAllMoviesClicked,...
                            @obj.mapUnMappedMovies,...
                            @obj.replaceKeywords,...
                            @obj.updateMovieSummaryFromFiles,...
                            @obj.batchProcessingChannel...
                            @obj.createDerivativeFiles,...
                            @obj.showIncludedCaptures,...
                            @obj.showMissingCaptures,...
                            @obj.toggleProjectInfo,...
                    };

                SeparatorList = {'off', 'off', 'off', ...
                                  'on', 'off', 'off', 'off', ...
                                  'on', 'off', 'off', 'off', 'off', ...
                                  'on', 'off', 'off'};


        obj.Viewer =    obj.Viewer.setMenu('ProjectMenu', 'Project', MenuLabels, CallbackList, SeparatorList);

        end

        function obj =          setPathForImageAnalysis(obj, ~, ~)
             obj.MovieLibrary =         obj.MovieLibrary.letUserSetAnnotationPath(obj);
             obj =                      obj.updateAfterAnnotationPathChange;

        end
        
       function obj =      updateAfterAnnotationPathChange(obj)
            obj =                           obj.setInfoTextView;
       end
        

        function obj =          changeMovieFolderClicked(obj,~,~)
            obj.MovieLibrary =      obj.MovieLibrary.letUserSetMovieFolder;
            obj =                   obj.updateAfterChangingMovieFolder;
            
             
        end
        
        
        function obj =      updateAfterChangingMovieFolder(obj)
            
           
            obj =                    obj.saveActiveMovieAndLibrary;
            try 
                 obj.ActiveMovieController =        obj.MovieLibrary.getActiveMovieController;
                 obj.ActiveMovieController =        obj.ActiveMovieController.setViewsByProjectView(obj.Viewer);
                    
            catch
                warning('Movie controller could not be reset.')
            end
            obj =                    obj.setInfoTextView;
        end
        

        function obj =    changeExportFolderClicked(obj,~,~)
            UserSelectedFolder=            uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select export folder',...
            'NumFiles', 1, 'Output', 'char');
            if isempty(UserSelectedFolder) || ~ischar(UserSelectedFolder)
            else
              obj = obj.setExportFolder(UserSelectedFolder);
            end

        end

        function obj =    addMovieClicked(obj,~,~)
            obj = obj.letUserAddNewMovie;
        end

        function obj =    addAllMissingCaptures(obj,~,~)
            missingFiles =                          obj.MovieLibrary.getFileNamesOfUnincorporatedMovies;
            for FileIndex= 1:size(missingFiles,1)
                CurrentFileName =   missingFiles{FileIndex,1};
                obj =     obj.addNewMovie(obj.convertFileNameIntoNickName(CurrentFileName), {CurrentFileName});
            end
        end

        function nickName = convertFileNameIntoNickName(~, FileName)
        nickName =  FileName(1:end-4);
        end

        function obj =  removeMovieClicked(obj,~,~)
            obj =                           obj.removeActiveEntry;   
        end

        function obj = removeActiveEntry(obj)
            obj.ActiveMovieController =     obj.ActiveMovieController.deleteMovieAnnotation;
            obj.MovieLibrary =              obj.MovieLibrary.removeActiveMovieFromLibrary;
            obj =                           obj.setEmpyActiveMovieController;  
            obj =                           obj.callbackForFilterChange;
           
        end

        function obj = removeAllMoviesClicked(obj, ~, ~)

            answer = questdlg(['Are you sure you remove all entries from the library?  Al linked data (tracking, drift correction etc.) will also be deleted. This is irreversible.'], ...
            'Project menu', 'Yes',   'No','No');
            switch answer
            case 'Yes'
                AllNickNames = obj.MovieLibrary.getAllNicknames;
                for index = 1:length(AllNickNames)
                    obj = obj.removeEntryWithNickName(AllNickNames{index});
                end
            end

        end

        function obj = removeEntryWithNickName(obj, Value)
            obj =           obj.setActiveMovieByNickName(Value);
            obj =           obj.removeActiveEntry;
        end

        function obj =  mapUnMappedMovies(obj,~,~)
            obj.Viewer =       obj.Viewer.setContentTypeFilterTo('Show all unmapped movies');
            obj =              obj.callbackForFilterChange;
            obj =              obj.batchProcessingOfNickNames(obj.MovieLibrary.getAllFilteredNicknames, 'MapImages');
        end

        function obj = showIncludedCaptures(obj, ~, ~)
            obj.Viewer = obj.Viewer.setInfoView(obj.MovieLibrary.getAllAttachedMovieFileNames);
        end
        
        function obj =  showMissingCaptures(obj,~,~)
            obj.Viewer = obj.Viewer.setInfoView(obj.MovieLibrary.getFileNamesOfUnincorporatedMovies);

        end
        
        function obj =      toggleProjectInfo(obj,~,~)
            obj =                               obj.setInfoTextView;
            
        end
       
        

        function obj = updateMovieSummaryFromFiles(obj,~,~)
            obj.MovieLibrary = obj.MovieLibrary.setAllMovies;
        end

        function obj = replaceKeywords(obj,~,~)
            
            NewKeyword = inputdlg('Enter the keyword that should replace keywords of currently filtered movies.');
            obj.MovieLibrary.showSummary;
            NickNames =     obj.MovieLibrary.getListWithFilteredNicknames;
            obj =           obj.batchProcessingOfNickNames(NickNames, 'changeKeywords', NewKeyword{1});
        end
  
    end
    
    methods (Access = private) % set movie-menu
        
        function obj =          setMovieMenu(obj)

            MenuLabels = { 'File settings', 'Rename linked movie files', 'Relink movies', ...
                'Remap image files', 'Delete image cache', ...
                'Export active movie into mp4 file', 'Export active image into jpg file', 'Export track coodinates into csv file', 'Export detailed meta-data into txt file',  'Show meta-data summary in info text box'};

                CallbackList =   {...
                    @obj.editMovieSettingsClicked, ...
                    @obj.changeNameOfLinkeMoviesClicked, ...
                    @obj.changeLinkedMoviesClicked, ...
                    @obj.reapplySourceFilesClicked, ...
                    @obj.deleteImageCacheClicked, ...
                    @obj.exportMovie, ...
                    @obj.exportImage, ...
                    @obj.exportTrackCoordinates, ...
                    @obj.exportDetailedMetaDataIntoFile, ...
                    @obj.showMetaDataSummary ...
            };

            SeparatorList = {'off', 'off', 'off', ...
                                      'on', 'off', ...
                                      'on', 'off', 'off', 'off', 'off'};


            obj.Viewer =    obj.Viewer.setMenu('MovieMenu', 'Movie', MenuLabels, CallbackList, SeparatorList);

        end

        function obj =          editMovieSettingsClicked(obj,~,~)
            obj =  obj.resetMovieTrackingFileController;
        end

        function obj =          resetMovieTrackingFileController(obj)    
             if isempty(obj.ActiveMovieController.getLoadedMovie)
                 fprintf('Currently no movie in memory. Cannot generate MovieTracking view.\n')
             else
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.resetView;
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.setCallbacks(@obj.changeNicknameClicked, @obj.changeKeywordClicked);
             end
        end

        function obj =          changeNicknameClicked(obj,~,~)

            MyNewNickName =                 obj.MovieTrackingFileController.getNickNameFromView;
            obj.ActiveMovieController =     obj.ActiveMovieController.setNickName(MyNewNickName);
            obj.MovieLibrary =              obj.MovieLibrary.changeNickNameOfSelectedMovie(MyNewNickName);

            obj =                           obj.updatesAfterChangingMovieController;

        end

        function obj =          updatesAfterChangingMovieController(obj)
          
            obj.MovieLibrary =                      obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
            obj.MovieTrackingFileController =       obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
            obj =                                   obj.callbackForFilterChange;
            obj =                                   obj.setInfoTextView;

        end

        function FileName =     convertNickNameIntoFileName(obj, NickName)
            FileName =        [NickName, obj.ActiveMovieController.getLoadedMovie.getMovieFileExtension];
        end

        function obj =          changeKeywordClicked(obj,~,~)

            if isempty(obj.MovieTrackingFileController.getKeywordFromView)
            else 
                  obj.ActiveMovieController =   obj.ActiveMovieController.setKeywords(obj.MovieTrackingFileController.getKeywordFromView);
                  obj =                         obj.updatesAfterChangingMovieController;



            end

        end
        
        function obj =          changeLinkedMoviesClicked(obj,~,~)
                obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(obj.MovieLibrary.askUserToSelectMovieFileNames);
                obj =                           obj.updatesAfterChangingMovieController;
         end
             
        function obj =          reapplySourceFilesClicked(obj,~,~)
             if isempty(obj.ActiveMovieController)
             else
                 obj.ActiveMovieController =      obj.ActiveMovieController.resetLoadedMovieFromImageFiles;
             end
        end
        
        function  obj =         deleteImageCacheClicked(obj,~,~) 
            if isempty(obj.ActiveMovieController) 
            else
                obj.ActiveMovieController    =      obj.ActiveMovieController.emptyOutLoadedImageVolumes;
                obj.ActiveMovieController =           obj.ActiveMovieController.blackOutViews;
            end
        end
        
        function obj =          exportMovie(obj,~,~)

            obj = obj.exportMovieToFile;
            
        end
        
        function obj =          exportImage(obj, ~, ~)
            obj.ActiveMovieController =     obj.ActiveMovieController.setExportFolder(obj.MovieLibrary.getExportFolder);
            obj.ActiveMovieController =     obj.ActiveMovieController.exportCurrentFrameAsImage;
            
        end
        
        function obj =          exportTrackCoordinates(obj,~,~)
            obj.ActiveMovieController =     obj.ActiveMovieController.exportTrackCoordinates;
        end
        
        function obj =          exportDetailedMetaDataIntoFile(obj, ~, ~)
            obj.ActiveMovieController = obj.ActiveMovieController.saveMetaData(obj.MovieLibrary.getExportFolder); 
        end
        
        function obj =          showMetaDataSummary(obj, ~, ~)
             obj.Viewer =               obj.Viewer.setInfoView(obj.ActiveMovieController.getLoadedMovie.getMetaDataSummary);
         end
        
        
    end
    
    methods (Access = private) % set drift menu:
        
       function obj =  setDriftMenu(obj)
               
                MenuLabels = { 'Apply manual drift correction', 'Erase all drift corrections'};

                CallbackList =   {...
                @obj.applyManualDriftCorrectionClicked, ...
                @obj.eraseAllDriftCorrectionsClicked ...
                };

                obj.Viewer =    obj.Viewer.setMenu('DriftMenu', 'Drift correction', MenuLabels, CallbackList);

        end
        
       function  obj = applyManualDriftCorrectionClicked(obj,~,~)
             obj.ActiveMovieController =          obj.ActiveMovieController.setDriftCorrection('byManualEntries');  
            obj = obj.saveActiveMovieAndLibrary;
            obj =  updatesAfterChangingMovieController(obj);
            
        end
        
       function  obj = eraseAllDriftCorrectionsClicked(obj,~,~)
            obj.ActiveMovieController =         obj.ActiveMovieController.setDriftCorrection('remove'); 
            obj = obj.saveActiveMovieAndLibrary;
            obj =  updatesAfterChangingMovieController(obj);
        end
           
    end
       
    methods (Access = private) % tracking menu
       
         function [obj] =        setTrackingMenu(obj)
              
                MenuLabels = { 'Autodetection of cells', 'Autotracking', 'View and edit tracks', 'Edit track segments'};

                CallbackList =   {...
                                @obj.manageAutoCellRecognition,...
                                @obj.manageTrackingAutoTracking, ...
                                @obj.manageTrackingEditAndView, ...
                                @obj.manageTrackSegments ...
                };

                obj.Viewer =    obj.Viewer.setMenu('TrackingMenu', 'Tracking', MenuLabels, CallbackList);
    
         end
        
        function [obj] = manageAutoCellRecognition(obj,~,~)
            obj.ActiveMovieController =     obj.ActiveMovieController.showAutoCellRecognitionWindow;
          end
           
        function [obj] = manageTrackingAutoTracking(obj,~,~)
            obj =  obj.resetAutoTrackingController;
        end

        function obj =             resetAutoTrackingController(obj)
            obj.ActiveMovieController =        obj.ActiveMovieController.showAutoTrackingController; 
        end
        
        function obj = manageTrackingEditAndView(obj,~,~)
            obj.ActiveMovieController =  obj.ActiveMovieController.setTrackingNavigationEditViewController('ForceDisplay');
        end
           
         function obj =             setTrackingNavigationEditViewController(obj, varargin)
             NumberOfArguments = length(varargin);
             switch NumberOfArguments
                 case 0
                     obj.ActiveMovieController =    obj.ActiveMovieController.setTrackingNavigationEditViewController;
                 case 1
                     obj.ActiveMovieController =    obj.ActiveMovieController.setTrackingNavigationEditViewController(varargin{1});
                 otherwise
                     error('Wrong input.')
             end
        
         end
         
        function obj = manageTrackSegments(obj, ~, ~)
            obj.TrackSegmentView =  PMStopTrackingSeriesViewer(15, 5, 20);
            obj.TrackSegmentView =  obj.TrackSegmentView.setCallbacks(@obj.visualizeTrackSegments,@obj.exportTrackSegments);
         
        end
        
        function obj = visualizeTrackSegments(obj, ~, ~)
            
             obj.ActiveMovieController = obj.ActiveMovieController.setSegmentLineViews(obj.TrackSegmentView.getDistanceLimit, ...
                  obj.TrackSegmentView.getMinTimeLimit, ...
                  obj.TrackSegmentView.getMaxTimeLimit, ...
                  obj.TrackSegmentView.getVisibility );
              
        end
        
        function obj = exportTrackSegments(obj, ~, ~)
            
            [StopTracks, GoTracks, StopMetric, GoMetric] = obj.ActiveMovieController.getStopGoTrackSegments(obj.TrackSegmentView.getDistanceLimit,  obj.TrackSegmentView.getMinTimeLimit, obj.TrackSegmentView.getMaxTimeLimit);

            FileName = obj.ActiveMovieController.getLoadedMovie.getBasicMovieTrackingFileName;
            
            save([FileName, '_StopTracksPixel.mat'], 'StopTracks')
            save([FileName, '_GoTracksPixel.mat'], 'GoTracks')
            save([FileName, '_StopTracksMetric.mat'], 'StopMetric')
            save([FileName, '_GoTracksMetric.mat'], 'GoMetric')
            
        end
        
        
        
        function obj = setInteractionsMenu(obj)
                MenuLabels = { 'Set interaction parameters'};

                CallbackList =   {...
                                @obj.showInteractionsViewer,...
                };

                obj.Viewer =    obj.Viewer.setMenu('InteractionsMenu', 'Interactions', MenuLabels, CallbackList);
                  
        end
        
        function obj = setHelpMenu(obj)

              MenuLabels = { 'Show keyboard shortcuts', 'Show keyboard shortcuts for tracking'};

                CallbackList =   {...
                       @obj.showKeyboardShortcuts, ...
                @obj.showKeyboardShortcutsForTracking ...
                };

                obj.Viewer =    obj.Viewer.setMenu('HelpMenu', 'Help', MenuLabels, CallbackList);
                
                
        end
        
        
        
    end

    methods (Access = private) % setters ACTIVEMOVIECONTROLLER
        
        function obj = setEmpyActiveMovieController(obj)
            obj.ActiveMovieController=      PMMovieController(obj.Viewer);  
            obj.Viewer =                    obj.Viewer.updateWith(obj.MovieLibrary);
        end
        
        
    end
    
    methods (Access = private)% callbacks for file and project:
       
            function obj =        addCallbacksToFileAndProject(obj)

                obj.Viewer = obj.Viewer.setCallbacks( ...
                    @obj.keyPressed, ...
                    @obj.mouseButtonPressed, ...
                    @obj.mouseButtonReleased, ...
                    @obj.mouseMoved, ...
                    @obj.callbackForFilterChange, ...
                    @obj.callbackForFilterChange, ...
                    @obj.setViews, ...
                    @obj.movieListClicked...
                    );


            end

            function obj =          movieListClicked(obj, ~, ~)

                switch obj.Viewer.getMousClickType
                    case 'open'
                        obj = obj.openSelectedMovie;
                end 

            end
        
          
    end
    
    methods (Access = private) % SETTERS MOVIE-LIBRARY
        
          function obj = saveActiveMovieAndLibrary(obj)
              
              try
                  
                  if obj.ActiveMovieController.verifyActiveMovieStatus 
                        obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(obj.MovieLibrary); % set current file paths by movie library;
                        obj.ActiveMovieController =     obj.ActiveMovieController.saveMovie;
                        obj.MovieLibrary =              obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);

                  end
                  
              catch
                 warning('Library could not be saved for unknown reason.') 
                 
              end
              
              obj.MovieLibrary =              obj.MovieLibrary.saveMovieLibraryToFile;
              
          end

          function obj = changeToNewLibraryWithFileName(obj, FileName)
               
             
                [a, ~, ~] = fileparts(FileName);
                obj.MovieLibrary =              PMMovieLibrary(...
                                        FileName, ...
                                        a, ...
                                        a, ...
                                        a...
                                        );
                                                
                      obj =                       obj.saveActiveMovieAndLibrary;
                obj =                       obj.setEmpyActiveMovieController;                
                obj.savePreviousSettings; 
                obj =                       obj.updateFilterView;
                      
                      
             
       
          end
          
          function obj = letUserAddNewMovie(obj)
                 ListWithMovieFileNames =    obj.MovieLibrary.askUserToSelectMovieFileNames;
                 NickName =                  obj.MovieLibrary.askUserToEnterUniqueNickName;
                 obj =                       obj.addNewMovie(NickName, ListWithMovieFileNames);
             
         end
         
    end
    
    methods (Access = private) % GETTERS MOVIE-LIBRARY
        
           function Library = getMovieLibraryForInput(obj, varargin)
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    PreviouslyUsedFileName = obj.getPreviouslyUsedFileName;
                    if isempty(PreviouslyUsedFileName)
                        Library =   PMMovieLibrary();
                    else
                        Library =   PMMovieLibrary(PreviouslyUsedFileName);
                    end
                    
                case 1
                    Type = class(varargin{1});
                    switch Type
                        case 'char'
                            Library = PMMovieLibrary(varargin{1});
                        case 'PMMovieLibrary'
                            Library = varargin{1};
                        otherwise
                            error('Wrong input.')
                    end
                    
                otherwise
                    error('Wrong number of arguments.')

            end
            
           end
        
    end
    
    methods (Access = private)
        
         function obj =           changeNameOfLinkeMoviesClicked(obj,~,~)
             if isempty(obj.ActiveMovieController.getLoadedMovie)
                 warning('Currently no movie loaded. Cannot complete request.')
                 
             else
                obj.FileManagerViewer =        PMFileManagementViewer(PMFileManagement(obj.MovieLibrary.getMovieFolder, obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames));
                obj.FileManagerViewer =        obj.FileManagerViewer.setCallbacks(@obj.renameFiles);
             end
             
         end
         
         function [obj] =           renameFiles(obj,~,~)
             
            obj.FileManagerViewer =     obj.FileManagerViewer.resetSelectedFiles;
            NewFileNames =              obj.FileManagerViewer.getFileNames;
            OldFileNames =              obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames;

            cellfun(@(x, y) PMFileManagement(obj.MovieLibrary.getMovieFolder).renameFile(x, y), OldFileNames, NewFileNames);
            obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(NewFileNames);

            
            for index = 1 : length(OldFileNames)
                 obj.MovieLibrary =     obj.MovieLibrary.changeMovieFileNamesFromTo(OldFileNames{index}, NewFileNames{index});
            end
            
            
           obj =                  obj.updatesAfterChangingMovieController;
            
           
            
            
         end
   
             
       
         
        
        
        %% callbacks for drift correction:
     
           
            
     

            function obj = userLoadsExistingLibrary(obj)
                Path = obj.userSelectsFileNameOfProject;
                if isempty(Path)
                else
                    
                      obj =                   obj.saveActiveMovieAndLibrary;
                    obj.MovieLibrary =      PMMovieLibrary(Path);
                    obj =                       obj.saveActiveMovieAndLibrary;
                obj =                       obj.setEmpyActiveMovieController;                
                obj.savePreviousSettings; 
                obj =                       obj.updateFilterView;
                end
            end

            function [Path] = userSelectsFileNameOfProject(obj)
                 [FileName,SelectedPath] =   uigetfile('.mat', 'Load existing project');
                 if SelectedPath== 0
                    Path = '';
                 else
                    Path = [SelectedPath, FileName];
                 end
            end

         

            function savePreviousSettings(obj)
                fprintf('PMMovieLibraryManager:@savePreviousSettings. During next start program will try to open file "%s".\n',  obj.MovieLibrary.getFileName)
                FileNameOfProject=           obj.MovieLibrary.getFileName;
                save(obj.FileWithPreviousSettings, 'FileNameOfProject')
            end

        
        
        
        
 
        
        function obj = createDerivativeFiles(obj, ~, ~)
            obj =             obj.batchProcessingOfNickNames(obj.MovieLibrary.getAllNicknames,'createDerivativeFiles');
        end
        
        
      
          %% batchProcessingChannel
          function obj = batchProcessingChannel(obj, ~, ~)
                 obj =        obj.batchProcessingOfNickNames(obj.Viewer.getSelectedNicknames, 'SetChannelsByActiveMovie');
          end
          
        
          
        
        
             function [obj] =            setViews(obj, ~,  ~)
            
                obj.Viewer =    obj.Viewer.updateWith(obj.MovieLibrary);
             end
            
             
   
         
      
         
     
         
       
         
    
        function obj =        callbackForFilterChange(obj, ~, ~) 
                obj = obj.updateFilterView;
        end
        
        function obj = updateFilterView(obj)
            
            obj.MovieLibrary =          obj.MovieLibrary.updateFilterSettingsFromPopupMenu(...
                                        obj.Viewer.getProjectViews.FilterForKeywords,  ...
                                        obj.Viewer.getProjectViews.RealFilterForKeywords);
            
                                    
            obj.Viewer =                obj.Viewer.updateWith(obj.MovieLibrary);
        end
        
        
      
    
        
        
        
        
     
         
    
        
        
         
         
 
    
       
        

        %% response to help menu click:
        
        
        function [obj] = showKeyboardShortcuts(obj,~,~)

            ShortcutsKeys{1,1}=         '--------KEYS-----------------------';
            ShortcutsKeys{2,1}=         '--------Navigation-----------------';
            ShortcutsKeys{3,1}=         '"Left arrow": one frame back';
            ShortcutsKeys{4,1}=         '"Right arrow": one frame forward';
            ShortcutsKeys{5,1}=         '"Up arrow": one plane up';
            ShortcutsKeys{6,1}=         '"Down arrow": one plane down';
            ShortcutsKeys{7,1}=         '"x": go to first frame';
            ShortcutsKeys{8,1}=         '"m": Toggle maximum-projection';
            ShortcutsKeys{9,1}=         '"o": Toggle between cropped and uncropped';
            ShortcutsKeys{10,1}=         '';
            ShortcutsKeys{11,1}=         '"1" to "9": Toggle visibility of channels 1 to 9';
            ShortcutsKeys{12,1}=         '';

            ShortcutsKeys{13,1}=        '-------Annotation------------------';
            ShortcutsKeys{14,1}=        '"i": Toggle visibility of time label';
            ShortcutsKeys{15,1}=        '"z": Toggle visibility of z-position label';
            ShortcutsKeys{16,1}=        '"s": Toggle visibility of scale bar';
            ShortcutsKeys{17,1}=         '';

            ShortcutsKeys{18,1}=        '-------Tracking--------------------';
            ShortcutsKeys{19,1}=        '"c": Toggle visibility of centroids';
            ShortcutsKeys{20,1}=        '"a": Toggle visibility of masks';
            ShortcutsKeys{21,1}=        '"t": Toggle visibility of trajectories';
            ShortcutsKeys{22,1}=        '"u": update tracks in TrackingResults model';
            ShortcutsKeys{23,1}=        '"n": select next track in track-list';
   
            ShortcutsKeys{25,1}=        '"p": select previous track in track-list';
            ShortcutsKeys{26,1}=        '';


            MouseMovement{1,1}=         '--------MOUSE-ACTION-----------------------------------';

            MouseMovement{2,1}=         'control-drag: move field of view';
            MouseMovement{3,1}=         'alt-drag: draw cropping rectange';
            MouseMovement{4,1}=         'down or drag: edit current mask (tracking only)';
            MouseMovement{5,1}=         'shift-down or shift-drag: create new track and edit current mask (tracking only)';
            MouseMovement{6,1}=         'shift-down or shift-drag: create new position for drift correction (drift correction only)';
            MouseMovement{7,1}=         'command-down or command-drag: remove pixels from current mask (tracking only)';
            MouseMovement{8,1}=         'shift/command-down or shift/command-drag: add pixels to current mask (tracking only)';
            MouseMovement{9,1}=         '';

            msgbox([ShortcutsKeys;MouseMovement])
            
        end
        
        function obj = showKeyboardShortcutsForTracking(obj, ~, ~)
            
                     ShortcutsKeys=      {  '"b": add pixel rim to current mask'; ...
                                            '-----------------------------------'; ...
                                             '"d": Go to last tracked mask of current track streatch'; ...
                                             '"shift-d": go to first frame of active track'; ...
                                             '"shift-command-d": delete active track'; ...
                                             '-----------------------------------'; ...
                                             '"e": remove pixel rim from current mask'; ...
                                             '-----------------------------------'; ...
                                             '"shift-command-f": set active track to finished and go to next unfinished track'; ...
                                             '-----------------------------------'; ...
                                             '"g": toggle forward gaps'; ...
                                             '"shift-g": forward and backward tracking of all incomplete tracks'; ...
                                             '"shift-command-g": go to first tracked frame from current point'; ...
                                             '-----------------------------------'; ...
                                             '"shift-i": toggle forward track gaps (ignore completeness)'; ...
                                             '"shift-command-i": toggle forward gaps'; ...
                                              '-----------------------------------'; ...
                                             '"l": auttracking when no mask in next frame (*)'; ...
                                             '-----------------------------------'; ...
                                             '"shift-m": merge two selected tracks (or one selected and one active track)'; ...
                                             '"shift-command-m": merge tracks by proximity (*)'; ...
                                             '-----------------------------------'; ...
                                             '"shift-command-p": fill gaps of active track'; ...
                                             '-----------------------------------'; ...
                                             '"r": autoforward tracking of active track (with edge detection)'; ...
                                             '"shift-r": minimize all masks of current track (*)'; ...
                                             '"shift-command-r": recreate masks of current track (*)'; ...
                                             '-----------------------------------'; ...
                                             '"shift-s": delete active track before active frame'; ...
                                             '"shift-command-s": delete active track after active frame'; ...
                                              '-----------------------------------'; ...
                                             '"shift-command-t": truncate active track so that it connects with selected track'; ...
                                              '-----------------------------------'; ...
                                             '"shift-command-u": set active track to unfinished and go to another track'; ...
                                             '-----------------------------------'; ...
                                             '"v": add pixel rim to current mask'; ...
                                             '"v": auto backward tracking of active track (with edge detection)'; ...
                                             '"command-v": toggle backward gaps'; ...
                                              '-----------------------------------'; ...
                                             '"w": add pixel rim to current mask'; ...
                                             '"command-w": split active track after active frame'; ...
                                             '-----------------------------------'; ...
                                             '"*": use not recommended'; ...
                                             };
                                         
                      msgbox([ShortcutsKeys])
        end
        
        
      
        
        
        
    end
    
    methods (Access = private) % interaction

        function obj = showInteractionsViewer(obj, ~, ~)
            obj.InteractionsManager =    obj.InteractionsManager.showView;
            obj =                       obj.addCallbacksToInteractionManager;
        end

        

        function obj =  addCallbacksToInteractionManager(obj)
            obj.InteractionsManager =               obj.InteractionsManager.setCallbacks(...
                                                                                            @obj.interactionsManagerAction, ...
                                                                                            @obj.updateInteractionSettings...
                                                                                            );    
        end

        function obj = interactionsManagerAction(obj, ~, ~)

            switch obj.InteractionsManager.getUserSelection

                case 'Write raw analysis to file'
                   
                    InteractionObject =             obj.InteractionsManager.getInteractionTrackingObject;
                    Nickname =                      obj.ActiveMovieController.getNickName;
                    Path =                          [obj.MovieLibrary.getInteractionFolder , Nickname, '.mat'];
                    save(Path, 'InteractionObject');

                case 'Write interaction map into file'

                    obj = obj.saveInteractionsMapForActiveMovie;

                otherwise
                    error('Wrong input.')

            end

        end


        function obj = updateInteractionSettings(obj, ~, ~)
            obj.InteractionsManager =       obj.InteractionsManager.updateModelByView;
            obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(obj.InteractionsManager);

        end
 
    end
    
end