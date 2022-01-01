classdef PMImage
    %PMIMAGE Manages manipulation of 2D image matrix;
    %   Detailed explanation goes here
    
    properties (Access = private)
        Image
    end
    
    methods

        function obj = PMImage(varargin)
            %PMIMAGE Construct an instance of this class
            %   1 argument: numerical matrix
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    obj.Image =             varargin{1};
                otherwise
                    error('Wrong input.')
            end
        end
        
        function obj = set.Image(obj, Value)
             assert((isnumeric(Value) || islogical(Value)) && ismatrix(Value), 'Wrong input') 
           obj.Image = Value; 
        end
        
        function Image = getImage(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
           Image = obj.Image;
        
        end
        
        function obj = filter(obj, varargin)
           
            
                      
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    Type = varargin{1};
                    switch Type
                        case {'Raw', 'raw'}
                            % no action
                        case {'Median', 'median'}
                            obj.Image =         medfilt2(obj.Image);
                        case {'Complex', 'complex'}
                            OpenedImage =       imopen(obj.Image, strel('disk', 2)); % open image
                            BackGroundImage =   imsubtract(obj.Image, OpenedImage);
                            obj.Image =         imsubtract(medfilt2(obj.Image), medfilt2(BackGroundImage));
                        otherwise
                            error(['Processing type ', varargin{1}, ' not supported. No image processing performed.'])      
                    end
                otherwise
                    error('Wrong input.')
            end
 
        end
        
        function obj = threshold(obj, Threshold)
            obj.Image(obj.Image < Threshold) =      0;
            obj.Image =            obj.Image > 0;
        end
        
        function obj = removeSmallObjects(obj, MinimumSize)
            obj.Image =   bwareaopen(obj.Image, MinimumSize);
        end
        
        
    end
    
    methods (Access =  private)
       
          
                    % this should be added somewhere optional, not as a default;
%              if strcmp(class(obj.Image), 'uint8')
%                     if sum(obj.Image(:) >= 100) >= length(obj.Image(:))/5 % get rid of highly saturated images 
%                        %  fprintf(', hypersaturated: black out')
%                         obj.Image(:,:) = 0;
%                     end
%               end
            
        
    end
end

