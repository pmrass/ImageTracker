classdef PMSpaceCalibrationSeries
    %PMSPACECALIBRATIONSERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Calibrations =    PMSpaceCalibration.empty(0,1)
    end
    
    methods
        function obj = PMSpaceCalibrationSeries(varargin)
            %PMSPACECALIBRATIONSERIES Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfInputArguments =     length(varargin);
            switch NumberOfInputArguments
                case 0
                case 1
                    obj.Calibrations = varargin{1};
            end
        end
        
         function obj = set.Calibrations(obj,Value)
            assert(isa(Value, 'PMSpaceCalibration'), 'Wrong input format.')
            obj.Calibrations =  Value;
         end
        
         function result = getDistanceBetweenZPixels_MicroMeter(obj)
             values= arrayfun(@(x) x.getDistanceBetweenZPixels_MicroMeter, obj.Calibrations);
             
             result = unique(values);
             assert(isscalar(result), 'Only movies with identical Z pixel size are allowed.')
             
         end
         
          function result = getDistanceBetweenXPixels_MicroMeter(obj)
             values= arrayfun(@(x) x.getDistanceBetweenXPixels_MicroMeter, obj.Calibrations);
             
             result = unique(values);
             assert(isscalar(result), 'Only movies with identical Z pixel size are allowed.')
             
          end
         
          function summary = getSummary(obj)
             summary = arrayfun(@(x) x.getSummary, obj.Calibrations, 'UniformOutput', false);
             
          end
         
    end
end

