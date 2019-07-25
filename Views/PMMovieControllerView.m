classdef PMMovieControllerView
    %PMMOVIECONTROLLERVIEW Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % views:
        Figure
        
        Menu
        
        Navigation
        Channels
        Annotation
        
        MovieView
         
        
    end
    
    methods
        
        function obj = PMMovieControllerView(Input)
            %PMMOVIECONTROLLERVIEW Construct an instance of this class
            %   Creation of views that support navigating through the loaded image-sequences;

            
            if ishghandle(Input,'axes') % if the input is only the 
                
                obj.Figure =           Input.Parent;  
                obj =                   obj.createMovieView(Input);
                
            else % if input is the project view: create more views and put them in relation to the whole project window;
            
                obj =                   obj.createMovieMenu(Input);
                obj =                   obj.CreateNavigationViews(Input);
                obj =                   obj.CreateChannelViews(Input);
                obj =                   obj.CreateAnnotationViews(Input);
                obj =                   obj.createMovieView(Input);
            
            end
      
        end
        
     
        function obj = createMovieMenu(obj, ProjectViews)
            
            MainMovieMenu=                                                      uimenu(ProjectViews.Figure);
            MainMovieMenu.Label=                                                'Movie';

            obj.Menu.Keyword=                                                   uimenu(MainMovieMenu);
            obj.Menu.Keyword.Label=                                             'Change keyword';
            obj.Menu.Keyword.Tag=                                               'Movies_EditKeyword';
            obj.Menu.Keyword.Enable=                                            'on';

            obj.Menu.ReapplySourceFiles=                                        uimenu(MainMovieMenu);
            obj.Menu.ReapplySourceFiles.Label=                                  'Reapply source files';
            obj.Menu.ReapplySourceFiles.Tag=                                    'ReapplySourceFiles';
            obj.Menu.ReapplySourceFiles.Separator=                              'on';
            obj.Menu.ReapplySourceFiles.Enable=                                 'on';

            obj.Menu.DeleteImageCache=                                          uimenu(MainMovieMenu);
            obj.Menu.DeleteImageCache.Label=                                    'Delete image cache';
            obj.Menu.DeleteImageCache.Tag=                                      'DeleteImageCache';
            obj.Menu.DeleteImageCache.Separator=                                'off';
            obj.Menu.DeleteImageCache.Enable=                                   'on';
            
            obj.Menu.ApplyManualDriftCorrection=                                uimenu(MainMovieMenu);
            obj.Menu.ApplyManualDriftCorrection.Label=                          'Apply manual drift correction';
            obj.Menu.ApplyManualDriftCorrection.Tag=                            'Export_ManualTracking';
            obj.Menu.ApplyManualDriftCorrection.Separator=                      'on';
            obj.Menu.ApplyManualDriftCorrection.Enable=                         'on';

            obj.Menu.EraseAllDriftCorrections=                                  uimenu(MainMovieMenu);
            obj.Menu.EraseAllDriftCorrections.Label=                            'Erase all drift corrections';
            obj.Menu.EraseAllDriftCorrections.Tag=                              'Export_ResetDriftCorrection';
            obj.Menu.EraseAllDriftCorrections.Enable=                           'on';

            % access movie file
            obj.Menu.ShowMetaData=                                              uimenu(MainMovieMenu);
            obj.Menu.ShowMetaData.Label=                                        'Show meta-data';
            obj.Menu.ShowMetaData.Tag=                                          'Movies_MovieInfo';
            obj.Menu.ShowMetaData.Separator=                                    'on';
            obj.Menu.ShowMetaData.Enable=                                       'on';

            %
            obj.Menu.ShowAttachedFiles=                                         uimenu(MainMovieMenu);
            obj.Menu.ShowAttachedFiles.Label=                                   'Show attached files';
            obj.Menu.ShowAttachedFiles.Tag=                                     'Movies_ShowFiles';
            obj.Menu.ShowAttachedFiles.Enable=                                  'on';
         
        end
        
        
        function obj = CreateNavigationViews(obj, ProjectViews)
            
           
            %% set positions
            
            TopRowInside =                                                          ProjectViews.StartRowNavigation;
            
            ColumnShiftInside =                                                     ProjectViews.ColumnShift;
            ViewHeightInside =                                                      ProjectViews.ViewHeight;
            WidthOfFirstColumnInside =                                              ProjectViews.WidthOfFirstColumn;
            WidthOfSecondColumnInside =                                             ProjectViews.WidthOfSecondColumn;
               
            RowShiftInside =                                                        ProjectViews.RowShift;
            LeftColumnStart =                                                       0.8;
           

            TitleRow =                                                              TopRowInside-0.11;
            
            HeightOfEditSelection =                                                 0.1;
            
            
            PositionRow1 =                                                          TitleRow-RowShiftInside;
            PositionRow2 =                                                          PositionRow1-RowShiftInside;
            PositionRow3 =                                                          PositionRow2-RowShiftInside;
            PositionRow4 =                                                          PositionRow3-RowShiftInside;
           
            PositionRow5 =                                                          PositionRow4-RowShiftInside;
            PositionRow6 =                                                          PositionRow5-RowShiftInside;

            FirstColumn =                                                           LeftColumnStart;
            SecondColumn =                                                          LeftColumnStart + ColumnShiftInside;

            

            %% list of options:
            EditingOptions=                                                         uicontrol;
            EditingOptions.Tag=                                                     'SelectDisplayOfImageAnalysis';
            EditingOptions.Style=                                                   'Listbox';
            EditingOptions.String=                                                  { 'Viewing only',  'Edit manual drift correction', 'Edit tracks'};
            EditingOptions.Units=                                                   'normalized';
            EditingOptions.Position=                                                [FirstColumn TitleRow (ColumnShiftInside + WidthOfSecondColumnInside) HeightOfEditSelection];


            CurrentTimePointTitle=                                                  uicontrol;
            CurrentTimePointTitle.Style=                                            'Text';
            CurrentTimePointTitle.FontWeight=                                       'normal';
            CurrentTimePointTitle.HorizontalAlignment=                              'left';
            CurrentTimePointTitle.Tag=                                              'CurrentTimePointText';
            CurrentTimePointTitle.String=                                           'Frame#:';
            CurrentTimePointTitle.Units=                                            'normalized';
            CurrentTimePointTitle.Position=                                         [ FirstColumn PositionRow1 WidthOfFirstColumnInside ViewHeightInside];
            
            CurrentTimePoint=                                                       uicontrol;
            CurrentTimePoint.Style=                                                 'PopupMenu';
            CurrentTimePoint.Tag=                                                   'CurrentTimePoint';
            CurrentTimePoint.Units=                                                 'normalized';
            CurrentTimePoint.Position=                                              [SecondColumn PositionRow1 WidthOfSecondColumnInside ViewHeightInside];

            TimeSlider =                                                            uicontrol;
            TimeSlider.Style =                                                      'slider';
             
            CurrentPlaneTitle=                                                      uicontrol;
            CurrentPlaneTitle.Style=                                                'Text';
            CurrentPlaneTitle.FontWeight=                                           'normal';
            CurrentPlaneTitle.HorizontalAlignment=                                  'left';
            CurrentPlaneTitle.Tag=                                                  'CurrentPlaneText';
            CurrentPlaneTitle.String=                                               'TopPlane#:';
            CurrentPlaneTitle.Units=                                                'normalized';
            CurrentPlaneTitle.Position=                                             [FirstColumn PositionRow2 WidthOfFirstColumnInside ViewHeightInside];

            CurrentPlane=                                                           uicontrol;
            CurrentPlane.Style=                                                     'PopupMenu';
            CurrentPlane.Tag=                                                       'CurrentPlane';
            CurrentPlane.Units=                                                     'normalized';
            CurrentPlane.Position=                                                  [SecondColumn PositionRow2 WidthOfSecondColumnInside ViewHeightInside];

            ShowMaxVolumeHandle=                                                    uicontrol;
            ShowMaxVolumeHandle.Style=                                              'CheckBox';
            ShowMaxVolumeHandle.Tag=                                                'ShowMaxVolume';
            ShowMaxVolumeHandle.String=                                             'Maximum projection';
            ShowMaxVolumeHandle.Units=                                              'normalized';
            ShowMaxVolumeHandle.Position=                                           [FirstColumn PositionRow3 WidthOfFirstColumnInside ViewHeightInside];

            CropImageHandle=                                                        uicontrol;
            CropImageHandle.Style=                                                  'CheckBox';
            CropImageHandle.Tag=                                                    'CropImage';
            CropImageHandle.Units=                                                  'normalized';
            CropImageHandle.Position=                                               [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            CropImageHandle.String=                                                 'Crop image';
            
            ApplyDriftCorrectionHandle=                                             uicontrol;
            ApplyDriftCorrectionHandle.Style=                                       'CheckBox';
            ApplyDriftCorrectionHandle.Tag=                                         'DriftCorrectionHandle';
            ApplyDriftCorrectionHandle.Units=                                       'normalized';
            ApplyDriftCorrectionHandle.Position=                                    [FirstColumn PositionRow4 WidthOfFirstColumnInside ViewHeightInside];
            ApplyDriftCorrectionHandle.String=                                      'Apply drift';
            
            %% change settings of handles that are dependent on loaded movie;
            obj.Navigation.TimeSlider=                                              TimeSlider;
            obj.Navigation.EditingOptions=                                          EditingOptions;
            obj.Navigation.CurrentTimePointTitle=                                   CurrentTimePointTitle;
            obj.Navigation.CurrentTimePoint=                                        CurrentTimePoint;
            obj.Navigation.CurrentPlaneTitle=                                       CurrentPlaneTitle;
            obj.Navigation.CurrentPlane=                                            CurrentPlane;
            obj.Navigation.ShowMaxVolume=                                           ShowMaxVolumeHandle;
            obj.Navigation.CropImageHandle=                                         CropImageHandle;
            obj.Navigation.ApplyDriftCorrection=                                    ApplyDriftCorrectionHandle;
        


        end
        
        
        function obj = CreateChannelViews(obj, ProjectViews)
            
            
            TopRow =                                                    ProjectViews.StartRowChannels;
            
            LeftColumnInside =                                          ProjectViews.LeftColumn;
            ColumnShiftInside =                                         ProjectViews.ColumnShift;
            ViewHeightInside =                                          ProjectViews.ViewHeight;
            
            WidthOfFirstColumnInside =                                  ProjectViews.WidthOfFirstColumn;
            WidthOfSecondColumnInside =                                 ProjectViews.WidthOfSecondColumn;
            
            RowShiftInside =                                            ProjectViews.RowShift;
           
            PositionRow0 =                                              TopRow-RowShiftInside*1;
            PositionRow1 =                                              TopRow-RowShiftInside*2;
            PositionRow2 =                                              TopRow-RowShiftInside*3;
            PositionRow3 =                                              TopRow-RowShiftInside*4;
            PositionRow4 =                                              TopRow-RowShiftInside*5;
            PositionRow5 =                                              TopRow-RowShiftInside*6;
            PositionRow6 =                                              TopRow-RowShiftInside*7;
            PositionRow7 =                                              TopRow-RowShiftInside*8;


            FirstColumn =                                               LeftColumnInside ;
            SecondColumn =                                              LeftColumnInside + ColumnShiftInside;

           
 
            
            
           
            SelectedChannelHandleTitle=                               uicontrol('Style', 'Text');
            SelectedChannelHandleTitle.Tag=                           'UseForDriftCorrectionComment';
            SelectedChannelHandleTitle.Units=                    'Normalized';
            SelectedChannelHandleTitle.Position=                 [FirstColumn PositionRow0 WidthOfFirstColumnInside ViewHeightInside];
            SelectedChannelHandleTitle.String=                   'Selected channel:';
            SelectedChannelHandleTitle.HorizontalAlignment=          'left';
            
           

            SelectedChannelHandle=                                              uicontrol;
            SelectedChannelHandle.Style=                                        'PopupMenu';
            SelectedChannelHandle.Tag=                                          'SelectedChannel';
            SelectedChannelHandle.Units=                                           'normalized';
            SelectedChannelHandle.Position=                                        [SecondColumn PositionRow0 WidthOfSecondColumnInside ViewHeightInside];

  

            SelectedChannelHandle.BackgroundColor =                     'k';

            %% fill content
            MinimumIntensityTitle=                                            uicontrol('Style', 'Text');
            MinimumIntensityTitle.Tag=                                   'TextMinimum';
            MinimumIntensityTitle.Units=                                              'Normalized';
            MinimumIntensityTitle.Position=                                           [FirstColumn PositionRow1 WidthOfFirstColumnInside ViewHeightInside];
            MinimumIntensityTitle.String=                                             'Intensity (min):';
            MinimumIntensityTitle.HorizontalAlignment=                                'left';

            MinimumIntensity=                                               uicontrol('Style', 'Edit');
            MinimumIntensity.Tag=                                           'MinimumIntensity';
            MinimumIntensity.Units=                                         'Normalized';
            MinimumIntensity.Position=                                      [SecondColumn PositionRow1 WidthOfSecondColumnInside ViewHeightInside];

            MaximumIntensityTitle=                                            uicontrol('Style', 'Text');
            MaximumIntensityTitle.Tag=                                   'TextMaximum';
            MaximumIntensityTitle.Units=                                              'Normalized';
            MaximumIntensityTitle.Position=                                           [FirstColumn PositionRow2 WidthOfFirstColumnInside ViewHeightInside];
            MaximumIntensityTitle.String=                                             'Intensity (max):';
            MaximumIntensityTitle.HorizontalAlignment=          'left';

            MaximumIntensity=                                       uicontrol('Style', 'Edit');
            MaximumIntensity.Tag=                                   'MaximumIntensity';
            MaximumIntensity.Units=                                         'Normalized';
            MaximumIntensity.Position=                                      [SecondColumn PositionRow2 WidthOfSecondColumnInside ViewHeightInside];
            
           
            
            ColorTitle=                                              uicontrol('Style', 'Text');
            ColorTitle.Tag=                                          'TextColor';
            ColorTitle.Units=                                        'Normalized';
            ColorTitle.Position=                                     [FirstColumn PositionRow3 WidthOfFirstColumnInside ViewHeightInside];
            ColorTitle.String=                                       {'Channel color:'};
            ColorTitle.HorizontalAlignment=                          'left';
            
                
            Color=                                                  uicontrol('Style', 'Popup');
            Color.Tag=                                              'Color';
            Color.Units=                                            'Normalized';
            Color.Position=                                         [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            Color.String=                                           {'Empty','Red', 'Green', 'Blue', 'Yellow', 'Magenta', 'Cyan', 'White'};
           
          
            CommentTitle=                                            uicontrol('Style', 'Text');
            CommentTitle.Tag=                                            'TextComment';
            CommentTitle.Units=                                      'Normalized';
            CommentTitle.Position=                                   [FirstColumn PositionRow4 WidthOfFirstColumnInside ViewHeightInside];
            CommentTitle.String=                                     'Comment:';
            CommentTitle.HorizontalAlignment=                        'left';

            Comment=                                                uicontrol('Style', 'Edit');
            Comment.Tag=                                            'Comment';
            Comment.Units=                                          'Normalized';
            Comment.Position=                                       [SecondColumn PositionRow4 WidthOfSecondColumnInside ViewHeightInside];

           
            OnOffTitle=                                              uicontrol('Style', 'Text');
            OnOffTitle.Tag=                                        'OnOffComment';
            OnOffTitle.Units=                                     'Normalized';
            OnOffTitle.Position=                                  [FirstColumn PositionRow5 WidthOfFirstColumnInside ViewHeightInside];
            OnOffTitle.String=                                    'Channel on/off:';
            OnOffTitle.HorizontalAlignment=                       'left';


            OnOff=                                                  uicontrol('Style', 'CheckBox');
            OnOff.Tag=                                             'OnOff';
            OnOff.Units=                                            'Normalized';
            OnOff.Position=                                         [SecondColumn PositionRow5 WidthOfSecondColumnInside ViewHeightInside];
            

            obj.Channels.MinimumIntensityTitle =                    MinimumIntensityTitle;
            obj.Channels.MinimumIntensity =                         MinimumIntensity;
            
            obj.Channels.MaximumIntensityTitle =                    MaximumIntensityTitle;
            obj.Channels.MaximumIntensity =                         MaximumIntensity;
            
            obj.Channels.ColorTitle =                               ColorTitle;
            obj.Channels.Color =                                    Color;
            
            obj.Channels.CommentTitle =                             CommentTitle;
            obj.Channels.Comment =                                  Comment;
            
            obj.Channels.OnOffTitle =                               OnOffTitle;
            obj.Channels.OnOff =                                    OnOff;
            
            obj.Channels.SelectedChannelTitle =                     SelectedChannelHandleTitle;
            obj.Channels.SelectedChannel =                          SelectedChannelHandle;
     
            
           
            
        end
      

        function obj = createMovieView(obj,Input)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            
                
                FontSize =                                      20;
                FontColor =                                     [ 0 0.1 0.99];
                TimeColumn =                                    0.1;
                PlaneColumn =                                   0.5;
                ScaleColumn =                                  0.9;
                AnnotationRow =                                 0.2;
            
            
            if ~ishghandle(Input,'axes') 
                
                
                 MovieFigure=                                    Input.Figure;
                 
                 ViewMovieAxes=                           axes;
                    ViewMovieAxes.Tag=                       'ImageAxes';
                    ViewMovieAxes.Position=                  [0 0 1 1];
                    ViewMovieAxes.DataAspectRatioMode=       'manual'; % this can be tricky, maybe better to turn it off and manually correct the x-y ratio for each view?
                 
            else
                MovieFigure =                           Input.Parent;
                ViewMovieAxes =                         Input;
                
            end
            
               
                


                
                obj.Figure.CurrentAxes = ViewMovieAxes;
          
                %% axes image;
               
                
                    
                    ViewMovieAxes.Visible=                   'on';
                    ViewMovieAxes.YDir=                      'reverse';  
                    ViewMovieAxes.XColor =                      'c';
                    ViewMovieAxes.YColor =                      'c';
                    
                    
                %% image and cropping
               
      
                    HandleOfMainImage=                      image;
                    HandleOfMainImage.Tag=                  'ImageOfFigure'; 
                    HandleOfMainImage.Parent=               ViewMovieAxes; % this is a safety thing but may be redundant;

                    handleOfRectangle=                              line;
                    handleOfRectangle.MarkerSize=                   14;
                    handleOfRectangle.Color=                        'w';
                    handleOfRectangle.Tag=                          'ClickedPosition';
                    handleOfRectangle.Parent=                       ViewMovieAxes;
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
                    TimeStampTextHandle.Parent=                     ViewMovieAxes;
                    
                        ZStampTextHandle=                               text(1, 1, '');
                        ZStampTextHandle.FontSize=                      FontSize;
                        ZStampTextHandle.HorizontalAlignment=           'center';
                        ZStampTextHandle.Color=                         FontColor;
                        ZStampTextHandle.Units=                         'normalized';
                        ZStampTextHandle.Position=                      [PlaneColumn AnnotationRow];
                        ZStampTextHandle.Tag=                           'ZStamp';
                        ZStampTextHandle.String=                     'ZStamp';
                        ZStampTextHandle.Parent=                     ViewMovieAxes;
                  
                        ScalebarTextHandle=                         text(1, 1, '');
                        ScalebarTextHandle.FontSize=                FontSize;
                        ScalebarTextHandle.HorizontalAlignment=     'center';
                        ScalebarTextHandle.Color=                   FontColor;
                        ScalebarTextHandle.Units=                   'normalized';
                        ScalebarTextHandle.Tag=                     'ScaleBar';
                        ScalebarTextHandle.Position=                [ScaleColumn AnnotationRow];
                        ScalebarTextHandle.String =                 'Scalebar';
                        ScalebarTextHandle.Parent=                     ViewMovieAxes;
                   


                        %% drift correction and tracking:

                        HandleOfManualDriftCorrectionLine=                          line; 


                         HandleOfManualDriftCorrectionLine.Parent=                   ViewMovieAxes;
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
                         HandleOfCentroidLine.Parent=                   ViewMovieAxes;
                         HandleOfCentroidLine.Marker=                   's';
                         HandleOfCentroidLine.MarkerSize=               8;
                         HandleOfCentroidLine.Color=                    'c';
                         HandleOfCentroidLine.Tag=                      'CentroidLine';
                         HandleOfCentroidLine.LineStyle=                'none';
                         HandleOfCentroidLine.MarkerFaceColor=          'none';
                         HandleOfCentroidLine.MarkerEdgeColor=          'c';
                         HandleOfCentroidLine.LineWidth=                2;
                        HandleOfCentroidLine.Visible =                'off';
                        HandleOfCentroidLine_SelectedTrack=                          line; 


                         HandleOfCentroidLine_SelectedTrack.Parent=                   ViewMovieAxes;
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
                        obj.MovieView.ViewMovieHandle=                   MovieFigure;

                        obj.MovieView.ViewMovieAxes=                     ViewMovieAxes;
                        obj.MovieView.MainImage=                         HandleOfMainImage;
                        obj.MovieView.ScalebarText=                      ScalebarTextHandle;
                        obj.MovieView.TimeStampText=                     TimeStampTextHandle;
                        obj.MovieView.ZStampText=                        ZStampTextHandle;
                        obj.MovieView.ManualDriftCorrectionLine=         HandleOfManualDriftCorrectionLine;
                        obj.MovieView.CentroidLine=                      HandleOfCentroidLine;
                        obj.MovieView.CentroidLine_SelectedTrack=        HandleOfCentroidLine_SelectedTrack;
                        obj.MovieView.Rectangle=                         handleOfRectangle;

                    
            
        end
        
        
          
        
        function obj = CreateAnnotationViews(obj, ProjectViews)
            
              MainWindowNavigationHandle = ProjectViews.Figure;
             figure(MainWindowNavigationHandle)
   
              %% set positions
            
            
            
            ColumnShiftInside =                                             ProjectViews.ColumnShift;
            ViewHeightInside =                                              ProjectViews.ViewHeight;
            WidthOfFirstColumnInside  =                                     ProjectViews.WidthOfFirstColumn;
            WidthOfSecondColumnInside  =                                    ProjectViews.WidthOfSecondColumn;
            
            TopRow =                                                        ProjectViews.StartRowAnnotation;
            RowShiftInside =                                                      ProjectViews.RowShift;
            LeftColumnInside =                                                    ProjectViews.LeftColumn;
            
            
            TitleRow =                                                  TopRow-RowShiftInside;
            PositionRow1 =                                              TopRow-RowShiftInside*2;
            PositionRow2 =                                              TopRow-RowShiftInside*3;
            PositionRow3 =                                              TopRow-RowShiftInside*4;
            PositionRow4 =                                              TopRow-RowShiftInside*5;
            PositionRow5 =                                              TopRow-RowShiftInside*6;
            PositionRow6 =                                              TopRow-RowShiftInside*7;

            
           

            FirstColumn =                                               LeftColumnInside;
            SecondColumn =                                              LeftColumnInside+ColumnShiftInside;
            ThirdColumn =                                               LeftColumnInside+2*ColumnShiftInside;

            
            
            %% get handles with graphics object
           
            ShowScaleBarHandle= uicontrol;
            ShowScaleBarHandle.Tag=                                    'ShowScaleBar';
            ShowScaleBarHandle.Style=                                       'CheckBox';
            ShowScaleBarHandle.Units=                                       'normalized';
            ShowScaleBarHandle.Position=                                    [FirstColumn PositionRow3 WidthOfFirstColumnInside ViewHeightInside];
            ShowScaleBarHandle.String=                                      { 'Scale bar'};

            

          
            SizeOfScaleBarHandle= uicontrol;
            SizeOfScaleBarHandle.Tag=                                  'SizeOfScaleBar';
            SizeOfScaleBarHandle.Style=                                     'PopupMenu';
            SizeOfScaleBarHandle.Units=                                     'normalized';
            SizeOfScaleBarHandle.Position=                                  [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            SizeOfScaleBarHandle.String=                                    1:100;
            SizeOfScaleBarHandle.Value=                                     50;

            obj.Annotation.ShowScaleBar=                                ShowScaleBarHandle;
            obj.Annotation.SizeOfScaleBar=                              SizeOfScaleBarHandle;

            
               
            
        end
        
        
        function obj = resetNavigationFontSize(obj, FontSize)
            
            
               obj.MovieView.ScalebarText.FontSize = FontSize;
               obj.MovieView.TimeStampText.FontSize = FontSize;
               obj.MovieView.ZStampText.FontSize = FontSize;
               
               
  

      
            
            
            
            
        end
    
        
        
     
        
        
        function obj = blackOutMovieView(obj)
            
            obj.MovieView.MainImage.CData(:) =                      0;
            obj.MovieView.ZStampText.String =                       '';
            
            obj.MovieView.TimeStampText.String =                    '';
            obj.MovieView.ScalebarText.String =                     '';
            obj.MovieView.CentroidLine.Visible =                    'off';
            obj.MovieView.CentroidLine_SelectedTrack.Visible =      'off';
            obj.MovieView.Rectangle.Visible =                       'off';
            obj.MovieView.ManualDriftCorrectionLine.Visible =       'off';
            
            
        end
        
        
        function obj = reverseBlackOut(obj)   
           
            obj.MovieView.CentroidLine.Visible =                    'on';
            obj.MovieView.CentroidLine_SelectedTrack.Visible =      'on';
            obj.MovieView.Rectangle.Visible =                       'on';
            obj.MovieView.ManualDriftCorrectionLine.Visible =       'on';
            
        end

    end
    
end

