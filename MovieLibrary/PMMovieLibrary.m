classdef PMMovieLibrary
    %PMMOVIELIBRARY manage movies for tracking analysis
    %   Saves filename and nickname information of attached movie-series so that all movie-related data can be loaded from file;
    

    properties (Access = private) % FILE-MANAGEMENT
        
        % files/folders:
        FileName =                                          '';
        
        PathForImageAnalysis
        PathOfMovieFolder
        PathForExport
         
        % other
      
        
        Version =                                           4;
        
    end
    
    properties (Access = private) % MOVIE-LIST
       
          SelectedNickname =                                  ''
        ListWithMovieObjectSummary =                        cell(0,1); % summary of movie objects; this is stored in library file, and needed for example to filter files by movie vs. Z-stack etc;
        ListhWithMovieObjects =                             cell(0,1); % list with complete information; this is stored in memory, not in library file; files are created for individual movie analyses
        ListWithLoadedImageData =                           cell(0,1);
        
    end
    
    properties (Access = private) % MOVIE-LIST FILTER          
        
        FilterList =                                        true

        FilterSelectionIndex
        FilterSelectionString =                             ''

        KeywordFilterSelectionIndex =                       1;
        KeywordFilterSelectionString =                      'Ignore keywords';

        SortIndex =                                         1;

    end
    
    methods % initialize
        
        function obj = PMMovieLibrary(varargin)
             % PMMOVIELIBRARY create instance
             % 0 or 1 arguments:
             % 1: string with complete path of stored PMMovieLibrary;
            
                NumberOfArguments = length(varargin);
                switch NumberOfArguments

                    case 0

                    case 1
                        obj.FileName =      varargin{1};
                        
                        [a,~,~]= fileparts(varargin{1});
                        
                         obj.PathForImageAnalysis =  a;
                            obj.PathOfMovieFolder =    a;
                            obj.PathForExport=         a;
                        
                        if  exist(obj.FileName) == 2
                            obj =               obj.load;
                            obj =               obj.ensureAllMovieTrackingFilesCanConnect;
                            obj =               obj.loadAllMoviesFromFile;
                        end
                        
                    case 2
                        assert(ischar(varargin{2}), 'Wrong input.')
                        
                        switch varargin{2}
                           
                            case 'DoNotLoad'
                                 obj.FileName =      varargin{1};
                                 obj =               obj.load;
                            otherwise
                                 obj.FileName =      varargin{1};
                                obj =               obj.load;
                                obj =               obj.ensureAllMovieTrackingFilesCanConnect(varargin{2});
                                obj =               obj.loadAllMoviesFromFile(varargin{2});
                            
                            
                            
                        end
                        
                    case 4
                        
                        error('Not supported. Verify approach or start with just one argument.') 
                            obj.FileName =              varargin{1};
                            obj.PathForImageAnalysis =  varargin{2};
                            obj.PathOfMovieFolder =     varargin{3};
                            obj.PathForExport=          varargin{4};

                    otherwise
                        error('Wrong number of arguments')
                end
       
        end
         
        function obj = set.PathForImageAnalysis(obj, Value)
            assert(ischar(Value), 'Wrong input.')
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

        function obj = set.FileName(obj, LibraryFileName)
              assert(~isempty(LibraryFileName) && ischar(LibraryFileName) , 'Invalid filename. Please enter a valid file-path as argument of this intializer.')
          
            obj.FileName = LibraryFileName;
        end
        
        function obj = set.SelectedNickname(obj, Value)
            
            if isempty(Value)
                
            else
                assert((ischar(Value)  ), 'Invalid nickname entered, potentially not unique. Try other nickname.')
                
                NumberOfMatches = obj.getNumberOfNickNameMatchesForString(Value);
                
                if NumberOfMatches == 1
                   
                elseif NumberOfMatches == 0
                    obj.showAllNicknames;
                    error('Suggested nickname %s was not accepted because it did not match a single entry in the library.\n', Value)
                    
                elseif NumberOfMatches > 1
                    obj.showAllNicknames;
                    error('Suggested nickname %s was not accepted because it matched multiple entries in the library.\n', Value)
                    
                else
                     obj.showAllNicknames;
                     error('Suggested nickname %s was not accepted for unknown reason.\n', Value)
                     
                end
                    
                    
               
                
               
            end
           
            obj.SelectedNickname = Value;
        end
        
  
    end
    
    methods % SUMMARY 
        
            function obj =          showSummary(obj)

                fprintf('\n*** This PMMovieLibrary object manages access to images and tracking data of a list of image-sequences.\n')
                fprintf('Its data are stored in the file "%s".', obj.FileName)
                fprintf('Movie specific annotations are stored in the following folder: "%s".\n', obj.PathForImageAnalysis)
                fprintf('The actual movies are stored in the following folder: "%s".\n', obj.getMovieFolder)
                fprintf('By default, exports are stored in the following folder: "%s".\n', obj.PathForExport)
                fprintf('The selected nickname is: "%s". Unless specified otherwise, this is the movie that the library will use.\n', obj.SelectedNickname)
                fprintf('There are %i elements for the movie summary.\n', length(obj.ListWithMovieObjectSummary))
                fprintf('There are %i elements in ListhWithMovieObjects.\n', length(obj.ListhWithMovieObjects))
                fprintf('There are %i elements in ListWithLoadedImageData.\n', length(obj.ListWithLoadedImageData))
                fprintf('\nThe library has filter settings:\n')
                fprintf('It will filter by movie type for "%s".\n', obj.FilterSelectionString)
                fprintf('It will filter for keyword "%s".\n', obj.KeywordFilterSelectionString)
                fprintf('Currently the following nicknames pass the filter:\n')
                cellfun(@(x) fprintf('"%s"\n', x), obj.getListWithFilteredNicknames)

                fprintf('There are additional properties that are not listed here that are relevant for sorting of entries.\n')

            end

            function InfoText =     getProjectInfoText(obj)
            FileNameOfProject{1,1}=             'Filename of current project:';
            FileNameOfProject{2,1}=             obj.FileName;
            FileNameOfProject{3,1}=             '';

            FolderWithMovieFiles{1,1}=          'Linked folder with movie files:';
            FolderWithMovieFiles{2,1}=          obj.getMovieFolder;
            FolderWithMovieFiles{3,1}=          '';
            
            AllMovieFolders{1,1} =              'Names of all possible movie folders:';
       
            AllMovieFolders =                   [AllMovieFolders;  obj.PathOfMovieFolder; ' '];

            PathForDataExport{1,1}=             'Folder for data export:';
            PathForDataExport{2,1}=             obj.PathForExport;
            PathForDataExport{3,1}=             '';

            AnnotationFolder{1,1}=             'Annotation folder:';
            AnnotationFolder{2,1}=             obj.getPathForImageAnalysis;
            AnnotationFolder{3,1}=             '';
            InfoText=                          [FileNameOfProject;AllMovieFolders;  FolderWithMovieFiles; PathForDataExport; AnnotationFolder];
        
        end
      
        end
    
    methods % SETTERS: BASIC
        
         function obj =         setFileName(obj, Value)
            obj.FileName = Value;
          end
          
         function obj =         setNewNickname(obj, Value)
            % SETNEWNICKNAME set new nickname
            % 1 argument: character; (nickename must have exactly one match in list of current nicknames, otherwise not allowed);
            obj.SelectedNickname =      Value;
           end
        
         function obj =         letUserSetAnnotationPath(obj)
            % LETUSERSETANNOTATIONPATH user can interactively pick a new
            % folder as a new path for all annotation files;
            NewPath=          uipickfiles('FilterSpec', obj.getPathForImageAnalysis, 'Prompt', 'Select tracking folder',...
            'NumFiles', 1, 'Output', 'char');

            if isempty(NewPath) || ~ischar(NewPath)
            
            else
                obj =              obj.setPathForImageAnalysis(NewPath); 
          
              

            end

         end

         function obj =         setPathForImageAnalysis(obj, Value)
            obj.PathForImageAnalysis =      Value;
         end
         
         function obj =         changeMovieFileNamesFromTo(obj, OriginalName, NewName)
            error('Something seems wrong here. Check before using the method.')
            for index = 1 : obj.getNumberOfMovies
                obj.ListhWithMovieObjects{index} = obj.ListhWithMovieObjects{index}.changeMovieFileNamesFromTo(OriginalName, NewName);
            end
            
            
            
        end
        
        function obj =          setExportFolder(obj, Value)
            obj.PathForExport = Value; 
        end

    end
    
    methods % SETTERS: BASIC, MOVIE-FOLDER;
       
          function obj =      letUserSetMovieFolder(obj)
               NewPath = obj.letUserPickMovieFolder;
        
            if isempty(NewPath) || ~ischar(NewPath)
            else
                 obj =       obj.addMovieFolder(NewPath);
                
            end
            
       end
       
          function obj =      setMovieFolders(obj, Value)
           obj.PathOfMovieFolder =  Value;
           obj =                    obj.setMovieFolderInAllMovies; 
          end
        
          function obj =      addMovieFolder(obj, Value)
            assert(ischar(Value), 'Wrong input.')
            OldFolders =                obj.getNamesOfAllMovieFolders;
            NewFolders =                [OldFolders; Value];
            obj.PathOfMovieFolder =     Value;
            obj =                       obj.setMovieFolderInAllMovies;
            
          end
        
          function obj =      setMovieFolderInAllMovies(obj)
            obj.ListhWithMovieObjects =    cellfun(@(x) x.setMovieFolder(obj.getMovieFolder), obj.ListhWithMovieObjects, 'UniformOutput', false);
        end

        
        
    end
    
    methods % GETTERS: BASIC

            function value =                getFileName(obj)
            value = obj.FileName;
            end

            function mainFolder =           getPathForImageAnalysis(obj)

            if isempty(obj.PathForImageAnalysis)
            error('Path for image analysis not specified.')
            mainFolder = '';

            else
            mainFolder = obj.PathForImageAnalysis;  

            end

            end

            function folder =               getInteractionFolder(obj)

            Position = find(obj.getPathForImageAnalysis == '/', 1, 'last');
            folder = [obj.PathForImageAnalysis(1:Position(1)), 'Interaction/'];

            if exist(folder) ~= 7
            mkdir(folder) 
            end

            end

            function folder =               getMovieFolder(obj)
                if ischar(obj.PathOfMovieFolder)
                    folder =          obj.PathOfMovieFolder;

                    elseif iscellstr(obj.PathOfMovieFolder)
                    folder =      PMFolderManagement(obj.PathOfMovieFolder).getFirstValidFolder;

                else
                    folder = '';
                    error('Invalid movie folder.')
                end
            end

            function folders =              getNamesOfAllMovieFolders(obj) 
                folders = obj.PathOfMovieFolder;
            end
            
            function path =                 getExportFolder(obj)
            path = obj.PathForExport;
            end

            function nick =                 getSelectedNickname(obj)
            nick = obj.SelectedNickname; 
            end

            function numberOfMovies =       getNumberOfMovies(obj)
            numberOfMovies =            size(obj.ListWithMovieObjectSummary, 1);
            end
   
    end
    
    methods % GETTERS NICKNAMES
        
        function value =                        checkWheterNickNameAlreadyExists(obj, Value)
            % CHECKWHETERNICKNAMEALREADYEXISTS determines whether interrogated nickname is currently in library;
            % returns logical scalar
            assert(ischar(Value), 'Wrong input.')
            SelectedRow =                    obj.getRowForNickName(Value);
            if sum(SelectedRow) >= 1
                value = true;
            else
                value = false;

            end
        
        end

    end
       
    methods % ACTION FILE-MANAGEMENT

        function obj =      load(obj)
            % LOAD load movie-library from file;
            ValidFileName =   obj.FileName;
            assert(ischar(ValidFileName) && exist(ValidFileName) == 2, 'Wrong input.')
            
            load(ValidFileName, 'ImagingProject');
            
            switch class(ImagingProject)
               
                case 'PMMovieLibrary'
                     obj.Version =                           ImagingProject.Version;
                otherwise
                    obj.Version =                           2;
                
            end
            
            switch obj.Version
                case 4 
                    obj =           ImagingProject;
                    obj.FileName =  ValidFileName;
                    
                otherwise
                    error('Version of library not supported. Go to PMMovieLibraryVersion to convert library into current version.')
            end
                            
            
            
         end
         
        function obj =      saveMovieLibraryToFile(obj)
            % SAVEMOVIELIBRARYTOFILE saves file of movie-library;
            % redundant data that are saved in other files are removed from object before saving;
            obj =           obj.saveMovieLibraryWithName(obj.FileName);


        end
          
        end

    methods % GETTERS FILE-MANAGEMENT

            function ListWithSelectedFileNames =    askUserToSelectMovieFileNames(obj)
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

            function Nickname =                     askUserToEnterUniqueNickName(obj)
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

            function CandidateNickName =            deleteNonUniqueNickName(obj, CandidateNickName)
                NickNames =          obj.getAllNicknames;
                if ~isempty(find(strcmp(CandidateNickName, NickNames), 1))
                    CandidateNickName = '';
                end
            end

        end

    methods % SETTERS MOVIE-LIST switchActiveMovieByNickName;
        
          function obj =      switchActiveMovieByNickName(obj, NickName, varargin)
            % SWITCHACTIVEMOVIEBYNICKNAME
            % takes 1 argument:
            % 1: nickname (character string):
            % changes active nickname and loads PMMovieTracking from file (unless already loaded);
            % does NOT save anything (e.g. changes in movie tracking will be lost unless saved previously);

            switch length(varargin)

                case 0
                    MyVersion = 'LoadMasks';
                case 1
                    MyVersion = varargin{1};
                otherwise
                    error('Wrong input.')

            end

            obj =                   obj.setNewNickname(NickName);
            myMovieTracking=        obj.getActiveMovieTracking(MyVersion);
            obj =                   obj.setLibraryWithActiveMovie(myMovieTracking);

        end
        
        
    end
    
    methods % SETTERS MOVIE-LIST ADD MOVIE:
        
        function obj =      addNewEntryToMovieList(obj, ActiveMovieController)
            % ADDNEWENTRYTOMOVIELIST add new movie to list;
            % takes 1 argument
            % 1: PMMovieController
            % the new movie is added at the bottom of the movie-list
            assert(isscalar(ActiveMovieController) && isa(ActiveMovieController, 'PMMovieController'), 'Wrong input.')
            assert(~obj.checkWheterNickNameAlreadyExists(ActiveMovieController.getNickName), '[Nickname already exists. Choose a different one.')

            MyLoadedImageVolumes =          ActiveMovieController.getLoadedImageVolumes;
            SelectedRow =                   obj.getNumberOfMovies + 1;
            obj =                           obj.updateMovieIndexWith(...
                                                SelectedRow, ...
                                                ActiveMovieController.getLoadedMovie, ...
                                                MyLoadedImageVolumes...
                                                );
                                            
            obj =                           obj.sortByNickName;
                                            
                                            
                                            

        end
         
        function obj =      sortByNickName(obj)
            % SORTBYNICKNAME sort order of movies by nickname
            AllNicknames =         obj.getAllNicknames;
            obj =                  obj.sortAllMovieListsBy(AllNicknames);  
        end
            
    end
    
    methods % SETTERS MOVIE-LIST REMOVE CONTENT;
        
        function obj =      removeAlEntriesExceptForNicknames(obj, NickNames)

            NewFileName =               [obj.FileName(1 : end - 4), '_', PMTime().getCurrentTimeString, '_Complete.mat'];
            obj =                       obj.saveMovieLibraryWithName(NewFileName);

            RowsToDelete =              obj.getAllRowsExceptForNicknames(NickNames);
            obj =                       obj.clearContentsOfLibraryIndex(RowsToDelete);
            obj.SelectedNickname =      '';

            obj =                       obj.saveMovieLibraryToFile;
        end

        function obj =      deleteAllEntriesFromLibrary(obj)
        % DELETEALLENTRIESFROMLIBRARY removes from library all entries (does not delete source-files, only links);
         obj =                       obj.clearContentsOfLibraryIndex(1 : obj.getNumberOfMovies);
         obj.SelectedNickname =      '';
        end

        function obj =      removeActiveMovieFromLibrary(obj)
        % REMOVEACTIVEMOVIEFROMLIBRARY removes from library active entry (does not delete source-files, only link);
         obj =          obj.removeFromLibraryMovieWithNickName(obj.SelectedNickname);
        end

        function obj =      deleteAllMovieFiles(obj, varargin)
            % DELETEALLFILES deletes movie-related files for all movies;
            % deletes current version files only, files from older formats are left untouched;
            
            switch length(varargin)
                case 0
                    MyVersion = '';
                case 1
                    MyVersion = varargin{1};
                    
                otherwise
                    error('Wrong input.')
                
            end
            
             ListWithNickNames =      obj.getAllNicknames;   

            for index = 1 : length(ListWithNickNames)
                fprintf('\nDelete movie %s. (%i of %i)\n', ListWithNickNames{index}, index, length(ListWithNickNames));
                obj =                   obj.setNewNickname(ListWithNickNames{index});
                myMovieTracking =       obj.getUnloadedMovieTracking;
                myMovieTracking.delete(MyVersion);

            end 
            
        end
           
    end
    
    methods % SETTERS MOVIE-LIST SET MOVIETRACKING FROM FILE;
        
         function obj =      updateMovieListWithMovieController(obj, ActiveMovieController)
            % UPDATEMOVIELISTWITHMOVIECONTROLLER: reset movie-lists of library with active movie controller;
            % argument: ActiveMovieController
            % extract PMMovieTracking and loaded image sequences ;
            % and update the following list:
            % ListWithMovieObjectSummary
            % ListhWithMovieObjects
            % ListWithLoadedImageData
            % also: add current movie to filter list:
            
            assert(isscalar(ActiveMovieController) && isa(ActiveMovieController, 'PMMovieController'), 'Wrong input.')
           
            if obj.allPropertiesAreValid
                MyLoadedImageVolumes =          ActiveMovieController.getLoadedImageVolumes;
                SelectedRow =                   find(obj.getRowForNickName(ActiveMovieController.getNickName));
                obj =                           obj.updateMovieIndexWith(SelectedRow, ActiveMovieController.getLoadedMovie, MyLoadedImageVolumes);
            else
                   warning('Library could not be saved. Reason: Not allPropertiesAreValid')
              
            end
          
        end

        function obj =      loadMovieIntoListhWithMovieObjects(obj, NickName)
            % consider deleting this method:
            MyRow =                                     obj.getRowForNickName(NickName);
            assert(isscalar(MyRow), 'Wrong input.')
            MovieStructure.NickName =                   NickName;
            obj.ListhWithMovieObjects{MyRow, 1} =       PMMovieTracking(MovieStructure, {obj.getMovieFolder, obj.getPathForImageAnalysis},1);  
        end
 
        
        
    end
    
    methods % SETTERS MOVIE-LIST UPGRADE VERSION;
       
        function obj =      upgradeVersion(obj)
            % UPGRADEVERSION loads for each movie version 'BeforeAugust2021' from file and converts into current version;
            % stores new files on disk;
            % old version is not deleted;
             ListWithNickNames =        obj.getAllNicknames;   
             obj =                      obj.ensureAllMovieTrackingFilesCanConnect('BeforeAugust2021');
             obj =                      obj.removeMovieListFromMemory;
             
            for index = 1 : length(ListWithNickNames)
                fprintf('\nUpgrade movie %s. (%i of %i)\n', ListWithNickNames{index}, index, length(ListWithNickNames));
                obj =                   obj.switchActiveMovieByNickName(ListWithNickNames{index}, 'BeforeAugust2021');
                myMovieTracking=        obj.getActiveMovieTracking('BeforeAugust2021');
                myMovieTracking.save; % saves movie-tracking in current format;
                obj =                   obj.setLibraryWithActiveMovie(myMovieTracking);

            end 
            
            obj =       obj.removeMovieListFromMemory;
            obj =       obj.ensureAllMovieTrackingFilesCanConnect('AfterAugust2021');
            obj =       obj.loadMissingMovieTrackingsFromFile('AfterAugust2021');
            obj =      obj.applyLibraryPropertiesToMovieTrackingObjects;
                        
            
        end
        
    end
    
    methods % GETTERS MOVIELIST

        function list =             getListhWithMovieObjects(obj)
            list =                  obj.ListhWithMovieObjects;
        end
        
        function value =            allMoviesAreSet(obj)
            value = min(cellfun(@(x) isa(x, 'PMMovieTracking') && isscalar(x), obj.ListhWithMovieObjects));
        end
        
        function KeywordList =      getKeyWordList(obj)
              % GETKEYWORDLIST: get list of keywords that are used in library;
              ListWithKeywords =               cellfun(@(x) x.getKeywords, obj.getListhWithMovieObjects, 'UniformOutput', false);
              FinalList =                      (vertcat([ListWithKeywords{:}]))';
                if ~isempty(FinalList)
                    EmptyRows=                 cellfun(@(x) isempty(x),FinalList);
                    FinalList(EmptyRows,:)=    [];  
                     KeywordList=              unique(FinalList);
                else
                    KeywordList =   '';
                end
        end
         
        function NickNames =        getAllNicknames(obj)
            % GETALLNICKNAMES returns list with all nicnnames;
            % 1 return:
            % 1: cell-string vector with all nicknames
            NickNames =       cellfun(@(x) x.getNickName, obj.ListWithMovieObjectSummary, 'UniformOutput', false);      
          end
       
        function rows =             getLibraryRowsOfNicknames(obj, Nicknames)
            ListWithAllNickNamesInternal =                 obj.getAllNicknames;
            rows =       cellfun(@(x) find(strcmp(ListWithAllNickNamesInternal, x)), Nicknames); 
        end 
        
    end
    
    methods % GETTERS MOVIE-LIST: movie-filepaths
        
            function names =        getAllAttachedMovieFileNames(obj)
                allPaths =              obj.getAllAttachedMoviePaths;
                [~, file, ext]  =       cellfun(@(x) fileparts(x), allPaths, 'UniformOutput', false);
                names =                 cellfun(@(x,y) [x, y], file, ext, 'UniformOutput', false);   
            end

            function names =        getFileNamesOfUnincorporatedMovies(obj)

                names =     PMFileManagement(obj.getMovieFolder).getFileNames;
                ListWithPaths =             cellfun(@(x) [ obj.getMovieFolder, '/', x], names, 'UniformOutput', false);

                for index = 1 : length(ListWithPaths)
                    fprintf('Testing validity of file %i of %i.\n', index, length(ListWithPaths))
                    try
                            ImageFileIndices(index, 1) = PMImageFiles({ListWithPaths{index}}).supportedFileType;
                    catch
                            ImageFileIndices(index, 1) = false;
                    end
                end

                names(~ImageFileIndices) = [];

                alreadyAddedFileNames =     obj.getAllAttachedMovieFileNames;
                if isempty(alreadyAddedFileNames)

                else
                    MatchingRows=                               cellfun(@(x) max(strcmp(x, alreadyAddedFileNames)), names);
                    names(MatchingRows,:)=      [];
                end

            end

       end
    
    methods % GETTERS MOVIE-LIST FILTERED
      
        function listWithAllWantedNickNames =       getAllFilteredNicknames(obj)
            listWithAllNicknames =              obj.getAllNicknames;
            listWithAllWantedNickNames =        listWithAllNicknames(obj.getFilterList,:); 
          end
        
        function ListWithFilteredNicknames =        getListWithFilteredNicknames(obj)
            ListWithAllNickNamesInternal =  obj.getAllNicknames;
            if isempty(ListWithAllNickNamesInternal)
                ListWithFilteredNicknames = '';
            else
                ListWithFilteredNicknames=      ListWithAllNickNamesInternal(obj.FilterList,:);
            end
        end
 
    end
   
    methods % SETTERS MOVIETRACKING: NICKNAME
        
       function obj =           changeNickNameOfSelectedMovie(obj, varargin)

            IndexOfMovie = obj.getIndexOfSelectedMovie;% because of name change this has to be done first;

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
             
                case 1
                    
                    Type = class(varargin{1});
                    switch Type

                        case 'char'
                            NewNickName =  varargin{1};
                            obj = obj.changeNickNameForMovieWithIndex(IndexOfMovie, NewNickName);
                            
                        case 'PMMovieController'
                            error('Not supported anymore. Use character string as input.')
                            
                        otherwise
                            error('Input not supported.')
                            
                    end

                otherwise
                    error('Wrong input.')

            end   
        end
        
       function obj =           changeNickNameForMovieWithIndex(obj, IndexOfMovie, NewNickName)
            assert(~obj.checkWheterNickNameAlreadyExists(NewNickName), 'Nickname already exists. Choose another one.')
            obj.ListWithMovieObjectSummary{IndexOfMovie,1 } =   obj.ListWithMovieObjectSummary{IndexOfMovie,1 }.setNickName(NewNickName);
            obj.ListhWithMovieObjects{IndexOfMovie,1 } =        obj.ListhWithMovieObjects{IndexOfMovie,1 }.setNickName(NewNickName);
            obj.SelectedNickname =                              NewNickName;
            
        end

    end
    
    methods % GETTERS MOVIECONTROLLER/ MOVIETRACKING
        
        function myMovieController =        getActiveMovieController(obj, varargin)
            % GETACTIVEMOVIECONTROLLER get active PMMovieTracking;
            % takes 0 or 1 arguments:
            % return movie controller for selected nickanme
            % the movie-controller is set from scratch and comes with movie-specific properties;
            % also sets loaded movie, image-volumes, export-folder and interaction folder;

            assert(~isempty(obj.ListhWithMovieObjects) && ~isempty(obj.SelectedNickname), 'Cannot create movie controller, because library has nof information about movies.')  
            switch length(varargin)

                case 0
                    myMovieController =     PMMovieController(obj.getActiveMovieTracking);
                case 1
                    error('Not supported anymore.')

                otherwise
                    error('Wrong input.')

            end

            Input =                     obj.getLoadedImageDataOfActiveMovie;
            if isempty(Input)
                
            else
                 myMovieController =     myMovieController.setLoadedImageVolumes(Input); 
            end

            myMovieController =     myMovieController.updateWith(obj);
            myMovieController =     myMovieController.setExportFolder(obj.getExportFolder);
            myMovieController =     myMovieController.setInteractionsFolder(obj.getInteractionFolder);


        end

        function myMovieTracking=           getActiveMovieTracking(obj, varargin)
            % GETACTIVEMOVIETRACKING returns PMMovieTracking of active movie entry;
            % takes 0 or 1 arguments:
            % 1: character string with wanted version (default: current version), only relevant when loading from file, otherwise just taking what's in memory;
            % gets from memory (if available);
            % otherwise uses getActiveMovieTrackingFromFile to get object from file;
            
            switch length(varargin)
               
                case 0
                    MyVersion =     '';
                case 1
                    MyVersion =     varargin{1};
                otherwise
                    error('Wrong input.')
                
            end

            myMovieTracking =           obj.ListhWithMovieObjects{obj.getSelectedRowInLibrary,1};
            if isempty(myMovieTracking)
                myMovieTracking =      obj.getActiveMovieTrackingFromFile(MyVersion);
            end
        end
        
        function myMovieTracking =          getActiveMovieTrackingFromFile(obj, varargin)
            % GETMOVIETRACKINGFROMFILE get a simple PMMovieTracking object with all the filenames, nicknames etc. set correctly;
            % object is always loaded from file;
            % takes 0 or 1 arguments:
            % 1: characters string of wanted version (default is current verions);
          
            myMovieTracking =           obj.getUnloadedMovieTracking;
            switch length(varargin)

                case 0
                    myMovieTracking =       myMovieTracking.load;
                    
                case 1
                    myMovieTracking =       myMovieTracking.load(varargin{1});

                otherwise
                    error('Wrong input.')


            end
            
            myMovieTracking =      obj.addMovieLibrarySettingsToMovieTracking(myMovieTracking); % have to do a second time because stored file may still have out-of date folder settings


        end
        
        function myMovieTracking =          getMovieTrackingForNickNames(obj, NickNames)
            MyRows =            obj.getLibraryRowsOfNicknames(NickNames);
            myMovieTracking =     obj.ListhWithMovieObjects(MyRows,:);
        end

        function myMovieTracking =          getMovieWithNickName(obj, Nickname)
            myMovieTracking  =      obj.ListhWithMovieObjects{strcmp(obj.getAllNicknames, Nickname)};    
        end
        
        
    end
    
    methods % SETTERS FILTER 

        function struct =       getFilterStructure(obj)
            
            struct.FilterForMovieType =         obj.FilterSelectionString;
            struct.FilterForKeyword =           obj.KeywordFilterSelectionString;
            
        end
        
        function obj =          updateFilterSettingsFromPopupMenu(obj, PopupMenu, PopUpMenuTwo)
            % UPDATEFILTERSETTINGSFROMPOPUPMENU update movie-filter list:
            % 2 arguments of type "matlab.ui.control.UIControl"
            
            assert(isscalar(PopupMenu) && isa(PopupMenu, 'matlab.ui.control.UIControl'), 'Wrong input.')
            assert(isscalar(PopUpMenuTwo) && isa(PopUpMenuTwo, 'matlab.ui.control.UIControl'), 'Wrong input.')

            [SelectedString, Value] =               obj.getStateOfPopupMenu(PopupMenu);
            obj.FilterSelectionString =             SelectedString;
            obj.FilterSelectionIndex =              Value;
            obj.FilterList =                        obj.getFilterListForActiveMovieType;
            
             [SelectedString, Value] =               obj.getStateOfPopupMenu(PopUpMenuTwo); 
            obj.KeywordFilterSelectionIndex =       Value;
            obj.KeywordFilterSelectionString =      SelectedString;
            obj =                                   obj.addKeyWordFilterToFilterList;

        end

    end

    methods % GETTERS LOADED IMAGE-DATA
       
            function ImageData =            getLoadedImageDataOfActiveMovie(obj)
                ImageData = obj.ListWithLoadedImageData{obj.getSelectedRowInLibrary, 1};
            end
        
    end

    
    
    
 
    methods (Access = private) % SETTERS: MOVIE-TRACKING FILES
       
        function obj =      ensureAllMovieTrackingFilesCanConnect(obj, varargin)
            % TESTINTACTNESSOFLIBRARY tests whether all movie entries could be linked to annotation files;
            % if connection is impossible: asks user to change annotation folder or delete unconnected MovieTracking entry;
            % takes 0 or 1 argument:
            % 1: version identifier:

            switch length(varargin)
               
                case 0
                    MyVersion = '';
                case 1
                    MyVersion = varargin{1};
                otherwise
                    error('Wrong input.')
                
            end
            
            KeepGoing = true;
            while KeepGoing
                
                 CouldConnect =          obj.getIndicesOfMoviesThatCanConnect(MyVersion);
                 if min(CouldConnect) == 1
                    fprintf('\nAll movie-tracking files could be found.\n') 
                    KeepGoing = false;
                 else
                    obj = obj.letUserResolveUnconnectedMovieTrackingFiles(CouldConnect);

                 end
             
             
             
            end
             
          end
        
        function obj =      letUserResolveUnconnectedMovieTrackingFiles(obj, CouldConnect)

         
            KeepGoing = true;
            while KeepGoing

                Text{1,1 } =       'Not all movies could be connected. The program can only proceed if this problem is fixed';
                Text{2, 1} =        'You have the following options:';
                Text{3, 1} =       '1: Change annotation folder which contains all the files.';
                Text{4, 1} =       '2: Delete all entries that are unlinked. (The actual files, if they exist will not be deleted.';
                Text{5, 1} =       '3: Crash the program.';

                cellfun(@(x) fprintf('%s\n', x), Text);
                fprintf('\n')

                Input = input('Enter 1, 2 or 3: ');



                if isscalar(Input) && isnumeric(Input)

                    switch Input

                        case 1
                            obj =                       obj.letUserSetAnnotationPath;
                            KeepGoing =                 false;

                        case 2
                            obj =                       obj.clearContentsOfLibraryIndex(~CouldConnect);
                            obj.SelectedNickname =      '';
                            KeepGoing =                 false;

                        case 3
                            error('User decided to crash the program.')





                    end

                end



            end





        end

             function obj =      loadAllMoviesFromFile(obj, varargin)
            
            ListWithNickNames =      obj.getAllNicknames;   
            for index = 1 : length(ListWithNickNames)
                fprintf('\nLoading movie %s. (%i of %i)\n', ListWithNickNames{index}, index, length(ListWithNickNames));
                obj =                   obj.setNewNickname(ListWithNickNames{index});
                myMovieTracking =       obj.getActiveMovieTrackingFromFile(varargin{:});
                obj =                   obj.setLibraryWithActiveMovie(myMovieTracking);
            end 
            
             end
             
                 
        
    end
    
    methods (Access = private) % GETTERS: MOVIE-TRACKING FILES:
        
         function CouldConnect =                 getIndicesOfMoviesThatCanConnect(obj, varargin)
            % GETINDICESOFMOVIESTHATCANCONNECT gets indices of all movies that can connect to source files;
            
            switch length(varargin)
               
                case 0
                    MyVersion = '';
                case 1
                    MyVersion = varargin{1};
                otherwise
                    error('Wrong input.')
            end
            
            fprintf('Testing connection of entire movie list...')
            
            if isempty(obj.getListOfUnLoadedMovieTrackingObjects)
                CouldConnect = true;
            else
                 CouldConnect =         arrayfun(@(x) ...
                                                x.canConnectToSourceFile(MyVersion), ...
                                                obj.getListOfUnLoadedMovieTrackingObjects...
                                                );
                                            
                                             obj.showAllNicknames;
                    obj.showAllUnConnectedNicknames(CouldConnect);

                
            end
            

           

         end
        
          
        
        
    end
    
    methods (Access = private) % ACTION: FILE
        
          function obj =      saveMovieLibraryWithName(obj, MyFileName)
             fprintf('PMMovieLibrary:@saveMovieLibraryToFile: ')
            if obj.allPathsAreValid
                fprintf('Create copy of library, ')
                ImagingProject =                        obj;
                if exist('ImagingProject', 'var')== 1 && ~isempty(MyFileName)
                    fprintf(' remove non-essential data, ')
                    ImagingProject.ListhWithMovieObjects =              cell(obj.getNumberOfMovies,1);
                    ImagingProject.ListWithLoadedImageData =            cell(obj.getNumberOfMovies,1);% remove ListWithMovieObjects; these are now stored in separted files for each movies


                    fprintf(' save library in path "%s".\n', MyFileName)
                    save(MyFileName, 'ImagingProject')
                else
                    warning('Library could not be saved. Reason: either the library did not exist or no file-path was specified')
                end

            else
            warning('Library could not be saved. Reason: Not allPropertiesAreValid')



            end

            
            
          end
        
        
        
    end
    
    methods (Access = private) % GETTERS FILE
        
             function test =                 allPropertiesAreValid(obj)

            SelectedNicknameTest = ~isempty(obj.SelectedNickname); 
            test = obj.allPathsAreValid && SelectedNicknameTest;

        end
        
        function test =                 allPathsAreValid(obj)
            FileNameTest =              ~isempty(obj.FileName);
            ImageAnalysisTest =         ~isempty(obj.PathForImageAnalysis);
            PathOfMovieFolderTest =     ~isempty(obj.PathOfMovieFolder);
            PathForExporTest =          ~isempty(obj.PathForExport);
            
            test =                      FileNameTest && ImageAnalysisTest && PathOfMovieFolderTest && PathForExporTest;
            
        end
        
        function NewPath = letUserPickMovieFolder(obj)
            % LETUSERPICKANNOTATIONFOLDER using uipickfiles
            % starting from current image-analysis folder
                 NewPath=          uipickfiles(...
                                            'FilterSpec', obj.getMovieFolder, ...
                                            'Prompt', 'Select movie folder',...
                                            'NumFiles', 1, ...
                                            'Output', 'char');
           end
        
        
    end
    
    methods (Access = private) % SETTERS SUMMARY
       
          function obj =    showAllNicknames(obj)
              MyNickNames = obj.getAllNicknames;
             fprintf('The library contains the following nicknames:\n')
             cellfun(@(x) fprintf('%s\n', x), MyNickNames);
          end
        
          function obj =    showAllUnConnectedNicknames(obj, CouldConnect)
             MyNickNames = obj.getAllNicknames;
             
             NotConnectedMovies =   find(~CouldConnect);
             
             if isempty(NotConnectedMovies)
                 fprintf('\nAll movies could be connected.\n')
             else
                 fprintf('\nThe following nicknames could not be connected:\n')
                cellfun(@(x) fprintf('%s\n', x), MyNickNames(NotConnectedMovies));
             end
             

          end
             
        
    end
    
    methods (Access = private) % NICKNAMES
       
        
        function check =                        testForPreciselyOneNickNameMatchForString(obj, String)
            numberOfMatches = obj.getNumberOfNickNameMatchesForString(String);
            if numberOfMatches == 1
                check = true;
            else
                check = false; 
            end

        end

        function numberOfMatches =              getNumberOfNickNameMatchesForString(obj, String)
            assert(ischar(String), 'Wrong argument type.')
            NickNames = obj.getAllNicknames;
            if isempty(NickNames)
                numberOfMatches = 0;
            else
                numberOfMatches =   sum(strcmp(String, NickNames));
            end
        end

          function NickName =                     getNickNameOfActiveMovie(obj)
                NickName =  obj.ListWithMovieObjectSummary{obj.getSelectedRowInLibrary}.getNickName;

                assert(~isempty(obj.getNickNameOfActiveMovie), 'Nickname not specified.')

            
            
          
            
          end
          
        function rows = getAllRowsExceptForNicknames(obj, Nicknames)
            rows = obj.getRowsForNicknames(Nicknames);
            rows = ~rows;
        end
        
        
        function rows = getRowsForNicknames(obj, Nicknames)
            
            rows = cell(1, length(Nicknames));
            for index = 1 : length(Nicknames)
                
                rows{1, index} = obj.getRowForNickName(Nicknames{index});
                
            end
            
            rows = cell2mat(rows);
            
            rows = max(rows, [], 2);
            
        end
        
        function [SelectedRow] =   getRowForNickName(obj, NickNameString)
            assert(ischar(NickNameString), 'Wrong input.')
            SelectedRow =                 strcmp(obj.getAllNicknames, NickNameString);
        end

        
    end
    
    methods (Access = private) % SETTERS MOVIELIST: updateMovieIndexWith;
       
        function obj =      updateMovieIndexWith(obj, SelectedRow, MyLoadedMovie, MyLoadedImageVolumes)
            
            assert(isnumeric(SelectedRow) && isscalar(SelectedRow) && ~isnan(SelectedRow), 'Selected row is not valid')
            assert(isa(MyLoadedMovie, 'PMMovieTracking'), 'Movie controller has no LoadedMovie attached.')
            assert(ischar(MyLoadedMovie.getNickName), 'LoadedMovie has no nickname.')
            assert(~isempty(MyLoadedMovie.getLinkedMovieFileNames), 'LoadedMovie has no filenames for image files attached.')

            obj.ListWithMovieObjectSummary{SelectedRow,1} =     PMMovieTrackingSummary(MyLoadedMovie);
            obj.ListhWithMovieObjects{SelectedRow,1} =          MyLoadedMovie;
            obj.ListWithLoadedImageData{SelectedRow,1} =        MyLoadedImageVolumes;
            obj.FilterList(SelectedRow, 1)=                     true;
            
         end
        
        
    end
    
    methods (Access = private) % SETTERS MOVIELIST
        
        function obj =      loadMissingMovieTrackingsFromFile(obj, varargin)
                % MAKEMOVIELISTCOMPLETE goes through every single movie;
                % if already in memory, no changes; if not in memory, load from file;
                % also resets all annotation filenames, and tracking filenames by annotation-folder;
                % takes 0 and 1 arguments;
                % 1: charcter string of desired version (only applies when the movie is not yet in memory);
                
                ListWithNickNames =      obj.getAllNicknames;   

                for index = 1 : length(ListWithNickNames)
                    fprintf('\nLoading movie %s. (%i of %i)\n', ListWithNickNames{index}, index, length(ListWithNickNames));
                    obj = obj.switchActiveMovieByNickName(ListWithNickNames{index},  varargin{:});

                end 

                

        end
        
            
        function obj = setLibraryWithActiveMovie(obj, myMovieTracking)
            
            assert((isa(myMovieTracking, 'PMMovieTracking')) && isscalar(myMovieTracking), 'Wrong input.')
            
            obj.ListhWithMovieObjects{obj.getIndexOfSelectedMovie, 1} =            myMovieTracking;
            obj.ListWithMovieObjectSummary{obj.getIndexOfSelectedMovie,1} =        PMMovieTrackingSummary(myMovieTracking);
        end
        
        
        function obj =      removeMovieListFromMemory(obj)
            % REMOVEMOVIELISTFROMMEMORY deletes all movie-related data that are loaded from file from object;
            obj.ListhWithMovieObjects =                             cell(obj.getNumberOfMovies, 1); % these two are not saved in file: initialize with right number of rows after loading;
            obj.ListWithLoadedImageData =                           cell(obj.getNumberOfMovies, 1);
        end
        
        function obj =      sortAllMovieListsBy(obj, SortList)
            
            if isempty(SortList)
            else
                
                obj.ListWithMovieObjectSummary(:,2) =       SortList;
                obj.ListWithMovieObjectSummary =            sortrows(obj.ListWithMovieObjectSummary, 2);
                obj.ListWithMovieObjectSummary(:,2) =       [];

                FilterListTemp  =                           num2cell(obj.FilterList);
                FilterListTemp(:,2) =                       SortList;
                FilterListTemp =                            sortrows(FilterListTemp, 2);
                FilterListTemp(:,2) =                       [];
                obj.FilterList =                            cell2mat(FilterListTemp);

                obj.ListhWithMovieObjects(:,2) =            SortList;
                obj.ListhWithMovieObjects =                 sortrows(obj.ListhWithMovieObjects, 2);
                obj.ListhWithMovieObjects(:,2) =           [];

                obj.ListWithLoadedImageData(:,2) =         SortList;
                obj.ListWithLoadedImageData =              sortrows(obj.ListWithLoadedImageData, 2);
                obj.ListWithLoadedImageData(:,2) =         [];
            end

          end
        
        function obj =      removeFromLibraryMovieWithNickName(obj, NickName)
            SelectedRow =               obj.getRowForNickName(NickName);
            obj =                       obj.clearContentsOfLibraryIndex(SelectedRow);
            obj.SelectedNickname =      '';
            
        end
        
        function obj =      clearContentsOfLibraryIndex(obj, index)
            obj.ListhWithMovieObjects(index, :)=          [];
            obj.ListWithMovieObjectSummary(index, :)=     [];
            obj.FilterList(index, :)=                     [];
            obj.ListWithLoadedImageData(index, :) =       [];
        end
        
    end
    
    methods (Access = private) % GETTERS MOVIELIST

    
        
        function movieControllers =     getListOfUnLoadedMovieTrackingObjects(obj)
            % GETLISTOFUNLOADEDMOVIETRACKINGOBJECTS returns list of all movie lists (essentially just containing path, but data not loaded);
            movieControllers =          cellfun(@(x) ...
                                                PMMovieTracking(obj.getPathForImageAnalysis, x), ...
                                                    obj.getAllNicknames);
        end

              function check =                testThatPathForImageAnalysisExists(obj)
            check = ~isempty( obj.getPathForImageAnalysis);
        end

        function rowInLibrary =         getIndexOfSelectedMovie(obj)
            rowInLibrary =     obj.getRowForNickName(obj.SelectedNickname);
        end


    end
    
    methods (Access = private) % GETTERS MOVIELIST: MOVIE-FILE PATHS;
       
        function files =        getAllAttachedMoviePaths(obj)
            files =         obj.getAttachedMoviePathsForEachEntry;
            files=          vertcat(files{:});
            if isempty(files)
               files = cell(0,1); 
            end
          end
          
        function files =        getAttachedMoviePathsForEachEntry(obj)
            if isempty(obj.getListhWithMovieObjects)
                files = cell(0,1);
            else
                files =          cellfun(@(x) x.getLinkedMovieFileNames, obj.getListhWithMovieObjects, 'UniformOutput', false);
            end

        end
   
    end
    
    methods (Access = private) % GETTERS MOVIETRACKING
        
        function myMovieTracking = getUnloadedMovieTracking(obj)
            myMovieTracking =       PMMovieTracking;
            myMovieTracking =       myMovieTracking.setNickName(obj.SelectedNickname); % nickname and image-analysis folder are needed for loading files;
            myMovieTracking =       obj.addMovieLibrarySettingsToMovieTracking(myMovieTracking);
            
        end
        
        
        
        
        
    end
    
    methods (Access = private) % SETTERS: applyLibraryPropertiesToMovieTrackingObjects;
       
         function obj =      applyLibraryPropertiesToMovieTrackingObjects(obj)
             obj.ListhWithMovieObjects =     cellfun(@(x)  obj.addMovieLibrarySettingsToMovieTracking( x), obj.ListhWithMovieObjects, 'UniformOutput', false);
         end
        
         function myMovieTracking =      addMovieLibrarySettingsToMovieTracking(obj, myMovieTracking)
            myMovieTracking =       myMovieTracking.setImageAnalysisFolder(obj.getPathForImageAnalysis);
            myMovieTracking =       myMovieTracking.setMovieFolder(obj.getMovieFolder);
         end
        
    end
     
    methods (Access = private)
        
        function [SelectedRow] =     getSelectedRowInLibrary(obj)
            ListWithAllNickNamesInternal =                 getAllNicknames(obj);   
            SelectedRow =                           strcmp(ListWithAllNickNamesInternal, obj.SelectedNickname);
        end
        
        function myMovieTrackingSummary = getInitializedMovieTrackingSummaryWithNickNameAndAttachedFiles(obj, NickName, AttachedFilenames)
            assert(obj.verifyStringIsNotUsedAsNickName(NickName) && obj.testForExistenceOfMovieFiles(AttachedFilenames), 'Invalid content for movie entry.')
            myMovieTrackingSummary =        PMMovieTrackingSummary;              
            myMovieTrackingSummary =        myMovieTrackingSummary.setNickName(NickName);               
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

       

     

         
        
    end
    
    methods (Access = private) % GETTERS: MOVIELIST FILTER
        
        function [SelectedString, Value] = getStateOfPopupMenu(obj, PopupMenu)
                
            if isempty(PopupMenu.Value)
                PopupMenu.Value = 1; 
            end

            if ischar(PopupMenu.String)
                SelectedString =  PopupMenu.String;
            else
                SelectedString =  PopupMenu.String{PopupMenu.Value};                                           
            end
            
            Value = PopupMenu.Value ;
            
        end
        
        function Filter =       getFilterListForActiveMovieType(obj)
            
                switch obj.FilterSelectionString
                    case 'Show all movies'
                        Filter =        obj.getIndicesOfMovies;

                    case 'Show all Z-stacks'
                        Filter =       obj.getIndicesOfZStacks;

                    case 'Show all snapshots'
                        Filter =       obj.getIndicesOfSnapshots;

                    case 'Show all tracked movies'
                        %FilterMovies =            obj.getIndicesOfMovies;
                        FilterTracking =         obj.getIndicesOfTrackedObjects;
                        Filter =         min([ FilterTracking], [], 2); 

                    case 'Show all untracked movies'
                       % FilterMovies =         obj.getIndicesOfMovies;
                        FilterTracking =      cellfun(@(x) ~x.testForExistenceOfTracking, obj.getListhWithMovieObjects);
                        Filter =      min([ FilterTracking], [], 2); 

                    case 'Show all movies with drift correction'   
                        Filter =         cellfun(@(x) x.testForExistenceOfDriftCorrection, obj.getListhWithMovieObjects);

                    case 'Show entire content'
                        Filter =      cellfun(@(x) true, obj.getListhWithMovieObjects);             

                    case 'Show all unmapped movies'
                        Filter =      cellfun(@(x) ~x.isMapped, obj.getListhWithMovieObjects);


                end
            
            
        end
        
        function movies =       getIndicesOfMovies(obj)
            movies =        cellfun(@(x) strcmp(x.getDataType, 'Movie'), obj.getListhWithMovieObjects);
        end
        
        function movies =       getIndicesOfZStacks(obj)
            movies =        cellfun(@(x) strcmp(x.getDataType, 'ZStack'), obj.getListhWithMovieObjects);
        end
        
        function movies =       getIndicesOfSnapshots(obj)
            movies =        cellfun(@(x) strcmp(x.getDataType, 'Snapshot'), obj.getListhWithMovieObjects);
        end
        
        function indices =      getIndicesOfTrackedObjects(obj)
            indices = cellfun(@(x) x.testForExistenceOfTracking, obj.getListhWithMovieObjects);
        end
          
          function FilterSelectionIndex =         getFilterSelectionIndex(obj)
           FilterSelectionIndex = obj.FilterSelectionIndex; 
         end
        
        function FilterList =                   getFilterList(obj)
           FilterList = obj.FilterList; 
        end
        
        
      
    end
    
    methods (Access = private) % keywords FILTER
        
         
            function obj =      addKeyWordFilterToFilterList(obj)

                switch obj.KeywordFilterSelectionString
                    case 'Ignore keywords'
                    case 'Movies with no keyword'
                        obj =          obj.addFilterForMoviesWithNoKeyword;
                    otherwise
                        obj =          obj.addKeywordFilter;
                end
                
            end

            function obj =      addFilterForMoviesWithNoKeyword(obj)

                function check = keyWordCheck(keywords)
                    if isempty(keywords) 
                        check = false;
                    elseif isempty(keywords{1,1})
                        check = false;
                    else
                        check = true;
                    end
                end

                rowsThatHaveNoKeyword =        cellfun(@(x) ~keyWordCheck(x.getKeywords), obj.getListhWithMovieObjects);
                obj.FilterList  =              min([obj.FilterList rowsThatHaveNoKeyword], [], 2);

            end

            function obj =      addKeywordFilter(obj)

                rowsThatHaveNoKeyword =                           cellfun(@(x) isempty(x.getKeywords), obj.getListhWithMovieObjects);
                KeywordFilterList =                               cellfun(@(x) max(strcmp(x.getKeywords, obj.KeywordFilterSelectionString)), obj.getListhWithMovieObjects, 'UniformOutput', false);
                KeywordFilterList(rowsThatHaveNoKeyword,:) =      {false};

                KeywordFilterList =                 cell2mat(KeywordFilterList);
                obj.FilterList =                    min([obj.FilterList,logical(KeywordFilterList)], [], 2);

            end
     
    end
   
end