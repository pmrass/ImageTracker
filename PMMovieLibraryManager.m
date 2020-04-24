classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties


        Viewer
        TagOfHandleOfInfoFigure =                   'PMMovieLibraryManager_InfoWindow';
        ActiveInfoType =                            'Project';
        
        MainProjectFolder =                         userpath; %not in use right now
        
        FileManagerViewer
        
        FileWithPreviousSettings =                  [userpath,'/imans_PreviouslyUsedFile.mat'];
        FileNameForLoadingNewObject =               '' % use this only for loading the new file; the movie-library will "save itself" with the filename it has in one its properties
        
        MovieLibrary
        
        ActiveMovieController
        AutoCellRecognitionController
        
        
        ProjectFilterList =                         {'Show all movies'; 'Show all Z-stacks'; 'Show all snapshots'; 'Show all movies with drift correction'; 'Show all tracked movies'; 'Show all untracked movies'; 'Show entire content'; 'Show content with non-matching channel information'; 'Show all unmapped movies'};
        
       
        MouseAction =                               'No action';
   

    end
    
    
    methods


        function obj =          PMMovieLibraryManager
           
            %PMMOVIELIBRARYMANAGER Construct an instance of this class
            %   Detailed explanation goes here


            %% update project with previous file:
            obj.Viewer =                                                                        PMImagingProjectViewer;
            
            fprintf('\n')
            obj =                                                                               obj.setPreviouslyUsedFileName;
            
            obj.ActiveMovieController       =                                                   PMMovieController(obj.Viewer);  
            obj.Viewer.MovieControllerViews.blackOutMovieView;
           
            obj =                                                                               obj.addCallbacksToFileAndProject;
            obj =                                                                               obj.addCallbacksToMovieObject;
            obj =                                                                               obj.addCallbacksToNavigationAndTracking;
       
              
            %% update image view settings:
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Visible =             'on';
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Units =               'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.DataAspectRatio =     [1 1 1];
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Position =            [11.5 5.7 19 19];
            obj.Viewer.MovieControllerViews.MovieView.ViewMovieAxes.Units =               'pixels';

            obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Units =               'centimeters';
            obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Position =            [11.5 4 19 1];


            obj.Viewer.MovieControllerViews.MovieView.TimeStampText.Units =               'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.TimeStampText.Position =            [2 0.3 ];
            obj.Viewer.MovieControllerViews.MovieView.TimeStampText.Color = 'c';

            obj.Viewer.MovieControllerViews.MovieView.ZStampText.Units =               'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.ZStampText.Position =              [9 0.3 ];
            obj.Viewer.MovieControllerViews.MovieView.ZStampText.Color = 'c';

            obj.Viewer.MovieControllerViews.MovieView.ScalebarText.Units =               'centimeters';
            obj.Viewer.MovieControllerViews.MovieView.ScalebarText.Position =            [16 0.3 ];
            obj.Viewer.MovieControllerViews.MovieView.ScalebarText.Color = 'c';

            obj.Viewer.InfoView.List.Position =                                           [11.5 0.1 21 3.5];
            
  
            %% load the project:
            obj =                                                                       obj.manageResettingOfLibrary;
      
        end
        
        

        %% file management:
        function [obj] =    newProjectClicked(obj,src,~)

                fprintf('Enter PMMovieLibraryManager:@newProjectClicked:\n')  
            
                %% first save the old project (before replacing it with the new one
                [obj] =                                         obj.manageSavingOfLibrary; % first save the old project to file so that changes are not lost (make sure that the new project is not loaded in the meantime so that the old project will be overwritten;
            
    
                %% create an empty project and clear up previous views:
                 %% let the user select the file path: future changes of this project will be saved there (also save it right now so that the project is on file);
               [FileName,SelectedPath] =                           uiputfile;
                if SelectedPath== 0
                    return
                end
                MyFileName =                                    [SelectedPath, FileName];
                
                obj.FileNameForLoadingNewObject =               MyFileName; % make file-name empty: this means that an "empty" new project will be created (rather then loaded from file);
                obj.ActiveInfoType =                            'Project';
                obj =                                           obj.manageResettingOfLibrary;
                [obj] =                                         obj.manageSavingOfLibrary;
                
                obj.updatePreviouslyLoadedFileInfo;
                
               
                fprintf('Exit PMMovieLibraryManager:@newProjectClicked.\n')  

        end
        
        function [obj] =    loadProjectClicked(obj,src,~)
            
            fprintf('Enter PMMovieLibraryManager:@loadProjectClicked:\n')  
            
              %% let the user select the file path:;
               [FileName,SelectedPath] =                           uigetfile('.mat', 'Load existing project');
                if SelectedPath== 0
                    return
                end
                
                obj.FileNameForLoadingNewObject =               [SelectedPath, FileName];
                obj.ActiveInfoType =                            'Project';
                obj =                                           obj.manageResettingOfLibrary;
                obj.updatePreviouslyLoadedFileInfo;   %% after loading the file: store the path of this file for future load at the beginning;

              
                 fprintf('Exit PMMovieLibraryManager:@loadProjectClicked.\n')  
            

        end
        
        function [obj] =    saveProjectClicked(obj,src,~)
            
            fprintf('\nPMMovieLibraryManager:@saveProjectClicked.\n')
            [obj] = obj.manageSavingOfLibrary;
            
        end
        
        
        
        
         %% getter:
         
         
        function [ListWithFileNamesToAdd] =             getMovieFileNames(obj)
            
            
            %% let the user choose movie-file/s from the movie-folder;
            
            fprintf('Enter: PMMovieLibraryManager:@getMovieFileNames:\n')
            assert(exist(obj.MovieLibrary.PathOfMovieFolder) == 7, 'No valid movie folder available. You must first choose a valid movie-folder.')

            cd(obj.MovieLibrary.PathOfMovieFolder);
            UserSelectedFileNames=                                                                 uipickfiles;
            if ~iscell(UserSelectedFileNames)
                fprintf('User decided to cancel entry. No files selected.\nExit: PMMovieLibraryManager:@getMovieFileNames.\n\n')
                return
            else
                
                FolderWasSelected =     cellfun(@(x) isfolder(x), UserSelectedFileNames);
                FolderWasSelected =     unique(FolderWasSelected);
                if length(FolderWasSelected) ~=1
                   error('You must select only folders (e.g. containing pic-files) or only files (e.g. TIFF, lsm, or czi), but not a mix of the two.') 
                end

                if FolderWasSelected

                    fprintf('Folder(s) were selected. Pic files are extracted from the folder(s).\n')
                    ExtracetedInformation =                 (cellfun(@(x) PMImageBioRadPicFolder(x), UserSelectedFileNames, 'UniformOutput', false))';
                    ListWithFiles =                         cellfun(@(x) x.FileNameList(:,1), ExtracetedInformation,  'UniformOutput', false);
                    ListWithFileNamesToAdd =                vertcat(ListWithFiles{:});

                else

                    fprintf('User directly selected files of interest.\n')
                    [~, file, ext]  =                       cellfun(@(x) fileparts(x), UserSelectedFileNames, 'UniformOutput', false);
                    ListWithFileNamesToAdd =                (cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false))';

                end
                     
            end
            
            fprintf('Add files: ')
            cellfun(@(x) fprintf('%s ', x), ListWithFileNamesToAdd)
            fprintf('Exit: PMMovieLibraryManager:@getMovieFileNames.\n\n')
            
        end
        
        
        function [missingFiles] =                       getUnincorporatedMovieFileNames(obj)
            
              missingFiles =                          obj.getAllFileNamesInMovieFolder;
            
              
              if ~isempty(missingFiles)
                  
                  
                        ListWithAlreadyAddedFiles =                             cellfun(@(x) x.AttachedFiles, obj.MovieLibrary.ListWithMovieObjectSummary, 'UniformOutput', false);
                        ListWithAlreadyAddedFiles=                              vertcat(ListWithAlreadyAddedFiles{:});

                        if ~isempty(ListWithAlreadyAddedFiles)
                           
                       
                             [~, file, ext]  =                                      cellfun(@(x) fileparts(x), ListWithAlreadyAddedFiles, 'UniformOutput', false);


                            ListWithAlreadyAddedFiles =                             cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false);
                             MatchingRows=                                                       cellfun(@(x) max(strcmp(x, ListWithAlreadyAddedFiles)), missingFiles);
                            missingFiles(MatchingRows,:)=                       [];
                            
                        end

                        


                         %% remove already added files from directory (so that they are not added as duplicates:
                           

              end
                
            
        end
        
        
          function [ListWithAllFileNamesInFolder] =     getAllFileNamesInMovieFolder(obj)
                
                %GETALLMOVIEFILENAMES Summary of this function goes here
                %   Detailed explanation goes here

                ListWithAllFileNamesInFolder=                                       (struct2cell(dir(obj.MovieLibrary.PathOfMovieFolder)))';
                RowsWithDirectories=                                                cell2mat(ListWithAllFileNamesInFolder(:,5))==1;
                ListWithAllFileNamesInFolder(RowsWithDirectories,:)=                [];
                RowsWithSystem=                                                     cellfun(@(x) (strcmp(x(1,1), '.')), ListWithAllFileNamesInFolder(:,1));   
                ListWithAllFileNamesInFolder(RowsWithSystem,:)=                     [];
                ListWithAllFileNamesInFolder(:,2:end)=                              [];

            end
        
      
        
          function [ Nickname ] =                       getNewUniqueNickName(obj)
            %NICKNAME_GET Summary of this function goes here
            %   Detailed explanation goes here

                ListWithAllExistingNicknamesInProject =                                      cellfun(@(x) x.NickName, obj.MovieLibrary.ListWithMovieObjectSummary, 'UniformOutput', false);
           
                Nickname=                                                                   inputdlg('For single or pooled movie sequence','Enter nickname');
                
                if isempty(Nickname)
                    return
                end
                
                Nickname=                                                                   Nickname{1,1};
                if isempty(Nickname)
                    return
                end

                UniqueNickNameWasSelected=                                                     isempty(find(strcmp(Nickname, ListWithAllExistingNicknamesInProject), 1));

                if ~UniqueNickNameWasSelected
                    Nickname = '';
                end




            end
         
         
          function [check] =                            pointIsWithinImageAxesBounds(obj, CurrentRow, CurrentColumn)
              
              
              MovieAxes =               obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
              

              XLimMin =                 MovieAxes.XLim(1);
              XLimMax =                 MovieAxes.XLim(2);
              
              YLimMin =                 MovieAxes.YLim(1);
              YLimMax =                 MovieAxes.YLim(2);
              
              % only axes is relevant now, so ignore if click is outside of
              % current axes limits:
              if min(CurrentColumn >= XLimMin) && min(CurrentColumn <= XLimMax) && min(CurrentRow >= YLimMin) && min(CurrentRow <= YLimMax)
                 check = true;
                 
              else
                  check = false;

              end
              
          end
        
          
          function [Category] =                         interpretMouseMovement(obj)

              if isempty(obj.ActiveMovieController) || isempty(obj.ActiveMovieController.MouseDownRow) || isempty(obj.ActiveMovieController.MouseDownColumn) 
                   
                  Category =      'Invalid';
                  
              elseif isnan(obj.ActiveMovieController.MouseDownRow) || isnan(obj.ActiveMovieController.MouseDownColumn)
                   
                  Category = 'Free movement';
                  
              else
                  

                   MovieAxes = obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
                    
                    obj.ActiveMovieController.MouseUpRow=                                                        MovieAxes.CurrentPoint(1,2);
                    obj.ActiveMovieController.MouseUpColumn=                                                     MovieAxes.CurrentPoint(1,1);

                    CurrentRows(1,1) =              obj.ActiveMovieController.MouseDownRow;
                    CurrentRows(2,1) =              obj.ActiveMovieController.MouseUpRow;
                    
                    CurrentColumns(1,1) =           obj.ActiveMovieController.MouseDownColumn;
                    CurrentColumns(2,1) =           obj.ActiveMovieController.MouseUpColumn;

                    if pointIsWithinImageAxesBounds(obj,CurrentRows,CurrentColumns)
                    
                        if (obj.ActiveMovieController.MouseDownRow == obj.ActiveMovieController.MouseUpRow) && (obj.ActiveMovieController.MouseDownColumn ==  obj.ActiveMovieController.MouseUpColumn)
                            Category = 'Stay';

                        else
                            Category = 'Movement';

                        end
                        
                    else
                        Category = 'Out of bounds';
                        
                        obj.ActiveMovieController.MouseDownRow =                NaN;
                        obj.ActiveMovieController.MouseDownColumn =             NaN;
                        
                        obj.ActiveMovieController.MouseUpRow =                NaN;
                        obj.ActiveMovieController.MouseUpColumn =             NaN;

                    end
                      
              end
              
              
              
          end
       
          function verifiedStatus =                     verifyActiveMovieStatus(obj)
              
              verifiedStatus = ~isempty(obj.ActiveMovieController)  && ~isempty(obj.ActiveMovieController.LoadedMovie) && ~isempty(obj.ActiveMovieController.Views) ;
              
          end

          function currentlySelectedNickName =          getCurrentlySelectedNickName(obj)
              
             
                currentlySelectedNickName =                                         obj.Viewer.ProjectViews.ListOfMoviesInProject.String{obj.Viewer.ProjectViews.ListOfMoviesInProject.Value};


          end
        
        
        
         %% setter:
            
            function obj =          manageAddingNewMovie(obj, MovieStructure)
                
                fprintf('\nEnter PMMovieLibraryManager:@manageAddingNewMovie:\n')
                PathOfMovieFolder =                             obj.MovieLibrary.PathOfMovieFolder;
                Version =                                       0;
                
                obj.ActiveMovieController.LoadedMovie =         PMMovieTracking(MovieStructure, PathOfMovieFolder, Version);
                obj =                                           obj.resetActiveNickNameWith(MovieStructure.NickName);
                obj =                                           obj.saveAndSynchronizeActiveMovie;
                
                obj =                                           obj.updateView;
                obj =                                           obj.callbackForFilterChange;
                fprintf('Exit PMMovieLibraryManager:@manageAddingNewMovie.\n\n')
                
            end
            
            function obj =          resetActiveNickNameWith(obj, NickNameString)
                
                fprintf('PMMovieLibraryManger:@resetActiveNickNameWith "%s".\n', NickNameString)
                obj.MovieLibrary.SelectedNickname=                                  NickNameString;
                obj.Viewer.ProjectViews.SelectedNickname.String =                   NickNameString;

                
            end

            function [obj] =          setPreviouslyUsedFileName(obj)
              
                fprintf('PMMovieLibraryManager:@setPreviouslyUsedFileName.\n')
                
                if exist(obj.FileWithPreviousSettings,'file')==2
                    load(obj.FileWithPreviousSettings, 'FileNameOfProject')
                    if exist(FileNameOfProject)==2
                        obj.FileNameForLoadingNewObject =  FileNameOfProject;
                        fprintf('FileNameForLoadingNewObject was changed to "%s".\n', FileNameOfProject)
                    else
                        fprintf('The settings file could not found. However, it had the wrong format and therefore the FileNameForLoadingNewObject was not changed.\n')
                    end

                else
                    
                    fprintf('The settings file could not be found. Therefore FileNameForLoadingNewObject was not changed.\n')
                end
                
                

            end
          
        
     
        
        
        function [obj] =        addCallbacksToFileAndProject(obj)
            
            
            
                 
            % movie-menu:


           
            %% for main figure:
              
            obj.Viewer.Figure.WindowKeyPressFcn =                                       @obj.keyPressed;
            obj.Viewer.Figure.WindowButtonDownFcn =                                     @obj.mouseButtonPressed;
            obj.Viewer.Figure.WindowButtonUpFcn =                                       @obj.mouseButtonReleased;
            obj.Viewer.Figure.WindowButtonMotionFcn =                                   @obj.mouseMoved;


            
            
             %% set menu callbacks:
            % file-menu:
            obj.Viewer.FileMenu.New.MenuSelectedFcn =                                   @obj.newProjectClicked;
            obj.Viewer.FileMenu.Save.MenuSelectedFcn =                                  @obj.saveProjectClicked;
            obj.Viewer.FileMenu.Load.MenuSelectedFcn =                                  @obj.loadProjectClicked;
            
            
            % project menu
            obj.Viewer.ProjectMenu.ChangeMovieFolder.MenuSelectedFcn=                   @obj.changeMovieFolderClicked;
            obj.Viewer.ProjectMenu.ChangeExportFolder.MenuSelectedFcn=                  @obj.changeExportFolderClicked;
            obj.Viewer.ProjectMenu.AddCapture.MenuSelectedFcn=                          @obj.addMovieClicked;
            obj.Viewer.ProjectMenu.RemoveCapture.MenuSelectedFcn=                       @obj.removeMovieClicked;
            obj.Viewer.ProjectMenu.AddAllCaptures.MenuSelectedFcn =                     @obj.addAllMissingCaptures;
            obj.Viewer.ProjectMenu.ShowMissingCaptures.MenuSelectedFcn =                     @obj.showMissingCaptures;
            
            
            
            obj.Viewer.ProjectMenu.Mapping.MenuSelectedFcn=                             @obj.mapUnMappedMovies;
            obj.Viewer.ProjectMenu.UnMapping.MenuSelectedFcn=                             @obj.unmapAllMovies;
            
            
            
            obj.Viewer.ProjectMenu.UpdateMovieSummary.MenuSelectedFcn=                             @obj.updateMovieSummaryFromFiles;
            obj.Viewer.ProjectMenu.ReplaceKeywords.MenuSelectedFcn=                             @obj.replaceKeywords;
            
            
            
            obj.Viewer.ProjectMenu.Info.MenuSelectedFcn =                               @obj.toggleProjectInfo;

            
            % help menu:
             obj.Viewer.HelpMenu.KeyboardShortcuts.MenuSelectedFcn  =                   @obj.showKeyboardShortcuts;

            
            %% other views
            obj.Viewer.ProjectViews.FilterForKeywords.Callback =                        @obj.callbackForFilterChange;
            obj.Viewer.ProjectViews.RealFilterForKeywords.Callback =                        @obj.callbackForFilterChange;
            
            
            obj.Viewer.ProjectViews.SortMovies.Callback =                               @obj.updateView;
            obj.Viewer.ProjectViews.ListOfMoviesInProject.Callback =                    @obj.movieListClicked;
            
   
        end
        
        
        function [obj] =        addCallbacksToMovieObject(obj)
            
            
             % movie menu:
            obj.Viewer.MovieControllerViews.Menu.Keyword.MenuSelectedFcn =                                              @obj.changeKeywordClicked;
              obj.Viewer.MovieControllerViews.Menu.Nickname.MenuSelectedFcn =                                              @obj.changeNicknameClicked;
              obj.Viewer.MovieControllerViews.Menu.RenameLinkedMovies.MenuSelectedFcn =                                              @obj.changeNameOfLinkeMoviesClicked;
            obj.Viewer.MovieControllerViews.Menu.LinkedMovies.MenuSelectedFcn =                                              @obj.changeLinkedMoviesClicked;
          
            
            
            
            
            obj.Viewer.MovieControllerViews.Menu.ReapplySourceFiles.MenuSelectedFcn =                                   @obj.reapplySourceFilesClicked;
            obj.Viewer.MovieControllerViews.Menu.DeleteImageCache.MenuSelectedFcn =                                     @obj.deleteImageCacheClicked;
            
            obj.Viewer.MovieControllerViews.Menu.ApplyManualDriftCorrection.MenuSelectedFcn =                           @obj.applyManualDriftCorrectionClicked;
            %obj.Viewer.MovieControllerViews.Menu.CompleteManualDriftCorrection.MenuSelectedFcn =                        @obj.completeManualDriftCorrectionClicked;
            obj.Viewer.MovieControllerViews.Menu.EraseAllDriftCorrections.MenuSelectedFcn =                             @obj.eraseAllDriftCorrectionsClicked;
            
            
            
            obj.Viewer.MovieControllerViews.Menu.ShowMetaData.MenuSelectedFcn =                                         @obj.showMetaDataInfoClicked;
            obj.Viewer.MovieControllerViews.Menu.ShowCompleteMetaData.MenuSelectedFcn =                                 @obj.showCompleteMetaDataInfoClicked;
            
            
            obj.Viewer.MovieControllerViews.Menu.ShowAttachedFiles.MenuSelectedFcn =                                    @obj.showAttachedFilesClicked;
            obj.Viewer.MovieControllerViews.Menu.ExportMovie.MenuSelectedFcn =                                           @obj.exportMovie;
            
            obj.Viewer.MovieControllerViews.Menu.ExportTrackCoordinates.MenuSelectedFcn =                               @obj.exportTrackCoordinates;
              
            
            
            
            
            
        end

        
         
        
        
        
        function [obj] =        addCallbacksToNavigationAndTracking(obj)
            
            fprintf('PMMovieLibraryManger:@addCallbacksToNavigationAndTracking.\n')
            
            % tracking menu:
            
            
            obj.Viewer.TrackingViews.Menu.AutoCellRecognition.MenuSelectedFcn =                         @obj.manageAutoCellRecognition;
            obj.Viewer.TrackingViews.Menu.DeleteTrack.MenuSelectedFcn =                         @obj.deleteTrackClicked;
            
            obj.Viewer.TrackingViews.Menu.DeleteAllTracks.MenuSelectedFcn =                      @obj.deleteAllTracksClicked;
            obj.Viewer.TrackingViews.Menu.RemoveShortTracks.MenuSelectedFcn =                      @obj.deleteTracksLessThan;
            
            
            
            
            obj.Viewer.TrackingViews.Menu.MergeTracks.MenuSelectedFcn =                         @obj.mergeSelectedTracks;
            obj.Viewer.TrackingViews.Menu.SpitTracks.MenuSelectedFcn =                         @obj.splitSelectedTracks;
            
            
            
         
            obj.Viewer.TrackingViews.Menu.UpdateTracks.MenuSelectedFcn =                        @obj.updateTracksClicked;
            obj.Viewer.TrackingViews.Menu.DeleteMask.MenuSelectedFcn  =                         @obj.deleteMaskClicked;
          
            
            
            

               addlistener(obj.Viewer.MovieControllerViews.Navigation.TimeSlider,'Value','PreSet', @obj.sliderActivity);
             
            
                obj.ActiveMovieController.Views.Navigation.EditingOptions.Callback =                  @obj.editingOptionsClicked;
                
                
                obj.ActiveMovieController.Views.Navigation.CurrentPlane.Callback =                  @obj.planeViewClicked;
                obj.ActiveMovieController.Views.Navigation.CurrentTimePoint.Callback =              @obj.frameViewClicked;
                obj.ActiveMovieController.Views.Navigation.ShowMaxVolume.Callback =                 @obj.maximumProjectionClicked;
                obj.ActiveMovieController.Views.Navigation.CropImageHandle.Callback =               @obj.croppingOnOffClicked;
                obj.ActiveMovieController.Views.Navigation.ApplyDriftCorrection.Callback =          @obj.driftCorrectionOnOffClicked;
   
                % channel settings:
                obj.ActiveMovieController.Views.Channels.SelectedChannel.Callback =                 @obj.channelViewClicked;
                obj.ActiveMovieController.Views.Channels.MinimumIntensity.Callback =                @obj.channelLowIntensityClicked;
                obj.ActiveMovieController.Views.Channels.MaximumIntensity.Callback =                @obj.channelHighIntensityClicked;
                obj.ActiveMovieController.Views.Channels.Color.Callback =                           @obj.channelColorClicked;
                obj.ActiveMovieController.Views.Channels.Comment.Callback =                         @obj.channelCommentClicked;
                obj.ActiveMovieController.Views.Channels.OnOff.Callback =                           @obj.channelOnOffClicked;
                obj.ActiveMovieController.Views.Channels.ChannelReconstruction.Callback =            @obj.channelReconstructionClicked;
                
                
                % annotation:
                obj.ActiveMovieController.Views.Annotation.ShowScaleBar.Callback =                   @obj.annotationScaleBarOnOffClicked;
                obj.ActiveMovieController.Views.Annotation.SizeOfScaleBar.Callback =                 @obj.annotationScaleBarSizeClicked;

                
                
                % TRACKING
                obj.ActiveMovieController.TrackingViews.ActiveTrackTitle.Callback =                   @obj.trackingActiveTrackButtonClicked;
                obj.ActiveMovieController.TrackingViews.ShowCentroids.Callback =                    @obj.trackingCentroidButtonClicked;
                obj.ActiveMovieController.TrackingViews.ShowMasks.Callback =                 @obj.trackingShowMaskButtonClicked;
                obj.ActiveMovieController.TrackingViews.ShowTracks.Callback =                 @obj.trackingShowTracksButtonClicked;
                obj.ActiveMovieController.TrackingViews.ShowMaximumProjection.Callback =                 @obj.trackingShowMaximumProjectionButtonClicked;
                obj.ActiveMovieController.TrackingViews.ListWithFilteredTracks.Callback =                 @obj.trackingTrackListClicked;

                 

            
        end
        
        
        
        %% response to project menu-click:
        
        function [obj] =        changeMovieFolderClicked(obj,src,~)
            
            
             
                fprintf('\nEnter PMMovieLibraryManager:@changeMovieFolderClicked:\n')

                    [NewPath]=                                              uipickfiles('FilterSpec', obj.MovieLibrary.getMainFolder, 'Prompt', 'Select movie folder',...
                    'NumFiles', 1, 'Output', 'char');
                    if isempty(NewPath) || ~ischar(NewPath)
                        return
                    end

                    obj.MovieLibrary =                                      obj.MovieLibrary.resetFolders(NewPath);
                    
                    if ~isempty(obj.ActiveMovieController.LoadedMovie)
                        obj.ActiveMovieController.LoadedMovie.Folder =      NewPath;
                    end

                    obj =                                                   obj.updateInfoView;
                    
                fprintf('\nEnter PMMovieLibraryManager:@changeMovieFolderClicked:\n\n')
            
            
        end
        
        function [obj] =        changeExportFolderClicked(obj,src,~)
            
            
                [NewPath]=                             uipickfiles('FilterSpec', obj.MovieLibrary.getMainFolder, 'Prompt', 'Select export folder',...
                'NumFiles', 1, 'Output', 'char');
                if isempty(NewPath) || ~ischar(NewPath)
                    return
                end

                obj.MovieLibrary.PathForExport =        NewPath;
                obj =                                   obj.updateInfoView;
            
            
        end
        
        function [obj] =        addMovieClicked(obj,src,~)
            
             fprintf('\nEnter PMMovieLibraryManager:@addMovieClicked:\n')

             MovieStructure.AttachedFiles =         obj.getMovieFileNames;
             MovieStructure.NickName =              obj.getNewUniqueNickName;
             
             obj =                                  obj.manageAddingNewMovie(MovieStructure);

             fprintf('Exit PMMovieLibraryManager:@addMovieClicked.\n\n')
             
        end
        
        
        function [obj] =        removeMovieClicked(obj,src,~)
            
                fprintf('\nEnter PMMovieLibraryManager:@removeMovieClicked:\n')

                SelectedNickname =              obj.MovieLibrary.SelectedNickname;
                
                 answer = questdlg(['Are you sure you remove the movie ', SelectedNickname, ' from the library?  The file with the actual tracking data will remain. It needs to be deleted manually'], ...
                'Project menu', 'Yes',   'No','No');
                % Handle response
                
                
                switch answer
                    
                    case 'Yes'
                          %% get rows of currently selected movies in structure:
                        
                        %% remove selected movies from structure:
                        
                        obj.MovieLibrary =                              obj.MovieLibrary.removeFromLibraryMovieWithNickName(SelectedNickname);
                        
                        
                        obj =                                           obj.updateView;
                        obj =                                           obj.callbackForFilterChange;
                        
                        
                        obj =                                           obj.resetActiveNickNameWith('');
                        obj =                                           obj.resetActiveMovieControllerWithActiveNickName;
                        
                    case 'No'

                end 
            
                fprintf('Exit PMMovieLibraryManager:@removeMovieClicked.\n\n')
                
        end
        
        
        function [obj] =        showMissingCaptures(obj,src,~)
            
             missingFiles =                          obj.getUnincorporatedMovieFileNames;
             
             
              obj.Viewer.InfoView.List.String =               missingFiles;
             obj.Viewer.InfoView.List.Value =            min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);
            
            
        end
        
        function [obj] =        addAllMissingCaptures(obj,src,~)
            
                missingFiles =                          obj.getUnincorporatedMovieFileNames;
                
                %% go through each file and add to project:
                 NumberOfFiles =                                                    size(missingFiles,1);
                 for FileIndex= 1:NumberOfFiles
                        %% create nickname from first filename:
                     
                        [ NewUniqueNickname ] =             missingFiles{FileIndex,1}(1:end-4);
                        FileName{1,1} =                     missingFiles{FileIndex,1};
                        
                        MovieStructure.NickName =             NewUniqueNickname;
                        MovieStructure.AttachedFiles =        FileName;

                        obj =                                  obj.manageAddingNewMovie(MovieStructure);
          
                 end
     
     
    
            
        end
        
        
        
        function [obj] =        batchProcessingOfNickNames(obj,NickNames,ActionType)
            
            % store the previously active movie
             obj =                                                                          obj.saveAndSynchronizeActiveMovie;
                    
            NumberOfMovies =    size(NickNames,1);
            
            for CurrentMovieIndex = 1:NumberOfMovies
                
                % switch active movie controller to current nickname;
                MyNickName =                                    NickNames{CurrentMovieIndex};
                obj =                                           obj.resetActiveNickNameWith(MyNickName);
                obj =                                           obj.resetActiveMovieControllerWithActiveNickName;

                
                % perform wanted action on active movie;
                switch ActionType
                    
                    case 'MapImages'

                         obj.ActiveMovieController =                obj.ActiveMovieController.manageResettingOfImageMap;

                         
                    case 'UnMapImages'

                        obj.ActiveMovieController =                obj.ActiveMovieController.manageUnMappingOfLoadedMovie;

                end
                
                 % store an synchronize currently modified movie and ;
                    obj =                                           obj.saveAndSynchronizeActiveMovie;
                    obj.ActiveMovieController =                     obj.ActiveMovieController.updateSaveStatusView;
                    obj =                                           obj.updateInfoView;

                    obj=                                            obj.callbackForFilterChange;

                
            end
            
            
        end
        
  
        function [obj] =           mapUnMappedMovies(obj,src,~)
            
            
            %% reset filter so that live watching of mapping update can be seen;
            WantedFilterRow =                                           strcmp(obj.Viewer.ProjectViews.FilterForKeywords.String, 'Show all unmapped movies');
            obj.Viewer.ProjectViews.FilterForKeywords.Value =           find(WantedFilterRow);
           obj =                                       obj.callbackForFilterChange;

            
            %% get data
            listWithAllNicknames =                                      cellfun(@(x) x.NickName, obj.MovieLibrary.ListWithMovieObjectSummary, 'UniformOutput', false);
            listWithWantedRowsInLibrary =                               obj.MovieLibrary.FilterList;
            listWithAllWantedNickNames =                                listWithAllNicknames(listWithWantedRowsInLibrary,:);
            
            [obj] =                                                         obj.batchProcessingOfNickNames(listWithAllWantedNickNames,'MapImages');
            
          
        end
        
        function obj = unmapAllMovies(obj,src,~)
            
            
            
            %% reset filter so that live watching of mapping update can be seen;
            WantedFilterRow =                                               strcmp(obj.Viewer.ProjectViews.FilterForKeywords.String, 'Show all unmapped movies');
            obj.Viewer.ProjectViews.FilterForKeywords.Value =               find(WantedFilterRow);
            [obj] =                                                         obj.callbackForFilterChange(src, 0);
            
            %% get data
            listWithAllNicknames =                                          cellfun(@(x) x.NickName, obj.MovieLibrary.ListhWithMovieObjects, 'UniformOutput', false);
          
            [obj] =                                                         obj.batchProcessingOfNickNames(listWithAllNicknames,'UnMapImages');
            
            
           
            
        end
        
        
        function obj = updateMovieSummaryFromFiles(obj,src,~)
            
            obj.MovieLibrary = obj.MovieLibrary.updateMovieSummariesFromFiles;
            
        end
        
      
        function obj = replaceKeywords(obj,src,~)
            
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

            
            ListWithKeywords =           obj.MovieLibrary.getKeyWordList;
            
            KeywordChangeViewer =        obj.Viewer.createKeywordEditorView;
            
            KeywordChangeViewer.ListWithFilterWordsTarget.String =      ListWithKeywords;
            KeywordChangeViewer.ListWithFilterWordsSource.String =         ListWithKeywords;
            
            
             waitfor(KeywordChangeViewer.DoneField,'Value')

            
             [KeywordManagerSelection] = DoneField_KeywordManager(KeywordChangeViewer);
      
             
             
   
             if strcmp(KeywordManagerSelection.SourceKeywordType, 'Cancel')
                 return

             end
             
             obj.ActiveMovieController.LoadedMovie.Keywords{1,1} =          KeywordManagerSelection.TargetKeyword;
              obj.MovieLibrary =                                            obj.MovieLibrary.replaceKeywords(KeywordManagerSelection.SourceKeyword,KeywordManagerSelection.TargetKeyword);
            
              
              obj =                           obj.updateView;
                obj =                           obj.callbackForFilterChange;
                
                obj =                           obj.updateInfoView;
              
        end
        

        function [obj] =    toggleProjectInfo(obj,src,~)
            
            
            obj.ActiveInfoType =                'Project';
            obj =                               obj.updateInfoView;
            
            
          
        end
       
  

        %% response to help menu click:
        
        
        function [obj] = showKeyboardShortcuts(obj,src,~)
            
            
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
          function [obj] =           keyPressed(obj,src,~)
             
              
              PressedKey=                             get(obj.Viewer.Figure,'CurrentCharacter');
              CurrentModifier =                                       obj.Viewer.Figure.CurrentModifier;
              
             if isempty(PressedKey) || ~obj.verifyActiveMovieStatus
                 return
             end
             
      
             
             %% library manager does some library related activities himself:
             
             switch PressedKey
               case 's'

                         NumberOfModifers = length(CurrentModifier);
                         switch NumberOfModifers

                             case 1
            

                                 if strcmp(CurrentModifier, 'command')

                                       obj =                                                                          obj.saveAndSynchronizeActiveMovie;
                                       return
                                       
                                       
                                 end
                                 
                         end
                         
             end
             
             
            %% more specific tasks are done directly by MovieController
             
             obj.ActiveMovieController.interpretKey(PressedKey,CurrentModifier);
             obj.Viewer.Figure.CurrentCharacter =                   '0';
             

          end
        
         
     
          function [obj] =          mouseButtonPressed(obj,src,~)
              
                MovieAxes =                                             obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
                obj.ActiveMovieController.MouseDownRow =                MovieAxes.CurrentPoint(1,2);
                obj.ActiveMovieController.MouseDownColumn =             MovieAxes.CurrentPoint(1,1);

               
                
                
               mousePattern =                                      obj.interpretMouseMovement;
                     
               
               if strcmp(mousePattern, 'Out of bounds')
                   obj.MouseAction = 'No action';
                   return
               end
               
              
              if obj.verifyActiveMovieStatus
                  
                    
                    myEditingActivity =                                     obj.ActiveMovieController.LoadedMovie.EditingActivity;
                    
                    
                    
                    CurrentModifier =                                       obj.Viewer.Figure.CurrentModifier;
                    NumberOfModifiers =                                     size(CurrentModifier,2);
                    
                    switch  NumberOfModifiers
                        
                        
                        case 0
                            
                            switch myEditingActivity
                                
                                case 'Tracking'
                                    obj.MouseAction =               'Edit mask';
                                    obj.ActiveMovieController =     obj.ActiveMovieController.updateActiveMaskByButtonClick;

                                otherwise

                                    obj.MouseAction = 'No action';
                                
                                
                                
                            end
                            
                            
                            
                        case 1
                            
                            NameOfModifier = CurrentModifier{1,1};
                            switch NameOfModifier
                                
                                case 'shift'
                                    
                                    switch myEditingActivity
                                
                                        case 'Tracking'
                                            obj.MouseAction =               'Edit mask';
                                            SelectedTrackIDs =                                                                obj.ActiveMovieController.LoadedMovie.findNewTrackID;
                                            
                                            obj.ActiveMovieController.LoadedMovie =                                      obj.ActiveMovieController.LoadedMovie.setActiveTrackWith( SelectedTrackIDs);
                                            obj.ActiveMovieController =                                                     obj.ActiveMovieController.updateActiveMaskByButtonClick;
                                            obj.ActiveMovieController =                                                   obj.ActiveMovieController.resetActiveTrack;
                                            obj.ActiveMovieController =                                                   obj.ActiveMovieController.updateViewsAfterTrackSelectionChange;

                                             
                                            
                                        case 'Manual drift correction'
                                            obj.MouseAction =           'Edit manual drift correction';
                                            [rowFinal, columnFinal, planeFinal, frame] =               obj.ActiveMovieController.getCoordinatesOfButtonPress;

                                            
                                            
                                            obj.ActiveMovieController.LoadedMovie.DriftCorrection =     obj.ActiveMovieController.LoadedMovie.DriftCorrection.updateManualDriftCorrectionByValues(columnFinal, rowFinal, planeFinal, frame);
                                            obj.ActiveMovieController  =                                obj.ActiveMovieController.updateManualDriftCorrectionView;
                                            
                                        otherwise
                                            obj.MouseAction = 'No action';

                                    end
                                     
                                case 'control'
                                    obj.MouseAction = 'MoveViewOrChangeTrack';
                                    
                                case 'alt'
                                    obj.MouseAction = 'Draw rectangle';
                                    
                                case 'command'
                                    
                                    switch myEditingActivity
                                
                                        case 'Tracking'
                                             obj.MouseAction = 'Subtract pixels';
                                             
                                        otherwise
                                            obj.MouseAction = 'No action';
                                            
                                            
                                            
                                    end
                                   
                                    
                                otherwise
                                    obj.MouseAction = 'No action';
                                
                            end
                            
   
                        case 2
                            
                            if max(strcmp(CurrentModifier, 'shift')) && max(strcmp(CurrentModifier, 'command'))
                                NameOfModifier = 'ShiftAndCommand';
                                
                            elseif max(strcmp(CurrentModifier, 'shift')) && max(strcmp(CurrentModifier, 'control'))
                                 NameOfModifier = 'ShiftAndControl';
                                 
                            elseif max(strcmp(CurrentModifier, 'shift')) && max(strcmp(CurrentModifier, 'alt'))
                                 NameOfModifier = 'ShiftAndAlt';
                                
                                
                            else
                                NameOfModifier = 'unknown';
                            end
                            
                            
                            
                            switch NameOfModifier
                                
                             case 'ShiftAndCommand'
                                 switch myEditingActivity

                                            case 'Tracking'
                                                obj.MouseAction =           'Add pixels';


                                            otherwise

                                                obj.MouseAction = 'No action';

                                 end
                                 
                                case 'ShiftAndControl'
                                    
                                     obj.MouseAction = 'ConnectTrackToActiveTrack';
                                 
                                case 'ShiftAndAlt'
                                    
                                    obj.MouseAction = 'UsePressedPointAsCentroid';
                             
                            end
                                    
                             
                        otherwise
                            
                            obj.MouseAction = 'No action';
                              
                        
                    end
                    
       
                    
              end
              

                   %% transfer read data into model:               
