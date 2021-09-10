classdef PMTrackingInteractionManager
    %PMTRACKINGOVERLAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        MovieTrackingObject
        
        Settings
        SelectedTrackRow =  1
        NumberOfTracks

        DistanceLimitForNeighbors =                                                     5;
        MaximumDistance =                                                               12;

        XCoordinates
        YCoordinates
        ZCoordinates
        HighlyVisitedSpotList
        
        InteractionChannel
        TrackingChannel
        
        ActiveIndex
 
    end
    
    methods
        
         function obj =                                 PMTrackingInteractionManager(myTrackedMovie)
            
             %PMTRACKINGOVERLAP Construct an instance of this class
            %   Detailed explanation goes here
            obj.MovieTrackingObject =                                   myTrackedMovie;
            obj.NumberOfTracks =                                        size(obj.MovieTrackingObject.TrackCell,1);
            
            
             %% first get coordinates lists (these are needed for getting highly visited places);
            YColumn=                                                        strcmp(obj.MovieTrackingObject.TrackCellFieldNames, 'CentroidY');
            obj.YCoordinates =           cellfun(@(x) cell2mat(x(:,YColumn)), obj.MovieTrackingObject.TrackCell, 'UniformOutput', false);

            XColumn=                     strcmp(obj.MovieTrackingObject.TrackCellFieldNames, 'CentroidX');
            obj.XCoordinates =           cellfun(@(x) cell2mat(x(:,XColumn)), obj.MovieTrackingObject.TrackCell, 'UniformOutput', false);

            
            ZColumn=                     strcmp(obj.MovieTrackingObject.TrackCellFieldNames, 'CentroidZ');
            obj.ZCoordinates =           cellfun(@(x) cell2mat(x(:,ZColumn)), obj.MovieTrackingObject.TrackCell, 'UniformOutput', false);

            TrackNumbers =               (num2cell(1:length(obj.XCoordinates)))';
            
            VistList =                   cellfun(@(x,y,z,n) obj.calculateHighlyVisitedSpots(x,y,z,n,obj.DistanceLimitForNeighbors), obj.XCoordinates, obj.YCoordinates, obj.ZCoordinates, TrackNumbers, 'UniformOutput', false);;
            
            obj.HighlyVisitedSpotList =                                 vertcat(VistList{:});
            obj.MovieTrackingObject =                                   obj.MovieTrackingObject.AddImageMap;
            % obj.ImageSequence =                                 obj.MovieTrackingObject.Create5DImageVolume(Settings);
    
                            
            
        end
        

         function HighlyVisitedSpotList =               calculateHighlyVisitedSpots(~, XCoordinates, YCoordinates, ZCoordinates,TrackNumber,DistanceLimit)
        
            % the input here is the "TrackDataCell", i.e. each row is a "position" ;
            % and the columns contain different information, e.g. X-coordinate, pixel-list etc;
            % 'ListWithFieldNames' contains a standardized legend for content;
            % this function gets the coordinates and calculates ;

            % in the process of moving this into PMTrackingAnalysis
            % (consider use this method instead and delete the method in this class);

            %% then go through each position and calculate distances to all other positions;
            % each other position that is within the distance limit, gets ;
            NumberOfPositions =                                     size(YCoordinates, 1);
            AbsolutePositions(:,1) =                                1:NumberOfPositions;

            HighlyVisitedSpotList =                                     cell(NumberOfPositions,2);
            ExportIndex =                                           0;
            SourceIndex =                                           1;
            
            while 1


                CurrentPositionX =                                  XCoordinates(SourceIndex,1);
                CurrentPositionY =                                  YCoordinates(SourceIndex,1);
                CurrentPositionZ =                                  ZCoordinates(SourceIndex,1);

                XDistances =                                        CurrentPositionX- XCoordinates;
                YDistances =                                        CurrentPositionY- YCoordinates;
                ZDistances =                                        CurrentPositionZ- ZCoordinates;

                Distances =                                         sqrt(XDistances.^2 + YDistances.^2 + ZDistances.^2);
                RowsWithNeighbors =                                 Distances <= DistanceLimit;
                NumberOfNeighbors =                                 sum(RowsWithNeighbors);

                ExportIndex =                                       ExportIndex + 1;
                HighlyVisitedSpotList{ExportIndex, 1} =             TrackNumber;
                HighlyVisitedSpotList{ExportIndex, 2} =             NumberOfNeighbors;
                HighlyVisitedSpotList{ExportIndex, 3} =             AbsolutePositions(RowsWithNeighbors);

                %% delete all used neighbors:

                XCoordinates(RowsWithNeighbors,:) =                 [];
                YCoordinates(RowsWithNeighbors,:) =                 [];
                ZCoordinates(RowsWithNeighbors,:) =                 [];
                AbsolutePositions(RowsWithNeighbors,:) =            [];

                if isempty(XCoordinates)
                    break
                end

            end


            EmptyRows =                                                 cellfun(@(x) isempty(x), HighlyVisitedSpotList(:,1));
            HighlyVisitedSpotList(EmptyRows,:) =                        [];

        
        end
        
         function [HandleWithPlots] =                   PlotStopPositions(CellListWithNeighbors, CellWithStopPositions, XCoordinates, YCoordinates, ZCoordinates);

                NumberOfRevisitPositions = size(CellListWithNeighbors,1);

                CurrentColorCode = 0;
                ColorCodes = {'r', 'g', 'b', 'c', 'm', 'k'};

                HandleWithPlots = figure;

                for RevisitIndex = 1:NumberOfRevisitPositions

                    CurrentColorCode =  CurrentColorCode + 1;
                    CurrentColor = ColorCodes{CurrentColorCode};
                    CurrentFrames =     CellWithStopPositions{RevisitIndex,2};
                   CurrentX = XCoordinates(CurrentFrames);
                    CurrentY= YCoordinates(CurrentFrames);

                    scatter(CurrentX, CurrentY, CurrentColor, 'Marker', 'x')

                    hold on

                    if CurrentColorCode == length(ColorCodes)
                        CurrentColorCode = 0;
                    end



                end


        end

         function [InteractionVolume] =                GetInteractionVolume(obj)
             
                FrameNumbers =                                              obj.HighlyVisitedSpotList{obj.ActiveIndex,3};
               
                SettingsReadImage.SourceChannels =                          obj.InteractionChannel;
                SettingsReadImage.TargetChannels =                          1;
                SettingsReadImage.SourceFrames =                            FrameNumbers; % this will be changed while going through sequence
                SettingsReadImage.TargetFrames =                            (1:length(FrameNumbers))';
                SettingsReadImage.SourcePlanes =                            [];
                SettingsReadImage.TargetPlanes =                            [];
                
                [InteractionVolume] =                                       obj.MovieTrackingObject.Create5DImageVolume(SettingsReadImage);

         end
         
         function [InteractionVolume] =                             GetTrackingVolume(obj)
             
                FrameNumbers =                                              obj.HighlyVisitedSpotList{obj.ActiveIndex,3};
               
                SettingsReadImage.SourceChannels =                          obj.TrackingChannel;
                SettingsReadImage.TargetChannels =                          1;
                SettingsReadImage.SourceFrames =                            FrameNumbers; % this will be changed while going through sequence
                SettingsReadImage.TargetFrames =                            (1:length(FrameNumbers))';
                SettingsReadImage.SourcePlanes =                            [];
                SettingsReadImage.TargetPlanes =                            [];
                
                [InteractionVolume] =                                       obj.MovieTrackingObject.Create5DImageVolume(SettingsReadImage);

         end
         
         function [obj]=                                            applyCell(obj, Cell)
             
             obj.HighlyVisitedSpotList{obj.ActiveIndex,4} =       Cell.ContactSiteIntensity;
             
         end
         
     
    end
end

