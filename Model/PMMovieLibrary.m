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
       
        ListhWithMovieObjects =                             cell(0,1); % list with complete information; this is stored in memory, not in library file; files are created for individual movie analyses
        ListWithLoadedImageData =                           cell(0,1);
        
        Version =                                           4;
        
    end
    
    properties (Access = private) % filter:
        
         FilterList =                                        true

        ListWithFilteredNicknames

        FilterSelectionIndex
        FilterSelectionString =                             ''

        KeywordFilterSelectionIndex =                       1;
        KeywordFilterSelectionString =                      'Ignore keywords';

        SortIndex =                                         1;
     

    end
    
    methods % initialize
        
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
                    
                case 4
                    
                    
                        obj.FileName =              varargin{1};
                        obj.PathForImageAnalysis =  varargin{2};
                        obj.PathOfMovieFolder =     varargin{3};
                        obj.PathForExport=          varargin{4};
            
                otherwise
                    error('Wrong number of arguments')
            end

            obj.ListhWithMovieObjects =                             cell(obj.getNumberOfMovies, 1); % these two are not saved in file: initialize with right number of rows after loading;
            obj.ListWithLoadedImageData =                           cell(obj.getNumberOfMovies, 1);

            
         end
         
         function obj = set.PathForImageAnalysis(obj, Value)
            obj.PathForImageAnalysis = Value; 
         end
         
        function obj = set.PathForExport(obj, Value)
            assert(ischar(Value), 'Wrong input.')
            obj.PathForExport = Value; 
        end

        function obj = set.PathOfMovieFolder(obj, Value)
            if ischar(Value)
            Value = {Value}; 
            end
            assert(iscellstr(Value), 'Wrong input.')
            obj.PathOfMovieFolder = Value;
        end

        function obj = set.FileName(obj, Value)
            assert(ischar(Value), 'Wrong argument type.')
            obj.FileName = Value;
        end
        
        function obj = set.SelectedNickname(obj, Value)
            assert((ischar(Value) && obj.getNumberOfNickNameMatchesForString(Value) <= 1), 'Invalid nickname entered, potentially not unique. Try other nickname.')
            obj.SelectedNickname = Value;
        end
        
  
    end
    
    methods % setters
        
        function obj = setExportFolder(obj, Value)
            obj.PathForExport = Value; 
        end

        function obj = setFileName(obj, Value)
            obj.FileName = Value;
        end

        function obj = setNickName(obj, varargin)

            IndexOfMovie = obj.getIndexOfSelectedMovie;% because of name change this has to be done first;

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    Type = class(varargin{1});
                    switch Type
                        case 'char'
                                obj.SelectedNickname =                              varargin{1};
                                obj.ListWithMovieObjectSummary{IndexOfMovie,1 } =   obj.ListWithMovieObjectSummary{IndexOfMovie,1 }.setNickName(varargin{1});
                                obj.ListhWithMovieObjects{IndexOfMovie,1 } =        obj.ListhWithMovieObjects{IndexOfMovie,1 }.setNickName(varargin{1});
                                
                        case 'PMMovieController'
                                obj.SelectedNickname =      varargin{1}.getNickName;
                                 obj.ListWithMovieObjectSummary{IndexOfMovie,1 } =  obj.ListWithMovieObjectSummary{IndexOfMovie,1 }.setNickName(obj.SelectedNickname);
                              obj =           obj.updateMovieListWithMovieController(varargin{1});

                    end

                otherwise
                    error('Wrong input.')

            end   
        end

   

        function obj = setPathForImageAnalysis(obj, Value)
            obj.PathForImageAnalysis =      Value;
            obj =              obj.saveMovieLibraryToFile;
           
        end

         function obj = addNewEntryIntoLibrary(obj, NickName, AttachedFilenames)
             obj = obj.addNewEntryIntoLibraryInternal(NickName, AttachedFilenames);
        end

          
    
    
          %% replace keywords:
        function obj = replaceKeywords(obj, SourceKeyword, TargetKeyword)
            % REPLACEKEYWORDS: replaces keywords in movie-library entries;
            % takes two arguments: 1: source keyword 2: target keyword that should be used as a replacement;
            % mehod goes through each entry and tests if the keyword matches the source keyword;
            % if this is the case: change movie summaries, movie objects and also load and store the revised files (this means that for large files the process could be slow);
            for MovieIndex = 1 : obj.getNumberOfMovies

                CurrentKeywords =      obj.ListWithMovieObjectSummary{MovieIndex,1}.getKeywords;
                if isempty(CurrentKeywords)
                    CurrentKeyword = '';
                else
                    CurrentKeyword = CurrentKeywords{1,1};
                end
                
                if  ~isempty(CurrentKeyword) && strcmp(CurrentKeyword, SourceKeyword) 

                    obj.ListWithMovieObjectSummary{MovieIndex,1} =  obj.ListWithMovieObjectSummary{MovieIndex,1}.setKeywords(TargetKeyword);
                     if ~isempty(obj.ListhWithMovieObjects{MovieIndex,1})
                        obj.ListhWithMovieObjects{MovieIndex,1} = obj.ListhWithMovieObjects{MovieIndex,1}.setKeywords(TargetKeyword);
                     end
                    
                    MovieStructure.NickName =  obj.ListWithMovieObjectSummary{MovieIndex,1}.getNickName;
                    newMovieTracking =         PMMovieTracking(MovieStructure, {obj.getMovieFolder, obj.getPathForImageAnalysis}, 1);
                    newMovieTracking =          newMovieTracking.setKeywords(TargetKeyword);
                    newMovieTracking.save; 
                
                end
                
            end
            
        end
        
      
         %% delete all entries:          
        function obj = deleteAllEntriesFromLibrary(obj)
             obj =                       obj.clearContentsOfLibraryIndex(1:obj.getNumberOfMovies);
             obj.SelectedNickname =      '';
        end
        
        
        
         
    end
    
    methods % remove active entry:
       
         function obj = removeActiveMovieFromLibrary(obj)
             obj =          obj.removeFromLibraryMovieWithNickName(obj.SelectedNickname);
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
        
        
        
    end
    
    methods % switch active movie
       
        function obj = setAllMovies(obj)
            ListWithNickNames = obj.getAllNicknames;
            
            for index = 1 : length(ListWithNickNames)
                obj = obj.switchActiveMovieByNickName(ListWithNickNames{index});
                
            end 
            
        end
        
        
          function obj = switchActiveMovieByNickName(obj, Value, varargin)
              
                assert(sum(obj.getRowForNickName(Value)) == 1, 'Chosen nickname is not unique')
                obj =                   obj.setNewNickname(Value);

                if isempty(varargin)
                    myMovieTracking=        obj.getFinalizedMovieTrackingOfActiveMovie;
                    myMovieTracking =       myMovieTracking.setNickName(Value);
                    myMovieTracking =       myMovieTracking.setMovieFolder(obj.getMovieFolder);
                    
                elseif strcmp(varargin{1}, 'DoNotLoadSourceData')
                    myMovieTracking =       obj.getInitializedMovieTracking;

                else
                    error('Input not supported')
                end

                 assert((isa(myMovieTracking, 'PMMovieTracking')) && isscalar(myMovieTracking), 'Wrong input.')

                 obj.ListhWithMovieObjects{obj.getIndexOfSelectedMovie, 1} =        myMovieTracking;

          end
         
      
        
         
        
        
    end
    
    methods % get movie-controller of active movie:
        
        function myMovieController = getActiveMovieController(obj, varargin)
            fprintf('PMMovieLibraryManager:@getActiveMovieController: ')

            assert(~isempty(obj.ListhWithMovieObjects) && ~isempty(obj.SelectedNickname), 'Cannot create movie controller, because library has nof information about movies.')  
            switch length(varargin)
               
                case 0
                    myMovieController =     PMMovieController(obj.getFinalizedMovieTrackingOfActiveMovie);
                case 1
                    myMovieController =     PMMovieController(varargin{1}, obj.getFinalizedMovieTrackingOfActiveMovie);
                    
                otherwise
                    error('Wrong input.')
                
            end
            
            myMovieController =     myMovieController.setLoadedImageVolumes(obj.getLoadedImageDataOfActiveMovie); 
            myMovieController =     myMovieController.setExportFolder(obj.getExportFolder);
            myMovieController =     myMovieController.setInteractionsFolder(obj.getInteractionFolder);
            myMovieController =     myMovieController.initializeViews;
           
        end
         
       function [myMovieTracking]=     getFinalizedMovieTrackingOfActiveMovie(obj)
            
            myMovieTracking =           obj.ListhWithMovieObjects{obj.getSelectedRowInLibrary,1};
            if isempty(myMovieTracking)
                myMovieTracking =   obj.getInitializedMovieTracking;
                myMovieTracking =   myMovieTracking.load;
            end
                 
        end
        
          function myMovieTracking = getInitializedMovieTracking(obj)
                % GETINITIALIZEDMOVIETRACKING get a simple PMMovieTracking object with all the filenames, nicknames etc. set correctly;
                % does not load the complete data to save time; gives user the opportunity to get direct access to derivative data;
                obj =                   obj.verifyThatAllFoldersAreSpecified;
                
                myMovieTracking =       PMMovieTracking;
                myMovieTracking =       myMovieTracking.setNickName(obj.getNickNameOfActiveMovie);
                myMovieTracking =       myMovieTracking.setNamesOfMovieFiles(obj.getAttachedImageSourceOfActiveMovie);

                myMovieTracking =       myMovieTracking.setImageAnalysisFolder(obj.getPathForImageAnalysis);
                myMovieTracking =       myMovieTracking.setMovieFolder(obj.getMovieFolder);
                myMovieTracking =       myMovieTracking.setKeywords(obj.getKeywordsOfActiveMovie); 
              
          end
          
        
    
        
        
    end
    
    methods % getters
        
        
        function test = allPropertiesAreValid(obj)
            
            FileNameTest = ~isempty(obj.FileName);
            ImageAnalysisTest = ~isempty(obj.PathForImageAnalysis);
            PathOfMovieFolderTest = ~isempty(obj.PathOfMovieFolder);
            PathForExporTest = ~isempty(obj.PathForExport);

            % other
            SelectedNicknameTest = ~isempty(obj.SelectedNickname); 
            
            test = FileNameTest && ImageAnalysisTest && PathOfMovieFolderTest && PathForExporTest && SelectedNicknameTest;
            
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
        
        function check = testThatPathForImageAnalysisExists(obj)
            check = ~isempty( obj.getPathForImageAnalysis);
        end
        
        function rowInLibrary = getIndexOfSelectedMovie(obj)
            rowInLibrary =     obj.getRowForNickName(obj.SelectedNickname);
        end
        
        function [SelectedRow] =                    getRowForNewOrExistingNickName(obj, NickNameString)
            assert(ischar(NickNameString), 'Wrong input.')
            SelectedRow =                 strcmp(obj.getAllNicknames, NickNameString);
            
            switch sum(SelectedRow)
               
                case 1
                    
                case 0
                    SelectedRow = obj.getNumberOfMovies + 1;
                otherwise
                    
                    error('Nickname does not work.')
                
                
            end
            
           
        end
        
        
        
        
        function value = checkWheterNickNameAlreadyExists(obj, Value)
            
            SelectedRow =                    obj.getRowForNickName(Value);
            if sum(SelectedRow) >= 1
                value = true;
            else
                value = false;
                
            end
        end
        
        
        function [SelectedRow] =                    getRowForNickName(obj, NickNameString)
            assert(ischar(NickNameString), 'Wrong input.')
            SelectedRow =                 strcmp(obj.getAllNicknames, NickNameString);

        end
        
     
         
        function obj = setNewNickname(obj, Value)
            obj.SelectedNickname =      Value;
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

         function value = getFileName(obj)
             value = obj.FileName;
         end
   
     
        
   

         
         
    
         function MovieTracking = getMovieTrackingForNickNames(obj, NickNames)
                MyRows =            obj.getLibraryRowsOfNicknames(NickNames);
                MovieTracking =     obj.ListhWithMovieObjects(MyRows,:);
         end
         
           function rows = getLibraryRowsOfNicknames(obj, Nicknames)
                ListWithAllNickNamesInternal =                 getAllNicknames(obj);
                rows =       cellfun(@(x) find(strcmp(ListWithAllNickNamesInternal, x)), Nicknames); 
           end
        
           
         
      
     
        
        %% get keywords:
         function KeywordList =          getKeyWordList(obj)
             % GETKEYWORDLIST: get list of keywords that are used in library;
              ListWithKeywords =               cellfun(@(x) x.getKeywords, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
              FinalList =                      (vertcat([ListWithKeywords{:}]))';
                if ~isempty(FinalList)
                    EmptyRows=                 cellfun(@(x) isempty(x),FinalList);
                    FinalList(EmptyRows,:)=    [];  
                     KeywordList=              unique(FinalList);
                else
                    KeywordList =   '';
                end
         end
        
        
          
      
        %% getNickNameOfActiveMovie
        function NickName = getNickNameOfActiveMovie(obj)
            NickName = obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.getNickName;
        end
        
        function NickName = getKeywordsOfActiveMovie(obj)
            NickName = obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.getKeywords;
        end
        
        function NickName = getAttachedImageSourceOfActiveMovie(obj)
            NickName = obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.getAttachedFiles;
        end
         
        function ImageData = getLoadedImageDataOfActiveMovie(obj)
            ImageData = obj.ListWithLoadedImageData{obj.getSelectedRowInLibrary, 1};
        end
          
          
        
        function [Movie] =              getMovieWithNickName(obj, Nickname)
            Movie  =      obj.ListhWithMovieObjects{strcmp(obj.getAllNicknames, Nickname)};    
        end
        
        function obj = loadMovieIntoListhWithMovieObjects(obj, NickName)
            MyRow = obj.getRowForNickName(NickName);
            assert(isscalar(MyRow), 'Wrong input.')
                MovieStructure.NickName =                       NickName;
                obj.ListhWithMovieObjects{MyRow, 1} =      PMMovieTracking(MovieStructure, {obj.getMovieFolder, obj.getPathForImageAnalysis},1);  
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
        
    
      
       
        function FilterSelectionIndex = getFilterSelectionIndex(obj)
           FilterSelectionIndex = obj.FilterSelectionIndex; 
        end
        
       
   
           
    end
    
    methods % summary lists
        
        function obj = updateMovieSummariesFromFiles(obj)
            
            for MovieIndex = 1 : obj.getNumberOfMovies
               
                CurrentNickName =                                   obj.ListWithMovieObjectSummary{MovieIndex,1}.getNickName;
                MyMovieTracking =                                   PMMovieTracking(obj.getPathForImageAnalysis, CurrentNickName).load;
                obj.ListWithMovieObjectSummary{MovieIndex,1} =      PMMovieTrackingSummary(MyMovieTracking);
            end

        end
          
    end
    
    methods %getters
        
        function obj = showSummary(obj)
            
            fprintf('\n*** This PMMovieLibrary object manages access to images and tracking data of a list of image-sequences.\n')
            fprintf('Its data are stored in the file "%s".', obj.FileName)
            fprintf('Movie specific annotations are stored in the following folder: "%s".\n', obj.PathForImageAnalysis)
            fprintf('The actual movies are stored in the following folder: "%s".\n', obj.getMovieFolder)
            fprintf('By default, exports are stored in the following folder: "%s".\n', obj.PathForExport)
            fprintf('The selected nickname is: "%s". Unless specified otherwise, this is the movie that the library will use.\n', obj.SelectedNickname)
            fprintf('There are %i elements for the movie summary.\n', length(obj.ListWithMovieObjectSummary))
            fprintf('There are %i elements in ListhWithMovieObjects.\n', length(obj.ListhWithMovieObjects))
            fprintf('There are %i elements in ListWithLoadedImageData.\n', length(obj.ListWithLoadedImageData))
            fprintf('There are additional properties that are not listed here that are relevant for filtering and sorting of entries.\n')
    
        end
        
        
        function movies = getIndicesOfMovies(obj)
            movies =        cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.ListWithMovieObjectSummary);
        end
        
        function movies = getIndicesOfZStacks(obj)
            movies =        cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.ListWithMovieObjectSummary);
        end
        
        function movies = getIndicesOfSnapshots(obj)
            movies =        cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.ListWithMovieObjectSummary);
        end
    
        function ListWithAllNickNamesInternal = getAllNickNames(obj)
               ListWithAllNickNamesInternal =              cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            
        end
        
        
        
        
           %% getFilterList:
        function FilterList = getFilterList(obj)
           FilterList = obj.FilterList; 
        end
        
        
        function ListWithFilteredNicknames = getListWithFilteredNicknames(obj)
           ListWithFilteredNicknames = obj.ListWithFilteredNicknames; 
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
                  error('Invalid movie folder.')
              end
        end
        
         function mainFolder =           getPathForImageAnalysis(obj)
             
             if isempty(obj.PathForImageAnalysis)
                 error('Path for image analysis not specified.')
                 mainFolder = '';
             else
                 mainFolder = obj.PathForImageAnalysis;  
             end
                
         end
         
         function folder = getInteractionFolder(obj)
             
             Position = find(obj.getPathForImageAnalysis == '/', 1, 'last');
            folder = [obj.PathForImageAnalysis(1:Position(1)), 'Interaction/'];
 
            if exist(folder) ~= 7
               mkdir(folder) 
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

 
        
           
    end
    
    methods % getters image paths:
        
        
        function names = getAllAttachedMovieFileNames(obj)
            allPaths = obj.getAllAttachedMoviePaths;
            [~, file, ext]  =                cellfun(@(x) fileparts(x), allPaths, 'UniformOutput', false);
            names =          cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false);   
        end
        
          function files = getAllAttachedMoviePaths(obj)
            files =         obj.getAttachedMoviePathsForEachEntry;
            files=          vertcat(files{:});
            if isempty(files)
               files = cell(0,1); 
            end
          end
          
        function files = getAttachedMoviePathsForEachEntry(obj)
            if isempty(obj.ListWithMovieObjectSummary)
            files = cell(0,1);
            else
                files =          cellfun(@(x) x.getAttachedFiles, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            end

        end
        
      
        function [namesOfAvailableFiles] =  getFileNamesOfUnincorporatedMovies(obj)
            namesOfAvailableFiles =    PMFileManagement(obj.getMovieFolder).getFileNames;
            
            ListWithPaths = cellfun(@(x) [ obj.getMovieFolder, '/', x], namesOfAvailableFiles, 'UniformOutput', false);
            
            for index = 1 : length(ListWithPaths)
                
                try
                     ImageFileIndices(index, 1) = PMImageFiles({ListWithPaths{index}}).supportedFileType;;
                catch
                    ImageFileIndices(index, 1) = false;
                end
                
            end
            
            
            namesOfAvailableFiles(~ImageFileIndices) = [];
            
            
            alreadyAddedFileNames =     obj.getAllAttachedMovieFileNames;
            if isempty(alreadyAddedFileNames)
                
            else
                MatchingRows=                               cellfun(@(x) max(strcmp(x, alreadyAddedFileNames)), namesOfAvailableFiles);
                namesOfAvailableFiles(MatchingRows,:)=      [];
            end
            
        end
         
                   
          function folders = getNamesOfAllMovieFolders(obj) 
            folders = obj.PathOfMovieFolder;
          end
          
        
    end
    
    
    methods %setters
            

        function obj = setMovieFolders(obj, Value)
           obj.PathOfMovieFolder =  Value;
           obj =                    obj.setMovieFolderInMovieObjectSummaries; 
        end
        
        function obj = addMovieFolder(obj, Value)
            
            assert(ischar(Value), 'Wrong input.')
            OldFolders =       obj.getNamesOfAllMovieFolders;
            NewFolders =    [OldFolders; Value];
            obj.PathOfMovieFolder = Value;
            obj =                    obj.setMovieFolderInMovieObjectSummaries; 
        end
        
          
             
      


        %% saveMovieLibraryToFile:
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
                         assert(~isempty(Nickname), 'The nickname was already chosen. Take another one.')
                    end
                end
           end
          
            function CandidateNickName =   deleteNonUniqueNickName(obj, CandidateNickName)
                NickNames =          obj.getAllNicknames;
                if ~isempty(find(strcmp(CandidateNickName, NickNames), 1))
                    CandidateNickName = '';
                end
            end
            
         
          
            
            
        
        
    end
    
    methods % filter
        
        function [obj] =                updateFilterSettingsFromPopupMenu(obj, PopupMenu, PopUpMenuTwo)
            obj =       obj.setMainFilterWith(PopupMenu); 
            obj =       obj.setKeywordFilterWith(PopUpMenuTwo);
            obj =       obj.updateFilterList;
        end
        
         function obj = setMainFilterWith(obj, PopupMenu)
             if isempty(PopupMenu.Value)
                PopupMenu.Value = 1; 
             end
             
            if ischar(PopupMenu.String)
                SelectedString =  PopupMenu.String;
            else
                SelectedString =  PopupMenu.String{PopupMenu.Value};                                           
            end
            obj.FilterSelectionString =            SelectedString;
            obj.FilterSelectionIndex =             PopupMenu.Value;
   
        end
        
        function obj = setKeywordFilterWith(obj, PopUpMenuTwo)
            if ischar(PopUpMenuTwo.String)
                SelectedString =  PopUpMenuTwo.String;
            else
                SelectedString = PopUpMenuTwo.String{PopUpMenuTwo.Value};                                           
            end
            obj.KeywordFilterSelectionIndex =               PopUpMenuTwo.Value;
            obj.KeywordFilterSelectionString =              SelectedString;
            
        end
        

        
            
        
        
        function [obj] =                updateFilterList(obj)
            
            
                obj = obj.setAllMovies;
            
              switch obj.FilterSelectionString
                  case 'Show all movies'
                      obj.FilterList =        obj.getIndicesOfMovies;
                      
                  case 'Show all Z-stacks'
                       obj.FilterList =       obj.getIndicesOfZStacks;
                       
                  case 'Show all snapshots'
                       obj.FilterList =       cellfun(@(x) strcmp(x.getDataType, 'Snapshot'), obj.ListWithMovieObjectSummary);
                       
                 case 'Show all tracked movies'
                     FilterMovies =            obj.getIndicesOfMovies;
                     FilterTracking =         cellfun(@(x) x.getTrackingWasPerformed, obj.ListWithMovieObjectSummary);
                     obj.FilterList =         min([FilterMovies FilterTracking], [], 2); 
    
                  case 'Show all untracked movies'
                     FilterMovies =         obj.getIndicesOfMovies;
                     FilterTracking =      cellfun(@(x) ~x.getTrackingWasPerformed, obj.ListWithMovieObjectSummary);
                     obj.FilterList =      min([FilterMovies FilterTracking], [], 2); 
                     
                 case 'Show all movies with drift correction'   
                     obj.FilterList =                       cellfun(@(x) x.testForExistenceOfDriftCorrection, obj.ListhWithMovieObjects);
                     
                 case 'Show entire content'
                        obj.FilterList =                        cellfun(@(x) true, obj.ListWithMovieObjectSummary);             
           
                  case 'Show all unmapped movies'
                        obj.FilterList =                       cellfun(@(x) ~x.isMapped, obj.ListhWithMovieObjects);

                  case 'Show content with non-matching channel information'
                      obj.FilterList =                       cellfun(@(x) ~x.ChannelSettingsAreOk, obj.ListWithMovieObjectSummary);

              end
              obj =         obj.applyKeywordsToFilter;
              
        end
        
        
        
        
         function obj =  applyKeywordsToFilter(obj)
            ListWithAllNickNamesInternal =     obj.getAllNickNames;
            obj.ListWithFilteredNicknames=     ListWithAllNickNamesInternal(obj.FilterList,:);
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

            rowsThatHaveNoKeyword =        cellfun(@(x) ~keyWordCheck(x.getKeywords), obj.ListWithMovieObjectSummary);
            obj.FilterList  =              min([obj.FilterList rowsThatHaveNoKeyword], [], 2);

            ListWithAllNickNamesInternal =   cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=   ListWithAllNickNamesInternal(obj.FilterList,:);

        end
        
        
        function [obj] =                addKeywordFilter(obj)

            rowsThatHaveNoKeyword =                                cellfun(@(x) isempty(x.getKeywords), obj.ListWithMovieObjectSummary);
            KeywordFilterList =                                     cellfun(@(x) max(strcmp(x.getKeywords, obj.KeywordFilterSelectionString)), obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            KeywordFilterList(rowsThatHaveNoKeyword,:) =            {false};
            
            KeywordFilterList =                                     cell2mat(KeywordFilterList);
            obj.FilterList =                                        min([obj.FilterList,logical(KeywordFilterList)], [], 2);
            ListWithAllNickNamesInternal =                                  cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=                          ListWithAllNickNamesInternal(obj.FilterList,:);
           

            
        end
        
        
    end
    
    methods % movie-list
    
         function [obj] =           updateMovieListWithMovieController(obj, ActiveMovieController)
            
            MyLoadedMovie =                ActiveMovieController.getLoadedMovie;
            NickNameOfLoadedMovie =        MyLoadedMovie.getNickName;
            LinkedFilesOfLoadedMovie =     MyLoadedMovie.getLinkedMovieFileNames;
            MyLoadedImageVolumes =         ActiveMovieController.getLoadedImageVolumes;

            assert(isa(MyLoadedMovie, 'PMMovieTracking'), 'Movie controller has no LoadedMovie attached.')
            assert(ischar(NickNameOfLoadedMovie), 'LoadedMovie has no nickname.')
            assert(~isempty(LinkedFilesOfLoadedMovie), 'LoadedMovie has no filenames for image files attached.')

            SelectedRow =                                       obj.getRowForNewOrExistingNickName(NickNameOfLoadedMovie);

            obj.ListWithMovieObjectSummary{SelectedRow,1} =     PMMovieTrackingSummary(MyLoadedMovie);
            obj.ListhWithMovieObjects{SelectedRow,1} =          MyLoadedMovie;
            obj.ListWithLoadedImageData{SelectedRow,1} =        MyLoadedImageVolumes;
            obj.FilterList(SelectedRow, 1)=                       true;


         end
        
        
        
        
    end
    
    methods (Access = private)
        
        
       
        
        
        
        function [SelectedRow] =                    getSelectedRowInLibrary(obj)
            ListWithAllNickNamesInternal =                 getAllNicknames(obj);   
            SelectedRow =                           strcmp(ListWithAllNickNamesInternal, obj.SelectedNickname);
        end
        
          %% addNewEntryIntoLibraryInternal
          function obj = addNewEntryIntoLibraryInternal(obj, NickName, AttachedFilenames)
              
              error('Do not use this. Use updateMovieListWithMovieController instead.')
                newMovieTrackingSummary =   obj.getInitializedMovieTrackingSummaryWithNickNameAndAttachedFiles(NickName, AttachedFilenames); 

                index =                     obj.getNumberOfMovies + 1;

                newMovieTracking =          PMMovieTracking(newMovieTrackingSummary);
                newMovieTracking =          newMovieTracking.setImageAnalysisFolder(obj.getPathForImageAnalysis);
                newMovieTracking =          newMovieTracking.setPropertiesFromImageFiles;

                newMovieTracking =          newMovieTracking.save;

                obj.ListhWithMovieObjects{index, 1}=            newMovieTracking;
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
           
        end
          
        
     
            
       

        function obj = setMovieFolderInMovieObjectSummaries(obj)
            obj.ListWithMovieObjectSummary =    cellfun(@(x) x.setMovieFolder(obj.getMovieFolder), obj.ListWithMovieObjectSummary, 'UniformOutput', false);
        end
        
        
        
        
         %% save and synchronize MovieTracking
       
         

        
          
        

          function obj = verifyThatAllFoldersAreSpecified(obj)
         

               if isempty( obj.getNickNameOfActiveMovie)
                   error('Nickname empty.')
               end
          end
          
       
         
        
    end
end

