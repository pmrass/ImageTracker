classdef PMSpaceCalibration
    %PMSPACECALIBRATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        DistanceBetweenXPixels_Meter
        DistanceBetweenYPixels_Meter
        DistanceBetweenZPixels_Meter
    end
    
    methods % initialization
        
        
        function obj = PMSpaceCalibration(varargin)
            %PMSPACECALIBRATION Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfInputArguments = length(varargin);
            switch NumberOfInputArguments
                case 0
                case 1
                case 3
                    obj.DistanceBetweenXPixels_Meter =      varargin{1};
                    obj.DistanceBetweenYPixels_Meter =      varargin{2};
                    obj.DistanceBetweenZPixels_Meter =      varargin{3};
                otherwise
                    error('Wrong number of input arguments')
            end
            
        end
        
        function obj = set.DistanceBetweenXPixels_Meter(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.DistanceBetweenXPixels_Meter =  Value;
        end
         
        function obj = set.DistanceBetweenYPixels_Meter(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.DistanceBetweenYPixels_Meter =  Value;
        end
         
        function obj = set.DistanceBetweenZPixels_Meter(obj,Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input format.')
            obj.DistanceBetweenZPixels_Meter =  Value;
        end
        
        
    end
    
    methods
        
        
        function obj= showSummary(obj)
            cellfun(@(x) fprintf('%s\n', x), obj.getSummary);
            
        end
         
        function list_um = convertXYZPixelListIntoUm(obj, Input)
            if iscell(Input)
                assert(size(Input,2) == 3, 'Input has wrong format.')
                if isempty(Input)
                    list =  zeros(0,3); % this is 
                else
                    list =           cell2mat(Input);
                end
            elseif isempty(Input)
                list = zeros(0, 3);
            else
                list = Input;
            end
            
            assert(isnumeric(list), 'Wrong input.')
            list_um(:,3) =   obj.convertZPixelsIntoUm(list(:,3));
            list_um(:,2) =  obj.convertYPixelsIntoUm(list(:,2));
            list_um(:,1) =  obj.convertXPixelsIntoUm(list(:,1));

            if iscell(Input)
                list_um =       num2cell(list_um); 
            end
            
        end
        
        function list_um = convertXPixelsIntoUm(obj, Input)
            list_um =   Input * obj.getDistanceBetweenXPixels_MicroMeter;
        end
        
        function list_um = convertYPixelsIntoUm(obj, Input)
            list_um =   Input * obj.getDistanceBetweenYPixels_MicroMeter;
        end

        function list_um = convertZPixelsIntoUm(obj, Input)
            list_um =   Input * obj.getDistanceBetweenZPixels_MicroMeter;
        end
      
        
        
         function list_um = convertYXZUmListIntoPixel(obj, Input)
            if iscell(Input)
                assert(size(Input,2) == 3, 'Input has wrong format.')
                list =           cell2mat(Input);
                 else
                list = Input;
            end
            
            
            assert(isnumeric(list), 'Wrong input.')
            list_um(:,3) =   list(:,3) * obj.getDistanceBetweenZPixels_MicroMeter;
                list_um(:,2) =   list(:,2) * obj.getDistanceBetweenXPixels_MicroMeter;
                list_um(:,1) =   list(:,1) * obj.getDistanceBetweenYPixels_MicroMeter;
                
                if iscell(Input)
                    list_um =       num2cell(list_um); 
                end
            
         end
        
         
        
        function value = getDistanceBetweenZPixels_MicroMeter(obj)
            value = obj.DistanceBetweenZPixels_Meter * 10^6;
        end
        
          function value = getDistanceBetweenXPixels_MicroMeter(obj)
            value = obj.DistanceBetweenXPixels_Meter * 10^6;
          end
        
        
        function value = getDistanceBetweenYPixels_MicroMeter(obj)
        value = obj.DistanceBetweenYPixels_Meter * 10^6;
        end

        function summary = getSummary(obj)
            summary{1,1} = sprintf('Distance between pixels in X = %f6.2', getDistanceBetweenXPixels_MicroMeter(obj));
            summary{2,1} = sprintf('Distance between pixels in Y = %f6.2', getDistanceBetweenYPixels_MicroMeter(obj));
            summary{3,1} = sprintf('Distance between pixels in Z = %f6.2', getDistanceBetweenZPixels_MicroMeter(obj));
        end
        
        function ratio = getRatioBetweenZAndXSize(obj)
            ratio = obj.getDistanceBetweenZPixels_MicroMeter / obj.getDistanceBetweenXPixels_MicroMeter;
            
        end
        

        
    end
    
    methods (Access = private)
        
        
    end
    
end

