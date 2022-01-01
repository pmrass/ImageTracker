classdef PMSegmentationCapture
    %PMTRACKINGCAPTURE for segmentation of given image volume;
    %   Detailed explanation goes here
    
    properties (Access = private) % center
        
        ActiveXCoordinate
        ActiveYCoordinate
        ActiveZCoordinate
        ActiveChannel =                         2
        
        
    end
    
    properties (Access = private) % range
       
        MinimumCellRadius =                     0  % leave at zero by default, otherwise 1 pixel coordinates will be deleted;
        MaximumCellRadius =                     50 %30
        PlaneNumberAboveAndBelow =              1
        MaximumDisplacement =                   50
        
        
    end
    
     properties (Access = private) % edge detection
        NumberOfPixelsForBackground =           20;
        BoostBackgroundFactor =                 1;
        PixelShiftForEdgeDetection =            1; %1
        WidenMaskAfterDetectionByPixels =       0;
        FactorForThreshold =                    0.3;
       
           
    end
    
    properties (Access = private)
         SizeForFindingCellsByIntensity
         PixelNumberForMaxAverage =              20; %25
      
    end
    
    methods
       
        function structure = getSummaryStructure(obj)
            
            structure.ActiveState.ActiveXCoordinate =           obj.ActiveXCoordinate;
            structure.ActiveState.ActiveYCoordinate =           obj.ActiveYCoordinate;
            structure.ActiveState.ActiveZCoordinate =           obj.ActiveZCoordinate;
            structure.ActiveState.ActiveChannel =               obj.ActiveChannel;

            structure.Range.MinimumCellRadius =                 obj.MinimumCellRadius;
            structure.Range.MaximumCellRadius =                 obj.MaximumCellRadius;
            structure.Range.PlaneNumberAboveAndBelow =          obj.PlaneNumberAboveAndBelow;
            structure.Range.MaximumDisplacement =               obj.MaximumDisplacement;

            structure.EdgeDetection.NumberOfPixelsForBackground =           obj.NumberOfPixelsForBackground;
            structure.EdgeDetection.BoostBackgroundFactor =                 obj.BoostBackgroundFactor;
            structure.EdgeDetection.PixelShiftForEdgeDetection =            obj.PixelShiftForEdgeDetection;
            structure.EdgeDetection.WidenMaskAfterDetectionByPixels =       obj.WidenMaskAfterDetectionByPixels;
            structure.EdgeDetection.FactorForThreshold =                    obj.FactorForThreshold; 
            
            structure.IntensityScreen.SizeForFindingCellsByIntensity =      obj.SizeForFindingCellsByIntensity;
            structure.IntensityScreen.PixelNumberForMaxAverage =            obj.PixelNumberForMaxAverage; 
            
            

 
        end
          
    end
    
    
    properties (Access = private) % do not save; just temporary during image analysis;

        %% temporary data: these data are derived from the original movie and are needed only temporarily for analysis;
        % no permanent record desired:
        FieldNamesForSegmentation =         {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        SegmentationOfCurrentFrame
        CurrentTrackId
        
        SegmentationType

        ImageVolume
      

        MaskCoordinateList
        AllowedExcessSizeFactor

        ShowSegmentationProgress =          false

        BlackedOutPixels = zeros(0,3);
        AccumulatedSegmentationFailures = 0
        
    end

    properties (Access = private, Constant)
        TrackIDColumn = 1;
    end

    
    methods % initialization

        function obj = PMSegmentationCapture(varargin)
            %PMTRACKINGCAPTURE Construct an instance of this class
            %   Detailed explanation goes here

            NumberOfInputArguments =    length(varargin);
            switch NumberOfInputArguments
                
                case 0
                    return
                    
                case 1 % one input argument means that the current PMMovieController is the input argument:
                    assert(isscalar(varargin{1}), 'Wrong input.')
                    switch class(varargin{1})
                        case 'PMMovieController'
                                obj =     obj.resetWithMovieController(varargin{1});
                            
                        otherwise
                            error('Wrong input.')
                        
                    end
                     
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
                    
                otherwise
                    error('Wrong input.')

            end
            
          
        end
        
        function obj = set.ImageVolume(obj, Value)
            assert(isnumeric(Value) && ndims(Value) == 3, 'Wrong input.')
            obj.ImageVolume = Value;
        end
        
        function obj =  set.BlackedOutPixels(obj, Value)
            assert(isnumeric(Value) && ismatrix(Value), 'Wrong input.')
            obj.BlackedOutPixels = Value;

        end

        function obj =  set.FactorForThreshold(obj, Value)
        assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value), 'Wrong input.')
        obj.FactorForThreshold = Value;
        end

        function obj =  set.MaximumCellRadius(obj, Value)
        assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value), 'Wrong input.')
        obj.MaximumCellRadius = Value;
        end

        function obj =  set.MaximumDisplacement(obj, Value)
        assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value), 'Wrong input.')
        obj.MaximumDisplacement = Value;
        end

        function obj =  set.PixelShiftForEdgeDetection(obj, Value)
        assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
        obj.PixelShiftForEdgeDetection = Value; 
        end

        function obj =  set.AllowedExcessSizeFactor(obj, Value)
        assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
        obj.AllowedExcessSizeFactor = Value; 
        end

        function obj =  set.ActiveChannel(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && Value >= 1, 'Wrong argument type.')
            obj.ActiveChannel = Value;
        end

        function obj =  set.ActiveYCoordinate(obj, Value)
            assert(isnumeric(Value) && isscalar(Value)  && Value >= 1, 'Wrong argument type.')
            obj.ActiveYCoordinate = Value;
        end

        function obj =  set.ActiveXCoordinate(obj, Value)
            assert(isnumeric(Value) && isscalar(Value)  && Value >= 1, 'Wrong argument type.')
            obj.ActiveXCoordinate = Value;
        end

        function obj =  set.ActiveZCoordinate(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && Value >= 1, 'Wrong argument type.')
            obj.ActiveZCoordinate = Value;
        end

        function obj =  set.MaskCoordinateList(obj, Value)
            if isempty(Value)
                Value = zeros(0, 3);
            else
                assert(isnumeric(Value) && ismatrix(Value) && size(Value,2) == 3, 'Wrong argument type.')
            end
            obj.MaskCoordinateList = Value;


        end

        function obj =  set.SizeForFindingCellsByIntensity(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && Value > 0, 'Wrong input.')
            obj.SizeForFindingCellsByIntensity = Value;
        end

        function obj =  set.CurrentTrackId(obj, Value)
            
            if isempty(Value)
                
            else
                assert(isscalar(Value) && isnumeric(Value), 'Wrong input.')
                
                if isnan(Value)
                    
                else
                    assert( mod(Value, 1) == 0 && Value >= 1, 'Wrong input.')
                    obj.CurrentTrackId = Value;
                    
                end
                
                
              
            end
            
        end
        
        function obj = set.ShowSegmentationProgress(obj, Value)
            assert(isscalar(Value) && islogical(Value), 'Wrong input.')
           obj.ShowSegmentationProgress = Value; 
        end

    end
    
    methods % summaries
        
        function obj = showSummary(obj)
            
            fprintf('\n*** This PMSegmentationCapture object is used to segment content of a loaded image-sequence.\n')
            fprintf('\nIt is currenlty set to perform edge detection by "%s".\n', obj.SegmentationType)
            
            if isempty(obj.SegmentationType)
                
                fprintf('Currently no segmentation type set.\n')
            else
                
            
                switch obj.SegmentationType
                    case 'ThresholdingByEdgeDetection'
                        fprintf('This approach first crops an image with the following limits:\n')
                        
                        cellfun(@(x) fprintf('%s\n', x), obj.getCroppingSummaryText);
                        fprintf('\nThen the central horizontal and vertical intensity vectors are processed to get the threshold from the detected edge:\n')
                        fprintf('The "%i" most peripheral pixels are thought to come from "background" and are used to measure "baseline intensity differences".\n', obj.NumberOfPixelsForBackground)
                        fprintf('The boost background factor has a value of "%6.2f". ', obj.BoostBackgroundFactor)
                        fprintf('(Values above 1 make the edge detection less sensitive. Value below 1 make it more sensitive.)\n')
                        fprintf('Thresholding will shift the detected edge by "%i" pixels. ', obj.PixelShiftForEdgeDetection)
                        fprintf('(Values >=1 are expected to make thresholding more aggressive. Values <= -1 are expected to make thresholding less aggressive.)\n')
                        fprintf('Widening of thresholded masks is set to "%i". ', obj.WidenMaskAfterDetectionByPixels)
                        fprintf('(Values of 1 widen the mask by one cycle, 2 by 2 cycles, etc.)\n')
                        
                    otherwise
                      fprintf('Summary cannot provide details for this segmentation type.')     
                end
                
            end
            
            
            
        end
        
        function obj = showAutoTrackingSettings(obj)
            
            fprintf('Minimum cell radius = %i.\n', obj.MinimumCellRadius);
            fprintf('Maximum cell radius = %i.\n', obj.MaximumCellRadius);
            fprintf('Plane number above and below = %i.\n', obj.PlaneNumberAboveAndBelow);
            fprintf('Maximum displacement = %i.\n', obj.MaximumDisplacement);
            fprintf('Pixel number for max average = %i.\n', obj.PixelNumberForMaxAverage);
        
            
        end
    end
    
    methods (Access = private) % summaries
        
        function text = getCroppingSummaryText(obj)
            text{1, 1} = sprintf('Minimum column = "%i"', obj.getMinimumColumnForImageCropping);
            text{2, 1} = sprintf('Maximum column = "%i"', obj.getMaximumColumnForImageCropping);
            text{3, 1} = sprintf('Minimum row = "%i"', obj.getMinimumRowForImageCropping);
            text{4, 1} = sprintf('Maximum row = "%i"', obj.getMaximumRowForImageCropping);
            
        end
        
    end
    
    methods % setters
        
        function obj = setBlackedOutPixels(obj, Value)
            obj.BlackedOutPixels = Value;
        end

        function obj = emptyOutBlackedOutPixels(obj) 
            obj.BlackedOutPixels = zeros(0,3);
        end

        function obj = setMaximumCellRadius(obj, Value)
            obj.MaximumCellRadius = Value;
        end

        function obj = setMaximumDisplacement(obj, Value)
            obj.MaximumDisplacement = Value; 
        end

        function obj = setPixelShiftForEdgeDetection(obj, Value)
            obj.PixelShiftForEdgeDetection = Value; 
        end

        function obj = setAllowedExcessSizeFactor(obj, Value)
            obj.AllowedExcessSizeFactor = Value; 
        end

        function obj = setActiveChannel(obj, Value)
            obj.ActiveChannel = Value; 
        end

        function obj = setActiveZCoordinate(obj, Value)
            obj.ActiveZCoordinate = Value;
        end

        function obj = setMaskCoordinateList(obj, Value)
            obj.MaskCoordinateList = Value;
            obj =        obj.setActiveCoordinateByBrightestPixels;
        end

        function obj = setFactorForThreshold(obj, Value)
            obj.FactorForThreshold = Value;
        end

        function obj = setSegmentationType(obj, Value)
            obj.SegmentationType = Value; 
        end

        function obj = setSizeForFindingCellsByIntensity(obj, Value)
            obj.SizeForFindingCellsByIntensity = Value;
        end

        function obj = setTrackId(obj, Value)
            obj.CurrentTrackId = Value;
        end
        
        function obj = setShowSegmentationProgress(obj, Value)
            
           obj.ShowSegmentationProgress = Value; 
        end
   
    end
    
    methods % setters: set multiple properties by MovieController

        function obj=               resetWithMovieController(obj, MovieController)
            
                assert(isscalar(MovieController) && isa(MovieController, 'PMMovieController'), 'Wrong input.')
                obj.ActiveChannel =                    MovieController.getLoadedMovie.getActiveChannelIndex;
                obj.ImageVolume =                      MovieController.getActiveImageVolumeForChannel(obj.ActiveChannel);
                obj.SegmentationOfCurrentFrame =       MovieController.getLoadedMovie.getUnfilteredSegmentationOfCurrentFrame;
                
                ActiveSegmentation = MovieController.getLoadedMovie.getSegmentationOfActiveMask;
                if ~isempty(ActiveSegmentation)
                    obj =         obj.setActiveStateBySegmentationCell(ActiveSegmentation);
                else
                    
                    
                end
                
                
        end

     

    end
    
    methods (Access = private) % setters: set multiple properties by MovieController
       
           function obj = setActiveStateBySegmentationCell(obj, SegmentationOfActiveTrack)
               
                 assert(size(SegmentationOfActiveTrack, 1) == 1, 'One unique segment must be retrieved here.')
                        
                MyMask =                        PMMask(SegmentationOfActiveTrack);

                obj.CurrentTrackId =            MyMask.getTrackID;
                obj.ActiveYCoordinate =         round(MyMask.getY);
                obj.ActiveXCoordinate =         round(MyMask.getX);
                obj.ActiveZCoordinate =         round(MyMask.getZ);
                obj.MaskCoordinateList =        MyMask.getMaskPixels;

        end

        
    end
    
    methods % getters
        
        function rows = getMaximumRows(obj)
            rows =  size(obj.ImageVolume,1); 
        end
        
        function rows = getMaximumColumns(obj)
            rows =  size(obj.ImageVolume,2); 
        end
        
        function plane = getPlaneMax(obj)
           plane = size(obj.ImageVolume, 3);
        end
      
        
       function value = getMaskCoordinateList(obj)
            value = obj.getActiveShape.getCoordinates;
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
        
        function CandidateYCentroid = getZCentroid(obj)
            CandidateYCentroid =        mean(obj.getMaskZCoordinateList);
        end

        function pixelNumber = getNumberOfPixels(obj)
            pixelNumber =   size(obj.MaskCoordinateList,1); 
        end                             

        function AllowedPixelNumber = getMaximumPixelNumber(obj)
             AllowedPixelNumber =         round(size(obj.MaskCoordinateList,1)*obj.AllowedExcessSizeFactor); 
        end
        
        function area = getPixelArea(obj)
            if isempty(obj.MaskCoordinateList)
                area = 0;
            else
                  area = round(size(unique(obj.MaskCoordinateList(:, 1:2)), 1));
            end
         
            
        end
        
        
        function Area = getMaximumPixelArea(obj)
            if isempty(obj.MaskCoordinateList)
                Area = 0;
            else
                Area = round(size(unique(obj.MaskCoordinateList(:, 1:2)), 1) * obj.AllowedExcessSizeFactor); 
            end
            
            
        end
        
        function type = getSegmentationType(obj)
           type = obj.SegmentationType; 
        end
        
           function Value = getTrackId(obj)
            Value = obj.CurrentTrackId;
           end
        
        
        
        
    end
    
    methods % autothresholding in brightest region of image 
        
            function obj = performAutothresholdSegmentationAroundBrightestAreaInImage(obj)
              
                
          
                              
            end
            
            
        
    end
    
    methods
        
        function obj = blackoutAllPreviouslyTrackedPixels(obj)
            
            TrackID = obj.CurrentTrackId;
            
            obj.CurrentTrackId =     NaN; % have to do this to also exclude currently active track pixels;
            obj =                    obj.addPreviouslTrackedPixelsToBlackedOutPixels;
            
            obj.CurrentTrackId = TrackID;
            
        end
        
        function obj = addActivePixelsToBlackedOutPixels(obj)
            
             obj = obj.addPixelsToBlackedOutPixels(obj.MaskCoordinateList);
            
            
        end
        
        
        
        function obj = addPixelsToBlackedOutPixels(obj, Pixels)
            assert(isnumeric(Pixels) && ismatrix(Pixels) && size(Pixels, 2) == 3, 'Wrong input.')
              obj.BlackedOutPixels =       unique([Pixels; obj.BlackedOutPixels], 'rows');
            
        end
        
        function obj = setActiveCoordinateByBrightestArea(obj)
            
            MyPlane =                       obj.ActiveZCoordinate;
            BlackedOutImage =               obj.getImageWithBlackedOutPixelsForPlane(MyPlane);
            
          
            
          
            
            [xCoordinate, yCoordinate] =    obj.detectBrightestAreaInImage(BlackedOutImage);
            obj.ActiveYCoordinate =         yCoordinate;
            obj.ActiveXCoordinate =         xCoordinate;

        end
        
        
    end
    
    methods (Access = private) % autothresholding in brightest region of image 
        
        function showAllImagePlanes(obj, ImageVolume, FigureNumber)
            
        
            
            NumberOfPlanes = size(ImageVolume, 3);
            
            NumberOfRows = 2;
            NumberOfColumns = 6;
            figure(FigureNumber)
            assert(NumberOfPlanes <= NumberOfRows * NumberOfColumns, 'Wrong input.')
               
            for index = 1 : NumberOfPlanes
                
                 subplot(NumberOfRows, NumberOfColumns, index)
                  imagesc(ImageVolume(:, :, index))
                  
            end
           
           
           
            
        end
        
        function BlackedOutImageVolume = getImageVolumeWithBlackedOutPixels(obj)
            BlackedOutImageVolume = arrayfun(@(x) obj.getImageWithBlackedOutPixelsForPlane(x), (1 : obj.getPlaneMax)', 'UniformOutput', false);
            
            BlackedOutImageVolume = cat( 3 , BlackedOutImageVolume{:} );
            
        end
        
        function BlackedOutImage = getImageWithBlackedOutPixelsForPlane(obj, MyPlane)
                DirtyImage =                            obj.ImageVolume(:, :, MyPlane);
                BlackedOutPixelsInCurrentPlane =        obj.filterPixelsForPlane(obj.BlackedOutPixels, MyPlane);
                BlackedOutPixelsInCurrentPlane(:, 3) = 1;
                
                BlackedOutImage =                        obj.removePixelsFromImage(BlackedOutPixelsInCurrentPlane, DirtyImage);
                
            
        end
        
           function obj = addPreviouslTrackedPixelsToBlackedOutPixels(obj)
               obj = obj.addPixelsToBlackedOutPixels(obj.getAllPreviouslyTrackedPixelsInActivePlane);
                
            end
            
            function PreviouslyTrackedPixels = getAllPreviouslyTrackedPixelsInActivePlane(obj)
                PreviouslyTrackedPixels =       obj.getAllPreviouslyTrackedPixels; 
                PreviouslyTrackedPixels =       obj.filterPixelsForPlane(PreviouslyTrackedPixels, obj.ActiveZCoordinate);
            end
            
            function Pixels = filterPixelsForPlane(obj, Pixels, Plane)
                
                  Pixels(Pixels(:,3) ~= Plane,:) =    []; 
            end
            
            function PixelsFromPreviouslyTrackedCells = getAllPreviouslyTrackedPixels(obj)

                
                if isempty(obj.SegmentationOfCurrentFrame)
                    PixelsFromPreviouslyTrackedCells = zeros(0,3);
                    
                else
                    
                    PreviouslyTrackedMasks =                obj.SegmentationOfCurrentFrame;
                    PreviouslyTrackedMasks =                obj.removeActiveTrackFromPixelList(PreviouslyTrackedMasks);
                    PixelsFromPreviouslyTrackedCells =      PreviouslyTrackedMasks(:, strcmp('ListWithPixels_3D', obj.FieldNamesForSegmentation));
                    PixelsFromPreviouslyTrackedCells =      vertcat(PixelsFromPreviouslyTrackedCells{:});
                    PixelsFromPreviouslyTrackedCells =      obj.removeOutOfPlanePixels(PixelsFromPreviouslyTrackedCells);
                   
                    if isempty(PixelsFromPreviouslyTrackedCells)
                        PixelsFromPreviouslyTrackedCells = zeros(0,3);
                    end
                    
                end
                
                
                
            end
            
             function CellWithMaskData = removeActiveTrackFromPixelList(obj, CellWithMaskData)
                if ~isempty(obj.CurrentTrackId) && ~isnan(obj.CurrentTrackId) % exclude currently tracked cell (not to block re-tracking)
                    RowsWithUnspecifiedTracks =                               cell2mat(CellWithMaskData(:, obj.TrackIDColumn)) == obj.CurrentTrackId;  
                    CellWithMaskData(RowsWithUnspecifiedTracks,:) =           [];
                end

                RowsWithUnspecifiedTracks =                               isnan(cell2mat(CellWithMaskData(:, obj.TrackIDColumn)));
                CellWithMaskData(RowsWithUnspecifiedTracks,:) =           [];
             end
             
            
          
            function PixelsFromPreviouslyTrackedCells = removeOutOfPlanePixels(obj, PixelsFromPreviouslyTrackedCells)

                if isempty(PixelsFromPreviouslyTrackedCells)

                else
                    PlaneRange =      obj.getUpperZPlane : obj.getBottomZPlane;
                    RowFilter = false(size(PixelsFromPreviouslyTrackedCells, 1), length(PlaneRange));
                    Index = 0;
                    for Plane = PlaneRange
                        Index = Index + 1;
                        RowFilter(:, Index) = PixelsFromPreviouslyTrackedCells(:, 3) == Plane;
                    end
                    RowsFromExcludedPlanes = max(RowFilter, [], 2);
                    PixelsFromPreviouslyTrackedCells(~RowsFromExcludedPlanes, :) = [];

                end

            end
  
    end
    
    methods (Access = private) % detectBrightestAreaInImage
              
            function [xCoordinate, yCoordinate] = detectBrightestAreaInImage(obj, Image)
                assert(isnumeric(Image) && ismatrix(Image), 'Wrong input.')
                IntensityMatrix =           obj.getIntensityMatrixForImage(Image);

                [ListWithMaxValues, ListWithMaxRowIndices] =          max(IntensityMatrix);
                [~,ListWithMaxColumnIndex] =    max(ListWithMaxValues);
                ListMaxRowIndex =               ListWithMaxRowIndices(ListWithMaxColumnIndex);
                
                yCoordinate =                   ListMaxRowIndex + round(obj.SizeForFindingCellsByIntensity / 2);
                xCoordinate =                   ListWithMaxColumnIndex + round(obj.SizeForFindingCellsByIntensity / 2);
                %CoordinatesList =               obj.convertRectangleLimitToYXZCoordinates([ListWithMaxColumnIndex,  ListMaxRowIndex, obj.SizeForFindingCellsByIntensity, obj.SizeForFindingCellsByIntensity]);
               
            end
            
            function IntensityMatrix = getIntensityMatrixForImage(obj, Image)
                assert(isnumeric(Image) && ismatrix(Image), 'Wrong input.')
                IntensityMatrix =   zeros(size(Image,1) - obj.SizeForFindingCellsByIntensity, size(Image,2) - obj.SizeForFindingCellsByIntensity);
                for RowIndex = 1 : size(Image,1) - obj.SizeForFindingCellsByIntensity + 1
                    for ColumnIndex = 1 : size(Image,2) - obj.SizeForFindingCellsByIntensity+1
                        Area =                                      Image(RowIndex:RowIndex+obj.SizeForFindingCellsByIntensity-1,ColumnIndex:ColumnIndex+obj.SizeForFindingCellsByIntensity-1);            
                        IntensityMatrix(RowIndex,ColumnIndex) =     median(Area(:));     
                    end  
                end
                
            end

            function Coordinates =    convertRectangleLimitToYXZCoordinates(obj, Rectangle)
                assert(isnumeric(Rectangle) && isvector(Rectangle) && length(Rectangle) == 4, 'Wrong input.')
            
                Image(Rectangle(2) : Rectangle(2) + Rectangle(4) - 1, Rectangle(1) : Rectangle(1) + Rectangle(3) - 1) = 1;
                Coordinates =    obj.convertImageToYXZCoordinates(Image);
                
            end
              
            function collectedCoordinates =    convertImageToYXZCoordinates(obj, Image)
                
                 
                NumberOfPlanes = size(Image,3);
                CorrdinateCell = cell(NumberOfPlanes,1);
                for CurrentPlane =1 :NumberOfPlanes
                    [rows, columns] =       find(Image(:,:,CurrentPlane));
                    addedCoordinates =      [ rows, columns];
                    addedCoordinates(addedCoordinates(:,1) <= 0, :) = [];
                    addedCoordinates(addedCoordinates(:,2) <= 0, :) = [];
                    addedCoordinates(addedCoordinates(:,1) > obj.getMaximumRows,:) =  [];
                    addedCoordinates(addedCoordinates(:,2) > obj.getMaximumColumns,:) = [];
                    addedCoordinates(:,3) =     CurrentPlane;
                    CorrdinateCell{CurrentPlane,1} =   addedCoordinates;
                end
                collectedCoordinates = vertcat(CorrdinateCell{:});
            end
  
    end
    
    methods (Access = private) % remove pixels
       
        
            function [Image] =          removePixelsFromImage(obj, PixelList, varargin)
                if length(varargin) ==1
                    Image = varargin{1};
                else
                    Image =      obj.ImageVolume(:, :, obj.ActiveZCoordinate);
                    error('This is not supported anymore.')
                end

                PixelList =         obj.removeCoordinatesThatAreOutOfRangeFromList(PixelList, Image);
                Image =             obj.addCoordinatesToImageWithIntensity(PixelList, Image, 0);


            end
            
            function Image = addCoordinatesToImageWithIntensity(obj, PixelList, Image, Intensity)
                NumberOfPixels = size(PixelList,1);
                for PixelIndex = 1 : NumberOfPixels % there should be a more efficient way to do this:
                    Image(PixelList(PixelIndex, 1), PixelList(PixelIndex, 2), PixelList(PixelIndex, 3)) = Intensity;
                end
            end
            
            function PixelList = removeCoordinatesThatAreOutOfRangeFromList(obj, PixelList, Image)
                PixelList(PixelList(:,1)<=0,:) =                        [];
                PixelList(PixelList(:,2)<=0,:) =                        [];
                PixelList(PixelList(:,1)>size(Image,1),:) =             [];
                PixelList(PixelList(:,2)>size(Image,2),:) =             [];
                PixelList(isnan(PixelList(:,1)),:) =                    [];
                PixelList(isnan(PixelList(:,2)),:) =                    [];
                
            end
         
        
        
    end
    
    methods % getters:

            function UpperZPlane = getUpperZPlane(obj)
                UpperZPlane =          max([ 1 obj.ActiveZCoordinate - obj.PlaneNumberAboveAndBelow]);
            end

            function BottomZPlane = getBottomZPlane(obj)
                BottomZPlane = min([ obj.ActiveZCoordinate + obj.PlaneNumberAboveAndBelow size(obj.ImageVolume, 3)]);
            end
            
           function pixelCheckSucceeded = testPixelValidity(obj)
               if isempty(obj.MaskCoordinateList)
                     pixelCheckSucceeded = false;
               else
                     pixelCheckSucceeded = obj.getActiveShape.testShapeValidity;
                      obj.getActiveShape.showSummary;
               end
            
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

    end
    
    methods % generateMaskByClickingThreshold
       
          
        function obj =                     generateMaskByClickingThreshold(obj)
            obj.SegmentationType =          'Manual';
            ThresholdedImage =              obj.thresholdImageByThreshold(obj.getCroppedImageWithExistingMasksRemoved, obj.getThresholdToClickedPixel);
            obj.MaskCoordinateList =        obj.convertConnectedPixelsIntoCoordinateList(ThresholdedImage);
            obj =                           obj.showMaskDetectionByThresholding(ThresholdedImage);
        end

        function Threshold =                getThresholdToClickedPixel(obj)
            Threshold =      obj.ImageVolume(obj.ActiveYCoordinate, obj.ActiveXCoordinate, obj.ActiveZCoordinate);
        end

        function [CoordinatesOfAllPlanes] =  convertConnectedPixelsIntoCoordinateList(obj, myCroppedImageVolumeMask)
            CoordinatesOfAllPlanes =  obj.convertConnectedPixelsIntoCoordinateListInternal(myCroppedImageVolumeMask);
        end
  
    end
    
    methods % setters
        
          function obj = setActiveCoordinateBy(obj, Y, X, Z)
                obj.ActiveYCoordinate =       Y;
                obj.ActiveXCoordinate =       X;
                obj.ActiveZCoordinate =               Z;
                fprintf('Active coordinate reset to %i (x) %i (y) and %i (z).\n', obj.ActiveXCoordinate,  obj.ActiveYCoordinate, obj.ActiveZCoordinate)
          end
         
       
        
       
                     
        %% generateMaskByEdgeDetectionForceSizeBelow:
        function obj=    generateMaskByEdgeDetectionForceSizeBelowMaxSize(obj)
            obj =   obj.generateMaskByEdgeDetectionForceSizeBelowInternal;
        end
        
        

        %% RemoveImageData
       function [obj] =       RemoveImageData(obj)
            obj.ImageVolume = cast(zeros(0,0,0), 'uint8');
            obj = resetMask(obj);
            obj.SegmentationOfCurrentFrame = [];
            
       end
       
       function obj = resetMask(obj)
           obj.MaskCoordinateList = zeros(0,3);
       end
       
 
   
       %% setActiveCoordinateByBrightestPixels
       function obj = setActiveCoordinateByBrightestPixels(obj)
            %METHOD1 set active coordinate by brightest pixels in currently loaded maks;
            %   Detailed explanation goes here
           obj =    obj.setActiveCoordinateByBrightestPixelsInternal;
       end
       
         
                
        %% views:
       
         function obj = highLightAutoEdgeDetection(obj, ImageHandle)
             obj = obj.highLightAutoEdgeDetectionInternal(ImageHandle);
         end
        
  
        
    end
    
    methods % generateMaskByAutoThreshold
          
        function obj =                generateMaskByAutoThreshold(obj)
            obj.SegmentationType =      'ThresholdingByEdgeDetection';
            
            CroppedImage = obj.getCroppedImageWithExistingMasksRemoved;
            Threshold = obj.getThresholdFromEdge;
            
            ThresholdedImage =         obj.thresholdImageByThreshold(CroppedImage, Threshold);
            obj.MaskCoordinateList =   obj.convertConnectedPixelsIntoCoordinateList(ThresholdedImage);
            
            obj =                      obj.showMaskDetectionByThresholding(ThresholdedImage);
            for WideningIndex = 1: obj.WidenMaskAfterDetectionByPixels
                obj =                 obj.addRimToActiveMask;
            end

        end
        
        
    end
    
    methods (Access = private) % getThresholdFromEdge
        
         function Threshold =                 getThresholdFromEdge(obj)
            CroppedImageAtCentralPlane =    obj.getCroppedImageAtCentralPlane;
            Threshold           =           obj.calculateThresholdFormImageByEdgeDetection(CroppedImageAtCentralPlane);
            
         end
         
        function  Threshold = calculateThresholdFormImageByEdgeDetection(obj, CroppedImageAtRightPlane) 
            Thresholds =        obj.getAllThresholdsByEdgeDetectionFromImage(CroppedImageAtRightPlane);
            Threshold  =        mean(Thresholds) * obj.FactorForThreshold;


        end
        
          function Thresholds = getAllThresholdsByEdgeDetectionFromImage(obj, CroppedImageAtRightPlane)
            assert(~isempty(CroppedImageAtRightPlane), 'Input image is empty.')
            RowIntensities =            obj.getRowIntensitiesForEdgeDetetectionFromImage(CroppedImageAtRightPlane);
            [ThresholdFromTop, ~] =     obj.findEdgeInVector(double(RowIntensities));
            [ThresholdFromBottom, ~] =  obj.findEdgeInVector(double(flip(RowIntensities)));

            ColumnIntensities =         obj.getColumnIntensitiesForEdgeDetetectionFromImage(CroppedImageAtRightPlane);

            [ThresholdLeft, ~] =        obj.findEdgeInVector(ColumnIntensities);
            [ThresholdRight, ~] =       obj.findEdgeInVector(flip(ColumnIntensities));

            Thresholds =                [ThresholdFromTop, ThresholdFromBottom, ThresholdLeft, ThresholdRight];

          end
          
         function RowPositions = getRowIntensitiesForEdgeDetetectionFromImage(obj, CroppedImageAtRightPlane)
            RowsToPadOnTop =        linspace(0, 0, obj.getRowsLostOnMarginTop);
            RowsToPadOnBottom =     linspace(0, 0, obj.getNumberOfRowsThatExtendBeyondOriginalImage);

            RowIntensities =        (CroppedImageAtRightPlane(:, obj.getSeedColumn, 1))';
            RowPositions =          double([RowsToPadOnTop, RowIntensities, RowsToPadOnBottom]);
        end
         
        function lostColumns = getRowsLostOnMarginTop(obj)
           lostColumns =        obj.getMinimumRowForCroppingRectangle;
           if lostColumns >= 0
               lostColumns = 0;
           else
               lostColumns = abs(lostColumns);
           end
        end
        
         function Rows = getNumberOfRowsThatExtendBeyondOriginalImage(obj)
             Rows = obj.getMaximumRowForCroppingRectangle - obj.getMaximumRows;
             if Rows < 0
                 Rows = 0;
             end
        end
        
        
         
         
         
         % getRowPositionsForEdgeDetection:
         function RowPositions = getRowPositionsForEdgeDetection(obj, CroppedImageAtRightPlane)
              RowIntensities =                  obj.getRowIntensitiesForEdgeDetetectionFromImage(CroppedImageAtRightPlane);
            [~, ThresholdColumnFromLeft] =      obj.findEdgeInVector(double(RowIntensities));
            [~, ThresholdColumnFromRight] =     obj.findEdgeInVector(double(flip(RowIntensities)));
             RowPositions =                     [ThresholdColumnFromLeft; ThresholdColumnFromRight];
         end
         
     
          function [Threshold, ThresholdRow] =              findEdgeInVector(obj, IntensityVector)
                %findEdgeInVector: key function for edte detection:
                IntensityDifferences =    diff(IntensityVector);
                DifferenceLimitFactor =      0.3;
                
                DifferenceLimit =          ((obj.getBackGroundDifferenceForIntensityVector(IntensityVector) + max(IntensityDifferences)) / 2) * DifferenceLimitFactor;

                if isempty(DifferenceLimit) || max(IntensityDifferences) < DifferenceLimit 
                    ThresholdRow =  NaN;
                    Threshold =     NaN;
                else
                    
                   
                    ThresholdRow =       find(IntensityDifferences >= DifferenceLimit, 1, 'first') + obj.PixelShiftForEdgeDetection;
                    if ThresholdRow > length(IntensityVector)
                        ThresholdRow = length(IntensityVector);  
                    end

                    Threshold =          IntensityVector(ThresholdRow);
                end

          end
          
          function BackgroundDifference = getBackGroundDifferenceForIntensityVector(obj, IntensityVector)
               IntensityDifferences =    diff(IntensityVector);
              StartPixels =             1 : length(IntensityDifferences) - obj.NumberOfPixelsForBackground + 1;
                EndPixels =               StartPixels + obj.NumberOfPixelsForBackground - 1;
                DifferencesAtPeriphery =  arrayfun(@(x,y) max(IntensityDifferences(x : y)), StartPixels, EndPixels);
                BackgroundDifference =    max(DifferencesAtPeriphery) * obj.BoostBackgroundFactor;
          end
        
        % getColumnPositionsForEdgeDetection:
         function ColumnPositions = getColumnPositionsForEdgeDetection(obj, CroppedImageAtRightPlane)
             ColumnIntensities =                obj.getColumnIntensitiesForEdgeDetetectionFromImage(CroppedImageAtRightPlane);
            [~, ThresholdRowsFromTop] =         obj.findEdgeInVector(ColumnIntensities);
            [~, ThresholdRowsFromBottom] =      obj.findEdgeInVector(flip(ColumnIntensities));
            ColumnPositions =                   [ThresholdRowsFromTop; ThresholdRowsFromBottom];
         end
         
         function ColumnIntensities = getColumnIntensitiesForEdgeDetetectionFromImage(obj, CroppedImageAtRightPlane)
            ColumnsToPadOnLeft =        linspace(0, 0, obj.getColumnsLostOnMarginLeft);
            ColumnsToPadOnRight =       linspace(0, 0, obj.getNumberOfColumnsThatExtendBeyondOriginalImage);
            ColumnIntensities =         CroppedImageAtRightPlane(obj.getSeedRow, : , 1);
            ColumnIntensities =         double([ColumnsToPadOnLeft, ColumnIntensities, ColumnsToPadOnRight]);
         end
         
          function lostColumns = getColumnsLostOnMarginLeft(obj)
               lostColumns =        obj.ActiveXCoordinate - obj.MaximumDisplacement;
               if lostColumns >= 0
                   lostColumns = 0;
               else
                   lostColumns = abs(lostColumns);
               end
          end
          
          
       
          
    end
    
    methods (Access = private) % getCroppedImageAtCentralPlane
        
         function CroppedImageAtRightPlane = getCroppedImageAtCentralPlane(obj)
               myCroppedImageVolume =          obj.getCroppedImageSource;
               CroppedImageAtRightPlane =      myCroppedImageVolume(:, :, obj.ActiveZCoordinate);
         end
         
         function empytImage =       getCroppedImageSource(obj)
                image =                     obj.getCropImageObjectForImage(obj.ImageVolume).getImage;
                empytImage =                image;
                empytImage(:, :, :) =       0;
                empytImage(:, :, getUpperZPlane(obj) : getBottomZPlane(obj)) = image(:, :, getUpperZPlane(obj) : getBottomZPlane(obj));
                
         end
         
          %% getCropImageObjectForImage
          function object = getCropImageObjectForImage(obj, Image)
              object = PMCropImage(Image, ...
                  obj.getMinimumColumnForImageCropping, ...
                  obj.getMaximumColumnForImageCropping, ...
                  obj.getMinimumRowForImageCropping, ...
                  obj.getMaximumRowForImageCropping);
          end
          
          % getMinimumColumnForImageCropping:
        function MinimumColumn = getMinimumColumnForImageCropping(obj)
            assert(~isempty(obj.ActiveXCoordinate), 'Cannot calculate minimum column for cropping.')
            MinimumColumn =        obj.ActiveXCoordinate - obj.MaximumDisplacement;
            if MinimumColumn < 1
                MinimumColumn = 1;
            end
        end
        
        % getMaximumColumnForImageCropping:
        function MaximumColumn =   getMaximumColumnForImageCropping(obj)
            MaximumColumn =         obj.getMaximumColumnForCroppingRectangle;
            
            if obj.getNumberOfColumnsThatExtendBeyondOriginalImage > 0
                MaximumColumn = obj.getMaximumColumns ;
            end  
        end
        
        function MaximumColumn = getMaximumColumnForCroppingRectangle(obj)
            assert(~isempty(obj.ActiveXCoordinate), 'Cannot calculate column for cropping.')
            MaximumColumn =            obj.ActiveXCoordinate + obj.MaximumDisplacement;
        end
        
        function Columns = getNumberOfColumnsThatExtendBeyondOriginalImage(obj)
             Columns = obj.getMaximumColumnForCroppingRectangle - obj.getMaximumColumns;
             if Columns < 0
                 Columns = 0;
             end
        end
        
        % getMinimumRowForImageCropping:
        function MinimumRow =      getMinimumRowForImageCropping(obj)
            MinimumRow =       obj.getMinimumRowForCroppingRectangle;
            if MinimumRow < 1
                MinimumRow = 1;
            end 
        end
        
        function MinimumRow = getMinimumRowForCroppingRectangle(obj)
             assert(~isempty(obj.ActiveYCoordinate), 'Cannot calculate row for cropping.')
            MinimumRow =       obj.ActiveYCoordinate - obj.MaximumDisplacement;
        end
        
        % getMaximumRowForImageCropping:
        function MaximumRow =      getMaximumRowForImageCropping(obj)
            MaximumRow = obj.getMaximumRowForCroppingRectangle;
            if obj.getNumberOfRowsThatExtendBeyondOriginalImage > 0
                MaximumRow =      obj.getMaximumRows;
            end
        end
         
        function MaximumRow = getMaximumRowForCroppingRectangle(obj)
             assert(~isempty(obj.ActiveYCoordinate), 'Cannot calculate row for cropping.')
            MaximumRow =          obj.ActiveYCoordinate + obj.MaximumDisplacement;
        end
        
       
        
    end
    
    methods % add RIM
       
        function obj =          addRimToActiveMask(obj)
             DilatedImage =             imdilate(obj.convertCoordinatesToImage(obj.MaskCoordinateList), strel('disk', 1));
             obj.MaskCoordinateList =   obj.convertImageToYXZCoordinates(DilatedImage);
             obj =                      obj.removePreviouslyTrackedDuplicatePixels;
        end
        
           function obj =          removeRimFromActiveMask(obj)
                SourceImage=                obj.convertCoordinatesToImage(obj.MaskCoordinateList); 
                ErodedImage =               imerode(SourceImage, strel('disk', 1));
                obj.MaskCoordinateList =    obj.convertImageToYXZCoordinates(ErodedImage);  
           end
       
        
    end
   
    methods (Access = private) % add RIM
       
        function Image= convertCoordinatesToImage(obj,ListWithCoordinates)
            Image(obj.getMaximumRows, obj.getMaximumColumns) = 0;
            for index = 1:size(ListWithCoordinates,1)
                Image(ListWithCoordinates(index,1),ListWithCoordinates(index,2),ListWithCoordinates(index,3)) = 1;  
            end 
        end
         
          function obj =       removePreviouslyTrackedDuplicatePixels(obj)
            if isempty(obj.MaskCoordinateList)
            else
                 if ~isempty(obj.getAllPreviouslyTrackedPixels)
                    obj.MaskCoordinateList(ismember(obj.MaskCoordinateList, obj.getAllPreviouslyTrackedPixels,'rows'),:) = [];
                 end
            end
          end
        

        
    end
    
    methods (Access = private) % show thresholding process

         function obj = showMaskDetectionByThresholding(obj, Thresholded)
            
            if obj.ShowSegmentationProgress
                
                figure(100)
                clf(100)
                currentAxesOne=             subplot(3, 3, 1);
                currentAxesOne.Visible = 'off';
                imagesc(max(obj.getCroppedImageSource, [], 3))
                title('Cropping')
                
                currentAxesOne=             subplot(3, 3, 2);
                currentAxesOne.Visible =    'off';
                imagesc(max(obj.getImageOfPreviouslyTrackedPixels, [], 3))
                title('Pixels from other tracked cells')
                
                currentAxesOne=             subplot(3, 3, 3);
                currentAxesOne.Visible =    'off';
                imagesc(max(obj.getCroppedImageWithExistingMasksRemoved, [], 3))
                title('Existing tracks removed')
                
                 currentAxesOne=            subplot(3, 3, 4);
                currentAxesOne.Visible =    'off';
                imagesc(obj.getImageShowingDetectedEdges);
                title('Edge detection')
                
                currentAxesOne=             subplot(3, 3, 5);
                currentAxesOne.Visible =    'off';
                imagesc(max(Thresholded, [], 3))
                title('Thresholded')
                
                currentAxesOne=             subplot(3, 3, 6);
                currentAxesOne.Visible =    'off';
                imagesc(max(Thresholded, [], 3))
                
                MyLine =                    line(obj.getSeedColumn, obj.getSeedRow);
                MyLine.Marker = 'x';
                MyLine.MarkerSize = 25;
                MyLine.Color = 'black';
                MyLine.LineWidth = 20;
                title('Original seed')
                
                currentAxesOne= subplot(3, 3, 7);
                currentAxesOne.Visible = 'off';
                imagesc(max(Thresholded, [], 3))
                
                CentralPlane =              obj.getOptimizedPlaneForSeed(Thresholded);
                [Row, Column] =             obj.getClosestFullPixelToSeedInImage(Thresholded(:, :, CentralPlane));
                
                MyLine = line(Column, Row);
                MyLine.Marker = 'x';
                MyLine.MarkerSize = 25;
                MyLine.Color = 'black';
                MyLine.LineWidth = 20;
                title('Optimized seed')
                
                currentAxesOne=                 subplot(3, 3, 8);
                currentAxesOne.Visible =        'off';
                image =                         obj.getCropImageObjectForImage(obj.getActiveShape.getRawImageVolume).getImage;
                imagesc(max(image, [], 3))
                title('Segmentation')
                
              %  currentAxesOne= subplot(3, 3, 8);
               % currentAxesOne.Visible = 'on';
                % title('Shape information')
                %MyText = text(0, 1, obj.getActiveShape.getLimitAnalysisString);
                % MyText.HorizontalAlignment = 'left';
                %MyText.VerticalAlignment = 'top';
                
                currentAxesOne= subplot(3, 3, 9);
                currentAxesOne.Visible = 'off';
                image = obj.getCropImageObjectForImage(obj.getActiveShape.getImageVolume).getImage;
                imagesc(max(image, [], 3))
                title('Shape verification')
                
                
                  obj.showAllImagePlanes(obj.ImageVolume, 10);
                     obj.showAllImagePlanes(obj.getImageVolumeWithBlackedOutPixels, 11);
                  
                  
                
               % area = obj.getPixelArea;
            end
            
            
         end
         
         function Image = getImageOfPreviouslyTrackedPixels(obj)
            
            Image = obj.getCroppedImageSource;
            Image(:, :) = 0;
            PreviouslyTrackedPixels =   obj.translateCoordinatesToMatchCroppedImage(obj.getAllPreviouslyTrackedPixels);
            PixelList =                 obj.removeCoordinatesThatAreOutOfRangeFromList(PreviouslyTrackedPixels, Image);
            Image =                     obj.addCoordinatesToImageWithIntensity(PixelList, Image, 255);

             
         end
         
         function HighlightedImage = getImageShowingDetectedEdges(obj)
             
          
            HighlightedImage = obj.getCroppedImageAtCentralPlane;
            HighlightedImage(obj.getSeedRow, :) = 255;
             HighlightedImage(:, obj.getSeedColumn) = 255;
            
             Rows = obj.getRowPositionsForEdgeDetection(obj.getCroppedImageAtCentralPlane);
             
             if isnan(Rows(1))
                 
             else
                HighlightedImage(Rows(1) ,obj.getSeedColumn) = 0;
                HighlightedImage(end - Rows(1) + 1 ,obj.getSeedColumn) = 0;

                Columns = obj.getRowPositionsForEdgeDetection(obj.getCroppedImageAtCentralPlane);
                HighlightedImage(obj.getSeedRow, Columns(1) ) = 0;
                HighlightedImage(obj.getSeedRow, end - Columns(1) + 1 ) = 0;
             end
             
            
             
             
         end
      
        
        
        
        
    end
    
    methods (Access = private)
        
        

         function obj = setActiveCoordinateByBrightestPixelsInternal(obj)
            %METHOD1 set active coordinate by brightest pixels in currently loaded maks;
            %   Detailed explanation goes here
            BrightestPixels =   obj.getBrightestCoordinatesFromActiveMask;
            if isempty(BrightestPixels)
                warning('Brightest pixel detection failed. Active coordinate left unchanged.')
            else
                CoordinateWithMaximumIntensity =      round(median(BrightestPixels(:,1:3), 1));
                X=          CoordinateWithMaximumIntensity(1,1);
                Y =         CoordinateWithMaximumIntensity(1,2);
                Z =         CoordinateWithMaximumIntensity(1,3);
                obj =       obj.setActiveCoordinateBy(X, Y, Z);
                
            end
            
            
         end
       
       
        
        function [CoordinatesWithMaximumIntensity] =   getBrightestCoordinatesFromActiveMask(obj)

                assert(~isempty(obj.MaskCoordinateList), 'Cannot get brightes pixels when no pixels are specified.')
                PixelIntensities =                  obj.getPixelIntensitiesOfActiveMask;
                if isempty(PixelIntensities)
                    CoordinatesWithMaximumIntensity =       obj.MaskCoordinateList;
                else
                    CoordinatesWithIntensity =          [obj.MaskCoordinateList, PixelIntensities];
                    CoordinatesWithIntensity =          sortrows(CoordinatesWithIntensity, -4);
                    
                    if size(CoordinatesWithIntensity,1) < obj.PixelNumberForMaxAverage
                        CoordinatesWithMaximumIntensity =       CoordinatesWithIntensity;
                    else
                        CoordinatesWithMaximumIntensity =      CoordinatesWithIntensity(1 : obj.PixelNumberForMaxAverage,:);
                    end


                    
                end
                

        

        end
        
        function PixelIntensities = getPixelIntensitiesOfActiveMask(obj)
            if isempty(obj.ImageVolume)
                PixelIntensities = '';
            else
                 PixelIntensities =        double(arrayfun(@(row,column,plane) obj.ImageVolume(row,column,plane), obj.MaskCoordinateList(:,1),obj.MaskCoordinateList(:,2),obj.MaskCoordinateList(:,3)));
            end
           
        end
        

        %% generateMaskByEdgeDetectionForceSizeBelowInternal
        function obj = generateMaskByEdgeDetectionForceSizeBelowInternal(obj)
            
            
            obj =               obj.generateMaskByAutoThreshold;
            PixelShift = 0;
           
            
            
            while obj.getPixelArea == 0 || obj.getActiveShape.cellIsTooLarge
                obj.PixelShiftForEdgeDetection =    PixelShift;
                obj =               obj.generateMaskByAutoThreshold;
                PixelShift =        PixelShift + 1; 
                if PixelShift > obj.MaximumCellRadius / 2
                    warning('Had to max out edge detection. This probably means that something is wrong. Check the settings.')
                   break 
                end
            end
            
            
            
        end
        
        
        
              
         
         function SeedRow =               getSeedRow(obj)
                    SeedRow =          obj.ActiveYCoordinate - obj.getRowsLostFromCropping;                                   
           end
           
        function SeedColumn =           getSeedColumn(obj)
                    SeedColumn =       obj.ActiveXCoordinate - obj.getColumnsLostFromCropping;                             
        end
        
      
        
        
        
        
        % thresholdImageByThreshold:
          function myCroppedImageVolumeMask = thresholdImageByThreshold(~, Image, myThreshold)
              
              if ~ (isnumeric(myThreshold) && isscalar(myThreshold))
                    myThreshold
                    error( 'Wrong input')
              end
              
              if isnan(myThreshold)
                  error('Could not calculate threshold. This cannot be right. Fix the problem.')
                  myCroppedImageVolumeMask =     uint8(Image >= 10) * 255;
              else
                  myCroppedImageVolumeMask =     uint8(Image >= myThreshold) * 255;
              end
            
          end
     
         function obj = highLightAutoEdgeDetectionInternal(obj, ImageHandle)
            
             
             obj.ImageVolume = ImageHandle.CData;
             
              if isempty(obj.SegmentationType)
              else
                     switch obj.SegmentationType
                  
                  case 'ThresholdingByEdgeDetection'
                       
                       
                     

                        ImageHandle.CData(obj.getMinimumRowForImageCropping : obj.getMaximumRowForImageCropping, obj.ActiveXCoordinate,1) =                    200;
                        ImageHandle.CData(obj.ActiveYCoordinate, obj.getMinimumColumnForImageCropping : obj.getMaximumColumnForImageCropping,1) =                    200;

                        ImageHandle.CData(obj.getMinimumRowForImageCropping : obj.getMinimumRowForImageCropping + obj.NumberOfPixelsForBackground - 1, obj.ActiveXCoordinate, 3) =                    200;
                        ImageHandle.CData(obj.getMinimumRowForDisplay: obj.getMaximumRowForImageCropping , obj.ActiveXCoordinate, 3) =                    200;

                        ImageHandle.CData(obj.ActiveYCoordinate, obj.getCoordinatesForColumnIndicationOne, 3) =  200;
                        ImageHandle.CData(obj.ActiveYCoordinate, obj.getCoordinatesForColumnIndicationTwo, 3) =  200;

                        ImageHandle.CData(obj.getMinimumRowForImageCropping, obj.ActiveXCoordinate, 1:3) =          255;
                        
                        
                        
                        ImageHandle.CData(obj.getMaximumRowForImageCropping, obj.ActiveXCoordinate, 1:3) =          255;
                     
                        
                        
                        ImageHandle.CData(obj.ActiveYCoordinate, obj.getMinimumColumnForImageCropping, 1:3) =     255;
                        ImageHandle.CData(obj.ActiveYCoordinate, obj.getMaximumColumnForImageCropping, 1:3) =     255;
                        
              end
                  
                  
              end
              
           

            
         end
         
         function minimumRow = getMinimumRowForDisplay(obj)
             minimumRow = obj.getMaximumRowForImageCropping - obj.NumberOfPixelsForBackground + 1 ;
             if minimumRow < 1
                minimumRow = 1; 
             end
         end
           
         function Coordinates = getCoordinatesForColumnIndicationOne(obj)
            Coordinates =  obj.getMinimumColumnForImageCropping : obj.getMinimumColumnForImageCropping + obj.NumberOfPixelsForBackground - 1;
            Coordinates(Coordinates <= 0) = [];
             
         end
         
         function Coordinates = getCoordinatesForColumnIndicationTwo(obj)
            Coordinates =  obj.getMaximumColumnForImageCropping - obj.NumberOfPixelsForBackground + 1 : obj.getMaximumColumnForImageCropping;
            Coordinates(Coordinates <= 0) = [];
             
         end
        


   
            
          function [ListWithPixels] =       addBackCutoffFromCroppingToCoordinateList(obj, ListWithPixels)
                ListWithPixels(:,1) =               ListWithPixels(:,1) + obj.getRowsLostFromCropping;
                ListWithPixels(:,2) =               ListWithPixels(:,2) + obj.getColumnsLostFromCropping;
          end

          % getCroppedImageWithExistingMasksRemoved
          function Image =                   getCroppedImageWithExistingMasksRemoved(obj)
            ListWithPreviouslyTrackedPixels =   obj.translateCoordinatesToMatchCroppedImage(obj.getAllPreviouslyTrackedPixels);
            
            
            Image =            obj.removePixelsFromImage(ListWithPreviouslyTrackedPixels, obj.getCroppedImageSource);
          end
          
          
          
        
        function [ListWithPixels] =         translateCoordinatesToMatchCroppedImage(obj, ListWithPixels)
           if isempty(obj.getRowsLostFromCropping)
               ListWithPixels = zeros(0, 3);
           else
               ListWithPixels(:,1) =    ListWithPixels(:,1) - obj.getRowsLostFromCropping;
            ListWithPixels(:,2) =    ListWithPixels(:,2) - obj.getColumnsLostFromCropping;
               
           end
            
            
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
        function CoordinatesOfAllPlanes =  convertConnectedPixelsIntoCoordinateListInternal(obj, myCroppedImageVolumeMask)
            
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
        
        
          function CoordinatesOfAllPlanes = removeNegativeCoordinates(~, CoordinatesOfAllPlanes)
                NegativeValuesOne =            CoordinatesOfAllPlanes(:,1) < 0;
                NegativeValuesTwo =            CoordinatesOfAllPlanes(:,2) < 0;
                NegativeValuesThree =          CoordinatesOfAllPlanes(:,3) < 0;

                rowsWithNegativeValues =      max([NegativeValuesOne, NegativeValuesTwo, NegativeValuesThree], [], 2);
                CoordinatesOfAllPlanes(rowsWithNegativeValues,:) =      [];
          end
               
        function [CentralPlane, PlanesAbove, PlanesBelow, numberOfPlanes] = getConnectedPlaneSpecification(obj, myCroppedImageVolumeMask)
         
            CentralPlane =    obj.getOptimizedPlaneForSeed(myCroppedImageVolumeMask);
            numberOfPlanes =  length(obj.getUpperZPlane : obj.getBottomZPlane);
            PlanesAbove =     CentralPlane -1 : -1 : obj.getUpperZPlane; % maybe include more checks: e.g. make isnan or empty when no values exist;
            PlanesBelow =     CentralPlane + 1 : 1 : obj.getBottomZPlane;
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

                    if isempty(fullRows)
                        Row = NaN;
                        Column = NaN;
                    else
                          [~, IndexWithClosestDistance] =     min(sqrt(obj.getSeedRow - fullRows.^2 + obj.getSeedColumn - fullColumns.^2));
                            Row =                               round(fullRows(IndexWithClosestDistance));
                            Column =                            round(fullColumns(IndexWithClosestDistance));
                    end

               else
                   Row =        obj.getSeedRow;
                   Column =     obj.getSeedColumn;
                   
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
         
        
    end
    
end

