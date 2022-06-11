classdef PMTrackingNavigationController
    %PMTRACKINGNAVIGATIONEDITVIEWCONTROLLER mediates interaction between PMTrackingNavigation and PMTrackingNavigationView;
    
    properties (Access = private)
        View
        Model

    end
    
    methods % INITIALIZE
        
          function obj = PMTrackingNavigationController(varargin)
                %PMTRACKINGNAVIGATIONEDITVIEWCONTROLLER Construct an instance of this class
                %   takes 0, 1 or 2 arguments:
                % 1: PMTrackingNavigation
                % 2: PMTrackingNavigationView
                switch length(varargin)
                   
                    case 0
                        obj.Model = PMTrackingNavigation;
                         obj.View = PMTrackingNavigationView;
                    case 1
                        
                        obj.Model = varargin{1};
                         obj.View = PMTrackingNavigationView;
                        
                    case 2
                        obj.Model = varargin{1};
                        obj.View = varargin{2};
                        
                    otherwise
                        error('Wrong input.')
                    
                    
                end
                
               
            
          end
          
          function obj = set.Model(obj, Value)
              assert(isscalar(Value) && isa(Value, 'PMTrackingNavigation'), 'Wrong input.')
             obj.Model = Value; 
          end
          
          function obj = set.View(obj, Value)
              assert(isscalar(Value) && isa(Value, 'PMTrackingNavigationView'), 'Wrong input.')
             obj.View = Value; 
          end
        
        
    end
    
    methods % SETTERS MODEL (AND VIEW):
        
        function obj =      performMethod(obj, Value, varargin)
            assert(ischar(Value), 'Wrong input.')
            if isempty( obj.Model )
               obj.Model = PMTrackingNavigation; 
            end
            obj.Model = obj.Model.(Value)(varargin{:});


                if isempty(obj.View) || isempty(obj.Model)

                else
                  obj.View =          obj.View.updateWith(obj.Model);

                end

        end

        function obj =      resetModelWith(obj, Model)
             % RESETMODELWITH set model (and view if available);

            obj.Model =     Model;
             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) 
             else
                 obj.View =         obj.View.updateWith(obj.Model);

             end
        end

        function obj =      resetForActiveTrackWith(obj, Model)
             obj.Model =     Model;

             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) 
             else
              obj.View =         obj.View.updateActiveTrackChangeWith(obj.Model);
         end


        end

        function obj =      resetForFinishedTracksWith(obj, Model)
             obj.Model =     Model;


             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) 
             else
              obj.View =         obj.View.updateFinishedTracksChangeWith(obj.Model);
             end
        end
    
    end
    
    methods % SETTERS FOR VIEW ONLY:

        function obj =       setView(obj, Value)
            obj.View = Value; 
        end
        
        function obj =      updateView(obj)
        obj.View =          obj.View.updateWith(obj.Model);

        end

        function obj =      setCallbacks(obj, varargin)
        obj.View =     obj.View.setCallbacks(varargin{:}); 
        end

        function obj =      show(obj)
        obj.View =          obj.View.show;
        obj.View =          obj.View.updateWith(obj.Model);

        end

        
    end
    
    methods % GETTERS FROM MODEL
       
         function Value = get(obj, Value, varargin)
            Value = obj.Model.get(Value, varargin{:});
            
        end
        
    end
    
    methods % GETTERS FROM VIEW
        
        function Value =    getView(obj)
        if isempty(obj.View)
           Value = PMTrackingNavigationView ;
        else
            Value = obj.View; 
        end

        end

        function Value =    getCurrentCharacter(obj)
        FigureHandle =  obj.View.getFigureHandle;
        Value  = obj.View.getFigureHandle.CurrentCharacter;
        FigureHandle.CurrentCharacter = '0';
        end

        function Value =    getSelectedFrame(obj)
        Value = obj.View.getSelectedFrame;

        end

        function Value =    getSelectedActionForSelectedTracks(obj)
        Value = obj.View.getSelectedActionForSelectedTracks;
        end

        function Value =    getSelectedActionForActiveTrack(obj)
        Value = obj.View.getSelectedActionForActiveTrack;
        end
          
    end

    methods (Access = private)
        
        function Action =               getHelperViewAction(obj,ForceView)

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

        function FigureHandle =         getFigureHandle(obj)
            if isempty(obj.View)
                FigureHandle = '';
            else
                FigureHandle = obj.View.getFigureHandle;
            end
        end
 
    end
    
    
    
end