%                 MovieModel.ViewMovieHandles.ControlLine.XData=                      NaN;
%                 MovieModel.ViewMovieHandles.ControlLine.YData=                      NaN;


              
          end
          
          
         
          function [obj] =          mouseMoved(obj,src,~)
              
              
               %% get mouse action (defined by key press during button down);
                        currentMouseAction =                                obj.MouseAction;
                      
              
             if strcmp(currentMouseAction, 'No action')
                obj.ActiveMovieController.MouseDownRow =              NaN;
                obj.ActiveMovieController.MouseDownColumn =           NaN;
                
                obj.ActiveMovieController.MouseUpRow =              NaN;
                obj.ActiveMovieController.MouseUpColumn =           NaN;


                  return
              end
              
              if obj.verifyActiveMovieStatus
                        
                        %% update current position in object: 
                        MovieAxes =                                         obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
                        obj.ActiveMovieController.MouseUpRow =              MovieAxes.CurrentPoint(1,2);
                        obj.ActiveMovieController.MouseUpColumn =           MovieAxes.CurrentPoint(1,1);
                        
                        %% interpret mouse pattern:
                        mousePattern =                                      obj.interpretMouseMovement;
                        
                         
                        switch currentMouseAction
                            
                            case 'Draw rectangle'
                                
                                 switch mousePattern

                                      case 'Movement'
                                             Rectangle =                     obj.ActiveMovieController.getRectangleFromMouseDrag;
          
       
                                             
                                                obj.ActiveMovieController.LoadedMovie =                       obj.ActiveMovieController.LoadedMovie.setCroppingGateWithRectange(Rectangle);
                                             obj.ActiveMovieController =                     obj.ActiveMovieController.updateCroppingLimitView;
                                            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.updateAppliedCroppingLimits;

                                      case {'Invalid', 'Out of bounds'}
                                            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.resetCroppingGate;
                                            obj.ActiveMovieController =                     obj.ActiveMovieController.updateCroppingLimitView;
                                            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.updateAppliedCroppingLimits;

                                 end
                                
                            case 'MoveViewOrChangeTrack'
                            
                                switch mousePattern

                                      case 'Movement'

                                          XMovement =                       obj.ActiveMovieController.MouseUpColumn - obj.ActiveMovieController.MouseDownColumn;
                                          YMovement =                       obj.ActiveMovieController.MouseUpRow - obj.ActiveMovieController.MouseDownRow;
                                          obj.ActiveMovieController =       obj.ActiveMovieController.resetAxesCenter(XMovement, YMovement);
   
                                end
                        
                        
                             case 'Edit mask'
                                
                                
                                switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.updateActiveMaskByButtonClick;
                                        
                                    
                                end
                                
                                
                            case 'Subtract pixels'
                                
                                  switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.removeHighlightedPixelsFromMask;
                                    
                                  end
                                
                            case 'Add pixels'
                                
                                  switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                       
                                         obj.ActiveMovieController =   obj.ActiveMovieController.addHighlightedPixelsFromMask;
                                       
                                    
                                  end
                                  
                                  
                            case 'UsePressedPointAsCentroid'
                                
                                 switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                       
                                         obj.ActiveMovieController =   obj.ActiveMovieController.usePressedCentroidAsMask;
                                       
                                    
                                  end
                                

                                  
                            case 'Edit manual drift correction'
                                
                                 switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        
                                    
                                  end
                                
                                

                                
                        end
                                

                     


              end


              end
            
    
          
    
          
          
          
          function [obj] =          mouseButtonReleased(obj,src,~)
              
              
               currentMouseAction =                                obj.MouseAction;
                      
              
              if strcmp(currentMouseAction, 'No action')
                  
                    obj.ActiveMovieController.MouseDownRow =              NaN;
                    obj.ActiveMovieController.MouseDownColumn =           NaN;

                    obj.ActiveMovieController.MouseUpRow =              NaN;
                    obj.ActiveMovieController.MouseUpColumn =           NaN;


                   return
                   
              end
              
                %% update current position in object: 
                MovieAxes =                                         obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
                obj.ActiveMovieController.MouseUpRow =              MovieAxes.CurrentPoint(1,2);
                obj.ActiveMovieController.MouseUpColumn =           MovieAxes.CurrentPoint(1,1);

                
                %% interpret mouse pattern:
                mousePattern =                                      obj.interpretMouseMovement;

                %% get mouse action (defined by key press during button down);
                currentMouseAction =                                obj.MouseAction;

                  switch currentMouseAction
                            
                            case 'Draw rectangle'
                                
                                 switch mousePattern

                                      case 'Stay'
                                           
                                            
                                      case {'Invalid', 'Out of bounds'}
                                          
                                          
                                 end
                                 
                                 
                            case 'Subtract pixels'
                                
                                  switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        
                                        
                                    
                                  end
                                
                                  
                               case 'Add pixels'
                                
                                  switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        
                                    
                                  end
                                  
                                  
                           case 'UsePressedPointAsCentroid'
                                    
                                     obj.ActiveMovieController =   obj.ActiveMovieController.usePressedCentroidAsMask;
                                     
                                  
                            case 'AutoTrackCurrentCell'
                                
                                switch mousePattern
                                    
                                    case { 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.autoTrackCurrentCell;
                                        
                                    
                                end
                          
                                  
                             case 'MoveViewOrChangeTrack'
                            
                                switch mousePattern
                                    case 'Stay'
                                        obj.ActiveMovieController =             obj.ActiveMovieController.changeActiveTrackByRectangle;
                                        obj.ActiveMovieController =            obj.ActiveMovieController.updateViewsAfterTrackSelectionChange;
                                        
                                        
                                end
                                
                            case 'ConnectTrackToActiveTrack'
                                
                                 switch mousePattern
                                    case 'Stay'
                                        obj.ActiveMovieController =             obj.ActiveMovieController.connectSelectedTrackToActiveTrack;
                                        obj.ActiveMovieController =            obj.ActiveMovieController.updateViewsAfterTrackSelectionChange;
                                        
                                        
                                end

                                 
                            end
              
                obj.MouseAction =                                       'No action';  
                obj.ActiveMovieController.MouseDownRow =                NaN;
                obj.ActiveMovieController.MouseDownColumn =             NaN;

             
   
          end
          
          
          
        %% respond to clicks on project views:
       
        
        function [obj] =        movieListClicked(obj, src, ~)
            

            fprintf('\nPMMovieLibraryManager: @movieListClicked\n')
            
            SelectionType =                                         obj.Viewer.Figure.SelectionType;
            switch SelectionType
                
                case 'open'
                    
                    %% save active movie and transfer info of "active movie" to MovieLibrary list;
                    
                    fprintf('PMMovieLibraryManager: @movieListClicked: double-click registered\n')
                    currentlySelectedNickName =                                                    obj.getCurrentlySelectedNickName;
                    
                    obj=                                                                            obj.manageTransferOfActiveMovieToNickName(currentlySelectedNickName);
                    
                    
           
            end
            
           
        end
        
        
        function [obj] =        callbackForFilterChange(obj, src, ~)
            
             
            fprintf('\nEnter PMMovieLibraryManager:@callbackForFilterChange:\n')
                %% apply current selection in menu to filter
                
                PopupMenuOne =                          obj.Viewer.ProjectViews.FilterForKeywords;
                PopUpMenuTwo =                          obj.Viewer.ProjectViews.RealFilterForKeywords;
                
                obj.MovieLibrary =                      obj.MovieLibrary.updateFilterSettingsFromPopupMenu(PopupMenuOne,PopUpMenuTwo);
                obj =                                   obj.updateView;
                 
              
             fprintf('Enter PMMovieLibraryManager:@callbackForFilterChange.\n\n') 
                 
            
        end
        

        
        %% response to movie menu click:
        
        
        

        function [obj] = changeKeywordClicked(obj,src,~)
               
                fprintf('Enter PMMovieLibraryManager:@changeKeywordClicked:\n')
                
                obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.changeMovieKeyword;
               
                obj.MovieLibrary =                              obj.MovieLibrary.synchronizeMovieLibraryWithActiveMovie(obj.ActiveMovieController);
                obj =                                           obj.updateView;
                obj =                                           obj.callbackForFilterChange;
                
                obj =                                           obj.updateInfoView;
            
                fprintf('Exit PMMovieLibraryManager:@changeKeywordClicked.\n\n')
            
        end
        
         function [obj] = changeNicknameClicked(obj,src,~)
               
             fprintf('\nPMMovieLibraryManager:@changeNicknameClicked:\n')
               
             % get row in library that corresponds to active movie 
             
              
               NewUniqueNickname =                                                                          obj.getNewUniqueNickName;
               if isempty(NewUniqueNickname)
                   fprint('User entered: %s. This nickname is empty or a duplicate of what is used in library\n.', NewUniqueNickname)
                   return 
                   
               end

                obj =                                       obj.renameNickNameOfActiveMovieWith(NewUniqueNickname);
             
                
                
              
                % also place the current image data into the manager;
                % they should not be saved on file because it could blow up storage;
                % but they should be kept in memory so that previous movie information of a previously selected file can be accessed quickly;
              
               
                obj =                                       obj.saveAndSynchronizeActiveMovie;
                obj =                                       obj.updateView;
                obj =                                       obj.callbackForFilterChange;
            
                fprintf('Exit PMMovieLibraryManager:@changeNicknameClicked:\n\n')
            
         end
         
         
         function [obj] =          renameNickNameOfActiveMovieWith(obj, NicknameAfterChange)    
            
                NickNameBeforeChange =                                                                          obj.ActiveMovieController.LoadedMovie.NickName;
                OldPath =                                                                                       obj.ActiveMovieController.LoadedMovie.getFileNameOfAnnotation;
                
                CurrentlyEditedRowInLibrary =                                                                   obj.MovieLibrary.getSelectedRowInLibraryOf(NickNameBeforeChange);
                if sum(CurrentlyEditedRowInLibrary) == 0
                    return
                end

                % change nickname both in active movie and library and then rename the linked file;
                % this is all that should be necessary;
                obj.MovieLibrary.SelectedNickname =                                                                 NicknameAfterChange;
                obj.ActiveMovieController.LoadedMovie =                                                             obj.ActiveMovieController.LoadedMovie.changeMovieNickname(NicknameAfterChange);
                obj.MovieLibrary.ListhWithMovieObjects{CurrentlyEditedRowInLibrary,1}.NickName =                    NicknameAfterChange;
                obj.MovieLibrary.ListWithMovieObjectSummary{CurrentlyEditedRowInLibrary,1}.NickName =               NicknameAfterChange;
 
           
                
                obj.ActiveMovieController.LoadedMovie=                                                          obj.ActiveMovieController.LoadedMovie.renameMovieDataFile(OldPath);

         end
        
        
         
        
         
         function [obj] = changeNameOfLinkeMoviesClicked(obj,src,~)
             
             
               NamesOfAttachedFileNames=                                        obj.ActiveMovieController.LoadedMovie.AttachedFiles;

               MoviePath =                                                      obj.MovieLibrary.PathOfMovieFolder;
               
               myFileMangeer =                                                  PMFileManagement(MoviePath);
               myFileManagerViewer =                                            PMFileManagementViewer(myFileMangeer);
             
               myFileManagerViewer =                                            myFileManagerViewer.resetSelectedFiles(NamesOfAttachedFileNames);
             
               myFileManagerViewer.GraphicObjects.EditField.Callback =          @obj.renameFiles;
               
               obj.FileManagerViewer =                                          myFileManagerViewer;
                
       
         end
         
         
         function [obj] = renameFiles(obj,src,~)
             
             
            obj.FileManagerViewer =                         obj.FileManagerViewer.RenameSelectedFile;



            ListWithFileNamesToAdd =                        obj.FileManagerViewer.FileManager.SelectedFileNames;
            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.changeMovieLinkedMovieFiles(ListWithFileNamesToAdd);

            obj.MovieLibrary =                              obj.MovieLibrary.synchronizeMovieLibraryWithActiveMovie(obj.ActiveMovieController);
            obj =                                           obj.updateView;
            obj =                                           obj.callbackForFilterChange;

            obj =                                           obj.updateInfoView;

             
         end
             
             

         
         
          function [obj] = changeLinkedMoviesClicked(obj,src,~)
               
              
                [ListWithFileNamesToAdd] =                      obj.getMovieFileNames;

                obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.changeMovieLinkedMovieFiles(ListWithFileNamesToAdd);

                obj.MovieLibrary =                              obj.MovieLibrary.synchronizeMovieLibraryWithActiveMovie(obj.ActiveMovieController);
                obj =                                           obj.updateView;
                obj =                                           obj.callbackForFilterChange;

            
        end
        
        
          
          
        
        
           
        function [obj] = reapplySourceFilesClicked(obj,src,~)
              
            fprintf('\n Enter PMMovieLibraryManager:@reapplySourceFilesClicked:\n')
            
             if isempty(obj.ActiveMovieController)  || isempty(obj.ActiveMovieController.LoadedMovie)
                 return
             end
             
             obj.ActiveMovieController =                                                                  obj.ActiveMovieController.manageResettingOfImageMap;
           
             fprintf('Exit PMMovieLibraryManager:@reapplySourceFilesClicked.\n\n')
              
          end
          
          
        function  [obj] = deleteImageCacheClicked(obj,src,~)
              
               
             if isempty(obj.ActiveMovieController) 
                 return
             end
             
             % first erase all the image volumes (if something was wrong we don't want these anymore);
            obj.ActiveMovieController    =                  obj.ActiveMovieController.emptyOutLoadedImageVolumes;
             
           
              
        end
        
        
        function  [obj] = applyManualDriftCorrectionClicked(obj,src,~)
            
            obj.ActiveMovieController =                      obj.ActiveMovieController.resetDriftCorrectionByManualClicks;
            
            
        end
        
      
        
        function  [obj] = eraseAllDriftCorrectionsClicked(obj,src,~)

             obj.ActiveMovieController =                      obj.ActiveMovieController.resetDriftCorrectionToNoDrift;
            
           
            
        end
        
        

          
        
        function [obj] = showAttachedFilesClicked(obj,src,~)
            
          

                %% get data of current movie:
              
                obj.ActiveInfoType =                'Attached files';
                obj =                               obj.updateInfoView;
          
    
             
            
         end
        
          
        function [obj] = showMetaDataInfoClicked(obj,src,~)

                obj.ActiveInfoType =                'MetaData';
                obj= obj.updateInfoView;  
                
                
                % obj.ActiveMovieController.LoadedMovie.Tracking.getTrackIdsWithLimitedMaskData;
                
                
                obj.ActiveMovieController.LoadedMovie =           obj.ActiveMovieController.LoadedMovie.refreshTrackingResults('OnlyUnfinishedTracks');
                            obj.ActiveMovieController =                       obj.ActiveMovieController.updateViewsAfterChangesInTracks;  

        end
        
        
        function [obj] = showCompleteMetaDataInfoClicked(obj, src, ~)
            
            
            
            fileType =                                           obj.ActiveMovieController.LoadedMovie.getFileType;

            switch fileType
                
                case 'czi' 
                    
                    % get meta-data string:
                    myImageDocuments =                                  cellfun(@(x)  PMCZIDocument(x), obj.ActiveMovieController.LoadedMovie.ListWithPaths, 'UniformOutput', false);
                    FirstMovie =                                        myImageDocuments{1,1};
                    MetaDataString =                                    FirstMovie.SegmentList{cellfun(@(x) contains(x, 'ZISRAWMETADATA'), FirstMovie.SegmentList(:,1)),6};

                 case {'tif'}
                    
                     
                    FirstMovie =                                  cellfun(@(x)  PMTIFFDocument(x), obj.ActiveMovieController.LoadedMovie.ListWithPaths(1), 'UniformOutput', false);
                    MetaDataString=                             FirstMovie{1}.getRawMetaData;
                    
                    
                case {'lsm'} % do not store ;
                    
                    
                    [Summary, MetaDataString] =                                   obj.ActiveMovieController.LoadedMovie.getMetaDataSummary;

                    obj.Viewer.InfoView.List.String =                   Summary;
                    obj.Viewer.InfoView.List.Value =                    min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);

                
                    
                otherwise
                    MetaDataString =                                   obj.ActiveMovieController.LoadedMovie.getMetaDataSummary;
                
            end
            
            
          
            switch fileType

            case {'czi', 'tif', 'lsm'} 

                % store text in file:
                ExportFileName =                                   [obj.ActiveMovieController.LoadedMovie.NickName, '_MetaDataString.text'];
                cd(obj.MovieLibrary.PathForExport)
                [file,path] =                                       uiputfile(ExportFileName);
                CurrentTargetFilename =                             [path, file];
                datei =                                             fopen(CurrentTargetFilename, 'w');
                fprintf(datei, '%s', MetaDataString);


            end
            
            
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
        
        
           function [obj] =        exportMovie(obj,src,~)
            
            myMovieManager =                            PMImagerViewerMovieManager(obj.ActiveMovieController);

            myMovieManager.MovieAxes =                  obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
            myMovieManager.ExportFolder =               obj.MovieLibrary.PathForExport;
            
            
            %% create window for managing export settings
            myMovieManager =                            myMovieManager.MenuForMovieExportSettings;
            myMovieManager.PrefillExportName;
            
            
            
             myMovieManager =                           myMovieManager.resetExportWindowValues(myMovieManager.MovieController.Views);
             


             waitfor(myMovieManager.ExportWindowHandles.Wait, 'Value')
                UserWantToMakeMovie=                                    ishandle(myMovieManager.ExportWindowHandles.Wait);
                if ~UserWantToMakeMovie
                    return
                end
                
                
                 AdditionalName =                            myMovieManager.ExportWindowHandles.MovieName.String;
            
                 
                    
                 
                    
                    
             myMovieManager.ExportFileName =            [obj.MovieLibrary.SelectedNickname '_' AdditionalName '.mp4'];
           myMovieManager.StartFrame =   myMovieManager.ExportWindowHandles.Start.Value;
           myMovieManager.EndFrame =  myMovieManager.ExportWindowHandles.End.Value;
           myMovieManager.FramesPerMinute =  myMovieManager.ExportWindowHandles.fps.Value;
            
      
            close(myMovieManager.ExportWindowHandles.ExportMovieWindow)
        
            myMovieManager =                        myMovieManager.createMovieSequence;


            
            myMovieManager =                              myMovieManager.detectSaturatedFrames;
            myMovieManager =                        myMovieManager.removeSaturatedFrames;
            
            myMovieManager.writeMovieSequenceIntoFile;
            
            
        end
        
        function [obj] =        exportTrackCoordinates(obj,src,~)
            
            
           
            
            %% let user define target location for saving file; (a filename is suggested);
            FileName =                      [obj.ActiveMovieController.LoadedMovie.NickName, '.csv'];
            [file,path] =                   uiputfile(FileName);
            CurrentTargetFilename =         [path, file];
            
            NickNameFromMovieTracking =     obj.ActiveMovieController.LoadedMovie.NickName;
            
            %% retrieve Tracking Analysis of wanted movie;
            TrackingAnalysisCopy =              obj.ActiveMovieController.LoadedMovie.TrackingAnalysis;
            TrackingAnalysisCopy =              TrackingAnalysisCopy.convertDistanceUnitsIntoUm;
            TrackingAnalysisCopy =              TrackingAnalysisCopy.convertTimeUnitsIntoSeconds;
            
            
            TrackingAnalysisCopy.exportTracksIntoCSVFile(CurrentTargetFilename,NickNameFromMovieTracking)
            
          

        end
        
    
        
        %% response to tracking menu click:
        function [obj] = manageAutoCellRecognition(obj,src,~)
            
            myMovie = obj.ActiveMovieController.LoadedMovie;
            
            if isempty(myMovie)
               return
            else
                
                MyImageVolumes =                        obj.ActiveMovieController.LoadedImageVolumes;
                MyChannel =                                         find(obj.ActiveMovieController.LoadedMovie.SelectedChannels);
                obj.AutoCellRecognitionController =                 PMAutoCellRecognitionController(PMAutoCellRecognition(MyImageVolumes,MyChannel));

                obj.AutoCellRecognitionController =     obj.AutoCellRecognitionController.udpatePlaneSettingView;
                
            end
            
            
        end
        
        function [obj] = deleteTrackClicked(obj,src,~)
            
            obj.ActiveMovieController =                     obj.ActiveMovieController.deleteActiveTrack;
            [SelectedTrackIDs] =                            obj.ActiveMovieController.getCurrentlySelectedTrackIDs;
            
            
            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.setActiveTrackWith(SelectedTrackIDs(1));
            obj.ActiveMovieController =                  obj.ActiveMovieController.resetActiveTrack;
            obj.ActiveMovieController =                     obj.ActiveMovieController.updateViewsAfterTrackSelectionChange;

            
        end
        
        function [obj] = deleteAllTracksClicked(obj,src,~)
            

                    obj.ActiveMovieController =                 obj.ActiveMovieController.deleteAllTracks;
                    obj.ActiveMovieController =                obj.ActiveMovieController.updateViewsAfterTrackSelectionChange;
                    obj.ActiveMovieController =                obj.ActiveMovieController.updateImageAndTrackViews;

                
        end
        
        function [obj] =            deleteTracksLessThan(obj,src,~)
            
            
            answer = inputdlg('Enter number frames. Tracks with equal of fewer frames will be delted');
            
            MyNumber =      str2double(answer{1});
            
            if ~isnan(MyNumber)
                obj.ActiveMovieController.LoadedMovie.Tracking =      obj.ActiveMovieController.LoadedMovie.Tracking.removeTrackWithFramesLessThan(MyNumber);
                
                
                obj.ActiveMovieController.LoadedMovie =                 obj.ActiveMovieController.LoadedMovie.refreshTrackingResults;
                obj =                                                obj.ActiveMovieController.updateViewsAfterChangesInTracks;
                
                
                
            else
                
                    FrameGap=               2;
                    DistanceLimitXY=        10;
                    DistanceLimitZ=         0;
                
                    %obj.ActiveMovieController.LoadedMovie.Tracking  =                obj.ActiveMovieController.LoadedMovie.Tracking.mergeDisconnectedTracks(FrameGap,DistanceLimitXY,DistanceLimitZ);
                
                    NumberOfFramesOverlapAllowed =  2;
                    obj.ActiveMovieController.LoadedMovie.Tracking =                      obj.ActiveMovieController.LoadedMovie.Tracking.mergOverlappingTracks(NumberOfFramesOverlapAllowed,DistanceLimitXY, DistanceLimitZ);
                
            end
            
        end
        
        
         function [obj] = mergeSelectedTracks(obj,src,~)
             obj.ActiveMovieController =         obj.ActiveMovieController.mergeSelectedTracks;
              obj.ActiveMovieController =                                                       obj.ActiveMovieController.updateTrackListView;
                obj.ActiveMovieController =                                                       obj.ActiveMovieController.updateTrackView;

         end
         
          function [obj] = splitSelectedTracks(obj,src,~)
             
             obj.ActiveMovieController =                obj.ActiveMovieController.splitSelectedTracks;
             obj.ActiveMovieController =                obj.ActiveMovieController.updateTrackListView;
             obj.ActiveMovieController =                obj.ActiveMovieController.updateTrackView;

         end
         
         
         
        
        
                 
        
         function [obj] = updateTracksClicked(obj,src,~)
             
                obj.ActiveMovieController.LoadedMovie =           obj.ActiveMovieController.LoadedMovie.refreshTrackingResults;
                obj.ActiveMovieController =                       obj.ActiveMovieController.updateTrackList;
                obj.ActiveMovieController =                       obj.ActiveMovieController.updateTrackView;

            
         end
        
        function [obj] = deleteMaskClicked(obj,src,~)
            
            
            obj.ActiveMovieController =         obj.ActiveMovieController.deleteActiveMask;
            obj.ActiveMovieController =           obj.ActiveMovieController.updateImageAndTrackViews;
              
            
        end
        
               
         %% response to view action in navigation and channel area:
        
        function [obj] =            sliderActivity(obj,src,~)
            
            disp(['Value = ', num2str(obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Value)]);
            obj.ActiveMovieController = obj.ActiveMovieController.resetFrame(round(obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Value));
            
        end
        

        function [obj] =           editingOptionsClicked(obj,src,~)
            
            
            SelectedString =                        obj.Viewer.MovieControllerViews.Navigation.EditingOptions.String{obj.Viewer.MovieControllerViews.Navigation.EditingOptions.Value};
            
            obj.ActiveMovieController.LoadedMovie    =          obj.ActiveMovieController.LoadedMovie.resetEditingActivityTo(SelectedString);
            obj.ActiveMovieController    =          obj.ActiveMovieController.setViewsForCurrentEditingActivity;
         
            
             
        end
        
          function [obj] =           planeViewClicked(obj,src,~)
            newPlane =                                      obj.ActiveMovieController.Views.Navigation.CurrentPlane.Value;

            obj.ActiveMovieController  =                    obj.ActiveMovieController.resetPlane(newPlane);
            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.resetViewPlanes;
             obj.ActiveMovieController =                                                obj.ActiveMovieController.updateImageView;  
                 obj.ActiveMovieController =                                                obj.ActiveMovieController.updateImageHelperViews;

         end
         
          function [obj] =           frameViewClicked(obj,src,~)
             newFrame =                                     obj.ActiveMovieController.Views.Navigation.CurrentTimePoint.Value;
             [obj]  =                                       obj.ActiveMovieController.resetFrame(newFrame);
             
          end
         
          function [obj] =          maximumProjectionClicked(obj,src,~)
              obj.ActiveMovieController.LoadedMovie.CollapseAllPlanes =     obj.ActiveMovieController.Views.Navigation.ShowMaxVolume.Value;
              obj.ActiveMovieController.LoadedMovie =                       obj.ActiveMovieController.LoadedMovie.resetViewPlanes;
              obj.ActiveMovieController =                                   obj.ActiveMovieController.updateImageView;
  
          end
          
          
          function [obj] =           croppingOnOffClicked(obj,src,~)
              
                NewCroppingState =              obj.ActiveMovieController.Views.Navigation.CropImageHandle.Value;
                obj.ActiveMovieController.LoadedMovie =               obj.ActiveMovieController.LoadedMovie.setCroppingStateTo(NewCroppingState);
                obj.ActiveMovieController =                           obj.ActiveMovieController.resetViewsForCurrentCroppingState;

              
          end
          
          
           function [obj] =          driftCorrectionOnOffClicked(obj,src,~)
               
               OnOrOffValue =                   obj.Viewer.MovieControllerViews.Navigation.ApplyDriftCorrection.Value;
               obj.ActiveMovieController =      obj.ActiveMovieController.setDriftCorrectionTo(OnOrOffValue);
                    
           end
          
          
  
          function [obj] =           channelViewClicked(obj,src,~)
              
             Value =            obj.ActiveMovieController.Views.Channels.SelectedChannel.Value;
             [obj]  =           obj.ActiveMovieController.resetChannelSettings(Value, 'SelectedChannelForEditing');
            
          end
         
         
          function [obj] =           channelLowIntensityClicked(obj,src,~)
             
             Value =                str2double(obj.ActiveMovieController.Views.Channels.MinimumIntensity.String);
             [obj]  =               obj.ActiveMovieController.resetChannelSettings(Value, 'ChannelTransformsLowIn');
             
            
         end
         
          function [obj] =           channelHighIntensityClicked(obj,src,~)
              
             Value =             str2double(obj.ActiveMovieController.Views.Channels.MaximumIntensity.String);
             [obj]  =               obj.ActiveMovieController.resetChannelSettings(Value, 'ChannelTransformsHighIn');
             
             
            
             
         end
         
          function [obj] =          channelColorClicked(obj,src,~)
              
              Value =               obj.ActiveMovieController.Views.Channels.Color.String{obj.ActiveMovieController.Views.Channels.Color.Value};
              [obj]  =               obj.ActiveMovieController.resetChannelSettings(Value, 'ChannelColors');
              
           
             
             
          end
          
          function [obj] =          channelCommentClicked(obj,src,~)
              
              Value =                                                                          obj.ActiveMovieController.Views.Channels.Comment.String;
              [obj]  =               obj.ActiveMovieController.resetChannelSettings(Value, 'ChannelColors');
              
              
             
             
          end
          
          function [obj] =          channelOnOffClicked(obj,src,~)
              
                Value =          logical(obj.ActiveMovieController.Views.Channels.OnOff.Value);
                [obj]  =               obj.ActiveMovieController.resetChannelSettings(Value, 'SelectedChannels');
             
                 
          end
          
          
          function [obj] =              channelReconstructionClicked(obj,src,~)
              
                Value =          obj.ActiveMovieController.Views.Channels.ChannelReconstruction.Value;
                [obj]  =               obj.ActiveMovieController.resetChannelSettings(Value, 'ChannelReconstruction');
             
              
          end
          
          
          % annotation:
          
       
          function [obj] =         annotationScaleBarOnOffClicked(obj,src,~)
              
              obj.ActiveMovieController.LoadedMovie.ScaleBarVisible =       obj.ActiveMovieController.Views.Annotation.ShowScaleBar.Value;
              
              obj.ActiveMovieController =                                   obj.ActiveMovieController.updateAnnotationViews;  
             
              
              
          end
          
          function [obj] =         annotationScaleBarSizeClicked(obj,src,~)
              
              
              obj.ActiveMovieController.LoadedMovie.ScaleBarSize =                          obj.ActiveMovieController.Views.Annotation.SizeOfScaleBar.Value;
              obj.ActiveMovieController.LoadedMovie =                                       obj.ActiveMovieController.LoadedMovie.updateScaleBarString;
              
              obj.ActiveMovieController.Views.MovieView.ScalebarText.String =              obj.ActiveMovieController.LoadedMovie.ScalebarStamp;
              
              obj.ActiveMovieController =                                                   obj.ActiveMovieController.updateAnnotationViews;  
              
          end
         
          
         %% respond to tracking view click:

          function [obj] =       trackingActiveTrackButtonClicked(obj,src,~)
                  
              
       
              obj.ActiveMovieController.LoadedMovie.ActiveTrackIsHighlighted = obj.ActiveMovieController.TrackingViews.ActiveTrackTitle.Value;
              
              obj.ActiveMovieController =       obj.ActiveMovieController.updateHighlightingOfActiveTrack;
              obj.ActiveMovieController =       obj.ActiveMovieController.updateImageView;
              
              
          end
          
          function [obj] =      trackingCentroidButtonClicked(obj,src,~)
              
              obj.ActiveMovieController.LoadedMovie.CentroidsAreVisible =       obj.ActiveMovieController.TrackingViews.ShowCentroids.Value;
              obj.ActiveMovieController =                                       obj.ActiveMovieController.updateCentroidVisibility;
              

                %  =           0;
                %TracksAreVisible =          0;

                % obj.ActiveMovieController.MasksAreVisible
                %     obj.ActiveMovieController.TracksAreVisible


                %         obj.ActiveMovieController.TrackingViews.TrackingTitle
                %         obj.ActiveMovieController.TrackingViews.ActiveTrackTitle

                %         obj.ActiveMovieController.TrackingViews.ShowTracks
                %         obj.ActiveMovieController.TrackingViews.ShowMaximumProjection
                %         obj.ActiveMovieController.TrackingViews.ActiveTrack
                %         obj.ActiveMovieController.TrackingViews.ListWithFilteredTracksTitle
                %         obj.ActiveMovieController.TrackingViews.ListWithFilteredTracks

          end

          
          function [obj] =      trackingShowMaskButtonClicked(obj,src,~)
              
              obj.ActiveMovieController.LoadedMovie.MasksAreVisible =               obj.ActiveMovieController.TrackingViews.ShowMasks.Value;
              
              obj.ActiveMovieController =                                           obj.ActiveMovieController.updateMaskVisibility;
              
            
             
          end


          function [obj] =      trackingShowTracksButtonClicked(obj,src,~)
              
              
              obj.ActiveMovieController.LoadedMovie.TracksAreVisible =      obj.ActiveMovieController.TrackingViews.ShowTracks.Value;
              obj.ActiveMovieController =                                   obj.ActiveMovieController.updateTrackVisibility;
                
              
          end
          

          function [obj] =      trackingShowMaximumProjectionButtonClicked(obj,src,~)
              
              
              
              obj.ActiveMovieController = obj.ActiveMovieController.resetPlaneTrackingByMenu;
              

              
              
          end
          
          
          function [obj] =      trackingTrackListClicked(obj,src,~)

              obj.ActiveMovieController =                           obj.ActiveMovieController.changActiveTrackByTableView;

              
          end
          
    
          %% change model and view:
       
          function [obj] =        manageResettingOfLibrary(obj)
              
                %% load file
                
                fprintf('\nEnter PMMovieLibraryManager:@manageResettingOfLibrary:\n')
                 
                obj.MovieLibrary =                                      PMMovieLibrary(obj.FileNameForLoadingNewObject);
                obj.MovieLibrary =                                      obj.MovieLibrary.sortByNickName;
                obj.ActiveMovieController       =                       PMMovieController(obj.Viewer);  

                obj.Viewer.MovieControllerViews.blackOutMovieView;

                obj =                                                   obj.updateView;
                obj =                                                   obj.updateInfoView;
                
                fprintf('\nExit PMMovieLibraryManager:@manageResettingOfLibrary.\n\n')
                
          end
          


          function [obj ] =       resetActiveMovieControllerWithActiveNickName(obj,src,~)
            
              
                fprintf('PMMovieLibraryManager:@resetActiveMovieControllerWithActiveNickName: ')

                obj.ActiveMovieController       =                                           PMMovieController(obj.Viewer);  
                
                %% if no movies exist or are not specified, just black out all the movie views and leave;
                if isempty(obj.MovieLibrary.ListhWithMovieObjects) || isempty(obj.MovieLibrary.SelectedNickname)
                    
                    
                    
                    fprintf('ListhWithMovieObjects or no SelectedNickname specified: Black out views and return.\n')
                    obj.Viewer.MovieControllerViews.blackOutMovieView;
                    return
                    
                end


                %% get data of selected movie from memory and if necessary from file;
                SelectedRow =                                                           obj.MovieLibrary.getSelectedRowInLibrary;
                LoadedMovie =                                                           obj.MovieLibrary.ListhWithMovieObjects{SelectedRow,1};
                LoadedImageVolumesFromMemory =                                          obj.MovieLibrary.ListWithLoadedImageData{SelectedRow,1};

                if isempty(LoadedMovie)
                    LoadedMovie =                                                       obj.MovieLibrary.getActiveMovieTrackingFromFile;
                end
                
                if isempty(LoadedMovie.AttachedFiles)
                    error('No filenames attached to this nickname. This needs to be fixed!')
                    
                end
                
                
                %% create a new movie controller and update with data of selected nickname:
                

                obj.Viewer.MovieControllerViews.blackOutMovieView;

                obj.ActiveMovieController.LoadedMovie =                                     LoadedMovie;  
                obj.ActiveMovieController.LoadedImageVolumes =                              LoadedImageVolumesFromMemory;  
                obj.ActiveMovieController.LoadedMovie.Folder =                              obj.MovieLibrary.PathOfMovieFolder; 
                
                     
                 
                
                %% if everything was ok: upload all the views with the newly loaded data:
                obj.ActiveMovieController =                                                 obj.ActiveMovieController.finalizeMovieController;
                
                if isempty(obj.ActiveMovieController.LoadedMovie.ImageMapPerFile)
                     
                     fprintf('No image map available: Black out views and return.\n')
                    obj.Viewer.MovieControllerViews.blackOutMovieView;
                    return
                    
                 end
                
                
               
                
                
                obj.ActiveMovieController =                                                 obj.ActiveMovieController.resetDriftDependentParameters;

                obj.ActiveMovieController =                                                 obj.ActiveMovieController.updateChannelSettingView; % changes the display of settings of selected channel;
                obj.ActiveMovieController =                                                 obj.ActiveMovieController.updateAllTrackingViews;


          end


          
         %% change view:
        function [obj] =            updateView(obj,src, ~)
                %PROJEC Summary of this function goes here
                %   Detailed explanation goes here


                fprintf('\nPMMovieLibraryManager:@updateView: \n')
                
                
                %% inactivate the controller views if nothing is selected: (maybe this should be at a different location)
                if isempty(obj.MovieLibrary.ListWithMovieObjectSummary) || isempty(obj.MovieLibrary.SelectedNickname)
                    fprintf('No movie objects available or no movie selected. Therefore disable views.\n')
                    obj.ActiveMovieController.disableAllViews;
                end
                
                fprintf('Update nickname view.\n')
                obj.Viewer.ProjectViews.SelectedNickname.String =                   obj.MovieLibrary.SelectedNickname;
               
                
               
                ProjectWindowHandles =                                              obj.Viewer.ProjectViews;
                
                
    
                %% general filter
                fprintf('Update view for image type filter.\n')
                
                ProjectWindowHandles.FilterForKeywords.Enable=                      'on';
                ProjectWindowHandles.FilterForKeywords.String=                      [obj.ProjectFilterList];
                

               ProjectWindowHandles.FilterForKeywords.Value =                       obj.MovieLibrary.FilterSelectionIndex;
               if ProjectWindowHandles.FilterForKeywords.Value == 0
                   ProjectWindowHandles.FilterForKeywords.Value = 1;
               end
               
               if min(ProjectWindowHandles.FilterForKeywords.Value)> length(ProjectWindowHandles.FilterForKeywords.String)
                   ProjectWindowHandles.FilterForKeywords.Value = length(ProjectWindowHandles.FilterForKeywords.String);
               end
                
               
               
               %% keyword filter:
               fprintf('Update view for keyword-filter.\n')
               
                ListWithKeywordStrings =                                            obj.MovieLibrary.getKeyWordList;
                
                if iscell(ListWithKeywordStrings)
                    KeywordList=                                                ['Ignore keywords'; 'Movies with no keyword'; ListWithKeywordStrings];
                else
                    KeywordList =                                                   {'Ignore keywords'; 'Movies with no keyword'; ListWithKeywordStrings};
                    
                end
                
                
                
                KeywordList(cellfun(@(x) isempty(x), KeywordList), :) = [];
                
                ProjectWindowHandles.RealFilterForKeywords.String =            KeywordList;    
            
                   
               if ProjectWindowHandles.RealFilterForKeywords.Value == 0
                   ProjectWindowHandles.RealFilterForKeywords.Value = 1;
               end
               
               if min(ProjectWindowHandles.RealFilterForKeywords.Value)> length(ProjectWindowHandles.RealFilterForKeywords.String)
                   ProjectWindowHandles.RealFilterForKeywords.Value = length(ProjectWindowHandles.RealFilterForKeywords.String);
               end
                
                
                
                
                
                %% show nicknames of all selected movies:
                
                fprintf('Update view for shown movies.\n')
                
                ListWithSelectedNickNames =                                             obj.MovieLibrary.ListWithFilteredNicknames;

                if ~isempty(ListWithSelectedNickNames)

                    if obj.MovieLibrary.SortIndex == 1 % currently always sorted by nickanme
                        ListWithSelectedNickNames =                                     sort(ListWithSelectedNickNames);
                        

                    end
                    
                    ProjectWindowHandles.ListOfMoviesInProject.String=                  ListWithSelectedNickNames;
                    ProjectWindowHandles.ListOfMoviesInProject.Value=                    min([length(ListWithSelectedNickNames)    ProjectWindowHandles.ListOfMoviesInProject.Value]);
                    ProjectWindowHandles.ListOfMoviesInProject.Enable=                  'on';

                else

                    ProjectWindowHandles.ListOfMoviesInProject.String=                  'No movies selected';
                    ProjectWindowHandles.ListOfMoviesInProject.Value=                   1;
                    ProjectWindowHandles.ListOfMoviesInProject.Enable=                  'off';


                end

       
        end
        
        

        function [obj]=             updateInfoView(obj)
            
            fprintf('Enter PMMovieLibraryManager:@updateInfoView:\n')

             switch obj.ActiveInfoType

                    case 'Project'

                        % currently not toggling:
                        FileNameOfProject{1,1}=             'Filename of current project:';
                        FileNameOfProject{2,1}=             obj.MovieLibrary.FileName;
                        FileNameOfProject{3,1}=             '';

                        FolderWithMovieFiles{1,1}=          'Folder with movie files:';
                        FolderWithMovieFiles{2,1}=          obj.MovieLibrary.PathOfMovieFolder;
                        FolderWithMovieFiles{3,1}=          '';

                        PathForDataExport{1,1}=             'Folder for data export:';
                        PathForDataExport{2,1}=             obj.MovieLibrary.PathForExport;
                        PathForDataExport{3,1}=             '';
                        
                    
                    
                        AnnotationFolder{1,1}=             'Annotation folder:';
                        AnnotationFolder{2,1}=             obj.MovieLibrary.getMainFolder;
                    AnnotationFolder{3,1}=             '';
                          
                        
                        InfoText=                               [FileNameOfProject;FolderWithMovieFiles; PathForDataExport;AnnotationFolder];

            
                    case 'Attached files'

                     
                     
                       if ~obj.verifyActiveMovieStatus
                         InfoText = {'No movie loaded'};
                         
                       else
                          
                            
                            NamesOfAttachedFileNames=                       obj.ActiveMovieController.LoadedMovie.AttachedFiles;

                            Keywords =                                      obj.ActiveMovieController.LoadedMovie.Keywords;

                            %% extract relevant information out of movie-info:
                            
                            if isempty(obj.ActiveMovieController.LoadedMovie.Tracking) || isempty(obj.ActiveMovieController.LoadedMovie.Tracking.Tracking)
                                
                                    TrackingText=                           'Tracking was not performed';
                                
                            else
                                
                                    NumberOfTracks = obj.ActiveMovieController.LoadedMovie.Tracking.NumberOfTracks;
                                    
                                    switch NumberOfTracks

                                        case 0
                                            TrackingText=                           'Tracking was not performed';


                                        case 1
                                             TrackingText=                           sprintf('%i track generated',      NumberOfTracks);  
                                             
                                        otherwise
                                            TrackingText=                           sprintf('%i tracks generated',      NumberOfTracks);  
                                            

                                    end

                                
                            
                            end
                            
                            
                            
                         if isempty(obj.ActiveMovieController.LoadedMovie.DriftCorrection)
                             DriftCorrectionWasPerformed = false;
                         else
                             DriftCorrectionWasPerformed=                   obj.ActiveMovieController.LoadedMovie.DriftCorrection.testForExistenceOfDriftCorrection;
                         end


                            
                            switch DriftCorrectionWasPerformed

                            case 1
                                DriftCorrectionText=            'Drift correction was performed';

                            otherwise
                                DriftCorrectionText=            'No drift correction';

                            end


                            %% put together wanted information from :
                            FileText=                                       [{'Attached files'}; NamesOfAttachedFileNames];


                            SummaryText{1,1}=                               DriftCorrectionText;
                            SummaryText{2,1}=                               TrackingText;

                            InfoText= [FileText; SummaryText; 'Keywords:'; Keywords];



                           
                       end
                     
                    
                         
                     
                      


                 case 'MetaData'
                     
                      if ~obj.verifyActiveMovieStatus
                         InfoText = {'No movie loaded'};
                         
                      else
                          
                         ShortFileName=                                     obj.ActiveMovieController.LoadedMovie.AttachedFiles;
                        [ MetaDataOfSeparateMovies ] =                      obj.ActiveMovieController.LoadedMovie.MetaDataOfSeparateMovies;

                        namesOfFields=                                      cellfun(@(x) fieldnames(x.EntireMovie), MetaDataOfSeparateMovies, 'UniformOutput', false);
                        contentsofFields=                                   cellfun(@(x) struct2cell(x.EntireMovie), MetaDataOfSeparateMovies, 'UniformOutput', false);
                        contentsofFields{1}{6} =                            contentsofFields{1}{6}*1e6;
                        contentsofFields{1}{7} =                            contentsofFields{1}{7}*1e6;
                        contentsofFields{1}{8} =                            contentsofFields{1}{8}*1e6;
                        
                        
                        numberOfMovies =                                    size(namesOfFields,1);
                        for movieIndex = 1:numberOfMovies
                            
                            InfoText{movieIndex,1}=                         cellfun(@(x,y) [x ':    ' num2str(y)], namesOfFields{movieIndex}(1:5,:), contentsofFields{movieIndex}(1:5,:), 'UniformOutput', false);
                            InfoText{movieIndex,1}=                         [['Filename: ', ShortFileName{movieIndex}];   InfoText{movieIndex,1}];

                              MoreInfoText =       [namesOfFields{movieIndex}(6:8,:), contentsofFields{movieIndex}(6:8,:)];
                            MoreInfoTextFormat =     cellfun(@(x,y) sprintf('%s: %6.2f µm', x,y),  MoreInfoText(:,1), MoreInfoText(:,2), 'UniformOutput', false);
                            
                            InfoText{movieIndex,1} = [InfoText{movieIndex,1};  MoreInfoTextFormat; ' '];
                            
                            
                        end
                        InfoText =                                          vertcat(InfoText{:});
                        
                        
                      
                        
                        
                        
                        
   
   
                      end


                otherwise

                        InfoText =             {'Info could not be retrieved.'};


            end
              
             
             obj.Viewer.InfoView.List.String =               InfoText;
             obj.Viewer.InfoView.List.Value =            min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);
            
             
             if obj.Viewer.InfoView.List.Value == 0
                obj.Viewer.InfoView.List.Value = 1; 
             end
             
             fprintf('Exit PMMovieLibraryManager:@updateInfoView.\n\n')
        end

          
    
          %% file management
          
          function updatePreviouslyLoadedFileInfo(obj)
              
               %% store specified path in "previous settings" file:
               fprintf('PMMovieLibraryManager:@updatePreviouslyLoadedFileInfo. During next start program will try to open file "%s".\n',  obj.MovieLibrary.FileName)
                FileNameOfProject=                              obj.MovieLibrary.FileName;
                save(obj.FileWithPreviousSettings, 'FileNameOfProject')

          end
           
          
          
          function [obj]= manageTransferOfActiveMovieToNickName(obj,NickName)
              
              
                    obj =                                                                          obj.saveAndSynchronizeActiveMovie;
                     obj =                                                                          obj.resetActiveNickNameWith(NickName);
                    obj =                                                                           obj.resetActiveMovieControllerWithActiveNickName;
       
                    obj.ActiveMovieController =                                                     obj.ActiveMovieController.updateSaveStatusView;
                    obj =                                                                           obj.updateInfoView;
          end
          
          
          function [obj] = manageSavingOfLibrary(obj)

            fprintf('\nEnter PMMovieLibraryManager:@manageSavingOfLibrary:\n')
            
            obj =                                                               obj.saveAndSynchronizeActiveMovie;
            obj.MovieLibrary =                                                  obj.MovieLibrary.saveMovieLibraryToFile;
            obj.ActiveMovieController =                                         obj.ActiveMovieController.updateSaveStatusView;

            fprintf('\nExit PMMovieLibraryManager:@manageSavingOfLibrary.\n')    
                      

          end
          
          function [obj] = saveAndSynchronizeActiveMovie(obj)
                    
            fprintf('\nPMMovieLibraryManager:@saveAndSynchronizeActiveMovie.\n\n')

            if ~isempty(obj.ActiveMovieController.LoadedMovie)  && strcmp(class(obj.ActiveMovieController.LoadedMovie), 'PMMovieTracking')
                [obj.ActiveMovieController.LoadedMovie] =                               obj.ActiveMovieController.LoadedMovie.setFolderAnnotation(obj.MovieLibrary.getMainFolder);
                obj.ActiveMovieController.LoadedMovie =                                 obj.ActiveMovieController.LoadedMovie.saveMovieDataWithOutCondition;
                obj.MovieLibrary =                                                      obj.MovieLibrary.synchronizeMovieLibraryWithActiveMovie(obj.ActiveMovieController);
            else
                fprintf('No valid LoadedMovie available: therefore no action taken.\n')
            end
              
          end

  
    end
end

