classdef PMTrackingNavigationEditViewView
    %PMTRACKINGNAVIGATIONEDITVIEWVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        MainFigure
        
        ActiveTrack
        EditActiveTrackSelection
        EditActiveTrackAction
        
        SelectedTracks
        EditSelectedTrackSelection
        EditSelectedTrackAction
        
        ActiveFrame
        
        ObjectList
        
        TrackList
   
        TrackDetail
         
    end
    
    methods
        
        function obj = PMTrackingNavigationEditViewView
            %PMTRACKINGNAVIGATIONEDITVIEWVIEW Construct an instance of this class
            %   Detailed explanation goes here
            
                ScreenSize =                    get(0,'screensize');

                Height =                        ScreenSize(4)*0.8;
                Left =                          ScreenSize(3)*0.5;
                Width =                         ScreenSize(3)*0.45;

                RightColumnPosition     =       0.05;
                RightColumWidth =               0.9;

                LeftColumnPosition =            0.05;
                LeftColumWidth =               0.3;

                fig =                           uifigure;

                obj.MainFigure =               fig;

                fig.Position =                  [Left 0 Width Height];

                
                ActiveTrackTitle =                          uilabel(fig);
                SelectedTracksTitle =                       uilabel(fig);
                ActiveFrameTitle =                          uilabel(fig);


                obj.ActiveTrack =                           uilabel(fig);
                obj.EditActiveTrackSelection =              uidropdown(fig);
                obj.EditActiveTrackAction =                    uibutton(fig);
                
                obj.SelectedTracks =                        uidropdown(fig);
                obj.EditSelectedTrackSelection =            uidropdown(fig);
                obj.EditSelectedTrackAction =               uibutton(fig);
                
                obj.ActiveFrame =                           uidropdown(fig);
                
                obj.ObjectList =                            uitable(fig);
                obj.TrackList =                             uitable(fig);
                obj.TrackDetail =                           uitable(fig);

                
                
                %% positions:
                ActiveTrackTitle.Position =                         [Width*0.05 Height - 30  Width*LeftColumWidth 20 ];
                SelectedTracksTitle.Position =                      [Width*0.3 Height - 30  Width*LeftColumWidth 20 ];
                ActiveFrameTitle.Position =                         [Width*0.65 Height - 30  Width*LeftColumWidth 20 ];

              
                obj.ActiveTrack.Position =                          [Width*0.2 Height - 30  100 20 ];
                obj.EditActiveTrackSelection.Position =             [Width*0.05 Height - 60  150 20 ];
                obj.EditActiveTrackAction.Position =                [Width*0.05 Height - 80  150 20 ];

                 
                obj.SelectedTracks.Position =                       [Width*0.5 Height - 30  70 20 ];
                obj.EditSelectedTrackSelection.Position =           [Width*0.3 Height - 60  150 20 ];
                obj.EditSelectedTrackAction.Position =              [Width*0.3 Height - 80  150 20 ];
                
                obj.ActiveFrame.Position =                          [Width*0.8 Height - 30  70 20 ];
                
                obj.ObjectList.Position =                       [Width*RightColumnPosition Height - 360  Width*RightColumWidth 270 ];;
                obj.TrackList.Position =                    [Width*RightColumnPosition Height - 480  Width*RightColumWidth 80 ];;
                obj.TrackDetail.Position =                 [Width*RightColumnPosition Height - 600  Width*RightColumWidth 80 ];;

                
                ActiveTrackTitle.Text =                     'Active track:';
                SelectedTracksTitle.Text =                  'Selected tracks:';
                ActiveFrameTitle.Text =                     'Active frame:';

                obj.EditSelectedTrackSelection.Items =      {'Delete tracks',  'Merge tracks', 'Split tracks'};
                obj.EditSelectedTrackAction.Text =          'Action';
                
                obj.EditActiveTrackSelection.Items =        {'Delete active mask', 'Forward tracking', 'Backward tracking', 'Label finished', 'Label unfinished'};
                obj.EditActiveTrackAction.Text =            'Action';
                    
                
                obj.TrackList.ColumnSortable =              [false true true true false false];
                
        end
        
       
    end
end

