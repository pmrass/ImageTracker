classdef PMMovieController_MouseAction
    %PMMOVIECONTROLLER_MOUSEACTION Executes PMMovieController action based on user input;
    %   specifically responds to mouse button press and release, and to mouse-movement;
    
    properties (Access= private)
        PressedKey
        MovieController
        Modifiers
        
    end
    
    methods
        
        function obj =                  PMMovieController_MouseAction(varargin)
            %PMMOVIECONTROLLER_MOUSEACTION Construct an instance of this class
            %   takes 3 arguments:
            % 1: PMMovieController
            % 2: pressed key
            % 3: modifier
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 3
                    obj.MovieController =   varargin{1};
                    obj.PressedKey =        varargin{2};
                    obj.Modifiers =         PMKeyModifiers(varargin{3}).getNameOfModifier;
                otherwise
                    error('Wrong input.')
                
            end
         
          
        end
        
        function myMovieController =    mouseButtonPressed(obj)
            % MOUSEBUTTONPRESSED mediates response to mouse button press;
            % returns PMMovieController object;

               if obj.MovieController.verifyActiveMovieStatus
                 
                   obj =                    obj.setMouseAction;

                   if strcmp(obj.MovieController.interpretMouseMovement, 'Out of bounds')
                       % obj.MovieController = obj.MovieController.setMouseAction('No action');
                     
                   end

               else
                   warning('No active movie. Cannot process request.')

               end
               myMovieController = obj.MovieController;
               
               obj =    obj.userSelectedText;

        end
        
        function obj =                  userSelectedText(obj)
            % USERSELECTEDTEXT prints set mouse action
            fprintf('User selected %s.\n', obj.MovieController.getMouseAction)
            
            
        end
           
        function myMovieController =    mouseMoved(obj)
            % MOUSEMOVED mediates response to mouse movement;

            if obj.MovieController.verifyActiveMovieStatus
                 obj = obj.perforActionDuringMouseDrag;
            end
            myMovieController = obj.MovieController;

        end

        function myMovieController =    mouseButtonReleased(obj)
            % mouseButtonReleased mediates response to mouse button release;

             switch obj.MovieController.interpretMouseMovement
                    case 'Stay'
                        obj = obj.performActionUponKeyReleaseWhenImmotile;
                    case 'Movement'
                        obj = obj.performActionUponKeyReleaseWhenMoving;
                end
            
            obj.MovieController =       obj.MovieController.setMouseAction('No action');  
            %  obj.MovieController =       obj.MovieController.blackOutStartMousePosition;
            myMovieController =         obj.MovieController;

        end


    end
        
     methods (Access = private)
        
         %% setMouseAction:
             function obj = setMouseAction(obj)
               
               obj = obj.setDefaultMouseAction;
               
               if ~isempty(obj.MovieController.getViews)
               
                    switch obj.MovieController.getViews.getEditingType
                        case 'No editing'

                        case 'Manual drift correction'
                            obj = obj.setMouseActionForDriftCorrection;
                        case 'Tracking'
                            obj = obj.setMouseActionForTracking;
                        otherwise
                            error('Eding type not supported.')

                    end

               end
           end
           
           function obj = setDefaultMouseAction(obj)
               switch obj.Modifiers

                   case 'shift'
                          obj.MovieController =       obj.MovieController.setMouseAction('DrawLine');

                    case 'control'
                        obj.MovieController =       obj.MovieController.setMouseAction('MoveViewOrChangeTrack');
                    case 'alt'
                        obj.MovieController =       obj.MovieController.setMouseAction('Draw rectangle');
                    case 'ShiftAndControl'
                            obj.MovieController =   obj.MovieController.setMouseAction('SetSelectedTrackByMousePosition');
                    case 'ShiftAndAlt'
                            obj.MovieController =   obj.MovieController.setMouseAction('AddSelectedTrackByMousePosition');
                   case 'ControlAndCommand'
                        obj.MovieController =       obj.MovieController.setMouseAction('AddClickedPointAsCentroid');
                   otherwise
                      obj =                         obj.processUnknownInput;
               end
               
           end
           
           function obj = processUnknownInput(obj)
                  obj.MovieController = obj.MovieController.setMouseAction('No action'); 
           end
           
           function obj = setMouseActionForDriftCorrection(obj)
               switch obj.Modifiers
                    case 'shift'
                        obj.MovieController =           obj.MovieController.setMouseAction('Edit current manual drift correction');
                   case 'command'
                      obj.MovieController =           obj.MovieController.setMouseAction('Edit future manual drift correction');
                   otherwise
                        obj = obj.processUnknownInput;

               end
           end
           
           function obj = setMouseActionForTracking(obj)
                 switch obj.Modifiers
                     case 'Nil'
                          obj.MovieController =    obj.MovieController.setMouseAction('Add clicked mask to active track');
                     case 'shift'
                         obj.MovieController =    obj.MovieController.setMouseAction('Add clicked mask to new track');
                    case 'command'
                           obj.MovieController =    obj.MovieController.setMouseAction('Subtract pixels');
                     case 'ShiftAndCommand'
                            obj.MovieController =   obj.MovieController.setMouseAction('Add pixels');
                    
              
                 end
           end
     
     
       
        function obj = perforActionDuringMouseDrag(obj)
 
            switch obj.MovieController.getMouseAction

                case 'No action'
                   

                case 'DrawLine'
                        obj.MovieController =      obj.MovieController.addCoordinatesToLine;
        
                case 'Draw rectangle'
                        switch obj.MovieController.interpretMouseMovement
                              case 'Movement'
                                obj.MovieController =           obj.MovieController.setViews('CroppingGate', 'changePositionByMouseDrag');  
                              case {'Invalid', 'Out of bounds'}
                                  
                               
                                  
                                  obj.MovieController =         obj.MovieController.setDefaultCroppingGate;

                         end

                 case 'MoveViewOrChangeTrack'
                        switch obj.MovieController.interpretMouseMovement
                              case 'Movement'
                                  obj.MovieController =         obj.MovieController.resetAxesCenterByMouseMovement;
                                  
                               
                        end

                case 'Add pixels'
                      switch obj.MovieController.interpretMouseMovement
                        case {'Movement', 'Stay'}
                             obj.MovieController =      obj.MovieController.highLightRectanglePixelsByMouse;
                      end
                      
                case 'Subtract pixels'
                      switch obj.MovieController.interpretMouseMovement
                        case {'Movement', 'Stay'}
                             obj.MovieController =      obj.MovieController.highLightRectanglePixelsByMouse;  
                      end

                case 'AddSelectedTrackByMousePosition'
                     switch obj.MovieController.interpretMouseMovement
                        case {'Movement', 'Stay'}
                        
                      end

                case 'Edit current manual drift correction'
                     switch obj.MovieController.interpretMouseMovement 
                        case {'Movement', 'Stay'}
                     end

                otherwise
                    warning('Type not supported.')

            end

        end
        
        %% performActionUponKeyRelease:
      

         function obj = performActionUponKeyReleaseWhenImmotile(obj)

            switch obj.MovieController.getMouseAction



                case 'AutoTrackCurrentCell'
                    obj.MovieController =       obj.MovieController.autoTrackCurrentCell; 
                    
                case 'SetSelectedTrackByMousePosition'
                    obj.MovieController =       obj.MovieController.performTrackingMethod('setSelectedTracks', 'byMousePosition');
                    
                case 'AddSelectedTrackByMousePosition'
                  obj.MovieController =         obj.MovieController.performTrackingMethod('addSelectedTracks', 'byMousePosition');
                    
                case 'MoveViewOrChangeTrack'
                    obj.MovieController =       obj.MovieController.setActiveTrackTo('byMousePositition');

                case 'Add clicked mask to new track'
                    fprintf('Mouse action: create new track and add mask by click position.\n')
                    obj.MovieController =       obj.MovieController.performTrackingMethod('addButtonClickMaskToNewTrack');

                case 'Add clicked mask to active track'
                    fprintf('Mouse action: add mask to current track by click position.\n')
                       obj.MovieController =   obj.MovieController.performTrackingMethod('updateActiveMaskByButtonClick');
                        
                case 'Subtract pixels'
                    obj.MovieController =   obj.MovieController.performTrackingMethod('removeHighlightedPixelsFromActiveMask');
                    
                case 'AddClickedPointAsCentroid'
                    obj.MovieController =   obj.MovieController.performTrackingMethod('usePressedCentroidAsMask');
                    
                case 'Edit current manual drift correction'
                    obj.MovieController =   obj.MovieController.setDriftCorrection('Manual', 'currentFrameByButtonPress');
                    
                case 'Edit future manual drift correction'
                      obj.MovieController =   obj.MovieController.setDriftCorrection('Manual', 'currentAndConsecutiveFramesByButtonPress');
            end

         end
         

         function obj = performActionUponKeyReleaseWhenMoving(obj)
              switch obj.MovieController.getMouseAction


                case 'DrawLine'

                   MyLine =   obj.MovieController.exportLine;

                  case 'Add pixels'
                         obj.MovieController =   obj.MovieController.performTrackingMethod('addHighlightedPixelsFromMask');

                    case 'Subtract pixels'
                         obj.MovieController =   obj.MovieController.performTrackingMethod('removeHighlightedPixelsFromActiveMask');

                    case 'SetSelectedTrackByMousePosition'
                          obj.MovieController = obj.MovieController.performTrackingMethod('setSelectedTracks', 'all');
                             
              end
         end
        
     end    
end