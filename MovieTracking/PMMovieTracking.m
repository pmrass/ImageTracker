classdef PMMovieTracking < PMChannels
    %PMMOVIETRACKING manage viewing and tracking of movie
    %   This class manages viewing and tracking.
    
    properties        
        % these are "hard-data" that should always come from the file:
        Tracking =                  PMTrackingNavigation
        
    end
    
    properties (Access = private)
        
        %% saving crucial
        NickName
        
        Folder                  % movie folder:
        AttachedFiles =            cell(0,1) % list files that contain movie-information;
        FolderAnnotation =     '' % folder that contains files with annotation information added by user;
      
         DriftCorrection =           PMDriftCorrection
         
         
         %% saving not crucial
         Navigation =                PMNavigationSeries
         
         AllPossibleEditingActivities =              {'No editing','Manual drift correction','Tracking'};
         Keywords =             cell(0,1)
       
         
         TimeVisible =                  true
         PlanePositionVisible =         true
         
         CollapseAllTracking =          false

         CentroidsAreVisible =       false
         TracksAreVisible =          false
         MasksAreVisible =           false
         ActiveTrackIsHighlighted =  false
         
         UnsavedTrackingDataExist =   true
         
         %% this can be always reconstructed from file, but it may be faster to save in file;
         ImageMapPerFile
         TimeCalibration =           PMTimeCalibrationSeries
         SpaceCalibration =          PMSpaceCalibrationSeries 
         
         CollapseAllPlanes =         1
         
         CroppingOn =               0
         CroppingGate =             [1 1 1 1]
         
         ScaleBarVisible =           1   
         ScaleBarSize =              50
        
         
    end
    
    methods
        
        function obj =                                                  PMMovieTracking(varargin)
            
            fprintf('\n@Create PMMovieTracking.\n')
            NumberOfInputArguments = length(varargin);
            switch NumberOfInputArguments
                case 0
                case 1
                    if isa(varargin{1}, 'PMMovieTrackingSummary')
                            obj.NickName =       varargin{1}.NickName;
                            obj.Folder =                 varargin{1}.Folder; 
                            obj.AttachedFiles =         varargin{1}.AttachedFiles;
                            obj.Keywords =          varargin{1}.Keywords;
                    else
                        obj.NickName = varargin{1};
                    end
                case 3
                    StructureOrNickName =  varargin{1};
                    if ischar(varargin{3})
                          
                    else
                        
                       switch varargin{3}
                        case 0 % this is a simple way to create a very basic object;
                            myFilesOrFolders =              StructureOrNickName.AttachedFiles;
                            EmptyRows =                     cellfun(@(x) isempty(x), myFilesOrFolders);
                            myFilesOrFolders(EmptyRows) =   [];

                            obj.NickName =              StructureOrNickName.NickName;
                            obj.Folder =                varargin{2};
                            obj.AttachedFiles =         myFilesOrFolders;


                            % if the user input was a folder, this means a folder with subfiles was selected and the subfiles have to be extracted;
                            % currently only the .pic format is organized in this way;
                            FolderWasSelected =     cellfun(@(x) isfolder(x), obj.getPathsOfImageFiles);
                            FolderWasSelected =     unique(FolderWasSelected);
                            if length(FolderWasSelected) ~=1
                                error('Cannot select a mix of files and folder') 
                            end

                             if FolderWasSelected
                                 ListWithExtractedFiles =       obj.extractFileNameListFromFolder(myFilesOrFolders);
                                 obj.AttachedFiles =        ListWithExtractedFiles;
                             else

                             end

                            obj.DriftCorrection =                                       PMDriftCorrection(StructureOrNickName, varargin{3});
                            obj.Tracking =                                              PMTrackingNavigation(StructureOrNickName,varargin{3});

                        case 1 % for loading from file

                            fprintf('Set NickName, Folder and FolderAnnotation.\n')
                            if isstruct(StructureOrNickName)
                                obj.NickName =      StructureOrNickName.NickName;
                            else
                                obj.NickName =      StructureOrNickName;
                            end
                            
                            obj.Folder =             varargin{2}{1};
                            obj.FolderAnnotation =   varargin{2}{2};
                            obj.Folder =             varargin{2}{1};
                            obj =                   obj.loadLinkeDataFromFile;   
                            obj.FolderAnnotation =   varargin{2}{2}; %

                        case 2
                            obj.NickName =                                              StructureOrNickName.NickName;
                            obj.Keywords{1,1}=                                          StructureOrNickName.Keyword;
                            obj.Folder =                                                varargin{2};
                            obj.AttachedFiles =                                         StructureOrNickName.FileInfo.AttachedFileNames;
                            obj.DriftCorrection =                                       PMDriftCorrection(StructureOrNickName, varargin{3});
                            obj =      setFrameTo(obj, StructureOrNickName.ViewMovieSettings.CurrentFrame);
                            [obj] =            setSelectedPlaneTo(obj, min(StructureOrNickName.ViewMovieSettings.TopPlane:StructureOrNickName.ViewMovieSettings.TopPlane+StructureOrNickName.ViewMovieSettings.PlaneThickness-1));
                            
                       
                            if isfield(StructureOrNickName.MetaData, 'EntireMovie') % without meta-data this field will stay empty; (need channel number to complete this; when using channels: this object must be completed);
                                 NumberOfChannels =     StructureOrNickName.MetaData.EntireMovie.NumberOfChannels;
                                obj.Channels =      obj.setDefaultChannelsForChannelCount(NumberOfChannels);
                             end

                            obj.CollapseAllPlanes =                     StructureOrNickName.ViewMovieSettings.MaximumProjection;
                            obj.PlanePositionVisible =                  StructureOrNickName.ViewMovieSettings.ZAnnotation;
                            obj.TimeVisible =                           StructureOrNickName.ViewMovieSettings.TimeAnnotation;
                            obj.ScaleBarVisible =                       StructureOrNickName.ViewMovieSettings.ScaleBarAnnotation;   

                            if isfield(StructureOrNickName.ViewMovieSettings, 'CropLimits')
                                obj =                      obj.setCroppingGateWithRectange(StructureOrNickName.ViewMovieSettings.CropLimits);
                            else
                                obj =                      obj.resetCroppingGate;
                            end
                            obj.CroppingOn =                            0;
                            obj.Tracking =                               PMTrackingNavigation(StructureOrNickName.TrackingResults,varargin{3});
                       otherwise
                        error('Cannot create movie tracking. Reason: loaded version is not supported')
                       end   
                   end
    
                case 4
                          fprintf('Set NickName, Folder and FolderAnnotation.\n')
                            if isstruct(varargin{1})
                                obj.NickName =      varargin{1}.NickName;
                            else
                                obj.NickName =      varargin{1};
                            end
                            
                            obj.Folder =             varargin{2}{1};
                            obj.FolderAnnotation =   varargin{2}{2};
                            obj =   obj.setActiveChannel(varargin{4});
                            obj =   obj.loadLinkeDataFromFile;   
                            obj.FolderAnnotation =   varargin{2}{2}; % duplicate because in some files this information may not be tehre
                otherwise
                    error('Wrong number of arguments')
            end
          
        end
        
        %%ScaleBarSize
        function obj = setScaleBarSize(obj, Value)
           obj.ScaleBarSize =  Value;
        end
        
        function obj = set.ScaleBarSize(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
           obj.ScaleBarSize =  Value;
        end
        
        
        %% setCollapseAllPlanes
        function obj = toggleCollapseAllPlanes(obj)
            obj.CollapseAllPlanes = ~obj.CollapseAllPlanes;
        end
        
        function obj = setCollapseAllPlanes(obj, Value)
            obj.CollapseAllPlanes = Value;
        end
        
        function obj = set.CollapseAllPlanes(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CollapseAllPlanes = Value;
        end
        
        function Value = getCollapseAllPlanes(obj)
            Value = obj.CollapseAllPlanes;
        end
        
        
        %% MasksAreVisible
         function obj = toggleMaskVisibility(obj)
            obj.MasksAreVisible = ~obj.MasksAreVisible;
        end
        
        function obj = setMaskVisibility(obj, Value)
            obj.MasksAreVisible = Value;
        end
        
        function obj = set.MasksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.MasksAreVisible = Value;
        end
        
        function Value = getMaskVisibility(obj)
            Value = obj.MasksAreVisible;
        end
        
        %% CentroidsAreVisible
        function obj = toggleCentroidVisibility(obj)
            obj.CentroidsAreVisible = ~obj.CentroidsAreVisible;
        end
        
        function obj = setCentroidVisibility(obj, Value)
            obj.CentroidsAreVisible = Value;
        end
        
        function obj = set.CentroidsAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CentroidsAreVisible = Value;
        end
        
        function Value = getCentroidVisibility(obj)
            Value = obj.CentroidsAreVisible;
        end
        
        %% TracksAreVisible
        function obj = toggleTrackVisibility(obj)
            obj.TracksAreVisible = ~obj.TracksAreVisible;
        end
        
        function obj = setTrackVisibility(obj, Value)
            obj.TracksAreVisible = Value;
        end
        
        function obj = set.TracksAreVisible(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.TracksAreVisible = Value;
        end
        
        function Value = getTrackVisibility(obj)
            Value = obj.TracksAreVisible;
        end
        
        %% UnsavedTrackingDataExist
        function status = getUnsavedDataExist(obj)
           status = obj.UnsavedTrackingDataExist; 
            
        end

        %% accessors:
        function tracking = getTracking(obj)
           tracking = obj.Tracking; 
        end
        
        
          function obj = setTimeVisibility(obj, Value)
              obj.TimeVisible = Value;
          end
          
          function obj = set.TimeVisible(obj, Value)
              assert(islogical(Value) && isscalar(Value), 'Wrong input.')
              obj.TimeVisible = Value;
          end
            
          function Visible = getTimeVisibility(obj)
             Visible = obj.TimeVisible;
          end
          
          function obj = hideTime(obj)
              obj.TimeVisible =     false;
          end
        
          function obj = showTime(obj)
            obj.TimeVisible =     true;
         end
        
          function obj = setPlaneVisibility(obj, Value)
             obj.PlanePositionVisible = Value;
          end
         
          function obj = set.PlanePositionVisible(obj, Value)
               assert(islogical(Value) && isscalar(Value), 'Wrong input.')
             obj.PlanePositionVisible = Value;
          end
         
          function value = getPlaneVisibility(obj)
              value = obj.PlanePositionVisible;
          end
         
          function obj = hidePlane(obj)
              obj.PlanePositionVisible = false;
          end
        
          function obj = showPlane(obj)
              obj.PlanePositionVisible = true;  
          end
          
          %% updateTrackingWith
          function obj = updateTrackingWith(obj, Value)
             obj.Tracking = obj.Tracking.updateWith(Value); 
          end
          
        
          %% scale-bar
          function obj = toggleScaleBarVisibility(obj)
             obj.ScaleBarVisible = ~obj.ScaleBarVisible; 
          end
          
          function obj = setScaleBarVisibility(obj, Value)
             obj.ScaleBarVisible = Value; 
          end
          
          function obj = set.ScaleBarVisible(obj, Value)
              assert(islogical(Value) && isscalar(Value), 'Wrong input.')
             obj.ScaleBarVisible = Value; 
          end
          
          function Value = getScaleBarVisibility(obj)
             Value = obj.ScaleBarVisible; 
          end
          
          
          %% hideScale
          function obj = hideScale(obj)
            obj.ScaleBarVisible =          false;
          end
        
          function obj = showScale(obj)
             obj.ScaleBarVisible =          tru;
         end
        

        %% setActiveTrackIsHighlighted
        function obj = setActiveTrackIsHighlighted(obj, Value)
           obj.ActiveTrackIsHighlighted = Value; 
        end
        
        function obj = set.ActiveTrackIsHighlighted(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
           obj.ActiveTrackIsHighlighted = Value; 
        end
        
         function Value = getActiveTrackIsHighlighted(obj)
           Value = obj.ActiveTrackIsHighlighted ; 
        end
        
        %% other:
        function possibleActivities = getPossibleEditingActivities(obj)
            possibleActivities = obj.AllPossibleEditingActivities;
        end
        
           %% getNumberOfLinkedMovieFiles:
           function number = getNumberOfLinkedMovieFiles(obj)
               number = length(obj.getLinkedMovieFileNames);
           end
           
           function linkeFiles = getLinkedMovieFileNames(obj)
              linkeFiles =  obj.AttachedFiles;  
           end
           
           %% setNamesOfMovieFiles:
           function [obj] =            setNamesOfMovieFiles(obj, Value)
              obj.AttachedFiles =       Value;
           end
           
           function obj = set.AttachedFiles(obj, Value)
               assert(iscellstr(Value), 'Invalid argument type.')
               obj.AttachedFiles = Value;
           end
           
           
          
           
        %% setNickName
        function [obj] =        setNickName(obj, String)
            OldPath =           obj.getPathOfMovieTrackingFile;
            obj.NickName =       String;
            if isempty(OldPath)
            else
                obj=                obj.renameMovieDataFile(OldPath);
            end

        end

        function fileName =     getPathOfMovieTrackingFile(obj)
            if isempty(obj.FolderAnnotation) || isempty(obj.NickName)
                fileName = '';
            else
                fileName = [obj.FolderAnnotation '/' obj.NickName  '.mat'];
            end
        end

        function obj =          set.NickName(obj, Value)
            assert(ischar(Value), 'Wrong argument type.')
            obj.NickName =   Value; 
        end
        
        function name = getNickName(obj)
           name = obj.NickName;
            
        end

        function [obj]=         renameMovieDataFile(obj, OldPath)
             if isequal(OldPath, obj.getPathOfMovieTrackingFile)
             else
                status =            movefile(OldPath, obj.getPathOfMovieTrackingFile);
                if status ~= 1
                    error('Renaming file failed.') 
                else
                    fprintf('File %s was renamed successfully to %s.\n', OldPath, obj.getPathOfMovieTrackingFile)
                end
                obj =      obj.setSavingStatus(false);
             end

         end

        function [obj] =        setSavingStatus(obj, Value)
            obj.UnsavedTrackingDataExist = Value;
        end
        
        %% setKeywords
           function obj =        setKeywords(obj, Value)
               if isempty(Value)
                  Value = 'Regular image'; 
               end
               
               if iscell(Value)
                  Value = Value{1,1}; 
               end
                obj.Keywords{1,1} =                   Value;
           end
          
           function obj = set.Keywords(obj, Value)

               assert(iscellstr(Value), 'Invalid argument type.')
               obj.Keywords =   Value;
           end
           
           function keywords = getKeywords(obj)
               keywords = obj.Keywords; 
           end
        
        %% setImageAnalysisFolder
          function [obj] =   setImageAnalysisFolder(obj, FolderName)
            fprintf('PMMovieTracking:@setImageAnalysisFolder to "%s".\n', FolderName)
            obj.FolderAnnotation =  FolderName;
          end
        
          function obj = set.FolderAnnotation(obj, Value)
              assert(ischar(Value), 'Wrong argument type.')
              obj.FolderAnnotation = Value;
          end
          
        %% setMovieFolder
          function obj = setMovieFolder(obj, Value)
              obj.Folder = Value;   
          end
          
          function obj = set.Folder(obj, Value)
              assert(ischar(Value) || isempty(Value), 'Invalid argument type.')
              obj.Folder = Value;   
          end
          
        %% setCollapseAllTrackingTo
        function obj =      setCollapseAllTrackingTo(obj, Value)
            obj.CollapseAllTracking = Value;
        end
        
        function Value =      getCollapseAllTracking(obj)
            Value = obj.CollapseAllTracking;
        end
        
        
        %% setDriftCorrectionTo
         function obj =      setDriftCorrectionTo(obj,OnOff)
            obj.DriftCorrection = obj.DriftCorrection.setDriftCorrectionActive(OnOff);
         end
        
        %% getDriftCorrectionStatus
         function value = getDriftCorrectionStatus(obj) 
             value = obj.DriftCorrection.getDriftCorrectionActive;
         end
         
        %% loadLinkeDataFromFile
        function obj =       loadLinkeDataFromFile(obj)
                obj =                       obj.getObjectFromFile;
                obj.DriftCorrection =       obj.DriftCorrection.setNavigation(obj.Navigation);
        end
        
          function ReadObject = getObjectFromFile(obj)
            fprintf('PMMovieTracking: Load from file.\n')
            assert(exist(obj.getPathOfMovieTrackingFile) == 2, 'File not found.')
            Data =              load(obj.getPathOfMovieTrackingFile, 'MovieAnnotationData');
            ReadObject =        Data.MovieAnnotationData;
          end
        
        %% drift correction related
          function DriftCorrectionWasPerformed =             testForExistenceOfDriftCorrection(obj)
               if isempty(obj.DriftCorrection)
                    DriftCorrectionWasPerformed =           false;
               else
                    DriftCorrectionWasPerformed=            obj.DriftCorrection.testForExistenceOfDriftCorrection;
               end
          end
        
          
          function obj = applyManualDriftCorrection(obj)
             obj.DriftCorrection =  obj.DriftCorrection.updateByManualDriftCorrection;
          end
         
         function myDriftCorrection = getDriftCorrection(obj)
            myDriftCorrection = obj.DriftCorrection;
         end
         
         function obj = setDriftCorrection(obj, Value)
            obj.DriftCorrection = Value;
         end
         
         function obj = set.DriftCorrection(obj, Value)
            assert(isa(Value, 'PMDriftCorrection') && isscalar(Value), 'Wrong input.')
            obj.DriftCorrection = Value;
         end
        
         %% getActivePositionsOfManualDriftcorrectionFor
        function coordinatesWithDrift = getActivePositionsOfManualDriftcorrectionFor(obj, varargin)
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    Argument = varargin{1};
                    switch Argument
                        case 'X'
                            coordinatesWithDrift = obj.getActiveXPositionsOfManualDriftcorrection;
                        case 'Y'
                            coordinatesWithDrift = obj.getActiveYPositionsOfManualDriftcorrection;
                        case 'Z'
                            coordinatesWithDrift = obj.getActiveZPositionsOfManualDriftcorrection;
                    end
            end
 
        end
        
         function xWithDrift = getActiveXPositionsOfManualDriftcorrection(obj)
            ManualDriftCorrectionValues =   obj.DriftCorrection.getManualDriftCorrectionValues;
            xWithoutDrift =                 ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 2);
            yWithoutDrift =                 ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 3);
            planeWithoutDrift =             ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 4);
            [xWithDrift, ~, ~ ] =     obj.addDriftCorrection(xWithoutDrift, yWithoutDrift, planeWithoutDrift);
         end
         
         
        
          function [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates) 
                CurrentFrame =                                      obj.getActiveFrames;
                [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame);
          end
          
        function frames = getActiveFrames(obj)
            frames = obj.Navigation.getActiveFrames;
        end
        
        
          
          function [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates, CurrentFrame)
                xCoordinates=         xCoordinates + obj.getAplliedColumnShiftsForActiveFrames;
                yCoordinates=         yCoordinates + obj.getAplliedRowShiftsForActiveFrames;
                zCoordinates=         zCoordinates + obj.getAplliedPlaneShiftsForActiveFrames;
          end
          
        function final = getAplliedColumnShiftsForActiveFrames(obj)
             shifts =   obj.getAplliedColumnShifts;
             final =    shifts(obj.getActiveFrames);
        end
         
          function final = getAplliedRowShiftsForActiveFrames(obj)
             shifts = obj.getAppliedRowShifts;
             final = shifts(obj.getActiveFrames);
          end
          
           function final = getAplliedPlaneShiftsForActiveFrames(obj)
            shifts = obj.getAplliedPlaneShifts;
            final = shifts(obj.getActiveFrames);
           end
        
        function yWithDrift = getActiveYPositionsOfManualDriftcorrection(obj)
               ManualDriftCorrectionValues =   obj.DriftCorrection.getManualDriftCorrectionValues;

            xWithoutDrift =                 ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 2);
            yWithoutDrift =                 ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 3);
            planeWithoutDrift =             ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 4);

            [~, yWithDrift, ~ ] =     obj.addDriftCorrection(xWithoutDrift, yWithoutDrift, planeWithoutDrift);


            
        end
        
        function PlaneWithDrifCorrection = getActiveZPositionsOfManualDriftcorrection(obj)
           
               ManualDriftCorrectionValues =   obj.DriftCorrection.getManualDriftCorrectionValues;

            xWithoutDrift =                 ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 2);
            yWithoutDrift =                 ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 3);
            planeWithoutDrift =             ManualDriftCorrectionValues(obj.Navigation.getActiveFrames, 4);

            [~, ~, PlaneWithDrifCorrection ] =     obj.addDriftCorrection(xWithoutDrift, yWithoutDrift, planeWithoutDrift);


            
        end
        
        %% setDriftDependentParameters
        function obj =  setDriftDependentParameters(obj)
            fprintf('Enter PMMovieTracking:@setDriftDependentParameters: \n')
            
            obj.DriftCorrection =           obj.DriftCorrection.setNavigation(obj.Navigation);
            obj.Tracking =      obj.Tracking.setTrackingCellForTimeWithDriftByDriftCorrection(obj.getDriftCorrection);
            fprintf('Exit PMMovieTracking:@setDriftDependentParameters.\n')
        end
        
        %% mergeActiveTrackWithTrack
        function obj = mergeActiveTrackWithTrack(obj, IDOfTrackToMerge)
            obj.Tracking =      obj.Tracking.splitTrackAtFrame(obj.getActiveFrames-1, obj.getIdOfActiveTrack, obj.Tracking.generateNewTrackID);
            obj.Tracking =      obj.Tracking.mergeTracks([obj.getIdOfActiveTrack,    IDOfTrackToMerge]);
        end
        
        %% loadHardLinkeDataFromFile:
         function obj =       loadHardLinkeDataFromFile(obj)
            LoadedMovieTracking =                obj.getObjectFromFile;

            obj.DriftCorrection =       LoadedMovieTracking.DriftCorrection;
            obj.DriftCorrection =       obj.DriftCorrection.setNavigation(obj.Navigation);
            obj.Tracking =              LoadedMovieTracking.Tracking;
            if ~isempty(LoadedMovieTracking.Channels)
                obj.Channels =              LoadedMovieTracking.Channels  ;  
            end
            
            if (1==2) % this is a mess; maybe better just to load these data from the TIFF file?;
            
                obj.Navigation =            LoadedMovieTracking.Navigation   ;        
                obj.TimeCalibration =       LoadedMovieTracking.TimeCalibration  ;  
                obj.SpaceCalibration =      LoadedMovieTracking.SpaceCalibration  ;  

               
            end
            
            obj = obj.finalizeMovieTracking;
            
         end
         
         function obj = finalizeMovieTracking(obj)
            if ~obj.isMapped  
                obj =   obj.setImageMapFromFiles;
            end
            
            obj =       obj.finalizeDriftCorrection;
            obj =       obj.initializeTracking;
                
         end
         
          function test = isMapped(obj)
            test = ~isempty(obj.ImageMapPerFile);
          end

          
        function obj =                                  setImageMapFromFiles(obj)
            fprintf('\nPMMovieTracking:@setImageMapFromFiles.\n')
            if isempty(obj.getPathsOfImageFiles)
                fprintf('Files not connected. Attempt to create image map incomplete.\n')
            else
                 % usually this will done only a single time for each file;
                % then the map and meta-data are saved in file enabling faster reading, still using other functions for retrieving data from file (with the help of this map);

                myImageFiles = PMImageFiles(obj.getPathsOfImageFiles);

                if myImageFiles.notAllFilesCouldBeRead
                    warning('At least one source file could not be read. No action taken.\n')
                   
                else
                    
                     fprintf('All source files could be accessed. Retrieving MetaData and ImageMaps.\n')

                    obj.ImageMapPerFile =              myImageFiles.getImageMapsPerFile; 
                    obj.SpaceCalibration =             myImageFiles.getSpaceCalibration; 
                    obj.TimeCalibration =              myImageFiles.getTimeCalibration; 
                    obj.Navigation =                   myImageFiles.getNavigation; 

                    obj.DriftCorrection =               obj.DriftCorrection.setNavigation(obj.Navigation);
                    obj =                               obj.setImageMapDependentProperties;

                    if obj.getNumberOfChannels ~= obj.Navigation.getMaxChannel
                        obj = obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);
                    end

                end

            end

        end
        
         function obj = finalizeDriftCorrection(obj)
            if isempty(obj.DriftCorrection)
                obj.DriftCorrection =               PMDriftCorrection(0,0);
            end
            obj.DriftCorrection =    obj.DriftCorrection.update;

         end
         
         function obj = initializeTracking(obj)
                if isstruct(obj.Tracking) || isempty(obj.Tracking)
                    obj.Tracking = PMTrackingNavigation(0,0);
                end
                obj.Tracking = obj.Tracking.initializeWithDrifCorrectionAndFrame(obj.DriftCorrection, obj.Navigation.getMaxFrame);
         end
         
     
        function obj = set.SpaceCalibration(obj,Value)
            assert(isa(Value,'PMSpaceCalibrationSeries') , 'Wrong input format.')
            obj.SpaceCalibration =  Value;
        end
        
        function calibration = getSpaceCalibration(obj, Value)
            calibration = obj.SpaceCalibration.Calibrations(1);
            
        end
        
        function Value = convertXYZPixelListIntoUm(obj, Value)
            Value = obj.SpaceCalibration.Calibrations.convertXYZPixelListIntoUm(Value);
        end
        
        function Value = convertYXZUmListIntoPixel(obj, Value)
            Value = obj.SpaceCalibration.Calibrations.convertYXZUmListIntoPixel(Value);
        end
        
        function obj = setNavigation(obj, Value)
            obj.Navigation =        Value;
            obj.DriftCorrection =   obj.DriftCorrection.setNavigation(Value);
        end
        
        function obj = set.Navigation(obj,Value)
             assert(isa(Value,'PMNavigationSeries') && length(Value) == 1, 'Wrong input format.')
            obj.Navigation =  Value;
        end
        
        %% save object:
           function  [obj] = saveMovieData(obj)
               fprintf('PMMovieTracking:@saveMovieData": ')
               if obj.UnsavedTrackingDataExist 
                   obj =        obj.saveMovieDataWithOutCondition;
               else
                    fprintf('Tracking data were already saved. Therefore no action taken.\n')
               end
           end
       
          function obj = saveMovieDataWithOutCondition(obj)
                fprintf('\nEnter PMMovieTracking:@saveMovieDataWithOutCondition:\n')
                fprintf('Get copy of PMMovieTracking object.\n')
                
                MovieAnnotationData =                       obj;
                MovieAnnotationData.Tracking =       MovieAnnotationData.Tracking.removeRedundantData;
              
                save(obj.getPathOfMovieTrackingFile, 'MovieAnnotationData')
                fprintf('File %s was saved successfully.\n', obj.getPathOfMovieTrackingFile)
                obj =                               obj.setSavingStatus(false);

                fprintf('Exit PMMovieTracking:@saveMovieDataWithOutCondition.\n\n')
            
          end
        
        %% deleteFile
          function obj = deleteFile(obj)
              fprintf('\nEnter PMMovieTracking:@deleteFile:\n')
              if exist(obj.getPathOfMovieTrackingFile) == 2
                delete(obj.getPathOfMovieTrackingFile)
              end
              fprintf('Exit PMMovieTracking:@deleteFile.\n\n')
          end
        
        %% testForExistenceOfTracking
        function DriftCorrectionWasPerformed =             testForExistenceOfTracking(obj)
           if isempty(obj.Tracking)
                DriftCorrectionWasPerformed =           false;
           else
                DriftCorrectionWasPerformed=            obj.Tracking.testForExistenceOfTracks;
           end
        end
          
        %% setActiveTrackToNewTrack
        function obj = setActiveTrackToNewTrack(obj)
            obj =     obj.setActiveTrackWith(obj.findNewTrackID);
        end
        
          function newTrackID =             findNewTrackID(obj)
                obj.Tracking =  obj.Tracking.removeInvalidSegmentationFromeFrame(obj.Navigation.getActiveFrames);
                newTrackID =    obj.Tracking.generateNewTrackID;
                fprintf('Tracking identified %i as new track ID.\n', newTrackID)
          end
          
         function obj =              setActiveTrackWith(obj, NewTrackID)
                obj.Tracking =      obj.Tracking.setActiveTrackIDTo(NewTrackID);
       end
        
        %% deleteActiveTrack
        function obj = deleteActiveTrack(obj)
                obj.Tracking  =     obj.Tracking.removeTrack(obj.getIdOfActiveTrack);
                obj.Tracking =      obj.Tracking.setActiveTrackID(obj.Tracking.getIDOfFirstSelectedTrack);
                obj =               obj.setActiveTrackWith(obj.getIdOfActiveTrac);
            
        end
        
        function [IdOfActiveTrack] =                    getIdOfActiveTrack(obj)
            IdOfActiveTrack =                           obj.Tracking.getIdOfActiveTrack;
        end
        
      
       
       %% setSelectedTrackIdsTo
       function obj = setSelectedTrackIdsTo(obj, Value)
           obj.Tracking =  obj.Tracking.setSelectedTrackIdsTo(Value);
       end
       
       %% selectAllTracks
       function obj = selectAllTracks(obj)
            obj.Tracking =  obj.Tracking.selectAllTracks;
       end
        
       %% removeMasksWithNoPixels
       function obj = removeMasksWithNoPixels(obj)
          obj.Tracking = obj.Tracking.removeMasksWithNoPixels; 
       end
       
       %% addToSelectedTrackIds
       function obj = addToSelectedTrackIds(obj, TracksToAdd)
           obj.Tracking =    obj.Tracking.addToSelectedTrackIds(TracksToAdd);
       end
       
       %% minimizeMasksOfActiveTrackAtFrame
       function obj = minimizeMasksOfActiveTrackAtFrame(obj, FrameIndex)
            MiniSegmentationOfActiveTrack =     obj.Tracking.getMiniMask(obj.getUnfilteredSegmentationOfActiveTrack);
            obj.Tracking =                      obj.Tracking.replaceMaskInTrackingCellForTimeWith(MiniSegmentationOfActiveTrack);
            obj =                               obj.setFrameAndAdjustPlaneAndCropByTrack(SourceFrames(FrameIndex)); 
                 
       end
  
        %% getAllTrackIDs
        function trackIds = getAllTrackIDs(obj)
             trackIds =    obj.Tracking.getListWithAllUniqueTrackIDs;
            
        end
        
        %% getSelectedTrackIDs
         function trackIds = getSelectedTrackIDs(obj)
             trackIds =    obj.Tracking.getIdsOfSelectedTracks;
            
         end
        
        %% getCoordinatesForTrack
        function coordinates = getCoordinatesForTrack(obj, TrackID)
               [coordinates] =        obj.Tracking.getCoordinatesForTrackID(TrackID, obj.DriftCorrection);
        end
        
        %% setNumberOfFramesInSubTracks:
       
         function [obj]=             setNumberOfFramesInSubTracks(obj, Frames)
            obj.Tracking.TrackNumberOfFramesInSubTracks =        Frames;
         end
        
        %% setFinishStatusOfTrackTo:
           function obj =   setFinishStatusOfTrackTo(obj, input)
              obj.Tracking = obj.Tracking.setInfoOfActiveTrack(input);
              fprintf('Finish status of track %i was changed to "%s".\n', obj.getIdOfActiveTrack, input)
           end
           
        %% getTrackingAnalysis:
        function TrackingAnalysis =     getTrackingAnalysis(obj)
            TrackingAnalysis =  PMTrackingAnalysis(obj.Tracking, obj.DriftCorrection, obj.SpaceCalibration, obj.TimeCalibration);
        end
        
        %% updateMaskOfActiveTrackByAdding:
        function [obj] =                                updateMaskOfActiveTrackByAdding(obj, yList, xList, plane)
            if isempty(yList) || isempty(xList)
            else
                pixelListToAdd =              [yList,xList];
                pixelListToAdd(:,3) =         plane;
                pixelList_AfterAdding =       unique([obj.Tracking.getPixelsOfActiveMaskFromFrame(obj.getActiveFrames); pixelListToAdd], 'rows');
                mySegementationCapture =      PMSegmentationCapture(pixelList_AfterAdding, 'Manual');
                [obj] =                       obj.resetActivePixelListWith(mySegementationCapture);
            end
            
        end
     
        function [obj] =             resetActivePixelListWith(obj, SegmentationCapture)
                obj.Tracking =      obj.Tracking.setActiveFrameTo(obj.getActiveFrames);
                obj.Tracking =      obj.Tracking.setActiveTrackID(obj.getIdOfActiveTrack);
                obj.Tracking =      obj.Tracking.addSegmentation(SegmentationCapture);
                obj =               obj.setSavingStatus(true);
              
        end
      
        %% get segmentation of current frame:
        function [segmentationOfCurrentFrame ] =            getUnfilteredSegmentationOfCurrentFrame(obj)
            segmentationOfCurrentFrame =        obj.Tracking.getSegmentationOfFrame( obj.Navigation.getActiveFrames);
        end
        
        %% get segmentation of active track:
        function [segmentationOfTrack] =                    getUnfilteredSegmentationOfTrack(obj, TrackID)
            segmentationOfTrack =       obj.Tracking.getSegmentationOfAllWithTrackID(TrackID);   
        end
        
        %% get unfiltered segmentation of active track:
        function segmentationOfActiveTrack =          getUnfilteredSegmentationOfActiveTrack(obj)
             segmentationOfCurrentFrame =                         obj.getUnfilteredSegmentationOfCurrentFrame;

            rowOfActiveTrack =                              obj.getRowOfActiveTrackIn(segmentationOfCurrentFrame);
             if sum(rowOfActiveTrack) ==                    0
                  segmentationOfActiveTrack =   cell(0,length(obj.Tracking));
             else
                 segmentationOfActiveTrack =     segmentationOfCurrentFrame(rowOfActiveTrack,:);
             end

        end
              
        function rowOfActiveTrack =      getRowOfActiveTrackIn(obj,segmentationOfCurrentFrame)
        rowOfActiveTrack =           cell2mat(segmentationOfCurrentFrame(:,obj.Tracking.getTrackIDColumn)) == obj.getIdOfActiveTrack ;
        end

        %% getMaxColumnWithAppliedDriftCorrection
        function columns = getMaxColumnWithAppliedDriftCorrection(obj)
            columns =       obj.Navigation.getMaxColumn +obj.getMaxAplliedColumnShifts;
        end
  
        %% getCurrentFrame
        function [currentFrame] =        getCurrentFrame(obj)
            currentFrame = obj.getActiveFrames;
        end

        %% getMaxFrame
        function [frameNumbers] =        getMaxFrame(obj)
            frameNumbers =      obj.Navigation.getMaxFrame;
        end

        %% getCurrentDriftCorrectionValues
        function [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =        getCurrentDriftCorrectionValues(obj)   
                CurrentColumnShift=           obj.getAplliedColumnShiftsForActiveFrames;
                CurrentRowShift=               obj.getAplliedRowShiftsForActiveFrames;
                CurrentPlaneShift =            obj.getAplliedPlaneShiftsForActiveFrames;
       end
        
        function [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
            CurrentFrame =                  obj.getActiveFrames;
            [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame);
        end
        
        function [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame)
                xCoordinates=       obj.removeDriftCorrectionX(xCoordinates);
                yCoordinates=       obj.removeDriftCorrectionY(yCoordinates);
                zCoordinates=       obj.removeDriftCorrectionZ(zCoordinates);
        end

        function xCoordinates = removeDriftCorrectionX(obj, xCoordinates)
             xCoordinates=       xCoordinates - obj.getAplliedColumnShiftsForActiveFrames;
        end
        
        function xCoordinates = removeDriftCorrectionY(obj, xCoordinates)
             xCoordinates=       xCoordinates - obj.getAplliedRowShiftsForActiveFrames;
        end
        
        function xCoordinates = removeDriftCorrectionZ(obj, xCoordinates)
             xCoordinates=       xCoordinates - obj.getAplliedPlaneShiftsForActiveFrames;
        end
          
        %% getFramesForTracking
          function [StartFrames,EndFrames] =                  getFramesForTracking(obj, Parameter)
                TrackingStartFrame =                                obj.getActiveFrames;
                [firstUntrackedFrame, lastUntrackedFrame] =         obj.getFirstLastContiguousUntrackedFrame;
                switch Parameter
                    case 'forward'
                            StartFrames =                        TrackingStartFrame:lastUntrackedFrame-1;
                            EndFrames =                          StartFrames + 1;
                    case 'backward'
                            StartFrames =            TrackingStartFrame:-1:firstUntrackedFrame+1;
                            EndFrames =              StartFrames - 1;
                end
          end
            
            function [firstUntrackedFrame, lastUntrackedFrame] =                getFirstLastContiguousUntrackedFrame(obj)
        
                TrackingStartFrame =                    obj.getActiveFrames;
                TrackID =                               obj.getIdOfActiveTrack;
                allFramesOfCurrentTrack  =              obj.Tracking.getAllFrameNumbersOfTrackID(TrackID);

                % get last untracked frame:
                AfterLastUntrackedTrackedFrame =        find(allFramesOfCurrentTrack>TrackingStartFrame,  1, 'first');
                if isempty(AfterLastUntrackedTrackedFrame)
                    lastUntrackedFrame =                  obj.Navigation.getMaxFrame;
                else
                    lastUntrackedFrame =                  allFramesOfCurrentTrack(AfterLastUntrackedTrackedFrame) - 1;
                end

                 % get first untracked frame:
                BeforeFirstUntrackedFrame =             find(allFramesOfCurrentTrack<TrackingStartFrame,  1, 'last');
                if isempty(BeforeFirstUntrackedFrame)
                    firstUntrackedFrame =          1;
                else
                    firstUntrackedFrame =          allFramesOfCurrentTrack(BeforeFirstUntrackedFrame) + 1;
                end

        
            end
        
        
        function pixelList_Modified =                            getPixelsFromActiveMaskAfterRemovalOf(obj, pixelListToRemove)
            
              if ~(isempty(pixelListToRemove(:,1)) || isempty(pixelListToRemove(:,2)))  
                    pixelList_Original =        obj.Tracking.getPixelsOfActiveMaskFromFrame(obj.getActiveFrames);
                    pixelList_Modified =      pixelList_Original;
             
                    deleteRows =             ismember(pixelList_Original(:,1:2), [pixelListToRemove(:,1) pixelListToRemove(:,2)], 'rows');
                    pixelList_Modified(deleteRows,:) =               [];
              end
        end
  
        function numberOfFrames =                           getUniqueFrameNumberFromImageMap(obj, ImageMap)
            ColumnWithTime = 10;
            numberOfFrames =             length(unique(cell2mat(ImageMap(2:end,ColumnWithTime))));   
        end

        %% get track ID where next frame has no mask:
        function trackIDsWithNoFollowUp =                                 getTrackIDsWhereNextFrameHasNoMask(obj)
            CurrentFrame =                                              obj.getActiveFrames;
            MaxFrame = obj.Navigation.getMaxFrame;
            if CurrentFrame >= MaxFrame 
                trackIDsWithNoFollowUp =                                  zeros(0,1);
            else                
                TrackIDsOfCurrentFrame =                                obj.getTrackIDsOfCurrentFrame;
                TrackIDsOfNextFrame =                                   obj.Tracking.getTrackIDsOfFrame(CurrentFrame + 1);
                trackIDsWithNoFollowUp =                                setdiff(TrackIDsOfCurrentFrame,TrackIDsOfNextFrame);
            end
        end
        
        function trackIDs =                                 getTrackIDsOfCurrentFrame(obj)
            TrackDataOfCurrentFrame =       obj.getTrackDataOfCurrentFrame;
            trackIDs =                      obj.Tracking.getTrackIDsFromSegmentationList(TrackDataOfCurrentFrame);
        end
        
          function TrackDataOfCurrentFrame =                  getTrackDataOfCurrentFrame(obj)
                TrackDataOfCurrentFrame =       obj.getTrackDataOfFrame(obj.getActiveFrames);
          end
          
         function segmentationOfCurrentFrame =              getTrackDataOfFrame(obj, FrameNumber)   
            segmentationOfCurrentFrame = obj.Tracking.getSegmentationOfFrame(FrameNumber);
         end

        %% unmap:
         function obj = unmap(obj)
                obj.ImageMapPerFile =                   [];
         end
        
         %%
         function plane = getMaxPlane(obj)
            plane = obj.Navigation.getMaxPlane; 
         end
         
        %% meta-data:
        function MetaDataString =   getMetaDataString(obj)
            myImageFiles =                          PMImageFiles(obj.getPathsOfImageFiles);
            MetaDataString =                        myImageFiles.getMetaDataString;
            obj.Viewer.InfoView.List.String =       myImageFiles.getMetaDataSummary;
            obj.Viewer.InfoView.List.Value =        min([length(obj.Viewer.InfoView.List.String) obj.Viewer.InfoView.List.Value]);
            
        end
        
        function StringOfTimeStamps = getTimeStamps(obj)
                TimeInSeconds=                obj.TimeCalibration.getRelativeTimeStampsInSeconds;

                TimeInMinutes=                TimeInSeconds / 60;
                MinutesInteger=               floor(TimeInMinutes);
                SecondsInteger=               round((TimeInMinutes- MinutesInteger)*60);
                SecondsString=                (arrayfun(@(x) num2str(x), SecondsInteger, 'UniformOutput', false));
                MinutesString=                (arrayfun(@(x) num2str(x), MinutesInteger, 'UniformOutput', false));
                StringOfTimeStamps=           cellfun(@(x,y) strcat(x, '''', y, '"'), MinutesString, SecondsString, 'UniformOutput', false);
          end
          
        function planeStamps = getPlaneStamps(obj) 
              PlanesAfterDrift =         obj.Navigation.getMaxPlane + max(obj.getAplliedPlaneShifts);
              planeStamps =             (arrayfun(@(x) sprintf('Z-depth= %i µm', int16((x-1) * obj.SpaceCalibration.getDistanceBetweenZPixels_MicroMeter)), 1:PlanesAfterDrift, 'UniformOutput', false))';;
        end
      
        function distance = getDistanceBetweenXPixels_MicroMeter(obj)
           distance = obj.SpaceCalibration.getDistanceBetweenXPixels_MicroMeter;
        end
            
        function string  = getActivePlaneStamp(obj)
             myPlaneStamps = obj.getPlaneStamps;
             string = myPlaneStamps{obj.getActivePlanes};
        end
         
        function frames = getActivePlanes(obj)
           frames = obj.Navigation.getActivePlanes;
        end
         
        function string  = getActiveTimeStamp(obj)
              myTimeStamps = obj.getTimeStamps;
             string = myTimeStamps{obj.getActiveFrames};
        end
        
       function InfoText =              getMetaDataInfoText(obj)

               dimensionSummaries =          obj.Navigation.getDimensionSummary;
               spaceCalibrationSummary =    obj.SpaceCalibration.getSummary;

               dataPerMovie = cell(length(obj.getLinkedMovieFileNames), 1);
               for index = 1: length(obj.getLinkedMovieFileNames)
                   textForCurrentMovei = [obj.getLinkedMovieFileNames{index}; dimensionSummaries{index}; spaceCalibrationSummary{index}; ' '];
                   dataPerMovie{index, 1} = textForCurrentMovei;

               end
                InfoText =                                          vertcat(dataPerMovie{:});
       end
           
        %% get images:
        function TempVolumes = loadImageVolumesForFrames(obj, numericalNeededFrames)
            TempVolumes = obj.loadImageVolumesForFramesInternal(numericalNeededFrames);
        end
        
        function paths = getPathsOfImageFiles(obj)
             if isempty(obj.getMovieFolder)
                 paths = '';
             else
                 paths = cellfun(@(x) [ obj.getMovieFolder '/' x], obj.getLinkedMovieFileNames, 'UniformOutput', false);
             end
            
        end
        
        function movieFolder = getMovieFolder(obj)
              movieFolder = obj.Folder;   
         end
                     
        %% show edge detection in view:
        function obj = showEdgeDetectionInView(obj, View)
              if obj.getActiveTrackIsHighlighted 
                     segmentationOfActiveTrack  =               obj.getSegmentationOfActiveTrack;
                     if ~isempty(segmentationOfActiveTrack)
                        SegmentationInfoOfActiveTrack = segmentationOfActiveTrack{1,7};
                        if ischar(SegmentationInfoOfActiveTrack.SegmentationType) || isempty(SegmentationInfoOfActiveTrack.SegmentationType)
                        else
                            SegmentationInfoOfActiveTrack.SegmentationType.highLightAutoEdgeDetection(View);

                        end
                     end
              end
        end

        function segmentationOfActiveTrack =                  getSegmentationOfActiveTrack(obj)
            segmentationOfActiveTrack =    obj.Tracking.getActiveSegmentationForFrames(obj.Navigation.getActiveFrames);
        end 

        %% getLastTrackedFrame      
        function lastOrFirstTrackedFrame =                         getLastTrackedFrame(obj, parameter)
                % from a contiguous stretch of tracked frames: get first or last frame in this contiguous sequence;
            
                
              
                if ~ismember(obj.getActiveFrames, obj.Tracking.getAllFrameNumbersOfTrackID(obj.getIdOfActiveTrack)) % perform this analysis only when the current position is tracked;
                      lastOrFirstTrackedFrame = NaN;
                      
                else
                     switch parameter
                        case 'up' 
                                lastOrFirstTrackedFrame =      PMVector(obj.Tracking.getAllFrameNumbersOfTrackID(obj.getIdOfActiveTrack)).getLastValueOfGaplessIntegerSeriesStartingFromValue(obj.getActiveFrames);
                        case 'down'
                            lastOrFirstTrackedFrame =          PMVector(obj.Tracking.getAllFrameNumbersOfTrackID(obj.getIdOfActiveTrack)).getFirstValueOfGaplessIntegerSeriesStartingFromValue(obj.getActiveFrames);

                    end
                    
                end   
        end
        
        %% getNumberOfTracks
        function numberOfTracks =   getNumberOfTracks(obj)
            numberOfTracks = obj.Tracking.getNumberOfTracks;
        end
        
        %% getDataType
       function DataType =                                  getDataType(obj)
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
           
       %% imageMatchesDimensions
       function value = imageMatchesDimensions(obj, Image)
           [rows, columns, planes] =                  obj.getImageDimensions;
           value(1) =   size(Image, 1) == rows;
           value(2) =   size(Image, 2) == columns;
           value(3) =   size(Image, 3) == planes;
           value =  min(value);  
       end
       
        function [rows, columns, planes] =                  getImageDimensions(obj)
            planes =        obj.Navigation.getMaxPlane;
            rows =          obj.Navigation.getMaxRow;
            columns =       obj.Navigation.getMaxColumn;
        end
        
        %% getSimplifiedImageMapForDisplay
        function imageMapOncell =        getSimplifiedImageMapForDisplay(obj)
               %% don't understand this one:
               function result =    convertMultiCellToSingleCell(input)
               
                   Dim =    size(input,1);
                   if Dim>1
                       result = '';
                       for index = 1:Dim
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
             imageSource = PMImageSource(obj.ImageMapPerFile, obj.Navigation);
         end
         
    
        
         
         
         
         function AplliedPlaneShifts = getMaxAplliedColumnShifts(obj)
            AplliedPlaneShifts =  max(getAplliedColumnShifts(obj));
         end 
         
        %% getAppliedCroppingRectangle 
        function croppingGate = getAppliedCroppingRectangle(obj)
            switch obj.CroppingOn
                case 1
                    croppingGate =          obj.CroppingGate;
                    croppingGate(1) =       croppingGate(1) + obj.getAplliedColumnShiftsForActiveFrames;
                    croppingGate(2) =       croppingGate(2) + obj.getAplliedRowShiftsForActiveFrames;
                otherwise
                    [rows,columns, ~] =     obj.getImageDimensionsWithAppliedDriftCorrection;
                    croppingGate =          [1 1 columns  rows];
            end

         end
       
        function [rows, columns, planes ] =     getImageDimensionsWithAppliedDriftCorrection(obj)
            rows =      obj.getMaxRowWithAppliedDriftCorrection;
            columns =   obj.getMaxColumnWithAppliedDriftCorrection;
            planes =    obj.getMaxPlaneWithAppliedDriftCorrection;
        end

        function rows = getMaxRowWithAppliedDriftCorrection(obj)
            rows =          obj.Navigation.getMaxRow + obj.getMaxAplliedRowShifts;
        end

        function AplliedPlaneShifts = getMaxAplliedRowShifts(obj)
            AplliedPlaneShifts =  max(obj.getAppliedRowShifts);
        end 

        function AplliedRowShifts = getAppliedRowShifts(obj)
            AplliedRowShifts = obj.DriftCorrection.getAppliedRowShifts;
        end
        
         function planes = getMaxPlaneWithAppliedDriftCorrection(obj)
            planes =        obj.Navigation.getMaxPlane + obj.getMaxAplliedPlaneShifts;
         end     
        
        function AplliedPlaneShifts = getMaxAplliedPlaneShifts(obj)
            AplliedPlaneShifts =  max(obj.getAplliedPlaneShifts);
        end 

        function AplliedPlaneShifts = getAplliedPlaneShifts(obj)
            AplliedPlaneShifts =  obj.DriftCorrection.getAplliedPlaneShifts;
        end

        %% getAppliedCroppingRectangle:
        function  XData = getXPointsForCroppingRectangleView(obj)
            StartColumn=    obj.CroppingGate(1) + obj.getAplliedColumnShiftsForActiveFrames;
            XData=          [StartColumn   StartColumn + obj.CroppingGate(3)     StartColumn + obj.CroppingGate(3)   StartColumn       StartColumn];   
        end

        function  YData = getYPointsForCroppingRectangleView(obj)
          StartRow=     obj.CroppingGate(2) + obj.getAplliedRowShiftsForActiveFrames;
          YData=        [StartRow  StartRow StartRow + obj.CroppingGate(4)  StartRow + obj.CroppingGate(4)  StartRow];
        end

        function obj =             resetCroppingGate(obj)
            obj.CroppingGate(1)=                  1;
            obj.CroppingGate(2)=                  1;
            obj.CroppingGate(3)=                  obj.Navigation.getMaxColumn;
            obj.CroppingGate(4)=                  obj.Navigation.getMaxRow;
        end

        function obj =       setCroppingGateWithRectange(obj, Rectangle)
            obj.CroppingGate =       Rectangle;
        end


        function obj = setCroppingStateTo(obj,OnOff)
            obj.CroppingOn =                                    OnOff;  
        end
        
        %% 
        function Value = getCroppingOn(obj)
            Value = obj.CroppingOn ;  
        end
        

        %% setFrameAndAdjustPlaneAndCropByTrack
        function obj =      setFrameAndAdjustPlaneAndCropByTrack(obj, FrameNumber)
            obj =           obj.setFrameTo(FrameNumber);
            obj =           obj.setSelectedPlaneTo(obj.getPlaneOfActiveTrack); % direct change of model:
            obj =           obj.moveCroppingGateToActiveMask; 
        end
        
        function obj =      setFrameTo(obj, FrameNumber)
            obj.Navigation =     obj.Navigation.setActiveFrames(FrameNumber);
            obj.Tracking =       obj.Tracking.setActiveFrameTo(FrameNumber);
        end
        
        function [obj] =            setSelectedPlaneTo(obj, selectedPlanes)
            obj.Navigation =        obj.Navigation.setActivePlanes(selectedPlanes);
        end
        
         function planeOfActiveTrack =                                       getPlaneOfActiveTrack(obj)
            segmentationOfActiveTrack =                 obj.getSegmentationOfActiveTrack;
            if isempty(segmentationOfActiveTrack)
                planeOfActiveTrack = NaN;
            else
                planeOfActiveTrack =            round(segmentationOfActiveTrack{1,obj.Tracking.getCentroidZColumn});
                [~, ~, planeOfActiveTrack ] =              obj.addDriftCorrection( 0, 0, planeOfActiveTrack);
            end

        end

        function obj =      moveCroppingGateToActiveMask(obj)
            if isempty(obj.getSegmentationOfActiveTrack)
                [centerY, centerX] =            deal(nan);
            else
                centerY =       obj.getSegmentationOfActiveTrack{1, obj.Tracking.getCentroidYColumn};
                centerX =       obj.getSegmentationOfActiveTrack{1, obj.Tracking.getCentroidXColumn};
            end
            obj =           obj.moveCroppingGateToNewCenter(centerX, centerY);
        end

        function obj =           moveCroppingGateToNewCenter(obj, centerX, centerY)
            if ~isnan(centerX)
                obj.CroppingGate(1) =        centerX - obj.CroppingGate(3) / 2;
                obj.CroppingGate(2) =        centerY - obj.CroppingGate(4) / 2; 
            end
        end

        %% get processed images:
        function ProcessedVolume = getImageVolumeForFrame(obj, FrameNumber)
            tic
            
                settings.SourceChannels =          [];
                settings.TargetChannels =          [];
                settings.SourcePlanes =            [];
                settings.TargetPlanes =            [];
                settings.TargetFrames =            1;

                settings.SourceFrames =     FrameNumber;
                 VolumeReadFromFile =        PMImageSource(obj.ImageMapPerFile, obj.Navigation, settings).getImageVolume;
                 ProcessedVolume =           PM5DImageVolume(VolumeReadFromFile).filter(obj.getReconstructionTypesOfChannels).getImageVolume;
             Time =  toc;
              fprintf('PMMovieTracking: @getImageVolumeForFrame. Loading frame %i from file. Duration: %8.5f seconds.\n', FrameNumber, Time)
              
        end
        
        function  rgbImage = convertImageVolumeIntoRgbImage(obj, SourceImageVolume)
           ImageVolume_Source =    SourceImageVolume(:, :, obj.getSelectedPlanesAsInSource, :, :);

            myRgbImage = PMRGBImage(...
                                    ImageVolume_Source, ...
                                    obj.getIndicesOfVisibleChannels, ...
                                    obj.getIntensityLowOfVisibleChannels, ...
                                    obj.getIntensityHighOfVisibleChannels, ...
                                    obj.getColorStringOfVisibleChannels ...
                                    );

            rgbImage = myRgbImage.getImage;
        end
                
        %% navigation
    
        function maxChannel = getMaxChannel(obj)
            maxChannel = obj.Navigation.getMaxChannel;
        end
      
            function obj = setChannels(obj, Value)
                assert(isa(Value, 'PMMovieTracking'), 'Wrong argument type.')
                obj.Channels = Value.Channels;
                
            end
            
           function [obj] =    resetChannelSettings(obj, Value, Field)
            
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


                end
            
           end
        
        %% geometry:
        
           function  [rowFinal, columnFinal, planeFinal] =                         verifyCoordinates(obj, rowFinal, columnFinal,planeFinal);
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
           
                  function SelectedTrackID = getIdOfTrackThatIsClosestToPoint(obj, Point)
                 
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
              
            function [ShortestDistance,rowWithShortestDistance] = computeShortestDistance(obj, Point, Coordinates)

                DistanceX=  Point(2)- Coordinates(:, 2);
                DistanceY=  Point(1)- Coordinates(:, 1);
                DistanceZ=  Point(3)- Coordinates(:, 3);

                if isempty(DistanceX) || isempty(DistanceY) || isempty(DistanceZ)
                    Distance=   nan;
                else
                    Distance=   sqrt(power(DistanceX,2) + power(DistanceY,2) + power(DistanceZ,2));
                end

                [ShortestDistance, rowWithShortestDistance]=  min(Distance);

            end
                
        %% get tracking navigation of selected tracks
        function [ TrackingNavigationOfSelected] =     getTrackingNavigationOfSelectedTracks(obj)
            selectedSegmentation =         obj.Tracking.getSelectedSegmentationForFramesPlanesDriftCorrection(obj.Navigation.getActiveFrames, obj.getVisibleSegmentationPlanesAsInSource, obj.DriftCorrection);
            TrackingNavigationOfSelected =  PMTrackingNavigation({selectedSegmentation});
        end
        
          function regularPlanes = getVisibleSegmentationPlanesAsInSource(obj)
            PlanesToBeShown=         obj.getVisibleSegmentationPlanesAsInView;
            [regularPlanes] =        obj.convertInputPlanesIntoRegularPlanes(PlanesToBeShown);
          end
        
        function visiblePlanes = getVisibleSegmentationPlanesAsInView(obj)
            switch obj.CollapseAllTracking
            case 1
                    visiblePlanes =     1 : obj.getMaxPlaneWithAppliedDriftCorrection;
                otherwise
                    visiblePlanes = obj.getActivePlanes;
            end
        end
        

        function [regularPlanes] =                  convertInputPlanesIntoRegularPlanes(obj, inputPlanes)
            % get planes without drift correction
            if obj.getDriftCorrectionStatus
                regularPlanes =                     inputPlanes - obj.getAplliedPlaneShiftsForActiveFrames;
                regularPlanes(regularPlanes<1) =    [];
                regularPlanes(regularPlanes>obj.Navigation.getMaxPlane) = [];
            else
                regularPlanes =                                       inputPlanes;
            end
        end

        %% getTrackingNavigationOfActiveTrack
        function [ TrackingNavigationOfSelected] =     getTrackingNavigationOfActiveTrack(obj)
            selectedSegmentation =         obj.Tracking.getActiveSegmentationForFramesAndPlanesWithDriftCorrection(obj.Navigation.getActiveFrames, obj.getVisibleSegmentationPlanesAsInSource, obj.DriftCorrection);
            TrackingNavigationOfSelected =  PMTrackingNavigation({selectedSegmentation});  
        end

        function obj =       setFocusOnActiveTrack(obj)
            obj =   obj.setSelectedPlaneTo(obj.getPlaneOfActiveTrack); % direct change of model:
            obj =   obj.moveCroppingGateToActiveMask;
        end

        %% executeAutoCellRecognition
        function obj = executeAutoCellRecognition(obj, myCellRecognition)
            myCellRecognition =     myCellRecognition.performAutoDetection;
            obj.Tracking =          obj.Tracking.setAutomatedCellRecognition(myCellRecognition);
            fprintf('\nCell recognition finished!\n')
            fprintf('\nAdding cells into track database ...\n')
            for CurrentFrame = myCellRecognition.getSelectedFrames' % loop through each frame 
                fprintf('Processing frame %i ...\n', CurrentFrame)
                obj =           obj.setFrameTo(CurrentFrame);
                PixelsOfCurrentFrame =      myCellRecognition.getDetectedCoordinates{CurrentFrame,1};
                for CellIndex = 1 : size(PixelsOfCurrentFrame,1) % loop through all cells within each frame and add to Tracking data
                    obj =      obj.setActiveTrackWith(obj.findNewTrackID);
                    obj =      obj.resetActivePixelListWith(PMSegmentationCapture(PixelsOfCurrentFrame{CellIndex,1}, 'DetectCircles'));
                end
            end
            fprintf('Cell were added into the database!\n')
        end
        
        
           
          %% mergeTracksWithinDistance
          function obj =    mergeTracksWithinDistance(obj, distance)
                 obj.Tracking =             obj.Tracking.setDistanceLimitZForTrackingMerging(2);
                 obj.Tracking =             obj.Tracking.setShowDetailedMergeInformation(true);
                 if isnan(distance)
                 else
                    obj.Tracking =        obj.Tracking.trackingByFindingUniqueTargetWithinConfines(distance);
                 end
          end
          
          %% deleteSelectedTracks
          function obj = deleteSelectedTracks(obj)
              obj.Tracking  =         obj.Tracking.deleteAllSelectedTracks;
          end
             
          
         %% checkConnectionToImageFiles
         function AllConnectionsOk = checkConnectionToImageFiles(obj)
             AllConnectionsOk = obj.checkConnectionToImageFilesInternal;
         end
     

           
         
    end
     
    methods (Access = private)
        
            %% loadImageVolumesForFramesInternal:
            function TempVolumes = loadImageVolumesForFramesInternal(obj, numericalNeededFrames)
                  TempVolumes =                   cell(length(numericalNeededFrames), 1);
                  if obj.checkConnectionToImageFiles 
                        obj =   obj.replaceImageMapPaths;
                         for frameIndex = 1:length(numericalNeededFrames)
                             TempVolumes{frameIndex,1} =        obj.getImageVolumeForFrame(numericalNeededFrames(frameIndex));
                         end
                  end  
            end
            
            
         function AllConnectionsOk = checkConnectionToImageFilesInternal(obj)
                RetrievedPointers =                 obj.getFreshPointersOfLinkedImageFilesInternal;
                ConnectionFailureList =             arrayfun(@(x) isempty(fopen(x)), RetrievedPointers);
                AtLeastOnePointerFailedToRead =     max(ConnectionFailureList);
                AllConnectionsOk =                  ~AtLeastOnePointerFailedToRead;
                RetrievedPointers(RetrievedPointers == -1) = [];
                
                if ~isempty(RetrievedPointers)
                    arrayfun(@(x) fclose(x), RetrievedPointers);

                end
                
         end
         
         function number = getNumberOfOpenFiles(obj)
             number = length(fopen('all'));
         end
        
         function pointers = getFreshPointersOfLinkedImageFilesInternal(obj)
                if isempty( obj.getPathsOfImageFiles)
                    pointers =  '';
                else
                    pointers =        cellfun(@(x) fopen(x), obj.getPathsOfImageFiles);
                end
         end
         

         function obj =    replaceImageMapPaths(obj)
             if obj.checkConnectionToImageFiles
                PointerColumn =                     3;
                FreshPaths = obj.getPathsOfImageFiles;
                for CurrentMapIndex = 1 : obj.getNumberOfLinkedMovieFiles
                    obj.ImageMapPerFile{CurrentMapIndex,1}(2:end,PointerColumn) =       {FreshPaths{CurrentMapIndex}};
                end 
             else
                 warning('Image files were not connected: No action taken.')
             end 
         end

      
        
        %% get basic drift correction information
         function AplliedColumnShifts = getAplliedColumnShifts(obj)
               AplliedColumnShifts =   obj.DriftCorrection.getAppliedColumnShifts;       
         end

        %% get planes as in source (i.e. without drift correction):
        function regularPlanes = getSelectedPlanesAsInSource(obj)
               PlanesToBeShown=         obj.getPlanesToBeShown;
               [regularPlanes] =        obj.convertInputPlanesIntoRegularPlanes(PlanesToBeShown);
           end

        function planesToBeShown = getPlanesToBeShown(obj)
          switch obj.CollapseAllPlanes
              case 1
                  planesToBeShown =     1 : obj.getMaxPlaneWithAppliedDriftCorrection;
              otherwise
                  planesToBeShown = obj.getActivePlanes;
          end
         end

    
        function obj = setChannelsToDefault(obj)
            obj = obj.setDefaultChannelsForChannelCount(obj.Navigation.getMaxChannel);
        end
                    
        function obj = setImageMapDependentProperties(obj)


          end
        
        %% get filenames from Pic folder:
        function [ListWithFileNamesToAdd] =         extractFileNameListFromFolder(obj, UserSelectedFileNames)    
            
            if isempty(obj.getMovieFolder)
                ListWithFileNamesToAdd =           '';
            else
                 PicFolderObjects =                      (cellfun(@(x) PMImageBioRadPicFolder([obj.getMovieFolder x]), UserSelectedFileNames, 'UniformOutput', false))';
                ListWithFiles =                         cellfun(@(x) x.FileNameList(:,1), PicFolderObjects,  'UniformOutput', false);
                ListWithFileNamesToAdd =                vertcat(ListWithFiles{:});
            end
               
           end
         
    end
        
         
    
end