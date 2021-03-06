classdef PMMovieLibrary
    %PMMOVIELIBRARY manage movies for tracking analysis
    %   Detailed explanation goes here
    
    properties
      
        
       
         
    end
    
    properties (Access = private)
        
        % files/folders:
        FileName =                                          '';
        PathForImageAnalysis
        PathOfMovieFolder
        PathForExport
         
        
        % other
        SelectedNickname =                                  ''

        ListWithMovieObjectSummary =                        cell(0,1); % summary of movie objects; this is stored in library file, and needed for example to filter files by movie vs. Z-stack etc;
        FilterList =                                        true

        ListWithFilteredNicknames

        FilterSelectionIndex =                              1;
        FilterSelectionString =                             ''

        KeywordFilterSelectionIndex =                       1;
        KeywordFilterSelectionString =                      'Ignore keywords';

        SortIndex =                                         1;

        ListhWithMovieObjects =                             cell(0,1); % list with complete information; this is stored in memory, not in library file; files are created for individual movie analyses
        ListWithLoadedImageData =                           cell(0,1);
        
        Version =                                           4;
    end
    
    methods
        
        function obj = PMMovieLibrary(varargin)
            
            NumberOfArguments = length(varargin);
            
            switch NumberOfArguments
                
                case 0
                    
                case 1
                    FileNameForLoadingNewObject = varargin{1};
                    fprintf('\nEnter @Create PMMovieLibrary: for path %s\n', FileNameForLoadingNewObject)
                    if (exist(FileNameForLoadingNewObject)==2)
                        fprintf('Path could be found: load PMMovieLibrary from file.\n')
                        load(FileNameForLoadingNewObject, 'ImagingProject');

                        if ~strcmp(class(ImagingProject), 'PMMovieLibrary')
                            obj.Version =                           2;
                        else
                            obj.Version =                           ImagingProject.Version;
                        end

                        switch obj.Version
                            case 4 
                                fprintf(' updating FileName, ')
                                obj =           ImagingProject;
                                obj.FileName =  FileNameForLoadingNewObject;
                            otherwise
                                error('Version of library not supported. Go to PMMovieLibraryVersion to convert library into current version.')
                        end
                    else
                       error('Invalid filename')
                    end

            
                otherwise
                    error('Wrong number of arguments')
            end

            obj.ListhWithMovieObjects =                             cell(obj.getNumberOfMovies, 1); % these two are not saved in file: initialize with right number of rows after loading;
            obj.ListWithLoadedImageData =                           cell(obj.getNumberOfMovies, 1);

            
        end
        
        %% accessors:
        function obj = setExportFolder(obj, Value)
           obj.PathForExport = Value; 
        end
        
         function obj = set.PathForExport(obj, Value)
             assert(ischar(Value), 'Wrong input.')
           obj.PathForExport = Value; 
         end
        
         function path = getExportFolder(obj)
              path = obj.PathForExport;
             
         end
        
        function list = getMovieObjectSummaries(obj)
            list = obj.ListWithMovieObjectSummary;
            
        end
        
        function nick = getSelectedNickname(obj)
           nick = obj.SelectedNickname; 
        end
        
          function obj = set.PathOfMovieFolder(obj, Value)
            if ischar(Value)
               Value = {Value}; 
            end
            assert(iscellstr(Value), 'Wrong input.')
            obj.PathOfMovieFolder = Value;
          end
        
          
          %% testThatPathForImageAnalysisExists
            function check = testThatPathForImageAnalysisExists(obj)
                check = ~isempty( obj.getPathForImageAnalysis);
            end
            
        %% getFilterList:
        function FilterList = getFilterList(obj)
           FilterList = obj.FilterList; 
        end
        
        
        function ListWithFilteredNicknames = getListWithFilteredNicknames(obj)
           ListWithFilteredNicknames = obj.ListWithFilteredNicknames; 
        end
        
        %% updateMovieSummariesFromFiles
        function obj = updateMovieSummariesFromFiles(obj)
            for MovieIndex=1:obj.getNumberOfMovies
                MovieStructure.NickName =                         obj.ListWithMovieObjectSummary{MovieIndex,1}.getNickName;
                obj.ListWithMovieObjectSummary{MovieIndex,1} =    PMMovieTrackingSummary(PMMovieTracking(MovieStructure, {obj.getMovieFolder, obj.getPathForImageAnalysis},1));
            end

        end
        
        function numberOfMovies =       getNumberOfMovies(obj)
            numberOfMovies =            size(obj.ListWithMovieObjectSummary,1);
        end
        
        function folder = getMovieFolder(obj)
              if ischar(obj.PathOfMovieFolder)
                  folder =          obj.PathOfMovieFolder;
              elseif iscellstr(obj.PathOfMovieFolder)
                  folder =      PMFolderManagement(obj.PathOfMovieFolder).getFirstValidFolder;
              else
                  folder = '';
                  warning('Invalid movie folder.')
              end
        end
        
         function mainFolder =           getPathForImageAnalysis(obj)
             
             if isempty(obj.PathForImageAnalysis)
                 error('Path for image analysis not specified.')
             else
                 mainFolder = obj.PathForImageAnalysis;  
             end
                
         end
        
        %% setFileName
        function obj = setFileName(obj, Value)
            obj.FileName = Value;
        end
        
         function obj = set.FileName(obj, Value)
            assert(ischar(Value), 'Wrong argument type.')
            obj.FileName = Value;
         end
         
         function value = getFileName(obj)
             value = obj.FileName;
         end
        
        %% change nickname:
        function obj = setNickName(obj, varargin)
            
            IndexOfMovie = obj.getIndexOfSelectedMovie;% because of name change this has to be done first;
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    Type = class(varargin{1});
                    switch Type
                        case 'char'
                                obj.SelectedNickname =   varargin{1};
                                obj.ListWithMovieObjectSummary{IndexOfMovie,1 } =  obj.ListWithMovieObjectSummary{IndexOfMovie,1 }.setNickName(varargin{1});
                                obj.ListhWithMovieObjects{IndexOfMovie,1 } =       obj.ListhWithMovieObjects{IndexOfMovie,1 }.setNickName(varargin{1});
                        case 'PMMovieController'
                                obj.SelectedNickname =      varargin{1}.getNickName;
                                 obj.ListWithMovieObjectSummary{IndexOfMovie,1 } =  obj.ListWithMovieObjectSummary{IndexOfMovie,1 }.setNickName(obj.SelectedNickname);
                                obj =                       obj.updateMovieListWith(varargin{1});
                    end
                    
                otherwise
                    error('Wrong input.')
                
            end   
        end
        
        function rowInLibrary = getIndexOfSelectedMovie(obj)
            rowInLibrary =     obj.getRowForNickName(obj.SelectedNickname);
        end
        
          function [SelectedRow] =                    getRowForNickName(obj, NickNameString)
                assert(ischar(NickNameString), 'Wrong input.')
                SelectedRow =                           strcmp(obj.getAllNicknames, NickNameString);
                assert(sum(SelectedRow) == 1, 'Non-unique nickname chosen.')
          end
         
        function obj = setNewNickname(obj, Value)
            obj.SelectedNickname =      Value;
        end

        function obj = set.SelectedNickname(obj, Value)
            assert((ischar(Value) && obj.getNumberOfNickNameMatchesForString(Value) <= 1), 'Invalid nickname entered, potentially not unique. Try other nickname.')
            obj.SelectedNickname = Value;
        end
        
        function check = testForPreciselyOneNickNameMatchForString(obj, String)
            numberOfMatches = obj.getNumberOfNickNameMatchesForString(String);
             if numberOfMatches == 1
                check = true;
            else
               check = false; 
             end
             
        end
        
        function numberOfMatches = getNumberOfNickNameMatchesForString(obj, String)
            assert(ischar(String), 'Wrong argument type.')
            NickNames = obj.getAllNicknames;
            if isempty(NickNames)
                numberOfMatches = 0;
            else
                numberOfMatches =   sum(strcmp(String, NickNames));
            end
        end
        
      function [NickNames] =          getAllNicknames(obj)
         NickNames =       cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);      
      end
        
      function    listWithAllWantedNickNames =       getAllFilteredNicknames(obj)
            listWithAllNicknames =              obj.getAllNicknames;
            listWithAllWantedNickNames =        listWithAllNicknames(obj.getFilterList,:); 
      end
      
      
        %% addNewEntryIntoLibrary:
          function obj = addNewEntryIntoLibrary(obj, NickName, AttachedFilenames)
                 obj = obj.addNewEntryIntoLibraryInternal(NickName, AttachedFilenames);
          end
          
          
     
       %% switchActiveMovieByNickName:
         function obj = switchActiveMovieByNickName(obj, Value)
            assert(sum(obj.getRowForNickName(Value)) == 1, 'Chosen nickname is not unique')
            obj =                   obj.setNewNickname(Value);
            
            myMovieTracking=        obj.getFinalizedMovieTrackingOfActiveMovie;
            myMovieTracking =       myMovieTracking.setNickName(Value);
            myMovieTracking =       myMovieTracking.setMovieFolder(obj.getMovieFolder);
            
            obj =                   obj.setActiveEntryOfMovieList(myMovieTracking);

         end
         
        function [myMovieTracking]=     getFinalizedMovieTrackingOfActiveMovie(obj)
            myMovieTracking =      obj.getMovieTrackingOfActiveMovie;
            if isempty(myMovieTracking)
                myMovieTracking =   obj.getInitializedMovieTracking;
                myMovieTracking =   myMovieTracking.loadHardLinkeDataFromFile;
            end
            myMovieTracking =   myMovieTracking.finalizeMovieTracking;
        end
        
        function MovieTracking = getMovieTrackingOfActiveMovie(obj)
            MovieTracking =           obj.ListhWithMovieObjects{obj.getSelectedRowInLibrary,1};
        end

         function obj = setActiveEntryOfMovieList(obj, Value)
              assert(isa(Value, 'PMMovieTracking'), 'Wrong type.')
              obj.ListhWithMovieObjects{obj.getIndexOfSelectedMovie, 1} =        Value;
         
         end
         
    
         
         %% remove active entry:
         function obj = removeActiveMovieFromLibrary(obj)
             if isempty(obj.SelectedNickname)
                 fprintf('No active movie selected. Removal not possible.\n')
             else
                 obj =          obj.removeFromLibraryMovieWithNickName(obj.SelectedNickname);
                 
             end
         end
                 
        function [obj] =                removeFromLibraryMovieWithNickName(obj, NickName)
            SelectedRow =               obj.getRowForNickName(NickName);
            obj =                       obj.clearContentsOfLibraryIndex(SelectedRow);
            obj.SelectedNickname =      '';
            
        end
        
        function obj = clearContentsOfLibraryIndex(obj, index)
            obj.ListhWithMovieObjects(index, :)=          [];
            obj.ListWithMovieObjectSummary(index, :)=     [];
            obj.FilterList(index, :)=                     [];
            obj.ListWithLoadedImageData(index, :) =       [];
        end
        
        %% get active movie controller:
        function myMovieController = getActiveMovieController(obj, myView)
            fprintf('PMMovieLibraryManager:@getActiveMovieController: ')
             myMovieController =     PMMovieController(myView);
            if isempty(obj.ListhWithMovieObjects) || isempty(obj.SelectedNickname)
               
            else
                myMovieController =     myMovieController.setMovieTracking(obj.getFinalizedMovieTrackingOfActiveMovie);  
                myMovieController =     myMovieController.setLoadedImageVolumes(obj.getLoadedImageDataOfActiveMovie); 
                myMovieController =     myMovieController.finalizeMovieController;
                
            end
           
        end
        

          
        %% delete all entries:          
        function obj = deleteAllEntriesFromLibrary(obj)
             obj =                       obj.clearContentsOfLibraryIndex(1:obj.getNumberOfMovies);
             obj.SelectedNickname =      '';
        end
        
        %% get keywords:
         function KeywordList =          getKeyWordList(obj)
              ListWithKeywords =               cellfun(@(x) x.Keywords, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
              FinalList =                      (vertcat([ListWithKeywords{:}]))';
                if ~isempty(FinalList)
                    EmptyRows=                 cellfun(@(x) isempty(x),FinalList);
                    FinalList(EmptyRows,:)=    [];  
                     KeywordList=              unique(FinalList);
                else
                    KeywordList =   '';
                end
         end
        
        function [SelectedRow] =                    getSelectedRowInLibrary(obj)
            ListWithAllNickNamesInternal =          cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);   
            SelectedRow =                           strcmp(ListWithAllNickNamesInternal, obj.SelectedNickname);
        end
        
      
        
        
 
        
      
 
        function NickName = getNickNameOfActiveMovie(obj)
            NickName = obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.getNickName;
        end
        
        function NickName = getKeywordsOfActiveMovie(obj)
            NickName = obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.Keywords;
        end
        
        function NickName = getAttachedImageSourceOfActiveMovie(obj)
            NickName = obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.AttachedFiles;
        end
         
        function ImageData = getLoadedImageDataOfActiveMovie(obj)
            ImageData = obj.ListWithLoadedImageData{obj.getSelectedRowInLibrary, 1};
        end
          
          
        
        function [Movie] =              getMovieWithNickName(obj, Nickname)
            Movie  =      obj.ListhWithMovieObjects{strcmp(obj.getAllNicknames, Nickname)};    
        end
        

    
        
   
        
        %% replace keywords:
        function obj = replaceKeywords(obj, SourceKeyword, TargetKeyword)
            for MovieIndex=1:obj.getNumberOfMovies
                CurrentKeyword =      obj.ListWithMovieObjectSummary{MovieIndex,1}.Keywords{1,1};
                if strcmp(CurrentKeyword, SourceKeyword)
                    
                    obj.ListWithMovieObjectSummary{MovieIndex,1}.Keywords{1,1} = TargetKeyword;
                     if ~isempty(obj.ListhWithMovieObjects{MovieIndex,1})
                        obj.ListhWithMovieObjects{MovieIndex,1} = obj.ListhWithMovieObjects{MovieIndex,1}.setKeywords(TargetKeyword);
                     end
                    
                    MovieStructure.NickName =  obj.ListWithMovieObjectSummary{MovieIndex,1}.getNickName;
                    newMovieTracking =         PMMovieTracking(MovieStructure, {obj.getMovieFolder, obj.getPathForImageAnalysis},1);
                    newMovieTracking =          newMovieTracking.setKeywords(TargetKeyword);
                    newMovieTracking.saveMovieDataWithOutCondition; 
                
                end
                
            end
            
            
            
        end
        
        function obj = loadMovieIntoListhWithMovieObjects(obj, NickName)
                MovieStructure.NickName =                       NickName;
                obj.ListhWithMovieObjects{obj.getRowForNickName(NickName), 1} =      PMMovieTracking(MovieStructure, {obj.getMovieFolder, obj.getPathForImageAnalysis},1);  
        end
        
         
        


        
        function [obj] =                sortByNickName(obj)
            AllNicknames =         cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj =                  obj.sortAllMovieListsBy(AllNicknames);  
        end
        
        function [obj] =                sortAllMovieListsBy(obj, SortList)
            
            if isempty(SortList)
            else
                
                obj.ListWithMovieObjectSummary(:,2) =     SortList;
                obj.ListWithMovieObjectSummary =          sortrows(obj.ListWithMovieObjectSummary, 2);
                obj.ListWithMovieObjectSummary(:,2) =     [];

                FilterListTemp  =                       num2cell(obj.FilterList);
                FilterListTemp(:,2) =                   SortList;
                FilterListTemp =                        sortrows(FilterListTemp, 2);
                FilterListTemp(:,2) =                   [];
                obj.FilterList =                            cell2mat(FilterListTemp);

                obj.ListhWithMovieObjects(:,2) =            SortList;
                obj.ListhWithMovieObjects =                 sortrows(obj.ListhWithMovieObjects, 2);
                obj.ListhWithMovieObjects(:,2) =           [];

                obj.ListWithLoadedImageData(:,2) =            SortList;
                obj.ListWithLoadedImageData =                 sortrows(obj.ListWithLoadedImageData, 2);
                obj.ListWithLoadedImageData(:,2) =           [];
            end

        end
        
    
        
        function obj = setPathForImageAnalysis(obj, Value)
           assert(ischar(Value), 'Wrong argument type.')
           obj.PathForImageAnalysis = Value;
        end
       
        

        
        
        function [obj] =                updateFilterSettingsFromPopupMenu(obj, PopupMenu, PopUpMenuTwo)
            
                if ischar(PopupMenu.String)
                    SelectedString =  PopupMenu.String;
                else
                    SelectedString =  PopupMenu.String{PopupMenu.Value};                                           
                end
                
                obj.FilterSelectionIndex =             PopupMenu.Value;
                obj.FilterSelectionString =            SelectedString;
                
                if ischar(PopUpMenuTwo.String)
                    SelectedString =  PopUpMenuTwo.String;
                else
                    SelectedString = PopUpMenuTwo.String{PopUpMenuTwo.Value};                                           
                end
                
                obj.KeywordFilterSelectionIndex =               PopUpMenuTwo.Value;
                
                
                obj.KeywordFilterSelectionString =              SelectedString;
                
                 obj =                                  obj.updateFilterList;
        
            
        end
        
        
        function FilterSelectionIndex = getFilterSelectionIndex(obj)
           FilterSelectionIndex = obj.FilterSelectionIndex; 
        end
        
        function [obj] =                updateFilterList(obj)
            
              switch obj.FilterSelectionString
                  case 'Show all movies'
                      obj.FilterList =        cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.ListWithMovieObjectSummary);
                  case 'Show all Z-stacks'
                       obj.FilterList =       cellfun(@(x) strcmp(x.getDataType, 'ZStack'), obj.ListWithMovieObjectSummary);
                  case 'Show all snapshots'
                       obj.FilterList =       cellfun(@(x) strcmp(x.getDataType, 'Snapshot'), obj.ListWithMovieObjectSummary);
                 case 'Show all tracked movies'
                     FilterMovies =           cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.ListWithMovieObjectSummary);
                     FilterTracking =         cellfun(@(x) x.getTrackingWasPerformed, obj.ListWithMovieObjectSummary);
                     obj.FilterList =         min([FilterMovies FilterTracking], [], 2); 
    
                  case 'Show all untracked movies'
                     FilterMovies =        cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.ListWithMovieObjectSummary);
                     FilterTracking =      cellfun(@(x) ~x.getTrackingWasPerformed, obj.ListWithMovieObjectSummary);
                     obj.FilterList =      min([FilterMovies FilterTracking], [], 2); 
                     
                 case 'Show all movies with drift correction'   
                     obj.FilterList =                       cellfun(@(x) x.DriftCorrectionWasPerformed, obj.ListWithMovieObjectSummary);
                     
                 case 'Show entire content'
                        obj.FilterList =                        cellfun(@(x) true, obj.ListWithMovieObjectSummary);             
           
                  case 'Show all unmapped movies'
                        obj.FilterList =                       cellfun(@(x) ~x.MappingWasPerformed, obj.ListWithMovieObjectSummary);

                  case 'Show content with non-matching channel information'
                      obj.FilterList =                       cellfun(@(x) ~x.ChannelSettingsAreOk, obj.ListWithMovieObjectSummary);

              end
              
            ListWithAllNickNamesInternal =              cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=              ListWithAllNickNamesInternal(obj.FilterList,:);
                switch obj.KeywordFilterSelectionString
                    case 'Ignore keywords'
                    case 'Movies with no keyword'
                        obj =          obj.filterMoviesWithNoKeyWord;
                    otherwise
                        obj =          obj.addKeywordFilter;
                end
  
        end
    
        
        
             
        function [obj] =                filterMoviesWithNoKeyWord(obj)
            function check = keyWordCheck(keywords)
                if isempty(keywords) 
                    check = false;
                elseif isempty(keywords{1,1})
                    check = false;
                else
                    check = true;
                end
            end

            rowsThatHaveNoKeyword =        cellfun(@(x) ~keyWordCheck(x.Keywords), obj.ListWithMovieObjectSummary);
            obj.FilterList  =              min([obj.FilterList rowsThatHaveNoKeyword], [], 2);

            ListWithAllNickNamesInternal =   cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=   ListWithAllNickNamesInternal(obj.FilterList,:);

        end
        
        
        function [obj] =                addKeywordFilter(obj)

            rowsThatHaveNoKeyword =                                cellfun(@(x) isempty(x.Keywords), obj.ListWithMovieObjectSummary);
            KeywordFilterList =                                     cellfun(@(x) max(strcmp(x.Keywords, obj.KeywordFilterSelectionString)), obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            KeywordFilterList(rowsThatHaveNoKeyword,:) =            {false};
            
            KeywordFilterList =                                     cell2mat(KeywordFilterList);
            obj.FilterList =                                        min([obj.FilterList,logical(KeywordFilterList)], [], 2);
            ListWithAllNickNamesInternal =                                  cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=                          ListWithAllNickNamesInternal(obj.FilterList,:);
           

            
        end


        function obj =  saveMovieLibraryToFile(obj)
            
            fprintf('PMMovieLibrary:@saveMovieLibraryToFile: ')
            fprintf('Create copy of library, ')
            ImagingProject =                        obj;
            if exist('ImagingProject', 'var')== 1 && ~isempty(obj.FileName)
                    fprintf(' remove non-essential data, ')
                    ImagingProject.ListhWithMovieObjects =              cell(obj.getNumberOfMovies,1);
                    ImagingProject.ListWithLoadedImageData =            cell(obj.getNumberOfMovies,1);% remove ListWithMovieObjects; these are now stored in separted files for each movies
                    fprintf(' save library in path "%s".\n', obj.FileName)
                    save (obj.FileName, 'ImagingProject')
            else
                warning('Library could not be saved. Reason: either the library did not exist or no file-path was specified')
            end

        end
        
        %% askUserToSelectMovieFileNames
           function [ListWithSelectedFileNames] =             askUserToSelectMovieFileNames(obj)
                fprintf('Enter: PMMovieLibraryManager:@askUserToSelectMovieFileNames:\n')
                assert(exist(obj.getMovieFolder) == 7, 'No valid movie folder available. You must first choose a valid movie-folder.')

                cd(obj.getMovieFolder);
                UserSelectedFileNames=           uipickfiles;
                if ~iscell(UserSelectedFileNames)
                    fprintf('User decided to cancel entry. No files selected.\nExit: PMMovieLibraryManager:@askUserToSelectMovieFileNames.\n\n')
                    ListWithSelectedFileNames = cell(0, 1);
                else

                    FolderWasSelected =     unique(cellfun(@(x) isfolder(x), UserSelectedFileNames));
                    if length(FolderWasSelected) ~=1
                       error('You must select only folders (e.g. containing pic-files) or only files (e.g. TIFF, lsm, or czi), but not a mix of the two.') 
                    else
                        
                        if FolderWasSelected
                            fprintf('Folder(s) were selected. Pic files are extracted from the folder(s).\n')
                            ExtracetedInformation =       (cellfun(@(x) PMImageBioRadPicFolder(x), UserSelectedFileNames, 'UniformOutput', false))';
                            ListWithFiles =               cellfun(@(x) x.FileNameList(:,1), ExtracetedInformation,  'UniformOutput', false);
                            ListWithSelectedFileNames =      vertcat(ListWithFiles{:});
                        else
                            fprintf('User directly selected files of interest.\n')
                            [~, file, ext]  =             cellfun(@(x) fileparts(x), UserSelectedFileNames, 'UniformOutput', false);
                            ListWithSelectedFileNames =      (cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false))';
                        end
                        
                        fprintf('Add files: ')
                        cellfun(@(x) fprintf('%s ', x), ListWithSelectedFileNames)
                        fprintf('Exit: PMMovieLibraryManager:@askUserToSelectMovieFileNames.\n\n')
                    end
                end    
           end
           
           %% askUserToEnterUniqueNickName
               function [ Nickname ] =     askUserToEnterUniqueNickName(obj)
                Nickname=               inputdlg('For single or pooled movie sequence','Enter nickname');
                if isempty(Nickname)
                else
                    Nickname=           Nickname{1,1};
                    if isempty(Nickname)
                    else
                         Nickname =     obj.deleteNonUniqueNickName(Nickname);    
                    end
                end
           end
          
            function CandidateNickName =   deleteNonUniqueNickName(obj, CandidateNickName)
                NickNames =          obj.getAllNicknames;
                if ~isempty(find(strcmp(CandidateNickName, NickNames), 1))
                    CandidateNickName = '';
                end
            end
            
         
          
       
         %% get info text:   
        function InfoText = getProjectInfoText(obj)
            FileNameOfProject{1,1}=             'Filename of current project:';
            FileNameOfProject{2,1}=             obj.FileName;
            FileNameOfProject{3,1}=             '';

            FolderWithMovieFiles{1,1}=          'Linked folder with movie files:';
            FolderWithMovieFiles{2,1}=          obj.getMovieFolder;
            FolderWithMovieFiles{3,1}=          '';
            
            AllMovieFolders{1,1} =      'Names of all possible movie folders:';
       
            AllMovieFolders =           [AllMovieFolders;  obj.PathOfMovieFolder; ' '];

            PathForDataExport{1,1}=             'Folder for data export:';
            PathForDataExport{2,1}=             obj.PathForExport;
            PathForDataExport{3,1}=             '';

            AnnotationFolder{1,1}=             'Annotation folder:';
            AnnotationFolder{2,1}=             obj.getPathForImageAnalysis;
            AnnotationFolder{3,1}=             '';
            InfoText=                          [FileNameOfProject;AllMovieFolders;  FolderWithMovieFiles; PathForDataExport; AnnotationFolder];
        end

        function files = getAttachedMoviePathsForEachEntry(obj)
            if isempty(obj.ListWithMovieObjectSummary)
                files = cell(0,1);
            else
                files =          cellfun(@(x) x.AttachedFiles, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            end

        end
        
        function files = getAllAttachedMoviePaths(obj)
            files =         obj.getAttachedMoviePathsForEachEntry;
            files=          vertcat(files{:});
            if isempty(files)
               files = cell(0,1); 
            end
        end
        
        function names = getAllAttachedMovieFileNames(obj)
            allPaths = obj.getAllAttachedMoviePaths;
                [~, file, ext]  =                cellfun(@(x) fileparts(x), allPaths, 'UniformOutput', false);
                names =          cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false);   
        end
        
        function [namesOfAvailableFiles] =  getFileNamesOfUnincorporatedMovies(obj)
            namesOfAvailableFiles =    PMFileManagement(obj.getMovieFolder).getFileNames;
            alreadyAddedFileNames =     obj.getAllAttachedMovieFileNames;
            if isempty(alreadyAddedFileNames)
                
            else
                MatchingRows=                    cellfun(@(x) max(strcmp(x, alreadyAddedFileNames)), namesOfAvailableFiles);
                namesOfAvailableFiles(MatchingRows,:)=    [];
            end
            
        end
         
                   
          function folders = getNamesOfAllMovieFolders(obj) 
            folders = obj.PathOfMovieFolder;
          end
        
             
          
          
            %% updateMovieListWith
            function obj = updateMovieListWith(obj, MovieController)
                obj =           obj.updateMovieListWithMovieController(MovieController);


            end
          
            %% setMovieFolders
               function obj = setMovieFolders(obj, Value)
           obj.PathOfMovieFolder =  Value;
           obj =                    obj.setMovieFolderInMovieObjectSummaries; 
        end
        
        function obj = addMovieFolder(obj, Value)
            
            assert(ischar(Value), 'Wrong input.')
            OldFolders =       obj.getNamesOfAllMovieFolders;
            NewFolders =    [OldFolders; Value];
            obj.PathOfMovieFolder = NewFolders;
            obj =                    obj.setMovieFolderInMovieObjectSummaries; 
        end
        
           
    end
    
    methods (Access = private)
        
        
          %% addNewEntryIntoLibraryInternal
          function obj = addNewEntryIntoLibraryInternal(obj, NickName, AttachedFilenames)
              newMovieTrackingSummary =        obj.getInitializedMovieTrackingSummaryWithNickNameAndAttachedFiles(NickName, AttachedFilenames); 
         
                index =                                         obj.getNumberOfMovies + 1;
                obj.ListhWithMovieObjects{index, 1}=            obj.getMovieTrackingForMovieTrackingSummary(newMovieTrackingSummary);
                obj.ListWithMovieObjectSummary{index, 1}=       newMovieTrackingSummary;
                obj.FilterList(index, 1)=                       true;
                obj.ListWithLoadedImageData{index, 1} =         '';
              
          end
          
            function myMovieTrackingSummary = getInitializedMovieTrackingSummaryWithNickNameAndAttachedFiles(obj, NickName, AttachedFilenames)
                assert(obj.verifyStringIsNotUsedAsNickName(NickName) && obj.testForExistenceOfMovieFiles(AttachedFilenames), 'Invalid content for movie entry.')
                myMovieTrackingSummary =        PMMovieTrackingSummary;
                myMovieTrackingSummary =        myMovieTrackingSummary.setMovieFolder(obj.getMovieFolder);                
                myMovieTrackingSummary =        myMovieTrackingSummary.setNickName(NickName);               
                myMovieTrackingSummary =        myMovieTrackingSummary.setNamesOfMovieFiles(AttachedFilenames);
            end

        function check = verifyStringIsNotUsedAsNickName(obj, String)
            numberOfMatches = obj.getNumberOfNickNameMatchesForString(String);
            if numberOfMatches == 0
                check = true;
            else
               check = false; 
            end

        end
        
        function check = testForExistenceOfMovieFiles(obj, Files)
            assert(iscellstr(Files), 'Wrong argument type.')

            NumberOfFiles =     length(Files);
            checks = zeros(NumberOfFiles, 1);
            for FileIndex = 1:NumberOfFiles
                checks(FileIndex) = fopen([obj.getMovieFolder '/' Files{FileIndex}]);
            end

            result = min(checks);
            if result == -1
                check = false;
            else
                check = true;
            end

        end
        
        function newMovieTracking = getMovieTrackingForMovieTrackingSummary(obj, newMovieTrackingSummary)
            newMovieTracking =      PMMovieTracking(newMovieTrackingSummary);
            newMovieTracking =      newMovieTracking.setImageAnalysisFolder(obj.getPathForImageAnalysis);
            newMovieTracking =      newMovieTracking.finalizeMovieTracking;
            newMovieTracking =      newMovieTracking.saveMovieDataWithOutCondition;
        end
          
        
     
            
       

        function obj = setMovieFolderInMovieObjectSummaries(obj)
            obj.ListWithMovieObjectSummary =    cellfun(@(x) x.setMovieFolder(obj.getMovieFolder), obj.ListWithMovieObjectSummary, 'UniformOutput', false);
        end
        
        
        
        
         %% save and synchronize MovieTracking
        function [obj] =           updateMovieListWithMovieController(obj, ActiveMovieController)
            
            if isempty(ActiveMovieController.getLoadedMovie)
                fprintf('ActiveMovieController has no valid LoadedMovie: therefore no action taken.\n')
            elseif isempty(ActiveMovieController.getLoadedMovie.getLinkedMovieFileNames)
                 error('LoadedMovie of ActiveMovieController has no AttachedFiles: this needs to be fixed.\n')
            else

                SelectedRow =                   obj.getRowForNickName(ActiveMovieController.getLoadedMovie.getNickName);
                obj.ListWithMovieObjectSummary{SelectedRow,1} =     PMMovieTrackingSummary(ActiveMovieController.getLoadedMovie);
                obj.ListhWithMovieObjects{SelectedRow,1} =          ActiveMovieController.getLoadedMovie;
                obj.ListWithLoadedImageData{SelectedRow,1} =        ActiveMovieController.getLoadedImageVolumes;
 
            end
            fprintf('Exit PMMovieLibrary:@updateMovieListWithMovieController.\n')
 
        end
        
         

       
          
            function myMovieTracking = getInitializedMovieTracking(obj)
                obj =                   obj.verifyThatAllFoldersAreSpecified;
                myMovieTracking =       PMMovieTracking;
                myMovieTracking =       myMovieTracking.setImageAnalysisFolder(obj.getPathForImageAnalysis);
                myMovieTracking =       myMovieTracking.setMovieFolder(obj.getMovieFolder);
                myMovieTracking =       myMovieTracking.setNickName(obj.getNickNameOfActiveMovie);
                myMovieTracking =       myMovieTracking.setKeywords(obj.getKeywordsOfActiveMovie); 
                myMovieTracking =       myMovieTracking.setNamesOfMovieFiles(obj.getAttachedImageSourceOfActiveMovie);
           end

          function obj = verifyThatAllFoldersAreSpecified(obj)
         

               if isempty( obj.getNickNameOfActiveMovie)
                   error('Nickname empty.')
               end
          end
          
       
         
        
    end
end

