%Author, Rishi Tikare Yang: Judy Cannons Lab, with Paulus Mrass 

clear;

% Determine where your m-file's folder is.
%folder = fileparts(which('/Users/rishi/Documents/MATLAB/ImageTracker')); 
% Add that folder plus all subfolders to the path.
addpath(genpath('/Users/rishi/Documents/MATLAB/ImageTracker'));
load('/Users/rishi/Documents/MATLAB/ImageSequences_LacticAcid.mat');

m1 = MaskDataManager(ImagingProject);
[Masks, Centroids] = GetMaskDataOfCellOverMovie(m1, 5);

a1 = MotilityAnalyzer(Masks, Centroids);
a1 = CreateSpeedList(a1);
a1 = CreateShapeList(a1);
close all;
a1 = DisplayShapes(a1);
a1 = PlotSpeedVs(a1, 'AxesRatio');
a1 = PlotSpeedVs(a1, 'Circularity');
a1 = PlotSpeedVs(a1, 'PercentAreaConcave');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Masks = ImagingProject.ListWithMovies(51).TrackingResults.Segmentation.TimePoint(17).CellMasksInEntireZVolume;
%TimePoint = ImagingProject.ListWithMovies(51).TrackingResults.Segmentation.TimePoint;
%MasksAtFrame = [];%[frame,trackID, mask]
%for i = 1:30
%    MasksAtFrame(i) = TimePoint(i).CellMasksInEntireZVolume.ListWithPixels_3D(:,:);
%end

%m1 = MotilityAnalyzer(TimePoint);
%m1 = CreateCentroidList(m1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
CurrentMask = Masks(1).ListWithPixels_3D;
s1 = Shape(CurrentMask);
s1 = CreateImage(s1);
s1 = CreatePerimeter(s1);
im = GetImage(s1);
s1 = CreateAxes(s1);
s1 = AdjustImageToRectangle(s1);
ShowImage(s1);

s2 = Shape(Masks(2).ListWithPixels_3D);
s2 = AdjustImageToRectangle(s2);
ShowImage(s2);
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%ShapesHandle = figure('Name','Shapes','NumberTitle','off');no need?
%Im = GetImage(s1);
%{
Rect = GetRectangle(s1);
MainAxesHandle = axes('YDir', 'reverse','XTick',[],'YTick',[] );
MainAxesHandle.Position = [0,0,1,1];
CircularityText = num2str(GetCircularity(s1));
CircularityTextHandle = text(.7,0.9,['Circularity: ',CircularityText],'Units','normalized','Color','r');
ImageAxisHandle = axes('YDir', 'reverse','XTick',[],'YTick',[] );
ImageAxisHandle.Position=[0,0,0.65,1];
imshow(Im);
line(Rect.xcors,Rect.ycors, 'Color', 'red', 'LineWidth', 2);
%}
%{
imshow(Im);
j = imrotate(Im, 90);
imshow(j);
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
masknum = 23;
%framenum
shapes = cell(masknum,1);
for i=1:masknum
    shapes(i,1) ={ Shape(Masks(i).ListWithPixels_3D) };
    shapes{i,1} = AdjustImageToRectangle(shapes{i,1});
end


close all;

f1 = ShapeFigure(shapes);
f1 = CreateWindow(f1);
FillWindow(f1);
f1 = CreateHistogram(f1, 'Circularity');
f1 = CreateHistogram(f1, 'AxesRatio');
f1 = CreateHistogram(f1, 'PercentAreaConcave');
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
sq1= [1,3;2,2;2,3;2,4;3,1;3,2;3,3;3,4;3,5;4,2;4,3;4,4;5,3];

sq2 = [1,1;1,2;1,3;2,1,;2,2;2,3;3,3;3,2;3,1];

sq3 =[1,1;1,2;1,3;2,1,;2,2;2,3;3,3;3,2;3,1;4,4;4,3;4,2;4,1;1,4;2,4;3,4]; 

r=200;
c=200;
num = 1;
sq4 = zeros(r*c,2);
for y=1:r
    for x=1:c
        sq4(num,:) = [x,y];
        num=num+1;
    end
end

sh1 = Shape(sq1) ;
sh2 = Shape(sq2) ;
sh3 = Shape(sq3) ;
sh4 = Shape(sq4) ;
sh4 = AdjustImageToRectangle(sh4);
shapes2 = {sh1;sh2;sh3;sh4};

f2 = ShapeFigure(shapes2);
f2 = CreateWindow(f2);
FillWindow(f2);
%}











