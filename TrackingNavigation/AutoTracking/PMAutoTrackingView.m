classdef PMAutoTrackingView
    %PMAUTOTRACKINGVIEW view for viewing and editing PMAutoTracking settings;
    %   change settings such as maximum tracking distances etc.
    
    properties (Access = private)
        
        MainFigure
        
        MaximumAcceptedDistanceForAutoTracking
        FirstPassDeletionFrameNumber
        AutoTrackingConnectionGaps  
        DistanceLimitXYForTrackMerging
        DistanceLimitZForTrackingMerging % all tracks that show some overlap are accepted; positive values extend overlap
        ShowDetailedMergeInformation
        
        ProcedureSelection
        
        StartButton
        
    end
    
  
    
    methods
        
        function obj = PMAutoTrackingView(varargin)
            %PMAUTOTRACKINGVIEW Construct an instance of this class
            %   takes 0 arguments:
             InputArguments =                            length(varargin);
                switch InputArguments
                
                case 0
                    obj = obj.setMainFigure;
                    obj = obj.setPanels;
                otherwise
                        error('Wrong input.') 
                end
            
        end
 
    end
    
    methods % SETTERS
    
        function obj = show(obj)
            assert(~isempty(obj.MainFigure), 'Can only show when figure exists.')
            figure(obj.MainFigure)
        end
        
        function obj = setCallbacks(obj, varargin)
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 7
                    obj.MaximumAcceptedDistanceForAutoTracking.ValueChangedFcn =    varargin{1};  
                    obj.FirstPassDeletionFrameNumber.ValueChangedFcn =              varargin{2};  
                    obj.AutoTrackingConnectionGaps.ValueChangedFcn =                varargin{3};  
                    obj.DistanceLimitXYForTrackMerging.ValueChangedFcn =            varargin{4};  
                    obj.DistanceLimitZForTrackingMerging.ValueChangedFcn =          varargin{5};  
                    obj.ShowDetailedMergeInformation.ValueChangedFcn =              varargin{6};  
                    obj.StartButton.ButtonPushedFcn =                               varargin{7};  

                otherwise
                    error('Wrong number of input arguments.')
                
            end
            
            
        end
        
        function obj = set(obj, varargin)
            % SET set states of view properties
            % takes 1 argument:
            % 1: scalar of PMAutoTracking
            
            switch length(varargin)
               
                case 1
                    
                    Model = varargin{1};
                    assert(isscalar(Model), 'Wrong input.')

                    switch class(Model)

                        case 'PMAutoTracking'
                            
                            obj.MaximumAcceptedDistanceForAutoTracking.Value =           num2str(Model.getMaximumAcceptedDistanceForAutoTracking);
                            obj.FirstPassDeletionFrameNumber.Value =                     num2str(Model.getFirstPassDeletionFrameNumber);
                            obj.AutoTrackingConnectionGaps.Value =                       num2str(Model.getAutoTrackingConnectionGaps);

                            obj.DistanceLimitXYForTrackMerging.Value =                   num2str(Model.getDistanceLimitXYForTrackMerging);
                            obj.DistanceLimitZForTrackingMerging.Value =                 num2str(Model.getDistanceLimitZForTrackingMerging);
                            obj.ShowDetailedMergeInformation.Value =                     Model.getShowDetailedMergeInformation;

                        
                        otherwise
                            error('Wrong input.')
                        
                        
                    end
                    
                otherwise
                    error('Wrong input.')
 
            end
              
        end
        
    end
    
    methods % GETTERS
        
        function Procedure = getSelectedProcedure(obj)
                 Procedure = obj.ProcedureSelection.Value;
        end
        
        function FigureHandle = getFigureHandle(obj)
              FigureHandle = obj.MainFigure;
        end
        
         function value = getMaximumAcceptedDistanceForAutoTracking(obj)
            value = str2double(obj.MaximumAcceptedDistanceForAutoTracking.Value);
        end

        function value = getFirstPassDeletionFrameNumber(obj)
            value = str2double(obj.FirstPassDeletionFrameNumber.Value);
        end
        
        function value = getAutoTrackingConnectionGaps(obj)
            value = str2double(strsplit(obj.AutoTrackingConnectionGaps.Value));
        end
        
        function value = getDistanceLimitXYForTrackMerging(obj)
            value = str2double(obj.DistanceLimitXYForTrackMerging.Value);
        end
        
        function value = getDistanceLimitZForTrackingMerging(obj)
            value =  str2double(obj.DistanceLimitZForTrackingMerging.Value);
        end
        
        function value = getShowDetailedMergeInformation(obj)
            value = obj.ShowDetailedMergeInformation.Value;
        end
        
        
    end
    
    
    methods (Access = private)
        
        function obj = setMainFigure(obj)            
            fig =                                                       uifigure;
            ScreenSize =                                                get(0, 'screensize');
            Left =                                                      ScreenSize(3)*0.6;
            fig.Position =                                              [Left 0 obj.getWidth obj.getHeight];
            obj.MainFigure =                                            fig;
         
        end
        
        function Width = getWidth(obj)
            ScreenSize =                                                get(0, 'screensize');
            Width =          ScreenSize(3)*0.3;  
        end
        
        function Height = getHeight(obj)
            ScreenSize =                                                get(0, 'screensize');
            Height =         ScreenSize(4)*0.8;
        end
        
        function obj =  setPanels(obj)
            
            
            MaximumAcceptedDistanceForAutoTrackingTitle =           uilabel(obj.MainFigure);
            MaximumAcceptedDistanceForAutoTrackingTitle.Position =                [obj.getWidth*0.05 obj.getHeight - 30  obj.getWidth*0.7 20 ];
            MaximumAcceptedDistanceForAutoTrackingTitle.Text =                  'Maximum distance for auto-tracking:';


            obj.MaximumAcceptedDistanceForAutoTracking =            uieditfield(obj.MainFigure);
            obj.MaximumAcceptedDistanceForAutoTracking.Position =   [obj.getWidth*0.79 obj.getHeight - 30  obj.getWidth*0.2 20 ];


             FirstPassDeletionFrameNumberTitle =                     uilabel(obj.MainFigure);
             FirstPassDeletionFrameNumberTitle.Position =            [obj.getWidth*0.05 obj.getHeight - 90  obj.getWidth*0.7 20 ];
             FirstPassDeletionFrameNumberTitle.Text =                'Delete all tracks with x or less frames:';
             
             obj.FirstPassDeletionFrameNumber =                        uieditfield(obj.MainFigure);
             obj.FirstPassDeletionFrameNumber.Position =                          [obj.getWidth*0.79 obj.getHeight - 90  obj.getWidth*0.2 20 ];
           
              
            AutoTrackingConnectionGapsTitle =                         uilabel(obj.MainFigure);
            AutoTrackingConnectionGapsTitle.Text =                              'Gap frame numbers for connnecting tracks:';
            AutoTrackingConnectionGapsTitle.Position =                            [obj.getWidth*0.05 obj.getHeight - 150  obj.getWidth*0.7 20 ];
            
            obj.AutoTrackingConnectionGaps =                          uieditfield(obj.MainFigure);
            obj.AutoTrackingConnectionGaps.Position =                            [obj.getWidth*0.79 obj.getHeight - 150  obj.getWidth*0.2 20 ];
            
            DistanceLimitXYForTrackMergingTitle =                     uilabel(obj.MainFigure);
            DistanceLimitXYForTrackMergingTitle.Position =                        [obj.getWidth*0.05 obj.getHeight - 180  obj.getWidth*0.7 20 ];
            DistanceLimitXYForTrackMergingTitle.Text =                          'Maximum XY-distance for track merging:';
          
            obj.DistanceLimitXYForTrackMerging =                        uieditfield(obj.MainFigure);
            obj.DistanceLimitXYForTrackMerging.Position =                        [obj.getWidth*0.79 obj.getHeight - 180  obj.getWidth*0.2 20 ];
             
            DistanceLimitZForTrackingMergingTitle =                   uilabel(obj.MainFigure);
            DistanceLimitZForTrackingMergingTitle.Position =                      [obj.getWidth*0.05 obj.getHeight - 210  obj.getWidth*0.7 20 ];
            DistanceLimitZForTrackingMergingTitle.Text =                        'Maximum Z-distance for track merging:';
           
            obj.DistanceLimitZForTrackingMerging =                      uieditfield(obj.MainFigure);
            obj.DistanceLimitZForTrackingMerging.Position =                      [obj.getWidth*0.79 obj.getHeight - 210  obj.getWidth*0.2 20 ];
            
            ShowDetailedMergeInformationTitle =                       uilabel(obj.MainFigure);
            ShowDetailedMergeInformationTitle.Position =                          [obj.getWidth*0.05 obj.getHeight - 230  obj.getWidth*0.7 20 ];
            ShowDetailedMergeInformationTitle.Text =                            'Show detailed log during track merging:';


            obj.ShowDetailedMergeInformation =                          uicheckbox(obj.MainFigure);
            obj.ShowDetailedMergeInformation.Position =                          [obj.getWidth*0.79 obj.getHeight - 240  obj.getWidth*0.2 20 ];

            obj.ProcedureSelection =                                    uidropdown(obj.MainFigure);
            obj.ProcedureSelection.Position =                                    [obj.getWidth*0.5 50  obj.getWidth*0.4 20 ];
            obj.ProcedureSelection.Items =                                      {'Tracking by minimizing object distances',...
                                                                                'Delete tracks',...
                                                                                'Connect exisiting tracks with each other',...
                                                                                'Track-Delete-Connect'};                                                           
            obj.ProcedureSelection.Value =         'Tracking by minimizing object distances';
            
            
            obj.StartButton =                      uibutton(obj.MainFigure);
            obj.StartButton.Position =             [obj.getWidth*0.5 20  obj.getWidth*0.4 20 ];
            obj.StartButton.Text =                 'Start';
        
        end
        
        
    end
end

