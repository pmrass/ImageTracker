classdef PMMovieView
    %PMMOVIEVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
        Figure
        ViewMovieHandle
        
        ViewMovieAxes
        MainImage
        Rectangle
        TimeStampText
        ZStampText
        ScalebarText
        ScaleBarLine
        
        ManualDriftCorrectionLine
        CentroidLine
        CentroidLine_SelectedTrack
        
        GoTrackViews
        StopTrackViews
        
        
                        
                        
    end
    
    methods % initialization
        
        function obj = PMMovieView(Input)
            %PMMOVIEVIEW Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj.createMovieView(Input);
        end
        
    end
    
    methods % setters track lines
        
         function obj = setSegmentLineViews(obj, StopCoordinates, GoCoordinates)
    
            
            
        
            obj = setGoLines(obj, GoCoordinates);
            obj = setStopLines(obj, StopCoordinates);
            
        end
        
        function obj = setGoLines(obj, GoCoordinates)
            
            
            if ~isempty(obj.GoTrackViews)
             cellfun(@(x) delete(x), obj.GoTrackViews)
            end
           
            

            Number = size(GoCoordinates, 1);
           
             
                for Index = 1 : Number

                    obj.GoTrackViews{Index, 1} = line;
                    obj.GoTrackViews{Index, 1}.Color = 'green';
                    obj.GoTrackViews{Index, 1}.LineStyle = '-';
                    obj.GoTrackViews{Index, 1}.LineWidth = 1.5;
                    obj.GoTrackViews{Index, 1}.XData = GoCoordinates{Index}(:, 1);
                    obj.GoTrackViews{Index, 1}.YData = GoCoordinates{Index}(:,2);

                end
            
             
        end
        
          
        function obj = setStopLines(obj, StopCoordinates)
            
             if ~isempty(obj.StopTrackViews)
                cellfun(@(x) delete(x), obj.StopTrackViews)
             end

            Number = size(StopCoordinates, 1);
           
               
                for Index = 1 : Number

                    obj.StopTrackViews{Index, 1} = line;
                    obj.StopTrackViews{Index, 1}.Color = 'red';
                    obj.StopTrackViews{Index, 1}.LineStyle = '-';
                    obj.StopTrackViews{Index, 1}.LineWidth = 1.5;
                   obj.StopTrackViews{Index, 1}.XData = StopCoordinates{Index}(:, 1);
                    obj.StopTrackViews{Index, 1}.YData = StopCoordinates{Index}(:,2);

                end
            
             
        end
        
        
    end
    
    methods % setters axes 
        
        function obj = setAxesLimits(obj, XLimits, YLimits)
            obj.ViewMovieAxes.XLim =    XLimits;
            obj.ViewMovieAxes.YLim =     YLimits;
        end
        
        function obj = setAxesWidth(obj, Width)
            obj.ViewMovieAxes.Position(3) =     Width;
        end
        
        
        
        
    end
    
    methods % setters centroids
       
        
        function obj = setSelectedCentroidCoordinates(obj, X, Y)
             assert(isnumeric(X) && isvector(X) && isnumeric(Y) && isvector(Y), 'Wrong input.')
                    obj.CentroidLine.XData =         X;
                    obj.CentroidLine.YData =         Y;
            
        end
             
        function obj = setActiveCentroidCoordinates(obj, XCoordinates,YCoordinates)
         
                obj.CentroidLine_SelectedTrack.XData =      XCoordinates;
                obj.CentroidLine_SelectedTrack.YData =      YCoordinates;
                
        end
        
         function obj = setVisibilityOfActiveTrack(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.CentroidLine_SelectedTrack.Visible =         Value;
            
        end
        
      
        
        function obj = setCentroidVisibility(obj, Value)
               assert(islogical(Value) && isscalar(Value), 'Wrong input.')
                obj.CentroidLine.Visible =         Value;
        end
        
        
                
        
        
        
    end
    
    methods % setters drift correction
        
          function obj =      setManualDriftCorrectionCoordinatesWith(obj, Value)
            Type = class(Value);
            switch Type
            case 'PMMovieTracking'

               Coordinates = Value.getActiveCoordinatesOfManualDriftCorrection;

                obj.ManualDriftCorrectionLine.XData =    Coordinates(1);
                obj.ManualDriftCorrectionLine.YData =    Coordinates(2);
                if ismember(Value.getActivePlanes,   Coordinates(3) )
                    obj.ManualDriftCorrectionLine.LineWidth =           3;
                else
                    obj.ManualDriftCorrectionLine.LineWidth =          1;
                end
            otherwise
               error('Type not supported.')


            end            
        end
        
        function obj =  updateDriftWith(obj, Value)
             Type = class(Value);
             switch Type
               case 'PMMovieTracking'
                    obj.MainImage.XData =       obj.getXLimitsOfImage(Value);
                    obj.MainImage.YData =       obj.getYLimitsOfImage(Value);
               
               otherwise
                   error('Type not supported.')
             end
             
        end
            
        
        function obj = setVisibilityOfManualDriftCorrection(obj, Value)
            obj.ManualDriftCorrectionLine.Visible = Value;
            
        end
        
         
        
        
        
    end
    
    methods % setters annotation
    
        
        function obj = setAnnotationWith(obj, Value)
            
            switch Value.getTimeVisibility                  
                case 1
                  obj.TimeStampText.Visible = 'on';
                otherwise
                  obj.TimeStampText.Visible = 'off';
            end

            switch Value.getPlaneVisibility
                case 1
                  obj.ZStampText.Visible = 'on';
                otherwise
                  obj.ZStampText.Visible = 'off';
            end

            try
                MyPlaneStamp = Value.getActivePlaneStamp;
            catch
                MyPlaneStamp = 'Plane stamp not available.';
            end
            obj.ZStampText.String =             MyPlaneStamp;
            
            try 
                MyTimeStamp = Value.getActiveTimeStamp;
            catch
                MyTimeStamp = 'Time stamp not available.';
            end
                
            obj.TimeStampText.String =          MyTimeStamp;

            
            
            obj =   obj.setScaleBarVisibility(Value.getScaleBarVisibility);
            
            
            try 
               
                MicroMeter = Value.getDistanceBetweenXPixels_MicroMeter;
            catch
                MicroMeter = 1;
            end
            obj =   obj.setScaleBarSize(Value.getScaleBarSize, MicroMeter);

        end
        
         function obj = setScaleBarVisibility(obj, ScaleBarVisible)
             switch ScaleBarVisible
                  case 1
                      obj.ScaleBarLine.Visible = 'on';
                      obj.ScalebarText.Visible =        'on';
                 otherwise
                      obj.ScalebarText.Visible = 'off';
                      obj.ScaleBarLine.Visible = 'off';   
             end 
         end
         
        function obj = setAnnotationFontSize(obj, FontSize)
            obj.ScalebarText.FontSize =    FontSize;
           obj.TimeStampText.FontSize =   FontSize;
           obj.ZStampText.FontSize =      FontSize; 
        end
        
        
        
        
         
        
    end
    
    methods % setters image
       
        function obj =    setImageContent(obj, Image)
            obj.MainImage.CData =                  Image; 
        end
        
        
    end
    
   
    
    methods % setters
        
         function obj =      inactivate(obj)
            obj.MainImage.CData(:) =                      0;
            obj.ZStampText.String =                       '';

            obj.TimeStampText.String =                    '';
            obj.ScalebarText.String =                     '';
            obj.ScaleBarLine.Visible =                    'off';

            obj.CentroidLine.Visible =                    'off';
            obj.CentroidLine_SelectedTrack.Visible =      'off';
            obj.Rectangle.Visible =                       'off';
            obj.ManualDriftCorrectionLine.Visible =       'off';
            
         end
         
           
        function obj = adjustViews(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.ViewMovieAxes.Visible =         'on';
            obj.ViewMovieAxes.Units =           'centimeters';
            obj.ViewMovieAxes.DataAspectRatio = [1 1 1];
            obj.ViewMovieAxes.Position =        [11.5 5.7 19 19];
            obj.ViewMovieAxes.Units =           'pixels';

            

            obj.TimeStampText.Units =           'centimeters';
            obj.TimeStampText.Position =        [2 0.3 ];
            obj.TimeStampText.Color = 'c';

            obj.ZStampText.Units =              'centimeters';
            obj.ZStampText.Position =           [9 0.3 ];
            obj.ZStampText.Color = 'c';

            obj.ScalebarText.Units =            'centimeters';
            obj.ScalebarText.Position =         [16 0.3 ];
            obj.ScalebarText.Color = 'c';
        end
        
       
        
        function obj = setDefaults(obj)
           obj.ViewMovieAxes.Color =       [0.1 0.1 0.1]; 
        end
       
       
      
        
       
        
        
        
        
        
    end
    
    methods % getters
        
        function Value = getAxes(obj)
            Value = obj.ViewMovieAxes;
        end
      
        function xLimits =  getXLimitsOfImage(~, Value)
            [~, columnsInImage, ~] =        Value.getImageDimensions;
            CurrentColumnShift=             Value.getAplliedColumnShiftsForActiveFrames;
            xLimits =                       [1+  CurrentColumnShift, columnsInImage + CurrentColumnShift];
        end

        function yLimits =  getYLimitsOfImage(~, Value)
            [rowsInImage, ~, ~] =       Value.getImageDimensions;
            CurrentRowShift =           Value.getAplliedRowShiftsForActiveFrames;
            yLimits =                   [1+  CurrentRowShift, rowsInImage + CurrentRowShift];
        end
        
        function Value = getImage(obj)
           Value = obj.MainImage; 
        end
        
        function Value = getRectangle(obj)
           Value = obj.Rectangle; 
        end
        
    end
    
    methods (Access = private)
       
        

        %% setScaleBarSize
        function obj = setScaleBarSize(obj, LengthInMicrometer, VoxelSizeXuM)

            assert(isnumeric(LengthInMicrometer) && isscalar(LengthInMicrometer) && ...
                isnumeric(VoxelSizeXuM) && isscalar(VoxelSizeXuM), 'Wrong input.')
            
                

               [AxesWidthCentimeter, AxesHeightCentimeter] = obj.getAxesDimentionsInCm;

               obj.ScalebarText.Units =          'centimeters';
                WantedLeftPosition =          obj.ScalebarText.Position(1);
                

                RelativeLeftPosition =     WantedLeftPosition / AxesWidthCentimeter;
                AxesWidthPixels =          diff(obj.ViewMovieAxes.XLim);
                XLimWidth =                AxesWidthPixels * RelativeLeftPosition;
                XLimStart =                obj.ViewMovieAxes.XLim(1);
                XLimMiddleBar =            XLimStart + XLimWidth;

                AxesHeightPixels =         diff(obj.ViewMovieAxes.YLim);

                if AxesWidthPixels>AxesHeightPixels
                    RealAxesHeightCentimeter = AxesHeightCentimeter * AxesHeightPixels/ AxesWidthPixels;
                else
                    RealAxesHeightCentimeter = AxesHeightCentimeter;
                end


                WantedCentimeters =           0.9;
                PixelsPerCentimeter =              AxesHeightPixels / RealAxesHeightCentimeter;
                PixelsForWantedCentimeters =      PixelsPerCentimeter * WantedCentimeters;
                YLimStart =                       obj.ViewMovieAxes.YLim(2) - PixelsForWantedCentimeters;


                LengthInPixels =      LengthInMicrometer / VoxelSizeXuM;

                obj.ScaleBarLine.Marker = 'none';
                obj.ScaleBarLine.XData = [(XLimMiddleBar - LengthInPixels/2), (XLimMiddleBar +  LengthInPixels/2) ];
                obj.ScaleBarLine.YData = [ YLimStart, YLimStart];

                
                obj.ScalebarText.String =         strcat(num2str(LengthInMicrometer), ' µm');

        end
        
        function [AxesWidthCentimeter, AxesHeightCentimeter] = getAxesDimentionsInCm(obj)
             obj.ViewMovieAxes.Units =         'centimeters';
                AxesWidthCentimeter =             obj.ViewMovieAxes.Position(3);
                AxesHeightCentimeter =            obj.ViewMovieAxes.Position(4);
                obj.ViewMovieAxes.Units =         'pixels';
        end
        
         function obj = createMovieView(obj, Input)
              FontSize =                                      20;
                FontColor =                                     [ 0 0.1 0.99];
                TimeColumn =                                    0.1;
                PlaneColumn =                                   0.5;
                ScaleColumn =                                  0.9;
                AnnotationRow =                                 0.2;

            if ~ishghandle(Input,'axes') 
                MovieFigure=                                    Input.getFigure;

                obj.ViewMovieAxes=                           axes;
                obj.ViewMovieAxes.Tag=                       'ImageAxes';
                obj.ViewMovieAxes.Position=                  [0 0 1 1];
                obj.ViewMovieAxes.DataAspectRatioMode=       'manual'; % this can be tricky, maybe better to turn it off and manually correct the x-y ratio for each view?
                 
            else
                MovieFigure =                           Input.Parent;
                obj.ViewMovieAxes =                         Input;
                
            end
            
                obj.Figure.CurrentAxes = obj.ViewMovieAxes;
          
                    obj.ViewMovieAxes.Visible=                   'on';
                    obj.ViewMovieAxes.YDir=                      'reverse';  
                    obj.ViewMovieAxes.XColor =                      'c';
                    obj.ViewMovieAxes.YColor =                      'c';
                    
                    
                %% image and cropping
                    HandleOfMainImage=                      image;
                    HandleOfMainImage.Tag=                  'ImageOfFigure'; 
                    HandleOfMainImage.Parent=               obj.ViewMovieAxes; % this is a safety thing but may be redundant;

                    handleOfRectangle=                              line;
                    handleOfRectangle.MarkerSize=                   14;
                    handleOfRectangle.Color=                        'w';
                    handleOfRectangle.Tag=                          'ClickedPosition';
                    handleOfRectangle.Parent=                       obj.ViewMovieAxes;
                    handleOfRectangle.Marker=                       'none';



                %% annotation text:
                    TimeStampTextHandle=                            text(1, 1, '');
                    TimeStampTextHandle.FontSize=                   FontSize;
                    TimeStampTextHandle.HorizontalAlignment=        'center'; 
                    TimeStampTextHandle.Color=                      FontColor;
                    TimeStampTextHandle.Units=                      'normalized'; 
                    TimeStampTextHandle.Position=                   [TimeColumn AnnotationRow];
                    TimeStampTextHandle.Tag=                        'TimeStamp';
                    TimeStampTextHandle.String=                     'Timestamp';
                    TimeStampTextHandle.Parent=                     obj.ViewMovieAxes;
                    
                        ZStampTextHandle=                               text(1, 1, '');
                        ZStampTextHandle.FontSize=                      FontSize;
                        ZStampTextHandle.HorizontalAlignment=           'center';
                        ZStampTextHandle.Color=                         FontColor;
                        ZStampTextHandle.Units=                         'normalized';
                        ZStampTextHandle.Position=                      [PlaneColumn AnnotationRow];
                        ZStampTextHandle.Tag=                           'ZStamp';
                        ZStampTextHandle.String=                     'ZStamp';
                        ZStampTextHandle.Parent=                     obj.ViewMovieAxes;
                  
                        ScalebarTextHandle=                         text(1, 1, '');
                        ScalebarTextHandle.FontSize=                FontSize;
                        ScalebarTextHandle.HorizontalAlignment=     'center';
                        ScalebarTextHandle.Color=                   FontColor;
                        ScalebarTextHandle.Units=                   'normalized';
                        ScalebarTextHandle.Tag=                     'ScaleBar';
                        ScalebarTextHandle.Position=                [ScaleColumn AnnotationRow];
                        ScalebarTextHandle.String =                 'Scalebar';
                        ScalebarTextHandle.Parent=                     obj.ViewMovieAxes;
                   
                        
                          ScaleBarLineHandle=                          line; 
                         ScaleBarLineHandle.Parent=                   obj.ViewMovieAxes;
                         ScaleBarLineHandle.Marker=                   's';
                         ScaleBarLineHandle.MarkerSize=               8;
                         ScaleBarLineHandle.Color=                    'w';
                         ScaleBarLineHandle.Tag=                      'ScaleBarLineHandle';
                         ScaleBarLineHandle.LineStyle=                '-';
                         ScaleBarLineHandle.MarkerFaceColor=          'none';
                         ScaleBarLineHandle.MarkerEdgeColor=          'w';
                         ScaleBarLineHandle.LineWidth=                3;
                        ScaleBarLineHandle.Visible =                'off';
                      


                        %% drift correction and tracking:
                        HandleOfManualDriftCorrectionLine=                          line; 

                         HandleOfManualDriftCorrectionLine.Parent=                   obj.ViewMovieAxes;
                         HandleOfManualDriftCorrectionLine.Marker=                   'x';
                         HandleOfManualDriftCorrectionLine.MarkerSize=               15;
                         HandleOfManualDriftCorrectionLine.Color=                    'w';
                         HandleOfManualDriftCorrectionLine.Tag=                      'ManualDriftCorrectionLine';
                         HandleOfManualDriftCorrectionLine.LineStyle=                'none';
                         HandleOfManualDriftCorrectionLine.MarkerFaceColor=          'none';
                         HandleOfManualDriftCorrectionLine.MarkerEdgeColor=          'w';
                         HandleOfManualDriftCorrectionLine.LineWidth=                   2;
                         HandleOfManualDriftCorrectionLine.Visible =                'off';

                        HandleOfCentroidLine=                          line; 
                         HandleOfCentroidLine.Parent=                   obj.ViewMovieAxes;
                         HandleOfCentroidLine.Marker=                   'x';
                         HandleOfCentroidLine.MarkerSize=               10;
                         HandleOfCentroidLine.Color=                    'c';
                         HandleOfCentroidLine.Tag=                      'CentroidLine';
                         HandleOfCentroidLine.LineStyle=                'none';
                         HandleOfCentroidLine.MarkerFaceColor=          'none';
                         HandleOfCentroidLine.MarkerEdgeColor=          'b';
                         HandleOfCentroidLine.LineWidth=                4;
                        HandleOfCentroidLine.Visible =                'off';
                        HandleOfCentroidLine_SelectedTrack=                          line; 

                         HandleOfCentroidLine_SelectedTrack.Parent=                   obj.ViewMovieAxes;
                         HandleOfCentroidLine_SelectedTrack.Marker=                   's';
                         HandleOfCentroidLine_SelectedTrack.MarkerSize=               25;
                         HandleOfCentroidLine_SelectedTrack.Color=                    'm';
                         HandleOfCentroidLine_SelectedTrack.Tag=                      'HandleOfCentroidLine_SelectedTrack';
                         HandleOfCentroidLine_SelectedTrack.LineStyle=                'none';
                         HandleOfCentroidLine_SelectedTrack.MarkerFaceColor=          'none';
                         HandleOfCentroidLine_SelectedTrack.MarkerEdgeColor=          'm';
                         HandleOfCentroidLine_SelectedTrack.LineWidth=                2.5;
                         HandleOfCentroidLine_SelectedTrack.Visible =                'off';

                        %% get all handles
                        obj.ViewMovieHandle=                   MovieFigure;

                        obj.MainImage=                         HandleOfMainImage;
                        obj.ScalebarText=                      ScalebarTextHandle;
                        obj.ScaleBarLine=                      ScaleBarLineHandle;
                        
                        obj.TimeStampText=                     TimeStampTextHandle;
                        obj.ZStampText=                        ZStampTextHandle;
                        obj.ManualDriftCorrectionLine=         HandleOfManualDriftCorrectionLine;
                        obj.CentroidLine=                      HandleOfCentroidLine;
                        obj.CentroidLine_SelectedTrack=        HandleOfCentroidLine_SelectedTrack;
                        obj.Rectangle=                         handleOfRectangle;

            
         end
        
        
        
    end
end

