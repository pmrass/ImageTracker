classdef PMSegmentationCapture
    %PMTRACKINGCAPTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties


        %% temporary data: these data are derived from the original movie and are needed only temporarily for analysis;
        % no permanent record desired:
        FieldNamesForSegmentation =         {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        SegmentationOfCurrentFrame
        CurrentTrackId
        
        SegmentationType

        ImageVolume
        MaximumRows
        MaximumColumns
        CroppedImageVolume
        NumberOfLostRows
        NumberOfLostColumns
        SeedRow
        SeedColumn

        MaskCoordinateList


        %% settings that define how segmentation/tracking is done;
        % these should be stored permanently because they will give insight into how the segmentation was obtained;
        % this could be useful in the future when 
        ActiveXCoordinate
        ActiveYCoordinate
        ActiveZCoordinate
        
        ActiveChannel =                         1
        
        MinimumCellRadius =                      5
        MaximumCellRadius =                     30
        PlaneNumberAboveAndBelow =              3
        
        PixelNumberForMaxAverage = 25;
        
        
        % edge detection:
        PixelShiftForEdgeDetection =            0;
        NumberOfPixelsForBackground =           10;
        ListWithEdgePositions =                 NaN;
        BoostBackgroundFactor =                 1;
       
        
        % currently not used;
        StdForMaskRecognition =                 NaN
        SeedWindowSize =                        NaN
        SeedMedian =                            NaN
        SeedStandardDeviation =                 NaN
        
        ListWithThresholds =                    NaN
        Threshold =                             NaN

    end
    
    
    methods
        
        
        function obj = PMSegmentationCapture(varargin)
            %PMTRACKINGCAPTURE Construct an instance of this class
            %   Detailed explanation goes here

            NumberOfInputArguments =    length(varargin);
            
            switch NumberOfInputArguments
                
                case 0
                    return
                case 1

                    input =                                         varargin{1};

                    CurrentFrame =                                  input.LoadedMovie.SelectedFrames(1);
                    ImageVolumeOfActiveChannel =                    input.LoadedImageVolumes{CurrentFrame,1}(:,:,:,:,input.LoadedMovie.ActiveChannel);

                    obj.ImageVolume =                               ImageVolumeOfActiveChannel;
                    obj.SegmentationOfCurrentFrame =                input.SegmentationOfCurrentFrame;

                    SegmentationOfActiveTrack =                    input.SegmentationOfCurrentFrame(input.RowOfActiveTrackAll,:);
                    if ~isempty(SegmentationOfActiveTrack)
                        
                        obj.CurrentTrackId =                        SegmentationOfActiveTrack{1,1};
                        obj.ActiveXCoordinate =                     SegmentationOfActiveTrack{1,4};
                        obj.ActiveYCoordinate =                     SegmentationOfActiveTrack{1,3};
                        obj.ActiveZCoordinate =                     SegmentationOfActiveTrack{1,5};
                        obj.MaskCoordinateList =                    SegmentationOfActiveTrack{1,6};
         
                    end


                case 3
                    
                    obj.CurrentTrackId =                        varargin{1};
                    obj.SegmentationOfCurrentFrame =            varargin{2};
                    obj.ImageVolume =                           varargin{3};


                case 6
                    
                    
                    obj.CurrentTrackId =                        varargin{1};
                    obj.SegmentationOfCurrentFrame =            varargin{2};
                    obj.ImageVolume =                           varargin{6};

                    obj.ActiveXCoordinate  =                   round(varargin{3});
                    obj.ActiveYCoordinate  =                   round(varargin{4});
                    obj.ActiveZCoordinate  =                   round(varargin{5});

                
            end
            
            obj.MaximumRows =      size(obj.ImageVolume,1); 
            obj.MaximumColumns = size(obj.ImageVolume,2); 

            

        end


        function [obj] =                                                generateMaskByAutoEdgeDetection(obj)
        %TRACKINGRESULTS_CONVERTMANUALCLICKTOMASK_SINGLEMASK Summary of this function goes here
        %   Detailed explanation goes here


            obj =                                               obj.createCroppedImage;

            % seed is currently not used:
            %[obj]=                                                                 obj.calculateSeedStatistics;

           [obj] =                                              obj.autoDetectThresholdFromEdge;
           [obj] =                                              obj.createMaskCoordinateList;
            obj =                                               obj.removePreviouslyTrackedDuplicatePixels;
           
           obj.SegmentationType =                               'ThresholdingByEdgeDetection';

        end
        
        
        function [obj] =                                        generateMaskByClickingThreshold(obj)
            
            obj =                                               obj.createCroppedImage; 
            [obj] =                                             obj.setThresholdToClickedPixel;
            [obj] =                                             obj.createMaskCoordinateList;
            obj =                                               obj.removePreviouslyTrackedDuplicatePixels;
            
            obj.SegmentationType =                              'Manual';
            
        end


        
        function [obj] =                                        createCroppedImage(obj)

            
            %% read data:
            MyImageVolume =                                     obj.ImageVolume;

           
            myYCoordinate=                                      obj.ActiveYCoordinate;
            myXCoordinate =                                     obj.ActiveXCoordinate;
            Channel =                                           obj.ActiveChannel;

            %% process data:
            % set area of interest by expected maximum cel size (if at border of image cut off there);
            MinimumRow =                                        obj.getMinimumRowForImageCropping;
            MaximumRow =                                        obj.getMaximumRowForImageCropping;
            
            MinimumColumn =                                      obj.getMinimumColumnForImageCropping;
            MaximumColumn =                                      obj.getMaximumColumnForImageCropping;
            

            %% output data:
            obj.NumberOfLostRows =                                     MinimumRow - 1;
            obj.NumberOfLostColumns =                                  MinimumColumn  - 1;   

            obj.SeedRow =                                              myYCoordinate - obj.NumberOfLostRows;                                   
            obj.SeedColumn =                                           myXCoordinate - obj.NumberOfLostColumns;

            obj.CroppedImageVolume =       MyImageVolume(...
            MinimumRow:MaximumRow,...
            MinimumColumn:MaximumColumn, ...
            :, 1, Channel);           


        end
        
        function MinimumRow = getMinimumRowForImageCropping(obj)
            
             myYCoordinate=                                      obj.ActiveYCoordinate;
            MaximumCellRadiusInside =                           obj.MaximumCellRadius;
             MinimumRow =                                        myYCoordinate - MaximumCellRadiusInside;

            if MinimumRow < 1
                MinimumRow = 1;
            end
            
            
        end
        
        
         function MaximumRow = getMaximumRowForImageCropping(obj)
            
                myYCoordinate=                                      obj.ActiveYCoordinate;
            MaximumCellRadiusInside =                           obj.MaximumCellRadius;
            MyImageVolume =                                     obj.ImageVolume;
            
            
            

            
            MaximumRow =                    myYCoordinate + MaximumCellRadiusInside;
            if MaximumRow>obj.MaximumRows
                MaximumRow =            obj.MaximumRows;
            end
            
            
            
         end
        
          function MinimumColumn = getMinimumColumnForImageCropping(obj)
            
               myXCoordinate =                                     obj.ActiveXCoordinate;
                MaximumCellRadiusInside =                           obj.MaximumCellRadius;
             MinimumColumn = myXCoordinate - MaximumCellRadiusInside;
            if MinimumColumn<1
                MinimumColumn = 1;

            end

            

            
          end
        
           function MaximumColumn = getMaximumColumnForImageCropping(obj)
            
               MyImageVolume =                                     obj.ImageVolume;
                myXCoordinate =                                     obj.ActiveXCoordinate;
                 MaximumCellRadiusInside =                           obj.MaximumCellRadius;
               MaximumColumn =                 myXCoordinate + MaximumCellRadiusInside;
            if MaximumColumn>obj.MaximumColumns 
                MaximumColumn = obj.MaximumColumns ;
            end
            
            
        end

        
        
        
        
      
                
        function [obj] =                                            setThresholdToClickedPixel(obj)
            
             MyImageVolume =                                     obj.ImageVolume;

            
            myYCoordinate=                                      obj.ActiveYCoordinate;
            myXCoordinate =                                     obj.ActiveXCoordinate;
            myZCoordinate =                                     obj.ActiveZCoordinate;
            Channel =                                           obj.ActiveChannel;

            obj.Threshold =                                     MyImageVolume(myYCoordinate,myXCoordinate,myZCoordinate,Channel);
            
        end


        function [obj]=                                             calculateSeedStatistics(obj)

            
            %% read data:
            myWindowSize =                                      obj.SeedWindowSize;
            myCroppedWindow =                                   obj.CroppedImageVolume;
            myZCoordinate =                                     obj.ActiveZCoordinate;


            %% process data:
            SeedValues =                                                double(myCroppedWindow(...
            MaximumRadiusInside - myWindowSize : MaximumRadiusInside + myWindowSize, ...
            MaximumRadiusInside - myWindowSize : MaximumRadiusInside + myWindowSize, ...
            myZCoordinate));

            SeedValues =                                            SeedValues(:);
            MySeedMedian =                                          median(SeedValues);
            MySeedStandardDeviation =                               std(SeedValues);


            %% return data:
            obj.SeedMedian  =                                       MySeedMedian;
            obj.SeedStandardDeviation =                             MySeedStandardDeviation;


        end


        function [obj] =                                            autoDetectThresholdFromEdge(obj)


                function [Threshold,ThresholdRow] =              InterpretIntensityChanges(IntensityList)

                    IntensityList = double(IntensityList);
                    
                    EdgeShift =                         obj.PixelShiftForEdgeDetection;
                    NumberOfBaselinePixels =            obj.NumberOfPixelsForBackground;
                    boost =                             obj.BoostBackgroundFactor;
                    
                    ListWithIntensityDifferences =      diff(IntensityList);

                    StartPixels =    1:length(ListWithIntensityDifferences)-NumberOfBaselinePixels+1;
                    EndPixels =      StartPixels+NumberOfBaselinePixels-1;
                    BaselineVariation =  arrayfun(@(x,y) max(ListWithIntensityDifferences(x:y)), StartPixels, EndPixels);
                    
                    
                            
                    
                    % get the intensity differences at the "side": this is supposed to be background and contain "background" noise;
   
                    BackGroundIncrease =                            max(BaselineVariation)*boost;

                    
                    
                    [MaximumIncrease] =                   max(ListWithIntensityDifferences);
                    
                    WantedIncrease =                    ((BackGroundIncrease + MaximumIncrease) / 2) * 0.3;
                    
                    
                    if WantedIncrease>MaximumIncrease
                        ThresholdRow = NaN;
                        Threshold = NaN;
                    else
                          % around the place where a higher intensity difference can be found: this should be ;;
                    ThresholdRow =                      find(ListWithIntensityDifferences>= WantedIncrease, 1, 'first')+EdgeShift;
                    Threshold =                         IntensityList(ThresholdRow);

                        
                        
                    end
                  
                end
                
                
                

            %% get data:
            myCroppedImageVolume =              obj.CroppedImageVolume;



            %% process data:

          
            % get the threshold values from "up", "down", "left", "right" and calculate the mean threshold;
            MiddleRow =                         obj.SeedRow;
            IntensityListOne(:,1) =             myCroppedImageVolume(MiddleRow,:,obj.ActiveZCoordinate);
            [ThresholdOne, ThresholdOneRow] =                      InterpretIntensityChanges(IntensityListOne);

            IntensityListTwo =                  flip(IntensityListOne);
            [ThresholdTwo, ThresholdTwoRow] =                      InterpretIntensityChanges(IntensityListTwo);

            MiddleColumn =                       obj.SeedColumn;
            IntensityListThree(:,1) =           myCroppedImageVolume(:,MiddleColumn,obj.ActiveZCoordinate);
            [ThresholdThree, ThresholdThreeRow] =                    InterpretIntensityChanges(IntensityListThree);

            IntensityListFour =                 flip(IntensityListThree);
            [ThresholdFour, ThresholdFourRow] =                     InterpretIntensityChanges(IntensityListFour);

            MyCalculatedMeanThreshold =             mean([ThresholdOne, ThresholdTwo, ThresholdThree, ThresholdFour]);

            
             obj.ListWithEdgePositions = [ThresholdOneRow;ThresholdTwoRow;ThresholdThreeRow;ThresholdFourRow];
            obj.ListWithThresholds = [ThresholdOne;ThresholdTwo;ThresholdThree;ThresholdFour];

            %% put result back
            obj.Threshold           =                   MyCalculatedMeanThreshold;




        end



        function [obj] =                                            createMaskCoordinateList(obj)
        %CREATELISTWITHMASKCOORDINATES create coordinate list by thresholding image;
        %   cropped image, threshold, seed position

        
                %% read data:

                myCroppedImageVolume =                              obj.CroppedImageVolume;
                NumberOfPlanesAboveAndBelowConsidered =             obj.PlaneNumberAboveAndBelow;
                middlePlane =                                       obj.ActiveZCoordinate;
                MyImageVolume =                                     obj.ImageVolume;
                myNewThreshold =                                    obj.Threshold;

                if isnan(myNewThreshold)
                    FinalListWith3DCoordinates = [];
                else
                    
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
                            ConnectedStructuresInTargetPlane =                                          bwconncomp(myCroppedImageVolumeMask(:,:,AnalyzedPlaneNumber));
                            ListWithUpperPlanePixels =                                                  ListWith3DCoordinatesCell{AnalyzedPlaneNumber+1};
                            ListWith3DCoordinatesCell{AnalyzedPlaneNumber,1}=                           obj.FindContactAreasInNeighborPlane(ConnectedStructuresInTargetPlane, ListWithUpperPlanePixels, AnalyzedPlaneNumber);

                        end


                        %% go through upper planes and find connected pixels in 3D:
                        for AnalyzedPlaneNumber = middlePlane+1:1:ZEnd
                             ConnectedStructuresInTargetPlane =                                         bwconncomp(myCroppedImageVolumeMask(:,:,AnalyzedPlaneNumber));
                            ListWithLowerPlanePixels =                                                  ListWith3DCoordinatesCell{AnalyzedPlaneNumber-1};
                            ListWith3DCoordinatesCell{AnalyzedPlaneNumber,1}=                           obj.FindContactAreasInNeighborPlane(ConnectedStructuresInTargetPlane, ListWithLowerPlanePixels, AnalyzedPlaneNumber);


                        end


                        FinalListWith3DCoordinates =                        vertcat(ListWith3DCoordinatesCell{:});

                        NegativeValuesOne =                                 FinalListWith3DCoordinates(:,1)<0;
                        NegativeValuesTwo =                                 FinalListWith3DCoordinates(:,2)<0;
                        NegativeValuesThree =                               FinalListWith3DCoordinates(:,3)<0;

                        NegativeValues =                                    max([NegativeValuesOne,NegativeValuesTwo, NegativeValuesThree], [], 2);
                        FinalListWith3DCoordinates(NegativeValues,:) =      [];


                    
                end
                
              

                %% create ouput:
                obj.MaskCoordinateList =                            FinalListWith3DCoordinates;

        end
        
        
          
        function [obj] =                                            removePreviouslyTrackedDuplicatePixels(obj)

            
            %% read data:
            FieldNames =                                        obj.FieldNamesForSegmentation;
            CellWithMaskData =                                  obj.SegmentationOfCurrentFrame;
            PixelListDerivedFromCurrentClick =                  obj.MaskCoordinateList;
            
            %% process data:
            
            if isempty(PixelListDerivedFromCurrentClick)
                return
            end
            
            % get coordinates of all other previously tracked cells:
            Column_TrackID=                                     strcmp('TrackID', FieldNames);
            Column_AbsoluteFrame=                               find(strcmp('AbsoluteFrame', FieldNames));
            Column_CentroidY=                                   find(strcmp('CentroidY', FieldNames));
            Column_CentroidX=                                   find(strcmp('CentroidX', FieldNames));
            Column_CentroidZ=                                   find(strcmp('CentroidZ', FieldNames));
            Column_PixelList =                                  strcmp('ListWithPixels_3D', FieldNames);
            
            
            if ~isempty(CellWithMaskData)
                RowWithCurrentTrack =                               cell2mat(CellWithMaskData(:,Column_TrackID)) == obj.CurrentTrackId;  
                CellWithMaskData(RowWithCurrentTrack,:) =           [];

                PixelListFromOtherTrackedCells =                    CellWithMaskData(:,Column_PixelList);
                PixelListFromOtherTrackedCells =                    vertcat(PixelListFromOtherTrackedCells{:});
            else
                PixelListFromOtherTrackedCells = [];

            end

             if ~isempty(PixelListFromOtherTrackedCells)
                PixelListDerivedFromCurrentClick(ismember(PixelListDerivedFromCurrentClick,PixelListFromOtherTrackedCells,'rows'),:) = [];

             end

             %% return data to object:
             obj.MaskCoordinateList =                                   PixelListDerivedFromCurrentClick;


        end


        function highLightAutoEdgeDetection(obj, ImageHandle)
            
            myYCoordinate=                                      obj.ActiveYCoordinate;
            myXCoordinate =                                     obj.ActiveXCoordinate;
            Channel =                                           obj.ActiveChannel;

            %% process data:
            % set area of interest by expected maximum cel size (if at border of image cut off there);
            MinimumRow =                                        obj.getMinimumRowForImageCropping;
            MaximumRow =                                        obj.getMaximumRowForImageCropping;
            
            MinimumColumn =                                      obj.getMinimumColumnForImageCropping;
            MaximumColumn =                                      obj.getMaximumColumnForImageCropping;
            

            ImageHandle.CData(MinimumRow:MaximumRow, myXCoordinate,1) =                    200;
            ImageHandle.CData(myYCoordinate, MinimumColumn:MaximumColumn,1) =                    200;
            
            ImageHandle.CData(MinimumRow:MinimumRow+obj.NumberOfPixelsForBackground-1, myXCoordinate,3) =                    200;
            ImageHandle.CData(MaximumRow-obj.NumberOfPixelsForBackground+1:MaximumRow, myXCoordinate,3) =                    200;
           
            ImageHandle.CData(myYCoordinate, MinimumColumn:MinimumColumn+obj.NumberOfPixelsForBackground-1,3) =                    200;
            ImageHandle.CData(myYCoordinate, MaximumColumn-obj.NumberOfPixelsForBackground+1:MaximumColumn,3) =                    200;

            ImageHandle.CData(MinimumRow+obj.ListWithEdgePositions(3),myXCoordinate,1:3) =          255;
            ImageHandle.CData(MaximumRow-obj.ListWithEdgePositions(4),myXCoordinate,1:3) =          255;
            ImageHandle.CData(myYCoordinate,MinimumColumn+obj.ListWithEdgePositions(1),1:3) =     255;
            ImageHandle.CData(myYCoordinate,MaximumColumn-obj.ListWithEdgePositions(2),1:3) =     255;

            
            
            
        end
        
        
        
        function [obj] =       RemoveImageData(obj)
            
             obj.ImageVolume = [];
                    obj.CroppedImageVolume = [];
                    obj.MaskCoordinateList = [];
                    obj.SegmentationOfCurrentFrame = [];
            
        end
          
                    
                   
                    
                    
                    
       function PixelIntensities = getPixelIntensitiesOfActiveMask(obj)

            PreCoordinateList =                     obj.MaskCoordinateList;
            AfterImageVolume =                      obj.ImageVolume;
            PixelIntensities =                      double(arrayfun(@(row,column,plane) AfterImageVolume(row,column,plane), PreCoordinateList(:,1),PreCoordinateList(:,2),PreCoordinateList(:,3)));

 
        end

        
        
        function [CoordinatesWithMaximumIntensity] =   getBrightestPixelsOfActiveMask(obj)
            
            
            PreCoordinateList =                     obj.MaskCoordinateList;
            PixelIntensities =                      obj.getPixelIntensitiesOfActiveMask;
            
           
            
            NumberOfRequiredPixels =                        obj.PixelNumberForMaxAverage;
            
            CoordinatesWithIntensity =              [PreCoordinateList, PixelIntensities];
            
            CoordinatesWithIntensity =              sortrows(CoordinatesWithIntensity, -4);
            
            
           
            
             
             
             CoordinatesWithMaximumIntensity =                           CoordinatesWithIntensity(1:NumberOfRequiredPixels,:);

           
            
            
            
        end
        
        
           function obj = setActiveCoordinateByBrightestPixels(obj, ImageHandle)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            
                CoordinatesWithMaximumIntensity =    obj.getBrightestPixelsOfActiveMask;

              


                
            
             ImageHandle.CData(CoordinatesWithMaximumIntensity(:,1), CoordinatesWithMaximumIntensity(:,2),1) =                    200;
        

               CoordinateWithMaximumIntensity =        round(median(CoordinatesWithMaximumIntensity(:,1:3), 1));
                obj.ActiveYCoordinate = CoordinateWithMaximumIntensity(1,1);
                obj.ActiveXCoordinate = CoordinateWithMaximumIntensity(1,2);
                obj.ActiveZCoordinate = CoordinateWithMaximumIntensity(1,3);

        end
        
       
        
        

        %% helper functions:
                                
        
        
        function [ListWithPixels] =                                 getConnectedPixels(obj,MaskImage,Plane)

            % start connecting from clicked pixel
            SeedRowInternal =                                                   obj.SeedRow;
            SeedColumnInteral =                                                 obj.SeedColumn;
            
            BW =                                                                grayconnected(MaskImage, SeedRowInternal, SeedColumnInteral);
            [YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]=           find(BW); 


            
          
            %% calibrate coordinates to full image (also will have to add drift-correction here at some point:
            [ListWithPixels] =                                              obj.CalibratePixelList([YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]);
            ListWithPixels(:,3)=                                            Plane;


        end


        function [ListWithPixels] =                                 CalibratePixelList(obj,ListWithPixels)

                    %% add back rows and columns and were removed during cropping of source image:
                    ListWithPixels(:,1) =               ListWithPixels(:,1) + obj.NumberOfLostRows;
                    ListWithPixels(:,2) =               ListWithPixels(:,2) + obj.NumberOfLostColumns;

        end


        function [ListWithOverlappingPixels]=                       FindContactAreasInNeighborPlane(obj, Structure, ComparisonList, PlaneIndex)

                 % compare neighboring planes and include all areas that overlap with the "source" plane;
            
                 %% first analyze the structures detected in the target image: 
                 if Structure.NumObjects == 0
                    ListWithOverlappingPixels =                     zeros(0,3);
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

