classdef PMInteractionsManager
    %PMINTERACTIONSMANAGER glue between view to control interaction-measurement PMInteractionsView and object that can do the actual processing PMInteractionsCapture;
    %  allows creation of "InteractionsMap";
    % this can be stored in a file and used by PMTrackingSuite to offer filtering tracks by distance to target locations;
    % PMInteractionsCapture has submodels PMInteractions, which, in turn, has PMInteraction;
    
    properties (Access = private)
        Model 
        View
                  
    end
    
    properties(Access = private)
    end
    
    methods % initialization
        
        function obj =      PMInteractionsManager(varargin)
                %PMINTERACTIONSMANAGER Construct an instance of this class
                % takes 0, 1, or 2 arguments
                % 1: PMInteractionsView
                % 2: PMInteractionsCapture
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 0
                        obj.View =          PMInteractionsView;
                        obj.Model =         PMInteractionsCapture;

                    case 1
                        obj.View = varargin{1};
                        obj.Model = PMInteractionsCapture;
                        
                    case 2
                        obj.View = varargin{1};
                        obj.Model = varargin{2};
                        

                    otherwise
                        error('Wrong input.')
                end

          end
        
        function obj =      set.Model(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMInteractionsCapture'), 'Wrong input.')
            obj.Model =         Value;
            
        end
        
        function obj =      set.View(obj, Value)
            assert(isscalar(Value) && isa(Value, 'PMInteractionsView'), 'Wrong input.')
            obj.View =          Value;
        end
        
        
    end
    
    methods % summary
        
        function obj = showSummary(obj)
            obj.Model =         obj.Model.showSummary;
            
        end
        
        
    end
    
    methods % SETTERS
        
        function obj =      resetModelByMovieTracking(obj, MovieTracking)
            % SETMOVIECONTROLLER sets PMMovieController used by PMInteractionsCapture model;
            % takes 1 argument:
            % 1: PMMovieController
            % also updates views;
            
           switch class(MovieTracking.getInteractionsCapture)
                   case 'PMInteractionsCapture'
                        obj.Model = MovieTracking.getInteractionsCapture; 
                   otherwise
                       error('Movie tracking input did not have PMInteractionsCapture')
            end

           if isempty(obj.Model.getThresholdsForImageVolumes)
                obj.Model = obj.Model.setThresholdsForImageVolumeOfTarget(MovieTracking.getDefaultThresholdsForAllPlanes);
           end
           
            obj.Model =     obj.Model.setMovieTracking(MovieTracking);
            
            obj =           obj.updateView;
           
        end
        
        function obj =      setExportFolder(obj, Value)
                obj.Model = obj.Model.setExportFolder(Value); 
          end
        
        function obj =      updateModelByView(obj)

             obj.Model =    obj.Model.set(...
                 obj.View.getPlaneThresholds, ...
                 obj.View.getReferenceTimeFrame, ...
                 obj.View.getMinimumSize, ...
                 obj.View.getChannel, ...
                 obj.View.getMaximumDistanceToTarget, ...
                 obj.View.getShowThresholdedImage ...
                 );

        end
        
        function obj =      setWith(obj, Value)

            Type = class(Value);
            switch Type                                      
                case 'PMMovieTracking'
                   obj.Model =       Value.getInteractionsCapture;
                   
                otherwise
                    error('Type not supported')
            end
            
            obj = obj.updateView;
            
        end
        
       
    end
    
    methods % SETTERS: VIEW
       
        function obj =      setCallbacks(obj, varargin)
        
            if isempty(obj.View ) || isempty(obj.View.getMainFigure) || ~isvalid(obj.View.getMainFigure)
                warning('Views not available. No callbacks set.')
            else
                assert(length(varargin) == 2, 'Wrong input.')
                obj.View = obj.View.setCallbacks(varargin{1}, varargin{2});
            end
            
        end

        function obj =      updateView(obj)
            if ~isempty(obj.View.getMainFigure) && isvalid(obj.View.getMainFigure)
                obj.View = obj.View.setWith(obj.Model);
            end
        end
        
        function obj =      showView(obj)
            obj.View =      obj.View.makeVisibible;
            obj =           obj.updateView;
        end
        
    end
    
    
    methods % GETTERS: MODEL
        
        function value =                    getModel(obj)
            value = obj.Model;
            
        end
        
        function volume =                   getImageVolume(obj) 
           volume = obj.Model.getImageVolume; 
         
           if obj.getVisibilityOfTargetImage
               
           else
               volume(:,:,:) = 0;
           end
           
        end
         
        function InteractionTracking =      getInteractionTrackingObject(obj)
            InteractionTracking =       obj.Model.getInteractionsObject;
            InteractionTracking =       InteractionTracking.minimizeSize;

        end
        
    end
    
    methods % GETTERS: VIEW:
       
        function ok =           testViewsAreSetup(obj)
            ok = obj.View.testViewsAreSetup;
            
        end
        
        function view =         getView(obj)
            view = obj.View;
            
        end
        
        function Value =        getUserSelection(obj)
            Value = obj.View.getUserSelection;
        end
        
    end
    
    methods % interaction measurement action
       
        function Map =          getInteractionsMap(obj)
            Map =       obj.Model.getInteractionsMap;
            
        end
        
        function obj =          exportDetailedInteractionInfoForTrackIDs(obj, TrackIDs, varargin)
            obj.Model = obj.Model.exportDetailedInteractionInfoForTrackIDs(TrackIDs, varargin{:});
            
        end
        
        
    end
    
    methods (Access = private) % GETTERS: NECESSARY?
       
        function value =        getVisibilityOfTargetImage(obj)
           value =  obj.View.getShowThresholdedImage;
        end
        
        function Value =        getThresholdsForImageVolumes(obj)
            Value = obj.Model.getThresholdsForImageVolumes;
        end

        function Value =        getSourceFramesForImageVolumes(obj)
            Value = obj.Model.getSourceFramesForImageVolumes;
        end

        function Value =        getMinimumSizesOfTarget(obj)
            Value = obj.Model.getMinimumSizesOfTarget;
        end

        function Value =        getChannelNumbersForTarget(obj)
            Value = obj.Model.getChannelNumbersForTarget;
        end

        function Value =        getMaximumDistanceToTarget(obj)
            Value = obj.Model.getMaximumDistanceToTarget;
        end

        function Value =        getShowThresholdedImage(obj)
            Value = obj.Model.getShowThresholdedImage;
        end
        
    end
    
    methods (Access = private) % SETTERS: NECESSARY?
        
        function obj =      setXYLimitForNeighborArea(obj, Value)
            obj.Model = obj.Model.setXYLimitForNeighborArea(Value);
        end
        
        function obj =     setZLimitForNeighborArea(obj, Value)
            obj.Model = obj.Model.setZLimitForNeighborArea(Value);
        end
            
        
        
    end
    

    
    
end

