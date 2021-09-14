classdef PMCropImage
    %PMCROPIMAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Image
        MinX
        MaxX
        MinY
        MaxY
    end
    
    methods
        function obj = PMCropImage(varargin)
            %PMCROPIMAGE Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 5
                    obj.Image = varargin{1};
                    obj.MinX = varargin{2};
                    obj.MaxX = varargin{3};
                    obj.MinY = varargin{4};
                    obj.MaxY= varargin{5};
                otherwise
                    error('Wrong input.')
                
            end
        end
        
        function image = getImage(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            myImage = cast(0, class(obj.Image));
            myImage(obj.MaxY, obj.MaxX, size(obj.Image, 3)) = 0;
            myImage(1 : size(obj.Image, 1), 1 : size(obj.Image, 2), :) = obj.Image;
              image =  myImage(obj.MinY : obj.MaxY, obj.MinX : obj.MaxX, :);    
        end
    end
end

