classdef PMMovieTracking < PMChannels
    %PMMOVIETRACKING manage viewing and tracking of movie
    %   This class manages viewing and tracking.
 
    properties (Access = private) % crucial to save these data:

        AnnotationFolder =          ''   % folder that contains files with annotation information added by user;
        NickName
        Keywords =                  cell(0,1)   
         
        MovieFolder                 % movie folder:
        AttachedFiles =             cell(0,1) % list files that contain movie-information;
       

        DriftCorrection =           PMDriftCorrection
        Interactions      
        
        CurrentVersion =            'AfterAugust2021';

    end

    properties (Access = private) % stop tracking settings:

        StopDistanceLimit =                 15 
        MaxStopDurationForGoSegment =       5
        MinStopDurationForStopSegment =     20

        Tracking =                  PMTrackingNavigation


    end

    properties (Access = private) % is saved but could also be reconstructed from original image file;

        ImageMapPerFile
        TimeCalibration =           PMTimeCalibrationSeries
        SpaceCalibration =          PMSpaceCalibrationSeries 

    end

    properties (Access = private) % movie view

        TimeVisible =                   true
        PlanePositionVisible =          true
        ScaleBarVisible =               1   
        ScaleBarSize =                  50;

        CentroidsAreVisible =           false
        
      
        MasksAreVisible =               false
        ActiveTrackIsHighlighted =      false
        CollapseAllTracking =           false

        CollapseAllPlanes =             1
        
          ActiveTrackIsVisible =             true
        SelectedTracksAreVisible  =    true
        RestingTracksAreVisible =       true
        
        

        CroppingOn =                     0
        CroppingGate =                  [1 1 1 1]

    end

    properties (Access = private) % no need to save:

        Navigation =                        PMNavigationSeries
        AllPossibleEditingActivities =      {'No editing','Manual drift correction','Tracking'};
       
        UnsavedTrackingDataExist =          true

    end

    properties (Access = private) % for view; this should be moved somewhere else
    EnforeMaxProjectionForTrackViews = true;

    end

    methods %initialization 
        
        function obj =  PMMovieTracking(varargin)
            % PMMOVIETRACKING create instance
            % takes 0, 1, 2, 3 or 4 arguments
            % 1: 'PMMovieTrackingSummary' or 'char': Nickname
            % 2: 1: AnnotationFolder; 2: NickName
            % 3: complicated; 1: structure; 2: movie-folder, 3: 0 or 2; 0: "simple" installer, not recommended; 2: indicates older version, will be converted to new;
            % 4: 1: nickname; 2: movie-folder; 3: attached movie files; 4: annotation folder;
           
            
          
            NumberOfInputArguments = length(varargin);
            switch NumberOfInputArguments
                case 0
                    
                case 1
                    
                    switch class(varargin{1})
                       
                        case 'PMMovieTrackingSummary'
                            obj.NickName =          varargin{1}.getNickName;
                            obj.MovieFolder =       varargin{1}.getMovieFolder; 
                            obj.AttachedFiles =     varargin{1}.getAttachedFiles;
                            obj.Keywords =          varargin{1}.getKeywords;
                            
                        case 'char'
                             obj.NickName =          varargin{1};
                            
                        otherwise
                            error('Wrong input.')
                        
                        
                        
                    end
                    
                case 2
                    obj.AnnotationFolder =  varargin{1};
                    obj.NickName =          varargin{2};
            
                case 3
                    
                    assert(isnumeric(varargin{3}), 'Wrong input.')
                    assert(isstruct(varargin{1}), 'Wrong input.')
                    
                    InputStructure =    varargin{1};
                    NumericCode =       varargin{3};
                    
                      switch NumericCode
                           
                        case 0 % this is a simple way to create a very basic object;
                            obj.NickName =                  InputStructure.NickName;
                            obj.MovieFolder =               varargin{2};
                            obj.AttachedFiles =             InputStructure.AttachedFiles;
                            obj.DriftCorrection =           PMDriftCorrection();
                            obj.Tracking =                  PMTrackingNavigation();

                        case 2 % this is for getting date from an older version;
                            obj.NickName =                  InputStructure.NickName;
                            obj.Keywords{1,1}=              InputStructure.Keyword;
                            obj.MovieFolder =               varargin{2};
                            obj.AttachedFiles =             InputStructure.FileInfo.AttachedFileNames;
                           
                            obj.DriftCorrection =           PMDriftCorrection(InputStructure, NumericCode);
                            obj =                           obj.setFrameTo(InputStructure.ViewMovieSettings.CurrentFrame);
                            obj =                           obj.setSelectedPlaneTo(min(InputStructure.ViewMovieSettings.TopPlane:InputStructure.ViewMovieSettings.TopPlane+InputStructure.ViewMovieSettings.PlaneThickness-1));
                            
                       
                            if isfield(InputStructure.MetaData, 'EntireMovie') % without meta-data this field will stay empty; (need channel number to complete this; when using channels: this object must be completed);
                                 NumberOfChannels =     InputStructure.MetaData.EntireMovie.NumberOfChannels;
                                obj.Channels =      obj.setDefaultChannelsForChannelCount(NumberOfChannels);
                             end

                            obj.CollapseAllPlanes =                     InputStructure.ViewMovieSettings.MaximumProjection;
                            obj.PlanePositionVisible =                  InputStructure.ViewMovieSettings.ZAnnotation;
                            obj.TimeVisible =                           InputStructure.ViewMovieSettings.TimeAnnotation;
                            obj.ScaleBarVisible =                       InputStructure.ViewMovieSettings.ScaleBarAnnotation;   

                            if isfield(InputStructure.ViewMovieSettings, 'CropLimits')
                                obj =                      obj.setCroppingGateWithRectange(InputStructure.ViewMovieSettings.CropLimits);
                            else
                                obj =                      obj.resetCroppingGate;
                            end
                            obj.CroppingOn =                            0;
                            obj.Tracking =                               PMTrackingNavigation(InputStructure.TrackingResults,NumericCode);
                        
                        otherwise
                            error('Wrong input.')
                      end 
                       
 
                case 4
                    
                    assert(strcmp(varargin{5}, 'Initialize'), 'Wrong input.')
                    
                    obj.NickName =              varargin{1};
                    obj.MovieFolder        =    varargin{2};  
                    obj.AttachedFiles =         varargin{3}; 
                    obj.AnnotationFolder =      varargin{4};

                otherwise
                    error('Wrong number of arguments')
            end
            
            if ~isa(obj.Interactions, 'PMInteractionsCapture') % not sure if this is a good thing;
                obj.Interactions = PMInteractionsCapture;
            end

        end
        
        function obj = set.ImageMapPerFile(obj, Value)
            
            assert(isvector(Value) && length(Value) == obj.getNumberOfLinkedMovieFiles, 'Wrong input')
            cellfun(@(x) PMImageMap(x), Value); % run this simply to provoke an error if input is wrong;
            obj.ImageMapPerFile = Value;
            
        end
        
        function obj = set.AttachedFiles(obj, Value)
            EmptyRows =                     cellfun(@(x) isempty(x), Value);
            Value(EmptyRows) =   [];
            
            assert(iscellstr(Value), 'Invalid argument type.')
            
            
                            
            % if the user input was a folder, this means a folder with subfiles was selected and the subfiles have to be extracted;
            % currently only the .pic format is organized in this way;
            CheckFolderStatus =     cellfun(@(x) isfolder(x), obj.getMovieFolderPathsForStrings(Value));
            CheckFolderStatus =     unique(CheckFolderStatus);
            if length(CheckFolderStatus) ~=1
                error('Cannot select a mix of files and folder') 
            end

            if CheckFolderStatus
                ListWithExtractedFiles =       obj.extractFileNameListFromFolder(Value);
                Value =                         ListWithExtractedFiles;
            else

            end

            
            obj.AttachedFiles = Value;
        end

        function obj = set.NickName(obj, Value)
            assert(ischar(Value), 'Wrong argument type.')
            obj.NickName =   Value; 
        end

        function obj = set.Keywords(obj, Value)
            assert(iscellstr(Value) && isvector(Value), 'Invalid argument type.')
            obj.Keywords =   Value;
        end
        
        function obj = set.MovieFolder(obj, Value)
            assert(ischar(Value), 'Invalid argument type.')
            obj.MovieFolder = Value;   
        end
        
        function obj = set.AnnotationFolder(obj, Value)
              assert(ischar(Value), 'Wrong argument type.')
              obj.AnnotationFolder = Value;
        end
          
        function obj = set.DriftCorrection(obj, Value)
            assert(isa(Value, 'PMDriftCorrection') && isscalar(Value), 'Wrong input.')
            obj.DriftCorrection = Value;
        end

        function obj = set.SpaceCalibration(obj,Value)
            assert(isa(Value,'PMSpaceCalibrationSeries') , 'Wrong input format.')
            obj.SpaceCalibration =  Value;
        end
        
        function obj = set.Interactions(obj, Value)
            assert(isa(Value, 'PMInteractionsCapture') && isscalar(Value), 'Wrong input.')
            obj.Interactions =      Value;
        end
        
       
        
        function obj = set.Navigation(obj,Value)
             assert(isa(Value,'PMNavigationSeries') && length(Value) == 1, 'Wrong input format.')
            obj.Navigation =  Value;
        end
        

    end
    
    methods % initialize movie view
        
        function obj = set.ScaleBarSize(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.ScaleBarSize = Value;
        end

        function obj = set.CollapseAllPlanes(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CollapseAllPlanes = Value;
        end

        function obj = set.MasksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.MasksAreVisible = Value;
        end

        function obj = set.CentroidsAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CentroidsAreVisible = Value;
        end

        function obj = set.ActiveTrackIsVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ActiveTrackIsVisible = Value;
        end
        
        function obj = set.SelectedTracksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.SelectedTracksAreVisible = Value;
        end
        
        function obj = set.RestingTracksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.RestingTracksAreVisible = Value;
        end

        
        
        function obj = set.TimeVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.TimeVisible = Value;
        end

        function obj = set.PlanePositionVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.PlanePositionVisible = Value;
        end

        function obj = set.ScaleBarVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ScaleBarVisible = Value; 
        end

        function obj = set.ActiveTrackIsHighlighted(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ActiveTrackIsHighlighted = Value; 
        end
        
        function obj = set.CollapseAllTracking(obj, Value)
             assert(isscalar(Value) && islogical(Value), 'Wrong input.')
            obj.CollapseAllTracking = Value;
        end

        function obj = set.CroppingOn(obj, Value)
            assert(isscalar(Value) && islogical(Value), 'Wrong input.')
            obj.CroppingOn = Value;
        end
        
        function obj = set.CroppingGate(obj, Value)
            assert(isnumeric(Value) && isvector(Value) && length(Value) == 4, 'Wrong input.')
            obj.CroppingGate = Value;
        end
        
    end

    methods % initialize advanced tracking
        
        function obj = set.StopDistanceLimit(obj,Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.StopDistanceLimit = Value;
        end
        
        function obj = set.MaxStopDurationForGoSegment(obj,Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.MaxStopDurationForGoSegment = Value;
        end
        
        function obj = set.MinStopDurationForStopSegment(obj,Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.MinStopDurationForStopSegment = Value;
        end
        
        
    end
    
   
    methods % SETTERS ADVANCED TRACKING
        
        function obj = setSpaceAndTimeLimits(obj, Space, TimeMax, TimeMin)
            % SETSPACEANDTIMELIMITS sets limits for confinment duration;
            % takes 3 arguments:
            % 1: maximum distance of confined area
            % 2: maximum time to be considered go segment;
            % 3: minimum time required to be considered go segment;
            obj.StopDistanceLimit =                     Space;
            obj.MaxStopDurationForGoSegment =           TimeMax;
            obj.MinStopDurationForStopSegment =         TimeMin;
        
         end
        
    end
    
    methods % SIMPLE GETTERS
       
        
         function possibleActivities = getPossibleEditingActivities(obj)
            possibleActivities = obj.AllPossibleEditingActivities;
         end
        
         
        
    end
    
    methods % SIMPLE SETTERS
       
        function obj =          setNickName(obj, String)
            % SETNICKNAME simply sets nickname of movie
            % takes 1 argument:
            % 1: character string
            obj.NickName =       String;
        end

        function obj =          setKeywords(obj, Value)
            % SETKEYWORDS set keywords
            % takes 1 argument:
            % 1: cell-string with keywords (default: {'Regular image'});
            
               if isempty(Value)
                  Value = 'Regular image'; 
               end
               
               if iscell(Value)
                  Value = Value{1,1}; 
               end
               
                obj.Keywords{1,1} =                   Value;
        end
          
        function obj =          setNavigation(obj, Value)
            % SETNAVIGATION set navigation
            % takes 1 argument:
            % 1: scalar of 'PMNavigationSeries';
            % also updates drift-correction with new navigation
            obj.Navigation =        Value;
            obj.DriftCorrection =   obj.DriftCorrection.setNavigation(Value);
        end
        
    end
    
    methods % SETTERS VIEW
       
          function obj =      setCollapseAllTrackingTo(obj, Value)
              % SETCOLLAPSEALLTRACKINGTO set whether tracked data of all planes, or just of "visible" planes are shown;
            obj.CollapseAllTracking = Value;
          end
        
        function Value =                            getCollapseAllTracking(obj)
            % GETCOLLAPSEALLTRACKING returns whether tracked data of all planes, or just of "visible" planes are shown;
            Value = obj.CollapseAllTracking;
        end
           
    end
    
    methods % SETTERS FILE-MANAGEMENT

        function obj =    setImageAnalysisFolder(obj, FolderName)
            % SETIMAGEANALYSISFOLDER set image analysis/ annotation folder;
            % takes 1 argument:
            % 1: name of folder ('char')
            % also sets other paths that depend on annotation folder;
                obj.AnnotationFolder =      FolderName;
                obj =                      obj.setPathsThatDependOnAnnotationFolder;
                
        end
        
        function obj =      setMovieFolder(obj, Value)
            % SETMOVIEFOLDER
            % takes 1 argument
            obj.MovieFolder = Value;   
        end
          
        function obj =      setNamesOfMovieFiles(obj, Value)
            % SETNAMESOFMOVIEFILES set names of attached movie files
            % takes 1 argument:
            % 1: cell-string with filenames
            obj.AttachedFiles =       Value;
        end

        function obj =      changeMovieFileNamesFromTo(obj, Old, New)
            % CHANGEMOVIEFILENAMESFROMTO change name of attached filenames;
            % takes 2 arguments:
            % 1: "old" filename;
            % 2: "new" filename;
            % old filename will be replaced with new filename
            OldFileNames =                  obj.AttachedFiles;
            MatchingRows =                  strcmp(OldFileNames, Old);
            OldFileNames(MatchingRows) =    {New};
            obj.AttachedFiles =             OldFileNames;
          
            
        end

        function obj =      load(obj, varargin)
            %LOAD load all data from file (in current file format);
            % takes 0 or 1 argument:
            % 1: files of version that should be loaded: 'BeforeAugust2021', 'AfterAugust2021';

            switch length(varargin)

                case 0
                    obj = obj.loadCurrentVersion;

                case 1
                        if isempty(varargin{1})
                              varargin{1} = obj.CurrentVersion;
                        end


                    assert(ischar(varargin{1}), 'Wrong input.')
                    switch varargin{1}
                        case 'BeforeAugust2021'
                            obj = obj.load_FormatBeforeAugust2021;
                        case 'AfterAugust2021'
                            obj = obj.loadCurrentVersion;
                        otherwise
                            error('Wrong input.')

                    end

                otherwise
                    error('Wrong input.')


            end


            obj.Tracking =          obj.Tracking.setTrackingCellForTimeWithDriftByDriftCorrection(obj.DriftCorrection);

        end

        function obj =      save(obj)
            % SAVE all permanent data into file
            % saves only as current format;
            
            MovieTrackingInfo = obj.getStructureForStorage;
            tic
            save(obj.getPathOfMovieTrackingForSmallFile, 'MovieTrackingInfo')
            a =                 toc;
            fprintf('Saving movie "%s" at path "%s" took %6.1f seconds.\n', obj.NickName, obj.getPathOfMovieTrackingForSmallFile, a)
            obj.Tracking =      obj.Tracking.saveBasic;
            fprintf('\n')

        end

        function obj =      delete(obj, varargin)
            % DELETE delete all files of current format (older formats are left untouched);
            % takes 1 argument:
            % 1: files of version that should be loaded: 'BeforeAugust2021', 'AfterAugust2021';

            switch length(varargin)

                case 1
                       assert(ischar(varargin{1}), 'Wrong input.')

                      ListWithFiles = obj.getAllAnnotationPaths(varargin{1}); 

                       for index = 1 : length(ListWithFiles)
                            CurrentPath =   ListWithFiles{index};
                            if exist(CurrentPath) == 2
                                  delete(CurrentPath);
                            elseif exist(CurrentPath) == 7
                                delete([CurrentPath, '/*']);
                                rmdir(CurrentPath);
                            end
                        end


                otherwise
                    error('Wrong input.')


            end



        end 

        function obj =      setPropertiesFromImageMetaData(obj)
            % SETPROPERTIESFROMIMAGEFILES
            % sets image map, space-calibration, time-calibration, navigation from file (also updates navigation used by drift correction);

            assert(~isempty(obj.getPathsOfImageFiles), 'Could not get paths.')
            
            fprintf('\nPMMovieTracking:@setPropertiesFromImageMetaData.\n')
            myImageFiles =      PMImageFiles(obj.getPathsOfImageFiles);
            assert(~myImageFiles.notAllFilesCouldBeRead, 'Could not connect to all movie-files.')
            
            fprintf('All source files could be accessed. Retrieving MetaData and ImageMaps.\n')

            obj.ImageMapPerFile =              myImageFiles.getImageMapsPerFile; 
            obj.SpaceCalibration =             myImageFiles.getSpaceCalibration; 
            obj.TimeCalibration =              myImageFiles.getTimeCalibration; 
            obj.Navigation =                   myImageFiles.getNavigation; 

            obj.DriftCorrection =              obj.DriftCorrection.setNavigation(obj.Navigation);

            if obj.getNumberOfChannels ~= obj.Navigation.getMaxChannel
                obj = obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);

            end
            
            obj.DriftCorrection =       obj.DriftCorrection.setBlankDriftCorrection;
                    

              

        end
        
        function obj =      setSavingStatus(obj, Value)
            % SETSAVINGSTATUS sets whether most recent version has been saved;
            % takes 1 argument:
            % 1: logical scalar
            obj.UnsavedTrackingDataExist = Value;
        end
        
        function obj =      saveMetaData(obj, varargin)
            % SAVEMETADATA save meta-data
            % takes 1 argument:
            % 1: preferred target path:
            % extracts meta-data from all attached image files and saves in file;

             NumberOfArguments = length(varargin);
             switch NumberOfArguments

                 case 1
                    MetaDataString  =   obj.getMetaDataString;

                    cd(varargin{1})
                    [file, path] =               uiputfile([obj.getNickName, '_MetaDataString.text']);
                    CurrentTargetFilename =      [path, file];
                    if CurrentTargetFilename(1) == 0
                    else
                        fprintf(fopen(CurrentTargetFilename, 'w'), '%s', MetaDataString);
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

                 otherwise
                     error('Wrong input.')
             end

        end
        
        function obj =      saveDerivativeData(obj)
            % SAVEDERIVATIVEDATA exports "derivative" data that are obtained from "raw" data and saved so that they can be retrieved more easily;
            % currently saves metric and pixel "TrackCells" (maks pixels are not saved);
              
            assert(obj.isMapped, 'Need movie to be mapped for this analysis. Use setPropertiesFromImageMetaData');

            TrackingAnalysis =      obj.getTrackingAnalysis;
            TrackingAnalysis =      TrackingAnalysis.setSpaceUnits('�m');
            TrackingAnalysis =      TrackingAnalysis.setTimeUnits('minutes');
            TrackCell_Metric =      TrackingAnalysis.getTrackCell;
            TrackCell_Metric =      cellfun(@(x) x(:, 1 : 5), TrackCell_Metric, 'UniformOutput', false);

            SavePath =              obj.getPathForTrackCell;
            save(SavePath, 'TrackCell_Metric')

            TrackingAnalysis =      TrackingAnalysis.setSpaceUnits('pixels');
            TrackingAnalysis =      TrackingAnalysis.setTimeUnits('frames');
            TrackCell_Pixels =      TrackingAnalysis.getTrackCell;
            TrackCell_Pixels =      cellfun(@(x) x(:, 1 : 5), TrackCell_Pixels, 'UniformOutput', false);

            SavePath =              obj.getPathForTrackCell('TrackCell_Pixels');
            save(SavePath, 'TrackCell_Pixels')
  
          end
            
    end

    methods % GETTERS FILE-MANAGEMENT
        
        function exist = verifyThatEssentialPropertiesAreSet(obj)
              % VERIFYTHATESSENTIALPROPERTIESARESET
              % tests that annotation paths, nickname, movie-folder anbd attached movie-names are all set;
            existOne =          obj.verifyExistenceOfAnnotationPaths;
            existTwo =          ~isempty(obj.MovieFolder);
            existThree =        ~isempty(obj.AttachedFiles);
            exist =             existOne && existTwo && existThree;
         end
           
        function value = canConnectToSourceFile(obj, varargin)
            % CANCONNECTTOSOURCEFILE tests whether all necessary source files are available;
            % takes 0 or 1 arguments:
            % 1: string of version that should be checked (default: current version);
            % returns 1 value:
            % 1: logical scalar
            
            switch length(varargin)
               
                case 0
                    MyVersion = obj.CurrentVersion;
                    
                case 1
                    if isempty(varargin{1})
                        MyVersion = obj.CurrentVersion;
                    else
                        assert(ischar(varargin{1}), 'Wrong input.')
                        MyVersion = varargin{1};
                        
                    end
                    
                    
                otherwise
                    error('Wrong input.')
                
                
            end
            
             value = obj.sourceFileExists_Internal(MyVersion);
            
        
        end

        function Data = getDerivedData(obj, Type)
            % GETDERIVEDDATA get derivative data from file
            % takes 1 argument:
            % 1: type of wanted derivative data ('char': 'TrackCell_Metric', 'TrackCell_Pixels';
            % these are data that are obtained from the "raw" PMMovieTracking data, but are saved in this format so that they can be retrieved more quickly (not lead to perform computations);
              assert(ischar(Type), 'Wrong input.')
              switch Type
                  case 'TrackCell_Metric'
                        Data =  load(obj.getPathForTrackCell, 'TrackCell_Metric');
                        Data =  Data.TrackCell_Metric;
                  case 'TrackCell_Pixels'
                      try
                        Data = load(obj.getPathForTrackCell('TrackCell_Pixels'), 'TrackCell_Pixels');
                          Data = Data.TrackCell_Pixels;
                      catch
                          Data = load(obj.getPathForTrackCell('TrackCell_Metric'), 'TrackCell_Metric'); % not ideal; create the pixel dataset, as long as not filtering for planes might be ok;
                            Data = Data.TrackCell_Metric;
                      end

                  otherwise
                      error('Type not supported.')

              end

        end
        
        function status = getUnsavedDataExist(obj)
            % GETUNSAVEDDATAEXIST
            status = obj.UnsavedTrackingDataExist; 
        end

        
  
    end
  
    methods % SETTERS MOVIE FILE AND DESCRIPTION
        
        function obj = unmap(obj)
         % UNMAP will throw an error
         error('Not allowed to unmap. Only remapping allowed. Use resetFromImageFiles.')
            obj.ImageMapPerFile =                   [];
        end

        function obj = resetFromImageFiles(obj)
         % RESETFROMIMAGEFILES will throw an error
         error('Not supported anymore. Use setPropertiesFromImageMetaData instead.')


        end

        function obj = toggleCollapseAllPlanes(obj)
            % TOGGLECOLLAPSEALLPLANES
            obj.CollapseAllPlanes = ~obj.CollapseAllPlanes;
        end
        
        function obj = setCollapseAllPlanes(obj, Value)
            % SETCOLLAPSEALLPLANES
            obj.CollapseAllPlanes = Value;
        end
      
    end
    
    methods % GETTERS MOVIE FILE AND DESCRIPTION
        
        function info =         getStructure(obj)
            % GETSTRUCTURE returns structure with short Summary of main object settings;
            info.Nickname =             obj.getNickName;
            info.AnnotationFolder =     obj.AnnotationFolder;
            info.Keywords =             obj.getKeywords;
            info.MoviePath =            obj.getPathOfMovieTrackingForSingleFile;
            info.MoviePaths =           obj.getPathsOfImageFiles;
            info.MovieFolder =          obj.getMovieFolder;
            info.MovieFileNames =       obj.getLinkedMovieFileNames;
            info.IsMapped =             obj.isMapped;
            info.MovieFileExtension =   obj.getMovieFileExtension;
            
        end
        
        function name =         getNickName(obj)
             % GETNICKNAME returns string of nickname;
            name = obj.NickName;

        end

        function keywords =     getKeywords(obj)
            % GETKEYWORDS: returns keywords;
            keywords = obj.Keywords; 
        end

        function fileName =     getPathOfMovieTrackingForSingleFile(obj)
            % GETPATHOFMOVIETRACKINGFORSINGLEFILE returns string of complete path of annotation file;
            obj =           obj.verifyAnnotationPaths;
            fileName =      [obj.AnnotationFolder '/' obj.NickName  '.mat'];
        end

        function paths =        getPathsOfImageFiles(obj)
            % GETPATHSOFIMAGEFILES returns empty (no movie-folder exists) or cell array with complete paths of all movie-files;
            assert(~isempty(obj.getMovieFolder), 'Paths can only be created when the movie-folder is set.')
            paths =         obj.getMovieFolderPathsForStrings(obj, obj.getLinkedMovieFileNames);

        end
        
        function movieFolder =  getMovieFolder(obj)
            % GETMOVIEFOLDER: returns string with name of folder that contains raw movie files;
              movieFolder = obj.MovieFolder;   
        end

        function linkeFiles =   getLinkedMovieFileNames(obj)
             % GETLINKEDMOVIEFILENAMES returns list of all attached filenames;
              linkeFiles =  obj.AttachedFiles;  
        end

        function test =         isMapped(obj)
            % ISMAPPED tests whether movie is fully mapped;
            % returns logical scalar
            % to be considered mapped the following requirements must be met;
            % 1) ImageMapPerFile must exist
            % 2) TimeCalibration must exist
            % 3) SpaceCalibration must exist
            % 4) Navigation must be set
            test(1) =       ~isempty(obj.ImageMapPerFile);
            test(2) =       isa(obj.TimeCalibration, 'PMTimeCalibrationSeries');
            test(3) =       isa(obj.SpaceCalibration, 'PMSpaceCalibrationSeries');
            test(4) =       obj.checkCompletenessOfNavigation;
            test =          min(test);

        end

        function extension =    getMovieFileExtension(obj)
            % GETMOVIEFILEEXTENSION returns extension of movie-file source;
            % throws error if extensions of different files don't match;
           [~, ~, NickNames] = cellfun(@(x) fileparts(x), obj.AttachedFiles, 'UniformOutput', false);
           extension = unique(NickNames);
           assert(length(extension) == 1, 'Cannot process diverse extensions.')
           extension = extension{1};
        end

        
        
    end
    
    methods % GETTERS TO GENERATE MOVIE-VIEW
       
        function TempVolumes =          loadImageVolumesForFrames(obj, numericalNeededFrames)
            % LOADIMAGEVOLUMESFORFRAMES loads all unloaded image-volumes of specified time frames;
            % input: vector with indices of frames that should be loaded;
            TempVolumes = obj.loadImageVolumesForFramesInternal(numericalNeededFrames);
        end
        
        function AllConnectionsOk =     checkConnectionToImageFiles(obj)
             % CHECKCONNECTIONTOIMAGEFILES
             AllConnectionsOk = obj.checkWhetherAllImagePathsCanBeLinked;
         end

        function Value =                getCollapseAllPlanes(obj)
            % GETCOLLAPSEALLPLANES
            Value = obj.CollapseAllPlanes;
        end
  
        function imageMapOncell =        getSimplifiedImageMapForDisplay(obj)
            % GETSIMPLIFIEDIMAGEMAPFORDISPLAY returns cell array of image map that is suitable for graphical display;
            
            function result =    convertMultiCellToSingleCell(input)

            Dim =    size(input,1);
            if Dim > 1
               result = '';
               for index = 1 : Dim
                   result = [result ' ' num2str(input(index))];
               end
            else
               result = input;
            end
            end

            myImageMap =        obj.getImageSource.getImageMap;
            imageMapOncell =    cellfun(@(x) convertMultiCellToSingleCell(x), myImageMap(2:end,:), 'UniformOutput', false);

        end
        
        function imageSource = getImageSource(obj)
            % GETIMAGESOURCE
            imageSource = PMImageSource(obj.ImageMapPerFile, obj.Navigation);
        end

        function  rgbImage = convertImageVolumeIntoRgbImage(obj, SourceImageVolume)
            % CONVERTIMAGEVOLUMEINTORGBIMAGE converts "image-volume" into 3-channel rgb image;
            rgbImage = obj.convertImageVolumeIntoRgbImageInternal(SourceImageVolume);
        end

        function filtered = filterImageVolumeByActivePlanes(obj, Volume)
            % FILTERIMAGEVOLUMEBYACTIVEPLANES
            filtered =    Volume(:, :, obj.getListOfVisiblePlanesWithoutDriftCorrection, :, :);
        end

        
        
        
        
    end
    
    methods % SETTERS CROPPING
        
        function obj =              setCroppingGateWithRectange(obj, Rectangle)
            % SETCROPPINGGATEWITHRECTANGE changes position of cropping rectange (does not apply change wehther cropping is applied);
            % 1 argument:
            % 1: vector with 4 numerical values: X-start position, Y-start position, X-width, Y-width;
            % enter pixels without drift correction
            obj.CroppingGate =       Rectangle;
        end

        function obj =              setCroppingStateTo(obj, OnOff)
            % SETCROPPINGSTATETO turn cropping on or off;
            obj.CroppingOn =                                    OnOff;  
        end
        
        function obj =              resetCroppingGate(obj)
            % RESETCROPPINGGATE sets cropping gate to entire image
            % sets cropping gate to the entire X-Y range of the image;
            obj.CroppingGate=                 [ 1 1 obj.Navigation.getMaxColumn obj.Navigation.getMaxRow];
        end

    end
    
    methods % GETTERS CROPPING
        
        function croppingGate =     getAppliedCroppingRectangle(obj)
            % GETAPPLIEDCROPPINGRECTANGLE

            switch obj.CroppingOn
                case 1
                   croppingGate =   obj.getCroppingRectangle;

                otherwise
                    [rows,columns, ~] =     obj.getImageDimensionsWithAppliedDriftCorrection;
                    croppingGate =          [1 1 columns  rows];

            end

          end

        function croppingGate =     getCroppingRectangle(obj)
            % GETCROPPINGRECTANGLE
            % returns numerical vector with four values:
            % 1: start column
            % 2: start row
            % 3: width
            % 4: heigth
            % units are pixels, drift correction is automatically added back;
            croppingGate =          obj.CroppingGate;
            croppingGate(1) =       croppingGate(1) + obj.getAplliedColumnShiftsForActiveFrames;
            croppingGate(2) =       croppingGate(2) + obj.getAplliedRowShiftsForActiveFrames;

        end
        
     
        
        function Value =            getCroppingOn(obj)
            % GETCROPPINGON returns logical scalar of whether cropping is "on";
            Value = obj.CroppingOn ;  
        end

        function  XData =           getXPointsForCroppingRectangleView(obj)
            % GETXPOINTSFORCROPPINGRECTANGLEVIEW returns X coordinates for rectangle;
            % returns 1 value:
            % numerical vector with 5 values for making rectangle;
            StartColumn=    obj.CroppingGate(1) + obj.getAplliedColumnShiftsForActiveFrames;
            XData=          [StartColumn   StartColumn + obj.CroppingGate(3)     StartColumn + obj.CroppingGate(3)   StartColumn       StartColumn];   
        end

        function  YData =           getYPointsForCroppingRectangleView(obj)
            % GETYPOINTSFORCROPPINGRECTANGLEVIEW returns Y coordinates for rectangle;
            % returns 1 value:
            % numerical vector with 5 values for making rectangle;
            StartRow=     obj.CroppingGate(2) + obj.getAplliedRowShiftsForActiveFrames;
            YData=        [StartRow  StartRow StartRow + obj.CroppingGate(4)  StartRow + obj.CroppingGate(4)  StartRow];
        end
  
    end
    
    methods % GETTERS METADATA
        
          function InfoText =              getMetaDataInfoText(obj)
              % GETMETADATAINFOTEXT returns info text about metadata;
              % contains:
              % dimension summary (for each movie)
              % space calibration summary (for each movie)
              %

               dimensionSummaries =          obj.Navigation.getDimensionSummary;
               spaceCalibrationSummary =    obj.SpaceCalibration.getSummary;

               dataPerMovie = cell(length(obj.getLinkedMovieFileNames), 1);
               for index = 1: length(obj.getLinkedMovieFileNames)
                   textForCurrentMovei = [obj.getLinkedMovieFileNames{index}; dimensionSummaries{index}; spaceCalibrationSummary{index}; ' '];
                   dataPerMovie{index, 1} = textForCurrentMovei;

               end
                InfoText =                                          vertcat(dataPerMovie{:});
          end
           
                    
       
        
        
    end
    
    methods % SETTERS NAVIGATION
            
         function obj =      setFrameTo(obj, FrameNumber)
             % SETFRAMETO sets active frame
             % takes 1 argument:
             % 1: frame number
            obj.Navigation =     obj.Navigation.setActiveFrames(FrameNumber);
            obj.Tracking =       obj.Tracking.setActiveFrameTo(FrameNumber);
        end
        
        function obj =       setFocusOnActiveMask(obj)
            % SETFOCUSONACTIVETRACK focuses XY-axis and plane on center of active track;
            obj =           obj.setSelectedPlaneTo(obj.getPlaneOfActiveTrack); % direct change of model:
            obj =           obj.moveCroppingGateToActiveMask;
        end

        function obj =            setSelectedPlaneTo(obj, selectedPlanes)
            % SETSELECTEDPLANETO set selected plane of navigation;
            % takes 1 argument:
            % 1: selected planes
            if isnan(selectedPlanes)
            else
                 obj.Navigation =        obj.Navigation.setActivePlanes(selectedPlanes);
            end
        end
        
        
    end
    
    methods % GETTERS NAVIGATION
        
        function DataType =                     getDataType(obj)
           % GETDATATYPE returns value describing data type
           % returns 1 value:
           % 1: 'Movie', 'ZStack', 'Snapshot', or 'Unspecified'
           if obj.Navigation.getMaxFrame > 1
               DataType =               'Movie';               
           elseif obj.Navigation.getMaxPlane > 1
               DataType =               'ZStack';
           elseif obj.Navigation.getMaxPlane == 1
                DataType =               'Snapshot';
           else
               DataType =               'Unspecified datatype';
           end

       end

        function value =                        imageMatchesDimensions(obj, Image)
            % IMAGEMATCHESDIMENSIONS determines, whether input image matches special dimensions of image-sequence attached with current object;
            % returns 1 value:
            % 1: logical scalar;
            [rows, columns, planes] =                  obj.getImageDimensions;
            value(1) =                      size(Image, 1) == rows;
            value(2) =                      size(Image, 2) == columns;
            value(3) =                      size(Image, 3) == planes;
            value =                         min(value);  
        end
 
        function Navigation =                   getNavigation(obj)
            % GETNAVIGATION gets navigation object
            Navigation =        obj.Navigation;
        end
         
        function plane =                        getMaxPlane(obj)
            % GETMAXPLANE returns number of planes of movie-sequence (does not include drift); 
            plane =         obj.Navigation.getMaxPlane; 
        end
         
        function maxChannel =                   getMaxChannel(obj)
            % GETMAXCHANNEL returns number of channels of movie-sequence (does not include drift);
            maxChannel =    obj.Navigation.getMaxChannel;
        end
         
        function [frameNumbers] =               getMaxFrame(obj)
            % GETMAXFRAME gets number frames of movie-sequence
            frameNumbers =      obj.Navigation.getMaxFrame;
        end
        
        function [rows, columns, planes] =      getImageDimensions(obj)
            % GETIMAGEDIMENSIONS returns dimensions of movie-sequence (does not include drift);
            % returns three values
            % 1: max-plane
            % 2: max-row
            % 3: max-column
            planes =        obj.Navigation.getMaxPlane;
            rows =          obj.Navigation.getMaxRow;
            columns =       obj.Navigation.getMaxColumn;
        end
        
        function [rows, columns, planes ] =     getImageDimensionsWithAppliedDriftCorrection(obj)
            % GETIMAGEDIMENSIONSWITHAPPLIEDDRIFTCORRECTION
            % returns three values:
            % 1: number of rows of image
            % 2: number of columns
            % 3: number of planes
            % all values add the currently applied drift correction to the values;
            rows =      obj.getMaxRowWithAppliedDriftCorrection;
            columns =   obj.getMaxColumnWithAppliedDriftCorrection;
            planes =    obj.getMaxPlaneWithAppliedDriftCorrection;
        end

        function frames =                       getActivePlanes(obj)
            % GETACTIVEPLANES returns active planes (this seems to include drift: if so, inconsistent with max planes, this needs to be fixed);
            frames = obj.Navigation.getActivePlanes;
        end
        
        function frames =                       getActiveFrames(obj)
            % GETACTIVEFRAMES returns active frames
            frames = obj.Navigation.getActiveFrames;
        end

        function visiblePlanes =                getPlanesThatAreVisibleForSegmentation(obj)
            % GETPLANESTHATAREVISIBLEFORSEGMENTATION get planes for which segmentation should be shown;
            % plane number seems to include drift;
            
            switch obj.CollapseAllTracking
                case 1
                   visiblePlanes =          1 : obj.Navigation.getMaxPlaneWithAppliedDriftCorrection;
                otherwise
                    visiblePlanes =         obj.getActivePlanes;
            end
        end
    
        function planeOfActiveTrack =            getPlaneOfActiveTrack(obj)
            % GETPLANEOFACTIVETRACK returns plane of active mask (with active drift-correction);
            [~, ~, planeOfActiveTrack ] =       obj.addDriftCorrection( 0, 0, obj.Tracking.getPlaneOfActiveTrackForFrame(obj.getActiveFrames));
            planeOfActiveTrack =                round(planeOfActiveTrack);
        end
        
    end
    
    methods % GETTERS CALIBRATION
       
        function calibration = getSpaceCalibration(obj)
            % GETSPACECALIBRATION returns space-calibration object
            calibration = obj.SpaceCalibration.Calibrations(1);   
        end
        
        function Value = convertXYZPixelListIntoUm(obj, Value)
            % CONVERTXYZPIXELLISTINTOUM converts XYZ pixel input �m output;
            Value = obj.SpaceCalibration.Calibrations.convertXYZPixelListIntoUm(Value);
        end
        
        function Value = convertYXZUmListIntoPixel(obj, Value)
            % CONVERTYXZUMLISTINTOPIXEL converts XYZ �m input into pixel output;
            Value = obj.SpaceCalibration.Calibrations.convertYXZUmListIntoPixel(Value);
        end
        
         function distance =     getDistanceBetweenXPixels_MicroMeter(obj)
             % GETDISTANCEBETWEENXPIXELS_MICROMETER
            distance = obj.SpaceCalibration.getDistanceBetweenXPixels_MicroMeter;
         end
        
        
    end
    
    methods % SETTERS DRIFT

        function obj =      setDriftCorrection(obj, Value)
            % SETDRIFTCORRECTION set drift correction
            % takes 1 argument:
            % 1: scalar of PMDriftCorrection
            % also updates dependent properties, such as Tracking;
            obj.DriftCorrection =       Value;
            obj =                       obj.setDriftDependentParameters;
            
        end
        
        function obj =      setDriftDependentParameters(obj)
            % SETDRIFTDEPENDENTPARAMETERS sets properties that are influenced by drift-correction;
            obj.DriftCorrection =       obj.DriftCorrection.setNavigation(obj.Navigation);
            obj.Tracking =              obj.Tracking.setTrackingAnalysis(obj.getTrackingAnalysis);
            obj.Tracking =              obj.Tracking.setTrackingCellForTimeWithDriftByDriftCorrection(obj.DriftCorrection);
            % % this really slow and not necessary I think;

        end
        
        function obj =      setDriftCorrectionTo(obj,OnOff)
            % SETDRIFTCORRECTIONTO turn drift correction on or off;
            % takes 1 argument:
            % 1: logical scalar;
            obj.DriftCorrection =   obj.DriftCorrection.setDriftCorrectionActive(OnOff);
        end

        function obj =      applyManualDriftCorrection(obj)
            % APPLYMANUALDRIFTCORRECTION uses current "manual drift" corretion values to update "real" drift correction;
            obj.DriftCorrection =   obj.DriftCorrection.updateByManualDriftCorrection;
        end

    end
    
    methods % GETTERS DRIFT
        
        function myDriftCorrection =                getDriftCorrection(obj)
             % GETDRIFTCORRECTION returns drif-correction
            myDriftCorrection = obj.DriftCorrection;
         end
        
        function DriftCorrectionWasPerformed =      testForExistenceOfDriftCorrection(obj)
            % TESTFOREXISTENCEOFDRIFTCORRECTION returns logical scalar that indicates whether drift correction was performed
           if isempty(obj.DriftCorrection)
                DriftCorrectionWasPerformed =           false;
           else
                DriftCorrectionWasPerformed=            obj.DriftCorrection.testForExistenceOfDriftCorrection;
           end
        end

        function Coordinates =                      getActiveCoordinatesOfManualDriftCorrection(obj)
             % GETACTIVECOORDINATESOFMANUALDRIFTCORRECTION returns coordinates of active drift correction;
             % coordinate at current frame with applied drift correction;
            ManualDriftCorrectionValues =                   obj.DriftCorrection.getManualDriftCorrectionValues;
            ActiveFrame =                                   obj.getActiveFrames;
            xWithoutDrift =                                 ManualDriftCorrectionValues(ActiveFrame, 2);
            yWithoutDrift =                                 ManualDriftCorrectionValues(ActiveFrame, 3);
            planeWithoutDrift =                             ManualDriftCorrectionValues(ActiveFrame, 4);
            [xWithDrift, yWithDrift, zWithDrift ] =         obj.addDriftCorrection(xWithoutDrift, yWithoutDrift, planeWithoutDrift);
            Coordinates =                                   [xWithDrift, yWithDrift, zWithDrift ];

        end
        
        function final =                            getAplliedColumnShiftsForActiveFrames(obj)
            % GETAPLLIEDCOLUMNSHIFTSFORACTIVEFRAMES get current drift-correction for columns;
            shifts =   obj.DriftCorrection.getAppliedColumnShifts;
            final =    shifts(obj.getActiveFrames);
        end

        function final =                            getAplliedRowShiftsForActiveFrames(obj)
            % GETAPLLIEDROWSHIFTSFORACTIVEFRAMES get current drift-correction for rows;
            shifts = obj.getAppliedRowShifts;
            final =    shifts(obj.getActiveFrames);
        end

        function [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
            % REMOVEDRIFTCORRECTION convert coordinates with drift correction to coordinates without drift correction;
            % takes 3 arguments:
            % 1: X-coordinates
            % 2: y-coordinates
            % 3: z-coordinates
            % returns 3 values:
            % 1: X-coordinates
            % 2: y-coordinates
            % 3: z-coordinates
            
            xCoordinates=       xCoordinates - obj.getAplliedColumnShiftsForActiveFrames;
            yCoordinates=       yCoordinates - obj.getAplliedRowShiftsForActiveFrames;
            zCoordinates=       zCoordinates - obj.getAplliedPlaneShiftsForActiveFrames;
            
        end

        function [row, column, plane, frame] =      getCoordinatesForPosition(obj, DownColumn,  MouseDownRow)
            % GETCOORDINATESFORPOSITION converts input coordinates into "verified" coordinates with applied drift correction removed;
            % takes 2 arguments:
            % 1: numerical scalar of column position
            % 2: numerical scalar of row position
            % returns 4 values:
            % 1: row (rounded, drift removed, NaN if out of range)
            % 2: column (rounded, drift removed, NaN if out of range)
            % 2: plane (rounded, drift removed, NaN if out of range)
            % 2: frame (rounded, drift removed, NaN if out of range)
            
            [column, row, plane] =            obj.removeDriftCorrection(DownColumn, MouseDownRow, obj.getActivePlanes);
            [row, column, plane, frame] =     obj.roundCoordinates(row, column, plane, obj.getActiveFrames);
            [row, column, plane]  =           obj.verifyCoordinates(row, column,plane);
        end
        
        function AplliedPlaneShifts = getMaxAplliedColumnShifts(obj)
            % GETMAXAPLLIEDCOLUMNSHIFTS
            AplliedPlaneShifts =  max(obj.DriftCorrection.getAppliedColumnShifts);
        end 
        
    end
    
    methods % SETTERS SUMMARY
        
        function obj = showSummary(obj)
            % SHOWSUMMARY shows summary of object
            
            fprintf('\n*** This PMMovieTracking object manages annotation of a movie-sequence.\n')
            fprintf('The most important functions are to track cells and to correct drift of movie-sequences.\n')
            fprintf('\nTracking is done with the following PMTrackingNavigation object:\n')
            
            obj.Tracking = obj.Tracking.showSummary;
            
            fprintf('\nAnother important feature is support for interaction analysis.\n')
            fprintf('The foundation for this support comes from the following object:\n')
            obj.Interactions = obj.Interactions.showSummary;
            
            fprintf('\nThis object also determines what type of annotation will be displayed.\n')
            if obj.TimeVisible
                fprintf('Captured time of the current frame will be shown.\n')
            else
                fprintf('Captured time of the current frame will not be shown.\n')
            end
            
            if obj.PlanePositionVisible
                fprintf('The depth of the selcted planes will be shown.\n')
            else
                 fprintf('The depth of the selcted planes will not be shown.\n')
            end
            
            if obj.ScaleBarVisible
                fprintf('A scale bar of a size of %i �m will be shown.\n', obj.ScaleBarSize)
            else
                 fprintf('A scale bar will not be shown.\n')
            end
            
            if obj.CollapseAllPlanes
                fprintf('Images are derived from a maximum projection of all planes.\n')
            else
                 fprintf('A scale bar will not be shown.\n')
            end
            
            if obj.CollapseAllTracking
                fprintf('Tracking from all planes will be shown.\n')
            else
                 fprintf('Tracking will be filtered so that only those form specific planes will be shown.\n')
            end
            
            if obj.CentroidsAreVisible
                fprintf('Centroids from tracked cells are shwon.\n')
            else
                fprintf('Centroids from tracked cells are not shwon.\n')
            end
            
            if obj.ActiveTrackIsVisible
                fprintf('Active track is shown.\n')
            else
                 fprintf('Active Track is not shown.\n')
            end
            
            if obj.SelectedTracksAreVisible
                fprintf('SelectedTracksAreVisible tracks are shown.\n')
            else
                 fprintf('SelectedTracksAreVisible track are not shown.\n')
            end
            
            if obj.RestingTracksAreVisible
                fprintf('Resting tracks tracks are shown.\n')
            else
                 fprintf('Resting tracks are not shown.\n')
            end
            
            if obj.MasksAreVisible
                fprintf('Masks are shown.\n')
            else
                 fprintf('Masks are not shown.\n')
             end
         
            if obj.ActiveTrackIsHighlighted
                fprintf('Active tracks are highlighted.\n')
            else
                 fprintf('Active tracks are not highlighted.\n')
            end

            if obj.CroppingOn
                    fprintf('Field of view will be cropped by cropping gate.\n')
            else
                    fprintf('Entire field of view will be shown.\n')
            end

            fprintf('The cropping gate is set to X start = "%i", Y start = "%i", X width = "%i", Y width = "%i".\n', ...
            obj.CroppingGate(1), obj.CroppingGate(2), obj.CroppingGate(3), obj.CroppingGate(4));

            fprintf('\nChannel settings:\n')
            obj.showChannelSummary;
  

        
            
        end
        
        
    end
    
    methods % SETTERS CHANNELS
       
       function obj =   setChannels(obj, Value)
           % SETCHANNELS set Channel property
           % takes 1 argument:
           % 1: 'PMMovieTracking' scalar (extracts its Channels property);
            assert(isa(Value, 'PMMovieTracking') && iscalar(Value), 'Wrong argument type.')
            obj.Channels = Value.Channels;

        end

       function obj =    resetChannelSettings(obj, Value, Field)
           % RESETCHANNELSETTINGS allows setting of Channel property;
           % takes 2 arguments:
           % 1: Value
           % 2: property name 'ChannelTransformsLowIn', 'ChannelTransformsHighIn', 'ChannelColors', 'ChannelComments', 'SelectedChannels', 'ChannelReconstruction';

            switch Field
                case 'ChannelTransformsLowIn'
                    obj = setIntensityLow(obj, Value);
                    
                case 'ChannelTransformsHighIn'
                    obj = setIntensityHigh(obj, Value);
                    
                case 'ChannelColors'
                    obj = setColor(obj, Value);
                    
                case 'ChannelComments'     
                    obj = setComment(obj, Value);
                    
                case 'SelectedChannels'     
                     obj = setVisible(obj, Value);
                     
                case 'ChannelReconstruction'
                    obj = obj.setReconstructionType(Value);   
                    
                otherwise
                    error('Wrong input')

            end

       end
          
    end
    
    methods % SETTERS TRACKING STATE

        function obj = setActiveMaskTo(obj, Code, Column, Row)
            % SETACTIVEMASKTO sets active track and frame by input;
            % takes 3 arguments:
            % 1: number of trackID or "code";
            % 2: column of current position
            % 3: row of current position
            [SelectedTrackID , FrameNumber]   =    obj.getWantedTrackIDFrameFor(Code, Column, Row);
            obj =                                   obj.setActiveTrackWith(SelectedTrackID);
            obj =                                   obj.setFrameTo(FrameNumber); 

        end

        function obj =      setActiveTrackWith(obj, NewTrackID)
            % SETACTIVETRACKWITH set active track
            % takes 1 argument:
            % 1: track ID
            obj.Tracking =      obj.Tracking.setActiveTrackIDTo(NewTrackID);
        end

        function obj =      deleteActiveTrack(obj)
            % DELETEACTIVETRACK deletes a active track
            obj.Tracking  =     obj.Tracking.removeActiveTrack;
        end
        
        function obj =      setSelectedTrackIdsTo(obj, Value)
            % SETSELECTEDTRACKIDSTO sets selected track IDs to input;
            obj.Tracking =  obj.Tracking.setSelectedTrackIdsTo(Value);
        end

        function obj =      addToSelectedTrackIds(obj, TracksToAdd)
            % ADDTOSELECTEDTRACKIDS adds input values to selected tracks;
            obj.Tracking =    obj.Tracking.addToSelectedTrackIds(TracksToAdd);
        end

        function obj =      selectAllTracks(obj)
            % SELECTALLTRACKS all tracks become selected
            obj.Tracking =  obj.Tracking.selectAllTracks;
        end

        function obj = deleteAllTracks(obj)
            % DELETEALLTRACKS delete all tracks
           obj.Tracking =     PMTrackingNavigation();
           obj.Tracking =     obj.Tracking.initializeWithDrifCorrectionAndFrame(obj.DriftCorrection, obj.getMaxFrame);
        end

        function obj =      setTrackingAnalysis(obj)
             % SETTRACKINGANALYSIS set tracking analysis of PMTrackingNavigation object;
             % takes 0 arguments 
            obj.Tracking =      obj.Tracking.setTrackingAnalysis(obj.getTrackingAnalysis);
        end

        function obj =      setPreventDoubleTracking(obj, Value, Value2)
            % SETPREVENTDOUBLETRACKING sets whether double tracking should be prevented;
            % takes 2 arguments:
            % 1: logical scalar
            % 2: distance in which double tracking should be prevented
            obj.Tracking = obj.Tracking.setPreventDoubleTracking(Value, Value2);
        end

        function obj =      setFinishStatusOfTrackTo(obj, input)
            % SETFINISHSTATUSOFTRACKTO sets "finished-status of active track;
              % takes 1 argument:
                % 1: 'char': 'Finished', 'Unfinished'
            obj.Tracking = obj.Tracking.setInfoOfActiveTrack(input);
            fprintf('Finish status of track %i was changed to "%s".\n', obj.getIdOfActiveTrack, input)
        end

     end
    
    methods % SETTERS TRACKING MANUAL TRACKING
       
        function obj =      updateTrackingWith(obj, Value)
             % UPDATETRACKINGWITH updates state of Tracking object with input;
             % takes 1 argument:
             % 1: 'PMTrackingNavigationAutoTrackView' or 'PMAutoCellRecognitionView';
            obj.Tracking = obj.Tracking.updateWith(Value); 
        end

        function obj =      performTrackingMethod(obj, Value)
            % PERFORMTRACKINGMETHOD call method of PMTrackingNavigation object;
            % takes 1 argument: allows calling a method of the object's, PMTrackingNavigation object;
            % 1: character string: name of method
            try
                if ismethod(obj.Tracking, Value)
                     obj.Tracking =      obj.Tracking.(Value);
                end

            catch ME
                throw(ME)
            end
        end

        function obj =      updateMaskOfActiveTrackByAdding(obj, yList, xList, plane)
            % UPDATEMASKOFACTIVETRACKBYADDING update tracking of active mask with coordinate list;
            % takes 3 arguments:
            % 1: list of Y-coordinates;
            % 2: list of X-coordinates;
            % 3: plane;
            if isempty(yList) || isempty(xList)

            else
                pixelListToAdd =                [yList,xList];
                pixelListToAdd(:,3) =           plane;
                pixelList_AfterAdding =         unique([obj.Tracking.getPixelsOfActiveTrackForFrames(obj.getActiveFrames); pixelListToAdd], 'rows');
                mySegementationCapture =        PMSegmentationCapture(pixelList_AfterAdding, 'Manual');
                obj =                           obj.resetActivePixelListWith(mySegementationCapture);

            end

        end

        function obj =      resetActivePixelListWith(obj, SegmentationCapture)
            % RESETACTIVEPIXELLISTWITH rests tracking automatically by SegmentationCapture argument;
            % takes 1 argument
            % 1: scalar of PMSegmentationCapture

            assert(isscalar(SegmentationCapture) && isa(SegmentationCapture, 'PMSegmentationCapture'), 'Wrong input.')  
            if isnan(obj.getIdOfActiveTrack)
                error('No valid active track. Therefore no action taken.')

            else

               % obj.Tracking =
               % obj.Tracking.setTrackingAnalysis(obj.getTrackingAnalysis);
               % % this is done somewhere else now; otherwise too slow;
               % check if this is ok now;
                try 
                    obj.Tracking =      obj.Tracking.addSegmentation(SegmentationCapture);
                catch ME
                    throw(ME)
                end

                obj =               obj.setSavingStatus(true);

            end

        end

        function obj =      mergeActiveTrackWithTrack(obj, IDOfTrackToMerge)
            % MERGEACTIVETRACKWITHTRACK merges active track with inputted track ID;
            % takes 1 argument:
            % 1: numeric scalar: ID of track with which to merge;
            obj.Tracking =      obj.Tracking.splitTrackAtFrame(obj.getActiveFrames-1, obj.getIdOfActiveTrack, obj.Tracking.generateNewTrackID);
            obj.Tracking =      obj.Tracking.mergeTracks([obj.getIdOfActiveTrack,    IDOfTrackToMerge]);
        end

        function obj =      minimizeMasksOfActiveTrackAtFrame(obj, FrameIndex)
           % MINIMIZEMASKSOFACTIVETRACKATFRAME replaces mask of active cell by point mask;
           % takes 1 argument:
           % 1: frame number where mask should be minimized
           obj.Tracking =       obj.Tracking.minimizeActiveTrackAtFrame(FrameIndex);
            obj =               obj.setFrameTo(SourceFrames(FrameIndex));
            obj =               obj.setFocusOnActiveMask;
        end

        function obj =      deleteSelectedTracks(obj)
            % DELETESELECTEDTRACKS deletes all selected tracks
            obj.Tracking  =         obj.Tracking.deleteAllSelectedTracks;
        end

        function obj =      deleteActiveTrackAfterActiveFrame(obj)
            % DELETEACTIVETRACKAFTERACTIVEFRAME 
            obj.Tracking =     obj.Tracking.deleteActiveTrackAfterFrame(obj.getActiveFrames);
        end

        function obj =      deleteActiveTrackBeforeActiveFrame(obj)
            % DELETEACTIVETRACKBEFOREACTIVEFRAME
            obj.Tracking =   obj.Tracking.deleteActiveTrackBeforeFrame(obj.getActiveFrames);
        end

        function obj =      splitTrackAfterActiveFrame(obj)
            %SPLITTRACKAFTERACTIVEFRAME
            obj.Tracking =     obj.Tracking.splitActiveTrackAtFrame(obj.getActiveFrames);
        end

        function obj =      generalCleanup(obj)
            % GENERALCLEANUP calls generalCleanup method of PMTrackingNavigation;
           obj.Tracking = obj.Tracking.generalCleanup;
        end

    end
    
    methods % SETTERS TRACKING AUTO-CELL RECOGNITION
        
         function obj =          executeAutoCellRecognition(obj, myCellRecognition)
            % EXECUTEAUTOCELLRECOGNITION recognizes new cells by circle recognition and addes to PMMovieTracking object;
            % takes 1 argument:
            % 1: cell recognition object

            myCellRecognition =     myCellRecognition.performAutoDetection;
            obj.Tracking =          obj.Tracking.setAutomatedCellRecognition(myCellRecognition);
            fprintf('\nCell recognition finished!\n')

            obj.Tracking =          obj.Tracking.setPreventDoubleTracking(true);

            fprintf('\nAdding cells into track database ...\n')
            for CurrentFrame = myCellRecognition.getSelectedFrames' % loop through each frame 
                fprintf('Processing frame %i ...\n', CurrentFrame)
                obj =           obj.setFrameTo(CurrentFrame);

                PixelsOfCurrentFrame =      myCellRecognition.getDetectedCoordinates{CurrentFrame,1};
                for CellIndex = 1 : size(PixelsOfCurrentFrame,1) % loop through all cells within each frame and add to Tracking data
                    obj =      obj.setActiveTrackWith(obj.findNewTrackID);
                    try
                        obj =      obj.resetActivePixelListWith(PMSegmentationCapture(PixelsOfCurrentFrame{CellIndex,1}, 'DetectCircles'));
                    catch

                    end
                end
            end

            obj.Tracking = obj.Tracking.setPreventDoubleTracking(true);

            fprintf('Cell were added into the database!\n')
        end

    end
    
    methods % SETTERS TRACKING AUTO-TRACKING
       
        function obj =          mergeTracksWithinDistance(obj, distance)
              % MERGETRACKSWITHINDISTANCE linking tracks
              % takes 1 argument:
              % 1: number of accepted "gap frames":
              % negative: connects tracks that show some overlap
              % positive: connects tracks that are separated by 1 or more frames;
              % 0: connects gap that fit exactly;
                 obj.Tracking =             obj.Tracking.setDistanceLimitZForTrackingMerging(2);
                 obj.Tracking =             obj.Tracking.setShowDetailedMergeInformation(true);
                 if isnan(distance)
                 else
                    obj.Tracking =        obj.Tracking.trackingByFindingUniqueTargetWithinConfines(distance);
                 end
          end
          
        function obj =          performAutoTrackingOfExistingMasks(obj)
            % PERFORMAUTOTRACKINGOFEXISTINGMASKS performs autTrackingProcedure method of Tracking;
             obj.Tracking =     obj.Tracking.autTrackingProcedure(obj.DriftCorrection, obj.SpaceCalibration, obj.TimeCalibration);
        end
         
    end
    
    methods % GETTERS TRACKING: BASIC
          
        function numberOfTracks =                   getNumberOfTracks(obj)
            % GETNUMBEROFTRACKS returns number of tracks
            numberOfTracks = obj.Tracking.getNumberOfTracks;
        end
        
        function tracking =                         getTracking(obj)
            % GETTRACKING returns Tracking object
            tracking = obj.Tracking; 
        end
        
         function Tracking =                       testForExistenceOfTracking(obj)
            % TESTFOREXISTENCEOFTRACKING tests whether tracking was performed;
            % returns 1 value:
            % 1: logical scalar: true when at least one track was created, otherwise false;
            if isempty(obj.Tracking)
                Tracking =           false;
            else
                Tracking=            obj.Tracking.testForExistenceOfTracks;
            end
         end
         
        function myStopTracking =                   getStopTrackingOfActiveTrack(obj)
            % GETSTOPTRACKINGOFACTIVETRACK returns PMStopTracking object of active track;
            myStopTracking =                PMStopTracking([obj.getFramesInMinutesOfActiveTrack, obj.getMetricCoordinatesOfActiveTrack]);
            myStopTracking =                myStopTracking.setSpaceAndTimeLimits(obj.StopDistanceLimit, obj.MaxStopDurationForGoSegment, obj.MinStopDurationForStopSegment);

        end
        

    end
    
    methods % GETTERS TRACKING: TRACK-IDS
        
        function TrackIDsToShow =       getIDsOfAllVisibleTracks(obj)
            % GETIDSOFALLVISIBLETRACKS returns list of all track-IDs that should be shown;
            TrackIDsToShow = zeros(0,1);
            if obj.getTrackVisibility
                TrackIDsToShow = [TrackIDsToShow; obj.getIdOfActiveTrack];
            end

            if obj.getSelectedTracksAreVisible
                TrackIDsToShow = [TrackIDsToShow; obj.getSelectedTrackIDs];
            end

            if obj.getRestingTracksAreVisible
                TrackIDsToShow = [TrackIDsToShow; obj.getIdsOfRestingTracks];
            end


        end
        
        function IdOfActiveTrack =      getIdOfActiveTrack(obj)
            % GETIDOFACTIVETRACK
            IdOfActiveTrack =               obj.Tracking.getIdOfActiveTrack;
        end

        function trackIds =             getAllTrackIDs(obj)
            % GETALLTRACKIDS
            trackIds =                      obj.Tracking.getListWithAllUniqueTrackIDs;
        end

        function trackIds =             getSelectedTrackIDs(obj)
            % GETSELECTEDTRACKIDS
            trackIds =                      obj.Tracking.getIdsOfSelectedTracks;
        end

        function trackIds =             getIdsOfRestingTracks(obj)
            % GETIDSOFRESTINGTRACKS returns all non-active and non-selected tracks;
            trackIds =                      obj.Tracking.getIdsOfRestingTracks;
        end

        function trackIDs =             getUnfinishedTrackIDs(obj)
            % GETUNFINISHEDTRACKIDS
            trackIDs =                      obj.Tracking.getUnfinishedTrackIDs;
        end  
        
        function SelectedTrackID =      getTrackIDClosestToPosition(obj, MouseColumn, MouseRow)
            % GETTRACKIDCLOSESTTOPOSITION returns trackID that is physically closest to input;
            % takes 2 arguments:
            % 1: column;
            % 2: row;
            frame =                                             obj.getActiveFrames;
            [ClickedColumn, ClickedRow, ClickedPlane] =         obj.removeDriftCorrection(MouseColumn, MouseRow, obj.getActivePlanes);
            [ClickedRow, ClickedColumn, ClickedPlane, ~] =      obj.roundCoordinates(ClickedRow, ClickedColumn, ClickedPlane, frame);
            SelectedTrackID=                                    obj.getIdOfTrackThatIsClosestToPoint([ClickedRow, ClickedColumn, ClickedPlane]);

        end

        function newTrackID =           findNewTrackID(obj)
            % FINDNEWTRACKID returns suitable ID for new track (ID that is not used yet);
            newTrackID =    obj.Tracking.generateNewTrackID;
            fprintf('Tracking identified %i as new track ID.\n', newTrackID)
        end
       
        function trackIDs =             getTrackIDsWhereNextFrameHasNoMask(obj)
               % GETTRACKIDSWHERENEXTFRAMEHASNOMASK returns all trackIDs where next frame has no mask;
            if obj.getActiveFrames >= obj.Navigation.getMaxFrame 
                trackIDs =                                  zeros(0,1);
            else                
                TrackIDsOfNextFrame =                                   obj.Tracking.getTrackIDsOfFrame(obj.getActiveFrames + 1);
                trackIDs =                                setdiff(obj.getTrackIDsOfCurrentFrame, TrackIDsOfNextFrame);
            end
            
        end
        
        function trackIDs =             getTrackIDsOfCurrentFrame(obj)
            % GETTRACKIDSOFCURRENTFRAME % returns list of track-IDs of current frame;
            trackIDs =                                   obj.Tracking.getTrackIDsOfFrame(obj.getActiveFrames);
        end
    
    end
    
    methods % GETTERS TRACKING: TRACKING SEGMENTATION CONTENT

        function coordinates =                      getCoordinatesForTrackIDs(obj, TrackIDs)
            % GETCOORDINATESFORTRACKIDS returns coordinates for specified track IDs and planes;
            % takes 1 arguments:
            % 1: vector with wanted track IDs
            % returns 1 value:
            % cell array:   one cell contains coordinates for each track:
            %               each cell contains numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;    
            % coordinates are filtered for "visible planes" and coordinates are adjusted for active drift-correction;
            coordinates =        obj.Tracking.getCoordinatesForTrackIDsPlanes(TrackIDs, obj.getPlanesThatAreVisibleForSegmentation, obj.DriftCorrection);
        end

        function segmentationOfActiveTrack =        getSegmentationOfActiveMask(obj)
            % GETSEGMENTATIONOFACTIVEMASK returns segmentation of active track filtered for active frame ("active mask");
            segmentationOfActiveTrack =    obj.Tracking.getActiveSegmentationForFrames(obj.Navigation.getActiveFrames);
        end 

        function pixelList_Modified =               getPixelsFromActiveMaskAfterRemovalOf(obj, pixelListToRemove)
            % GETPIXELSFROMACTIVEMASKAFTERREMOVALOF returns pixel list of active track (after removal of pixels where X and Y coordinates match input pixel list);

            if ~(isempty(pixelListToRemove(:,1)) || isempty(pixelListToRemove(:,2)))  
                pixelList_Original =        obj.Tracking.getPixelsOfActiveTrackForFrames(obj.getActiveFrames);
                deleteRows =                ismember(pixelList_Original(:,1:2), [pixelListToRemove(:,1) pixelListToRemove(:,2)], 'rows');
                pixelList_Modified =        pixelList_Original;
                pixelList_Modified(deleteRows,:) =               [];
            end
        end

        function MySegmentation =                   getUnfilteredSegmentationOfActiveTrack(obj)
            % GETUNFILTEREDSEGMENTATIONOFACTIVETRACK returns segmentation for track ID;
            % returns 1 value:
            % segmentation list for all frames where wanted TrackID was successfully tracked;
            MySegmentation =        obj.Tracking.getSegmentationForTrackID(obj.getIdOfActiveTrack);
        end

        function [segmentationOfCurrentFrame ] =    getUnfilteredSegmentationOfCurrentFrame(obj)
            % GETUNFILTEREDSEGMENTATIONOFCURRENTFRAME returns segmentation of current frame;
            % returns 1 value:
            % segmentation list for all cells of current frame;
            segmentationOfCurrentFrame =        obj.Tracking.getSegmentationOfFrame( obj.Navigation.getActiveFrames);
        end

        function metricCoordinatesForEachSegment =  getMetricCoordinatesOfActiveTrackFilteredForFrames(obj, myFrames)
            % GETMETRICCOORDINATESOFACTIVETRACKFILTEREDFORFRAMES returns metric coordinates of active track, filtered for input;
            % takes 1 argument:
            % 1: numerical vector with wanted frame-numbers
            % returns 1 value:
            % numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;   
            % out of plane-range coordinates are replaced with NaN;
            MyTrackMatrix =                         [obj.Tracking.getFramesOfActiveTrack, obj.getMetricCoordinatesOfActiveTrack];
            metricCoordinatesForEachSegment =       obj.Tracking.filterMatrixByFirstColumnForValues(MyTrackMatrix, myFrames);
            metricCoordinatesForEachSegment =       metricCoordinatesForEachSegment(:, 2:4);
        end

        function metricCoordinates =                getMetricCoordinatesOfActiveTrack(obj)
            % GETMETRICCOORDINATESOFACTIVETRACK returns metric coordinates of active track;
            % returns 1 value:
            % numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;   
            % out of plane-range coordinates are replaced with NaN;
            metricCoordinates =     obj.getSpaceCalibration.convertXYZPixelListIntoUm(obj.getCoordinatesForActiveTrack);  
        end

        function coordinates =                      getCoordinatesForActiveTrack(obj)
            % GETCOORDINATESFORACTIVETRACK returns coordinates of active track;
            % returns 1 value:
            % numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;   
            % out of plane-range coordinates are replaced with NaN;
            coordinates =        obj.Tracking.getCoordinatesForActiveTrackPlanes(obj.getPlanesThatAreVisibleForSegmentation, obj.DriftCorrection);
        end

    end
    
    methods % GETTERS TRACKING: FRAME INFORMATION
        
        function FramesInMinutesForGoSegments =  getMetricFramesOfStopSegmentsOfActiveTrack(obj)
            % GETMETRICFRAMESOFSTOPSEGMENTSOFACTIVETRACK returns cell-array;
            % each cell contains list of time of all frames in minutes
            TimeInMinutesForEachFrame=              obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;
            FramesInMinutesForGoSegments =          cellfun(@(x)   TimeInMinutesForEachFrame(x), obj.getFramesOfStopSegmentsOfActiveTrack, 'UniformOutput', false);
        end
        
        function frameList =                     getFramesOfStopSegmentsOfActiveTrack(obj)
             % GETFRAMESOFSTOPSEGMENTSOFACTIVETRACK returns cell-array;
             % each cell contains list of time of all frames of all stop tracks contain within parental track;
                frameList =         obj.getStopTrackingOfActiveTrack.getStartAndEndRowsOfStopTracks;
         end

        function FramesInMinutesForGoSegments =  getMetricFramesOfGoSegmentsOfActiveTrack(obj)
            % GETMETRICFRAMESOFGOSEGMENTSOFACTIVETRACK returns cell-array;
            % each cell contains list of time of all frames in minutes
             TimeInMinutesForEachFrame=         obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;
             FramesInMinutesForGoSegments =     cellfun(@(x)   TimeInMinutesForEachFrame(x),obj.getFramesOfGoSegmentsOfActiveTrack, 'UniformOutput', false);
        end

        function frameList =                     getFramesOfGoSegmentsOfActiveTrack(obj)
             % GETFRAMESOFGOSEGMENTSOFACTIVETRACK returns cell-array;
             % each cell contains list of time of all frames of all go tracks contain within parental track;
            frameList =                         obj.getStopTrackingOfActiveTrack.getStartAndEndRowsOfGoTracks;
        end

        function TimeInMinutesForActiveTrack =   getFramesInMinutesOfActiveTrack(obj)
            % GETFRAMESINMINUTESOFACTIVETRACK returns numerical vector with minute times of all frames of active track; 
            TimeInMinutesForEachFrame=          obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;
            TimeInMinutesForActiveTrack =       TimeInMinutesForEachFrame(obj.Tracking.getFramesOfActiveTrack);
        end

        function GapFrames =                     getGapFrames(obj, Parameter)
            % GETGAPFRAMES returns vector of gap-frames:
            % takes 1 argument: 'forward' or 'backward'
            % 'forward': returns "empty frames" between current frame and next tracked frame for active track;
            % 'backward': returns "empty frames" between active frame and last untracked frame in backwards direction;

            switch Parameter
                case 'forward'

                    GapFrames =    obj.getActiveFrames + 1 : obj.getLastUntrackedFrameAfterActiveFrame;
                    fprintf('Looking for gap immediately after active frame %i.', obj.getActiveFrames)
                    if isempty(GapFrames)
                        fprintf('There is no gap.\n')
                    else
                        fprintf('There is a gap between frames %i and %i.\n', min(GapFrames), max(GapFrames))
                    end

                case 'backward'
                    GapFrames =      obj.getActiveFrames - 1 : -1 : obj.firstUntrackedFrame;
                    fprintf('Looking for gap immediately before active frame %i.', obj.getActiveFrames)
                    if isempty(GapFrames)
                        fprintf('There is no gap.\n')
                    else
                        fprintf('There is a gap between frames %i and %i.\n', max(GapFrames), min(GapFrames))
                    end
                    
                otherwise
                    error('Wrong input.')
            end



        end

        function lastUntrackedFrame =            getLastUntrackedFrameAfterActiveFrame(obj)
            % GETLASTUNTRACKEDFRAMEAFTERACTIVEFRAME returns frame
            % if currently located on tracked frame: return empty
            % if no tracked after current frame: return last frame
            % otherwise: get frame before next tracked frame

            FramesOfActiveTrack  =          obj.Tracking.getFramesOfActiveTrack;

            Index = find(FramesOfActiveTrack > obj.getActiveFrames,  1, 'first');
            if isempty(Index)
                lastUntrackedFrame =        obj.Navigation.getMaxFrame;
            elseif FramesOfActiveTrack(Index) == obj.getActiveFrames + 1
                lastUntrackedFrame = zeros(0, 1);
            else
                lastUntrackedFrame =        FramesOfActiveTrack(Index) - 1;
            end

        end

        function firstUntrackedFrame =           firstUntrackedFrame(obj)
            % FIRSTUNTRACKEDFRAME returns last untracked frame (in reverse direction);

            FramesOfActiveTrack  =              obj.Tracking.getFramesOfActiveTrack;
            % get first untracked frame:
            BeforeFirstUntrackedFrame =             find(FramesOfActiveTrack < obj.getActiveFrames,  1, 'last');
            if isempty(BeforeFirstUntrackedFrame)
                firstUntrackedFrame =          1;
            else
                firstUntrackedFrame =          FramesOfActiveTrack(BeforeFirstUntrackedFrame) + 1;
            end

        end
        
        function [first, last] =                 getFirstLastContiguousUntrackedFrame(obj)
            % GETFIRSTLASTCONTIGUOUSUNTRACKEDFRAME returns two values
            % 1: first untracked frame (relative to current frame)
            % 2: last untracked frame (relative to current frame)
            last = obj.getLastUntrackedFrameAfterActiveFrame;
            first = obj.firstUntrackedFrame;
        end

        function frame =                         getLastTrackedFrame(obj, parameter)
            % GETLASTTRACKEDFRAME returns frame number based on tracking status;
            % takes 1 argument: 'up' or 'down'
            % returns 1 value:
            % 1: numerical scalar
            % if the current frame is untracked: NaN;
            % 'up': if the current frame is tracked: find last tracked frame after current frame;
            % 'down': if the current frame is tracked: find first tracked frame before current frame;
            
             AllFramesOfActiveTrack = obj.Tracking.getFrameNumbersForTrackID(obj.getIdOfActiveTrack);
            
                % from a contiguous stretch of tracked frames: get first or last frame in this contiguous sequence;
                if ~ismember(obj.getActiveFrames, AllFramesOfActiveTrack) % perform this analysis only when the current position is tracked;
                      frame = NaN;
                else
                   
                     switch parameter
                        case 'up' 
                                frame =      PMVector(AllFramesOfActiveTrack).getLastValueOfGaplessIntegerSeriesStartingFromValue(obj.getActiveFrames);
                        case 'down'
                            frame =          PMVector(AllFramesOfActiveTrack).getFirstValueOfGaplessIntegerSeriesStartingFromValue(obj.getActiveFrames);
                         otherwise
                             error('Input not supported') 
                    end
                    
                end   
        end

        
    end
    
    methods % GETTERS TRACKING ANALYSIS

    function TrackingAnalysis =     getTrackingAnalysis(obj)
        % GETTRACKINGANALYSIS
        TrackingAnalysis =  PMTrackingAnalysis(...
                                    obj.Tracking, ...
                                    obj.DriftCorrection, ...
                                    obj.SpaceCalibration, ...
                                    obj.TimeCalibration...
                                    );
    end


    end

    methods % SETTERS INTERACTIONS

     function obj = updateWith(obj, Value)
         % UPDATEWITH 
         % takes 1 argument:
         % 1: PMInteractionsCapture object

         switch class(Value)
             case 'PMInteractionsCapture'
                  obj.Interactions =          Value;
             otherwise
                 error('Input not supported.')


         end


    end

    end

    methods % GETTERS INTERACTIONS
        
         function interactions = getInteractions(obj)
             % GETINTERACTIONS returns 'PMInteractionsCapture' object;
            interactions = obj.Interactions;
         end
         
        function thresholds = getDefaultThresholdsForAllPlanes(obj)
            % GETDEFAULTTHRESHOLDSFORALLPLANES returns default threshold values;
            % numeric vector with a number for each plane;
            thresholds(1: obj.getMaxPlane, 1) = 30;

        end

        
    end
 
    methods % SETTERS TRACKING ANNOTATION VIEWS

        function obj = toggleCentroidVisibility(obj)
            % TOGGLECENTROIDVISIBILITY
            obj.CentroidsAreVisible = ~obj.CentroidsAreVisible;
        end

        function obj = setCentroidVisibility(obj, Value)
            % CENTROIDSAREVISIBLE
            % takes 1 argument:
            % 1: logical scalar
            obj.CentroidsAreVisible = Value;
        end

        function obj = toggleTrackVisibility(obj)
            % TOGGLETRACKVISIBILITY
            obj.ActiveTrackIsVisible = ~obj.ActiveTrackIsVisible;
        end

        function obj = setTrackVisibility(obj, Value)
            % SETTRACKVISIBILITY
            % takes 1 argument:
            % 1: logical scalar
            obj.ActiveTrackIsVisible = Value;
        end

        function obj = toggleSelectedTracksAreVisible(obj)
            % TOGGLESELECTEDTRACKSAREVISIBLE
            obj.SelectedTracksAreVisible = ~obj.SelectedTracksAreVisible;
        end

        function obj = setSelectedTracksAreVisible(obj, Value)
            % SETSELECTEDTRACKSAREVISIBLE
            % takes 1 argument:
            % 1: logical scalar
            obj.SelectedTracksAreVisible = Value;
        end

        function obj = setRestingTracksAreVisible(obj, Value)
            % SETRESTINGTRACKSAREVISIBLE
            % takes 1 argument:
            % 1: logical scalar
            obj.RestingTracksAreVisible = Value;
        end

        function obj = toggleMaskVisibility(obj)
            % TOGGLEMASKVISIBILITY
            obj.MasksAreVisible = ~obj.MasksAreVisible;
        end

        function obj = setMaskVisibility(obj, Value)
            % SETMASKVISIBILITY
            % takes 1 argument:
            % 1: logical scalar
            obj.MasksAreVisible = Value;
        end
        
    end
    
    methods % GETTERS TRACKING ANNOTATION VIEWS
        
        function Value = getMaskVisibility(obj)
            % GETMASKVISIBILITY
            Value = obj.MasksAreVisible;
        end
        
        function Value = getCentroidVisibility(obj)
            % GETCENTROIDVISIBILITY
            Value = obj.CentroidsAreVisible;
        end
        
        function Value = getTrackVisibility(obj)
            % GETTRACKVISIBILITY
            Value = obj.ActiveTrackIsVisible;
        end
        
        function Value = getSelectedTracksAreVisible(obj)
            % GETSELECTEDTRACKSAREVISIBLE
            Value = obj.SelectedTracksAreVisible;
        end
        
        function Value = getRestingTracksAreVisible(obj)
            % GETRESTINGTRACKSAREVISIBLE
            Value = obj.RestingTracksAreVisible;
        end
      
        
    end
    
    methods % SETTERS ANNOTATION VIEWS (TIME, PLANE, SPACE-CALIBRATION)
        
          function obj =    setScaleBarSize(obj, Value)
             % SETSCALEBARSIZE
             % takes 1 argument:
             % 1: numeric scalar
            obj.ScaleBarSize = Value;
        end
         
          function obj =    toggleScaleBarVisibility(obj)
              % TOGGLESCALEBARVISIBILITY
             obj.ScaleBarVisible = ~obj.ScaleBarVisible; 
          end
          
          function obj =    setScaleBarVisibility(obj, Value)
              % SETSCALEBARVISIBILITY
             obj.ScaleBarVisible = Value; 
          end
          
          function obj =    hideScale(obj)
              % HIDESCALE
            obj.ScaleBarVisible =          false;
          end
        
          function obj =    showScale(obj)
              % SHOWSCALE
             obj.ScaleBarVisible =          tru;
          end

          
          function obj =    setTimeVisibility(obj, Value)
              % SETTIMEVISIBILITY
              obj.TimeVisible = Value;
          end

          function obj =    hideTime(obj)
              % HIDETIME
              obj.TimeVisible =     false;
          end
        
          function obj =    showTime(obj)
              % SHOWTIME
            obj.TimeVisible =     true;
          end
          
          
          function obj =    setPlaneVisibility(obj, Value)
              % SETPLANEVISIBILITY
             obj.PlanePositionVisible = Value;
          end
         
          function obj =    hidePlane(obj)
              % HIDEPLANE
              obj.PlanePositionVisible = false;
          end
        
          function obj =    showPlane(obj)
              % SHOWPLANE
              obj.PlanePositionVisible = true;  
          end
              
    end
    
    methods % GETTERS ANNOTATION VIEWS (TIME, PLANE, SPACE-CALIBRATION)
       
        function Value =        getScaleBarVisibility(obj)
        % GETSCALEBARVISIBILITY
        Value = obj.ScaleBarVisible; 
        end

        function Value =        getScaleBarSize(obj)
        % GETSCALEBARSIZE
        Value = obj.ScaleBarSize;
        end

        function Visible =      getTimeVisibility(obj)
        % GETTIMEVISIBILITY
        Visible = obj.TimeVisible;
        end

        function value =        getPlaneVisibility(obj)
        % GETPLANEVISIBILITY
        value = obj.PlanePositionVisible;
        end

        function strings =      getTimeStamps(obj)
            % GETTIMESTAMPS returns cell string with formatted time of active frame;

            TimeInSeconds=                obj.TimeCalibration.getRelativeTimeStampsInSeconds;

            TimeInMinutes=                TimeInSeconds / 60;
            MinutesInteger=               floor(TimeInMinutes);
            SecondsInteger=               round((TimeInMinutes- MinutesInteger)*60);
            SecondsString=                (arrayfun(@(x) num2str(x), SecondsInteger, 'UniformOutput', false));
            MinutesString=                (arrayfun(@(x) num2str(x), MinutesInteger, 'UniformOutput', false));
            strings=           cellfun(@(x,y) strcat(x, '''', y, '"'), MinutesString, SecondsString, 'UniformOutput', false);
        end

        function planeStamps =  getPlaneStamps(obj) 
            % GETPLANESTAMPS returns cell string with for all Z-planes
              PlanesAfterDrift =         obj.Navigation.getMaxPlane + max(obj.DriftCorrection.getAplliedPlaneShifts);
              planeStamps =             (arrayfun(@(x) sprintf('Z-depth= %i �m', int16((x-1) * obj.SpaceCalibration.getDistanceBetweenZPixels_MicroMeter)), 1:PlanesAfterDrift, 'UniformOutput', false))';;
        end

        function string  =      getActivePlaneStamp(obj)
            % GETACTIVEPLANESTAMP
            myPlaneStamps =     obj.getPlaneStamps;
            string =            myPlaneStamps{obj.getActivePlanes};
        end

        function string  =      getActiveTimeStamp(obj)
            % GETACTIVETIMESTAMP
            myTimeStamps =      obj.getTimeStamps;
            string =            myTimeStamps{obj.getActiveFrames};
        end
     
    end
    
    methods % GETTERS METADATA
       
        function summary =              getMetaDataSummary(obj)
            % GETMETADATASUMMARY
            summary = PMImageFiles(obj.getPathsOfImageFiles).getMetaDataSummary;
        end
        
        function MetaDataString =       getMetaDataString(obj)
            % GETMETADATASTRING
            MetaDataString =             PMImageFiles(obj.getPathsOfImageFiles).getMetaDataString;
        end
   
    end
    
    methods (Access = private) % SETTERS CROPPING
        
        function obj =              moveCroppingGateToActiveMask(obj)
            % MOVECROPPINGGATETOACTIVEMASK sets center of cropping gate to current position of active track;
            % takes 0 arguments
            Coordinates =   obj.Tracking.getCoordinatesOfActiveTrackForFrame(obj.getActiveFrames);
            if isempty(Coordinates)
            else
                obj =           obj.moveCroppingGateToNewCenter(Coordinates(1), Coordinates(2));
            end

        end

        function obj =              moveCroppingGateToNewCenter(obj, centerX, centerY)
            if ~isnan(centerX)
                obj.CroppingGate(1) =        centerX - obj.CroppingGate(3) / 2;
                obj.CroppingGate(2) =        centerY - obj.CroppingGate(4) / 2; 
            end
        end
        
        
    end
    
    methods (Access = private) % getImageDimensionsWithAppliedDriftCorrection

      function rows = getMaxRowWithAppliedDriftCorrection(obj)
        rows =          obj.Navigation.getMaxRow + obj.getMaxAplliedRowShifts;
    end

    function columns = getMaxColumnWithAppliedDriftCorrection(obj)
        columns =       obj.Navigation.getMaxColumn +obj.getMaxAplliedColumnShifts;
    end

    function planes = getMaxPlaneWithAppliedDriftCorrection(obj)
        planes =        obj.Navigation.getMaxPlane + obj.getMaxAplliedPlaneShifts;
    end  


   end

    methods (Access = private) % SETTERS FILE-MANAGEMENT

        function obj =      setPathsThatDependOnAnnotationFolder(obj)
            % SETPATHSTHATDEPENDONANNOTATIONFOLDER changes paths that depend on annotation folder path
            % sets folder for tracking-data
             obj.Tracking =          obj.Tracking.setMainFolder(obj.getTrackingFolder);

        end
        
        function obj =      loadCurrentVersion(obj)
            assert(obj.canConnectToSourceFile, 'File was not stored in currently required format.')

            obj =                   obj.loadDataForFileFormat_AfterAugust2021;
            obj.Tracking =          PMTrackingNavigation(obj.getTrackingFolder);
            try
                obj.Tracking =      obj.Tracking.load;
            catch
            % if no file is available, simply use the "blank" tracking
            end

        end

        function obj =      load_FormatBeforeAugust2021(obj)
            % LOADFORMATBEFOREAUGUST2021 load PMMovieTracking for file-formats before August2021;

            OriginalAnnotationFolder =  obj.AnnotationFolder;
            OriginalMovieFolder =       obj.MovieFolder;

            obj =                       obj.loadDataForFileFormatBefore_August2021;

            obj =                       obj.setImageAnalysisFolder(OriginalAnnotationFolder);
            obj =                       obj.setMovieFolder(OriginalMovieFolder);

        end

        function obj =      loadDataForFileFormat_AfterAugust2021(obj)

            tic
            fprintf('Loading "%s": ', obj.getPathOfMovieTrackingForSmallFile)
            load(obj.getPathOfMovieTrackingForSmallFile, 'MovieTrackingInfo');

            obj.NickName  =                     MovieTrackingInfo.File.NickName         ;
            obj.MovieFolder =                   MovieTrackingInfo.File.MovieFolder   ;                % movie folder:
            obj.AttachedFiles =                 MovieTrackingInfo.File.AttachedFiles     ;
            obj.AnnotationFolder =              MovieTrackingInfo.File.AnnotationFolder   ;

            obj.Keywords =                      MovieTrackingInfo.File.Keywords;
            
            obj.DriftCorrection  =              MovieTrackingInfo.File.DriftCorrection     ;
            obj.Interactions =                  MovieTrackingInfo.File.Interactions        ;

            obj.StopDistanceLimit =             MovieTrackingInfo.StopTracking.StopDistanceLimit            ;
            obj.MaxStopDurationForGoSegment =   MovieTrackingInfo.StopTracking.MaxStopDurationForGoSegment;    
            obj.MinStopDurationForStopSegment = MovieTrackingInfo.StopTracking.MinStopDurationForStopSegment  ;

            obj.ImageMapPerFile =               MovieTrackingInfo.ImageMapPerFile        ;
            obj.TimeCalibration =               MovieTrackingInfo.TimeCalibration         ;
            obj.SpaceCalibration =              MovieTrackingInfo.SpaceCalibration        ;
            obj.Navigation =                    MovieTrackingInfo.Navigation   ;  

            obj.TimeVisible =                   MovieTrackingInfo.MovieView.TimeVisible         ;
            obj.PlanePositionVisible =          MovieTrackingInfo.MovieView.PlanePositionVisible  ;
            obj.ScaleBarVisible =               logical(MovieTrackingInfo.MovieView.ScaleBarVisible        );
            obj.ScaleBarSize =                  MovieTrackingInfo.MovieView.ScaleBarSize         ;

            obj.CentroidsAreVisible =           MovieTrackingInfo.MovieView.CentroidsAreVisible  ;
            
            if isfield(MovieTrackingInfo.MovieView, 'ActiveTrackIsVisible')
                obj.ActiveTrackIsVisible =              MovieTrackingInfo.MovieView.ActiveTrackIsVisible      ;
            else
                obj.ActiveTrackIsVisible =  true;
            end
            
             if isfield(MovieTrackingInfo.MovieView, 'SelectedTracksAreVisible')
                obj.SelectedTracksAreVisible =              MovieTrackingInfo.MovieView.SelectedTracksAreVisible      ;
            else
                obj.SelectedTracksAreVisible =  true;
             end
            
              if isfield(MovieTrackingInfo.MovieView, 'RestingTracksAreVisible')
                obj.RestingTracksAreVisible =              MovieTrackingInfo.MovieView.RestingTracksAreVisible      ;
            else
                obj.RestingTracksAreVisible =  false;
            end
            
            
            
            
            
            obj.MasksAreVisible =               MovieTrackingInfo.MovieView.MasksAreVisible        ;
            obj.ActiveTrackIsHighlighted =      MovieTrackingInfo.MovieView.ActiveTrackIsHighlighted ;
            obj.CollapseAllTracking =           MovieTrackingInfo.MovieView.CollapseAllTracking    ;

            obj.CollapseAllPlanes =             logical(MovieTrackingInfo.MovieView.CollapseAllPlanes );

            obj.CroppingOn =                    logical(MovieTrackingInfo.MovieView.CroppingOn            );
            obj.CroppingGate =                  MovieTrackingInfo.MovieView.CroppingGate      ;

            obj.ActiveChannel =                 MovieTrackingInfo.Channels.ActiveChannel  ;

            if isempty(MovieTrackingInfo.Channels.Channels)

            else
                obj.Channels = MovieTrackingInfo.Channels.Channels ;
            end
            
            time = toc;
            fprintf(' %6.2f seconds.\n', time)

        end

        function obj =      loadDataForFileFormatBefore_August2021(obj)

            % control what is transferred to new object after loading from
            % file:
            fprintf('PMMovieTracking: Load from old file format.')
            assert(exist(obj.getPathOfMovieTrackingForSingleFile) == 2, 'File not found.')
            tic
            Data =              load(obj.getPathOfMovieTrackingForSingleFile, 'MovieAnnotationData');
            LoadedMovieTracking =        Data.MovieAnnotationData;

            
            
            LoadedMovieTracking = LoadedMovieTracking.setImageAnalysisFolder(obj.AnnotationFolder);
            
            obj = LoadedMovieTracking;
            obj.DriftCorrection =           obj.DriftCorrection.setNavigation(obj.Navigation); % has to be after setting navigation
            if isempty(obj.DriftCorrection)
                obj.DriftCorrection =               PMDriftCorrection;
            end



            if ~obj.isMapped  
                obj =   obj.setPropertiesFromImageMetaData;
            end

            obj.DriftCorrection =       obj.DriftCorrection.update;
            obj.DriftCorrection =       obj.DriftCorrection.setNavigation(obj.Navigation);

             fprintf(' Setting interactions, channels, navigation, calibrations and drift correction took %5.1f seconds.\n', toc)


            obj.Tracking =              obj.Tracking.initializeWithDrifCorrectionAndFrame(obj.DriftCorrection, obj.Navigation.getMaxFrame);

            if isempty(obj.Interactions) || ~isa(obj.Interactions, 'PMInteractionsCapture')
                obj.Interactions =      PMInteractionsCapture;
                obj.Interactions =      obj.Interactions.setWith(obj);

            end
            
            obj = obj.setPathsThatDependOnAnnotationFolder;


        end

        function obj=       renameMovieDataFile(obj, OldPath)

            if isequal(OldPath, obj.getPathOfMovieTrackingForSingleFile)

            else

            status =            movefile(OldPath, obj.getPathOfMovieTrackingForSingleFile);
            if status ~= 1
                error('Renaming file failed.') 
            else
                fprintf('File %s was renamed successfully to %s.\n', OldPath, obj.getPathOfMovieTrackingForSingleFile)
            end

            obj =      obj.setSavingStatus(false);
            end

        end

        function obj =      loadLinkeDataFromFile(obj)
        error('Method not supported anymore. Use load instead.')

        end

        function exists = sourceFileExists_Internal(obj, Version)
            assert(ischar(Version), 'Wrong input.')
                switch Version
                    case 'BeforeAugust2021'
                       exists =  exist(obj.getPathOfMovieTrackingForSingleFile) == 2;
                    case 'AfterAugust2021'
                        exists = exist(obj.getPathOfMovieTrackingForSmallFile) == 2 ;
                    otherwise
                        error('Suggested version not supported.')

                end
        end
        
         function obj = verifyAnnotationPaths(obj)
            assert(obj.verifyExistenceOfAnnotationPaths, 'Invalid annotation filepaths.')
            
         end
         
        
        
          
        
        
        
    end
    
    methods (Access = private) % GETTERS FILE-MANAGEMENT
        
         
       function exist =                        verifyExistenceOfAnnotationPaths(obj)
       exist =  ~isempty(obj.AnnotationFolder) &&  ~isempty(obj.NickName);  
       end
        
        function fileName =                     getPathForTrackCell(obj, varargin)

            if isempty(varargin)
                Name = '_TrackingCell_Metric';
            else
                assert(ischar(varargin{1}), 'Wrong input.')


                switch varargin{1}
                  case 'TrackCell_Pixels'
                      Name = '_TrackingCell_Pixels';
                    case 'TrackCell_Metric'
                         Name = '_TrackingCell_Metric';
                        
                  otherwise
                      error('Wrong input.')

                end
            end



            obj = obj.verifyAnnotationPaths;
            fileName = [obj.AnnotationFolder '_DerivativeData/' obj.NickName Name];
                if exist([obj.AnnotationFolder '_DerivativeData/']) ~=7
                    mkdir( [obj.AnnotationFolder '_DerivativeData/']);
                end
            
            
            
        end
        
     
        function MovieTrackingInfo =            getStructureForStorage(obj)

            MovieTrackingInfo.File.NickName =                       obj.NickName;
            MovieTrackingInfo.File.Keywords =                       obj.Keywords;
            
            
            MovieTrackingInfo.File.MovieFolder       =              obj.MovieFolder;                % movie folder:
            MovieTrackingInfo.File.AttachedFiles =                  obj.AttachedFiles;
            MovieTrackingInfo.File.AnnotationFolder  =              obj.AnnotationFolder;

            MovieTrackingInfo.File.DriftCorrection  =               obj.DriftCorrection;
            MovieTrackingInfo.File.Interactions       =             obj.Interactions.getMiniObject;

            MovieTrackingInfo.StopTracking.StopDistanceLimit =              obj.StopDistanceLimit;
            MovieTrackingInfo.StopTracking.MaxStopDurationForGoSegment =    obj.MaxStopDurationForGoSegment;
            MovieTrackingInfo.StopTracking.MinStopDurationForStopSegment =  obj.MinStopDurationForStopSegment;

            MovieTrackingInfo.ImageMapPerFile =                     obj.ImageMapPerFile;
            MovieTrackingInfo.TimeCalibration =                     obj.TimeCalibration;
            MovieTrackingInfo.SpaceCalibration =                    obj.SpaceCalibration;
            MovieTrackingInfo.Navigation =                          obj.Navigation;


            MovieTrackingInfo.MovieView.TimeVisible =               obj.TimeVisible;
            MovieTrackingInfo.MovieView.PlanePositionVisible =      obj.PlanePositionVisible;
            MovieTrackingInfo.MovieView.ScaleBarVisible =           obj.ScaleBarVisible;
            MovieTrackingInfo.MovieView.ScaleBarSize =              obj.ScaleBarSize;

            MovieTrackingInfo.MovieView.CentroidsAreVisible =       obj.CentroidsAreVisible;
            
            
            MovieTrackingInfo.MovieView.ActiveTrackIsVisible =              obj.ActiveTrackIsVisible;
            MovieTrackingInfo.MovieView.SelectedTracksAreVisible =          obj.SelectedTracksAreVisible;
            MovieTrackingInfo.MovieView.RestingTracksAreVisible =           obj.RestingTracksAreVisible;

            
            MovieTrackingInfo.MovieView.MasksAreVisible =           obj.MasksAreVisible;
            MovieTrackingInfo.MovieView.ActiveTrackIsHighlighted =  obj.ActiveTrackIsHighlighted;
            MovieTrackingInfo.MovieView.CollapseAllTracking =       obj.CollapseAllTracking;

            MovieTrackingInfo.MovieView.CollapseAllPlanes =         obj.CollapseAllPlanes;

            MovieTrackingInfo.MovieView.CroppingOn =                obj.CroppingOn;
            MovieTrackingInfo.MovieView.CroppingGate =              obj.CroppingGate;

             MovieTrackingInfo.Channels.ActiveChannel =             obj.ActiveChannel ;
             MovieTrackingInfo.Channels.Channels =                  obj.Channels;

        end
  
        function number =                       getNumberOfLinkedMovieFiles(obj)
           number = length(obj.getLinkedMovieFileNames);
        end
        
        function [ListWithFileNamesToAdd] =     extractFileNameListFromFolder(obj, FolderNames)    

            assert(~isempty(obj.getMovieFolder), 'Movie folder must be set.')
            
            PicFolderObjects =          (cellfun(@(x) PMImageBioRadPicFolder([obj.getMovieFolder x]), FolderNames, 'UniformOutput', false))';
            ListWithFiles =             cellfun(@(x) x.FileNameList(:,1), PicFolderObjects,  'UniformOutput', false);
            ListWithFileNamesToAdd =    vertcat(ListWithFiles{:});

        end
           
        
        

    end
    
    methods (Access = private) % GETTERS FILE-MANAGEMENT ANNOTATION

        function paths =        getAllAnnotationPaths(obj, varargin)

            switch length(varargin)
               
                case 1
                    
                    assert(ischar(varargin{1}), 'Wrong input')
                    
                    switch varargin{1}
                       
                        case 'BeforeAugust2021'
                            paths{1,1 } =       obj.getPathOfMovieTrackingForSingleFile;
                         

                        case 'AfterAugust2021'
                               paths{1,1 } =       obj.getPathOfMovieTrackingForSmallFile;
                            paths{2,1 } =       obj.getTrackingFolder;
                            
                        otherwise
                            error('Wrong input')
                    end
              
                    
                    
                otherwise
                    error('Wrong input.')
                
                
            end
            
            

        end

        function fileName =     getBasicMovieTrackingFileName(obj)
            if isempty(obj.AnnotationFolder) || isempty(obj.NickName)
               error('Filename not specified')
            else
                fileName = [obj.AnnotationFolder '/' obj.NickName];
            end

        end

        function fileName =     getPathOfMovieTrackingForSmallFile(obj)
            obj = obj.verifyAnnotationPaths;
            fileName = [obj.AnnotationFolder '/' obj.NickName  '_Small.mat'];

        end

        function Folder =       getTrackingFolder(obj)
             obj =      obj.verifyAnnotationPaths;
            Folder =    [obj.AnnotationFolder '/' obj.NickName '_Tracking'];
        end

    end

    methods (Access = private) % GETTERS MOVIE-FILES
        
        function paths = getMovieFolderPathsForStrings(obj, Value)
            assert(iscellstr(Value), 'Wrong input.')
            paths = cellfun(@(x) [ obj.getMovieFolder '/' x], Value, 'UniformOutput', false);
        end

        function Value = getImageMapsPerFile(obj)
            Value = obj.ImageMapPerFile; 
        end
        
        
        
        
    end
    
    methods (Access = private) % load images from file
        
         function number = getNumberOfOpenFiles(obj)
             number = length(fopen('all'));
         end
         

            function TempVolumes = loadImageVolumesForFramesInternal(obj, ListOfFramesThatShouldBeLoaded)
                assert(isnumeric(ListOfFramesThatShouldBeLoaded) && isvector(ListOfFramesThatShouldBeLoaded), 'Wrong input.')
                
                  TempVolumes =                   cell(length(ListOfFramesThatShouldBeLoaded), 1);
                  if obj.checkWhetherAllImagePathsCanBeLinked 
                         obj =   obj.replaceImageMapPaths;                         
                         TempVolumes =        ...
                             arrayfun(@(x) obj.getImageVolumeForFrame(x), ListOfFramesThatShouldBeLoaded, 'UniformOutput', false);
                  else
                      warning('Image files cannot be accessed. Image files are not updated right now. It is still possible to navigate the tracked cells without image information.')

                  end  
            end

            function obj =    replaceImageMapPaths(obj)

             
                PointerColumn =                     3;
                ListWithPathsToImageFiles = obj.getPathsOfImageFiles;
                for CurrentMapIndex = 1 : obj.getNumberOfLinkedMovieFiles
                    obj.ImageMapPerFile{CurrentMapIndex, 1}( 2 : end, PointerColumn) =       {ListWithPathsToImageFiles{CurrentMapIndex}};
                end

                
                 
            end
          
            
            
         function AllConnectionsOk = checkWhetherAllImagePathsCanBeLinked(obj)
             
                RetrievedPointers =         obj.getFreshPointersOfLinkedImageFilesInternal;
                
                ConnectionFailureList =     arrayfun(@(x) isempty(fopen(x)), RetrievedPointers);
                AllConnectionsOk =          ~max(ConnectionFailureList);
                
                RetrievedPointers(RetrievedPointers == -1) = [];
                if ~isempty(RetrievedPointers)
                    arrayfun(@(x) fclose(x), RetrievedPointers);

                end
                
         end

         function pointers = getFreshPointersOfLinkedImageFilesInternal(obj)

                if isempty( obj.getPathsOfImageFiles)
                    pointers =  '';
                else
                    pointers =        cellfun(@(x) fopen(x), obj.getPathsOfImageFiles);
                end

         end
         
        function ProcessedVolume = getImageVolumeForFrame(obj, FrameNumber)
            
                tic
            
                settings.SourceChannels =          [];
                settings.TargetChannels =          [];
                settings.SourcePlanes =            [];
                settings.TargetPlanes =            [];
                
                settings.TargetFrames =            1;
                settings.SourceFrames =         FrameNumber;
                
                VolumeReadFromFile =      PMImageSource(obj.ImageMapPerFile, obj.Navigation, settings).getImageVolume;
                ProcessedVolume =         PM5DImageVolume(VolumeReadFromFile).filter(obj.getReconstructionTypesOfChannels).getImageVolume;
                
                Time =  toc;
                fprintf('PMMovieTracking: @getImageVolumeForFrame. Loading frame %i from file. Duration: %8.5f seconds.\n', FrameNumber, Time)

        end
        
     
        
        
        
        
    end
   
    methods (Access = private) % GETTERS TRACKING
       
        function [SelectedTrackID, Frame] =             getWantedTrackIDFrameFor(obj, Code, Column, Row)
             % GETWANTEDTRACKIDFRAMEFOR returns track ID and frame number based on the user input;
             % takes 3 arguments:
             % 1: numeric scalar (track ID) or 
             %          'char': 'byMousePositition', 'nextUnfinishedTrack', 'firstForwardGapInNextTrack', 'firstForwardGapInNextUnfinishedTrack', 'backWardGapInNextUnfinishedTrack';
             % 2: active "column" (only relevant when using 'byMousePositition'); 
             % 3: active "row" (only relevant when using 'byMousePositition'); 


            Type = class(Code);
            switch Type
                
                case 'double'
                    SelectedTrackID =      Input;
                    Frame =         NaN;

                case 'char'
                    switch Input
                         case 'nextUnfinishedTrack'
                            [SelectedTrackID , Frame]  =  obj.toggleUnfinishedTracks('forward');
                            
                        case 'byMousePositition'
                            SelectedTrackID =     obj.getTrackIDClosestToPosition(Column, Row);
                            Frame = NaN;

                        case 'firstForwardGapInNextTrack'
                            [SelectedTrackID , Frame]  = obj.toggleTrackForwardGapsIgnoreComplete;


                        case 'firstForwardGapInNextUnfinishedTrack'
                            [SelectedTrackID , Frame]   = obj.toggleTrackForwardGaps;

                        case 'backWardGapInNextUnfinishedTrack'
                            [SelectedTrackID , Frame]  = obj.toggleTrackBackwardGaps;

                        otherwise
                            error('Wrong input.')
                    end

                otherwise
                    error('Wrong input.')
            end

          end
         
        function [SelectedTrackId , Position]=          toggleUnfinishedTracks(obj, GapDescriptor)
            [SelectedTrackId , Position]=   obj.getTracking.selectTrackIdForTogglingFromList(obj.getUnfinishedTrackIDs, '', GapDescriptor);
        end
        
        function [SelectedTrackId , Position] =         toggleTrackForwardGapsIgnoreComplete(obj)
            [Gaps, TrackIdsToToggle] =          obj.getLimitsOfSurroundedFirstForwardGapOfAllTracks;
            [SelectedTrackId , Position]=       obj.getTracking.selectTrackIdForTogglingFromList(TrackIdsToToggle, Gaps, 'Forward');
            assert(~isempty(SelectedTrackId), 'Could not find target track Id.')

        end
        
        function [SelectedTrackId , Position] =         toggleTrackForwardGaps(obj)
            % TOGGLETRACKFORWARDGAPS
            [ListWithFirstGapRanges, PossibleTrackIDs] =          obj.getLimitsOfUnfinishedForwardGaps;
            [SelectedTrackId , Position]=               obj.getTracking.selectTrackIdForTogglingFromList(PossibleTrackIDs, ListWithFirstGapRanges, 'Forward');


        end

        function [SelectedTrackId , Position] =         toggleTrackBackwardGaps(obj)
            [Gaps, TrackIdsToToggle] =       obj.getLimitsOfUnfinishedBackwardGaps;
            [SelectedTrackId , Position]=   obj.getTracking.selectTrackIdForTogglingFromList(TrackIdsToToggle, Gaps, 'Backward');
        end
        
        function indices =                              getIndicesOfFinishedTracksFromList(obj, List)
        indices = obj.Tracking.getIndicesOfFinishedTracksFromList(List); 
        end

        function SelectedTrackID =                      getIdOfTrackThatIsClosestToPoint(obj, Point)

            TrackDataOfCurrentFrame =       obj.Tracking.getSegmentationOfFrame(obj.Navigation.getActiveFrames); 
            OVERLAP =                       find(cellfun(@(x)  ismember(round(Point), round(x(:,1:3)), 'rows'), TrackDataOfCurrentFrame(:,6)));

            if length(OVERLAP) >= 1
            SelectedTrackID =        TrackDataOfCurrentFrame{OVERLAP(1),1};
            else

            YOfAllTracks = cell2mat(TrackDataOfCurrentFrame(:,3));
            XOfAllTracks = cell2mat(TrackDataOfCurrentFrame(:,4));
            ZOfAllTracks = cell2mat(TrackDataOfCurrentFrame(:,5));

            [~,row] =   obj.computeShortestDistance(Point, [YOfAllTracks,XOfAllTracks, ZOfAllTracks]);



            if ~isempty(row)
            SelectedTrackID = TrackDataOfCurrentFrame{row,1};
            else
            SelectedTrackID = NaN ;

            end

            end
        end

        function [distance,row] =                       computeShortestDistance(~, Point, Coordinates)

        if isempty(Coordinates)
        distance = '';
        row = '';
        else
        DistanceX=  Point(2)- Coordinates(:, 2);
        DistanceY=  Point(1)- Coordinates(:, 1);
        DistanceZ=  Point(3)- Coordinates(:, 3);

        if isempty(DistanceX) || isempty(DistanceY) || isempty(DistanceZ)
        Distance=   nan;
        else
        Distance=   sqrt(power(DistanceX,2) + power(DistanceY,2) + power(DistanceZ,2));
        end

        [distance, row]=  min(Distance);


        end


        end
        
        function [row, column, plane, frame] =     roundCoordinates(~, row, column, plane, frame)
            row =          round(row);
            column =       round(column);
            plane =        round(plane);
            frame =             round(frame);
        end
        
      
        
        
     
    end
    
    methods (Access = private) % GETTERS TRACKING LIMITS
        
        function [Gaps, TrackIdsToToggle] =         getLimitsOfUnfinishedForwardGaps(obj)
            [Gaps, TrackIdsToToggle] =        obj.getLimitsOfFirstForwardGapOfAllTracks;
            Indices =                         obj.getIndicesOfFinishedTracksFromList(TrackIdsToToggle);
            TrackIdsToToggle(Indices, :) =    [];  
            Gaps(Indices, :) =               [];

        end 
        
        function [limits, ids] =                    getLimitsOfFirstForwardGapOfAllTracks(obj)
            % GETLIMITSOFFIRSTFORWARDGAPOFALLTRACKS
             % returns 2 values:
                % 1: cell array that contains gap range of each track;
                % 2: numerical vector that contains track IDs of returned tracks;
                % this version includes also "gaps" at the end of each track (unitl max frame);
            [limits, ids] =     obj.Tracking.getLimitsOfFirstForwardGapOfAllTracksForLimitValue( obj.Navigation.getMaxFrame);
        end
        
        function [limits, ids] =                    getLimitsOfSurroundedFirstForwardGapOfAllTracks(obj)
             [limits, ids] =    obj.Tracking.getLimitsOfSurroundedFirstForwardGapOfAllTracks;
        end
        
        function [Gaps, TrackIdsToToggle] =         getLimitsOfUnfinishedBackwardGaps(obj)
            % GETLIMITSOFUNFINISHEDBACKWARDGAPS
            % like GETLIMITSOFFIRSTFORWARDGAPOFALLTRACKS, except that "backward" gaps rather than "foward" gaps are returned;
            [Gaps, TrackIdsToToggle] =            obj.getLimitsOfFirstBackwardGapOfAllTracks;
            Indices =                           obj.getIndicesOfFinishedTracksFromList(TrackIdsToToggle);
            TrackIdsToToggle(Indices, :) =      [];  
            Gaps(Indices, :) = [];
        end

        function [limits, ids] =                    getLimitsOfFirstBackwardGapOfAllTracks(obj)
            [limits, ids] =     obj.Tracking.getLimitsOfFirstBackwardGapOfAllTracksForLimitValue( obj.Navigation.getMaxFrame);

        end
        
        function limits =                           getLimitsOfFirstGapOfActiveTrack(obj)
           limits =             obj.Tracking.getLimitsOfFirstGapOfActiveTrackForLimitValue(obj.Navigation.getMaxFrame); 
        end
         
    end

    methods (Access = private) % navigation: get plane information

        function AplliedPlaneShifts = getMaxAplliedPlaneShifts(obj)
        AplliedPlaneShifts =  max(obj.DriftCorrection.getAplliedPlaneShifts);
        end 

      

    end

    methods (Access = private) % GETTERS DRIFT CORRECTION
        
        function [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates) 
            xCoordinates=         xCoordinates + obj.getAplliedColumnShiftsForActiveFrames;
            yCoordinates=         yCoordinates + obj.getAplliedRowShiftsForActiveFrames;
            zCoordinates=         zCoordinates + obj.getAplliedPlaneShiftsForActiveFrames;
        end

        function AplliedPlaneShifts = getMaxAplliedRowShifts(obj)
            AplliedPlaneShifts =  max(obj.getAppliedRowShifts);
        end 

        function AplliedRowShifts = getAppliedRowShifts(obj)
            AplliedRowShifts = obj.DriftCorrection.getAppliedRowShifts;
        end

        function final = getAplliedPlaneShiftsForActiveFrames(obj)
            shifts =    obj.DriftCorrection.getAplliedPlaneShifts;
            final =     shifts(obj.getActiveFrames);
        end
        
      

        
        
    end
      
    methods (Access = private) % verify user input
         
         function  [rowFinal, columnFinal, planeFinal] =                         verifyCoordinates(obj, rowFinal, columnFinal,planeFinal)
            rowFinal =      obj.verifyYCoordinate(rowFinal);
            columnFinal =   obj.verifyXCoordinate(columnFinal);
            planeFinal =    obj.verifyZCoordinate(planeFinal);

          end
        
        
        function rowFinal = verifyYCoordinate(obj, rowFinal)
            if     rowFinal>=1 && rowFinal<=obj.Navigation.getMaxRow 
            else
                rowFinal = NaN;
            end
        end

        function columnFinal = verifyXCoordinate(obj, columnFinal)
            if    columnFinal>=1 && columnFinal<=obj.Navigation.getMaxColumn 
            else
              columnFinal = NaN;
            end
        end

        function planeFinal = verifyZCoordinate(obj, planeFinal)
            if    planeFinal>=1 && planeFinal<=obj.Navigation.getMaxPlane
            else
              planeFinal = NaN;
            end
        end
           
               
         
     end
     
    methods (Access = private) % image processing for rgb-image presentation;
        
           function rgbImage = convertImageVolumeIntoRgbImageInternal(obj, SourceImageVolume)
               
                if isempty(SourceImageVolume)
                     rgbImage = 0;

                else

                        ImageVolume_Source = obj.filterImageVolumeByActivePlanes(SourceImageVolume);
                        
                        myRgbImage =    PMRGBImage(...
                                                ImageVolume_Source, ...
                                                obj.getIndicesOfVisibleChannels, ...
                                                obj.getIntensityLowOfVisibleChannels, ...
                                                obj.getIntensityHighOfVisibleChannels, ...
                                                obj.getColorStringOfVisibleChannels ...
                                                );

                        rgbImage =      myRgbImage.getImage;

                end

           end
            
           
            
            function VisiblePlanesWithoutDriftCorrection = getListOfVisiblePlanesWithoutDriftCorrection(obj)

                if obj.DriftCorrection.getDriftCorrectionActive
                     VisiblePlanesWithoutDriftCorrection =      obj.removeDriftCorrectionFromPlaneList(obj.getPlanesThatAreVisibleForSegmentation);
                     
                else
                    VisiblePlanesWithoutDriftCorrection =       obj.getPlanesThatAreVisibleForSegmentation;
                    
                end


            end
            
            function PlanesWithoutDrift = removeDriftCorrectionFromPlaneList(obj, PlanesWithDrift)
                PlanesWithoutDrift =                            PlanesWithDrift - obj.getAplliedPlaneShiftsForActiveFrames;
                PlanesWithoutDrift(PlanesWithoutDrift < 1) =      [];
                PlanesWithoutDrift(PlanesWithoutDrift > obj.Navigation.getMaxPlane) = [];
            end

           

    end
    
    methods (Access = private)
        
        function complete = checkCompletenessOfNavigation(obj)
            if isempty(obj.Navigation.Navigations)
                complete = false;
            else
                complete = true;
            end
            
        end
        

        %% get planes as in source (i.e. without drift correction):
       

    
        function obj = setChannelsToDefault(obj)
            obj = obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);
        end
                    
  
        
       
    
      
          
        
         
    end
          
end