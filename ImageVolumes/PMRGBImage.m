classdef PMRGBImage
    %PMRGBIMAGE Convert 4D image volumes into rgb images
    
    properties (Access = private)
        SourceImageVolume
        indicesOfSourceChannels 
        ListWithMinimumIntensities_Select 
        ListWithMaximumIntensities_Select
        ListWithChannelColors_Select 
        
        
    end
    
    methods %INITIALIZE
        
         function obj = PMRGBImage(varargin)
            %PMRGBIMAGE Construct an instance of this class
            %   Takes 0 or 5 arguments:
            % 1: 4D image-volume (rows, columns, planes, channels)
            % 2: indices of source-channels (should add empty option so that default would be 1 ascending;
            % 3: minimum intensities for each input channel
            % 4: maximum intensities for each input channel
            % 5: cell-string array with colors for each input channel
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                case 5
                    obj.SourceImageVolume =                     varargin{1};
                    obj.indicesOfSourceChannels =               varargin{2};
                    obj.ListWithMinimumIntensities_Select=      varargin{3};
                    obj.ListWithMaximumIntensities_Select=      varargin{4};
                    obj.ListWithChannelColors_Select =          varargin{5};
                    
                otherwise
                    error('Wrong input.')
                
                
            end

         end
        
         function obj = set.SourceImageVolume(obj, Value)
            assert(isnumeric(Value) && ndims(Value) <= 5 && ndims(Value) >= 2, 'Wrong input.')
            obj.SourceImageVolume = Value;
         end
         
         function obj = set.indicesOfSourceChannels(obj, Value)
             
             if isempty(Value)
                 
             elseif  isvector(Value) && isnumeric(Value) 
                arrayfun(@(x) assert( (mod(x, 1) == 0), 'Wrong input.'), Value);
            else
                error('Wrong input.')
            end

            arrayfun(@(x) assert(x >= 1, 'Wrong input'), Value);
            arrayfun(@(x) assert(x <= obj.getNumberOfChannels, 'Wrong input'), Value);

            obj.indicesOfSourceChannels = Value;
            
           
           
         end
         
         function obj = set.ListWithMinimumIntensities_Select(obj, Value)
            assert(isnumeric(Value) && (isvector(Value) || isempty(Value)), 'Wrong input.')
            obj.ListWithMinimumIntensities_Select = Value;
         end
         
         function obj = set.ListWithMaximumIntensities_Select(obj, Value)
            assert(isnumeric(Value) && (isvector(Value) || isempty(Value)), 'Wrong input.')
            obj.ListWithMaximumIntensities_Select = Value;
         end
         
         function obj = set.ListWithChannelColors_Select(obj, Value)
            assert(iscellstr(Value) && (isvector(Value) || isempty(Value)) && length(Value) == length(obj.getNumberOfVisibleChannels), 'Wrong input.')
            obj.ListWithChannelColors_Select = Value;
              
         end
         
    end
    
    methods % GETTERS:
 
        function imageVolume = getImageVolumeWithAdjustedIntensities(obj)
            
            
            imageVolume = obj.SourceImageVolume;
            
             for ChannelIndex = 1 : size(imageVolume, 5)
                 
                 for planeIndex = 1 : size(imageVolume, 3)
                 
                        low = obj.ListWithMinimumIntensities_Select(ChannelIndex) ;
                        high = obj.ListWithMaximumIntensities_Select(ChannelIndex);

                        if high <= 0
                            high = 0.5;

                        else

                              if low > high
                            low = high - 0.01;
                            end

                        end




                      

                    imageVolume(:, :, planeIndex, ChannelIndex)=          imadjust(imageVolume(:, :, planeIndex, ChannelIndex), [ low high], [0 1]);

                 end
                    
             end
            
            
        end
        
   
        
        function rgbImage =             getImage(obj)
            % GETIMAGE returns rgb image determined by object state:
           
           

            if isempty(obj.SourceImageVolume) % if no image remains: return black;
                
            else

               imageVolume =        obj.getImageVolumeWithAdjustedIntensities; 
               rgbImage =            obj.getRgbImageFromImageVolume(imageVolume);

            end
        end
        
     function rgbImage =            getRgbImageFromImageVolume(obj, imageVolume)

          rgbImage=     cast(0, obj.getImagePrecision(imageVolume));
          rgbImage(size(imageVolume,1), size(imageVolume,2), 3)=                   0;
         
          for ChannelIndex= 1 : length(obj.ListWithChannelColors_Select) % go through all channels of image:
                    
                    ImageOfSourceChannel=          imageVolume(:, :, :, obj.indicesOfSourceChannels(ChannelIndex)); 
                    ImageOfSourceChannel =          max(ImageOfSourceChannel(:,:,:), [], 3);
                    rgbImage =                      obj.addImageWithColor(rgbImage, ImageOfSourceChannel, obj.ListWithChannelColors_Select{ChannelIndex});
           end
         
     end

        
             
        
        function numberOfPlanes =       getNumberOfChannels(obj)
            numberOfPlanes = size(obj.SourceImageVolume, 5);

        end
        
        function numberOfChannels =     getNumberOfVisibleChannels(obj)
            numberOfChannels = obj.indicesOfSourceChannels;
            
        end
   
    end
    
    methods % PROCESSING
       
         function sourceImage =      addImageWithColor(~, sourceImage, imageToAdd, CurrentColor)
             
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
                        
                    case 'ColorMap'
                        
                       Map =                colormap(jet);
                       ColorMapImage =      ind2rgb(imageToAdd,Map);
                       
                       MyClass =            class(sourceImage);
                       
                       switch MyClass
                           case 'uint16'
                                 sourceImage(:,:,1:3)=    sourceImage(:,:,1:3) + uint16((ColorMapImage(:,:,1:3) .* 60000));
                           case 'uint8'
                            sourceImage(:,:,1:3)=    sourceImage(:,:,1:3) + uint8((ColorMapImage(:,:,1:3) .*255));
                           otherwise
                               error('Not supported.')
                               
                       end
                      
                        
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

