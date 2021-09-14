classdef PMRgbImageMatrix
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Image
        CoordinateList
        
        
    end
    
    methods
        function obj = PMRgbImageMatrix(varargin)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            switch length(varargin)
                case 0
                case 1
                    obj.Image = varargin{1};
                otherwise
                    error('Invalid number of arguments')
            end
        end
        
        function obj = set.Image(obj, Value)
            assert(isnumeric(Value), 'Wrong argument type.')
            obj.Image = Value;
        end
        
        
        function obj = set.CoordinateList(obj, Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.CoordinateList = Value;
        end
        
        function image = getImage(obj)
            image = obj.Image;
        end
    end
end

