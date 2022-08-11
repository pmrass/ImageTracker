classdef PMMovieView
    %PMMOVIEVIEW manages views showing captured images
    %   shows image and annotation such as scale bar, Z-plane, time and tracked cells;
    
    properties (Access = private)
        
        Figure
        
        
        ViewMovieAxes
       
        
        
        MainImage
        Rectangle
        TimeStampText
        ZStampText
        ScalebarText
        ScaleBarLine
        
        ManualDriftCorrectionLine
        CentroidLine
        CentroidLineOfActiveTrack
        
        GoTrackViews
        StopTrackViews
        
        
                        
                        
    end
    
    properties (Constant, Access = private)
            TimeColumn =                                    0.1;
            PlaneColumn =                                   0.5;
            ScaleColumn =                                  0.9;
            AnnotationRow =                                 0.2;

            FontSize =                                      20;
            FontColor =                                     [ 0 0.1 0.99];
             

        
        
    end
    
    methods % INITIALIZATION
        
        function obj = PMMovieView(Input)
            %PMMOVIEVIEW Construct an instance of this class
            %   takes 1 argument:
            % 1: axes or object that has method getFigure
            
             switch class(Input)
                   
                    case 'PMImagingProjectViewer'
                        obj.Figure=          Input.getFigure;
                    obj =       obj.clear;
                         obj =       obj.initializeHandles(Input);

                    case 'matlab.graphics.axis.Axes'
                         obj.Figure =        Input.Parent;
                       obj =       obj.initializeHandles(Input);
                        
                    otherwise
                        error('Wrong input.')
                    
              end
           
        end
        
        function obj = set.CentroidLine(obj, Value)
           assert(isscalar(Value) && isa(Value, 'matlab.graphics.primitive.Line'), 'Wrong input.')
            obj.CentroidLine = Value;
            
        end
        
    end
    
    methods % SETTERS: general resets
        
        function obj =      clear(obj)
            % CLEAR delete all relevant handles;
            delete(obj.getListOfHandles);
            
            obj = obj.deleteStopTracks;
            obj = obj.deleteGoTracks;
                
                 ImageAxes = findobj(obj.Figure, 'Tag', 'ImageAxes');
             arrayfun(@(x) delete(x), ImageAxes);
             
                   OtherAxes = findobj(obj.Figure, 'Type', 'Axes'); % this could be undesirable when main figure has other axes;
             arrayfun(@(x) delete(x), OtherAxes);
             
             Images = findobj(obj.Figure, 'Tag', 'ImageOfFigure');
             arrayfun(@(x) delete(x), Images);
        

          end
      
        function obj =      inactivate(obj)
            obj.MainImage.CData(:) =                      0;
            obj.ZStampText.String =                       '';

            obj.TimeStampText.String =                    '';
            obj.ScalebarText.String =                     '';
            obj.ScaleBarLine.Visible =                    'off';

            obj.CentroidLine.Visible =                    'off';
            obj.CentroidLineOfActiveTrack.Visible =      'off';
            obj.Rectangle.Visible =                       'off';
            obj.ManualDriftCorrectionLine.Visible =       'off';
            
        end
        
        function obj =      setDefaults(obj)
           obj.ViewMovieAxes.Color =       [0.1 0.1 0.1]; 
        end  
        
    end
    
    methods % SETTERS AXES 

        function obj = setAxesLimits(obj, XLimits, YLimits)
            % SETAXESLIMITS sets limits of axes;
            % takes 2 arguments:
            % 1: limits for x-axis;
            % 2: limits for y-axis;
            
            obj =                               obj.updateGraphicHandles;
            
            obj.ViewMovieAxes.Units =           'normalized';
            obj.ViewMovieAxes.Position =        [0.25 0.22 0.7 0.75];
            obj.ViewMovieAxes.Units =           'pixels';
            
            obj.ViewMovieAxes.XLim =            XLimits;
            obj.ViewMovieAxes.YLim =            YLimits;
            obj =                               obj.adjustWidthOfMovieAxes;
            obj =                               obj.setHorizontalPositionsOfAnnotation;

        end



    end
    
    methods % SETTERS IMAGE

        function obj =    setImageContent(obj, Image)
            % SETIMAGECONTENT sets CData of image;
            % takes 1 argument:
            % 1: image intensity pixels
            obj =                           obj.updateGraphicHandles;  
            obj.MainImage.CData =           Image; 
        end
        
        function obj =      updateDriftWith(obj, Value)
            % UPDATEDRIFTWITH adjust position of image based on current drift-correction;
            % takes 1 argument:
            % 1: PMMovieTracking;
            obj =                           obj.updateGraphicHandles;

            Type = class(Value);
            switch Type
                case 'PMMovieTracking'
                    XLimits =                       obj.getXLimitsOfImage(Value);
                    YLimits =                       obj.getYLimitsOfImage(Value);
                    
                    obj.MainImage.XData =       XLimits;
                    obj.MainImage.YData =       YLimits;

                otherwise
                   error('Type not supported.')
            end

        end
        

    end

    
    
    
    

  
    methods % SETTERS CENTROIDS
       
        function obj = setSelectedCentroidCoordinates(obj, X, Y)
             %SETSELECTEDCENTROIDCOORDINATES set centroids of visible masks;
             % takes 2 arguments:
             % 1: numerical vector with X-values
             % 2: numerical vector with Y-values
            
            assert(isnumeric(X) && isvector(X) && isnumeric(Y) && isvector(Y), 'Wrong input.')
            obj =                           obj.updateGraphicHandles;
            obj.CentroidLine.XData =         X;
            obj.CentroidLine.YData =         Y;
            
        end
        
        function obj = setCentroidVisibility(obj, Value)
            % SETCENTROIDVISIBILITY set visibility of centroids;
            % takes 1 argument:
            % 1: logical scalar;
               assert(islogical(Value) && isscalar(Value), 'Wrong input.')
                 obj =                           obj.updateGraphicHandles;
                obj.CentroidLine.Visible =         Value;
        end
           
        function obj = setActiveCentroidCoordinates(obj, XCoordinates,YCoordinates)
            % SETACTIVECENTROIDCOORDINATES set centroid of active track;
             % takes 2 arguments:
             % 1: numerical vector with X-values
             % 2: numerical vector with Y-values
            
            obj =                                       obj.updateGraphicHandles;
            obj.CentroidLineOfActiveTrack.XData =       XCoordinates;
            obj.CentroidLineOfActiveTrack.YData =       YCoordinates;
                
        end
        
        function obj = setVisibilityOfActiveTrack(obj, Value)
            % SETVISIBILITYOFACTIVETRACK sets visibility of centroid of active track;
            % takes 1 argument:
            % 1: logical scalar;
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj =                           obj.updateGraphicHandles;
            obj.CentroidLineOfActiveTrack.Visible =         Value;
            
        end

        
        
    end
    
    methods % SETTERS DRIFT-CORRECTION
        
        function obj =      setManualDriftCorrectionCoordinatesWith(obj, Value)
              obj =                           obj.updateGraphicHandles;
              
            Type = class(Value);
            switch Type
                case 'PMMovieTracking'

                   Coordinates = Value.getActiveManualDriftCorrectionWithAppliedDriftCorrection;

                    obj.ManualDriftCorrectionLine.XData =    Coordinates(1);
                    obj.ManualDriftCorrectionLine.YData =    Coordinates(2);
                    if ismember(Value.getActivePlanesWithAppliedDriftCorrection,   Coordinates(3) )
                        obj.ManualDriftCorrectionLine.LineWidth =           3;
                    else
                        obj.ManualDriftCorrectionLine.LineWidth =          1;
                    end
                otherwise
                   error('Type not supported.')


            end            
        end
        
      
            
        function obj =      setVisibilityOfManualDriftCorrection(obj, Value)
              obj =                           obj.updateGraphicHandles;
              
            obj.ManualDriftCorrectionLine.Visible = Value;
            
        end
        
    end
    
    methods % SETTERS ANNOTATION
    
        function obj = setAnnotationWith(obj, Value)
            % SETANNOTATIONWITH set state of annotation views (time, Z-plane, scale-bar);
            % takes 1 argument:
            % 1: scalar of PMMovieTracking
            
            assert(isscalar(Value) && isa(Value, 'PMMovieTracking'), 'Wrong input.')
            
             obj =                           obj.updateGraphicHandles;
            
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
            
              obj =                           obj.updateGraphicHandles;
              
             switch ScaleBarVisible
                  case 1
                      obj.ScaleBarLine.Visible =    'on';
                      obj.ScalebarText.Visible =    'on';
                      
                 otherwise
                      obj.ScalebarText.Visible =    'off';
                      obj.ScaleBarLine.Visible =    'off';   
             end 
         end
         
        function obj = setAnnotationFontSize(obj, FontSize)
            
            obj =                           obj.updateGraphicHandles;

            obj.ScalebarText.FontSize =    FontSize;
            obj.TimeStampText.FontSize =   FontSize;
            obj.ZStampText.FontSize =      FontSize; 
        end
         
    end
    

    methods % GETTERS
        
        function Value = getAxes(obj)
            Value = obj.ViewMovieAxes;
        end
      
        function Value = getImage(obj)
           Value = obj.MainImage; 
        end
        
        function Value = getRectangle(obj)
           Value = obj.Rectangle; 
        end
        
     
        
    end
    
    methods % SETTERS TRACK LINES
        
        function obj = setSegmentLineViews(obj, StopCoordinates, GoCoordinates)
            obj = setGoLines(obj, GoCoordinates);
            obj = setStopLines(obj, StopCoordinates);
            
        end
        
        function obj = setGoLines(obj, GoCoordinates)
            
            
           
           obj = deleteGoTracks(obj);
            

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
        
        function obj = deleteGoTracks(obj)
             if ~isempty(obj.GoTrackViews)
             cellfun(@(x) delete(x), obj.GoTrackViews)
            end
            
        end
          
        function obj = setStopLines(obj, StopCoordinates)
            
           obj = obj.deleteStopTracks;

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
        
        function obj = deleteStopTracks(obj)
              if ~isempty(obj.StopTrackViews)
                cellfun(@(x) delete(x), obj.StopTrackViews)
             end
            
        end
        
        end
    
    
     methods (Access = private) % SETTERS INITIALIZE GRAPHIC OBJECTS;
        
       
        function obj =      initializeHandles(obj, Input)
            
            obj =       obj.initializeAxes(Input);
            obj =       obj.initializeImage;
            obj =       obj.initializeAnnotationHandles;
            obj =       obj.initializeDriftCorrectionLine;
            obj =       obj.initializeCentroidLine;
            obj =       obj.initializeCentroidLineForActiveTrack;
                
        end
        
        function obj =      initializeAxes(obj, Input)

            switch class(Input)
                case 'matlab.graphics.axis.Axes'
                     obj.ViewMovieAxes =                         Input;

                otherwise
                    obj.ViewMovieAxes=                           axes;


            end

            obj.ViewMovieAxes.Parent =           obj.Figure;

            obj.ViewMovieAxes.Tag=                       'ImageAxes';
            obj.ViewMovieAxes.DataAspectRatioMode=       'manual'; % this can be tricky, maybe better to turn it off and manually correct the x-y ratio for each view?

            obj.ViewMovieAxes.DataAspectRatio = [1 1 1];
            obj.ViewMovieAxes.Visible=         'on';
            obj.ViewMovieAxes.YDir=            'reverse';  
            obj.ViewMovieAxes.XColor =         'c';
            obj.ViewMovieAxes.YColor =         'c';

            obj.ViewMovieAxes.Visible =         'on';
         

            obj.Figure.CurrentAxes =             obj.ViewMovieAxes;


               obj.ViewMovieAxes.Units =           'normalized';

               
                 
            obj.ViewMovieAxes.Position =        [0.25 0.18 0.7 0.8];
            
           
            obj.ViewMovieAxes.Units =           'pixels';

        end

        function obj =      initializeImage(obj)
                obj.MainImage=                      image;
                obj.MainImage.Tag=                  'ImageOfFigure'; 
                obj.MainImage.Parent=               obj.ViewMovieAxes; 

                obj.Rectangle=                              line;
                obj.Rectangle.MarkerSize=                   14;
                obj.Rectangle.Color=                        'w';
                obj.Rectangle.Tag=                          'ClickedPosition';
                obj.Rectangle.Parent=                       obj.ViewMovieAxes;
                obj.Rectangle.Marker=                       'none';




        end

        function obj =      initializeAnnotationHandles(obj)


                TimeStampTextHandle=                            text(1, 1, '');
                TimeStampTextHandle.FontSize=                   obj.FontSize;
                TimeStampTextHandle.HorizontalAlignment=        'center'; 
                TimeStampTextHandle.Color=                      obj.FontColor;
                TimeStampTextHandle.Units=                      'normalized'; 
                TimeStampTextHandle.Position=                   [obj.TimeColumn obj.AnnotationRow];
                TimeStampTextHandle.Tag=                        'TimeStamp';
                TimeStampTextHandle.String=                     'Timestamp';
                TimeStampTextHandle.Parent=                     obj.ViewMovieAxes;

                    ZStampTextHandle=                               text(1, 1, '');
                    ZStampTextHandle.FontSize=                      obj.FontSize;
                    ZStampTextHandle.HorizontalAlignment=           'center';
                    ZStampTextHandle.Color=                         obj.FontColor;
                    ZStampTextHandle.Units=                         'normalized';
                    ZStampTextHandle.Position=                      [obj.PlaneColumn obj.AnnotationRow];
                    ZStampTextHandle.Tag=                           'ZStamp';
                    ZStampTextHandle.String=                     'ZStamp';
                    ZStampTextHandle.Parent=                     obj.ViewMovieAxes;

                    ScalebarTextHandle=                         text(1, 1, '');
                    ScalebarTextHandle.FontSize=                obj.FontSize;
                    ScalebarTextHandle.HorizontalAlignment=     'center';
                    ScalebarTextHandle.Color=                   obj.FontColor;
                    ScalebarTextHandle.Units=                   'normalized';
                    ScalebarTextHandle.Tag=                     'ScaleBar';
                    ScalebarTextHandle.Position=                [obj.ScaleColumn obj.AnnotationRow];
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

                     obj.ScalebarText=                      ScalebarTextHandle;
                    obj.ScaleBarLine=                      ScaleBarLineHandle;

                    obj.TimeStampText=                     TimeStampTextHandle;
                    obj.ZStampText=                        ZStampTextHandle;



        end

        function obj =      initializeDriftCorrectionLine(obj)

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


                    obj.ManualDriftCorrectionLine=         HandleOfManualDriftCorrectionLine;

        end
         
        function obj =      initializeCentroidLine(obj)
            
            obj.CentroidLine=                          line; 
            obj.CentroidLine.Parent=                   obj.ViewMovieAxes;
            obj.CentroidLine.Marker=                   'x';
            obj.CentroidLine.MarkerSize=               10;
            obj.CentroidLine.Color=                    'c';
            obj.CentroidLine.Tag=                      'CentroidLine';
            obj.CentroidLine.LineStyle=                'none';
            obj.CentroidLine.MarkerFaceColor=          'none';
            obj.CentroidLine.MarkerEdgeColor=          'b';
            obj.CentroidLine.LineWidth=                4;
            obj.CentroidLine.Visible =                'off';
                        
            
        end
        
        function obj =      initializeCentroidLineForActiveTrack(obj)
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
                      
                        
                   
                        obj.CentroidLineOfActiveTrack=        HandleOfCentroidLine_SelectedTrack;
                        
        end
                       

     end
    
     methods (Access = private) % SETTERS AXES
        
        function obj =      adjustWidthOfMovieAxes(obj)
            XLength =                           obj.ViewMovieAxes.XLim(2)- obj.ViewMovieAxes.XLim(1);
            YLength =                           obj.ViewMovieAxes.YLim(2)- obj.ViewMovieAxes.YLim(1);
            RelativeWidth =                     XLength/  YLength;
            obj =                               obj.setRelativeAxesWidth( RelativeWidth);

        end

        function obj =      setRelativeAxesWidth(obj, Width)
            obj.ViewMovieAxes.Position(3) =     obj.ViewMovieAxes.Position(4)  * Width;
        end

         
     end
    
        
    methods (Access = private) % GETTERS HANDLES
        
        function obj = updateGraphicHandles(obj)
            

                try
                    AllValid =     min(arrayfun(@(x) isvalid(x), obj.getListOfHandles));

                    if AllValid

                    else

                        if isvalid(obj.Figure)
                            obj = obj.initializeHandles('');
                        else
                           error('Cannot continue because parent figure is unspecfied.') 
                        end


                    end

                catch
                    warning('Could not update graphics handles.')
                end
        end
        
        function ListWithHandles = getListOfHandles(obj)
            
             ListWithHandles = [        ...
                                    obj.ViewMovieAxes; ...
                                    obj.MainImage; ...
                                    obj.Rectangle; ...
                                    obj.TimeStampText; ...
                                    obj.ZStampText; ...
                                    obj.ScalebarText; ...
                                    obj.ScaleBarLine; ...
                                    obj.ManualDriftCorrectionLine; ...
                                    obj.CentroidLine; ...
                                    obj.CentroidLineOfActiveTrack...
            ];

            
        end
        
        
    end
    
    methods (Access = private) % GETTERS DIMENSIONS
       
        function Width = getWidthOfAxes(obj, varargin)
            switch length(varargin)
                case 1
                    assert(ischar(varargin{1}), 'Wrong input.')
                    switch varargin{1}
                        case 'centimeters'
                            obj.ViewMovieAxes.Units = varargin{1};
                            Width =  obj.ViewMovieAxes.Position(3);
                        otherwise
                            error('Wrong input.')
                        
                    end
                    
             
                    
                otherwise
                    error('Wrong input.')
                
                
            end
        end
        
           function [AxesWidthCentimeter, AxesHeightCentimeter] = getAxesDimentionsInCm(obj)
             obj.ViewMovieAxes.Units =         'centimeters';
                AxesWidthCentimeter =             obj.ViewMovieAxes.Position(3);
                AxesHeightCentimeter =            obj.ViewMovieAxes.Position(4);
                obj.ViewMovieAxes.Units =         'pixels';
           end
        
        
        function xLimits =  getXLimitsOfImage(~, Value)
             assert(isscalar(Value) && isa(Value, 'PMMovieTracking'), 'Wrong input.')
            [~, columnsInImage, ~] =        Value.getImageDimensions;
            CurrentColumnShift=             Value.getAplliedColumnShiftsForActiveFrames;
            xLimits =                       [1+  CurrentColumnShift, columnsInImage + CurrentColumnShift ];
        end

        function yLimits =  getYLimitsOfImage(~, Value)
            assert(isscalar(Value) && isa(Value, 'PMMovieTracking'), 'Wrong input.')
            [rowsInImage, ~, ~] =       Value.getImageDimensions;
            CurrentRowShift =           Value.getAplliedRowShiftsForActiveFrames;
            yLimits =                   [1+  CurrentRowShift, rowsInImage + CurrentRowShift];
        end
        
        
    end
    
   
    methods (Access = private) % SETTERS ANNOTATION
       
        function obj = setHorizontalPositionsOfAnnotation(obj)
              WidtOfImage =                       obj.getWidthOfAxes('centimeters');
                
                
                
                
                obj.TimeStampText.Units =           'centimeters';
                obj.TimeStampText.Position =        [2 0.3 ];
                obj.TimeStampText.Color = 'c';

                obj.ZStampText.Units =              'centimeters';
                obj.ZStampText.Position =           [WidtOfImage / 2 0.3 ];
                obj.ZStampText.Color = 'c';

                obj.ScalebarText.Units =            'centimeters';
                obj.ScalebarText.Position =         [WidtOfImage - 2 0.3 ];
                obj.ScalebarText.Color = 'c';
            
        end
        
       
        
   
    end
    
    methods (Access = private) % SETTERS SCALEBAR
        
         function obj = setScaleBarSize(obj, LengthInMicrometer, VoxelSizeXuM)

                assert(isnumeric(LengthInMicrometer) && isscalar(LengthInMicrometer) && ...
                isnumeric(VoxelSizeXuM) && isscalar(VoxelSizeXuM), 'Wrong input.')
            
                [Left, Right] =                     obj.getXPositionsOfScaleBar(LengthInMicrometer, VoxelSizeXuM);
                YPosition_ScaleBar =                obj.getYPositionOfScaleBar;
                
                obj.ScaleBarLine.Marker =           'none';
                obj.ScaleBarLine.XData =            [Left,  Right];
                obj.ScaleBarLine.YData =            [ YPosition_ScaleBar, YPosition_ScaleBar];

                obj.ScalebarText.String =           strcat(num2str(LengthInMicrometer), ' µm');

         end
         
         function [ScalebarLeft_X_Pixels, ScalebarRight_X_Pixels] = getXPositionsOfScaleBar(obj, LengthInMicrometer, VoxelSizeXuM)
              [AxesWidth_Centimeter, ~] =          obj.getAxesDimentionsInCm;
               [TextPositionX_Cm, ~] =              obj.getScaleBarTextPositionInCm;
               
               TextPositionX_Cm = TextPositionX_Cm + 1;
               
              TextPositionX_Fraction =            TextPositionX_Cm / AxesWidth_Centimeter;
                AxesWidth_Pixels =                  diff(obj.ViewMovieAxes.XLim);
                TextPositionX_Pixels_Relative =     AxesWidth_Pixels * TextPositionX_Fraction;
                TextPositionX_Pixels_Absolute =     obj.ViewMovieAxes.XLim(1) + TextPositionX_Pixels_Relative;
                LengthInPixels =                    LengthInMicrometer / VoxelSizeXuM;
               
                ScalebarLeft_X_Pixels =             (TextPositionX_Pixels_Absolute  - LengthInPixels);
                ScalebarRight_X_Pixels =            (TextPositionX_Pixels_Absolute );
             
         end
        
       
         function YPosition_ScaleBar = getYPositionOfScaleBar(obj)
               AxesHeight_Pixels =                  diff(obj.ViewMovieAxes.YLim);
                AxesWidth_Pixels =                   diff(obj.ViewMovieAxes.XLim);
                [~, AxesHeight_Centimeter] =  obj.getAxesDimentionsInCm;
                

                if AxesWidth_Pixels > AxesHeight_Pixels
                    RealAxesHeightCentimeter = AxesHeight_Centimeter * AxesHeight_Pixels/ AxesWidth_Pixels;
                else
                    RealAxesHeightCentimeter = AxesHeight_Centimeter;
                end


                WantedCentimeters =                 0.9;
                PixelsPerCentimeter =               AxesHeight_Pixels / RealAxesHeightCentimeter;
                PixelsForWantedCentimeters =        PixelsPerCentimeter * WantedCentimeters;
                YPosition_ScaleBar =                obj.ViewMovieAxes.YLim(2) - PixelsForWantedCentimeters;

         end
        
        function midPosition = getScalebarMidPosition(obj)
            
        end
        
        
    end

    methods (Access = private) % GETTERS ANNOTATION
        
        function [TextPositionX, TextPositionY] = getScaleBarTextPositionInCm(obj)
             obj.ScalebarText.Units =          'centimeters';
                TextPositionX =          obj.ScalebarText.Position(1);
                TextPositionY =          obj.ScalebarText.Position(2);
            
        end
       
                

        
    end
end

