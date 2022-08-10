classdef PMMovieController_Keypress
    %PMMOVIECONTROLLER_KEYPRESS manages PMMovieController object actions by keypress;
    % has PMMovieController object; processKeyInput method takes key and modifier and executes appropriate action;
    
    properties (Access= private)
        PressedKey
        Modifiers
        MovieController
        
    end
    
    methods
        
        function obj = PMMovieController_Keypress(Object)
            %PMMOVIECONTROLLER_KEYPRESS Construct an instance of this class
            %   takes 1 argument:
            % 1: PMMovieController;
            obj.MovieController = Object;
              
        end
        
        function MyMovieController = processKeyInput(obj, PressedKey, CurrentModifier)
            % PROCESSKEYINPUT based on input executes PMMovieController action;
            % takes 2 arguments:
            % 1: pressed key
            % 2: modifier
            % returns PMMovieController object
            obj.PressedKey =     PressedKey;
            if ischar(CurrentModifier)
               CurrentModifier = {CurrentModifier}; 
            end
            obj.Modifiers =      PMKeyModifiers(CurrentModifier).getNameOfModifier;
            obj =                obj.processKeyPressAnyTime;
               
              switch obj.MovieController.getViews.getEditingType
            
                case 'No editing'
                    
                case 'Manual drift correction'
                        
                case 'Tracking'
                    obj = obj.processKeypressDuringTracking;
                
                otherwise
                    error('Editing type not supported.')
                    
            end
            
            MyMovieController = obj.MovieController;
        end
 
    end
    
    methods (Access = private)
        
        function obj = processKeyPressAnyTime(obj)
            
             switch double(obj.PressedKey)
                case 28 % left 
                    obj.MovieController =       obj.MovieController.setFrame('previous');
                    
                case 29 %right 
                    obj.MovieController =       obj.MovieController.setFrame('next');
                    
                case 30 % up 
                    obj.MovieController =       obj.MovieController.goOnePlaneUp;
                    
                case 31 %down
                      obj.MovieController =     obj.MovieController.goOnePlaneDown;
                      
             end
            
                switch obj.PressedKey
               
                    case 'a'
                        obj.MovieController =       obj.MovieController.setViews('maskVisibility', 'toggle');

                    case {'c','C'} %% toggle centroids, masks, tracks
                         switch obj.Modifiers
                             case 'Nil'
                                    obj.MovieController = obj.MovieController.setViews('centroidVisibility', 'toggle');
                             case 'command'
                                    obj.MovieController =      obj.MovieController.performTrackingMethod('setSelectedTracks', 'all'); 
                         end

              
                        
                    case 'i'   
                        obj.MovieController =         obj.MovieController.setViews('timeAnnotationVisibility', 'toggle');
                        
                    case 'm' 
                         switch obj.Modifiers
                             case 'Nil'
                                obj.MovieController =   obj.MovieController.setImageMaximumProjection(~obj.MovieController.getViews.getShowMaximumProjection);
                         end
                        
                    case 'o' % crop-toggle
                        obj.MovieController =                  obj.MovieController.setViews('CroppingOn', 'toggle');
                        
                    case {'1', '2', '3', '4', '5', '6', '7', '8', '9'} % channel toggle
                        switch obj.MovieController.getViews.getActiveView    
                            case 'MovieImage'
                                
                                obj.MovieController =   obj.MovieController.setViews('channelVisibility', 'toggleByKeyPress');
                                
                                   
                        end
                               
                    case 'z'
                        obj.MovieController =         obj.MovieController.setViews('planeAnnotationVisibility', 'toggle'); 

                    case {'s','S'}
                        switch obj.Modifiers
                            case 'Nil'
                                 obj.MovieController =      obj.MovieController.setViews('scaleBarVisibility', 'toggle'); 
                        end
                        
                    case 't'
                        obj.MovieController =       obj.MovieController.setViews('trackVisibility', 'toggle');

                    case {'u', 'U'} 
                        switch obj.Modifiers
                            case 'Nil'
                                obj.MovieController =       obj.MovieController.updateAllViewsThatDependOnActiveTrack;
                        end
                        
                   case {'x','X'}  %% navigation shortcuts: first frame, last/ first tracked frame:
                         switch obj.Modifiers
                             case 'Nil'
                                obj.MovieController =      obj.MovieController.setFrame('first');
                                
                                
                                
                             case 'shift'
                                obj.MovieController =      obj.MovieController.setFrame('last');
                                
                            case 'ShiftAndCommand' 
                                obj.MovieController =      obj.MovieController.focusOnActiveMask;
                                
                         end 
        
                end
            
        end
                 
        function obj = processKeypressDuringTracking(obj)
            
            switch obj.PressedKey
                
                  case 'b' 
                         obj.MovieController =           obj.MovieController.performTrackingMethod('addPixelRimToActiveMask');

                  case {'d', 'D'}
                       switch obj.Modifiers
                            case 'Nil' 
                                obj.MovieController =       obj.MovieController.setFrame('lastFrameOfCurrentTrackStretch');
                           case 'shift'
                               obj.MovieController =       obj.MovieController.setFrame('firstFrameOfActiveTrack');
                            case 'ShiftAndCommand'
                                  obj.MovieController =     obj.MovieController.performTrackingMethod('deleteActiveTrack');
                       end       
                         
                case 'e' 
                         obj.MovieController =          obj.MovieController.performTrackingMethod('removePixelRimFromActiveMask');
                     
                         
                case {'f','F'} %% tracking shortcut
                    
                    switch obj.Modifiers
                        case 'Nil' 
                            % currently not recommended option;
                            % using brightest pixels to detect cells and then create 3D mask;
                            % problems: very slow, leads to a lot of double-tracking;
                            
                        case 'shift' 
                                
                        case 'ShiftAndCommand'
                             obj.MovieController =  obj.MovieController.setFinishStatusOfTrackTo('Finished');  
                    end
                    
                   
                        
                    
              case {'g', 'G'}
                 switch obj.Modifiers
                     case 'Nil'
                         obj.MovieController =    obj.MovieController.setActiveTrackTo('firstForwardGapInNextUnfinishedTrack');
                     case 'shift'
                         obj.MovieController =    obj.MovieController.trackGapsForAllTracks('Forward');
                         obj.MovieController =    obj.MovieController.trackGapsForAllTracks('Backward');   
                     case 'ShiftAndCommand'
                         
                         obj.MovieController =    obj.MovieController.setFrame('firstFrameOfCurrentTrackStretch');
                 end
                        
                         
                case {'i', 'I'}
                     switch obj.Modifiers
                         case 'shift'
                             obj.MovieController =  obj.MovieController.setActiveTrackTo('firstForwardGapInNextTrack');
                             
                        case 'ShiftAndCommand'
                            obj.MovieController =  obj.MovieController.setActiveTrackTo('firstForwardGapInNextUnfinishedTrack');
                     end
                    

                case 'l' 
                            obj.MovieController =  obj.MovieController.performTrackingMethod('autoTracking', 'allTracks', 'forwardFromActiveFrame');

                case {'m', 'M'}
                    switch obj.Modifiers
                        case 'shift'
                            obj.MovieController =  obj.MovieController.performTrackingMethod('mergeSelectedTracks');
                        case 'ShiftAndCommand'
                                 obj.MovieController =  obj.MovieController.mergeTracksByProximity;  
                    end
                          
                case {'p', 'P'}
                     switch obj.Modifiers
                        case 'ShiftAndCommand'
                            obj.MovieController =  obj.MovieController.performTrackingMethod('fillGapsOfActiveTrack');  
                     end
                    
                    
                    
                case {'R','r'} 
                    switch obj.Modifiers
                         case 'Nil' 
                             % do both segmentation and tracking of current cell (consecutive) frames from scratch;
                             % this is now mostly replace by 
                              obj.MovieController =              obj.MovieController.performTrackingMethod('autoTracking', 'activeTrack', 'forwardInFirstGap');
                             
                         case 'shift' 
                             % for current track:
                             % if unhappy with the masks of the current track: create 'mini' masks;
                             % this will can be done for 're-creating' masks (re-creating masks ignores current masks that cannot be satisfactarily recreated;
                             obj.MovieController =     obj.MovieController.performTrackingMethod('autoTracking', 'activeTrack',  'convertAllMasksToMiniMasks');

                          case 'command'
                             % for current track, use current centroid as basis and recreate 3D mask by autothresholding surrounding area;
                             obj.MovieController =   obj.MovieController.performTrackingMethod('autoTracking', 'activeTrack',  'convertAllMasksByCurrentSettings');

                    end


                    case {'s','S'}
                         switch obj.Modifiers
                             case 'shift'
                                  obj.MovieController =     obj.MovieController.performTrackingMethod('splitTrackAtFrameAndDeleteFirstPart');  
                             case 'ShiftAndCommand'
                                  obj.MovieController =     obj.MovieController.performTrackingMethod('splitSelectedTracksAndDeleteSecondPart');
                         end
                         
                   case {'t', 'T'}
                     switch obj.Modifiers
                        case 'ShiftAndCommand'
                           obj.MovieController =  obj.MovieController.truncateActiveTrackToFit;  
                     end
                         
                         
                     case {'u','U'}
                         switch obj.Modifiers 
                             case 'ShiftAndCommand'
                                obj.MovieController =  obj.MovieController.setFinishStatusOfTrackTo('Unfinished');
                         end
                          
                    case {'v', 'V'} 
                         switch obj.Modifiers 
                             case 'Nil'
                                obj.MovieController =              obj.MovieController.performTrackingMethod('autoTracking', 'activeTrack', 'backwardInLastGap');
                             case 'command'
                                 obj.MovieController =    obj.MovieController.setActiveTrackTo('backWardGapInNextUnfinishedTrack');
                                 
                            
                         end
                         

                    case 'w'
                        switch obj.Modifiers 
                           case 'command'
                               obj.MovieController =            obj.MovieController.performTrackingMethod('splitTrackAfterActiveFrame');
                        end  
            end
            
        end
        
    end
end

