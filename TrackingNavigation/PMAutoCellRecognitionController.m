classdef PMAutoCellRecognitionController
    %PMAUTOCELLRECOGNITIONCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Model
        View
    end
    
    methods
        
        function obj = PMAutoCellRecognitionController(Model)
            %PMAUTOCELLRECOGNITIONCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
            obj.Model =     Model;
            obj.View =      PMAutoCellRecognitionView;
            obj =           obj.udpatePlaneSettingView;
        end
        
        function view = getView(obj)
            view = obj.View;
        end
        
        function obj = setSelectedFrames(obj, Value)
           obj.Model = setSelectedFrames(obj.Model, Value);
        end
        
         function obj = setActiveChannel(obj, Value)
          obj.Model = setActiveChannel(obj.Model, Value);
        end
        
        function obj = setCircleLimitsBy(obj, Value)
            obj.Model = obj.Model.setCircleLimitsBy(Value);
        end
        
        
         function obj = setCallBacks(obj, varargin)
             assert(length(varargin) == 6, 'Wrong input.')
             obj.View = obj.View.setCallBacks(varargin{1}, varargin{2}, varargin{3}, varargin{4},  varargin{5},  varargin{6});
         end
         
         function selection = getUserSelection(obj)
             selection = obj.View.getUserSelection;
         end
         
         function selection = getAutoCellRecognition(obj)
            selection = obj.Model; 
         end
         
         function frames = getSelectedFrames(obj)
           frames = obj.Model.getSelectedFrames; 
        end
         
         function obj = interpolateCircleRecognitionLimits(obj)
                obj.Model =                        obj.Model.interpolateRadiusLimits;
                    obj.Model =                        obj.Model.interpolateSensitivityLimits;
                    obj.Model =                        obj.Model.interpolateEdgeThresholdLimits;
                    obj = udpatePlaneSettingView(obj);
         end
 
    end
    
    methods (Access = private)
        
        function obj = udpatePlaneSettingView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.View=        obj.View.setChannels((1:obj.Model.getNumberOfChannels)');   
       
            obj.View =       obj.View.setFrames(                  obj.Model.getAvailableFrames);     
            obj.View =       obj.View.setPlaneSettings(          [obj.Model.getRadiusRanges, obj.Model.getSensitivities, obj.Model.getEdgeThresholds]);
            
            
            
            obj.View =       obj.View.setHighDensityNumbers(     num2str(obj.Model.getHighDensityNumberLimit));
            obj.View =       obj.View.setHighDensityDistances(  num2str(obj.Model.getHighDensityDistanceLimit)); 
            
        end 
        
    end
    
end

