classdef PMSegmentationCapture
    %PMTRACKINGCAPTURE for segmentation of given image volume;
    %  based on user defined settings (active position, minimum/maximum size), threshold-settings the program performs segmentation of structures;
    
    properties (Access = private) % center
        ActiveXCoordinate = 1
        ActiveYCoordinate = 1
        ActiveZCoordinate = 1
        
        ActiveXCoordinateHistory
        ActiveYCoordinateHistory
        ActiveZCoordinateHistory
             
    end
    
    properties (Access = private) % for setting size of cropped image
        MaximumDisplacement =                   180
        PlaneNumberAboveAndBelow =              1 
        
    end
    
     properties (Access = private) % edge detection
        NumberOfPixelsForBackground =           30;
        BoostBackgroundFactor =                 1; % complex, higher values are;
        DifferenceLimitFactor =                 2; % complex, but higher values are likely to make the edge-detection more aggressive;
        PixelShiftForEdgeDetection =            2; % higher values make edge-detection more aggessive;
            
     end

    properties (Access = private)
        FactorForThreshold =                    0.3; % multiply threshold obtained from edge detection with this factor, higher values lead to more aggerssive segmentation;
       
    end
    
    properties (Access = private)
        WidenMaskAfterDetectionByPixels =       0;
         
    end
    
    properties (Access = private) % sets accepted size limits
        MinimumCellRadius =                     6  % leave at zero by default, otherwise 1 pixel coordinates will be deleted;
        MaximumCellRadius =                     100 %30
       
           
    end
    
    
    properties (Access = private) % currently not in use
         PixelNumberForMaxAverage =              240; %25
         SizeForFindingCellsByIntensity 
        
    end
    
    properties (Access = private) % do not save; just temporary during image analysis;

        %% temporary data: these data are derived from the original movie and are needed only temporarily for analysis;
        % no permanent record desired:
        FieldNamesForSegmentation =         {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        SegmentationOfCurrentFrame
        CurrentTrackId
        
        SegmentationType

        ImageVolume
      
        MaskSeriesCoordinates
        
        MaskCoordinateList % list with coordinates: three columns: Y, X, Z;
        AllowedExcessSizeFactor

        BlackedOutPixels =                  zeros(0,3);
        
        ShowSegmentationProgress =          false

        
    
        
     end

    methods % SUMMARY
       
        function structure = getSummaryStructure(obj)
            
            structure.ActiveState.ActiveXCoordinate =                       obj.ActiveXCoordinate;
            structure.ActiveState.ActiveYCoordinate =                       obj.ActiveYCoordinate;
            structure.ActiveState.ActiveZCoordinate =                       obj.ActiveZCoordinate;
          
            structure.Range.MinimumCellRadius =                             obj.MinimumCellRadius;
            structure.Range.MaximumCellRadius =                             obj.MaximumCellRadius;
            structure.Range.PlaneNumberAboveAndBelow =                      obj.PlaneNumberAboveAndBelow;
            structure.Range.MaximumDisplacement =                           obj.MaximumDisplacement;

            structure.EdgeDetection.NumberOfPixelsForBackground =           obj.NumberOfPixelsForBackground;
            structure.EdgeDetection.BoostBackgroundFactor =                 obj.BoostBackgroundFactor;
            structure.EdgeDetection.PixelShiftForEdgeDetection =            obj.PixelShiftForEdgeDetection;
            structure.EdgeDetection.WidenMaskAfterDetectionByPixels =       obj.WidenMaskAfterDetectionByPixels;
            structure.EdgeDetection.FactorForThreshold =                    obj.FactorForThreshold; 
            
            structure.IntensityScreen.SizeForFindingCellsByIntensity =      obj.SizeForFindingCellsByIntensity;
            structure.IntensityScreen.PixelNumberForMaxAverage =            obj.PixelNumberForMaxAverage; 
            
        end
          
    end
    
    properties (Access = private, Constant)
        TrackIDColumn = 1;
    end

    methods % INITIALIZATION

        function obj = PMSegmentationCapture(varargin)
            %PMSEGMENTATIONCAPTURE Construct an instance of this class
            % takes 0, 1, 2, 3 or 6 arguments:
            % 1 argument: PMMovieTracking
            % 2 arguments: 1: PMMovieTracking; 2: coordinates (vector of 3) or coordinates and channel (vector of 4);
            %               or 1: coordinate list, 2: segmentation type
            % 3 arguments: 1: track ID, 2: segmentation of current frame, 3: Image-Volume;
            % 6 arguments: 1: track ID, 2: segmentation of current frame, 3: Image-Volume, 4: X-position, 5: Y-position, 6: Z-position;

            NumberOfInputArguments =    length(varargin);
            switch NumberOfInputArguments
                
                case 0
                    return
                    
                case 1 % one input argument means that the current PMMovieController is the input argument:
                   
                    switch class(varargin{1})
                        case 'PMMovieTracking'
                             assert(isscalar(varargin{1}), 'Wrong input.')
                                obj =     obj.resetWithMovieTracking(varargin{1});
                                
                        case 'double'
                            MyMask =    varargin{1};
                            assert(ismatrix(MyMask), 'Wrong input.')
                            
                            switch size(MyMask, 2)
                                
                                case 2
                                    
                                    obj.MaskCoordinateList =    varargin{1};
                                    obj.MaskCoordinateList(:, 3) = obj.ActiveZCoordinate;
                                
                                    
                                otherwise
                                    error('Wrong input.')
                                
                                
                                
                            end
                            
                            
                        otherwise
                            error('Wrong input.')
                        
                    end
                     
                case 2 % manual tracking: pixel-list and type "manual";

                   switch class(varargin{1})
                       
                        case 'PMMovieTracking'
                            
                            switch length(varargin{2})
                                case 3
                                    [obj]=                          obj.resetWithMovieTracking(varargin{1});
                                    obj.ActiveYCoordinate =         varargin{2}(1);
                                    obj.ActiveXCoordinate =         varargin{2}(2);
                                    obj.ActiveZCoordinate =         varargin{2}(3);
                                    obj.MaskCoordinateList =        varargin{2};

                                case 4
                                    [obj]=                          obj.resetWithMovieTracking(varargin{1});
                                    obj.ActiveYCoordinate =         varargin{2}(1);
                                    obj.ActiveXCoordinate =         varargin{2}(2);
                                    obj.ActiveZCoordinate =         varargin{2}(3);
                                    obj.MaskCoordinateList =        varargin{2}(1:3);
                                    
                                otherwise
                                    
                                error('Wrong argument type')
                            end
                        
                        
                        
                       otherwise
                        
                            obj.MaskCoordinateList =      varargin{1};
                            obj.SegmentationType =        varargin{2};

                            obj.ActiveYCoordinate =       obj.getYCentroid;
                            obj.ActiveXCoordinate =       obj.getXCentroid;
                            obj.ActiveZCoordinate =       obj.getZCentroid;

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
            assert(isnumeric(Value) && (ismatrix(Value) || ndims(Value) == 3), 'Wrong input.')
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
            assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value) && Value > 0, 'Wrong input.')
            obj.MaximumCellRadius = Value;
        end
        
        function obj =  set.MinimumCellRadius(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value) && Value >= 0, 'Wrong input.')
            obj.MinimumCellRadius = Value;
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
%             if isempty(Value)
%                 Value = zeros(0, 3);
%             else
%                 assert(isnumeric(Value) && ismatrix(Value) && size(Value,2) == 3, 'Wrong argument type.')
%             end
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
    
    methods % SUMMARIES
        
        function obj = showSummary(obj)
            
            fprintf('\n*** This PMSegmentationCapture object is used to segment content of a loaded image-sequence.\n')
            

            fprintf('Limits:\n')
            fprintf('Minimum radius = %6.2f.\n', obj.MinimumCellRadius)
            fprintf('MaximumCellRadius radius = %6.2f.\n', obj.MaximumCellRadius)
            fprintf('PlaneNumberAboveAndBelow radius = %6.2f.\n', obj.PlaneNumberAboveAndBelow)
            fprintf('MaximumDisplacement radius = %6.2f.\n', obj.MaximumDisplacement)
            
            fprintf('\nThen the central horizontal and vertical intensity vectors are processed to get the threshold from the detected edge:\n')
            fprintf('The "%i" most peripheral pixels are thought to come from "background" and are used to measure "baseline intensity differences".\n', obj.NumberOfPixelsForBackground)
            fprintf('The boost background factor has a value of "%6.2f". ', obj.BoostBackgroundFactor)
            fprintf('(Values above 1 make the edge detection less sensitive. Value below 1 make it more sensitive.)\n')
            fprintf('Thresholding will shift the detected edge by "%i" pixels. ', obj.PixelShiftForEdgeDetection)
            fprintf('(Values >=1 are expected to make thresholding more aggressive. Values <= -1 are expected to make thresholding less aggressive.)\n')
            fprintf('Widening of thresholded masks is set to "%i". ', obj.WidenMaskAfterDetectionByPixels)
            fprintf('(Values of 1 widen the mask by one cycle, 2 by 2 cycles, etc.)\n')

            
            fprintf('\nIt is currenlty set to perform edge detection by "%s".\n', obj.SegmentationType)
            
            if obj.ShowSegmentationProgress
               fprintf('Show figure with detailed description of segmentation procedure.\n') 
            else
                fprintf('Do not show figure with detailed description of segmentation procedure.\n') 
            end
            
            
            if isempty(obj.SegmentationType)
                
                fprintf('Currently no segmentation type set.\n')
            else
                
            
                switch obj.SegmentationType
                    case 'ThresholdingByEdgeDetection'
                        fprintf('This approach first crops an image with the following limits:\n')
                        
                        cellfun(@(x) fprintf('%s\n', x), obj.getCroppingSummaryText);
                    
                        
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
    
    methods % SETTERS: BASIC:
        
        function obj =      setImageVolume(obj, Value)
            % SETIMAGEVOLUME set image-volume, i.e., the image-source for the segmentation procedure;
            % takes 1 argument:
            % 1: 3-dimensional numeric array: rows, columns, planes
           obj.ImageVolume = Value; 
        end
        
        function obj =      setSegmentationOfCurrentFrame(obj, Value)
           obj.SegmentationOfCurrentFrame =     Value; 
           obj =                                obj.emptyOutBlackedOutPixels; 
           obj =                                obj.blackoutAllPreviouslyTrackedPixels;
           
        end
        
        function obj =      setSegmentationType(obj, Value)
            obj.SegmentationType = Value; 
        end

        function obj =      setTrackId(obj, Value)
            obj.CurrentTrackId = Value;
        end
        
        function obj =      setShowSegmentationProgress(obj, Value)
            % SETSHOWSEGMENTATIONPROGRESS sets visualziation of segmentation process;
            % takes 1 argument:
            % 1: logical scalar
           obj.ShowSegmentationProgress = Value; 
        end
         
    end
    
    methods % SETTERS: ACTIVE MASK:
       
        function obj =      setActiveCoordinateByBrightestPixels(obj)
            %SETACTIVECOORDINATEBYBRIGHTESTPIXELS set active coordinate by brightest pixels in currently loaded maks;
            %   Detailed explanation goes here
            obj =    obj.setActiveCoordinateByBrightestPixelsInternal;
        end

        function obj =      setActiveCoordinateBy(obj, Y, X, Z)
            obj.ActiveYCoordinate =                 Y;
            obj.ActiveXCoordinate =                 X;
            obj.ActiveZCoordinate =                 Z;
            fprintf('Active coordinate reset to %i (x) %i (y) and %i (z).\n', obj.ActiveXCoordinate,  obj.ActiveYCoordinate, obj.ActiveZCoordinate)
        end

        function obj =      resetMask(obj)
           % RESETMASK delete "MaskCoordinateList"
           % MaskCoordinateList corresponds to "active mask" and is used as a starting point for mask-specific operations;
           obj.MaskCoordinateList = zeros(0,3);
        end
        
        function obj =      setActiveZCoordinate(obj, Value)
            % SETACTIVEZCOORDINATE sets active Z-coordinate
            % takes 1 argument:
            % 1: positive, numeric scalar
            % this is the "active plane" that is used as a reference point where plane information is relevant (e.g. get image of "active plane");
            obj.ActiveZCoordinate = Value;
        end

        function obj =      setMaskCoordinateList(obj, Value)
            obj.MaskCoordinateList = Value;
            obj =        obj.setActiveCoordinateByBrightestPixels;
        end
        
        
    end
    
    methods % SETTERS: SHAPE-VERIFICATION;
        % influences what final coordinates are returned; does not impact actual segmentation procedure;
        
        function obj =      setMaximumCellRadius(obj, Value)
            % SETMAXIMUMCELLRADIUS set maximum cell radius
            % takes 1 argument:
            % 1 positive numeric scalar;
            % this value is most relevant for determining the acceptable size of a shape;
            obj.MaximumCellRadius = Value;
        end
        
        function obj =      setMinimumCellRadius(obj, Value)
            % SETMINIMUMCELLRADIUS set minimum cell radius
            % takes 1 argument:
            % 1 positive numeric scalar;
            % this value is most relevant for determining the acceptable size of a shape;
            obj.MinimumCellRadius = Value;
        end
        
        function obj =      setAllowedExcessSizeFactor(obj, Value)
            obj.AllowedExcessSizeFactor = Value; 
        end

        
        
        
    end
    
    methods % SETTERS: CROPPING WINDOW
       
           function obj =      setMaximumDisplacement(obj, Value)
            % SETMAXIMUMDISPLACEMENT set maximum displacement
            % takes 1 argument: numeric scalar
            % the main consequence of this setting is the size of the cropping window;
            % the window has two times length of MaximumDisplacement and two times width of MaximumDisplacement;
            % larger windows will take more time to process some extension over original cell is required to make approach work;
            % normally MaximumDisplacement should be roughl 2 times of the expected cell diameter;
            obj.MaximumDisplacement = Value; 
        end
        
        
    end
    
    methods % SETTERS: INTENSITY DETECTION OF POINTS:
       
          function obj =      setSizeForFindingCellsByIntensity(obj, Value)
            % SETSIZEFORFINDINGCELLSBYINTENSITY sets size for finding cells by intensity;
            % takes 1 argument:
            % 1: numeric,positive scalar; "size" should be similar to expected diameter of cell;
            % currently not in use, can slow down approach signficantly, not real benefit ;
            obj.SizeForFindingCellsByIntensity = Value;
        end
        
        
    end
    
    methods % SETTERS: EDGE-DETECTION RELATED:
       
        function obj = setWidenMaskByNumber(obj, Value)
           obj.WidenMaskAfterDetectionByPixels = Value; 
        end
       
        function obj = setBoostBackgroundFactor(obj, Value)
            obj.BoostBackgroundFactor = Value;
        end
        
        function obj = setDifferenceLimitFactor(obj, Value)
            obj.DifferenceLimitFactor = Value;
        end
        
        function obj =      setNumberOfPixelsForBackground(obj, Value)
           obj.NumberOfPixelsForBackground = Value; 
        end
        
        function obj =      setFactorForThreshold(obj, Value)
            % SETFACTORFORTHRESHOLD sets FactorForThreshold
            % this value is used to muliply threshold obtained by edge-detection (it is best left at 1);
            obj.FactorForThreshold = Value;
        end
        
        function obj =      setPixelShiftForEdgeDetection(obj, Value)
            % SETPIXELSHIFTFOREDGEDETECTION set PixelShiftForEdgeDetection
            % takes 1 argument:
            % 1: numeric scalar
            % PixelShiftForEdgeDetection shifts the border "away" from the cell and into background territory;
            % there is usually a fuzziness in the area;
            % higher pixel-shifts mean that the threshold is pushed more into the cell area and is higher; the threshold is more aggressive and will lead to a smaller mask;
            % this setting is irrelevant when using the method generateMaskByEdgeDetectionForceSizeBelowMaxSize: in this case the method will start with a pixel-shift of 0 and increase until the cell size is below the wanted limit;
            obj.PixelShiftForEdgeDetection = Value; 
            
       end
        
    end
    
    methods % SETTERS: BLACKED-OUT PIXELS
       
        function obj =      setBlackedOutPixels(obj, Value)
            obj.BlackedOutPixels = Value;
        end

        function obj =      emptyOutBlackedOutPixels(obj) 
            % EMPTYOUTBLACKEDOUTPIXELS delete all "black-out" pixels;
            % "black-out" pixels are typically used when previously tracked pixels should be elimintated to avoid double-tracking;
            obj.BlackedOutPixels = zeros(0,3);
        end
    
        
        
    end
    
    methods % SETTERS: NEW 

            
        function [obj] =       RemoveImageData(obj)
            obj.ImageVolume =                   cast(zeros(0,0,0), 'uint8');
            obj =                               obj.resetMask;
            obj.SegmentationOfCurrentFrame =    [];

        end     

        function obj = highLightAutoEdgeDetection(obj, ImageHandle)
            obj = obj.highLightAutoEdgeDetectionInternal(ImageHandle);
        end
         
      end

    methods % SETTERS: set multiple properties by MovieController

        function obj=               resetWithMovieTracking(obj, varargin)
            % RESETWITHMOVIECONTROLLER set state with MovieTracking;
            % takes 1 argument:
            % 1: PMMovieTracking
            % sets active channel, Image-volume, SegmentationOfCurrentFrame and "active state" (track ID and current position) ;
            % SegmentationOfCurrentFrame: useful to prevent double-tracking of "previously tracked cells";
            
            switch length(varargin)
                
                case 0
                    
                    
                case 1
                    
                    MovieTracking = varargin{1};
                    
                    assert(isscalar(MovieTracking) && isa(MovieTracking, 'PMMovieTracking'), 'Wrong input.')
                                  
                    obj =        obj.setImageVolume(MovieTracking.getActiveProcessedImageVolume);
                    obj =        obj.setSegmentationOfCurrentFrame(MovieTracking.getUnfilteredSegmentationOfCurrentFrame); 
                    obj =        obj.setActiveStateBySegmentationCell(MovieTracking.getSegmentationOfActiveMask);
                    
                otherwise
                    error('Wrong input.')
                
                
                
            end
         

         end

        function obj =              set(obj, varargin)
            
            switch length(varargin)
               
                case 1
                    
                    switch class(varargin{1})
                       
                        case 'PMSegmentationCaptureView'

                             obj.MaximumDisplacement =              varargin{1}.getMaximumDisplacement;
                             obj.NumberOfPixelsForBackground =      varargin{1}.getNumberOfPixelsForBackground;
                             obj.BoostBackgroundFactor =            varargin{1}.getBoostBackgroundFactor;
                             obj.DifferenceLimitFactor =            varargin{1}.getDifferenceLimitFactor;
                             obj.PixelShiftForEdgeDetection =       varargin{1}.getPixelShiftForEdgeDetection;
                             obj.FactorForThreshold =               varargin{1}.getFactorForThreshold;
                             obj.WidenMaskAfterDetectionByPixels =  varargin{1}.getWidenMaskAfterDetectionByPixels;
                             obj.MaximumCellRadius =                varargin{1}.getMaximumCellRadius;
                             obj.MinimumCellRadius =                varargin{1}.getMinimumCellRadius;
                             obj.ShowSegmentationProgress =         varargin{1}.getShowSegmentationProgress;
           
        
    
        
                            
                        otherwise
                            error('Wrong input.')
                        
                        
                    end
                    
                    
                otherwise
                    
                    error('Wrong input.')
                
                
                
            end
            
            
            
        end
        
    end
    
    methods % GETTERS FOR STATE
        
        function image = getImageVolume(obj)
            
           image = obj.ImageVolume; 
        end
        
        
        function radius = getMaximumDisplacement(obj)
            % GETMINIMUMCELLRADIUS;
           radius = obj.MaximumDisplacement; 
        end
        
        function Value = getNumberOfPixelsForBackground(obj)
            % GETNUMBEROFPIXELSFORBACKGROUND;
           Value = obj.NumberOfPixelsForBackground; 
        end
        
        function Value = getBoostBackgroundFactor(obj)
            % GETBOOSTBACKGROUNDFACTOR;
           Value = obj.BoostBackgroundFactor; 
        end
        
        function Value = getDifferenceLimitFactor(obj)
            % GETDIFFERENCELIMITFACTOR;
           Value = obj.DifferenceLimitFactor; 
        end
        
        function Value = getPixelShiftForEdgeDetection(obj)
            % GETPIXELSHIFTFOREDGEDETECTION;
           Value = obj.PixelShiftForEdgeDetection; 
        end
        
        function Value = getFactorForThreshold(obj)
            % GETFACTORFORTHRESHOLD;
           Value = obj.FactorForThreshold; 
        end
        
        function radius = getMinimumCellRadius(obj)
            % GETMINIMUMCELLRADIUS returns defined minimum cell radius;
           radius = obj.MinimumCellRadius; 
        end
        
        function radius = getMaximumCellRadius(obj)
            % GETMINIMUMCELLRADIUS returns defined minimum cell radius;
           radius = obj.MaximumCellRadius; 
        end
        
        function radius = getWidenMaskAfterDetectionByPixels(obj)
            % GETWIDENMASKAFTERDETECTIONBYPIXELS
           radius = obj.WidenMaskAfterDetectionByPixels; 
        end
        
        function radius = getShowSegmentationProgress(obj)
            % GETSHOWSEGMENTATIONPROGRESS
           radius = obj.ShowSegmentationProgress; 
        end
        
        
        
        
    end
    
    methods % GETTERS PIXELS
        
       function value = getMaskCoordinateList(obj)
            value = obj.getActiveShape.getCoordinates;
       end
       
       
       function value = getRawMaskCoordinateList(obj)
           % GETRAWMASKCOORDINATELIST: returns  all coordinates;
           % used by PMTrackingNavigation when adding mask with PMSegmentationCapture object;
            value = obj.getActiveShape.getRawCoordinates;
       end
        
        function value = getMaskXCoordinateList(obj)
            % GETMASKXCOORDINATELIST: returns  all X-coordinates;
           % used by PMTrackingNavigation when adding mask with PMSegmentationCapture object;
           value = obj.MaskCoordinateList; 
           value = value(:, 2);
        end
        
        function value = getMaskYCoordinateList(obj)
            % GETMASKYCOORDINATELIST: returns  all Y-coordinates;
           % used by PMTrackingNavigation when adding mask with PMSegmentationCapture object;
           value = obj.MaskCoordinateList; 
           value = value(:, 1);
        end
        
        function value = getMaskZCoordinateList(obj)
            % GETMASKZCOORDINATELIST: returns  all Z-coordinates;
           % used by PMTrackingNavigation when adding mask with PMSegmentationCapture object;
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

        
        
    end

    methods % GETTERS
          
        function list = getSegmentationCaptureChildren(obj)
            if isempty(obj.MaskSeriesCoordinates)
                list = '';
            else

                list = cellfun(@(x) PMSegmentationCapture(x, 'Child'), obj.MaskSeriesCoordinates);
                
            end
            
        end
        
        function rows = getMaximumRows(obj)
            rows =  size(obj.ImageVolume,1); 
        end
        
        function rows = getMaximumColumns(obj)
            rows =  size(obj.ImageVolume,2); 
        end
        
        function plane = getPlaneMax(obj)
           plane = size(obj.ImageVolume, 3);
        end
      
        
     
     
        function type = getSegmentationType(obj)
           type = obj.SegmentationType; 
        end
        
           function Value = getTrackId(obj)
            Value = obj.CurrentTrackId;
           end
        
        
        
        
    end
    
    methods % GETTERS SHAPE

        function pixelCheckSucceeded = testPixelValidity(obj)
            % TESTPIXELVALIDITY returns logical scalar depending on whether shape is acceptable or not;
            if isempty(obj.MaskCoordinateList)
                 pixelCheckSucceeded = false;
                 
            else
                 pixelCheckSucceeded = obj.getActiveShape.testShapeValidity;
                 
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
      
    methods % GETTERS MASK SIZE AND SIZE LIMITE
       
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
        
        
        
    end

    methods % GETTERS: SEGMENTATIONCAPTURE-LIST (AUTOCELLRECOGNITION BY INTENSITY); 
       
        function ListWithSegmentationCaptures = getSegmentationCaptureListByNeighborMerging(obj)
                MyTCellImage =                              obj.getImageVolume;
                CC =                                        bwconncomp(MyTCellImage);
               [row,col] =                                  cellfun(@(x) ind2sub(CC.ImageSize, x), CC.PixelIdxList, 'UniformOutput', false);
               
               
               
               Sizes =                                      cellfun(@(x) length(x), row');
               myRefShape =                                obj.getShapeForCoordinateList('');

                MinimumSizeForPreClear =                    myRefShape.getMinimumSize;
                MaximumSizeForPreClear =                    myRefShape.getMaximumSize;

               DeleteSmall = Sizes < MinimumSizeForPreClear;
               DeleteLarge = Sizes > MaximumSizeForPreClear;
               
               Delete = max([DeleteSmall, DeleteLarge], [], 2);
               
               row(Delete) = [];
                col(Delete) = [];
                
                fprintf('(%i cells)', length(col))
               
                ListWithSegmentationCaptures =              cellfun(@(row, col) PMSegmentationCapture([row, col]), row, col); %slow;
           %     ListWithSegmentationCaptures =              obj.cleanupListWithSegmentationCaptures(ListWithSegmentationCaptures);
       
        end
        
        
          function ListWithSegmentationCaptures = getSegmentationCaptureListByIntensityRecognition(obj)
              
                NumberOfAcceptedFailures =                  30;
                NumberOfCellsAdded  =                       0;
                AccumulatedSegmentationFailures =           0;
              
                myRefShape =                                obj.getShapeForCoordinateList('');

                MinimumSizeForPreClear =                    myRefShape.getMinimumSize;


                ListWithSegmentationCaptures =              cell(5000, 1);

                [BlackedOutImage, OriginalImage] =          obj.getImageWithBlackedOutPixelsForPlane(obj.ActiveZCoordinate);

                FilteredImage =                             medfilt2(BlackedOutImage, [obj.MinimumCellRadius, obj.MinimumCellRadius]);

                OriginalImageModel =                        PMImage(OriginalImage);

                OriginalBlackOutImageModel =                PMImage(OriginalImage);  % this will currently only work for 2D, adjust that it will also work for 3D;
                FilteredBlackOutImageModel =                PMImage(FilteredImage);


                OriginalBlackOutImageModel =                OriginalBlackOutImageModel.removeSmallObjects(MinimumSizeForPreClear);
                FilteredBlackOutImageModel =                FilteredBlackOutImageModel.removeSmallObjects(MinimumSizeForPreClear);
 
                    ContinueLoop = true;
                    while ContinueLoop
                        
                            OriginalBlackOutImageModel =             OriginalBlackOutImageModel.removeSmallObjects(MinimumSizeForPreClear);
                            FilteredBlackOutImageModel =             FilteredBlackOutImageModel.removeSmallObjects(MinimumSizeForPreClear);

                            obj =                                   obj.setActiveCoordinateByImageModel(FilteredBlackOutImageModel);
                            obj =                                   obj.showSourceImages(OriginalImageModel, OriginalBlackOutImageModel, FilteredBlackOutImageModel);

                            InputImage =                            OriginalBlackOutImageModel.getImage;
                           
                            [Coordinates, ThresholdedImage] =       obj.getCoordinatesFromSourceImageVolume(InputImage);
                         
                            obj.SegmentationType =                  'ThresholdingByEdgeDetection';
                            obj.MaskCoordinateList =                Coordinates;

                     
                            for WideningIndex = 1: obj.WidenMaskAfterDetectionByPixels
                                obj =                 obj.addRimToActiveMask;
                            end

                            obj =                                   obj.addPixelsToBlackedOutPixels(obj.MaskCoordinateList);
                            
                            OriginalBlackOutImageModel =            OriginalBlackOutImageModel.addCoordinatesWithIntensityPrecise(obj.MaskCoordinateList, 0);

                            FilteredBlackOutImageModel =            FilteredBlackOutImageModel.addCoordinatesWithIntensityPrecise(obj.MaskCoordinateList, 0);

                            obj =                                   obj.showMasksDetectionByEdgeThreshold(ThresholdedImage);
                        
                            if obj.testPixelValidity
                                AccumulatedSegmentationFailures =                       0;
                               
                                obj =                                                   obj.showSuccessText(NumberOfCellsAdded);
                               
                            else 

                                AccumulatedSegmentationFailures =       AccumulatedSegmentationFailures + 1;
                                obj =                                   obj.showFailureText(AccumulatedSegmentationFailures, NumberOfAcceptedFailures);
                                
                            end
                            
                              NumberOfCellsAdded =                                    NumberOfCellsAdded + 1;
                             ListWithSegmentationCaptures{NumberOfCellsAdded, 1} =   obj;
                             

                            if AccumulatedSegmentationFailures > NumberOfAcceptedFailures
                                ContinueLoop = false;

                            end
                        
                    end
                    
                    
                    Remove =                                    cellfun(@(x) isempty(x), ListWithSegmentationCaptures);
                    ListWithSegmentationCaptures(Remove, :) =   [];
                    
                     ListWithSegmentationCaptures =              cellfun(@(x) x, ListWithSegmentationCaptures);
                   
                    ListWithSegmentationCaptures =              obj.cleanupListWithSegmentationCaptures(ListWithSegmentationCaptures);
                    
          end
          
          function ListWithSegmentationCaptures = cleanupListWithSegmentationCaptures(obj, ListWithSegmentationCaptures)
              
            WrongShape = arrayfun(@(x) ~x.testPixelValidity, ListWithSegmentationCaptures);
            ListWithSegmentationCaptures(WrongShape) = [];
              
          end
          
          function [Coordinates, ThresholdedImage] = getCoordinatesFromSourceImageVolume(obj, InputImage)
              
                CroppedVolume =                     obj.convertImageVolumeIntoCroppedVolume(InputImage); % get cropped image

                myCroppedImageVolume =              obj.filterPlanesOfCroppedImage(CroppedVolume);
                CroppedImageAtCentralPlane =        myCroppedImageVolume(:, :, obj.ActiveZCoordinate);

                CoordinatesToZeroOut =              obj.removeCroppingFromCoordinateList(obj.BlackedOutPixels);

                BlackedOutCroppedImage =            PMImage(CroppedImageAtCentralPlane).addCoordinatesWithIntensityPrecise(CoordinatesToZeroOut, 0).getImage;

                Threshold           =               obj.calculateThresholdFormImageByEdgeDetection(BlackedOutCroppedImage);
                ThresholdedImage =                  uint8(PMImage(BlackedOutCroppedImage).threshold(Threshold).getImage);


                Coordinates =                       obj.getCoordinatesFromCroppedImage(ThresholdedImage);

                             
              
          end
        
       
        function obj =          generateMaskByAutoThreshold(obj)
            % GENERATEMASKBYAUTOTHRESHOLD use thresholding to detect edge and to generate new MaskCoordinateList;
            

                image =                 obj.convertImageVolumeIntoCroppedVolume(obj.ImageVolume); % get cropped image
                myCroppedImageVolume =            obj.filterPlanesOfCroppedImage(image);


                BlackedOutCroppedImage =        obj.convertCroppedImageVolumeIntoBlackedOutImage(myCroppedImageVolume);

                Threshold           =           obj.calculateThresholdFormImageByEdgeDetection(BlackedOutCroppedImage);


                ThresholdedImage =              uint8(PMImage(BlackedOutCroppedImage).threshold(Threshold).getImage);

                Coordinates =                    obj.getCoordinatesFromCroppedImage(ThresholdedImage);

                obj.SegmentationType =      'ThresholdingByEdgeDetection';
                obj.MaskCoordinateList =       Coordinates;

                obj =                        obj.showMasksDetectionByEdgeThreshold(ThresholdedImage);
                for WideningIndex = 1: obj.WidenMaskAfterDetectionByPixels
                obj =                 obj.addRimToActiveMask;
                end

        end
        
       
        
        function BlackedOutCroppedImage = convertCroppedImageVolumeIntoBlackedOutImage(obj, myCroppedImageVolume)
             CoordinatesToZeroOut =           obj.removeCroppingFromCoordinateList(obj.BlackedOutPixels);
            CroppedImageAtCentralPlane =      myCroppedImageVolume(:, :, obj.ActiveZCoordinate);
            BlackedOutCroppedImage =        PMImage(CroppedImageAtCentralPlane).addCoordinatesWithIntensityPrecise(CoordinatesToZeroOut, 0).getImage;
        end
        
        
        
        function Coordinates = getCoordinatesFromCroppedImage(obj, ThresholdedImage)
            
            Coordinates =                obj.convertConnectedPixelsIntoCoordinateList(ThresholdedImage);
            Coordinates =                obj.addCroppingToCoordinateList(Coordinates);

            if isempty(Coordinates)
                Coordinates(1, 1) = obj.ActiveYCoordinate;
                Coordinates(1, 2) = obj.ActiveXCoordinate;
                Coordinates(1, 3) = obj.ActiveZCoordinate;
            end
        end
    
       
        
      
        
    end
    

    methods % PROCESSING: GET PIXELS FROM IMAGE

           function CoordinatesOfAllPlanes =       convertConnectedPixelsIntoCoordinateList(obj, myCroppedImageVolumeMask)
            % CONVERTCONNECTEDPIXELSINTOCOORDINATELISTINTERNAL returns list of coordinates that coorespond to "positive" pixels of input image;


            [CentralPlane, PlanesAbove, PlanesBelow, NumberOfPlanesAnalyzed] = obj.getConnectedPlaneSpecification(myCroppedImageVolumeMask);

            coordinatesPerPlane =                   cell(NumberOfPlanesAnalyzed,1);
            coordinatesPerPlane{CentralPlane,1} =   obj.getConnectedPixelsForImage(myCroppedImageVolumeMask(:,:,CentralPlane), CentralPlane);

            
            
            for planeIndex = PlanesAbove
                coordinatesPerPlane{planeIndex,1}=   obj.FindContactAreasInNeighborPlane(bwconncomp(myCroppedImageVolumeMask(:,:,planeIndex)), coordinatesPerPlane{planeIndex+1}, planeIndex);
            end

            for planeIndex = PlanesBelow
                coordinatesPerPlane{planeIndex,1}=   obj.FindContactAreasInNeighborPlane(bwconncomp(myCroppedImageVolumeMask(:,:,planeIndex)), coordinatesPerPlane{planeIndex-1}, planeIndex);
            end

            CoordinatesOfAllPlanes =        vertcat(coordinatesPerPlane{:});
            CoordinatesOfAllPlanes =        obj.removeNegativeCoordinates(CoordinatesOfAllPlanes);





           end


        

    end

    methods (Access = private)

          function [ListWithPixels] =             getConnectedPixelsForImage(obj, MaskImage, Plane)
            % GETCONNECTEDPIXELS returns list of connected pixels:
            % takes 2 arguments:
            % 1: binary image matrix
            % 2: target plane;
            % the method uses getClosestFullPixelToSeedInImage to get seed, only pixels that are overlapping this seed will be considered;
            [Row, Column] =                 obj.getClosestFullPixelToSeedInImage(MaskImage);
            if isnan(Row) || isnan(Column)
                ListWithPixels =    zeros(0,3);
            else
                MaskImage(MaskImage==1) =                                       255; % need to do that; otherwise grayconnected doesn't work;
                BW =                                                            grayconnected(MaskImage, Row, Column);
                [YCoordinatesInCroppedImage, XCoordinatesInCroppedImage]=       find(BW); 

                ListWithPixels =                                                [YCoordinatesInCroppedImage, XCoordinatesInCroppedImage];


                ListWithPixels(:,3)=                                            Plane;   
            end

        end


    end


    methods % SETTERS BLACKED-OUT PIXELS
        
        function obj =      blackoutAllPreviouslyTrackedPixels(obj)
            % BLACKOUTALLPREVIOUSLYTRACKEDPIXELS black-out all previuosly tracked pixels;
            
            TrackID =                               obj.CurrentTrackId;
            obj.CurrentTrackId =                    NaN; % have to do this to also exclude currently active track pixels;

            PreviouslyTrackedPixelsInPlane =        obj.getShapeForCoordinateList(obj.getAllPreviouslyTrackedPixels).getRawCoordinatesForZ(obj.ActiveZCoordinate); 
            obj =                                   obj.addPixelsToBlackedOutPixels(PreviouslyTrackedPixelsInPlane);

            obj.CurrentTrackId =                    TrackID;
            
        end
        
        function obj =      addPixelsToBlackedOutPixels(obj, Pixels)
            % ADDPIXELSTOBLACKEDOUTPIXELS add pixels that should be blacked-out;
            % takes 1 argument:
            % 1: numeric matrix with 3 columns:
            assert(isnumeric(Pixels) && ismatrix(Pixels) && size(Pixels, 2) == 3, 'Wrong input.')
            obj.BlackedOutPixels =       unique([obj.BlackedOutPixels; Pixels], 'rows');
            
        end
        
        
         
    end
    
    methods % SETTERS THRESHOLDING
       


        function obj =                     generateMaskByClick(obj)

              obj.SegmentationType =          'Manual';
            
              
          
          
            obj.MaskCoordinateList =        [obj.ActiveYCoordinate, obj.ActiveXCoordinate, obj.ActiveZCoordinate];
            

      
        end

        function obj =                     generateMaskByClickingThreshold(obj)
            % GENERATEMASKBYCLICKINGTHRESHOLD
            obj.SegmentationType =          'Manual';
            
            OldMin =                        obj.MinimumCellRadius;
            OldMax =                        obj.MaximumCellRadius;

            obj.MinimumCellRadius =         1;
            obj.MaximumCellRadius =         1000000000;
            
            obj =                           obj.emptyOutBlackedOutPixels;
            obj =                           obj.blackoutAllPreviouslyTrackedPixels;
           
            SourceImage =                   obj.getCroppedImageWithBlackedOutPixelsRemoved;
            
            h =                             fspecial('disk', 2);
            %    SourceImage = imerode(SourceImage, h);
         %   SourceImage =                   imdilate(SourceImage, h);
    
            SourceThresholdImage =          uint8(PMImage(SourceImage).threshold(obj.getIntensityOfClickedPixel).getImage);                                   
                                                    
            Coordinates =                   obj.convertConnectedPixelsIntoCoordinateList(SourceThresholdImage);   
            Coordinates =                   obj.addCroppingToCoordinateList(Coordinates);
            obj.MaskCoordinateList =        Coordinates;
            
            obj =                           obj.showMaskDetectionByClickedPixel(SourceImage);

            obj.MinimumCellRadius =         OldMin;
            obj.MaximumCellRadius =         OldMax;
            
        end
        
    end
    
    methods % SETTERS SEGMENTATION
        
        function obj=                   generateMaskByEdgeDetectionForceSizeBelowMaxSize(obj)
            % GENERATEMASKBYEDGEDETECTIONFORCESIZEBELOWMAXSIZE 
            % generates mask, forces cell size below;
            obj =   obj.generateMaskByEdgeDetectionForceSizeBelowInternal;
        end
        
      
    end
    
    methods % SETTERS MASK COORDINATES
       
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

    methods   % SETTERS: "active state"

        function obj = setActiveStateBySegmentationCell(obj, SegmentationOfActiveTrack)
            %SETACTIVESTATEBYSEGMENTATIONCELL takes one argument
            % 1: segmentation cell with coordinate and track ID information;
            % sets trackID, active coordinate and mask list;


            if isempty(SegmentationOfActiveTrack)

            else
                 assert(size(SegmentationOfActiveTrack, 1) == 1, 'One unique segment must be retrieved here.')

                    MyMask =                        PMMask(SegmentationOfActiveTrack);
                    obj.CurrentTrackId =            MyMask.getTrackID;
                    obj.ActiveYCoordinate =         round(MyMask.getY);
                    obj.ActiveXCoordinate =         round(MyMask.getX);
                    obj.ActiveZCoordinate =         round(MyMask.getZ);
                    obj.MaskCoordinateList =        MyMask.getMaskPixels;

            end


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

    methods (Access = private) % GETTERS BLACKED-OUT PIXELS
        
        function BlackedOutImageVolume =    getImageVolumeWithBlackedOutPixels(obj)
            BlackedOutImageVolume =             arrayfun(@(x) obj.getImageWithBlackedOutPixelsForPlane(x), (1 : obj.getPlaneMax)', 'UniformOutput', false);
            BlackedOutImageVolume =             cat( 3 , BlackedOutImageVolume{:} );
            
        end
        
        function [BlackedOutImage, OriginalImage] =          getImageWithBlackedOutPixelsForPlane(obj, MyPlane)
            % GETIMAGEWITHBLACKEDOUTPIXELSFORPLANE returns image plane-input where all blacked-out pixels are "erased" (set to zero;
            BlackedOutPixelsInCurrentPlane =            obj.getShapeForCoordinateList(obj.BlackedOutPixels).getRawCoordinatesForZ(MyPlane);
            BlackedOutPixelsInCurrentPlane(:, 3) =      1;

            OriginalImage =                             obj.ImageVolume(:, :, MyPlane);
            BlackedOutImage =                           PMImage(OriginalImage).addCoordinatesWithIntensityPrecise(BlackedOutPixelsInCurrentPlane, 0).getImage;

        end
        
        
        
        
        
    end
    
    methods (Access = private) % GETTERS PREVIOUSLY TRACKED PIXELS
        
        function Pixels =                       filterPixelsForPlane(~, Pixels, Plane)
            assert(isnumeric(Plane) && isscalar(Plane), 'Wrong input.')
              Pixels(Pixels(:,3) ~= Plane,:) =    []; 
        end

        function Pixels =                       getAllPreviouslyTrackedPixels(obj)
            % GETALLPREVIOUSLYTRACKEDPIXELS returns list with previously tracked pixels (excluding active mask and exluding all pixels that are not in the current plane-range);

            if isempty(obj.SegmentationOfCurrentFrame)
                Pixels = zeros(0,3);

            else

           %     LargeImage(1000, 1000 ) = 0;

             %      myImageOne =                     PMImage(LargeImage);


            %       outImage =       myImageOne.addCoordinatesWithIntensityPrecise(Masks{1, 6}, 255).getImage;

                Masks =       obj.SegmentationOfCurrentFrame;
                Masks =       obj.removeActiveTrackFromPixelList(Masks);
                Pixels =      Masks(:, strcmp('ListWithPixels_3D', obj.FieldNamesForSegmentation));
                Pixels =      vertcat(Pixels{:});
                Pixels =      obj.removeOutOfPlanePixels(Pixels);

                if isempty(Pixels)
                    Pixels = zeros(0,3);
                end

            end



        end

        function CellWithMaskData =             removeActiveTrackFromPixelList(obj, CellWithMaskData)
             % REMOVEACTIVETRACKFROMPIXELLIST remove currently tracked cell from pixel-list (not to block re-tracking)
            if ~isempty(obj.CurrentTrackId) && ~isnan(obj.CurrentTrackId)
                RowsWithUnspecifiedTracks =                               cell2mat(CellWithMaskData(:, obj.TrackIDColumn)) == obj.CurrentTrackId;  
                CellWithMaskData(RowsWithUnspecifiedTracks,:) =           [];
            end

            RowsWithUnspecifiedTracks =                               isnan(cell2mat(CellWithMaskData(:, obj.TrackIDColumn)));
            CellWithMaskData(RowsWithUnspecifiedTracks,:) =           [];
         end

        function Pixels =                       removeOutOfPlanePixels(obj, Pixels)
            % REMOVEOUTOFPLANEPIXELS returns pixel-list after removal of pixels that are not in the plane-range of the object;

            if isempty(Pixels)

            else
                PlaneRange =        obj.getUpperZPlane : obj.getBottomZPlane;
                RowFilter =         false(size(Pixels, 1), length(PlaneRange));
                Index = 0;
                for Plane = PlaneRange
                    Index = Index + 1;
                    RowFilter(:, Index) = Pixels(:, 3) == Plane;
                end
                RowsFromExcludedPlanes =        max(RowFilter, [], 2);
                Pixels(~RowsFromExcludedPlanes, :) = [];

            end

        end
        
          function UpperZPlane = getUpperZPlane(obj)
            UpperZPlane =          max([ 1 obj.ActiveZCoordinate - obj.PlaneNumberAboveAndBelow]);
        end

        function BottomZPlane = getBottomZPlane(obj)
            BottomZPlane = min([ obj.ActiveZCoordinate + obj.PlaneNumberAboveAndBelow size(obj.ImageVolume, 3)]);
        end
        

        
    end

    methods (Access = private)
        
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
        
       
        
            
    end
    
    methods (Access = private) % GETTERS AUTOCELLRECOGNITION BY BRIGHTNESS;
              
           
            
            function IntensityMatrix = getIntensityMatrixForImage(obj, Image)
                % GETINTENSITYMATRIXFORIMAGE convert image into "compressed image", by averaging submatrix corresponding to "intensity-size";
                % this is very time-consuming for large images and the benefit is unclear;
                assert(isnumeric(Image) && ismatrix(Image), 'Wrong input.')
                IntensityMatrix =   zeros(size(Image,1) - obj.SizeForFindingCellsByIntensity, size(Image,2) - obj.SizeForFindingCellsByIntensity);
                
                for RowIndex = 1 : size(Image,1) - obj.SizeForFindingCellsByIntensity + 1
                    
                    
                    for ColumnIndex = 1 : size(Image,2) - obj.SizeForFindingCellsByIntensity+1
                        Area =                                      Image(  RowIndex : RowIndex + obj.SizeForFindingCellsByIntensity - 1, ...
                                                                            ColumnIndex : ColumnIndex + obj.SizeForFindingCellsByIntensity - 1);
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

    methods (Access = private) % GETTERS EDGE-THRESHOLDING
        
        function Threshold =                    getThresholdFromEdge(obj)
            % GETTHRESHOLDFROMEDGE get threshold bey edge detection of central plane from cropped image;
            error('Do not use');
            CroppedImageAtCentralPlane =    obj.getCroppedImageAtCentralPlane;
            Threshold           =           obj.calculateThresholdFormImageByEdgeDetection(CroppedImageAtCentralPlane);

        end

        function Threshold =                    calculateThresholdFormImageByEdgeDetection(obj, ImageMatrix) 
            % CALCULATETHRESHOLDFORMIMAGEBYEDGEDETECTION returns threshold obtained by edge-detection;
            % gets mean of "up", "down", "left", "right" thresholds, then multiply by FactorForThreshold;
            Thresholds =        obj.getAllThresholdsByEdgeDetectionFromImage(ImageMatrix);
            Threshold  =        mean(Thresholds) * obj.FactorForThreshold;

        end

        function Thresholds =                   getAllThresholdsByEdgeDetectionFromImage(obj, ImageMatrix)
            assert(~isempty(ImageMatrix), 'Input image is empty.')
            ThresholdRows =             obj.getRowIntensitiesForEdgeDetection(ImageMatrix);
            ThresholdColumns =          obj.getColumnIntensitiesForEdgeDetection(ImageMatrix);
            Thresholds =                [ThresholdRows(1), ThresholdRows(2), ThresholdColumns(1), ThresholdColumns(2)];

        end

        
        function RowPositions =                 getRowIntensitiesForEdgeDetection(obj, ImageMatrix)
            RowIntensities =                    obj.getRowIntensitiesForEdgeDetetectionFromImage(ImageMatrix);
            [ThresholdFromTop, ~] =             obj.findEdgeInVector(double(RowIntensities));
            [ThresholdFromBottom, ~] =          obj.findEdgeInVector(double(flip(RowIntensities)));
            RowPositions =                      [ThresholdFromTop; ThresholdFromBottom];



        end
        
         function ColumnPositions =              getColumnIntensitiesForEdgeDetection(obj, CroppedImageAtRightPlane)
            ColumnIntensities =                obj.getColumnIntensitiesForEdgeDetetectionFromImage(CroppedImageAtRightPlane);
            [ThresholdRowsFromTop, ~] =         obj.findEdgeInVector(ColumnIntensities);
            [ThresholdRowsFromBottom, ~] =      obj.findEdgeInVector(flip(ColumnIntensities));
            ColumnPositions =                   [ThresholdRowsFromTop; ThresholdRowsFromBottom];
         end
        
        
        function RowPositions =                 getRowPositionsForEdgeDetection(obj, ImageMatrix)
            RowIntensities =                    obj.getRowIntensitiesForEdgeDetetectionFromImage(ImageMatrix);
            [~, ThresholdFromTop] =             obj.findEdgeInVector(double(RowIntensities));
            [~, ThresholdFromBottom] =          obj.findEdgeInVector(double(flip(RowIntensities)));
            RowPositions =                      [ThresholdFromTop; ThresholdFromBottom];



        end

        function ColumnPositions =              getColumnPositionsForEdgeDetection(obj, CroppedImageAtRightPlane)
            ColumnIntensities =                obj.getColumnIntensitiesForEdgeDetetectionFromImage(CroppedImageAtRightPlane);
            [~, ThresholdRowsFromTop] =         obj.findEdgeInVector(ColumnIntensities);
            [~, ThresholdRowsFromBottom] =      obj.findEdgeInVector(flip(ColumnIntensities));
            ColumnPositions =                   [ThresholdRowsFromTop; ThresholdRowsFromBottom];
        end
        
        function ColumnIntensities =            getColumnIntensitiesForEdgeDetetectionFromImage(obj, CroppedImageAtRightPlane)
            ColumnsToPadOnLeft =        linspace(0, 0, obj.getColumnsLostOnMarginLeft);
            ColumnsToPadOnRight =       linspace(0, 0, obj.getNumberOfColumnsThatExtendBeyondOriginalImage);
            ColumnIntensities =         CroppedImageAtRightPlane(obj.getSeedRow, : , 1);
            ColumnIntensities =         double([ColumnsToPadOnLeft, ColumnIntensities, ColumnsToPadOnRight]);
        end

        function lostColumns =                  getColumnsLostOnMarginLeft(obj)
           lostColumns =        obj.ActiveXCoordinate - obj.MaximumDisplacement;
           if lostColumns >= 0
               lostColumns = 0;
           else
               lostColumns = abs(lostColumns);
           end
        end

        function RowPositions =                 getRowIntensitiesForEdgeDetetectionFromImage(obj, CroppedImageAtRightPlane)
            RowsToPadOnTop =        linspace(0, 0, obj.getRowsLostOnMarginTop);
            RowsToPadOnBottom =     linspace(0, 0, obj.getNumberOfRowsThatExtendBeyondOriginalImage);

            RowIntensities =        (CroppedImageAtRightPlane(:, obj.getSeedColumn, 1))';
            RowPositions =          double([RowsToPadOnTop, RowIntensities, RowsToPadOnBottom]);
        end

        function lostColumns =                  getRowsLostOnMarginTop(obj)
            lostColumns =        obj.getMinimumRowForCroppingRectangle;
            if lostColumns >= 0
               lostColumns = 0;
            else
               lostColumns = abs(lostColumns);
            end
        end

        function Rows =                         getNumberOfRowsThatExtendBeyondOriginalImage(obj)
             Rows = obj.getMaximumRowForCroppingRectangle - obj.getMaximumRows;
             if Rows < 0
                 Rows = 0;
             end
        end

        function [Threshold, TargetIndex] =     findEdgeInVector(obj, IntensityVector)
            % FINDEDGEINVECTOR: key function for edge detection:
            % takes 1 argument:
            IntensityDifferences =    diff(IntensityVector);
       

            DifferenceLimit =          obj.getBackGroundDifferenceForIntensityVector(IntensityVector)  * obj.DifferenceLimitFactor;

            if isempty(DifferenceLimit) || max(IntensityDifferences) < DifferenceLimit 
                TargetIndex =           NaN;
                Threshold =     NaN;
            else


                TargetIndex =       find(IntensityDifferences >= DifferenceLimit, 1, 'first') + obj.PixelShiftForEdgeDetection;
                if TargetIndex > length(IntensityVector)
                    TargetIndex = length(IntensityVector);  
                elseif TargetIndex<1
                    TargetIndex = 1;
                end

                Threshold =          IntensityVector(TargetIndex);
            end

        end

        function BackgroundDifference =         getBackGroundDifferenceForIntensityVector(obj, IntensityVector)
                IntensityDifferences =                 diff(IntensityVector);
                DifferencesAtPeriphery(1) =            mean(IntensityDifferences( 1 :  obj.NumberOfPixelsForBackground ));
                DifferencesAtPeriphery(2) =            mean(IntensityDifferences( length(IntensityDifferences): -1 :  length(IntensityDifferences)- obj.NumberOfPixelsForBackground ));

                BackgroundDifference =                  max(DifferencesAtPeriphery) * obj.BoostBackgroundFactor;
        end

    end
    
    methods (Access = private) % GETTERS CROPPED IMAGE
        
         function CroppedImageAtRightPlane = getCroppedImageAtCentralPlane(obj)
             % GETCROPPEDIMAGEATCENTRALPLANE get cropped image only of active plane;
                   image =                 obj.convertImageVolumeIntoCroppedVolume(obj.ImageVolume); % get cropped image
                myCroppedImageVolume =            obj.filterPlanesOfCroppedImage(image);
           
               CroppedImageAtRightPlane =      myCroppedImageVolume(:, :, obj.ActiveZCoordinate);
         end
         
        
         
  
         
         function empytImage = filterPlanesOfCroppedImage(obj, image)
               empytImage =                image;
                empytImage(:, :, :) =       0;
                empytImage(:, :, obj.getUpperZPlane : obj.getBottomZPlane) = image(:, :, obj.getUpperZPlane : obj.getBottomZPlane);
             
         end

          function object = convertImageVolumeIntoCroppedVolume(obj, Image)
              object = PMCropImage(Image, ...
                  obj.getMinimumColumnForImageCropping, ...
                  obj.getMaximumColumnForImageCropping, ...
                  obj.getMinimumRowForImageCropping, ...
                  obj.getMaximumRowForImageCropping).getImage;
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
    
    methods (Access = private) % SETTERS THRESHOLDING: VISUALIZE PROCESS

        function obj = showSuccessText(obj, NumberOfCellsAdded)
           
            if obj.ShowSegmentationProgress
                 fprintf('Detected mask number %i.\n', NumberOfCellsAdded)
            end
            
        end
        
        function obj = showFailureText(obj, AccumulatedSegmentationFailures, NumberOfAcceptedFailures)
            
           
             if obj.ShowSegmentationProgress
                    fprintf('Failure count = %i of %i. (', AccumulatedSegmentationFailures, NumberOfAcceptedFailures)

                                MyStringCell =                      obj.getActiveShape.getShapeValidityString;
                                cellfun(@(x) fprintf('%s ', x), MyStringCell)
                                fprintf(')\n')

             end
             
        end
        
        
         function obj =                 showMaskDetectionByClickedPixel(obj, ThresholdedImage)
            
             if obj.ShowSegmentationProgress 
               
                figure(100)
                clf(100)
                obj =                       obj.addGeneralSegmentationPanels(ThresholdedImage);
                  figure(100)
                currentAxesOne=             subplot(3, 3, 4);
                currentAxesOne.Visible =    'off';
                imagesc(max(obj.getCroppedImageWithBlackedOutPixelsRemoved, [], 3));
                obj =                       obj.highlightActivePixel;
                title('Clicked pixel')
                
             end
            
        end
        
         function obj =                 showMasksDetectionByEdgeThreshold(obj, ThresholdedImage)
            
            if obj.ShowSegmentationProgress
                
                figure(100)
                clf(100)
                
                obj =                           obj.addGeneralSegmentationPanels(ThresholdedImage);
                figure(100)
                currentAxesOne=                 subplot(3, 3, 4);
                currentAxesOne.Visible =        'off';
                imagesc(obj.getImageShowingDetectedEdges);
               
                title('Edge detection')
     
            end
            
            
         end
         
         
         
         function obj =                 addGeneralSegmentationPanels(obj, ThresholdedImage)
              figure(100)
                currentAxesOne=             subplot(3, 3, 1);
                currentAxesOne.Visible = 'off';
                 image =                 obj.convertImageVolumeIntoCroppedVolume(obj.ImageVolume); % get cropped image
                MyVolume =            obj.filterPlanesOfCroppedImage(image);
            
                imagesc(max( MyVolume, [], 3))
                title('Cropping')
                
                currentAxesOne=             subplot(3, 3, 2);
                currentAxesOne.Visible =    'off';


                MyPreviousTrackedPixels = obj.getImageOfPreviouslyTrackedPixels;

                imagesc(max(MyPreviousTrackedPixels, [], 3))
                title('Pixels from other tracked cells')
                
                currentAxesOne=             subplot(3, 3, 3);
                currentAxesOne.Visible =    'off';
                imagesc(max(obj.getCroppedImageWithBlackedOutPixelsRemoved, [], 3))
                title('Blacked out pixels removed')
                
                currentAxesOne=             subplot(3, 3, 5);
                currentAxesOne.Visible =    'off';
                imagesc(max(ThresholdedImage, [], 3))
                title('Thresholded')
                
                currentAxesOne=             subplot(3, 3, 6);
                currentAxesOne.Visible =    'off';
                imagesc(max(ThresholdedImage, [], 3))
                obj =                       obj.highlightActivePixel;
                title('Original seed')
                
                currentAxesOne= subplot(3, 3, 7);
                currentAxesOne.Visible = 'off';
                imagesc(max(ThresholdedImage, [], 3))
                
                CentralPlane =                  obj.getOptimizedPlaneForSeed(ThresholdedImage);
                [Row, Column] =                 obj.getClosestFullPixelToSeedInImage(ThresholdedImage(:, :, CentralPlane));
                
                MyLine =                        line(Column, Row);
                MyLine.Marker = 'x';
                MyLine.MarkerSize = 25;
                MyLine.Color = 'black';
                MyLine.LineWidth = 20;
                title('Optimized seed')
                
                currentAxesOne=                 subplot(3, 3, 8);
                currentAxesOne.Visible =        'off';
                image =                         obj.convertImageVolumeIntoCroppedVolume(obj.getActiveShape.getRawImageVolume);
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
                image = obj.convertImageVolumeIntoCroppedVolume(obj.getActiveShape.getImageVolume);
                imagesc(max(image, [], 3))
                title('After shape verification')
                
                 MyText = sprintf('Radius: Min= %6.2f, Max= %6.2f\n', obj.MinimumCellRadius, obj.MaximumCellRadius);
                 Text = text(currentAxesOne.XLim(1),currentAxesOne.YLim(2),MyText);
                 Text.Color = 'w';
                 
               
             
         end
         
         function Image =               getImageOfPreviouslyTrackedPixels(obj) 
              image =                 obj.convertImageVolumeIntoCroppedVolume(obj.ImageVolume); % get cropped image
                Image =            obj.filterPlanesOfCroppedImage(image);

                Image(:,: ) = 0;           
          
            PrevsiouslyTrackedPixels_Nocrop =   obj.getAllPreviouslyTrackedPixels;

             


            PreviouslyTrackedPixels =   obj.removeCroppingFromCoordinateList(PrevsiouslyTrackedPixels_Nocrop);
            
            myImage =                     PMImage(Image).addCoordinatesWithIntensityPrecise(PreviouslyTrackedPixels, 255);

            Image  =                    myImage.getImage;

             
         end
         
         function HighlightedImage =    getImageShowingDetectedEdges(obj)
             % GETIMAGESHOWINGDETECTEDEDGES returns cropped images where "edge-pixels" are highlighted;
            HighlightedImage =                          obj.getCroppedImageAtCentralPlane;
            HighlightedImage(obj.getSeedRow, :) =       255;
            HighlightedImage(:, obj.getSeedColumn) =    255;
            
             Rows = obj.getRowPositionsForEdgeDetection(obj.getCroppedImageAtCentralPlane);
             Rows(Rows==0) = 1;
             
             if isnan(Rows(1))
                 
             else
                 try
                        HighlightedImage(Rows(1) ,obj.getSeedColumn) =                  0;
                 catch
                    disp('test') 
                 end
                
                HighlightedImage(end - Rows(1) + 1 ,obj.getSeedColumn) =        0;

                Columns =                           obj.getColumnPositionsForEdgeDetection(obj.getCroppedImageAtCentralPlane);
                
                if isnan(Columns(1))
                    
                else
                    HighlightedImage(obj.getSeedRow, Columns(1) ) = 0;
                    HighlightedImage(obj.getSeedRow, end - Columns(1) + 1 ) = 0;
                end
                
                
             end
             
            
             
             
         end

         function obj =                 highlightActivePixel(obj)
            MyLine =                    line(obj.getSeedColumn, obj.getSeedRow);
            MyLine.Marker =             'x';
            MyLine.MarkerSize =         20;
            MyLine.Color =              'red';
            MyLine.LineWidth =          5;
            
         end

    end
    
    methods (Access = private) % GETTERS THRESHOLDING
       
         function Threshold =                getIntensityOfClickedPixel(obj)
            Threshold =      obj.ImageVolume(obj.ActiveYCoordinate, obj.ActiveXCoordinate, obj.ActiveZCoordinate);
        end

  
    end
    
    methods (Access = private) % SETTERS SEGMENTATION
       
         function obj = generateMaskByEdgeDetectionForceSizeBelowInternal(obj)
             % GENERATEMASKBYEDGEDETECTIONFORCESIZEBELOWINTERNAL ;
             % enforce size below maximum radius by iteratively increasing pixel-shift;
            
                obj =               obj.generateMaskByAutoThreshold;
                PixelShift =        0;

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
        
    end
    
    methods (Access = private) % GETTERS CROPPED IMAGE FOR SEGMENTATION;
       
          function Image =                          getCroppedImageWithExistingMasksRemoved(obj)
              % GETCROPPEDIMAGEWITHEXISTINGMASKSREMOVED returns cropped image volume where all pixels from previously tracked cells are set to value 0;
            CoordinatesToZeroOut =           obj.removeCroppingFromCoordinateList(obj.getAllPreviouslyTrackedPixels);
            
             image =                 obj.convertImageVolumeIntoCroppedVolume(obj.ImageVolume); % get cropped image
                MyVolume =            obj.filterPlanesOfCroppedImage(image);
             
             Image =                     PMImage(MyVolume ).addCoordinatesWithIntensityPrecise(CoordinatesToZeroOut, 0).getImage;
            
            
          end
          
          function Image =                          getCroppedImageWithBlackedOutPixelsRemoved(obj)
              % GETCROPPEDIMAGEWITHEXISTINGMASKSREMOVED returns cropped image volume where all pixels from previously tracked cells are set to value 0;
                CoordinatesToZeroOut =           obj.removeCroppingFromCoordinateList(obj.BlackedOutPixels);
                 image =                 obj.convertImageVolumeIntoCroppedVolume(obj.ImageVolume); % get cropped image
                MyVolume =            obj.filterPlanesOfCroppedImage(image);
           
                Image =                            PMImage(MyVolume).addCoordinatesWithIntensityPrecise(CoordinatesToZeroOut, 0).getImage;
            
          end
          
          
          
        
        function [ListWithPixels] =         removeCroppingFromCoordinateList(obj, ListWithPixels)
           if isempty(obj.getRowsLostFromCropping)
               ListWithPixels = zeros(0, 3);
           else
               ListWithPixels(:,1) =    ListWithPixels(:,1) - obj.getRowsLostFromCropping;
            ListWithPixels(:,2) =    ListWithPixels(:,2) - obj.getColumnsLostFromCropping;
               
           end
            
            
        end
        
           function [ListWithPixels] =       addCroppingToCoordinateList(obj, ListWithPixels)
                ListWithPixels(:,1) =               ListWithPixels(:,1) + obj.getRowsLostFromCropping;
                ListWithPixels(:,2) =               ListWithPixels(:,2) + obj.getColumnsLostFromCropping;
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
        
        
        
    end
    
    methods (Access = private) % GETTERS ACTIVE COORDINATES
       
         function SeedRow =               getSeedRow(obj)
             % GETSEEDROW returns active row, adjusted for cropped image;
                    SeedRow =          obj.ActiveYCoordinate - obj.getRowsLostFromCropping;                                   
           end
           
        function SeedColumn =           getSeedColumn(obj)
            % GETSEEDCOLUMN returns active column, adjusted for cropped image;
                    SeedColumn =       obj.ActiveXCoordinate - obj.getColumnsLostFromCropping;                             
        end
        
        
    end
    
    methods (Access = private) % GET CONNECTED PIXELS
        
     

        function CoordinatesOfAllPlanes =       removeNegativeCoordinates(~, CoordinatesOfAllPlanes)
            NegativeValuesOne =            CoordinatesOfAllPlanes(:,1) < 0;
            NegativeValuesTwo =            CoordinatesOfAllPlanes(:,2) < 0;
            NegativeValuesThree =          CoordinatesOfAllPlanes(:,3) < 0;

            rowsWithNegativeValues =      max([NegativeValuesOne, NegativeValuesTwo, NegativeValuesThree], [], 2);
            CoordinatesOfAllPlanes(rowsWithNegativeValues,:) =      [];
        end

        function [CentralPlane, PlanesAbove, PlanesBelow, numberOfPlanes] = getConnectedPlaneSpecification(obj, myCroppedImageVolumeMask)
            % GETCONNECTEDPLANESPECIFICATION returns plane settings that should be combined;

            CentralPlane =    obj.getOptimizedPlaneForSeed(myCroppedImageVolumeMask); % get central plane (usually active Z, unless the center-pixel is 0;
            numberOfPlanes =  length(obj.getUpperZPlane : obj.getBottomZPlane);
            PlanesAbove =     CentralPlane -1 : -1 : obj.getUpperZPlane; % maybe include more checks: e.g. make isnan or empty when no values exist;
            PlanesBelow =     CentralPlane + 1 : 1 : obj.getBottomZPlane;

        end

        function [myActiveZCoordinate] =        getOptimizedPlaneForSeed(obj, myCroppedImageVolumeMask)

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

      

        function [Row, Column] =                getClosestFullPixelToSeedInImage(obj, Image)

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

        function [ListWithOverlappingPixels]=    FindContactAreasInNeighborPlane(obj, Structure, CoordinatesOfNeightborList, PlaneIndex)


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
                  [CoordinatesOfSelectedRegion] =  obj.addCroppingToCoordinateList([ Rows , Columns]);
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
    
    methods (Access = private) % SETTERS: ACTIVE COORDINATE: BRIGHTEST PIXEL;
       
        function obj =                                      setActiveCoordinateByBrightestPixelsInternal(obj)
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
       
        function [CoordinatesWithMaximumIntensity] =        getBrightestCoordinatesFromActiveMask(obj)

               
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
        
        function PixelIntensities =                         getPixelIntensitiesOfActiveMask(obj)
            if isempty(obj.ImageVolume)
                PixelIntensities = '';
            else
                 PixelIntensities =        double(arrayfun(@(row,column,plane)...
                                                obj.ImageVolume(row,column,plane), ...
                                                obj.MaskCoordinateList(:,1),...
                                                obj.MaskCoordinateList(:,2),...
                                                obj.MaskCoordinateList(:,3)));
            end
           
        end
         
    end
    
    methods (Access = private) % SETTERS: ACTIVE COORDINATE
       
        function obj = setActiveCoordinateByImageModel(obj, FilteredImageModel)
           
                obj =                               obj.resetMask;
                [xCoordinate, yCoordinate] =    FilteredImageModel.getBrightestPositionInImage;
                
                
                obj.ActiveXCoordinateHistory(end + 1, 1) = obj.ActiveXCoordinate;  
                obj.ActiveYCoordinateHistory(end + 1, 1) = obj.ActiveYCoordinate;  
                
                obj.ActiveYCoordinate =         yCoordinate;
                obj.ActiveXCoordinate =         xCoordinate;
                
                
                
                
            
        end
      
         function obj = showSourceImages(obj, OriginalImageModel, OriginalBlackImageModel, FilteredBlackImageModel)
            
               if obj.ShowSegmentationProgress
                   
                   
                   
                   
                    figure(103)
                    AxesOne = subplot(1,3,1);
                    AxesTwo = subplot(1,3,2);
                    AxesThree = subplot(1,3,3);

                     imagesc(AxesOne, OriginalImageModel.getImage)
                    imagesc(AxesTwo, OriginalBlackImageModel.getImage)

                    imagesc(AxesThree, FilteredBlackImageModel.getImage)

                    title(AxesOne,'Original image') 
                    title(AxesTwo,'Blacked out image')
                      title(AxesThree,'Blacked out image after median filter') 
                      
                    myLineOne = obj.getLineForActivePosition;
                    obj.getMyHistoryLines( AxesOne);
                    
                    
                    myLineOne.Parent = AxesOne;
                    
                    myLineTwo = obj.getLineForActivePosition;
                    myLineTwo.Parent = AxesTwo;
                     obj.getMyHistoryLines( AxesTwo);
                    
                    myLineThree = obj.getLineForActivePosition;
                    myLineThree.Parent = AxesThree;
                    
                     obj.getMyHistoryLines( AxesThree);
                
                
               end
            
             
         end
         
         function myLine = getLineForActivePosition(obj)
             
             myLine =   line(obj.ActiveXCoordinate, obj.ActiveYCoordinate);
             myLine.Color = 'red';
             myLine.LineStyle = 'none';
             myLine.Marker = 'x';
              myLine.MarkerSize  = 20;
              myLine.LineWidth = 3;
    
            myLine.MarkerFaceColor = 'red';
             
         end
         
         function myHistoryLines = getMyHistoryLines(obj, Parent)
             
             myHistoryLines = arrayfun(@(x, y) line(x, y), obj.ActiveXCoordinateHistory, obj.ActiveYCoordinateHistory);
            
             myHistoryLines = arrayfun(@(x) obj.formatHistoryLine(x, Parent), myHistoryLines);
             
             
         end
         
         function myLine = formatHistoryLine(obj, myLine, MyParent)
             
              myLine.Color = 'white';
             myLine.LineStyle = 'none';
             myLine.Marker = 'o';
              myLine.MarkerSize  = 20;
              myLine.LineWidth = 2;
    
            myLine.MarkerFaceColor = 'none';
             myLine.MarkerEdgeColor = 'white';
            
             myLine.Parent = MyParent;
             
         end
        
        
    end
    
    methods (Access = private)

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

        
    end
    
    methods (Access = private) % EDGE-DELTION SEGMENTATION ALGORITHM- INCOMPLETE FRAGMENT ;
        
        function obj =                                  betaFunction(obj)
            
            [ImageWithDeletedEdges, edges]=   obj.getImageWithDeletedEdges(SourceThresholdImage);
            ImageWithDeletedEdges =           obj.deleteEdges(ImageWithDeletedEdges, SourceImage, edges);

            figure(1000)

            imagesc(ImageWithDeletedEdges)
            ListWithPostSplitCoordinates =  cell(20,1);

            KeepGoing = true;
           Count = 0;
            while KeepGoing
                
                CoordinateListAfterEdgeRemoval =    obj.convertConnectedPixelsIntoCoordinateList(ImageWithDeletedEdges);
                if isempty(CoordinateListAfterEdgeRemoval)
                    KeepGoing = false;
                    
                else
                    
                        MyShape =                           PMShape(CoordinateListAfterEdgeRemoval, 'YXZ');
                        Image =                             MyShape.getRawImageVolume ;

                        figure(106)
                        imagesc(Image)

                        h =         fspecial('disk', 3);
                        Image = imdilate(Image, h);
                        Image = imdilate(Image, h);
                        Image = imdilate(Image, h);
                        Image = imdilate(Image, h);

                        figure(107)

                        Image(size(SourceThresholdImage, 1), size(SourceThresholdImage, 2)) = 0;
                        imagesc(Image)

                        [CoordinateList] =                              obj.addCroppingToCoordinateList(CoordinateListAfterEdgeRemoval);
                        Count =                                         Count + 1;
                        ListWithPostSplitCoordinates{Count,  1} =       CoordinateList;

                        ImageWithDeletedEdges =                     PMImage(ImageWithDeletedEdges).addCoordinatesWithIntensityPrecise(CoordinateListAfterEdgeRemoval, 0).getImage;
                        figure(1000 + Count)

                        imagesc(ImageWithDeletedEdges)
   
                end
                
                Empty = cellfun(@(x) isempty(x), ListWithPostSplitCoordinates);
                ListWithPostSplitCoordinates(Empty, :) = [];
                obj.MaskSeriesCoordinates = ListWithPostSplitCoordinates;

            end
            
        end
        
        function [ImageWithDeletedEdges, edges] =       getImageWithDeletedEdges(obj, SourceThresholdImage)
            
            
                CoordinatesOfSourceImage_WithoutCrop =     obj.convertConnectedPixelsIntoCoordinateList(SourceThresholdImage);
                 
                SourceImageForEdgeDetection =               obj.convertSourceImageAndCoordinateListToEdgeDetectionImage(...
                                                                    SourceThresholdImage, ...
                                                                    CoordinatesOfSourceImage_WithoutCrop...
                                                                    );
                                     
                 [ImageWithDeletedEdges, edges] =                    obj.deleteEdgesOfInputImage(SourceImageForEdgeDetection);
                        
        end

        function BW2 =                                  deleteEdges(obj, ImageWithDeletedEdges, SourceImageForEdgeDetection, edges)
           
            figure(104)
            imagesc(ImageWithDeletedEdges)

            [row, column] = find(edges == 1);
            Intensities = arrayfun(@(x, y) SourceImageForEdgeDetection(x, y), row, column);

            Y = prctile(Intensities(:), 95);
            %  ImageWithDeletedEdges(ImageWithDeletedEdges<Y) = 0;

            BW = uint8(ImageWithDeletedEdges > Y);

            BW2 = bwareaopen(BW, 100);

            figure(105)
            imagesc(BW2)

            BW2 = uint8(BW2);
            
        end
        
        function NewImage =                             convertSourceImageAndCoordinateListToEdgeDetectionImage(obj, ThresholdedImage, CoordinatesWithoutCrop)
            
                MyShape =                       PMShape(CoordinatesWithoutCrop, 'YXZ');
                Image =                         MyShape.getRawImageVolume ;

                Image(size(ThresholdedImage, 1), size(ThresholdedImage, 2)) = 0;
               
                h =         fspecial('disk', 2);
                Eroded =    imerode(Image, h);
                
                 h =         fspecial('disk', 2);
                Eroded =    imerode(Eroded, h);
                
                  h =         fspecial('disk', 2);
                Eroded =    imerode(Eroded, h);
                
                NewImage = ThresholdedImage .* Eroded;

                h =         fspecial('disk',10);
                NewImage=          imfilter(NewImage, h);
                
                if obj.ShowSegmentationProgress
                    
                    figure(90)
                    imagesc(Image)

                     figure(100)
                    imagesc(Eroded)

                    figure(101)
                    imagesc(NewImage)
                end

                
            
        end
        
        function [CroppedImage, edges] =                deleteEdgesOfInputImage(obj, CroppedImage)

            edges =         edge(CroppedImage, 'Canny');
            se =            strel('disk', 4);
            edges =         imdilate(edges, se);

            CroppedImage =  CroppedImage .* uint8(~edges);
            if obj.ShowSegmentationProgress    
                figure(102)
                imagesc(edges)

                figure(103)
                imagesc(CroppedImage)

            end

        end  
        
        
    end
    
end

