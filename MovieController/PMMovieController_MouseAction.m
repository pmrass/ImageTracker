classdef PMMovieController_MouseAction
    %PMMOVIECONTROLLER_MOUSEACTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access= private)
        PressedKey
        MovieController
        Modifiers
        
    end
    
    methods
        
        function obj = PMMovieController_MouseAction(varargin)
            %PMMOVIECONTROLLER_MOUSEACTION Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 3
                    obj.MovieController =   varargin{1};
                    obj.PressedKey =        varargin{2};
                    obj.Modifiers =         PMKeyModifiers(varargin{3}).getNameOfModifier;
                otherwise
                    error('Wrong input.')
                
            end
            obj.MovieController =           obj.MovieController.setMouseEndPosition;
          
        end
        
        function myMovieController = mouseButtonPressed(obj)

               if obj.MovieController.verifyActiveMovieStatus
                   obj.MovieController =    obj.MovieController.setCurrentDownPositions;
                   obj =                    obj.setMouseAction;

                   if strcmp(obj.MovieController.interpretMouseMovement, 'Out of bounds')
                        obj.MovieController = obj.MovieController.setMouseAction('No action');
                     
                   end

               else
                   warning('No active movie. Cannot process request.')

               end
               myMovieController = obj.MovieController;
               
               obj =    obj.userSelectedText;

        end
        
        function obj = userSelectedText(obj)
            fprintf('User selected %s.\n', obj.MovieController.getMouseAction)
            
            
        end
           
       
           %% mouseMoved:
           function myMovieController =    mouseMoved(obj)
                if obj.MovieController.verifyActiveMovieStatus
                     obj = obj.perforActionDuringMouseDrag;
                end
                myMovieController = obj.MovieController;
           end
           
           
           
            
           function myMovieController = mouseButtonReleased(obj)
               try 
                obj =                       obj.performActionUponKeyRelease;
                   catch E
                   throw(E) 
               end
                
                obj.MovieController =       obj.MovieController.setMouseAction('No action');  
                obj.MovieController =       obj.MovieController.blackOutStartMousePosition;
                myMovieController =         obj.MovieController;

           end
            
          
  
    end
    
    
     methods (Access = private)
        
         %% setMouseAction:
             function obj = setMouseAction(obj)
               
               obj = obj.setDefaultMouseAction;
               
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
           
           function obj = setDefaultMouseAction(obj)
               switch obj.Modifiers
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
     
     
        %% perforActionDuringMouseDrag:
        function obj = perforActionDuringMouseDrag(obj)
 
            switch obj.MovieController.getMouseAction
                case 'No action'
                    obj.MovieController =      obj.MovieController.blackOutMousePositions;

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

            end

        end
        
        %% performActionUponKeyRelease:
         function obj = performActionUponKeyRelease(obj)

                switch obj.MovieController.interpretMouseMovement
                    case 'Stay'
                        try 
                            obj = obj.performActionUponKeyReleaseWhenImmotile;
                               catch E
                           throw(E) 
                        end
                    case 'Movement'
                        obj = obj.performActionUponKeyReleaseWhenMoving;
                end

                    
         end

         function obj = performActionUponKeyReleaseWhenImmotile(obj)

            switch obj.MovieController.getMouseAction
                case 'AutoTrackCurrentCell'
                    obj.MovieController =   obj.MovieController.autoTrackCurrentCell; 
                    
                case 'SetSelectedTrackByMousePosition'
                    obj.MovieController = obj.MovieController.performTrackingMethod('setSelectedTracks', 'byMousePosition');
                    
                case 'AddSelectedTrackByMousePosition'
                  obj.MovieController = obj.MovieController.performTrackingMethod('addSelectedTracks', 'byMousePosition');
                    
                case 'MoveViewOrChangeTrack'
                    obj.MovieController = obj.MovieController.setActiveTrackTo('byMousePositition');

                case 'Add clicked mask to new track'
                    fprintf('Mouse action: create new track and add mask by click position.\n')
                    obj.MovieController =   obj.MovieController.performTrackingMethod('addButtonClickMaskToNewTrack');

                case 'Add clicked mask to active track'
                    fprintf('Mouse action: add mask to current track by click position.\n')
                    try 
                        obj.MovieController =     obj.MovieController.performTrackingMethod('updateActiveMaskByButtonClick');
                    catch E
                       throw(E) 
                    end
                        
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