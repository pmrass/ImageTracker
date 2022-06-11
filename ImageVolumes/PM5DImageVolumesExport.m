classdef PM5DImageVolumesExport
    %PM5DIMAGEVOLUMESEXPORT For writing 5D image-volume into file;
    
    properties (Access = private)
        Folder
        ImageVolumes
        Titles
        
    end
    
    methods % INITIALIZATION
        
        function obj = PM5DImageVolumesExport(varargin)
            %PM5DIMAGEVOLUMESEXPORT Construct an instance of this class
            %   Takes 3 arguments:
            % 1: vector of PM5DImageVolume objects
            % 2: cell-string array that describe individual image-volumes;
            % 3: name of folder for data export (character-string)
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 3
                    obj.ImageVolumes =  varargin{1};
                    obj.Titles =        varargin{2};
                    obj.Folder =        varargin{3};
                    
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
  
    end
    
    methods % ACTION
        
         function obj = exportPlaneSeries(obj)
             % EXPORTPLANESERIES exports individual planes of a series of image-volume into file;
            
            for PlaneIndex = 1: obj.getNumberOfPlanes
                CurrentPlane_AllVolumes =   arrayfun(@(x) x.getImageAtPlane(PlaneIndex),  obj.ImageVolumes);
                FileName =                  [obj.Folder, '/Plane_', num2str(PlaneIndex)];
                myImageExport =             PMImagesExport(CurrentPlane_AllVolumes, obj.Titles, FileName);
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

