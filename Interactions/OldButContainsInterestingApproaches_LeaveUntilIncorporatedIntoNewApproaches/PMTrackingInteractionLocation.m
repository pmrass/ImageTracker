classdef PMTrackingInteractionLocation
    %PMTRACKINGINTERACTIONCELL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        PositionIndex = 1
        NumberOfPositions
        
        ImageVolumeInteraction
        ImageVolumesTracking
        
        RevisitInfo
        
        MaskPixels
        SurfacePixels
        ContactSitePixels
        OutsidePixels
        ContactSiteIntensity
        
        
    end
    
    methods
        
        
        function obj = PMTrackingInteractionLocation(InteractionAnalysisManager)
            %PMTRACKINGINTERACTIONCELL Construct an instance of this class
            %   Detailed explanation goes here
            
            %% add image volume of currently selected revisit to object:
            ImageInteraction =                          InteractionAnalysisManager.GetInteractionVolume;
            ImageTracking =                             InteractionAnalysisManager.GetTrackingVolume;
            MaximumDistance =                           InteractionAnalysisManager.MaximumDistance;
            
            obj.ImageVolumeInteraction =                (arrayfun(@(x) ImageInteraction(:,:,x,:), 1:size(ImageInteraction,3), 'UniformOutput', false))';
            obj.ImageVolumesTracking =                  (arrayfun(@(x) ImageTracking(:,:,x,:), 1:size(ImageTracking,3), 'UniformOutput', false))';
            
            
            obj.RevisitInfo =                           InteractionAnalysisManager.HighlyVisitedSpotList(InteractionAnalysisManager.ActiveIndex,:);
           
            TrackNumber =                               obj.RevisitInfo{1};
            FrameNumbers =                              obj.RevisitInfo{3};
            TrackData =                                 InteractionAnalysisManager.MovieTrackingObject.TrackCell{TrackNumber,1};
            
            
            ColumnWithListWithPixels_3D =               strcmp(InteractionAnalysisManager.MovieTrackingObject.TrackCellFieldNames, 'ListWithPixels_3D');

            obj.MaskPixels =                            arrayfun(@(x) TrackData{x, ColumnWithListWithPixels_3D}, FrameNumbers, 'UniformOutput', false);

            obj.SurfacePixels =                         cellfun(@(x) obj.GetBorderPixelList(x), obj.MaskPixels, 'UniformOutput', false);
            
            [ListWithSurfacePixelClusters_All_Cell] =        cellfun(@(x) obj.GetPixelNeighbors(MaximumDistance,x), obj.SurfacePixels, 'UniformOutput', false);

            %% write a loop because otherwise it would be too complicated:
            for CurrentLocation=1:size(ListWithSurfacePixelClusters_All_Cell,1)
                
                CurrentInteractionImage =               obj.ImageVolumeInteraction{CurrentLocation};
                ListWithSurfacePixelClusters_All =      ListWithSurfacePixelClusters_All_Cell{CurrentLocation};
                
                 ListerWithAllClusterIntensities_PixelList{CurrentLocation,1} =            cellfun(@(x) obj.CollectIntensitiesOverlappingMask(CurrentInteractionImage, x), ListWithSurfacePixelClusters_All, 'UniformOutput', false);
                ListWithAllClusterIntensities_Median{CurrentLocation,1} =                 cellfun(@(x) median(x), ListerWithAllClusterIntensities_PixelList{CurrentLocation,1} );
                
            end
            
            
            

             %% find the brightest clusters = "synapse":
             [~, rowWithMaximumClusterIntensity] =                   cellfun(@(x) max(x), ListWithAllClusterIntensities_Median, 'UniformOutput', false);
           
            obj.ContactSitePixels =                                 cellfun(@(x,y) x{y,1}, ListWithSurfacePixelClusters_All_Cell,rowWithMaximumClusterIntensity, 'UniformOutput', false);
             obj.ContactSiteIntensity =                              cellfun(@(x,y) x(y,1),ListWithAllClusterIntensities_Median,rowWithMaximumClusterIntensity, 'UniformOutput', false);

             Empty =    cellfun(@(x) isempty(x), obj.ContactSiteIntensity);
             
             
             obj.ContactSiteIntensity(Empty) = {NaN};
             
             obj.OutsidePixels =    obj.SurfacePixels;
             
              for CurrentLocation=1:size(ListWithSurfacePixelClusters_All_Cell,1)
                obj.OutsidePixels{CurrentLocation}(ismember(obj.OutsidePixels{CurrentLocation} ,obj.ContactSitePixels{CurrentLocation} ,'rows'),:)=[];
              end
              
       

            end

             %% update synapse intensity list for current stop position:

          
            
            
        
        
        
         function [PooledBorderPixels] =               GetBorderPixelList(~, PixelList)


                %% get minimum and maximum-plane of pixel list:
                MinimumPlane =  min(PixelList(:,3));
                MaximumPlane =  max(PixelList(:,3));
                % return empty if source matrix is empty:
                if isempty(MinimumPlane) ||  isnan(MinimumPlane) 
                    PooledBorderPixels= zeros(0,3);
                    return

                end

                %% for each pixel list of current plane: 
                for PlaneIndex=MinimumPlane:MaximumPlane

                    PixelListForCurrentPlane = PixelList(PixelList(:,3)==PlaneIndex,:);
                    if isempty(PixelListForCurrentPlane)
                        BorderPixelsCurrentPlane= zeros(0,3);

                    else

                        %% create image from coordinate list and use this to create list with border coordinates; 
                        NumberOfPixels =    size(PixelListForCurrentPlane,1); 
                        Image=              zeros(512,512);
                        for CurrentPixel=1:NumberOfPixels
                            Image(PixelListForCurrentPlane(CurrentPixel,1), PixelListForCurrentPlane(CurrentPixel,2)) = 1;
                        end
                        BorderImage =                          bwboundaries(Image);

                        BorderPixelsCurrentPlane=              BorderImage{1,1};
                        BorderPixelsCurrentPlane(:,3)=          PlaneIndex;

                    end


                     BorderPixels{PlaneIndex-MinimumPlane+1}=  BorderPixelsCurrentPlane;

                end

                %% convert cell into matrix with all border pixels:
                PooledBorderPixels=     vertcat(BorderPixels{:});



        end

         function [ListWithNeighbors] =                 GetPixelNeighbors(~,MaximumDistance,PixelList)
                %GETPIXELNEIGHBORS Summary of this function goes here
                %   Detailed explanation goes here

                
                NumberOfPixels = size(PixelList,1);
                ListWithNeighbors =     cell(NumberOfPixels,1);
                for PixelIndex = 1:NumberOfPixels


                    CurrentPixel =                          PixelList(PixelIndex,:);

                    Distances =                             PixelList- CurrentPixel;
                    Distances3D =                           Distances(:,1).^2 +  Distances(:,2).^2 + Distances(:,3).^2;

                    PixelList(:,4) =                        Distances3D;
                    %PixelList =                             sortrows(PixelList,4);

                    ListWithNeighbors{PixelIndex,1} =       PixelList(PixelList(:,4)<=MaximumDistance, 1:3);


                end


         end

         function [ListWithIntensities] =               CollectIntensitiesOverlappingMask(~,ImageVolume, PixelList)
            %COLLECTINTENSITIESOVERLAPPINGMASK Summary of this function goes here
            %   Detailed explanation goes here

               NumberOfPixels = size(PixelList,1); 
                ListWithIntensities=zeros(NumberOfPixels,1);
                for CurrentPixel=1:NumberOfPixels

                    ListWithIntensities(CurrentPixel,1)=        ImageVolume(PixelList(CurrentPixel,1), PixelList(CurrentPixel,2), PixelList(CurrentPixel,3));

                    %TestImage(PixelList(CurrentPixel,1), PixelList(CurrentPixel,2))= 0;

                end

         end

    end
end

