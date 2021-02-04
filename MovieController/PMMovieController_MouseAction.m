classdef PMMovieController_MouseAction
    %PMMOVIECONTROLLER_MOUSEACTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access= private)
        MovieController
    end
    
    methods
        function obj = PMMovieController_MouseAction(Object)
            %PMMOVIECONTROLLER_MOUSEACTION Construct an instance of this class
            %   Detailed explanation goes here
            obj.MovieController = Object;
            
            
        end
        
           function myMovieController =    mouseMoved(obj)

             if strcmp(obj.MovieController.getMouseAction, 'No action')
                obj.MovieController =       obj.MovieController.setMouseDownRow(NaN);
                obj.MovieController =         obj.MovieController.setMouseDownColumn(NaN);
                
                obj.MovieController =              obj.MovieController.setMouseUpRow(NaN);
                obj.MovieController =           obj.MovieController.setMouseUpColumn(NaN);

                myMovieController = obj.MovieController;
                  return
              end
              
              if obj.MovieController.verifyActiveMovieStatus
                        
                        %% update current position in object: 
                        MovieAxes =                                         obj.MovieController.getViews.MovieView.ViewMovieAxes;
                        obj.MovieController =              obj.MovieController.setMouseUpRow(MovieAxes.CurrentPoint(1,2));
                        obj.MovieController =           obj.MovieController.setMouseUpColumn(MovieAxes.CurrentPoint(1,1));
                        
                        %% interpret mouse pattern:
                        mousePattern =                                      obj.MovieController.interpretMouseMovement;
                        switch obj.MovieController.getMouseAction
                            case 'Draw rectangle'
                                switch mousePattern
                                      case 'Movement'
                                        obj.MovieController =                   obj.MovieController.setCroppingGateByMouseDrag;  
                                      case {'Invalid', 'Out of bounds'}
                                          obj.MovieController =         obj.MovieController.setDefaultCroppingGate;
                                          
                                 end
                                
                            case 'MoveViewOrChangeTrack'
                                switch mousePattern
                                      case 'Movement'
                                          XMovement =                       obj.MovieController.getMouseUpColumn - obj.MovieController.getMouseDownColumn;
                                          YMovement =                       obj.MovieController.getMouseUpRow - obj.MovieController.getMouseDownRow;
                                          obj.MovieController =       obj.MovieController.resetAxesCenter(XMovement, YMovement);
   
                                end
                        
                            case 'Subtract pixels'
                                  switch mousePattern
                                    case {'Movement', 'Stay'}
                                         [Coordinates] =     obj.MovieController.getCoordinateListByMousePositions;
                                            obj.MovieController =                                obj.MovieController.highLightRectanglePixelsByMouse([Coordinates(:, 2), Coordinates(:, 1)]);  
                                  end
                                
                            case 'Add pixels'
                                  switch mousePattern
                                    case {'Movement', 'Stay'}
                                         obj.MovieController =   obj.MovieController.addHighlightedPixelsFromMask;
                                  end
                                  
                            case 'UsePressedPointAsCentroid'
                                 switch mousePattern
                                    case {'Movement', 'Stay'}
                                         obj.MovieController =   obj.MovieController.usePressedCentroidAsMask;
                                  end
                                   
                            case 'Edit manual drift correction'
                                 switch mousePattern 
                                    case {'Movement', 'Stay'}
                                  end
                                     
                        end
                                
              end

                myMovieController = obj.MovieController;
                
               
           end
           

           function myMovieController = mouseButtonPressed(obj)

                MovieAxes =                 obj.MovieController.getViews.MovieView.ViewMovieAxes;
                obj.MovieController =       obj.MovieController.setMouseDownRow(MovieAxes.CurrentPoint(1,2));
                obj.MovieController =       obj.MovieController.setMouseDownColumn(MovieAxes.CurrentPoint(1,1));
                             
                if strcmp(obj.MovieController.interpretMouseMovement, 'Out of bounds')
                    obj.MovieController = obj.MovieController.setMouseAction('No action');
                    
                else
                    
                    if obj.MovieController.verifyActiveMovieStatus
                        
                        switch obj.getNameOfModifier
                            case 'Nil'
                            case 'shift'
                                switch obj.MovieController.getViews.getEditingType
                                    case 'Manual drift correction'
                                        obj.MovieController =           obj.MovieController.setMouseAction('Edit manual drift correction');
                                        [rowFinal, columnFinal, planeFinal, frame] =     obj.MovieController.getCoordinatesOfButtonPress;
                                        obj.MovieController =               obj.MovieController.setManualDriftCorrectionByTimeSpaceCoordinates([frame, columnFinal, rowFinal,  planeFinal] );

                                    otherwise
                                        obj.MovieController = obj.MovieController.setMouseAction('No action');
                                end

                            case 'control'
                                obj.MovieController = obj.MovieController.setMouseAction('MoveViewOrChangeTrack');

                            case 'alt'
                                obj.MovieController = obj.MovieController.setMouseAction('Draw rectangle');

                            case 'command'
                                switch obj.MovieController.getViews.getEditingType
                                    case 'Tracking'
                                        obj.MovieController = obj.MovieController.setMouseAction('Subtract pixels');
                                    otherwise
                                        obj.MovieController = obj.MovieController.setMouseAction('No action');
                                end 

                             case 'ShiftAndCommand'
                                switch obj.MovieController.getViews.getEditingType
                                    case 'Tracking'
                                        obj.MovieController =           obj.MovieController.setMouseAction('Add pixels');
                                    otherwise
                                        obj.MovieController = obj.MovieController.setMouseAction('No action');
                                end

                            case 'ShiftAndControl'
                                obj.MovieController = obj.MovieController.setMouseAction('ConnectTrackToActiveTrack');

                            case 'ShiftAndAlt'
                                obj.MovieController = obj.MovieController.setMouseAction('UsePressedPointAsCentroid');

                            otherwise
                                fprintf('Mouse input not recognized. No action taken.\n')
                                obj.MovieController = obj.MovieController.setMouseAction('No action'); 

                        end
                       
                    end
 
                end
                
                 myMovieController = obj.MovieController;
           
           end
           
            
           function myMovieController = mouseButtonReleased(obj)

                switch obj.MovieController.getViews.getEditingType
                    case 'Tracking'
                        switch obj.MovieController.interpretMouseMovement
                            case {'Movement', 'Stay'}
                                switch obj.getNameOfModifier
                                    case 'shift'
                                        fprintf('Mouse action: create new track and add mask by click position.\n')
                                        obj.MovieController =   obj.MovieController.addMaskToNewTrackByButtonClick;
                                    case 'Nil'
                                        fprintf('Mouse action: add mask to current track by click position.\n')
                                        obj.MovieController =     obj.MovieController.updateActiveMaskByButtonClick;
                                end      
                        end   
                end
               
               
                    if strcmp(obj.MovieController.getMouseAction, 'No action')
                        obj.MovieController =           obj.MovieController.setMouseDownRow(NaN);
                        obj.MovieController =           obj.MovieController.setMouseDownColumn(NaN);
                        obj.MovieController =           obj.MovieController.setMouseUpRow(NaN);
                        obj.MovieController =           obj.MovieController.setMouseUpColumn(NaN);
                        
                    else
                        MovieAxes =                 obj.MovieController.getViews.MovieView.ViewMovieAxes;
                        obj.MovieController =       obj.MovieController.setMouseUpRow(MovieAxes.CurrentPoint(1,2));
                        obj.MovieController =       obj.MovieController.setMouseUpColumn(MovieAxes.CurrentPoint(1,1));

                          switch obj.MovieController.getMouseAction
                            

                            case 'Draw rectangle'
                                 switch obj.MovieController.interpretMouseMovement
                                      case 'Stay'
                                      case {'Invalid', 'Out of bounds'}
                                 end

                             case 'Subtract pixels'
                                  switch obj.MovieController.interpretMouseMovement
                                        case {'Movement', 'Stay'}
                                            obj.MovieController =   obj.MovieController.removeHighlightedPixelsFromMask;
                                  end

                            case 'Add pixels'
                              switch obj.MovieController.interpretMouseMovement
                                case {'Movement', 'Stay'}
                              end

                            case 'UsePressedPointAsCentroid'
                                   obj.MovieController =   obj.MovieController.usePressedCentroidAsMask;  

                            case 'AutoTrackCurrentCell'
                                switch obj.MovieController.interpretMouseMovement
                                    case { 'Stay'}
                                        obj.MovieController =   obj.MovieController.autoTrackCurrentCell;    
                                end

                           case 'MoveViewOrChangeTrack'
                                switch obj.MovieController.interpretMouseMovement
                                    case 'Stay'
                                        obj.MovieController = obj.MovieController.resetActiveTrackByMousePosition;
                                end

                            case 'ConnectTrackToActiveTrack'
                                switch obj.MovieController.interpretMouseMovement
                                    case 'Stay'
                                        obj.MovieController =             obj.MovieController.connectSelectedTrackToActiveTrack;
                                        obj.MovieController =            obj.MovieController.updateAllViewsThatDependOnActiveTrack;

                                end        
                          end
                        obj.MovieController =      obj.MovieController.setMouseAction('No action');  
                        obj.MovieController =      obj.MovieController.setMouseDownRow(NaN);
                        obj.MovieController =   obj.MovieController.setMouseDownColumn(NaN);

                    end
                    myMovieController = obj.MovieController;

            end
  
    end
    
    
     methods (Access = private)
        
         function number = getNumberOfModifiers(obj)
             number = size(obj.MovieController.getViews.Figure.CurrentModifier,2);
             
         end
         
         function NameOfModifier = getNameOfModifier(obj)
             switch getNumberOfModifiers(obj)
                
                 case 0
                     NameOfModifier = 'Nil';
                 case 1
                    NameOfModifier = obj.MovieController.getViews.Figure.CurrentModifier{1,1};
                 case 2
                     if max(strcmp(obj.MovieController.getViews.Figure.CurrentModifier, 'shift')) && max(strcmp(obj.MovieController.getViews.Figure.CurrentModifier, 'command'))
                        NameOfModifier = 'ShiftAndCommand';
                    elseif max(strcmp(obj.MovieController.getViews.Figure.CurrentModifier, 'shift')) && max(strcmp(obj.MovieController.getViews.Figure.CurrentModifier, 'control'))
                        NameOfModifier = 'ShiftAndControl';
                    elseif max(strcmp(obj.MovieController.getViews.Figure.CurrentModifier, 'shift')) && max(strcmp(obj.MovieController.getViews.Figure.CurrentModifier, 'alt'))
                        NameOfModifier = 'ShiftAndAlt';   
                    else
                        NameOfModifier = 'unknown';
                     end
                 
                 otherwise
                     fprintf('\nUnkown modifer pressed.\n')
                     NameOfModifier = 'Unknown';
                 
             end
             
             fprintf('\nClicked modifier = %s.\n', NameOfModifier)
             
               
                                
         end
        
        
        
     end
    
end

