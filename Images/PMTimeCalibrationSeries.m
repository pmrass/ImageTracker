classdef PMTimeCalibrationSeries
    %PMTIMECALIBRATIONSERIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Calibrations =  PMTimeCalibration
    end
    
    methods
        function obj = PMTimeCalibrationSeries(varargin)
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
            assert(isa(Value, 'PMTimeCalibration'), 'Wrong input format.')
            obj.Calibrations =  Value;
         end
        
         function number = getNumberOfFrames(obj)
             number = sum(arrayfun(@(x) x.getNumberOfFrames, obj.Calibrations));
             
         end
         
           function frames = getTimeStampsInSeconds(obj)
                frames = arrayfun(@(x) x.getTimeStampsInSeconds, obj.Calibrations, 'UniformOutput', false);
                frames = vertcat(frames{:});
           end
           
           function frames = getRelativeTimeStampsInSeconds(obj)
               frames = obj.getTimeStampsInSeconds;
               frames = frames - frames(1);
           end
           
          function frames_Seconds = convertFramesIntoSeconds(obj, list)
             if iscell(list)
                 TimeInSeconds = obj.getTimeStampsInSeconds;
                frames_Seconds =             num2cell(TimeInSeconds(cell2mat(list)));
             else
                 error('Input type not supported.')
             end
        end
           
            function frames_Minutes = convertFramesIntoMinutes(obj, list)
            if iscell(list)
                
                TimeInSeconds = obj.getTimeStampsInSeconds;
                ListWithFrames =    cell2mat(list);
                MyList_Seconds =    TimeInSeconds(ListWithFrames);
                frames_Minutes =    num2cell(MyList_Seconds / 60);
            else
                 error('Input type not supported.')
             end
        end
           
         
    end
end

