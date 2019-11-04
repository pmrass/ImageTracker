classdef PMMovieLibraryManager < handle
    %PMMOVIELIBRARYMANAGER manages selection and viewing multiple included movies;
    %   Detailed explanation goes here
    
    properties


        Viewer
        TagOfHandleOfInfoFigure =                   'PMMovieLibraryManager_InfoWindow';
        ActiveInfoType =                            'Project';
        
        MainProjectFolder =                         userpath; %not in use right now
        
        FileWithPreviousSettings =                  [userpath,'/imans_PreviouslyUsedFile.mat'];
        FileNameForLoadingNewObject =               '' % use this only for loading the new file; the movie-library will "save itself" with the filename it has in one its properties
        
        MovieLibrary
        
        ActiveMovieController
        ListWithLoadedImageData =                   cell(0,1);
        
        ProjectFilterList =                         {'Show all movies'; 'Show all Z-stacks'; 'Show all snapshots'; 'Show all movies with drift correction'; 'Show all tracked movies'; 'Show all untracked movies'; 'Show entire content'; 'Show content with non-matching channel information'; 'Show all unmapped movies'};
        
        EditingActivity =                           'No editing';
        MouseAction =                               'No action';
   

    end
    
    
    methods
        
        function obj =          PMMovieLibraryManager
           
            %PMMOVIELIBRARYMANAGER Construct an instance of this class
            %   Detailed explanation goes here


            %% update project with previous file:
            obj.Viewer =                                                                        PMImagingProjectViewer;
            obj =                                                                               obj.setPreviouslyUsedFileName;
            
            
            obj =                                                                               obj.resetActiveMovieController;

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
            obj =                                                                       obj.loadLibraryAndUpdateViews;

 

            
                
        end
        
        
        function [obj]=         resetActiveMovieController(obj)
            
            
                
            obj.ActiveMovieController       =                                                   PMMovieController();  
            obj.ActiveMovieController.Views =                                                   obj.Viewer.MovieControllerViews;
            obj.ActiveMovieController.Views.Figure =                                            obj.Viewer.Figure;   
            obj.ActiveMovieController.Views.MovieView.ManualDriftCorrectionLine.Visible =       'off';
            obj.ActiveMovieController.TrackingViews =                                           obj.Viewer.TrackingViews.ControlPanels;
            obj.ActiveMovieController.changeAppearance;
            
            
            obj.ActiveMovieController.disableAllViews;
            obj.Viewer.MovieControllerViews.blackOutMovieView;
            obj.ActiveMovieController =                                                         obj.ActiveMovieController.deleteAllTrackLineViews;

            
            
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
            
            obj.Viewer.ProjectMenu.Mapping.MenuSelectedFcn=                             @obj.mapUnMappedMovies;
            obj.Viewer.ProjectMenu.UnMapping.MenuSelectedFcn=                             @obj.unmapAllMovies;
            
            
            
            obj.Viewer.ProjectMenu.Info.MenuSelectedFcn =                               @obj.toggleProjectInfo;

            
            % help menu:
             obj.Viewer.HelpMenu.KeyboardShortcuts.MenuSelectedFcn  =                   @obj.showKeyboardShortcuts;

            
            %% other views
            obj.Viewer.ProjectViews.FilterForKeywords.Callback =                        @obj.callbackForFilterChange;
            obj.Viewer.ProjectViews.SortMovies.Callback =                               @obj.updateView;
            obj.Viewer.ProjectViews.ListOfMoviesInProject.Callback =                    @obj.movieListClicked;
            
            
            
          
            
            
            
        end
        
        
        function [obj] =       addCallbacksToMovieObject(obj)
            
            
             % movie menu:
            obj.Viewer.MovieControllerViews.Menu.Keyword.MenuSelectedFcn =                                              @obj.changeKeywordClicked;
            obj.Viewer.MovieControllerViews.Menu.ReapplySourceFiles.MenuSelectedFcn =                                   @obj.reapplySourceFilesClicked;
            obj.Viewer.MovieControllerViews.Menu.DeleteImageCache.MenuSelectedFcn =                                     @obj.deleteImageCacheClicked;
            
            obj.Viewer.MovieControllerViews.Menu.ApplyManualDriftCorrection.MenuSelectedFcn =                           @obj.applyManualDriftCorrectionClicked;
            %obj.Viewer.MovieControllerViews.Menu.CompleteManualDriftCorrection.MenuSelectedFcn =                        @obj.completeManualDriftCorrectionClicked;
            obj.Viewer.MovieControllerViews.Menu.EraseAllDriftCorrections.MenuSelectedFcn =                             @obj.eraseAllDriftCorrectionsClicked;
            
            
            
            obj.Viewer.MovieControllerViews.Menu.ShowMetaData.MenuSelectedFcn =                 @obj.showMetaDataInfoClicked;
            obj.Viewer.MovieControllerViews.Menu.ShowAttachedFiles.MenuSelectedFcn =            @obj.showAttachedFilesClicked;
            obj.Viewer.MovieControllerViews.Menu.ExportMovie.MenuSelectedFcn =                  @obj.exportMovie;
            
            
               obj.Viewer.MovieControllerViews.Menu.ExportTrackCoordinates.MenuSelectedFcn =                   @obj.exportTrackCoordinates;
              
            
            
            
            
            
        end

        
        function [obj] =        exportMovie(obj,src,~)
            
            myMovieManager =                        PMImagerViewerMovieManager(obj.ActiveMovieController);

            myMovieManager.MovieAxes =              obj.ActiveMovieController.Views.MovieView.ViewMovieAxes;
            myMovieManager.ExportFolder =           obj.MovieLibrary.PathForExport;
            myMovieManager.ExportFileName =         [obj.MovieLibrary.SelectedNickname '.mp4'];
            
            
            myMovieManager =                        myMovieManager.createMovieSequence;
            myMovieManager.writeMovieSequenceIntoFile;
            
            
        end
        
        function [obj] = exportTrackCoordinates(obj,src,~)
            
            TrackingAnalysisCopy =   obj.ActiveMovieController.LoadedMovie.TrackingAnalysis;
            
            
            TrackingAnalysisCopy =      TrackingAnalysisCopy.convertDistanceUnitsIntoUm;
            
            TrackingAnalysisCopy =      TrackingAnalysisCopy.convertTimeUnitsIntoSeconds;
            
            
        
            FileName = [obj.ActiveMovieController.LoadedMovie.NickName, '.csv'];
            
            [file,path] = uiputfile(FileName);
            
            if file == 0
                return
            end
            
            CurrentTargetFilename = [path, file];
            
            
            
            
            datei =                     fopen(CurrentTargetFilename, 'w');

            fprintf(datei, '%s\n', 'Filename');
            fprintf(datei, '%s\n', obj.ActiveMovieController.LoadedMovie.NickName);

            TotalNumberOfRows=          size(TrackingAnalysisCopy.ListWithCompleteMaskInformationWithDrift,1);     
            for CurrentRow=1:TotalNumberOfRows
                
                dataInRow =    TrackingAnalysisCopy.ListWithCompleteMaskInformationWithDrift(CurrentRow,:); 
                
                fprintf(datei, '%12.0f,%10.5f,%10.5f,%10.5f,%14.5f \n', dataInRow{1}, dataInRow{3}, dataInRow{4}, dataInRow{5}, dataInRow{2} );
            end
           
            fclose(datei);

        end
        
        
        
        
        
        function [obj] =        addCallbacksToNavigationAndTracking(obj)
            
            
            % tracking menu:
            obj.Viewer.TrackingViews.Menu.DeleteTrack.MenuSelectedFcn =                         @obj.deleteTrackClicked;
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
        
        
        
        %% respond to file menu-click:
        
        function [obj] =    newProjectClicked(obj,src,~)

                
                %% first save the old project (before replacing it with the new one
                [obj] =                                         obj.saveProjectToFile; % first save the old project to file so that changes are not lost (make sure that the new project is not loaded in the meantime so that the old project will be overwritten;
            
    
                %% create an empty project and clear up previous views:
                obj.FileNameForLoadingNewObject =               ''; % make file-name empty: this means that an "empty" new project will be created (rather then loaded from file);
                obj.ActiveInfoType =                            'Project';
                obj =                                           obj.loadLibraryAndUpdateViews;

                
                %% let the user select the file path: future changes of this project will be saved there (also save it right now so that the project is on file);
               [FileName,SelectedPath] =                           uiputfile;
                if SelectedPath== 0
                    return
                end
                
                %% store the new name in the movie-library and update filename for loading next time from the start;
                obj.MovieLibrary.FileName =                     [SelectedPath, FileName];
                obj.updatePreviouslyLoadedFileInfo;
                obj=                                            obj.updateInfoView;
                [obj] =                                         obj.saveProjectToFile;
                

        end
        
        function [obj] =    loadProjectClicked(obj,src,~)
            
              %% let the user select the file path:;
               [FileName,SelectedPath] =                           uigetfile('.mat', 'Load existing project');
                if SelectedPath== 0
                    return
                end
                
                
                %% then use that filename to load this project and update the views:
                obj.FileNameForLoadingNewObject =               [SelectedPath, FileName];
               
                
                obj.ActiveInfoType =                            'Project';
                obj =                                           obj.loadLibraryAndUpdateViews;
                 obj.MovieLibrary.FileName =                     [SelectedPath, FileName];
                 
                 obj=                                            obj.updateInfoView;
              
                
                %% after loading the file: store the path of this file for future load at the beginning;
                obj.updatePreviouslyLoadedFileInfo;

              
                
            

        end
        
        function [obj] =    saveProjectClicked(obj,src,~)
            
            [obj] = obj.saveProjectToFile;
            
        end
        
        
        
        %% response to project menu-click:
        
        function [obj] =        changeMovieFolderClicked(obj,src,~)
            
             
                [NewPath]=                             uipickfiles('FilterSpec', obj.MainProjectFolder, 'Prompt', 'Select movie folder',...
                'NumFiles', 1, 'Output', 'char');
                if isempty(NewPath) || ~ischar(NewPath)
                    return
                end

    
                obj.MovieLibrary.PathOfMovieFolder =            NewPath;
                obj.MovieLibrary =                              obj.MovieLibrary.resetFolders(NewPath);
                
                if ~isempty(obj.ActiveMovieController.LoadedMovie)
                    obj.ActiveMovieController.LoadedMovie.Folder = NewPath;
                end
                
                 obj =                                          obj.updateInfoView;
                
        
            
            
        end
        
        function [obj] =        changeExportFolderClicked(obj,src,~)
            
            
            [NewPath]=                             uipickfiles('FilterSpec', obj.MainProjectFolder, 'Prompt', 'Select export folder',...
                'NumFiles', 1, 'Output', 'char');
                if isempty(NewPath) || ~ischar(NewPath)
                    return
                end

            
            
            obj.MovieLibrary.PathForExport = NewPath;
            
             obj =   obj.updateInfoView;
            
            
        end
        
        function [obj] =        addMovieClicked(obj,src,~)
            
            
            %% let the user choose movie-file/s from the movie-folder;
            if exist(obj.MovieLibrary.PathOfMovieFolder) ~= 7
                msgbox('You must first choose a valid movie-folder', 'Adding movie/image to project')
                return
            end
            
            cd(obj.MovieLibrary.PathOfMovieFolder);
            
            ListWithFileNamesToAdd=                                                                 uipickfiles;
            if ~iscell(ListWithFileNamesToAdd)
                return
            end
            
            [~, file, ext]  =            cellfun(@(x) fileparts(x), ListWithFileNamesToAdd, 'UniformOutput', false);

            
            ListWithFileNamesToAdd =        cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false);

             %% let user selected nickname for current movie:
             NewUniqueNickname =                   obj.getNewUniqueNickName;

             MovieStructure.NickName =             NewUniqueNickname;
              MovieStructure.AttachedFiles =        ListWithFileNamesToAdd;
              
             obj =                              obj.addSingleMovieToProject(MovieStructure);
             
              
 
           
        end
        
        function obj = addSingleMovieToProject(obj, MovieStructure)
            
            
             [NewMovieObject]=                                                  PMMovieTracking(MovieStructure, obj.MovieLibrary.PathOfMovieFolder, 0); 
             
             NumberOfMovies =                                                   size(obj.MovieLibrary.ListhWithMovieObjects,1);
             
             obj.MovieLibrary.SelectedNickname =                                MovieStructure.NickName;
             obj.MovieLibrary.ListhWithMovieObjects{NumberOfMovies+1,1} =       NewMovieObject;
             
             obj.ListWithLoadedImageData{NumberOfMovies+1,1} =                  cell(0,1);
             
             obj =                                                              obj.updateView;
             obj =                                                              obj.callbackForFilterChange;
 
        end
        
        
        function [ Nickname ] = getNewUniqueNickName(obj)
            %NICKNAME_GET Summary of this function goes here
            %   Detailed explanation goes here

            ListWithAllExistingNicknamesInProject =                                      cellfun(@(x) x.NickName, obj.MovieLibrary.ListhWithMovieObjects, 'UniformOutput', false);
           
            while 1

                Nickname=                                                                   inputdlg('For single or pooled movie sequence','Enter nickname');
                Nickname=                                                                   Nickname{1,1};
                if isempty(Nickname)
                    continue
                end

                UniqueNickNameWasSelected=                                                     isempty(find(strcmp(Nickname, ListWithAllExistingNicknamesInProject), 1));

                if UniqueNickNameWasSelected
                    return
                end


            end


                

                       

                


            end
        
        function [obj] =        removeMovieClicked(obj,src,~)
            

            SelectedNickname = obj.MovieLibrary.SelectedNickname;
            
             
            
                         answer = questdlg(['Are you sure you remove the movie ', SelectedNickname, ' from the library?  Tracking data will be lost. This is irreversible!'], ...
                'Project menu', 'Yes',   'No','No');
                % Handle response
                
                
                switch answer
                    
                    case 'Yes'
                          %% get rows of currently selected movies in structure:
                        
                        %% remove selected movies from structure:
                        
                         SelectedRow =                                               obj.MovieLibrary.getSelectedRowInLibrary;
                        
                         MovieNickname =    obj.MovieLibrary.ListhWithMovieObjects{SelectedRow,1}.NickName;
                         
                        obj.MovieLibrary.ListhWithMovieObjects(SelectedRow, :)=      [];

                        obj.MovieLibrary.SelectedNickname = '';
                        
                        obj =          obj.updateView;
                        obj =          obj.callbackForFilterChange;
                        
                        


                    case 'No'

                end 
            
        end
        
        function [obj] =        addAllMissingCaptures(obj,src,~)
            
            ListWithAllFileNamesInFolder =                                  obj.getAllFileNamesInMovieFolder;
            
            ListWithAlreadyAddedFiles =                         cellfun(@(x) x.AttachedFiles, obj.MovieLibrary.ListhWithMovieObjects, 'UniformOutput', false);
            ListWithAlreadyAddedFiles=                          vertcat(ListWithAlreadyAddedFiles{:});

            
             [~, file, ext]  =            cellfun(@(x) fileparts(x), ListWithAlreadyAddedFiles, 'UniformOutput', false);

            
            ListWithAlreadyAddedFiles =        cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false);

            
            
             %% remove already added files from directory (so that they are not added as duplicates:
                MatchingRows=                                                       cellfun(@(x) max(strcmp(x, ListWithAlreadyAddedFiles)), ListWithAllFileNamesInFolder);
                ListWithAllFileNamesInFolder(MatchingRows,:)=                       [];

                
                
                %% go through each file and add to project:
                 NumberOfFiles =                                                    size(ListWithAllFileNamesInFolder,1);
                 for FileIndex= 1:NumberOfFiles
                        %% create nickname from first filename:
                     
                        [ NewUniqueNickname ] =             ListWithAllFileNamesInFolder{FileIndex,1}(1:end-4);
                      
                        FileName{1,1} =                     ListWithAllFileNamesInFolder{FileIndex,1};
                        
                        MovieStructure.NickName =             NewUniqueNickname;
                        MovieStructure.AttachedFiles =        FileName;

                        obj =                              obj.addSingleMovieToProject(MovieStructure);

                        
                        
                        
                 end
     
     
    
            
        end
        
        
        function [ListWithAllFileNamesInFolder] = getAllFileNamesInMovieFolder(obj)
        %GETALLMOVIEFILENAMES Summary of this function goes here
        %   Detailed explanation goes here

            ListWithAllFileNamesInFolder=                                       (struct2cell(dir(obj.MovieLibrary.PathOfMovieFolder)))';
            RowsWithDirectories=                                                cell2mat(ListWithAllFileNamesInFolder(:,5))==1;
            ListWithAllFileNamesInFolder(RowsWithDirectories,:)=                [];
            RowsWithSystem=                                                     cellfun(@(x) (strcmp(x(1,1), '.')), ListWithAllFileNamesInFolder(:,1));   
            ListWithAllFileNamesInFolder(RowsWithSystem,:)=                     [];
            ListWithAllFileNamesInFolder(:,2:end)=                              [];

        end
        
        
        
        function [obj] =           mapUnMappedMovies(obj,src,~)
            
            
            %% reset filter so that live watching of mapping update can be seen;
            WantedFilterRow =                                           strcmp(obj.Viewer.ProjectViews.FilterForKeywords.String, 'Show all unmapped movies');
            obj.Viewer.ProjectViews.FilterForKeywords.Value =           find(WantedFilterRow);
           
            
            %% get data
            listWithAllNicknames =                                      cellfun(@(x) x.NickName, obj.MovieLibrary.ListhWithMovieObjects, 'UniformOutput', false);
            listWithWantedRowsInLibrary =                               find(obj.MovieLibrary.FilterList);
            
            
            h =                                                         waitbar(0, 'Mapping image files');
            numberOfNickNamesToMap =                                    length(listWithWantedRowsInLibrary);

            for movieIndex = 1:numberOfNickNamesToMap

                currentIndex =                              listWithWantedRowsInLibrary(movieIndex,1);
                
                % update waitbar:
                currentNickName =                           listWithAllNicknames{currentIndex,1};
                currentNickName(currentNickName=='_') =     ' ';
                waitBarNumber =                             movieIndex/numberOfNickNamesToMap;
                waitbar(waitBarNumber, h, ['Mapping image file: ' currentNickName]);
                
                % do the actual mapping
                obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1}.Folder =                  obj.MovieLibrary.PathOfMovieFolder;
                obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1} =                         obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1}.AddImageMap;

                % update filter view (i.e. remove mapped movie from "unmapped list";
                [obj] =                                                                                                     obj.callbackForFilterChange(src, 0);

            end

            waitbar(1, h, 'Finished mapping')
            close(h)
            
        end
        
        function obj = unmapAllMovies(obj,src,~)
            
            
            
            %% reset filter so that live watching of mapping update can be seen;
            WantedFilterRow =                                           strcmp(obj.Viewer.ProjectViews.FilterForKeywords.String, 'Show all unmapped movies');
            obj.Viewer.ProjectViews.FilterForKeywords.Value =           find(WantedFilterRow);
            [obj] =                                                                                                     obj.callbackForFilterChange(src, 0);
            
            %% get data
            listWithAllNicknames =                                      cellfun(@(x) x.NickName, obj.MovieLibrary.ListhWithMovieObjects, 'UniformOutput', false);
             numberOfNickNamesToUnMap =                                    length(listWithAllNicknames);
            listWithWantedRowsInLibrary =                               (1:numberOfNickNamesToUnMap)';
            
            
            h =                                                         waitbar(0, 'Unampping image files');
           

            for movieIndex = 1:numberOfNickNamesToUnMap

                currentIndex =                              listWithWantedRowsInLibrary(movieIndex,1);
                
                % update waitbar:
                currentNickName =                           listWithAllNicknames{currentIndex,1};
                currentNickName(currentNickName=='_') =     ' ';
                waitBarNumber =                             movieIndex/numberOfNickNamesToUnMap;
                waitbar(waitBarNumber, h, ['Unampping image file: ' currentNickName]);
                
                % remove mapping:
      
                obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1}.ImageMapPerFile =                 [];
                obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1}.ImageMap =                        [];
                obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1}.MetaData =                        [];
                obj.MovieLibrary.ListhWithMovieObjects{listWithWantedRowsInLibrary(movieIndex),1}.MetaDataOfSeparateMovies =        [];

                % update filter view (i.e. remove mapped movie from "unmapped list";
                [obj] =                                                                                                     obj.callbackForFilterChange(src, 0);

            end

            waitbar(1, h, 'Finished unmapping')
            close(h)
            
            
            
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
            ShortcutsKeys{7,1}=         '"m": Toggle maximum-projection';
            ShortcutsKeys{8,1}=         '"o": Toggle between cropped and uncropped';
            ShortcutsKeys{9,1}=         '';
            ShortcutsKeys{10,1}=         '"1" to "9": Toggle visibility of channels 1 to 9';
            ShortcutsKeys{11,1}=         '';
            
            ShortcutsKeys{12,1}=        '-------Annotation------------------';
            ShortcutsKeys{13,1}=        '"i": Toggle visibility of time label';
            ShortcutsKeys{14,1}=        '"z": Toggle visibility of z-position label';
            ShortcutsKeys{15,1}=        '"s": Toggle visibility of scale bar';
             ShortcutsKeys{16,1}=         '';
             
            ShortcutsKeys{17,1}=        '-------Tracking--------------------';
            ShortcutsKeys{18,1}=        '"c": Toggle visibility of centroids';
            ShortcutsKeys{19,1}=        '"a": Toggle visibility of masks';
            ShortcutsKeys{20,1}=        '"t": Toggle visibility of trajectories';
            ShortcutsKeys{21,1}=        '"u": update tracks in TrackingResults model';
            ShortcutsKeys{22,1}=        '"n": select next track in track-list';
            ShortcutsKeys{23,1}=        '"p": select previous track in track-list';
            ShortcutsKeys{24,1}=        '';
           

            MouseMovement{1,1}=         '--------MOUSE-MOVEMENT-----------------------------------';
            MouseMovement{2,1}=         'with control: drag currently cropped region';
            MouseMovement{3,1}=         '';
            MouseMovement{4,1}=         '--------MOUSE-MOVEMENT DURING TRACKING-------------------';
            MouseMovement{5,1}=         'with command: add pixels to current mask';
            MouseMovement{6,1}=        '';
            
            MouseLiftUp{1,1}=         '--------MOUSE-RELEASE ON SAME SPOT-----------------------------------';
            MouseLiftUp{2,1}=         ' ';
            MouseLiftUp{3,1}=         '--------MOUSE-RELEASE ON DIFFERENT SPOT-------------------';
            MouseLiftUp{4,1}=         'complete view: draw cropping rectangle';
            MouseLiftUp{5,1}=         'cropped during tracking: delete all pixels in rectangle';
            MouseLiftUp{6,1}=        '';
            
            
            msgbox([ShortcutsKeys;MouseMovement;MouseLiftUp])


            
        end
        
   
        
         %% respond to mouse or key input:
          function [obj] =           keyPressed(obj,src,~)
             
             if ~obj.verifyActiveMovieStatus
                 return
             end
             
             
             PressedKey=                             get(obj.Viewer.Figure,'CurrentCharacter');
            if isempty(PressedKey)
                return
            end
             
             obj.ActiveMovieController.interpretKey(PressedKey);
             
             
             obj.Viewer.Figure.CurrentCharacter = '0';
             
             
              
                 
             
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
                  
                    
                    myEditingActivity =                                     obj.EditingActivity;
                    
                    
                    
                    CurrentModifier =                                       obj.Viewer.Figure.CurrentModifier;
                    NumberOfModifiers =                                     size(CurrentModifier,2);
                    
                    switch  NumberOfModifiers
                        
                        
                        case 0
                            
                            switch myEditingActivity
                                
                                case 'Tracking'
                                    obj.MouseAction = 'Edit mask';
                                    obj.ActiveMovieController =   obj.ActiveMovieController.updateActiveMaskByButtonClick;

                                otherwise

                                    obj.MouseAction = 'No action';
                                
                                
                                
                            end
                            
                            
                            
                        case 1
                            
                            NameOfModifier = CurrentModifier{1,1};
                            switch NameOfModifier
                                
                                case 'shift'
                                    
                                    switch myEditingActivity
                                
                                        case 'Tracking'
                                            obj.MouseAction =           'Edit mask';
                                            obj.ActiveMovieController = obj.ActiveMovieController.activateNewTrack;
                                            obj.ActiveMovieController =   obj.ActiveMovieController.updateActiveMaskByButtonClick;

                                        case 'Manual drift correction'
                                            obj.MouseAction =           'Edit manual drift correction';
                                            obj.ActiveMovieController =   obj.ActiveMovieController.updateManualDriftCorrectionByMouse;
                                            
                                            
                                        otherwise
                                            obj.MouseAction = 'No action';

                                    end
                                     
                                case 'control'
                                    obj.MouseAction = 'Move view';
                                    
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
                                    
                                      switch myEditingActivity

                                            case 'Tracking'
                                                obj.MouseAction =           'AutoTrackCurrentCell';


                                            otherwise

                                                obj.MouseAction = 'No action';

                                        end
                                    
                                    
                             
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
                                            obj.ActiveMovieController = obj.ActiveMovieController.updateCroppingGateFromMouseClicks;
                                            obj.ActiveMovieController = obj.ActiveMovieController.updateCroppingLimitView;
                                            obj.ActiveMovieController = obj.ActiveMovieController.updateAppliedCroppingLimits;

                                      case {'Invalid', 'Out of bounds'}
                                            obj.ActiveMovieController = obj.ActiveMovieController.resetCroppingGate;
                                            obj.ActiveMovieController = obj.ActiveMovieController.updateCroppingLimitView;
                                            obj.ActiveMovieController = obj.ActiveMovieController.updateAppliedCroppingLimits;

                                 end
                                
                            case 'Move view'
                            
                                switch mousePattern

                                      case 'Movement'

                                          XMovement =       obj.ActiveMovieController.MouseUpColumn - obj.ActiveMovieController.MouseDownColumn;
                                          YMovement =       obj.ActiveMovieController.MouseUpRow - obj.ActiveMovieController.MouseDownRow;


                                          obj.ActiveMovieController = obj.ActiveMovieController.resetAxesCenter(XMovement, YMovement);

                            
                                end
                        
                        
                             case 'Edit mask'
                                
                                
                                switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.updateActiveMaskByButtonClick;
                                        
                                    
                                end
                                
                                
                            case 'Subtract pixels'
                                
                                  switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.highLightRectanglePixelsByMouse;
                                        
                                    
                                  end
                                
                            case 'Add pixels'
                                
                                  switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.highLightRectanglePixelsByMouse;
                                        
                                    
                                  end

                                  
                            case 'Edit manual drift correction'
                                
                                 switch mousePattern
                                    
                                    case {'Movement', 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.updateManualDriftCorrectionByMouse;
                                        
                                    
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

                                      case 'Movement'
                                            obj.ActiveMovieController = obj.ActiveMovieController.changeActiveTrackByRectangle;
                                           
                                            
                                            
                                      case {'Invalid', 'Out of bounds'}
                                          
                                          
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
                                  
                            case 'AutoTrackCurrentCell'
                                
                                switch mousePattern
                                    
                                    case { 'Stay'}
                                        
                                        obj.ActiveMovieController =   obj.ActiveMovieController.autoTrackCurrentCell;
                                        
                                    
                                  end
                          

                                 
                  end
              
                obj.MouseAction =                                       'No action';  
                obj.ActiveMovieController.MouseDownRow =                NaN;
                obj.ActiveMovieController.MouseDownColumn =             NaN;

             
   
          end
          
          
        %% respond to clicks on project views:
       
        
        function [obj] =        movieListClicked(obj, src, ~)
            

            SelectionType =                                         obj.Viewer.Figure.SelectionType;
            switch SelectionType
                
                case 'open'
                    
                    
                   
                     obj =                                                              obj.synchronizeMovieLibraryWithActiveMovie;
            
           
            
                    %% change selected nickname and update views with newly selected movie:
                    [ListWithSelectedNickNames] =                                       obj.MovieLibrary.ListWithFilteredNicknames;
                    obj.MovieLibrary.SelectedNickname=                                  ListWithSelectedNickNames{obj.Viewer.ProjectViews.ListOfMoviesInProject.Value};
                    obj.Viewer.ProjectViews.SelectedNickname.String =                   obj.MovieLibrary.SelectedNickname;

                    obj =                                                               obj.changeDisplayedMovie;

                    %% update info-view as appropriate:
                    obj =                                                               obj.updateInfoView;
           
                    

            end
            
            
        end
        
        
        function [obj] =        callbackForFilterChange(obj, src, ~)
            
             
                %% apply current selection in menu to filter
                
                PopupMenu =                         obj.Viewer.ProjectViews.FilterForKeywords;
                
                obj.MovieLibrary =                  obj.MovieLibrary.updateFilterSettingsFromPopupMenu(PopupMenu);
                obj =                              obj.updateView;
                 
              
                 
                 
            
        end
        
        
        

      
                
        %% response to movie menu click:

        function [obj] = changeKeywordClicked(obj,src,~)
               
               obj.ActiveMovieController =      obj.ActiveMovieController.changeMovieKeyword;
               
                [obj] =                         obj.synchronizeMovieLibraryWithActiveMovie;
                
                
                obj =                           obj.updateView;
                
                obj =                           obj.callbackForFilterChange;
            
            
          end
        
           
        function [obj] = reapplySourceFilesClicked(obj,src,~)
              
             if isempty(obj.ActiveMovieController)  || isempty(obj.ActiveMovieController.LoadedMovie)
                 return
             end
             
             % first erase all the image volumes (if something was wrong we don't want these anymore);
             obj.ActiveMovieController.LoadedImageVolumes =     cell(obj.ActiveMovieController.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints,1);
             
             % then replace the image maps:
             obj.ActiveMovieController.LoadedMovie =            obj.ActiveMovieController.LoadedMovie.AddImageMap;
             [obj] =                                            obj.synchronizeMovieLibraryWithActiveMovie;
             obj =                                              obj.changeDisplayedMovie;
             
              
          end
          
          
        function  [obj] = deleteImageCacheClicked(obj,src,~)
              
               
             if isempty(obj.ActiveMovieController)  || isempty(obj.ActiveMovieController.LoadedMovie)
                 return
             end
             
             % first erase all the image volumes (if something was wrong we don't want these anymore);
             obj.ActiveMovieController.LoadedImageVolumes =     cell(obj.ActiveMovieController.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints,1);
      
              
        end
        
        
        function  [obj] = applyManualDriftCorrectionClicked(obj,src,~)
            
            
            obj.ActiveMovieController.LoadedMovie.DriftCorrection =                     obj.ActiveMovieController.LoadedMovie.DriftCorrection.updateByManualDriftCorrection;
            obj.ActiveMovieController =                                                 obj.ActiveMovieController.updateAppliedPositionShift; % needs to be before resetLimitsOfImageAxes
            obj.ActiveMovieController =                                                 obj.ActiveMovieController.resetLimitsOfImageAxes;

        end
        
      
        
        function  [obj] = eraseAllDriftCorrectionsClicked(obj,src,~)

            obj.ActiveMovieController.LoadedMovie.DriftCorrection =                     obj.ActiveMovieController.LoadedMovie.DriftCorrection.eraseDriftCorrection(obj.ActiveMovieController.LoadedMovie.MetaData);
            obj.ActiveMovieController =                                                 obj.ActiveMovieController.updateAppliedPositionShift; % needs to be before resetLimitsOfImageAxes
            obj.ActiveMovieController =                                                 obj.ActiveMovieController.resetLimitsOfImageAxes;

            
        end
        
        

          
        
        function [obj] = showAttachedFilesClicked(obj,src,~)
            
          

                %% get data of current movie:
              
                obj.ActiveInfoType =                'Attached files';
                obj =                               obj.updateInfoView;
          
    
             
            
         end
        
          
        function [obj] = showMetaDataInfoClicked(obj,src,~)

                obj.ActiveInfoType =                'MetaData';
                obj= obj.updateInfoView;    

        end
        
        
        %% response to tracking menu click:
        
        function [obj] = deleteTrackClicked(obj,src,~)
            
            obj.ActiveMovieController =         obj.ActiveMovieController.deleteActiveTrack;
            
            
        end
        
         function [obj] = mergeSelectedTracks(obj,src,~)
             obj.ActiveMovieController =         obj.ActiveMovieController.mergeSelectedTracks;
             
         end
         
          function [obj] = splitSelectedTracks(obj,src,~)
             
             obj.ActiveMovieController =         obj.ActiveMovieController.splitSelectedTracks;
         end
         
         
         
        
        
                 
        
         function [obj] = updateTracksClicked(obj,src,~)
             
                obj.ActiveMovieController.LoadedMovie =           obj.ActiveMovieController.LoadedMovie.refreshTrackingResults;
                obj.ActiveMovieController =                       obj.ActiveMovieController.updateTrackList;
                obj.ActiveMovieController =                       obj.ActiveMovieController.updateTrackView;

            
         end
        
        function [obj] = deleteMaskClicked(obj,src,~)
            
            
            obj.ActiveMovieController =         obj.ActiveMovieController.deleteActiveMask;
              
              
            
        end
        
        
     
         
          
        %% response to view action in navigation and channel area:
        
        function [obj] =            sliderActivity(obj,src,~)
            
            disp(['Value = ', num2str(obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Value)]);
            obj.ActiveMovieController = obj.ActiveMovieController.resetFrame(round(obj.Viewer.MovieControllerViews.Navigation.TimeSlider.Value));
            
        end
        

        function [obj] =           editingOptionsClicked(obj,src,~)
            
            
            SelectedString = obj.Viewer.MovieControllerViews.Navigation.EditingOptions.String{obj.Viewer.MovieControllerViews.Navigation.EditingOptions.Value};
            
            switch SelectedString
                
                case 'Viewing only' % 'Visualize'
                    obj.ActiveMovieController.Views.MovieView.ManualDriftCorrectionLine.Visible = 'off';
                    obj.EditingActivity =                                   'No editing';
                    obj.ActiveMovieController.LoadedMovie.TrackingOn =      0;
                    
                case 'Edit manual drift correction'
                    obj.ActiveMovieController.Views.MovieView.ManualDriftCorrectionLine.Visible = 'on';
                    obj.EditingActivity =                                   'Manual drift correction';
                    obj.ActiveMovieController.LoadedMovie.TrackingOn =      0;
                    
                case 'Edit tracks' %  'Tracking: draw mask'
                    obj.ActiveMovieController.Views.MovieView.ManualDriftCorrectionLine.Visible = 'off';
                    obj.EditingActivity =                                'Tracking';
                    obj.ActiveMovieController.LoadedMovie.TrackingOn =   1;

            end
             
        end
        
          function [obj] =           planeViewClicked(obj,src,~)
            newPlane =                                      obj.ActiveMovieController.Views.Navigation.CurrentPlane.Value;

            obj.ActiveMovieController  =                    obj.ActiveMovieController.resetPlane(newPlane);
            obj.ActiveMovieController.LoadedMovie =         obj.ActiveMovieController.LoadedMovie.resetViewPlanes;
            [obj.ActiveMovieController] =                   obj.ActiveMovieController.updateViewsAfterPlaneChange;

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
              obj.ActiveMovieController.LoadedMovie.CroppingOn =        obj.ActiveMovieController.Views.Navigation.CropImageHandle.Value;
              obj.ActiveMovieController =                   obj.ActiveMovieController.resetLimitsOfImageAxes;
              
              
              
          end
          
          
           function [obj] =          driftCorrectionOnOffClicked(obj,src,~)
               
               OnOrOffValue =                   obj.Viewer.MovieControllerViews.Navigation.ApplyDriftCorrection.Value;
               obj.ActiveMovieController =      obj.ActiveMovieController.updateAppliedDriftCorrectionFromCheckBox(OnOrOffValue);
                    
           end
          
          
  
          function [obj] =           channelViewClicked(obj,src,~)
              
             newChannel =       obj.ActiveMovieController.Views.Channels.SelectedChannel.Value;
             [obj]  =           obj.ActiveMovieController.resetChannelSettings(newChannel);
            
          end
         
         
          function [obj] =           channelLowIntensityClicked(obj,src,~)
             
             newIntensity =         str2double(obj.ActiveMovieController.Views.Channels.MinimumIntensity.String);
             channelNumber =        obj.ActiveMovieController.LoadedMovie.SelectedChannelForEditing;
             
             obj.ActiveMovieController.LoadedMovie.ChannelTransformsLowIn(channelNumber) = newIntensity;
             
             obj.ActiveMovieController = obj.ActiveMovieController.updateViewsAfterChannelChange;
            
         end
         
          function [obj] =           channelHighIntensityClicked(obj,src,~)
             newIntensity =             str2double(obj.ActiveMovieController.Views.Channels.MaximumIntensity.String);
             channelNumber =            obj.ActiveMovieController.LoadedMovie.SelectedChannelForEditing;
             obj.ActiveMovieController.LoadedMovie.ChannelTransformsHighIn(channelNumber) = newIntensity;
             
            obj.ActiveMovieController = obj.ActiveMovieController.updateViewsAfterChannelChange;
            
             
         end
         
          function [obj] =          channelColorClicked(obj,src,~)
              NewColor =  obj.ActiveMovieController.Views.Channels.Color.String{obj.ActiveMovieController.Views.Channels.Color.Value};
              channelNumber = obj.ActiveMovieController.LoadedMovie.SelectedChannelForEditing;
              obj.ActiveMovieController.LoadedMovie.ChannelColors{channelNumber} = NewColor;
           
              ob.ActiveMovieControllerj = obj.ActiveMovieController.updateViewsAfterChannelChange;
             
          end
          
          function [obj] =          channelCommentClicked(obj,src,~)
              newComment = obj.ActiveMovieController.Views.Channels.Comment.String;
              channelNumber = obj.ActiveMovieController.LoadedMovie.SelectedChannelForEditing; 
              obj.ActiveMovieController.LoadedMovie.ChannelComments{channelNumber} = newComment;
            
            
              obj.ActiveMovieController = obj.ActiveMovieController.updateViewsAfterChannelChange;
             
          end
          
          function [obj] =          channelOnOffClicked(obj,src,~)
              newSelection =     logical(obj.ActiveMovieController.Views.Channels.OnOff.Value);
              channelNumber = obj.ActiveMovieController.LoadedMovie.SelectedChannelForEditing;
               obj.ActiveMovieController.LoadedMovie.SelectedChannels(channelNumber) = newSelection;
             
               obj.ActiveMovieController = obj.ActiveMovieController.updateViewsAfterChannelChange;
               
          end
          
          
          % annotation:
          
       
          function [obj] =         annotationScaleBarOnOffClicked(obj,src,~)
              
              obj.ActiveMovieController.LoadedMovie.ScaleBarVisible = obj.ActiveMovieController.Views.Annotation.ShowScaleBar.Value;
              obj.ActiveMovieController = obj.ActiveMovieController.updateAnnotationViews;  
             
              
              
          end
          
          function [obj] =         annotationScaleBarSizeClicked(obj,src,~)
              
              obj.ActiveMovieController.LoadedMovie.ScaleBarSize =  obj.ActiveMovieController.Views.Annotation.SizeOfScaleBar.Value;
              obj.ActiveMovieController.LoadedMovie =                obj.ActiveMovieController.LoadedMovie.updateScaleBarString;
              obj.ActiveMovieController =                                                     obj.ActiveMovieController.updateViewsAfterScaleBarChange;
              
          end
         
          
          %% respond to tracking view click:

          function [obj] =       trackingActiveTrackButtonClicked(obj,src,~)
                  
              
       
              obj.ActiveMovieController.LoadedMovie.ActiveTrackIsHighlighted = obj.ActiveMovieController.TrackingViews.ActiveTrackTitle.Value;
              
              obj.ActiveMovieController =       obj.ActiveMovieController.updateHighlightingOfActiveTrack;
              
              
              
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
              
              
              obj.ActiveMovieController.LoadedMovie.TracksAreVisible = obj.ActiveMovieController.TrackingViews.ShowTracks.Value;
              obj.ActiveMovieController = obj.ActiveMovieController.updateTrackVisibility;
                
              
          end
          

          function [obj] =      trackingShowMaximumProjectionButtonClicked(obj,src,~)
              
              
              
              obj.ActiveMovieController = obj.ActiveMovieController.resetPlaneTrackingByMenu;
              

              
              
          end
          
          
          function [obj] =      trackingTrackListClicked(obj,src,~)
              
              
              obj.ActiveMovieController =       obj.ActiveMovieController.resetActiveTrackByTrackList;
              
              
            

              
          end
          
          
                   
                
          
          %% change model and view:
       
          function [obj] =        loadLibraryAndUpdateViews(obj)
              
                %% load file
                
                 
                obj.MovieLibrary =                                  PMMovieLibrary(obj.FileNameForLoadingNewObject);
                obj.MovieLibrary =                                  obj.MovieLibrary.sortByNickName;

                obj =                                               obj.resetActiveMovieController;
                
                if isempty(obj.FileNameForLoadingNewObject)
                    return
                end


                obj.ListWithLoadedImageData =                       cell(size(obj.MovieLibrary.ListhWithMovieObjects,1),1);
                obj =                                               obj.updateView;
                obj =                                               obj.updateInfoView;
          %     obj =                                               obj.changeDisplayedMovie;
                
          end
          


          function [obj ] =       changeDisplayedMovie(obj,src,~)
            
            
            %% if no movies exist or are not specified, just black out all the movie views and leave;
            if isempty(obj.MovieLibrary.ListhWithMovieObjects) || isempty(obj.MovieLibrary.SelectedNickname)
                obj.Viewer.MovieControllerViews.blackOutMovieView;
                return
            end
            
             [obj.ActiveMovieController] =                          obj.ActiveMovieController.deleteAllTrackLineViews;
             
             
            obj =                                                      obj.resetActiveMovieController;
            
            
            %% if a movie is there: change the "active movie";
            SelectedRow =                                               obj.MovieLibrary.getSelectedRowInLibrary;
            obj.ActiveMovieController.LoadedMovie =                     obj.MovieLibrary.ListhWithMovieObjects{SelectedRow,1};
            obj.ActiveMovieController.LoadedImageVolumes =              obj.ListWithLoadedImageData{SelectedRow,1};
          
            
             %% when the file was not yet mapped successfully, do the mapping now
            if isempty(obj.ActiveMovieController.LoadedMovie.ImageMapPerFile)
                
                obj.ActiveMovieController.LoadedMovie.Folder =                obj.MovieLibrary.PathOfMovieFolder;
                 obj.ActiveMovieController.LoadedMovie =                        obj.ActiveMovieController.LoadedMovie.AddImageMap;
                 
                
            else

                % otherwise: update the pointers of the current image maps if necessary:;
                obj.ActiveMovieController.LoadedMovie =                     obj.ActiveMovieController.LoadedMovie.updateFileReadingStatus;
                 
            end 
            
            
            % this shouldn't be necessary: but if for some reason the set plane etc. is inaccurate change this before doing anything with the data;
            obj.ActiveMovieController.LoadedMovie =                     obj.ActiveMovieController.LoadedMovie.autoCorrectNavigation;
            
            
            
            
          %  obj.ActiveMovieController.Views.MovieView.CentroidLine_SelectedTrack.Visible =  ActiveTrackIsHighlighted;
           
            
             
             
             
             
                 
                obj.ActiveMovieController.enableAllViews;
                obj.Viewer.MovieControllerViews.reverseBlackOut;

                
                
                obj.ActiveMovieController =                                     obj.ActiveMovieController.ensureCurrentImageFrameIsInMemory;
                
                obj.ActiveMovieController.LoadedMovie.Folder
                
                %% finalize loaded movie so that it works together with the controller views:
                obj.ActiveMovieController.LoadedMovie.DriftCorrection =                 obj.ActiveMovieController.LoadedMovie.DriftCorrection.update(obj.ActiveMovieController.LoadedMovie.MetaData);
                obj.ActiveMovieController.LoadedMovie =                                 obj.ActiveMovieController.LoadedMovie.autoCorrectTrackingObject;
                
                obj.ActiveMovieController =                                              obj.ActiveMovieController.synchronizeTrackingResults;
                

                %% if everything was ok: upload all the views with the newly loaded data:
                
                
                obj.ActiveMovieController =                                             obj.ActiveMovieController.updateCompleteView;
                obj.ActiveMovieController =                                             obj.ActiveMovieController.updateAllTrackingViews;
       
                
             
                   

          end
        
        
         
       
          
         %% change model:
         
         function [obj] =           synchronizeMovieLibraryWithActiveMovie(obj)
             
             
              %% put changes in currently edit movie back to library: not if the movie in active controller is empty (this happens when no movie could be loaded successfully): 
            if ~isempty(obj.ActiveMovieController.LoadedMovie) && ~isempty(obj.MovieLibrary.ListhWithMovieObjects)
                
                

             
                % get row in library that corresponds to active movie 
                NickNameOfActiveMovie =                                                             obj.ActiveMovieController.LoadedMovie.NickName;
                CurrentlyEditedRowInLibrary =                                                       obj.MovieLibrary.getSelectedRowInLibraryOf(NickNameOfActiveMovie);
                
                if sum(CurrentlyEditedRowInLibrary) == 0
                    return
                end
                
                % update library
                obj.MovieLibrary.ListhWithMovieObjects{CurrentlyEditedRowInLibrary,1} =             obj.ActiveMovieController.LoadedMovie;
                
                % also place the current image data into the manager;
                % they should not be saved on file because it could blow up storage;
                % but they should be kept in memory so that previous movie information of a previously selected file can be accessed quickly;
                obj.ListWithLoadedImageData{CurrentlyEditedRowInLibrary,1} =                        obj.ActiveMovieController.LoadedImageVolumes;

            end
            
         end

          
        
          function [obj] =          setPreviouslyUsedFileName(obj)
              
            if exist(obj.FileWithPreviousSettings,'file')==2
                load(obj.FileWithPreviousSettings, 'FileNameOfProject')
                if exist(FileNameOfProject)==2
                    obj.FileNameForLoadingNewObject =  FileNameOfProject;
                end

            end
              
          end
          
          
        %% change view:
        function [obj] =            updateView(obj,src, ~)
                %PROJEC Summary of this function goes here
                %   Detailed explanation goes here


                %% inactivate the controller views if nothing is selected: (maybe this should be at a different location)
                if isempty(obj.MovieLibrary.ListhWithMovieObjects) || isempty(obj.MovieLibrary.SelectedNickname)
                    obj.ActiveMovieController.disableAllViews;
                end
                obj.Viewer.ProjectViews.SelectedNickname.String =                   obj.MovieLibrary.SelectedNickname;
               
                
                %% set the current filter by view:
                ListWithKeywordStrings =                                            obj.MovieLibrary.getKeyWordList;
                ProjectWindowHandles =                                              obj.Viewer.ProjectViews;
                
                if isempty(ListWithKeywordStrings)
                    ListWithKeywordStrings=                                         [obj.ProjectFilterList];
                    ProjectWindowHandles.FilterForKeywords.Enable=                  'on';
                   
                else
                    ListWithKeywordStrings=                                          [obj.ProjectFilterList; ListWithKeywordStrings];
                    ProjectWindowHandles.FilterForKeywords.Enable=                  'on';
                end
                ProjectWindowHandles.FilterForKeywords.String=                      ListWithKeywordStrings;
                
               ProjectWindowHandles.FilterForKeywords.Value =  obj.MovieLibrary.FilterSelectionIndex;
               if min(ProjectWindowHandles.FilterForKeywords.Value) == 0
                   ProjectWindowHandles.FilterForKeywords.Value = 1;
               end
               
               if min(ProjectWindowHandles.FilterForKeywords.Value)> length(ProjectWindowHandles.FilterForKeywords.String)
                   ProjectWindowHandles.FilterForKeywords.Value = length(ProjectWindowHandles.FilterForKeywords.String);
               end
                
                
                
                
                
                %% show nicknames of all selected movies:
                ListWithSelectedNickNames =               obj.MovieLibrary.ListWithFilteredNicknames;

                if ~isempty(ListWithSelectedNickNames)

                    if obj.MovieLibrary.SortIndex == 1 % currently always sorted by nickanme
                        ListWithSelectedNickNames =                         sort(ListWithSelectedNickNames);
                        
                        
        
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

                        InfoText=                               [FileNameOfProject;FolderWithMovieFiles; PathForDataExport];

            
                 case 'Attached files'

                     
                      TrackingInternal =                              obj.ActiveMovieController.LoadedMovie.Tracking;
                        
                          NamesOfAttachedFileNames=                       obj.ActiveMovieController.LoadedMovie.AttachedFiles;






                        %% extract relevant information out of movie-info:

                        TrackingWasPerformed=                           isfield(TrackingInternal, 'Tracking');
                        switch TrackingWasPerformed

                            case 1
                                NumberOfTracks=                         size(TrackingInternal.Tracking,1);
                                TrackingText=                           sprintf('%i tracks generated',      NumberOfTracks);     

                            otherwise
                                TrackingText=                           'Tracking was not performed';

                        end


                        
                        DriftCorrectionWasPerformed=                   obj.ActiveMovieController.LoadedMovie.DriftCorrection.testForExistenceOfDriftCorrection;
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

                        InfoText= [FileText; SummaryText];

                         
                     
                      


                 case 'MetaData'
                     
                      if ~obj.verifyActiveMovieStatus
                         InfoText = {'No movie loaded'};
                         
                      else
                          ShortFileName=                                      obj.ActiveMovieController.LoadedMovie.AttachedFiles;
                        [ MetaDataOfSeparateMovies ] =                                      obj.ActiveMovieController.LoadedMovie.MetaDataOfSeparateMovies;

                        namesOfFields=                                      cellfun(@(x) fieldnames(x.EntireMovie), MetaDataOfSeparateMovies, 'UniformOutput', false);
                        contentsofFields=                                   cellfun(@(x) struct2cell(x.EntireMovie), MetaDataOfSeparateMovies, 'UniformOutput', false);
                        numberOfMovies =                                    size(namesOfFields,1);
                        for movieIndex = 1:numberOfMovies
                            InfoText{movieIndex,1}=                                cellfun(@(x,y) [x ':    ' num2str(y)], namesOfFields{movieIndex}, contentsofFields{movieIndex}, 'UniformOutput', false);
                            InfoText{movieIndex,1}=                                [['Filename: ', ShortFileName{movieIndex}];   InfoText{movieIndex,1}; ' '];

                        end
                        InfoText = vertcat(InfoText{:});
   
                      end


                otherwise

                        InfoText =             {'Info could not be retrieved.'};


            end
              
             
             obj.Viewer.InfoView.List.String =               InfoText;
             obj.Viewer.InfoView.List.Value =            min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);
            
        end

          
          %% helper functions  
        
          function [check] =      pointIsWithinImageAxesBounds(obj, CurrentRow, CurrentColumn)
              
              
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
        
          function [Category] =   interpretMouseMovement(obj)

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
       
           function verifiedStatus = verifyActiveMovieStatus(obj)
              
              verifiedStatus = ~isempty(obj.ActiveMovieController)  && ~isempty(obj.ActiveMovieController.LoadedMovie) && ~isempty(obj.ActiveMovieController.Views) ;
              
          end
          
         
          
          %% file management
          
          function updatePreviouslyLoadedFileInfo(obj)
              
               %% store specified path in "previous settings" file:
                FileNameOfProject=                              obj.MovieLibrary.FileName;
                save(obj.FileWithPreviousSettings, 'FileNameOfProject')

           end
          
          
          function [obj] = saveProjectToFile(obj)

              
              % it would be good to synchronize, but I had some issues with
              % that;
              % for now just click on another movie to commit the changes;
              % current movie is not
               [obj] = synchronizeMovieLibraryWithActiveMovie(obj); % first synchronize movie (otherwise current edits of active movie will be lost;
              
                ImagingProject =                    obj.MovieLibrary;
                CompletePathOfCurrentProject =      obj.MovieLibrary.FileName;
                %% store project:
                if exist('ImagingProject', 'var')== 1 && ~isempty(CompletePathOfCurrentProject)
                    %% store imaging project in specified path:
                    save (CompletePathOfCurrentProject, 'ImagingProject')

                end
                
                
               % [obj] = synchronizeMovieLibraryWithActiveMovie(obj);
                
               % save ([CompletePathOfCurrentProject '_second.mat'], 'ImagingProject')

          end

  
    end
end

