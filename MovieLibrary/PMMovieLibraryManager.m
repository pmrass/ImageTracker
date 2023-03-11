classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties (Access = private)

        
        
        MovieLibrary 
        ActiveMovieController
        
          
        
        
     
        
        StopDistanceLimit =                     15;
        MaxStopDurationForGoSegment =           5;
        MinStopDurationForStopInterval =        20;
        
 
    end
    
    properties (Access = private) % views
        
        Viewer
        
        MovieControllerView
        
        FileManagerViewer
        
        MovieTrackingFileView
     
        TrackingNavigationView
        
        
        AutoCellRecognitionView
        SegementationCaptureView
         
        TrackSegmentView
        
        InteractionsView
        
        AutoTrackingView
         TrackingAutoTrackingController =        PMAutoTrackingController
        
    end
    
    properties % add accessors and make private;
          DistanceLimits =      {[0, 8];  [2, 8]; [0, 1]};
          DistanceType =        'FractionFullPixels';
    end
    

    
    properties(Access = private, Constant)
        FileWithPreviousSettings =         [userpath,'/imans_PreviouslyUsedFile.mat'];
    end
    
    methods % INITIALIZATION
        
        function obj =      PMMovieLibraryManager(varargin)
            % PMMOVIELIBRARYMANAGER create instance of this class
            % takes 0 or 1 arguments:
            % 0: empty library
            % 1: character string: complete path of library or 'Previous': tries to load previous library;
        
           
            obj.Viewer =                PMImagingProjectViewer;
            
            switch length(varargin)
                
                case 0
                     Library =   PMMovieLibrary();
                    

                    
                case  1


                    Type = class(varargin{1});
                    
                    switch Type
                    
                        case 'char'
                        
                        switch varargin{1}
                            case 'Previous'
                            
                                 PreviouslyUsedFileName = obj.getPreviouslyUsedFileName;
                                    if isempty(PreviouslyUsedFileName)
                                        Library =   PMMovieLibrary();
                                    else
                                        Library =   PMMovieLibrary(PreviouslyUsedFileName);
                                    end
                                    
                            
                            
                            otherwise
                            
                               Library =              PMMovieLibrary(varargin{1});
                                     obj =                  obj.setMovieLibrary(Library);
                                     
                        
                        end
                        
                        case 'PMMovieLibrary'
                                        Library = varargin{1};
                                       
                        otherwise
                            error('Wrong input.')

                    end

   
                    end
            

             obj =                                  obj.setMovieLibrary(Library);

            obj.MovieTrackingFileView =             PMMovieTrackingFileView;

            obj.TrackingNavigationView =            PMTrackingNavigationView;

            obj.AutoTrackingView =                  PMAutoTrackingView;
            obj.AutoCellRecognitionView =           PMAutoCellRecognitionView;
            obj.SegementationCaptureView =          PMSegmentationCaptureView;

            obj.InteractionsView =                  PMInteractionsView;
 
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
            obj =                           obj.setMovieControllerView;

        end
         
   
        
    end
    
    methods % SETTERS
        
        function obj =      openSelectedMovie(obj)
            % OPENSELECTEDMOVIE activates currently selected movie;
            % only works when precisely one movie is selected 
            SelectedNicknames =     obj.Viewer.getSelectedNicknames;
            if length(SelectedNicknames) == 1
             %   obj =    obj.saveActiveMovieAndLibrary;
                obj =    obj.setActiveMovieByNickName(SelectedNicknames{1});
            end
                    
        end
        
        
        function obj =      setLoadedMovie(obj, LoadedMovie)
            % SETLOADEDMOVIE allows visualization of a user-defined PMMovieTracking object:
            % takes 1 argument:
            % 1: PMMovieTracking
            obj.ActiveMovieController  =          obj.ActiveMovieController.setLoadedMovie(LoadedMovie);
            obj.ActiveMovieController =           obj.ActiveMovieController.initializeViews;

         end
         
        function obj =      forwardUpdatedInteractionsManagerToMovieController(obj)
               MyInteractionsManager =              obj.getInteractionsManager;
              MyInteractionsManager =                MyInteractionsManager.resetModelByMovieTracking(obj.ActiveMovieController.getLoadedMovie);
              obj.ActiveMovieController =            obj.ActiveMovieController.performMovieTrackingMethod(...
                                                        'setInteractionsCapture', MyInteractionsManager.getModel);
                 
            
        end
        
        function obj =      setMovieDependentViews(obj)            
            
            
            % this is important: otherwise movie-frames will be loaded internally from segmentation and this will not be saved in memory;
            obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('updateLoadedImageVolumes', 'Active');
            
            
            
            
            MyTrackingFileController =          obj.getMovieTrackingFileController;
            MyTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
             
            obj =                                   obj.updateTrackingNavigationView;
            
            if ~isempty( obj.SegementationCaptureView)
                obj.SegementationCaptureView =          obj.SegementationCaptureView.set( obj.ActiveMovieController.getSegmentationCapture);
            end
           
            obj.getAutoCellRecognitionController.setViewByModel;
            obj.ActiveMovieController =             obj.ActiveMovieController.initializeViews;
            
            obj =                                   obj.setInfoTextView;
                   

        end
        
        function obj =      updateTrackingNavigationView(obj)
            
            trackingNavigationController =      obj.getTrackingNavigationController;
            trackingNavigationController =      trackingNavigationController.updateView;
            trackingNavigationController =      obj.updateHandlesForTrackingNavigationEditView(trackingNavigationController);
            obj.TrackingNavigationView =        trackingNavigationController.getView;
  
        end
        
        
       
        
        
    end
    
    methods % GETTERS: AUTOCELLRECOGNITION:
        
          function MyAutoRecognitionController = getAutoCellRecognitionController(obj)

                MyModel =                           obj.ActiveMovieController.getLoadedMovie.getAutoCellRecognition;
             
                MyAutoRecognitionController =       PMAutoCellRecognitionController(...
                   MyModel , ...
                    obj.AutoCellRecognitionView...
                    ) ;
            
          end
 
    end

    methods % SETTERS: MOVIECONTROLLER
       
        function obj =      setActiveMovieByNickName(obj, varargin)
            % SETACTIVEMOVIEBYNICKNAME change active movie
            % takes 1 argument:
            % 1: character string with nickname
            % updates views and content including MovieTrackingFileController;
            % also updates callbacks;

            switch length(varargin)
                
                case 1
                    
                
                    obj.MovieLibrary=                           obj.MovieLibrary.switchActiveMovieByNickName(varargin{1});
                    obj.ActiveMovieController =                 obj.MovieLibrary.getActiveMovieController;
                    
                    assert(~isempty(obj.ActiveMovieController), 'Something went wrong. No active movie-controller could be retrieved')
                    
                    obj.ActiveMovieController =                 obj.ActiveMovieController.setMovieDependentProperties;
                    obj =                                       obj.forwardUpdatedInteractionsManagerToMovieController;
                    
                    
                    % the following should be relevant for views only:
                    obj.Viewer =                                obj.Viewer.updateWith(obj.MovieLibrary);
                    obj.ActiveMovieController =                 obj.ActiveMovieController.setView(obj.MovieControllerView);
                    
                    obj =                                       obj.setAutoTrackingView(obj.AutoTrackingView);
                    
                    obj =                                       obj.setMovieDependentViews;
                    
                    obj =                                       obj.addCallbacksToInteractionManager;
                    obj =                                       obj.addCallbacksToFileAndProject;
           
                otherwise
                    error('Invalid number of arguments')
            end


        end
      
        function obj =      setActiveMovieController(obj, Value)
           % SETACTIVEMOVIECONTROLLER set active movie-controller
           % takes 1 argument:
           % 1: scalar PMMovieController
           obj.ActiveMovieController  = Value;
           
        end
        
        function obj =      setEmpyActiveMovieController(obj)
            obj.ActiveMovieController=          PMMovieController;  
            obj.Viewer =                        obj.Viewer.updateWith(obj.MovieLibrary);
            obj.ActiveMovieController =         obj.ActiveMovieController.setView(obj.MovieControllerView);
                  
        end
         
        function obj =      performMovieControllerMethod(obj, varargin)
            % CALLMOVIECONTROLLERMETHOD allows usage of method from active movie-controller;
            % takes 1 or more arguments:
            % 1: name of method
            % 2: arguments for method (number depends on method)
            obj.ActiveMovieController = obj.ActiveMovieController.(varargin{1})(varargin{2:end});
            
        end
        
        function obj =  performMovieTrackingMethod(obj, varargin)
            obj.ActiveMovieController = obj.ActiveMovieController.performMovieTrackingMethod(varargin{1}, varargin{2:end});
            
         
            
        end
         
    end
    
    methods % GETTERS: MOVIECONTROLLER
       
         function controller =     getActiveMovieController(obj)
                % GETACTIVEMOVIECONTROLLER returns active movie controller
                assert(~isempty(obj.ActiveMovieController), 'No movie controller set.')
                controller  = obj.ActiveMovieController ;
          end
        
    end
   
    methods % SETTERS MOVIE-LIBRARY
       
         function obj =         setMovieLibrary(obj, Value)
             % SETMOVIELIBRARY set movie-library
             % takes 1 argument:
             % 1: scalar 'PMMovieLibrary'
             % updates project movies and movie controller
            obj.MovieLibrary =          Value;
        
            obj =                       obj.setEmpyActiveMovieController;       
            obj.savePreviousSettings; 
            
         end

         function obj =         deleteAllEntriesOfLibrary(obj)
               %DELETEALLENTRIESOFLIBRARY delete all entries in library also delete connected files;
              AllNickNames = obj.MovieLibrary.getAllNicknames;
            for index = 1:length(AllNickNames)
                obj = obj.removeEntryWithNickName(AllNickNames{index});
            end
            
         end


         function obj = deleteAllSelectedMovies(obj, ~, ~)

              SelectedNicknames =     obj.Viewer.getSelectedNicknames;
              for index = 1:length(SelectedNicknames)
                obj = obj.removeEntryWithNickName(SelectedNicknames{index});
            end

         end
        
         function obj =         performMovieLibraryMethod(obj, varargin)
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
                     assert(ischar(varargin{1}), 'Wrong input.')
                     MyMethod = varargin{1};
                     MyParameters = varargin{2:end};
                    Output = obj.MovieLibrary.(MyMethod)(MyParameters);
                    if isa(Output, 'PMMovieLibrary')
                        obj.MovieLibrary = Output;
                    end

            end
               
         end
      
      
    end
    
    methods % GETTERS
        
          function library =        getMovieLibrary(obj)
              % GETMOVIELIBRARY returns movie-library
                library = obj.MovieLibrary;
          end

         
        
     end
    
    methods % SETTERS BATCH-PROCESSING
        
          function obj =            batchProcessingOfNickNames(obj, NickNames, ActionType, varargin)
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
        
        function obj =              saveInteractionsMapsForAllShownMovies(obj)
            % SAVEINTERACTIONSMAPSFORALLSHOWNMOVIES save interaction map for all selected movies;
            SelectedNicknames =     obj.Viewer.getSelectedNicknames;
            obj =                   obj.batchProcessingOfNickNames(SelectedNicknames, 'saveInteractionMap');

        end

        function obj =              saveInteractionsMapForActiveMovie(obj) 
            % SAVEINTERACTIONSMAPFORACTIVEMOVIE saves interaction map for active movie;
            MyInteractionsManager  = obj.getInteractionsManager;

            InteractionObject =             MyInteractionsManager.getInteractionsMap;
            save(obj.getFileNameWithInteractionAnalysis, 'InteractionObject');

        end

        function obj =              exportDetailedInteractionInfoOfActiveTrack(obj, varargin)
            % EXPORTDETAILEDINTERACTIONINFOOFACTIVETRACK export detailed interaction of active track;
            MyInteractionsManager  =        obj.getInteractionsManager;
           
         %   MyInteractionsManager.getModel.showTargetImage;
            MyInteractionsManager.exportDetailedInteractionInfoForTrackIDs(...
                obj.ActiveMovieController.getLoadedMovie.getIdOfActiveTrack, ...
                varargin{:});
        end
 
        function obj =              showTrackSummaryOfActiveMovie(obj)

            fprintf('\n*** Summary of tracking data of active movie:\n')
            mySuite = obj.getTrackingSuiteOfActiveMovie;

            fprintf('\n2) Summary of active track:\n')
            mySuite = mySuite.showSummaryOfTrackID(obj.ActiveMovieController.getLoadedMovie.getIdOfActiveTrack);

            fprintf('\n3) Summary of tracks, segments, etc. by distance to target:\n')
            for index = 1 : length(obj.DistanceLimits)
              mySuite = mySuite.showTrackSummaryForDistanceRange(obj.DistanceLimits{index}, obj.DistanceType);

            end

        end

        function mySuite =          getTrackingSuiteOfActiveMovie(obj)
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
        
        function fileName =         getFileNameWithInteractionAnalysis(obj)
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

   methods  % SETTERS SAVE LIBRARY FROM FILE

      function obj =    saveActiveMovieAndLibrary(obj)

            if  ~isempty(obj.ActiveMovieController) && obj.ActiveMovieController.verifyActiveMovieStatus 
                    obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(obj.MovieLibrary); % set current file paths by movie library;
                    obj.ActiveMovieController =     obj.ActiveMovieController.saveMovie;
                    obj.MovieLibrary =              obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);

            end


            if ~isempty(obj.MovieLibrary)
              obj.MovieLibrary =              obj.MovieLibrary.saveMovieLibraryToFile;
            end


      end

      function obj =    changeToNewLibraryWithFileName(obj, FileName)


            [a, ~, ~] = fileparts(FileName);
            obj.MovieLibrary =              PMMovieLibrary(...
                                    FileName ...
                                    );

           % obj =                       obj.saveActiveMovieAndLibrary;
            obj =                       obj.setEmpyActiveMovieController;                
            obj.savePreviousSettings; 
            obj =                       obj.updateFilterView;




      end

      function obj =    letUserAddNewMovie(obj)
             ListWithMovieFileNames =    obj.MovieLibrary.askUserToSelectMovieFileNames;
             NickName =                  obj.MovieLibrary.askUserToEnterUniqueNickName;
             obj =                       obj.addNewMovieWithNicknameFiles(NickName, ListWithMovieFileNames);

     end

   end

    methods (Access = private) % AUTOTRACKING
        
        function obj =      manageTrackingAutoTracking(obj,~,~) 
            
            MyAutoTracking =    obj.ActiveMovieController.getLoadedMovie.getTracking.getAutoTracking;
            obj.TrackingAutoTrackingController =         obj.TrackingAutoTrackingController.resetModelWith(...
                                                        MyAutoTracking, ...
                                                        'ForceDisplay'...
                                                        );
            obj =             obj.setAutoTrackingView(obj.TrackingAutoTrackingController.getView);
            obj =             obj.setCallbacksForAutoTracking;                                           

        end

        function obj =      setAutoTrackingView(obj, Value)

        obj.TrackingAutoTrackingController =        obj.TrackingAutoTrackingController.setView(Value);

        obj.TrackingAutoTrackingController =         obj.TrackingAutoTrackingController.resetModelWith(...
                                                            obj.ActiveMovieController.getLoadedMovie.getTracking.getAutoTracking, ...
                                                            'Update figure' ...
                                                            );                                    
        obj.AutoTrackingView = obj.TrackingAutoTrackingController.getView; % necessary



        end

        function obj =      setCallbacksForAutoTracking(obj)
            obj.AutoTrackingView = obj.AutoTrackingView.setCallbacks(...
                @obj.respondToMaximumAcceptedDistanceForAutoTracking, ...
                @obj.respondToFirstPassDeletionFrameNumber, ...
                @obj.respondToConnectionGapsValueChanged, ...
                @obj.respondToConnectionGapsXYLimitChanged, ...
                @obj.respondToConnectionGapsZLimitValueChanged, ...
                @obj.respondToShowMergeInfoValueChanged, ...
                @obj.startAutoTrackingPushed ...
            );

            end

        function obj =      respondToMaximumAcceptedDistanceForAutoTracking(obj, ~, ~)
            obj = obj.setTrackingNavigationByAutoTrackingView;
        end

        function obj =      setTrackingNavigationByAutoTrackingView(obj)
            obj.TrackingAutoTrackingController =      obj.TrackingAutoTrackingController.setModelByView;
            obj.ActiveMovieController =               obj.ActiveMovieController.updateTrackingWith(obj.TrackingAutoTrackingController.getModel);
        end

        function obj =      respondToFirstPassDeletionFrameNumber(obj, ~, ~)
            obj.ActiveMovieController = obj.ActiveMovieController.setTrackingNavigationByAutoTrackingView;
        end

        function obj =      respondToShowMergeInfoValueChanged(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setTrackingNavigationByAutoTrackingView;
        end

        function obj =      respondToConnectionGapsValueChanged(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setTrackingNavigationByAutoTrackingView;
        end

        function obj =      respondToConnectionGapsXYLimitChanged(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setTrackingNavigationByAutoTrackingView;
        end

        function obj =      respondToConnectionGapsZLimitValueChanged(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setTrackingNavigationByAutoTrackingView;
        end

        function obj =      startAutoTrackingPushed(obj,~,~)

        switch obj.TrackingAutoTrackingController.getUserSelection

            case 'Tracking by minimizing object distances'
                obj.ActiveMovieController =             obj.ActiveMovieController.trackByMinimizingDistancesOfTracks;

            case 'Delete tracks'
                obj.ActiveMovieController =             obj.ActiveMovieController.unTrack;

            case 'Connect exisiting tracks with each other'
                obj.ActiveMovieController.LoadedMovie =   obj.ActiveMovieController.LoadedMovie.performTrackingMethod('performSerialTrackReconnection');

            case 'Track-Delete-Connect'
                obj.ActiveMovieController.LoadedMovie =   obj.ActiveMovieController.LoadedMovie.performAutoTrackingOfExistingMasks;

        end


        obj.ActiveMovieController =           obj.ActiveMovieController.initializeViews;
        obj.ActiveMovieController =           obj.ActiveMovieController.updateMovieView;
        obj.ActiveMovieController =           obj.ActiveMovieController.updateAllViewsThatDependOnActiveTrack;

        end

    end
      
    methods (Access = private) % SETTERS: CALLBACKS FOR FILE-MANAGEMENT;
        
        function obj =      setFileMenu(obj)
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
       % obj =       obj.saveActiveMovieAndLibrary;
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
    
    methods (Access = private) % SETTERS: LOAD LIBRARY FROM FILE
                
            function obj = userLoadsExistingLibrary(obj)
                Path = obj.userSelectsFileNameOfProject;
                if isempty(Path)
                else
                    
                %    obj =                       obj.saveActiveMovieAndLibrary;
                    obj.MovieLibrary =          PMMovieLibrary(Path, 'LoadMasks');
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
  
    end
         
    methods (Access = private) % SETTERS

   
        
        function obj =      setExportFolder(obj, UserSelectedFolder)
                obj.MovieLibrary =              obj.MovieLibrary.setExportFolder(UserSelectedFolder);
                % obj =                           obj.Viewer.getSelectedNicknames;
             
                obj =                           obj.setInfoTextView;

        end

        function obj =      addNewMovieWithNicknameFiles(obj, Nickname, AttachedFiles)

                try
            
                    if obj.MovieLibrary.checkWheterNickNameAlreadyExists(Nickname)
                        warning('Nickname already exists and could therefore not be added.')

                    else

                        obj =                   obj.saveActiveMovieAndLibrary;
 
                        NewMovieTrackingList = obj.MovieLibrary.getListOfMovieTrackingsForNickNameAttachedFilesPositions(Nickname, AttachedFiles);

                    
                         for sceneIndex = 1 : length(NewMovieTrackingList)
                           
                                 obj =                                  obj.addNewMovieByMovieTracking(NewMovieTrackingList(sceneIndex));
            
                         end
                    end
                
                catch
                      warning('Movie could not be added for unknown reason.')
                        
                        
                end


        end
        
    
     

      

       

        
        function obj = addNewMovieByMovieTracking(obj, NewMovieTracking)
               NewMovieTracking =                  NewMovieTracking.setPropertiesFromImageMetaData;

               NewMovieController =                 PMMovieController(...
                                                                    NewMovieTracking ...
                                                                    );

                obj.MovieLibrary =                  obj.MovieLibrary.addNewEntryToMovieList(NewMovieController);
                
                obj =                               obj.setActiveMovieByNickName(NewMovieTracking.getNickName);
                obj =                               obj.callbackForFilterChange;
                obj =                               obj.saveActiveMovieAndLibrary;
                
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

                     
                        if strcmp(obj.getPressedKey, 'o') && isempty(obj.getModifier)
                            
                            obj.Viewer = obj.Viewer.setPositions;
                        end
                        
                        obj.ActiveMovieController.interpretKey(obj.getPressedKey, obj.getModifier);    
                end


             end

             obj.Viewer = obj.Viewer.setCurrentCharacter('0');


        end

        function obj =          mouseButtonPressed(obj,~,~)
             if ~isempty(obj.ActiveMovieController)
                obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonPressed(obj.getPressedKey, obj.getModifier);
             end

        end

        function obj =          mouseMoved(obj,~,~)
            if ~isempty(obj.ActiveMovieController)
                obj.ActiveMovieController = obj.ActiveMovieController.mouseMoved(obj.getPressedKey, obj.getModifier);
            end

        end

        function obj =          mouseButtonReleased(obj,~,~)
             if ~isempty(obj.ActiveMovieController)
                      obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonReleased(obj.getPressedKey, obj.getModifier);    
                      obj = obj.updateTrackingNavigationView;   
             end
        end

        function obj =          sliderActivity(obj,~,~)
             if ~isempty(obj.ActiveMovieController)
                obj.ActiveMovieController = obj.ActiveMovieController.setFrameBySlider;
             end
        end

        
    end
    
    methods (Access = private) % SETTERS VIEWS
        
        function obj=       setInfoTextView(obj)
             obj.Viewer =   obj.Viewer.setInfoView(obj.MovieLibrary.getProjectInfoText);  
        end
        
        function obj =      setInfoTextViewWith(obj, Value)
             obj.Viewer =   obj.Viewer.setInfoView(Value);   
        end
        
        function obj =      setMovieControllerView(obj)
            obj.MovieControllerView =           PMMovieControllerView(obj.Viewer);
         end
        
        function obj =      finalizeProjectViews(obj)
            
             if obj.Viewer.MenusAlreadySet
                 
             else
                    obj =                       obj.setMenus;
                    obj =                       obj.addCallbacksToFileAndProject;
                   
             end
             
            obj =                       obj.updateFilterView;
            
        end
        
        function obj =      setMenus(obj)
            
            obj =                       obj.setFileMenu;
            obj =                       obj.setProjectMenu;
            obj =                       obj.setMovieMenu;
            obj =                       obj.setDriftMenu;
            obj =                       obj.setTrackingMenu;
            obj =                       obj.setInteractionsMenu;
            obj =                       obj.setHelpMenu;
           
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
                    'Delete all selected movies'; ...
                    'Delete all entries in library'; ...
                    'Batch: Remap all movies'; ...
                    'Replace keywords'; ...
                    'Update movie summaries from file'; ...
                    'Create derivative files'; ...
                    'Batch: replace selected movies by active movie: channels'; ...
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
                            @obj.deleteAllSelectedMovies,...
                            @obj.removeAllMoviesClicked,...
                            @obj.mapUnMappedMovies,...
                            @obj.replaceKeywords,...
                            @obj.updateMovieSummaryFromFiles,...
                            @obj.createDerivativeFiles,...
                            @obj.batchProcessingChannel...
                            @obj.showIncludedCaptures,...
                            @obj.showMissingCaptures,...
                            @obj.toggleProjectInfo,...
                    };

                SeparatorList = {'off', 'off', 'off', ...
                                  'on', 'off', 'off', 'off', 'off', ...
                                  'on', 'off', 'off', 'off', 'off', ...
                                  'on', 'off', 'off'};


        obj.Viewer =    obj.Viewer.setMenu('ProjectMenu', 'Project', MenuLabels, CallbackList, SeparatorList);

        end

        function obj =          setPathForImageAnalysis(obj, ~, ~)
             obj.MovieLibrary =         obj.MovieLibrary.letUserSetAnnotationPath;
             obj =                      obj.updateAfterAnnotationPathChange;

        end
        
       function obj =      updateAfterAnnotationPathChange(obj)
           obj.ActiveMovieController =  obj.ActiveMovieController.updateWith(obj.MovieLibrary);
           obj =                        obj.setInfoTextView;
       end
        

        function obj =          changeMovieFolderClicked(obj,~,~)
            obj.MovieLibrary =      obj.MovieLibrary.letUserSetMovieFolder;
            obj =                   obj.updateAfterChangingMovieFolder;
            
             
        end
        
        
        function obj =      updateAfterChangingMovieFolder(obj)
            
           
            obj =                               obj.saveActiveMovieAndLibrary;
            obj.ActiveMovieController =             obj.MovieLibrary.getActiveMovieController;
            obj.ActiveMovieController =         obj.ActiveMovieController.setView(obj.MovieControllerView);
            obj.ActiveMovieController =         obj.ActiveMovieController.initializeViews;
            obj =                               obj.setInfoTextView;
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
            for FileIndex= 1 : size(missingFiles,1)
                CurrentFileName =       missingFiles{FileIndex,1};
                obj =                   obj.addNewMovieWithNicknameFiles(...
                                                        obj.convertFileNameIntoNickName(CurrentFileName), ...
                                                        {CurrentFileName});
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
                  obj = obj.deleteAllEntriesOfLibrary;
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
            obj =  obj.showMovieTrackingFileController;
        end

        function obj =          showMovieTrackingFileController(obj)    
             if isempty(obj.ActiveMovieController.getLoadedMovie)
                 fprintf('Currently no movie in memory. Cannot generate MovieTracking view.\n')
             else
                 
                MyController =          obj.getMovieTrackingFileController;   
                MyController =          MyController.show;
                
                obj.MovieTrackingFileView = MyController.getView;
                 
                
                obj.MovieTrackingFileView =     obj.MovieTrackingFileView.setCallbacks(...
                        @obj.changeNicknameClicked, ...
                        @obj.changeKeywordClicked...
                        );
             end
        end

        function obj =          changeNicknameClicked(obj,~,~)

            MyNewNickName =                 obj.getMovieTrackingFileController.getNickNameFromView;
            obj.ActiveMovieController =     obj.ActiveMovieController.setNickName(MyNewNickName);
            obj.MovieLibrary =              obj.MovieLibrary.changeNickNameOfSelectedMovie(MyNewNickName);

            obj =                           obj.updatesAfterChangingMovieController;

        end

        function obj =          updatesAfterChangingMovieController(obj)
          
            obj.MovieLibrary =                      obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
            
            MyMovieTrackingFileController =         obj.getMovieTrackingFileController;
            MyMovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
            obj =                                   obj.callbackForFilterChange;
            obj =                                   obj.setInfoTextView;

        end

        function FileName =     convertNickNameIntoFileName(obj, NickName)
            FileName =        [NickName, obj.ActiveMovieController.getLoadedMovie.getMovieFileExtension];
        end

        function obj =          changeKeywordClicked(obj,~,~)

            if isempty(obj.getMovieTrackingFileController.getKeywordFromView)
            else 
                  obj.ActiveMovieController =   obj.ActiveMovieController.setKeywords(obj.getMovieTrackingFileController.getKeywordFromView);
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
                obj.ActiveMovieController    =      obj.ActiveMovieController.performMovieTrackingMethod('emptyOutLoadedImageVolumes');
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
    
    methods (Access = private) % MOVIETRACKING-FILES
        
        
        function controller = getMovieTrackingFileController(obj)
            
            MyMovie = obj.ActiveMovieController.getLoadedMovie;
            if ~isempty(MyMovie)
                
                 controller = PMMovieTrackingFileController(...
                     obj.MovieTrackingFileView, ...
                     MyMovie ...
                     );
            else
                
                
                 controller = PMMovieTrackingFileController(...
                     obj.MovieTrackingFileView, ...
                     PMMovieTracking ...
                     );
                
            end
            
           
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
       
    methods (Access = private) % SETTERS TRACKING MENU:
       
        function obj =      setTrackingMenu(obj)
              
                MenuLabels = {'Show track editing window', 'Delete all tracks','Show autotracking window', 'Show autorecognition window', 'Show segmentation capture window',  'Edit track segments'};

                CallbackList =   {...
                                @obj.manageTrackingEditAndView, ...
                                @obj.askUserToDeleteTrackingData, ...
                                 @obj.manageTrackingAutoTracking, ...
                                @obj.manageAutoCellRecognition,...
                                @obj.showSegmentationCapture,...
                                @obj.manageTrackSegments ...
                                
                };
            
              SeparatorList = {'off', 'off', ...
                                    'on', 'off', 'off', ...
                                      'on'};


                obj.Viewer =    obj.Viewer.setMenu('TrackingMenu', 'Tracking', MenuLabels, CallbackList, SeparatorList);
    
         end
        
        function obj =      manageAutoCellRecognition(obj,~,~)
            
            MyController =                  obj.getAutoCellRecognitionController;
            MyController =                  MyController.showFigure;
            MyController =                  MyController.setViewByModel;

            obj =                           obj.setCallBacksForAutoCellRecognitionWindow(MyController);
            
            obj.AutoCellRecognitionView =   MyController.getView;
       
              
        end
        
       
        
    end
              
    methods (Access = private) % TRACKING NAVIGATION
       
           function MyController =      updateHandlesForTrackingNavigationEditView(obj, MyController)

            

                MyController.setCallbacks(...
                    @obj.respondToTrackTableActivity, ...
                    @obj.respondToActiveFrameClicked, ...
                    @obj.respondToActiveTrackSelectionClicked, ...
                    @obj.respondToActiveTrackActivity, ...
                    @obj.respondToEditSelectedTrackSelectionClicked, ...
                    @obj.respondToSelectedTrackActivity ...
                    );
            end
            
            function obj = respondToTrackTableActivity(obj, ~, a)
                
                obj.ActiveMovieController = obj.ActiveMovieController.respondToTrackTableActivity(obj.getTrackingNavigationController, a);
                obj = obj.updateTrackingNavigationView;
            end
            
             function obj = respondToActiveFrameClicked(obj, ~, ~)
                obj.ActiveMovieController = obj.ActiveMovieController.respondToActiveFrameClicked(obj.getTrackingNavigationController);
                obj = obj.updateTrackingNavigationView;
                
             end
        
            
              function obj = respondToActiveTrackSelectionClicked(obj, ~, ~)
                obj.ActiveMovieController = obj.ActiveMovieController.respondToActiveTrackSelectionClicked(obj.getTrackingNavigationController);
                obj = obj.updateTrackingNavigationView;
                
              end
        
            
               function obj = respondToActiveTrackActivity(obj, ~, ~)
                obj.ActiveMovieController = obj.ActiveMovieController.respondToActiveTrackActivity(obj.getTrackingNavigationController);
                obj = obj.updateTrackingNavigationView;
                
               end
        
            
                function obj = respondToEditSelectedTrackSelectionClicked(obj, ~, ~)
                
                obj.ActiveMovieController = obj.ActiveMovieController.respondToEditSelectedTrackSelectionClicked(obj.getTrackingNavigationController);
                obj = obj.updateTrackingNavigationView;
                end
        
            
              function obj = respondToSelectedTrackActivity(obj, ~, ~)
                
                obj.ActiveMovieController = obj.ActiveMovieController.respondToSelectedTrackActivity(obj.getTrackingNavigationController);
                obj = obj.updateTrackingNavigationView;
                
              end
        
        
        
        
    end
    
    methods (Access = private) % SETTERS AND GETTERS AUTOCELLRECOGNITION

        function obj = setCallBacksForAutoCellRecognitionWindow(obj, MyController)

                      MyController.setCallBacks(...
                    @obj.AutoCellRecognitionChannelChanged,...
                    @obj.AutoCellRecognitionFramesChanged,...
                    @obj.AutoCellRecognitionTableChanged,...
                    @obj.changeOfAutoCellRecognitionView, ...
                    @obj.startAutoCellRecognitionPushed);
        end

        function obj =      AutoCellRecognitionChannelChanged(obj, ~, third)
                MyController =                      obj.getAutoCellRecognitionController;
            
                MyController =                      MyController.setActiveChannel(third.DisplayIndices(1));
                MyController =                      MyController.setModelByView;
                
                obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('setAutoCellRecognition', MyController.getModel);
                
        end

        function obj =      AutoCellRecognitionFramesChanged(obj, ~, third)
                MyController =                      obj.getAutoCellRecognitionController;

            myFrames =                      third.DisplayIndices(:, 1);
            MyController =                  MyController.setSelectedFrames(myFrames);
            MyController =                  MyController.setModelByView;
            
             obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('setAutoCellRecognition', MyController.getModel);

        end

        function obj =      AutoCellRecognitionTableChanged(obj,src,~)
            MyController =              obj.getAutoCellRecognitionController;
             
            MyController =              MyController.setCircleLimitsBy(src.Data);
            MyController =              MyController.setModelByView;
            
               obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('setAutoCellRecognition', MyController.getModel);

        end
        
        function obj =      changeOfAutoCellRecognitionView(obj, ~, ~)
            MyController =                      obj.getAutoCellRecognitionController;
            MyController =                      MyController.setModelByView;
            obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('setAutoCellRecognition', MyController.getModel);

        end
       
        function obj =      startAutoCellRecognitionPushed(obj,~,~)

            switch obj.getAutoCellRecognitionController.getUserSelection
                
                case 'Interpolate plane settings'
                        MyController =                  obj.getAutoCellRecognitionControllerInternal(View).interpolateCircleRecognitionLimits;  
            obj.AutoCellRecognition =       MyController.getModel;
                      
                case 'Circle recognition'
                    obj =                               obj.askUserToDeleteTrackingData;
                    obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('setTrackingAnalysis');
                    obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('executeAutoCellRecognition');
                    obj.ActiveMovieController =         obj.ActiveMovieController.updateAllViewsThatDependOnSelectedTracks;

                case 'Intensity recognition'
                    obj.ActiveMovieController =         obj.ActiveMovieController.performMovieTrackingMethod('autDetectMasksByIntensity');
                    obj.ActiveMovieController =         obj.ActiveMovieController.updateAllViewsThatDependOnSelectedTracks;
                    obj.ActiveMovieController =         obj.ActiveMovieController.updateAllViewsThatDependOnActiveTrack;
                 
            end
            
            obj = obj.updateTrackingNavigationView;

        end
        
        function obj =      resetAutoTrackingController(obj)
            obj.ActiveMovieController =        obj.ActiveMovieController.resetAutoTrackingController; 
        end
        
        function obj =      manageTrackingEditAndView(obj,~,~)
             obj = obj.showTrackingNavigationView;
        end
        
        function obj =      showTrackingNavigationView(obj)
            
            if ~isempty(obj.ActiveMovieController)  
                
                MyController =      obj.getTrackingNavigationController;
                MyController =      MyController.show;

                MyController =      obj.updateHandlesForTrackingNavigationEditView(MyController);
                
                obj.TrackingNavigationView = MyController.getView;
                
            end
            
            
        end
        
        function controller = getTrackingNavigationController(obj)
            
            if ~isempty(obj.ActiveMovieController.getLoadedMovie)
                
                controller = PMTrackingNavigationController(...
                                    obj.ActiveMovieController.getLoadedMovie.getTracking, ...
                                    obj.TrackingNavigationView...
                                    );
            else
                 controller = PMTrackingNavigationController(...
                                    PMTrackingNavigation, ...
                                    obj.TrackingNavigationView...
                                    );
                
                
            end
        end
           
        function obj =      setTrackingNavigationEditViewController(obj, varargin)
            
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
         
        function obj =      manageTrackSegments(obj, ~, ~)
            
            obj.TrackSegmentView =  PMStopTrackingSeriesViewer(15, 5, 20);
            obj.TrackSegmentView =  obj.TrackSegmentView.setCallbacks(...
                                            @obj.visualizeTrackSegments,...
                                            @obj.exportTrackSegments...
                                            );
         
        end
        
        function obj =      askUserToDeleteTrackingData(obj, ~, ~)
           obj.ActiveMovieController = obj.ActiveMovieController.askUserToDeleteTrackingData;
        end
        
        function obj =      setInteractionsMenu(obj)
                MenuLabels = { 'Set interaction parameters'};

                CallbackList =   {...
                                @obj.showInteractionsViewer,...
                };

                obj.Viewer =    obj.Viewer.setMenu('InteractionsMenu', 'Interactions', MenuLabels, CallbackList);
                  
        end
             
    end
    
    methods (Access = private) % SETTERS ACTION CALLBACKS FOR TRACKING;
        
      
        
        function obj =      visualizeTrackSegments(obj, ~, ~)
            
             obj.ActiveMovieController = obj.ActiveMovieController.setSegmentLineViews(obj.TrackSegmentView.getDistanceLimit, ...
                  obj.TrackSegmentView.getMinTimeLimit, ...
                  obj.TrackSegmentView.getMaxTimeLimit, ...
                  obj.TrackSegmentView.getVisibility );
              
        end
        
        function obj =      exportTrackSegments(obj, ~, ~)
            
            [StopTracks, GoTracks, StopMetric, GoMetric] = obj.ActiveMovieController.getStopGoTrackSegments(obj.TrackSegmentView.getDistanceLimit,  obj.TrackSegmentView.getMinTimeLimit, obj.TrackSegmentView.getMaxTimeLimit);

            FileName = obj.ActiveMovieController.getLoadedMovie.getBasicMovieTrackingFileName;
            
            save([FileName, '_StopTracksPixel.mat'], 'StopTracks')
            save([FileName, '_GoTracksPixel.mat'], 'GoTracks')
            save([FileName, '_StopTracksMetric.mat'], 'StopMetric')
            save([FileName, '_GoTracksMetric.mat'], 'GoMetric')
            
        end
        
        
        
        
    end
    
    methods (Access = private) % SETTERS HELP MENU:
       
         function obj =      setHelpMenu(obj)

              MenuLabels = { 'Show keyboard shortcuts', 'Show keyboard shortcuts for tracking'};

                CallbackList =   {...
                       @obj.showKeyboardShortcuts, ...
                @obj.showKeyboardShortcutsForTracking ...
                };

                obj.Viewer =    obj.Viewer.setMenu('HelpMenu', 'Help', MenuLabels, CallbackList);
                
                
        end
       
        
    end

    methods (Access = private) % SEGMENTATION CAPTURE
       
            function obj =      showSegmentationCapture(obj, ~, ~)
                    obj.SegementationCaptureView =      obj.SegementationCaptureView.show;
                    obj.SegementationCaptureView =      obj.SegementationCaptureView.set( obj.ActiveMovieController.getSegmentationCapture);
                    obj.SegementationCaptureView =      obj.SegementationCaptureView.setCallbacks(@obj.callBackForSegmentationCapture);

            end

            function obj =      callBackForSegmentationCapture(obj, ~, ~)
                OldSegmentationCapture =        obj.getSegmentationCapture;
                OldSegmentationCapture =        OldSegmentationCapture.set(obj.SegementationCaptureView);
                obj.ActiveMovieController =     obj.ActiveMovieController.performMovieTrackingMethod('setSegmentationCapture', OldSegmentationCapture);

           end
               
            function capture = getSegmentationCapture(obj)

                if ~isempty(obj.ActiveMovieController)
                    capture = obj.ActiveMovieController.getSegmentationCapture;
                else
                    capture = PMMovieTracking().getSegmentationCapture; 
                end



            end
               
    end
    
    methods (Access = private) % callbacks for file and project:
       
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
            
            if ~isempty(obj.MovieLibrary)
                obj.MovieLibrary =          obj.MovieLibrary.updateFilterSettingsFromPopupMenu(...
                                            obj.Viewer.getProjectViews.FilterForKeywords,  ...
                                            obj.Viewer.getProjectViews.RealFilterForKeywords);


                obj.Viewer =                obj.Viewer.updateWith(obj.MovieLibrary);

            end
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
    
    methods (Access = private) % INTERACTIONSCAPTURE

        function obj = showInteractionsViewer(obj, ~, ~)
              MyInteractionsManager = obj.getInteractionsManager;
          
            
            MyInteractionsManager = MyInteractionsManager.showView;
            obj.InteractionsView =  MyInteractionsManager.getView;
            obj =                       obj.addCallbacksToInteractionManager;
        end

        

        function obj =  addCallbacksToInteractionManager(obj)
            
          
            
            obj.InteractionsView = obj.InteractionsView.setCallbacks(...
                                                                                            @obj.interactionsManagerAction, ...
                                                                                            @obj.updateInteractionSettings...
                                                                                            );    
                                                                                        
                                                           
                                                                                       
          end

        function obj = interactionsManagerAction(obj, ~, ~)

            MyInteractionsManager = obj.getInteractionsManager;
            
            switch MyInteractionsManager.getUserSelection

                case 'Write raw analysis to file'
                   
                    InteractionObject =             MyInteractionsManager.getInteractionTrackingObject;
                    Nickname =                      obj.ActiveMovieController.getNickName;
                    Path =                          [obj.MovieLibrary.getInteractionFolder , Nickname, '.mat'];
                    save(Path, 'InteractionObject');

                case 'Write interaction map into file'

                    obj = obj.saveInteractionsMapForActiveMovie;
                    
                case 'Export detailed information of active track'
                    
                    obj = obj.exportDetailedInteractionInfoOfActiveTrack('SuppressMetric');

                otherwise
                    error('Wrong input.')

            end

        end


        function obj = updateInteractionSettings(obj, ~, ~)
            
            MyInteractionsManager =         obj.getInteractionsManager;
            MyInteractionsManager =         MyInteractionsManager.updateModelByView;
            obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(MyInteractionsManager);

        end
        
        function MyInteractionsManager = getInteractionsManager(obj)
            
            MyView =        obj.InteractionsView;
            MyModel =       obj.ActiveMovieController.getLoadedMovie.getInteractionsCapture;
            
            MyInteractionsManager =     PMInteractionsManager(...
                                                        MyView, ...
                                                        MyModel...
                                                        );
                                                    
            MyInteractionsManager =       MyInteractionsManager.setExportFolder(obj.MovieLibrary.getInteractionFolder);
                                                    
        end
 
    end
    
end