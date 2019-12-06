classdef PMMovieController < handle
    %PMMOVIETRACKINGSTATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
         
        %% model
        LoadedMovie
        
        %% views
        Views
        TrackingViews
        
       %% controller state 
        % this is not stored on file and contains user input and preprocessed model data for convenient and fast use for updating views; 
        PressedKeyValue % direct and direct of user is store here
        
        MouseDownRow =                                  NaN
        MouseDownColumn =                               NaN
        MouseUpRow =                                    NaN
        MouseUpColumn =                                 NaN
        
        ActiveXCoordinate =                             NaN
        ActiveYCoordinate =                             NaN
        ActiveZCoordinate =                             NaN
        
        LoadedImageVolumes                              % saving image information (saves actual images and settings for how many images should be loaded)
        NumberOfLoadedFrames =                          40
         
        CurrentTrackIDs % currently relevant segmentation information (this comes directly from model but may be filter, corrected for drift etc.);
        CurrentXOfCentroids 
        CurrentYOfCentroids
        CurrentZOfCentroids
        ListOfAllPixels
        ListOfAllActiveTrackPixels

        ListOfTrackViews =                              cell(0,1) % contains information for each track how to be displayed
 
        MaskLocalizationSize =                          5; % info for segmentation (this could potentially be expanded or moved to MovieTracking
        
        MaskColor =                                     [NaN NaN 150]; % some settings for how 
        MaskColorForActiveTrack =                       [100 100 100];
        
        BackgroundColor =                               [0 0.1 0.2];
        ForegroundColor =                               'c';

    end
    
    methods
        
        
        function obj =                          PMMovieController(varargin)
            
            if ~isempty(varargin) % input should be movie controller views
                
                switch length(varargin)
                    
                    case 1 % only connected movies
                        
                        Input =     varargin{1};
                        
                        if strcmp(class(Input), 'PMImagingProjectViewer')
                            obj.Views =                                                   Input.MovieControllerViews;
                            obj.Views.Figure =                                            Input.Figure;   
                            
                            obj.TrackingViews =                                           Input.TrackingViews.ControlPanels;
                            obj.changeAppearance;

                            obj.disableAllViews;
                            obj =                                                         obj.deleteAllTrackLineViews;

                        else
                            
                            ViewObject =                                                         Input;
                            obj.Views =                                                     ViewObject;
                            obj.Views.Figure =                                              ViewObject.Figure;  

                            
                        end
                        
                        
            
                      

                        
                    case 2 % connected views and movie
                        
                         ViewObject =                                                         varargin{1};
                        obj.Views =                                                     ViewObject;
                        obj.Views.Figure =                                              ViewObject.Figure;  

                    
                        obj.LoadedMovie =                                           varargin{2};
                    
                end
                
                if ~isempty(obj.LoadedMovie)
                    
                     obj =                                  obj.resetDriftDependentParameters;
                   
                    obj =                                               obj.resetLimitsOfImageAxesWithAppliedCroppingGate;
                    obj =                                               obj.shiftImageByDriftCorrection;
                    obj =                                               obj.updateCroppingLimitView;

                    
                    obj.LoadedImageVolumes =                      cell(obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints,1);
                end
                

                
            end
           
            %PMMOVIETRACKINGSTATE Construct an instance of this class
            %   modulates interplay between movie model (images and annotation) and views;
           

        end
        
        
       %% set model and view:

       
        % navigation
        function [obj]  =                       resetFrame(obj, newFrame)
            

            %obj.Views.Navigation.TimeSlider.Value = newFrame;
            if newFrame<1 || newFrame>obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints
                return
            end
            
            
            
             myPressedKey =                                      obj.PressedKeyValue;
           
             PlaneAndCropShouldBeReset =       (obj.LoadedMovie.TrackingOn && ~isempty(double(myPressedKey)) &&   double(myPressedKey)==29) || strcmp(myPressedKey, 'a');
             
             if PlaneAndCropShouldBeReset
                
                 
                    obj.LoadedMovie =                              obj.LoadedMovie.setFrameAndAdjustPlaneAndCropByTrack(newFrame); 
                 
               
                    obj =                                           obj.updateCroppingLimitView;
                    obj =                                           obj.resetLimitsOfImageAxesWithAppliedCroppingGate;
                
             
             else
                 
                 obj.LoadedMovie =                              obj.LoadedMovie.setFrameTo(newFrame);
                 
                     
             end
            
            
            obj =                                               obj.setCentroidAndMovieData;
            
            %% update views:
            obj =                                               obj.updateImageView;  
            obj =                                               obj.updateImageHelperViews;
            
            
            
            
        end

        function [obj]  =                       resetPlane(obj, newPlane)
            
            obj.LoadedMovie.SelectedPlanes =                newPlane;
            obj.LoadedMovie =                               obj.LoadedMovie.resetViewPlanes;
            
            obj =                                           obj.setCentroidAndMovieData;
            obj =                                           obj.updateImageView;  
            obj =                                           obj.updateImageHelperViews;
            

        end
      
        function [obj] =                        resetChannelSettings(obj, selectedChannel)
            
            obj.LoadedMovie.SelectedChannelForEditing =         selectedChannel;
            obj =                                               obj.updateChannelSettingView;
            
        end
        
        
        % drift correction
        function obj  =                         setDriftCorrectionTo(obj, state)

            obj.LoadedMovie =                       obj.LoadedMovie.setDriftCorrectionTo(state); % the next function should be incoroporated into this function
            obj =                                   obj.resetDriftDependentParameters;
   
        end
        
        function obj =                          resetDriftCorrectionByManualClicks(obj)
            
            obj.LoadedMovie.DriftCorrection =             obj.LoadedMovie.DriftCorrection.updateByManualDriftCorrection;
              obj =                                         obj.resetDriftDependentParameters;
            
        end
        
        function obj =                          resetDriftCorrectionToNoDrift(obj)
           
            obj.LoadedMovie.DriftCorrection =               obj.LoadedMovie.DriftCorrection.eraseDriftCorrection(obj.LoadedMovie.MetaData);
            obj =                                           obj.resetDriftDependentParameters;
            
        end
        
        function obj =                          resetDriftDependentParameters(obj)
           
            obj.LoadedMovie =                       obj.LoadedMovie.setDriftDependentParameters;
            obj =                                   obj.setCentroidAndMovieData; % centroids may change
            
            obj =                                   obj.resetViewsForCurrentDriftCorrection;
            
          
        end  
        
         % tracking:
         function [obj] =                        resetPlaneTrackingByMenu(obj) % maximum projection for tracking
             
             
                MaximumProjOfTracking =                             obj.TrackingViews.ShowMaximumProjection.Value;

                obj.LoadedMovie =                                   obj.LoadedMovie.setCollapseAllTrackingTo(MaximumProjOfTracking);
                
                obj =                                               obj.setCentroidAndMovieData;
                obj =                                               obj.updateImageView;  
                obj =                                               obj.updateImageHelperViews;

         
         end
         
        function obj =                          changActiveTrackByTableView (obj)
            
                SelectedTrackIDs =                                  obj.getCurrentlySelectedTrackIDs;
                
                if length(SelectedTrackIDs)== 1
                        
                    obj.LoadedMovie =                                      obj.LoadedMovie.setActiveTrackWith( SelectedTrackIDs);
                    obj =                                                   obj.resetActiveTrack;
                    obj =                                                   obj.updateViewsAfterTrackSelectionChange;

                    

                end
                
        end
        
        function [obj] =                        mergeSelectedTracks(obj)
            
               SelectedTrackIDs =                       obj.getCurrentlySelectedTrackIDs;
               obj.LoadedMovie.Tracking =               obj.LoadedMovie.Tracking.mergeTracks(SelectedTrackIDs);

               obj.LoadedMovie  =                       obj.LoadedMovie.refreshTrackingResults;
               
               obj =                                    obj.updateViewsAfterChangesInTracks; 
                 
         end
         
        function [obj] =                        splitSelectedTracks(obj)
                
                SourceTrackID =                                                 obj.LoadedMovie.IdOfActiveTrack;
                SplitTrackID =                                                  obj.LoadedMovie.Tracking.generateNewTrackID;
                SplitFrame =                                                    obj.LoadedMovie.SelectedFrames(1);

                obj.LoadedMovie.Tracking =                                      obj.LoadedMovie.Tracking.splitTrackAtFrame(SplitFrame,SourceTrackID,SplitTrackID);

                obj.LoadedMovie  =                                              obj.LoadedMovie.refreshTrackingResults;  

                obj =                                                           obj.updateViewsAfterChangesInTracks;      
               
          end
            

        
        %% controller directly sets model:
        
          function [obj] =                            resetMovieToLastTrackedFrame(obj)
            
            
             [~,rowOfWantedFrame] =                                max(AllFramesOfSelectedTrack);

                    
               TimeFrame =                                         RelevantSegmentation{frameColumn};
                    
             obj.LoadedMovie.SelectedFrames  =                   TimeFrame;
            
            
            
          end
        

         
             function obj =             updateLoadedImageVolumes(obj)
            
             
             %% first check whether any frames need to loaded;

             neededFrames =                      obj.getFramesThatNeedToBeLoaded;
            
             settings.SourceChannels =          [];
             settings.TargetChannels =          [];
             
             settings.SourcePlanes =            [];
             settings.TargetPlanes =            [];
           
             settings.TargetFrames =            1;
             
             numericalNeededFrames =            find(neededFrames);

             numberOfNeedeFrames = length(numericalNeededFrames);
             
             %% don't do anything if no frames are needed
             if numberOfNeedeFrames<1 % don't do anything if no frames are needed;
                 return
             end
             
             %% otherwise check whether the files can be connected and inactivate various controls;
             obj.disableAllViews;% don't let anybody do anything until movie sequence was loaded succesfully;
             
             [obj.LoadedMovie] =                                obj.LoadedMovie.createFunctionalImageMap;
            if obj.LoadedMovie.FileCouldNotBeRead % check whether the files could be connected: if not do not try to read;
                    obj.enableAllViews;
                    return
            
            end
            obj.LoadedMovie.FileCouldNotBeRead = true; % now anticipate that during the reading something might go wrong and set this to false x;
            % if something goes wrong it will stay there and indicate that the load wasn't complete;
            
             
            
            if iscell(obj.LoadedImageVolumes)
                TemporaryImageVolumes =            obj.LoadedImageVolumes;
            else
                TemporaryImageVolumes =             cell(0,1);
            end
            
            
            
            
             %% then read all the needed data into a temporary buffer
             for frameIndex = 1:numberOfNeedeFrames

                 if frameIndex == 1 % waitbar should not show up when nothing needs to be loaded.
                    h = waitbar((0/numberOfNeedeFrames), 'Loading images from file.');
                 else
                     waitbar(frameIndex/numberOfNeedeFrames, h, 'Loading images from file.');
                 end
                 
                 currentFrame =                                 numericalNeededFrames(frameIndex);
                 settings.SourceFrames =                        currentFrame;
                 wantedImageVolume =                            obj.LoadedMovie.Create5DImageVolume(settings);
                 
                 
                 %% apply median filter:
                 NumberOfPlanes =       size(wantedImageVolume,3);
                 NumberOfChannels =       size(wantedImageVolume,5);
                
                 ReconstructionType = 2;
                 
                 for CurrentPlane = 1:NumberOfPlanes
                    for CurrentChannel = 1: NumberOfChannels
                        
                        switch ReconstructionType
                            
                            case 1
                                PresentImage =  medfilt2(wantedImageVolume(:,:,CurrentPlane,1,CurrentChannel));
                        
                            case 2
                                
                                 PresentImage =  wantedImageVolume(:,:,CurrentPlane,1,CurrentChannel);


                                 se = strel('disk',2);
                                 modIm = imopen(PresentImage, se);


                                    modIm = imsubtract(PresentImage, modIm);


                                    modIm =        imsubtract(medfilt2(PresentImage),medfilt2(modIm));

                                    PresentImage = modIm;
                            
                        end
                        

    
                        
                        if strcmp(class(PresentImage), 'uint8')
                            
                           
                            if sum(PresentImage(:)>=100) >= length(PresentImage(:))/5 % get rid of highly saturated images 
                                PresentImage(:,:) = 0;
                            end
                            
                        end
                        
                        wantedImageVolume(:,:,CurrentPlane,1,CurrentChannel) = PresentImage;
                            
                    
                    end
                
                end
                 
                 TemporaryImageVolumes{currentFrame,1} =        wantedImageVolume;
                 
                  if frameIndex == numberOfNeedeFrames
                      close(h)
                  end
                 
                
                 
             end
             
            
             obj.LoadedImageVolumes =                       TemporaryImageVolumes;
             
             obj.LoadedMovie.FileCouldNotBeRead =           false;
             
   
         end
        
          
           %% setters:
           function obj =                             deleteAllTracks(obj)
             
                trackIDs =                                   obj.LoadedMovie.getTrackIDsOfCurrentFrame;

                numberOfTracks =    size(trackIDs,1);

                for CurrentTrack =1:numberOfTracks
                    currentTrackID =                                trackIDs(CurrentTrack);
                    obj.LoadedMovie.Tracking  =                     obj.LoadedMovie.Tracking.removeTrack(currentTrackID);
                end

                obj.LoadedMovie =                                   obj.LoadedMovie.setActiveTrackWith(NaN);
                obj =                                               obj.resetActiveTrack;

                obj.LoadedMovie =                                   obj.LoadedMovie.refreshTrackingResults;
                obj =                                               obj.updateViewsAfterChangesInTracks;

         end
         
       
        
        
         function obj =                             deleteActiveMask(obj)
             
            % change model: 
            TrackID =                                       obj.LoadedMovie.IdOfActiveTrack;
            CurrentFrame =                                  obj.LoadedMovie.SelectedFrames(1);
            obj.LoadedMovie.Tracking  =                     obj.LoadedMovie.Tracking.removeMask(TrackID,CurrentFrame);
             
            obj.LoadedMovie =                               obj.LoadedMovie.refreshTrackingResults;
            
            obj =                                           obj.updateViewsAfterChangesInTracks;
            
              

         end
         
        
        
        
          function obj =                              updateTrackList(obj)
           
                % don't quit understand what's the benefit of using this, instead of directly calling refreshTrackingResults; leave for now;
         
              if isempty(obj.LoadedMovie.Tracking.Tracking) || isempty(obj.LoadedMovie.Tracking.TrackingWithDriftCorrection)
                    obj.LoadedMovie  =      obj.LoadedMovie.refreshTrackingResults;
                    
              end
                
               
               
                    
          end
        
        
          
        
        
          function [obj] =                              finalizeMovieController(obj)
                
            %% when the file was not yet mapped successfully, do the mapping now
                if isempty(obj.LoadedMovie.ImageMapPerFile)
                     
                     obj.LoadedMovie =                              obj.LoadedMovie.AddImageMap;

                else
                    % otherwise: update the pointers of the current image maps if necessary:;
                    obj.LoadedMovie =                               obj.LoadedMovie.updateFileReadingStatus;

                end 
            
                                     
                
                % this shouldn't be necessary: but if for some reason the set plane etc. is inaccurate change this before doing anything with the data;
                obj.LoadedMovie =                                   obj.LoadedMovie.autoCorrectNavigation;
                obj.enableAllViews;
                obj =                                               obj.ensureCurrentImageFrameIsInMemory;
                obj.enableAllViews;

                
                %% finalize loaded movie so that it works together with the controller views:
                obj.LoadedMovie.DriftCorrection =                   obj.LoadedMovie.DriftCorrection.update(obj.LoadedMovie.MetaData);
                obj.LoadedMovie =                                   obj.LoadedMovie.autoCorrectTrackingObject;
                

              

            
            
          end
        
       
            function obj =      resetActiveTrack(obj)
                % this should be in movieTracking, but cannot do this now because need to get centroid from mouse click;
            
                planeOfActiveTrack =                                        obj.LoadedMovie.getPlaneOfActiveTrack;
                obj.LoadedMovie =                                           obj.LoadedMovie.setSelectedPlaneTo(planeOfActiveTrack); % direct change of model:
                obj =                                                      obj.setCentroidAndMovieData; % reset active track 
                
                TrackDataOfActiveMask =                                obj.LoadedMovie.getSegmentationOfActiveTrack;
                
                if ~isempty(TrackDataOfActiveMask)
                     obj.LoadedMovie =                           obj.LoadedMovie.moveCroppingGateToActiveMask;
                 
                else
                    
                    % probably need to remove drift when drift correction is on;
                    MovieAxes =                                         obj.Views.MovieView.ViewMovieAxes;
                    CenterX =                                           MovieAxes.CurrentPoint(1,1);
                    CenterY =                                           MovieAxes.CurrentPoint(1,2);
                    obj.LoadedMovie =                                   obj.LoadedMovie.moveCroppingGateToNewCenter(CenterX, CenterY);
                    
                end
                 obj.LoadedMovie =                                      obj.LoadedMovie.updateAppliedCroppingLimits;
                    


            end
      
          
           function obj =             changeActiveTrackByRectangle(obj)
             
             
                function [ShortestDistance] = computeShortestDistance(currentX,currentY,xOfTracks,yOfTracks)
               
                DistanceX=  currentX-xOfTracks;
                DistanceY=  currentY-yOfTracks;

                if isempty(DistanceX) || isempty(DistanceY)
                    Distance=   nan;

                else
                    Distance=   sqrt(power(DistanceX,2)+power(DistanceY,2));

                end

                ShortestDistance=  min(Distance);

                end
                
                [ClickedRow, ClickedColumn, ~, ~] =               obj.getUnverifiedCoordinatesOfCurrentMousePosition;
               
                
                

               
                
                TrackDataOfCurrentFrame =       obj.LoadedMovie.getSegmentationOfCurrentFrame;
                
                OVERLAP =                                cellfun(@(x)  ismember(round([ClickedRow ClickedColumn]), round(x(:,1:2)), 'rows'), TrackDataOfCurrentFrame(:,6));

                if sum(OVERLAP) == 1
                    NewTrackID =                        TrackDataOfCurrentFrame{OVERLAP,1};
                    obj.LoadedMovie =                   obj.LoadedMovie.setActiveTrackWith(NewTrackID);
                    obj =                               obj.resetActiveTrack;
                    obj =                               obj.setCentroidAndMovieData; % reset active track data
                end

               
               

           end
         
         
                 
        function obj =              deleteActiveTrack(obj)
            
             %% first remove all the masks corresponding to the track:
            TrackID =                                           obj.LoadedMovie.IdOfActiveTrack;
            obj.LoadedMovie.Tracking  =                         obj.LoadedMovie.Tracking.removeTrack(TrackID);
             
            %% then update the track list: one track will be gone;
            obj.LoadedMovie =                                   obj.LoadedMovie.refreshTrackingResults;
            
            obj =                                               obj.updateViewsAfterChangesInTracks;

           
              
 
         end
        
         function [obj] =           synchronizeTrackingResults(obj)
             
             
             
             if isempty(obj.LoadedMovie.TrackingAnalysis)
                 return
             end
             
            obj.LoadedMovie.Tracking.ColumnsInTrackingCell =                    obj.LoadedMovie.TrackingAnalysis.ColumnsInTracksForMovieDisplay;
            obj.LoadedMovie.Tracking.Tracking =                                 obj.LoadedMovie.TrackingAnalysis.TrackingListForMovieDisplay;
            obj.LoadedMovie.Tracking.TrackingWithDriftCorrection =              obj.LoadedMovie.TrackingAnalysis.TrackingListWithDriftForMovieDisplay;

             
             
         end
         
        
              
        function [obj] =       filterTrackModelByTrackID(obj, trackIDs)
             
             
             obj.LoadedMovie.TrackingAnalysis = obj.LoadedMovie.TrackingAnalysis.addFilterForTrackIds(trackIDs);
             
              end
         
    
         
              
      
         function [obj] =       filterTrackModelByFrame(obj, frames)
             
             
             obj.LoadedMovie.TrackingAnalysis = obj.LoadedMovie.TrackingAnalysis.addFilterForTrackFrames(frames);
             
         end
         
       
         
            
        %% setting controller state only (indirect effect may still occur):
        function obj =  setCentroidPositions(obj)
                segmentationOfCurrentFrame =                         obj.LoadedMovie.getSegmentationOfCurrentFrame;
                myIDOfActiveTrack =                                 obj.LoadedMovie.IdOfActiveTrack;
             
              %% update centroids (they are used only for displaying the centroid view) ;
                obj.CurrentTrackIDs =                           cell2mat(segmentationOfCurrentFrame(:,obj.LoadedMovie.Tracking.getTrackIDColumn));
                obj.CurrentXOfCentroids =                       cell2mat(segmentationOfCurrentFrame(:,obj.LoadedMovie.Tracking.getCentroidXColumn ));
                obj.CurrentYOfCentroids =                       cell2mat(segmentationOfCurrentFrame(:,obj.LoadedMovie.Tracking.getCentroidYColumn ));
                obj.CurrentZOfCentroids =                       cell2mat(segmentationOfCurrentFrame(:,obj.LoadedMovie.Tracking.getCentroidZColumn));

                obj.ListOfAllPixels =                           cell2mat(segmentationOfCurrentFrame(:,obj.LoadedMovie.Tracking.getPixelListColumn));
                
                
                %% update list of pixels specifically for active track
                
                myCurrentTrackIDsAll =                            cell2mat(segmentationOfCurrentFrame(:,obj.LoadedMovie.Tracking.getTrackIDColumn)); 
                myRowOfActiveTrackAll =                           myCurrentTrackIDsAll == myIDOfActiveTrack ;         

                obj.ListOfAllActiveTrackPixels =                cell2mat(segmentationOfCurrentFrame(myRowOfActiveTrackAll,obj.LoadedMovie.Tracking.getPixelListColumn));

            
        end
        
         function obj =             addDriftCorrectionToCentroids(obj)
              
            CurrentFrame =                      obj.LoadedMovie.SelectedFrames(1);    
            CurrentColumnShift =                obj.LoadedMovie.AplliedColumnShifts(CurrentFrame);
            CurrentRowShift =                   obj.LoadedMovie.AplliedRowShifts(CurrentFrame);
            CurrentPlaneShift =                 obj.LoadedMovie.AplliedPlaneShifts(CurrentFrame);

            obj.CurrentXOfCentroids =           obj.CurrentXOfCentroids + CurrentColumnShift;
            obj.CurrentYOfCentroids =           obj.CurrentYOfCentroids + CurrentRowShift;
            obj.CurrentZOfCentroids =           obj.CurrentZOfCentroids + CurrentPlaneShift;
   
         end
        
       
           function obj =             setCentroidAndMovieData(obj)
             
                
                obj =                                               obj.setCentroidPositions;
                obj =                                               obj.addDriftCorrectionToCentroids;         

                obj =                                               obj.updateLoadedImageVolumes;

         end
         
            
          function obj =          resetActivePixelWithSegmentation(obj, Segmentation)
                
                obj.ActiveZCoordinate=              Segmentation.ActiveZCoordinate;
                obj.ActiveXCoordinate=              Segmentation.ActiveXCoordinate;
                obj.ActiveYCoordinate=              Segmentation.ActiveYCoordinate;
                  
                
          end
           
          
          

         function obj =         ensureCurrentImageFrameIsInMemory(obj)
             
             
             %% if the active movie controller has no image in memory, it needs to be loaded now(just load one frame), otherwise it should be there (it goes back to the same place where it came before)
                if isempty(obj.LoadedImageVolumes)
                     % reserve space for actual imaging data;
                    obj.LoadedImageVolumes =                      cell(obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints,1);
                    

                end
                
                if isempty(obj.LoadedImageVolumes{obj.LoadedMovie.SelectedFrames(1),1})
                    
                    PressedKey =                            obj.PressedKeyValue;  
                    PressedKeyAsciiCode=                    double(PressedKey);

                    %% pre-load single image: this prevents loading multiple frames when the current frame is empty;
                    if PressedKeyAsciiCode == 29 
                        obj.NumberOfLoadedFrames =                    40;

                    else
                        
                        obj.NumberOfLoadedFrames =                    0;

                    end
                    obj =                                         obj.updateLoadedImageVolumes;
                    
                    obj.enableAllViews;
                    
                    obj.NumberOfLoadedFrames =                    40;
                    
                    
                    
                end
                
                
                    
                
                
                
             
             
             
             
         end
         
       

         
         
        %% getters:
        
        

            function [yCoordinates, xCoordinates,planeWithoutDrift] =           getCoordinateListByMousePositions(obj)


                [ yStart, xStart,  planeStartWithoutDrift, frame ] =                obj.getCoordinatesOfButtonPress;
                [ yEnd, xEnd,  planeWithoutDrift, frame ] =                         obj.getCoordinatesOfCurrentMousePosition;


                Image(min([yStart,yEnd]):max([yStart,yEnd]),min([xStart,xEnd]):max([xStart,xEnd])) =              1;


                [yCoordinates, xCoordinates] =                                  find(Image==1);


            end

            
            
             function [rowFinal, columnFinal, planeFinal, frame] =               getUnverifiedCoordinatesOfCurrentMousePosition(obj)
           
                % get coordinates of button press in image (drift correction needst to be subtraced);
                frame =                                                             obj.LoadedMovie.SelectedFrames(1);
                planeRaw =                                                          obj.LoadedMovie.SelectedPlanes(1);
                rowRaw =                                                            obj.MouseUpRow;
                columnRaw =                                                         obj.MouseUpColumn;

                [columnFinal, rowFinal, planeFinal] =                               obj.LoadedMovie.removeDriftCorrection(columnRaw, rowRaw, planeRaw);
           
                rowFinal =                                                          round(rowFinal);
                columnFinal =                                                       round(columnFinal);
                planeFinal =                                                        round(planeFinal);


            end 
            
            function [rowFinal, columnFinal, planeFinal, frame] =               getCoordinatesOfCurrentMousePosition(obj)
           
                [rowFinal, columnFinal, planeFinal, frame] =               obj.getUnverifiedCoordinatesOfCurrentMousePosition;
                
               
                coordinatesAreWithinOriginalImageBounds =                           obj.verifyCoordinatesAreWithinBounds(rowFinal, columnFinal,planeFinal);
                if ~coordinatesAreWithinOriginalImageBounds
                    rowFinal = NaN;
                    columnFinal = NaN;
                    planeFinal = NaN;

                end

            end

            function [rowFinal, columnFinal, planeFinal, frame] =               getCoordinatesOfButtonPress(obj)

                frame =                                                 obj.LoadedMovie.SelectedFrames(1);
                planeRaw =                                              obj.LoadedMovie.SelectedPlanes(1);
                rowRaw =                                                obj.MouseDownRow;
                columnRaw =                                             obj.MouseDownColumn;

                [columnFinal, rowFinal, planeFinal] =                   obj.LoadedMovie.removeDriftCorrection(columnRaw, rowRaw, planeRaw);

                rowFinal =                                              round(rowFinal);
                columnFinal =                                           round(columnFinal);
                planeFinal =                                            round(planeFinal);

                coordinatesAreWithinOriginalImageBounds =               obj.verifyCoordinatesAreWithinBounds(rowFinal, columnFinal,planeFinal);
                if ~coordinatesAreWithinOriginalImageBounds
                    rowFinal = NaN;
                    columnFinal = NaN;
                    planeFinal = NaN;

                end

            end

            function [rowFinal, columnFinal, planeFinal, frame] =               getTrackingCoordinatesFromMousePosition(obj)


                if isnan(obj.LoadedMovie.IdOfActiveTrack)
                    [rowFinal, columnFinal, planeFinal, frame] = deal(NaN);
                else
                    
                    
                    
                    [rowFinal, columnFinal, planeFinal, frame] =   obj.getCoordinatesOfCurrentMousePosition;

                    rowFinal =          round(rowFinal);
                    columnFinal =       round(columnFinal);
                    planeFinal =        round(planeFinal);
                    frame =             round(frame);



                     if min(isnan([rowFinal, columnFinal, planeFinal, frame]))
                        [rowFinal, columnFinal, planeFinal, frame] = deal(NaN);
                     end

                     distanceFromPreviousMaskIsTooLarge =                  obj.LoadedMovie.checkWhetherButtonPressIsDistantFromPreviousMask(rowFinal, columnFinal, planeFinal);
                     if distanceFromPreviousMaskIsTooLarge
                          [rowFinal, columnFinal, planeFinal, frame] = deal(NaN);
                     end

                end


            end

            
             function [Rectangle] =               getRectangleFromMouseDrag(obj)
              
                [ StartRowAfterRemovingDrift, StartColumnAfterRemovingDrift,  ~, ~ ] =              obj.getCoordinatesOfButtonPress;
                [ EndRowAfterRemovingDrift, EndColumnAfterRemovingDrift,  ~, ~ ] =                  obj.getCoordinatesOfCurrentMousePosition;


                Width =                                                             EndColumnAfterRemovingDrift - StartColumnAfterRemovingDrift;
                Height =                                                            EndRowAfterRemovingDrift - StartRowAfterRemovingDrift;

                Rectangle =     [StartColumnAfterRemovingDrift, StartRowAfterRemovingDrift, Width, Height];
                
             end
             
            function [rowFinal, columnFinal, planeFinal, frame] =               getCoordinatesOfMouseDrag(obj)
            
                frame =                                                     obj.LoadedMovie.SelectedFrames(1);
                planeRaw =                                                  obj.LoadedMovie.SelectedPlanes(1);
                rowRaw =                                                    obj.MouseUpRow;
                columnRaw =                                                 obj.MouseUpColumn;
                
                [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =         obj.LoadedMovie.getCurrentDriftCorrectionValues;
                
                rowFinal =                                              round(rowRaw - CurrentRowShift);
                columnFinal =                                           round(columnRaw - CurrentColumnShift);
                planeFinal =                                            round(planeRaw - CurrentPlaneShift);

                coordinatesAreWithinOriginalImageBounds =               obj.verifyCoordinatesAreWithinBounds(rowFinal, columnFinal,planeFinal);
                if ~coordinatesAreWithinOriginalImageBounds
                    rowFinal = NaN;
                    columnFinal = NaN;
                    planeFinal = NaN;

                end
 
           end

            function [SelectedTrackIDs] =                                       getCurrentlySelectedTrackIDs(obj)

                % get trackIds that are selected in table List:
                ListView =                                              obj.TrackingViews.ListWithFilteredTracks;
                IndicesOfSelectedRows=                                  ListView.Value;
                
                ModelOfTrackDataForDisplay =                            obj.LoadedMovie.Tracking.Tracking; 
                if isnan(IndicesOfSelectedRows(1)) || max(IndicesOfSelectedRows) == 0
                    SelectedTrackIDs =                                  NaN;
                else
                    SelectedTrackIDs=                                   cell2mat(ModelOfTrackDataForDisplay(IndicesOfSelectedRows,2));

                end
            end


            function ImageVolume_Target =                                       extractCurrentRgbImage(obj)


            %% extract and process SourceImageVolume
            WantedFrame =                               obj.LoadedMovie.SelectedFrames(1);
            DriftPlanes=                                obj.LoadedMovie.SelectedPlanesForView;

            WantedPlanes =                              obj.LoadedMovie.convertInputPlanesIntoRegularPlanes(DriftPlanes);



            CompleteImageVolume =                       obj.LoadedImageVolumes{WantedFrame,1};
            %NumberChannelsOfImageSequence=      obj.LoadedMovie.MetaData.EntireMovie.NumberOfChannels;

            NumberOfRows=                               obj.LoadedMovie.MetaData.EntireMovie.NumberOfRows;
            NumberOfColumns=                            obj.LoadedMovie.MetaData.EntireMovie.NumberOfColumns;

            ListWithSelectedChannels =                  obj.LoadedMovie.SelectedChannels;
            RowsOfSelectedChannels =                    find(ListWithSelectedChannels);
            ListWithMinimumIntensities_Select =         obj.LoadedMovie.ChannelTransformsLowIn(ListWithSelectedChannels);
            ListWithMaximumIntensities_Select  =        obj.LoadedMovie.ChannelTransformsHighIn(ListWithSelectedChannels);
            ListWithChannelColors_Select =              obj.LoadedMovie.ChannelColors(ListWithSelectedChannels);

            % frst verify that format is correct:
            Is16Bit=            isa(CompleteImageVolume, 'uint16');
            Is8Bit=             isa(CompleteImageVolume, 'uint8');
            assert(Is16Bit || Is8Bit, 'Only 8-bit and 16-bit images supported')
            if Is16Bit
                Precision=      'uint16';
            else
                Precision=      'uint8';
            end


            % get source image (make maximum-projection along plane-dimension):
    CompleteImageVolume =                                              CompleteImageVolume(:,:,WantedPlanes,:,:);

            %% these two steps are the slowst: potentially this cannot be improved much (unless putting everything into memory) to me this is fast enough;
           
            
            
            ImageVolume_Source=                                                 max(CompleteImageVolume(:, :, :, :), [], 3); % make maximum projection of wanted image


            %% make target image:
            ImageVolume_Target=                                                     cast(0, Precision);
            ImageVolume_Target(NumberOfRows, NumberOfColumns, 3)=                   0;

             if isempty(ImageVolume_Source) % if no image remains: return black;
                return

            end


            % coloring: transfer source channels to correct target channel(s);
            for ChannelIndex= 1:length(RowsOfSelectedChannels) % go through all channels of image:

                %% get relevant info for current channel:
                CurrentChannelRow =                     RowsOfSelectedChannels(ChannelIndex);
                CurrentImage=                           ImageVolume_Source(:,:,:,CurrentChannelRow); 

                CurrentMin=                             ListWithMinimumIntensities_Select(ChannelIndex);
                CurrentMax=                             ListWithMaximumIntensities_Select(ChannelIndex);

                CurrentColor   =                        ListWithChannelColors_Select{ChannelIndex};


                %% process information:

                CurrentImage=                            imadjust(CurrentImage, [CurrentMin  CurrentMax], [0 1]);
                switch CurrentColor

                    case 'Red'
                        ImageVolume_Target(:,:,1)=    ImageVolume_Target(:,:,1)+CurrentImage;

                    case 'Green'
                        ImageVolume_Target(:,:,2)=    ImageVolume_Target(:,:,2)+CurrentImage;

                    case 'Blue'
                        ImageVolume_Target(:,:,3)=    ImageVolume_Target(:,:,3)+CurrentImage;

                    case 'Yellow'
                        ImageVolume_Target(:,:,1)=    ImageVolume_Target(:,:,1)+CurrentImage;
                        ImageVolume_Target(:,:,2)=    ImageVolume_Target(:,:,2)+CurrentImage;

                    case 'Magenta'
                        ImageVolume_Target(:,:,1)=    ImageVolume_Target(:,:,1)+CurrentImage;
                        ImageVolume_Target(:,:,3)=    ImageVolume_Target(:,:,3)+CurrentImage;

                    case 'Cyan'
                        ImageVolume_Target(:,:,2)=    ImageVolume_Target(:,:,2)+CurrentImage;
                        ImageVolume_Target(:,:,3)=    ImageVolume_Target(:,:,3)+CurrentImage;

                    case 'White'
                        ImageVolume_Target(:,:,1)=    ImageVolume_Target(:,:,1)+CurrentImage;
                        ImageVolume_Target(:,:,2)=    ImageVolume_Target(:,:,2)+CurrentImage;
                        ImageVolume_Target(:,:,3)=    ImageVolume_Target(:,:,3)+CurrentImage;

                end

            end



            end

            function [neededFrames] =                                           getFramesThatNeedToBeLoaded(obj)



            %% first check whether the current frame needs to be loaded:
            WantedTimeFrame =                                           obj.LoadedMovie.SelectedFrames(1); % currently this is just for one frame, to do this for multiple frames will be more complicated
            Range =                                                     obj.NumberOfLoadedFrames;  
            TotalFramesInMovie =                                        obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints;
            CurrentlyLoadedImageCell =                                  obj.LoadedImageVolumes;

            neededFrames(TotalFramesInMovie,1) = false;
            if ~isempty(CurrentlyLoadedImageCell{WantedTimeFrame,1})
                return
            end


            %% then get numbers before and after;
            range =                                                     WantedTimeFrame-Range:WantedTimeFrame+Range;
            range(range<=0) =                                           [];
            range(range>TotalFramesInMovie) =                           [];
            neededFrames(range,1) =                                     true;

            %% and remove all the frames that are currently already loaded:
            framesThatHaveTheMovieAlreadyLoaded =                           cellfun(@(x)  ~isempty(x),     CurrentlyLoadedImageCell);                  
            neededFrames(framesThatHaveTheMovieAlreadyLoaded,1) =           false;


            end

            function [rgbImage] =                                               addMasksToImage(obj, rgbImage)


                IntensityForRedChannel =                obj.MaskColor(1);
                IntensityForGreenChannel =              obj.MaskColor(2);
                IntensityForBlueChannel =               obj.MaskColor(3);

                CoordinateList =                        obj.ListOfAllPixels;


                NumberOfPixels =                        size(CoordinateList,1);
                if ~isnan(IntensityForRedChannel)
                    for CurrentPixel =  1:NumberOfPixels
                        rgbImage(CoordinateList(CurrentPixel,1),CoordinateList(CurrentPixel,2),1)= IntensityForRedChannel;
                    end
                end

                if ~isnan(IntensityForGreenChannel)
                    for CurrentPixel =  1:NumberOfPixels
                        rgbImage(CoordinateList(CurrentPixel,1),CoordinateList(CurrentPixel,2),2)= IntensityForGreenChannel;
                    end
                end

                if ~isnan(IntensityForBlueChannel)
                    for CurrentPixel =  1:NumberOfPixels


                        rgbImage(CoordinateList(CurrentPixel,1),CoordinateList(CurrentPixel,2),3)= IntensityForBlueChannel;
                    end
                end


                %% add mask specifically for activated track when mask is active;

                CoordinateListActive =                  obj.ListOfAllActiveTrackPixels;

                 NumberOfPixels =                        size(CoordinateListActive,1);

                  for CurrentPixel =  1:NumberOfPixels
                        rgbImage(CoordinateListActive(CurrentPixel,1),CoordinateListActive(CurrentPixel,2),1:3)= 255;
                  end

            end

            function [rgbImage] =                                               addActiveMaskToImage(obj, rgbImage)

               if ~obj.LoadedMovie.ActiveTrackIsHighlighted
                   return
               end

                        IntensityForRedChannel =                obj.MaskColorForActiveTrack(1);
                        IntensityForGreenChannel =              obj.MaskColorForActiveTrack(2);
                        IntensityForBlueChannel =               obj.MaskColorForActiveTrack(3);

                        CoordinateList =                        obj.ListOfAllActiveTrackPixels;


                        NumberOfPixels =                        size(CoordinateList,1);
                        if ~isnan(IntensityForRedChannel)
                            for CurrentPixel =  1:NumberOfPixels
                                rgbImage(CoordinateList(CurrentPixel,1),CoordinateList(CurrentPixel,2),1)= IntensityForRedChannel;
                            end
                        end

                        if ~isnan(IntensityForGreenChannel)
                            for CurrentPixel =  1:NumberOfPixels
                                rgbImage(CoordinateList(CurrentPixel,1),CoordinateList(CurrentPixel,2),2)= IntensityForGreenChannel;
                            end
                        end

                        if ~isnan(IntensityForBlueChannel)
                            for CurrentPixel =  1:NumberOfPixels


                                rgbImage(CoordinateList(CurrentPixel,1),CoordinateList(CurrentPixel,2),3)= IntensityForBlueChannel;
                            end
                        end





            end

     

            function  coordinatesAreWithinOriginalImageBounds =                         verifyCoordinatesAreWithinBounds(obj, rowFinal, columnFinal,planeFinal);


              maximumRows =     obj.LoadedMovie.MetaData.EntireMovie.NumberOfRows;
              maximumColumns =  obj.LoadedMovie.MetaData.EntireMovie.NumberOfColumns;
              maximumPlanes =   obj.LoadedMovie.MetaData.EntireMovie.NumberOfPlanes;

              coordinatesAreWithinOriginalImageBounds =       rowFinal>=1 && rowFinal<=maximumRows && columnFinal>=1 && columnFinal<=maximumColumns && planeFinal>=1 && planeFinal<=maximumPlanes;


            end

            
              function [ListWithAllViews] =                                       getListWithAllViews(obj)


                if isempty(obj.Views.Navigation)
                    ListWithAllViews =       cell(0,1);
                    return
                elseif isempty(obj.Views.Channels)
                    ListWithAllViews =       cell(0,1);
                    return
                end

                FieldNames =                fieldnames(obj.Views.Navigation);
                NavigationViews =           cellfun(@(x) obj.Views.Navigation.(x), FieldNames, 'UniformOutput', false);

                FieldNames =                fieldnames(obj.Views.Channels);
                ChannelViews =              cellfun(@(x) obj.Views.Channels.(x), FieldNames, 'UniformOutput', false);

                FieldNames =                fieldnames(obj.Views.Annotation);
                AnnotationViews =           cellfun(@(x) obj.Views.Annotation.(x), FieldNames, 'UniformOutput', false);

                FieldNames =                fieldnames(obj.TrackingViews);
                TrackingViewsInside =       cellfun(@(x) obj.TrackingViews.(x), FieldNames, 'UniformOutput', false);

                ListWithAllViews =          [NavigationViews; ChannelViews;AnnotationViews;TrackingViewsInside];

            end

           
            
         %% interactive tracking and autotracking
         function [obj] =                   updateActiveMaskByButtonClick(obj)
            

                [rowFinal, columnFinal, planeFinal, frame] =                        obj.getTrackingCoordinatesFromMousePosition;
                
                if ~isnan(rowFinal)
                    
                        obj.Views.MovieView.MainImage.CData(rowFinal,columnFinal,:) =       255;
                        
                        mySegmentationObject =                                              PMSegmentationCapture(obj, [rowFinal, columnFinal, planeFinal]);
                        mySegmentationObject =                                              mySegmentationObject.generateMaskByClickingThreshold;

                        [pixelTestSucceeded, explanation] =                                                mySegmentationObject.checkPixelList;

                        if pixelTestSucceeded % if the pixels are wrong, e.g. too large, do not use this pixels (do nothing); 
                            obj.LoadedMovie =                                                   obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                            obj =                                                               obj.setCentroidAndMovieData;
                            obj =                                                               obj.updateViewsAfterSegmentationChange;
                        else
                            explanation
                            
                        end


                end
 

         end
         
         
          function [obj] =                   removeHighlightedPixelsFromMask(obj)
             

                if isnan(obj.LoadedMovie.IdOfActiveTrack)
                    return
                end

                [yCoordinates, xCoordinates,z] =            getCoordinateListByMousePositions(obj);
                obj =                                       obj.highLightRectanglePixelsByMouse([yCoordinates, xCoordinates]);
                
                pixelList_Modified =                        obj.LoadedMovie.getPixelsFromActiveMaskAfterRemovalOf([yCoordinates,xCoordinates]);
                
                mySegementationCapture =                    PMSegmentationCapture(pixelList_Modified, 'Manual');
                obj.LoadedMovie =                           obj.LoadedMovie.resetActivePixelListWith(mySegementationCapture);

                obj =                                       obj.setCentroidAndMovieData;
                obj =                                       obj.updateViewsAfterSegmentationChange;

                
             
              
         end
         
         
         function obj =                     addHighlightedPixelsFromMask(obj)
             
             if isnan(obj.LoadedMovie.IdOfActiveTrack)
                 return
                 
             end
             
            [yCoordinates, xCoordinates,planeWithoutDrift] =        getCoordinateListByMousePositions(obj);
            obj =                                                   obj.highLightRectanglePixelsByMouse([yCoordinates, xCoordinates]);

            pixelList_Modified =                                    obj.LoadedMovie.getPixelsOfActiveTrackAfterAddingOf([yCoordinates,xCoordinates,(linspace(planeWithoutDrift,planeWithoutDrift,length(xCoordinates)))']);

            mySegementationCapture =                                PMSegmentationCapture(pixelList_Modified, 'Manual');
            obj.LoadedMovie =                                       obj.LoadedMovie.resetActivePixelListWith(mySegementationCapture);

            obj =                                                   obj.setCentroidAndMovieData;
            obj =                                                   obj.updateViewsAfterSegmentationChange;


         
         end
         
        
         function obj =                     addExtraPixelRowToCurrentMask(obj)
             
 
                mySegmentationObject =                 PMSegmentationCapture(obj);
                mySegmentationObject =                 mySegmentationObject.addRimToActiveMask;

                obj.LoadedMovie =                       obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                obj =                                   obj.setCentroidAndMovieData;
                obj =                                   obj.updateViewsAfterSegmentationChange;


                
         end
         
         
          function obj =                    removePixelRimFromCurrentMask(obj)
             
                mySegmentationObject =                 PMSegmentationCapture(obj);
                mySegmentationObject =                 mySegmentationObject.removeRimFromActiveMask;

                obj.LoadedMovie =                       obj.LoadedMovie.resetActivePixelListWith(mySegmentationObject);
                obj =                                   obj.setCentroidAndMovieData;
                obj =                                   obj.updateViewsAfterSegmentationChange;

                
          end
         
         
          function obj =                    autoDetectMasksOfCurrentFrame(obj)
              
              
              obj.ActiveZCoordinate =                                      obj.LoadedMovie.SelectedPlanes(1);
              CumulativePixelList =                                         zeros(0,3);
                 
              CountFailures =                                               0;
              
              while 1

                    %% get "cleaned" image where all previously tracked pixels are removed;
                    SegmentationObjOfCurrentFrame =                               PMSegmentationCapture(obj);
                    
                    SegmentationObjOfCurrentFrame.CurrentTrackId =            NaN; % have to do this to also exclude currently active track pixels;
                    PixelListOfCurrentCentroidsAndPreviousTries =            unique([SegmentationObjOfCurrentFrame.getAllPreviouslyTrackedPixels;CumulativePixelList], 'rows');
                        
                    [myCleanedImage] =                                        SegmentationObjOfCurrentFrame.removePixelsFromImage(PixelListOfCurrentCentroidsAndPreviousTries);
                  
                   
                    %% detect the brightest remaining spot in the image and add it to the cumulative list;
                    [xCoordinate,yCoordinate,coordinateList] =                    SegmentationObjOfCurrentFrame.detectBrightestAreaInImage(myCleanedImage, obj.MaskLocalizationSize);
                    CumulativePixelList =                                         [CumulativePixelList; coordinateList]; % remember positions that have been tried (avoid multiple tries);
                    
                   
                    
                   
                  
                     %% put the SegementationObject to work and let it calculate the "true next mask";
                     
                    SegmentationObjOfCurrentFrame.ActiveZCoordinate =             obj.ActiveZCoordinate;
                    SegmentationObjOfCurrentFrame.ActiveYCoordinate =             yCoordinate;
                    SegmentationObjOfCurrentFrame.ActiveXCoordinate =             xCoordinate;
                    
                    SegmentationObjOfCurrentFrame =                             SegmentationObjOfCurrentFrame.generateMaskByAutoThreshold;
                    
 
                    pixelTestSucceeded =                                        SegmentationObjOfCurrentFrame.checkPixelList;
                    if pixelTestSucceeded  
                        
                        % reset to new track ID:
                        newTrackID =                                            obj.LoadedMovie.findNewTrackID;
                        obj.LoadedMovie =                                       obj.LoadedMovie.setActiveTrackWith(newTrackID);
                        
                        % then add the pixels to the new track and update
                        % model and views:
                        obj.LoadedMovie =                                       obj.LoadedMovie.resetActivePixelListWith(SegmentationObjOfCurrentFrame);
                        obj =                                                   obj.resetActiveTrack;
                        
                        obj =                                                   obj.updateViewsAfterTrackSelectionChange;
                        obj =                                                   obj.updateViewsAfterSegmentationChange;
                       
                        
                        
                        drawnow
                        
                        
       
                    else %% if the pixels are supicious ignore and remember, stop after certain number of failures;

                          CountFailures = CountFailures + 1;
                          if CountFailures>=10
                            break 
                          else
                              continue
                           end
                        
                    end
                    
                  
                  
              end
              
                obj.LoadedMovie =                   obj.LoadedMovie.refreshTrackingResults;
                obj =                               obj.updateViewsAfterChangesInTracks;
                obj.PressedKeyValue  = '';

               
              
          end
          
          
          
          function obj =                    autoTrackCurrentCell(obj, SourceFrames, TargetFrames)
             
             
                    StopObject =                      obj.createStopButtonForAutoTracking;
                    ButtonHandle =                    StopObject.Button;
                    obj.PressedKeyValue =             'a';

                    %% perform tracking from current frame forward:
                    NumberOfFrames =     length(SourceFrames);
                    for FrameIndex = 1:NumberOfFrames
                    
                        sourceFrameNumber =                         SourceFrames(FrameIndex);
                        targetFrameNumber =                         TargetFrames(FrameIndex);
                    
                        [~,SegementationObjOfTargetFrame] =         obj.performTrackingBetweenTwoFrames(sourceFrameNumber, targetFrameNumber);
                        [pixelTestSucceeded, explanation] =                        SegementationObjOfTargetFrame.checkPixelList;

                        if ~pixelTestSucceeded || ~ishandle(ButtonHandle) %% if the pixels are supicious or the user closed the stop button: stop tracking;
                            explanation
                            break

                        else %% otherwise update model and views with new pixels;

                            obj.LoadedMovie =                           obj.LoadedMovie.resetActivePixelListWith(SegementationObjOfTargetFrame);
                            obj =                                       obj.setCentroidAndMovieData;
                            obj =                                       obj.updateViewsAfterSegmentationChange;

                            

                        end
                        
                        drawnow

                    end
                    drawnow
                    obj.LoadedMovie =               obj.LoadedMovie.refreshTrackingResults;
                    obj =                           obj.updateViewsAfterChangesInTracks;
                    obj.PressedKeyValue  =          '';
                    delete(StopObject.ParentFigure)
                    
          end
            
         
          
          function obj =                    autoTrackingWhenNoMaskInNextFrame(obj)
              
              
                TrackingStartFrame =                    obj.LoadedMovie.SelectedFrames(1);
                TrackingEndFrame =                      obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints - 1;
                TrackingFrames =                        TrackingStartFrame:TrackingEndFrame;
                TargetFrames =                          TrackingFrames + 1;

                TrackIDsForTracking =                 obj.LoadedMovie.getTrackIDsWhereNextFrameHasNoMask;
                NumberOfTracks =                      size(TrackIDsForTracking,1);

                  for TrackIDIndex = 1:NumberOfTracks

                        % rest track, update model and views:
                        obj =                           obj.resetFrame(TrackingStartFrame);  
                        CurrentTrackID =                TrackIDsForTracking(TrackIDIndex,1);
                        
                        obj.LoadedMovie =               obj.LoadedMovie.setActiveTrackWith(CurrentTrackID);
                        obj =                           obj.resetActiveTrack;
                        obj =                           obj.updateViewsAfterTrackSelectionChange;
                        drawnow
                        
                        % perform tracking on new track:
                        obj =                           obj.autoTrackCurrentCell(TrackingFrames,TargetFrames);


                  end
              
          end
         
          
          
          function StopObject =            createStopButtonForAutoTracking(obj)
                 %% create a stop-button: its only function is to let the user stop the tracking when something goes wrong;
                MyFigure = figure;
                MyFigure.MenuBar = 'none';
                MyFigure.Position = [40 630 100 50 ];


                ButtonHandle = uicontrol(MyFigure,'Style', 'PushButton', ...
                'String', 'Stop tracking', ...
                'Callback', 'delete(gcbf)');

                ButtonHandle.Units = 'normalized';
                ButtonHandle.Position = [ 0 0 1 1 ];

                StopObject.ParentFigure = MyFigure;
                StopObject.Button = ButtonHandle;

              
              
          end
          
          
          function [SegmentationObjOfSourceFrame,SegementationObjOfTargetFrame] =                    performTrackingBetweenTwoFrames(obj,sourceFrameNumber,targetFrameNumber)
              
              
                    %% get segmentation object of current frame:
                    obj =                                                       obj.resetFrame(sourceFrameNumber);
                    SegmentationObjOfSourceFrame =                              PMSegmentationCapture(obj);
                    
                    
                    %% get segmentation object of next frame (use "current mask" as a foundation for getting the "tru next mask");
                    % getting the masks of the previous frame is the key step here: it mediates tracking by "overlap" to a degree;
                    obj =                                                           obj.resetFrame(targetFrameNumber);
                    SegementationObjOfTargetFrame =                               PMSegmentationCapture(obj);    
                    SegementationObjOfTargetFrame.MaskCoordinateList =            SegmentationObjOfSourceFrame.MaskCoordinateList;
                    SegementationObjOfTargetFrame.CurrentTrackId =                obj.LoadedMovie.IdOfActiveTrack; % not sure if this is necessary

                   
                    %% put the SegementationObject to work and let it calculate the "true next mask";
                    SegementationObjOfTargetFrame =                             SegementationObjOfTargetFrame.setActiveCoordinateByBrightestPixels;
                    SegementationObjOfTargetFrame =                             SegementationObjOfTargetFrame.generateMaskByAutoThreshold;
                    
                    
                     
                    
              
          end
              
              
              

         
        
       
            
        
        %% respond to user input:
       
        function [obj] =    interpretKey(obj,PressedKey,CurrentModifier)
            
            %% extract relevant information from model:
            
            myEditingActivityString =                     obj.LoadedMovie.EditingActivity;
            
            obj.PressedKeyValue =                       PressedKey;  
            PressedKeyAsciiCode=                        double(PressedKey);    % convert to numbers for "non-characters" like left and right key
            PressedKeyNumber =                          str2double(PressedKey);
               
            
            %% interpret keys and reset when appropriate
            switch PressedKeyAsciiCode


                %% navigation:
                case 28 % left 
                    CurrentFrame =                          obj.LoadedMovie.SelectedFrames;
                    if CurrentFrame> 1
                        obj =                       obj.resetFrame(CurrentFrame - 1);
                        
                    end

                case 29 %right 
                    
                    MaximumFrame=                           obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints;
                    CurrentFrame =                          obj.LoadedMovie.SelectedFrames;
                    if CurrentFrame< MaximumFrame
                        obj =                       obj.resetFrame(CurrentFrame + 1);
                    else
                        obj.LoadedMovie.SelectedFrames = 1;
                        obj =                       obj.resetFrame( 1);
                    end


                case 30 % up 
                     CurrentPlane =                          obj.LoadedMovie.SelectedPlanes;
                    if CurrentPlane> 1
                        [obj]  = obj.resetPlane(CurrentPlane - 1);
                       
                    end

                case 31 %down
                     CurrentPlane =                          obj.LoadedMovie.SelectedPlanes;
                      MaximumPlane=                           obj.LoadedMovie.MetaData.EntireMovie.NumberOfPlanes + max(obj.LoadedMovie.AplliedPlaneShifts);
                    if CurrentPlane< MaximumPlane  
                        [obj]  = obj.resetPlane(CurrentPlane + 1);
                    end

            end

            
            switch PressedKey
                
                    case 'x'  %% navigation shortcuts: first frame, last/ first tracked frame:
                            obj =                       obj.resetFrame(1);
 
                            
                    case 'd' 

                        lastTrackedFrame =                  obj.LoadedMovie.getLastTrackedFrame('up');
                        if ~isnan(lastTrackedFrame)
                            obj =                           obj.resetFrame(lastTrackedFrame);
                        end
                    
                    
                    case 'g'

                        lastTrackedFrame =                 obj.LoadedMovie.getLastTrackedFrame('down');
                        if ~isnan(lastTrackedFrame)
                            obj =                           obj.resetFrame(lastTrackedFrame);
                        end

                        
                    case 'm' % maximum-projection toggle

                        PlanesShouldBeCollapsed =                                   ~obj.Views.Navigation.ShowMaxVolume.Value;
                        obj.LoadedMovie.CollapseAllPlanes =                         PlanesShouldBeCollapsed;
                        obj.LoadedMovie =                                           obj.LoadedMovie.resetViewPlanes;
                        obj =                                                       obj.setCentroidAndMovieData;

                        obj.Views.Navigation.ShowMaxVolume.Value =                  PlanesShouldBeCollapsed;
                        obj =                                                       obj.updateImageView;  
                        obj =                                                       obj.updateImageHelperViews;

                    case 'o' % crop-toggle

                        % apply new cropping to model
                        NewCroppingState =                                              ~obj.Views.Navigation.CropImageHandle.Value;
                        
                         obj.LoadedMovie =                                              obj.LoadedMovie.setCroppingStateTo(NewCroppingState);
                        obj =                                                           obj.resetViewsForCurrentCroppingState;
                        
                      
                       
                    case {'1', '2', '3', '4', '5', '6', '7', '8', '9'} % channel toggle

                        if obj.Views.Figure.CurrentObject == obj.Views.MovieView.MainImage % do this only when on image (otherwise this gets always activated)

                            NumberOfChannels =                      obj.LoadedMovie.MetaData.EntireMovie.NumberOfChannels;
                            if PressedKeyNumber <= NumberOfChannels

                                % update model:
                                IndexOfEditedChannel=                                           PressedKeyNumber;
                                ChannelShouldBeOn =                                             ~obj.LoadedMovie.SelectedChannels(IndexOfEditedChannel,1);
                                obj.LoadedMovie.SelectedChannels(IndexOfEditedChannel,1)=       ChannelShouldBeOn;
                                obj.LoadedMovie.SelectedChannelForEditing =                     IndexOfEditedChannel;

                                % update views:
                                obj =                                                           obj.updateChannelSettingView;
                                obj =                                                           obj.updateImageView;  


                            end

                        end

                    
                    case 'i'   %% toggle annotations

                        TimeShouldBeVisible =                       ~obj.LoadedMovie.TimeVisible;
                        obj.LoadedMovie.TimeVisible =               TimeShouldBeVisible;
                        obj =                                       obj.updateAnnotationViews; 

                        
                    case 'z'

                        PlanesShouldBeVisible=                          ~obj.LoadedMovie.PlanePositionVisible;
                        obj.LoadedMovie.PlanePositionVisible =      PlanesShouldBeVisible
                        obj =                                       obj.updateAnnotationViews; 

                        
                    case 's'

                         NumberOfModifers = length(CurrentModifier);
                         switch NumberOfModifers

                             case 0
                                 ScaleBarShouldBeVisible =                  ~obj.Views.Annotation.ShowScaleBar.Value;
                                obj.LoadedMovie.ScaleBarVisible =        	ScaleBarShouldBeVisible;
                                obj =                                       obj.updateAnnotationViews; 
                                obj =                                       obj.updateImageHelperViewsMore;



                             

                         end
                

                    case 'c' %% toggle centroids, masks, tracks
                     
                        CentroidsShouldBeVisible =                         ~obj.LoadedMovie.CentroidsAreVisible;
                        obj.LoadedMovie.CentroidsAreVisible =           CentroidsShouldBeVisible;
                        obj =                                            obj.updateCentroidVisibility;  
                        

                    case 'a'
                   
                        MasksShouldBeVisible =                               ~obj.LoadedMovie.MasksAreVisible;
                        obj.LoadedMovie.MasksAreVisible =                    MasksShouldBeVisible  ; 
                        obj =                                                   obj.updateMaskVisibility;
                   

                    case 't'

                        TracksShouldBeVisible =                     ~obj.LoadedMovie.TracksAreVisible;
                        
                        obj.LoadedMovie.TracksAreVisible =          TracksShouldBeVisible;
                        obj =                                       obj.updateTrackVisibility;


                    case 'u' %% update tracks, scroll through tracks
                        
                            obj.LoadedMovie =           obj.LoadedMovie.refreshTrackingResults;
                            obj =                       obj.updateViewsAfterChangesInTracks;  
                            
        
                    case 'n'

                        % select "next track" in track list-table:
                        IndexChange =                                   1;
                        obj =                                           obj.resetIndexOfTrackListView(IndexChange);
                        obj =                                           obj.changActiveTrackByTableView;
                        
                       
                    case 'p'

                        % select "previous track" in track list-table:
                       IndexChange =                                   -1;
                        obj =                                           obj.resetIndexOfTrackListView(IndexChange);
                        obj =                                           obj.changActiveTrackByTableView;
                        
                
                    case 'f' %% tracking shortcuts


                        if strcmp(myEditingActivityString, 'Tracking')
                            obj =   obj.autoDetectMasksOfCurrentFrame;
                        end

                    case 'l' 

                         if strcmp(myEditingActivityString, 'Tracking')
                            obj =   obj.autoTrackingWhenNoMaskInNextFrame;
                        end

                    case 'r' 

                        if strcmp(myEditingActivityString, 'Tracking')


                            [SourceFrames,TargetFrames] =           obj.LoadedMovie.getFramesForTracking('forward');
                            obj =                                   obj.autoTrackCurrentCell(SourceFrames,TargetFrames);

                        end

                    case 'v' 

                        if strcmp(myEditingActivityString, 'Tracking')

                            [SourceFrames,TargetFrames] =           obj.LoadedMovie.getFramesForTracking('backward');
                            obj =                                   obj.autoTrackCurrentCell(SourceFrames,TargetFrames);

                        end

                    case 'b' 

                         if strcmp(myEditingActivityString, 'Tracking')
                            obj =                                   obj.addExtraPixelRowToCurrentMask;
                         end

                    case 'e' 

                        if strcmp(myEditingActivityString, 'Tracking')
                            obj =                                   obj.removePixelRimFromCurrentMask;
                        end



           end
            
           
            obj.PressedKeyValue = '';
                
        end
        
                  
          
         
        %% main view:
            

        % centroid line, image
        function obj =                  updateImageView(obj)
            

            % update views that are directly within image area:
            obj =                                                                   obj.setViewsForCurrentEditingActivity;
            obj =                                                                   obj.updateAnnotationViews;
            
            obj.Views.MovieView.CentroidLine.XData =                                obj.CurrentXOfCentroids;
            obj.Views.MovieView.CentroidLine.YData =                                obj.CurrentYOfCentroids;

            obj =                                                                   obj.updatePositionOfActiveTrackHighlight;
            obj =                                                                   obj.updateManualDriftCorrectionView;

            
            % update pixels of image (channel specific, with masks etc.):
            obj.enableAllViews;
            obj =                                                                   obj.shiftImageByDriftCorrection;
            
            
            if obj.LoadedMovie.FileCouldNotBeRead
                error('File could not be read')
                return
            end
            
            rgbImage =                                                              obj.extractCurrentRgbImage; % this is by far the slowest component (but ok): consider changing;
            if obj.LoadedMovie.MasksAreVisible && ~isempty(obj.ListOfAllPixels)
                obj.ListOfAllPixels(isnan(obj.ListOfAllPixels(:,1)),:) =            [];
                rgbImage =                                                          obj.addMasksToImage(rgbImage);
            end
            
            
            
           
            rgbImage =                                                              obj.addActiveMaskToImage(rgbImage);
            obj.Views.MovieView.MainImage.CData=                                    rgbImage;
            
            obj.Views.MovieView.ViewMovieAxes.Color =                           [0.1 0.1 0.1];
            
             if obj.LoadedMovie.ActiveTrackIsHighlighted 
                     
                 
                 segmentationOfActiveTrack  =               obj.LoadedMovie.getSegmentationOfActiveTrack;
                 if isempty(segmentationOfActiveTrack)
                    return 
                 end
                 
                SegmentationInfoOfActiveTrack = segmentationOfActiveTrack{1,7};
                if ischar(SegmentationInfoOfActiveTrack.SegmentationType)
                   return 
                end
                SegmentationInfoOfActiveTrack.SegmentationType.highLightAutoEdgeDetection(obj.Views.MovieView.MainImage);

             end
             

        end
        
        % time/ Z/ scale
        function obj =                              updateAnnotationViews(obj)
            % update annotation within image view:
            
          
            
            
            switch obj.LoadedMovie.TimeVisible
                  
                  case 1
                      obj.Views.MovieView.TimeStampText.Visible = 'on';
                  otherwise
                      obj.Views.MovieView.TimeStampText.Visible = 'off';
                      
            end
            
            switch obj.LoadedMovie.PlanePositionVisible
                  
                  case 1
                      obj.Views.MovieView.ZStampText.Visible = 'on';
                  otherwise
                      obj.Views.MovieView.ZStampText.Visible = 'off';
                      
            end
              
             switch obj.LoadedMovie.ScaleBarVisible
                  
                  case 1
                      
                      
                      obj.Views.MovieView.ScalebarText.Units = 'centimeters';
                      obj.Views.MovieView.ScalebarText.Visible = 'on';
                      
                      
                       
                      obj.Views.MovieView.ViewMovieAxes.Units =     'centimeters';
                      AxesWidthCentimeter =                         obj.Views.MovieView.ViewMovieAxes.Position(3);
                      AxesHeightCentimeter =                        obj.Views.MovieView.ViewMovieAxes.Position(4);
                      
                      
                     
                      
                      obj.Views.MovieView.ViewMovieAxes.Units =     'pixels';
                      
          
                    
                      WantedLeftPosition =                          obj.Views.MovieView.ScalebarText.Position(1);
                      WantedCentimeters =                           0.9;
                      
                
                      RelativeLeftPosition =        WantedLeftPosition/AxesWidthCentimeter;
                      AxesWidthPixels =                 diff(obj.Views.MovieView.ViewMovieAxes.XLim);
                      XLimWidth =                   AxesWidthPixels * RelativeLeftPosition;
                      XLimStart =                   obj.Views.MovieView.ViewMovieAxes.XLim(1);
                     XLimMiddleBar =  XLimStart + XLimWidth;
                      
                    
                   
                      
                      AxesHeightPixels =           diff(obj.Views.MovieView.ViewMovieAxes.YLim);
                      
                      
                       if AxesWidthPixels>AxesHeightPixels
                           RealAxesHeightCentimeter = AxesHeightCentimeter * AxesHeightPixels/ AxesWidthPixels;
                           
                       else
                           RealAxesHeightCentimeter = AxesHeightCentimeter;
                           
                       end
                     

                      PixelsPerCentimeter =              AxesHeightPixels/RealAxesHeightCentimeter;
                      PixelsForWantedCentimeters =      PixelsPerCentimeter * WantedCentimeters;
                      YLimStart =                       obj.Views.MovieView.ViewMovieAxes.YLim(2)-PixelsForWantedCentimeters;
                     
                      
                      
                      
                        
                      if isfield(obj.Views.Annotation, 'SizeOfScaleBar')
                        LengthInMicrometer = obj.Views.Annotation.SizeOfScaleBar.Value;
                      else
                          LengthInMicrometer = 50;
                      end
                      
                      VoxelSizeXuM = obj.LoadedMovie.MetaData.EntireMovie.VoxelSizeX * 10^6;
                      
                      XRange = obj.Views.MovieView.ViewMovieAxes.XLim(2)- obj.Views.MovieView.ViewMovieAxes.XLim(1);
                      YRange = obj.Views.MovieView.ViewMovieAxes.YLim(2) - obj.Views.MovieView.ViewMovieAxes.YLim(1);
                      
                      YPosition = YRange*0.95 + obj.Views.MovieView.ViewMovieAxes.YLim(1);
                      XPosition =   XRange * 0.95 + obj.Views.MovieView.ViewMovieAxes.XLim(1);
                      
                      LengthInPixels = LengthInMicrometer / VoxelSizeXuM;
                      
                      
                      obj.Views.MovieView.ScaleBarLine.Marker = 'none';
                      obj.Views.MovieView.ScaleBarLine.XData = [(XLimMiddleBar - LengthInPixels/2), (XLimMiddleBar +  LengthInPixels/2) ];
                      obj.Views.MovieView.ScaleBarLine.YData = [ YLimStart,YLimStart];
                      obj.Views.MovieView.ScaleBarLine.Visible = 'on';
                   
                      
                 otherwise
                      
                      obj.Views.MovieView.ScalebarText.Visible = 'off';
                      obj.Views.MovieView.ScaleBarLine.Visible = 'off';
                      
             end
              
            
             
              obj.Views.MovieView.ZStampText.String =             obj.LoadedMovie.ListWithPlaneStamps{obj.LoadedMovie.SelectedPlanes(1)};
            obj.Views.MovieView.TimeStampText.String =          obj.LoadedMovie.ListWithTimeStamps{obj.LoadedMovie.SelectedFrames};
            obj.Views.MovieView.ScalebarText.String =           obj.LoadedMovie.ScalebarStamp;

          
            
        end
        
          
        % axes:
        function obj =                              resetLimitsOfImageAxesWithAppliedCroppingGate(obj)

                currentAppliedCroppingGate =                        obj.LoadedMovie.AppliedCroppingGate;

                %% process data:
                XLimit(1) =                                              currentAppliedCroppingGate(1) ;     
                XLimit(2) =                                              currentAppliedCroppingGate(1)   + currentAppliedCroppingGate(3);

                YLimit(1) =                                              currentAppliedCroppingGate(2) ;     
                YLimit(2) =                                              currentAppliedCroppingGate(2)   + currentAppliedCroppingGate(4);


                %% apply data:
                obj.Views.MovieView.ViewMovieAxes.XLim =        [min(XLimit), max(XLimit)];
                obj.Views.MovieView.ViewMovieAxes.YLim =        [min(YLimit), max(YLimit)];
                
               
           end
        
      
           
        function obj =                              resetAxesCenter(obj, xShift, yShift)
             
             obj.Views.MovieView.ViewMovieAxes.XLim = obj.Views.MovieView.ViewMovieAxes.XLim - xShift;
             obj.Views.MovieView.ViewMovieAxes.YLim = obj.Views.MovieView.ViewMovieAxes.YLim - yShift;
             
             
        end
        
        
        function [obj] =                            resetWidthOfMovieAxesToMatchAspectRatio(obj)
            
            XLength =                                           obj.Views.MovieView.ViewMovieAxes.XLim(2)- obj.Views.MovieView.ViewMovieAxes.XLim(1);
            YLength =                                           obj.Views.MovieView.ViewMovieAxes.YLim(2)- obj.Views.MovieView.ViewMovieAxes.YLim(1);
            LengthenFactorForX =                                XLength/  YLength;
            obj.Views.MovieView.ViewMovieAxes.Position(3) =     obj.Views.MovieView.ViewMovieAxes.Position(4) * LengthenFactorForX;
            
        end
        
        
        % image-pixels
        
        function obj =                              shiftImageByDriftCorrection(obj)


            [rowsInImage, columnsInImage, planesInImage] =              obj.LoadedMovie.getImageDimensions;

            CurrentFrame =                                              obj.LoadedMovie.SelectedFrames(1);    
            CurrentColumnShift=                                         obj.LoadedMovie.AplliedColumnShifts(CurrentFrame);
            CurrentRowShift =                                           obj.LoadedMovie.AplliedRowShifts(CurrentFrame);
            CurrentPlaneShift =                                         obj.LoadedMovie.AplliedPlaneShifts(CurrentFrame);

            obj.Views.MovieView.MainImage.XData =                       [1+  CurrentColumnShift, columnsInImage + CurrentColumnShift];
            obj.Views.MovieView.MainImage.YData =                       [1+  CurrentRowShift, rowsInImage + CurrentRowShift];




        end


        function obj =                              highLightActivePixel(obj)


        obj.Views.MovieView.MainImage.CData(round(obj.ActiveYCoordinate),(obj.ActiveXCoordinate),:) = 255;


        end



        function [obj] =                            highLightRectanglePixelsByMouse(obj,coordinates)

        TrackingViewChannel =                                          1;

        yCoordinates =                                                 coordinates(:,1);
        xCoordinates =                                                 coordinates(:,2);



        obj.Views.MovieView.MainImage.CData(:,:,TrackingViewChannel) =                  0;
        obj.Views.MovieView.MainImage.CData( round(min([yCoordinates]):max([yCoordinates])),round(min(xCoordinates):max(xCoordinates)),TrackingViewChannel) = 200;


        end


        function [obj] =                            updateCroppingLimitView(obj)

        %% read data

        MyCroppingGate=                                 obj.LoadedMovie.CroppingGate;

        CurrentFrame =                                  obj.LoadedMovie.SelectedFrames(1);    
        CurrentColumnShift=                             obj.LoadedMovie.AplliedColumnShifts(CurrentFrame);
        CurrentRowShift=                                obj.LoadedMovie.AplliedRowShifts(CurrentFrame);
        CurrentPlaneShift =                             obj.LoadedMovie.AplliedPlaneShifts(CurrentFrame);

        %% calculate new cropping gate as to be shown (with drift correction)
        StartColumn=                                    MyCroppingGate(1) + CurrentColumnShift;
        StartRow=                                       MyCroppingGate(2) + CurrentRowShift;
        Width=                                          MyCroppingGate(3);
        Height=                                         MyCroppingGate(4);


        %% apply data to view:
        MyRectangleView =                               obj.Views.MovieView.Rectangle;
        MyRectangleView.Visible =                       'on';
        MyRectangleView.YData=                          [StartRow      StartRow              StartRow+Height     StartRow+Height  StartRow];
        MyRectangleView.XData=                          [StartColumn   StartColumn+Width     StartColumn+Width   StartColumn       StartColumn];
        MyRectangleView.Color =                         'w';


        end

        % drift marker:
        function [obj] =                            updateManualDriftCorrectionView(obj)

            % update marker for manual drift correction:
            CurrentFrame =                                                         obj.LoadedMovie.SelectedFrames(1);



            [xWithDrift, yWithDrift, PlaneWithDrifCorrection ] =                    obj.LoadedMovie.addDriftCorrection(obj.LoadedMovie.DriftCorrection.ManualDriftCorrectionValues(CurrentFrame,2), obj.LoadedMovie.DriftCorrection.ManualDriftCorrectionValues(CurrentFrame,3), obj.LoadedMovie.DriftCorrection.ManualDriftCorrectionValues(CurrentFrame,4));


            obj.Views.MovieView.ManualDriftCorrectionLine.XData =                   xWithDrift;
            obj.Views.MovieView.ManualDriftCorrectionLine.YData =                   yWithDrift;


            if ismember(obj.LoadedMovie.SelectedPlanes,PlaneWithDrifCorrection )
                obj.Views.MovieView.ManualDriftCorrectionLine.LineWidth =           3;
            else
                obj.Views.MovieView.ManualDriftCorrectionLine.LineWidth =          1;
            end

        end

          
        % centroid line:
         function obj =                              updatePositionOfActiveTrackHighlight(obj)
            
              myIDOfActiveTrack =                                 obj.LoadedMovie.IdOfActiveTrack;
             myRowOfActiveTrack =                             obj.CurrentTrackIDs == myIDOfActiveTrack ;

           
            if sum(myRowOfActiveTrack) == 0
                obj.Views.MovieView.CentroidLine_SelectedTrack.XData =      NaN;
                obj.Views.MovieView.CentroidLine_SelectedTrack.YData =      NaN;
                
            else
                obj.Views.MovieView.CentroidLine_SelectedTrack.XData =      obj.CurrentXOfCentroids(myRowOfActiveTrack);
                obj.Views.MovieView.CentroidLine_SelectedTrack.YData =      obj.CurrentYOfCentroids(myRowOfActiveTrack);

            end
         end
           
        
          function obj =                              updateHighlightingOfActiveTrack(obj)
            
              ActiveTrackShouldBeHighlighted =                                      obj.LoadedMovie.ActiveTrackIsHighlighted;
              
               obj.TrackingViews.ActiveTrack.Value =                                ActiveTrackShouldBeHighlighted;
               if isnan(obj.LoadedMovie.IdOfActiveTrack)
                   obj.Views.MovieView.CentroidLine_SelectedTrack.Visible =         false;
                    
               else
                   obj.Views.MovieView.CentroidLine_SelectedTrack.Visible =         ActiveTrackShouldBeHighlighted;
                   
               end
               
                

          end
           
        %% main image and helper views:
        
         function obj =                 resetViewsForCurrentDriftCorrection(obj)
            
            obj =                       obj.resetLimitsOfImageAxesWithAppliedCroppingGate; % reset applied cropping limit (dependent on drift correction)
            obj =                       obj.shiftImageByDriftCorrection; % reset image shift (dependent on drift correction)
            obj =                       obj.initializeHelperViewRanges; % plane number may change
            obj =                       obj.updateCroppingLimitView; % crop position may change
            
            obj =                       obj.updateImageView;  % centroid position may may change;
            obj =                       obj.updateViewsAfterChangesInTracks; % change drift correction of tracks
            obj =                       obj.updateImageHelperViews; % plane number may change
            obj =                       obj.updateImageHelperViewsMore; % drift setting may change
             obj =                      obj.updateAnnotationViews;  % adjust position of annotation within views
            
            
          
              
         end
        
         function obj =     resetViewsForCurrentCroppingState(obj)
             
            obj =                       obj.resetLimitsOfImageAxesWithAppliedCroppingGate; % reset applied cropping limit (dependent on drift correction)
            obj =                       obj.updateCroppingLimitView; % crop position may change
            obj =                       obj.updateAnnotationViews;  % adjust position of annotation within views
            obj =                       obj.updateImageHelperViewsMore;

         end
        

         function obj =                 setViewsForCurrentEditingActivity(obj)
               
               SelectedString =                                     obj.LoadedMovie.EditingActivity;
               PossibleActivities =                                 obj.LoadedMovie.AllPossibleEditingActivities;
               
               SelectedIndex =                                      find(strcmp(SelectedString, PossibleActivities));
               
               obj.Views.Navigation.EditingOptions.Value =          SelectedIndex;

                switch SelectedIndex
                
                    case 1 % 'Visualize'
                        obj.Views.MovieView.ManualDriftCorrectionLine.Visible = 'off';
                       

                    case 2
                        obj.Views.MovieView.ManualDriftCorrectionLine.Visible = 'on';
                       

                    case 3 %  'Tracking: draw mask'
                        obj.Views.MovieView.ManualDriftCorrectionLine.Visible = 'off';
                        

                end
               
               
               
               
           end
        
       
        function obj =                  updateViewsAfterSegmentationChange(obj)
                                                         
           
            obj =                                                               obj.updateImageView;  
            obj =                                                               obj.updateSaveStatusView;

            
        end
     
        
        function [obj] =                updateViewsAfterTrackSelectionChange(obj)
            
             
                NewTrackID =                                            obj.LoadedMovie.IdOfActiveTrack;
                obj.TrackingViews.ActiveTrack.String =                  num2str(NewTrackID);

                 obj =                                                   obj.updateImageView;  
                 obj =                                                   obj.updateImageHelperViews;
               
                obj =                                                   obj.updatePositionOfActiveTrackHighlight;
               
                obj =                                                   obj.updateTrackView; % drawn tracks in image view

                obj =                                                   obj.updateCroppingLimitView;
                obj =                                                   obj.resetLimitsOfImageAxesWithAppliedCroppingGate;
               
            
        end
        
        

        %% helper views (navigation and channel) 
        
        function obj =                  updateImageHelperViews(obj)
            
           %% update helper views:
           
           if isempty(obj.Views.Navigation) % only set when this actually an object (the controller can be used without these views);
                return
            end
           
             obj.Views.Navigation.CurrentPlane.Value =           obj.LoadedMovie.SelectedPlanes;
             obj.Views.Navigation.CurrentTimePoint.Value =       obj.LoadedMovie.SelectedFrames;  
           
            
        end
       
        
          function obj =                  updateImageHelperViewsMore(obj)
              
              
               NewCroppingState =                                   obj.LoadedMovie.CroppingOn;
              
                obj =                                               obj.updateImageHelperViews;
                
                obj.Views.Navigation.ShowMaxVolume.Value =          obj.LoadedMovie.CollapseAllPlanes ;
                obj.Views.Navigation.ApplyDriftCorrection.Value =   obj.LoadedMovie.DriftCorrectionOn;
                obj.Views.Navigation.CropImageHandle.Value =                    NewCroppingState;
                
                obj.Views.Annotation.ShowScaleBar.Value =           obj.LoadedMovie.ScaleBarVisible;
              
                
                
                
          end
        
          function obj =                  initializeHelperViewRanges(obj)
            
            obj.Views.Navigation.CurrentTimePoint.String =          1:obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints; 
            [~, ~, planes ] =                                       obj.LoadedMovie.getImageDimensionsWithAppliedDriftCorrection;
            obj.Views.Navigation.CurrentPlane.String =              1:planes;
            
             obj.Views.Channels.SelectedChannel.String =            1:obj.LoadedMovie.MetaData.EntireMovie.NumberOfChannels;
            
             
           
             if obj.Views.Navigation.CurrentTimePoint.Value<1 || obj.Views.Navigation.CurrentTimePoint.Value>length(obj.Views.Navigation.CurrentTimePoint.String)
                 obj.Views.Navigation.CurrentTimePoint.Value = 1;
             end
             
              if obj.Views.Navigation.CurrentPlane.Value<1 || obj.Views.Navigation.CurrentPlane.Value>length(obj.Views.Navigation.CurrentPlane.String)
                 obj.Views.Navigation.CurrentPlane.Value = 1;
              end
             
              if obj.Views.Channels.SelectedChannel.Value<1 || obj.Views.Channels.SelectedChannel.Value>length(obj.Views.Channels.SelectedChannel.String)
                 obj.Views.Channels.SelectedChannel.Value = 1;
             end

              obj.Views.Navigation.TimeSlider.Min =                 1;
              obj.Views.Navigation.TimeSlider.Max =                 obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints;  
              %obj.Views.Navigation.TimeSlider.Value =               obj.Views.Navigation.CurrentTimePoint.Value;
              
              Range = obj.Views.Navigation.TimeSlider.Max -   obj.Views.Navigation.TimeSlider.Min;
              if Range == 0
                obj.Views.Navigation.TimeSlider.Visible = 'off';
              else
                  
                  Step =     1/ (Range);
                  obj.Views.Navigation.TimeSlider.Visible = 'on';
                  obj.Views.Navigation.TimeSlider.SliderStep = [Step Step];
              end
              

             
         end
       

        function obj =                  updateChannelSettingView(obj)
        
            PossibleColors =                                            obj.Views.Channels.Color.String;
            EditedChannelNumber =                                       obj.LoadedMovie.SelectedChannelForEditing;
         
            obj.Views.Channels.SelectedChannel.Value =                  EditedChannelNumber;
            obj.Views.Channels.MinimumIntensity.String =                obj.LoadedMovie.ChannelTransformsLowIn(EditedChannelNumber);
            obj.Views.Channels.MaximumIntensity.String =                obj.LoadedMovie.ChannelTransformsHighIn(EditedChannelNumber);
            obj.Views.Channels.Color.Value =                            find(strcmp(obj.LoadedMovie.ChannelColors{EditedChannelNumber},PossibleColors));
            obj.Views.Channels.Comment.String =                         obj.LoadedMovie.ChannelComments{EditedChannelNumber};
            obj.Views.Channels.OnOff.Value =                            obj.LoadedMovie.SelectedChannels(EditedChannelNumber);
        
            
            
        end
        
        %% views: track views and and other views
        
        
        
         function obj =                         updateImageAndTrackViews(obj)
             
             % update views:
            obj =                                           obj.updateTrackListView;
            obj =                                           obj.updateTrackView;
            obj =                                           obj.updateImageView;  
             
         end
         
        function obj =                              updateCentroidVisibility(obj)
            
             obj.TrackingViews.ShowCentroids.Value =        obj.LoadedMovie.CentroidsAreVisible;
             obj.Views.MovieView.CentroidLine.Visible =      obj.LoadedMovie.CentroidsAreVisible;
             
            
        end
        
        
         function obj =                              updateMaskVisibility(obj)

            obj.TrackingViews.ShowMasks.Value =                 obj.LoadedMovie.MasksAreVisible;
            obj =                                               obj.updateImageView; 
            
    
        end
   
         %% update tracking views: this should be moved directly to tracking views;
            function obj =                              updateAllTrackingViews(obj)
            

                obj.TrackingViews.ShowMaximumProjection.Value =    obj.LoadedMovie.CollapseAllTracking;

                obj =                                               obj.updateTrackListView;

                obj =                                               obj.updateCentroidVisibility;
                obj =                                               obj.updateMaskVisibility;
                obj =                                               obj.updateTrackVisibility;
                obj =                                               obj.updateHighlightingOfActiveTrack;
                
                obj =                                               obj.updateTrackView;

            end
        
          
            function obj =                          updateViewsAfterChangesInTracks(obj)
                
                
                obj =                                               obj.updateTrackListView;
                obj =                                               obj.updateTrackView;
                
            end
        
          
             
            
         
           function obj   =                updateTrackListView(obj)
                % shows all current tracks in table
            
                DriftCorrectionIsOn =                   obj.LoadedMovie.DriftCorrectionOn;
                
                obj.LoadedMovie =                                                  obj.LoadedMovie.synchronizeTrackingResults; %this shouldn't be necessary
                
                TrackModelWithoutDriftCorrection =      obj.LoadedMovie.Tracking.Tracking;
                TrackModelWithDriftCorrection =         obj.LoadedMovie.Tracking.TrackingWithDriftCorrection;
               
                
                if DriftCorrectionIsOn
                    AppliedTrackingModel =      TrackModelWithDriftCorrection;

                else
                    AppliedTrackingModel =      TrackModelWithoutDriftCorrection;

                end


                %% reformat track-list for view:
                NumberOfTracks=                                         size(AppliedTrackingModel,1);
                TrackListForUITable=                                    cell(NumberOfTracks,1);
                for TrackIndex=1:NumberOfTracks

                    TrackListForUITable{TrackIndex,1}=          sprintf('%5i %5i %5i %5i %5i %5i %5i', AppliedTrackingModel{TrackIndex,1}, AppliedTrackingModel{TrackIndex,2}, AppliedTrackingModel{TrackIndex,8} , AppliedTrackingModel{TrackIndex,9}, AppliedTrackingModel{TrackIndex,10}, ...
                    AppliedTrackingModel{TrackIndex,11}, AppliedTrackingModel{TrackIndex,12}, AppliedTrackingModel{TrackIndex,8});

                end

  
            
                ListWithFilteredTracksView =                            obj.TrackingViews.ListWithFilteredTracks;
                
                if NumberOfTracks == 0
                    ListWithFilteredTracksView.String=                  'No tracking data available';
                    ListWithFilteredTracksView.Value=                   1;
                    ListWithFilteredTracksView.Enable=                  'off';
               
                else
                     ListWithFilteredTracksView.String=                  TrackListForUITable;
                    if ListWithFilteredTracksView.Value == 0
                        ListWithFilteredTracksView.Value =                  1;
                    end
                    ListWithFilteredTracksView.Value=                   min([ListWithFilteredTracksView.Value length(ListWithFilteredTracksView.String)]);
                    ListWithFilteredTracksView.Enable=                  'on';


                end

             
            
            
            
               

           end
        
         
            function obj =                      updateTrackView(obj)
            
                 obj =              obj.resetThicknessOfActiveTrack;
                 obj =              obj.deleteNonMatchingTrackLineViews;
                 obj =              obj.addMissingTrackLineViews;
                 obj =              obj.updatePropertiesOfTrackLineViews;


            end
          
             function obj =                  updateSaveStatusView(obj)
            
                 if ~isempty(obj.LoadedMovie)
                 
            UnsavedTrackingDataExist = obj.LoadedMovie.UnsavedTrackingDataExist;
            
            switch UnsavedTrackingDataExist
                
                case true
                    obj.TrackingViews.TrackingTitle.ForegroundColor = 'red';
                   
                otherwise
                
                    obj.TrackingViews.TrackingTitle.ForegroundColor = 'green';
                
            end
            
                 end
        end
       
              function obj =                              updateTrackVisibility(obj)

                function track = changeTrackVisibility(track, state)
                    track.Visible = state;
                end

                obj.TrackingViews.ShowTracks.Value =        obj.LoadedMovie.TracksAreVisible;

                cellfun(@(x) changeTrackVisibility(x, obj.LoadedMovie.TracksAreVisible), obj.ListOfTrackViews);

            end
         
           
           function obj =                   resetIndexOfTrackListView(obj,IndexChange)
               
                ListView =                              obj.TrackingViews.ListWithFilteredTracks;
                MaximumIndex =                          length(obj.TrackingViews.ListWithFilteredTracks.String);

                CurrentIndex=                           min(ListView.Value);
                NewIndex =                              CurrentIndex+IndexChange;
                
               
                
                if  NewIndex<=MaximumIndex && NewIndex>=1
                
                
                    NewIndex =                          CurrentIndex+IndexChange;
                    ListView.Value =                    NewIndex;
                    
                end
               
               
           end
           
           

         
        
        
         function [obj] =                           resetThicknessOfActiveTrack(obj)
             
               
             
                IDOfActiveTrack =                           obj.LoadedMovie.IdOfActiveTrack;
                
                DriftCorrectionUsed =           obj.LoadedMovie.DriftCorrectionOn;
                
                switch DriftCorrectionUsed
                    
                    case 1
                        MyTrackModel =          obj.LoadedMovie.Tracking.TrackingWithDriftCorrection;
                        
                    otherwise
                        MyTrackModel =                              obj.LoadedMovie.Tracking.Tracking;
                        
                    
                end
                
                
                ColumnWithLineThickness =                   strcmp(obj.LoadedMovie.Tracking.ColumnsInTrackingCell, 'LineWidth');
                
 

              if  ~isempty(IDOfActiveTrack) && ~isempty(MyTrackModel)

                   MyTrackModel(:,ColumnWithLineThickness) =        {1};

                    RowWithActiveTrack=                             cell2mat(MyTrackModel(:,2))== IDOfActiveTrack;
                    if sum(RowWithActiveTrack)==1
                        LineWidthOfActiveTrack =                    3; % usually 3
                        MyTrackModel{RowWithActiveTrack,ColumnWithLineThickness}=    LineWidthOfActiveTrack;
                    end

                    obj.LoadedMovie.Tracking.Tracking = MyTrackModel;

               end
             
             
         end
         
     
        
        function [obj] =                            updatePropertiesOfTrackLineViews(obj)
            
            
                 %% draw selected trajectories: 
                 if isempty(obj.ListOfTrackViews)
                     return
                 end
                 
                 
                 %% read model and existing track-lines:
                
                 switch obj.LoadedMovie.DriftCorrectionOn
                     
                     case true
                          TrackModel =                               obj.LoadedMovie.Tracking.TrackingWithDriftCorrection;
                     otherwise
                              
                         TrackModel =                               obj.LoadedMovie.Tracking.Tracking;
                                
                 end
                 
                ListWithTrackViews =                       obj.ListOfTrackViews;

                
                
                NumberOfTracksToDraw=                       size(TrackModel,1);
                ListOfTrackTags =                       cellfun(@(x) str2double(x.Tag), ListWithTrackViews);
                for TrackIndex=1:NumberOfTracksToDraw

                    % get model of current track
                    ModelForCurrentTrack =                  TrackModel(TrackIndex,:);
                    
                    % find correct line handle for current track:
                    TrackID =                               ModelForCurrentTrack{1,2};               
                    RowInTrackViews =                       ListOfTrackTags == TrackID;
                    HandleForCurrentTrack =                 ListWithTrackViews{RowInTrackViews};
                    
                    % apply model to current line handle: inlcluding position of line;
                    obj.updateLineWithInputTrack(ModelForCurrentTrack, HandleForCurrentTrack);

                end
            
        end
        
        
        function                                    updateLineWithInputTrack(~, ModelForCurrentTrack, HandleForCurrentTrack)
            
            
            
                    X=                                      ModelForCurrentTrack{1,3};
                    Y=                                      ModelForCurrentTrack{1,4};
                    Z=                                      ModelForCurrentTrack{1,5};
                    TrackColor=                             ModelForCurrentTrack{1,6};
                    LineWidth=                              ModelForCurrentTrack{1,7};
                    
                    HandleForCurrentTrack.XData=            X;    
                    HandleForCurrentTrack.YData=            Y;  
                    HandleForCurrentTrack.ZData=            Z;  
                    HandleForCurrentTrack.Color=            TrackColor;  
                    HandleForCurrentTrack.LineWidth=        LineWidth;  
            
        end
        
        
        function [obj] =                            addMissingTrackLineViews(obj)
            
             function TrackLine = setTagOfTrackLines(TrackLine, TrackLineNumber)
                TrackLine.Tag = num2str(TrackLineNumber);
             end
             
             
              CurrentlyLoadedTrackModel =                 obj.LoadedMovie.Tracking.Tracking;
            
             
              if isempty(CurrentlyLoadedTrackModel) % if there are no tracks, just return
                  return
              end
            %% read data from model:
                ListWithTrackViews =                        obj.ListOfTrackViews;
                ParentAxes =                                obj.Views.MovieView.ViewMovieAxes;
            
                %% find all the track numbers that don't have a line view yet, and create a cell of views (each line has its number as a tag);
                ListWithVisibleTrackNumbers =               cellfun(@(x) str2double(x.Tag), ListWithTrackViews);
                ListWithAvailableTrackNumbers =             cell2mat(CurrentlyLoadedTrackModel(:,2));
                TrackNeedToBeAdded =                        ~ismember(ListWithAvailableTrackNumbers,ListWithVisibleTrackNumbers);
                IDsOfTracksThatNeedToBeAdded =              ListWithAvailableTrackNumbers(TrackNeedToBeAdded);
                
                if isempty(IDsOfTracksThatNeedToBeAdded)
                    return
                end
                
                CellWithNewLineHandles =                    (arrayfun(@(x) line(ParentAxes), 1:length(IDsOfTracksThatNeedToBeAdded), 'UniformOutput', false))';
                CellWithNewLineHandles =                    cellfun(@(x,y) setTagOfTrackLines(x,y), CellWithNewLineHandles, num2cell(IDsOfTracksThatNeedToBeAdded), 'UniformOutput', false);

                
                obj.ListOfTrackViews =                  [ListWithTrackViews; CellWithNewLineHandles];
            
        end
        
        
        function [obj] =                            deleteNonMatchingTrackLineViews(obj)
            
            
               
                ListWithTrackViews =                        obj.ListOfTrackViews;
                CurrentlyLoadedTrackModel =                 obj.LoadedMovie.Tracking.Tracking;
                
                if isempty(CurrentlyLoadedTrackModel)
                    obj =           obj.deleteAllTrackLineViews;
                    
                else
                    
                    
                    %% delete all tracks views that are not supported by a model;
                    ListWithViewTrackNumbers =                          cellfun(@(x) str2double(x.Tag), ListWithTrackViews);
                    ListWithModelTrackNumbers =                         cell2mat(CurrentlyLoadedTrackModel(:,2));

                    TracksThatNeedToBeDeleted =                        ~ismember(ListWithViewTrackNumbers, ListWithModelTrackNumbers);

                    cellfun(@(x) delete(x), obj.ListOfTrackViews(TracksThatNeedToBeDeleted))
                    obj.ListOfTrackViews(TracksThatNeedToBeDeleted,:) = [];

                end
                
                
               
            
        end
        
        
        function [obj] =                            deleteAllTrackLineViews(obj)
            
            
            AllLines =                  findobj(obj.Views.MovieView.ViewMovieAxes, 'Type', 'Line');
            TrackLineRows  =            arrayfun(@(x) ~isnan(str2double(x.Tag)), AllLines);
            TrackLines=                 AllLines(TrackLineRows,:);
            
            if ~isempty(TrackLines)
                arrayfun(@(x) delete(x),  TrackLines);
            end
            
            
            obj.ListOfTrackViews =  cell(0,1);
            
 
        end
        
        
         
        
       
         %% update views (maybe this should be moved to View Class);
        
        function changeAppearance(obj)
            
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                if strcmp(CurrentView.Style, 'popupmenu')
                    CurrentView.ForegroundColor = 'r';
                else
                    CurrentView.ForegroundColor =      obj.ForegroundColor;
                end
                CurrentView.BackgroundColor =       obj.BackgroundColor;

            end
            
            
        end
        
        function disableViews(obj)
            
             [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                if ~isempty(CurrentView.Callback)
                    CurrentView.Enable = 'off';
                end
               
            end

        end
        
        
        
        
        function disableAllViews(obj)
            
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                CurrentView.Enable = 'off';
                
            end
            
            
        end
        
        function enableAllViews(obj)
            
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                CurrentView.Enable = 'on';
                
            end
            
            
        end
        
        
        
         function enableViews(obj)
            
             [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                if ~isempty(CurrentView.Callback)
                    CurrentView.Enable = 'on';
                end
               
            end

         end
        
          
         
        
    end
    
end

