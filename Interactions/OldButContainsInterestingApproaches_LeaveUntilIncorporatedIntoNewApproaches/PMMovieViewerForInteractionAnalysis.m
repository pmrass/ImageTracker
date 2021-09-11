classdef PMMovieViewerForInteractionAnalysis
    %PMMOVIEVIEWERFORINTERACTIONANALYSIS visualization of movie plus interaction analysis-data;
    %   Detailed explanation goes here
    
    properties
        
        SimpleMovieView
        InteractionViews
        
    end
    
    methods
        
        function obj = PMMovieViewerForInteractionAnalysis(SimpleMovie)
            %PMMOVIEVIEWERFORINTERACTIONANALYSIS Construct an instance of this class
            %   Detailed explanation goes here
            
            obj.SimpleMovieView =                                       SimpleMovie;
            
            obj.InteractionViews.LabelAxes =                                axes;
            obj.InteractionViews.LabelAxes.Position =                       [0 0 1 1];
            obj.InteractionViews.LabelAxes.Units =                          'pixels';
            obj.InteractionViews.LabelAxes.Color =                          'k';
            uistack(obj.InteractionViews.LabelAxes,'bottom');

            
            %% general legend-view variables:
            FontSize =                                          12;

            TopRow =                                            150;
            ShiftBetweenRows =                                  20;

            FirstColumn =                                       20;
            SecondColumn =                                      300;

            MotilityColor =                                     [0 1 0.8];
            InteractionColor =                                  [1 0.2 0.4];

            %% views for motility:

            obj.InteractionViews.MotilityNameHandle =                               text;

            obj.InteractionViews.MotilityNameHandle.Color =                         'w';
            obj.InteractionViews.MotilityNameHandle.FontWeight =                    'bold';
            obj.InteractionViews.MotilityNameHandle.Units =                         'pixels';
            obj.InteractionViews.MotilityNameHandle.Position =                      [FirstColumn, TopRow-ShiftBetweenRows*0, 0];
            obj.InteractionViews.MotilityNameHandle.FontSize =                      FontSize;   


            obj.InteractionViews.MotilityTitleHandle =                               text;
            obj.InteractionViews.MotilityTitleHandle.String =                        'Motility parameters:';
            obj.InteractionViews.MotilityTitleHandle.Color =                         MotilityColor;
            obj.InteractionViews.MotilityTitleHandle.FontWeight =                    'bold';
            obj.InteractionViews.MotilityTitleHandle.Units =                         'pixels';
            obj.InteractionViews.MotilityTitleHandle.Position =                      [FirstColumn, TopRow-ShiftBetweenRows*1, 0];
            obj.InteractionViews.MotilityTitleHandle.FontSize =                      FontSize;

            obj.InteractionViews.FrameHandle =                                       text;
            obj.InteractionViews.FrameHandle.String =                                'Frames ';
            obj.InteractionViews.FrameHandle.Color =                                  MotilityColor;
            obj.InteractionViews.FrameHandle.Units =                                 'pixels';
            obj.InteractionViews.FrameHandle.Position =                              [FirstColumn, TopRow-ShiftBetweenRows*2, 0];
            obj.InteractionViews.FrameHandle.FontSize =                              FontSize;

            obj.InteractionViews.PlaneHandle =                                       text;
            obj.InteractionViews.PlaneHandle.String =                                'Z-depth';
            obj.InteractionViews.PlaneHandle.Color =                                 MotilityColor;
            obj.InteractionViews.PlaneHandle.Units =                                 'pixels';
            obj.InteractionViews.PlaneHandle.Position =                              [FirstColumn, TopRow-ShiftBetweenRows*3, 0];
            obj.InteractionViews.PlaneHandle.FontSize =                              FontSize;

            obj.InteractionViews.SpeedHandle =                                       text;
            obj.InteractionViews.SpeedHandle.String =                                'Speed = ';
            obj.InteractionViews.SpeedHandle.Color =                                 MotilityColor;
            obj.InteractionViews.SpeedHandle.Units =                                 'pixels';
            obj.InteractionViews.SpeedHandle.Position =                              [FirstColumn, TopRow-ShiftBetweenRows*4, 0];
            obj.InteractionViews.SpeedHandle.FontSize =                              FontSize;

            obj.InteractionViews.TurningAngleHandle =                                text;
            obj.InteractionViews.TurningAngleHandle.String =                         'Turning angle = ';
            obj.InteractionViews.TurningAngleHandle.Color =                          MotilityColor;
            obj.InteractionViews.TurningAngleHandle.Units =                          'pixels';
            obj.InteractionViews.TurningAngleHandle.Position =                       [FirstColumn, TopRow-ShiftBetweenRows*5, 0];
            obj.InteractionViews.TurningAngleHandle.FontSize =                       FontSize;

            obj.InteractionViews.NumberOfRevisitsHandle =                            text;
            obj.InteractionViews.NumberOfRevisitsHandle.String =                     'Revisits =';
            obj.InteractionViews.NumberOfRevisitsHandle.Color =                      MotilityColor;
            obj.InteractionViews.NumberOfRevisitsHandle.Units =                      'pixels';
            obj.InteractionViews.NumberOfRevisitsHandle.Position =                   [FirstColumn, TopRow-ShiftBetweenRows*6, 0];
            obj.InteractionViews.NumberOfRevisitsHandle.FontSize =                   FontSize;

            %% views for interaction:
            obj.InteractionViews.InteractionTitleHandle =                               text;
            obj.InteractionViews.InteractionTitleHandle.String =                        'Interaction parameters:';
            obj.InteractionViews.InteractionTitleHandle.Color =                         InteractionColor;
            obj.InteractionViews.InteractionTitleHandle.FontWeight =                    'bold';
            obj.InteractionViews.InteractionTitleHandle.Units =                         'pixels';
            obj.InteractionViews.InteractionTitleHandle.Position =                      [SecondColumn, TopRow-ShiftBetweenRows*1, 0];
            obj.InteractionViews.InteractionTitleHandle.FontSize =                      FontSize;


            obj.InteractionViews.SynapseIntensityHandle =                            text;
            obj.InteractionViews.SynapseIntensityHandle.String =                     'Synapse intensity =';
            obj.InteractionViews.SynapseIntensityHandle.Color =                      InteractionColor;
            obj.InteractionViews.SynapseIntensityHandle.Units =                      'pixels';
            obj.InteractionViews.SynapseIntensityHandle.Position =                   [SecondColumn, TopRow-ShiftBetweenRows*2, 0];
            obj.InteractionViews.SynapseIntensityHandle.FontSize =                   FontSize;

            obj.InteractionViews.SynapseMeanDevHandle =                               text;
            obj.InteractionViews.SynapseMeanDevHandle.String =                        'Synapse mean deviation =';
            obj.InteractionViews.SynapseMeanDevHandle.Color =                         InteractionColor;
            obj.InteractionViews.SynapseMeanDevHandle.Units =                         'pixels';
            obj.InteractionViews.SynapseMeanDevHandle.Position =                      [SecondColumn, TopRow-ShiftBetweenRows*3, 0];
            obj.InteractionViews.SynapseMeanDevHandle.FontSize =                      FontSize;



            obj.InteractionViews.SynapseStdHandle =                               text;
            obj.InteractionViews.SynapseStdHandle.String =                        'Standard deviation =';
            obj.InteractionViews.SynapseStdHandle.Color =                         InteractionColor;
            obj.InteractionViews.SynapseStdHandle.Units =                         'pixels';
            obj.InteractionViews.SynapseStdHandle.Position =                      [SecondColumn, TopRow-ShiftBetweenRows*4, 0];
            obj.InteractionViews.SynapseStdHandle.FontSize =                      FontSize;


            obj.InteractionViews.SynapseZScoreHandle =                               text;
            obj.InteractionViews.SynapseZScoreHandle.String =                        'Synapse Z-score =';
            obj.InteractionViews.SynapseZScoreHandle.Color =                         InteractionColor;
            obj.InteractionViews.SynapseZScoreHandle.Units =                         'pixels';
            obj.InteractionViews.SynapseZScoreHandle.Position =                      [SecondColumn, TopRow-ShiftBetweenRows*5, 0];
            obj.InteractionViews.SynapseZScoreHandle.FontSize =                      FontSize;




            %% format movie-axes:


            AxesHeight =                                                        0.7;
            FigureHeight =                                                      0.7;


            obj.InteractionViews.ViewMovieHandle.Units =                                'normalized';
            obj.InteractionViews.ViewMovieHandle.Position =                             [0 0 FigureHeight FigureHeight];


            obj.SimpleMovieView.Axes.Position =                                         [0, 1-AxesHeight, 1, AxesHeight];


            obj.InteractionViews.LineWithCompleteTrack =                                                 line;
            obj.InteractionViews.LineWithCompleteTrack.Color =                                           'g';
            obj.InteractionViews.LineWithCompleteTrack.Parent =                                          obj.SimpleMovieView.Axes;

            obj.InteractionViews.LineWithCurrentTrack =                                                  line;
            obj.InteractionViews.LineWithCurrentTrack.LineWidth =                                        4;
            obj.InteractionViews.LineWithCurrentTrack.Marker =                                           'x';
            obj.InteractionViews.LineWithCurrentTrack.Color =                                            'w';
            obj.InteractionViews.LineWithCurrentTrack.MarkerSize =                                       18;
            obj.InteractionViews.LineWithCurrentTrack.Parent =                                           obj.SimpleMovieView.Axes;

    
        end
        
        
        function obj =                              ApplyModel(obj, Model)
            
            
                %% reading data:
                AxesHeight =                                                            0.7;
                XCordinates =                                                           Model.XCoordinates{Model.SelectedTrackRow,1};
                YCoordinates =                                                          Model.YCoordinates{Model.SelectedTrackRow,1};
                ZCordinates =                                                           Model.ZCoordinates{Model.SelectedTrackRow,1};

                MovieName =                                                             Model.MovieTrackingObject.NickName;
                
                IDOfActiveTrack =                                                       Model.MovieTrackingObject.TrackCell{Model.SelectedTrackRow,1}{1,2};
                
                %% processing data
                MinimumYOfTrack =                                                      min(YCoordinates);
                MaximumYOfTrack =                                                      max(YCoordinates);

                MinimumXOfTrack=                                                       min(XCordinates);
                MaximumXOfTrack=                                                       max(XCordinates);

                
                
                % label title handle:
                
                MovieName(MovieName=='_')=                                          ' ';
                ProcessedMovieName =                                                sprintf('Movie: %s, Track%i', MovieName, IDOfActiveTrack);
                
                ExtraSpace =                                                        20;
                AxesAspectRatio =                                                   ( MaximumXOfTrack- MinimumXOfTrack + 2 * ExtraSpace)/(MaximumYOfTrack-MinimumYOfTrack+ 2* ExtraSpace);


                obj.SimpleMovieView.Figure.Units =                                  'pixels';
                FigureHeightPixels =                                                obj.SimpleMovieView.Figure.Position(4);
                FigureWidthPixels =                                                 AxesHeight*FigureHeightPixels*AxesAspectRatio;
                
                
                %% applying data:
                obj.SimpleMovieView.Figure.Position =                           [0 0 FigureWidthPixels FigureHeightPixels];
                obj.SimpleMovieView.Figure.Resize =                             'off';

                MinimumWidthForFigure =                                             640;
                if obj.SimpleMovieView.Figure.Position(3)<MinimumWidthForFigure
                    obj.SimpleMovieView.Figure.Position(3) =                        MinimumWidthForFigure;
                end

                
                obj.SimpleMovieView.Axes.Units =                              'pixels'; % reset units to pixel so that after that view can be resized without changing axes;
                obj.SimpleMovieView.Axes.XLim =                               [MinimumXOfTrack-ExtraSpace MaximumXOfTrack+ExtraSpace];
                obj.SimpleMovieView.Axes.YLim =                               [MinimumYOfTrack-ExtraSpace MaximumYOfTrack+ExtraSpace];

                obj.InteractionViews.MotilityNameHandle.String =                     ProcessedMovieName;   

                obj.InteractionViews.LineWithCompleteTrack.XData =                      XCordinates;
                obj.InteractionViews.LineWithCompleteTrack.YData =                      YCoordinates;

                
            
        end
       
        function obj =                               applyTrackingCell(obj, Cell)
            
            
             %% update label-views:

             
             %obj.InteractionViews.LineWithCurrentTrack
             %obj.InteractionViews.LabelAxes
             %obj.InteractionViews.MotilityNameHandle
            
             %obj.InteractionViews.MotilityTitleHandle
             obj.InteractionViews.FrameHandle.String =                                      sprintf('Visit index %i of %i', Cell.PositionIndex, Cell.NumberOfPositions);
             obj.InteractionViews.PlaneHandle.String =                                      sprintf('Visit index %i', Cell.PositionIndex);
             obj.InteractionViews.SpeedHandle.String =                                      sprintf('Visit index %i', Cell.PositionIndex);
             obj.InteractionViews.TurningAngleHandle.String =                               sprintf('Visit index %i', Cell.PositionIndex);
             obj.InteractionViews.NumberOfRevisitsHandle.String =                                   sprintf('Visit index %i', Cell.PositionIndex);
             
             %obj.InteractionViews.InteractionTitleHandle
             obj.InteractionViews.SynapseIntensityHandle.String =                                   sprintf('Visit index %i', Cell.PositionIndex);
             obj.InteractionViews.SynapseMeanDevHandle.String =                                   sprintf('Visit index %i', Cell.PositionIndex);
             obj.InteractionViews.SynapseStdHandle.String =                                   sprintf('Visit index %i', Cell.PositionIndex);
             obj.InteractionViews.SynapseZScoreHandle.String =                                   sprintf('Visit index %i', Cell.PositionIndex);
            
             obj.InteractionViews.ViewMovieHandle
             obj.InteractionViews.LineWithCompleteTrack

