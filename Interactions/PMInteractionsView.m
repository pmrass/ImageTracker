classdef PMInteractionsView
    %PMINTERACTIONSVIEW view settings for interaction measurement;
    %   PlaneThresholds
    
    properties (Access = private)
        MainFigure
        
        PlaneThresholds
        ReferenceTimeFrame
        Channel
        
        MinimumSize
        MaximumDistanceToTarget
        
        ShowThresholdedImage
        
        Options
        Action
    end
    
    properties (Constant, Access = private)
       
        LeftColumnPosition =            0.05;
        LeftColumWidth =               0.3;


        RightColumnPosition     =       0.3;
        RightColumWidth =               0.68;


        
    end
    
    
    methods % initialziation
        
          function obj = PMInteractionsView(varargin)
            %PMINTERACTIONSVIEW Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
              
                otherwise
                    error('Wrong input')
                
            end
            
        end
        
        
    end
    
    methods % GETTERS
        
        
        function ok = testViewsAreSetup(obj)
            ok = ~isempty(obj.PlaneThresholds);
        end
        
         
        function Figure = getMainFigure(obj)
           Figure = obj.MainFigure; 
            
        end
        
        %% accessors
        function value = getPlaneThresholds(obj)
            assert(~isempty(obj.PlaneThresholds), 'Plane thresholds not yet set. This object still needs to be set.')
            value = obj.PlaneThresholds.Data;
        end

        function value = getReferenceTimeFrame(obj)
            value = str2double(obj.ReferenceTimeFrame.Value);
        end

        function value = getChannel(obj)
            value = str2double(obj.Channel.Value);
        end

        function value = getMinimumSize(obj)
            value = obj.MinimumSize.Value;
        end

        function value = getMaximumDistanceToTarget(obj)
            value = obj.MaximumDistanceToTarget.Value;
        end

        function value = getShowThresholdedImage(obj)
            if isempty(obj.ShowThresholdedImage)
                value = false;
            else
                value = obj.ShowThresholdedImage.Value;
            end
            
        end
        
        
        
    end
    
    methods % SETTERS
      
        function obj = setCallbacks(obj, varargin)
            if isvalid(obj.MainFigure)
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 2
                        obj.Action.ButtonPushedFcn =                    varargin{1};
                        obj.PlaneThresholds.CellEditCallback =          varargin{2};
                        obj.ReferenceTimeFrame.ValueChangedFcn =        varargin{2};
                        obj.Channel.ValueChangedFcn =                   varargin{2};
                        obj.MinimumSize.ValueChangedFcn =               varargin{2};
                        obj.MaximumDistanceToTarget.ValueChangedFcn =   varargin{2};
                        obj.ShowThresholdedImage.ValueChangedFcn =      varargin{2};


                    otherwise
                        error('Wrong input.') 
                end
                
            end 
        end
        
        function obj = setWith(obj, Value)
            Type = class(Value);
            switch Type

                case 'PMInteractionsCapture'

                    obj.PlaneThresholds.Data =              Value.getThresholdsForImageVolumes;

                    TimeValue = num2str(Value.getSourceFramesForImageVolumes);
                    if str2double(TimeValue) > length(obj.ReferenceTimeFrame.Items)
                        TimeValue = '1';
                    end
                    obj.ReferenceTimeFrame.Value =          TimeValue;

                    ChannelValue = num2str(Value.getChannelNumbersForTarget);
                    if str2double(ChannelValue) > length(obj.Channel.Items)
                        ChannelValue = '1';
                    end
                    obj.Channel.Value   =                   ChannelValue;
                    obj.MinimumSize.Value =                 Value.getMinimumSizesOfTarget;

                    obj.MaximumDistanceToTarget.Value =     Value.getMaximumDistanceToTarget;
                    obj.ShowThresholdedImage.Value =        Value.getShowThresholdedImage;

                otherwise
                    error('Wrong input.')

            end
        
        end
        
        function obj = makeVisibible(obj)
            if isempty(obj.MainFigure)
                obj = obj.initialize;
            elseif ~isvalid(obj.MainFigure)
                obj = obj.initialize;
            end
        end
        
        function obj = setMovieDependentParameters(obj, Movie)
            obj.PlaneThresholds.Data =          (linspace(10, 10, Movie.getMaxPlane))';
            obj.Channel.Items =                 arrayfun(@(x)  num2str(x), 1 : Movie.getMaxChannel, 'UniformOutput', false);
            obj.ReferenceTimeFrame.Items =      arrayfun(@(x)  num2str(x), 1 : Movie.getMaxFrame, 'UniformOutput', false);
        end
        
        function Selection = getUserSelection(obj)
            Selection = obj.Options.Value;
        end
        
    end
    
    
    
    
    methods (Access = private)
        
        function obj = initialize(obj)
            
            obj = obj.setMainFigure;

            PlaneThresholdsTitle =                      uilabel(obj.MainFigure);
            PlaneThresholdsTitle.Text =                 'PlaneThresholds:';
            PlaneThresholdsTitle.Position =             [obj.getWidth * obj.LeftColumnPosition obj.getHeight - 30  obj.getWidth * obj.LeftColumWidth 20 ];

            ReferenceTimeFrameTitle =                   uilabel(obj.MainFigure);
            ReferenceTimeFrameTitle.Text =              'Time frame of source image:';
            ReferenceTimeFrameTitle.Position =          [obj.getWidth * obj.LeftColumnPosition obj.getHeight - 200  obj.getWidth * obj.LeftColumWidth 20 ];

            ChannelTitle =                              uilabel(obj.MainFigure);
            ChannelTitle.Text =                         'Used channel:';
            ChannelTitle.Position =                     [obj.getWidth * obj.LeftColumnPosition obj.getHeight - 230  obj.getWidth * obj.LeftColumWidth 20 ];

            MinimumSizeTitle =                          uilabel(obj.MainFigure);
            MinimumSizeTitle.Text =                     'Minimum size of structure:';
            MinimumSizeTitle.Position =                 [obj.getWidth * obj.LeftColumnPosition obj.getHeight - 260  obj.getWidth * obj.LeftColumWidth 20 ];

            MaximumDistanceToTargetTitle =              uilabel(obj.MainFigure);
            MaximumDistanceToTargetTitle.Text =         'Maximum analyzed distance:';
            MaximumDistanceToTargetTitle.Position =     [obj.getWidth * obj.LeftColumnPosition obj.getHeight - 290  obj.getWidth * obj.LeftColumWidth 20 ];

            ShowThresholdedImageTitle =                  uilabel(obj.MainFigure);
            ShowThresholdedImageTitle.Text =              'Show thresholded images';
            ShowThresholdedImageTitle.Position =          [obj.getWidth * obj.LeftColumnPosition obj.getHeight - 320  obj.getWidth * obj.LeftColumWidth 20 ];

            obj.PlaneThresholds =                       uitable(obj.MainFigure);
            obj.PlaneThresholds.Position =              [obj.getWidth * obj.RightColumnPosition obj.getHeight - 180  obj.getWidth * obj.LeftColumWidth 170 ];
            obj.PlaneThresholds.ColumnEditable =        true;   


            obj.ReferenceTimeFrame =                    uidropdown(obj.MainFigure);
            obj.ReferenceTimeFrame.Position =           [obj.getWidth * obj.RightColumnPosition obj.getHeight - 200  obj.getWidth * obj.LeftColumWidth 20 ];

            obj.Channel =                               uidropdown(obj.MainFigure);
            obj.Channel.Position =                      [obj.getWidth * obj.RightColumnPosition obj.getHeight - 230  obj.getWidth * obj.LeftColumWidth 20 ];

            obj.MinimumSize =                           uieditfield(obj.MainFigure,'numeric');
            obj.MinimumSize.Position =                  [obj.getWidth * obj.RightColumnPosition obj.getHeight - 260  obj.getWidth * obj.LeftColumWidth 20 ];

            obj.MaximumDistanceToTarget =               uieditfield(obj.MainFigure,'numeric');
            obj.MaximumDistanceToTarget.Position =      [obj.getWidth * obj.RightColumnPosition obj.getHeight - 290  obj.getWidth * obj.LeftColumWidth 20 ];

            obj.ShowThresholdedImage =                  uicheckbox(obj.MainFigure);
            obj.ShowThresholdedImage.Position =         [obj.getWidth * obj.RightColumnPosition obj.getHeight - 320  obj.getWidth * obj.LeftColumWidth 20 ];

            obj.Options =                               uidropdown(obj.MainFigure);
            obj.Options.Position =                      [obj.getWidth * obj.RightColumnPosition obj.getHeight - 350  obj.getWidth * obj.LeftColumWidth 20 ];
            obj.Options.Items =                         { 'Write raw analysis to file', 'Write interaction map into file'};

            obj.Action =                                uibutton(obj.MainFigure);
            obj.Action.Text =                           'Action';
            obj.Action.Position =                       [obj.getWidth * obj.RightColumnPosition obj.getHeight - 380  obj.getWidth * obj.LeftColumWidth 20 ];

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
                left =                    ScreenSize(3)  * 0.5;
              
        end
        
        
    end
    
end

