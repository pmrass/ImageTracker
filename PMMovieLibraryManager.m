classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties (Access = private)

        Viewer
        MovieLibrary 
        ActiveMovieController =            PMMovieController()
        MovieTrackingFileController =      PMMovieTrackingFileController
        InteractionsManager =              PMInteractionsManager      
        TrackSegmentView
        
        FileManagerViewer
        
    end
    
    properties % add accessors and make private;
          DistanceLimits = {[0, 8];  [2, 8]; [0, 1]};
          DistanceType =  'FractionFullPixels';
    end
    
    properties (Access = private) % default settings for some advanced analysis
       
        XYLimitForNeighborArea =                50;
        ZLimitsForNeighborArea =                8;
        
        StopDistanceLimit =                     15;
        MaxStopDurationForGoSegment =           5;
        MinStopDurationForStopInterval =        20;
        
    end
    
    properties(Access = private, Constant)
        FileWithPreviousSettings =         [userpath,'/imans_PreviouslyUsedFile.mat'];
    end
    
    methods % initialization
        
        function obj =          PMMovieLibraryManager(varargin)

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    myFileName =   obj.getPreviouslyUsedFileName;
                case 1
                    myFileName =  varargin{1};
                otherwise
                    error('Wrong number of arguments.')
            end
            
            assert(~isempty(myFileName) && ischar(myFileName) && exist(myFileName) == 2, 'Invalid filename. Please enter a valid file-path as argument of this intializer.')
            
            obj.Viewer =            PMImagingProjectViewer;
            obj.Viewer.getMovieControllerView.blackOutMovieView;
            obj.Viewer =            obj.Viewer.adjustViews([11.5 0.1 21 3.5]);

            obj =                   obj.addCallbacksToFileAndProject;

            obj =                   obj.setFileMenu;
            obj =                   obj.setProjectMenu;
            obj =                   obj.setMovieMenu;
            obj =                   obj.setDriftMenu;
            obj =                   obj.setTrackingMenu;
            obj =                   obj.setInteractionsMenu;
            obj =                   obj.setHelpMenu;

            obj.MovieLibrary =      PMMovieLibrary(myFileName);            
            obj =                   obj.resetAfterLibraryChange;

       end
        
        function set.ActiveMovieController(obj, Value)
            assert(isa(Value,  'PMMovieController'), 'Wrong input type.')
           obj.ActiveMovieController = Value;
        end
        
         function set.MovieLibrary(obj, Value)
           assert(isa(Value,  'PMMovieLibrary'), 'Wrong input type.')
           obj.MovieLibrary = Value; 
        end
        
    end
    
    methods  % movie-list clicked
        
        function [obj] =         movieListClicked(obj, ~, ~)
          
            switch obj.Viewer.getMousClickType

                case 'open'
                  
            end 
            
        end
        
        function obj = openSelectedMovie(obj)
            
              SelectedNicknames =     obj.Viewer.getSelectedNicknames;
                    if length(SelectedNicknames) == 1

                        obj =           obj.finishOffCurrentLibrary;
                        obj =          obj.setActiveMovieByNickName(SelectedNicknames{1});

                    end
                    
        end
        

        function obj =          setActiveMovieByNickName(obj, varargin)

            switch length(varargin)
                
                case 1
                    obj.MovieLibrary=                       obj.MovieLibrary.switchActiveMovieByNickName(varargin{1});
                    obj.ActiveMovieController =             obj.MovieLibrary.getActiveMovieController(obj.Viewer);

                    obj.Viewer =                            obj.Viewer.updateWith(obj.MovieLibrary);  
                    obj.MovieTrackingFileController =       obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
                    obj =                                   obj.addCallbacksToInteractionManager;
                    obj.InteractionsManager =               obj.InteractionsManager.setMovieController(obj.ActiveMovieController);
                    obj =                                   obj.setInfoTextView;


                otherwise
                    error('Invalid number of arguments')
            end


        end

     end
   
    methods % getter
        
        function obj = showSummary(obj)
            obj.ActiveMovieController = obj.ActiveMovieController.showSummary;
        end
        
        
         function controller = getActiveMovieController(obj)
           controller  = obj.ActiveMovieController ;
         end
        
       function library = getMovieLibrary(obj)
            library = obj.MovieLibrary;

       end
        
        
    end
    
    methods

        function obj = setActiveMovieController(obj, Value)
           obj.ActiveMovieController  = Value;
        end

        function obj = setMovieLibrary(obj, Value)
            obj.MovieLibrary = Value;
        end

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
          

        
    
        
        function obj = setMovieFolders(obj, Value)
            obj.MovieLibrary =              obj.MovieLibrary.setMovieFolders(Value);
            obj =                           obj.finishOffCurrentLibrary;
            obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
            obj =                           obj.setInfoTextView;
        end
        
        function [obj]=             setInfoTextView(obj)
             obj.Viewer =   obj.Viewer.setInfoView(obj.MovieLibrary.getProjectInfoText);  
        end
        
        function obj = setInfoTextViewWith(obj, Value)
            
             obj.Viewer =   obj.Viewer.setInfoView(Value);  
            
        end
        
        
        
     

      
    
        
        
         
     
             
  
        
      
        
      
      
        
  
     

        function [obj] =    toggleProjectInfo(obj,~,~)
            obj =                               obj.setInfoTextView;
            
        end
       
  
         %% respond to mouse or key input:
          function [obj] =           keyPressed(obj,~,~)
              
              
                 if isempty(obj.getPressedKey) || ~obj.ActiveMovieController.verifyActiveMovieStatus

                 else
                     
                    if strcmp(obj.getPressedKey, 's') && length(obj.getModifier) == 1 && strcmp(obj.getModifier, 'command')
                         obj = obj.finishOffCurrentLibrary;
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
          
          function PressedKey = getPressedKey(obj)
              PressedKey=       get(obj.Viewer.getFigure,'CurrentCharacter');
          end
          
          function Modifier = getModifier(obj)
              Modifier =   obj.Viewer.getFigure.CurrentModifier;
              
          end
          
        function verifiedStatus =                     verifyActiveMovieStatus(obj)
            verifiedStatus = obj.ActiveMovieController.verifyActiveMovieStatus;
        end
          
          function [obj] =          mouseButtonPressed(obj,~,~)
              obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonPressed(obj.getPressedKey, obj.getModifier);
          end

          function [obj] =          mouseMoved(obj,~,~)
              obj.ActiveMovieController = obj.ActiveMovieController.mouseMoved(obj.getPressedKey, obj.getModifier);
          end
            
          function [obj] =          mouseButtonReleased(obj,~,~)
              try 
                    obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonReleased(obj.getPressedKey, obj.getModifier);    
              catch E
                   throw(E) 
              end
                
          end
          
          
          
       
        

        
        function [obj] =            sliderActivity(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setFrameBySlider;
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
                    obj =       obj.finishOffCurrentLibrary;
                    obj =       obj.changeToNewLibraryWithFileName([SelectedPath, FileName]);
                end
             end

        function [obj] =    saveProjectClicked(obj,~,~)
               obj =        obj.finishOffCurrentLibrary;
        end
        
        function [obj] =    loadProjectClicked(obj,~,~)
            obj =   obj.userLoadsExistingLibrary;
        end
                    
       
        
     
        
        
    end
    
    methods (Access = private) % project menu
             
        function obj = setProjectMenu(obj)

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
                            @obj.showMissingCaptures,...
                            @obj.toggleProjectInfo,...
                    };

                SeparatorList = {'off', 'off', 'off', ...
                                  'on', 'off', 'off', 'off', ...
                                  'on', 'off', 'off', 'off', 'off', ...
                                  'on', 'off'};


        obj.Viewer =    obj.Viewer.setMenu('ProjectMenu', 'Project', MenuLabels, CallbackList, SeparatorList);

        end

        function obj =    setPathForImageAnalysis(obj, ~, ~)

            NewPath=          uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select tracking folder',...
            'NumFiles', 1, 'Output', 'char');

            if isempty(NewPath) || ~ischar(NewPath)
            else
            obj = obj.setImageAnalysisPath(NewPath);

            end

        end

        function obj =    changeMovieFolderClicked(obj,~,~)
            NewPath=          uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select movie folder',...
            'NumFiles', 1, 'Output', 'char');
            if isempty(NewPath) || ~ischar(NewPath)
            else
            obj = obj.addMovieFolder(NewPath);
            end
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
            obj.ActiveMovieController =     obj.ActiveMovieController.deleteImageAnalysisFile;
            obj.MovieLibrary =              obj.MovieLibrary.removeActiveMovieFromLibrary;
            obj =                           obj.callbackForFilterChange;
            obj =                           obj.setEmpyActiveMovieController;  
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

        function obj =  showMissingCaptures(obj,~,~)   

        obj.Viewer = obj.Viewer.setInfoView(obj.MovieLibrary.getFileNamesOfUnincorporatedMovies);


        end

        function obj = updateMovieSummaryFromFiles(obj,~,~)
        obj.MovieLibrary = obj.MovieLibrary.updateMovieSummariesFromFiles;
        end

        function obj = replaceKeywords(obj,~,~)
            
            NewKeyword = inputdlg('Enter the keyword that should replace keywords of currently filtered movies.');
            obj.MovieLibrary.showSummary;
            NickNames =     obj.MovieLibrary.getListWithFilteredNicknames;
            obj =           obj.batchProcessingOfNickNames(NickNames, 'changeKeywords', NewKeyword{1});
        end
  
    end
    
    methods (Access = private) % set movie-menu
        
        function obj =  setMovieMenu(obj)

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

        function obj =  editMovieSettingsClicked(obj,~,~)
            obj =  obj.resetMovieTrackingFileController;
        end

        function obj =  resetMovieTrackingFileController(obj)    
             if isempty(obj.ActiveMovieController.getLoadedMovie)
                 fprintf('Currently no movie in memory. Cannot generate MovieTracking view.\n')
             else
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.resetView;
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.setCallbacks(@obj.changeNicknameClicked, @obj.changeKeywordClicked);
             end
        end

        function obj =  changeNicknameClicked(obj,~,~)

        MyNewNickName =                 obj.MovieTrackingFileController.getNickNameFromView;
        obj.ActiveMovieController =     obj.ActiveMovieController.setNickName(MyNewNickName);

        obj =               obj.updatesAfterChangingMovieController;

         if length(obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames) == 1

            obj =                   obj.renameLinkedFileNamesOfActiveMovie({obj.convertNickNameIntoFileName(MyNewNickName)});

         end

        end

        function obj =  updatesAfterChangingMovieController(obj)
            obj.MovieLibrary =                      obj.MovieLibrary.setNickName(obj.ActiveMovieController);
            obj.MovieLibrary =                      obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
            obj.MovieTrackingFileController =       obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);

            obj =                                   obj.callbackForFilterChange;

            obj =                            obj.setInfoTextView;

        end

        function FileName = convertNickNameIntoFileName(obj, NickName)
         FileName =        [NickName, obj.ActiveMovieController.getLoadedMovie.getMovieFileExtension];
        end

        function obj =  renameLinkedFileNamesOfActiveMovie(obj, NewFileNames) 
            cellfun(@(x, y) PMFileManagement(obj.MovieLibrary.getMovieFolder).renameFile(x, y), obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames, NewFileNames) 
            obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(NewFileNames);
            obj =                            obj.updatesAfterChangingMovieController;

        end

        function obj =  changeKeywordClicked(obj,~,~)

        if isempty(obj.MovieTrackingFileController.getKeywordFromView)
        else 
              obj.ActiveMovieController =   obj.ActiveMovieController.setKeywords(obj.MovieTrackingFileController.getKeywordFromView);
              obj =                         obj.updatesAfterChangingMovieController;



        end

        end
        
        function obj =  changeLinkedMoviesClicked(obj,~,~)
                obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(obj.MovieLibrary.askUserToSelectMovieFileNames);
                obj =                           obj.updatesAfterChangingMovieController;
         end
             
        function obj =  reapplySourceFilesClicked(obj,~,~)
             if isempty(obj.ActiveMovieController)
             else
                 obj.ActiveMovieController =      obj.ActiveMovieController.resetLoadedMovieFromImageFiles;
             end
        end
        
        function  obj = deleteImageCacheClicked(obj,~,~) 
            if isempty(obj.ActiveMovieController) 
            else
                obj.ActiveMovieController    =      obj.ActiveMovieController.emptyOutLoadedImageVolumes;
                obj.ActiveMovieController =           obj.ActiveMovieController.blackOutViews;
            end
        end
        
        function obj =  exportMovie(obj,~,~)

            obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
            myMovieManager =                PMImagerViewerMovieManager(obj.ActiveMovieController);
          
            myMovieManager =                myMovieManager.showExportWindow;
            waitfor(myMovieManager.getDoneHandle, 'Value')
            myMovieManager.exportMovie;
            
        end
        
        function obj =  exportImage(obj, ~, ~)
            obj.ActiveMovieController =     obj.ActiveMovieController.setExportFolder(obj.MovieLibrary.getExportFolder);
            obj.ActiveMovieController =     obj.ActiveMovieController.exportCurrentFrameAsImage;
            
        end
        
        function obj =  exportTrackCoordinates(obj,~,~)
            obj.ActiveMovieController =     obj.ActiveMovieController.exportTrackCoordinates;
        end
        
        function obj = exportDetailedMetaDataIntoFile(obj, ~, ~)
            obj.ActiveMovieController = obj.ActiveMovieController.saveMetaData(obj.MovieLibrary.getExportFolder); 
        end
        
        function obj = showMetaDataSummary(obj, ~, ~)
             obj.Viewer =               obj.Viewer.setInfoView(obj.ActiveMovieController.getMetaDataSummary);
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
            obj = obj.finishOffCurrentLibrary;
            obj =  updatesAfterChangingMovieController(obj);
            
        end
        
       function  obj = eraseAllDriftCorrectionsClicked(obj,~,~)
             obj.ActiveMovieController =         obj.ActiveMovieController.setDriftCorrection('remove'); 
         obj = obj.finishOffCurrentLibrary;
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
    
    methods % setters project:
       
           function obj =          setImageAnalysisPath(obj, NewPath)
                obj.MovieLibrary =              obj.MovieLibrary.setPathForImageAnalysis(NewPath);  
                obj =                           obj.setInfoTextView;

           end
        
            function obj = addMovieFolder(obj, Value)
                obj.MovieLibrary =                  obj.MovieLibrary.addMovieFolder(Value);
                obj =                           obj.finishOffCurrentLibrary;
                try 
                    obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                catch
                    error('Could not reset movie controller.')
                end
                obj =                           obj.setInfoTextView;
            end
        
                function obj = setExportFolder(obj, UserSelectedFolder)
                      obj.MovieLibrary =              obj.MovieLibrary.setExportFolder(UserSelectedFolder);
                           % obj =                           obj.Viewer.getSelectedNicknames;
                        %    obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                            obj =                           obj.setInfoTextView;
            
                end
                
                
         function obj =          addNewMovie(obj, Nickname, AttachedFiles)
             
             if obj.MovieLibrary.checkWheterNickNameAlreadyExists(Nickname)
                warning('Nickname already exists and could therefore not be added.')
                 
             else
                   NewMovieTracking = PMMovieTracking(...
                Nickname, ...
                obj.MovieLibrary.getMovieFolder, ...
                AttachedFiles, ...
                obj.MovieLibrary.getPathForImageAnalysis, ...
                'Initialize' ...
                );

                NewMovieController =                    PMMovieController(obj.Viewer, NewMovieTracking);
                
                obj.MovieLibrary =                      obj.MovieLibrary.updateMovieListWithMovieController(NewMovieController);
                obj.MovieLibrary=                       obj.MovieLibrary.switchActiveMovieByNickName(Nickname);
                obj.MovieLibrary =                      obj.MovieLibrary.sortByNickName;
                
                 
                
                obj.ActiveMovieController =             obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                
                obj = obj.finishOffCurrentLibrary;

                obj.Viewer =                            obj.Viewer.updateWith(obj.MovieLibrary);  
                obj.MovieTrackingFileController =       obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
                obj =                                   obj.addCallbacksToInteractionManager;
                obj.InteractionsManager =               obj.InteractionsManager.setMovieController(obj.ActiveMovieController);
                obj =                                   obj.setInfoTextView;
    
                obj =                                   obj.callbackForFilterChange;
                
               
                 
             end
              

         end
        
        
        
    end
    
    methods (Access = private)% callbacks for file and project:
       
           function [obj] =        addCallbacksToFileAndProject(obj)

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
          
        
        
    end
    
    methods (Access = private) % create new library
        
          function obj = finishOffCurrentLibrary(obj)
              
              if obj.ActiveMovieController.verifyActiveMovieStatus && obj.MovieLibrary.allPropertiesAreValid
                obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(obj.MovieLibrary);
                obj.ActiveMovieController =     obj.ActiveMovieController.saveMovie;

                obj.MovieLibrary =              obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
                obj.MovieLibrary =              obj.MovieLibrary.saveMovieLibraryToFile;
                
              end
              
          end

            
          

          function obj = changeToNewLibraryWithFileName(obj, FileName)
               
                obj =                   obj.finishOffCurrentLibrary;
              
                [a, ~, ~] = fileparts(FileName);
                obj.MovieLibrary =              PMMovieLibrary(...
                                        FileName, ...
                                        a, ...
                                        a, ...
                                        a...
                                        );
                                                
                      obj =                  obj.resetAfterLibraryChange;
                      
                      
             
       
          end
          
           function obj = letUserAddNewMovie(obj)
                 ListWithMovieFileNames =    obj.MovieLibrary.askUserToSelectMovieFileNames;
                 NickName =                  obj.MovieLibrary.askUserToEnterUniqueNickName;
                 obj =                       obj.addNewMovie(NickName, ListWithMovieFileNames);
             
         end
         
          
         
           function obj = setEmpyActiveMovieController(obj)
                obj.ActiveMovieController=      PMMovieController(obj.Viewer);  
                obj.Viewer.getMovieControllerView.blackOutMovieView;
                obj.Viewer =    obj.Viewer.updateWith(obj.MovieLibrary);
           end

           
        
        
    end
    
    methods (Access = private)
        
           %% changeNameOfLinkeMoviesClicked
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
                NewFileNames =           obj.FileManagerViewer.getFileNames;
                obj =                    obj.renameLinkedFileNamesOfActiveMovie(NewFileNames);
         end
   
             
       
         
        
        
        %% callbacks for drift correction:
     
           
            
     

            function obj = userLoadsExistingLibrary(obj)
                Path = obj.userSelectsFileNameOfProject;
                if isempty(Path)
                else
                    
                      obj =                   obj.finishOffCurrentLibrary;
                    obj.MovieLibrary =      PMMovieLibrary(Path);
                    obj =                  obj.resetAfterLibraryChange;
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

            function [obj] =             resetAfterLibraryChange(obj)

                obj.MovieLibrary =      obj.MovieLibrary.testIntactnessOfLibrary;
                
                obj =                   obj.finishOffCurrentLibrary;
                
                obj =                   obj.setEmpyActiveMovieController;                
                obj.Viewer.getMovieControllerView.blackOutMovieView;

                obj.savePreviousSettings; 

                obj.MovieLibrary =          obj.MovieLibrary.updateFilterSettingsFromPopupMenu(...
                            obj.Viewer.getProjectViews.FilterForKeywords,  ...
                            obj.Viewer.getProjectViews.RealFilterForKeywords);

                obj.Viewer =                obj.Viewer.updateWith(obj.MovieLibrary);
                
                
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
            
            obj.Viewer =                obj.Viewer.updateWith(obj.MovieLibrary);
            
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
                                             '"f": autodetect masks of current frame (*)'; ...
                                             '"shift-f": autodetect masks by circle recognition'; ...
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
    
    methods  % batchProcessingOfNickNames
        
          function obj =        batchProcessingOfNickNames(obj, NickNames, ActionType, varargin)
            
            originalNickName =        obj.MovieLibrary.getSelectedNickname;  
            OriginalController =        obj.ActiveMovieController;
              
            obj =                           obj.finishOffCurrentLibrary;
            
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
                
                obj =                           obj.finishOffCurrentLibrary;
                obj.ActiveMovieController.getViews.updateSaveStatusWith(obj.ActiveMovieController.getLoadedMovie);
                obj =                           obj.setInfoTextView;
                obj=                            obj.callbackForFilterChange;
            end
            
            obj =         obj.setActiveMovieByNickName(originalNickName);
            
          end
        
         
          
        
        
    end
    
    methods % interaction
        
        function obj = saveInteractionsMapsForAllShownMovies(obj)
            SelectedNicknames =     obj.Viewer.getSelectedNicknames;
             [obj] =        obj.batchProcessingOfNickNames(SelectedNicknames, 'saveInteractionMap');

            
        end
        
        
         function obj = saveInteractionsMapForActiveMovie(obj, varargin) 
             
             switch length(varargin)
                 case 0
                     
                 case 2
                     
                        obj.XYLimitForNeighborArea = varargin{1};
                        obj.ZLimitsForNeighborArea =  varargin{2};

        
                 otherwise
                     error('Wrong input.')
    
             end
             
            obj =                          obj.initializeInteractionManager;
            obj.InteractionsManager =       obj.InteractionsManager.setExportFolder(obj.MovieLibrary.getInteractionFolder); % specify folder if you want to export detailed interaction measurement specifications
            InteractionObject =             obj.InteractionsManager.getInteractionsMap;
            save(obj.getFileNameWithInteractionAnalysis, 'InteractionObject');

         end
            
         function fileName = getFileNameWithInteractionAnalysis(obj)
              Nickname =                      obj.ActiveMovieController.getNickName;
                fileName =                          [obj.MovieLibrary.getInteractionFolder , Nickname, '_Map.mat'];
             
         end
            
       
        function obj = exportDetailedInteractionInfoOfActiveTrack(obj, varargin)
            
             switch length(varargin)
                 case 0
                     
                 case 2
                     
                      obj.XYLimitForNeighborArea = varargin{1};
                            obj.ZLimitsForNeighborArea =  varargin{2};
        
        
                 otherwise
                     error('Wrong input.')
                      
        
                 
             end
             
            obj =                           obj.initializeInteractionManager;
            obj.InteractionsManager =       obj.InteractionsManager.setExportFolder(obj.MovieLibrary.getInteractionFolder);
            obj.InteractionsManager =       obj.InteractionsManager.exportDetailedInteractionInfoForTrackIDs(obj.ActiveMovieController.getLoadedMovie.getIdOfActiveTrack);
        end
        
        function obj = showTrackSummaryOfActiveMovie(obj)
            
            fprintf('\n*** Summary of tracking data of active movie:\n')
            mySuite = obj.getTrackingSuiteOfActiveMovie;
          
            fprintf('\n2) Summary of active track:\n')
            mySuite = mySuite.showSummaryOfTrackID(obj.ActiveMovieController.getLoadedMovie.getIdOfActiveTrack);

            fprintf('\n3) Summary of tracks, segments, etc. by distance to target:\n')
            for index = 1 : length(obj.DistanceLimits)
              mySuite = mySuite.showTrackSummaryForDistanceRange(obj.DistanceLimits{index}, obj.DistanceType);

            end

        end
        
        function mySuite = getTrackingSuiteOfActiveMovie(obj)
            
               % initialize tracking-suite:
            mySuite = PMTrackingSuite( obj.MovieLibrary.getFileName, 'CurrentMovieInManager', {obj.ActiveMovieController.getNickName}, {obj.getFileNameWithInteractionAnalysis});
            mySuite = mySuite.setSpaceTimeLimitsOfSuites(obj.StopDistanceLimit, obj.MinStopDurationForStopInterval, obj.MaxStopDurationForGoSegment);
            fprintf('\n1) Summary of tracking suite:\n')
             mySuite.showSummary;
            
        end
        
        
    end
    
    methods (Access = private) % interaction

        function obj = showInteractionsViewer(obj, ~, ~)

          obj = obj.initializeInteractionView;

        end

        function obj = initializeInteractionView(obj)
            obj.InteractionsManager = obj.InteractionsManager.setMovieController(obj.ActiveMovieController);

           obj.InteractionsManager = obj.InteractionsManager.showView;
            obj =                     obj.addCallbacksToInteractionManager;

        end

        function obj =  addCallbacksToInteractionManager(obj)
            obj.InteractionsManager =               obj.InteractionsManager.setCallbacks(@obj.interactionsManagerAction, @obj.updateInteractionSettings);    
        end

        function obj = interactionsManagerAction(obj, ~, ~)


            switch obj.InteractionsManager.getUserSelection

                case 'Write raw analysis to file'
                     obj = obj.initializeInteractionManager;
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

        function obj = initializeInteractionManager(obj)

            if ~obj.InteractionsManager.testViewsAreSetup
                obj = obj.initializeInteractionView;    
            end

            obj.InteractionsManager =       obj.InteractionsManager.updateModelByView;
            obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(obj.InteractionsManager);
            obj.InteractionsManager =       obj.InteractionsManager.setMovieController(obj.ActiveMovieController);

            obj.InteractionsManager =       obj.InteractionsManager.setXYLimitForNeighborArea(obj.XYLimitForNeighborArea);
            obj.InteractionsManager =       obj.InteractionsManager.setZLimitForNeighborArea(obj.ZLimitsForNeighborArea);
        end

        function obj = updateInteractionSettings(obj, ~, ~)

            obj.InteractionsManager =       obj.InteractionsManager.updateModelByView;
            obj.ActiveMovieController =     obj.ActiveMovieController.updateWith(obj.InteractionsManager);
            obj.InteractionsManager =       obj.InteractionsManager.setMovieController(obj.ActiveMovieController);

            Volume =                        obj.InteractionsManager.getImageVolume;
            obj.ActiveMovieController =     obj.ActiveMovieController.setInteractionImageVolume(Volume);

        end
 
    end
    
end