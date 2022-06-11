classdef PMAutoCellRecognitionView < PMFigure
    %PMMOVIETRACKINGSETTINGS View for displaying and editing properties of PMAutoCellRecognition;
    % used by PMAutoCellRecognitionController to communicate with PMAutoCellRecognition;
    
    properties (Access = private)
        
        ListWithChannels
        ListWithFrames
        ListWithPlaneSettings
        
        FilterForHighDensityDistance
        FilterForHighDensityNumber
        
        FilterForOverLapExclusion
        FilterForOverLapDistance
        
        ProcedureSelection
        StartButton
        
    end
    
    properties (Access = private, Constant)
        
        RowPositionForChannels =    0.7
        HeightForChannels =         0.27

        RowPositionForFrames =      0.15
        HeightForFrames =           0.5

        RowPositionForDoubleTracking = 0.93
        
        RowPositionForFilterOut =       0.79
        
        RowPositionForCircleSettings =  0.15
        HeightForCircleSettings =       0.5


        FirstColumnPosition = 0.03
        SecondColumnPosition = 0.3
        
       
 
        
    end
    
    methods % initialize
        
          function obj = PMAutoCellRecognitionView(varargin)
                %PMMOVIETRACKINGSETTINGS Construct an instance of this class
                %   Takes 0 arguments; automatically creates new view;
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 0

                    otherwise
                        error('Wrong input.')

                end
          end
          
          function obj = set.ListWithChannels(obj, Value)
             assert(~isempty(Value), 'Wrong input.')
             obj.ListWithChannels = Value; 
          end
          
          
        
        
    end
    
    methods % GETTERS
        
        function value = getListWithChannels(obj)
            value  = obj.ListWithChannels;
        end
        
        function value = getListWithFrames(obj)
            value  = obj.ListWithFrames;
        end
        
        function value = getFilterForHighDensityDistance(obj)
            value = str2double(obj.FilterForHighDensityDistance.Value);
        end
        
        function value = getFilterForHighDensityNumber(obj)
            value = str2double(obj.FilterForHighDensityNumber.Value);
        end
        
        
        function value = getOverlapExclusionSelection(obj)
           % GETOVERLAPEXCLUSIONSELECTION returns whether detected cells should be excluded when distance to next neighbor is too small;
           value = obj.FilterForOverLapExclusion.Value; 
        end
        
        function value = getOverlapExclusionDistance(obj)
            % GETOVERLAPEXCLUSIONDISTANCE returns specified distance for overlap-exclusion;
            value = str2double(obj.FilterForOverLapDistance.Value); 
        end
        
   
        
        
        
    end
    
    methods % INITIALIZATION
        
         function obj =          show(obj)
            
            obj =        obj.showFigure;
            if obj.figureIsBlank
                obj =       obj.updateHandles;
                obj =       obj.setFigureIsBlank(false);
            end
            
          end

         function obj =          setCallBacks(obj, varargin)

        NumberOfArguments = length(varargin);
        switch NumberOfArguments
            case 5

                if obj.figureIsActive

                    obj.ListWithChannels.CellSelectionCallback =        varargin{1};
                    obj.ListWithFrames.CellSelectionCallback =          varargin{2};
                    obj.ListWithPlaneSettings.DisplayDataChangedFcn =   varargin{3};
                   
                    obj.FilterForHighDensityDistance.ValueChangedFcn  =    varargin{4};
                    obj.FilterForHighDensityNumber.ValueChangedFcn  =    varargin{4}; 
                    obj.FilterForOverLapExclusion.ValueChangedFcn  =    varargin{4};
                    obj.FilterForOverLapDistance.ValueChangedFcn =      varargin{4};
                    
                     obj.StartButton.ButtonPushedFcn =                   varargin{5};

                end


            otherwise
                error('Wrong input.')

        end

         end

    end
    
    methods % GETTERS
        
        function Value =        getListWithPlaneSettings(obj)
           Value = obj.ListWithPlaneSettings.Data; 
        end
        
        function selection =    getUserSelection(obj)
            selection = obj.ProcedureSelection.Value;
        end
     
        
    end
    
    methods % SETTERS GENERAL
        
        function obj =          setFrames(obj, Value)
            assert(~isempty(obj.ListWithFrames), 'Handles not set.')
            obj.ListWithFrames.Data =         Value;     
           
        end
        
        function obj =          setChannels(obj, Value)
            assert(obj.figureIsActive, 'Wrong input.')
            obj.ListWithChannels.Data =                       Value;    
        end
        
    end
    
    methods % SETTERS INTENSITY RECOGNITION
        
         function obj =          setDoubleTracking(obj, Value)
            assert(~isempty(obj.ListWithFrames), 'Handles not set.')
            obj.FilterForOverLapExclusion.Value =         Value;     
           
         end
        
         function obj =          setDoubleTrackingDistance(obj, Value)
            assert(~isempty(obj.ListWithFrames), 'Handles not set.')
            obj.FilterForOverLapDistance.Value =         Value;     
           
        end
         
    end
    
    methods % SETTERS CRICLE RECOGNITION
        
        function obj =          setPlaneSettings(obj, Value)
            assert(~isempty(obj.ListWithPlaneSettings), 'Handles not set.')
             obj.ListWithPlaneSettings.Data =          Value;
             number = size(Value, 1);
             Title = arrayfun(@(x) ['Plane ', num2str(x)], (1:number)', 'UniformOutput', false);
              obj.ListWithPlaneSettings.RowName = Title;
              
              obj.ListWithPlaneSettings.Data =          Value;
              obj.ListWithPlaneSettings.ColumnEditable = true;
              
        end
         
        function obj =          setHighDensityDistances(obj, Value)
            assert(~isempty(obj.FilterForHighDensityDistance), 'Handles not set.')
            obj.FilterForHighDensityDistance.Value =       Value; 
        end
        
        function obj =          setHighDensityNumbers(obj, Value)
            assert(~isempty(obj.FilterForHighDensityNumber), 'Handles not set.')
            obj.FilterForHighDensityNumber.Value =        Value;
        end
           
    end
    
    methods (Access = private)
        
        function obj =          updateHandles(obj)

            obj =       obj.setPosition(obj.getFigurePosition);            
         
            obj =       obj.setFramePanels;
            obj =       obj.setPlanePanels;
            obj =       obj.setChannelPanels;
         
            obj =       obj.setHighDensityPanels;
            obj =       setDoubleTrackingPanels(obj);
            
            obj =       obj.setActionPanels;
            
            
             
        end
        
        function Position =     getFigurePosition(obj)
            ScreenSize =                                get(0,'screensize');
            Height =                                    ScreenSize(4) * 0.7;
            Left =                                      ScreenSize(3) * 0.4;
            Width =                                     ScreenSize(3) * 0.45;
            Bottom =                                    ScreenSize(4) * 0.15;
            
            Position =                                  [Left Bottom Width Height];
        end
        
    end
    
    methods (Access = private) % SETTERS AUTORECOGNITION GENERAL
        
        function obj =          setChannelPanels(obj)
            
            RowPosition =   obj.getFigureHeight * obj.RowPositionForChannels;
            
            obj.ListWithChannels =                              uitable(obj.getFigureHandle);
            obj.ListWithChannels.Position =                    [obj.getFigureWidth * obj.FirstColumnPosition RowPosition  obj.getFigureWidth * 0.2 obj.getFigureHeight * obj.HeightForChannels ];
            obj.ListWithChannels.RowName =                     '';
            obj.ListWithChannels.ColumnName =                  'Channels';
            
            
          
        
        end
        
        function obj =          setFramePanels(obj)
            obj.ListWithFrames =        uitable(obj.getFigureHandle);
            RowPosition =               obj.getFigureHeight * obj.RowPositionForFrames;
            
            
            % obj.ListWithFrames.Value =                        'New sample';
            obj.ListWithFrames.Position =                       [obj.getFigureWidth * obj.FirstColumnPosition RowPosition obj.getFigureWidth * 0.2 obj.getFigureHeight * obj.HeightForFrames ];
            obj.ListWithFrames.ColumnName =                     {'Available frames'};

        end
        
        function obj =          setActionPanels(obj)
            
    
            obj.ProcedureSelection  =               uidropdown(obj.getFigureHandle);
            obj.ProcedureSelection.Position =       [obj.getFigureWidth * obj.SecondColumnPosition 50  obj.getFigureWidth * 0.4 20 ];
            obj.ProcedureSelection.Items =          { 'Intensity recognition', 'Circle recognition', 'Interpolate plane settings'};
            obj.ProcedureSelection.Value =          'Intensity recognition';

            obj.StartButton =                       uibutton(obj.getFigureHandle);
            obj.StartButton.Position =              [obj.getFigureWidth * obj.SecondColumnPosition 20  obj.getFigureWidth * 0.4 20 ];
            obj.StartButton.Text =                  'Start';
         
            
            
         end
       
        
    end
    
    methods (Access = private) % SETTERS CIRCLE RECOGNITION
        
        function obj =          setHighDensityPanels(obj)
            
            RowPosition =               obj.getFigureHeight * obj.RowPositionForFilterOut;
            DistanceBetweenRows =                               25;

            ColumnWidth =                                       obj.getFigureWidth * 0.25;

            ColumnPosition =                                    obj.getFigureWidth * obj.SecondColumnPosition;

            CircleDetection =                                   uilabel(obj.getFigureHandle);
            CircleDetection.Position =                          [ColumnPosition RowPosition  ColumnWidth 20 ]; 
            CircleDetection.Text =                              'Circle recognition:';
            CircleDetection.FontWeight =                        'bold';
            
            FilterForHighDensityTitle =                         uilabel(obj.getFigureHandle);
            FilterForHighDensityTitle.Position =                [ColumnPosition RowPosition - DistanceBetweenRows  ColumnWidth 20 ]; 
            FilterForHighDensityTitle.Text =                    'Filter out cells';
            
            
            FilterForHighDensityNumberTitle =                   uilabel(obj.getFigureHandle);
            FilterForHighDensityNumberTitle.Position =          [ColumnPosition RowPosition - DistanceBetweenRows * 2   ColumnWidth 20 ];   
            FilterForHighDensityNumberTitle.Text =              'when cell number exceeds';

            obj.FilterForHighDensityNumber =                    uieditfield(obj.getFigureHandle);
            obj.FilterForHighDensityNumber.Position =           [ColumnPosition RowPosition - DistanceBetweenRows * 3 ColumnWidth 20 ];  
            
            
            FilterForHighDensityDistanceTitle =                 uilabel(obj.getFigureHandle);
            FilterForHighDensityDistanceTitle.Position =        [ColumnPosition + ColumnWidth + 10  RowPosition - DistanceBetweenRows * 2 ColumnWidth 20 ];   
            FilterForHighDensityDistanceTitle.Text =            'with a radius of';
            
            obj.FilterForHighDensityDistance =                  uieditfield(obj.getFigureHandle);
            obj.FilterForHighDensityDistance.Position =         [ColumnPosition + ColumnWidth + 10  RowPosition - DistanceBetweenRows * 3  ColumnWidth 20 ];    

 

        end
        
        function obj =          setPlanePanels(obj)
            
                         RowPosition =               obj.getFigureHeight * obj.RowPositionForCircleSettings;
            

            obj.ListWithPlaneSettings =                         uitable(obj.getFigureHandle);
            obj.ListWithPlaneSettings.Position =                [obj.getFigureWidth * obj.SecondColumnPosition, RowPosition, obj.getFigureWidth * 0.6, obj.getFigureHeight * obj.HeightForCircleSettings  ];
            obj.ListWithPlaneSettings.ColumnName =              {'Minimum radius', 'Maximum radius', 'Sensitivity', 'EdgeThreshold'};

        end   
     
        
        
        
    end
    
    methods (Access = private) % SETTERS INTENSITY RECOGNITION
        
         
        function obj =          setDoubleTrackingPanels(obj)
        
            RowPosition =                               obj.getFigureHeight * obj.RowPositionForDoubleTracking;
            DistanceBetweenRows =                       30;
            ColumnWidth =                               obj.getFigureWidth * obj.SecondColumnPosition;

            ColumnPosition =                            obj.getFigureWidth * obj.SecondColumnPosition;

            FilterForOverlapTitle =                     uilabel(obj.getFigureHandle);
            FilterForOverlapTitle.Position =            [ColumnPosition RowPosition  ColumnWidth 20 ]; 
            FilterForOverlapTitle.Text =                'Intensity recognition:';
            FilterForOverlapTitle.FontWeight =          'bold';

            obj.FilterForOverLapExclusion =             uicheckbox(obj.getFigureHandle);
            obj.FilterForOverLapExclusion.Position =    [ColumnPosition RowPosition - DistanceBetweenRows ColumnWidth * 1.5 20 ];   
            obj.FilterForOverLapExclusion.Text =        'Remove cells when within x pixels of previously tracked cells:';

            obj.FilterForOverLapDistance =              uieditfield(obj.getFigureHandle);
            obj.FilterForOverLapDistance.Position =     [ColumnPosition + ColumnWidth * 1.5 + 10 RowPosition - DistanceBetweenRows  ColumnWidth * 0.5 20 ];  
              
        end
          
        
        
    end
    
    
    
    
    
    
end

