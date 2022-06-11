classdef PMAutoCellRecognitionController
    %PMAUTOCELLRECOGNITIONCONTROLLER for managing communication between PMAutoCellRecognition and PMAutoCellRecognitionView; 
    %   
    
    properties (Access = private)
        Model
        View
    end
    
    methods
        
        function obj = PMAutoCellRecognitionController(varargin)
            %PMAUTOCELLRECOGNITIONCONTROLLER Construct an instance of this class
            %  takes 0, 1, or 2 arguments:
            % 1: PMAutoCellRecognition
            % 2: PMAutoCellRecognitionView
            switch length(varargin)
                case 0
                    obj.Model =     PMAutoCellRecognition;
                    obj.View =      PMAutoCellRecognitionView;
                    obj =           obj.setViewByModel;
                    
                case 1
                    obj.Model =     varargin{1};
                    obj.View =      PMAutoCellRecognitionView;
                    obj =           obj.setViewByModel;
                    
                case 2
                    obj.Model =     varargin{1};
                    obj.View =      varargin{2};
                    
                    
                otherwise
                    error('Wrong input.')
                
            end
  

        end
        
        function obj = set.Model(obj, Value)
           
            if isempty(Value)
               obj.Model = PMAutoCellRecognition ;
               
            else
                assert(isscalar(Value) && isa(Value, 'PMAutoCellRecognition'))
                obj.Model = Value; 
            end
           
            
        end
        
        function obj = set.View(obj, Value) 
            
            if isempty(Value)
                
            else
                   assert(isscalar(Value) && isa(Value, 'PMAutoCellRecognitionView')) 
               obj.View = Value;
            end
                
                
            
            
        end
        
    end
    
    methods % SETTERS
        
        function obj =      showFigure(obj)
           obj.View = obj.View.show; 
        end
        
        function obj =      setView(obj, Value)
           obj.View =       Value; 
           obj =            obj.setViewByModel;
           
        end
        
        function obj =      setModel(obj, Value)
            obj.Model =         Value;
            obj =               obj.setViewByModel;
            
        end
        
        function obj =      setCallBacks(obj, varargin)
         assert(length(varargin) == 5, 'Wrong input.')

         obj.View = obj.View.setCallBacks(   varargin{1}, ...
                                                       varargin{2}, ...
                                                        varargin{3}, ...
                                                        varargin{4}, ...
                                                        varargin{5} ...
                                                        );

        end

        function obj =      setCircleLimitsBy(obj, Value)
            obj.Model = obj.Model.setCircleLimitsBy(Value);
         end
        
        function obj =      interpolateCircleRecognitionLimits(obj)
            obj.Model =                        obj.Model.interpolateRanges;
            obj =                              obj.setViewByModel;
        end

    end

    
    methods % SETTERS GENERAL 
        
        function obj =      performMethod(obj, Value, varargin)
            
            if isempty(obj.Model)
                warning('Model not set. Method not called.')
            else
                  obj.Model = obj.Model.performMethod(Value, varargin{:}); 
            end
         
            
        end
        
        function obj =      setSelectedFrames(obj, Value)
           obj.Model = setSelectedFrames(obj.Model, Value);
        end
        
        function obj =      setActiveChannel(obj, Value)
          obj.Model = setActiveChannel(obj.Model, Value);
        end
 
    end
    
    methods % SETTERS CONNECT VIEW AND MODEL

        function obj =      setModelByView(obj)
             obj.Model =    obj.Model.setCircleLimitsBy(obj.View.getListWithPlaneSettings);
             obj.Model =    obj.Model.setHighDensityNumberLimit(obj.View.getFilterForHighDensityNumber);
             obj.Model =    obj.Model.setHighDensityDistanceLimit(obj.View.getFilterForHighDensityDistance);
             obj.Model =    obj.Model.setPreventDoubleTracking(obj.View.getOverlapExclusionSelection);
             obj.Model =    obj.Model.setPreventDoubleTrackingDistance(obj.View.getOverlapExclusionDistance);

        end

        function obj =      setViewByModel(obj)
        %UDPATEPLANESETTINGVIEW Summary of this method goes here
        %   Detailed explanation goes here
        if ~isempty(obj.Model) && ~isempty(obj.View) && obj.View.figureIsActive
            obj.View=        obj.View.setChannels((1:obj.Model.getNumberOfChannels)');   
            obj.View =       obj.View.setFrames(  obj.Model.getAvailableFrames);     

            obj.View =       obj.View.setPlaneSettings([obj.Model.getRadiusRanges, obj.Model.getSensitivities, obj.Model.getEdgeThresholds]);
            obj.View =       obj.View.setHighDensityNumbers( num2str(obj.Model.getHighDensityNumberLimit));
            obj.View =       obj.View.setHighDensityDistances(num2str(obj.Model.getHighDensityDistanceLimit)); 

            obj.View =       obj.View.setDoubleTracking(obj.Model.getPreventDoubleTracking);
            obj.View =       obj.View.setDoubleTrackingDistance(num2str(obj.Model.getPreventDoubleTrackingDistance));

        end

     end 

    end

    methods % GETTERS
        
         function Value =        get(obj, Value, varargin)
            MethodName = ['get', Value];
            Value = obj.(MethodName)(varargin{:});
        end
        
         function view =        getView(obj)
            view = obj.View;
         end
         
         function selection =   getModel(obj)
             selection = obj.Model; 
             
         end
        
         function selection =   getAutoCellRecognition(obj)
            selection = obj.Model; 
         end
         
         function selection =   getUserSelection(obj)
             selection = obj.View.getUserSelection;
         end
          
    end

    
    methods (Access = private) % callbacks 
       
      
        
    end
    
end

