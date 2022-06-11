classdef PMTrackingNavigationView < PMFigure
    %PMTRACKINGNAVIGATIONEDITVIEWVIEW For visual display of PMTrackingNavigation data;
    %   shows active track and selected track information
    %   offers action to be taken;
    
    properties
        
           
    end
    
    properties (Access = private)
        
        
        ActiveTrack
        EditActiveTrackSelection
        EditActiveTrackAction
        
        SelectedTracks
        EditSelectedTrackSelection
        EditSelectedTrackAction
        
        ActiveFrame
        
        TrackList
        TrackDetail
        
        
    end
    
    properties (Access = private) % dimensions/ positions
        Height 
        Left
        Width
        RightColumnPosition
        RightColumWidth
        LeftColumnPosition
        LeftColumWidth
        
    end
    
    
    methods % INITIALIZATION
        
        function obj = PMTrackingNavigationView(varargin)
            %PMTRACKINGNAVIGATIONVIEW Construct an instance of this class
            %   takes 0 arguments
            switch length(varargin)    
                case 0
                otherwise
                    error('Wrong input.')
            end
           
          
        end
        
    end
    
    methods % SETTERS
        
        function obj =      show(obj)
            
            obj =        obj.showFigure;
            if obj.figureIsBlank

                obj =       obj.setGraphicElements;
                obj =       obj.setFigureIsBlank(false);
            end
            
        end
        
        function obj =      setCallbacks(obj, varargin)
            
            if obj.figureIsActive
                
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 6
                        obj.TrackList.CellSelectionCallback =                  varargin{1};   
                        obj.ActiveFrame.ValueChangedFcn =                     varargin{2};   

                        obj.EditActiveTrackSelection.ValueChangedFcn =        varargin{3};   
                        obj.EditActiveTrackAction.ButtonPushedFcn =           varargin{4};   

                        obj.EditSelectedTrackSelection.ValueChangedFcn =       varargin{5};   
                        obj.EditSelectedTrackAction.ButtonPushedFcn =         varargin{6};   

                    otherwise
                     error('All possible 6 callbacks must be set simultaneously.')

                end
            end
        end
        
        function obj =      updateWith(obj, MyTrackingNavigation)
           
            if obj.figureIsActive
                
                Type = class(MyTrackingNavigation);
                switch Type
                    case 'PMTrackingNavigation'
                        % this should be done by controller, not view;
                        obj =                           obj.updateActiveTrackChangeWith(MyTrackingNavigation);
                        
                        obj =                           obj.setSelectedFrameWith(MyTrackingNavigation.getActiveFrame);

                        obj.TrackList.ColumnName =       {'ID', 'Start frame', 'End frame', 'Total frame', 'Missing frames', 'Finished'};
                        obj.TrackList.Data =            MyTrackingNavigation.getTrackSummaryList;

                        obj.TrackDetail.ColumnName =    MyTrackingNavigation.getFieldNamesOfTrackingCell;
                        obj.TrackDetail.Data =          MyTrackingNavigation.getConciseObjectListOfActiveTrack;
                        
                        obj =                           obj.resetSelectedTracksActionForTrackNumber(length(MyTrackingNavigation.getIdsOfSelectedTracks));    

                    otherwise
                        error('Wrong input.')



                end
            
            end
            
           
           end

        function obj =      updateActiveTrackChangeWith(obj, MyTrackingNavigation)
            
            Type = class(MyTrackingNavigation);
            switch Type
                case 'PMTrackingNavigation'
                    obj.ActiveTrack.Text =        num2str(MyTrackingNavigation.getIdOfActiveTrack);
                     obj =                         obj.setActiveFrameList(MyTrackingNavigation);
                     
                    NewSelectedTracks =           arrayfun(@(x) num2str(x), MyTrackingNavigation.getIdsOfSelectedTracks, 'UniformOutput', false);
                    obj.SelectedTracks.Items =    NewSelectedTracks;

                        
                    
                otherwise
                     error('Wrong input.')
                    
            end
            
            
        end
        
        function obj =      updateFinishedTracksChangeWith(obj, Value)
            
            Type = class(Value);
            switch Type
                case 'PMTrackingNavigation'                     
                    NewData =                       Value.getTrackSummaryList;
                    obj.TrackList.Data(:, 6)=       NewData(:, 6);

                otherwise
                     error('Wrong input.')
                    
            end
            
            
        end
        
    end
    
    methods % GETTERS

        function Value =    getSelectedFrame(obj)
            Value = obj.ActiveFrame.Value;
        end

        function Value =    getSelectedActionForSelectedTracks(obj)
            Value = obj.EditSelectedTrackSelection.Value;
        end

        function Value =    getSelectedActionForActiveTrack(obj)
            Value = obj.EditActiveTrackSelection.Value;
        end
           
    end
    
    methods (Access = private)
        
        function obj =      setDimensions(obj)
            
            ScreenSize =           get(0,'screensize');

            obj.Height =           ScreenSize(4) * 0.8;
            obj.Left =             ScreenSize(3) * 0.5;
            obj.Width =            ScreenSize(3) * 0.45;

            obj.RightColumnPosition     =       0.05;
            obj.RightColumWidth =               0.9;

            obj.LeftColumnPosition =            0.05;
            obj.LeftColumWidth =               0.3;

        end
        
        function obj =      setGraphicElements(obj)
            
            obj =           obj.setDimensions;
            obj=            obj.setPosition([obj.Left 0 obj.Width obj.Height]);

            ActiveTrackTitle =                          uilabel(obj.getFigureHandle);
            ActiveTrackTitle.Position =                 [obj.Width*0.05 obj.Height - 30  obj.Width*obj.LeftColumWidth 20 ];
            ActiveTrackTitle.Text =                     'Active track:';

            obj.ActiveTrack =                           uilabel(obj.getFigureHandle);
            obj.ActiveTrack.Position =                  [obj.Width*0.2 obj.Height - 30  100 20 ];

            SelectedTracksTitle =                       uilabel(obj.getFigureHandle);
            SelectedTracksTitle.Position =              [obj.Width*0.3 obj.Height - 30  obj.Width*obj.LeftColumWidth 20 ];
            SelectedTracksTitle.Text =                  'Selected tracks:';

            obj.SelectedTracks =                        uidropdown(obj.getFigureHandle);
            obj.SelectedTracks.Position =               [obj.Width*0.5 obj.Height - 30  70 20 ];

            ActiveFrameTitle =                          uilabel(obj.getFigureHandle);
            ActiveFrameTitle.Position =                 [obj.Width*0.65 obj.Height - 30  obj.Width*obj.LeftColumWidth 20 ];
            ActiveFrameTitle.Text =                     'Active frame:';

            obj.ActiveFrame =                           uidropdown(obj.getFigureHandle);
            obj.ActiveFrame.Position =                 [obj.Width*0.8 obj.Height - 30  70 20 ];

            obj.EditActiveTrackSelection =              uidropdown(obj.getFigureHandle);
            obj.EditActiveTrackSelection.Position =     [obj.Width*0.05 obj.Height - 60  150 20 ];
            obj.EditActiveTrackSelection.Items =        {'Delete active mask', 'Forward tracking', 'Backward tracking', 'Label finished', 'Label unfinished'};
        
            obj.EditActiveTrackAction =                 uibutton(obj.getFigureHandle);
            obj.EditActiveTrackAction.Position =        [obj.Width*0.05 obj.Height - 80  150 20 ];
            obj.EditActiveTrackAction.Text =            'Action';

            obj.EditSelectedTrackSelection =            uidropdown(obj.getFigureHandle);
            obj.EditSelectedTrackSelection.Position =   [obj.Width*0.3 obj.Height - 60  150 20 ];
            obj.EditSelectedTrackSelection.Items =      {'Delete tracks',  'Merge tracks', 'Split tracks'};

          
            obj.EditSelectedTrackAction =               uibutton(obj.getFigureHandle);
              obj.EditSelectedTrackAction.Position =     [obj.Width*0.3 obj.Height - 80  150 20 ];
            obj.EditSelectedTrackAction.Text =          'Action';

        
            obj.TrackList =                             uitable(obj.getFigureHandle);
            obj.TrackList.Position =                    [obj.Width * obj.RightColumnPosition obj.Height * 0.3 + 40  obj.Width * obj.RightColumWidth obj.Height * 0.5 ];
            obj.TrackList.ColumnSortable =              [true true true true true true];

            obj.TrackDetail =                          uitable(obj.getFigureHandle);
            obj.TrackDetail.Position =                 [obj.Width * obj.RightColumnPosition 20  obj.Width * obj.RightColumWidth obj.Height * 0.3 ];
    
            
        end
        
        function obj =      setActiveFrameList(obj, Value)
            obj.ActiveFrame.Items =                    arrayfun(@(x) num2str(x), 1 : Value.getMaxFrame, 'UniformOutput', false);
          end
          
        function obj =      resetSelectedTracksActionForTrackNumber(obj, NumberOfSelectedTracks)

            SelectedEditAction = obj.EditSelectedTrackSelection.Value;
            switch NumberOfSelectedTracks
                case 0
                    obj.EditSelectedTrackAction.Enable = 'off';

                case 1
                    switch SelectedEditAction
                        case  {'Delete tracks','Delete masks','Split tracks'}
                            obj.EditSelectedTrackAction.Enable = 'on';
                        otherwise
                            obj.EditSelectedTrackAction.Enable = 'off';
                    end


                case 2
                     switch SelectedEditAction
                        case  {'Delete tracks','Delete masks','Merge tracks'}
                            obj.EditSelectedTrackAction.Enable = 'on';
                        otherwise
                            obj.EditSelectedTrackAction.Enable = 'off';
                    end

                otherwise
                    switch SelectedEditAction
                        case  {'Delete tracks','Delete masks'}
                            obj.EditSelectedTrackAction.Enable = 'on';
                        otherwise
                            obj.EditSelectedTrackAction.Enable = 'off';
                    end

            end


        end
        
        function  obj =     setSelectedFrameWith(obj, Value)
                if ~isempty(obj) && isvalid(obj.ActiveFrame) && ~isnan(Value) && length(obj.ActiveFrame.Value) >= Value
                    obj.ActiveFrame.Value =       num2str(Value);

                end

            end
 
    end
    
end

