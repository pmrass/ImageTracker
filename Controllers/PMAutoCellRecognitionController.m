classdef PMAutoCellRecognitionController
    %PMAUTOCELLRECOGNITIONCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Model
        Views
    end
    
    methods
        function obj = PMAutoCellRecognitionController(Model)
            %PMAUTOCELLRECOGNITIONCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
            obj.Model = Model;
            obj.Views = PMAutoCellRecognitionView;
            
        end
        
        function obj = udpatePlaneSettingView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            
            Colum1Data =    obj.Model.RadiusRange;
            Colum2Data =    obj.Model.Sensitivity;
            Colum3Data =    obj.Model.EdgeThreshold;
            
            
            
            
  
        end
        
         function obj = updatePlaneDataFromView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            outputArg = obj.Property1 + inputArg;
            
  
        end
        
    end
    
end

