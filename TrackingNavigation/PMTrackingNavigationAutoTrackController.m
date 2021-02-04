classdef PMTrackingNavigationAutoTrackController
    %PMTRACKINGNAVIGATIONCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Model
        View
    end
    
    methods
        function obj = PMTrackingNavigationAutoTrackController
            %PMTRACKINGNAVIGATIONCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
        function obj = resetModelWith(obj, Model, varargin)
            
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Model = Model;
            
             %% also update view under certain conditions
             if isempty(varargin)
                ForceView =  false;
            else
                ForceView = strcmp(varargin{1}, 'ForceDisplay');
             end

             switch obj.getHelperViewAction(ForceView)
                 case 'Create figure'
                    obj =          obj.resetView;
                    obj =          obj.updateView;  
                    figure(obj.View.MainFigure)
                    
                 case 'Update figure'
                    obj =          obj.updateView;  
                    
                 case 'No action'
                     
             end

        end
        
        function view = getView(obj)
            view = obj.View;
        end
        
        function selection = getUserSelection(obj)
            selection = obj.View.ProcedureSelection.Value;
        end
        
        function obj = setCallbacks(obj, varargin)
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 7
                    
                    obj.View.MaximumAcceptedDistanceForAutoTracking.ValueChangedFcn =               varargin{1};  
                    obj.View.FirstPassDeletionFrameNumber.ValueChangedFcn =                         varargin{2};  
                    obj.View.AutoTrackingConnectionGaps.ValueChangedFcn =           varargin{3};  
                    obj.View.DistanceLimitXYForTrackMerging.ValueChangedFcn =       varargin{4};  
                    obj.View.DistanceLimitZForTrackingMerging.ValueChangedFcn =     varargin{5};  
                    obj.View.ShowDetailedMergeInformation.ValueChangedFcn =         varargin{6};  
                    obj.View.StartButton.ButtonPushedFcn =                          varargin{7};  

                otherwise
                    errror('Wrong number of input arguments.')
                
            end
            
        end
        
        
            
        
    end
    
    methods (Access = private)
        
         function obj =  updateView(obj)
            
            obj.View.MaximumAcceptedDistanceForAutoTracking.Value =           num2str(obj.Model.getMaximumAcceptedDistanceForAutoTracking);
            obj.View.FirstPassDeletionFrameNumber.Value =                     num2str(obj.Model.getFirstPassDeletionFrameNumber);
            obj.View.AutoTrackingConnectionGaps.Value =                       num2str(obj.Model.getAutoTrackingConnectionGaps);
            
            obj.View.DistanceLimitXYForTrackMerging.Value =                   num2str(obj.Model.getDistanceLimitXYForTrackMerging);
            obj.View.DistanceLimitZForTrackingMerging.Value =                 num2str(obj.Model.getDistanceLimitZForTrackingMerging);
            obj.View.ShowDetailedMergeInformation.Value =                     obj.Model.getShowDetailedMergeInformation;
               
        end
       
        function obj =  resetView(obj)
            obj.View = PMTrackingNavigationAutoTrackView;
            
        end
        
        
         function Action =            getHelperViewAction(obj, ForceView)

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

