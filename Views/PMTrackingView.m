classdef PMTrackingView
    %PMTRACKINGVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        Menu
        ControlPanels
        
    end
    
    methods
        
        function obj = PMTrackingView(ProjectViews)
            %PMTRACKINGVIEW Construct an instance of this class
            %   Detailed explanation goes here
            
            obj =                   obj.createMenu(ProjectViews);
            obj =                   obj.CreateTrackingViews(ProjectViews);

        end
        
        
        function [obj] = createMenu(obj, ProjectViews)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            FigureHandle  =                                     ProjectViews.Figure;
    
            %% tracks menu:
            Tracks_Main=                                        uimenu(FigureHandle);
            Tracks_Main.Label=                                  'Tracking';
            Tracks_Main.Tag=                                    'Tracks_Main';



            Tracks_Remove=                                      uimenu(Tracks_Main);
            Tracks_Remove.Label=                                'Delete active track';
            Tracks_Remove.Tag=                                  'Tracks_Remove';
            Tracks_Remove.Enable=                               'on';
            
             Tracks_RemoveAll=                                      uimenu(Tracks_Main);
            Tracks_RemoveAll.Label=                                'Delete all tracks';
            Tracks_RemoveAll.Tag=                                  'Tracks_RemoveAll';
            Tracks_RemoveAll.Enable=                               'on';
            
            Tracks_Merge=                                       uimenu(Tracks_Main);
            Tracks_Merge.Label=                                 'Merge selected tracks';
            Tracks_Merge.Tag=                                   'Tracks_Merge';
            Tracks_Merge.Separator=                              'off';
            Tracks_Merge.Enable=                               'on';

            Tracks_Split=                                       uimenu(Tracks_Main);
            Tracks_Split.Label=                                 'Split selected tracks';
            Tracks_Split.Tag=                                   'Tracks_Split';
            Tracks_Split.Enable=                               'on';

            
            Tracks_Update=                                      uimenu(Tracks_Main);
            Tracks_Update.Label=                                'Update tracks (u)';
            Tracks_Update.Tag=                                  'Tracks_Update';
            Tracks_Update.Separator=                            'off';
            Tracks_Update.Enable=                               'on';
            
          
            
            Masks_Remove=                                       uimenu(Tracks_Main);
            Masks_Remove.Label=                                 'Delete active mask';
            Masks_Remove.Tag=                                   'Masks_Remove';
            Masks_Remove.Separator=                              'on';
            Masks_Remove.Enable=                                'on';

                 
            obj.Menu.DeleteAllTracks =                          Tracks_RemoveAll;
             obj.Menu.DeleteTrack =                          Tracks_Remove;
             obj.Menu.MergeTracks =                          Tracks_Merge;
             obj.Menu.SpitTracks =                          Tracks_Split;
            obj.Menu.UpdateTracks =                         Tracks_Update;
            
            obj.Menu.DeleteMask =                           Masks_Remove;
            
            
            
            
            
            Tracks_Link=                                        uimenu(Tracks_Main);
            Tracks_Link.Label=                                  'Link';
            Tracks_Link.Tag=                                    'Tracks_Link';

             Tracks_Link.Enable=                                'off';

          


            Tracks_LabelComplete=                               uimenu(Tracks_Main);
            Tracks_LabelComplete.Label=                         'Label complete';
            Tracks_LabelComplete.Tag=                           'Tracks_LabelComplete';

            Tracks_LabelComplete.Separator=                     'on';
            Tracks_LabelComplete.Enable=                       'off';

            Tracks_LabelIncomplete=                             uimenu(Tracks_Main);
            Tracks_LabelIncomplete.Label=                       'Label incomplete';
            Tracks_LabelIncomplete.Tag=                         'Tracks_LabelIncomplete';

            Tracks_LabelIncomplete.Enable=                       'off';

            Tracks_LabelUndefined=                              uimenu(Tracks_Main);
            Tracks_LabelUndefined.Label=                        'Label undefined';
            Tracks_LabelUndefined.Tag=                          'Tracks_LabelUndefined';

            Tracks_LabelUndefined.Enable=                       'off';

         

                        Tracks_Link.Callback=                               'ModifyTracks(''Link'')';
                        Tracks_LabelComplete.Callback=                      'ModifyTracks(''Label complete'')';
              Tracks_LabelIncomplete.Callback=                    'ModifyTracks(''Label incomplete'')';
                        Tracks_LabelUndefined.Callback=                     'ModifyTracks(''Label undefined'')';
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
            
            

                TopRow =               ProjectViews.StartRowTracking;
                FirstColumn =           ProjectViews.LeftColumn;
                SecondColumn =          FirstColumn +ProjectViews.ColumnShift ;
                WholeColumn =           ProjectViews.ColumnShift + ProjectViews.WidthOfSecondColumn;
                Height =                ProjectViews.ViewHeight;
                FirstColumnWidth =      ProjectViews.WidthOfFirstColumn;
                SecondColumnWidth =     ProjectViews.WidthOfSecondColumn;
                RowShiftInternal =      ProjectViews.RowShift;

                FirstRow =              TopRow;
                SecondRow =             FirstRow-RowShiftInternal;
                ThirdRow =              SecondRow-RowShiftInternal;
                FourthRow =             ThirdRow-RowShiftInternal;
                FifthRow =              FourthRow-RowShiftInternal;
                SixthRow =              FifthRow-RowShiftInternal;
                SeventhRow =            SixthRow-RowShiftInternal;
                
                RowForList =              0.005;
                HeightForList  =            0.23;
              

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
                
 
                
                ListWithFilteredTracksTitle=                            uicontrol;
                ListWithFilteredTracksTitle.Style=                      'Text';
                ListWithFilteredTracksTitle.Tag =                       'ListWithFilteredTracksTitle';
                TitleOfTrackColumns=                                    sprintf('%5s %5s %5s %5s %5s %5s %5s', '#', 'ID', 'Start', 'End','fr#', 'Miss', 'Link');
                ListWithFilteredTracksTitle.String=                     TitleOfTrackColumns;
                ListWithFilteredTracksTitle.HorizontalAlignment =       'left';
                ListWithFilteredTracksTitle.FontName=                   'Courier';
                ListWithFilteredTracksTitle.Units=                      'normalized';
                ListWithFilteredTracksTitle.Position=                   [FirstColumn FifthRow WholeColumn Height];

                
                ListWithFilteredTracks=                                 uicontrol;
                ListWithFilteredTracks.Style=                           'Listbox';
                ListWithFilteredTracks.Tag=                             'ListWithFilteredTracks';
                ListWithFilteredTracks.FontName=                        'Courier';
                ListWithFilteredTracks.Max=                             2;
                ListWithFilteredTracks.Units=                           'normalized';
                ListWithFilteredTracks.Position=                         [FirstColumn FifthRow-HeightForList WholeColumn HeightForList];

                
                
                %% for changing visibility of tracks:
                Tracking.TrackingTitle=                                 TrackingTitle;
                Tracking.ActiveTrackTitle=                              ActiveTrackTitle;
                
                Tracking.ShowCentroids=                                 ShowCentroids;
                Tracking.ShowMasks=                                     ShowMasks;
                Tracking.ShowTracks=                                    ShowTracks;
                Tracking.ShowMaximumProjection=                         ShowMaximumProjection;
                
                Tracking.ActiveTrack=                                   ActiveTrack;
                Tracking.ListWithFilteredTracksTitle=                   ListWithFilteredTracksTitle;
                Tracking.ListWithFilteredTracks=                        ListWithFilteredTracks;


                
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

