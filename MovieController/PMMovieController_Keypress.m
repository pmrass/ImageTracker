classdef PMMovieController_Keypress
    %PMMOVIECONTROLLER_KEYPRESS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access= private)
        MovieController
    end
    
    methods
        
        function obj = PMMovieController_Keypress(Object)
            %PMMOVIECONTROLLER_KEYPRESS Construct an instance of this class
            %   Detailed explanation goes here
            obj.MovieController = Object;
              
        end
        
        function MyMovieController = processKeyInput(obj, PressedKey, CurrentModifier)
            
            switch double(PressedKey)
                case 28 % left 
                    obj.MovieController =       obj.MovieController.goOneFrameDown;
                case 29 %right 
                    obj.MovieController =       obj.MovieController.goOneFrameUp;
                case 30 % up 
                    obj.MovieController = obj.MovieController.goOnePlaneUp;
                case 31 %down
                      obj.MovieController = obj.MovieController.goOnePlaneDown;
            end

            switch PressedKey
                    case {'x','X'}  %% navigation shortcuts: first frame, last/ first tracked frame:
                         switch length(CurrentModifier)
                             case 0
                                obj.MovieController =      obj.MovieController.resetFrame(1);
                             case 1
                                 switch CurrentModifier{1,1}
                                     case 'shift'
                                         obj.MovieController =      obj.MovieController.goToLastFrame;
                                 end
                         end
                                
                    case {'d', 'D'} 
                        if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                             switch length(CurrentModifier)
                                 case 0 
                                    obj.MovieController =       obj.MovieController.goToLastContiguouslyTrackedFrameInActiveTrack;
                                case 2 
                                     if max(strcmp(CurrentModifier,'shift')) && max(strcmp(CurrentModifier, 'command'))
                                        obj.MovieController =      obj.MovieController.deleteActiveTrack;
                                     end
                             end
                        end
                        
                    case 'g'
                        obj.MovieController =       obj.MovieController.gotToFirstTrackedFrameFromCurrentPoint;
                        
                    case 'm' 
                         switch length(CurrentModifier)
                             case 0
                                obj.MovieController =   obj.MovieController.setImageMaximumProjection(~obj.MovieController.getViews.Navigation.ShowMaxVolume.Value);
                             case 2
                                 if max(strcmp(CurrentModifier,'shift')) && max(strcmp(CurrentModifier, 'command'))
                                     obj.MovieController = obj.MovieController.mergeTracksByProximity;
                                 end       
                         end
                        
                    case 'o' % crop-toggle
                        obj.MovieController =                  obj.MovieController.toggleCroppingOn;
                        
                    case {'1', '2', '3', '4', '5', '6', '7', '8', '9'} % channel toggle
                            if obj.MovieController.getViews.Figure.CurrentObject == obj.MovieController.getViews.MovieView.MainImage % do this only when on image (otherwise this gets always activated)
                                 obj.MovieController =   obj.MovieController.toggleVisibilityOfChannelIndex(str2double(PressedKey));    
                            end

                    case 'i'   
                        obj.MovieController =               obj.MovieController.toggleTimeVisibility;

                    case 'z'
                        obj.MovieController =                  obj.MovieController.togglePlaneAnnotationVisibility; 

                    case {'s','S'}
                         switch length(CurrentModifier)
                             case 0 
                                 obj.MovieController =      obj.MovieController.toggleScaleBarVisibility;
                                 
                             case 1
                                 switch CurrentModifier{1,1}
                                     case 'shift'
                                         if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                                                obj.MovieController =     obj.MovieController.splitTrackAtFrameAndDeleteFirst;  
                                         end
                                 end

                             case 2
                                  if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                                       if max(strcmp(CurrentModifier,'shift')) && max(strcmp(CurrentModifier, 'command'))
                                           obj.MovieController =            obj.MovieController.splitSelectedTracksAndDeleteSecondPart;
                                       end
                                  end
                         end
                

                    case {'c','C'} %% toggle centroids, masks, tracks
                         switch length(CurrentModifier)
                             case 0
                                 obj.MovieController = toggleCentroidVisibility(obj.MovieController);
                                 
                             case 1
                                 switch CurrentModifier{1,1} 
                                     case 'shift'
                                         obj.MovieController =      obj.MovieController.removeMasksWithNoPixels;
                                     case 'command'
                                         obj.MovieController =      obj.MovieController.selectAllTracks; 
                                 end
                         end

                    case 'a'
                        obj.MovieController =       obj.MovieController.toggleMaskVisibility;
                        
                    case 't'
                        obj.MovieController =       obj.MovieController.toggleTrackVisibility;

                    case 'u' 
                            switch length(CurrentModifier) 
                                case 0
                                    obj.MovieController =       obj.MovieController.resetAllTrackViews;
                                    
                                case 2
                                     if max(strcmp(CurrentModifier,'shift')) && max(strcmp(CurrentModifier, 'command'))
                                          obj.MovieController =  obj.MovieController.setFinishStatusOfTrackTo('Unfinished');
                                     end
                             end
        
                    case {'f','F'} %% tracking shortcuts
                            if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                                 switch length(CurrentModifier)
                                     case 0
                                         % currently not recommended option;
                                         % using brightest pixels to detect cells and then create 3D mask;
                                         % problems: very slow, leads to a lot of double-tracking;
                                          obj.MovieController =   obj.MovieController.autoDetectMasksOfCurrentFrame;
                                    
                                     case 1
                                         switch CurrentModifier{1,1}
                                             case 'shift' 
                                                 obj.MovieController =   obj.MovieController.autoDetectMasksByCircleRecognition; % currently recommeneded approach;
                                         end
                                         
                                     case 2
                                         if max(strcmp(CurrentModifier,'shift')) && max(strcmp(CurrentModifier, 'command'))
                                             obj.MovieController =  obj.MovieController.setFinishStatusOfTrackTo('Finished');
                                         end
                                 end
                            end
                        

                    case 'l' 
                        if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                            obj.MovieController =   obj.MovieController.autoTrackingWhenNoMaskInNextFrame;
                        end

                    case {'R','r'} 
                        if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                             switch length(CurrentModifier)
                                 case 0
                                     % do both segmentation and tracking of current cell (consecutive) frames from scratch;
                                     % this is now mostly replace by 
                                     obj.MovieController =              obj.MovieController.autoForwardTrackingOfActiveTrack;
                                 case 1
                                     switch CurrentModifier{1,1}
                                         case 'shift'
                                             % for current track:
                                             % if unhappy with the masks of the current track: create 'mini' masks;
                                             % this will can be done for 're-creating' masks (re-creating masks ignores current masks that cannot be satisfactarily recreated;
                                             obj.MovieController =     obj.MovieController.minimizeMasksOfCurrentTrack;
                                             
                                         case 'command'
                                             % for current track, use current centroid as basis and recreate 3D mask by autothresholding surrounding area;
                                             obj.MovieController =   obj.MovieController.recreateMasksOfCurrentTrack;

                                     end

                             end
                        end

                    case 'v' 
                        if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                            obj.MovieController =              obj.MovieController.autoBackwardTrackingOfActiveTrack;
                        end

                    case 'b' 
                         if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                            obj.MovieController =                                   obj.MovieController.addExtraPixelRowToCurrentMask;
                         end

                    case 'e' 
                        if strcmp(obj.MovieController.getViews.getEditingType, 'Tracking')
                            obj.MovieController =                                   obj.MovieController.removePixelRimFromCurrentMask;
                        end
            end
            MyMovieController = obj.MovieController;
        end
 
    end
    
    methods (Access = private)
        
        
        
        
    end
end

