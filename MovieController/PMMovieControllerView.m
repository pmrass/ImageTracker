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
         
        ListOfTrackViews =          cell(0,1)
        
        BackgroundColor =           [0 0.1 0.2];
        ForegroundColor =           'c';
        
        EditingType 
        
    end
    
    properties (Constant, Access = private)
        ChannelFilterTypes = {'Raw','Median filter', 'Complex filter'};
        ChannelFilterTypes_MovieTracking =  {'Raw', 'Median', 'Complex'};
    end
    
    methods
        
        function obj = PMMovieControllerView(Input)
            %PMMOVIECONTROLLERVIEW Construct an instance of this class
            %   Creation of views that support navigating through the loaded image-sequences;

            
            if ishghandle(Input,'axes') % if the input is only the axes;
                
                obj.Figure =           Input.Parent;  
                
                obj =                   obj.createMovieView(Input);
                
            else % if input is the project view: create more views and put them in relation to the whole project window;
            
            
                obj =                   obj.CreateNavigationViews(Input);
                obj =                   obj.CreateChannelViews(Input);
                obj =                   obj.CreateAnnotationViews(Input);
                obj =                   obj.createMovieView(Input);
               
            
            end
      
        end
        
     
        function ChannelReconstructionType = getFilterTypeOfSelectedChannel(obj)
            ChannelReconstructionType =                 obj.ChannelFilterTypes_MovieTracking{obj.Channels.ChannelReconstruction.Value};
            
        end
        
        function    obj =   resetChannelViewsByMovieTracking(obj, MovieTracking)
            if isempty(obj.Channels) || isempty(MovieTracking.Channels)
            else
                
              
                
                obj.Channels.SelectedChannel.String =                        1 : MovieTracking.getMaxChannel;
                obj.Channels.SelectedChannel.Value =                  MovieTracking.getIndexOfActiveChannel;
                obj.Channels.MinimumIntensity.String =                MovieTracking.getIntensityLowOfActiveChannel;
                obj.Channels.MaximumIntensity.String =                MovieTracking.getIntensityHighOfActiveChannel;
                obj.Channels.Color.Value =                            find(strcmp(MovieTracking.getColorStringOfActiveChannel, obj.Channels.Color.String));
                obj.Channels.Comment.String =                         MovieTracking.getCommentOfActiveChannel;
                obj.Channels.OnOff.Value =                            MovieTracking.getVisibleOfActiveChannel;
                
                obj.Channels.ChannelReconstruction.Value =         obj.getActiveChannelReconstructionIndexFromMovieTracking(MovieTracking);
                
               
            end
        
                
        end
        
    
        
        function Index = getActiveChannelReconstructionIndexFromMovieTracking(obj, MovieTracking)
            Index = find(strcmp(MovieTracking.getReconstructionTypeOfActiveChannel, obj.ChannelFilterTypes_MovieTracking));
            if isempty(Index)
               Index = 1; 
            end
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
            obj.MovieView.ScaleBarLine.Visible =                    'off';
            
            obj.MovieView.CentroidLine.Visible =                    'off';
            obj.MovieView.CentroidLine_SelectedTrack.Visible =      'off';
            obj.MovieView.Rectangle.Visible =                       'off';
            obj.MovieView.ManualDriftCorrectionLine.Visible =       'off';
            
            
        end
        
        function obj = setMaxTime(obj, Value)
                obj.Navigation.CurrentTimePoint.String =          1 : Value; 
                if obj.Navigation.CurrentTimePoint.Value<1 || obj.Navigation.CurrentTimePoint.Value>length(obj.Navigation.CurrentTimePoint.String)
                    obj.Navigation.CurrentTimePoint.Value = 1;
                end


                Range = obj.Navigation.TimeSlider.Max -   obj.Navigation.TimeSlider.Min;
                if Range == 0
                obj.Navigation.TimeSlider.Visible = 'off';
                else
                  Step =     1/ (Range);
                  obj.Navigation.TimeSlider.Visible = 'on';
                  obj.Navigation.TimeSlider.SliderStep = [Step Step];
                end

                obj.Navigation.TimeSlider.Min =                 1;
                obj.Navigation.TimeSlider.Max =                 Value;  
            
        end
        
        function obj = setEditingTypeToIndex(obj, Value)
            
             obj.Navigation.EditingOptions.Value =          Value;
                switch Value
                    case 1 % 'Visualize'
                        obj.MovieView.ManualDriftCorrectionLine.Visible = 'off';
                    case 2
                        obj.MovieView.ManualDriftCorrectionLine.Visible = 'on';
                    case 3 %  'Tracking: draw mask'
                        obj.MovieView.ManualDriftCorrectionLine.Visible = 'off';
                end
            
        end
        
          function obj = setScaleBarVisibility(obj, ScaleBarVisible)
             switch ScaleBarVisible
                  case 1
                      obj.MovieView.ScaleBarLine.Visible = 'on';
                      obj.MovieView.ScalebarText.Visible =        'on';
                 otherwise
                      obj.MovieView.ScalebarText.Visible = 'off';
                      obj.MovieView.ScaleBarLine.Visible = 'off';   
             end 
          end
        
          
          function obj = setScaleBarSize(obj, VoxelSizeXuM)
              

            obj.MovieView.ScalebarText.Units =          'centimeters';
                     

            obj.MovieView.ViewMovieAxes.Units =         'centimeters';
            AxesWidthCentimeter =                             obj.MovieView.ViewMovieAxes.Position(3);
            AxesHeightCentimeter =                            obj.MovieView.ViewMovieAxes.Position(4);
            obj.MovieView.ViewMovieAxes.Units =         'pixels';

            WantedLeftPosition =                              obj.MovieView.ScalebarText.Position(1);
            WantedCentimeters =                               0.9;

            RelativeLeftPosition =            WantedLeftPosition / AxesWidthCentimeter;
            AxesWidthPixels =                 diff(obj.MovieView.ViewMovieAxes.XLim);
            XLimWidth =                       AxesWidthPixels * RelativeLeftPosition;
            XLimStart =                       obj.MovieView.ViewMovieAxes.XLim(1);
            XLimMiddleBar =                    XLimStart + XLimWidth;

            AxesHeightPixels =            diff(obj.MovieView.ViewMovieAxes.YLim);


            if AxesWidthPixels>AxesHeightPixels
            RealAxesHeightCentimeter = AxesHeightCentimeter * AxesHeightPixels/ AxesWidthPixels;

            else
            RealAxesHeightCentimeter = AxesHeightCentimeter;
            end


            PixelsPerCentimeter =              AxesHeightPixels / RealAxesHeightCentimeter;
            PixelsForWantedCentimeters =      PixelsPerCentimeter * WantedCentimeters;
            YLimStart =                       obj.MovieView.ViewMovieAxes.YLim(2) - PixelsForWantedCentimeters;

            if isfield(obj.Annotation, 'SizeOfScaleBar') && isfield(obj.Annotation.SizeOfScaleBar, 'Value')
                LengthInMicrometer = obj.Annotation.SizeOfScaleBar.Value;
            else
                LengthInMicrometer = 50;
            end




            LengthInPixels =      LengthInMicrometer / VoxelSizeXuM;

            obj.MovieView.ScaleBarLine.Marker = 'none';
            obj.MovieView.ScaleBarLine.XData = [(XLimMiddleBar - LengthInPixels/2), (XLimMiddleBar +  LengthInPixels/2) ];
            obj.MovieView.ScaleBarLine.YData = [ YLimStart, YLimStart];



                      
                      
            obj.MovieView.ScalebarText.String =         strcat(num2str(VoxelSizeXuM), ' µm');
              
              
              
              
              
          end
          
          
        %% still need to adjust after moving from controller
        
     
            
          
           
          function [obj] =        addMissingTrackLineViews(obj, allTrackIdsInModel)
                 
   
                function TrackLine = setTagOfTrackLines(TrackLine, TrackLineNumber)
                    TrackLine.Tag = num2str(TrackLineNumber);
                 end
                
                rowsOfMissingTrackIDs = ~ismember(allTrackIdsInModel, obj.getIdsFromTrackHandles( obj.ListOfTrackViews));
                missingTrackIds =       allTrackIdsInModel(rowsOfMissingTrackIDs);

                if isempty(missingTrackIds)
                else
                    CellWithNewLineHandles =    (arrayfun(@(x) line(obj.MovieView.ViewMovieAxes), 1:length(missingTrackIds), 'UniformOutput', false))';
                    CellWithNewLineHandles =    cellfun(@(x,y) setTagOfTrackLines(x,y), CellWithNewLineHandles, num2cell(missingTrackIds), 'UniformOutput', false);
                    obj.ListOfTrackViews =      [obj.ListOfTrackViews; CellWithNewLineHandles];   
                end
                
              
          end
          
           function [obj] =       deleteNonMatchingTrackLineViews(obj, TrackNumbers)
                if isempty(TrackNumbers)
                    obj =           obj.deleteAllTrackLineViews;
                else                    
                    rowsThatMustBeDeleted =       ~ismember(obj.getTrackIdsOfTrackHandles, TrackNumbers);
                    cellfun(@(x) delete(x), obj.ListOfTrackViews(rowsThatMustBeDeleted))
                    obj.ListOfTrackViews(rowsThatMustBeDeleted,:) = [];
                end
                    
           end
           
          
           
        function TrackHandles =          getHandlesForTrackIDs(obj, TrackID)
            if isempty(TrackID)
                TrackHandles = cell(0,1);
            else
                TrackHandles =      obj.ListOfTrackViews(ismember(obj.getTrackIdsOfTrackHandles,  TrackID), :);
            end    
        end
        
        function ListWithTrackIDsThatHaveAHandle =     getTrackIdsOfTrackHandles(obj)
             ListWithTrackIDsThatHaveAHandle =           cellfun(@(x) str2double(x.Tag), obj.ListOfTrackViews); 
        end
        
         function ListWithTrackIDsThatAlreadyHaveAHandle   =        getIdsFromTrackHandles(~, ListWithWithCurrentTrackHandles)
              ListWithTrackIDsThatAlreadyHaveAHandle =               cellfun(@(x) str2double(x.Tag), ListWithWithCurrentTrackHandles);
         end
        
          function                                    updateTrackLineCoordinatesForHandle(~, HandleForCurrentTrack, Coordinates)
            if isempty(Coordinates)
                Coordinates = [0, 0, 0];
            else
                    Coordinates=      cell2mat(Coordinates);
            end
                HandleForCurrentTrack.XData=            Coordinates(:, 1);    
                HandleForCurrentTrack.YData=            Coordinates(:, 2);  
                HandleForCurrentTrack.ZData=            Coordinates(:, 3);  
                HandleForCurrentTrack.Color=            'w';  
          end
          
          
          
          
         
        function [obj] =                            deleteAllTrackLineViews(obj)
            
            fprintf('PMMovieController:@deleteAllTrackLineViews: find all currently existing track lines and deleted them.\n')
            AllLines =           findobj(obj.MovieView.ViewMovieAxes, 'Type', 'Line');
            TrackLineRows  =     arrayfun(@(x) ~isnan(str2double(x.Tag)), AllLines);
            TrackLines=          AllLines(TrackLineRows,:);
            if ~isempty(TrackLines)
                arrayfun(@(x) delete(x),  TrackLines);
            end
            obj.ListOfTrackViews =  cell(0,1);
            
        end
        
        
          function obj = changeAppearance(obj)
            fprintf('PMMovieController:@changeAppearance: change foreground and background of view ')
            
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                fprintf('%i of % %i ', CurrentIndex, NumberOfViews)
                if strcmp(ListWithAllViews{CurrentIndex,1}.Style, 'popupmenu')
                    ListWithAllViews{CurrentIndex,1}.ForegroundColor = 'r';
                else
                    ListWithAllViews{CurrentIndex,1}.ForegroundColor =      obj.ForegroundColor;
                end
                ListWithAllViews{CurrentIndex,1}.BackgroundColor =       obj.BackgroundColor;
            end
            fprintf('\n')
            
        end
        
        function obj = disableViews(obj)
            
             [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                if ~isempty(ListWithAllViews{CurrentIndex,1}.Callback)
                    ListWithAllViews{CurrentIndex,1}.Enable = 'off';
                end
               
            end

        end
        
        
        
        
        function obj = disableAllViews(obj)
            
            fprintf('PMMovieController:@disableAllViews ')
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                
                fprintf('%i of %i ', CurrentIndex, NumberOfViews)
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                CurrentView.Enable = 'off';
                
            end
            fprintf('\n')
            
        end
        
        function obj = enableAllViews(obj)
            
            [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                CurrentView.Enable = 'on';
                
            end
            
            
        end
        
%         
        
         function obj = enableViews(obj)
             [ListWithAllViews] =               obj.getListWithAllViews;
            NumberOfViews = size(ListWithAllViews,1);
            for CurrentIndex=1:NumberOfViews
                CurrentView =   ListWithAllViews{CurrentIndex,1};
                if ~isempty(CurrentView.Callback)
                    CurrentView.Enable = 'on';
                end
               
            end

         end
         
         
         
          function [ListWithAllViews] =                                       getListWithAllViews(obj)


                if isempty(obj.Navigation)
                    ListWithAllViews =       cell(0,1);
                    return
                elseif isempty(obj.Channels)
                    ListWithAllViews =       cell(0,1);
                    return
                end

                FieldNames =                fieldnames(obj.Navigation);
                NavigationViews =           cellfun(@(x) obj.Navigation.(x), FieldNames, 'UniformOutput', false);

                FieldNames =                fieldnames(obj.Channels);
                ChannelViews =              cellfun(@(x) obj.Channels.(x), FieldNames, 'UniformOutput', false);

                FieldNames =                fieldnames(obj.Annotation);
                AnnotationViews =           cellfun(@(x) obj.Annotation.(x), FieldNames, 'UniformOutput', false);

               
                ListWithAllViews =          [NavigationViews; ChannelViews;AnnotationViews];

          end
        
         
        function string = getEditingType(obj)
              input =                        obj.Navigation.EditingOptions.String{obj.Navigation.EditingOptions.Value};
                 switch input
                    case 'Viewing only' % 'Visualize'
                        string =                                   'No editing';
                    case 'Edit manual drift correction'
                        string =                                   'Manual drift correction';
                    case 'Edit tracks' %  'Tracking: draw mask'
                        string =                                'Tracking';
                end
        
            
        end
          
        
        

    end
    
    methods (Access = private)
        
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
            CurrentTimePoint.String =                                               'Empty';
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
                 CurrentPlane.String =                                               'Empty';
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
            SelectedChannelHandleTitle.HorizontalAlignment=                     'left';
            
           

            SelectedChannelHandle=                                              uicontrol;
            SelectedChannelHandle.Style=                                        'PopupMenu';
                 SelectedChannelHandle.String =                                               'Empty';
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
            
            
            ChannelReconstructionTitle=                                              uicontrol('Style', 'Text');
            ChannelReconstructionTitle.Tag=                                        'ChannelReconstructionTitle';
            ChannelReconstructionTitle.Units=                                     'Normalized';
            ChannelReconstructionTitle.Position=                                  [FirstColumn PositionRow6 WidthOfFirstColumnInside ViewHeightInside];
            ChannelReconstructionTitle.String=                                    'Image reconstruction type:';
            ChannelReconstructionTitle.HorizontalAlignment=                       'left';


            
              ChannelReconstructionHandle=                                                  uicontrol('Style', 'Popup');
            ChannelReconstructionHandle.Tag=                                              'ChannelReconstruction';
            ChannelReconstructionHandle.Units=                                            'Normalized';
            ChannelReconstructionHandle.Position=                                         [SecondColumn PositionRow6 WidthOfSecondColumnInside ViewHeightInside];
            ChannelReconstructionHandle.String=                                           obj.ChannelFilterTypes;
           
            

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
            
            obj.Channels.ChannelReconstruction =                          ChannelReconstructionHandle;
     
            
           
            
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
                   
                        
                          ScaleBarLineHandle=                          line; 
                         ScaleBarLineHandle.Parent=                   ViewMovieAxes;
                         ScaleBarLineHandle.Marker=                   's';
                         ScaleBarLineHandle.MarkerSize=               8;
                         ScaleBarLineHandle.Color=                    'w';
                         ScaleBarLineHandle.Tag=                      'ScaleBarLineHandle';
                         ScaleBarLineHandle.LineStyle=                '-';
                         ScaleBarLineHandle.MarkerFaceColor=          'none';
                         ScaleBarLineHandle.MarkerEdgeColor=          'w';
                         ScaleBarLineHandle.LineWidth=                3;
                        ScaleBarLineHandle.Visible =                'off';
                      


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
                         HandleOfCentroidLine.Marker=                   'x';
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
                        obj.MovieView.ScaleBarLine=                      ScaleBarLineHandle;
                        
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
             SizeOfScaleBarHandle.String=                                     'Empty';
            SizeOfScaleBarHandle.Units=                                     'normalized';
            SizeOfScaleBarHandle.Position=                                  [SecondColumn PositionRow3 WidthOfSecondColumnInside ViewHeightInside];
            SizeOfScaleBarHandle.String=                                    1:100;
            SizeOfScaleBarHandle.Value=                                     50;

            obj.Annotation.ShowScaleBar=                                ShowScaleBarHandle;
            obj.Annotation.SizeOfScaleBar=                              SizeOfScaleBarHandle;

            
               
            
        end
        
    end
    
end

