classdef PMSegmentationCaptureView
    %PMSEGMENTATIONCAPTUREVIEW view and edit settings of PMSegmentation object;
    %   view, edit and retrieve settings for PMSegmentation object
    
    properties (Access = private)
        MainFigure

        MaximumDisplacement
        %PlaneNumberAboveAndBelow

        NumberOfPixelsForBackground 
        BoostBackgroundFactor
        DifferenceLimitFactor
        PixelShiftForEdgeDetection

        FactorForThreshold

        WidenMaskAfterDetectionByPixels
        MinimumCellRadius
        MaximumCellRadius
        
        ShowSegmentationProgress
        
    end
    
    properties (Access = private) % positions
       
        LeftColumnPosition =            0.05;
        LeftColumWidth =                0.45;

        RightColumnPosition     =       0.5;
        RightColumWidth =               0.45;
        
        TopPositionCropping  =          0.95;
        TopPositionEdgeDetection =      0.85;
        TopPositionThreshold =          0.6;
        TopPositionPostDetection =      0.4;
        TopPositionShowProgress =       0.2;

        HeightOfPanels  =               20;
        ShiftBetweenRows =              30;
        
    end
    
    methods
        
        function obj =          PMSegmentationCaptureView(varargin)
            %PMSEGMENTATIONCAPTUREVIEW Construct an instance of this class
             %   takes 0 arguments;
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
              
                otherwise
                    error('Wrong input')
                
            end
        end
        
        function obj =          setCallbacks(obj, varargin)
            % SETCALLBACKS takes 1 argument that sets all callback actions;
            % 1: typically method that uses the view to reset a relevant PMSegmentationCaptureObject;
           
            switch length(varargin)
               
                case 1
                    
                    obj.MaximumDisplacement.ValueChangedFcn =               varargin{1};
                    obj.NumberOfPixelsForBackground.ValueChangedFcn =       varargin{1};
                    obj.BoostBackgroundFactor.ValueChangedFcn =             varargin{1};
                    obj.DifferenceLimitFactor.ValueChangedFcn =             varargin{1};
                    obj.PixelShiftForEdgeDetection.ValueChangedFcn =        varargin{1};
                    obj.FactorForThreshold.ValueChangedFcn =                varargin{1};
                    obj.MinimumCellRadius.ValueChangedFcn =                 varargin{1};
                    obj.MaximumCellRadius.ValueChangedFcn =                 varargin{1};
                    obj.WidenMaskAfterDetectionByPixels.ValueChangedFcn =   varargin{1};
                    obj.ShowSegmentationProgress.ValueChangedFcn =          varargin{1};
  
                    
                otherwise
                    error('Wrong input.')
                
            end
            
            
        end
        
         function obj =          show(obj)
             % SHOW show figure
            if isempty(obj.MainFigure) || ~isvalid(obj.MainFigure)
                obj = obj.initialize;
            end
         end
        
         function obj =         set(obj, varargin)
             % SET
             % takes 1 arugment:
             % 1: PMSegmentationCapture object: view properties will be reset by SegmentationCapture object;
             
             if ~isempty(obj.MaximumDisplacement) && ~isstruct(obj.MaximumDisplacement) && isvalid(obj.MaximumDisplacement)
                 
                 switch length(varargin)
                
                 case 1
                     
                     switch class(varargin{1})
                        
                         case 'PMSegmentationCapture'
                             
                            obj.MaximumDisplacement.Value =                 varargin{1}.getMaximumDisplacement;

                            obj.NumberOfPixelsForBackground.Value =         varargin{1}.getNumberOfPixelsForBackground;

                            obj.BoostBackgroundFactor.Value =               varargin{1}.getBoostBackgroundFactor;

                            obj.DifferenceLimitFactor.Value =               varargin{1}.getDifferenceLimitFactor;

                            obj.PixelShiftForEdgeDetection.Value =          varargin{1}.getPixelShiftForEdgeDetection;

                            obj.FactorForThreshold.Value =                  varargin{1}.getFactorForThreshold;

                            obj.MinimumCellRadius.Value =                   varargin{1}.getMinimumCellRadius;

                            obj.MaximumCellRadius.Value =                   varargin{1}.getMaximumCellRadius;

                            obj.WidenMaskAfterDetectionByPixels.Value =     varargin{1}.getWidenMaskAfterDetectionByPixels;

                            obj.ShowSegmentationProgress.Value =            varargin{1}.getShowSegmentationProgress;
           
                             
                         otherwise
                             error('Wrong input.')
                         
                         
                         
                     end
                     
                     
                 otherwise
                     error('Wrong input.')
                 
                 
             end
                 
                 
             end
             
             
             
             
         end
         
    end
    
    methods % GETTERS
        
        function Value = getMaximumDisplacement(obj)
           Value = obj.MaximumDisplacement.Value;
        end
        
        function Value = getNumberOfPixelsForBackground(obj)
           Value = obj.NumberOfPixelsForBackground.Value;
        end
        
        function Value = getBoostBackgroundFactor(obj)
           Value = obj.BoostBackgroundFactor.Value;
        end
        
        function Value = getDifferenceLimitFactor(obj)
           Value = obj.DifferenceLimitFactor.Value;
        end
        
        function Value = getPixelShiftForEdgeDetection(obj)
           Value = obj.PixelShiftForEdgeDetection.Value;
        end
        
         function Value = getFactorForThreshold(obj)
           Value = obj.FactorForThreshold.Value;
        end
        
        function Value = getWidenMaskAfterDetectionByPixels(obj)
           Value = obj.WidenMaskAfterDetectionByPixels.Value;
        end
        
        function Value = getMinimumCellRadius(obj)
           Value = obj.MinimumCellRadius.Value;
        end
        
        function Value = getMaximumCellRadius(obj)
           Value = obj.MaximumCellRadius.Value;
        end
        
        function Value = getShowSegmentationProgress(obj)
           Value = obj.ShowSegmentationProgress.Value;
        end
         
    end
    
    
    methods (Access = private) % INITIALIZE VIEWS
        
        function obj = initialize(obj)
            
            obj =   obj.setMainFigure;
            
            obj =   obj.initializeCropHandles;
            obj =   obj.initializeEdgeDetectionHandles;
            obj =   obj.initilaizeThresholdHandles;
            obj =   obj.initializePostDetectionHandles;
            obj =   obj.initializeViewHandles;

        end
        
        function obj = initializeCropHandles(obj)
            
            StartPosition =                         obj.getHeight * obj.TopPositionCropping;
            
            Title =                                 uilabel(obj.MainFigure);
            Title.Text =                            'Cropping settings:';
            Title.Position =                        [obj.getWidth * obj.LeftColumnPosition StartPosition obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            MaximumDisplacementTitle =              uilabel(obj.MainFigure);
            MaximumDisplacementTitle.Text =         'Maximum displacement (half size of cropping rectangle):';
            MaximumDisplacementTitle.Position =     [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            obj.MaximumDisplacement =               uieditfield(obj.MainFigure,'numeric');
            obj.MaximumDisplacement.Position =      [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
          
       
            
            
        end
        
        function obj = initializeEdgeDetectionHandles(obj)
            
            StartPosition =     obj.getHeight * obj.TopPositionEdgeDetection;
            
            Title =                                 uilabel(obj.MainFigure);
            Title.Text =                            'Edge detection settings: (for autotracking only)';
            Title.Position =                        [obj.getWidth * obj.LeftColumnPosition StartPosition obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];
 
            NumberOfPixelsForBackgroundTitle =          uilabel(obj.MainFigure);
            NumberOfPixelsForBackgroundTitle.Text =     'Number of pixels at periphery for "background" intensity variation:';
            NumberOfPixelsForBackgroundTitle.Position = [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            BoostBackgroundFactorTitle =                uilabel(obj.MainFigure);
            BoostBackgroundFactorTitle.Text =           'Factor for boosting background (leave at 1):';
            BoostBackgroundFactorTitle.Position =       [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows * 2  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            DifferenceLimitFactorTitle =                uilabel(obj.MainFigure);
            DifferenceLimitFactorTitle.Text =           'Factor by which edges must exceed background intensity differences:';
            DifferenceLimitFactorTitle.Position =       [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows * 3  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            PixelShiftForEdgeDetectionTitle =           uilabel(obj.MainFigure);
            PixelShiftForEdgeDetectionTitle.Text =      'Pixel shift (higher values will lead to more aggeressive segmentation):';
            PixelShiftForEdgeDetectionTitle.Position =  [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows * 4  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            obj.NumberOfPixelsForBackground =           uieditfield(obj.MainFigure,'numeric');
            obj.NumberOfPixelsForBackground.Position =  [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            obj.BoostBackgroundFactor =                 uieditfield(obj.MainFigure,'numeric');
            obj.BoostBackgroundFactor.Position =        [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows * 2  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            obj.DifferenceLimitFactor =                 uieditfield(obj.MainFigure,'numeric');
            obj.DifferenceLimitFactor.Position =        [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows * 3 obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            obj.PixelShiftForEdgeDetection =            uieditfield(obj.MainFigure,'numeric');
            obj.PixelShiftForEdgeDetection.Position =   [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows * 4  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
            
 

    
        
            
        end
        
        function obj = initilaizeThresholdHandles(obj)
            
            StartPosition =                             obj.getHeight * obj.TopPositionThreshold;


            Title =                                     uilabel(obj.MainFigure);
            Title.Text =                                'Threshold settings: (for autotracking only)';
            Title.Position =                            [obj.getWidth * obj.LeftColumnPosition StartPosition obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];


            FactorForThresholdTitle =                   uilabel(obj.MainFigure);
            FactorForThresholdTitle.Text =              'Multiply threshold after autodetection (1: no change)';
            FactorForThresholdTitle.Position =          [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels  ];

            obj.FactorForThreshold =                    uieditfield(obj.MainFigure,'numeric');
            obj.FactorForThreshold.Position =           [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];


              
   
            
        end
        
        function obj = initializePostDetectionHandles(obj)
            
             StartPosition =                             obj.getHeight * obj.TopPositionPostDetection;
            
            Title =                                     uilabel(obj.MainFigure);
            Title.Text =                                'Mask processing post-capture: (for autotracking only)';
            Title.Position =                            [obj.getWidth * obj.LeftColumnPosition StartPosition obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
             WidenMaskAfterDetectionByPixelsTitle =                  uilabel(obj.MainFigure);
            WidenMaskAfterDetectionByPixelsTitle.Text =              'Widen mask by x pixels';
            WidenMaskAfterDetectionByPixelsTitle.Position =          [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];
            
             MinimumCellRadiusTitle =                  uilabel(obj.MainFigure);
            MinimumCellRadiusTitle.Text =              'Delete mask if radius below:';
            MinimumCellRadiusTitle.Position =          [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows * 2  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
             MaximumCellRadiusTitle =                  uilabel(obj.MainFigure);
            MaximumCellRadiusTitle.Text =              'Delete mask if radius above:';
            MaximumCellRadiusTitle.Position =          [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows * 3  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

             obj.WidenMaskAfterDetectionByPixels =                    uieditfield(obj.MainFigure,'numeric');
            obj.WidenMaskAfterDetectionByPixels.Position =           [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

             obj.MinimumCellRadius =                    uieditfield(obj.MainFigure,'numeric');
            obj.MinimumCellRadius.Position =           [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows * 2  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
             obj.MaximumCellRadius =                    uieditfield(obj.MainFigure,'numeric');
            obj.MaximumCellRadius.Position =           [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows * 3  obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            

        
        % ShowSegmentationProgress
             
        end
        
        function obj = initializeViewHandles(obj)
            
              
             StartPosition =                             obj.getHeight * obj.TopPositionShowProgress;
            
            Title =                                     uilabel(obj.MainFigure);
            Title.Text =                                'Graphical depiction of segmentation process (turn off for high speed):';
            Title.Position =                            [obj.getWidth * obj.LeftColumnPosition StartPosition obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
            ShowSegmentationProgressTitle =                  uilabel(obj.MainFigure);
            ShowSegmentationProgressTitle.Text =              'Show thresholded images';
            ShowSegmentationProgressTitle.Position =          [obj.getWidth * obj.LeftColumnPosition StartPosition - obj.ShiftBetweenRows   obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

            
          
            obj.ShowSegmentationProgress =                  uicheckbox(obj.MainFigure);
            obj.ShowSegmentationProgress.Position =         [obj.getWidth * obj.RightColumnPosition StartPosition - obj.ShiftBetweenRows   obj.getWidth * obj.LeftColumWidth obj.HeightOfPanels ];

           
            
        end
        
        
        
        function obj = setMainFigure(obj)
                fig =                     uifigure;
                fig.Position =            [obj.getLeft 0 obj.getWidth obj.getHeight];
                obj.MainFigure =          fig;

        end
        
        function width = getWidth(~)
             ScreenSize =              get(0,'screensize');
             width =                   ScreenSize(3) * 0.45;   
        end
        
        function height = getHeight(~)
                ScreenSize =              get(0,'screensize');
                height =                  ScreenSize(4) * 0.8;
        end
        
        function left = getLeft(~)
              ScreenSize =              get(0,'screensize');
                left =                  ScreenSize(3)  * 0.5;
              
        end
        
        
    end
    
    
end

