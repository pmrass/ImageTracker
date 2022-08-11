classdef PMMovieTracking < PMChannels
    %PMMOVIETRACKING manage viewing and tracking of movie
    %   This class manages viewing and tracking.
 
    properties (Access = private) % crucial to save these data:

        AnnotationFolder =                      ''   % folder that contains files with annotation information added by user;
        NickName
        Keywords =                              cell(0,1)   
         
        MovieFolder                             % movie folder:
        AttachedFiles =                         cell(0,1) % list files that contain movie-information;
        WantedScene
       

        DriftCorrection =                       PMDriftCorrection
              
        
        CurrentVersion =                        'AfterAugust2021';
        
        LoadedImageVolumes
        DefaultNumberOfLoadedFrames =           40
              
        MaskColor =                             [NaN NaN 150]; % some settings for how 
         
        
        SegmentationCapture
        
    end
    
    properties (Access = private) % interactions
        
        Interactions
        
        
    end

    properties (Access = private) % stop tracking settings:

        StopDistanceLimit =                 15 
        MaxStopDurationForGoSegment =       5
        MinStopDurationForStopSegment =     20

        Tracking =                          PMTrackingNavigationController
        
        
        
        AutoCellRecognition


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

    methods % INITIALIZATION 
        
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
                            obj.Tracking =                  PMTrackingNavigationController(PMTrackingNavigation());

                        case 2 % this is for getting date from an older version;
                            obj.NickName =                  InputStructure.NickName;
                            obj.Keywords{1,1}=              InputStructure.Keyword;
                            obj.MovieFolder =               varargin{2};
                            obj.AttachedFiles =             InputStructure.FileInfo.AttachedFileNames;
                           
                            obj.DriftCorrection =           PMDriftCorrection(InputStructure, NumericCode);
                            obj =                           obj.setFrameTo(InputStructure.ViewMovieSettings.CurrentFrame);
                            
                            InputPlane =                    min(InputStructure.ViewMovieSettings.TopPlane : ...
                                                                    InputStructure.ViewMovieSettings.TopPlane + ...
                                                                    InputStructure.ViewMovieSettings.PlaneThickness-1);
                                                                
                            obj =                           obj.setSelectedPlaneTo(InputPlane);
                            
                       
                            if isfield(InputStructure.MetaData, 'EntireMovie') % without meta-data this field will stay empty; (need channel number to complete this; when using channels: this object must be completed);
                                 NumberOfChannels =     InputStructure.MetaData.EntireMovie.NumberOfChannels;
                                obj =                   obj.setChannels(obj.setDefaultChannelsForChannelCount(NumberOfChannels));
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
                            obj.Tracking =                               PMTrackingNavigationController(PMTrackingNavigation(InputStructure.TrackingResults,NumericCode));
                        
                        otherwise
                            error('Wrong input.')
                      end 
                       
 
                case 4
                    
                    
                    obj.NickName =              varargin{1};
                    obj.MovieFolder        =    varargin{2};  
                    obj.AttachedFiles =         varargin{3}; 
                    obj.AnnotationFolder =      varargin{4};

                otherwise
                    error('Wrong number of arguments')
                    
            end
            
            if ~isa(obj.Interactions, 'PMInteractionsCapture')
                obj.Interactions = PMInteractionsCapture;
                XYLimitForNeighborArea =                50;
                ZLimitsForNeighborArea =                8;

                obj.Interactions =       obj.Interactions.setXYLimitForNeighborArea(XYLimitForNeighborArea);
                obj.Interactions =       obj.Interactions.setZLimitForNeighborArea(ZLimitsForNeighborArea);

            
            end

        end
        
        function obj = set.AutoCellRecognition(obj, Value)
            assert(isa(Value, 'PMAutoCellRecognition') && isscalar(Value), 'Wrong input.')
           obj.AutoCellRecognition = Value ;
        end
        
        function obj = set.Tracking(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMTrackingNavigationController'), 'This property was PMTrackingNavigation but is now PMTrackingNavigationController. Please convert.')
            
           obj.Tracking= Value; 
        end
        
        function obj = set.ImageMapPerFile(obj, Value)
            
            assert(isvector(Value) && length(Value) == obj.getNumberOfLinkedMovieFiles, 'Wrong input')
        %    cellfun(@(x) PMImageMap(x), Value); % run this simply to provoke an error if input is wrong; don't use it super slow;
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
        
        function obj = set.WantedScene(obj, Value)
            
            if isempty(Value)
                
            else
                assert(isnumeric(Value) && Value >= 1 && mod(Value, 1) == 0, 'Wrong argument type.')
                
            end
            
            
            obj.WantedScene =   Value; 
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
        
           function obj = set.LoadedImageVolumes(obj, Value)
            
             assert(iscell(Value) && isvector(Value), 'Wrong input.')
             assert(length(Value) == obj.getMaxFrame, 'Wrong input.')

            obj.LoadedImageVolumes = Value;
            
          
          
            
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
    
    methods % SETTERS FILE-MANAGEMENT

        function obj =          setImageAnalysisFolder(obj, FolderName)
            % SETIMAGEANALYSISFOLDER set image analysis/ annotation folder;
            % takes 1 argument:
            % 1: name of folder ('char')
            % also sets other paths that depend on annotation folder;
                obj.AnnotationFolder =      FolderName;
                obj =                      obj.setPathsThatDependOnAnnotationFolder;
                
        end
        
        function obj =          setMovieFolder(obj, Value)
            % SETMOVIEFOLDER
            % takes 1 argument
            obj.MovieFolder = Value;   
        end
          
        function obj =          setNamesOfMovieFiles(obj, Value)
            % SETNAMESOFMOVIEFILES set names of attached movie files
            % takes 1 argument:
            % 1: cell-string with filenames
            obj.AttachedFiles =       Value;
        end

        function obj =          changeMovieFileNamesFromTo(obj, Old, New)
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

        function obj =          load(obj, varargin)
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
                            obj =               obj.load_FormatBeforeAugust2021;
                        case 'AfterAugust2021'
                            obj =               obj.loadCurrentVersion;
                        case 'LoadMasks'
                            obj =               obj.loadCurrentVersion;
                          
                            
                            
                        otherwise
                            error('Wrong input.')

                    end

                otherwise
                    error('Wrong input.')


            end


               obj.Tracking =          obj.Tracking.performMethod('setTrackingCellForTimeWithDriftByDriftCorrection', obj.DriftCorrection);
            
               obj.Interactions =        obj.Interactions.setMovieTracking(obj);
       

        end

        function obj =          save(obj)
            % SAVE all permanent data into file
            % saves only as current format;
            
            MovieTrackingInfo = obj.getStructureForStorage;
            tic
            save(obj.getPathOfMovieTrackingForSmallFile, 'MovieTrackingInfo')
            a =                 toc;
            fprintf('Saving movie "%s" at path "%s" took %6.1f seconds.\n', obj.NickName, obj.getPathOfMovieTrackingForSmallFile, a)
            
            obj.Tracking =      obj.Tracking.performMethod('setMainFolder', obj.getTrackingFolder);
            obj.Tracking =      obj.Tracking.performMethod('saveBasic');
            fprintf('\n')

        end
        
        function obj =          saveMasks(obj)
            %SAVEMASKS save mask pixels
            obj.Tracking =      obj.Tracking.performMethod('setMainFolder', obj.getTrackingFolder);
            obj.Tracking =      obj.Tracking.performMethod('saveMasks');
        end
        
        function obj =          delete(obj, varargin)
            % DELETE delete all files of current format (older formats are left untouched);
            % takes 1 argument:
            % 1: files of version that should be loaded: 'BeforeAugust2021', 'AfterAugust2021';

            switch length(varargin)
                
                case 0
                     ListWithFiles = obj.getAllAnnotationPaths(); 
                    
                case 1
                      assert(ischar(varargin{1}), 'Wrong input.')
                      ListWithFiles =   obj.getAllAnnotationPaths(varargin{1}); 

                otherwise
                    error('Wrong input.')


            end
            
            for index = 1 : length(ListWithFiles)
                
                    CurrentPath =   ListWithFiles{index};
                    if exist(CurrentPath) == 2
                          delete(CurrentPath);
                    elseif exist(CurrentPath) == 7
                        delete([CurrentPath, '/*']);
                        rmdir(CurrentPath);
                    end
             end



        end 

        function obj =          setSavingStatus(obj, Value)
            % SETSAVINGSTATUS sets whether most recent version has been saved;
            % takes 1 argument:
            % 1: logical scalar
            obj.UnsavedTrackingDataExist = Value;
        end
        
        function obj =          saveMetaData(obj, varargin)
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
        
        function obj =          saveDerivativeData(obj)
            % SAVEDERIVATIVEDATA exports "derivative" data that are obtained from "raw" data and saved so that they can be retrieved more easily;
            % currently saves metric and pixel "TrackCells" (maks pixels are not saved);
              
            assert(obj.isMapped, 'Need movie to be mapped for this analysis. Use setPropertiesFromImageMetaData');

            
            TrackCell_Metric =      obj.getMetricTrackingAnalysis.getTrackCell;
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
        
        function exist =        verifyThatEssentialPropertiesAreSet(obj)
              % VERIFYTHATESSENTIALPROPERTIESARESET
              % tests that annotation paths, nickname, movie-folder anbd attached movie-names are all set;
            existOne =          obj.verifyExistenceOfAnnotationPaths;
            existTwo =          ~isempty(obj.MovieFolder);
            existThree =        ~isempty(obj.AttachedFiles);
            exist =             existOne && existTwo && existThree;
         end
           
        function value =        canConnectToSourceFile(obj, varargin)
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
            
             if value == true
                
             else
                 disp('test')
                 
             end
        
        end

        function Data =         getDerivedData(obj, Type)
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
        
        function status =       getUnsavedDataExist(obj)
            % GETUNSAVEDDATAEXIST
            status = obj.UnsavedTrackingDataExist; 
        end

    end
   
    methods % SETTERS IMAGE-VOLUMES
       
        function obj = setDefaultNumberOfLoadedFrames(obj, Value)
           obj.DefaultNumberOfLoadedFrames = Value; 
            
        end
        
        function obj =                      setLoadedImageVolumes(obj, Value)
            % SETLOADEDIMAGEVOLUMES sets LoadedImageVolumes (which contains stored images of source files so that they don't have to be loaded from file each time);
            obj.LoadedImageVolumes =      Value; 
        end

        function obj    =                   emptyOutLoadedImageVolumes(obj)
            % EMPTYOUTLOADEDIMAGEVOLUMES delete loaded image volumes from memory;
            obj.LoadedImageVolumes =        cell(obj.getMaxFrame,1);   
        end

        function obj =                      updateLoadedImageVolumes(obj, varargin)
            % UPDATELOADEDIMAGEVOLUMES loads image data from file and sets LoadedImageVolumesn property;
            %takes 1 argument:
            % 0: loads frames of specified range around active frame, e.g. : lower frame: 60- 40 = 20, higher frame: 60  + 40 = 100;
            % 1: a) number of wanted frame
            %    b) 'All" loads all image data:
            % only frames that are currently not in memory are loaded;
            % to reset already loaded frames have to call emptyOutLoadedImageVolumes first;
            if isempty(obj.LoadedImageVolumes)
                obj = obj.emptyOutLoadedImageVolumes; 
            end
            
            switch length(varargin)
               
                case 0
                     WantedFrames =          obj.getSetFrameRanged;
                     
                case 1
                    
                    switch class(varargin{1})
                        
                        case 'double'
                            WantedFrames = varargin{1};
                            
                        case 'char'
                            
                                
                                switch varargin{1}

                                    case 'All'
                                        WantedFrames =  obj.getEntireFrameRange;

                                    otherwise
                                        error('Wrong input.')

                                end
                    
                            
                        otherwise
                            error('Wrong input.')
                        
                        
                        
                    end
                
                    
                    
                otherwise
                    error('Wrong input.')
                
                
            end

            MyFrames =              obj.removeAlreadyLoadedFramesFromFrames(WantedFrames);
           
            obj =                   obj.updateLoadedImageVolumesForFrames(MyFrames);


        end
        
        function obj =                      updateLoadedImageVolumesForFrames(obj, MyFrames)
             obj.LoadedImageVolumes(MyFrames,1 ) = obj.loadImageVolumesForFrames(MyFrames);
        end
 
    end
   
    methods % GETTERS LOADED IMAGEVOLUMES
        

        
        function volumes =                 getLoadedImageVolumes(obj, varargin)
            switch length(varargin)
                case 0
                     volumes = obj.LoadedImageVolumes;
                    
                case 1
                     volumes = obj.LoadedImageVolumes{varargin{1}};
                otherwise
                    error('Wrong input.')
                
                
            end
           
        end

        function TempVolumes =              loadImageVolumesForFrames(obj, numericalNeededFrames)
            % LOADIMAGEVOLUMESFORFRAMES loads all unloaded image-volumes of specified time frames;
            % input: vector with indices of frames that should be loaded;
            TempVolumes = obj.loadImageVolumesForFramesInternal(numericalNeededFrames);
        end
        
        function AllConnectionsOk =         checkConnectionToImageFiles(obj)
             % CHECKCONNECTIONTOIMAGEFILES
             AllConnectionsOk = obj.checkWhetherAllImagePathsCanBeLinked;
        end
         
       

    end
    
    methods % GETTERS LOADED IMAGE-VOLUMES: DERIVATIVE
       
        function CleanedUpVolume =      getActiveImage(obj, varargin)
            % GETACTIVEIMAGE returns image of active channel;
            % shown is signal of active channel, pixels outside of crop are blacked out;
            activeVolume =          obj.getActiveImageVolume(varargin{:});
            CleanedUpVolume =       obj.convertImageVolumeToActiveImage(activeVolume);

        end
        
        function activeVolume =         getActiveImageVolume(obj, varargin)

            obj =     obj.updateLoadedImageVolumes;

            switch length(varargin)

            case 0
                Frame = obj.getActiveFrames;

            case 1
                assert(isnumeric(varargin{1}) && isscalar(varargin{1}) && varargin{1} >= 1 && mod(varargin{1}, 1) == 0, 'Wrong input.')
                Frame = varargin{1};
            end

            activeVolume =          obj.getLoadedImageVolumes{Frame, 1};


        end

        function rgbImage =             getRgbImage(obj)
            % GETRGBIMAGE returns active image (with cell masks);
            activeVolume =          obj.getActiveImageVolume;
            rgbImage =              obj.convertImageVolumeIntoRgbImage(activeVolume); 
            rgbImage =              obj.addInteractionImageToImage(rgbImage);
            rgbImage =              obj.addMasksToImage(rgbImage);

        end
        
       
        
    end
    
    methods % CONVERSION: IMAGE-VOLUMES:
       
        function Volume =               filterImageVolumeForChannel(obj, Volume, ChannelIndex)
            Volume =            Volume(:, :, :, 1, ChannelIndex);
        end

        function rgbImage =             highlightPixelsInRgbImage(~, rgbImage, CoordinateList, Channel, Intensity)

            if isempty(CoordinateList)

            else

            assert(isnumeric(CoordinateList) && ismatrix(CoordinateList) && size(CoordinateList, 2) >=2, 'Wrong input.')    
             CoordinateList(isnan(CoordinateList(:,1)),:) = []; % this should not be necessary if everything works as expected;
             NumberOfPixels =                        size(CoordinateList,1);
            if ~isnan(Intensity)
                for CurrentPixel =  1:NumberOfPixels
                    rgbImage(CoordinateList(CurrentPixel, 1), CoordinateList(CurrentPixel, 2), Channel)= rgbImage(CoordinateList(CurrentPixel, 1), CoordinateList(CurrentPixel, 2), Channel) + Intensity;
                end
            end

            end

        end

        function rgbImage =             convertImageVolumeIntoRgbImage(obj, SourceImageVolume)
            % CONVERTIMAGEVOLUMEINTORGBIMAGE converts "image-volume" into 3-channel rgb image;
            rgbImage = obj.convertImageVolumeIntoRgbImageInternal(SourceImageVolume);

        end
        
    end
    
    methods % AUTO-DETECTION
        
        function obj = removeFromActiveMaskPixelList(obj, UserSelectedY, UserSelectedX)
            pixelListWithoutSelected =          obj.getPixelsFromActiveMaskAfterRemovalOf([UserSelectedY, UserSelectedX]);
            MySegmentationCapture =             obj.getDefaultSegmentationCapture;
            MySegmentationCapture =         MySegmentationCapture.setImageVolume(obj.getActiveImage);

            MySegmentationCapture =        MySegmentationCapture.setSegmentationOfCurrentFrame(obj.getUnfilteredSegmentationOfCurrentFrame); 
            MySegmentationCapture =        MySegmentationCapture.setActiveStateBySegmentationCell(obj.getSegmentationOfActiveMask);
            MySegmentationCapture =        MySegmentationCapture.setBlackedOutPixelsByPreviousTrackedPixels;

            MySegmentationCapture =        MySegmentationCapture.setActiveZCoordinate(obj.getActivePlanesWithoutDriftCorrection);
            MySegmentationCapture =             MySegmentationCapture.setSegmentationType('Manual');
            MySegmentationCapture =            MySegmentationCapture.setMaskCoordinateList(pixelListWithoutSelected);
            obj =                               obj.resetActivePixelListWith(MySegmentationCapture);
            
        end
            
        
       
    
    end
    
    methods % SEGMENTATIONCAPTURE
        
        function obj =                              setSegmentationCapture(obj, Value)
            obj.SegmentationCapture = Value; 
        end

        function SegementationOfReference =         getSegmentationCapture(obj)
            SegementationOfReference = obj.getDefaultSegmentationCapture;
        end

        function SegementationOfReference =         getDefaultSegmentationCapture(obj)

            if isempty(obj.SegmentationCapture)

                SegementationOfReference =      PMSegmentationCapture(obj);
                SegementationOfReference =      SegementationOfReference.setPixelShiftForEdgeDetection(4);
                SegementationOfReference =      SegementationOfReference.setMaximumCellRadius(80);
                SegementationOfReference =      SegementationOfReference.setMaximumDisplacement(120);
                SegementationOfReference =      SegementationOfReference.setAllowedExcessSizeFactor(1.3);
                SegementationOfReference =      SegementationOfReference.setFactorForThreshold(1);  
                SegementationOfReference =      SegementationOfReference.setNumberOfPixelsForBackground(30);  


                SegementationOfReference =      SegementationOfReference.setSizeForFindingCellsByIntensity(5);
                SegementationOfReference =      SegementationOfReference.setShowSegmentationProgress(false);


            else
                SegementationOfReference =    obj.SegmentationCapture.resetWithMovieTracking(obj);



            end






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
         
        function Value =                getCollapseAllPlanes(obj)
            % GETCOLLAPSEALLPLANES
            Value = obj.CollapseAllPlanes;
        end
         
    end
    
    methods % GETTERS THAT MODIFIY INPUT
        
        
        function mySegmentationObject = applyActiveStateToSegmentationCapture(obj, mySegmentationObject)
            error('Not supported anymore.')
         
             

            
        end
        
        
    end
    
    methods % SIMPLE SETTERS
       
        function obj = performMethod(obj, Value, varargin)
           
            obj = obj.(Value)(varargin{:});
            
        end
        
        function obj = performLoadedMovieMethod(obj, Value, varargin)
           obj = obj.performMethod(Value, varargin{:});
           
        end
        
        function obj = setTrackingNavigationControllerView(obj, Value)
            
            
        end
        
        function obj =          setNickName(obj, String)
            % SETNICKNAME simply sets nickname of movie
            % takes 1 argument:
            % 1: character string
            obj.NickName =       String;
        end
        
        function obj =          setWantedScene(obj, String)
            % SETNICKNAME simply sets nickname of movie
            % takes 1 argument:
            % 1: character string
            obj.WantedScene =       String;
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
       
        
        function obj = setActiveTrackIsHighlighted(obj, Value)
            obj.ActiveTrackIsHighlighted = Value;
            
        end
        
          function obj =      setCollapseAllTrackingTo(obj, Value)
              % SETCOLLAPSEALLTRACKINGTO set whether tracked data of all planes, or just of "visible" planes are shown;
            obj.CollapseAllTracking = Value;
          end
        
        function Value =                            getCollapseAllTracking(obj)
            % GETCOLLAPSEALLTRACKING returns whether tracked data of all planes, or just of "visible" planes are shown;
            Value = obj.CollapseAllTracking;
        end
           
    end
    
    methods % SETTERS IMAGE MAP
       
           function obj =      setPropertiesFromImageMetaData(obj)
            % SETPROPERTIESFROMIMAGEFILES
            % sets image map, space-calibration, time-calibration, navigation from file (also updates navigation used by drift correction);
            % takes 0 arguments;
            assert(~isempty(obj.getPathsOfImageFiles), 'Could not get paths.')
            
            fprintf('\nPMMovieTracking:@setPropertiesFromImageMetaData.\n')
            myImageFiles =                      PMImageFiles(...
                                                    obj.getPathsOfImageFiles, ...
                                                    obj.WantedScene...
                                                    );
            assert(~myImageFiles.notAllFilesCouldBeRead, 'Could not connect to all movie-files.')
            
            fprintf('All source files could be accessed. Retrieving MetaData and ImageMaps.\n')
            obj.ImageMapPerFile =              myImageFiles.getImageMapsPerFile; 
            obj.SpaceCalibration =             myImageFiles.getSpaceCalibration; 
            obj.TimeCalibration =              myImageFiles.getTimeCalibration; 
            obj.Navigation =                   myImageFiles.getNavigation; 
           
            
             
            if obj.getNumberOfChannels ~= obj.Navigation.getMaxChannel
                    obj =                           obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);
            end
            
            if isempty(obj.DriftCorrection)
                    obj.DriftCorrection =               PMDriftCorrection;
            end
            
            obj.DriftCorrection =           obj.DriftCorrection.setNavigation(obj.Navigation);
            obj.DriftCorrection =           obj.DriftCorrection.setBlankDriftCorrection;
           
                    
        end
        
        
    end
    
    methods % GETTERS IMAGE MAP
        
        function imageMapOncell =           getSimplifiedImageMapForDisplay(obj)
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
        
        function imageSource =              getImageSource(obj, varargin)
            % GETIMAGESOURCE
            
            obj= obj.replaceImageMapPaths;
            
            switch length(varargin)
               
                case 0
                      imageSource = PMImageSource(...
                                        obj.ImageMapPerFile, ...
                                        obj.Navigation...
                                        );
                    
                case 1
                    settings.SourceChannels =          [];
                    settings.TargetChannels =          [];
                    settings.SourcePlanes =            [];
                    settings.TargetPlanes =            [];

                    settings.TargetFrames =             1;
                    settings.SourceFrames =             varargin{1};

                    imageSource =                PMImageSource(...
                                            obj.ImageMapPerFile, ...
                                            obj.Navigation, ...
                                            settings);
                   
                                                    
                    
                otherwise
                    error('Wrong input.')
                
                
                
            end
          
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
            paths =         obj.getMovieFolderPathsForStrings(obj.getLinkedMovieFileNames);

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
            obj.Tracking =       obj.Tracking.performMethod('setActiveFrameTo', FrameNumber);
        end
        
        function obj =       setFocusOnActiveMask(obj)
            % SETFOCUSONACTIVETRACK focuses XY-axis and plane on center of active track;
            obj =           obj.setSelectedPlaneTo(obj.getPlaneOfActiveTrackWithAppliedDriftCorrection); % direct change of model:
            obj =           obj.moveCroppingGateToActiveMask;
        end

        function obj =            setSelectedPlaneTo(obj, selectedPlanes)
            % SETSELECTEDPLANETO set selected plane of navigation;
            % takes 1 argument:
            % 1: selected planes: takes plane with applied drift correction, sets plane without drift:
            
              [~, ~, selectedPlanesWithoutDrift] =         obj.removeAppliedDriftCorrection(0, 0, selectedPlanes);
            if isnan(selectedPlanes)
            else
                 obj.Navigation =        obj.Navigation.setActivePlanes(selectedPlanesWithoutDrift);
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
           elseif obj.getMaxPlaneWithoutDriftCorrection > 1
               DataType =               'ZStack';
           elseif obj.getMaxPlaneWithoutDriftCorrection == 1
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
            planes =        obj.getMaxPlaneWithoutDriftCorrection;
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

        
       
        function frames =                       getActiveFrames(obj)
            % GETACTIVEFRAMES returns active frames
            frames = obj.Navigation.getActiveFrames;
        end

   
    
        
    end
    
    methods % GETTERS NAVIGATION PLANES
        
        function plane =                        getMaxPlaneWithoutDriftCorrection(obj)
             plane =         obj.Navigation.getMaxPlane; 
        end
        
        
        
        function planes = getMaxPlaneWithAppliedDriftCorrection(obj)
            planes =        obj.getMaxPlaneWithoutDriftCorrection + obj.getMaxAplliedPlaneShifts;
        end  
        
          function plane =                        getMaxPlane(obj)
            % GETMAXPLANE returns number of planes of movie-sequence (does not include drift); 
            error('Not supported. Use getMaxPlaneWithoutDriftCorrection or getMaxPlaneWithAppliedDriftCorrection.')
            plane =         obj.Navigation.getMaxPlane; 
          end
        
         function frames =                       getActivePlanes(obj)
           error('Not supported. Use getActivePlanesWithoutDriftCorrection or getActivePlanesWithAppliedDriftCorrection.')
        end
        
        function planes =                       getActivePlanesWithAppliedDriftCorrection(obj)
            % GETACTIVEPLANES returns active planes (this seems to include drift: if so, inconsistent with max planes, this needs to be fixed);
           [~, ~, planes] =         obj.addAppliedDriftCorrection(0, 0, obj.getActivePlanesWithoutDriftCorrection);
        end
        
        function frames =       getActivePlanesWithoutDriftCorrection(obj)

            frames = double(obj.Navigation.getActivePlanes);
             
        end
        
            function visiblePlanes =                getVisibleTrackingPlanesWithoutDriftCorrection(obj)
            % GETPLANESTHATAREVISIBLEFORSEGMENTATION get planes for which segmentation should be shown;
            % plane number seems to include drift;

            switch obj.CollapseAllTracking
                case 1
                   visiblePlanes =          1 : obj.getMaxPlaneWithoutDriftCorrection;
                otherwise
                    visiblePlanes =         obj.getActivePlanesWithoutDriftCorrection;
            end
         end
        
        
        function planeOfActiveTrack =            getPlaneOfActiveTrackWithAppliedDriftCorrection(obj)
            % GETPLANEOFACTIVETRACK returns plane of active mask (with active drift-correction);
            PlaneWithoutDriftCorrection =       obj.Tracking.performMethod('getPlaneOfActiveTrackForFrame', obj.getActiveFrames);
            [~, ~, planeOfActiveTrack ] =       obj.addAppliedDriftCorrection( 0, 0, PlaneWithoutDriftCorrection);
            planeOfActiveTrack =                round(planeOfActiveTrack);
        end
        
    end
    
    methods % GETTERS CALIBRATION
       
        function calibration = getSpaceCalibration(obj)
            % GETSPACECALIBRATION returns space-calibration object
            calibration = obj.SpaceCalibration.Calibrations(1);   
        end
        
        function Value = convertXYZPixelListIntoUm(obj, Value)
            % CONVERTXYZPIXELLISTINTOUM converts XYZ pixel input µm output;
            Value = obj.SpaceCalibration.Calibrations.convertXYZPixelListIntoUm(Value);
        end
        
        function Value = convertYXZUmListIntoPixel(obj, Value)
            % CONVERTYXZUMLISTINTOPIXEL converts XYZ µm input into pixel output;
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
            obj.Tracking =              obj.Tracking.performMethod('setTrackingAnalysis', obj.getTrackingAnalysis);
          %  obj.Tracking =              obj.Tracking.performMethod('setTrackingCellForTimeWithDriftByDriftCorrection', obj.DriftCorrection);
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
          error('Not supported. Use getActiveManualDriftCorrectionWithAppliedDriftCorrection instead')

        end
        
        function Coordinates =                      getActiveManualDriftCorrectionWithAppliedDriftCorrection(obj)
             % GETACTIVECOORDINATESOFMANUALDRIFTCORRECTION returns coordinates of active drift correction;
             % coordinate at current frame with applied drift correction;
            ManualDriftCorrectionValues =                   obj.DriftCorrection.getManualDriftCorrectionValues;
            ActiveFrame =                                   obj.getActiveFrames;
            xWithoutDrift =                                 ManualDriftCorrectionValues(ActiveFrame, 2);
            yWithoutDrift =                                 ManualDriftCorrectionValues(ActiveFrame, 3);
            planeWithoutDrift =                             ManualDriftCorrectionValues(ActiveFrame, 4);
            [xWithDrift, yWithDrift, zWithDrift ] =         obj.addAppliedDriftCorrection(xWithoutDrift, yWithoutDrift, planeWithoutDrift);
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

    

     
        
        function AplliedPlaneShifts = getMaxAplliedColumnShifts(obj)
            % GETMAXAPLLIEDCOLUMNSHIFTS
            AplliedPlaneShifts =  max(obj.DriftCorrection.getAppliedColumnShifts);
        end 
        
    end
    
    methods % PROCESSING DRIFT CORRECTION
       
           function [row, column, plane, frame] =      removeAppliedDriftCorrectionFromFrames(obj, DownColumn,  MouseDownRow)
            % GETCOORDINATESFORPOSITION converts input coordinates into "verified" coordinates with applied drift correction removed;
            % takes 2 arguments:
            % 1: numerical scalar of column position
            % 2: numerical scalar of row position
            % returns 4 values:
            % 1: row (rounded, drift removed, NaN if out of range)
            % 2: column (rounded, drift removed, NaN if out of range)
            % 2: plane (rounded, drift removed, NaN if out of range)
            % 2: frame (rounded, drift removed, NaN if out of range)
            
            
            
            [column, row, plane] =            obj.removeAppliedDriftCorrection(DownColumn, MouseDownRow, obj.getActivePlanesWithAppliedDriftCorrection);
            [row, column, plane, frame] =     obj.roundCoordinates(row, column, plane, obj.getActiveFrames);
            [row, column, plane]  =           obj.verifyCoordinates(row, column,plane);
        end
        
    end
    
    methods % SETTERS SUMMARY
        
        function obj = showSummary(obj)
            % SHOWSUMMARY shows summary of object
            
            fprintf('\n*** This PMMovieTracking object manages annotation of a movie-sequence.\n')
            fprintf('Annotation folder = "%s".\n', obj.AnnotationFolder)
            fprintf('Movie folder = "%s".\n', obj.getMovieFolder)
            fprintf('Export folder = "%s".\n', obj.AnnotationFolder)
            
            if isempty(obj.LoadedImageVolumes)
                fprintf('No images are loaded.\n')
            else
               fprintf('Images are loaded.\n') 
            end
            
            
            
            fprintf('The most important functions are to track cells and to correct drift of movie-sequences.\n')
            fprintf('\nTracking is done with the following PMTrackingNavigation object:\n')
            
            
            
            obj.Tracking = obj.Tracking.performMethod('showSummary');
            
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
                fprintf('A scale bar of a size of %i µm will be shown.\n', obj.ScaleBarSize)
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
            assert(isvector(Value), 'Wrong argument type.')
            
            switch class(Value)
               
                case 'PMMovieTracking'
                    assert(isscalar(Value), 'Wrong input.')
                    obj = setChannels@PMChannels(obj, Value.getChannels);

                case 'PMChannel'
                    obj = setChannels@PMChannels(obj,Value);

                otherwise
                    error('Wrong input.')
                
                
            end
            
            
        end

       function obj =    resetChannelSettings(obj, Value, Field)
           % RESETCHANNELSETTINGS allows setting of properties of active channel;
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
       
       function obj = setVisibilityToActiveChannel(obj)
             % SETVISIBILITYTOACTIVECHANNEL sets active channel to visible and all other channels to nvisible;
            AllChannelsFalse = false(1, obj.getNumberOfChannels);
            AllChannelsFalse(obj.getActiveChannelIndex) = true; 
            obj = obj.setVisibleForAllChannels(AllChannelsFalse);
             
            
           
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
            if isnan(SelectedTrackID)
                
            else
                  obj =                                   obj.setActiveTrackWith(SelectedTrackID);
                  if ~isnan(FrameNumber)
                        obj =                                   obj.setFrameTo(FrameNumber); 
                  end
                
            end
          

        end

        function obj =      setActiveTrackWith(obj, NewTrackID)
            % SETACTIVETRACKWITH set active track
            % takes 1 argument:
            % 1: track ID
            obj.Tracking =      obj.Tracking.performMethod('setActiveTrackIDTo', NewTrackID);
        end

        function obj =      deleteActiveTrack(obj)
            % DELETEACTIVETRACK deletes a active track
            obj.Tracking  =     obj.Tracking.performMethod('removeActiveTrack');
        end
        
        function obj =      setSelectedTrackIdsTo(obj, Value)
            % SETSELECTEDTRACKIDSTO sets selected track IDs to input;
            obj.Tracking =  obj.Tracking.performMethod('setSelectedTrackIdsTo', Value);
        end

        function obj =      addToSelectedTrackIds(obj, TracksToAdd)
            % ADDTOSELECTEDTRACKIDS adds input values to selected tracks;
            obj.Tracking =    obj.Tracking.performMethod('addToSelectedTrackIds', TracksToAdd);
        end

        function obj =      selectAllTracks(obj)
            % SELECTALLTRACKS all tracks become selected
            obj.Tracking =  obj.Tracking.performMethod('selectAllTracks');
        end

        function obj = deleteAllTracks(obj)
            % DELETEALLTRACKS delete all tracks
           obj.Tracking =     PMTrackingNavigationController(PMTrackingNavigation());
           obj.Tracking =     obj.Tracking.performMethod('initializeWithDrifCorrectionAndFrame', obj.DriftCorrection, obj.getMaxFrame);
        end

        function obj =      setTrackingAnalysis(obj)
             % SETTRACKINGANALYSIS set tracking analysis of PMTrackingNavigation object;
             % takes 0 arguments 
            obj.Tracking =      obj.Tracking.performMethod('setTrackingAnalysis', obj.getTrackingAnalysis);
        end

    

        function obj =      setFinishStatusOfTrackTo(obj, input)
            % SETFINISHSTATUSOFTRACKTO sets "finished-status of active track;
              % takes 1 argument:
                % 1: 'char': 'Finished', 'Unfinished'
            obj.Tracking = obj.Tracking.performMethod('setInfoOfActiveTrack', input);
            fprintf('Finish status of track %i was changed to "%s".\n', obj.getIdOfActiveTrack, input)
        end

     end
    
    methods % SETTERS TRACKING MANUAL TRACKING
       
        function obj =      addMaskByClickedCoordiante(obj, Coordinate)      
            
            rowPos =                        Coordinate(1);
            columnPos =                     Coordinate(2);
            planePos =                      Coordinate(3);
            
            mySegmentationObject =          obj.getDefaultSegmentationCapture;
            mySegmentationObject =          mySegmentationObject.setImageVolume(obj.getActiveImage);
          
               mySegmentationObject =        mySegmentationObject.setSegmentationOfCurrentFrame(obj.getUnfilteredSegmentationOfCurrentFrame); 
                mySegmentationObject =        mySegmentationObject.setActiveStateBySegmentationCell(obj.getSegmentationOfActiveMask);
                mySegmentationObject =        mySegmentationObject.setBlackedOutPixelsByPreviousTrackedPixels;
            mySegmentationObject =          mySegmentationObject.setActiveCoordinateBy(rowPos, columnPos, planePos);
            mySegmentationObject =          mySegmentationObject.generateMaskByClickingThreshold;
            
             obj =                          obj.resetActivePixelListWith(mySegmentationObject);
            
            if 1== 2
                  children =                          mySegmentationObject.getSegmentationCaptureChildren;
                   NewTrackID = obj.findNewTrackID;
                    for index = 1 : length(children)
                        % children(index) = children(index).setTrackId(NewTrackID + index - 1);
                         obj.Tracking =       obj.Tracking.performMethod('setActiveTrackID', NewTrackID + index - 1);
                        obj =                 obj.resetActivePixelListWith(children(index));

                        obj =       obj.addToSelectedTrackIds(NewTrackID + index - 1);
                    end
                
                
            end
            
          
                            
            
        end
        
        function obj =      performTrackingMethod(obj, Value, varargin)
            % PERFORMTRACKINGMETHOD call method of PMTrackingNavigation object;
            % takes 1 or more arguments: allows calling a method of the object's, PMTrackingNavigation object;
            % 1: character string: name of method
            assert(ischar(Value), 'First argument must be character-string.')
            try
                if ismethod(obj.Tracking, Value)
                     obj.Tracking =      obj.Tracking.performMethod(Value, varargin{:});
                end

            catch ME
                throw(ME)
            end
            
         end
 
        function obj =      updateTrackingWith(obj, Value)
             % UPDATETRACKINGWITH updates state of Tracking object with input;
             % takes 1 argument:
             % 1: 'PMTrackingNavigationAutoTrackView' or 'PMAutoCellRecognitionView';
            obj.Tracking = obj.Tracking.performMethod('updateWith', Value); 
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
                pixelList_AfterAdding =         unique([obj.Tracking.get('PixelsOfActiveTrackForFrames', obj.getActiveFrames); pixelListToAdd], 'rows');
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
               
               if isempty(obj.Tracking.get('TrackingAnalysis'))
                   obj.Tracking = obj.Tracking.performMethod('setTrackingAnalysis', obj.getTrackingAnalysis);
                   
               end
              
                obj.Tracking =      obj.Tracking.performMethod('addSegmentation', SegmentationCapture);
                obj =               obj.setSavingStatus(false);
                
      

            end

        end

        function obj =      mergeActiveTrackWithTrack(obj, IDOfTrackToMerge)
            % MERGEACTIVETRACKWITHTRACK merges active track with inputted track ID;
            % takes 1 argument:
            % 1: numeric scalar: ID of track with which to merge;
            obj.Tracking =      obj.Tracking.performMethod('splitTrackAtFrame', obj.getActiveFrames-1, obj.getIdOfActiveTrack, obj.Tracking.get('NewTrackID'));
            obj.Tracking =      obj.Tracking.performMethod('mergeTracks', [obj.getIdOfActiveTrack,    IDOfTrackToMerge]);
        end

        function obj =      minimizeMasksOfActiveTrackAtFrame(obj, FrameIndex)
           % MINIMIZEMASKSOFACTIVETRACKATFRAME replaces mask of active cell by point mask;
           % takes 1 argument:
           % 1: frame number where mask should be minimized
           obj.Tracking =       obj.Tracking.performMethod('minimizeActiveTrackAtFrame', FrameIndex);
            obj =               obj.setFrameTo(SourceFrames(FrameIndex));
            obj =               obj.setFocusOnActiveMask;
        end

        function obj =      deleteSelectedTracks(obj)
            % DELETESELECTEDTRACKS deletes all selected tracks
            obj.Tracking  =         obj.Tracking.performMethod('deleteAllSelectedTracks');
        end

        function obj =      deleteActiveTrackAfterActiveFrame(obj)
            % DELETEACTIVETRACKAFTERACTIVEFRAME 
            obj.Tracking =     obj.Tracking.performMethod('deleteActiveTrackAfterFrame', obj.getActiveFrames);
        end

        function obj =      deleteActiveTrackBeforeActiveFrame(obj)
            % DELETEACTIVETRACKBEFOREACTIVEFRAME
            obj.Tracking =   obj.Tracking.performMethod('deleteActiveTrackBeforeFrame', obj.getActiveFrames);
        end

        function obj =      splitTrackAfterActiveFrame(obj)
            %SPLITTRACKAFTERACTIVEFRAME
            obj.Tracking =     obj.Tracking.performMethod('splitActiveTrackAtFrame', obj.getActiveFrames);
        end

        function obj =      generalCleanup(obj)
            % GENERALCLEANUP calls generalCleanup method of PMTrackingNavigation;
           obj.Tracking = obj.Tracking.performMethod('generalCleanup');
        end

    end
    
    methods % AUTOCELLRECOGNITION
        
        function Value = getAutoCellRecognition(obj)
            Value = obj.AutoCellRecognition; 
        end
        
        function obj =      setAutoCellRecognition(obj)
            
            if isempty(obj.AutoCellRecognition)
                obj.AutoCellRecognition = PMAutoCellRecognition ;
            end

            if ~isempty(obj.getLoadedImageVolumes)
              obj.AutoCellRecognition = obj.AutoCellRecognition.performMethod('setImageSequence', obj.getLoadedImageVolumes);
            end
                 
        end

        function obj =      interpolateAutoCellRecognitionController(obj, View) 
            MyController =                  obj.getAutoCellRecognitionControllerInternal(View).interpolateCircleRecognitionLimits;  
            obj.AutoCellRecognition =       MyController.getModel;
            
        end
        

        
         function obj =     setActiveTrackToNewTrack(obj)
             obj =      obj.setActiveTrackWith(obj.findNewTrackID);
             
         end
         
        function obj =      AutoCellRecognitionChannelChanged(obj, View, third)
                MyController =                  obj.getAutoCellRecognitionControllerInternal(View);
                
                MyController =                  MyController.setActiveChannel(third.DisplayIndices(1));
                MyController =                  MyController.setModelByView;
                
                obj.AutoCellRecognition =       MyController.getModel;
           
        end

        function obj =      AutoCellRecognitionFramesChanged(obj, View, third)
            MyController =                  obj.getAutoCellRecognitionControllerInternal(View);

            myFrames =                      third.DisplayIndices(:, 1);
            MyController =                  MyController.setSelectedFrames(myFrames);
            MyController =                  MyController.setModelByView;
            
            obj.AutoCellRecognition =       MyController.getModel;

        end

        function obj =      AutoCellRecognitionTableChanged(obj,View, src)
            
            MyController =              obj.getAutoCellRecognitionControllerInternal(View);
             
            MyController =              MyController.setCircleLimitsBy(src.Data);
            MyController =              MyController.setModelByView;
            
            obj.AutoCellRecognition =   MyController.getModel;

        end
        
        function obj =      changeOfAutoCellRecognitionView(obj, View)
            MyController =                      obj.getAutoCellRecognitionControllerInternal(View);
            MyController =                      MyController.setModelByView;
           obj.AutoCellRecognition =            MyController.getModel;

        end
       
        
         
         

    end
    
    methods % AUTOCELLRECOGNITION: ACTION
       
        function obj =          autDetectMasksByIntensity(obj)

            MySelectedFrames =                    obj.AutoCellRecognition.getSelectedFrames  ;
            PreventDoubleTracking =                 obj.AutoCellRecognition.getPreventDoubleTracking;
            DoubleTrackingDistance =                obj.AutoCellRecognition.getPreventDoubleTrackingDistance;

            SegmentationCaptureSourceList =             obj.getSegmenationCaptureSourceListForFramesWithAuto(...
                                                            MySelectedFrames);
                                                        
            obj =                                   obj.setTrackingAnalysis;     
            
            
            obj.Tracking =               obj.Tracking.performMethod('performIntensityAutoRecognition', ...
                                                            SegmentationCaptureSourceList, ...
                                                            MySelectedFrames, ...
                                                            PreventDoubleTracking, ...
                                                            DoubleTrackingDistance ...
                                                            );
            

          
        end
        
        
         function SegmentationCaptureSourceList =        getSegmenationCaptureSourceListForFramesChannel(obj, FramesThatShouldBeTracked, ChannelIWant)
             
              if isempty(obj.LoadedImageVolumes)
                obj = obj.emptyOutLoadedImageVolumes; 
            end
            FramesINeed =                       obj.removeAlreadyLoadedFramesFromFrames(FramesThatShouldBeTracked);
            obj =                               obj.updateLoadedImageVolumesForFrames(FramesINeed);


           
            obj =                               obj.setActiveChannel(ChannelIWant);

            mySegmentationCaptureSource =       obj.getDefaultSegmentationCapture;

            MyActiveImages =                    arrayfun(@(x) obj.getActiveImage(x), FramesThatShouldBeTracked, 'UniformOutput', false);
            MySegmentationLists =               arrayfun(@(x) obj.getUnfilteredSegmentationOfFrame(x), FramesThatShouldBeTracked, 'UniformOutput', false);

            SegmentationCaptureSourceList =     cellfun(@(x)                        mySegmentationCaptureSource.setSegmentationOfCurrentFrame(x), MySegmentationLists, 'UniformOutput', false);
            SegmentationCaptureSourceList =     cellfun(@(segmentation, x)          mySegmentationCaptureSource.setImageVolume(x), SegmentationCaptureSourceList, MyActiveImages); 

            MyPlane =                           obj.getActivePlanesWithoutDriftCorrection;
            SegmentationCaptureSourceList =     arrayfun(@(x) x.setActiveZCoordinate(MyPlane), SegmentationCaptureSourceList);

            
         end
  
       
        

        function obj =      updateTrackingDataBySegmentationList(obj, ListWithSegmentationCaptureResults, FramesThatShouldBeTracked)

            StartFrame =                    obj.getActiveFrames;
            for frameIndex = 1 :length(FramesThatShouldBeTracked)
                obj =   obj.setFrameTo(FramesThatShouldBeTracked(frameIndex));  
                SegmentationCapturesOfCurrentFrame = ListWithSegmentationCaptureResults{frameIndex};
                for index = 1 : length(SegmentationCapturesOfCurrentFrame)
                    obj =       obj.setActiveTrackWith(obj.findNewTrackID);
                    obj =       obj.resetActivePixelListWith(SegmentationCapturesOfCurrentFrame(index));
                end
            end
            obj =      obj.setFrameTo( StartFrame);

        end
         

        function obj =          executeAutoCellRecognition(obj)
            % EXECUTEAUTOCELLRECOGNITION recognizes new cells by circle recognition and addes to PMMovieTracking object;
            % takes 1 argument:
            % 1: cell recognition object

            %  obj.getLoadedImageVolumes
            obj.AutoCellRecognition =       obj.AutoCellRecognition.performAutoDetection;
            obj.Tracking =                  obj.Tracking.performMethod('setAutomatedCellRecognition', autoCellRecongition);
            fprintf('\nCell recognition finished!\n')

        
            FramesThatShouldBeTracked = obj.AutoCellRecognition.getSelectedFrames';
            
            fprintf('\nAdding cells into track database ...\n')
            for CurrentFrame = FramesThatShouldBeTracked % loop through each frame 
                fprintf('Processing frame %i ...\n', CurrentFrame)
                obj =           obj.setFrameTo(CurrentFrame);

                PixelsOfCurrentFrame =      obj.AutoCellRecognition.getDetectedCoordinates{CurrentFrame,1};
                for CellIndex = 1 : size(PixelsOfCurrentFrame,1) % loop through all cells within each frame and add to Tracking data
                    obj =       obj.setActiveTrackWith(obj.findNewTrackID);
                    try
                        mySegmentation = PMSegmentationCapture(PixelsOfCurrentFrame{CellIndex,1}, 'DetectCircles');
                        obj =      obj.resetActivePixelListWith(mySegmentation);
                    catch

                    end
                end
            end

        
            fprintf('Cells were added into the database!\n')
         end
         
        
    end

    methods % SETTERS TRACKING AUTO-TRACKING
       

        function obj =          performAutoTrackingOfExistingMasks(obj)
            % PERFORMAUTOTRACKINGOFEXISTINGMASKS performs autTrackingProcedure method of Tracking;
             obj.Tracking =     obj.Tracking.performMethod('autTrackingProcedure', obj.DriftCorrection, obj.SpaceCalibration, obj.TimeCalibration);
        end
         
    end
    
    methods % GETTERS TRACKING: BASIC
          
        function obj = showTrackingNavigationWindow(obj)
            obj.Tracking = obj.Tracking.show;
            
        end
        
        function Value = getTrackingNavigationView(obj)
           Value = obj.Tracking.getView;
        end
        
        function obj = setTrackingNavigationView(obj, Value)
            
           obj.Tracking  = obj.Tracking.setView(Value); 
        end
        
         function tracking =                         getTracking(obj)
            % GETTRACKING returns Tracking object
            tracking = obj.Tracking.get('Model'); 
         end
         
 
         
 
        
        function numberOfTracks =                   getNumberOfTracks(obj)
            % GETNUMBEROFTRACKS returns number of tracks
            numberOfTracks = obj.Tracking.get('NumberOfTracks');
        end
        
       
        
         function Tracking =                       testForExistenceOfTracking(obj)
            % TESTFOREXISTENCEOFTRACKING tests whether tracking was performed;
            % returns 1 value:
            % 1: logical scalar: true when at least one track was created, otherwise false;
            if isempty(obj.Tracking)
                Tracking =           false;
            else
                Tracking=            obj.Tracking.get('TracksExist');
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
                TrackIDsToShow = [TrackIDsToShow; obj.Tracking.get('IdOfActiveTrack')];
            end

            if obj.getSelectedTracksAreVisible
                TrackIDsToShow = [TrackIDsToShow; obj.Tracking.get('IdsOfSelectedTracks')];
            end

            if obj.getRestingTracksAreVisible
                TrackIDsToShow = [TrackIDsToShow; obj.Tracking.get('IdsOfRestingTracks')];
            end


        end
        
        function IdOfActiveTrack =      getIdOfActiveTrack(obj)
            % GETIDOFACTIVETRACK
            IdOfActiveTrack =               obj.Tracking.get('IdOfActiveTrack');
        end

        function trackIds =             getAllTrackIDs(obj)
            % GETALLTRACKIDS
            trackIds =                      obj.Tracking.get('ListWithAllUniqueTrackIDs');
        end

        function trackIds =             getSelectedTrackIDs(obj)
            % GETSELECTEDTRACKIDS
            trackIds =                      obj.Tracking.get('IdsOfSelectedTracks');
        end

        function trackIds =             getIdsOfRestingTracks(obj)
            % GETIDSOFRESTINGTRACKS returns all non-active and non-selected tracks;
            trackIds =                      obj.Tracking.get('IdsOfRestingTracks');
        end

        function trackIDs =             getUnfinishedTrackIDs(obj)
            % GETUNFINISHEDTRACKIDS
            trackIDs =                      obj.Tracking.get('UnfinishedTrackIDs');
        end  
        
        function SelectedTrackID =      getTrackIDClosestToPosition(obj, MouseColumn, MouseRow)
            % GETTRACKIDCLOSESTTOPOSITION returns trackID that is physically closest to input;
            % takes 2 arguments:
            % 1: column;
            % 2: row;
            frame =                                             obj.getActiveFrames;
            [ClickedColumn, ClickedRow, ClickedPlane] =         obj.removeAppliedDriftCorrection(MouseColumn, MouseRow, obj.getActivePlanesWithAppliedDriftCorrection);
            [ClickedRow, ClickedColumn, ClickedPlane, ~] =      obj.roundCoordinates(ClickedRow, ClickedColumn, ClickedPlane, frame);
            SelectedTrackID=                                    obj.getIdOfTrackThatIsClosestToPoint([ClickedRow, ClickedColumn, ClickedPlane]);

        end

        function newTrackID =           findNewTrackID(obj)
            % FINDNEWTRACKID returns suitable ID for new track (ID that is not used yet);
            newTrackID =    obj.Tracking.get('NewTrackID');
        end
       
        function trackIDs =             getTrackIDsWhereNextFrameHasNoMask(obj)
               % GETTRACKIDSWHERENEXTFRAMEHASNOMASK returns all trackIDs where next frame has no mask;
            if obj.getActiveFrames >= obj.Navigation.getMaxFrame 
                trackIDs =                                  zeros(0,1);
            else                
                TrackIDsOfNextFrame =                                   obj.Tracking.get('TrackIDsOfFrame', obj.getActiveFrames + 1);
                trackIDs =                                setdiff(obj.getTrackIDsOfCurrentFrame, TrackIDsOfNextFrame);
            end
            
        end
        
        function trackIDs =             getTrackIDsOfCurrentFrame(obj)
            % GETTRACKIDSOFCURRENTFRAME % returns list of track-IDs of current frame;
            trackIDs =                                   obj.Tracking.get('TrackIDsOfFrame', obj.getActiveFrames);
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
            MyPlanes =              obj.getVisibleTrackingPlanesWithoutDriftCorrection; % should this be with applied drift-correction?
            coordinates =           obj.Tracking.get('CoordinatesForTrackIDsPlanes', TrackIDs, MyPlanes, obj.DriftCorrection);
        end

        function segmentationOfActiveTrack =        getSegmentationOfActiveMask(obj)
            % GETSEGMENTATIONOFACTIVEMASK returns segmentation of active track filtered for active frame ("active mask");
            segmentationOfActiveTrack =    obj.Tracking.get('ActiveSegmentationForFrames', obj.Navigation.getActiveFrames);
        end 

        function pixelList_Modified =               getPixelsFromActiveMaskAfterRemovalOf(obj, pixelListToRemove)
            % GETPIXELSFROMACTIVEMASKAFTERREMOVALOF returns pixel list of active track (after removal of pixels where X and Y coordinates match input pixel list);

            if ~(isempty(pixelListToRemove(:,1)) || isempty(pixelListToRemove(:,2)))  
                pixelList_Original =        obj.Tracking.get('PixelsOfActiveTrackForFrames', obj.getActiveFrames);
                deleteRows =                ismember(pixelList_Original(:,1:2), [pixelListToRemove(:,1) pixelListToRemove(:,2)], 'rows');
                pixelList_Modified =        pixelList_Original;
                pixelList_Modified(deleteRows,:) =               [];
            end
        end

        function MySegmentation =                   getUnfilteredSegmentationOfActiveTrack(obj)
            % GETUNFILTEREDSEGMENTATIONOFACTIVETRACK returns segmentation for track ID;
            % returns 1 value:
            % segmentation list for all frames where wanted TrackID was successfully tracked;
            MySegmentation =        obj.Tracking.get('SegmentationForTrackID', obj.getIdOfActiveTrack);
        end

        function [segmentationOfCurrentFrame ] =    getUnfilteredSegmentationOfCurrentFrame(obj)
            % GETUNFILTEREDSEGMENTATIONOFCURRENTFRAME returns segmentation of current frame;
            % returns 1 value:
            % segmentation list for all cells of current frame;
             [segmentationOfCurrentFrame ] = obj.getUnfilteredSegmentationOfFrame(obj.Navigation.getActiveFrames);
        end
        
        function [Segmentation ] = getUnfilteredSegmentationOfFrame(obj, Frame)
            Segmentation =        obj.Tracking.get('SegmentationOfFrame', Frame);
        end

        function metricCoordinatesForEachSegment =  getMetricCoordinatesOfActiveTrackFilteredForFrames(obj, myWantedFrames)
            % GETMETRICCOORDINATESOFACTIVETRACKFILTEREDFORFRAMES returns metric coordinates of active track, filtered for input;
            % takes 1 argument:
            % 1: numerical vector with wanted frame-numbers
            % returns 1 value:
            % numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;   
            % out of plane-range coordinates are replaced with NaN;
            MetricCoordinatesOfActiveTrack =            [obj.Tracking.get('FramesOfActiveTrack'), obj.getMetricCoordinatesOfActiveTrack];

            MatchingRows =                              ismember(MetricCoordinatesOfActiveTrack(:, 1), myWantedFrames);
            metricCoordinatesForEachSegment =           MetricCoordinatesOfActiveTrack(MatchingRows,:);

            metricCoordinatesForEachSegment =           metricCoordinatesForEachSegment(:, 2:4);
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
             MyPlanes =              obj.getVisibleTrackingPlanesWithoutDriftCorrection; % should this be with applied drift-correction?
            coordinates =        obj.Tracking.get('CoordinatesForActiveTrackPlanes', MyPlanes, obj.DriftCorrection);
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
             FramesInMinutesForGoSegments =     cellfun(@(x)   TimeInMinutesForEachFrame(x),  obj.getFramesOfGoSegmentsOfActiveTrack,  'UniformOutput', false);
        end

        function frameList =                     getFramesOfGoSegmentsOfActiveTrack(obj)
             % GETFRAMESOFGOSEGMENTSOFACTIVETRACK returns cell-array;
             % each cell contains list of time of all frames of all go tracks contain within parental track;
            frameList =                         obj.getStopTrackingOfActiveTrack.getStartAndEndRowsOfGoTracks;
        end

        function TimeInMinutesForActiveTrack =   getFramesInMinutesOfActiveTrack(obj)
            % GETFRAMESINMINUTESOFACTIVETRACK returns numerical vector with minute times of all frames of active track; 
            TimeInMinutesForEachFrame=          obj.TimeCalibration.getRelativeTimeStampsInSeconds / 60;
            TimeInMinutesForActiveTrack =       TimeInMinutesForEachFrame(obj.Tracking.get('FramesOfActiveTrack'));
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

            FramesOfActiveTrack  =          obj.Tracking.get('FramesOfActiveTrack');

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

            FramesOfActiveTrack  =              obj.Tracking.get('FramesOfActiveTrack');
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
            
             AllFramesOfActiveTrack = obj.Tracking.get('FrameNumbersForTrackID', obj.getIdOfActiveTrack);
            
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
 
        function TrackingAnalysis =                 getMetricTrackingAnalysis(obj)
            TrackingAnalysis =      obj.getTrackingAnalysis;
            TrackingAnalysis =      TrackingAnalysis.setSpaceUnits('µm');
            TrackingAnalysis =      TrackingAnalysis.setTimeUnits('minutes');

        end

        function MyTrackingAnalysis_Pixel =          getPixelTrackingAnalysis(obj)
            MyTrackingAnalysis_Pixel =                  obj.getTrackingAnalysis;
            MyTrackingAnalysis_Pixel =                  MyTrackingAnalysis_Pixel.setTimeUnits('frames');
            MyTrackingAnalysis_Pixel =                  MyTrackingAnalysis_Pixel.setSpaceUnits('pixels');
        end

        function TrackingAnalysis =                  getTrackingAnalysis(obj)
            % GETTRACKINGANALYSIS
            TrackingAnalysis =  PMTrackingAnalysis(...
                                        obj.Tracking.get('Model'), ...
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

        function obj = setInteractionsCapture(obj, Value)
            obj.Interactions = Value;
            
          
        
          
        end


        function obj = setInteractions(obj, Value)
            error('Use setInteractionsCapture instead.')
        end


        
    
  

    end

    methods % GETTERS INTERACTIONS 
        
        function interactions = getInteractionsCapture(obj)
              interactions = obj.Interactions;
        end
        
        function obj = setShowThresholdedImage(obj, Value)
            
            obj.Interactions = obj.Interactions.setShowThresholdedImage(Value);
        end
        
         function interactions = getInteractions(obj)
             % GETINTERACTIONS returns 'PMInteractionsCapture' object;
                error('Use getInteractionsCapture instead.')
         end
         
        function thresholds = getDefaultThresholdsForAllPlanes(obj)
            % GETDEFAULTTHRESHOLDSFORALLPLANES returns default threshold values;
            % numeric vector with a number for each plane;
            thresholds(1: obj.getMaxPlaneWithoutDriftCorrection, 1) = 30;

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
            % GETTIMESTAMPS returns cell string with formatted time of all frames;

            TimesInSeconds=            obj.TimeCalibration.getRelativeTimeStampsInSeconds;
            strings =                   arrayfun(@(x) PMTime(x).getMinSecString, TimesInSeconds, 'UniformOutput', false);
            
           
        end

        function planeStamps =  getPlaneStamps(obj) 
            % GETPLANESTAMPS returns cell string with for all Z-planes
              PlanesAfterDrift =         obj.getMaxPlaneWithAppliedDriftCorrection;
              planeStamps =             (arrayfun(@(x) ...
                  sprintf('Z-depth= %i µm', int16((x-1) * obj.SpaceCalibration.getDistanceBetweenZPixels_MicroMeter)), ...
                  1 : PlanesAfterDrift, ...
                  'UniformOutput', false))';
        end

        function string  =      getActivePlaneStamp(obj)
            % GETACTIVEPLANESTAMP
            myPlaneStamps =     obj.getPlaneStamps;
            string =            myPlaneStamps{obj.getActivePlanesWithAppliedDriftCorrection};
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
            summary = PMImageFiles(obj.getPathsOfImageFiles, obj.WantedScene).getMetaDataSummary;
        end
        
        function MetaDataString =       getMetaDataString(obj)
            % GETMETADATASTRING
            MetaDataString =             PMImageFiles(obj.getPathsOfImageFiles, obj.WantedScene).getMetaDataString;
        end
   
    end
    
    methods (Access = private) % AUTOCELLRECOGNTION
        
        function controller =                           getAutoCellRecognitionControllerInternal(obj, View)
            controller =                            PMAutoCellRecognitionController(obj.AutoCellRecognition, View);
            
        end
        
         function SegmentationCaptureSourceList =        getSegmenationCaptureSourceListForFramesWithAuto(obj, FramesThatShouldBeTracked)
            % GETSEGMENATIONCAPTURESOURCELISTFORFRAMES returns PMSegmentationCapture vector for input frames;
            % this vector can be used for various cell tracking objectives;

             ChannelIWant =                      obj.AutoCellRecognition.getActiveChannel;
            
             
             SegmentationCaptureSourceList =        getSegmenationCaptureSourceListForFramesChannel(obj, FramesThatShouldBeTracked, ChannelIWant);
           

         end
        
        
    end
    
    methods (Access = private) % SETTERS CROPPING
        
        function obj =              moveCroppingGateToActiveMask(obj)
            % MOVECROPPINGGATETOACTIVEMASK sets center of cropping gate to current position of active track;
            % takes 0 arguments
            Coordinates =   obj.Tracking.get('CoordinatesOfActiveTrackForFrame', obj.getActiveFrames);
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
    
    methods (Access = private) % GETTERS NAVIGATION

    
        
        function AplliedPlaneShifts = getMaxAplliedPlaneShifts(obj)
            AplliedPlaneShifts =  max(obj.DriftCorrection.getAplliedPlaneShifts);
        end 

      
        
      function rows = getMaxRowWithAppliedDriftCorrection(obj)
        rows =          obj.Navigation.getMaxRow + obj.getMaxAplliedRowShifts;
    end

    function columns = getMaxColumnWithAppliedDriftCorrection(obj)
        columns =       obj.Navigation.getMaxColumn +obj.getMaxAplliedColumnShifts;
    end




   end

    methods (Access = private) % SETTERS FILE-MANAGEMENT

        function obj =      setPathsThatDependOnAnnotationFolder(obj)
            % SETPATHSTHATDEPENDONANNOTATIONFOLDER changes paths that depend on annotation folder path
            % sets folder for tracking-data
             obj.Tracking =          obj.Tracking.performMethod('setMainFolder', obj.getTrackingFolder);

        end
        
        function obj =      loadCurrentVersion(obj)
            assert(obj.canConnectToSourceFile, 'Cannot connect to movie-tracking file.')

            obj =                   obj.loadDataForFileFormat_AfterAugust2021;
            obj.Tracking =          PMTrackingNavigationController(PMTrackingNavigation(obj.getTrackingFolder));
            try
                obj.Tracking =      obj.Tracking.performMethod('load');
                obj.Tracking =              obj.Tracking.permformMethod('initializeWithDrifCorrectionAndFrame', obj.DriftCorrection, obj.Navigation.getMaxFrame);

            catch
                warning('Tracking was not loaded.')
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
          %  obj.AnnotationFolder =              MovieTrackingInfo.File.AnnotationFolder   ;

            if isfield(MovieTrackingInfo.File, 'WantedScene')
                obj.WantedScene =              MovieTrackingInfo.File.WantedScene      ;

            end
            
            obj.Keywords =                      MovieTrackingInfo.File.Keywords;
            
            obj.DriftCorrection  =              MovieTrackingInfo.File.DriftCorrection     ;
            obj.Interactions =                  MovieTrackingInfo.File.Interactions        ;

            obj.StopDistanceLimit =             MovieTrackingInfo.StopTracking.StopDistanceLimit            ;
            obj.MaxStopDurationForGoSegment =   MovieTrackingInfo.StopTracking.MaxStopDurationForGoSegment;    
            obj.MinStopDurationForStopSegment = MovieTrackingInfo.StopTracking.MinStopDurationForStopSegment  ;

            obj.ImageMapPerFile =               MovieTrackingInfo.ImageMapPerFile        ;
            
            
            obj.ImageMapPerFile =               cellfun(@(x) ...
                                                        PMImageMap().getCompletedImageMap(x), ...
                                                        obj.ImageMapPerFile, ...
                                                        'UniformOutput', false...
                                                        );
            
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

          
            if isempty(MovieTrackingInfo.Channels.Channels)

            else
                obj =   obj.setChannels(MovieTrackingInfo.Channels.Channels);
                obj =   obj.setActiveChannel(MovieTrackingInfo.Channels.ActiveChannel);

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


            obj.Tracking =              obj.Tracking.permformMethod('initializeWithDrifCorrectionAndFrame', obj.DriftCorrection, obj.Navigation.getMaxFrame);

            if isempty(obj.Interactions) || ~isa(obj.Interactions, 'PMInteractionsCapture')
                obj.Interactions =      PMInteractionsCapture;

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
                    case 'LoadMasks'
                        exists = exist(obj.getPathOfMovieTrackingForSmallFile) == 2 ;
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

               MovieTrackingInfo.File.WantedScene =             obj.WantedScene;
          
            
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

             MovieTrackingInfo.Channels.ActiveChannel =             obj.getActiveChannelIndex ;
             MovieTrackingInfo.Channels.Channels =                  obj.getChannels;

             
             
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
                case 0
                     paths{1,1 } =       obj.getPathOfMovieTrackingForSmallFile;
                            paths{2,1 } =       obj.getTrackingFolder;
                            
                
               
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

    methods (Access = private) % GETTERS LOADED IMAGE-VOLUMES
        
       
        
        function requiredFrames =                   removeAlreadyLoadedFramesFromFrames(obj, requiredFrames)
            requiredFrames(obj.getAlreadyLoadedFrames, 1) =     false;
            requiredFrames =                            find(requiredFrames);
        end

        function requiredFrames =                   getSetFrameRanged(obj)
            requiredFrames(1: obj.getMaxFrame, 1) = false;
            
            range =                                 obj.getActiveFrames - obj.getLimitForLoadingFrames : obj.getActiveFrames + obj.getLimitForLoadingFrames;
            range(range <= 0) =                       [];
            range(range > obj.getMaxFrame) =        [];
            requiredFrames(range,1) =               true;
        end
        
        function requiredFrames =                   getEntireFrameRange(obj)
             requiredFrames(1: obj.getMaxFrame, 1) = true;
            
        end
        
        function frames =                           getLimitForLoadingFrames(obj, varargin)  
            
            switch length(varargin)

            case 0
               Key = 'LoadSet';
            case 1
               Key = 'LoadOnlyOne';
            otherwise
               error('Wrong input.')


            end

            switch Key

            case 'LoadOnlyOne'
                frames =        0;
            otherwise
                frames =        obj.DefaultNumberOfLoadedFrames;

            end


        end
        
        function framesThatHaveTheMovieAlreadyLoaded = getAlreadyLoadedFrames(obj)
            framesThatHaveTheMovieAlreadyLoaded =         cellfun(@(x)  ~isempty(x),     obj.LoadedImageVolumes);   
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
    
    methods (Access = private) % GETTER IMAGES FROM FILE:
        
         function number = getNumberOfOpenFiles(obj)
             number = length(fopen('all'));
         end
         

            function TempVolumes = loadImageVolumesForFramesInternal(obj, ListOfFramesThatShouldBeLoaded)
                
                if isempty(ListOfFramesThatShouldBeLoaded)
                    TempVolumes = '';
                    
                else
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
            
                MyImageSource =              obj.getImageSource(FrameNumber);                                    
                VolumeReadFromFile =         MyImageSource.getImageVolume;
                                                    
                ProcessedVolume =           PM5DImageVolume(VolumeReadFromFile).filter(obj.getReconstructionTypesOfChannels).getImageVolume;
                
                Time =  toc;
                fprintf('PMMovieTracking: @getImageVolumeForFrame. Loading frame %i from file. Duration: %8.5f seconds.\n', FrameNumber, Time)

        end
        
        function BitInformation = getBitsForFrame(obj, FrameNumber)
            
            
        end
        
     
        
        
        
        
    end
   
     methods (Access = private) %  GETTERS IMAGES

        function rgbImage =             addInteractionImageToImage(obj, rgbImage)

            InteractionImage =      obj.getInteractionImage;
            if isempty(InteractionImage)

            else

                switch class(rgbImage)

                    case 'uint8'
                        InteractionImage = InteractionImage * 150;
                    case 'uint16'
                        InteractionImage = InteractionImage * 50000;
                    otherwise
                        error('Wrong input.')


                end

                rgbImage = PMRGBImage().addImageWithColor(...
                                                            rgbImage, ...
                                                            InteractionImage, ...
                                                            'Red'...
                                                            );
            end
        end

        function image =                getInteractionImage(obj)
            % GETINTERACTIONIMAGE 
            % returns processed "interaction image";
            % thresholded image that contains all "target pixels" for interaction analysis;

            if ~obj.Interactions.getShowThresholdedImage

                image = '';

            else

                MyInteractionsCapture =         obj.getInteractionsCapture;
                MyInteractionsCapture =         MyInteractionsCapture.setMovieTracking(obj);
                ThresholdedImage =              MyInteractionsCapture.getImageVolume;
                filtered =                      obj.filterImageVolumeByActivePlanes(ThresholdedImage);
                image =                         max(filtered, [], 3);

            end

        end
        
         function filtered = filterImageVolumeByActivePlanes(obj, Volume)
            % FILTERIMAGEVOLUMEBYACTIVEPLANES
            
              VisiblePlanesWithoutDriftCorrection =         obj.getVisibleTrackingPlanesWithoutDriftCorrection;
              filtered =                                    Volume(:, :, VisiblePlanesWithoutDriftCorrection, :, :);
         end
        

        function rgbImage =             addMasksToImage(obj, rgbImage)

            if obj.getMaskVisibility 


            ColorOfSelectedTracks =     obj.getColorOfSelectedMasksForImage(rgbImage);
          
            ListWithSelectedMasks =     obj.getTracking.get('SelectedMasksAtFramePlaneDrift', ...
                                                obj.getActiveFrames, ...
                                                obj.getVisibleTrackingPlanesWithoutDriftCorrection, ...
                                                obj.getDriftCorrection...
                                                );
            
            
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, ListWithSelectedMasks, 1, ColorOfSelectedTracks(1));
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, ListWithSelectedMasks, 2, ColorOfSelectedTracks(2));
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, ListWithSelectedMasks, 3, ColorOfSelectedTracks(3));

            ActiveMask =                obj.getTracking.get('ActiveMasksAtFramePlaneDrift', ...
                                        obj.getActiveFrames, ...
                                        obj.getVisibleTrackingPlanesWithoutDriftCorrection, ...
                                        obj.getDriftCorrection...
                                        );
                                    
            Intensity =                 obj.getColorOfActiveMaskForImage(rgbImage);
            rgbImage =                  obj.highlightPixelsInRgbImage(rgbImage, ActiveMask, 1:3, Intensity);

            end

        end
        
        function MaskColor =                        getColorOfSelectedMasksForImage(obj, rgbImage)
            MaskColor(1) =          obj.MaskColor(1);
            MaskColor(2) =          obj.MaskColor(2);
            MaskColor(3) =          obj.MaskColor(3);

            if strcmp(class(rgbImage), 'uint16')
                MaskColor(1) =          MaskColor(1) * 255;
                MaskColor(2) =          MaskColor(2) * 255;
                MaskColor(3) =          MaskColor(3) * 255;
            end
        end
        
        function Intensity =                        getColorOfActiveMaskForImage(~, rgbImage)
            Intensity =    100;
            switch(class(rgbImage))
            case 'uint8'
            case 'uint16'
            Intensity = Intensity * 255;        
            otherwise
            error('Input not supported.')
            end
        end

        function  CleanedUpVolume =     convertImageVolumeToActiveImage(obj, activeVolume)
            % CONVERTIMAGEVOLUMETOACTIVEIMAGE returns 2D-image matrix, where each pixel has intensity of active channel;
            % all pixels outside of applied cropping rectange are set to zero;

            obj =                           obj.setVisibilityToActiveChannel;
            obj =                           obj.resetChannelSettings('Red', 'ChannelColors');
            Image =                         obj.convertImageVolumeIntoRgbImage(activeVolume); 
            MyImageVolume =                 Image(:,:,1);
            
            CleanedUpVolume =               MyImageVolume;
            CleanedUpVolume(:, :) =         0;
            Rectangle =                     obj.getAppliedCroppingRectangle;
            
             try
            if isscalar(CleanedUpVolume)
                
            else
            CleanedUpVolume(Rectangle(2): Rectangle(2) + Rectangle(4)-1,Rectangle(1): Rectangle(1) + Rectangle(3) - 1) = ...
            MyImageVolume(Rectangle(2): Rectangle(2) + Rectangle(4)-1,Rectangle(1): Rectangle(1) + Rectangle(3) - 1);
            end
            
             catch
                 
                warning('Could not apply rectangle.') 
             end
            

        end

        function rgbImage =             convertImageVolumeIntoRgbImageInternal(obj, SourceImageVolume)

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
                    SelectedTrackID =      Code;
                    Frame =         NaN;

                case 'char'
                    switch Code
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
        indices = obj.Tracking.get('IndicesOfFinishedTracksFromList', List); 
        end

        function SelectedTrackID =                      getIdOfTrackThatIsClosestToPoint(obj, Point)

            TrackDataOfCurrentFrame =       obj.Tracking.get('SegmentationOfFrame', obj.Navigation.getActiveFrames); 
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
            [limits, ids] =     obj.Tracking.get('LimitsOfFirstForwardGapOfAllTracksForLimitValue',  obj.Navigation.getMaxFrame);
        end
        
        function [limits, ids] =                    getLimitsOfSurroundedFirstForwardGapOfAllTracks(obj)
             [limits, ids] =    obj.Tracking.get('LimitsOfSurroundedFirstForwardGapOfAllTracks');
        end
        
        function [Gaps, TrackIdsToToggle] =         getLimitsOfUnfinishedBackwardGaps(obj)
            % GETLIMITSOFUNFINISHEDBACKWARDGAPS
            % like GETLIMITSOFFIRSTFORWARDGAPOFALLTRACKS, except that "backward" gaps rather than "foward" gaps are returned;
            [Gaps, TrackIdsToToggle] =           obj.Tracking.get('LimitsOfFirstBackwardGapOfAllTracksForLimitValue',  obj.Navigation.getMaxFrame);
            Indices =                           obj.getIndicesOfFinishedTracksFromList(TrackIdsToToggle);
            TrackIdsToToggle(Indices, :) =      [];  
            Gaps(Indices, :) = [];
        end

 
        
      
         
    end

    methods (Access = private) % PROCESS DRIFT CORRECTION
        function removeDriftCorrection(obj)
           error('Not supported anymore. Use removeAppliedDriftCorrection instead.')
        end
        
        function addDriftCorrection(obj)
           error('Not supported anymore. Use addAppliedDriftCorrection instead.')
        end
        
        
        function [xCoordinates, yCoordinates, zCoordinates ] =              removeAppliedDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
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
        
        
        
        function [xCoordinates, yCoordinates, zCoordinates ] =              addAppliedDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates) 
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
            if     rowFinal >= 1 && rowFinal <= obj.Navigation.getMaxRow 
            else
                rowFinal = NaN;
            end
        end

        function columnFinal = verifyXCoordinate(obj, columnFinal)
            if    columnFinal >= 1 && columnFinal <= obj.Navigation.getMaxColumn 
            else
              columnFinal = NaN;
            end
        end

        function planeFinal = verifyZCoordinate(obj, planeFinal)
            if    planeFinal >= 1 && planeFinal <= obj.getMaxPlaneWithoutDriftCorrection
            else
              planeFinal = NaN;
            end
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