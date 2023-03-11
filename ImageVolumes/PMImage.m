classdef PMImage
    %PMIMAGE Manages manipulation of 2D image matrix;
    
    properties (Access = private)
        Image
        
    end
    
    methods % INITIALIZATION:

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
     
           
    end
    
    methods % CLASS METHODS:
       
     
           
        
        
    end

    methods % PROCESSING


        function BorderImage = getImageWithBorderForCoordinates(obj, YCoordinates, XCoordinates, SizeOfCircle)

                BorderImage =                   obj.Image;
                XCoordinates(XCoordinates > size(BorderImage, 2)) = size(BorderImage, 2);

                YCoordinates(YCoordinates > size(BorderImage, 1)) = size(BorderImage, 1);

                MYIndices =                         sub2ind(size(BorderImage),YCoordinates , XCoordinates);
                BorderImage(MYIndices) =            255;

                

                SE =                                strel("disk", SizeOfCircle);
                BorderImage =                       imdilate(BorderImage,SE);

        end

        function Filled = getImageFilledWithinCoordinates(obj, YCoordinates, XCoordinates, SizeOfCircle)


            BorderImage =       obj.getImageWithBorderForCoordinates(YCoordinates, XCoordinates, SizeOfCircle);


            MiddleY = round(size(BorderImage, 1) / 2);
            MiddleX =  round(size(BorderImage, 2) / 2);

             Filled =            imfill(logical(BorderImage), [MiddleY, MiddleX], 8);
            


        end


    end
    
    methods % GETTERS
       
     

         function Image =   getImage(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
           Image = obj.Image;
        
         end
        
           function [xCoordinate, yCoordinate] = getBrightestPositionInImage(obj)
                % DETECTBRIGHTESTAREAINIMAGE returns x and y-coordinate with brightest pixel in image;
                assert(isnumeric(obj.Image) && ismatrix(obj.Image), 'Wrong input.')

                [ListWithMaxValues, ListWithMaxRowIndices] =          max(obj.Image);
                [~,ListWithMaxColumnIndex] =    max(ListWithMaxValues);
                ListMaxRowIndex =               ListWithMaxRowIndices(ListWithMaxColumnIndex);
                
                yCoordinate =                   ListMaxRowIndex ;
                xCoordinate =                   ListWithMaxColumnIndex;
                %CoordinatesList =               obj.convertRectangleLimitToYXZCoordinates([ListWithMaxColumnIndex,  ListMaxRowIndex, obj.SizeForFindingCellsByIntensity, obj.SizeForFindingCellsByIntensity]);
               
           end
            
        
    end
    
    methods % SETTERS
        
        function obj = clear(obj)

            obj.Image(:, :) = 0;


        end



        function obj =      threshold(obj, Threshold)
            
           if ~ (isnumeric(Threshold) && isscalar(Threshold))
                myThreshold
                error( 'Wrong input')
           elseif isnan(Threshold)
               warning('Threshold was nan. No action taken.')
           else
                obj.Image(obj.Image < Threshold) =      0;
                obj.Image =            obj.Image > 0;
               
          end
            
          
        end
        
        function obj =      removeSmallObjects(obj, MinimumSize)
            
            ClearedImage =          bwareaopen(obj.Image, MinimumSize);
            ClearedImage =          cast(ClearedImage, class( obj.Image));
            ConvertedImage  =       ClearedImage .* obj.Image;
            obj.Image =             ConvertedImage;
            
        end
        
        function obj =      filter(obj, varargin)

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



        function obj = addCoordinatesWithIntensitySingle(obj, PixelList, Intensity)

             obj.Image(PixelList) = Intensity;

        end

        function obj = addCoordinatesWithIntensityPrecise(obj, PixelList, Intensity)

             PixelList =      obj.removeOutOfRangeCoordinates(PixelList); % necessary?
           

                             NumberOfPixels = size(PixelList,1);
                for PixelIndex = 1 : NumberOfPixels % there should be a more efficient way to do this:
                     obj.Image(PixelList(PixelIndex, 1), PixelList(PixelIndex, 2), PixelList(PixelIndex, 3)) = Intensity;
                end


        end

         function obj = addCoordinatesWithIntensity(obj, PixelList, Intensity)
             
             PixelList =      obj.removeOutOfRangeCoordinates(PixelList); % necessary?
             
             if length(PixelList) < 100
                    MinY =      min(PixelList(:, 1)) - 10;
                    MaxY =      max(PixelList(:, 1)) + 10;
                    
                    MinX =      min(PixelList(:, 2)) - 10;
                    MaxX =      max(PixelList(:, 2)) + 10;
                    
                    MinX =      max([1, MinX]);
                    MaxX =      max([1, MaxX]);
                    
                    MinY =      max([1, MinY]);
                    MaxY =      max([1, MaxY]);
             
             else
                    MinY =      min(PixelList(:, 1));
                    MaxY =      max(PixelList(:, 1));
                    
                    MinX =      min(PixelList(:, 2));
                    MaxX =      max(PixelList(:, 2));
             
                 
             end
             
        if isempty(PixelList)
            
        else
            
            
             
              obj.Image(MinY : MaxY, MinX : MaxX)  = Intensity;
        end
             
%              too slow:

                
               
                
                
         end
            
    end
    
    methods (Access =  private)
       
         function PixelList = removeOutOfRangeCoordinates(obj, PixelList)
                
                NumberOfRows = size(obj.Image,1);
                NumberOfColumns = size(obj.Image,2);
                
                PixelList(PixelList(:,1) <= 0, :) =                        [];
                PixelList(PixelList(:,2) <= 0, :) =                        [];
                PixelList(PixelList(:,1) > NumberOfRows, :) =             [];
                PixelList(PixelList(:,2) > NumberOfColumns, :) =             [];
                PixelList(isnan(PixelList(:,1)), :) =                    [];
                PixelList(isnan(PixelList(:,2)), :) =                    [];

         end
            
          
                    % this should be added somewhere optional, not as a default;
%              if strcmp(class(obj.Image), 'uint8')
%                     if sum(obj.Image(:) >= 100) >= length(obj.Image(:))/5 % get rid of highly saturated images 
%                        %  fprintf(', hypersaturated: black out')
%                         obj.Image(:,:) = 0;
%                     end
%               end
            
        
    end
end

