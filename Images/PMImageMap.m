classdef PMImageMap
    %PMIMAGEMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        RawData
    end
    
    properties (Access = private, Constant)
       FrameColumn = 10;
       PlaneColumn = 11;
    end
    
    methods
        function obj = PMImageMap(Input)
            %PMIMAGEMAP Construct an instance of this class
            %   Detailed explanation goes here
            assert(iscell(Input) && ismatrix(Input) && size(Input, 1) >= 2 && size(Input, 2) == 15, 'Image map has wrong size.')
            obj.RawData = Input(2:end, :);
        end
        
         function PlaneList = getMaxPlaneForEachFrame(obj)
            
            frames = obj.getListOfAllFrames;
            planes = obj.getListOfAllPlanes;
            
            UniqueFrames =  unique(frames);
            PlaneList = zeros(length(UniqueFrames), 1);
            for FrameIndex = 1:length(UniqueFrames)
                
               PlaneList(FrameIndex) =  max(planes(obj.getRowsForFrame(UniqueFrames(FrameIndex))));
                
            end
          
         end
        
          function rowsForFrame = getRowsForFrame(obj, Frame)
            rowsForFrame = obj.getListOfAllFrames == Frame;
            
        end
             
         
    end
    
    methods (Access = private)
        
        function frames = getListOfAllFrames(obj)
             frames = cell2mat(obj.RawData(:, obj.FrameColumn));
        end
        
         function frames = getListOfAllPlanes(obj)
             frames = cell2mat(obj.RawData(:, obj.PlaneColumn));
        end
         
   
        
    end
    
end

