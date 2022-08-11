classdef PMMovieTracking_ShapeThresholding
    %PMMOVIETRACKING_THRESHOLDING For detection of shapes in PMMovieTracking object;
    
    properties (Access = private)
        
        MovieTracking
        
        MinimumIntensity
        MaximumIntensity
        MinimumSize
        FigureNumber
        
    end
    
    methods% INTIALIZE:
        
        function obj = PMMovieTracking_ShapeThresholding(varargin)
            %PMMOVIETRACKING_THRESHOLDING Construct an instance of this class
            % Takes 5 arguments:
            % 1: PMMovieTracking
            % 2: min-intensity
            % 3: max-intensity
            % 4: min-size (number of pixels)
            % 5: figure number to show progress (NaN: do not show)
            switch length(varargin)
                
                case 5
                    obj.MovieTracking = varargin{1};
                    obj.MinimumIntensity = varargin{2};
                    obj.MaximumIntensity = varargin{3};
                    obj.MinimumSize  = varargin{4};
                    obj.FigureNumber = varargin{5};
                    
                otherwise
                    error('Wrong input.')
                
                
            end
        end
        
        
    end
    
    methods % GETTERS:
        
        function image = getShapeImage(obj)
             myMovie =                   obj.MovieTracking;

            myMovie =                   myMovie.resetChannelSettings(obj.MinimumIntensity, 'ChannelTransformsLowIn');
            myMovie =                   myMovie.resetChannelSettings(obj.MaximumIntensity, 'ChannelTransformsHighIn');
            image =                     myMovie.getRgbImage ;
            image =                     max(image, [], 3);
            image =                     PMImage(image).removeSmallObjects(obj.MinimumSize).getImage; 
            
        end
        
        function Number = getNumberOfShapePixels(obj)
            %GETNUMBEROFSHAPEPIXELS returns number of foreground pixels in image;
            %   based on minimum intensity, maximum intensity, minimum size;
            % image shown when figure number is number (not NaN);
            
            image =                     obj.getShapeImage;
            Number =                    sum(image(:)>0);

            if ~isnan(obj.FigureNumber)
                figure(obj.FigureNumber)
                imagesc(image)
            end
            
            
        end
        
        
    end
    
    
end

