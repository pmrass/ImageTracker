classdef ShapeFigure
    %Author, Rishi Tikare Yang: Judy Cannons Lab, with Paulus Mrass 
    %Creates figures and axes to display: list of shapes, histogram, plots
    %Fills Figure/axes with given information
    properties
        MainAxesHandle
        ImageAxesHandleList
        TextAxesHandleList
        HistogramHandleList
        ScatterHandleList
    end
    
    methods
        function obj = ShapeFigure()
            
        end
        
        function obj = CreateWindow(obj, ShapeList)%it SHOULD be able to input either the number of shapes, or the shapelist
            %creates a roughly square figure with axes to be filled with
            %images - figure is square or one row wider than square
            
            numrows = floor( sqrt( size( ShapeList, 1) + 1));%%plus one becasue the last axes will be filled with text 
            numcols = ceil( (size( ShapeList, 1) + 1) / numrows );%%^^^^
            axisheight = 1/numrows;
            axislength = 1/numcols;
            
            AxesList = cell(numrows, numcols);
            TextAxes = cell(numrows, numcols);
            NumberOfTextLines = 3;%<---change number of text lines here, this will adjust normalized size of text 
            
            
            figure1 = figure('Name', 'Cell Data');%Figure handle is not saved, but if needed to, start here
            obj.MainAxesHandle = axes('XTick',[],'YTick',[] );%<--Those properties make the axes less visible
            obj.MainAxesHandle.Position = [0,0,1,1];
            for c = 1:numcols
                for r=1:numrows
                    %{ 
                    %fills from bottom left to top right
                    AxesList(r, c) = { axes( 'YDir', 'reverse','XTick',[],'YTick',[]) };
                    AxesList{r, c}.Position =  [axislength*(c-1),axisheight*(r-1)+axisheight*0.1,axislength, axisheight*0.9];
                    TextAxes(r,c) = { axes('XTick',[],'YTick',[]) };
                    TextAxes{r, c}.Position =  [axislength*(c-1),axisheight*(r-1),axislength, axisheight*0.1];
                    %}
                    %fills from top left to bottom right by column
                    AxesList(r, c) = { axes( 'YDir', 'reverse','XTick',[],'YTick',[]) };
                    AxesList{r, c}.Position =  [axislength*(c-1),(1-axisheight*r)+axisheight*NumberOfTextLines/10,axislength, axisheight*(1-NumberOfTextLines/10)];
                    TextAxes(r,c) = { axes('XTick',[],'YTick',[]) };
                    TextAxes{r, c}.Position =  [axislength*(c-1),(1-axisheight*r),axislength, axisheight*NumberOfTextLines/10];
                    
                end
            end
            obj.ImageAxesHandleList = AxesList;
            obj.TextAxesHandleList = TextAxes;
        end
        function FillWindow(obj, ShapeList)
            %fills axes with images and text, 
            %fills left to right, then top to bottom
            ishape = 1;
            for r=1:size(obj.ImageAxesHandleList,1)
                for c=1:size(obj.ImageAxesHandleList,2)
                    %%show avergare cicularity
                    if ishape > size(ShapeList,1)%if all shapes have been displayed
                        AC = num2str(ShapeFigure.GetAverageCircularity(ShapeList));
                        text(0.05,0.5,['Average Circularity: ', newline AC],...
                            'Units','normalized',...
                            'Color','k',...
                            'FontUnits','normalized',...
                            'FontSize', 0.1,...
                            'Parent', obj.ImageAxesHandleList{r,c});
                        break;
                    end
                    %%show image
                    image = GetImage(ShapeList{ishape,1});
                    imshow(image, 'Parent', obj.ImageAxesHandleList{r,c} );
                    
                    %%draw rectangle
                    Rectangle = GetRectangle(ShapeList{ishape,1});
                    line(Rectangle.xcors,Rectangle.ycors,...
                        'Color', '#EDB120',...
                        'LineWidth', 2,...
                        'Parent', obj.ImageAxesHandleList{r,c});
                    
                    %%Draw longest line
                    LongestLine = GetLongestLine(ShapeList{ishape,1});
                    line(LongestLine(:,1),LongestLine(:,2),...
                        'Color', '#77AC30',...
                        'LineWidth', 2,...
                        'Parent', obj.ImageAxesHandleList{r,c},...
                        'LineStyle','--');
                    
                    %%display stats
                    Circularity = num2str( GetCircularity(ShapeList{ishape,1}) );
                    ShapeAxes = GetAxesLength(ShapeList{ishape,1}) ;
                    AxesRatio = num2str(ShapeAxes(1)/ShapeAxes(2));
                    ConcavePercentage = num2str(GetPercentAreaConcave(ShapeList{ishape,1}));
                    t = ['Circularity: ' Circularity newline 'Axes Ratio: ' AxesRatio newline 'Concave Area %: ' ConcavePercentage];
                    text(0.05,0.5,t,...
                        'Units','normalized',...
                        'Color','k',...
                        'FontUnits','normalized',...
                        'FontSize', 0.75/3,...
                        'Parent', obj.TextAxesHandleList{r,c});
                    
                    ishape = ishape + 1;
                    
                    
                end
            end
        end
        function obj = CreateHistogram(obj,ShapeList, variable)
            %Given List of Shapes, and a variable, creates histogram in new
            %figure
            %Data is put into a list with CreateVariableList Function
            
            VariableList = ShapeFigure.CreateVariableList(ShapeList, variable);
            rows = size(obj.HistogramHandleList,1); 
            obj.HistogramHandleList{rows+1,1}.figure = figure('Name', [variable ' Histogram'] );
            obj.HistogramHandleList{rows+1,1}.axes = axes('XTick',[],'YTick',[] );
            obj.HistogramHandleList{rows+1,1}.histogram = histogram(VariableList );
            
        
        end
        function obj = CreateScatterPlot(obj, xVariable, yVariable, ShapeList)
            %   Given List of Shapes, and a variable, creates scatter plot in new
            %figure.
            %   yVaribale can be either the string of a variable name that 
            %is known to CreateVariableListor, or can be data ready to plot.
            %   If yVariable is a string, and only if yVariable is a string,
            %then the shapelist should be provided as an argument so data
            %can be retrieved.
            
            %MakeAxesLabels
            xString = xVariable;
            yString = yVariable;
            if ~isstring(xString)
                xString = 'Speed';
            end
            if ~isstring(yString)
                yString = 'Variable';
            end
            %Set Up figure and axes
            rows = size(obj.ScatterHandleList,1);
            obj.ScatterHandleList{rows+1,1}.figure = figure('Name', [yString ' vs ' xString ' Scatter Plot'] );
            obj.ScatterHandleList{rows+1,1}.axes = axes();
            %Check what to plot
            if nargin == 3
                obj.ScatterHandleList{rows+1,1}.scatter = scatter(xVariable, yVariable,'filled' );
            else
                yVariable = ShapeFigure.CreateVariableList(ShapeList, yVariable);
                obj.ScatterHandleList{rows+1,1}.scatter = scatter(xVariable, yVariable, 'filled' );
            end
            %Add Axes Labels 
            obj.ScatterHandleList{rows+1,1}.axes.XLabel.String = xString;
            obj.ScatterHandleList{rows+1,1}.axes.YLabel.String = yString;                                      
        end
        
    end
    methods(Static)
        function AverageCirculary = GetAverageCircularity(shapelist)
            %return number calculated from given list
            totalCircularity = 0;
            numCircularity = 0;
            
            for i = 1:size(shapelist,1)
                totalCircularity = totalCircularity+GetCircularity(shapelist{i,1});
                numCircularity = numCircularity+1;
            end
            AverageCirculary = totalCircularity/numCircularity;
        end
        function VariableList = CreateVariableList(ShapeList, variable)
            %creates List of numbers for plot of the given variable
            VariableList = zeros(size(ShapeList,1),1);
            
            switch variable
                case 'Circularity'
                    for i = 1:size(ShapeList,1)
                        VariableList(i,1) = GetCircularity(ShapeList{i,1});
                    end
                case 'PercentAreaConcave'
                    for i = 1:size(ShapeList,1)
                        VariableList(i,1) = GetPercentAreaConcave(ShapeList{i,1});
                    end
                case 'AxesRatio'
                    for i = 1:size(ShapeList,1)
                        ShapeAxes = GetAxesLength(ShapeList{i,1}) ;
                        VariableList(i,1) = ShapeAxes(1)/ShapeAxes(2);
                    end
                otherwise
                    disp('Invalid variable');
            end
        end
        
    end
end

