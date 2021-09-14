classdef PMTimeCalibration
    %PMTIMECALIBRATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TimePoints_Seconds
    end
    
    methods
        function obj = PMTimeCalibration(varargin)
            %PMTIMECALIBRATION Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfInputArguments =    length(varargin);
            switch NumberOfInputArguments
                case 0
                case 1
                    obj.TimePoints_Seconds  =       varargin{1};
                otherwise
                    error('Wrong number of input arguments.')
            end
        end
        
        function obj = set.TimePoints_Seconds(obj,Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input format.')
            obj.TimePoints_Seconds =  Value(:);
        end
        
        function frames_Seconds = convertFramesIntoSeconds(obj, list)
             if iscell(list)
                frames_Seconds =             num2cell(obj.TimePoints_Seconds(cell2mat(list)));
             else
                 error('Input type not supported.')
             end
        end
        
        function frames_Minutes = convertFramesIntoMinutes(obj, list)
            if iscell(list)
                ListWithFrames =    cell2mat(list);
                MyList_Seconds =    obj.TimePoints_Seconds(ListWithFrames);
                frames_Minutes =    num2cell(MyList_Seconds / 60);
            else
                 error('Input type not supported.')
             end
        end
        
        function numberOfFrames = getNumberOfFrames(obj)
            numberOfFrames = length(obj.TimePoints_Seconds);
        end
        
        function frames = getTimeStampsInSeconds(obj)
            frames = obj.TimePoints_Seconds;
        end
        
        
    end
end

