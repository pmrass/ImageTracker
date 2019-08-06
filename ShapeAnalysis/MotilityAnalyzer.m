classdef MotilityAnalyzer
    %Author, Rishi Tikare Yang: Judy Cannons Lab, with Paulus Mrass
    %MotilityAnalyzer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MaskList
        ShapeList
        Views
        SpeedList
        CentroidList
    end
    
    methods
        function obj = MotilityAnalyzer(Masks, Centroids)
            %MotilityAnalyzer takes in Cell array of masks and number
            %array of centroids, and creates a ShapeFigure to for
            %displaying data
            obj.MaskList = Masks;
            obj.CentroidList =Centroids;
            obj.Views = ShapeFigure();
            
        end
        function obj = CreateSpeedList(obj)
            %given x number of frames creates list of x-1 number of frames,
            %finding the distance traveled between frames
            %Assumes constant time difference between frames
            %Creates number array and assigns to SpeedList
            obj.SpeedList = zeros( size(obj.MaskList,1)-1, 1);
            for i = 1: size(obj.MaskList,1)-1
               obj.SpeedList(i) = MotilityAnalyzer.FindDistanceBetween( obj.CentroidList(i,:),obj.CentroidList(i+1,:) );
            end
        end
        function obj = CreateShapeList(obj)
            %creates list of shapes from MaskList
            obj.ShapeList = cell(size(obj.MaskList,1),1);
            for i=1:size(obj.MaskList,1)
                obj.ShapeList(i,1) ={ Shape(obj.MaskList{i,1}) };
            end
        end
        
        function obj =  DisplayShapes(obj)
            %Displays Shapes from Shape list with ShapeFigure
            obj.Views = CreateWindow(obj.Views, obj.ShapeList);
            FillWindow(obj.Views, obj.ShapeList);
            
        end
        function obj = PlotSpeedVs(obj, variable, PreserveSpeedOrShape)
            %Creates plot with Shape Figure
            %Will 'preserve' speed or shape: this means it either averages
            %shape statistics(preserve speed) or averages speed (preserve
            %shape). Defaults to preseve speed
            if nargin > 2 && isequal(PreserveSpeedOrShape , 'Shape')
                
                AdjustedSpeedList = obj.SpeedList;
                InitialValue = obj.SpeedList(1,1);
                for i = 1:size(AdjustedSpeedList, 1)-1
                    AdjustedSpeedList(i,1) = (AdjustedSpeedList(i,1)+AdjustedSpeedList(i+1,1))/2;
                end
                
                AdjustedSpeedList = [InitialValue ;AdjustedSpeedList];  
                yVariable = ShapeFigure.CreateVariableList(obj.ShapeList, variable);
                obj.Views = CreateScatterPlot(obj.Views, AdjustedSpeedList, yVariable);
            else 
               yVariable = ShapeFigure.CreateVariableList(obj.ShapeList, variable);
               AdjustedVariableList = zeros(size(obj.SpeedList,1),1);
               for i=1:size(obj.SpeedList,1)
                   AdjustedVariableList(i,1) = (yVariable(i,1)+yVariable(i+1,1))/2;
               end
               obj.Views = CreateScatterPlot(obj.Views, obj.SpeedList, AdjustedVariableList);
            end
        end
        
        
    end
    methods(Static)
        function dist = FindDistanceBetween(cor1,cor2)
            %a^2 + b^2 = c^2
            dist = sqrt( (cor1(1)-cor2(1)).^2 + (cor1(2)-cor2(2)).^2 + (cor1(3)-cor2(3)).^2);
        end
    end
end

