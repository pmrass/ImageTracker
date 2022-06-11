classdef PM5DImageVolume
    %PM5DIMAGEVOLUME For convenient access to a 5-dimensional numerical matrix;
    % Typically used for managing image-sequence;
    % Also allows conversion of images into coordinate-lists
    
    properties (Access = private)
        ImageVolume
    end
    
    methods % initializaion
        
        function obj = PM5DImageVolume(varargin)
            %PM5DIMAGEVOLUME Construct an instance of this class
            % Takes 1 argument:
            % 5-dimensional numeric array, representing an image-volume;
            NumberOfArguments= length(varargin);
            switch NumberOfArguments
                case 1
                    obj.ImageVolume =               varargin{1};
                
                otherwise    
                    error('Wrong input.')
                
            end
            
            
            
        end
        
        function obj = set.ImageVolume(obj, Value)
             assert(isnumeric(Value) && ndims(Value) <= 5, 'Wrong input')
             obj.ImageVolume =               Value;
        end
        
        
    end
    
    methods % GETTERS: BASIC
       
        function image =        getImageVolume(obj)
            % GETIMAGEVOLUME: get image-volume;
           image = obj.ImageVolume; 
        end
        
        function image =        getImageAtPlane(obj, Plane)
            image = PMImage(obj.ImageVolume(:, :, Plane, :, :));
        end
      
        function Number =       getNumberOfPlanes(obj)
            Number = size(obj.ImageVolume,3);
        end

        function Number =       getNumberOfChannels(obj)
            Number = size(obj.ImageVolume,5);
        end
        
        function dim =          getDimenstions(obj)
            dim = size(obj.ImageVolume);
        end
 
    end
    
    methods % GETTERS
        
          function Coordinates = getSpaceCoordinates(obj)
              % GETSPACECOORDINATES returns matrix with all coordinates of non-zero pixels;
              % column 1: X-coordinates
              % column 2: Y-coordinates
              % column 3: Z-coordinates
            ListWithCoordinatesForEachPlane =   arrayfun(@(x) obj.convertImageMatrixIntoCoordinateList(x), obj.getPlaneList, 'UniformOutput', false);
            Coordinates =                       vertcat(ListWithCoordinatesForEachPlane{:});
         end
        
    end
    
  
    
    methods % SETTERS
        
         function obj =     threshold(obj, varargin)
             
               NumberOfArguments = length(varargin);
               switch NumberOfArguments
                   case 1
                       Threshold=   varargin{1};
                       obj =        obj.thresholdVolume(Threshold);
                   otherwise
                       error('Wrong input.')

               end
            
         end
        
         function obj =     filter(obj, varargin)
            % FILTER filters image-volume by input string;
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    FilterType = varargin{1};
                    obj = obj.filterVolume(FilterType);
                otherwise
                    error('Wrong input.')
            end
        end
        
         function obj =     removeSmallObjects(obj, MinimumSize)

                if length(MinimumSize) == 1
                  Result(1: obj.getNumberOfChannels, 1) = MinimumSize;
                  MinimumSize = Result;
                end

                processedVolume = obj.ImageVolume;
                 for CurrentPlane = 1:size(obj.ImageVolume,3)
                     
                        for ChannelIndex = 1: obj.getNumberOfChannels
                            
                            SourceImage =        obj.ImageVolume(:,:,CurrentPlane,1,ChannelIndex);
                            processedVolume(: , : , CurrentPlane , 1 , ChannelIndex) = PMImage(SourceImage).removeSmallObjects(MinimumSize(ChannelIndex)).getImage;
                       
                        end
                        
                 end

                 obj.ImageVolume = processedVolume;


           end
            
    end
    
    methods % ACTION

        function obj = show(obj)
            image= max(obj.ImageVolume(:, :, :, 1, 1), [], 3);
            figure
            imagesc(image)
        end

    end
    
    
    methods (Access = private) % processing of image-volume
        
         function  obj =    thresholdVolume(obj, Threshold)
            
             if isempty(Threshold)
                 
             else
                 
                  processedVolume = obj.ImageVolume;
             for PlaneIndex = 1 : size(obj.ImageVolume,3)
                    for ChannelIndex = 1: size(obj.ImageVolume,5)
                        SourceImage =        obj.ImageVolume(:,:,PlaneIndex,1,ChannelIndex);
                        
                        CurrentImage =          PMImage(SourceImage).threshold(Threshold(PlaneIndex)).getImage;
                        processedVolume(: , : , PlaneIndex , 1 , ChannelIndex) = CurrentImage;
                    end
             end

             obj.ImageVolume = processedVolume;
                 
                 
             end
             
           
                 
         end
         
         function obj =     filterVolume(obj, FilterTypes)
            
              if ischar(FilterTypes)
                  MyFilter = FilterTypes;
                  Result(1: obj.getNumberOfChannels, 1) = {MyFilter};
                  FilterTypes = Result;
              end
              
                processedVolume = obj.ImageVolume;
                 for CurrentPlane = 1:size(obj.ImageVolume,3)
                        for ChannelIndex = 1: obj.getNumberOfChannels
                            SourceImage =        obj.ImageVolume(:,:,CurrentPlane,1,ChannelIndex);
                            processedVolume(: , : , CurrentPlane , 1 , ChannelIndex) = PMImage(SourceImage).filter(FilterTypes{ChannelIndex}).getImage;
                        end
                 end
                 
                 obj.ImageVolume = processedVolume;
                         
            
            end
          

    end
    
    methods (Access = private)
        
        function DimensionX =       getSizeX(obj)
          DimensionX = size(obj.ImageVolume, 2);
        end

        function DimensionY =       getSizeY(obj)
         DimensionY = size(obj.ImageVolume, 1);
        end

        function DimensionZ =       getSizeZ(obj)
        DimensionZ = size(obj.ImageVolume, 3);
        end

        function list =             getPlaneList(obj)
        list = (1: obj.getSizeZ)';
        end

        function Coordinates =      convertImageMatrixIntoCoordinateList(obj, PlaneIndex)
            [YCoordinates, XCoordinates] =     find(obj.ImageVolume(:, :, PlaneIndex) > 0);
            ZCoordinates =                     linspace(PlaneIndex, PlaneIndex, length(YCoordinates));
            Coordinates =                       [XCoordinates, YCoordinates, ZCoordinates' ];
        end
  
    end
end

