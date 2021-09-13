classdef PMInteractionsManager
    %PMINTERACTIONSMANAGER glue between view to control interaction-measurement PMInteractionsView and object that can do the actual processing PMInteractionsCapture;
    %  allows creation of "InteractionsMap";
    % this can be stored in a file and used by PMTrackingSuite to offer filtering tracks by distance to target locations;
    
    properties (Access = private)
        
        Model 
        View
                  
     
    end
    
    properties(Access = private)
    end
    
    methods % initialization
        
           function obj = PMInteractionsManager(varargin)
            %PMINTERACTIONSMANAGER Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    
                otherwise
                    error('Wrong input.')
            end
            
            obj.View = PMInteractionsView;
  
        end
        
        function obj = set.Model(obj, Value)
            assert(isa(Value, 'PMInteractionsCapture'), 'Wrong input.')
            obj.Model = Value;
        end
        
        
    end
    
    methods % summary
        
        function obj = showSummary(obj)
            obj.Model = obj.Model.showSummary;
            
        end
        
        
    end
    
    methods % setters
        
          function obj = setExportFolder(obj, Value)
                obj.Model = obj.Model.setExportFolder(Value); 
          end
        
        function obj = updateModelByView(obj)
             obj.Model =    obj.Model.set(...
                 obj.View.getPlaneThresholds, ...
                 obj.View.getReferenceTimeFrame, ...
                 obj.View.getMinimumSize, ...
                 obj.View.getChannel, ...
                 obj.View.getMaximumDistanceToTarget, ...
                 obj.View.getShowThresholdedImage ...
                 );
        end
        
        
        function obj = setWith(obj, Value)
            Type = class(Value);
            switch Type                                      
                case 'PMMovieTracking'
                   obj.Model =       Value.getInteractions;
                   
                otherwise
                    error('Type not supported')
            end
            
            obj = obj.updateView;
            
        end
        
        function obj = setCallbacks(obj, varargin)
            if isempty(obj.View ) || isempty(obj.View.getMainFigure) || ~isvalid(obj.View.getMainFigure)
                warning('Views not available. No callbacks set.')
            else
                assert(length(varargin) == 2, 'Wrong input.')
                obj.View = obj.View.setCallbacks(varargin{1}, varargin{2});
            end
            
            
        end

        
        %% setMovieController
        function obj = setMovieController(obj, Value)
            if isempty(obj.Model)
                obj.Model = PMInteractionsCapture;
            end
            
            obj.Model =     obj.Model.setMovieController(Value);
            obj =           obj.updateView;
           
        end
        
        function obj = setXYLimitForNeighborArea(obj, Value)
            obj.Model = obj.Model.setXYLimitForNeighborArea(Value);
        end
        
         function obj = setZLimitForNeighborArea(obj, Value)
            obj.Model = obj.Model.setZLimitForNeighborArea(Value);
        end
         
         
        
        function obj = updateView(obj)
            if ~isempty(obj.View.getMainFigure) && isvalid(obj.View.getMainFigure)
                obj.View = obj.View.setMovieDependentParameters(obj.Model.getMovie);
                obj.View = obj.View.setWith(obj.Model);
            end
        end
        
        %% showView
        function obj = showView(obj)
            obj.View =      obj.View.makeVisibible;
            obj =           obj.updateView;
        end
        
        
        
    end
    
    
    methods % getters
        
        function ok = testViewsAreSetup(obj)
            ok = obj.View.testViewsAreSetup;
            
        end
        
      
     
        function view = getView(obj)
            view = obj.View;
            
        end
        
        function value = getPMInteractionsQuantification(obj)
            value = obj.Model;
            
        end
        
        
        %% getImageVolume:
        function volume = getImageVolume(obj) 
           volume = obj.Model.getImageVolume; 
         
           if obj.View.getShowThresholdedImage
               
           else
               volume(:,:,:) = 0;
           end
           
        end
        
        %% accessors:
        function Value = getThresholdsForImageVolumes(obj)
            Value = obj.Model.getThresholdsForImageVolumes;
        end

        function Value = getSourceFramesForImageVolumes(obj)
            Value = obj.Model.getSourceFramesForImageVolumes;
        end

        function Value = getMinimumSizesOfTarget(obj)
            Value = obj.Model.getMinimumSizesOfTarget;
        end

        function Value = getChannelNumbersForTarget(obj)
            Value = obj.Model.getChannelNumbersForTarget;
        end

        function Value = getMaximumDistanceToTarget(obj)
            Value = obj.Model.getMaximumDistanceToTarget;
        end

         function Value = getShowThresholdedImage(obj)
            Value = obj.Model.getShowThresholdedImage;
        end

        function Value = getUserSelection(obj)
            Value = obj.View.getUserSelection;
        end
       
        %% user converts image data into coordinate lists of searchers and targets;
        function InteractionTracking = getInteractionTrackingObject(obj)
            InteractionTracking =       obj.Model.getInteractionsObject;
            InteractionTracking =       InteractionTracking.minimizeSize;

        end
        
      
        
        
  
    end
    
    methods % interaction measurement action
       
        function Map = getInteractionsMap(obj)
            Map =       obj.Model.getInteractionsMap;
            
        end
        
        function obj = exportDetailedInteractionInfoForTrackIDs(obj, TrackIDs)
            obj.Model = obj.Model.exportDetailedInteractionInfoForTrackIDs(TrackIDs);
            
        end
        
        
    end
    
    methods (Access = private)
        
      
        
        
    end
    
    
end

