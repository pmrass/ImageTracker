classdef PMSegmentationCapture
    %PMTRACKINGCAPTURE for segmentation of given image volume;
    %   Detailed explanation goes here
    
    properties (Access = private)


        %% temporary data: these data are derived from the original movie and are needed only temporarily for analysis;
        % no permanent record desired:
        FieldNamesForSegmentation =         {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        SegmentationOfCurrentFrame
        CurrentTrackId
        
        SegmentationType

        ImageVolume
        MaximumRows
        MaximumColumns
        
        MaskCoordinateList
        AllowedExcessSizeFactor


        %% settings that define how segmentation/tracking is done;
        % these should be stored permanently because they will give insight into how the segmentation was obtained;
        % this could be useful in the future when 
        ActiveXCoordinate
        ActiveYCoordinate
        
        ActiveChannel =                         2
        
        MinimumCellRadius =                     0  % leave at zero by default, otherwise 1 pixel coordinates will be deleted;
        MaximumCellRadius =                     50 %30
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

        ShowSegmentationProgress =          true

        FactorForThreshold =                0.3;
        
    end
    
    properties (Access = private)
        
        BlackedOutPixels = zeros(0,3);
        ActiveZCoordinate
        SizeForFindingCellsByIntensity
        AccumulatedSegmentationFailures = 0
    end
    
    
    methods
        
        function obj = emptyOutBlackedOutPixels(obj) 
            obj.BlackedOutPixels = zeros(0,3);
        end
        
        
        function obj = setBlackedOutPixels(obj, Value)
            obj.BlackedOutPixels = Value;
        end
        
        function obj = set.BlackedOutPixels(obj, Value)
            assert(isnumeric(Value) && ismatrix(Value), 'Wrong input.')
            obj.BlackedOutPixels = Value;
            
        end
        
        function failurs = getAccumulatedSegmentationFailures(obj)
            failurs = obj.AccumulatedSegmentationFailures;
        end
        
        function obj = PMSegmentationCapture(varargin)
            %PMTRACKINGCAPTURE Construct an instance of this class
            %   Detailed explanation goes here

            NumberOfInputArguments =    length(varargin);
            
            switch NumberOfInputArguments
                
                case 0
                    return
                    
                case 1 % one input argument means that the current PMMovieController is the input argument:
                    MovieControllerObject =      varargin{1};
                    [obj]=                       obj.resetWithMovieController(MovieControllerObject);
                    
                case 2 % manual tracking: pixel-list and type "manual";

                    if strcmp(class(varargin{1}),  'PMMovieController')
                        
                        if length(varargin{2}) == 1
                             obj.ActiveChannel =             varargin{2};
                             [obj]=                          obj.resetWithMovieController(varargin{1});
                             
                        elseif length(varargin{2}) == 3
                            [obj]=                          obj.resetWithMovieController(varargin{1});
                            obj.ActiveYCoordinate =         varargin{2}(1);
                            obj.ActiveXCoordinate =         varargin{2}(2);
                            obj.ActiveZCoordinate =         varargin{2}(3);
                            obj.MaskCoordinateList =        varargin{2};
                        elseif length(varargin{2}) == 4
                            obj.ActiveChannel =             varargin{2}(4);
                            [obj]=                          obj.resetWithMovieController(varargin{1});
                            obj.ActiveYCoordinate =         varargin{2}(1);
                            obj.ActiveXCoordinate =         varargin{2}(2);
                            obj.ActiveZCoordinate =         varargin{2}(3);
                            obj.ActiveChannel =             varargin{2}(4);
                            obj.MaskCoordinateList =        varargin{2}(1:3);
                        else
                            error('Wrong argument type')
                        end
                        
                        
                        
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
        
        function obj = setActiveChannel(obj, Value)
           obj.ActiveChannel = Value; 
        end
        
        function obj = set.ActiveChannel(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && Value >= 1, 'Wrong argument type.')
            obj.ActiveChannel = Value;
        end
        
        function obj = set.ActiveYCoordinate(obj, Value)
            assert(isnumeric(Value) && isscalar(Value)  && Value >= 1, 'Wrong argument type.')
            obj.ActiveYCoordinate = Value;
        end
        
        function obj = set.ActiveXCoordinate(obj, Value)
            assert(isnumeric(Value) && isscalar(Value)  && Value >= 1, 'Wrong argument type.')
            obj.ActiveXCoordinate = Value;
        end
        
        function obj = setActiveZCoordinate(obj, Value)
            obj.ActiveZCoordinate = Value;
        end
        
        function obj = set.ActiveZCoordinate(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && Value >= 1, 'Wrong argument type.')
            obj.ActiveZCoordinate = Value;
        end
        
        %% MaskCoordinateList
        function obj = set.MaskCoordinateList(obj, Value)
            assert(isnumeric(Value) && ismatrix(Value) && size(Value,2) == 3, 'Wrong argument type.')
            obj.MaskCoordinateList = Value;
        end
        
        function value = getMaskXCoordinateList(obj)
           value = obj.MaskCoordinateList; 
           value = value(:, 2);
        end
        
        function value = getMaskYCoordinateList(obj)
           value = obj.MaskCoordinateList; 
           value = value(:, 1);
        end
        
        function value = getMaskZCoordinateList(obj)
           value = obj.MaskCoordinateList; 
           value = value(:, 3);
        end
         
        function CandidateXCentroid = getXCentroid(obj)
            CandidateXCentroid =        mean(obj.getMaskXCoordinateList);
        end
        
        function CandidateYCentroid = getYCentroid(obj)
            CandidateYCentroid =        mean(obj.getMaskYCoordinateList);
        end
        
        function pixelNumber = getNumberOfPixels(obj)
            pixelNumber =   size(obj.MaskCoordinateList,1); 
        end                             

        function AllowedPixelNumber = getMaximumPixelNumber(obj)
             AllowedPixelNumber =         round(size(obj.MaskCoordinateList,1)*obj.AllowedExcessSizeFactor); 
        end
        
        function type = getSegmentationType(obj)
           type = obj.SegmentationType; 
        end
        
       
        function obj = setSizeForFindingCellsByIntensity(obj, Value)
           obj.SizeForFindingCellsByIntensity = Value;
            
        end
        
        function obj = set.SizeForFindingCellsByIntensity(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.SizeForFindingCellsByIntensity = Value;
        end
        
         
         %% performAutothresholdSegmentationAroundBrightestAreaInImage
            function obj = performAutothresholdSegmentationAroundBrightestAreaInImage(obj)
              
                obj.CurrentTrackId =         NaN; % have to do this to also exclude currently active track pixels;
                obj =                       obj.addPreviouslTrackedPixelsToBlackedOutPixels;
                
                CleanedupImage =                obj.removePixelsFromImage(obj.BlackedOutPixels);
                figure(20)
                imagesc(CleanedupImage)

                [xCoordinate, yCoordinate, coordinateList] =    obj.detectBrightestAreaInImage(CleanedupImage);
                
                obj =                     obj.addPixelsToBlackedOutPixels(coordinateList);
                obj.ActiveYCoordinate =   yCoordinate;
                obj.ActiveXCoordinate =   xCoordinate;
                obj =                     obj.generateMaskByAutoThreshold;

                 if ~obj.getActiveShape.testShapeValidity
                            obj.AccumulatedSegmentationFailures = obj.AccumulatedSegmentationFailures + 1;    
                 end
                              
            end
            
            function obj = addPreviouslTrackedPixelsToBlackedOutPixels(obj)
                obj.BlackedOutPixels =       unique([obj.getAllPreviouslTrackedPixelsInPlane(obj.ActiveZCoordinate); obj.BlackedOutPixels], 'rows');
                
            end
            
            function PreviouslyTrackedPixels = getAllPreviouslTrackedPixelsInPlane(obj, Plane)
                PreviouslyTrackedPixels =                           obj.getAllPreviouslyTrackedPixels; 
                PreviouslyTrackedPixels(PreviouslyTrackedPixels(:,3) ~= obj.ActiveZCoordinate,:) =    []; % this is just for current plane; generalize this more;
            end
            
            function PixelListFromOtherTrackedCells = getAllPreviouslyTrackedPixels(obj)

                CellWithMaskData =              obj.SegmentationOfCurrentFrame;
                if isempty(obj.SegmentationOfCurrentFrame)
                    PixelListFromOtherTrackedCells = zeros(0,3);
                else
                    
                    if ~isempty(obj.CurrentTrackId) && ~isnan(obj.CurrentTrackId) % exclude currently tracked cell (not to block re-tracking)
                        RowWithCurrentTrack =                               cell2mat(CellWithMaskData(:, strcmp('TrackID', obj.FieldNamesForSegmentation))) == obj.CurrentTrackId;  
                        CellWithMaskData(RowWithCurrentTrack,:) =           [];
                    end
                    PixelListFromOtherTrackedCells =        CellWithMaskData(:,strcmp('ListWithPixels_3D', obj.FieldNamesForSegmentation));
                    PixelListFromOtherTrackedCells =        vertcat(PixelListFromOtherTrackedCells{:});

                    if isempty(PixelListFromOtherTrackedCells)
                        PixelListFromOtherTrackedCells = zeros(0,3);
                    end
                end
            end
            
            function [Image] =                                          removePixelsFromImage(obj, PixelList, varargin)
                if length(varargin) ==1
                    Image = varargin{1};
                else
                    Image =      obj.ImageVolume(:, :, obj.ActiveZCoordinate);
                end

                PixelList =         obj.removeCoordinatesThatAreOutOfRangeFromList(PixelList, Image);
                NumberOfPixels = size(PixelList,1);
                for PixelIndex = 1 : NumberOfPixels % there should be a more efficient way to do this:
                    Image(PixelList(PixelIndex, 1), PixelList(PixelIndex, 2)) = 0;
                end


            end
            
            function PixelList = removeCoordinatesThatAreOutOfRangeFromList(obj, PixelList, Image)
                PixelList(PixelList(:,1)<=0,:) =                        [];
                PixelList(PixelList(:,2)<=0,:) =                        [];
                PixelList(PixelList(:,1)>size(Image,1),:) =             [];
                PixelList(PixelList(:,2)>size(Image,2),:) =             [];
                PixelList(isnan(PixelList(:,1)),:) = [];
                PixelList(isnan(PixelList(:,2)),:) = [];
            end
                          
            function [xCoordinate,yCoordinate,CoordinatesList] = detectBrightestAreaInImage(obj, Image)
            IntensityMatrix =   zeros(size(Image,1)-obj.SizeForFindingCellsByIntensity,size(Image,2)-obj.SizeForFindingCellsByIntensity);
            for RowIndex = 1:size(Image,1)-obj.SizeForFindingCellsByIntensity+1
                for ColumnIndex = 1:size(Image,2)-obj.SizeForFindingCellsByIntensity+1
                    Area =                                      Image(RowIndex:RowIndex+obj.SizeForFindingCellsByIntensity-1,ColumnIndex:ColumnIndex+obj.SizeForFindingCellsByIntensity-1);            
                    IntensityMatrix(RowIndex,ColumnIndex) =     median(Area(:));     
                end  
            end
            
            [a,listWithRows] = max(IntensityMatrix);
            [c,column] = max(a);
            yCoordinate = listWithRows(column) + round(obj.SizeForFindingCellsByIntensity/2);
            xCoordinate = column + round(obj.SizeForFindingCellsByIntensity/2);
            [CoordinatesList] =    obj.convertRectangleLimitToYXZCoordinates([column  listWithRows(column) obj.SizeForFindingCellsByIntensity obj.SizeForFindingCellsByIntensity]);
            CoordinatesList(:,3) =     obj.ActiveZCoordinate;  
            end
         
            function [Coordinates] =    convertRectangleLimitToYXZCoordinates(obj,Rectangle)
            Image(Rectangle(2):Rectangle(2)+Rectangle(4)-1,Rectangle(1):Rectangle(1)+Rectangle(3)-1) = 1;
            [Coordinates] =    obj.convertImageToYXZCoordinates(Image);
        end
              
            function [collectedCoordinates] =    convertImageToYXZCoordinates(obj, Image)
                NumberOfPlanes = size(Image,3);
                CorrdinateCell = cell(NumberOfPlanes,1);
                for CurrentPlane =1 :NumberOfPlanes
                    [rows, columns] =       find(Image(:,:,CurrentPlane));
                    addedCoordinates =      [ rows, columns];
                    addedCoordinates(addedCoordinates(:,1) <= 0, :) = [];
                    addedCoordinates(addedCoordinates(:,2) <= 0, :) = [];
                    addedCoordinates(addedCoordinates(:,1) > obj.MaximumRows,:) =  [];
                    addedCoordinates(addedCoordinates(:,2) > obj.MaximumColumns,:) = [];
                    addedCoordinates(:,3) =     CurrentPlane;
                    CorrdinateCell{CurrentPlane,1} =   addedCoordinates;
                end
                collectedCoordinates = vertcat(CorrdinateCell{:});
            end
    
            function obj = addPixelsToBlackedOutPixels(obj, coordinateList)
                  obj.BlackedOutPixels =     [obj.BlackedOutPixels; coordinateList]; % remember positions that have been tried (avoid multiple tries);

            end
         
            %% testPixelValidity
            function pixelCheckSucceeded = testPixelValidity(obj)
              pixelCheckSucceeded = getActiveShape.testShapeValidity;
           end
           
            function myShape = getActiveShape(obj)
                myShape = obj.getShapeForCoordinateList(obj.MaskCoordinateList);
            end
          
            function myShape = getShapeForCoordinateList(obj, CoordinateList)
                myShape =   PMShape(CoordinateList, 'YXZ');
                myShape  =  myShape.setLimits(obj.MinimumCellRadius, obj.MaximumCellRadius);
                myShape =   myShape.setDimensions(obj.getWithOfCroppedImage, obj.getHeightOfCroppedImage);
                myShape =   myShape.setOutputFormat('YXZ');
            end
    
           
  
        %% resetWithMovieController
        function [obj]=               resetWithMovieController(obj, MovieController)          
                obj.ImageVolume =                       MovieController.getActiveImageVolumeForChannel(obj.ActiveChannel);
                obj.SegmentationOfCurrentFrame =        MovieController.LoadedMovie.getUnfilteredSegmentationOfCurrentFrame;
                obj =                                   obj.setActiveStateBySegmentationCell(MovieController.LoadedMovie.getUnfilteredSegmentationOfActiveTrack);
        end
        
        function obj = setActiveStateBySegmentationCell(obj, SegmentationOfActiveTrack) 
            if ~isempty(SegmentationOfActiveTrack)
                    obj.CurrentTrackId =                        SegmentationOfActiveTrack{1,1};
                    obj.ActiveYCoordinate =                     round(SegmentationOfActiveTrack{1,3});
                    obj.ActiveXCoordinate =                     round(SegmentationOfActiveTrack{1,4});
                    obj.ActiveZCoordinate =                     round(SegmentationOfActiveTrack{1,5});
                    obj.MaskCoordinateList =                    SegmentationOfActiveTrack{1,6};
             end
        end
                     
         %% generateMaskByEdgeDetectionForceSizeBelow:
        function obj=    generateMaskByEdgeDetectionForceSizeBelow(obj, MaximumPixelNumber)
            
            NumberOfPixelsInNewMask =        MaximumPixelNumber + 20;
            while NumberOfPixelsInNewMask > MaximumPixelNumber
                obj.PixelShiftForEdgeDetection =    PixelShift;
                obj =                               obj.generateMaskByAutoThreshold;
                NumberOfPixelsInNewMask =           obj.getNumberOfPixels; 
                PixelShift =      PixelShift + 1; 
                if PixelShift > obj.MaximumCellRadius/1.5
                   break 
                end
            end
            
        end
       

        function [obj] =                generateMaskByAutoThreshold(obj)
            obj.SegmentationType =      'ThresholdingByEdgeDetection';
            obj =                       obj.getThresholdFromEdge;
             ThresholdedImage =        obj.thresholdImageByThreshold(obj.getCroppedImageWithExistingMasksRemoved, obj.getThresholdFromEdge);
            obj.MaskCoordinateList =        obj.convertConnectedPixelsIntoCoordinateList(ThresholdedImage);
            for WideningIndex = 1: obj.WidenMaskAfterDetectionByPixels
                obj =                 obj.addRimToActiveMask;
            end

        end
        
          function myCroppedImageVolumeMask = thresholdImageByThreshold(obj, Image, myThreshold)
            assert(isnumeric(myThreshold) && isscalar(myThreshold) && ~isnan(myThreshold), 'Wrong input')
            myCroppedImageVolumeMask =     uint8(Image >= myThreshold) * 255;
          end
      
         function Threshold =                 getThresholdFromEdge(obj)
            myCroppedImageVolume =              obj.getCroppedImageSource;
            RowIntensities =                    myCroppedImageVolume(obj.getSeedRow, : , obj.ActiveZCoordinate);
            [ThresholdOne, ThresholdOneRow] =   obj.InterpretIntensityChanges(double(RowIntensities));
            [ThresholdTwo, ThresholdTwoRow] =   obj.InterpretIntensityChanges(double(flip(RowIntensities)));

            ColumIntensities =                      myCroppedImageVolume(:, obj.getSeedColumn, obj.ActiveZCoordinate);
            [ThresholdThree, ThresholdThreeRow] =  obj.InterpretIntensityChanges(double(ColumIntensities));
            [ThresholdFour, ThresholdFourRow] =    obj.InterpretIntensityChanges(double(flip(ColumIntensities)));

            obj.ListWithEdgePositions =         [ThresholdOneRow; ThresholdTwoRow; ThresholdThreeRow; ThresholdFourRow];
            obj.ListWithThresholds =            [ThresholdOne; ThresholdTwo; ThresholdThree; ThresholdFour];
            Threshold           =           mean([ThresholdOne, ThresholdTwo, ThresholdThree, ThresholdFour]) * obj.FactorForThreshold;

         end
         
         function SeedRow =               getSeedRow(obj)
                    SeedRow =          obj.ActiveYCoordinate - obj.getRowsLostFromCropping;                                   
           end
           
        function SeedColumn =           getSeedColumn(obj)
                    SeedColumn =       obj.ActiveXCoordinate - obj.getColumnsLostFromCropping;                             
        end
        
        function [Threshold,ThresholdRow] =              InterpretIntensityChanges(obj, IntensityList)

            IntensityDifferences =    diff(IntensityList);
            StartPixels =             1:length(IntensityDifferences)-obj.NumberOfPixelsForBackground+1;
            EndPixels =               StartPixels + obj.NumberOfPixelsForBackground-1;
            DifferencesAtPeriphery =  arrayfun(@(x,y) max(IntensityDifferences(x:y)), StartPixels, EndPixels);
            BackgroundDifference =    max(DifferencesAtPeriphery) * obj.BoostBackgroundFactor;
            DifferenceLimit =          ((BackgroundDifference + max(IntensityDifferences)) / 2) * 0.3;

            if max(IntensityDifferences) < DifferenceLimit
                ThresholdRow =  NaN;
                Threshold =     NaN;
            else
                % around the place where a higher intensity difference can be found: this should be ;;
                ThresholdRow =       find(IntensityDifferences >= DifferenceLimit, 1, 'first') + obj.PixelShiftForEdgeDetection;
                Threshold =          IntensityList(ThresholdRow);
            end

        end


        function obj =          addRimToActiveMask(obj)
             DilatedImage =             imdilate(obj.convertCoordinatesToImage(obj.MaskCoordinateList), strel('disk', 1));
             obj.MaskCoordinateList =   obj.convertImageToYXZCoordinates(DilatedImage);
             obj =                      obj.removePreviouslyTrackedDuplicatePixels;
        end
        
        function [Image]= convertCoordinatesToImage(obj,ListWithCoordinates)
            Image(obj.MaximumRows, obj.MaximumColumns) = 0;
            for index = 1:size(ListWithCoordinates,1)
                Image(ListWithCoordinates(index,1),ListWithCoordinates(index,2),ListWithCoordinates(index,3)) = 1;  
            end 
        end
        
    
        
          function [obj] =       removePreviouslyTrackedDuplicatePixels(obj)
            if isempty(obj.MaskCoordinateList)
            else
                 if ~isempty(obj.getAllPreviouslyTrackedPixels)
                    obj.MaskCoordinateList(ismember(obj.MaskCoordinateList, obj.getAllPreviouslyTrackedPixels,'rows'),:) = [];
                 end
            end
          end
        

            
          function [ListWithPixels] =       addBackCutoffFromCroppingToCoordinateList(obj, ListWithPixels)
                ListWithPixels(:,1) =               ListWithPixels(:,1) + obj.getRowsLostFromCropping;
                ListWithPixels(:,2) =               ListWithPixels(:,2) + obj.getColumnsLostFromCropping;
          end

          %% generateMaskByClickingThreshold
        function [obj] =                     generateMaskByClickingThreshold(obj)
            obj.SegmentationType =          'Manual';
            ThresholdedImage =              obj.thresholdImageByThreshold(obj.getCroppedImageWithExistingMasksRemoved, obj.getThresholdToClickedPixel);
            obj.MaskCoordinateList =        obj.convertConnectedPixelsIntoCoordinateList(ThresholdedImage);
            obj =                           obj.showMaskDetectionByThresholding(ThresholdedImage);
        end

        function value = getMaskCoordinateList(obj)
            value = obj.getActiveShape.getCoordinates;
        end

        function Threshold =                getThresholdToClickedPixel(obj)
            Threshold =      obj.ImageVolume(obj.ActiveYCoordinate, obj.ActiveXCoordinate, obj.ActiveZCoordinate);
        end

        function [CoordinatesOfAllPlanes] =  convertConnectedPixelsIntoCoordinateList(obj, myCroppedImageVolumeMask)
            CoordinatesOfAllPlanes =  obj.convertConnectedPixelsIntoCoordinateListInternal(myCroppedImageVolumeMask);
        end
       
        %% calculateSeedStatistics
       function [obj]=                                             calculateSeedStatistics(obj)

           % not sure what this is good for:
            myWindowSize =                                      obj.SeedWindowSize;
            myCroppedWindow =                                   obj.getCroppedImageSource;
            myZCoordinate =                                     obj.ActiveZCoordinate;

            SeedValues =                                                double(myCroppedWindow(...
            MaximumRadiusInside - myWindowSize : MaximumRadiusInside + myWindowSize, ...
            MaximumRadiusInside - myWindowSize : MaximumRadiusInside + myWindowSize, ...
            myZCoordinate));

            SeedValues =                                            SeedValues(:);
            MySeedMedian =                                          median(SeedValues);
            MySeedStandardDeviation =                               std(SeedValues);

            obj.SeedMedian  =                                       MySeedMedian;
            obj.SeedStandardDeviation =                             MySeedStandardDeviation;


       end

        %% RemoveImageData
       function [obj] =       RemoveImageData(obj)
            obj.ImageVolume = [];
            obj.MaskCoordinateList = zeros(0,3);
            obj.SegmentationOfCurrentFrame = [];
            
       end
       
        %% removeRimFromActiveMask
       function obj =          removeRimFromActiveMask(obj)
            
            
            ListWithCoordinates =               obj.MaskCoordinateList;
            [FinalImage]=                       obj.convertCoordinatesToImage(ListWithCoordinates); 
      
             ErodedImage =                      imerode(FinalImage, strel('disk', 1));
             
             [Coordinates] =                    convertImageToYXZCoordinates(obj,ErodedImage);
             obj.MaskCoordinateList =           Coordinates;  
       end
   
       %% setActiveCoordinateByBrightestPixels
       function obj = setActiveCoordinateByBrightestPixels(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
                CoordinateWithMaximumIntensity =            round(median(obj.getBrightestPixelsOfActiveMask(:,1:3), 1));
                obj.ActiveYCoordinate =                     CoordinateWithMaximumIntensity(1,1);
                obj.ActiveXCoordinate =                     CoordinateWithMaximumIntensity(1,2);
                obj.ActiveZCoordinate =                     CoordinateWithMaximumIntensity(1,3);

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
        
         function PixelIntensities = getPixelIntensitiesOfActiveMask(obj)
            PreCoordinateList =                     obj.MaskCoordinateList;
            AfterImageVolume =                      obj.ImageVolume;
            PixelIntensities =                      double(arrayfun(@(row,column,plane) AfterImageVolume(row,column,plane), PreCoordinateList(:,1),PreCoordinateList(:,2),PreCoordinateList(:,3)));
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
        
  
   

    end
    
    methods (Access = private)
        
        %% getCropImageObjectForImage
          function object = getCropImageObjectForImage(obj, Image)
              object = PMCropImage(Image, ...
                  obj.getMinimumColumnForImageCropping, ...
                  obj.getMaximumColumnForImageCropping, ...
                  obj.getMinimumRowForImageCropping, ...
                  obj.getMaximumRowForImageCropping);
          end
        
        function MinimumRow =      getMinimumRowForImageCropping(obj)
            MinimumRow =       obj.ActiveYCoordinate - obj.MaximumDisplacement;
            if MinimumRow < 1
                MinimumRow = 1;
            end 
        end

        function MaximumRow =      getMaximumRowForImageCropping(obj)
            MaximumRow =          obj.ActiveYCoordinate + obj.MaximumDisplacement;
            if MaximumRow > obj.MaximumRows
                MaximumRow =      obj.MaximumRows;
            end
         end
        
          function MinimumColumn = getMinimumColumnForImageCropping(obj)
                MinimumColumn =        obj.ActiveXCoordinate - obj.MaximumDisplacement;
                if MinimumColumn<1
                    MinimumColumn = 1;
                end
          end
        
        function MaximumColumn =   getMaximumColumnForImageCropping(obj)
            MaximumColumn =            obj.ActiveXCoordinate + obj.MaximumDisplacement;
            if MaximumColumn>obj.MaximumColumns 
                MaximumColumn = obj.MaximumColumns ;
            end  
        end
        
        
           %% 1a: getCroppedImageWithExistingMasksRemoved
          function Image =                   getCroppedImageWithExistingMasksRemoved(obj)
            ListWithPreviouslyTrackedPixels =   obj.translateCoordinatesToMatchCroppedImage(obj.getAllPreviouslyTrackedPixels);
            Image =            obj.removePixelsFromImage(ListWithPreviouslyTrackedPixels, obj.getCroppedImageSource);
          end
          
          function image =       getCroppedImageSource(obj)
                image = obj.getCropImageObjectForImage(obj.ImageVolume).getImage;
          end
          
        
        function [ListWithPixels] =         translateCoordinatesToMatchCroppedImage(obj, ListWithPixels)
            ListWithPixels(:,1) =    ListWithPixels(:,1) - obj.getRowsLostFromCropping;
            ListWithPixels(:,2) =    ListWithPixels(:,2) - obj.getColumnsLostFromCropping;
        end
        
        function lostRows =                 getRowsLostFromCropping(obj)
            lostRows =         obj.getMinimumRowForImageCropping - 1;
        end
        
        function lostColumns =              getColumnsLostFromCropping(obj)
            lostColumns =         obj.getMinimumColumnForImageCropping  - 1;   
        end
        
        function width =                    getWithOfCroppedImage(obj)
            width = length(obj.getMinimumColumnForImageCropping : obj.getMaximumColumnForImageCropping);
        end
        
        function height =                   getHeightOfCroppedImage(obj)
            height = length(obj.getMinimumRowForImageCropping : obj.getMaximumRowForImageCropping);
        end
        
        
        
        %% convertConnectedPixelsIntoCoordinateListInternal
        function [CoordinatesOfAllPlanes] =  convertConnectedPixelsIntoCoordinateListInternal(obj, myCroppedImageVolumeMask)
            
            [CentralPlane, PlanesAbove, PlanesBelow, NumberOfPlanesAnalyzed] = obj.getConnectedPlaneSpecification(myCroppedImageVolumeMask);

            coordinatesPerPlane =                   cell(NumberOfPlanesAnalyzed,1);
            coordinatesPerPlane{CentralPlane,1} =   obj.getConnectedPixels(myCroppedImageVolumeMask(:,:,CentralPlane), CentralPlane);

            for planeIndex = PlanesAbove
                coordinatesPerPlane{planeIndex,1}=   obj.FindContactAreasInNeighborPlane(bwconncomp(myCroppedImageVolumeMask(:,:,planeIndex)), coordinatesPerPlane{planeIndex+1}, planeIndex);
            end

            for planeIndex = PlanesBelow
                coordinatesPerPlane{planeIndex,1}=   obj.FindContactAreasInNeighborPlane(bwconncomp(myCroppedImageVolumeMask(:,:,planeIndex)), coordinatesPerPlane{planeIndex-1}, planeIndex);
            end

            CoordinatesOfAllPlanes =       vertcat(coordinatesPerPlane{:});
            CoordinatesOfAllPlanes =        obj.removeNegativeCoordinates(CoordinatesOfAllPlanes);
            
        end
        
        
          function CoordinatesOfAllPlanes = removeNegativeCoordinates(obj, CoordinatesOfAllPlanes)
                NegativeValuesOne =            CoordinatesOfAllPlanes(:,1) < 0;
                NegativeValuesTwo =            CoordinatesOfAllPlanes(:,2) < 0;
                NegativeValuesThree =          CoordinatesOfAllPlanes(:,3) < 0;

                rowsWithNegativeValues =      max([NegativeValuesOne, NegativeValuesTwo, NegativeValuesThree], [], 2);
                CoordinatesOfAllPlanes(rowsWithNegativeValues,:) =      [];
          end
               
        function [CentralPlane, PlanesAbove, PlanesBelow, numberOfPlanes] = getConnectedPlaneSpecification(obj, myCroppedImageVolumeMask)
         
            CentralPlane =    obj.getOptimizedPlaneForSeed(myCroppedImageVolumeMask);
            ZStart =          max([ 1 obj.ActiveZCoordinate - obj.PlaneNumberAboveAndBelow]);
            ZEnd =            min([ obj.ActiveZCoordinate + obj.PlaneNumberAboveAndBelow size(obj.ImageVolume, 3)]);
            numberOfPlanes =  length(ZStart:ZEnd);
            PlanesAbove =     CentralPlane -1 : -1 : ZStart; % maybe include more checks: e.g. make isnan or empty when no values exist;
            PlanesBelow =     CentralPlane + 1 : 1 : ZEnd;
        end
        
          function [myActiveZCoordinate] = getOptimizedPlaneForSeed(obj, myCroppedImageVolumeMask)
             
                if myCroppedImageVolumeMask(obj.getSeedRow, obj.getSeedColumn, obj.ActiveZCoordinate) == 0 
                    %% this should be rewritten, not very clear;
                    % main point: if the current seed is on an empty pixel (for whatever reason) find the closest full pixel to this point;
                    
                    %% I am not sure if all of this is needed;
                    % now it is done differently
                    % 1st: find closest plane with full pixel;
                    % 2nd: and this is done later separately: find closest pixel in the target plane;
                    MaximumPlaneLimit = 3;
                    % find position of closest "full pixel"
                    % (otherwise "background would be detected);
                    % this is potentially dangerous because tracking may be continued on relatively distanc unrelated tracks: consider eliminating this option ;

                    NumberOfPlanes =        size(myCroppedImageVolumeMask, 3);
                    ClosestFullRows =       nan(NumberOfPlanes, 1);
                    ClosestFullColumns=     nan(NumberOfPlanes, 1);
                    Planes =                nan(NumberOfPlanes, 1);
                    for PlaneIndex =1 : NumberOfPlanes
                        
                        [Row, Column] =                 obj.getClosestFullPixelToSeedInImage(myCroppedImageVolumeMask(:, :, PlaneIndex));
                        
                        ClosestFullRows(PlaneIndex,1) =     Row;
                        ClosestFullColumns(PlaneIndex,1) =  Column;
                        Planes(PlaneIndex,1) =              PlaneIndex;

                    end

                    %% remove data for all planes that are too distant:
                    rowsToDelete =      abs(obj.ActiveZCoordinate - Planes) > MaximumPlaneLimit;
                    ClosestFullRows(rowsToDelete,:) =       [];
                    ClosestFullColumns(rowsToDelete,:) =    [];
                    Planes(rowsToDelete,:) =                [];

                    % this may not be ideal: results from "distant planes" may get preference;
                    rowDifferences =          obj.getSeedRow - ClosestFullRows;
                    columnDifferences =       obj.getSeedColumn - ClosestFullColumns;
                    [~, IndexWithClosestDistance] =   min(sqrt(rowDifferences.^2 + columnDifferences.^2));
                    myActiveZCoordinate=    Planes(IndexWithClosestDistance);      

                else
                    myActiveZCoordinate = obj.ActiveZCoordinate;
                end

          end    
          
           function [Row, Column] =         getClosestFullPixelToSeedInImage(obj, Image)
               
               if Image(obj.getSeedRow, obj.getSeedColumn) == 0
                    [fullRows, fullColumns] =       find(Image);

                    % is there a parenthesis missing here?
                    if isempty(fullRows)
                        Row = NaN;
                        Column = NaN;
                    else
                          [~, IndexWithClosestDistance] =     min(sqrt(obj.getSeedRow - fullRows.^2 + obj.getSeedColumn - fullColumns.^2));
                            Row =                               round(fullRows(IndexWithClosestDistance));
                            Column =                            round(fullColumns(IndexWithClosestDistance));
                    end

               else
                   Row = obj.getSeedRow;
                   Column = obj.getSeedColumn;
               end
              
           end
        
     
        function [ListWithPixels] =          getConnectedPixels(obj, MaskImage, Plane)
             [Row, Column] =                 obj.getClosestFullPixelToSeedInImage(MaskImage);
            if isnan(Row) || isnan(Column)
                ListWithPixels =    zeros(0,3);
            else
                 MaskImage(MaskImage==1) = 255; % need to do that; otherwise grayconnected doesn't work;
                BW =                                                          grayconnected(MaskImage, Row, Column);
                [YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]=     find(BW); 
                [ListWithPixels] =                                            obj.addBackCutoffFromCroppingToCoordinateList([YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]);
                ListWithPixels(:,3)=                                          Plane;   
            end

       end
        
            function [ListWithOverlappingPixels]=                       FindContactAreasInNeighborPlane(obj, Structure, CoordinatesOfNeightborList, PlaneIndex)


                 %% first analyze the structures detected in the target image: 
                 if Structure.NumObjects == 0
                    ListWithOverlappingPixels =                     zeros(0,3);
                    return
                 else
                     
                    ListWithDetectedRegions(:,1) =          Structure.PixelIdxList;
                    SizeOfStructures =                      cellfun(@(x) length(x), ListWithDetectedRegions);
                    ListWithDetectedRegions(:,2) =          num2cell(SizeOfStructures);
                    ListWithDetectedRegions =               sortrows(ListWithDetectedRegions, -2);

                    %% then go through each region, starting from the biggest one:
                    % the first one that shows overlap is accepted as extension of the "seed cell";
                    NumberOfRegions =    size(ListWithDetectedRegions,1);
                    for CurrentRegionIndex = 1:NumberOfRegions
                          [Rows, Columns] =                 ind2sub(Structure.ImageSize, ListWithDetectedRegions{CurrentRegionIndex,1});
                          [CoordinatesOfSelectedRegion] =  obj.addBackCutoffFromCroppingToCoordinateList([ Rows , Columns]);
                          [~,overlap,~] =                  intersect(CoordinatesOfSelectedRegion, CoordinatesOfNeightborList(:,1:2),'rows');

                          if ~isempty(overlap) % if some pixels are overlapping accept that the current region is a cell extension into current plane;
                              ListWithOverlappingPixels =           CoordinatesOfSelectedRegion;
                              ListWithOverlappingPixels(:,3) =      PlaneIndex;
                              return

                          end
                    end

                    if ~exist('ListWithOverlappingPixels')
                        ListWithOverlappingPixels = zeros(0,3);
                    end
                    
                 end

            end
      
               
            
        %% 1d: showMaskDetectionByThresholding
         function obj = showMaskDetectionByThresholding(obj, Thresholded)
            
            if obj.ShowSegmentationProgress
                figure(100)
                clf(100)
                currentAxesOne= subplot(3, 3, 1);
                currentAxesOne.Visible = 'off';
                imagesc(max(obj.getCroppedImageSource, [], 3))
                title('Cropping')
                
                currentAxesOne= subplot(3, 3, 2);
                currentAxesOne.Visible = 'off';
                imagesc(max(obj.getCroppedImageWithExistingMasksRemoved, [], 3))
                title('Existing tracks removed')
                
                currentAxesOne= subplot(3, 3, 3);
                currentAxesOne.Visible = 'off';
                imagesc(max(Thresholded, [], 3))
                title('Thresholded')
                
                currentAxesOne= subplot(3, 3, 4);
                currentAxesOne.Visible = 'off';
                imagesc(max(Thresholded, [], 3))
                
                MyLine = line(obj.getSeedColumn, obj.getSeedRow);
                MyLine.Marker = 'x';
                MyLine.MarkerSize = 25;
                MyLine.Color = 'black';
                MyLine.LineWidth = 20;
                title('Original seed')
                
                 currentAxesOne= subplot(3, 3, 5);
                currentAxesOne.Visible = 'off';
                imagesc(max(Thresholded, [], 3))
                
                CentralPlane =    obj.getOptimizedPlaneForSeed(Thresholded);
                 [Row, Column] =                 obj.getClosestFullPixelToSeedInImage(Thresholded(:, :, CentralPlane));
                
                MyLine = line(Column, Row);
                MyLine.Marker = 'x';
                MyLine.MarkerSize = 25;
                MyLine.Color = 'black';
                MyLine.LineWidth = 20;
                title('Optimized seed')
                
                
                currentAxesOne= subplot(3, 3, 6);
                currentAxesOne.Visible = 'off';
                 image = obj.getCropImageObjectForImage(obj.getActiveShape.getRawImageVolume).getImage;
                imagesc(max(image, [], 3))
                title('Segmentation')
                
                 
                
                currentAxesOne= subplot(3, 3, 7);
                currentAxesOne.Visible = 'on';
                 title('Shape information')
                MyText = text(0, 1, obj.getActiveShape.getLimitAnalysisString);
                 MyText.HorizontalAlignment = 'left';
                MyText.VerticalAlignment = 'top';
                
                currentAxesOne= subplot(3, 3, 8);
                currentAxesOne.Visible = 'off';
               image = obj.getCropImageObjectForImage(obj.getActiveShape.getImageVolume).getImage;
                imagesc(max(image, [], 3))
                title('Shape verification')
                
                
            end
            
            
        end
      
            
        
    end
    
end

