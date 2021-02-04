classdef PMTrackingNavigationEditViewController
    %PMTRACKINGNAVIGATIONEDITVIEWCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        View
        Model
    end
    
    methods
        function obj = PMTrackingNavigationEditViewController
            %PMTRACKINGNAVIGATIONEDITVIEWCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
          
        end
        
        
         function obj =  resetModelWith(obj, Model, varargin)
            
             if isempty(varargin)
                ForceView =  false;
            else
                ForceView = strcmp(varargin{1}, 'ForceDisplay');
            end
       
            
            obj.Model = Model;
            
            %% also update view under certin conditions
             ViewType =          obj.getHelperViewAction(ForceView);
           
             switch ViewType
                 
                 case 'Create figure'
                    obj =          obj.resetView;
                    obj =          obj.updateView;  
                    figure(obj.View.MainFigure)
                    
                 case 'Update figure'
                    obj =          obj.updateView;  
                    
                 case 'No action'
                     return
                     
             end
             
   
         end
        
         function obj = setCallbacks(obj, varargin)
             NumberOfArguments = length(varargin);
             switch NumberOfArguments
                 case 6
                      obj.View.TrackList.CellSelectionCallback =                  varargin{1};   
                    obj.View.ActiveFrame.ValueChangedFcn =                     varargin{2};   

                    obj.View.EditActiveTrackSelection.ValueChangedFcn =        varargin{3};   
                    obj.View.EditActiveTrackAction.ButtonPushedFcn =           varargin{4};   

                    obj.View.EditSelectedTrackSelection.ValueChangedFcn =       varargin{5};   
                    obj.View.EditSelectedTrackAction.ButtonPushedFcn =         varargin{6};   

                 otherwise
                     error('All possible 6 callbacks must be set simultaneously.')
                 
             end
             
             
         end
              
         
        function obj =  resetView(obj)
            
            obj.View =                                      PMTrackingNavigationEditViewView;
            obj.View.ObjectList.ColumnName =                obj.Model.getFieldNamesOfTrackingCell;
            obj.View.TrackList.ColumnName =                 {'ID', 'Start frame', 'End frame', 'Total frame', 'Missing frames', 'Finished'};
            obj.View.TrackDetail.ColumnName =               obj.Model.getFieldNamesOfTrackingCell;
            obj =                                           obj.updateView;
            
        end
        
       
        
        function obj = updateView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.View.ActiveTrack.Text =             num2str(obj.Model.getIdOfActiveTrack);
            obj =                                   obj.setActiveFrameList;
            NewSelectedTracks =                     arrayfun(@(x) num2str(x), obj.Model.getIdsOfSelectedTracks, 'UniformOutput', false);
            obj.View.SelectedTracks.Items =         NewSelectedTracks;
            obj =                                   obj.setSelectedFrameWith(obj.Model.getActiveFrame);
            obj =                                   obj.updateObjectList;
            obj.View.TrackList.Data =               obj.Model.getTrackSummaryList;
            obj.View.TrackDetail.Data =             obj.Model.getConciseObjectListOfActiveTrack;
            obj =                                   obj.resetSelectedTracksAction;    
        end
        
         function obj = setActiveFrameList(obj)
            obj.View.ActiveFrame.Items =                    arrayfun(@(x) num2str(x), 1 : obj.Model.getMaximumTrackedFrame, 'UniformOutput', false);
         end
        
        
        
        function  obj =             setSelectedFrameWith(obj, Value)
            if ~isempty(obj.View) && isvalid(obj.View.ActiveFrame) && ~isnan(Value) && length(obj.View.ActiveFrame.Value) >= Value
                 obj.View.ActiveFrame.Value =       num2str(Value);
                 obj =                              obj.updateObjectList;
            end
   
        end
        
        
        function   obj =            resetSelectedTracksAction(obj)
             
          
            NumberOfSelectedTracks =            length(obj.Model.getIdsOfSelectedTracks);
             
            SelectedEditAction = obj.View.EditSelectedTrackSelection.Value;
            
            switch NumberOfSelectedTracks
                
                case 0
                    
                    obj.View.EditSelectedTrackAction.Enable = 'off';
                    
                    
                case 1
                    
                    switch SelectedEditAction
                        case  {'Delete tracks','Delete masks','Split tracks'}
                            obj.View.EditSelectedTrackAction.Enable = 'on';
                        otherwise
                            obj.View.EditSelectedTrackAction.Enable = 'off';
                            
                    end
                    
                    
                case 2
                    
                     switch SelectedEditAction
                        case  {'Delete tracks','Delete masks','Merge tracks'}
                            obj.View.EditSelectedTrackAction.Enable = 'on';
                        otherwise
                            obj.View.EditSelectedTrackAction.Enable = 'off';
                            
                    end
                    
                otherwise
                    
                     switch SelectedEditAction
                        case  {'Delete tracks','Delete masks'}
                            obj.View.EditSelectedTrackAction.Enable = 'on';
                        otherwise
                            obj.View.EditSelectedTrackAction.Enable = 'off';
                            
                    end
                    
                
                
            end
             
             
             
            
        end
        
        function obj =              updateObjectList(obj)
            FrameNumber =                           str2double(obj.View.ActiveFrame.Value);
            obj.View.ObjectList.Data =              obj.Model.getConciseObjectListOfFrame(FrameNumber); 
        end
        
        
       function Action =            getHelperViewAction(obj,ForceView)
            
             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) % movie controller there but figure was closed
                if ForceView
                    Action = 'Create figure';
                    
                else
                    Action = 'No action';
                end
                
            else % if a figure is there;
                Action = 'Update figure';
                
             end

     end
        
        
        
        
        
        
        function FigureHandle = getFigureHandle(obj)
            if isempty(obj.View)
                FigureHandle = '';
            else
                FigureHandle = obj.View.MainFigure;
            end
        end
  
        
    end
end

