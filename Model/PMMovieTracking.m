classdef PMMovieTracking
    %PMMOVIETRACKING manage viewing and tracking of movie
    %   Detailed explanation goes here
    
    properties
        
        % information related to source files:
        NickName
        
        Keywords =                  cell(0,1)
        Folder
        AttachedFiles
        
         ListWithPaths
        PointersPerFile =           -1
        FileCouldNotBeRead =        1
        
        
        % tracking: stats
        IdOfActiveTrack =           NaN
        ActiveTrackIsHighlighted =  false
        CentroidsAreVisible =       false
        TracksAreVisible =          false
        MasksAreVisible =           false
        CollapseAllTracking =       false
        
        DriftCorrectionOn =         false
        TrackingOn =                false
        
        
        % state for navigation: this is mostly relevant for the window controller but is here so that it can be saved conveniently on file;
        ScaleBarSize =              50
        ScaleBarVisible =           1   
        ScalebarStamp
        
        SelectedFrames =            1
        ListWithTimeStamps
        TimeVisible =               1

        SelectedPlanes =            1
        SelectedPlanesForView =     1
        ListWithPlaneStamps
        CollapseAllPlanes =         1
        PlanePositionVisible =      1
        
        SelectedChannels =          1 % if selected channels is 0 it shows incompleteness: check this field when using the channels ;
        SelectedChannelForEditing = 1
        ChannelTransformsLowIn
        ChannelTransformsHighIn
        ChannelColors =             cell(0,1);
        ChannelComments =           cell(0,1);
        
        ActiveChannel =             1 % this is used for tracking for example, need to add option that user can change this;
        
        CroppingGate =              [1 1 1 1]
        AppliedCroppingGate
        CroppingOn =                0
        
        
        
        %%  information that is read from linked files; 
        ImageMapPerFile
        ImageMap
        
        MetaData
        MetaDataOfSeparateMovies
        
       
        
        
        %% dimensions of drift correction and tracking are dependent on the movie files:
        % content is set by the user;
        DriftCorrection
        
        % tracking model content used for displaying data
        % there are now several different formats of the tracking data: maybe add a method to remove duplicate analysis to not boost storage space unnecessarily;
        Tracking % for storing basic migration data on file (new tracking data are moved directly here);
        TrackingAnalysis % is built from basic migration data and enables sophisticated analysis on tracks;
        
       
        
        

    end
    
    methods
        
        function obj =                                                  PMMovieTracking(MovieStructure, AdditionalInput, Version)
            
            %PMMOVIETRACKING add basic properties
            %   only basal information goes here
            % additional features, such as specific file information and mapping can be added optionally with specific methods;
         
            switch Version
                
                case 0 % this is the current default version:
                    
                    obj.NickName =                                              MovieStructure.NickName;
                    obj.Folder =                                                AdditionalInput;
                    obj.AttachedFiles =                                         MovieStructure.AttachedFiles;
                    
                    obj.DriftCorrection =                                       PMDriftCorrection(MovieStructure, Version);
                    obj.Tracking =                                              PMTrackingNavigation(MovieStructure,Version);

                    

                case 2
                    
                    obj.NickName =                                              MovieStructure.NickName;
                    obj.Keywords{1,1}=                                          MovieStructure.Keyword;
                    
                    obj.Folder =                                                AdditionalInput;
                    obj.AttachedFiles =                                         MovieStructure.FileInfo.AttachedFileNames;
                    

                    obj.DriftCorrection =                                       PMDriftCorrection(MovieStructure, Version);
                    
                  

                    
                    % obj.TrackingAnalysis =                                      PMTrackingAnalysis(obj.Tracking);
                    
                    
                    
                    %% add navigation state
                    obj.SelectedFrames =                    MovieStructure.ViewMovieSettings.CurrentFrame;
                    obj.SelectedPlanes =                    min(MovieStructure.ViewMovieSettings.TopPlane:MovieStructure.ViewMovieSettings.TopPlane+MovieStructure.ViewMovieSettings.PlaneThickness-1);
                 
                    obj.SelectedPlanesForView =             MovieStructure.ViewMovieSettings.TopPlane:MovieStructure.ViewMovieSettings.TopPlane+MovieStructure.ViewMovieSettings.PlaneThickness-1;

                     %% channel data from previous versions will be lost: this is just for display and would have been very complicated (because old dataset was inconcistent);
                    
                    if isfield(MovieStructure.MetaData, 'EntireMovie') % without meta-data this field will stay empty; (need channel number to complete this; when using channels: this object must be completed);
                         
                         NumberOfChannels =                      MovieStructure.MetaData.EntireMovie.NumberOfChannels;
                         obj =                                  obj.resetChannels(NumberOfChannels);
                         
                     end
                     
                    obj.CollapseAllPlanes =                     MovieStructure.ViewMovieSettings.MaximumProjection;

                    obj.PlanePositionVisible =                  MovieStructure.ViewMovieSettings.ZAnnotation;
                    obj.TimeVisible =                           MovieStructure.ViewMovieSettings.TimeAnnotation;
                    obj.ScaleBarVisible =                       MovieStructure.ViewMovieSettings.ScaleBarAnnotation;   
        
  
                    if isfield(MovieStructure.ViewMovieSettings, 'CropLimits')
                        obj.CroppingGate =                      MovieStructure.ViewMovieSettings.CropLimits;
                    else
                        obj.CroppingGate =                      [1 1 1 1];
                    end
                    
                    obj.CroppingOn =                            0;
 
                    obj.Tracking =                               PMTrackingNavigation(MovieStructure.TrackingResults,Version);
                    
                    
                   

                otherwise
                    
                    error('Cannot create movie tracking. Reason: loaded version is not supported')
                    
                    
                    
            end
            
            
        end
        
        
        %% basic methods that are used for creating the model:
        
        
          function [obj] = autoCorrectChannels(obj)
            
            NumberOfChannels = obj.MetaData.EntireMovie.NumberOfChannels;
            channelCheck = obj.verifyChannels(NumberOfChannels);
            if ~channelCheck
                obj = obj.resetChannels(NumberOfChannels);
            end
            
            
          end
        
        
           function [obj] = resetChannels(obj, NumberOfChannels)
            
            iSelectedChannels(1,1) =                             true;
            iSelectedChannels(2:NumberOfChannels,1) =            false;

            iSelectedChannelForEditing =                         1;
            iChannelTransformsLowIn(1:NumberOfChannels,1)=       0;
            iChannelTransformsHighIn(1:NumberOfChannels,1)=      0.7;
            iChannelColors(1:NumberOfChannels,1) =               {'Green'}; 
            iChannelComments(1:NumberOfChannels,1)=              {''};
            
            
            
            obj.SelectedChannels=               iSelectedChannels;
            obj.SelectedChannels =              iSelectedChannels;

            obj.SelectedChannelForEditing =                         iSelectedChannelForEditing;
            obj.ChannelTransformsLowIn=       iChannelTransformsLowIn;
            obj.ChannelTransformsHighIn=      iChannelTransformsHighIn;
            obj.ChannelColors =               iChannelColors; 
            obj.ChannelComments=              iChannelComments;
            
            end
        
         
            
          function obj = updateTimeStampStrings(obj)
             
             TimeInSeconds=                                     obj.MetaData.RelativeTimeStamps;
            
             
             TimeInMinutes=                                     TimeInSeconds/60;

            MinutesInteger=                                     floor(TimeInMinutes);
            SecondsInteger=                                     round((TimeInMinutes- MinutesInteger)*60);

            SecondsString=                                      (arrayfun(@(x) num2str(x), SecondsInteger, 'UniformOutput', false));
            MinutesString=                                      (arrayfun(@(x) num2str(x), MinutesInteger, 'UniformOutput', false));
            
          
            StringOfTimeStamps=                                 cellfun(@(x,y) strcat(x, '''', y, '"'), MinutesString, SecondsString, 'UniformOutput', false);

            
            obj.ListWithTimeStamps =                            StringOfTimeStamps;
            
             
             
          end
            
         
          function obj= updatePlaneStampStrings(obj)
             
            VoxelSizeZ=                             obj.MetaData.EntireMovie.VoxelSizeZ;
            Planes=                                 obj.MetaData.EntireMovie.NumberOfPlanes;
            obj.ListWithPlaneStamps=                (arrayfun(@(x) sprintf('Z-depth= %i µm', int16((x-1)*VoxelSizeZ*10^6)), 1:Planes, 'UniformOutput', false))';
  
         end
         
         
         
         function obj = updateScaleBarString(obj)
             
            LengthOfScaleBarInMicroMeter=            obj.ScaleBarSize;
            obj.ScalebarStamp=                       strcat(num2str(LengthOfScaleBarInMicroMeter), ' µm');

         end
          
         
         
         function [obj] =    resetViewPlanes(obj)
            
            
             
             Selection = obj.CollapseAllPlanes;
              switch Selection
                  
                  case 1
                    obj.SelectedPlanesForView = 1:obj.MetaData.EntireMovie.NumberOfPlanes; %CHANGE? to planes with drift correction?
                    
                  otherwise
                     obj.SelectedPlanesForView = obj.SelectedPlanes;
                      
                  
              end
              
              
            
            
         end
        
         
         
          function obj = hideTime(obj)
              
              obj.TimeVisible =     false;
        
            
            
        end
        
        
         function obj = showTime(obj)
            obj.TimeVisible =     true;
            
         end
        
          function obj = hidePlane(obj)
            
                  
              obj.PlanePositionVisible = false;
        

        end
        
        
         function obj = showPlane(obj)
             
              obj.PlanePositionVisible = true;
            
            
         end
        
          function obj = hideScale(obj)
            
            obj.ScaleBarVisible =          false;
        end
        
        
         function obj = showScale(obj)
             obj.ScaleBarVisible =          tru;
            
            
         end
        
         
         function obj = applyManualDriftCorrection(obj)
             
             
             obj.DriftCorrection =  obj.DriftCorrection.updateByManualDriftCorrection(obj.MetaData);
             
             
             
         end
        
          
          
        
        %% mapping image-data:
        % this time-consuming and potentially memory-intensive: therefore this is not called by default;
        function obj =                                  AddImageMap(obj)
            
            
                    
                    % usually this will done only a single time for each file;
                    % then the map and meta-data are saved in file enabling faster reading, still using other functions for retrieving data from file (with the help of this map);
                    
                    f =                                     waitbar(0.5, 'Mapping image file(s). This can take a few minutes for large files.'); % cannot do a proper waitbar because it is not a loop;
                    obj=                                    obj.updateFilePaths;
                    
                    
                    [~,~,Extensions] =                             cellfun(@(x) fileparts(x), obj.AttachedFiles, 'UniformOutput', false);
                    
                    Extension = unique(Extensions);
                    assert(length(Extension)==1, 'Can only work when all files have same format.')
                    Extension =     Extension{1,1};
                    
                    
                    
                    switch Extension
                        
                        case '.tif'
                            
                              myImageDocuments =                       cellfun(@(x)  PMTIFFDocument(x), obj.ListWithPaths);
                  
                            
                            
                        case '.czi'
                            
                            myImageDocuments =                          cellfun(@(x)  PMCZIDocument(x), obj.ListWithPaths);
                            
                        otherwise
                            
                            error('Format of image file not supported.')
                            
                            
                            
                        
                        
                    end
                    
                    
                    
                    
                    AtLeastOneTiffReadFailed = min(arrayfun(@(x) x.FilePointer, myImageDocuments)) == -1 ;
                    if AtLeastOneTiffReadFailed
                        
                        obj.ImageMapPerFile =               [];
                        obj.PointersPerFile =           -1;
                        obj.FileCouldNotBeRead =        1;
                    
                       
                        
                        
                    else

                        
                        % extract meta-data:
                        obj.MetaDataOfSeparateMovies =          arrayfun(@(x) x.MetaData, myImageDocuments, 'UniformOutput', false);
                        obj =                                   obj.createMergeOfMetaData;

                        
                        % extract image map -data:
                        obj.ImageMapPerFile =                   arrayfun(@(x) x.ImageMap, myImageDocuments, 'UniformOutput', false);
                         
                       % Number = obj.getUniqueFrameNumberFromImageMap(obj.ImageMap);
                        
                         obj =                                   obj.autoCorrectChannels;
                        obj =                                   obj.updateTimeStampStrings;
                        obj =                                   obj.updatePlaneStampStrings;
                        obj =                                   obj.updateScaleBarString;
                        obj =                                   obj.resetViewPlanes;

                        obj.PointersPerFile =                   -1;
                        obj.FileCouldNotBeRead =               0;
                      
                        
 
                        
                    end
                    
                    
                    
                     
                    
                   
                    waitbar(1, f, 'Mapping image file(s)');
                    close(f);

        end
        
        
        %% model:
        
        function numberOfFrames =            getUniqueFrameNumberFromImageMap(obj, ImageMap)
            
            ColumnWithTime = 10;
            numberOfFrames =             length(unique(cell2mat(ImageMap(2:end,ColumnWithTime))));
            
            
            
        end
        
        function obj =                       createMergeOfMetaData(obj)
              
              
             MetaDataCell =         obj.MetaDataOfSeparateMovies;
            
            NumberOfRows =      unique(cellfun(@(x) x.EntireMovie.NumberOfRows, MetaDataCell));
            NumberOfColumns =      unique(cellfun(@(x) x.EntireMovie.NumberOfColumns, MetaDataCell));
            NumberOfPlanes =    unique(cellfun(@(x) x.EntireMovie.NumberOfPlanes, MetaDataCell));
            NumberOfChannels =  unique(cellfun(@(x) x.EntireMovie.NumberOfChannels, MetaDataCell));
            VoxelSizeX =        unique(cellfun(@(x) x.EntireMovie.VoxelSizeX, MetaDataCell));
            VoxelSizeY =        unique(cellfun(@(x) x.EntireMovie.VoxelSizeY, MetaDataCell));
            VoxelSizeZ =        unique(cellfun(@(x) x.EntireMovie.VoxelSizeZ, MetaDataCell));
            
            assert(length(NumberOfRows) == 1 && length(NumberOfColumns) == 1 && length(NumberOfPlanes) == 1 && length(NumberOfChannels) == 1 && length(VoxelSizeX) == 1 && length(VoxelSizeY) == 1 && length(VoxelSizeZ) == 1, ...
                'Cannot combine the different files. Reason: Dimension or resolutions do not match')
            
            NumberOfTimePoints =                            sum(cellfun(@(x) x.EntireMovie.NumberOfTimePoints, MetaDataCell));
            
            
            MergedMetaData.EntireMovie.NumberOfRows =           NumberOfRows;
            MergedMetaData.EntireMovie.NumberOfColumns=         NumberOfColumns;
            MergedMetaData.EntireMovie.NumberOfPlanes =         NumberOfPlanes;
            MergedMetaData.EntireMovie.NumberOfTimePoints  =    NumberOfTimePoints;
            MergedMetaData.EntireMovie.NumberOfChannels =       NumberOfChannels;
            
            MergedMetaData.EntireMovie.VoxelSizeX=              VoxelSizeX;
            MergedMetaData.EntireMovie.VoxelSizeY=              VoxelSizeY;
            MergedMetaData.EntireMovie.VoxelSizeZ=              VoxelSizeZ;
         
            
            MyListWithTimeStamps =                                cellfun(@(x) x.TimeStamp, MetaDataCell, 'UniformOutput', false);
            
            MergedMetaData.PooledTimeStamps =                                  vertcat(MyListWithTimeStamps{:});
            MergedMetaData.RelativeTimeStamps =                                MergedMetaData.PooledTimeStamps - MergedMetaData.PooledTimeStamps(1);  
            
            
            obj.MetaData =                                          MergedMetaData;
           
        end

        
        function obj =                      refreshTrackingResults(obj)

            
            obj.TrackingAnalysis =                                 PMTrackingAnalysis(obj.Tracking, obj.DriftCorrection, obj.MetaData);
            
          
             
             obj =                                                  obj.synchronizeTrackingResults;
             
        end
        
        function obj = resetTrackingAnalysisToPhysicalUnits(obj)
            
            
            obj.TrackingAnalysis =      obj.TrackingAnalysis.convertDistanceUnitsIntoUm;
            obj.TrackingAnalysis =      obj.TrackingAnalysis.convertTimeUnitsIntoSeconds;
            
            
            
              
        
            
            
        end
        
        function obj =                  synchronizeTrackingResults(obj)
            

            obj.Tracking.ColumnsInTrackingCell =                   obj.TrackingAnalysis.ColumnsInTracksForMovieDisplay;
            obj.Tracking.Tracking =                                obj.TrackingAnalysis.TrackingListForMovieDisplay;
            obj.Tracking.TrackingWithDriftCorrection =             obj.TrackingAnalysis.TrackingListWithDriftForMovieDisplay;

            
            
        end
        
       
       

        %% file-management
        
        function [obj] =                                createFunctionalImageMap(obj)
            
            obj =                                       obj.createNewFilePointers;
            obj =                                       obj.verifyPointerConnection;
            if obj.FileCouldNotBeRead
                obj.ImageMap =                          [];
            else
                
                obj =                                       obj.replaceImageMapPointers;
                obj =                                       obj.mergeImageMaps;
            end
            
        end
        
        function [obj] =                            resetFolder(obj, Folder)
            obj.Folder =                            Folder;
            
            
        end
        
        function [obj] =                                updateFilePaths(obj)
            
            obj.ListWithPaths =                         cellfun(@(x) [ obj.Folder '/' x], obj.AttachedFiles, 'UniformOutput', false);
            
        end
        
        
         function [obj] =                                createNewFilePointers(obj)

            obj =                                       obj.updateFilePaths;
            obj.PointersPerFile =                       cellfun(@(x) fopen(x), obj.ListWithPaths);

        end
        
          
        function obj =                                  verifyPointerConnection(obj)
            
            
                ConnectionFailureList = arrayfun(@(x) isempty(fopen(x)), obj.PointersPerFile);
                AtLeastOnePointerFailedToRead = max(ConnectionFailureList);
                
                if AtLeastOnePointerFailedToRead % if that failed (because the hard-drive is disconnected or because the file was moved);;
                    obj.FileCouldNotBeRead = 1;
                    
                else
                    obj.FileCouldNotBeRead = 0;

                end
            
            
        end
        

        function obj =                                  replaceImageMapPointers(obj)
            
            % use the current file pointers and use them in the image map:

            PointerColumn =                     3;
            NumberOfImageMaps =     size(obj.ImageMapPerFile,1);
            for CurrentMapIndex = 1:NumberOfImageMaps
                CurrentNewPointer =                                                 obj.PointersPerFile(CurrentMapIndex);
                obj.ImageMapPerFile{CurrentMapIndex,1}(2:end,PointerColumn) =       {CurrentNewPointer};
                  
            end
  
        end
        

        function [obj] =                                updateFileReadingStatus(obj)
            
            %% test file connection and try to fix if there is a problem (use this method before trying to read from file;
            obj =                                       obj.verifyPointerConnection;
            
            if obj.FileCouldNotBeRead
                
                % try to make new pointers and test readability;
                obj =                               obj.createNewFilePointers;
                obj =                               obj.verifyPointerConnection;
                
                if obj.FileCouldNotBeRead % if new pointers don't work, give up for now, the user has to enter correct connection details, then it will work;
                    return
                else
                    % if the file can now be read: update image map with the new pointers;
                      obj = obj.replaceImageMapPointers;
                      % try to create new pointers with the filename;
                    
                end
                
            else
                
                % if the file could be read, "i.e. the pointers are ok", double check whether the pointers in the object are synchronized with the pointers in the image map;
                listWithPointers = obj.getCurrentPointersInImageMap;
                if ~isequal(obj.PointersPerFile, listWithPointers) % if the file pointers are correct, but the ones in the image map are wrong (for whatever reason): change them too;
                    obj = obj.replaceImageMapPointers;
                
                end
                
                
            end
            
          
            
            
        end
        
        

        %% helper functions for file- and image-managment:
        
        function [obj] =                                  mergeImageMaps(obj)
            
            %% get from model
            TimeColumn =                        10;
            ImageMapPerFileInternal =                   obj.ImageMapPerFile;
            
            %% pool image maps: (this is done on a copy becausre otherwise we would overwrite the time frames in the original which we don't want;
            FramesPerMap =                      cellfun(@(x) max(cell2mat(x(2:end,TimeColumn))), ImageMapPerFileInternal);
            CumulativeTemp =                    cumsum(FramesPerMap);
            CumulativeNumbers =                 [0; CumulativeTemp(1:end-1)];
            TemporaryImageMapPerFile =          ImageMapPerFileInternal;
            
             NumberOfImageMaps =     size(TemporaryImageMapPerFile,1);
            for CurrentMapIndex = 1:NumberOfImageMaps
                OldMapNumbers =                                         cell2mat(ImageMapPerFileInternal{CurrentMapIndex,1}(2:end,TimeColumn));
                TimeFrameAfterShift =                                   OldMapNumbers + CumulativeNumbers(CurrentMapIndex);
                TemporaryImageMapPerFile{CurrentMapIndex,1}(2:end,TimeColumn) =      num2cell(TimeFrameAfterShift);
               
            end
            ImageMapsWithoutTitles =        cellfun(@(x) x(2:end,:), TemporaryImageMapPerFile, 'UniformOutput', false);
            
            
            %% put result back into model:
            obj.ImageMap =                  [ImageMapPerFileInternal{1,1}(1,:); vertcat(ImageMapsWithoutTitles{:})];
            

        end
        
        
        function [rows, columns, planes] =              getImageDimensions(obj)
            
            planes =        obj.MetaData.EntireMovie.NumberOfPlanes;
            rows =          obj.MetaData.EntireMovie.NumberOfRows;
            columns =       obj.MetaData.EntireMovie.NumberOfColumns;
            
        end
        
        function [rows, columns, planes ] =              getImageDimensionsWithAppliedDriftCorrection(obj)
            
            if obj.DriftCorrectionOn
                

                planes =        obj.MetaData.EntireMovie.NumberOfPlanes + max(obj.DriftCorrection.PlaneShiftsAbsolute);
                rows =          obj.MetaData.EntireMovie.NumberOfRows + max(obj.DriftCorrection.RowShiftsAbsolute);
                columns =       obj.MetaData.EntireMovie.NumberOfColumns + max(obj.DriftCorrection.ColumnShiftsAbsolute);
                
            else
                planes =        obj.MetaData.EntireMovie.NumberOfPlanes;
                rows =          obj.MetaData.EntireMovie.NumberOfRows;
                columns =       obj.MetaData.EntireMovie.NumberOfColumns;
                
                
            end
            
            
        end

            
        function [CurrentImageVolume] =                     Create5DImageVolume(obj, Settings)
            
            
          
            
            ImageMapColumns =                           obj.ImageMap(1,:);
            

            ColumnForFrames =                           strcmp(ImageMapColumns,'TargetFrameNumber');
            ColumnForPlanes =                           strcmp(ImageMapColumns,'TargetPlaneNumber');

             SourceChannels =                           Settings.SourceChannels;
             TargetChannels =                           Settings.TargetChannels;
           
             SourceFrames =                             Settings.SourceFrames;
             TargetFrames =                             Settings.TargetFrames;
             
             SourcePlanes =                             Settings.SourcePlanes;
             TargetPlanes =                             Settings.TargetPlanes;
            
             
             %% first filter the image map: only images that meet the defined source numbers will be kept;
             [FilteredImageMap] =                       obj.FilterImageMap(SourceFrames,SourcePlanes,SourceChannels);
             
             
             %% then reset the numbers of the images in the file to rearrange if needed;
             % for example, you may want to change time frame from 10 to 1 if you want just a single image volume rather than a time-series;
             NumberOfChanges =                   length(SourceChannels);
             for ChangeIndex = 1:NumberOfChanges
                 originalNumber =                SourceChannels(ChangeIndex);
                 newNumber =                     TargetChannels(ChangeIndex);
                    
                 [FilteredImageMap] =                   ResetChannelsInImageMap(obj, FilteredImageMap, originalNumber, newNumber);
                 
             end
             
             
              NumberOfChanges =                   length(SourcePlanes);
             for ChangeIndex = 1:NumberOfChanges
                 originalNumber =                SourcePlanes(ChangeIndex);
                 newNumber =                     TargetPlanes(ChangeIndex);
                    
                 [FilteredImageMap] =                   ResetPlanesInImageMap(obj, FilteredImageMap, originalNumber, newNumber);
                 
             end
             
               NumberOfChanges =                   length(SourceFrames);
             for ChangeIndex = 1:NumberOfChanges
                 originalNumber =                SourceFrames(ChangeIndex);
                 newNumber =                     TargetFrames(ChangeIndex);
                    
                 [FilteredImageMap] =                   ResetFramesInImageMap(obj, FilteredImageMap, originalNumber, newNumber);
                 
             end
             
             %% after cleaning up the image map, simply read one "strip" after another, the correct target image will come automatically;
            [Structure]  =                              obj.VerifyImageMap(FilteredImageMap);
            Precision =                                 Structure.Precision;
            TotcalColumnsOfImage =                      Structure.TotcalColumnsOfImage ;
            TotalRowsOfImage =                          Structure.TotalRowsOfImage;
            
           
            TotalNumberOfChannels =                     max(cell2mat(FilteredImageMap(:,15)));
            TotalPlanes =                               max(cell2mat(FilteredImageMap(:,ColumnForPlanes)));
            TotalFrames =                               max(cell2mat(FilteredImageMap(:,ColumnForFrames)));
            
            
            CurrentImageVolume=                         cast(uint8(0),Precision);
            CurrentImageVolume(TotalRowsOfImage,TotcalColumnsOfImage,TotalPlanes,TotalFrames,TotalNumberOfChannels)=                          0;



            NumberOfImageDirectories =        size(FilteredImageMap,1);

            for StripIndex=1:NumberOfImageDirectories

                CurrentImageDirectory =             FilteredImageMap(StripIndex,:);

                
                %% place file pointer to beginning of strip
                 % 'source' info:
                fileID =                            CurrentImageDirectory{3};
                CurrentPlane =                      CurrentImageDirectory{ColumnForPlanes};
                CurrentFrame =                      CurrentImageDirectory{ColumnForFrames};    
                CurrentChannel =                    CurrentImageDirectory{15};
               
                BytesPerSample =                    CurrentImageDirectory{5}/8; % bits per sample divided by 8
               
                Precision=                          CurrentImageDirectory{6};
                byteOrder=                          CurrentImageDirectory{4};
                
                TotcalColumnsOfImage =              CurrentImageDirectory{8};
                RowsPerStrip =                      CurrentImageDirectory{12};
               
                
                ListWithStripOffsets =              CurrentImageDirectory{1};
                ListWithStripByteCounts=              CurrentImageDirectory{2};
                 ListWithUpperRows=                   CurrentImageDirectory{13};
                ListWithLowerRows=                   CurrentImageDirectory{14};
                
                NumberOfStrips =                    size(ListWithStripOffsets,1);          
                
                
                for CurrentStripIndex = 1:NumberOfStrips
                    
                    
                    CurrentStripOffset =            ListWithStripOffsets(CurrentStripIndex,1);
                    CurrentStripByteCount =         ListWithStripByteCounts(CurrentStripIndex,1);
                    
                    CurrentUpperRow =               ListWithUpperRows(CurrentStripIndex,1);
                    CurrentBottomRow =              ListWithLowerRows(CurrentStripIndex,1);
                 
                    fseek(fileID,  CurrentStripOffset, -1);

                    CurrentStripLength =                CurrentStripByteCount / BytesPerSample;
                    CurrentStripData =                  cast((fread(fileID, CurrentStripLength, Precision, byteOrder))', Precision);    


                    %% reshape the strip so that it fits:
                    % 'target' info
                    CurrentStripImage=                  (reshape(CurrentStripData, TotcalColumnsOfImage, RowsPerStrip ))';                
                    CurrentImageVolume(CurrentUpperRow:CurrentBottomRow,1:TotcalColumnsOfImage, CurrentPlane, CurrentFrame, CurrentChannel)=     CurrentStripImage;
                    

                end
            end
            
            
        end
        
    
        function [ImageMap] =                               FilterImageMap(obj,sourceFrameNumber,sourcePlaneNumber,sourceChannelNumber)
              
            % filter image map: keep only images that are defined as "source";
              % if the inputs are empty, ignore and leave all rows;
            
            ImageMap =                                  obj.ImageMap(2:end,:);

          
            
           if ~isempty(sourceFrameNumber)
                WantedColumn =                                              strcmp('TargetFrameNumber', obj.ImageMap(1,:));
                % filter for channels:
                NumberOfSources = length(sourceFrameNumber);
                clear WantedRows
                for CurrentIndex = 1:NumberOfSources
                    WantedRows(:,CurrentIndex) =          cell2mat(ImageMap(:,WantedColumn)) == sourceFrameNumber(CurrentIndex);
                end

                ChannelCondition =                              max(WantedRows, [], 2);

                ImageMap=                                       ImageMap(ChannelCondition,:);

            end
            
            if ~isempty(sourcePlaneNumber)
                 WantedColumn =                                              strcmp('TargetPlaneNumber', obj.ImageMap(1,:));
                % filter for channels:
                NumberOfSources = length(sourcePlaneNumber);
                clear WantedRows
                for CurrentIndex = 1:NumberOfSources
                    WantedRows(:,CurrentIndex) =          cell2mat(ImageMap(:,WantedColumn)) == sourcePlaneNumber(CurrentIndex);
                end

                ChannelCondition =                              max(WantedRows, [], 2);

                ImageMap=                                       ImageMap(ChannelCondition,:);

            end
            
              
            if ~isempty(sourceChannelNumber)
                 WantedColumn =                                              strcmp('TargetChannelIndex', obj.ImageMap(1,:));
                % filter for channels:
                NumberOfSources = length(sourceChannelNumber);
                clear WantedRows
                for CurrentIndex = 1:NumberOfSources
                    WantedRows(:,CurrentIndex) =          cell2mat(ImageMap(:,WantedColumn)) == sourceChannelNumber(CurrentIndex);
                end

                ChannelCondition =                              max(WantedRows, [], 2);

                ImageMap=                                       ImageMap(ChannelCondition,:);

            end

        end

        
        function [NonObjectImageMap] =                       ResetChannelsInImageMap(obj, NonObjectImageMap, oldValue, newValue)
            
            WantedColumn =                                              strcmp('TargetChannelIndex', obj.ImageMap(1,:));
            RowsThatNeedChange =                                        cell2mat(NonObjectImageMap(:,WantedColumn)) == oldValue;
            NonObjectImageMap(RowsThatNeedChange,WantedColumn) =        {newValue};
            
            
        end
        
        function [NonObjectImageMap] =                       ResetFramesInImageMap(obj, NonObjectImageMap, oldValue, newValue)
            
            WantedColumn =                                              strcmp('TargetFrameNumber', obj.ImageMap(1,:));
            RowsThatNeedChange =                                        cell2mat(NonObjectImageMap(:,WantedColumn)) == oldValue;
            NonObjectImageMap(RowsThatNeedChange,WantedColumn) =        {newValue};
            
            
        end
        
        function [NonObjectImageMap] =                       ResetPlanesInImageMap(obj, NonObjectImageMap, oldValue, newValue)
            
            WantedColumn =                                              strcmp('TargetPlaneNumber', obj.ImageMap(1,:));
            RowsThatNeedChange =                                        cell2mat(NonObjectImageMap(:,WantedColumn)) == oldValue;
            NonObjectImageMap(RowsThatNeedChange,WantedColumn) =        {newValue};
            
            
        end
        
        
        function [Structure]  =                             VerifyImageMap(obj,FilteredImageMap)
            
              PrecisionList =                     unique(FilteredImageMap(:,6));
            assert(length(PrecisionList)==1, 'Cannot read file. Reason: precision of different image elements is not identical')
            Structure.Precision =                         PrecisionList{1,1};


            TotcalColumnsOfImageList =         unique(cell2mat(FilteredImageMap(:,8)));
            assert(length(TotcalColumnsOfImageList)==1, 'Cannot read file. Reason: precision of different image elements is not identical')
            Structure.TotcalColumnsOfImage =             TotcalColumnsOfImageList(1,1);

            TotalRowsOfImageList =              unique(cell2mat(FilteredImageMap(:,9)));
            assert(length(TotalRowsOfImageList)==1, 'Cannot read file. Reason: precision of different image elements is not identical')
            Structure.TotalRowsOfImage =                  TotalRowsOfImageList(1,1);

             
            
            
        end
        
        
        function listWithPointers =                         getCurrentPointersInImageMap(obj)
            
            listWithPointers = cellfun(@(x) x{2,3}, obj.ImageMapPerFile);

        end
         
        
        function [obj] =                                    autoCorrectNavigation(obj)
            
            
            obj =           obj.autoCorrectChannels;
            
             timepoints = obj.MetaData.EntireMovie.NumberOfTimePoints;
            planes = obj.MetaData.EntireMovie.NumberOfPlanes;
            
            if isempty(obj.SelectedFrames) ||  max(obj.SelectedFrames) > timepoints || min(obj.SelectedFrames) < 1
                obj.SelectedFrames = 1;
                
            end
            
            if isempty(obj.SelectedPlanes) ||  max(obj.SelectedPlanes) > planes || min(obj.SelectedPlanes) < 1
                obj.SelectedPlanes = 1;
                
            end
          
            
        end
        
        function [obj] =                                    autoCorrectTrackingObject(obj)
            
            CurrentNumberOfColumns =    size(PMTrackingAnalysis().ListWithCompleteMaskInformation,2);

             NumberOfFrames =           obj.MetaData.EntireMovie.NumberOfTimePoints;
             EmptyContent =             cell(0,CurrentNumberOfColumns);
             
             if isempty(obj.TrackingAnalysis)
                 return
             end
             
             if isempty(obj.TrackingAnalysis.MetaData)
                 obj.TrackingAnalysis.MetaData = obj.MetaData;
                 
             end
             
            if isempty(obj.Tracking.TrackingCellForTime) || size(obj.Tracking.TrackingCellForTime,1) < NumberOfFrames
                
                obj.Tracking.TrackingCellForTime{NumberOfFrames,1} =      EmptyContent;
       
            end
            
            for CurrentTime = 1:NumberOfFrames
                
                if isempty(obj.Tracking.TrackingCellForTime{CurrentTime,1})
                    
                    obj.Tracking.TrackingCellForTime{CurrentTime,1} =   EmptyContent;
                elseif size(obj.Tracking.TrackingCellForTime{CurrentTime,1},2) == 6
                    obj.Tracking.TrackingCellForTime{CurrentTime,1}(:,7) =  {PMSegmentationCapture};
                    
                end
                
                
                
                
                
            end
            
        end
        
  
        function [RowForCurrentTrack]=                      FindLocationOfNewCellMask(obj)

                %% find the row in the structure (and the mask ID) of a mask from a specific track (at a given frame);

                TrackingResults =                           obj.Tracking.TrackingCellForTime;
                ID_OfTrack =                                obj.IdOfActiveTrack;
                State_CurrentFrame =                        obj.SelectedFrames(1);
                FieldNames =                                obj.Tracking.FieldNamesForTrackingCell;
                
                if ~isempty(TrackingResults) && size(TrackingResults,1) >= State_CurrentFrame
                    DataOfCurrentFrame =                        TrackingResults{State_CurrentFrame,1}; 
                else
                    DataOfCurrentFrame = [];
                end

                Column_TrackId=                             strcmp('TrackID', FieldNames);
                Column_AbsoluteFrame=                       find(strcmp('AbsoluteFrame', FieldNames));
                Column_CentroidY=                           find(strcmp('CentroidY', FieldNames));
                Column_CentroidX=                           find(strcmp('CentroidX', FieldNames));
                Column_CentroidZ=                           find(strcmp('CentroidZ', FieldNames));


                if isempty(DataOfCurrentFrame)
                    RowForCurrentTrack=     1;
                    
                else
                    
                    TracksOfCurrentTimePoint =              cell2mat(DataOfCurrentFrame(:,Column_TrackId));
                    RowForCurrentTrack=                     find(TracksOfCurrentTimePoint==ID_OfTrack);
                     
                    if isempty(RowForCurrentTrack) %if the current track does not have a cell mask in the current frame;
                        RowForCurrentTrack=                 size(DataOfCurrentFrame,1) + 1;
                     end
                
                end



        end

        
       

        function [obj] = updateMaskOfActiveTrack(obj, FinalListWith3DCoordinates, varargin)
                %TRACKINGRESULTS_ADDPIXELLIST Summary of this function goes here
                %   Detailed explanation goes here
                
                
                
                
                
 
                if isempty(FinalListWith3DCoordinates) || max(isnan(FinalListWith3DCoordinates(:,1)))
                    error('It is not allowed to add empty coordinate lists or list wih nan')
                end


                 %% obtain data:
                 MyTrackID =                                obj.IdOfActiveTrack;
                 [RowInCell]=                               obj.FindLocationOfNewCellMask;
                 MySelectedFrame =                          obj.SelectedFrames(1);

                 FieldNames =                                obj.Tracking.FieldNamesForTrackingCell;

                 %% process data:
                Column_TrackId=                             strcmp('TrackID', FieldNames);
                Column_AbsoluteFrame=                       strcmp('AbsoluteFrame', FieldNames);
                Column_CentroidY=                           strcmp('CentroidY', FieldNames);
                Column_CentroidX=                           strcmp('CentroidX', FieldNames);
                Column_CentroidZ=                           strcmp('CentroidZ', FieldNames);
                Column_PixelList =                          strcmp('ListWithPixels_3D', FieldNames);

                obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_TrackId} =               MyTrackID;
                obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_AbsoluteFrame} =         MySelectedFrame;
                obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidY} =             mean(FinalListWith3DCoordinates(:,1));
                obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidX} =             mean(FinalListWith3DCoordinates(:,2));
                obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidZ} =              mean(FinalListWith3DCoordinates(:,3));
                obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_PixelList} =              FinalListWith3DCoordinates;

                   
                NumberOfInputArguments =        length(varargin);
                
                if NumberOfInputArguments == 1
                    
                    
                    SegmentationInfo = varargin{1};
                    
                    SegmentationInfo = SegmentationInfo.RemoveImageData;
                    
                   
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,7} = SegmentationInfo;
                    
                    
                end

        end
                
        
        function [obj] =  updateMaskOfActiveTrackByRemoval(obj,yList,xList)
            
            if isempty(yList) || isempty(xList)
                
                return

            end
            
            
               %% obtain data:
                 MyTrackID =                                obj.IdOfActiveTrack;
                 [RowInCell]=                               obj.FindLocationOfNewCellMask;
                 MySelectedFrame =                          obj.SelectedFrames(1);

                 FieldNames =                                obj.Tracking.FieldNamesForTrackingCell;

                 %% process data:
                Column_TrackId=                             strcmp('TrackID', FieldNames);
                Column_AbsoluteFrame=                       strcmp('AbsoluteFrame', FieldNames);
                Column_CentroidY=                           strcmp('CentroidY', FieldNames);
                Column_CentroidX=                           strcmp('CentroidX', FieldNames);
                Column_CentroidZ=                           strcmp('CentroidZ', FieldNames);
                Column_PixelList =                          strcmp('ListWithPixels_3D', FieldNames);

                
                oldPixels =                             obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_PixelList};
                deleteRows =                            min(ismember(oldPixels(:,1:2), [yList xList]), [], 2);
                newPixels =                             oldPixels;
                newPixels(deleteRows,:) =               [];
                
                if isempty(newPixels)
                    
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}(RowInCell,:) = [];
                else
                    
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_TrackId} =               MyTrackID;
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_AbsoluteFrame} =         MySelectedFrame;
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidY} =             mean(newPixels(:,1));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidX} =             mean(newPixels(:,2));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidZ} =              mean(newPixels(:,3));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_PixelList} =              newPixels;

                     obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,7}.SegmentationType = 'Manual';
                    
                end
                
                
            
            
        end
        
        
        
         function [obj] =  updateMaskOfActiveTrackByAdding(obj,yList,xList, plane)
             
             
                if isempty(yList) || isempty(xList)
                
                return

            end
            
            
               %% obtain data:
                 MyTrackID =                                obj.IdOfActiveTrack;
                 [RowInCell]=                               obj.FindLocationOfNewCellMask;
                 MySelectedFrame =                          obj.SelectedFrames(1);

                 FieldNames =                                obj.Tracking.FieldNamesForTrackingCell;

                 %% process data:
                Column_TrackId=                             strcmp('TrackID', FieldNames);
                Column_AbsoluteFrame=                       strcmp('AbsoluteFrame', FieldNames);
                Column_CentroidY=                           strcmp('CentroidY', FieldNames);
                Column_CentroidX=                           strcmp('CentroidX', FieldNames);
                Column_CentroidZ=                           strcmp('CentroidZ', FieldNames);
                Column_PixelList =                          strcmp('ListWithPixels_3D', FieldNames);

                
                RowsThere =                             size(obj.Tracking.TrackingCellForTime{MySelectedFrame, 1},1);
                
                if RowsThere<RowInCell
                    oldPixels =      zeros(0,3);
                else
                    oldPixels =                             obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_PixelList};
                
                    
                end
                
                
                addPixels =                             [yList,xList];
                addPixels(:,3) =                        plane;
                
                
                newPixels =             unique([oldPixels;addPixels], 'rows');
                
                
               
                
                
                if isempty(newPixels)
                    
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}(RowInCell,:) = [];
                else
                    
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_TrackId} =               MyTrackID;
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_AbsoluteFrame} =         MySelectedFrame;
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidY} =             mean(newPixels(:,1));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidX} =             mean(newPixels(:,2));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_CentroidZ} =              mean(newPixels(:,3));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,Column_PixelList} =              newPixels;

                    obj.Tracking.TrackingCellForTime{MySelectedFrame, 1}{RowInCell,7}.SegmentationType = 'Manual';
                    
                    
                end
                
                
            
             
         end
        



        
       function Check = verifyChannels(obj, NumberOfChannels)
            
               %% if the dimension of the channels are incorrect replace them with the default;
               % if these numbers don't match this would lead to serious problems during execution of the program;
               
                SelectionNumber =       length(obj.SelectedChannels);
                LowInNumber  =          length(obj.ChannelTransformsLowIn);
                HighInNumber =          length(obj.ChannelTransformsHighIn);
                ColorNumber =           length(obj.ChannelColors);
                CommentNumber =         length(obj.ChannelComments);

                Count = length(unique([NumberOfChannels; SelectionNumber; LowInNumber; HighInNumber; ColorNumber; CommentNumber]));

                if Count == 1
                    Check = true;
                else
                    Check = false;
                end

       end
      
           
    
     
     
        
         
    end
end