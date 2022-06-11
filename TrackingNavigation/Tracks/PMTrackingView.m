classdef PMTrackingView
    %PMTRACKINGVIEW Creates views for tracking
    %  Creates guis to change tracking settings;
    
    
    
    properties
        ControlPanels
        
    end
    
    methods
        
        function obj = PMTrackingView(varargin)
            %PMTRACKINGVIEW Construct an instance of this class
            %   takes 1 argument:
            % 1: PMImagingProjectViewer (for positioning of panels relative to project-view);
            
            assert(isscalar(varargin{1}) && isa(varargin{1}, 'PMImagingProjectViewer'), 'Wrong input.')
         
            switch length(varargin)
               
                case 1
                     obj =                   obj.CreateTrackingViews(varargin{1});
                    
                otherwise
                    error('Wrong input.')
                
                
            end
           

        end
        
        
        function [obj] = createMenu(obj, ProjectViews)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
         
          
          
%             Masks_AutomatedCentroidConversion.Callback=         'CallbackForAutomatedMaskDetection';
%             Export_T_Tiff.Callback=                             'ExportData(''Time-series TIFF'')'; 
%             Export_Z_Tiff.Callback=                             'ExportData(''Z-stack TIFF'')';
%             Export_ChannelSeries.Callback=                      'ExportData(''Channel series'')';
%             Export_CurrentFrame.Callback=                       'ExportData(''Current frame'')';
    


           

%             Masks_AutomatedCentroidConversion=                  uimenu(Masks_Main);
%             Masks_AutomatedCentroidConversion.Label=            'Remove';
%             Masks_AutomatedCentroidConversion.Tag=              'Masks_AutomatedCentroidConversion';
%             Masks_AutomatedCentroidConversion.Enable=           'on';

            %% export menu:
%             Export_Main=                                        uimenu(FigureHandle, 'label', 'Export', 'tag', 'Export_Main');
% 
%             Export_T_Tiff=                                      uimenu(Export_Main);    
%             Export_T_Tiff.Label=                                'Time-series TIFF';
%             Export_T_Tiff.Tag=                                  'Export_T_Tiff';

% 
% 
% 
%             Export_T_Movie=                                     uimenu(Export_Main);
%             Export_T_Movie.Label=                               'Time-series Movie';
%             Export_T_Movie.Tag=                                 'Export_T_Movie';

% 
% 
%             Export_Z_Tiff=                                      uimenu(Export_Main);
%             Export_Z_Tiff.Label=                                'Z-stack TIFF';
%             Export_Z_Tiff.Tag=                                  'Export_Z_Tiff';



%             Export_Z_Tiff.Enable=                               'on';
% 
%             Export_ChannelSeries=                               uimenu(Export_Main);
%             Export_ChannelSeries.Label=                         'Channel series';
%             Export_ChannelSeries.Tag=                           'Export_ChannelSeries';

%              Export_ChannelSeries.Enable=                       'off';
% 
%             Export_CurrentFrame=                                uimenu(Export_Main);
%             Export_CurrentFrame.Label=                          'Currently shown frame';
%             Export_CurrentFrame.Tag=                            'Export_CurrentFrame';