%             ViewMovieHandles.FrameHandle.String =                                   sprintf('Revisit index %i', RevisitPositionIndex);
%             ViewMovieHandles.PlaneHandle.String =                                   sprintf('Relative frame: %i of %i', RevisitIndex, NumberOfRevisits);
%             ViewMovieHandles.SpeedHandle.String =                                   sprintf('Absolute frame: %i (%s) ', round(FrameIndex), StartTimeString);
%             ViewMovieHandles.TurningAngleHandle.String =                            sprintf('%s', StringForZPosition);
%             ViewMovieHandles.NumberOfRevisitsHandle.String =                        sprintf('');
%             ViewMovieHandles.NumberOfRevisitsHandle.String =                        sprintf('');
%             ViewMovieHandles.NumberOfRevisitsHandle.String =                        sprintf('');
% 
%             ViewMovieHandles.SynapseIntensityHandle.String =                        sprintf('Current synapse intensity = %4.2f arbitrary units', SynapseIntensity);
%             ViewMovieHandles.SynapseMeanDevHandle.String =                          sprintf('Median synapse intensity frame %i to %i = %4.2f arbitrary units', RevisitIndex, NumberOfRevisits, median(IntensityList));
%             ViewMovieHandles.SynapseStdHandle.String =                              sprintf('');
%             ViewMovieHandles.SynapseZScoreHandle.String =                           sprintf('');
% 
% 
%             %% create image then add to view:
% 
%             ViewMovieHandles.MainImage.CData=                                       ThreeChannelExportVolume;
% 
%             %% update tracks in view:
%             ViewMovieHandles.LineWithCurrentTrack.XData =                           XCordinates;
%             ViewMovieHandles.LineWithCurrentTrack.YData =                           YCoordinates;

            %% update views and capture frame for movie:
            drawnow
            
        end
        
        
        
        function obj =                              UpdateViewWithModel(ViewMovieHandles, MovieModel, ImageVolume_CurrentFrame_SelectedPlanes, ResultsForView)


            %% extract data:
            SynapseIntensity =                                                      ResultsForView.SynapseIntensity;
            SynapseIntensityArray =                                                  ResultsForView.SynapseIntensityArray;
            PixelList_OutsideSynapse =                                              ResultsForView.PixelList_OutsideSynapse;
            PixelList_InsideSynapse =                                               ResultsForView.PixelList_InsideSynapse;                          



            IntensityList =                                                         ResultsForView.SynapseIntensityArray(1:ResultsForView.RevisitIndex);

            RevisitPositionIndex=                                                   ResultsForView.RevisitPositionIndex;

            RevisitIndex=                                                           ResultsForView.RevisitIndex;

            NumberOfRevisits=                                                       ResultsForView.NumberOfRevisits;
            XCordinates =                                                           ResultsForView.XCordinates;
            YCoordinates =                                                          ResultsForView.YCoordinates;

            FrameIndex =                                                            ResultsForView.FrameIndex;

            %% process data:
             [StringForZPosition] =                                                 MovieModel_ExtractPlaneString(MovieModel);
            StartTimeString =                                                       MetaData_ExtractTimeString(MovieModel.MetaData, FrameIndex);

            [ ThreeChannelExportVolume ] =                                          ConvertIntoRGBVolume(ImageVolume_CurrentFrame_SelectedPlanes, MovieModel);
            [ThreeChannelExportVolume] =                                            AddMaskToImage(ThreeChannelExportVolume, PixelList_InsideSynapse, [NaN NaN 150]);
            [ThreeChannelExportVolume] =                                            AddMaskToImage(ThreeChannelExportVolume, PixelList_OutsideSynapse, [250 250 250]);


            %% update label-views:


            ViewMovieHandles.FrameHandle.String =                                   sprintf('Revisit index %i', RevisitPositionIndex);
            ViewMovieHandles.PlaneHandle.String =                                   sprintf('Relative frame: %i of %i', RevisitIndex, NumberOfRevisits);
            ViewMovieHandles.SpeedHandle.String =                                   sprintf('Absolute frame: %i (%s) ', round(FrameIndex), StartTimeString);
            ViewMovieHandles.TurningAngleHandle.String =                            sprintf('%s', StringForZPosition);
            ViewMovieHandles.NumberOfRevisitsHandle.String =                        sprintf('');
            ViewMovieHandles.NumberOfRevisitsHandle.String =                        sprintf('');
            ViewMovieHandles.NumberOfRevisitsHandle.String =                        sprintf('');

            ViewMovieHandles.SynapseIntensityHandle.String =                        sprintf('Current synapse intensity = %4.2f arbitrary units', SynapseIntensity);
            ViewMovieHandles.SynapseMeanDevHandle.String =                          sprintf('Median synapse intensity frame %i to %i = %4.2f arbitrary units', RevisitIndex, NumberOfRevisits, median(IntensityList));
            ViewMovieHandles.SynapseStdHandle.String =                              sprintf('');
            ViewMovieHandles.SynapseZScoreHandle.String =                           sprintf('');


            %% create image then add to view:

            ViewMovieHandles.MainImage.CData=                                       ThreeChannelExportVolume;

            %% update tracks in view:
            ViewMovieHandles.LineWithCurrentTrack.XData =                           XCordinates;
            ViewMovieHandles.LineWithCurrentTrack.YData =                           YCoordinates;

            %% update views and capture frame for movie:
            drawnow

        end

        
    end
end

