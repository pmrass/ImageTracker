classdef PMMovieController < handle
    %PMMOVIETRACKINGSTATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
         
        
        Views
        TrackingViews
        
        PressedKeyValue
        
        ListOfTrackViews =        cell(0,1)
        
        LoadedMovie
        
        LoadedImageVolumes
        NumberOfLoadedFrames =      40
        
        
        RowOfActiveTrack
        
        RowOfActiveTrackAll
        SegmentationOfCurrentFrame
        
        RowOfActiveTrackFilter
        SegmentationOfCurrentFramePlaneFilter
        
        % important track information of current frame:
        CurrentTrackIDsAll
        CurrentTrackIDsPlaneFilter
        
        CurrentTrackIDs
        CurrentXOfCentroids
        CurrentYOfCentroids
        CurrentZOfCentroids
        ListOfAllPixels
        
        ColumnWithTrack =                               1;
        ColumnWithAbsoluteFrame =                       2;
        ColumnWithCentroidY =                           3;
        ColumnWithCentroidX =                           4;  
        ColumnWithCentroidZ =                           5;
        ColumnWithPixelList =                           6;
        
        AplliedRowShifts
        AplliedColumnShifts
        AplliedPlaneShifts
        
        MaximumRowShift = 0
        MaximumColumnShift = 0
        MaximumPlaneShift = 0
        
        
        
        
        MaskColor =             [NaN NaN 150];
        
        MouseDownRow =              NaN
        MouseDownColumn =           NaN
        MouseUpRow =                NaN
        MouseUpColumn =             NaN
        
        % appearance
        BackgroundColor =               [0 0.1 0.2];
        ForegroundColor =               'c';
        
        TrackingCapture
        
        
   
    end
    
    methods
        
        function obj = PMMovieController
            
           
            %PMMOVIETRACKINGSTATE Construct an instance of this class
            %   modulates interplay between movie model (images and annotation) and views;
           

        end
        
        
        function [obj] =changeMovieKeyword(obj)
              KeywordString=                        char(inputdlg('Enter new keyword'));
              obj.LoadedMovie.Keywords{1,1} =       KeywordString;
                 
        end
       

        %% change views:
        function [obj] = updateCompleteView(obj)
            
            obj =                                               obj.updateAppliedPositionShift; % needs to be before resetLimitsOfImageAxes
            obj =                                               obj.resetLimitsOfImageAxes;
            
            if obj.LoadedMovie.TrackingOn
            
                obj.Views.Navigation.EditingOptions.Value =     3;
                
            end
            
            obj =                                               obj.initializeViewRanges;
            obj.Views.Navigation.ShowMaxVolume.Value =          obj.LoadedMovie.CollapseAllPlanes ;
            obj.Views.Navigation.ApplyDriftCorrection.Value =   obj.LoadedMovie.DriftCorrectionOn;
            
            obj =                                               obj.shiftImageByDriftCorrection;
            obj =                                               obj.applyNavigationChangesToView; % change frame/plane/channel value in menu
            obj =                                               obj.updateChannelSettingView; % changes the display of settings of selected channel;
           
            obj =                                               obj.updateCroppingLimitView; % draws cropping rectangle (will be out-of-bounds if cropping is actually selected;
            obj =                                               obj.updateAnnotationViews; % toggle visibility of annotation
            
            obj.Views.MovieView.ZStampText.String =             obj.LoadedMovie.ListWithPlaneStamps{obj.LoadedMovie.SelectedPlanes(1)};
            obj.Views.MovieView.TimeStampText.String =          obj.LoadedMovie.ListWithTimeStamps{obj.LoadedMovie.SelectedFrames};
            obj.Views.MovieView.ScalebarText.String =           obj.LoadedMovie.ScalebarStamp;

            obj=                                                obj.updateImageView; % changes the image in the current axes;
            obj=                                                obj.applyCropLimitsToView; % apply cropping to axis
            [obj] =                                             obj.updateCroppingLimitView;
            
        end
          
        
        
        function obj =   updateImageView(obj)
            
            
            %% collect relevant data from model:
            myPressedKey =                                      obj.PressedKeyValue;
           
            CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);
            myIDOfActiveTrack =                                 obj.LoadedMovie.IdOfActiveTrack;

            %% update segmentation and location of active track:
            
            obj =                                               obj.updateSegmentationInformationForFrame(CurrentFrame);
            
            
            %% during tracking: set focus on active track,
            if obj.LoadedMovie.TrackingOn && ~isempty(double(myPressedKey)) &&  (double(myPressedKey)==28 || double(myPressedKey)==29)
                obj =                                           obj.resetPlaneToActiveTrack;
                obj =                                           obj.centerFieldOfViewOnCurrentTrack;
            else %% otherwise just  update the gate (i.e. switch between crop/non crop and with/without drift correction);
                %obj =                                           obj.updateAppliedCroppingLimits;
            end
            
             
                     
            %% update centroids (they are used only for displaying the centroid view) ;
            if obj.LoadedMovie.CollapseAllTracking

                obj.CurrentTrackIDs =                           cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithTrack));
                obj.CurrentXOfCentroids =                       cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithCentroidX ));
                obj.CurrentYOfCentroids =                       cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithCentroidY ));
                obj.CurrentZOfCentroids =                       cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithCentroidZ));

                obj.ListOfAllPixels =                           cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithPixelList));

            else

                obj.CurrentTrackIDs =                           cell2mat(obj.SegmentationOfCurrentFramePlaneFilter(:,obj.ColumnWithTrack));
                obj.CurrentXOfCentroids =                       cell2mat(obj.SegmentationOfCurrentFramePlaneFilter(:,obj.ColumnWithCentroidX ));
                obj.CurrentYOfCentroids =                       cell2mat(obj.SegmentationOfCurrentFramePlaneFilter(:,obj.ColumnWithCentroidY ));
                obj.CurrentZOfCentroids =                       cell2mat(obj.SegmentationOfCurrentFramePlaneFilter(:,obj.ColumnWithCentroidZ));

                 obj.ListOfAllPixels =                          cell2mat(obj.SegmentationOfCurrentFramePlaneFilter(:,obj.ColumnWithPixelList));
            end
            
            
             obj.RowOfActiveTrack =                             obj.CurrentTrackIDs == myIDOfActiveTrack ;


            %% update the drift correction of centroids and show in view:
            obj =                                               obj.updateDriftCorrectionOfCentroids;
            obj.Views.MovieView.CentroidLine.XData =            obj.CurrentXOfCentroids;
            obj.Views.MovieView.CentroidLine.YData =            obj.CurrentYOfCentroids;


            obj =                                               obj.updatePositionOfActiveTrackHighlight;
            obj =                                               obj.updateManualDriftCorrectionView;




            %% update image
            obj =                                                                   obj.updateLoadedImageVolumes;
            rgbImage =                                                              obj.extractCurrentRgbImage; % this is by far the slowest component (but ok): consider changing;

            if obj.LoadedMovie.MasksAreVisible && ~isempty(obj.ListOfAllPixels)
                obj.ListOfAllPixels(isnan(obj.ListOfAllPixels(:,1)),:) =            [];
                rgbImage =                                                          obj.addMasksToImage(rgbImage);
            end

            obj =                                                                   obj.shiftImageByDriftCorrection;
            obj.Views.MovieView.MainImage.CData=                                    rgbImage;


        end
        
        function [obj] =    updateManualDriftCorrectionView(obj)
            
             CurrentFrame =                                                         obj.LoadedMovie.SelectedFrames(1);
            % update marker for manual drift correction:
            
            
            [xWithDrift, yWithDrift, PlaneWithDrifCorrection ] = addDriftCorrection(obj, obj.LoadedMovie.DriftCorrection.ManualDriftCorrectionValues(CurrentFrame,2), obj.LoadedMovie.DriftCorrection.ManualDriftCorrectionValues(CurrentFrame,3), obj.LoadedMovie.DriftCorrection.ManualDriftCorrectionValues(CurrentFrame,4));
            
            
            obj.Views.MovieView.ManualDriftCorrectionLine.XData =                   xWithDrift;
            obj.Views.MovieView.ManualDriftCorrectionLine.YData =                   yWithDrift;


            
            if ismember(obj.LoadedMovie.SelectedPlanes,PlaneWithDrifCorrection )
                obj.Views.MovieView.ManualDriftCorrectionLine.LineWidth =           3;
            else
                 obj.Views.MovieView.ManualDriftCorrectionLine.LineWidth =          1;
            end
            
        end
        
        function [obj] =        updateManualDriftCorrectionModelByMouseClick(obj)
            
             [ yCoordinateWithOutDrift, xCoordinateWithoutDrift,  planeWithoutDrift, frame ] =           obj.getCoordinatesOfCurrentMousePosition;
                 
        end
        
        function [obj] =    updateSegmentationInformationForFrame(obj, CurrentFrame)
            
              myIDOfActiveTrack =                             obj.LoadedMovie.IdOfActiveTrack;
            
            obj.SegmentationOfCurrentFrame =                    obj.LoadedMovie.Tracking.TrackingCellForTime{CurrentFrame,1};
            obj =                                               obj.createSegmentationWithPlaneFilter;
    
             obj.CurrentTrackIDsAll =                           cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithTrack));;
             obj.CurrentTrackIDsPlaneFilter =                   cell2mat(obj.SegmentationOfCurrentFramePlaneFilter(:,obj.ColumnWithTrack));;
                   
            obj.RowOfActiveTrackAll =                           obj.CurrentTrackIDsAll == myIDOfActiveTrack ;         
            obj.RowOfActiveTrackFilter  =                       obj.CurrentTrackIDsPlaneFilter == myIDOfActiveTrack ;  

            
            
        end
        
        
        function [obj] =    resetPlaneToActiveTrack(obj)
            
            
                        
            myIDOfActiveTrack =                             obj.LoadedMovie.IdOfActiveTrack;
              % simply reset the plane to the current plane of active
                % track; down below this plane will be used to create the image;
                RowOfActiveTrackForAll =                              find(cell2mat(obj.SegmentationOfCurrentFrame(:,obj.ColumnWithTrack)) == myIDOfActiveTrack) ;

                if ~isempty(RowOfActiveTrackForAll)
                    PlaneOfActiveTrack =                                round(obj.SegmentationOfCurrentFrame{RowOfActiveTrackForAll,obj.ColumnWithCentroidZ});
                    
                    
                    obj.LoadedMovie.SelectedPlanes =                    PlaneOfActiveTrack;
                    obj.LoadedMovie =                                   obj.LoadedMovie.resetViewPlanes;
                    obj.Views.Navigation.CurrentPlane.Value =             PlaneOfActiveTrack;
                    
                    
                end
            
            
        end
        
        function [obj] = updateViewsAfterFrameChange(obj)
            
            obj.Views.Navigation.CurrentTimePoint.Value =       obj.LoadedMovie.SelectedFrames;
            obj=                                                obj.updateImageView;
            obj.Views.MovieView.TimeStampText.String =          obj.LoadedMovie.ListWithTimeStamps{obj.LoadedMovie.SelectedFrames};
            
        end
        
        
        function [obj] = updateViewsAfterPlaneChange(obj)
            
            obj.Views.Navigation.CurrentPlane.Value =       obj.LoadedMovie.SelectedPlanes;
            obj=                                            obj.updateImageView;
            obj.Views.MovieView.ZStampText.String =         obj.LoadedMovie.ListWithPlaneStamps{obj.LoadedMovie.SelectedPlanes(1)};
            
            
        end
        
        function [obj] =    updateViewsAfterFrameAndPlaneChange(obj)
            
            obj.Views.Navigation.CurrentTimePoint.Value =       obj.LoadedMovie.SelectedFrames;
            obj.Views.MovieView.TimeStampText.String =          obj.LoadedMovie.ListWithTimeStamps{obj.LoadedMovie.SelectedFrames};

            obj.Views.Navigation.CurrentPlane.Value =       obj.LoadedMovie.SelectedPlanes;
            obj.Views.MovieView.ZStampText.String =         obj.LoadedMovie.ListWithPlaneStamps{obj.LoadedMovie.SelectedPlanes(1)};

            obj=                                            obj.updateImageView;
            
        end
        
        
        function [obj] = updateCroppingLimitView(obj)
                
            %% read data
            MyRectangleView =                               obj.Views.MovieView.Rectangle;
            MyCroppingGate=                                 obj.LoadedMovie.CroppingGate;

            CurrentFrame =                                  obj.LoadedMovie.SelectedFrames(1);    
             CurrentColumnShift=                               obj.AplliedColumnShifts(CurrentFrame);
             CurrentRowShift=                            obj.AplliedRowShifts(CurrentFrame);
            CurrentPlaneShift =                             obj.AplliedPlaneShifts(CurrentFrame);
           
            %% calculate new cropping gate as to be shown (with drift correction)
            
            Width=                                          MyCroppingGate(3);
            Height=                                         MyCroppingGate(4);
            StartColumn=                                    MyCroppingGate(1) + CurrentColumnShift;
            StartRow=                                       MyCroppingGate(2) + CurrentRowShift; 

            %% apply cropping gate:
            MyRectangleView.YData=                          [StartRow      StartRow              StartRow+Height     StartRow+Height  StartRow];
            MyRectangleView.XData=                          [StartColumn   StartColumn+Width     StartColumn+Width   StartColumn       StartColumn];
            MyRectangleView.Color =                         'w';


        end
        
     
        
        function [obj] = updateViewsAfterScaleBarChange(obj)
            
            obj.Views.MovieView.ScalebarText.String =              obj.LoadedMovie.ScalebarStamp;
            
        end
        
        
        function [obj] = updateViewsAfterChannelChange(obj)
            
            obj=                                                obj.updateImageView;
            
        end
        
        
        function obj = applyNavigationChangesToView(obj)
            obj.Views.Navigation.CurrentTimePoint.Value =       obj.LoadedMovie.SelectedFrames;    
            obj.Views.Navigation.CurrentPlane.Value =           obj.LoadedMovie.SelectedPlanes;
            obj.Views.Channels.SelectedChannel.Value =          obj.LoadedMovie.SelectedChannelForEditing;

            
        end
        
        
        function obj = updateAnnotationViews(obj)
            
            
          
            obj.Views.Annotation.ShowScaleBar.Value =       obj.LoadedMovie.ScaleBarVisible;
            
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
                      obj.Views.MovieView.ScalebarText.Visible = 'on';
                  otherwise
                      obj.Views.MovieView.ScalebarText.Visible = 'off';
                      
              end
          
              
            
      

            
        end
        
        
        function obj = updateChannelSettingView(obj)
        
           
            PossibleColors =                                            obj.Views.Channels.Color.String;
            EditedChannelNumber =                                       obj.LoadedMovie.SelectedChannelForEditing;
         

            obj.Views.Channels.SelectedChannel.Value =                  EditedChannelNumber;
            obj.Views.Channels.MinimumIntensity.String =                obj.LoadedMovie.ChannelTransformsLowIn(EditedChannelNumber);
            obj.Views.Channels.MaximumIntensity.String =                obj.LoadedMovie.ChannelTransformsHighIn(EditedChannelNumber);
            obj.Views.Channels.Color.Value =                            find(strcmp(obj.LoadedMovie.ChannelColors{EditedChannelNumber},PossibleColors));
            obj.Views.Channels.Comment.String =                         obj.LoadedMovie.ChannelComments{EditedChannelNumber};
            obj.Views.Channels.OnOff.Value =                            obj.LoadedMovie.SelectedChannels(EditedChannelNumber);
        
        end
        
        
        
       
        
        function obj = updateTrackView(obj)
            

                %% make line of active track thicker
               IDOfActiveTrack =          obj.LoadedMovie.IdOfActiveTrack;
                MyTrackModel =                       obj.LoadedMovie.Tracking.Tracking;
                
                if  ~isempty(IDOfActiveTrack) && ~isempty(MyTrackModel)

                    ColumnWithLineThickness =               7;
                   
                   

                    
                   MyTrackModel(:,ColumnWithLineThickness) =        {1};
                   % MyTrackModel(:,ColumnWithLineThickness) =       1:
                    
                    RowWithActiveTrack=                             cell2mat(MyTrackModel(:,2))== IDOfActiveTrack;
                    if sum(RowWithActiveTrack)==1
                        LineWidthOfActiveTrack =                    3; % usually 3
                        MyTrackModel{RowWithActiveTrack,ColumnWithLineThickness}=    LineWidthOfActiveTrack;
                    end

                    obj.LoadedMovie.Tracking.Tracking = MyTrackModel;

               end

 
            %% put data back into model (added additional lines that were missing);
             obj =              obj.deleteNonMatchingTrackLineViews;
             obj =              obj.addMissingTrackLineViews;
             obj =              obj.updatePropertiesOfTrackLineViews;
             
       
            
        end
        
        
        
        
        function [obj] = updatePropertiesOfTrackLineViews(obj)
            
            
                 %% draw selected trajectories: 
                 if isempty(obj.ListOfTrackViews)
                     return
                 end
                 
                 
                 TrackModel =               obj.LoadedMovie.Tracking.Tracking;
                 
                 switch obj.LoadedMovie.DriftCorrectionOn
                     
                     case true
                         TrackModel(:,3:5) = obj.LoadedMovie.Tracking.TrackingWithDriftCorrection(:,3:5);
                                
                 end

                ListWithTrackViews =       obj.ListOfTrackViews;
                NumberOfTracksToDraw=        size(TrackModel,1);
                NumbersInTrackViews =      cellfun(@(x) str2double(x.Tag), ListWithTrackViews);
                for TrackIndex=1:NumberOfTracksToDraw

                    TrackID =                   TrackModel{TrackIndex,2};
                    X=                          TrackModel{TrackIndex,3};
                    Y=                          TrackModel{TrackIndex,4};
                    Z=                          TrackModel{TrackIndex,5};
                    TrackColor=                 TrackModel{TrackIndex,6};
                    LineWidth=                  TrackModel{TrackIndex,7};
                    
                    RowInTrackViews =               NumbersInTrackViews == TrackID;

                    LineOfInterest =                ListWithTrackViews{RowInTrackViews};
                    LineOfInterest.XData=           X;    
                    LineOfInterest.YData=           Y;  
                    LineOfInterest.ZData=           Z;  
                    LineOfInterest.Color=           TrackColor;  
                    LineOfInterest.LineWidth=       LineWidth;  

                end
            
        end
        
        
        function [obj] =    addMissingTrackLineViews(obj)
            
             function TrackLine = setTagOfTrackLines(TrackLine, TrackLineNumber)
                TrackLine.Tag = num2str(TrackLineNumber);
             end
             
             
              CurrentlyLoadedTrackModel =                 obj.LoadedMovie.Tracking.Tracking;
            
             
              if isempty(CurrentlyLoadedTrackModel) % if there are no tracks, just return
                  return
              end
            %% read data from model:
                ListWithTrackViews =                        obj.ListOfTrackViews;
               
            
                %% find all the track numbers that don't have a line view yet, and create a cell of views (each line has its number as a tag);
                ListWithVisibleTrackNumbers =               cellfun(@(x) str2double(x.Tag), ListWithTrackViews);
                ListWithAvailableTrackNumbers =             cell2mat(CurrentlyLoadedTrackModel(:,2));
                TrackNeedToBeAdded =                        ~ismember(ListWithAvailableTrackNumbers,ListWithVisibleTrackNumbers);
                IDsOfTracksThatNeedToBeAdded =              ListWithAvailableTrackNumbers(TrackNeedToBeAdded);
                
                if isempty(IDsOfTracksThatNeedToBeAdded)
                    return
                end
                
                CellWithNewLineHandles =                    (arrayfun(@(x) line, 1:length(IDsOfTracksThatNeedToBeAdded), 'UniformOutput', false))';
                CellWithNewLineHandles =                    cellfun(@(x,y) setTagOfTrackLines(x,y), CellWithNewLineHandles, num2cell(IDsOfTracksThatNeedToBeAdded), 'UniformOutput', false);

                
                obj.ListOfTrackViews =                  [ListWithTrackViews; CellWithNewLineHandles];
            
        end
        
        
        function [obj] = deleteNonMatchingTrackLineViews(obj)
            
            
            %% read data from model:
                ListWithTrackViews =                        obj.ListOfTrackViews;
                
                
                CurrentlyLoadedTrackModel =                 obj.LoadedMovie.Tracking.Tracking;
                
                if isempty(CurrentlyLoadedTrackModel)
                    obj =           obj.deleteAllTrackLineViews;
                    
                else
                    
                    

                    %% delete all tracks views that are not supported by a model;
                    ListWithViewTrackNumbers =               cellfun(@(x) str2double(x.Tag), ListWithTrackViews);
                    ListWithModelTrackNumbers =             cell2mat(CurrentlyLoadedTrackModel(:,2));

                    TracksThatNeedToBeDeleted =                        ~ismember(ListWithViewTrackNumbers, ListWithModelTrackNumbers);


                    cellfun(@(x) delete(x), obj.ListOfTrackViews(TracksThatNeedToBeDeleted))
                    obj.ListOfTrackViews(TracksThatNeedToBeDeleted,:) = [];

               
                    
                    
                end
                
                
               
            
        end
        
        
        function [obj] = deleteAllTrackLineViews(obj)
            
            
            AllLines =  findobj(obj.Views.MovieView.ViewMovieAxes, 'Type', 'Line');
            
            TrackLineRows  =    arrayfun(@(x) ~isnan(str2double(x.Tag)), AllLines);
            
            TrackLines=     AllLines(TrackLineRows,:);
            
            if ~isempty(TrackLines)
                arrayfun(@(x) delete(x),  TrackLines);
            end
            
            
            obj.ListOfTrackViews =  cell(0,1);
            
 
        end
        
        
        %% change tracking model:
         function [obj] =        updateActiveMaskByButtonClick(obj)
            
             
             if isnan(obj.LoadedMovie.IdOfActiveTrack)
                 return
                 
             end
             
                %% if invalid values were returned: do nothing:
                CurrentFrame =                                                                              obj.LoadedMovie.SelectedFrames(1);
                ImageVolumeOfActiveChannel =                                                                obj.LoadedImageVolumes{CurrentFrame,1}(:,:,:,:,obj.LoadedMovie.ActiveChannel);
                [ yCoordinateWithOutDrift, xCoordinateWithoutDrift,  planeWithoutDrift, frame ] =           obj.getCoordinatesOfCurrentMousePosition;
                
                
                if min(isnan([xCoordinateWithoutDrift, yCoordinateWithOutDrift, planeWithoutDrift, frame]))
                    return
                end
                
                
                %% if the values are ok, autodetect pixels corresponding to identified mask:
                myTrackingObject =                                              PMTrackingCapture(obj.LoadedMovie.IdOfActiveTrack, obj.SegmentationOfCurrentFrame, round(xCoordinateWithoutDrift), round(yCoordinateWithOutDrift), round(planeWithoutDrift), ImageVolumeOfActiveChannel);
                
                
                obj.Views.MovieView.MainImage.CData(round(yCoordinateWithOutDrift),(xCoordinateWithoutDrift),:) = 255;
                
                myTrackingObject =                                              myTrackingObject.generateMaskByClickingThreshold;
                myTrackingObject =                                              myTrackingObject.removeDuplicatePixels;

                myPixels =                                                      myTrackingObject.MaskCoordinateList;
                if isempty(myPixels) || max(max(isnan(myPixels))) % if empty or not numeric: do not add pixel list:
                    return
                end
                
                %% if the created pixels are ok: add them to the tracking-structure;
                obj.LoadedMovie =                                               obj.LoadedMovie.updateMaskOfActiveTrack(myPixels);
                obj =                                                           obj.updateImageView;
            
 
                obj =                                               obj.updatePositionOfActiveTrackHighlight;
                obj =                                               obj.updateHighlightingOfActiveTrack;

         end
         
         
         function [obj] =       highLightRectanglePixelsByMouse(obj)
             
             TrackingViewChannel =      1;
             
             if isnan(obj.LoadedMovie.IdOfActiveTrack)
                 return
                 
             end
             
            [ yStart, xStart,  planeStartWithoutDrift, frame ] =                            obj.getCoordinatesOfButtonPress;
            [ yEnd, xEnd,  planeWithoutDrift, frame ] =                                     obj.getCoordinatesOfCurrentMousePosition;
            
            obj.Views.MovieView.MainImage.CData(:,:,TrackingViewChannel) =                  0;
            obj.Views.MovieView.MainImage.CData( round(min([yStart,yEnd]):max([yStart,yEnd])),round(min([xStart,xEnd]):max([xStart,xEnd])),TrackingViewChannel) = 200;

             
             
         end
         
         
         function [obj] = updateManualDriftCorrectionByMouse(obj)
             
            [ yEnd, xEnd,  planeWithoutDrift, frame ] =                     obj.getCoordinatesOfCurrentMousePosition;
            obj.LoadedMovie.DriftCorrection =                               obj.LoadedMovie.DriftCorrection.updateManualDriftCorrectionByValues(xEnd, yEnd,  planeWithoutDrift, frame);

            obj =                                                           obj.updateManualDriftCorrectionView;

     
         end
         
         function [obj] = removeHighlightedPixelsFromMask(obj)
             
             
               TrackingViewChannel =      1;
             
             if isnan(obj.LoadedMovie.IdOfActiveTrack)
                 return
                 
             end
             
                [ yStart, xStart,  planeStartWithoutDrift, frame ] =           obj.getCoordinatesOfButtonPress;
             
                [ yEnd, xEnd,  planeWithoutDrift, frame ] =                 obj.getCoordinatesOfCurrentMousePosition;
                
                obj.Views.MovieView.MainImage.CData(:,:,TrackingViewChannel) =                                      0;
                obj.Views.MovieView.MainImage.CData(round(min([yStart,yEnd]):max([yStart,yEnd])),round(min([xStart,xEnd]):max([xStart,xEnd])),TrackingViewChannel) =    200;
             
                [yCoordinates, xCoordinates] =   find(obj.Views.MovieView.MainImage.CData(:,:,TrackingViewChannel));
             
   
                
               %% if the created pixels are ok: add them to the tracking-structure;
                obj.LoadedMovie =                                               obj.LoadedMovie.updateMaskOfActiveTrackByRemoval(yCoordinates, xCoordinates);
                obj =                                                           obj.updateImageView;
            
                obj =                                                           obj.updatePositionOfActiveTrackHighlight;
                obj =                                                           obj.updateHighlightingOfActiveTrack;

                obj.LoadedMovie =                                   obj.LoadedMovie.refreshTrackingResults;
                obj =                                                       obj.updateTrackList;    % because this could potentially lead to track deletion
             
         end
         
         
         function obj = addHighlightedPixelsFromMask(obj)
             
             
               TrackingViewChannel =      1;
             
             if isnan(obj.LoadedMovie.IdOfActiveTrack)
                 return
                 
             end
             
                [ yStart, xStart,  planeStartWithoutDrift, frame ] =           obj.getCoordinatesOfButtonPress;
             
                [ yEnd, xEnd,  planeWithoutDrift, frame ] =                 obj.getCoordinatesOfCurrentMousePosition;
                
                obj.Views.MovieView.MainImage.CData(:,:,TrackingViewChannel) =                                      0;
                obj.Views.MovieView.MainImage.CData(round(min([yStart,yEnd]):max([yStart,yEnd])),round(min([xStart,xEnd]):max([xStart,xEnd])),TrackingViewChannel) =    200;
             
                [yCoordinates, xCoordinates] =   find(obj.Views.MovieView.MainImage.CData(:,:,TrackingViewChannel));
             
   
                
               %% if the created pixels are ok: add them to the tracking-structure;
                obj.LoadedMovie =                                               obj.LoadedMovie.updateMaskOfActiveTrackByAdding(yCoordinates, xCoordinates, planeWithoutDrift);
                obj =                                                           obj.updateImageView;
            
                obj =                                                           obj.updatePositionOfActiveTrackHighlight;
                obj =                                                           obj.updateHighlightingOfActiveTrack;

                     obj.LoadedMovie =                                   obj.LoadedMovie.refreshTrackingResults;
                obj =                                                       obj.updateTrackList;    % because this could potentially lead to track deletion
             
         
         
         
    end
        
         
         function [obj] =       createSegmentationWithPlaneFilter(obj)
             
             obj.SegmentationOfCurrentFramePlaneFilter =        obj.SegmentationOfCurrentFrame;
             
            pixelColumn =                                       obj.ColumnWithPixelList;  
            SelectedPlane =                                     obj.LoadedMovie.SelectedPlanes(1);
            [~, ~, SelectedPlaneWithoutDriftCorrection] =           obj.removeDriftCorrection(0,0,SelectedPlane);
            FilteredPixelLists =                                cellfun(@(x) obj.filterPixelListForPlane(x,SelectedPlaneWithoutDriftCorrection), obj.SegmentationOfCurrentFrame(:,pixelColumn), 'UniformOutput', false);
            
            obj.SegmentationOfCurrentFramePlaneFilter(:,pixelColumn) =               FilteredPixelLists;
            
            
            
            EmptyRows =     cellfun(@(x) isempty(x), obj.SegmentationOfCurrentFramePlaneFilter(:,pixelColumn));
             
            obj.SegmentationOfCurrentFramePlaneFilter(EmptyRows,:) = [];
            
         end
         
         function [list] = filterPixelListForPlane(obj, list,SelectedPlane)
             list(list(:,3)~=SelectedPlane,:) = [];  
         end
    
         
         function [obj] =           resetPlaneTrackingByMenu(obj)
             
             
             obj.LoadedMovie.CollapseAllTracking =          obj.TrackingViews.ShowMaximumProjection.Value;
      
             obj =                                          obj.updateImageView;
             
         end
         
         
         
         
        
          function [rowFinal, columnFinal, planeFinal, frame] =   getCoordinatesOfCurrentMousePosition(obj)
            
                frame =                                                 obj.LoadedMovie.SelectedFrames(1);
                planeRaw =                                              obj.LoadedMovie.SelectedPlanes(1);
                rowRaw =                                                obj.MouseUpRow;
                columnRaw =                                             obj.MouseUpColumn;
                
                [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =        getCurrentDriftCorrectionValues(obj);
                
                rowFinal =                                          round(rowRaw - CurrentRowShift);
                columnFinal =                                       round(columnRaw - CurrentColumnShift);
                planeFinal =                                        round(planeRaw - CurrentPlaneShift);

                coordinatesAreWithinOriginalImageBounds =           obj.verifyCoordinatesAreWithinBounds(rowFinal, columnFinal,planeFinal);
                if ~coordinatesAreWithinOriginalImageBounds
                    rowFinal = NaN;
                    columnFinal = NaN;
                    planeFinal = NaN;

                end
 
          end
          
           function [rowFinal, columnFinal, planeFinal, frame] =   getCoordinatesOfButtonPress(obj)
            
                frame =                                                 obj.LoadedMovie.SelectedFrames(1);
                planeRaw =                                              obj.LoadedMovie.SelectedPlanes(1);
                rowRaw =                                                obj.MouseDownRow;
                columnRaw =                                             obj.MouseDownColumn;
                
                [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =        getCurrentDriftCorrectionValues(obj);
                
                rowFinal =                                          round(rowRaw - CurrentRowShift);
                columnFinal =                                       round(columnRaw - CurrentColumnShift);
                planeFinal =                                        round(planeRaw - CurrentPlaneShift);

                coordinatesAreWithinOriginalImageBounds =           obj.verifyCoordinatesAreWithinBounds(rowFinal, columnFinal,planeFinal);
                if ~coordinatesAreWithinOriginalImageBounds
                    rowFinal = NaN;
                    columnFinal = NaN;
                    planeFinal = NaN;

                end
 
          end
        
          
           function [rowFinal, columnFinal, planeFinal, frame] =   getCoordinatesOfMouseDrag(obj)
            
                frame =                                                 obj.LoadedMovie.SelectedFrames(1);
                planeRaw =                                              obj.LoadedMovie.SelectedPlanes(1);
                rowRaw =                                                obj.MouseUpRow;
                columnRaw =                                             obj.MouseUpColumn;
                
                [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =        getCurrentDriftCorrectionValues(obj);
                
                rowFinal =                                          round(rowRaw - CurrentRowShift);
                columnFinal =                                       round(columnRaw - CurrentColumnShift);
                planeFinal =                                        round(planeRaw - CurrentPlaneShift);

                coordinatesAreWithinOriginalImageBounds =           obj.verifyCoordinatesAreWithinBounds(rowFinal, columnFinal,planeFinal);
                if ~coordinatesAreWithinOriginalImageBounds
                    rowFinal = NaN;
                    columnFinal = NaN;
                    planeFinal = NaN;

                end
 
        end
       
        
        %% change tracking views:
        
        function [obj] = resetActiveTrackByTrackList(obj)
            
                ListView =                                          obj.TrackingViews.ListWithFilteredTracks;
                IndicesOfSelectedRows=                              ListView.Value;
                if length(IndicesOfSelectedRows)== 1
                    
                    
                    %% read data:
                    ModelOfTrackDataForDisplay =                        obj.LoadedMovie.Tracking.Tracking;

 
                    %% process data:
                    NewTrackID=                                         ModelOfTrackDataForDisplay{IndicesOfSelectedRows,2};
                    obj =                                               obj.resetActiveTrackByNumber(NewTrackID);
                    obj =                                               obj.updateImageView;
                    
                end
               
        end
        
        
        
         function obj = deleteActiveTrack(obj)
            
             %% first remove all the masks corresponding to the track:
            TrackID =                                           obj.LoadedMovie.IdOfActiveTrack;
            obj.LoadedMovie.Tracking  =                         obj.LoadedMovie.Tracking.removeTrack(TrackID);
             
            %% then update the track list: one track will be gone;
            obj.LoadedMovie =                                   obj.LoadedMovie.refreshTrackingResults;
            obj =                                               obj.updateTrackList;

            %% then change other displays (like active track highlight etc.;
            obj =                                               obj.updateActiveTrackViewsByNumber(NaN);
            obj =                                               obj.updateImageView; % to update mask-view (remove it)
           
 
         end
         
         
         function obj = deleteActiveMask(obj)
             
             
             TrackID =                                           obj.LoadedMovie.IdOfActiveTrack;
             CurrentFrame =                          obj.LoadedMovie.SelectedFrames(1);
             
             obj.LoadedMovie.Tracking  =                         obj.LoadedMovie.Tracking.removeMask(TrackID,CurrentFrame);
        
            obj.LoadedMovie =           obj.LoadedMovie.refreshTrackingResults;
            obj =                       obj.updateTrackList;
            obj =                       obj.updateTrackView;
            
            ListWithExistinTracks = cell2mat(obj.LoadedMovie.Tracking.Tracking(:,2));
            test = obj.LoadedMovie.IdOfActiveTrack == ListWithExistinTracks;
            
             obj =           obj.updateImageView;
            
            if sum(test) == 0
                
                obj =           obj.updateActiveTrackViewsByNumber(NaN);
                obj =           obj.updateImageView;
                
            end

         end
         
         
           
        function [obj] =    resetActiveTrackByNumber(obj, NewTrackID)
            
                trackColumn =                                       obj.ColumnWithTrack;
                frameColumn =                                       obj.ColumnWithAbsoluteFrame;
                centroidYColumn =                                   obj.ColumnWithCentroidY;
                centroidXColumn =                                   obj.ColumnWithCentroidX;  


                obj =               obj.updateActiveTrackViewsByNumber(NewTrackID);
              
               
           
               %% if tracking is on: change current frame:
                    %% go to last frame of current track and update all views;

                   
                    SegmentationOfAllTracks_AllFrames =                 obj.LoadedMovie.TrackingAnalysis.ListWithCompleteMaskInformation;

                    %% process data: (get frame and coordinates);
                    RowsOfActiveTrack =                                 cell2mat(SegmentationOfAllTracks_AllFrames(:,trackColumn)) == NewTrackID;
                    SegmentationOfActiveTrack_AllFrames =               SegmentationOfAllTracks_AllFrames(RowsOfActiveTrack,:);

                    [~,rowOfLastFrame] =                                max(cell2mat(SegmentationOfActiveTrack_AllFrames(:,frameColumn)));


                    RelevantSegmentation =       	SegmentationOfActiveTrack_AllFrames(rowOfLastFrame,:);

                    TimeFrame =                                         RelevantSegmentation{frameColumn};
                    
                    %% put data back and apply:
                    obj.LoadedMovie.SelectedFrames  =                   TimeFrame;
                    obj =                                               obj.resetPlaneToActiveTrack;

                   % obj=                                            obj.updateImageView; % not elegant, but have to call this first to reset active track information;

                   
                    obj =                                               obj.updateViewsAfterFrameAndPlaneChange;
                   
                    
              
                    CenterX =                                           RelevantSegmentation{centroidXColumn};
                    CenterY =                                           RelevantSegmentation{centroidYColumn};
                   
                    obj =                                               obj.moveCroppingGateToNewCenter(CenterX, CenterY);
                    obj =                                               obj.updateCroppingLimitView;
                    
                    obj =                                               obj.resetPlaneToActiveTrack;

              
              
                if obj.LoadedMovie.CroppingOn
                        obj =                                               obj.updateAppliedCroppingLimits;
                        obj =                                               obj.resetLimitsOfImageAxes;

                    end


            
            
            
        end
        
         
         
           function [obj] = updateActiveTrackViewsByNumber(obj, NewTrackID)
             
               
               
            %% set back data and apply:
            obj.TrackingViews.ActiveTrack.String =              num2str(NewTrackID);
            obj.LoadedMovie.IdOfActiveTrack =                   NewTrackID;
            
            ListOfCurrentTrackIDs =                             obj.CurrentTrackIDs;
            RowOfNewActiveTrack_CurrentFrameSegmentation =      ListOfCurrentTrackIDs == NewTrackID;
            obj.RowOfActiveTrack =                              RowOfNewActiveTrack_CurrentFrameSegmentation;
            obj =                                               obj.updatePositionOfActiveTrackHighlight;
            obj =                                               obj.updateHighlightingOfActiveTrack;

            obj =                                               obj.updateTrackView;
           

            
            
         end
         
         
         
        
         
        
         function [obj] = activateNewTrack(obj)
            
            
            
            % this just creates the track ID and sets it as activate track;
            % masks that are clicked later will be added to this track:
            
            
            MySelectedFrame =                      obj.LoadedMovie.SelectedFrames(1);
             FieldNames =                                obj.LoadedMovie.Tracking.FieldNamesForTrackingCell;

             
             %% process data:
            Column_TrackId=                             strcmp('TrackID', FieldNames);
            Column_AbsoluteFrame=                       strcmp('AbsoluteFrame', FieldNames);
            Column_CentroidY=                           strcmp('CentroidY', FieldNames);
            Column_CentroidX=                           strcmp('CentroidX', FieldNames);
            Column_CentroidZ=                           strcmp('CentroidZ', FieldNames);
            Column_PixelList =                          strcmp('ListWithPixels_3D', FieldNames);

            
            
            InvaldRows =        isnan(cell2mat(obj.LoadedMovie.Tracking.TrackingCellForTime{MySelectedFrame,1}(:,Column_TrackId)));
            obj.LoadedMovie.Tracking.TrackingCellForTime{MySelectedFrame,1}(InvaldRows,:) = [];
            
            newTrackID =   max(cell2mat(obj.LoadedMovie.Tracking.TrackingCellForTime{MySelectedFrame,1}(:,Column_TrackId))) + 1;
                 
            if isempty(newTrackID) || isnan(newTrackID)
                newTrackID = 1;
            end
            
            obj.TrackingViews.ActiveTrack.String =              num2str(newTrackID);
            obj.LoadedMovie.IdOfActiveTrack =                   newTrackID;
                    
            
            
         end
        
         
         
       
         
         
         
      
        
        
        function obj = focusViewOnActiveTrack(obj)
            
            
            
        end
        
        function obj = updateHighlightingOfActiveTrack(obj)
            
               obj.TrackingViews.ActiveTrack.Value = obj.LoadedMovie.ActiveTrackIsHighlighted;
              
               if isnan(obj.LoadedMovie.IdOfActiveTrack)
                   obj.Views.MovieView.CentroidLine_SelectedTrack.Visible = false;
                    
               else
                   obj.Views.MovieView.CentroidLine_SelectedTrack.Visible = obj.LoadedMovie.ActiveTrackIsHighlighted;
               end
            
        end
        
        function obj = updatePositionOfActiveTrackHighlight(obj)
            
            if sum(obj.RowOfActiveTrack) == 0
                obj.Views.MovieView.CentroidLine_SelectedTrack.XData = NaN;
                obj.Views.MovieView.CentroidLine_SelectedTrack.YData = NaN;
                
            else
                obj.Views.MovieView.CentroidLine_SelectedTrack.XData =  obj.CurrentXOfCentroids(obj.RowOfActiveTrack);
                obj.Views.MovieView.CentroidLine_SelectedTrack.YData =  obj.CurrentYOfCentroids(obj.RowOfActiveTrack);

            end
        end
        
        function obj = updateAllTrackingViews(obj)
            
            
            %obj.TrackingViews.TrackingTitle
            %obj.TrackingViews.ActiveTrackTitle
            
            obj.TrackingViews.ShowCentroids.Value =            obj.LoadedMovie.CentroidsAreVisible;
            obj.TrackingViews.ShowMasks.Value =                obj.LoadedMovie.MasksAreVisible;
            obj.TrackingViews.ShowTracks.Value =               obj.LoadedMovie.TracksAreVisible;
            obj.TrackingViews.ShowMaximumProjection.Value =    obj.LoadedMovie.CollapseAllTracking;
            
            
            %obj.TrackingViews.ActiveTrack
            %obj.TrackingViews.ListWithFilteredTracksTitle
            %obj.TrackingViews.ListWithFilteredTracks
            
            
            
            obj =                                               obj.updateCentroidVisibility;
            obj =                                               obj.updateMaskVisibility;
            
            obj =                                               obj.updateHighlightingOfActiveTrack;
            
            obj =                                               obj.updateTrackList;
            
           % obj  = obj.deleteAllTrackLineViews; % when a movie is loaded delete all track lines; otherwise tracks;
            obj =                                               obj.updateTrackView;
            obj =                                               obj.updateTrackVisibility;
            

        end
        
        function obj = updateTrackList(obj)
            %REPOPULATETRACKINGHANDLES Summary of this function goes here
            %   Detailed explanation goes here
                    
            ListWithFilteredTracksView =            obj.TrackingViews.ListWithFilteredTracks;
            
            obj.LoadedMovie.Tracking =              obj.LoadedMovie.Tracking.calculateNumberOfTracks;
            
            NumberOfTracks =                        obj.LoadedMovie.Tracking.NumberOfTracks;
            
            if NumberOfTracks == 0
                    ListWithFilteredTracksView.String=                  'No tracking data available';
                    ListWithFilteredTracksView.Value=                   1;
                    ListWithFilteredTracksView.Enable=                  'off';
                    return
            end
            
            
                
                
                DriftCorrectionIsOn =                   obj.LoadedMovie.DriftCorrectionOn;

                if isempty(obj.LoadedMovie.Tracking.Tracking) || isempty(obj.LoadedMovie.Tracking.TrackingWithDriftCorrection)
                    obj.LoadedMovie  =      obj.LoadedMovie.refreshTrackingResults;
                    
                end
                
                TrackModelWithoutDriftCorrection =      obj.LoadedMovie.Tracking.Tracking;
                TrackModelWithDriftCorrection =         obj.LoadedMovie.Tracking.TrackingWithDriftCorrection;

                if DriftCorrectionIsOn

                    AppliedTrackingModel =      TrackModelWithDriftCorrection;

                else
                    AppliedTrackingModel =      TrackModelWithoutDriftCorrection;

                end


                %% filter tracks; filter and sort currently not supported:
%                     CurrentMinimumAcceptedTrackDuration=                    MovieViews.TrackingHandles.MinimumFramesPerTrack.Value;
%                     CurrentMinRange=                                        MovieViews.TrackingHandles.RangeMin.Value;
%                     CurrentMaxRange=                                        MovieViews.TrackingHandles.RangeMax.Value;
% 
%                     TrackingResults =                                       MovieModel.TrackingResults;
% 
%                     AppliedTrackingModel([AppliedTrackingModel{:,10}] < CurrentMinimumAcceptedTrackDuration,:)=     [];
%                     AppliedTrackingModel([AppliedTrackingModel{:,8}] < CurrentMinRange,:)=                          [];
%                     AppliedTrackingModel([AppliedTrackingModel{:,9}] > CurrentMaxRange,:)=                          [];
% 
%                     %% sort tracks by desired column:
%                     ColumnForWhichToSort=                                   MovieViews.TrackingHandles.SortTrackList.Value; 
%                     AppliedTrackingModel=                                           sortrows(AppliedTrackingModel, ColumnForWhichToSort);
% 

                %% reformat track-list for view:
                NumberOfTracks=                                         size(AppliedTrackingModel,1);
                TrackListForUITable=                                    cell(NumberOfTracks,1);
                for TrackIndex=1:NumberOfTracks

                    TrackListForUITable{TrackIndex,1}=          sprintf('%5i %5i %5i %5i %5i %5i %5i', AppliedTrackingModel{TrackIndex,1}, AppliedTrackingModel{TrackIndex,2}, AppliedTrackingModel{TrackIndex,8} , AppliedTrackingModel{TrackIndex,9}, AppliedTrackingModel{TrackIndex,10}, ...
                    AppliedTrackingModel{TrackIndex,11}, AppliedTrackingModel{TrackIndex,12}, AppliedTrackingModel{TrackIndex,8});

                end


                %% update view of track-list:

                ListWithFilteredTracksView.String=                  TrackListForUITable;
                if ListWithFilteredTracksView.Value == 0
                    ListWithFilteredTracksView.Value =                  1;
                end
                ListWithFilteredTracksView.Value=                   min([ListWithFilteredTracksView.Value length(ListWithFilteredTracksView.String)]);
                ListWithFilteredTracksView.Enable=                  'on';

                    
        end

        function obj = updateTrackVisibility(obj)

            function track = changeTrackVisibility(track, state)
                track.Visible = state;
            end
            
            cellfun(@(x) changeTrackVisibility(x, obj.LoadedMovie.TracksAreVisible), obj.ListOfTrackViews)
            
        end
        
        function obj = updateCentroidVisibility(obj)
            
             obj.TrackingViews.ShowCentroids.Value =        obj.LoadedMovie.CentroidsAreVisible;
             obj.Views.MovieView.CentroidLine.Visible =      obj.LoadedMovie.CentroidsAreVisible;
             
            
        end
        
        function obj = updateMaskVisibility(obj)
            
              obj.TrackingViews.ShowMasks.Value =            obj.LoadedMovie.MasksAreVisible;
              obj =                                           obj.updateImageView;
              
            
            
            
        end
        
        %% respond to user input:
       
        function [obj] =    interpretKey(obj,PressedKey)
            
            %% extract relevant information from model:
            
            obj.PressedKeyValue =                     PressedKey;  
            PressedKeyAsciiCode=                    double(PressedKey);    % convert to numbers for "non-characters" like left and right key
            PressedKeyNumber =                      str2double(PressedKey);
            
            CurrentFrame =                          obj.LoadedMovie.SelectedFrames;
            CurrentPlane =                          obj.LoadedMovie.SelectedPlanes;
            NumberOfChannels =                      obj.LoadedMovie.MetaData.EntireMovie.NumberOfChannels;
            
            
            MaximumFrame=                           obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints;
            MaximumPlane=                           obj.LoadedMovie.MetaData.EntireMovie.NumberOfPlanes;

            
            
            
            %% interpret keys and reset when appropriate
            switch PressedKeyAsciiCode


                %% navigation:
                case 28 % left 
                    if CurrentFrame> 1
                        obj =                       obj.resetFrame(CurrentFrame - 1);
                    end

                case 29 %right 
                    if CurrentFrame< MaximumFrame
                        obj =                       obj.resetFrame(CurrentFrame + 1);
                    end


                case 30 % up 
                    if CurrentPlane> 1
                        [obj]  = obj.resetPlane(CurrentPlane - 1);
                       
                    end

                case 31 %down
                    if CurrentPlane< MaximumPlane  
                        [obj]  = obj.resetPlane(CurrentPlane + 1);
                    end

            end

            
           switch PressedKey
                
                case {'1', '2', '3', '4', '5', '6', '7', '8', '9'} % channel toggle

                    if obj.Views.Figure.CurrentObject == obj.Views.MovieView.MainImage % do this only when on image (otherwise this gets always activated)

                         %% toggle visibility of current selected channel:
                        if PressedKeyNumber <= NumberOfChannels
                            ChannelToChange=                                                        PressedKeyNumber;
                            obj.LoadedMovie.SelectedChannels(ChannelToChange,1)=                                ~obj.LoadedMovie.SelectedChannels(ChannelToChange,1);
                            [obj]  =                                                                obj.resetChannelSettings(ChannelToChange);
                            obj =                                                                   obj.updateViewsAfterChannelChange;

                        end
                    
                    end

                case 'm' % maximum-projection toggle

                    obj.LoadedMovie.CollapseAllPlanes =                         ~obj.Views.Navigation.ShowMaxVolume.Value;
                    obj.Views.Navigation.ShowMaxVolume.Value =      obj.LoadedMovie.CollapseAllPlanes;
                    obj.LoadedMovie =                                           obj.LoadedMovie.resetViewPlanes;
                    obj =                                           obj.updateImageView;
                    
                case 'o' % crop-toggle

                    obj.LoadedMovie.CroppingOn =                                    ~obj.Views.Navigation.CropImageHandle.Value;
                    obj.Views.Navigation.CropImageHandle.Value =                    obj.LoadedMovie.CroppingOn;
                    obj =                                                           obj.resetLimitsOfImageAxes;
              


                 case 'i'

                        obj.LoadedMovie.TimeVisible =               ~obj.LoadedMovie.TimeVisible;
                        obj =                                       obj.updateAnnotationViews;

                 case 'z'

                        obj.LoadedMovie.PlanePositionVisible =      ~obj.LoadedMovie.PlanePositionVisible;
                        obj =                                       obj.updateAnnotationViews; 

                 case 's'

                        obj.LoadedMovie.ScaleBarVisible =        	~obj.Views.Annotation.ShowScaleBar.Value;
                        obj.Views.Annotation.ShowScaleBar.Value =   obj.LoadedMovie.ScaleBarVisible;
                        obj =                                       obj.updateAnnotationViews;  

                
                 case 'c'
                     
                        obj.LoadedMovie.CentroidsAreVisible =           ~obj.LoadedMovie.CentroidsAreVisible;
                        obj =                               obj.updateCentroidVisibility;
                        

               case 'a'
                   
                    obj.LoadedMovie.MasksAreVisible =                       ~obj.LoadedMovie.MasksAreVisible;
                    obj =                                                   obj.updateMaskVisibility;
                   

                    case 't'

                        obj.LoadedMovie.TracksAreVisible =          ~obj.LoadedMovie.TracksAreVisible;
                        obj.TrackingViews.ShowTracks.Value =        obj.LoadedMovie.TracksAreVisible;
                        obj =                                       obj.updateTrackVisibility;


                    case 'u'
                        
                        obj.LoadedMovie =           obj.LoadedMovie.refreshTrackingResults;
                        obj =                       obj.updateTrackList;
                        obj =                       obj.updateTrackView;
                        
                        
                   case 'n'

                        %% select "next track" in track-list (at navigation control):
                        ListView =                                          obj.TrackingViews.ListWithFilteredTracks;
                        ModelOfTrackDataForDisplay =                        obj.LoadedMovie.Tracking.Tracking;


                        OldIndex=                              min(ListView.Value);
                        if OldIndex<size(ModelOfTrackDataForDisplay,1)
                            NewIndex =  OldIndex+1;
                            ListView.Value = NewIndex;
                            
                            NewTrackID=                                         ModelOfTrackDataForDisplay{NewIndex,2};
                            obj =                                               obj.resetActiveTrackByNumber(NewTrackID);
                            obj =                                               obj.updateImageView;
                            
                        end
                        
                        
                        
                       

                    case 'p'

                       ListView =                                          obj.TrackingViews.ListWithFilteredTracks;
                        ModelOfTrackDataForDisplay =                        obj.LoadedMovie.Tracking.Tracking;


                        OldIndex=                              min(ListView.Value);
                        if OldIndex>1
                            NewIndex =  OldIndex-1;
                            ListView.Value = NewIndex;
                            
                            NewTrackID=                                         ModelOfTrackDataForDisplay{NewIndex,2};
                            obj =                                               obj.resetActiveTrackByNumber(NewTrackID);
                            obj =                                               obj.updateImageView;
                            
                        end


           end
            
           
            obj.PressedKeyValue = '';
                
           end
        
         %% change model and view:
         
        function [obj] =    resetChannelSettings(obj, selectedChannel)
            obj.LoadedMovie.SelectedChannelForEditing = selectedChannel;
            obj =   obj.updateChannelSettingView;
            
        end
        

        function [obj]  =   resetFrame(obj, newFrame)
            
            
            
            %obj.Views.Navigation.TimeSlider.Value = newFrame;
            if newFrame<1 || newFrame>obj.LoadedMovie.MetaData.EntireMovie.NumberOfTimePoints
                return
            end
            
            obj.LoadedMovie.SelectedFrames = newFrame;
            obj.Views.Navigation.CurrentTimePoint.Value = newFrame;
            
            [obj] = obj.updateViewsAfterFrameChange;

        end

        function [obj]  =   resetPlane(obj, newPlane)
            obj.LoadedMovie.SelectedPlanes =    newPlane;
            obj.LoadedMovie =                   obj.LoadedMovie.resetViewPlanes;
            [obj] =                              obj.updateViewsAfterPlaneChange;

        end
      
        
        
        %% change model:
        
          
        

        
        function obj  = updateAppliedDriftCorrectionFromCheckBox(obj, state)
            obj.LoadedMovie.DriftCorrectionOn =             state;
            obj =                                           obj.updateAppliedPositionShift;
              
        end
              
        
        function obj =      updateAppliedPositionShift(obj)
            
            DriftCorrectionIsOn =               obj.LoadedMovie.DriftCorrectionOn;
            metaData =                          obj.LoadedMovie.MetaData;
             
            switch DriftCorrectionIsOn
                
                 case true
                    
                     
                     
                    obj.AplliedRowShifts =          obj.LoadedMovie.DriftCorrection.RowShiftsAbsolute;
                    obj.AplliedColumnShifts =       obj.LoadedMovie.DriftCorrection.ColumnShiftsAbsolute;
                    obj.AplliedPlaneShifts =        obj.LoadedMovie.DriftCorrection.PlaneShiftsAbsolute;
                    
                    
                case false
                    
                    structure =                     obj.LoadedMovie.DriftCorrection.calculateEmptyShifts(metaData);
                    
                    obj.AplliedRowShifts =          structure.RowShiftsAbsolute;
                    obj.AplliedColumnShifts =       structure.ColumnShiftsAbsolute;
                    obj.AplliedPlaneShifts =        structure.PlaneShiftsAbsolute;
                      
            end
            
            obj.MaximumRowShift =                       max(obj.AplliedRowShifts);
            obj.MaximumColumnShift =                    max(obj.AplliedColumnShifts);
            obj.MaximumPlaneShift =                     max(obj.AplliedPlaneShifts);
            

            
            obj =                                       obj.resetLimitsOfImageAxes;
            obj =                                       obj.shiftImageByDriftCorrection;
            obj =                                       obj.updateCroppingLimitView;
            
            
            obj =                                   obj.initializeViewRanges;
            obj =                                   obj.updateImageView;
            
             obj =                              obj.updateTrackList;
             obj =                              obj.updateTrackView;
            
            
        end
        
        function obj =          updateAppliedCroppingLimits(obj)
            
                switch obj.LoadedMovie.CroppingOn

                     case 1
                         
                          CurrentFrame =                                        obj.LoadedMovie.SelectedFrames(1);    
                            CurrentColumnShift=                                 obj.AplliedColumnShifts(CurrentFrame);
                            CurrentRowShift =                                   obj.AplliedRowShifts(CurrentFrame);
                            CurrentPlaneShift =                                 obj.AplliedPlaneShifts(CurrentFrame);

                            obj.LoadedMovie.AppliedCroppingGate =               obj.LoadedMovie.CroppingGate;
                            obj.LoadedMovie.AppliedCroppingGate(1) =            obj.LoadedMovie.AppliedCroppingGate(1) + CurrentColumnShift;
                            obj.LoadedMovie.AppliedCroppingGate(2) =            obj.LoadedMovie.AppliedCroppingGate(2) + CurrentRowShift;
                             

                     otherwise
                          [rows,columns, ~] =                               obj.LoadedMovie.getImageDimensionsWithAppliedDriftCorrection;
                           obj.LoadedMovie.AppliedCroppingGate =          [1 1 columns  rows];

                 end
            
            
        end
        
      
        function obj =          shiftImageByDriftCorrection(obj)
            
            
            [rowsInImage, columnsInImage, planesInImage] =        obj.LoadedMovie.getImageDimensions;
            
            CurrentFrame =                                              obj.LoadedMovie.SelectedFrames(1);    
            CurrentColumnShift=                                           obj.AplliedColumnShifts(CurrentFrame);
            CurrentRowShift =                                        obj.AplliedRowShifts(CurrentFrame);
            CurrentPlaneShift =                                         obj.AplliedPlaneShifts(CurrentFrame);
           
            obj.Views.MovieView.MainImage.XData =                   [1+  CurrentColumnShift, columnsInImage + CurrentColumnShift];
            obj.Views.MovieView.MainImage.YData =                   [1+  CurrentRowShift, rowsInImage + CurrentRowShift];

            
            
            
        end
        
        
         function obj =         updateLoadedImageVolumes(obj)
            
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
                
                 for CurrentPlane = 1:NumberOfPlanes
                    for CurrentChannel = 1: NumberOfChannels
                        wantedImageVolume(:,:,CurrentPlane,1,CurrentChannel) = ...
                            medfilt2(wantedImageVolume(:,:,CurrentPlane,1,CurrentChannel));
                    
                    end
                
                end
                 
                 TemporaryImageVolumes{currentFrame,1} =        wantedImageVolume;
                 
                  if frameIndex == numberOfNeedeFrames
                      close(h)
                  end
                 
                
                 
             end
             
             %% once loading is finished reset to normal state
             obj.LoadedImageVolumes =                       TemporaryImageVolumes;
             obj.LoadedMovie.FileCouldNotBeRead =           false;
             obj.enableAllViews;
             
             
             
            
            
         end
        
         
         function obj =         centerFieldOfViewOnCurrentTrack(obj)
             
       
             if sum(obj.RowOfActiveTrackAll) ~= 0
                 
                    centerY =       obj.SegmentationOfCurrentFrame{obj.RowOfActiveTrackAll,obj.ColumnWithCentroidY};
                    centerX =       obj.SegmentationOfCurrentFrame{obj.RowOfActiveTrackAll,obj.ColumnWithCentroidX};

                    obj =           moveCroppingGateToNewCenter(obj, centerX, centerY);
                    obj =           obj.updateAppliedCroppingLimits;
                    obj =           obj.resetLimitsOfImageAxes;
                
             end

         end
         
         function obj =         moveCroppingGateToNewCenter(obj, centerX, centerY)
             
             
             %% only the start position needs to be changed, ;
             
        
    
            Width =                             obj.LoadedMovie.CroppingGate(3);
            Height =                            obj.LoadedMovie.CroppingGate(4);
            
            
            
            
            %OldStartColumn =        obj.LoadedMovie.CroppingGate(1);
            %OldStartRow   =         obj.LoadedMovie.CroppingGate(2);
            
            %CurrentCenterX =        OldStartColumn +  Width / 2;
            %CurrentCenterY =         OldStartRow +  Height / 2;
             
            NewCenterX =            centerX;
            NewCenterY =            centerY;
            
            
            NewStartColumn =        NewCenterX - Width / 2;
            NewStartRow =           NewCenterY - Height / 2;
            
            
            obj.LoadedMovie.CroppingGate(1) = NewStartColumn;
            obj.LoadedMovie.CroppingGate(2) = NewStartRow;
            
             
         end
         
         
         function obj =         resetAxesCenter(obj, xShift, yShift)
             
             obj.Views.MovieView.ViewMovieAxes.XLim = obj.Views.MovieView.ViewMovieAxes.XLim - xShift;
             obj.Views.MovieView.ViewMovieAxes.YLim = obj.Views.MovieView.ViewMovieAxes.YLim - yShift;
             
             
         end
         
         function obj =         updateCroppingGateFromMouseClicks(obj)
             
             % the gate is stored without drift correction; remove drift correction before storing positions;
            StartRowAsClicked =                                 obj.MouseDownRow;
            StartColumnAsClicked =                              obj.MouseDownColumn;
            EndRowAsClicked =                                   obj.MouseUpRow;
            EndColumnAsClicked =                                obj.MouseUpColumn; 
            
            
            CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);
            RowShiftsAbsolute =                                 obj.AplliedRowShifts;
            ColumnShiftsAbsolute =                              obj.AplliedColumnShifts;
            PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;
            
            Width =                                             EndColumnAsClicked - StartColumnAsClicked;
            Height =                                            EndRowAsClicked - StartRowAsClicked;
            
            CurrentRowShift =                                   RowShiftsAbsolute( CurrentFrame);
            CurrentColumnShift =                                ColumnShiftsAbsolute( CurrentFrame);
            CurrentPlaneShift =                                 PlaneShiftsAbsolute( CurrentFrame);
            
            
            StartRowAfterRemovingDrift =                        StartRowAsClicked - CurrentRowShift;
            StartColumnAfterRemovingDrift =                     StartColumnAsClicked - CurrentColumnShift;

              
                
                
            obj.LoadedMovie.CroppingGate(1)=                  round(StartColumnAfterRemovingDrift);
            obj.LoadedMovie.CroppingGate(2)=                  round(StartRowAfterRemovingDrift);
            obj.LoadedMovie.CroppingGate(3)=                  round(Width       );
            obj.LoadedMovie.CroppingGate(4)=                  round(Height);
    
  
         end
         
         function obj =         resetCroppingGate(obj)
         
            obj.LoadedMovie.CroppingGate(1)=                  1;
            obj.LoadedMovie.CroppingGate(2)=                  1;
            obj.LoadedMovie.CroppingGate(3)=                  obj.LoadedMovie.MetaData.EntireMovie.NumberOfColumns;
            obj.LoadedMovie.CroppingGate(4)=                  obj.LoadedMovie.MetaData.EntireMovie.NumberOfRows;
             
         end
         
         
         
            
        function [obj] = applyCropLimitsToView(obj)
            
            
               %% calculate X and Y limits from crop-settings and apply them to the axis (this makes the actual cropping);
                MyAxes  =                                           obj.Views.MovieView.ViewMovieAxes;      
                MyCroppingGate =                                    obj.LoadedMovie.AppliedCroppingGate;
                
                CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);    
                CurrentColumnShift =                                   obj.AplliedColumnShifts(CurrentFrame);
                CurrentRowShift =                                obj.AplliedRowShifts(CurrentFrame);
                CurrentPlaneShift =                                 obj.AplliedPlaneShifts(CurrentFrame);

                
                
                
                
                
                Left =                                              MyCroppingGate(1) + CurrentColumnShift;
                Top =                                               MyCroppingGate(2) + CurrentRowShift;
                
                 
                Width =                                             MyCroppingGate(3);
                Right =                                             Left + Width - 1;

                
                Height =                                            MyCroppingGate(4);
                Bottom =                                            Top + Height  - 1;
                
                XLim =                                              sort([Left Right]);
                YLim =                                              sort([Top Bottom]);
                
                MyAxes.XLim=                                        XLim;
                MyAxes.YLim=                                        YLim;
                %MyAxes.YDir=                                        'reverse';  
                %MyAxes.DataAspectRatio=                             [ 1  1 1];
                %MyAxes.Position =                                   [ 0 0 1 1 ];


            
        end
        
        
         
           function obj =                                   resetLimitsOfImageAxes(obj)
            
                %% read data:
                obj =                                               obj.updateAppliedCroppingLimits;

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
        
         
         
         function obj = initializeViewRanges(obj)
            
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
              obj.Views.Navigation.TimeSlider.Value =               obj.Views.Navigation.CurrentTimePoint.Value;
              
              Range = obj.Views.Navigation.TimeSlider.Max -   obj.Views.Navigation.TimeSlider.Min;
              if Range == 0
                obj.Views.Navigation.TimeSlider.Visible = 'off';
              else
                  
                  Step =     1/ (Range);
                  obj.Views.Navigation.TimeSlider.Visible = 'on';
                  obj.Views.Navigation.TimeSlider.SliderStep = [Step Step];
              end
              

             
         end
        
         
         function obj = changeActiveTrackByRectangle(obj)
             
             
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
                
             %% read data:
             currentCroppingGate = obj.LoadedMovie.CroppingGate;
             mostRecentTrackData =                          obj.LoadedMovie.Tracking.Tracking;
             
            %% process data:
             
             
             if isempty(mostRecentTrackData)
                 return
             end
             
             xReference =           currentCroppingGate(1) + currentCroppingGate(3)/2;
             yReference =           currentCroppingGate(2) + currentCroppingGate(4)/2;
     
             
             
             trackXCoordinates_NoDriftCorrection = mostRecentTrackData(:,3);
             trackYCoordinates_NoDriftCorrection = mostRecentTrackData(:,4);
             %ZCoordinates_NoDriftCorrection = MostRecentTrackData(:,5);
             
             
             ListWithSelectedTrackIDs =               cell2mat(mostRecentTrackData(:,2));
             [ ListWithDistances ] =                 cellfun(@(x,y)  computeShortestDistance(xReference, yReference, x,y ), trackXCoordinates_NoDriftCorrection,trackYCoordinates_NoDriftCorrection);
             
             [~, Index]=                                         nanmin(ListWithDistances(:,1));
                NewTrackID=                                   ListWithSelectedTrackIDs(Index,1);
             
                
                obj =           obj.updateActiveTrackViewsByNumber(NewTrackID);
               
             
             
         end
         
         function [currentFrame] =  getCurrentFrame(obj)
             
              currentFrame = obj.LoadedMovie.SelectedFrames(1);
             
             
         end
        
         %%
           function [ListWithAllViews] =               getListWithAllViews(obj)
            

            
            FieldNames =            fieldnames(obj.Views.Navigation);
            NavigationViews = cellfun(@(x) obj.Views.Navigation.(x), FieldNames, 'UniformOutput', false);
            
            FieldNames =            fieldnames(obj.Views.Channels);
            ChannelViews = cellfun(@(x) obj.Views.Channels.(x), FieldNames, 'UniformOutput', false);
            
            FieldNames =            fieldnames(obj.Views.Annotation);
            AnnotationViews = cellfun(@(x) obj.Views.Annotation.(x), FieldNames, 'UniformOutput', false);
            
              FieldNames =            fieldnames(obj.TrackingViews);
            TrackingViewsInside = cellfun(@(x) obj.TrackingViews.(x), FieldNames, 'UniformOutput', false);
            
            ListWithAllViews =          [NavigationViews; ChannelViews;AnnotationViews;TrackingViewsInside];
        end
        
        
        
        
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
        
        
         function [xCoordinates, yCoordinates, zCoordinates ] = addDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
             
                CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);


                RowShiftsAbsolute =                                 obj.AplliedRowShifts;
                ColumnShiftsAbsolute =                              obj.AplliedColumnShifts;
                PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;

                xCoordinates=                                       xCoordinates+ColumnShiftsAbsolute(CurrentFrame);
                yCoordinates=                                       yCoordinates+RowShiftsAbsolute(CurrentFrame);
                zCoordinates=                                       zCoordinates+PlaneShiftsAbsolute(CurrentFrame);

         end
         
         
          function [xCoordinates, yCoordinates, zCoordinates ] = removeDriftCorrection(obj, xCoordinates, yCoordinates, zCoordinates)
             
                CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);


                RowShiftsAbsolute =                                 obj.AplliedRowShifts;
                ColumnShiftsAbsolute =                              obj.AplliedColumnShifts;
                PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;

                xCoordinates=                                       xCoordinates-ColumnShiftsAbsolute(CurrentFrame);
                yCoordinates=                                       yCoordinates-RowShiftsAbsolute(CurrentFrame);
                zCoordinates=                                       zCoordinates-PlaneShiftsAbsolute(CurrentFrame);

         end
         
         
    

          %% helper functions
        
          function ImageVolume_Target =               extractCurrentRgbImage(obj)


            %% extract and process SourceImageVolume
            WantedFrame =                               obj.LoadedMovie.SelectedFrames(1);
            DriftPlanes=                                obj.LoadedMovie.SelectedPlanesForView;
            
            WantedPlanes =                              obj.convertInputPlanesIntoRegularPlanes(DriftPlanes);
            
           
            
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
            
            
            %% these two steps are the slowst: potentially this cannot be improved much (unless putting everything into memory) to me this is fast enough;
            CompleteImageVolume =                                              CompleteImageVolume(:,:,WantedPlanes,:,:); % keep only selected planes
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
        
      
          function [neededFrames] =                   getFramesThatNeedToBeLoaded(obj)
            
            
            
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
        
        
          function [rgbImage] =                     addMasksToImage(obj, rgbImage)
              
              
                IntensityForRedChannel =                obj.MaskColor(1);
                IntensityForGreenChannel =              obj.MaskColor(2);
                IntensityForBlueChannel =               obj.MaskColor(3);
                
                CoordinateList =                        obj.ListOfAllPixels;
                
               
        
                NumberOfPixels =                                                    size(CoordinateList,1);
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
      
        
          function [regularPlanes] =                convertInputPlanesIntoRegularPlanes(obj, inputPlanes)
              
              if obj.LoadedMovie.DriftCorrectionOn
                  
                    CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);
                    PlaneShiftsAbsolute =                               obj.AplliedPlaneShifts;
                    regularPlanes =                                     inputPlanes - PlaneShiftsAbsolute(CurrentFrame);
                    
                    regularPlanes(regularPlanes<1) =                  [];
                    regularPlanes(regularPlanes>obj.LoadedMovie.MetaData.EntireMovie.NumberOfPlanes) = [];

                  
              else
                  regularPlanes =                                       inputPlanes;
                  
              end
              
              
          end
          
          
          function [CurrentRowShift, CurrentColumnShift, CurrentPlaneShift] =        getCurrentDriftCorrectionValues(obj)
              
            CurrentFrame =                                      obj.LoadedMovie.SelectedFrames(1);    
            CurrentColumnShift=                                 obj.AplliedColumnShifts(CurrentFrame);
            CurrentRowShift=                                    obj.AplliedRowShifts(CurrentFrame);
            CurrentPlaneShift =                                 obj.AplliedPlaneShifts(CurrentFrame);

          end
          
          
          function  coordinatesAreWithinOriginalImageBounds =           verifyCoordinatesAreWithinBounds(obj, rowFinal, columnFinal,planeFinal);
               
              
              maximumRows =     obj.LoadedMovie.MetaData.EntireMovie.NumberOfRows;
              maximumColumns =  obj.LoadedMovie.MetaData.EntireMovie.NumberOfColumns;
              maximumPlanes =   obj.LoadedMovie.MetaData.EntireMovie.NumberOfPlanes;
              
              coordinatesAreWithinOriginalImageBounds =       rowFinal>=1 && rowFinal<=maximumRows && columnFinal>=1 && columnFinal<=maximumColumns && planeFinal>=1 && planeFinal<=maximumPlanes;

              
          end
          
          
          function obj =                updateDriftCorrectionOfCentroids(obj)
              
            CurrentFrame =                                              obj.LoadedMovie.SelectedFrames(1);    
            CurrentColumnShift =                                           obj.AplliedColumnShifts(CurrentFrame);
            CurrentRowShift =                                        obj.AplliedRowShifts(CurrentFrame);
            CurrentPlaneShift =                                         obj.AplliedPlaneShifts(CurrentFrame);

            

            obj.CurrentXOfCentroids =           obj.CurrentXOfCentroids + CurrentColumnShift;
            obj.CurrentYOfCentroids =           obj.CurrentYOfCentroids + CurrentRowShift;
            obj.CurrentZOfCentroids =           obj.CurrentZOfCentroids + CurrentPlaneShift;
   
          end
          
        
    end
    
end

