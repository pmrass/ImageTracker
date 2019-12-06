classdef PMMovieLibrary
    %PMMOVIELIBRARY manage movies for tracking analysis
    %   Detailed explanation goes here
    
    properties
        
        Version =                                   4;
        FileName
        FileCouldNotBeLoaded =                      1;
        UnsupportedVersion =                        1;
        
        PathOfMovieFolder
        PathForExport
        
        % list that contain entry for every single movie:
       
        ListWithMovieObjectSummary =                        cell(0,1);
        FilterList =                                        true
        ListhWithMovieObjects =                             cell(0,1);
        ListWithLoadedImageData =                           cell(0,1);
        
        % scalar filter settings
        SelectedKeywords =                              ''
        SelectedNickname =                              ''
        ListWithFilteredNicknames
        
        
        FilterSelectionIndex =                      1;
        FilterSelectionString =                     ''
        
        KeywordFilterSelectionIndex =               1;
        KeywordFilterSelectionString =              'Ignore keywords';
        
        
        SortIndex =                                 1;
        
    end
    
    methods
        
     
        
        function obj = PMMovieLibrary(FileNameForLoadingNewObject)
            
            
            %% attempt to load and update load status:
            if exist(FileNameForLoadingNewObject)~=2
                return
                   
            end
            
            
            
            load(FileNameForLoadingNewObject, 'ImagingProject');
            obj.FileCouldNotBeLoaded =              0;

            
            %% get version:
            if ~strcmp(class(ImagingProject), 'PMMovieLibrary')
                obj.Version = 2;
  
            else
                obj.Version = ImagingProject.Version;

            end
            
            %% load file and/or update version status:
            switch obj.Version
                
                case 2
                    obj.UnsupportedVersion =            0;
                    
                    obj.FileName =                      ImagingProject.Files_ProjectName;
                    obj.FileName =                      FileNameForLoadingNewObject;
                    
                    obj =                               obj.convertVersionTwoToThree(ImagingProject);
                    obj.Version =                       3;
                    OldFilename =                       obj.FileName;
                    NewFilename =                       [OldFilename(1:end-4) '_Version3.mat'];
                    obj.FileName =                      NewFilename; % now the file will be saved as version 3, but with a new filename do prevent overwriteing
                   
                    if size(obj.ListWithFilteredNicknames,1) >= 1
                        obj.SelectedNickname=               obj.ListWithFilteredNicknames{1, 1};
                    end
                    
                case 3 % this is the current version: just read the file directly, that's it; no parsing required;
                     obj =   ImagingProject;
                     obj.FileName =                         FileNameForLoadingNewObject;
                      obj =                               obj.convertVersionThreeToFour;
                    
                case 4
                    obj =                               ImagingProject;
                    obj.FileName =                      FileNameForLoadingNewObject;
                    
                    
                otherwise
                    obj = [];
                    
                
            end
            
            numberOfMovies =                                        obj.getNumberOfMovies;
            obj.ListhWithMovieObjects =                             cell(numberOfMovies,1); % these two are not saved in file: initialize with right number of rows after loading;
            obj.ListWithLoadedImageData =                           cell(numberOfMovies,1);
          
            
        end
        
     
        %% getters:
        function mainFolder =           getMainFolder(obj)
            
             [mainFolder,name,ext] =                           fileparts(obj.FileName);
            
            
        end
        
         function KeywordList =          getKeyWordList(obj)
            
                ListWithKeywords =                      cellfun(@(x) x.Keywords, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
              FinalList =                             (vertcat([ListWithKeywords{:}]))';
                
                if ~isempty(FinalList)
                    
                    EmptyRows=                          cellfun(@(x) isempty(x),FinalList);
                    FinalList(EmptyRows,:)=             [];  
                     KeywordList=                        unique(FinalList);
                     
                else
                    KeywordList =   '';
                    
                end

         end
        
        
        function [SelectedRow] =        getSelectedRowInLibrary(obj)
            ListWithAllNickNamesInternal =      cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);   
            SelectedRow =                       strcmp(ListWithAllNickNamesInternal, obj.SelectedNickname);

        end
        
        function [SelectedRow] =        getSelectedRowInLibraryOf(obj,NickNameString)
            ListWithAllNickNamesInternal =      cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);   
            SelectedRow =               strcmp(ListWithAllNickNamesInternal, NickNameString);

            
            
        end
        
        
        function [NickNames] =          getAllNicknames(obj)
            
             NickNames =                        cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);      
            
        end
        
        function [Movie] =              getMovieWithNickName(obj, Nickname)

            Nicknames =         obj.getAllNicknames;
            Row =               strcmp(Nicknames,Nickname);
            Movie  =            obj.ListhWithMovieObjects{Row};
            
        end
        
        function numberOfMovies =       getNumberOfMovies(obj)
            
            numberOfMovies =            size(obj.ListWithMovieObjectSummary,1);
            
        end
        
        
         function [SelectedMovie, obj] =     selectMovieObject(obj, NickNameString)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            ListWithCompleteMovieObjects =              obj.ListhWithMovieObjects;
            [MatchingNickNameRow] =                     obj.getSelectedRowInLibraryOf(NickNameString);
            SelectedMovie =                                 ListWithCompleteMovieObjects{MatchingNickNameRow,1};
            
         end
        
         function [MovieTracking] =         getActiveMovieTrackingFromFile(obj)
             
             MovieStructure.NickName =      obj.SelectedNickname;
             
             mainFolder =                   obj.getMainFolder;
             MovieTracking =                PMMovieTracking(MovieStructure, {obj.PathOfMovieFolder, mainFolder},1);
             
         end
         
         
         
        %% setters:
        
        function obj = loadMovieIntoListhWithMovieObjects(obj, NickName)
            
                MovieStructure.NickName =           NickName;
             
                mainFolder =                        obj.getMainFolder;
                MovieTracking =                     PMMovieTracking(MovieStructure, {obj.PathOfMovieFolder, mainFolder},1);
                
                [SelectedRow] =                     getSelectedRowInLibraryOf(obj,NickName);
                
                obj.ListhWithMovieObjects{SelectedRow,1} =      MovieTracking;
                
                
            
        end
        
          function obj = addSingleMovieToProject(obj, MovieStructure)
            
            
             [NewMovieObject]=                                                      PMMovieTracking(MovieStructure, obj.PathOfMovieFolder, 0); 
             
             numberOfMovies =                                                       obj.getNumberOfMovies;
            
             obj.ListWithMovieObjectSummary{numberOfMovies+1,1} =                   PMMovieTrackingSummary(NewMovieObject);
             obj.FilterList(numberOfMovies+1,1) =                                   true;
             obj.ListhWithMovieObjects{numberOfMovies+1,1} =                        NewMovieObject;
             obj.ListWithLoadedImageData{numberOfMovies+1,1} =                      cell(0,1);
             
            
          end
        
        
        
         function [obj] =           synchronizeMovieLibraryWithActiveMovie(obj, ActiveMovieController)
             
             
              %% put changes in currently edit movie back to library: not if the movie in active controller is empty (this happens when no movie could be loaded successfully): 
            if ~isempty(ActiveMovieController.LoadedMovie)
                

                % get row in library that corresponds to active movie 
                NickNameOfActiveMovie =                                                             ActiveMovieController.LoadedMovie.NickName;
                CurrentlyEditedRowInLibrary =                                                       obj.getSelectedRowInLibraryOf(NickNameOfActiveMovie);
                
                if sum(CurrentlyEditedRowInLibrary) == 0 % if the movie is not yet in the library, add it to the bottom of the current library
                    CurrentlyEditedRowInLibrary = size( obj.ListWithMovieObjectSummary,1) + 1;
                    
                   
                end
                
                % update library
                
                if isempty(ActiveMovieController.LoadedMovie.AttachedFiles)
                    return
                else
                    obj.ListWithMovieObjectSummary{CurrentlyEditedRowInLibrary,1} =        PMMovieTrackingSummary(ActiveMovieController.LoadedMovie);
                    obj.ListhWithMovieObjects{CurrentlyEditedRowInLibrary,1} =             ActiveMovieController.LoadedMovie;
                    obj.ListWithLoadedImageData{CurrentlyEditedRowInLibrary,1} =           ActiveMovieController.LoadedImageVolumes;

                    
                    
                end
                
               
            end
            
         end

         
        
        function [obj] =                addPostFixToFileName(obj,PostFix)
            
             [mainFolder,name,ext] =                           fileparts(obj.FileName);
            
             obj.FileName =         [mainFolder, '/', name,PostFix, ext];
        end
        
        function [obj] =                removeMovieFromLibrary(obj)
            
            SelectedRow =                                               obj.getSelectedRowInLibrary;

            obj.ListhWithMovieObjects(SelectedRow, :)=                  [];
            obj.ListWithMovieObjectSummary(SelectedRow, :)=             [];
            obj.FilterList(SelectedRow, :)=                             [];
            obj.ListWithLoadedImageData(SelectedRow, :) =               [];

            obj.SelectedNickname = '';


            
        end
        
        function [obj] =                sortByNickName(obj)
            

            AllNicknames =                                  cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj =                                           obj.sortAllMovieListsBy(AllNicknames);
            
            
            
            
        end
        
        function [obj] =                sortAllMovieListsBy(obj,SortList)
            
            if isempty(SortList)
                
               return 
            end
            
                obj.ListWithMovieObjectSummary(:,2) =            SortList;
                obj.ListWithMovieObjectSummary =                 sortrows(obj.ListWithMovieObjectSummary, 2);
                obj.ListWithMovieObjectSummary(:,2) =           [];

                
                FilterListTemp  =                               num2cell(obj.FilterList);
                FilterListTemp(:,2) =                           SortList;
                FilterListTemp =                                 sortrows(FilterListTemp, 2);
                FilterListTemp(:,2) =                           [];
                
                obj.FilterList =                            cell2mat(FilterListTemp);

                
                obj.ListhWithMovieObjects(:,2) =            SortList;
                obj.ListhWithMovieObjects =                 sortrows(obj.ListhWithMovieObjects, 2);
                obj.ListhWithMovieObjects(:,2) =           [];

                
                obj.ListWithLoadedImageData(:,2) =            SortList;
                obj.ListWithLoadedImageData =                 sortrows(obj.ListWithLoadedImageData, 2);
                obj.ListWithLoadedImageData(:,2) =           [];

             
     
        end
        
        function [obj] =                resetFolders(obj, Path)
            
            obj.ListhWithMovieObjects = cellfun(@(x) x.resetFolder(Path), obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            
            
        end
       
        

        
        
        function [obj] =                updateFilterSettingsFromPopupMenu(obj,PopupMenu,PopUpMenuTwo)
            
            %% first do general filter
                if ischar(PopupMenu.String)
                    SelectedString =  PopupMenu.String;
                else
                    SelectedString = PopupMenu.String{PopupMenu.Value};                                           
                end
                
                obj.FilterSelectionIndex =             PopupMenu.Value;
                obj.FilterSelectionString =            SelectedString;
                

                %% then do keyword-filter
                
                  if ischar(PopUpMenuTwo.String)
                    SelectedString =  PopUpMenuTwo.String;
                else
                    SelectedString = PopUpMenuTwo.String{PopUpMenuTwo.Value};                                           
                end
                
                 obj.KeywordFilterSelectionIndex =               PopUpMenuTwo.Value;
                obj.KeywordFilterSelectionString =              SelectedString;
                
                %% finalize filter:
                 obj =                                  obj.updateFilterList;
        
            
        end
        
        function [obj] =                updateFilterList(obj)
            
            
                     
                      
            SelectedString =        obj.FilterSelectionString;
            
              switch SelectedString
                    
                  case 'Show all movies'

                      obj.FilterList =                      cellfun(@(x) strcmp(x.DataType, 'Movie'), obj.ListWithMovieObjectSummary);
                    

                      
                  case 'Show all Z-stacks'
                      
                       obj.FilterList =                      cellfun(@(x) strcmp(x.DataType, 'ZStack'), obj.ListWithMovieObjectSummary);
                      
                  case 'Show all snapshots'
                      
                       obj.FilterList =                      cellfun(@(x) strcmp(x.DataType, 'Snapshot'), obj.ListWithMovieObjectSummary);
                       
                 case 'Show all tracked movies'
                     
                     FilterMovies =                         cellfun(@(x) strcmp(x.DataType, 'Movie'), obj.ListWithMovieObjectSummary);
                     FilterTracking =                       cellfun(@(x) x.TrackingWasPerformed, obj.ListWithMovieObjectSummary);
                      
                     obj.FilterList =                    min([FilterMovies FilterTracking], [], 2); 
                     
                    
                     
                  case 'Show all untracked movies'
                      
                      
                      FilterMovies =                         cellfun(@(x) strcmp(x.DataType, 'Movie'), obj.ListWithMovieObjectSummary);
                     FilterTracking =                       cellfun(@(x) ~x.TrackingWasPerformed, obj.ListWithMovieObjectSummary);
                      
                     obj.FilterList =                    min([FilterMovies FilterTracking], [], 2); 
                     

                 case 'Show all movies with drift correction'   
                     
                     obj.FilterList =                       cellfun(@(x) x.DriftCorrectionWasPerformed, obj.ListWithMovieObjectSummary);
                     
                    
                     
                 case 'Show entire content'
                     
                         obj.FilterList =                        cellfun(@(x) true, obj.ListWithMovieObjectSummary);             
           
                        
                        
                  case 'Show all unmapped movies'
                      
                        obj.FilterList =                       cellfun(@(x) ~x.MappingWasPerformed, obj.ListWithMovieObjectSummary);
                     

                        
          
                        
                  case 'Show content with non-matching channel information'
                      
                      obj.FilterList =                       cellfun(@(x) ~x.ChannelSettingsAreOk, obj.ListWithMovieObjectSummary);
                       

              end
              
              
            ListWithAllNickNamesInternal =              cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=              ListWithAllNickNamesInternal(obj.FilterList,:);

             
              
              
                       
                 
                        SelectedKeywordString =             obj.KeywordFilterSelectionString;
                        
                        switch SelectedKeywordString
                            
                            case 'Ignore keywords'
                                
                            case 'Movies with no keyword'
                                
                                
                                obj =                              obj.filterMoviesWithNoKeyWord;
                                
                                
                            otherwise
                                    
                                obj =                              obj.addKeywordFilter;
                            
                        end
                        
                        
            
            
        end
    
             
        function [obj] =                filterMoviesWithNoKeyWord(obj)
            
            
            rowsThatHaveNoKeyword =                                 cellfun(@(x) isempty(x.Keywords), obj.ListWithMovieObjectSummary);

            obj.FilterList  =                                       min([obj.FilterList rowsThatHaveNoKeyword], [], 2);

            ListWithAllNickNamesInternal =                          cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=                          ListWithAllNickNamesInternal(obj.FilterList,:);

        end
        
        
        function [obj] =                addKeywordFilter(obj)
            
            SelectedKeyword =                                       obj.KeywordFilterSelectionString;
            
             rowsThatHaveNoKeyword =                                cellfun(@(x) isempty(x.Keywords), obj.ListWithMovieObjectSummary);
 
            KeywordFilterList =                                     cellfun(@(x) max(strcmp(x.Keywords, SelectedKeyword)), obj.ListWithMovieObjectSummary, 'UniformOutput', false);
        
            KeywordFilterList(rowsThatHaveNoKeyword,:) =            {false};
            
            KeywordFilterList =                                     cell2mat(KeywordFilterList);
            
            obj.FilterList =                                        min([obj.FilterList,logical(KeywordFilterList)], [], 2);
            
            ListWithAllNickNamesInternal =                                  cellfun(@(x) x.NickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=                          ListWithAllNickNamesInternal(obj.FilterList,:);
           

            
        end

       

        function [obj] =                convertVersionTwoToThree(obj,ImagingProject)
            
            obj.PathOfMovieFolder =             ImagingProject.Files_MovieFolder;
            obj.PathForExport =                 ImagingProject.Files_DataExport;
            
            NumberOfMovies =                    size(ImagingProject.ListWithMovies,1);
            obj.ListhWithMovieObjects =         cell(NumberOfMovies,1);
            
            for MovieIndex=1:NumberOfMovies
                MovieStructure =                                ImagingProject.ListWithMovies(MovieIndex,1);
                obj.ListhWithMovieObjects{MovieIndex,1} =       PMMovieTracking(MovieStructure, ImagingProject.Files_MovieFolder, obj.Version);    
                
            end
                
            
        end

        
        
        
        function [obj] =                convertVersionThreeToFour(obj) 
            
            
            MainFolder =                                            obj.getMainFolder;
            numberOfMovies =                                        size(obj.ListhWithMovieObjects,1);
            
            for MovieIndex=1:numberOfMovies
              
                CurrentMovieObject =                                obj.ListhWithMovieObjects{MovieIndex,1};
                %CurrentMovieObject.Folder =                         MainFolder;
                CurrentMovieObject.FolderAnnotation =               MainFolder;
                
                CurrentMovieObjectSummary =                         PMMovieTrackingSummary(CurrentMovieObject);
                
                obj.ListWithMovieObjectSummary{MovieIndex,1} =      CurrentMovieObjectSummary;
                
                
                CurrentMovieObject.saveMovieData
                
            end
            
            obj.Version = 4;
            
            obj =                   obj.addPostFixToFileName('_Version4');
            obj =                   obj.saveMovieLibraryToFile;
            
        end
        
        
        
        
        %% file management:
        function obj =  saveMovieLibraryToFile(obj)
            
                ImagingProject =                        obj;
                CompletePathOfCurrentProject =          obj.FileName;

                %% store project:
                if exist('ImagingProject', 'var')== 1 && ~isempty(CompletePathOfCurrentProject)
                    
                        %% store imaging project in specified path:
                        numberOfMovies =                                    obj.getNumberOfMovies;
                        ImagingProject.ListhWithMovieObjects =              cell(numberOfMovies,1);
                        ImagingProject.ListWithLoadedImageData =            cell(numberOfMovies,1);% remove ListWithMovieObjects; these are now stored in separted files for each movies
                        save (CompletePathOfCurrentProject, 'ImagingProject')

                end
                
                
               % [obj] = synchronizeMovieLibraryWithActiveMovie(obj);
                
             
            
            
        end
        
       
        
    end
end