%              Export_CurrentFrame.Enable=                        'off';
% 
%             Export_Status=                                      uimenu(Export_Main);
%             Export_Status.Label=                                'Export status';
%             Export_Status.Tag=                                  'Export_Status';
%             Export_Status.Checked=                              'off';
%             Export_Status.Enable=                               'off';
% 

        end
        
        
        
             
        function [obj] = CreateTrackingViews(obj, ProjectViews)
            
            

                TopRow =                ProjectViews.getStartRowTracking;
                FirstColumn =           ProjectViews.getLeftColumn;
                
                SecondColumn =          FirstColumn +  ProjectViews.getColumnShift ;
                WholeColumn =           ProjectViews.getColumnShift + ProjectViews.getWidthOfSecondColumn;
                Height =                ProjectViews.getViewHeight;
                FirstColumnWidth =      ProjectViews.getWidthOfFirstColumn;
                SecondColumnWidth =     ProjectViews.getWidthOfSecondColumn;
                RowShiftInternal =      ProjectViews.getRowShift;

                FirstRow =              TopRow;
                SecondRow =             FirstRow-RowShiftInternal;
                ThirdRow =              SecondRow-RowShiftInternal;
                FourthRow =             ThirdRow-RowShiftInternal;
                FifthRow =              FourthRow-RowShiftInternal;
                SixthRow =              FifthRow-RowShiftInternal;
               

                TrackingTitle=                                          uicontrol;
                TrackingTitle.Tag=                                      'TrackingTitle';
                TrackingTitle.Style=                                    'Text';
                TrackingTitle.Units=                                    'normalized';
                TrackingTitle.FontWeight=                               'bold';
                TrackingTitle.String=                                   'Tracking:';
                TrackingTitle.Position=                                 [FirstColumn FirstRow WholeColumn Height];
                TrackingTitle.HorizontalAlignment=                      'left';

                ActiveTrackTitle=                                       uicontrol;
                ActiveTrackTitle.Style=                                 'CheckBox';
                ActiveTrackTitle.Tag=                                   'SelectedTrackNumberText';
                ActiveTrackTitle.String=                                'Active track:';
                ActiveTrackTitle.FontWeight=                            'bold';
                ActiveTrackTitle.HorizontalAlignment=                   'left';
                ActiveTrackTitle.Units=                                 'normalized';
                ActiveTrackTitle.Position=                              [FirstColumn SecondRow FirstColumnWidth Height];

                
                ActiveTrack=                                            uicontrol;
                ActiveTrack.Style=                                      'Text';
                ActiveTrack.Tag=                                        'SelectedTrackNumber';
                ActiveTrack.FontWeight=                                 'bold';
                ActiveTrack.Units=                                      'normalized';
                ActiveTrack.Position=                                   [SecondColumn SecondRow SecondColumnWidth Height];
                
                
                ShowCentroids=                                       uicontrol;
                ShowCentroids.Tag=                                   'ShowCentroids';
                ShowCentroids.Style=                                  'CheckBox';
                ShowCentroids.Units=                                  'normalized';
                ShowCentroids.Position=                               [FirstColumn ThirdRow FirstColumnWidth Height];
                ShowCentroids.String=                                 { 'Centroids'};
                

                ShowMasks=                                            uicontrol;
                ShowMasks.Tag=                                        'ShowMasks';
                ShowMasks.Style=                                      'CheckBox';
                ShowMasks.Units=                                      'normalized';
                ShowMasks.Position=                                   [SecondColumn ThirdRow SecondColumnWidth Height];
                ShowMasks.String=                                     { 'Masks'};
                
                ShowTracks= uicontrol;
                ShowTracks.Tag=                                'ShowTrajectories';
                ShowTracks.Style=                               'CheckBox';
                ShowTracks.Units=                               'normalized';
                ShowTracks.Position=                            [FirstColumn FourthRow FirstColumnWidth Height];
                ShowTracks.String=                              { 'Tracks'};
                

                ShowMaximumProjection=                                    uicontrol;
                ShowMaximumProjection.Tag=                               'ShowMaxAnnotation';
                ShowMaximumProjection.Style=                              'CheckBox';
                ShowMaximumProjection.Units=                              'normalized';
                ShowMaximumProjection.Position=                           [SecondColumn FourthRow SecondColumnWidth Height];
                ShowMaximumProjection.String=                             { 'Max projection of annotation'};
                
 
                
            
                
                
                %% for changing visibility of tracks:
                Tracking.TrackingTitle=                                 TrackingTitle;
                Tracking.ActiveTrackTitle=                              ActiveTrackTitle;
                
                Tracking.ShowCentroids=                                 ShowCentroids;
                Tracking.ShowMasks=                                     ShowMasks;
                Tracking.ShowTracks=                                    ShowTracks;
                Tracking.ShowMaximumProjection=                         ShowMaximumProjection;
                
                Tracking.ActiveTrack=                                   ActiveTrack;
              

                
                obj.ControlPanels =                                 Tracking;

                

