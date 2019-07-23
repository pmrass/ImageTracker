classdef PMTrackingCapture
    %PMTRACKINGCAPTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        FieldNamesForSegmentation = {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'};
        SegmentationOfCurrentFrame
        CurrentTrackId
        
        ImageVolume
        CroppedImageVolume
        NumberOfLostRows
        NumberOfLostColumns
        SeedRow
        SeedColumn
        
        CurrentXCoordinate
        CurrentYCoordinate
        CurrentZCoordinate
        
        MaskCoordinateList
        
        CurrentChannel =            1
        
        MaximumCellRadius =         30
        
        % this is for calculating seed statistics: this is only optional;
        StdForMaskRecognition =     2
        SeedWindowSize =            2
        SeedMedian
        SeedStandardDeviation
        
        PlaneNumberAboveAndBelow = 3
        
        Threshold
        
    end
    
    
    methods
        
        function obj = PMTrackingCapture(id, SegmentationOfCurrentFrame, XCoordinate, YCoordinate, ZCoordinate, ImageVolume)
            %PMTRACKINGCAPTURE Construct an instance of this class
            %   Detailed explanation goes here

            obj.SegmentationOfCurrentFrame =            SegmentationOfCurrentFrame;
            obj.CurrentTrackId =                        id;

            obj.ImageVolume =                           ImageVolume;

            obj.CurrentXCoordinate  =                   round(XCoordinate);
            obj.CurrentYCoordinate  =                   round(YCoordinate);
            obj.CurrentZCoordinate  =                   round(ZCoordinate);

        end


        function [obj] =                                                generateMask(obj)
        %TRACKINGRESULTS_CONVERTMANUALCLICKTOMASK_SINGLEMASK Summary of this function goes here
        %   Detailed explanation goes here

            obj =                                           obj.createCroppedImage;
            % seed is currently not used:
            %[obj]=                                                                 obj.calculateSeedStatistics;

           [obj] =                                         obj.autoDetectThreshold;
           [obj] =                                         obj.createMaskCoordinateList;

        end
        
        
        function [obj] =                                        generateMaskByClickingThreshold(obj)
            
            obj =                                           obj.createCroppedImage;
            [obj] =                                         obj.setThresholdToClickedPixel;
            [obj] =                                         obj.createMaskCoordinateList;
            
        end


        function [obj] =                                        removeDuplicatePixels(obj)

            
            %% read data:
            FieldNames =                                        obj.FieldNamesForSegmentation;
            CellWithMaskData =                                  obj.SegmentationOfCurrentFrame;
            PixelListDerivedFromCurrentClick =                  obj.MaskCoordinateList;
            
            %% process data:
            
            % get coordinates of all other previously tracked cells:
            Column_TrackID=                                     strcmp('TrackID', FieldNames);
            Column_AbsoluteFrame=                               find(strcmp('AbsoluteFrame', FieldNames));
            Column_CentroidY=                                   find(strcmp('CentroidY', FieldNames));
            Column_CentroidX=                                   find(strcmp('CentroidX', FieldNames));
            Column_CentroidZ=                                   find(strcmp('CentroidZ', FieldNames));
            Column_PixelList =                                  strcmp('ListWithPixels_3D', FieldNames);
            
            RowWithCurrentTrack =                               cell2mat(CellWithMaskData(:,Column_TrackID)) == obj.CurrentTrackId;  
            CellWithMaskData(RowWithCurrentTrack,:) =           [];

            PixelListFromOtherTrackedCells =                    CellWithMaskData(:,Column_PixelList);
            PixelListFromOtherTrackedCells =                    vertcat(PixelListFromOtherTrackedCells{:});


             if ~isempty(PixelListFromOtherTrackedCells)
                PixelListDerivedFromCurrentClick(ismember(PixelListDerivedFromCurrentClick,PixelListFromOtherTrackedCells,'rows'),:) = [];

             end

             %% return data to object:
             obj.MaskCoordinateList =                                   PixelListDerivedFromCurrentClick;


        end


        function [obj] =                                            createCroppedImage(obj)

            
            %% read data:
            MyImageVolume =                                     obj.ImageVolume;

            MaximumCellRadiusInside =                           obj.MaximumCellRadius;
            myYCoordinate=                                      obj.CurrentYCoordinate;
            myXCoordinate =                                     obj.CurrentXCoordinate;
            Channel =                                           obj.CurrentChannel;

            %% process data:

             MinimumRow =                                        myYCoordinate - MaximumCellRadiusInside;

            if MinimumRow < 1
                MinimumRow = 1;
            end
            
            MaximumRow =                    myYCoordinate + MaximumCellRadiusInside;
            if MaximumRow>size(MyImageVolume,1)
                MaximumRow =            size(MyImageVolume,1);
            end
            
            
            

            MinimumColumn = myXCoordinate - MaximumCellRadiusInside;
            if MinimumColumn<1
                MinimumColumn = 1;

            end

            MaximumColumn =                 myXCoordinate + MaximumCellRadiusInside;
            if MaximumColumn>size(MyImageVolume,2)
                MaximumColumn = size(MyImageVolume,2);
            end

           

            %% output data:
            
            
            
             obj.NumberOfLostRows =                                 MinimumRow - 1;
             obj.NumberOfLostColumns =                               MinimumColumn  - 1;   
             
             
              obj.SeedRow =        myYCoordinate - obj.NumberOfLostRows;                                   
             obj.SeedColumn = myXCoordinate - obj.NumberOfLostColumns;

            obj.CroppedImageVolume =       MyImageVolume(...
            MinimumRow:MaximumRow,...
            MinimumColumn:MaximumColumn, ...
            :, 1, Channel);           


        end



        function [obj]=                                             calculateSeedStatistics(obj)

            %% read data:
            myWindowSize =          obj.SeedWindowSize;
            myCroppedWindow =        obj.CroppedImageVolume;
            myZCoordinate =         obj.CurrentZCoordinate;


            %% process data:
            SeedValues =                                                double(myCroppedWindow(...
                MaximumRadiusInside - myWindowSize : MaximumRadiusInside + myWindowSize, ...
                MaximumRadiusInside - myWindowSize : MaximumRadiusInside + myWindowSize, ...
                myZCoordinate));

            SeedValues =                                                SeedValues(:);
            MySeedMedian =                                                median(SeedValues);
            MySeedStandardDeviation =                                     std(SeedValues);


            %% return data:
            obj.SeedMedian  =            MySeedMedian;
            obj.SeedStandardDeviation =  MySeedStandardDeviation;


        end


        function [obj] =                                            autoDetectThreshold(obj)


                function [Threshold] =              InterpretIntensityChanges(IntensityList)

                    ListWithIntensityDifferences =      diff(IntensityList);

                    % get the intensity differences at the "side": this is supposed to be background and contain "background" noise;
                    FirstTen =                          ListWithIntensityDifferences(1:10);
                    LastTen  =                          ListWithIntensityDifferences(end-9:end);
                    Baseline =                          [FirstTen; LastTen];
                    MaxDev =                            max(Baseline);

                    % around the place where a higher intensity difference can be found: this should be ;;
                    ThresholdRow =                      find(ListWithIntensityDifferences> MaxDev, 1, 'first')+2;
                    Threshold =                         IntensityList(ThresholdRow);

                end

            %% get data:
            myCroppedImageVolume =              obj.CroppedImageVolume;



            %% process data:

            % get the threshold values from "up", "down", "left", "right" and calculate the mean threshold;
            MiddleRow =                         round(size(myCroppedImageVolume,1)/2);
            IntensityListOne(:,1) =             myCroppedImageVolume(MiddleRow,:);
            ThresholdOne =                      InterpretIntensityChanges(IntensityListOne);

            IntensityListTwo =                  flip(IntensityListOne);
            ThresholdTwo =                      InterpretIntensityChanges(IntensityListTwo);

            MiddleColumn =                      round(size(myCroppedImageVolume,2)/2);
            IntensityListThree(:,1) =           myCroppedImageVolume(:,MiddleColumn);
            ThresholdThree =                    InterpretIntensityChanges(IntensityListThree);

            IntensityListFour =                 flip(IntensityListThree);
            ThresholdFour =                     InterpretIntensityChanges(IntensityListFour);

            MyCalculatedMeanThreshold =             mean([ThresholdOne, ThresholdTwo, ThresholdThree, ThresholdFour]);


            %% put result back
            obj.Threshold           =                   MyCalculatedMeanThreshold;




        end

        
        function [obj] =                                            setThresholdToClickedPixel(obj)
            
             MyImageVolume =                                     obj.ImageVolume;

            
            myYCoordinate=                                      obj.CurrentYCoordinate;
            myXCoordinate =                                     obj.CurrentXCoordinate;
            myZCoordinate =                                     obj.CurrentZCoordinate;
            Channel =                                           obj.CurrentChannel;

            
            obj.Threshold =                                     MyImageVolume(myYCoordinate,myXCoordinate,myZCoordinate,Channel);
            
        end


        function [obj] =                                            createMaskCoordinateList(obj)
        %CREATELISTWITHMASKCOORDINATES Summary of this function goes here
        %   Detailed explanation goes here

        
                %% read data:

                myCroppedImageVolume =                              obj.CroppedImageVolume;
                NumberOfPlanesAboveAndBelowConsidered =             obj.PlaneNumberAboveAndBelow;
                middlePlane =                                       obj.CurrentZCoordinate;
                MyImageVolume =                                     obj.ImageVolume;
                myNewThreshold =                                    obj.Threshold;


                myCroppedImageVolumeMask =                          uint8(myCroppedImageVolume >= myNewThreshold) * 255;

                
                %% process data:
                ZStart =                                            max([ 1 middlePlane - NumberOfPlanesAboveAndBelowConsidered]);
                MaxZ =                                              size(MyImageVolume, 3);
                ZEnd =                                              min([ middlePlane + NumberOfPlanesAboveAndBelowConsidered MaxZ]);
                NumberOfPlanesAnalyzed =                            length(ZStart:ZEnd);


                %% create a cell for all coordinates in each analyzed plane and fill data for "middle plane;
                 ListWith3DCoordinatesCell =                                                     cell(NumberOfPlanesAnalyzed,1);

                MaskImageOfMiddlePlane =                                                        myCroppedImageVolumeMask(:,:,middlePlane);
                ListWith3DCoordinatesCell{middlePlane,1} =                                      obj.getConnectedPixels(MaskImageOfMiddlePlane, middlePlane);


                %% go through lower planes and find connected pixels in 3D:
                for AnalyzedPlaneNumber = middlePlane-1:-1:ZStart
                    ConnectedStructuresInTargetPlane =                                  bwconncomp(myCroppedImageVolumeMask(:,:,AnalyzedPlaneNumber));
                    ListWithUpperPlanePixels =                                          ListWith3DCoordinatesCell{AnalyzedPlaneNumber+1};
                    ListWith3DCoordinatesCell{AnalyzedPlaneNumber,1}=                    obj.FindOverlappingPixels(ConnectedStructuresInTargetPlane, ListWithUpperPlanePixels, AnalyzedPlaneNumber);

                end


                %% go through upper planes and find connected pixels in 3D:
                for AnalyzedPlaneNumber = middlePlane+1:1:ZEnd
                     ConnectedStructuresInTargetPlane =                                 bwconncomp(myCroppedImageVolumeMask(:,:,AnalyzedPlaneNumber));
                    ListWithLowerPlanePixels =                                          ListWith3DCoordinatesCell{AnalyzedPlaneNumber-1};
                    ListWith3DCoordinatesCell{AnalyzedPlaneNumber,1}=                   obj.FindOverlappingPixels(ConnectedStructuresInTargetPlane, ListWithLowerPlanePixels, AnalyzedPlaneNumber);


                end


                FinalListWith3DCoordinates =                        vertcat(ListWith3DCoordinatesCell{:});

                NegativeValuesOne =                                 FinalListWith3DCoordinates(:,1)<0;
                NegativeValuesTwo =                                 FinalListWith3DCoordinates(:,2)<0;
                NegativeValuesThree =                               FinalListWith3DCoordinates(:,3)<0;
                
                NegativeValues =                                    max([NegativeValuesOne,NegativeValuesTwo, NegativeValuesThree], [], 2);
                FinalListWith3DCoordinates(NegativeValues,:) =      [];

                
                %% create ouput:
                obj.MaskCoordinateList =                            FinalListWith3DCoordinates;





        end


        %% helper functions:
        function [ListWithPixels] =                                 getConnectedPixels(obj,MaskImage,Plane)

            % start connecting from clicked pixel

            SeedRowInternal =                                                           obj.SeedRow;
            SeedColumnInteral =                                                       obj.SeedColumn;
            BW =                                                                grayconnected(MaskImage, SeedRowInternal,SeedColumnInteral);
            [YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]=           find(BW); 


            
          
            %% calibrate coordinates to full image (also will have to add drift-correction here at some point:
            [ListWithPixels] =                                              obj.CalibratePixelList([YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]);
            ListWithPixels(:,3)=                                            Plane;


        end


        function [ListWithPixels] =                                 CalibratePixelList(obj,ListWithPixels)

                    %myXCoordinate =                     obj.CurrentXCoordinate;
                    %myYCoordinate =                     obj.CurrentYCoordinate;
                    %myCellRadius =                      obj.MaximumCellRadius;

                    ListWithPixels(:,1) =               ListWithPixels(:,1) + obj.NumberOfLostRows;
                    ListWithPixels(:,2) =               ListWithPixels(:,2) + obj.NumberOfLostColumns;

        end


        function [ListWithOverlappingPixels]=                       FindOverlappingPixels(obj, Structure, ComparisonList, PlaneIndex)

                  %% first analyze the structures detected in the target image: 
                 if Structure.NumObjects == 0
                    ListWithOverlappingPixels =             zeros(0,3);
                    return
                 else
                     ListWithDetectedRegions(:,1) =               Structure.PixelIdxList;
                 end

                % sort by size (start analyzing with larget regions
                SizeOfStructures =                      cellfun(@(x) length(x), ListWithDetectedRegions);
                ListWithDetectedRegions(:,2) =          num2cell(SizeOfStructures);
                ListWithDetectedRegions =               sortrows(ListWithDetectedRegions, -2);

                %% then go through each region, starting from the biggest one:
                % the first one that shows overlap is accepted as extension of the "seed cell";
                NumberOfRegions =    size(ListWithDetectedRegions,1);
                for CurrentRegionIndex = 1:NumberOfRegions


                      CurrentRegion =                           ListWithDetectedRegions{CurrentRegionIndex,1};
                      [Rows,Columns] =                          ind2sub(Structure.ImageSize, CurrentRegion);
                      [CurrentCoordinateList] =                 obj.CalibratePixelList([ Rows , Columns]);
                      [~,index_A,~] =                           intersect(CurrentCoordinateList,ComparisonList(:,1:2),'rows');

                      if ~isempty(index_A) % if some pixels are overlapping accept that the current region is a cell extension into current plane;
                          ListWithOverlappingPixels =           CurrentCoordinateList;
                          ListWithOverlappingPixels(:,3) =      PlaneIndex;
                          return

                      end


                end


                if ~exist('ListWithOverlappingPixels')
                    ListWithOverlappingPixels = zeros(0,3);
                end


        end


       

   

        

    end
    
end

