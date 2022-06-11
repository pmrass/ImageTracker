classdef PMCropImage
    % PMCROPIMAGE allows retrieval of cropped image
    % 
    
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
            %   takes 5 arguments:
            % 1: image-volume
            % 2: min X
            % 3: max X
            % 4: min Y
            % 5: max Y
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 5
                    obj.Image =     varargin{1};
                    obj.MinX =      varargin{2};
                    obj.MaxX =      varargin{3};
                    obj.MinY =      varargin{4};
                    obj.MaxY=       varargin{5};
                    
                otherwise
                    error('Wrong input.')
                
            end
        end
        
        function image = getImage(obj)
            %GETIMAGE returns cropped image
            %  
            myImage =                                           cast(0, class(obj.Image));
            myImage(obj.MaxY, obj.MaxX, size(obj.Image, 3)) =   0; % is this meanigful?;
            myImage(1 : size(obj.Image, 1), 1 : size(obj.Image, 2), :) = obj.Image;
            
            image =     myImage(obj.MinY : obj.MaxY, obj.MinX : obj.MaxX, :);    
        end
        
    end
end

