classdef PMImagesExport
    %PMIMAGEEXPORT For exporting images into file
    
    properties (Access = private)
        FileName
        Images
        Titles
    end
    
    methods
        function obj = PMImagesExport(varargin)
            %PMIMAGEEXPORT Construct an instance of this class
            %   Takes 3 arguments
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case  3
                    obj.Images =        varargin{1};
                    obj.Titles =        varargin{2};
                    obj.FileName =      varargin{3};
                    
                otherwise
                    error('Wrong input.')
            end
         
        end
        
      
    end
    
    methods % ACTION
        
          function obj = exportPlaneView(obj)
            %EXPORTPLANEVIEW writes series of images into single file;
            
            MyFigure = figure;
            MyFigure.Position = PMFigureView().getRectangleForWideView;
            for PanelIndex = 1 : obj.getNumberOfImages
                subplot(1, obj.getNumberOfImages ,PanelIndex);
                imagesc(obj.Images(PanelIndex).getImage)
                title(obj.Titles{PanelIndex})
            end
            saveas(MyFigure, [obj.FileName, '.jpg'])
            close(MyFigure)
          end
        
        
    end
    
    methods (Access = private)

        function number = getNumberOfImages(obj)
            number = length(obj.Images);
        end
        
    end
    
end

