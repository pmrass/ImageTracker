classdef PM5DImageVolumesExport
    %PM5DIMAGEVOLUMESEXPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Folder
        ImageVolumes
        Titles
        
    end
    
    methods
        function obj = PM5DImageVolumesExport(varargin)
            %PM5DIMAGEVOLUMESEXPORT Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 3
                    obj.ImageVolumes = varargin{1};
                    obj.Titles = varargin{2};
                    obj.Folder = varargin{3};
                otherwise
                    error('Wrong input')
                
                
            end
            
            
        end
        
        function obj = set.ImageVolumes(obj, Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(isa(Value, 'PM5DImageVolume') && isvector(Value), 'Wrong input.')
            obj.ImageVolumes = Value;
        end
        
        function obj = set.Folder(obj, Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(ischar(Value) , 'Wrong input.')
            obj.Folder = Value;
        end
        
        function obj = set.Titles(obj, Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(iscellstr(Value), 'Wrong input.')
            obj.Titles = Value;
        end
        
        function obj = exportPlaneSeries(obj)
            
            for PlaneIndex = 1: obj.getNumberOfPlanes
            
                Images = arrayfun(@(x) x.getImageAtPlane(PlaneIndex),  obj.ImageVolumes);
                FileName = [obj.Folder, '/Plane_', num2str(PlaneIndex)];
                myImageExport = PMImagesExport(Images, obj.Titles, FileName);
                myImageExport.exportPlaneView
            end
            
        end
        
    end
    
    methods (Access = private)
        
        function number = getNumberOfPlanes(obj)
            number = obj.ImageVolumes(1).getNumberOfPlanes;
        end
        
        function number = getNumberOfImages(obj)
            number = length(obj.ImageVolumes);
            
        end
        
    end
end

