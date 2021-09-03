classdef PMTrackingNavigationEditViewController
    %PMTRACKINGNAVIGATIONEDITVIEWCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        View
        Model

    end
    
    methods
        
        function obj = PMTrackingNavigationEditViewController
            %PMTRACKINGNAVIGATIONEDITVIEWCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function Value = getCurrentCharacter(obj)
            FigureHandle =  obj.View.getFigureHandle;
            Value  = obj.View.getFigureHandle.CurrentCharacter;
            FigureHandle.CurrentCharacter = '0';
        end
        
        function Value = getSelectedFrame(obj)
            Value = obj.View.getSelectedFrame;
            
        end
        
        function Value = getSelectedActionForSelectedTracks(obj)
            Value = obj.View.getSelectedActionForSelectedTracks.Value;
        end
        
         function Value = getSelectedActionForActiveTrack(obj)
            Value = obj.View.getSelectedActionForActiveTrack.Value;
         end
        
         function obj = updateBasicViewWith(obj, Model)
             
         end
         
         function obj = resetForActiveTrackWith(obj, Model)
             obj.Model =     Model;
             obj =           obj.setViews('');
             
             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) 
             else
              obj.View =         obj.View.updateActiveTrackChangeWith(obj.Model);
             end
         end
         
         function obj = resetForFinishedTracksWith(obj, Model)
             obj.Model =     Model;
             obj =           obj.setViews('');
             
             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) 
             else
              obj.View =         obj.View.updateFinishedTracksChangeWith(obj.Model);
             end
         end
         
         function obj =  resetModelWith(obj, Model, varargin)
           
            obj.Model =     Model;
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    Input = '';
                case 1
                    Input = varargin{1};
                otherwise
                    error('Wrong input.')
            end
            
            obj =           obj.setViews(Input);
       
             if  isempty(obj.getFigureHandle) || ~isvalid(obj.getFigureHandle) 
             else
                 obj.View =         obj.View.updateWith(obj.Model);

             end
         end
         
         function obj = setViews(obj, Input)
             if isempty(Input)
                ForceView =  false;
            else
                ForceView = strcmp(Input, 'ForceDisplay');
             end
            
                switch obj.getHelperViewAction(ForceView)
                 case 'Create figure'
                    obj.View =                             PMTrackingNavigationEditViewView;
                    
                 case 'Update figure'
                    
                 case 'No action'

                end

         end

         function obj = setCallbacks(obj, varargin)
             obj.View =     obj.View.setCallbacks(varargin{:}); 
         end
                   
    end

    methods (Access = private)
        
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
                FigureHandle = obj.View.getFigureHandle;
            end
        end
 
    end
    
    
    
end

