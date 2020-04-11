classdef PMMovieTracking
    %PMMOVIETRACKING manage viewing and tracking of movie
    %   This class manages viewing and tracking.
    
    properties
        
        % information related to source files:
        NickName
        
        Keywords =                  cell(0,1)
        Folder                      % movie folder:
        FolderAnnotation =          '' % folder that contains files with annotation information added by user;
        AttachedFiles =             cell(0,1) % list files that contain movie-information;
        
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
        
        
        
        
        EditingActivity =       'No editing'
        AllPossibleEditingActivities =  {'No editing','Manual drift correction','Tracking'};
        
        
        %%  information that is read from linked files; 
        ImageMapPerFile
        ImageMap
        
        MetaData
        MetaDataOfSeparateMovies
        
       
        
        
        %% dimensions of drift correction and tracking are dependent on the movie files:
        % content is set by the user;
        DriftCorrection
        
        AplliedRowShifts                                % drift correction: depending on frame and whether drifct correction is on, settings for how much centroids, gates, etc. have to be moved is stored here;                
        AplliedColumnShifts
        AplliedPlaneShifts
        MaximumRowShift =                               0
        MaximumColumnShift =                            0
        MaximumPlaneShift =                             0
        
        
        CroppingGate =              [1 1 1 1]
        AppliedCroppingGate
        CroppingOn =                0
        
        
        % tracking model content used for displaying data
        % there are now several different formats of the tracking data: maybe add a method to remove duplicate analysis to not boost storage space unnecessarily;
        Tracking % for storing basic migration data on file (new tracking data are moved directly here);
        TrackingAnalysis % is built from basic migration data and enables sophisticated analysis on tracks;
        
        
        %
        AutomatedCellRecognition
        
        
       %% saving status
       UnsavedTrackingDataExist =                                   true
        
        

    end
    
    methods
        
        function obj =                                                  PMMovieTracking(MovieStructure, FolderInformation, Version)
            
            %PMMOVIETRACKING add basic properties
            %   only basal information goes here
            % additional features, such as specific file information and mapping can be added optionally with specific methods;
         
            switch Version
                
                case 0 % this is a simple way to create a very basic object;
                    
                    myFilesOrFolders =                                                      MovieStructure.AttachedFiles;
                    EmptyRows =                                                             cellfun(@(x) isempty(x), myFilesOrFolders);
                    myFilesOrFolders(EmptyRows) =                                           [];
                    
                    obj.NickName =                                                      MovieStructure.NickName;
                    obj.Folder =                                                        FolderInformation;
                     obj.AttachedFiles =                                         myFilesOrFolders;
                    
                    obj = obj.updateFilePaths;
                    
                    % if the user input was a folder, this means a folder with subfiles was selected and the subfiles have to be extracted;
                    % currently only the .pic format is organized in this way;
                    FolderWasSelected =     cellfun(@(x) isfolder(x), obj.ListWithPaths);
                    FolderWasSelected =     unique(FolderWasSelected);
                    if length(FolderWasSelected) ~=1
                        error('Cannot select a mix of files and folder') 
                    end
           
                     if FolderWasSelected
                         ListWithExtractedFiles =       obj.extractFileNameListFromFolder(myFilesOrFolders);
                         obj.AttachedFiles =        ListWithExtractedFiles;
                     else
                         
                         
                     end
                    
                    
                    
                    
                   
                    
                    obj.DriftCorrection =                                       PMDriftCorrection(MovieStructure, Version);
                    obj.Tracking =                                              PMTrackingNavigation(MovieStructure,Version);

                case 1 % for loading from file
                    
                    
                    if isstruct(MovieStructure)
                        obj.NickName =                                              MovieStructure.NickName;
                        
                    else
                        obj.NickName =                                          MovieStructure;
                        
                    end

                    obj.Folder =                                                FolderInformation{1};
                    obj.FolderAnnotation =                                      FolderInformation{2};
                    obj =                                                       obj.loadObjectFromFile;
                    obj.FolderAnnotation =                                      FolderInformation{2}; % duplicate because in some files this information may not be tehre
               
                case 2
                    
                    obj.NickName =                                              MovieStructure.NickName;
                    obj.Keywords{1,1}=                                          MovieStructure.Keyword;
                    
                    obj.Folder =                                                FolderInformation;
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
        
        
        %% getters:
        
        function [segmentationOfCurrentFrame ] =            getUnfilteredSegmentationOfCurrentFrame(obj)
            
              CurrentFrame =                                      obj.SelectedFrames(1);

                DataDoNotExist =     isempty(obj.Tracking.TrackingCellForTime) || size(obj.Tracking.TrackingCellForTime,1) < CurrentFrame || isempty(obj.Tracking.TrackingCellForTime{CurrentFrame});
                
                if DataDoNotExist
                     segmentationOfCurrentFrame =                    cell(0,length(obj.Tracking.FieldNamesForTrackingCell));
                else
                     segmentationOfCurrentFrame =                    obj.Tracking.TrackingCellForTime{CurrentFrame,1};
                     
                end
            
        end
        
        function [segmentationOfTrack] =                    getUnfilteredSegmentationOfTrack(obj,TrackID)
            
            
            if length(TrackID)~=1 || isnan(TrackID)
                 segmentationOfTrack =                    cell(0,length(obj.Tracking.FieldNamesForTrackingCell));
            else
            
                AllTracking =                   vertcat(obj.Tracking.TrackingCellForTime{:});
                segmentationOfTrack =           AllTracking(cell2mat(AllTracking(:,1))==    TrackID,:);
            end
            
        end
        
           function [segmentationOfCurrentFrame ] =         getSegmentationOfCurrentFrame(obj)
                    
               
               
               function [list] =                                   filterPixelListForPlane(list,SelectedPlane)
                        if isempty(list)
                           list =   zeros(0,3);
                        else
                            list(list(:,3)~=SelectedPlane,:) = [];  
                        end
                        end
               
                CurrentFrame =                                      obj.SelectedFrames(1);

                DataDoNotExist =     isempty(obj.Tracking.TrackingCellForTime) || size(obj.Tracking.TrackingCellForTime,1) < CurrentFrame || isempty(obj.Tracking.TrackingCellForTime{CurrentFrame});
                
                if DataDoNotExist
                     segmentationOfCurrentFrame =                    cell(0,length(obj.Tracking.FieldNamesForTrackingCell));
                else
                     segmentationOfCurrentFrame =                    obj.Tracking.TrackingCellForTime{CurrentFrame,1};
                     
                       

                    if ~obj.CollapseAllTracking % filter further (unless maximum projection is wanted);

                        SelectedPlane =                                                         obj.SelectedPlanes(1);
                        [~, ~, SelectedPlaneWithoutDriftCorrection] =                           obj.removeDriftCorrection(0,0,SelectedPlane);


                        if ~isempty(segmentationOfCurrentFrame)
                            % remove mask pixels that are not within the selected frame;
                            FilteredPixelLists =                                                    cellfun(@(x) filterPixelListForPlane(x,SelectedPlaneWithoutDriftCorrection), segmentationOfCurrentFrame(:,obj.Tracking.getPixelListColumn), 'UniformOutput', false);
                            segmentationOfCurrentFrame(:,obj.Tracking.getPixelListColumn) =                 FilteredPixelLists;

                            % completely remove cells where all the pixels are out the specified frames;
                            EmptyRows =                                                             cellfun(@(x) isempty(x), segmentationOfCurrentFrame(:,obj.Tracking.getPixelListColumn));
                            %segmentationOfCurrentFrame(EmptyRows,:) =                               [];


                        end


                    end
                
                
              end
                
                
                
              

  
           end
            
           
           
           
        function TrackDataOfCurrentFrame =                  getTrackDataOfCurrentFrame(obj)
                
                State_CurrentFrame =                        obj.SelectedFrames(1);
                TrackDataOfCurrentFrame =                   obj.getTrackDataOfFrame(State_CurrentFrame);
                
  
        end
        
        function TrackDataOfSpecifiedFrame =              getTrackDataOfFrame(obj, FrameNumber)
            
                TrackingResults =                           obj.Tracking.TrackingCellForTime;
                if ~isempty(TrackingResults) && size(TrackingResults,1) >= FrameNumber
                    TrackDataOfSpecifiedFrame =                        TrackingResults{FrameNumber,1}; 
                else
                    TrackDataOfSpecifiedFrame = cell(0,obj.Tracking.getNumberOfTrackColumns);
                end
                
                
            
        end
        
       
           
              function DataOfActiveTrackPreviousFrame =                           getPreviousMaskData(obj)


                    PreviousFrame =                                                 obj.SelectedFrames(1)-1;

                    if PreviousFrame<= 0 || size( obj.Tracking.TrackingCellForTime,1)<PreviousFrame 
                        DataOfActiveTrackPreviousFrame = cell(0,length(obj.Tracking.FieldNamesForTrackingCell));
                    else

                         if isempty(obj.Tracking.TrackingCellForTime)
                             obj.Tracking.TrackingCellForTime(1:obj.MetaData.EntireMovie.NumberOfTimePoints,:) = {cell(0,length(obj.Tracking.FieldNamesForTrackingCell))};


                         elseif isempty(obj.Tracking.TrackingCellForTime{PreviousFrame})
                             obj.Tracking.TrackingCellForTime{PreviousFrame,1}= cell(0,length(obj.Tracking.FieldNamesForTrackingCell));

                         end

                        segementationOfPreviousFrame =                    obj.Tracking.TrackingCellForTime{PreviousFrame,1};
                        
                        myIDOfActiveTrack =                             obj.IdOfActiveTrack;
                        allTrackIDsInPreviousFrame =                    cell2mat(segementationOfPreviousFrame(:,obj.Tracking.getTrackIDColumn));
                        rowWithActiveTrackInPreviousFrame =             allTrackIDsInPreviousFrame == myIDOfActiveTrack ;   

                        DataOfActiveTrackPreviousFrame =                segementationOfPreviousFrame(rowWithActiveTrackInPreviousFrame,:);

                    end


              end

           
              function segmentationOfActiveTrack =          getUnfilteredSegmentationOfActiveTrack(obj)
                  segmentationOfCurrentFrame =                         obj.getUnfilteredSegmentationOfCurrentFrame;
                
                rowOfActiveTrack =                              obj.getRowOfActiveTrackIn(segmentationOfCurrentFrame);
                 if sum(rowOfActiveTrack) ==                    0
                      segmentationOfActiveTrack =   cell(0,length(obj.Tracking));
                 else
                     segmentationOfActiveTrack =     segmentationOfCurrentFrame(rowOfActiveTrack,:);
                 end
                  
                  
              end
              
            
              function segmentationOfActiveTrack =                                getSegmentationOfActiveTrack(obj)

                segmentationOfCurrentFrame =                         obj.getSegmentationOfCurrentFrame;
                
                rowOfActiveTrack =                              obj.getRowOfActiveTrackIn(segmentationOfCurrentFrame);
                 if sum(rowOfActiveTrack) ==                    0
                      segmentationOfActiveTrack =   cell(0,length(obj.Tracking));
                 else
                     segmentationOfActiveTrack =     segmentationOfCurrentFrame(rowOfActiveTrack,:);
                 end

              end 
            
              
               function rowOfActiveTrack =                                         getRowOfActiveTrackIn(obj,segmentationOfCurrentFrame)

                 myIDOfActiveTrack =                             obj.IdOfActiveTrack;
                % simply reset the plane to the current plane of active
                % track; down below this plane will be used to create the image;
                rowOfActiveTrack =                              cell2mat(segmentationOfCurrentFrame(:,obj.Tracking.getTrackIDColumn)) == myIDOfActiveTrack ;


               end
               
               function row =       getActiveRowInTrackInfoList(obj)
                   
                   myIDOfActiveTrack =                             obj.IdOfActiveTrack;
                   
                  
                   
                   
                   if isnan(myIDOfActiveTrack) 
                       row = NaN;
                   elseif isempty(obj.Tracking.TrackInfoList)
                       row = 1;
                       
                   else
                        ExistingTrackIds =              cellfun(@(x) x.TrackID, obj.Tracking.TrackInfoList);
                        
                        MatchingRows =                  find(ExistingTrackIds == myIDOfActiveTrack);
                        
                        if isempty(MatchingRows) 
                            row = size(obj.Tracking.TrackInfoList,1)+1;
                            
                        elseif length(MatchingRows) == 1
                            row = MatchingRows;
                        else
                            error('Track-info list is corrupted. More than one row for same track.')
                        end
                        
                   end
                       
                   
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
            
               
            function [regularPlanes] =                                          convertInputPlanesIntoRegularPlanes(obj, inputPlanes)

                % get planes without drift correction
                
                  if obj.DriftCorrectionOn

                        CurrentFrame =                                      obj.SelectedFrames(1);
                        PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;
                        regularPlanes =                                     inputPlanes - PlaneShiftsAbsolute(CurrentFrame);

                        regularPlanes(regularPlanes<1) =                  [];
                        regularPlanes(regularPlanes>obj.MetaData.EntireMovie.NumberOfPlanes) = [];


                  else
                      regularPlanes =                                       inputPlanes;

                  end


            end

                    
            function newTrackID =                                               findNewTrackID(obj)

                 MySelectedFrame =                      obj.SelectedFrames(1);

                if ~isempty(obj.Tracking.TrackingCellForTime) % not sure what this is good for, some cleanupt? ;
                    InvalidRows =            isnan(cell2mat(obj.Tracking.TrackingCellForTime{MySelectedFrame,1}(:,obj.Tracking.getTrackIDColumn)));
                    obj.Tracking.TrackingCellForTime{MySelectedFrame,1}(InvalidRows,:) = [];

                end
                
                newTrackID =            obj.Tracking.generateNewTrackID;

                if isempty(newTrackID) || isnan(newTrackID)
                    newTrackID = 1;
                end

            end
            
            
            function [currentFrame] =                                           getCurrentFrame(obj)

                currentFrame = obj.SelectedFrames(1);


            end
            
            function [frameNumbers] =           getTotalNumberOfFrames(obj)
                
                frameNumbers =      obj.MetaData.EntireMovie.NumberOfTimePoints;
                
            end

               
       function [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =        getCurrentDriftCorrectionValues(obj)

                CurrentFrame =                                      obj.SelectedFrames(1);    
                CurrentColumnShift=                                 obj.AplliedColumnShifts(CurrentFrame);
                CurrentRowShift=                                    obj.AplliedRowShifts(CurrentFrame);
                CurrentPlaneShift =                                 obj.AplliedPlaneShifts(CurrentFrame);

       end
        
            
          function [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
                    
                CurrentFrame =                                      obj.SelectedFrames(1);
                [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame);

                
          end
          
          function [xCoordinates, yCoordinates, zCoordinates ] =              addDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame)

              
                 

                RowShiftsAbsolute =                                 obj.AplliedRowShifts;
                ColumnShiftsAbsolute =                              obj.AplliedColumnShifts;
                PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;

                xCoordinates=                                       xCoordinates+ColumnShiftsAbsolute(CurrentFrame);
                yCoordinates=                                       yCoordinates+RowShiftsAbsolute(CurrentFrame);
                zCoordinates=                                       zCoordinates+PlaneShiftsAbsolute(CurrentFrame);

              
          end
            
           function [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)

                CurrentFrame =                                      obj.SelectedFrames(1);

                [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame);

              
           end
        
           
            function [xCoordinates, yCoordinates, zCoordinates ] =              removeDriftCorrectionBasic(obj, xCoordinates, yCoordinates, zCoordinates,CurrentFrame)

                RowShiftsAbsolute =                                 obj.AplliedRowShifts;
                ColumnShiftsAbsolute =                              obj.AplliedColumnShifts;
                PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;

                xCoordinates=                                       xCoordinates-ColumnShiftsAbsolute(CurrentFrame);
                yCoordinates=                                       yCoordinates-RowShiftsAbsolute(CurrentFrame);
                zCoordinates=                                       zCoordinates-PlaneShiftsAbsolute(CurrentFrame);

            
        end
        
          
       
          function [StartFrames,EndFrames] =                  getFramesForTracking(obj, Parameter)

                TrackingStartFrame =                                obj.SelectedFrames(1);
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
        
        function pixelList =                                getPixelsFromActiveMask(obj)
            
            RowInCell=                                          obj.FindLocationOfNewCellMask;
            activeFrame =                                       obj.getSelectedFrame;
            pixelList =                                         obj.Tracking.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.Tracking.getPixelListColumn};

        end
        
        
        function pixelList_Modified =                            getPixelsFromActiveMaskAfterRemovalOf(obj, pixelListToRemove)
            
            
             
                
              
             pixelList_Original =                                getPixelsFromActiveMask(obj);
              pixelList_Modified =        pixelList_Original;
              
              
             yList =                                                pixelListToRemove(:,1);
             xList =                                                pixelListToRemove(:,2);
                
              if ~(isempty(yList) || isempty(xList))
                   
                deleteRows =                                    ismember(pixelList_Original(:,1:2), [yList xList], 'rows');
                pixelList_Modified =                             pixelList_Original;
                pixelList_Modified(deleteRows,:) =               [];

              end
             
                
                
            
        end
        
        
        function pixelList_AfterAdding =                        getPixelsOfActiveTrackAfterAddingOf(obj, pixelListToAdd)
            
              %% obtain data:
                oldPixels =                                 getPixelsFromActiveMask(obj);
              
                pixelList_AfterAdding =                     unique([oldPixels;pixelListToAdd], 'rows');
                
            
        end
        
        
        
        
        function activeFrame =                              getSelectedFrame(obj)
             activeFrame =                          obj.SelectedFrames(1);

        end
        
        function numberOfFrames =                           getUniqueFrameNumberFromImageMap(obj, ImageMap)
            
            ColumnWithTime = 10;
            numberOfFrames =             length(unique(cell2mat(ImageMap(2:end,ColumnWithTime))));
            
            
            
        end
        
      
        
        function trackIDsWithNoFollowUp =                                 getTrackIDsWhereNextFrameHasNoMask(obj)
            
            
            
            CurrentFrame =                                              obj.SelectedFrames(1);
            
            MaxFrame = obj.MetaData.EntireMovie.NumberOfTimePoints;
            if CurrentFrame >= MaxFrame 
                trackIDsWithNoFollowUp =                                  zeros(0,1);
                
            else
                
                TrackIDsOfCurrentFrame =                                obj.getTrackIDsOfCurrentFrame;
                TrackIDsOfNextFrame =                                   obj.getTrackIDsOfFrame(CurrentFrame+1);
                trackIDsWithNoFollowUp =                                setdiff(TrackIDsOfCurrentFrame,TrackIDsOfNextFrame);
                
                
                
               
               
            end
             
            
             
            
        end
       
        
        function fileName =                                 getFileNameOfAnnotation(obj)
            
            fileName = [obj.FolderAnnotation '/' obj.NickName '.mat'];
            
            
        end
        
        
        
       
        
        function listWithPointers =                         getCurrentPointersInImageMap(obj)
            
            listWithPointers = cellfun(@(x) x{2,3}, obj.ImageMapPerFile);

        end
        
        
        
        
        function trackIDs =                                 getTrackIDsOfCurrentFrame(obj)
            
            TrackDataOfCurrentFrame =                       obj.getTrackDataOfCurrentFrame;
            
            trackIDs =                                 obj.parseTrackIDsFromMaskList(TrackDataOfCurrentFrame);
            
            
            
     
        end
        
        function trackIDs =                                 getTrackIDsOfFrame(obj, FrameNumber)
            
            TrackDataOfSpecifiedFrame =                     obj.getTrackDataOfFrame(FrameNumber);
             trackIDs =                                 obj.parseTrackIDsFromMaskList(TrackDataOfSpecifiedFrame);
            
        end
        
        function trackIDs =                                 parseTrackIDsFromMaskList(obj,MaskList)
            if isempty(MaskList)
                trackIDs =                                  zeros(0,1);
            else
                trackIDs =                                  cell2mat(MaskList(:,obj.Tracking.getTrackIDColumn));
            end
            
            
        end
        
        
        function [firstUntrackedFrame, lastUntrackedFrame] =                getFirstLastContiguousUntrackedFrame(obj)
        
                TrackingStartFrame =                    obj.SelectedFrames(1);
                TrackID =                               obj.IdOfActiveTrack;
                allFramesOfCurrentTrack  =              obj.Tracking.getAllFrameNumbersOfTrackID(TrackID);

                % get last untracked frame:
                AfterLastUntrackedTrackedFrame =        find(allFramesOfCurrentTrack>TrackingStartFrame,  1, 'first');
                if isempty(AfterLastUntrackedTrackedFrame)
                    lastUntrackedFrame =                  obj.MetaData.EntireMovie.NumberOfTimePoints;
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
        
                        
        function lastOrFirstTrackedFrame =                         getLastTrackedFrame(obj, parameter)
                % from a contiguous stretch of tracked frames: get first or last frame in this contiguous sequence;
            
                ActiveTrackID =                                 obj.IdOfActiveTrack;
                listWithTrackedFrames =                         obj.Tracking.getAllFrameNumbersOfTrackID(ActiveTrackID);
                State_CurrentFrame =                            obj.SelectedFrames(1);

                if ~ismember(State_CurrentFrame,listWithTrackedFrames) % perform this analysis only when the current position is tracked;
                      lastOrFirstTrackedFrame = NaN;
                      return
                end

                   
                switch parameter
                   
                    case 'up' 

                            listWithTrackedFrames(listWithTrackedFrames<State_CurrentFrame,:) = [];
                            nonConescutiveIndex = find(diff(listWithTrackedFrames)>1, 1, 'first')+1;

                           if ~isempty(nonConescutiveIndex)
                               listWithTrackedFrames(nonConescutiveIndex:end,:) = []; % remove all frames after tracking "gaps";
                           end

                           lastOrFirstTrackedFrame = max(listWithTrackedFrames);

                    case 'down'
                        
                            listWithTrackedFrames(listWithTrackedFrames>State_CurrentFrame,:) = [];
                            nonConescutiveIndex = find(diff(listWithTrackedFrames)>1, 1, 'last')+1;

                           if ~isempty(nonConescutiveIndex)
                               listWithTrackedFrames(nonConescutiveIndex:end,:) = [];

                           end
                           lastOrFirstTrackedFrame = min(listWithTrackedFrames);

                    end
               
        end
        
        function [RowForCurrentTrack]=                      FindLocationOfNewCellMask(obj)

                %% find the row in the structure (and the mask ID) of a mask from a specific track (at a given frame);

                
                TrackIdsOfCurrentTimePoint =                                 obj.getTrackIDsOfCurrentFrame;
                ID_OfTrack =                                                obj.IdOfActiveTrack;
                
                if isempty(TrackIdsOfCurrentTimePoint)
                    RowForCurrentTrack=     1;
                    
                else
                    
                    RowForCurrentTrack=                     find(TrackIdsOfCurrentTimePoint==ID_OfTrack);
                    if isempty(RowForCurrentTrack) %if the current track does not have a cell mask in the current frame;
                        RowForCurrentTrack=                 size(TrackIdsOfCurrentTimePoint,1) + 1;
                    end
                
                end



        end


       function Check =                                     verifyChannels(obj, NumberOfChannels)
            
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
      
       function DataType =                                  getDataType(obj)
           
           
           if isempty(obj.MetaData)
                 NumberOfTimePoints =                                 NaN;
               NumberOfPlanes =                                     NaN;
           else
               NumberOfTimePoints =                                obj.MetaData.EntireMovie.NumberOfTimePoints;
                NumberOfPlanes =                                    obj.MetaData.EntireMovie.NumberOfPlanes;
               
           end
           
           
             
           
           if NumberOfTimePoints>1
               DataType =               'Movie';
               
           elseif NumberOfPlanes>1
               DataType =               'ZStack';
           elseif NumberOfPlanes == 1
                DataType =               'Snapshot';
           else
               DataType =               'Unspecified datatype';
           end
           
         
           
       end
           

       function FileType =                                  getFileType(obj)
           
            [~,~,Extensions] =                                      cellfun(@(x) fileparts(x), obj.AttachedFiles, 'UniformOutput', false);
                    
                    Extension =                                             unique(Extensions);
                    assert(length(Extension)==1, 'Can only work when all files have same format.')
                    Extension =                                             Extension{1,1}; 
                    
                    
                     switch Extension
                        
                        case '.tif'
                              FileType =        'tif';
                  
                         case '.lsm'
                             FileType =        'lsm';
                        case '.czi'
                            FileType =        'czi';
                        case '.pic'
                            FileType =        'unknown';
                            
                            
                        otherwise % need to add pic
                           

                    end
           
           
       end
       

        function [rows, columns, planes] =                  getImageDimensions(obj)
            
            planes =        obj.MetaData.EntireMovie.NumberOfPlanes;
            rows =          obj.MetaData.EntireMovie.NumberOfRows;
            columns =       obj.MetaData.EntireMovie.NumberOfColumns;
            
        end
        
        
        
        function metaDataSummary =                  getMetaDataSummary(obj)
            
            
            fileType =                                           obj.getFileType;
            
             switch fileType
                
                case 'lsm' 
                       myImageDocuments =                                  cellfun(@(x)  PMTIFFDocument(x), obj.ListWithPaths, 'UniformOutput', false);
                    
                    FirstMovie =                                        myImageDocuments{1,1};
                    MetaDataString =                                    FirstMovie.getRawMetaData;
                             
                    [lsminf,scaninf,imfinf] =           cellfun(@(x) lsminfo(x), obj.ListWithPaths, 'UniformOutput',false);
                    
                    
                    metaDataSummary{1,1} =              ['Objective: ', lsminf{1, 1}.ScanInfo.ENTRY_OBJECTIVE];
                    
                    
                    metaDataSummary{2,1}  =              sprintf('Used laser sources (not track-specific):');
                    
                    numberOfLasers =                length( lsminf{1, 1}.ScanInfo.WAVELENGTH);
                    
                    LaserString =  '';
                    
                    for laserIndex = 1:numberOfLasers
                        
                        NumberText = sprintf('%i, ', round(lsminf{1, 1}.ScanInfo.WAVELENGTH{laserIndex}));
                        
                        
                         LaserString =  [LaserString , NumberText];
                    end
                    
                    LaserString(end-1:end) = [];
                    
                    metaDataSummary  =   [metaDataSummary; LaserString];
                    
                    
                    metaDataSummary = [metaDataSummary; 'Emission filters for each channel:'];
                    
                    
                    metaDataSummary = [ metaDataSummary  ;(lsminf{1, 1}.ScanInfo.FILTER_NAME)'];
                    
                    
                    
                    
                 
                    
                   
                    
                 otherwise
                     
                     
                   
                     metaDataSummary = 'Meta data summary currently not supported for this format.';
                     
                    
             end
            
            
            
            
            
           
            
            
        end
        
        
        
        
        
        function [rows, columns, planes ] =                 getImageDimensionsWithAppliedDriftCorrection(obj)
            
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

     
           function check =                                                    checkWhetherButtonPressIsDistantFromPreviousMask(obj,yCoordinateWithOutDrift, xCoordinateWithoutDrift,  planeWithoutDrift);


             TrackinAnalysis =                                  obj.TrackingAnalysis;
              MaximumDistance =                                  PMTrackingNavigation(0,0).MaximumDistanceForTracking;
             TwoPositionTrack =                                 obj.getPreviousMaskData;


             if isempty(TrackinAnalysis)
                 check = false;
             elseif isempty(TwoPositionTrack)
                 check = false;

             else

                TwoPositionTrack{2,obj.Tracking.getCentroidYColumn} =      yCoordinateWithOutDrift;
                TwoPositionTrack{2,obj.Tracking.getCentroidXColumn} =      xCoordinateWithoutDrift;
                TwoPositionTrack{2,obj.Tracking.getCentroidZColumn} =      planeWithoutDrift;

                displacement =             TrackinAnalysis.getDisplacementOfTrack(TwoPositionTrack);
                if isempty(displacement)
                    check =                 false;

                elseif displacement>MaximumDistance
                    check =                 true;

                else
                    check =                 false;

                end


             end



            end

        
        
        %% setters:
        
        
        function obj =      setDriftCorrectionTo(obj,OnOff)
            
            obj.DriftCorrectionOn =     OnOff;
            
        end
        
        
        function obj =  setDriftDependentParameters(obj)
            
            obj =                       obj.resetViewPlanes;
            obj =                       obj.resetAppliedDriftShifts; % reset drift correction 
            obj =                       obj.updateAppliedCroppingLimits;
            obj =                       obj.updatePlaneStampStrings;
            % change cropping limit by drift correction (dependent on drift correction)
         
            %obj  =                      obj.refreshTrackingResults;

        end
        
        
        function obj = setCroppingStateTo(obj,OnOff)
            
            obj.CroppingOn =                                    OnOff;
            obj =                                               obj.updateAppliedCroppingLimits;

            
        end
        
        function obj =      setCollapseAllTrackingTo(obj, Value)
            
            obj. CollapseAllTracking = Value;
        end
         
        function obj =      setFrameTo(obj, FrameNumber)
            
            obj.SelectedFrames =                    FrameNumber;
            
        end
        
        function obj =      setFrameAndAdjustPlaneAndCropByTrack(obj, FrameNumber)
            
                obj =                                   obj.setFrameTo(FrameNumber);
            
               planeOfActiveTrack =                 obj.getPlaneOfActiveTrack;
               
               if ~isnan(planeOfActiveTrack)
               
                obj =                               obj.setSelectedPlaneTo(planeOfActiveTrack); % direct change of model:
                
                obj =                               obj.moveCroppingGateToActiveMask;
                obj =                               obj.updateAppliedCroppingLimits;
                
               end
                
            
        end
        
        
         function obj =  resetEditingActivityTo(obj, EditingMenuString)
            
                switch EditingMenuString
                
                    case 'Viewing only' % 'Visualize'
                        obj.EditingActivity =                                   'No editing';
                        obj.TrackingOn =                            0;
                        

                    case 'Edit manual drift correction'
                        obj.EditingActivity =                                   'Manual drift correction';
                        obj.TrackingOn =                            0;

                    case 'Edit tracks' %  'Tracking: draw mask'
                        obj.EditingActivity =                                'Tracking';
                        obj.TrackingOn =   1;

                end
    
                        

        end
         
        
          function [obj] =            changeMovieKeyword(obj)
            
            
            if strcmp(class(obj), 'PMMovieTracking')
              KeywordString=                        char(inputdlg('Enter new keyword'));
              obj.Keywords{1,1} =       KeywordString;
            end
                 
        end
        
        
        function [obj] =            changeMovieNickname(obj, String)
            
             
             if strcmp(class(obj), 'PMMovieTracking')
              
              obj.NickName =       String;
             end
            
             
             
                 
         end
        
         
        function [obj] =            changeMovieLinkedMovieFiles(obj,ListWithFileNamesToAdd)
            
              
              obj.AttachedFiles =       ListWithFileNamesToAdd;
              
              % check whether a folder: if a folder: need to add all the valid files within this folder (not just the folder);;
                 
          end
        
        
        
         function obj =          resetAppliedDriftShifts(obj)
                
               % this essentially resets the applied drift correction (essentially choosen whether or not to use drift correction;
            
                DriftCorrectionIsOn =               obj.DriftCorrectionOn;
                metaData =                          obj.MetaData;

                switch DriftCorrectionIsOn

                     case true



                        obj.AplliedRowShifts =          obj.DriftCorrection.RowShiftsAbsolute;
                        obj.AplliedColumnShifts =       obj.DriftCorrection.ColumnShiftsAbsolute;
                        obj.AplliedPlaneShifts =        obj.DriftCorrection.PlaneShiftsAbsolute;


                    case false

                        structure =                     obj.DriftCorrection.calculateEmptyShifts(metaData);

                        obj.AplliedRowShifts =          structure.RowShiftsAbsolute;
                        obj.AplliedColumnShifts =       structure.ColumnShiftsAbsolute;
                        obj.AplliedPlaneShifts =        structure.PlaneShiftsAbsolute;

                end


                %% update model:
                obj.MaximumRowShift =                       max(obj.AplliedRowShifts);
                obj.MaximumColumnShift =                    max(obj.AplliedColumnShifts);
                obj.MaximumPlaneShift =                     max(obj.AplliedPlaneShifts);

               


           
            
            
        end
        
        
        
        function [obj] =            setSelectedPlaneTo(obj, planeOfActiveTrack)

          
            
            if ~isnan(planeOfActiveTrack)

                obj.SelectedPlanes =                        planeOfActiveTrack;
                obj =                                       obj.resetViewPlanes;
                

            end
            
            
        end
        
        
        function obj =              setActiveTrackWith(obj, NewTrackID)
            

            obj.IdOfActiveTrack =                           NewTrackID;
        
        end
        
        
          function obj =      moveCroppingGateToActiveMask(obj)
                
                segmentationOfActiveTrack =                obj.getSegmentationOfActiveTrack;
                
                if isempty(segmentationOfActiveTrack)
                    [centerY, centerX] =            deal(nan);
                else
                    centerY =       segmentationOfActiveTrack{1,obj.Tracking.getCentroidYColumn};
                    centerX =       segmentationOfActiveTrack{1,obj.Tracking.getCentroidXColumn};
                end
                
                
                obj =           obj.moveCroppingGateToNewCenter(centerX, centerY);

                
            end
        
          
         
        
         function obj =           moveCroppingGateToNewCenter(obj, centerX, centerY)
             
               if ~isnan(centerX)
                    Width =                                 obj.CroppingGate(3);
                    Height =                                obj.CroppingGate(4);

                    NewCenterX =                            centerX;
                    NewCenterY =                            centerY;

                    NewStartColumn =                        NewCenterX - Width / 2;
                    NewStartRow =                            NewCenterY - Height / 2;


                    obj.CroppingGate(1) =       NewStartColumn;
                    obj.CroppingGate(2) =       NewStartRow; 
               end

               
            
         end
         
         
           function obj =             resetCroppingGate(obj)
         
                obj.CroppingGate(1)=                  1;
                obj.CroppingGate(2)=                  1;
                obj.CroppingGate(3)=                  obj.MetaData.EntireMovie.NumberOfColumns;
                obj.CroppingGate(4)=                  obj.MetaData.EntireMovie.NumberOfRows;
             
           end
         
           function obj =       setCroppingGateWithRectange(obj, Rectangle)
               
                obj.CroppingGate =       Rectangle;
               
           

           end
           
         
            function obj =          updateAppliedCroppingLimits(obj)
                    % from cropping setting and cropping gate: calculate actually applied cropping gate;
                switch obj.CroppingOn

                     case 1
                         
                            CurrentFrame =                                        obj.SelectedFrames(1);    
                            CurrentColumnShift=                                 obj.AplliedColumnShifts(CurrentFrame);
                            CurrentRowShift =                                   obj.AplliedRowShifts(CurrentFrame);
                            CurrentPlaneShift =                                 obj.AplliedPlaneShifts(CurrentFrame);

                            obj.AppliedCroppingGate =                       obj.CroppingGate;
                            obj.AppliedCroppingGate(1) =                    obj.AppliedCroppingGate(1) + CurrentColumnShift;
                            obj.AppliedCroppingGate(2) =                    obj.AppliedCroppingGate(2) + CurrentRowShift;
                             

                     otherwise
                          [rows,columns, ~] =                               obj.getImageDimensionsWithAppliedDriftCorrection;
                           obj.AppliedCroppingGate =          [1 1 columns  rows];

                 end
            
            
            end
        
         
         
        
        function obj =                                      loadObjectFromFile(obj)
            
            fileName =                                      obj.getFileNameOfAnnotation;
            
            if exist(fileName) == 2
                
                Data =                                          load(fileName, 'MovieAnnotationData');
                obj =                                           Data.MovieAnnotationData;
                
                obj.DriftCorrection =                           obj.DriftCorrection.updateByManualDriftCorrection(obj.MetaData);
                
                
                
                obj =                                           obj.refreshTrackingResults; % refresh tracking results (PMTrackingAnalysis); these way they don't have to be saved to file; lots of duplicate data there
            
            end
            
        end
        
        
        function [obj] = setSavingStatus(obj, Value)
            
            obj.UnsavedTrackingDataExist = Value;
            
        end
        
        
    
        
        
        function [obj] = saveMovieDataWithOutCondition(obj)
            
                CompletPath =                       obj.getFileNameOfAnnotation;
                MovieAnnotationData =               obj;
                
                MovieAnnotationData.TrackingAnalysis =  '';
                
                
                if ~isempty(MovieAnnotationData.AutomatedCellRecognition)
                    MovieAnnotationData.AutomatedCellRecognition.ImageSequence = cell(size(MovieAnnotationData.AutomatedCellRecognition.ImageSequence,1),1);
                end
                save(CompletPath, 'MovieAnnotationData')
                fprintf('File %s was saved successfully.\n', CompletPath)
                obj =                               obj.setSavingStatus(false);
            
        end
        
       function  [obj] = saveMovieData(obj)
        
           if obj.UnsavedTrackingDataExist 
            
               obj =        obj.saveMovieDataWithOutCondition;

           end
        
       end
        
      
        
        
           
        function [obj] =   setFolderAnnotation(obj,FolderName)
            obj.FolderAnnotation =  FolderName;
            
        end
        
          function [obj] = autoCorrectChannels(obj)
            
            
            
            if isempty(obj.MetaData)
               disp('Movie does not have meta-data') 
               return
               
            end
            
            NumberOfChannels =  obj.MetaData.EntireMovie.NumberOfChannels;
            
            channelCheck =      obj.verifyChannels(NumberOfChannels);
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
            PlanesAfterDrift =                      Planes + max( obj.AplliedPlaneShifts);
            
            obj.ListWithPlaneStamps=                (arrayfun(@(x) sprintf('Z-depth= %i µm', int16((x-1)*VoxelSizeZ*10^6)), 1:PlanesAfterDrift, 'UniformOutput', false))';
  
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
        
          
         
           function obj =                       createMergeOfMetaData(obj)
              
              
             MetaDataCell =         obj.MetaDataOfSeparateMovies;
            
            NumberOfRows =      unique(cellfun(@(x) x.EntireMovie.NumberOfRows, MetaDataCell));
            NumberOfColumns =               unique(cellfun(@(x) x.EntireMovie.NumberOfColumns, MetaDataCell));
            NumberOfPlanes =                unique(cellfun(@(x) x.EntireMovie.NumberOfPlanes, MetaDataCell));
            NumberOfChannels =              unique(cellfun(@(x) x.EntireMovie.NumberOfChannels, MetaDataCell));
            VoxelSizeX =                    unique(cellfun(@(x) x.EntireMovie.VoxelSizeX, MetaDataCell));
            VoxelSizeY =                    unique(cellfun(@(x) x.EntireMovie.VoxelSizeY, MetaDataCell));
            VoxelSizeZ =                    unique(cellfun(@(x) x.EntireMovie.VoxelSizeZ, MetaDataCell));
            
            assert(length(NumberOfRows) == 1 && length(NumberOfColumns) == 1 && length(NumberOfPlanes) == 1 && length(NumberOfChannels) == 1 && length(VoxelSizeX) == 1 && length(VoxelSizeY) == 1 && length(VoxelSizeZ) == 1, ...
                'Cannot combine the different files. Reason: Dimension or resolutions do not match')
            
                 
           
            
            MergedMetaData.EntireMovie.NumberOfRows =                       NumberOfRows;
            MergedMetaData.EntireMovie.NumberOfColumns=                     NumberOfColumns;
            MergedMetaData.EntireMovie.NumberOfPlanes =                     NumberOfPlanes;
            
            MergedMetaData.EntireMovie.NumberOfChannels =                   NumberOfChannels;
            
            MergedMetaData.EntireMovie.VoxelSizeX=                          VoxelSizeX;
            MergedMetaData.EntireMovie.VoxelSizeY=                          VoxelSizeY;
            MergedMetaData.EntireMovie.VoxelSizeZ=                          VoxelSizeZ;
         
            
            MyListWithTimeStamps =                                          cellfun(@(x) x.TimeStamp, MetaDataCell, 'UniformOutput', false);
            
            MergedMetaData.PooledTimeStamps =                               unique(vertcat(MyListWithTimeStamps{:}));
            MergedMetaData.RelativeTimeStamps =                             MergedMetaData.PooledTimeStamps - MergedMetaData.PooledTimeStamps(1);  
            
            MergedMetaData.EntireMovie.NumberOfTimePoints  =                length(MergedMetaData.PooledTimeStamps);
            
            obj.MetaData =                                                  MergedMetaData;
           
           end

           
           function obj =   setFinishStatusOfTrackTo(obj, input)
               
               assert(strcmp(input, 'Finished') || strcmp(input,'Unfinished'), 'Input has to Finished or Unfinished')
               
                activeRow = obj.getActiveRowInTrackInfoList;
               
               if size(obj.Tracking.TrackInfoList,1) < activeRow
                   content =     PMTrackInfo(  obj.IdOfActiveTrack);
                   
               else
                   content = obj.Tracking.TrackInfoList{activeRow,1};
                   
               end
               
               switch input
                   
                   case 'Finished'
                        content =                                        content.setTrackAsFinished;
                   case 'Unfinished'
                     content =                                        content.setTrackAsUnfinished;
               end
              
               obj.Tracking.TrackInfoList{activeRow,1} =        content;
               
               fprintf('Finish status of track %i was changed to "%s".\n', obj.IdOfActiveTrack, input)
               
           end
        
         
           
        
        function obj =                      refreshTrackingResults(obj,varargin)
            
            assert(length(varargin) <= 1, 'Too many input argments')
            
            

            obj.TrackingAnalysis =                                 PMTrackingAnalysis(obj.Tracking, obj.DriftCorrection, obj.MetaData);
            
            if length(varargin) == 1
                obj =                                                  obj.synchronizeTrackingResults(varargin{1});
            else
                obj =                                                  obj.synchronizeTrackingResults;

            end
        end
        
        function obj =          addFilterForTrackFrames(obj,Frames)
            
            obj.TrackingAnalysis =          obj.TrackingAnalysis.addFilterForTrackFrames(Frames);
            
        end
        
        
        
        function obj =                      resetTrackingAnalysisToPhysicalUnits(obj)
            
            
            obj.TrackingAnalysis =      obj.TrackingAnalysis.convertDistanceUnitsIntoUm;
            obj.TrackingAnalysis =      obj.TrackingAnalysis.convertTimeUnitsIntoSeconds;
            
            
            
              
        
            
            
        end
        
        function obj =                  synchronizeTrackingResults(obj,varargin)
            

            
            
            assert(length(varargin) <= 1, 'Too many input arguments.')
            
            if ~isempty(obj.TrackingAnalysis)
            
                
                NumberOfPlanes = 20;
                
                if ~isempty(varargin)
                    
                    
                    MyInputCode =   varargin{1};
                    
                    switch MyInputCode % filter usable track masks;
                        
                        
                        case 'FilterForMiniMasks' %remove tracks where more than 50 of masks are "small", i.e. no real mask generation was performed;
                            
                             PixelData =           cellfun(@(x) x(:,6),  obj.TrackingAnalysis.TrackCell, 'UniformOutput', false);
                    
                            NumberOfTracks =        size(PixelData,1);
                            Filter =                false(NumberOfTracks,1);

                            for TrackIndex=1:NumberOfTracks
                                
                                ListOfMasksOfCurrentTrack = PixelData{TrackIndex};

                                NumberOfMasks =             size(ListOfMasksOfCurrentTrack,1);
                                DetailedMask =              cellfun(@(x) size(x,1)>NumberOfPlanes+10, ListOfMasksOfCurrentTrack);
                                Fraction =                  sum(DetailedMask)/NumberOfMasks;

                                if Fraction< 0.5
                                    Filter(TrackIndex,1) =  true;

                                end

                            end
                            
                        case 'OnlyUnfinishedTracks'

                            
                            ListWithAllUniqueTrackIDs =         obj.Tracking.getListWithAllUniqueTrackIDs;
                            ListOfClassifiedTrackIds  =         cellfun(@(x) x.TrackID, obj.Tracking.TrackInfoList);
                            ListOfFinishedRows  =               cellfun(@(x) x.Finalized, obj.Tracking.TrackInfoList);
                            
                            ListOfFinishedTrackIDs =            ListOfClassifiedTrackIds(ListOfFinishedRows);
                            
                            
                            Filter =                            ~ismember(  ListWithAllUniqueTrackIDs, ListOfFinishedTrackIDs);
                            
                        
                            TotalTracks = size(Filter,1);
                            FilterTracks =  sum(Filter);
                            
                            fprintf('Total tracks: %i. Shown tracks: %i\n', TotalTracks, FilterTracks)
                            
                    end
                    
                   
                    
                      obj.Tracking.ColumnsInTrackingCell =                   obj.TrackingAnalysis.ColumnsInTracksForMovieDisplay;
                obj.Tracking.Tracking =                                obj.TrackingAnalysis.TrackingListForMovieDisplay(Filter,:);
                obj.Tracking.TrackingWithDriftCorrection =             obj.TrackingAnalysis.TrackingListWithDriftForMovieDisplay(Filter,:);

                    
                else
                    
                    
                    
                    
                     obj.Tracking.ColumnsInTrackingCell =                   obj.TrackingAnalysis.ColumnsInTracksForMovieDisplay;
                obj.Tracking.Tracking =                                obj.TrackingAnalysis.TrackingListForMovieDisplay;
                obj.Tracking.TrackingWithDriftCorrection =             obj.TrackingAnalysis.TrackingListWithDriftForMovieDisplay;

                    
                   
                end
                
                
                
               
                
                
                
                
               
            end
            
            
        end
        
          
        
        %% mapping image-data:
        % this time-consuming and potentially memory-intensive: therefore this is not called by default;
        function obj =                                  AddImageMap(obj)
            
                    % usually this will done only a single time for each file;
                    % then the map and meta-data are saved in file enabling faster reading, still using other functions for retrieving data from file (with the help of this map);
                    myWaitBar =                                             waitbar(0.5, 'Mapping image file(s). This can take a few minutes for large files.'); % cannot do a proper waitbar because it is not a loop;
                    obj=                                                    obj.updateFilePaths;

                    [~,~,Extensions] =                                      cellfun(@(x) fileparts(x), obj.AttachedFiles, 'UniformOutput', false);
                    
                    Extension =                                             unique(Extensions);
                    if length(Extension)~=1
                       display('Image map could not be generated.') 
                       return
                    end
                    Extension =                                             Extension{1,1}; 
                    
                    switch Extension
                        
                        case {'.tif', '.lsm'}
                              myImageDocuments =                            cellfun(@(x)  PMTIFFDocument(x), obj.ListWithPaths);
                  
                        case '.czi'
                            myImageDocuments =                              cellfun(@(x)  PMCZIDocument(x), obj.ListWithPaths);
                            
                        case '.pic'
                             myImageDocuments =                             cellfun(@(x)  PMImageBioRadPicFile(x), obj.ListWithPaths);
                        otherwise % need to add pic
                            error('Format of image file not supported.')

                    end
                    
                    AtLeastOneTiffReadFailed =          min(arrayfun(@(x) x.FilePointer, myImageDocuments)) == -1 ;
                    if AtLeastOneTiffReadFailed
                        
                        obj.ImageMapPerFile =               [];
                        obj.PointersPerFile =               -1;
                        obj.FileCouldNotBeRead =            1;
   
                        
                    else

                        % extract meta-data:
                        obj.MetaDataOfSeparateMovies =          arrayfun(@(x) x.MetaData, myImageDocuments, 'UniformOutput', false);
                         % extract image map -data:
                        obj.ImageMapPerFile =                   arrayfun(@(x) x.ImageMap, myImageDocuments, 'UniformOutput', false); 
                        
                        obj =                                   obj.createMergeOfMetaData;

                        
                        
                       % Number = obj.getUniqueFrameNumberFromImageMap(obj.ImageMap);
                        
                        obj =                                   obj.autoCorrectChannels;
                        obj =                                   obj.updateTimeStampStrings;
                        obj =                                   obj.updatePlaneStampStrings;
                        obj =                                   obj.updateScaleBarString;
                        obj =                                   obj.resetViewPlanes;

                        obj.PointersPerFile =                   -1;
                        obj.FileCouldNotBeRead =               0;
                           
                    end
                    

                    if isvalid(myWaitBar)
                       % waitbar(1, myWaitBar, 'Mapping image file(s)'); %
                       % something strange is happening to waitBar
                        close(myWaitBar);
                    end

        end
        

        %% file-management of images
        
        
        function [ListWithFileNamesToAdd] =         extractFileNameListFromFolder(obj, UserSelectedFileNames)
            
                FolderName =                            obj.Folder;
            
                PicFolderObjects =                      (cellfun(@(x) PMImageBioRadPicFolder([FolderName x]), UserSelectedFileNames, 'UniformOutput', false))';
                ListWithFiles =                         cellfun(@(x) x.FileNameList(:,1), PicFolderObjects,  'UniformOutput', false);
                ListWithFileNamesToAdd =                vertcat(ListWithFiles{:});
               
        end
        
        
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
        
      
        
        function [obj] =                                updateFilePaths(obj)
            
            obj.ListWithPaths =                         cellfun(@(x) [ obj.Folder '/' x], obj.AttachedFiles, 'UniformOutput', false);
            
        end
        
        
         function [obj] =                                createNewFilePointers(obj)
            % each file gets its own pointer;
            obj =                                       obj.updateFilePaths;
            obj.PointersPerFile =                       cellfun(@(x) fopen(x), obj.ListWithPaths);
            
            
            fprintf('\nPMMovieTracking: @createNewFilePointers.\n')
            fprintf('The pointers to the following files were created:')
            cellfun(@(x) fprintf('%s\n', x),obj.ListWithPaths) 
            % need to add an option to create pointers when image-sequence is comprised by multiple images: e.g. .pic file, then;

        end
        
          
        function obj =                                  verifyPointerConnection(obj)
            
            
                ConnectionFailureList =                     arrayfun(@(x) isempty(fopen(x)), obj.PointersPerFile);
                AtLeastOnePointerFailedToRead =             max(ConnectionFailureList);
                
                if AtLeastOnePointerFailedToRead % if that failed (because the hard-drive is disconnected or because the file was moved);;
                    fprintf('\nPMMovieTracking: @verifyPointerConnection.\nPointer to file could not be accessed.\n')
                    fprintf('Possible reasons: harddrive with data are not connected, movie folder is incorrect.\n')
                    obj.FileCouldNotBeRead = 1;
                    
                else
                    obj.FileCouldNotBeRead = 0;

                end
            
            
        end
        

        function obj =                                  replaceImageMapPointers(obj)
            
            fprintf('\nPMMovieTracking: @replaceImageMapPointers.\n')
            
            
            % use the current file pointers and use them in the image map:
            PointerColumn =                     3;
            NumberOfImageMaps =     size(obj.ImageMapPerFile,1);
            for CurrentMapIndex = 1:NumberOfImageMaps
                fprintf('Updating pointers in ImageMapPerFile #%i of %i.\n', CurrentMapIndex, NumberOfImageMaps)
                CurrentNewPointer =                                                 obj.PointersPerFile(CurrentMapIndex);
                obj.ImageMapPerFile{CurrentMapIndex,1}(2:end,PointerColumn) =       {CurrentNewPointer};
                  
            end
            
            % also need to add an option when there are multiple files (i.e. pointers per movie event);
            
  
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
            
           
            if isstruct(obj.Tracking) || isempty(obj.Tracking)
                obj.Tracking = PMTrackingNavigation(0,0);
            end

            
             
             
             if isempty(obj.TrackingAnalysis)
                 
                 
             elseif isempty(obj.TrackingAnalysis.MetaData)
                 obj.TrackingAnalysis.MetaData = obj.MetaData;
                 
             end
             
             NumberOfFrames =                       obj.MetaData.EntireMovie.NumberOfTimePoints;
             obj.Tracking =                          obj.Tracking.fillEmptySpaceOfTrackingCellTime(NumberOfFrames);
             
             
            
            
        end
        

     
        
        function [obj] =                                updateMaskOfActiveTrackByAdding(obj,yList,xList, plane)
             
            if isempty(yList) || isempty(xList)
                return
            end

            pixelListToAdd =                            [yList,xList];
            pixelListToAdd(:,3) =                       plane;

            pixelList_AfterAdding =                     getPixelsOfActiveTrackAfterAddingOf(obj, pixelListToAdd);

            mySegementationCapture =                    PMSegmentationCapture(pixelList_AfterAdding, 'Manual');
            [obj] =                                     obj.resetActivePixelListWith(mySegementationCapture);
                
 
        end
     
        
        function [obj] =                                resetActivePixelListWith(obj, SegmentationCapture)
            
                 RowInCell=                                     obj.FindLocationOfNewCellMask;
                 activeFrame =                                  obj.getSelectedFrame;
                 MyTrackID =                                    obj.IdOfActiveTrack;
                  
                 newPixels =                                    SegmentationCapture.MaskCoordinateList;
                 obj.Tracking =                                 obj.Tracking.addPixelsToTrackingCellForTime(activeFrame,RowInCell,MyTrackID,newPixels,SegmentationCapture);
                 
                obj =                                           obj.setSavingStatus(true);

        end
        
        
      
        

        function [obj] =                                  mergeImageMaps(obj)
            
            
            
            %% get from model
            TimeColumn =                                    10;
            ImageMapPerFileInternal =                       obj.ImageMapPerFile;
            
            fprintf('\nPMMovieTracking: @mergeImageMaps\n')
            fprintf('Pooling %i ImageMaps.\n', length(ImageMapPerFileInternal))
            
            
            %% pool image maps: (this is done on a copy becausre otherwise we would overwrite the time frames in the original which we don't want;  
            pooledTemp =        cellfun(@(x) x(2:end,:), ImageMapPerFileInternal, 'UniformOutput', false);
            pooledTemp =        vertcat(pooledTemp{:});
            
            sumTimeOfAllParts =     sum(cellfun(@(x) max(cell2mat(x(2:end,10))), ImageMapPerFileInternal));
            
            if obj.MetaData.EntireMovie.NumberOfTimePoints == sumTimeOfAllParts
                FramesPerMap =                                          cellfun(@(x) max(cell2mat(x(2:end,TimeColumn))), ImageMapPerFileInternal);
                CumulativeTemp =                                        cumsum(FramesPerMap);
                NumbersForAdjustingFramesOfDifferentFiles =             [0; CumulativeTemp(1:end-1)];
          
            elseif obj.MetaData.EntireMovie.NumberOfTimePoints == size(pooledTemp,1)/obj.MetaData.EntireMovie.NumberOfChannels
               
                NumbersForAdjustingFramesOfDifferentFiles =             linspace(0,obj.MetaData.EntireMovie.NumberOfTimePoints-1,obj.MetaData.EntireMovie.NumberOfTimePoints);
                NumbersForAdjustingFramesOfDifferentFiles =             repmat(NumbersForAdjustingFramesOfDifferentFiles, obj.MetaData.EntireMovie.NumberOfChannels,1);
                NumbersForAdjustingFramesOfDifferentFiles =             NumbersForAdjustingFramesOfDifferentFiles(:);
                
            elseif obj.MetaData.EntireMovie.NumberOfTimePoints == max(cell2mat(pooledTemp(:,10)))
                % do nothing 
                fprintf('Meta-data frame data and numbers in ImageMap matches. Therefore no adjusting of frame numbers is necessary.\n')
            else
                error('Cannot interpret time-series')
                
            end
            
            TemporaryImageMapPerFile =          ImageMapPerFileInternal;
            
            
            if exist('NumbersForAdjustingFramesOfDifferentFiles') == 1
                
                 NumberOfImageMaps =     size(TemporaryImageMapPerFile,1);
                for CurrentMapIndex = 1:NumberOfImageMaps
                    AdjustingForCurrentImageMap = NumbersForAdjustingFramesOfDifferentFiles(CurrentMapIndex);
                    
                    fprintf('Adjust frame numbers of ImageMap #%i. %i frames added.\n', CurrentMapIndex, AdjustingForCurrentImageMap)
                    OldMapNumbers =                                                         cell2mat(ImageMapPerFileInternal{CurrentMapIndex,1}(2:end,TimeColumn));
                    TimeFrameAfterShift =                                                   OldMapNumbers + AdjustingForCurrentImageMap;
                    TemporaryImageMapPerFile{CurrentMapIndex,1}(2:end,TimeColumn) =         num2cell(TimeFrameAfterShift);

                end
            
            end
            
            ImageMapsWithoutTitles =                cellfun(@(x) x(2:end,:), TemporaryImageMapPerFile, 'UniformOutput', false);
            
            
            %% put result back into model:
            obj.ImageMap =                          [ImageMapPerFileInternal{1,1}(1,:); vertcat(ImageMapsWithoutTitles{:})];
            

        end
        
        
      
        
        
        
        
        

        %% helper functions for file- and image-managment:
        
        
         
        function [ImageVolumeForExport] =                     Create5DImageVolume(obj, Settings)
            
            
  
            %% first filter the image map: only images that meet the defined source numbers will be kept;
             FilteredImageMap =                         obj.ImageMap;   
            ImageMapColumns =                           obj.ImageMap(1,:);
            
            if ~isempty(Settings)
            
                [FilteredImageMap] =                        obj.FilterImageMap(FilteredImageMap, Settings,'TargetFrameNumber'); % filter for frames
                [FilteredImageMap] =                        obj.FilterImageMap(FilteredImageMap, Settings,'TargetPlaneNumber'); % filter for planes
                [FilteredImageMap] =                        obj.FilterImageMap(FilteredImageMap, Settings,'TargetChannelIndex'); % filter for channels


                 %% then reset the numbers of the images in the file to rearrange if needed;
                 % for example, you may want to change time frame from 10 to 1 if you want just a single image volume rather than a time-series;
                [FilteredImageMap] =                        obj.resetImageMap(FilteredImageMap, Settings,'TargetFrameNumber'); % replace source frame numbers wiht target frame numbers
                [FilteredImageMap] =                        obj.resetImageMap(FilteredImageMap, Settings,'TargetPlaneNumber'); 
                [FilteredImageMap] =                        obj.resetImageMap(FilteredImageMap, Settings,'TargetChannelIndex');

            end
             FilteredImageMap(1,:) =                    [];
 
             if isempty(FilteredImageMap)
                   ImageVolumeForExport=                         cast(uint8(0),'uint8');
                ImageVolumeForExport(1,1,1,1,1)=                          0;
                return
                 
             end
             
             
             %% after filter the image map, verify that some contents are consistent and get precision and dimensions and initialize array;
             
            [Structure]  =                              obj.VerifyImageMap(FilteredImageMap);
            Precision =                                 Structure.Precision;
            
            ColumnForPlanes =                           strcmp(ImageMapColumns, 'TargetPlaneNumber');
            ColumnForFrames =                           strcmp(ImageMapColumns, 'TargetFrameNumber');
            
            TotcalColumnsOfImage =                      Structure.TotcalColumnsOfImage ;
            TotalRowsOfImage =                          Structure.TotalRowsOfImage;
            TotalNumberOfChannels =                     max(cell2mat(FilteredImageMap(:,15)));
            TotalPlanes =                               max(cell2mat(FilteredImageMap(:,ColumnForPlanes)));
            TotalFrames =                               max(cell2mat(FilteredImageMap(:,ColumnForFrames)));
            
            ImageVolumeForExport=                         cast(uint8(0),Precision);
            ImageVolumeForExport(TotalRowsOfImage,TotcalColumnsOfImage,TotalPlanes,TotalFrames,TotalNumberOfChannels)=                          0;


            %% go through one entry after another in image map and reconstruct image;
            NumberOfImageDirectories =        size(FilteredImageMap,1);

            for IndexOfDirectory=1:NumberOfImageDirectories

                CurrentImageDirectory =             FilteredImageMap(IndexOfDirectory,:);

                
                %% place file pointer to beginning of strip
                 % 'source' info:
                fileID =                            CurrentImageDirectory{3};
                CurrentPlanes =                      CurrentImageDirectory{ColumnForPlanes};
                CurrentFrame =                      CurrentImageDirectory{ColumnForFrames};    
                ChannelList =                    CurrentImageDirectory{15};
               
                BytesPerSample =                    CurrentImageDirectory{5}/8; % bits per sample divided by 8
               
                Precision=                          CurrentImageDirectory{6};
                byteOrder=                          CurrentImageDirectory{4};
                
                TotcalColumnsOfImage =              CurrentImageDirectory{8};
                RowsPerStrip =                      CurrentImageDirectory{12};
               
                
                ListWithStripOffsets =              CurrentImageDirectory{1};
                 NumberOfStrips =                    size(ListWithStripOffsets,1);        
                
                ListWithStripByteCounts=              CurrentImageDirectory{2};
                 ListWithUpperRows=                   CurrentImageDirectory{13};
                ListWithLowerRows=                   CurrentImageDirectory{14};
                
                if length(ListWithUpperRows) ~= NumberOfStrips
                    ListWithUpperRows(1:NumberOfStrips,1) = ListWithUpperRows;
                end
                
                  if length(ListWithLowerRows) ~= NumberOfStrips
                    ListWithLowerRows(1:NumberOfStrips,1) = ListWithLowerRows;
                end
                
                
                if length(ChannelList) ~= NumberOfStrips
                    ChannelList(1:NumberOfStrips,1) =   ChannelList;
                end
                
                
                for CurrentStripIndex = 1:NumberOfStrips
                    
                    
                    CurrentStripOffset =            ListWithStripOffsets(CurrentStripIndex,1);
                    CurrentStripByteCount =         ListWithStripByteCounts(CurrentStripIndex,1);
                    
                    CurrentUpperRow =               ListWithUpperRows(CurrentStripIndex,1);
                    CurrentBottomRow =              ListWithLowerRows(CurrentStripIndex,1);
                 
                    fseek(fileID,  CurrentStripOffset, -1);

                    CurrentStripLength =                CurrentStripByteCount / BytesPerSample;
                    CurrentStripData =                  cast((fread(fileID, CurrentStripLength, Precision, byteOrder))', Precision);    


                    CurrentChannel =                    ChannelList(CurrentStripIndex,1);
                    %% reshape the strip so that it fits:
                    % 'target' info
                    CurrentStripImage=                  reshape(CurrentStripData,TotcalColumnsOfImage,RowsPerStrip, length(CurrentPlanes));                
                    CurrentStripImage =         permute (CurrentStripImage, [2 1 3]);  % in image information comes usually as rows first, but reshape reads columns first that's why a switch is necessary;  
                    ImageVolumeForExport(CurrentUpperRow:CurrentBottomRow,1:TotcalColumnsOfImage, CurrentPlanes, CurrentFrame, CurrentChannel)=     CurrentStripImage;
                    

                end
                
            end
            
            
        end
        

    
         function [ImageMap] =                               FilterImageMap(obj,ImageMap, Settings, FilterCode)
              
            % filter image map: keep only images that are defined as "source";
              % if the inputs are empty, ignore and leave all rows;
            
            ColumnsOfImageMap  =          ImageMap(1,:);
            ImageMapForFiltering =          ImageMap(2:end,:);

            
            switch FilterCode
                
                case 'TargetFrameNumber'
                    ListWithWantedNumbers =         Settings.SourceFrames;
                    
                case 'TargetPlaneNumber'
                    ListWithWantedNumbers =         Settings.SourcePlanes;
                    
                case 'TargetChannelIndex'
                     ListWithWantedNumbers =         Settings.SourceChannels;   
                        
                
            end
            

           if ~isempty(ListWithWantedNumbers)
               
                ColumnWithWantedParameter =                                 strcmp('TargetFrameNumber', ColumnsOfImageMap);
                % filter for channels:
                NumberOfSources =                                           length(ListWithWantedNumbers);
                RowsThatShouldBeKept =                                      false(size(ImageMapForFiltering,1),NumberOfSources);
                for CurrentIndex = 1:NumberOfSources
                    RowsThatShouldBeKept(:,CurrentIndex) =                  cell2mat(ImageMapForFiltering(:,ColumnWithWantedParameter)) == ListWithWantedNumbers(CurrentIndex);
                end

                RowsThatShouldBeKept =                                      max(RowsThatShouldBeKept, [], 2);
                ImageMapForFiltering=                                       ImageMapForFiltering(RowsThatShouldBeKept,:);

           end
            
            ImageMap = [ColumnsOfImageMap; ImageMapForFiltering];
           
          

        end
        
        
        
         function [ImageMap] =                       resetImageMap(obj,ImageMap, Settings, FilterCode)
                      
                ColumnsOfImageMap  =                ImageMap(1,:);
                ImageMapForFiltering =              ImageMap(2:end,:);

                switch FilterCode

                    case 'TargetFrameNumber'
                        SourceNumbers =                 Settings.SourceFrames;
                        TargetNumbers =                 Settings.TargetFrames;

                    case 'TargetPlaneNumber'
                        SourceNumbers =                 Settings.SourcePlanes;
                        TargetNumbers =                 Settings.TargetPlanes;

                    case 'TargetChannelIndex'
                        SourceNumbers =                 Settings.SourceChannels;   
                        TargetNumbers =                 Settings.TargetChannels;   

                end

                WantedColumn =                                              strcmp(FilterCode, ColumnsOfImageMap);

                NumberOfChanges =                   length(SourceNumbers);
                for ChangeIndex = 1:NumberOfChanges


                    oldValue =                      SourceNumbers(ChangeIndex);
                    newValue =                      TargetNumbers(ChangeIndex);


                    RowsThatNeedChange =                                        cell2mat(ImageMapForFiltering(:,WantedColumn)) == oldValue;
                    ImageMapForFiltering(RowsThatNeedChange,WantedColumn) =        {newValue};


                end

                ImageMap = [ColumnsOfImageMap; ImageMapForFiltering];

                
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
            
            if isempty(FilteredImageMap)
                Structure.Precision = '';
                Structure.TotcalColumnsOfImage =  '';
                Structure.TotalRowsOfImage = '';
            end
            
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
        
        
        
    
     end
        
         
    
end