% 
% 
%                 MinimumFramesPerTrackTextHandle=                    uicontrol;
%                 MinimumFramesPerTrackTextHandle.Style=              'Text';
%                 MinimumFramesPerTrackTextHandle.Tag=                'MinimumFramesPerTrackText';
%                 MinimumFramesPerTrackTextHandle.String=             'Min frames:';
%                 MinimumFramesPerTrackTextHandle.Units=                  'normalized';
%                 MinimumFramesPerTrackTextHandle.Position=               [FirstColumn FourthRow 0.19 0.02];
% 
% 
%                 MinimumFramesPerTrackHandle=                    uicontrol;
%                 MinimumFramesPerTrackHandle.Style=              'PopupMenu';
%                 MinimumFramesPerTrackHandle.Tag=                'MinimumFramesPerTrack';
%                 MinimumFramesPerTrackHandle.Value=              1;
%                 MinimumFramesPerTrackHandle.Units=                 'normalized';
%                 MinimumFramesPerTrackHandle.Position=              [SecondColumn FourthRow 0.2 0.02];
% 
% 
%                 RangeMinTextHandle=                 uicontrol;
%                 RangeMinTextHandle.Style=           'Text';
%                 RangeMinTextHandle.Tag=             'RangeMinText';
%                 RangeMinTextHandle.String=          'Range min:';
%                 RangeMinTextHandle.Units=           'normalized';
%                 RangeMinTextHandle.Position=        [FirstColumn FifthRow 0.19 0.02];
% 
%                 RangeMinHandle=             uicontrol;
%                 RangeMinHandle.Style=       'PopupMenu';
%                 RangeMinHandle.Tag=         'RangeMin';
%                 RangeMinHandle.Value=                           1;
%                 RangeMinHandle.Units=                           'normalized';
%                 RangeMinHandle.Position=                        [SecondColumn FifthRow 0.2 0.02];
% 
% 
%                 RangeMaxTextHandle=                 uicontrol;
%                 RangeMaxTextHandle.Style=           'Text';
%                 RangeMaxTextHandle.Tag=            'RangeMaxText';
%                 RangeMaxTextHandle.String=                                              'Range max:';
%                 RangeMaxTextHandle.Units=                                               'normalized';
%                 RangeMaxTextHandle.Position=                                            [FirstColumn SixthRow 0.19 0.02];
% 
%                 RangeMaxHandle=                 uicontrol;
%                 RangeMaxHandle.Style=           'PopupMenu';
%                 RangeMaxHandle.Tag=             'RangeMax';
%                 RangeMaxHandle.Units=          'normalized';
%                 RangeMaxHandle.Position=        [SecondColumn SixthRow 0.2 0.02];
% 
%                  
%                 SortTrackListHandle=                    uicontrol;
%                 ColumnList=                             {'#', 'ID', 'Start', 'End','fr#', 'Miss', 'Link'};
%                 SortTrackListHandle.String=             ColumnList;
%                 SortTrackListHandle.Style=              'PopupMenu';
%                 SortTrackListHandle.Tag=                'SortTrackList';
%                 SortTrackListHandle.Parent=             MainWindowNavigationHandle;
%                 SortTrackListHandle.Units=              'normalized';
%                 SortTrackListHandle.Position=           [SecondColumn SeventhRow 0.2 0.02];
% 
%                 SortTrackListTextHandle=                uicontrol;
%                 SortTrackListTextHandle.Style=          'Text';
%                 SortTrackListTextHandle.Tag=            'SortTrackListText';
%                 SortTrackListTextHandle.String=         'Sort by:';
%                 SortTrackListTextHandle.Units=                                          'normalized';
%                 SortTrackListTextHandle.Position=                                       [FirstColumn SeventhRow 0.19 0.02];


               

                
                
                
                %MinimumFramesPerTrackHandle.Callback=           'RepopulateTrackList';
                %RangeMinHandle.Callback=                        'RepopulateTrackList';
                %RangeMaxHandle.Callback=        'RepopulateTrackList';     
                %SortTrackListHandle.Callback=           'RepopulateTrackList';
                
                %obj.Tracking.MinimumFramesPerTrack=                                  MinimumFramesPerTrackHandle;
                %obj.Tracking.RangeMin=                                               RangeMinHandle;
                %obj.Tracking.RangeMax=                                               RangeMaxHandle;
                %obj.Tracking.SortTrackList=                                          SortTrackListHandle;

                
            
            
            
            
            
            
            
        end
        
    end
end

