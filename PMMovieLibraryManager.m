classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties (Access = private)

        Viewer
        MainProjectFolder =                     userpath; %not in use right now
        MovieLibrary
        ActiveMovieController =                 PMMovieController()
        MovieTrackingFileController =           PMMovieTrackingFileController
         
    end
    
    properties(Access = private, Constant)
        FileWithPreviousSettings =           [userpath,'/imans_PreviouslyUsedFile.mat'];
    end
    
    
    methods

        function obj =          PMMovieLibraryManager(varargin)

            obj.Viewer =            PMImagingProjectViewer;
            obj.Viewer.MovieControllerViews.blackOutMovieView;
            obj =       obj.adjustViews;
       
            obj =       obj.addCallbacksToFileAndProject;
            obj =       obj.addCallbacksToNavigationAndTracking;
            obj =       obj.addCallbacksToMovieMenu;
            obj =       obj.addCallbacksToDriftMenu;
            
            
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
        
        function controller = getActiveMovieController(obj)
           controller  = obj.ActiveMovieController ;
        end
        
        function obj = setActiveMovieController(obj, Value)
           obj.ActiveMovieController  = Value;
        end
        
        
        function set.MovieLibrary(obj, Value)
           assert(isa(Value,  'PMMovieLibrary'), 'Wrong input type.')
           obj.MovieLibrary = Value; 
        end
        
        function obj = setMovieLibrary(obj, Value)
            obj.MovieLibrary = Value;
        end
        
        function library = getMovieLibrary(obj)
            library = obj.MovieLibrary;
            
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
          

        
     

        %% save library;   
        function [obj] =    saveProjectClicked(obj,~,~)
            obj = obj.saveLibrary;
        end
        
        %% change movie-folder:
        function [obj] =        changeMovieFolderClicked(obj,~,~)
                NewPath=          uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select movie folder',...
                'NumFiles', 1, 'Output', 'char');
                if isempty(NewPath) || ~ischar(NewPath)
                else
                    obj = obj.addMovieFolder(NewPath);
                end
        end
        
        function obj = addMovieFolder(obj, Value)
              obj.MovieLibrary =              obj.MovieLibrary.addMovieFolder(Value);
            obj =                           obj.saveLibrary;
            obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
            obj =                           obj.setInfoTextView;
        end
        
        function obj = setMovieFolders(obj, Value)
            obj.MovieLibrary =              obj.MovieLibrary.setMovieFolders(Value);
            obj =                           obj.saveLibrary;
            obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
            obj =                           obj.setInfoTextView;
        end
        
        function [obj]=             setInfoTextView(obj)
             obj.Viewer =   obj.Viewer.setInfoView(obj.MovieLibrary.getProjectInfoText);  
        end
        
        
        %% change export folder:
        function [obj] =        changeExportFolderClicked(obj,~,~)
                UserSelectedFolder=            uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select export folder',...
                'NumFiles', 1, 'Output', 'char');
                if isempty(UserSelectedFolder) || ~ischar(UserSelectedFolder)
                else
                    obj.MovieLibrary =   obj.MovieLibrary.setExportFolder(UserSelectedFolder);
                    obj =                           obj.Viewer.getSelectedNicknames;
                    obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                    obj =                           obj.setInfoTextView;
                end

        end
        
        %% add entry
          function [obj] =        addMovieClicked(obj,~,~)
             ListWithMovieFileNames =    obj.MovieLibrary.askUserToSelectMovieFileNames;
             NickName =                  obj.MovieLibrary.askUserToEnterUniqueNickName;
             obj =                       obj.addNewMovie(NickName, ListWithMovieFileNames);
          end
          
         function obj =          addNewMovie(obj, Nickname, AttachedFiles)
                  obj =                   obj.saveActiveMovie;
                  obj.MovieLibrary =      obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                  obj.MovieLibrary =      obj.MovieLibrary.addNewEntryIntoLibrary(Nickname, AttachedFiles);
                  obj =                   obj.setActiveMovieByNickName(Nickname);
                  obj =                   obj.callbackForFilterChange;
         end
          
        %% add all missing entries:
           function [obj] =        addAllMissingCaptures(obj,~,~)
                missingFiles =                          obj.MovieLibrary.getFileNamesOfUnincorporatedMovies;
                for FileIndex= 1:size(missingFiles,1)
                    obj =     obj.addNewMovie(missingFiles{FileIndex,1}(1:end-4), {missingFiles{FileIndex,1}});
                end
           end
           
        %% remove single entry:
        function [obj] =        removeMovieClicked(obj,~,~)
            answer = questdlg(['Are you sure you remove the movie ', obj.MovieLibrary.getMovieObjectSummaries, ' from the library?  Al linked data (tracking, drift correction etc.) will also be deleted. This is irreversible.'], ...
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
        
        %% remove all entries:
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

        function obj = respondToDeleteTrackClick(obj,~,~)
             obj.ActiveMovieController =        obj.ActiveMovieController.deleteSelectedTracks;
       end
       
        function [obj] = deleteAllTracksClicked(obj,~,~)
                    obj.ActiveMovieController =                 obj.ActiveMovieController.deleteAllTracks;
                    obj.ActiveMovieController =                 obj.ActiveMovieController.updateAllViewsThatDependOnActiveTrack;
                    obj.ActiveMovieController =                 obj.ActiveMovieController.setTrackLineViews;
        end
        
         function [obj] = mergeSelectedTracks(obj,~,~)
                obj.ActiveMovieController =         obj.ActiveMovieController.mergeSelectedTracks;
                obj.ActiveMovieController =         obj.ActiveMovieController.updateTrackView;
         end
         
         function [obj] = splitSelectedTracks(obj,~,~)
             obj.ActiveMovieController =                obj.ActiveMovieController.splitSelectedTracks;
             obj.ActiveMovieController =                obj.ActiveMovieController.updateTrackView;
         end
             
        function [obj] = deleteMaskClicked(obj,~,~)
            
            obj.ActiveMovieController =             obj.ActiveMovieController.deleteActiveMask;
            obj.ActiveMovieController =             obj.ActiveMovieController.setTrackLineViews;
                
        end
        
        function [obj] =        showMissingCaptures(obj,~,~)            
            obj.Viewer.InfoView.List.String =     obj.MovieLibrary.getFileNamesOfUnincorporatedMovies;
            obj.Viewer.InfoView.List.Value =      min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);
        end
        
      
      
        
        %% updateMovieSummaryFromFiles
        function obj = updateMovieSummaryFromFiles(obj,~,~)
            obj.MovieLibrary = obj.MovieLibrary.updateMovieSummariesFromFiles;
        end
        
      
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
                    obj.ActiveMovieController =         obj.ActiveMovieController.setKeywords(KeywordManagerSelection.TargetKeyword);
                    obj.MovieLibrary =   obj.MovieLibrary.replaceKeywords(KeywordManagerSelection.SourceKeyword, KeywordManagerSelection.TargetKeyword);
                    obj =                obj.setViews;
                    obj =                obj.callbackForFilterChange;
                    obj =                obj.setInfoTextView;
             end
             
            
              
        end
        

        function [obj] =    toggleProjectInfo(obj,~,~)
            obj =                               obj.setInfoTextView;
            
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
            ShortcutsKeys{24,1}=        '"r": autotrack current cells (only when tracking is on)';
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
        
   
        
         %% respond to mouse or key input:
          function [obj] =           keyPressed(obj,~,~)
              
                 PressedKey=       get(obj.Viewer.Figure,'CurrentCharacter');
                 CurrentModifier =   obj.Viewer.Figure.CurrentModifier;
                 if isempty(PressedKey) || ~obj.ActiveMovieController.verifyActiveMovieStatus

                 else
                    switch PressedKey
                       case 's'
                         switch length(CurrentModifier)
                             case 1
                                 if strcmp(CurrentModifier, 'command')
                                     obj =                    obj.saveActiveMovie;
                  obj.MovieLibrary =        obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                                 end
                         end
                    otherwise
                        obj.ActiveMovieController.interpretKey(PressedKey, CurrentModifier);
                    end

                 end
                obj.Viewer.Figure.CurrentCharacter =                   '0'; 
          end
          
        function verifiedStatus =                     verifyActiveMovieStatus(obj)
          verifiedStatus = ~isempty(obj.ActiveMovieController)  && ~isempty(obj.ActiveMovieController.getLoadedMovie) && ~isempty(obj.ActiveMovieController.getViews) ;
        end
          
          function [obj] =          mouseButtonPressed(obj,~,~)
              obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonPressed;
          end

          function [obj] =          mouseMoved(obj,~,~)
              obj.ActiveMovieController = obj.ActiveMovieController.mouseMoved;
          end
            
          function [obj] =          mouseButtonReleased(obj,~,~)
              obj.ActiveMovieController = obj.ActiveMovieController.mouseButtonReleased;    
          end
          
          
          
          %% changeNameOfLinkeMoviesClicked
         function [obj] =           changeNameOfLinkeMoviesClicked(obj,~,~)
               myFileManagerViewer =                    PMFileManagementViewer(PMFileManagement(obj.MovieLibrary.getMovieFolder));
               myFileManagerViewer =                    myFileManagerViewer.resetSelectedFiles(obj.ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames);
               myFileManagerViewer.GraphicObjects.EditField.Callback =          @obj.renameFiles;
         end
         
         function [obj] =           renameFiles(obj,~,~)
            obj.FileManagerViewer =             obj.FileManagerViewer.RenameSelectedFile;
            obj.ActiveMovieController =         obj.ActiveMovieController.setNamesOfMovieFiles(obj.FileManagerViewer.getSelectedFileNames);
            obj.MovieLibrary =                  obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
            obj =                               obj.setViews;
            obj =                               obj.callbackForFilterChange;
            obj =                               obj.setInfoTextView;  
         end
             
         %% changeLinkedMoviesClicked
         function [obj] =          changeLinkedMoviesClicked(obj,~,~)
                obj.ActiveMovieController =      obj.ActiveMovieController.setNamesOfMovieFiles(obj.MovieLibrary.askUserToSelectMovieFileNames);
                obj.MovieLibrary =               obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                obj =                            obj.callbackForFilterChange; 
         end
        
        %% showCompleteMetaDataInfoClicked
        function [obj] = showCompleteMetaDataInfoClicked(obj, ~, ~)
            
            MetaDataString  =   obj.ActiveMovieController.getLoadedMovie.getMetaDataString;

            ExportFileName =                                   [obj.ActiveMovieController.getLoadedMovie.getNickName, '_MetaDataString.text'];
            cd(obj.MovieLibrary.getExportFolder)
            [file,path] =                                       uiputfile(ExportFileName);
            CurrentTargetFilename =                             [path, file];
            datei =                                             fopen(CurrentTargetFilename, 'w');
            fprintf(datei, '%s', MetaDataString);
          
            if 1== 2 % this crashes the program to much text
            
                    currentFigure =    figure;
                    currentFigure.Units = 'normalized';
                    currentFigure.Position = [0 0 0.8 0.8];

                    textBox = uicontrol(currentFigure);
                    textBox.Style = 'edit';
                    textBox.Units = 'normalized';
                    textBox.Position = [0 0 1 1 ];
                    textBox.Max = 2;
                    textBox.Min = 0;  

                   textBox.String =  MetaDataString;

            end
            
            
        end
        
        function [obj] =        exportMovie(obj,~,~)

            myMovieManager =                            PMImagerViewerMovieManager(obj.ActiveMovieController);

            myMovieManager.MovieAxes =                  obj.ActiveMovieController.getViews.MovieView.ViewMovieAxes;
            myMovieManager.ExportFolder =               obj.MovieLibrary.getExportFolder;
            AdditionalName =                            myMovieManager.ExportWindowHandles.MovieName.String;
            myMovieManager.ExportFileName =             [obj.MovieLibrary.getMovieObjectSummaries '_' AdditionalName '.mp4'];


            myMovieManager =                            myMovieManager.MenuForMovieExportSettings;
            myMovieManager.PrefillExportName;

            myMovieManager =                           myMovieManager.resetExportWindowValues(myMovieManager.MovieController.getViews);
            waitfor(myMovieManager.ExportWindowHandles.Wait, 'Value')
            
            UserWantToMakeMovie=                   ishandle(myMovieManager.ExportWindowHandles.Wait);
            if ~UserWantToMakeMovie
            else
                myMovieManager.StartFrame =            myMovieManager.ExportWindowHandles.Start.Value;
                myMovieManager.EndFrame =              myMovieManager.ExportWindowHandles.End.Value;
                myMovieManager.FramesPerMinute =       myMovieManager.ExportWindowHandles.fps.Value;
                close(myMovieManager.ExportWindowHandles.ExportMovieWindow)

                myMovieManager =                       myMovieManager.createMovieSequence;
                myMovieManager =                       myMovieManager.detectSaturatedFrames;
                myMovieManager =                       myMovieManager.removeSaturatedFrames;
                myMovieManager.writeMovieSequenceIntoFile;
                
                
            end

            

        end
        
        function [obj] =        exportTrackCoordinates(obj,~,~)
            
            obj.ActiveMovieController =     obj.ActiveMovieController.exportTrackCoordinates;
            
           
        end
        
    
        %% callbacks for drift correction:
        function  [obj] = applyManualDriftCorrectionClicked(obj,~,~)
            obj.ActiveMovieController =                      obj.ActiveMovieController.resetDriftCorrectionByManualClicks;  
        end
        
        function  [obj] = eraseAllDriftCorrectionsClicked(obj,~,~)
             obj.ActiveMovieController =                      obj.ActiveMovieController.resetDriftCorrectionToNoDrift; 
        end

        function [obj] =            sliderActivity(obj,~,~)
            disp(['Value = ', num2str(obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Value)]);
            obj.ActiveMovieController = obj.ActiveMovieController.resetFrame(round(obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Value));
        end


    end
    
    methods (Access = private)
        
        %% create new project:
        function [obj] =    newProjectClicked(obj,~,~)
           [FileName, SelectedPath] =    uiputfile;
            if SelectedPath== 0
            else
                obj =                       obj.changeToNewLibraryWithFileName([SelectedPath, FileName]);
            end
        end

          function obj = changeToNewLibraryWithFileName(obj, FileName)
                obj =                   obj.saveLibrary; 
                obj.MovieLibrary =      PMMovieLibrary;
                obj.MovieLibrary =      obj.MovieLibrary.setFileName(FileName);
                obj =                   obj.updatesAfterChangingToNewLibrary;
          end

            function [obj] = saveLibrary(obj)
                if isempty(obj.MovieLibrary)

                else
                    obj =                    obj.saveActiveMovie;
                    obj.MovieLibrary =        obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                    obj.MovieLibrary =         obj.MovieLibrary.saveMovieLibraryToFile;
                end
            end

            function obj = saveActiveMovie(obj)
                  obj.ActiveMovieController =             obj.ActiveMovieController.updateWith(obj.MovieLibrary);
                  obj.ActiveMovieController =             obj.ActiveMovieController.saveMovie;
            end

             function obj = updatesAfterChangingToNewLibrary(obj)
                obj.MovieLibrary =     obj.MovieLibrary.sortByNickName;
                obj =                  obj.setEmpyActiveMovieController;
                obj.savePreviousSettings; 
                obj =                   obj.saveLibrary; 
             end

           function obj = setEmpyActiveMovieController(obj)
                obj.ActiveMovieController=      PMMovieController(obj.Viewer);  
                obj.Viewer.MovieControllerViews.blackOutMovieView;
                obj =                           obj.setViews;
           end

           
             %% loadProjectClicked
            function [obj] =    loadProjectClicked(obj,~,~)
                obj =   obj.userLoadsExistingLibrary;
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
                obj =                   obj.saveLibrary; 
                obj.MovieLibrary =      PMMovieLibrary(FileName);
                obj =                   obj.updatesAfterChangingToNewLibrary;
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
        
        
        %% batchProcessingOfNickNames
          function [obj] =        batchProcessingOfNickNames(obj, NickNames, ActionType)
            originalNickName =        obj.MovieLibrary.getSelectedNickname;
              
            OriginalController =        obj.ActiveMovieController;
              
            obj =                    obj.saveActiveMovie;
            obj.MovieLibrary =        obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);   
            
            for CurrentMovieIndex = 1:size(NickNames,1)
                obj =        obj.setActiveMovieByNickName( NickNames{CurrentMovieIndex});
                switch ActionType                    
                    case 'MapImages'
                         obj.ActiveMovieController =       obj.ActiveMovieController.manageResettingOfImageMap;
                    case 'UnMapImages'
                        obj.ActiveMovieController =        obj.ActiveMovieController.unMapMovie;
                    case 'SetChannelsByActiveMovie'
                        obj.ActiveMovieController =         obj.ActiveMovieController.setChannels(OriginalController.getLoadedMovie);
                        
                end
                
                obj =                           obj.saveActiveMovie;
                obj.MovieLibrary =              obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                obj.ActiveMovieController =     obj.ActiveMovieController.updateSaveStatusView;
                obj =                           obj.setInfoTextView;
                obj=                            obj.callbackForFilterChange;
            end
            
            
            obj =         obj.setActiveMovieByNickName(originalNickName);
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
                obj.MovieTrackingFileController =           obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
             obj.MovieTrackingFileController =                   obj.MovieTrackingFileController.resetView;
              obj.MovieTrackingFileController =      obj.MovieTrackingFileController.setCallbacks(@obj.changeNicknameClicked, @obj.changeKeywordClicked);
         end
         
      
         
         function [obj] =           changeNicknameClicked(obj,~,~)
                obj.ActiveMovieController =     obj.ActiveMovieController.setNickName(obj.MovieTrackingFileController.getNickNameFromView);
                obj.MovieLibrary =              obj.MovieLibrary.setNickName(obj.ActiveMovieController);
                obj =                           obj.callbackForFilterChange;
         end
         
    
        function [obj] =        callbackForFilterChange(obj, ~, ~) 
            obj.MovieLibrary =        obj.MovieLibrary.updateFilterSettingsFromPopupMenu(obj.Viewer.ProjectViews.FilterForKeywords,  obj.Viewer.ProjectViews.RealFilterForKeywords);
            obj =                     obj.setViews;
        end
      
        function [obj] =           changeKeywordClicked(obj,~,~)
            fprintf('Enter PMMovieLibraryManager:@changeKeywordClicked:\n')

            if isempty(obj.MovieTrackingFileController.getKeywordFromView)
            else 
                obj.ActiveMovieController =    obj.ActiveMovieController.setKeywords(obj.MovieTrackingFileController.getKeywordFromView);
                obj.MovieLibrary =    obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                obj =         obj.setViews;
                obj =         obj.callbackForFilterChange;
                obj =         obj.setInfoTextView;
                fprintf('Exit PMMovieLibraryManager:@changeKeywordClicked.\n\n')
            end
            
        end
        
        
        
        
        %% movieListClicked:
          function [obj] =        movieListClicked(obj, ~, ~)
                fprintf('\nPMMovieLibraryManager: @movieListClicked\n')
                switch obj.Viewer.getMousClickType
                    case 'open'
                        SelectedNicknames =     obj.Viewer.getSelectedNicknames;
                        if length(SelectedNicknames) == 1
                                obj =                   obj.verifyPathForImageAnalysis;
                                obj =                   obj.saveActiveMovie;
                                obj.MovieLibrary =      obj.MovieLibrary.updateMovieListWith(obj.ActiveMovieController);
                                obj =                   obj.setActiveMovieByNickName(SelectedNicknames{1});
                        end
                end    
          end
        
          function obj = verifyPathForImageAnalysis(obj)
                if ~obj.MovieLibrary.testThatPathForImageAnalysisExists
                        obj =           obj.setPathForImageAnalysis;
                else
                    warning('Path for image analysis was not set.')
                end
          end
          
        function obj = setPathForImageAnalysis(obj, ~, ~)
            
              NewPath=          uipickfiles('FilterSpec', obj.MovieLibrary.getPathForImageAnalysis, 'Prompt', 'Select tracking folder',...
                'NumFiles', 1, 'Output', 'char');
            
                if isempty(NewPath) || ~ischar(NewPath)
                else
                    obj.MovieLibrary =              obj.MovieLibrary.setPathForImageAnalysis(NewPath);
                    obj =                           obj.saveLibrary;
                    obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                    obj =                           obj.setInfoTextView;
                     
                end
        end
        
        function obj =          setActiveMovieByNickName(obj, varargin)
            switch length(varargin)
                case 1
                    obj.MovieLibrary=               obj.MovieLibrary.switchActiveMovieByNickName(varargin{1});
                    obj.ActiveMovieController =     obj.MovieLibrary.getActiveMovieController(obj.Viewer);
                otherwise
                    error('Invalid number of arguments')
            end
            
            obj.Viewer =    obj.Viewer.updateWith(obj.MovieLibrary);  
            obj.MovieTrackingFileController =           obj.MovieTrackingFileController.updateWith(obj.ActiveMovieController.getLoadedMovie);
            obj =           obj.setInfoTextView;
                          
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

          
         %% callbacks:
          function [obj] =        addCallbacksToFileAndProject(obj)
            
            obj.Viewer.Figure.WindowKeyPressFcn =                          @obj.keyPressed;
            obj.Viewer.Figure.WindowButtonDownFcn =                       @obj.mouseButtonPressed;
            obj.Viewer.Figure.WindowButtonUpFcn =                         @obj.mouseButtonReleased;
            obj.Viewer.Figure.WindowButtonMotionFcn =                     @obj.mouseMoved;

            %% file menu:
            obj.Viewer.FileMenu.New.MenuSelectedFcn =                     @obj.newProjectClicked;
            obj.Viewer.FileMenu.Save.MenuSelectedFcn =                    @obj.saveProjectClicked;
            obj.Viewer.FileMenu.Load.MenuSelectedFcn =                    @obj.loadProjectClicked;
            
            %% project menu:
            obj.Viewer.ProjectMenu.ChangeImageAnalysisFolder.MenuSelectedFcn=   @obj.setPathForImageAnalysis;
            obj.Viewer.ProjectMenu.ChangeMovieFolder.MenuSelectedFcn=           @obj.changeMovieFolderClicked;
            obj.Viewer.ProjectMenu.ChangeExportFolder.MenuSelectedFcn=          @obj.changeExportFolderClicked;
            
            
            obj.Viewer.ProjectMenu.AddCapture.MenuSelectedFcn=                  @obj.addMovieClicked;
            obj.Viewer.ProjectMenu.AddAllCaptures.MenuSelectedFcn =             @obj.addAllMissingCaptures;
            obj.Viewer.ProjectMenu.RemoveCapture.MenuSelectedFcn=               @obj.removeMovieClicked;
            obj.Viewer.ProjectMenu.DeleteAllEntries.MenuSelectedFcn=            @obj.removeAllMoviesClicked;
            
            obj.Viewer.ProjectMenu.ShowMissingCaptures.MenuSelectedFcn =        @obj.showMissingCaptures;
            
            obj.Viewer.ProjectMenu.Mapping.MenuSelectedFcn=                     @obj.mapUnMappedMovies;
            obj.Viewer.ProjectMenu.UnMapping.MenuSelectedFcn=                   @obj.unmapAllMovies;
            
            obj.Viewer.ProjectMenu.UpdateMovieSummary.MenuSelectedFcn=          @obj.updateMovieSummaryFromFiles;
            obj.Viewer.ProjectMenu.ReplaceKeywords.MenuSelectedFcn=             @obj.replaceKeywords;
            
            obj.Viewer.ProjectMenu.Info.MenuSelectedFcn =                 @obj.toggleProjectInfo;

            obj.Viewer.ProjectMenu.BatchProcessingChannel.MenuSelectedFcn =     @obj.batchProcessingChannel;
            
            obj.Viewer.HelpMenu.KeyboardShortcuts.MenuSelectedFcn  =      @obj.showKeyboardShortcuts;

            obj.Viewer.ProjectViews.FilterForKeywords.Callback =          @obj.callbackForFilterChange;
            obj.Viewer.ProjectViews.RealFilterForKeywords.Callback =      @obj.callbackForFilterChange;
            
            obj.Viewer.ProjectViews.SortMovies.Callback =                 @obj.setViews;
            obj.Viewer.ProjectViews.ListOfMoviesInProject.Callback =      @obj.movieListClicked;
            
   
        end
        
        
        function obj =      addCallbacksToMovieMenu(obj)

            obj.Viewer.MovieMenu.MovieSettings.MenuSelectedFcn =                    @obj.editMovieSettingsClicked;
            obj.Viewer.MovieMenu.RenameLinkedMovies.MenuSelectedFcn =               @obj.changeNameOfLinkeMoviesClicked;
            obj.Viewer.MovieMenu.RelinkMovies.MenuSelectedFcn =                     @obj.changeLinkedMoviesClicked;

            obj.Viewer.MovieMenu.MapSourceFiles.MenuSelectedFcn =                   @obj.reapplySourceFilesClicked;
            obj.Viewer.MovieMenu.DeleteImageCache.MenuSelectedFcn =                 @obj.deleteImageCacheClicked;

            obj.Viewer.MovieMenu.ExportMovie.MenuSelectedFcn =                      @obj.exportMovie;
            obj.Viewer.MovieMenu.ExportTrackCoordinates.MenuSelectedFcn =           @obj.exportTrackCoordinates;
            obj.Viewer.MovieMenu.ShowCompleteMetaData.MenuSelectedFcn =             @obj.showCompleteMetaDataInfoClicked;

        end
        
        function obj =  addCallbacksToDriftMenu(obj)
            obj.Viewer.DriftMenu.ApplyManualDriftCorrection.MenuSelectedFcn =                           @obj.applyManualDriftCorrectionClicked;
            %obj.Viewer.MovieControllerViews.Menu.CompleteManualDriftCorrection.MenuSelectedFcn =                        @obj.completeManualDriftCorrectionClicked;
            obj.Viewer.DriftMenu.EraseAllDriftCorrections.MenuSelectedFcn =                             @obj.eraseAllDriftCorrectionsClicked;

        end
        
        function [obj] =        addCallbacksToNavigationAndTracking(obj)
            
            fprintf('PMMovieLibraryManger:@addCallbacksToNavigationAndTracking.\n')

            obj.Viewer.TrackingViews.Menu.AutoCellRecognition.MenuSelectedFcn =                        @obj.manageAutoCellRecognition;
            obj.Viewer.TrackingViews.Menu.AutoTracking.MenuSelectedFcn =                            @obj.manageTrackingAutoTracking;
            obj.Viewer.TrackingViews.Menu.EditAndView.MenuSelectedFcn =                            @obj.manageTrackingEditAndView;
            addlistener(obj.Viewer.MovieControllerViews.Navigation.TimeSlider,'Value','PreSet', @obj.sliderActivity);


         
             
        end
        
       
        function obj = adjustViews(obj) 
            
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Visible =         'on';
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Units =           'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.DataAspectRatio = [1 1 1];
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Position =        [11.5 5.7 19 19];
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Units =           'pixels';

            obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Units =             'centimeters';
            obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Position =          [11.5 4 19 1];

            obj.Viewer.MovieControllerViews.MovieView.TimeStampText.Units =           'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.TimeStampText.Position =        [2 0.3 ];
            obj.Viewer.MovieControllerViews.MovieView.TimeStampText.Color = 'c';

            obj.Viewer.MovieControllerViews.MovieView.ZStampText.Units =              'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.ZStampText.Position =           [9 0.3 ];
            obj.Viewer.MovieControllerViews.MovieView.ZStampText.Color = 'c';

            obj.Viewer.MovieControllerViews.MovieView.ScalebarText.Units =            'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.ScalebarText.Position =         [16 0.3 ];
            obj.Viewer.MovieControllerViews.MovieView.ScalebarText.Color = 'c';

            obj.Viewer.InfoView.List.Position =                                           [11.5 0.1 21 3.5];
            
        end
        
        
        
    end
end

