classdef PMRGBImage
    %PMRGBIMAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        SourceImageVolume
        indicesOfSourceChannels 
        ListWithMinimumIntensities_Select 
        ListWithMaximumIntensities_Select
        ListWithChannelColors_Select 
        
        
    end
    
    methods%initialize
        
         function obj = PMRGBImage(varargin)
            %PMRGBIMAGE Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                case 5
                    obj.SourceImageVolume = varargin{1};
                    obj.indicesOfSourceChannels = varargin{2};
                    obj.ListWithMinimumIntensities_Select= varargin{3};
                    obj.ListWithMaximumIntensities_Select= varargin{4};
                    obj.ListWithChannelColors_Select = varargin{5};
                otherwise
                    error('Wrong input.')
                
                
            end

         end
        
         function obj = set.SourceImageVolume(obj, Value)
            assert(isnumeric(Value) && ndims(Value) == 5, 'Wrong input.')
            obj.SourceImageVolume = Value;
         end
         
         function obj = set.indicesOfSourceChannels(obj, Value)
            if  isvector(Value) && isnumeric(Value) 
                arrayfun(@(x) assert( (mod(x, 1) == 0), 'Wrong input.'), Value);
            else
                error('Wrong input.')
            end

            arrayfun(@(x) assert(x>=1, 'Wrong input'), Value);
            arrayfun(@(x) assert(x <= obj.getNumberOfChannels, 'Wrong input'), Value);

            obj.indicesOfSourceChannels = Value;
            
           
           
         end
         
         function obj = set.ListWithMinimumIntensities_Select(obj, Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input.')
            obj.ListWithMinimumIntensities_Select = Value;
         end
         
         function obj = set.ListWithMaximumIntensities_Select(obj, Value)
            assert(isnumeric(Value) && isvector(Value), 'Wrong input.')
            obj.ListWithMaximumIntensities_Select = Value;
         end
         
         function obj = set.ListWithChannelColors_Select(obj, Value)
            assert(iscellstr(Value) && isvector(Value) && length(Value) == length(obj.getNumberOfVisibleChannels), 'Wrong input.')
            obj.ListWithChannelColors_Select = Value;
              
         end
         
    end
    
    methods % getter
        
       
        
        function rgbImage = getImage(obj)
           
            rgbImage=     cast(0, obj.getImagePrecision(obj.SourceImageVolume));
            rgbImage(size(obj.SourceImageVolume,1), size(obj.SourceImageVolume,2), 3)=                   0;

            if isempty(obj.SourceImageVolume) % if no image remains: return black;
                
            else

                for ChannelIndex= 1 : length(obj.ListWithMinimumIntensities_Select) % go through all channels of image:
                    
                    CurrentImage=          obj.SourceImageVolume(:,:,:,obj.indicesOfSourceChannels(ChannelIndex)); 

                    CurrentImage =         max(CurrentImage(:,:,:), [], 3);
                    CurrentImage=          imadjust(CurrentImage, [obj.ListWithMinimumIntensities_Select(ChannelIndex)  obj.ListWithMaximumIntensities_Select(ChannelIndex)], [0 1]);

                    rgbImage =              obj.addImageWithColor(rgbImage, CurrentImage, obj.ListWithChannelColors_Select{ChannelIndex});
                end

            end
        end
        
        function numberOfPlanes = getNumberOfChannels(obj)
            numberOfPlanes = size(obj.SourceImageVolume, 5);

        end
        
        function numberOfChannels = getNumberOfVisibleChannels(obj)
            numberOfChannels = obj.indicesOfSourceChannels;
            
        end
        
        function sourceImage = addImageWithColor(~, sourceImage, imageToAdd, CurrentColor)
             
                switch CurrentColor
                    case 'Red'
                        sourceImage(:,:,1)=    sourceImage(:,:,1) + imageToAdd;
                    case 'Green'
                        sourceImage(:,:,2)=    sourceImage(:,:,2) + imageToAdd;
                    case 'Blue'
                        sourceImage(:,:,3)=    sourceImage(:,:,3) + imageToAdd;
                    case 'Yellow'
                        sourceImage(:,:,1)=    sourceImage(:,:,1) + imageToAdd;
                        sourceImage(:,:,2)=    sourceImage(:,:,2) + imageToAdd;
                    case 'Magenta'
                        sourceImage(:,:,1)=    sourceImage(:,:,1) + imageToAdd;
                        sourceImage(:,:,3)=    sourceImage(:,:,3) + imageToAdd;
                    case 'Cyan'
                        sourceImage(:,:,2)=    sourceImage(:,:,2) + imageToAdd;
                        sourceImage(:,:,3)=    sourceImage(:,:,3) + imageToAdd;
                    case 'White'
                        sourceImage(:,:,1)=    sourceImage(:,:,1) + imageToAdd;
                        sourceImage(:,:,2)=    sourceImage(:,:,2) + imageToAdd;
                        sourceImage(:,:,3)=    sourceImage(:,:,3) + imageToAdd;
                        
                    case 'Black'
                      
                        
                        
                    otherwise
                        error('Color not supported.')
                end
                
         end
        
                
             
         
    end
    
    methods (Access = private)
       
        
         
        
          function Precision = getImagePrecision(~, image)
                if isa(image, 'uint16')
                    Precision=      'uint16';
                elseif isa(image, 'uint8')
                    Precision=      'uint8';
                else
                    error('Image format not supported.')
                end
          end
    end
end

