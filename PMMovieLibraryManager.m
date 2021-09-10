classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties (Access = private)

        Viewer
        MainProjectFolder =                userpath; %not in use right now
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
       
        XYLimitForNeighborArea = 50;
        ZLimitsForNeighborArea =  8;
        
        StopDistanceLimit =                     15;
        MaxStopDurationForGoSegment =           5;
        MinStopDurationForStopInterval =        20;
        
    end
    
    properties(Access = private, Constant)
        FileWithPreviousSettings =         [userpath,'/imans_PreviouslyUsedFile.mat'];
    end
    
     methods  % movie-list clicked
        
        function [obj] =         movieListClicked(obj, ~, ~)
            fprintf('\nPMMovieLibraryManager: @movieListClicked\n')

            switch obj.Viewer.getMousClickType

                case 'open'
                    SelectedNicknames =     obj.Viewer.getSelectedNicknames;
                    if length(SelectedNicknames) == 1

                        obj =      obj.finishOffCurrentLibrary;
                        obj =        obj.setActiveMovieByNickName(SelectedNicknames{1});

                    end
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
   
    methods % initialization
        
        function obj =          PMMovieLibraryManager(varargin)

            obj.Viewer =    PMImagingProjectViewer;
            obj.Viewer.MovieControllerViews.blackOutMovieView;
            obj =           obj.adjustViews;

            obj =           obj.addCallbacksToFileAndProject;

            obj =           obj.addCallbacksToFileMenu;
            obj =           obj.addCallbacksToProjectMenu;
            obj =           obj.addCallbacksToMovieMenu;
            obj =           obj.addCallbacksToDriftMenu;
            obj =           obj.addCallbacksToTrackingMenu;
            obj =           obj.addCallbacksToInteractionsMenu;
            obj =           obj.addCallbacksToHelpMenu;

            obj.MovieLibrary = PMMovieLibrary();

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    myFileName =   obj.getPreviouslyUsedFileName;
                case 1
                    myFileName =  varargin{1};
                otherwise
                    error('Wrong number of arguments')
            end

            if isempty(myFileName)
                obj =       obj.userLoadsExistingLibrary;
            else
                obj =       obj.changeLibraryToFileName(myFileName);
            end



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
        
        
   
       
         

           
       
         %% editMovieSettingsClicked:
         function obj = editMovieSettingsClicked(obj,~,~)
                obj =  obj.resetMovieTrackingFileController;
         end
        
         
        %% manageAutoCellRecognition
        function [obj] = manageAutoCellRecognition(obj,~,~)
            obj.ActiveMovieController =     obj.ActiveMovieController.showAutoCellRecognitionWindow;
          end
           
        %% manageTrackingAutoTracking
        function [obj] = manageTrackingAutoTracking(obj,~,~)
            obj =  obj.resetAutoTrackingController;
        end

        function obj =             resetAutoTrackingController(obj)
            obj.ActiveMovieController =        obj.ActiveMovieController.showAutoTrackingController; 
        end
           
        
        %% manageTrackSegments
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
        
        %% new helper views: TrackingNavigation
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

      
    
        
        
         
     
             
  
        
      
        
      
      
        
        %% updateMovieSummaryFromFiles
        function obj = updateMovieSummaryFromFiles(obj,~,~)
            obj.MovieLibrary = obj.MovieLibrary.updateMovieSummariesFromFiles;
        end
        
      
        %% replaceKeywords:
        function obj = replaceKeywords(obj,~,~)
            
            function [KeywordManagerSelection] = DoneField_KeywordManager(KeywordManagerHandles)
                    %DONEFIELD_KEYWORDMANAGER Summary of this function goes here
                    %   Detailed explanation goes here
                     if ~isvalid(KeywordManagerHandles.SelectFilterTypeSource)
                         KeywordManagerSelection.SourceKeywordType =    'Cancel';
                         return
                     end

                     KeywordManagerSelection.SourceKeywordType =        GetFieldname(KeywordManagerHandles.SelectFilterTypeSource.String{KeywordManagerHandles.SelectFilterTypeSource.Value});
                     KeywordManagerSelection.SourceKeyword =            KeywordManagerHandles.ListWithFilterWordsSource.String{KeywordManagerHandles.ListWithFilterWordsSource.Value};

                     KeywordManagerSelection.TargetKeywordType =        GetFieldname(KeywordManagerHandles.SelectFilterTypeTarget.String{KeywordManagerHandles.SelectFilterTypeTarget.Value});
                     KeywordManagerSelection.TargetKeyword =            KeywordManagerHandles.ListWithFilterWordsTarget.String{KeywordManagerHandles.ListWithFilterWordsTarget.Value};

                     close(KeywordManagerHandles.FigureHandle)


            end

            function [FieldName]= GetFieldname(String)
                switch String
                    case 'Keywords'
                       FieldName =  'Keyword';
                    case 'Technical'
                            FieldName =  'TechnicalComments';
                    case 'Conceptual'
                        FieldName =  'ConceptualComments';
                    case 'Delete'
                        FieldName =  'Delete';
                end
            end

            
            KeywordChangeViewer =                                       obj.Viewer.createKeywordEditorView;
            KeywordChangeViewer.ListWithFilterWordsTarget.String =      obj.MovieLibrary.getKeyWordList;
            KeywordChangeViewer.ListWithFilterWordsSource.String =      obj.MovieLibrary.getKeyWordList;
            waitfor(KeywordChangeViewer.DoneField,'Value')
            
            KeywordManagerSelection = DoneField_KeywordManager(KeywordChangeViewer);
             if strcmp(KeywordManagerSelection.SourceKeywordType, 'Cancel')
             else
                    obj.MovieLibrary =              obj.MovieLibrary.replaceKeywords(KeywordManagerSelection.SourceKeyword, KeywordManagerSelection.TargetKeyword);
                    obj =                           obj.setViews;
                    obj =                           obj.callbackForFilterChange;
                    obj =                           obj.setInfoTextView;
             end
             
            
              
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
                obj.Viewer.Figure.CurrentCharacter =                   '0';
                
          end
          
          function PressedKey = getPressedKey(obj)
              PressedKey=       get(obj.Viewer.Figure,'CurrentCharacter');
          end
          
          function Modifier = getModifier(obj)
              Modifier =   obj.Viewer.Figure.CurrentModifier;
              
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
          
          
          
       
        
        %% showCompleteMetaDataInfoClicked
        function [obj] = exportDetailedMetaDataIntoFile(obj, ~, ~)
            obj.ActiveMovieController = obj.ActiveMovieController.saveMetaData(obj.MovieLibrary.getExportFolder); 
        end
        
        function obj = showMetaDataSummary(obj, ~, ~)
             obj.Viewer =               obj.Viewer.setInfoView(obj.ActiveMovieController.getMetaDataSummary);
        end
        
        function [obj] =        exportMovie(obj,~,~)

            myMovieManager =                            PMImagerViewerMovieManager(obj.ActiveMovieController);
            myMovieManager.ExportFolder =               obj.MovieLibrary.getExportFolder;
            myMovieManager =                            myMovieManager.showExportWindow;
            waitfor(myMovieManager.ExportWindowHandles.Wait, 'Value')
            
            AdditionalName =                            myMovieManager.ExportWindowHandles.MovieName.String;
            myMovieManager.ExportFileName =             [obj.ActiveMovieController.getNickName '_' AdditionalName '.mp4'];

            myMovieManager.exportMovie;
            
        end
        
        function obj = exportImage(obj, ~, ~)
            
            obj.ActiveMovieController =     obj.ActiveMovieController.setExportFolder(obj.MovieLibrary.getExportFolder);
            obj.ActiveMovieController =     obj.ActiveMovieController.exportCurrentFrameAsImage;
            
            
        
        end
        
        function [obj] =        exportTrackCoordinates(obj,~,~)
            obj.ActiveMovieController =     obj.ActiveMovieController.exportTrackCoordinates;
        end
        
        function [obj] =            sliderActivity(obj,~,~)
            obj.ActiveMovieController = obj.ActiveMovieController.setFrameBySlider;
        end


    end
    
    
    
    methods (Access = private) % callbacks file menu
        
       
         
          
        
          function obj = addCallbacksToFileMenu(obj)
              obj.Viewer =    obj.Viewer.setFileMenuCallbacks(...
                            @obj.newProjectClicked, ...
                            @obj.saveProjectClicked, ...
                            @obj.loadProjectClicked);
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
            
        
      
          
         
        
        function obj =      addCallbacksToMovieMenu(obj)

            obj.Viewer =    obj.Viewer.setMovieMenuCallbacks(...
                @obj.editMovieSettingsClicked, ...
                @obj.changeNameOfLinkeMoviesClicked, ...
                @obj.changeLinkedMoviesClicked, ...
                @obj.reapplySourceFilesClicked, ...
                @obj.deleteImageCacheClicked, ...
                @obj.exportImage, ...
                @obj.exportMovie, ...
                @obj.exportTrackCoordinates, ...
                @obj.exportDetailedMetaDataIntoFile, ...
                @obj.showMetaDataSummary ...
        );
        
   
            

        end
        
        function obj =  addCallbacksToDriftMenu(obj)
             obj.Viewer =    obj.Viewer.setDriftMenuCallbacks(...
                 @obj.applyManualDriftCorrectionClicked, ...
                 @obj.eraseAllDriftCorrectionsClicked ...
         );
         
     

        end
        
      
        
        function [obj] =        addCallbacksToTrackingMenu(obj)
            
            obj.Viewer.TrackingViews.Menu.AutoCellRecognition.MenuSelectedFcn =      @obj.manageAutoCellRecognition;
            obj.Viewer.TrackingViews.Menu.AutoTracking.MenuSelectedFcn =             @obj.manageTrackingAutoTracking;
            obj.Viewer.TrackingViews.Menu.EditAndView.MenuSelectedFcn =              @obj.manageTrackingEditAndView;
            obj.Viewer.TrackingViews.Menu.TrackSegments.MenuSelectedFcn =              @obj.manageTrackSegments;
            % addlistener(obj.Viewer.MovieControllerViews.Navigation.TimeSlider,'Value','PreSet', @obj.sliderActivity);
    
        end
        
        function obj = addCallbacksToHelpMenu(obj)
             obj.Viewer =    obj.Viewer.setHelpMenuCallbacks(...
                @obj.showKeyboardShortcuts, ...
                @obj.showKeyboardShortcutsForTracking ...
                ); 
        end
        
        
        
    end
    
    methods
       
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
                obj.MovieLibrary =                      obj.MovieLibrary.saveMovieLibraryToFile;
                
                obj.ActiveMovieController =             obj.MovieLibrary.getActiveMovieController(obj.Viewer);

                obj.Viewer =                            obj.Viewer.updateWith(obj.MovieLibrary);  
                obj.MovieTrackingFileController =       obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
                obj =                                   obj.addCallbacksToInteractionManager;
                obj.InteractionsManager =               obj.InteractionsManager.setMovieController(obj.ActiveMovieController);
                obj =                                   obj.setInfoTextView;
    
                obj =                                   obj.callbackForFilterChange;

         end
        
        
        
    end
    
    methods (Access = private) % add calbbacks for project menu
       
            
          function obj = addCallbacksToProjectMenu(obj)
              obj.Viewer =    obj.Viewer.setProjectMenuCallbacks(...
                            @obj.setPathForImageAnalysis, ...
                            @obj.changeMovieFolderClicked, ...
                            @obj.changeExportFolderClicked,...
                            @obj.addMovieClicked,...
                            @obj.addAllMissingCaptures,...
                            @obj.removeMovieClicked,...
                            @obj.removeAllMoviesClicked,...
                            @obj.showMissingCaptures,...
                            @obj.mapUnMappedMovies,...
                            @obj.unmapAllMovies,...
                            @obj.createDerivativeFiles,...
                            @obj.updateMovieSummaryFromFiles,...
                            @obj.replaceKeywords,...
                            @obj.toggleProjectInfo,...
                            @obj.batchProcessingChannel...
                            );
              
          end
          
          
        function obj =           setPathForImageAnalysis(obj, ~, ~)

             NewPath=          uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select tracking folder',...
            'NumFiles', 1, 'Output', 'char');

            if isempty(NewPath) || ~ischar(NewPath)
            else
                obj = obj.setImageAnalysisPath(NewPath);

            end
            
        end

     

        function obj =        changeMovieFolderClicked(obj,~,~)
            NewPath=          uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select movie folder',...
            'NumFiles', 1, 'Output', 'char');
            if isempty(NewPath) || ~ischar(NewPath)
            else
                obj = obj.addMovieFolder(NewPath);
            end
        end

       
        
         
        function [obj] =        changeExportFolderClicked(obj,~,~)
                UserSelectedFolder=            uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select export folder',...
                'NumFiles', 1, 'Output', 'char');
                if isempty(UserSelectedFolder) || ~ischar(UserSelectedFolder)
                else
                  obj = obj.setExportFolder(UserSelectedFolder);
                end

        end
        
        
    
        

        function [obj] =        addMovieClicked(obj,~,~)
            obj = obj.letUserAddNewMovie;
        end
        

           function [obj] =        addAllMissingCaptures(obj,~,~)
                missingFiles =                          obj.MovieLibrary.getFileNamesOfUnincorporatedMovies;
                for FileIndex= 1:size(missingFiles,1)
                    CurrentFileName =   missingFiles{FileIndex,1};
                    obj =     obj.addNewMovie(obj.convertFileNameIntoNickName(CurrentFileName), {CurrentFileName});
                end
           end
           
           function nickName = convertFileNameIntoNickName(~, FileName)
              nickName =  FileName(1:end-4);
           end
        

        function [obj] =        removeMovieClicked(obj,~,~)
            answer = questdlg(['Are you sure you remove the movie ', obj.MovieLibrary.getSelectedNickname, ' from the library?  Al linked data (tracking, drift correction etc.) will also be deleted. This is irreversible.'], ...
            'Project menu', 'Yes',   'No','No');
            switch answer
                case 'Yes'
                    obj =                           obj.removeActiveEntry;   
            end

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
          
           
           
        function [obj] =        showMissingCaptures(obj,~,~)            
            obj.Viewer.InfoView.List.String =     obj.MovieLibrary.getFileNamesOfUnincorporatedMovies;
            obj.Viewer.InfoView.List.Value =      min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);
        end
        

           

        
    end
    
    methods (Access = private)% callbacks for file and project:
       
           function [obj] =        addCallbacksToFileAndProject(obj)
            
                obj.Viewer.Figure.WindowKeyPressFcn =                           @obj.keyPressed;
                obj.Viewer.Figure.WindowButtonDownFcn =                         @obj.mouseButtonPressed;
                obj.Viewer.Figure.WindowButtonUpFcn =                           @obj.mouseButtonReleased;
                obj.Viewer.Figure.WindowButtonMotionFcn =                       @obj.mouseMoved;

                obj.Viewer.ProjectViews.FilterForKeywords.Callback =            @obj.callbackForFilterChange;
                obj.Viewer.ProjectViews.RealFilterForKeywords.Callback =        @obj.callbackForFilterChange;
                obj.Viewer.ProjectViews.SortMovies.Callback =                   @obj.setViews;
                obj.Viewer.ProjectViews.ListOfMoviesInProject.Callback =        @obj.movieListClicked;
            
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
               
                [a, ~, ~] = fileparts(FileName);
                obj.MovieLibrary =              PMMovieLibrary(...
                                        FileName, ...
                                        a, ...
                                        a, ...
                                        a...
                                        );
                                    
                obj.savePreviousSettings; 
              
          end
          
           function obj = letUserAddNewMovie(obj)
                 ListWithMovieFileNames =    obj.MovieLibrary.askUserToSelectMovieFileNames;
                 NickName =                  obj.MovieLibrary.askUserToEnterUniqueNickName;
                 obj =                       obj.addNewMovie(NickName, ListWithMovieFileNames);
             
         end
         
          
         
           function obj = setEmpyActiveMovieController(obj)
                obj.ActiveMovieController=      PMMovieController(obj.Viewer);  
                obj.Viewer.MovieControllerViews.blackOutMovieView;
                obj =                           obj.setViews;
           end

           
        
        
    end
    
    methods (Access = private) % add new movie
        
       
        
        
          
        
    end
    
    methods (Access = private)
        
           %% changeNameOfLinkeMoviesClicked
         function [obj] =           changeNameOfLinkeMoviesClicked(obj,~,~)
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
         
         function obj = renameLinkedFileNamesOfActiveMovie(obj, NewFileNames) 
           
            cellfun(@(x, y) PMFileManagement(obj.MovieLibrary.getMovieFolder).renameFile(x, y), obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames, NewFileNames) 
             
            obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(NewFileNames);
            obj.MovieLibrary =               obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
            obj =                            obj.setViews;
            obj =                            obj.callbackForFilterChange;
            obj =                            obj.setInfoTextView;

         end
             
         %% changeLinkedMoviesClicked
         function [obj] =          changeLinkedMoviesClicked(obj,~,~)
                obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(obj.MovieLibrary.askUserToSelectMovieFileNames);
                obj.MovieLibrary =               obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
                obj =                            obj.callbackForFilterChange; 
         end
         
        
        
        %% callbacks for drift correction:
        function  [obj] = applyManualDriftCorrectionClicked(obj,~,~)
            obj.ActiveMovieController =                      obj.ActiveMovieController.setDriftCorrection('byManualEntries');  
             obj.ActiveMovieController =                      obj.ActiveMovieController.saveMovie;  
            
            
        end
        
        function  [obj] = eraseAllDriftCorrectionsClicked(obj,~,~)
             obj.ActiveMovieController =                      obj.ActiveMovieController.setDriftCorrection('remove'); 
              obj.ActiveMovieController =                      obj.ActiveMovieController.saveMovie;  
        end
        
           
            
     

            function obj = userLoadsExistingLibrary(obj)
                Path = obj.userSelectsFileNameOfProject;
                if isempty(Path)
                else
                    obj =                  obj.changeLibraryToFileName(Path);
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

            function [obj] =             changeLibraryToFileName(obj, FileName)
                obj.MovieLibrary =      PMMovieLibrary(FileName);
                obj =                   obj.setEmpyActiveMovieController;
                obj =                   obj.finishOffCurrentLibrary;
                obj.savePreviousSettings; 
            end

            function savePreviousSettings(obj)
                fprintf('PMMovieLibraryManager:@savePreviousSettings. During next start program will try to open file "%s".\n',  obj.MovieLibrary.getFileName)
                FileNameOfProject=           obj.MovieLibrary.getFileName;
                save(obj.FileWithPreviousSettings, 'FileNameOfProject')
            end

        
        
        
        
         %% mapUnMappedMovies
        function [obj] =           mapUnMappedMovies(obj,~,~)
            obj.Viewer =       obj.Viewer.setContentTypeFilterTo('Show all unmapped movies');
            obj =              obj.callbackForFilterChange;
            obj =              obj.batchProcessingOfNickNames(obj.MovieLibrary.getAllFilteredNicknames, 'MapImages');
        end
        
        %% unmapAllMovies
        function obj = unmapAllMovies(obj,~,~)
            obj.Viewer =      obj.Viewer.setContentTypeFilterTo('Show all unmapped movies');
            obj =             obj.callbackForFilterChange;
            obj =             obj.batchProcessingOfNickNames(obj.MovieLibrary.getAllNicknames,'UnMapImages');
        end
        
        function obj = createDerivativeFiles(obj, ~, ~)
            obj =             obj.batchProcessingOfNickNames(obj.MovieLibrary.getAllNicknames,'createDerivativeFiles');
        end
        
        
      
          %% batchProcessingChannel
          function obj = batchProcessingChannel(obj, ~, ~)
                 obj =        obj.batchProcessingOfNickNames(obj.Viewer.getSelectedNicknames, 'SetChannelsByActiveMovie');
          end
          
        
          
        
        %% setViews
             function [obj] =            setViews(obj, ~,  ~)
                if isempty(obj.MovieLibrary.getMovieObjectSummaries) || isempty(obj.MovieLibrary.getMovieObjectSummaries)
                    fprintf('No movie objects available or no movie selected. Therefore disable views.\n')
                    obj.ActiveMovieController.getViews.disableAllViews;
                end
                obj.Viewer =    obj.Viewer.updateWith(obj.MovieLibrary);
             end
            
             
         %% resetMovieTrackingFileController
         function obj =              resetMovieTrackingFileController(obj)    
             if isempty(obj.ActiveMovieController.getLoadedMovie)
                 warning('Currently no movie in memory. Cannot generate MovieTracking view.')
             else
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.resetView;
                obj.MovieTrackingFileController =     obj.MovieTrackingFileController.setCallbacks(@obj.changeNicknameClicked, @obj.changeKeywordClicked);
             end
         end
         
      
         
         function [obj] =           changeNicknameClicked(obj,~,~)
                
            MyNewNickName =                 obj.MovieTrackingFileController.getNickNameFromView;
            obj.ActiveMovieController =     obj.ActiveMovieController.setNickName(MyNewNickName);
            obj.MovieLibrary =              obj.MovieLibrary.setNickName(obj.ActiveMovieController);

            if length(obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames) == 1
              
                obj =                   obj.renameLinkedFileNamesOfActiveMovie({obj.convertNickNameIntoFileName(MyNewNickName)});
                fprintf('File was also renamed to match new nickname.\n')
            end

            obj.MovieTrackingFileController =     obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
            obj =                           obj.callbackForFilterChange;
         end
         
         function FileName = convertNickNameIntoFileName(obj, NickName)
             FileName =        [NickName, obj.ActiveMovieController.getLoadedMovie.getMovieFileExtension];
         end
         
    
        function [obj] =        callbackForFilterChange(obj, ~, ~) 
            obj.MovieLibrary =        obj.MovieLibrary.updateFilterSettingsFromPopupMenu(obj.Viewer.ProjectViews.FilterForKeywords,  obj.Viewer.ProjectViews.RealFilterForKeywords);
            obj =                     obj.setViews;
        end
      
        function [obj] =           changeKeywordClicked(obj,~,~)
            fprintf('Enter PMMovieLibraryManager:@changeKeywordClicked:\n')

            if isempty(obj.MovieTrackingFileController.getKeywordFromView)
            else 
                obj.ActiveMovieController =     obj.ActiveMovieController.setKeywords(obj.MovieTrackingFileController.getKeywordFromView);
                obj.MovieLibrary =              obj.MovieLibrary.updateMovieListWithMovieController(obj.ActiveMovieController);
                obj =         obj.setViews;
                obj =         obj.callbackForFilterChange;
                obj =         obj.setInfoTextView;
                fprintf('Exit PMMovieLibraryManager:@changeKeywordClicked.\n\n')
            end
            
        end
        
        
        
        
     
         
    
        
        
         
         
        %% reapplySourceFilesClicked
        function [obj] =            reapplySourceFilesClicked(obj,~,~)
            fprintf('\n Enter PMMovieLibraryManager:@reapplySourceFilesClicked:\n')
             if isempty(obj.ActiveMovieController)
             else
                 obj.ActiveMovieController =      obj.ActiveMovieController.manageResettingOfImageMap;
             end
             fprintf('Exit PMMovieLibraryManager:@reapplySourceFilesClicked.\n\n')
        end
        
        %% deleteImageCacheClicked
        function  [obj] = deleteImageCacheClicked(obj,~,~) 
            if isempty(obj.ActiveMovieController) 
            else
                obj.ActiveMovieController    =      obj.ActiveMovieController.emptyOutLoadedImageVolumes;
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
        
          
          function [obj] =        batchProcessingOfNickNames(obj, NickNames, ActionType)
            
              
              
              originalNickName =        obj.MovieLibrary.getSelectedNickname;
              
            OriginalController =        obj.ActiveMovieController;
              
            obj =                           obj.finishOffCurrentLibrary;
            
            for CurrentMovieIndex = 1:size(NickNames,1)
                
                obj =        obj.setActiveMovieByNickName( NickNames{CurrentMovieIndex});
                switch ActionType                    
                    case 'MapImages'
                         obj.ActiveMovieController =       obj.ActiveMovieController.manageResettingOfImageMap;
                    case 'UnMapImages'
                        obj.ActiveMovieController =        obj.ActiveMovieController.unMapMovie;
                    case 'SetChannelsByActiveMovie'
                        obj.ActiveMovieController =         obj.ActiveMovieController.setChannels(OriginalController.getLoadedMovie);
                    case 'createDerivativeFiles'
                        obj.ActiveMovieController =         obj.ActiveMovieController.createDerivativeFiles;
                        obj =                               obj.saveInteractionsMapForActiveMovie;
                    case 'saveInteractionMap'
                         obj =                               obj.saveInteractionsMapForActiveMovie;
                 
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
    
    methods (Access = private) % interation
        
          %% addCallbacksToInteractionsMenu:
       function obj = addCallbacksToInteractionsMenu(obj)
             obj.Viewer =    obj.Viewer.setInteractionsMenuCallbacks(...
                @obj.showInteractionsViewer ...
                );
       end
        
       function obj = showInteractionsViewer(obj, ~, ~)
           
          obj = obj.initializeInteractionView;
           
       end
       
       function obj = initializeInteractionView(obj)
            obj.InteractionsManager = obj.InteractionsManager.setMovieController(obj.ActiveMovieController);
          
           obj.InteractionsManager = obj.InteractionsManager.showView;
            obj =                     obj.addCallbacksToInteractionManager;
           
       end
        
       
        function obj = adjustViews(obj) 
                obj.Viewer.MovieControllerViews = obj.Viewer.MovieControllerViews.adjustViews;
                obj.Viewer.InfoView.List.Position =                                           [11.5 0.1 21 3.5];
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

