classdef PMSegmentationCapture
    %PMTRACKINGCAPTURE for segmentation of given image volume;
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
        
        ActiveChannel =                         2
        
        MinimumCellRadius =                     3  %5
        MaximumCellRadius =                     30 %30
        PlaneNumberAboveAndBelow =              10
        MaximumDisplacement =                   50
        
        PixelNumberForMaxAverage =              20; %25
        
        
        % edge detection:
        PixelShiftForEdgeDetection =            1; %1
        WidenMaskAfterDetectionByPixels =       0;
        NumberOfPixelsForBackground =           20;
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
                    
                case 1 % one input argument means that the current PMMovieController is the input argument:

                    MovieControllerObject =                         varargin{1};
                    [obj]=                                             obj.resetWithMovieController(MovieControllerObject);
                    
                    

                case 2 % manual tracking: pixel-list and type "manual";

                    if strcmp(class(varargin{1}),  'PMMovieController')
                        
                        MovieControllerObject =                         varargin{1};
                        [obj]=                                          obj.resetWithMovieController(MovieControllerObject);
                    
                        Coordinates =                                   varargin{2};
                        obj.ActiveYCoordinate =                         Coordinates(1);
                        obj.ActiveXCoordinate =                         Coordinates(2);
                        obj.ActiveZCoordinate =                         Coordinates(3);
                        obj.MaskCoordinateList =                        Coordinates;
                        
                    else
                        
                        obj.MaskCoordinateList =                        varargin{1};
                        obj.SegmentationType =                          varargin{2};
                        
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
            
            obj.MaximumRows =           size(obj.ImageVolume,1); 
            obj.MaximumColumns =        size(obj.ImageVolume,2); 

            

        end

        %% getters:
        
         function MinimumRow =                            getMinimumRowForImageCropping(obj)
            
            myYCoordinate=                                          obj.ActiveYCoordinate;
            MaximumDisplacementInside =                           obj.MaximumDisplacement;
            MinimumRow =                                            myYCoordinate - MaximumDisplacementInside;

            if MinimumRow < 1
                MinimumRow = 1;
            end
            
            
        end
        
        
         function MaximumRow =                          getMaximumRowForImageCropping(obj)
            
            myYCoordinate=                                          obj.ActiveYCoordinate;
            MaximumDisplacementInside =                             obj.MaximumDisplacement;
            MaximumRow =                                            myYCoordinate + MaximumDisplacementInside;
            
            if MaximumRow>obj.MaximumRows
                MaximumRow =            obj.MaximumRows;
            end
            
            
            
         end
        
          function MinimumColumn =                      getMinimumColumnForImageCropping(obj)
            
                myXCoordinate =                                 obj.ActiveXCoordinate;
                MaximumDisplacementInside =                     obj.MaximumDisplacement;
                MinimumColumn =                                 myXCoordinate - MaximumDisplacementInside;
                if MinimumColumn<1
                MinimumColumn = 1;

                end

            

            
          end
        
        function MaximumColumn =                     getMaximumColumnForImageCropping(obj)
            
            myXCoordinate =                             obj.ActiveXCoordinate;
            MaximumDisplacementInside =                 obj.MaximumDisplacement;
            MaximumColumn =                             myXCoordinate + MaximumDisplacementInside;
            if MaximumColumn>obj.MaximumColumns 
                MaximumColumn = obj.MaximumColumns ;
            end
            
            
        end

        
         function [xCoordinate,yCoordinate,CoordinatesList] = detectBrightestAreaInImage(obj, Image,Size)
             
            IntensityMatrix =   zeros(size(Image,1)-Size,size(Image,2)-Size);
            
            for RowIndex = 1:size(Image,1)-Size+1
                
                for ColumnIndex = 1:size(Image,2)-Size+1
                
                    Area =                                      Image(RowIndex:RowIndex+Size-1,ColumnIndex:ColumnIndex+Size-1);            
                    IntensityMatrix(RowIndex,ColumnIndex) =     median(Area(:));
                         
                end
                
                
            end
            
            [a,listWithRows] = max(IntensityMatrix);
            
            [c,column] = max(a);
            
            yCoordinate = listWithRows(column) + round(Size/2);
            xCoordinate = column + round(Size/2);
            
          [CoordinatesList] =    convertRectangleLimitToCoordinates(obj,[column  listWithRows(column) Size Size]);
            
          CoordinatesList(:,3) =     obj.ActiveZCoordinate;
        
         
          
         end
        
         
          function PixelListFromOtherTrackedCells = getAllPreviouslyTrackedPixels(obj)
            
              % get coordinates of all other previously tracked cells:
            FieldNames =                                        obj.FieldNamesForSegmentation;
            Column_TrackID=                                     strcmp('TrackID', FieldNames);
            Column_PixelList =                                  strcmp('ListWithPixels_3D', FieldNames);
           
            
            CellWithMaskData =                                  obj.SegmentationOfCurrentFrame;
            if ~isempty(CellWithMaskData)
                
                if ~isempty(obj.CurrentTrackId) && ~isnan(obj.CurrentTrackId) % exclude currently tracked cell (not to block re-tracking)
                    RowWithCurrentTrack =                               cell2mat(CellWithMaskData(:,Column_TrackID)) == obj.CurrentTrackId;  
                    CellWithMaskData(RowWithCurrentTrack,:) =           [];

                end
                PixelListFromOtherTrackedCells =                    CellWithMaskData(:,Column_PixelList);
                PixelListFromOtherTrackedCells =                    vertcat(PixelListFromOtherTrackedCells{:});
                
                if isempty(PixelListFromOtherTrackedCells)
                    PixelListFromOtherTrackedCells = zeros(0,3);
                end
                
            else
                PixelListFromOtherTrackedCells = zeros(0,3);

            end

            
            
            
          end

        
        function PixelIntensities = getPixelIntensitiesOfActiveMask(obj)

            PreCoordinateList =                     obj.MaskCoordinateList;
            AfterImageVolume =                      obj.ImageVolume;
            PixelIntensities =                      double(arrayfun(@(row,column,plane) AfterImageVolume(row,column,plane), PreCoordinateList(:,1),PreCoordinateList(:,2),PreCoordinateList(:,3)));

 
        end

        
        
        function [CoordinatesWithMaximumIntensity] =   getBrightestPixelsOfActiveMask(obj)


        PreCoordinateList =                             obj.MaskCoordinateList;
        PixelIntensities =                              obj.getPixelIntensitiesOfActiveMask;



        NumberOfRequiredPixels =                        obj.PixelNumberForMaxAverage;

        CoordinatesWithIntensity =                      [PreCoordinateList, PixelIntensities];

        CoordinatesWithIntensity =                      sortrows(CoordinatesWithIntensity, -4);




        if size(CoordinatesWithIntensity,1) < NumberOfRequiredPixels
            
            fprintf('PMSegmentationCapture: @getBrightestPixelsOfActiveMask.\n')
            fprintf('The "reference mask" contains only %i pixels, but %i pixels are required.\n', size(CoordinatesWithIntensity,1), NumberOfRequiredPixels)
            error('An error was thrown because not enough reference pixels are available.')
            
        end


         CoordinatesWithMaximumIntensity =                           CoordinatesWithIntensity(1:NumberOfRequiredPixels,:);





        end


        function [ListWithPixels] =                                 getConnectedPixels(obj,MaskImage,Plane)

        % start connecting from clicked pixel
        SeedRowInternal =                                                   obj.SeedRow;
        SeedColumnInteral =                                                 obj.SeedColumn;

        if isempty(SeedRowInternal) || isempty(SeedColumnInteral)
            ListWithPixels =    zeros(0,3);
            return
        end

        
        MaskImage(MaskImage==1) = 255; % need to do that; otherwise grayconnected doesn't work;
        BW =                                                                grayconnected(MaskImage, SeedRowInternal, SeedColumnInteral);
        [YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]=           find(BW); 




        %% calibrate coordinates to full image (also will have to add drift-correction here at some point:
        [ListWithPixels] =                                              obj.CalibratePixelList([YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]);
        ListWithPixels(:,3)=                                            Plane;


        end



           function [check, explanation] = checkPixelList(obj)

                NewPixels =                                                      obj.MaskCoordinateList;


                %% assert that autodected pixels are above the required minimum
                if isempty(NewPixels) || size(NewPixels,1) < obj.MinimumCellRadius^2
                    check = false;
                    explanation = 'No pixels or too few pixels detected.';
                    return
                end

                %% if no pixels are detected or if the "width" and "height" of the detected pixels are not ok, check is negative;
                Width =                                         max(NewPixels(:,2)) - min(NewPixels(:,2));
                Height =                                        max(NewPixels(:,1)) - min(NewPixels(:,1));
                if   Width >= 2* obj.MaximumCellRadius || Height >= 2* obj.MaximumCellRadius
                    explanation = 'Mask was too wide or too high.';
                    check = false;
                    return
                end
                
                %% 

                MeanOne =   round(mean(NewPixels(:,1)));
                MeanTwo =   round(mean(NewPixels(:,2)));
                MeanThree =   round(mean(NewPixels(:,3)));
                
                
                MeanRow =   find(ismember(NewPixels,[MeanOne,MeanTwo,MeanThree],'rows'));
                
                if isempty(MeanRow)
                    explanation = 'Center of mass was empty.';
                    check = false;
                    return
                end
                
                 explanation =   'Pixels were acceptable';
                check = true;


           end

           function [recreatedVolume] =        createBinaryVolumeByEdgeDetection(obj,myCroppedImageVolume)
               
               
               numberOfPlanes =             size(myCroppedImageVolume,3);
               
               Int =             cell(numberOfPlanes,1);
               
               for Plane = 1:numberOfPlanes
                   
                   
                   
                       myCurrentImage =                     myCroppedImageVolume(:,:,Plane);       
                    [ edges, oher] =                        edge(myCurrentImage, 'canny');
                    ohernew =    oher*1.5;
                    [ edges2, oher2] =                      edge(myCurrentImage,'canny',ohernew);

                    filled =                                imfill(edges2, 'holes');
                    filled =                                filled-edges2;
                    filled =                                imfill(filled, 'holes');
                    
                    
                    [labeledImage, number] =                          bwlabel(filled);
                    
                    IntensityValues =       zeros(number,1);
                    
                   
                    
                    BinaryVolume(:,:,Plane) =               filled;
                    if 1== 2 % for trouble shooting
                    figure(20)
                    imagesc(myCurrentImage)

                    
                    
                    figure(22)
                    imagesc(edges2)
                    
                    figure(23)
                    imagesc(filled)
                    
                    figure(24)
                    imagesc(labeledImage)
                    
                    end
                   
                    IntensityValues =       zeros(number,1);
                    CoordinateLists =       cell(number,1);
                     for currentObjectIndex =1:number
                        
                         
                         [r, c] =                                       find(labeledImage==currentObjectIndex);
                         MedianIntens =                                 median(myCurrentImage(labeledImage==currentObjectIndex));
                      
                         IntensityValues(currentObjectIndex,1) =        MedianIntens;
                         CoordinateLists{currentObjectIndex,1} =        [r, c];
                     end
                    
                     
                     IntPlanes{Plane,1} =               IntensityValues;
                     CoorPlanes{Plane,1} =              CoordinateLists;
                     PlanePlanes{Plane,1} =             (linspace(Plane, Plane, length(IntensityValues)))';
                    PixelNumberPlanes{Plane,1} =        cellfun(@(x) length(x), CoordinateLists);
                    
               end
               
               IntAll=  vertcat(IntPlanes{:});
               CoorAll=  vertcat(CoorPlanes{:});
               PlaneAll=  vertcat(PlanePlanes{:});
               PixelNumberAll =  vertcat(PixelNumberPlanes{:});
               
               AllTogether =    [num2cell(IntAll), CoorAll, num2cell(PlaneAll),num2cell(PixelNumberAll)];
             
               AllTogether =    sortrows(AllTogether,-1);
               
               differ=abs(diff(cell2mat(AllTogether(:,1))));
             
               
               LastRowWithBigDifference =       find(differ>=2, 1, 'last');
               
               if ~isempty(LastRowWithBigDifference)
                   
                   AllTogether(LastRowWithBigDifference:end,:) = [];
               end
               
                MinimumPixels =  obj.MinimumCellRadius^2;
               RowsToDelete = cell2mat(AllTogether(:,4))<MinimumPixels;
 
               AllTogether(RowsToDelete,:) = [];
               
               
               
               recreatedVolume =   myCroppedImageVolume;
               recreatedVolume(:,:,:) = 0;
               
               numberOfObjects =    size(AllTogether,1);
               
               for currentObjetIndex =1 :numberOfObjects
                   
                   CurrentCoordinates =  AllTogether{currentObjetIndex,2};
                   CurrentCoordinates(:,3) =    AllTogether{currentObjetIndex,3};
                   
                   recreatedVolume(CurrentCoordinates) = 1;
                   
                   NumberOfPixels = size(CurrentCoordinates,1);
                   
                   for Currentpixel = 1:NumberOfPixels
                       
                       
                       CurrentCoordinate = CurrentCoordinates(Currentpixel,:);
                       
                       recreatedVolume(CurrentCoordinate(1),CurrentCoordinate(2),CurrentCoordinate(3)) = 1;
                       
                   end
                   
                   
               end
               
              % maxRec =max(recreatedVolume, [], 3);
               
            
               
           end
           
       
           function [CentralPlane, PlanesAbove, PlanesBelow, NumberOfPlanesAnalyzed] = getConnectedPlaneSpecification(obj)

                CentralPlane =                                      obj.ActiveZCoordinate;

                NumberOfPlanesAboveAndBelowConsidered =             obj.PlaneNumberAboveAndBelow;
                MyImageVolume =                                     obj.ImageVolume;

                ZStart =                                            max([ 1 CentralPlane - NumberOfPlanesAboveAndBelowConsidered]);
                MaxZ =                                              size(MyImageVolume, 3);
                ZEnd =                                              min([ CentralPlane + NumberOfPlanesAboveAndBelowConsidered MaxZ]);
                NumberOfPlanesAnalyzed =                            length(ZStart:ZEnd);

                PlanesAbove =                                       CentralPlane-1:-1: ZStart; % maybe include more checks: e.g. make isnan or empty when no values exist;
                PlanesBelow =                                       CentralPlane+1:1: ZEnd;

           end

        %% setter: create mask:
        
        function [obj]=                                             resetWithMovieController(obj, MovieControllerObject)
            
                    CurrentFrame =                                  MovieControllerObject.LoadedMovie.SelectedFrames(1);
                    ImageVolumeOfActiveChannel =                    MovieControllerObject.LoadedImageVolumes{CurrentFrame,1}(:,:,:,:,obj.ActiveChannel);

                    obj.ImageVolume =                               ImageVolumeOfActiveChannel;
                    obj.SegmentationOfCurrentFrame =                MovieControllerObject.LoadedMovie.getUnfilteredSegmentationOfCurrentFrame;

                    
                    
                    SegmentationOfActiveTrack =                     MovieControllerObject.LoadedMovie.getUnfilteredSegmentationOfActiveTrack;
                    if ~isempty(SegmentationOfActiveTrack)
                        
                        obj.CurrentTrackId =                        SegmentationOfActiveTrack{1,1};
                        obj.ActiveYCoordinate =                     round(SegmentationOfActiveTrack{1,3});
                        obj.ActiveXCoordinate =                     round(SegmentationOfActiveTrack{1,4});
                        obj.ActiveZCoordinate =                     round(SegmentationOfActiveTrack{1,5});
                        obj.MaskCoordinateList =                    SegmentationOfActiveTrack{1,6};
         
                    end
            
            
            
            
            
        end
                     
        function [obj] =                                            setThresholdToClickedPixel(obj)
            
             MyImageVolume =                                     obj.ImageVolume;

            
            myYCoordinate=                                      obj.ActiveYCoordinate;
            myXCoordinate =                                     obj.ActiveXCoordinate;
            myZCoordinate =                                     obj.ActiveZCoordinate;
            Channel =                                           obj.ActiveChannel;

            obj.Threshold =                                     MyImageVolume(myYCoordinate,myXCoordinate,myZCoordinate);
            
        end


          function [obj] =                                            autoDetectThresholdFromEdge(obj)


                function [Threshold,ThresholdRow] =              InterpretIntensityChanges(IntensityList)

                    IntensityList =                     double(IntensityList);
                    
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

            %% process data: this is "hand-made" probably better to use some MatLab function for this;

          
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

          
        function [obj] =                                                generateMaskByAutoThreshold(obj)
        %TRACKINGRESULTS_CONVERTMANUALCLICKTOMASK_SINGLEMASK Summary of this function goes here
        %   Detailed explanation goes here


            obj =                                               obj.createCroppedImage;
           obj.SegmentationType =                               'ThresholdingByEdgeDetection';

           [obj] =                                              obj.autoDetectThresholdFromEdge;
            obj =                                               obj.removePreviouslyTrackedPixelsFromCroppedImage;
           
            [obj] =                                              obj.createMaskCoordinateListByThreshold;
            
            for WideningIndex = 1: obj.WidenMaskAfterDetectionByPixels
                obj =                 obj.addRimToActiveMask;
            end
          
           

        end
        
        
           function [obj] =                                                generateMaskByEdgeDetection(obj)
        %TRACKINGRESULTS_CONVERTMANUALCLICKTOMASK_SINGLEMASK Summary of this function goes here
        %   Detailed explanation goes here


            obj =                                               obj.createCroppedImage;
           obj.SegmentationType =                               'MaskRecognitionByEdgeDetection';

         
            obj =                                               obj.removePreviouslyTrackedPixelsFromCroppedImage;
           
            [obj] =                                              obj.createMaskCoordinateListByEdgeDetection;
            
            for WideningIndex = 1: obj.WidenMaskAfterDetectionByPixels
                obj =                 obj.addRimToActiveMask;
            end
          
           

        end
        
        
        function [obj] =                                        generateMaskByClickingThreshold(obj)
            
            obj.SegmentationType =                              'Manual';
            
            obj =                                               obj.createCroppedImage; 
            obj =                                               obj.removePreviouslyTrackedPixelsFromCroppedImage;
            [obj] =                                             obj.setThresholdToClickedPixel;
            [obj] =                                             obj.createMaskCoordinateListByThreshold;
            %obj =
            %obj.removePreviouslyTrackedDuplicatePixels; % done before, otherwise connected pixels doesn't work;
            
            
            
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
            :);           


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


        function [obj] =                                          createMaskCoordinateListByEdgeDetection(obj)
            
            myCroppedImageVolume =                              obj.CroppedImageVolume;
            myCroppedImageVolumeMask =                          obj.createBinaryVolumeByEdgeDetection(myCroppedImageVolume);

            obj =                                               obj.resetSeedPositions(myCroppedImageVolumeMask);
            [FinalListWith3DCoordinates] =                      obj.convertConnectedPixelsIntoCoordinateList(myCroppedImageVolumeMask);
            obj.MaskCoordinateList =                            FinalListWith3DCoordinates;

            
        end
        

        function [obj] =                                            createMaskCoordinateListByThreshold(obj)
        %CREATELISTWITHMASKCOORDINATES create coordinate list by thresholding image;
        %   cropped image, threshold, seed position

        
                %% read data:

              
                myNewThreshold =                                    obj.Threshold;

                if isnan(myNewThreshold)
                    FinalListWith3DCoordinates = [];
                else
                    
                    
                    %% first verify that the seed coordinate is ok (this should be moved to a separate method;
                    
                    
                    myCroppedImageVolume =                      obj.CroppedImageVolume;
                    myCroppedImageVolumeMask =                  uint8(myCroppedImageVolume >= myNewThreshold) * 255;
                    obj =                                       obj.resetSeedPositions(myCroppedImageVolumeMask);
                    [FinalListWith3DCoordinates] =              obj.convertConnectedPixelsIntoCoordinateList(myCroppedImageVolumeMask);


                end
                
              

                %% create ouput:
                obj.MaskCoordinateList =                            FinalListWith3DCoordinates;

        end
        
        
            function [FinalListWith3DCoordinates] =      convertConnectedPixelsIntoCoordinateList(obj, myCroppedImageVolumeMask)


                    [CentralPlane, PlanesAbove, PlanesBelow, NumberOfPlanesAnalyzed] = obj.getConnectedPlaneSpecification;


                    %% create a cell for all coordinates in each analyzed plane and fill data for "middle plane;
                     ListWith3DCoordinatesOfAllConnectedPlanes =                                    cell(NumberOfPlanesAnalyzed,1);

                    MaskImageOfMiddlePlane =                                                        myCroppedImageVolumeMask(:,:,CentralPlane);
                    ListWith3DCoordinatesOfAllConnectedPlanes{CentralPlane,1} =                 obj.getConnectedPixels(MaskImageOfMiddlePlane, CentralPlane);


                    %% go through lower planes and find connected pixels in 3D:
                    for AnalyzedPlaneNumber = PlanesAbove
                        ConnectedStructuresInTargetPlane =                                          bwconncomp(myCroppedImageVolumeMask(:,:,AnalyzedPlaneNumber));
                        ListWithUpperPlanePixels =                                                  ListWith3DCoordinatesOfAllConnectedPlanes{AnalyzedPlaneNumber+1};
                        ListWith3DCoordinatesOfAllConnectedPlanes{AnalyzedPlaneNumber,1}=           obj.FindContactAreasInNeighborPlane(ConnectedStructuresInTargetPlane, ListWithUpperPlanePixels, AnalyzedPlaneNumber);

                    end


                    %% go through upper planes and find connected pixels in 3D:
                    for AnalyzedPlaneNumber = PlanesBelow
                         ConnectedStructuresInTargetPlane =                                         bwconncomp(myCroppedImageVolumeMask(:,:,AnalyzedPlaneNumber));
                        ListWithLowerPlanePixels =                                                  ListWith3DCoordinatesOfAllConnectedPlanes{AnalyzedPlaneNumber-1};
                        ListWith3DCoordinatesOfAllConnectedPlanes{AnalyzedPlaneNumber,1}=           obj.FindContactAreasInNeighborPlane(ConnectedStructuresInTargetPlane, ListWithLowerPlanePixels, AnalyzedPlaneNumber);


                    end


                    FinalListWith3DCoordinates =                        vertcat(ListWith3DCoordinatesOfAllConnectedPlanes{:});

                    % negative values may creep in during cropping and need to be elminated (actually not sure about this);
                    NegativeValuesOne =                                 FinalListWith3DCoordinates(:,1)<0; % 
                    NegativeValuesTwo =                                 FinalListWith3DCoordinates(:,2)<0;
                    NegativeValuesThree =                               FinalListWith3DCoordinates(:,3)<0;

                    NegativeValues =                                    max([NegativeValuesOne,NegativeValuesTwo, NegativeValuesThree], [], 2);
                    FinalListWith3DCoordinates(NegativeValues,:) =      [];



           end

        
        function obj =                                              resetSeedPositions(obj, myCroppedImageVolumeMask)
            
              
        
             ActivePixelIntensity = myCroppedImageVolumeMask(obj.SeedRow, obj.SeedColumn, obj.ActiveZCoordinate);
                                
                                if ActivePixelIntensity == 0 % if active pixel is zero (background) ;
                                    
                                    % find position of closest "full pixel"
                                    % (otherwise "background would be detected);
                                    
                                    % this is potentially dangerous because tracking may be continued on relatively distanc unrelated tracks: consider eliminating this option ;
                                    
                                    
                                    NumberOfPlanes =    size(myCroppedImageVolumeMask,3);
                                    BestRows =   nan(NumberOfPlanes,1);
                                    BestColumns= nan(NumberOfPlanes,1);
                                    Planes =     nan(NumberOfPlanes,1);
                                    for PlaneIndex =1:NumberOfPlanes
                                        
                                         [row, column] =                     find(myCroppedImageVolumeMask(:,:,PlaneIndex));
                                    
                                         if ~isempty(row)
                                             
                                            rowDifferences =                    obj.SeedRow-row;
                                            columnDifferences =                 obj.SeedColumn-column;

                                            distances =                         sqrt(rowDifferences.^2 + columnDifferences.^2);

                                            [~,SmallestDistanceIndex] =         min(distances);

                                            rowPositionOfBestFit =               round(row(SmallestDistanceIndex));
                                            columnPositionOfBestFit =            round(column(SmallestDistanceIndex));

                                            BestRows(PlaneIndex,1) =    rowPositionOfBestFit;
                                            BestColumns(PlaneIndex,1) =    columnPositionOfBestFit;
                                            Planes(PlaneIndex,1) =    PlaneIndex;
                                             else
                                                 BestRows(PlaneIndex,1) =    NaN;
                                            BestColumns(PlaneIndex,1) =    NaN;
                                            Planes(PlaneIndex,1) =    PlaneIndex;
                                             end

                                        end
                                    

                                        rowsToDelete =      abs(obj.ActiveZCoordinate-Planes)>3;

                                        BestRows(rowsToDelete,:) = [];
                                        BestColumns(rowsToDelete,:) = [];
                                        Planes(rowsToDelete,:) = [];

                                        rowDifferences =                    obj.SeedRow-BestRows;
                                        columnDifferences =                 obj.SeedColumn-BestColumns;

                                         distances =                         sqrt(rowDifferences.^2 + columnDifferences.^2);
                                        [~,SmallestDistanceIndex] =         min(distances);

                                        obj.SeedRow =                     BestRows(SmallestDistanceIndex);   
                                        obj.SeedColumn=                   BestColumns(SmallestDistanceIndex);   
                                        obj.ActiveZCoordinate=            Planes(SmallestDistanceIndex);      

                                    end
                           
                                    
                                
                      
            
            
        end
        
        function [obj]=                                             removePreviouslyTrackedPixelsFromCroppedImage(obj)
            
            
            
            ListWithPreviouslyTrackedPixels =                       obj.getAllPreviouslyTrackedPixels;
            [ListWithPreviouslyTrackedPixels] =                     convertPixelCoordinateToCroppedImage(obj, ListWithPreviouslyTrackedPixels);

            myCroppedImageVolume =                                  obj.CroppedImageVolume;
            [myCroppedImageVolume] =                                obj.removePixelsFromImage(ListWithPreviouslyTrackedPixels, myCroppedImageVolume);

            obj.CroppedImageVolume =                                myCroppedImageVolume;

        end
        
        function [Image] =                                          removePixelsFromImage(obj, PixelList, varargin)
            
            if length(varargin) ==1
                Image = varargin{1};
            else
                Image =                                                 obj.ImageVolume(:,:,obj.ActiveZCoordinate);

            end
            
            PixelList(PixelList(:,1)<=0,:) =                        [];
            PixelList(PixelList(:,2)<=0,:) =                        [];
            PixelList(PixelList(:,1)>size(Image,1),:) =             [];
            PixelList(PixelList(:,2)>size(Image,2),:) =             [];


            PixelList(isnan(PixelList(:,1)),:) = [];
            PixelList(isnan(PixelList(:,2)),:) = [];
          
            
            
            NumberOfPixels = size(PixelList,1);
            for PixelIndex = 1:NumberOfPixels % there should be a more efficient way to do this:
                Image(PixelList(PixelIndex,1),PixelList(PixelIndex,2)) = 0;

            end
            
            
        end
        
        
        
        function [obj] =                                            removePreviouslyTrackedDuplicatePixels(obj)

            
            %% read data:

            CurrentMaskPixels =                     obj.MaskCoordinateList;
            
            %% process data:
            
            if isempty(CurrentMaskPixels)
                return
            end
            
          
            PixelListFromOtherTrackedCells =        obj.getAllPreviouslyTrackedPixels;
             if ~isempty(PixelListFromOtherTrackedCells)
                CurrentMaskPixels(ismember(CurrentMaskPixels,PixelListFromOtherTrackedCells,'rows'),:) = [];

             end

             %% return data to object:
             obj.MaskCoordinateList =                                   CurrentMaskPixels;


        end
        
        

        
            function [obj] =       RemoveImageData(obj)
            
            obj.ImageVolume = [];
            obj.CroppedImageVolume = [];
            obj.MaskCoordinateList = [];
            obj.SegmentationOfCurrentFrame = [];
            
        end
          
        
                
                   
            function obj =          addRimToActiveMask(obj)
            
            
            ListWithCoordinates =               obj.MaskCoordinateList;
            [FinalImage]=                       obj.convertCoordinatesToImage(ListWithCoordinates); 
      
             ErodedImage =                      imdilate(FinalImage, strel('disk', 1));
             
             [Coordinates] =                    convertImageToCoordinates(obj,ErodedImage);
             obj.MaskCoordinateList =           Coordinates;
             
             
             [obj] =                            obj.removePreviouslyTrackedDuplicatePixels;

             
        end
        
        
          function obj =          removeRimFromActiveMask(obj)
            
            
            ListWithCoordinates =               obj.MaskCoordinateList;
            [FinalImage]=                       obj.convertCoordinatesToImage(ListWithCoordinates); 
      
             ErodedImage =                      imerode(FinalImage, strel('disk', 1));
             
             [Coordinates] =                    convertImageToCoordinates(obj,ErodedImage);
             obj.MaskCoordinateList =           Coordinates;
             

             
        end
                    
                    
   
           function obj = setActiveCoordinateByBrightestPixels(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            
                % set the active coordinate by the brightest pixel of the
                % current mask;
                CoordinatesWithMaximumIntensity =               obj.getBrightestPixelsOfActiveMask;


                CoordinateWithMaximumIntensity =            round(median(CoordinatesWithMaximumIntensity(:,1:3), 1));
                obj.ActiveYCoordinate =                     CoordinateWithMaximumIntensity(1,1);
                obj.ActiveXCoordinate =                     CoordinateWithMaximumIntensity(1,2);
                obj.ActiveZCoordinate =                     CoordinateWithMaximumIntensity(1,3);

        end
        
       
        
        %% views:
        
          function highLightAutoEdgeDetection(obj, ImageHandle)
            
              if isempty(obj.SegmentationType)
                 return 
                  
              end
              
              switch obj.SegmentationType
                  
                  case 'ThresholdingByEdgeDetection'
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
              
              
              
          
            
            
        end
        

        %% helper functions:
                                
        function [Image]= convertCoordinatesToImage(obj,ListWithCoordinates)
            
             Image(obj.MaximumRows,obj.MaximumColumns) = 0;
             NumberOfCoordinates =  size(ListWithCoordinates,1);
             
             for CurrentCoordinateIndex = 1:NumberOfCoordinates
                 Image(ListWithCoordinates(CurrentCoordinateIndex,1),ListWithCoordinates(CurrentCoordinateIndex,2),ListWithCoordinates(CurrentCoordinateIndex,3)) = 1;  
             end
             
              
           
            
            
        end
        
        function [Coordinates] =    convertRectangleLimitToCoordinates(obj,Rectangle)
            
            Image(Rectangle(2):Rectangle(2)+Rectangle(4)-1,Rectangle(1):Rectangle(1)+Rectangle(3)-1) = 1;
            
            [Coordinates] =    obj.convertImageToCoordinates(Image);
            
            
        end
        
        function [collectedCoordinates] =    convertImageToCoordinates(obj,Image)
            
            NumberOfPlanes = size(Image,3);
            
            CorrdinateCell = cell(NumberOfPlanes,1);
            for CurrentPlane =1 :NumberOfPlanes
                
                 [rows, columns] =           find(Image(:,:,CurrentPlane));
            
                myCoordinates =    [rows, columns];


                myCoordinates(myCoordinates(:,1)<=0,:) = [];
                myCoordinates(myCoordinates(:,2)<=0,:) = [];
                myCoordinates(myCoordinates(:,1)>obj.MaximumRows,:) =  [];
                myCoordinates(myCoordinates(:,2)>obj.MaximumColumns,:) = [];


                 myCoordinates(:,3) =     CurrentPlane;

                 CorrdinateCell{CurrentPlane,1} =   myCoordinates;
                
            end
            
            collectedCoordinates = vertcat(CorrdinateCell{:});
     
            
        end
         
        
     

        function [ListWithPixels] =                                 CalibratePixelList(obj,ListWithPixels)

                    %% add back rows and columns and were removed during cropping of source image:
                    ListWithPixels(:,1) =               ListWithPixels(:,1) + obj.NumberOfLostRows;
                    ListWithPixels(:,2) =               ListWithPixels(:,2) + obj.NumberOfLostColumns;

        end
        
        function [ListWithPixels] =                                 convertPixelCoordinateToCroppedImage(obj, ListWithPixels)
            
            %% add back rows and columns and were removed during cropping of source image:
                    ListWithPixels(:,1) =               ListWithPixels(:,1) - obj.NumberOfLostRows;
                    ListWithPixels(:,2) =               ListWithPixels(:,2) - obj.NumberOfLostColumns;
            
            
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

