classdef PMImagesExport
    %PMIMAGEEXPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        FileName
        Images
        Titles
    end
    
    methods
        function obj = PMImagesExport(varargin)
            %PMIMAGEEXPORT Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case  3
                    obj.Images =     varargin{1};
                    obj.Titles =     varargin{2};
                    obj.FileName =  varargin{3};
                otherwise
                    error('Wrong input.')
            end
         
        end
        
        function obj = exportPlaneView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
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

