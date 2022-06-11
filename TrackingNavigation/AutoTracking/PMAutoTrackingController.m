classdef PMAutoTrackingController
    %PMAUTOTRACKINGCONTROLLER manages properties relevant for autotracking;
    % mediates interaction between PMAutoTrackingView and PMAutoTracking
    
    properties (Access = private)
        Model
        View
    end
    
    methods
        
        function obj = PMAutoTrackingController
            %PMAUTOTRACKINGCONTROLLER Construct an instance of this class
            %   takes 0 arguments
            
        end
        
        function obj = resetModelWith(obj, Model, varargin)
            %RESETMODELWITH set model with value
            %  takes 1 or 2 arguments:
            % 1: PMTrackingNavigation
            % 2: 'ForceDisplay': forces view to be generated
            % updates model and depednent views (if applicable)
            obj.Model = Model;
            
             %% also update view under certain conditions
             if isempty(varargin)
                ForceView =  false;
            else
                ForceView = strcmp(varargin{1}, 'ForceDisplay');
             end

             switch obj.getHelperViewAction(ForceView)
                 
                 case 'Create figure'
                    obj =           obj.resetView;
                    obj =           obj.updateView;  
                    obj.View =      obj.View.show;
                    
                 case 'Update figure'
                    obj =          obj.updateView;  
                    
                 case 'No action'
                     
             end

        end
        
        function obj = set.Model(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMAutoTracking'), 'Wrong input.')
           obj.Model = Value; 
        end
        
        function obj = set.View(obj, Value)
             assert(isscalar(Value) && isa(Value, 'PMAutoTrackingView'), 'Wrong input.')
           obj.View = Value; 
        end
        
    end
    
    methods % SETTERS
       
        function obj =      setModelByView(obj)
            obj.Model = obj.Model.set(obj.View);
            
        end
      
        function obj =      setView(obj, Value)
           obj.View = Value; 
        end
        
        function obj =      setCallbacks(obj, varargin)
            obj.View = obj.View.setCallbacks( varargin{:});
        end
        
    end
    
    methods % GETTERS
        
        function view =             getModel(obj)
            view = obj.Model;
        end
        
        function view =             getView(obj)
            view = obj.View;
        end
        
        function selection =        getUserSelection(obj)
            selection = obj.View.getSelectedProcedure;
       
        end
        
        
    end
    
    methods (Access = private)
        
        function obj =              updateView(obj)
             obj.View = obj.View.set(obj.Model);
        end
       
        function obj =              resetView(obj)
            obj.View = PMAutoTrackingView;
            
        end
        
        function Action =           getHelperViewAction(obj, ForceView)

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
        
        function FigureHandle =     getFigureHandle(obj)
             if isempty(obj.View)
                 FigureHandle = '';
             else
                 FigureHandle  = obj.View.getFigureHandle;
                
             end
        end
        
    end
    
end

