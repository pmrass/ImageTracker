classdef PMAutoCellRecognition
    %PMAUTOCELLRECOGNITION Enables autodetection of roundish objects in image-sequence;
    %   Can independently recognize shapes in specified channel of imported image-sequence;
    
    properties (Access = private) % DATA-SOURCE AND RANGE
        
        ImageSequence
        
        ShowViewsForControl =          0;
        ActiveChannel =                1
        SelectedFrames =               1
        
    end
    
    properties (Access = private) % RESULTS
        DetectedCoordinates =                cell(0,1);

    end
    
    properties (Access = private)
        % also currently misssing: information of how the image was created (e.g. was opening used?);
        
        % approach : use circle recognition to detect cells;
        % currently this is done by user defined edge-thresholds radius and sensitivty;
        % a future approach could be:;
        % 1: loop through different contrasts (e.g. 0.2 to 0.02);
        % 2: recognize cells and erase high-density cells (e.g. a cell has more than 5 neighhbors with x �m);
        % 3: then pool the different analysis; this should combine high sensitity and specificity;
        
        % after turning off median filtering, approach worked much better; therefore this is not high priority right now;
        % set these values for each plane;
        % cells get to get smaller/dimmer in deeper planes therefore size of filter/ radisu and sensitivy should be increase; 

        RadiusRange =                       [];
        Sensitivity =                       []% higher values make it more sensitive (more circles are detected (use between 0.85 and 0.95;
        EdgeThreshold =                     []; % higher values require higher contrast;
                  
        EliminateHighDensityEvents =        false;
        HighDensityDistanceLimit =          50; % if a cell has too many neighbors, it will be deleted;
        HighDensityNumberLimit =            9; % this is possibly noise, or if they are cells they would be difficult to track anyway;
        
        DistanceLimitForPlaneMerging =       10;
       
  
    end

    properties (Access = private) % INTENSITY-RECOGNITION
    
        PreventDoubleTracking = false
        PreventDoubleTrackingDistance = NaN

        
    end
    
    properties (Access = private) % CIRCLE-RECOGNITION
        RadiusRangeFirstPlane =       [5, 9];
        RadiusRangeLastPlane =       [5, 10];

        SensitivityMinimum=        0.92;
        SensitivityMaximum=        0.95;

        EdgeThresholdMinimum =     0.85;
        EdgeThresholdMaximum =     0.85;
        
    end
   
    methods % INITIALIZATION
        
           function obj = PMAutoCellRecognition(varargin)
                %PMAUTOCELLRECOGNITION Construct an instance of this class
                % takes 0 or 2 arguments:
                % 1: 5D image-sequence
                % 2: index of channel that should be analyzed (numeric scalar)
                switch length(varargin)
                   
                    case 0
                         
                    case 2
                        
                        myImageSequence =           varargin{1};
                        Channel =                   varargin{2};
                        
                        assert(size(myImageSequence,1) >= 1, 'ImageSequence must contain at least one frame');

                        obj.ImageSequence =          myImageSequence;
                        obj.ActiveChannel =          Channel;
                        
                        obj =                       obj.interpolateRanges;
                        
                      
                        
                    otherwise
                        error('Wrong input.')
                    
                    
                end
            
           end
           
           function obj = set.ActiveChannel(obj, Value)
               assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
              obj.ActiveChannel = Value; 
           end
           
           function obj = set.SelectedFrames(obj, Value)
                assert(isnumeric(Value) && isvector(Value), 'Wrong input.')
                obj.SelectedFrames = Value; 
           end
   
    end
    
    methods % SUMMARY
        
        function obj = showSummary(obj)

            if obj.PreventDoubleTracking
               fprintf('Prevent double-tracking.\n') 
            end
            
            fprintf('Double tracking distance = %6.2f\n', obj.PreventDoubleTrackingDistance)
            
          
           fprintf('Number of frames: %i.\n', obj.getNumberOfPlanes)
           
           
              

            
        end
        
    end
    
    methods % SETTERS ACTION
        
            function obj =      performMethod(obj, Value, varargin)
           
            obj = obj.(Value)(varargin{:});
            
        end
        
    end
    
    methods % SETTERS

        function obj =      setImageSequence(obj, Value)
           obj.ImageSequence = Value; 
        end

        function obj =      setSelectedFrames(obj, Value)
            obj.SelectedFrames = Value; 
        end

        function obj =      setActiveChannel(obj, Value)
            obj.ActiveChannel = Value; 
        end

        function obj =     removeRedundantData(obj)
                obj.ImageSequence = cell(size(obj.ImageSequence,1),1);
        end

    end

    methods % SETTERS INTENSITY-RECOGNITION

       function obj =       setPreventDoubleTracking(obj, Value)
           obj.PreventDoubleTracking = Value;
       end

       function obj =       setPreventDoubleTrackingDistance(obj, Value)
           obj.PreventDoubleTrackingDistance = Value;
       end

    end

    methods % SETTERS RANGES

         function obj =     setHighDensityDistanceLimit(obj, Value)
            obj.HighDensityDistanceLimit = Value;
        end

        function obj =      setHighDensityNumberLimit(obj, Value)
            obj.HighDensityNumberLimit = Value;
        end

        function obj =      setCircleLimitsBy(obj, Value)

            if isempty(Value)


            elseif ismatrix(Value) && isnumeric(Value)

                obj.RadiusRangeFirstPlane =       [Value(1,1), Value(1, 2)];
                obj.RadiusRangeLastPlane =        [Value(end,1), Value(end, 2)];

                obj.SensitivityMinimum=        Value(1, 3);
                obj.SensitivityMaximum=        Value(end, 3);

                obj.EdgeThresholdMinimum =     Value(1, 4);
                obj.EdgeThresholdMaximum =     Value(end, 4);

            else
                error('Wrong input.')

            end


    end

        function obj =      interpolateRanges(obj)
                obj =           obj.interpolateRadiusLimits;
                obj =           obj.interpolateSensitivityLimits;
                obj =           obj.interpolateEdgeThresholdLimits;
        end

    end

    methods % SUMMARIES

         function obj = printSettings(obj)

           if length(obj.ActiveChannel) ~= 1
            fprintf('Failure because of the following reason:\n')
            fprintf('Currently not exactly one channel is selected.\nThe following channels are currently selected:')
            arrayfun(@(x) fprintf(' %i', x), obj.ActiveChannel)
            fprintf('.\n')
            error('For this reason @performAutoDetection triggered an error.')

         end



         if size(obj.RadiusRange,1)~= 1 && size(obj.RadiusRange,1)~= obj.getNumberOfPlanes
             fprintf('This movie has %i planes. This does not match the number of entered radius values, which is %i.\n', obj.getNumberOfPlanes, size(obj.RadiusRange,1))
             error('For this reason @performAutoDetection triggered an error.')
         end

         if size(obj.EdgeThreshold,1)~= 1 && size(obj.EdgeThreshold,1)~= obj.getNumberOfPlanes
             fprintf('This movie has %i planes. This does not match the number of entered edge-threshold values, which is %i.\n', obj.getNumberOfPlanes, size(obj.EdgeThreshold,1))
             error('For this reason @performAutoDetection triggered an error.')
         end

          if size(obj.Sensitivity,1)~= 1 && size(obj.Sensitivity,1)~= obj.getNumberOfPlanes
             fprintf('This movie has %i planes. This does not match the number of entered sensitivity values, which is %i.\n', obj.getNumberOfPlanes, size(obj.Sensitivity,1))
             error('For this reason @performAutoDetection triggered an error.')
         end




        fprintf('Analyzing frames')
        arrayfun(@(x)  fprintf(' %i', x), obj.SelectedFrames)
        fprintf('.\n')


        fprintf('Analyzing %i planes.',obj.getNumberOfPlanes)

        fprintf('\nSensitivity settings [0,1]: 0.85 = good starting value; 0 = low ; 1 = high sensitivity; high detects more objects\n')
        arrayfun(@(x) fprintf('%1.3f ', x), obj.Sensitivity)
        fprintf('\n')
        fprintf('EdgeThreshold [0,1]: 0.85 = good starting value; 0 = low ; 1 = high edge requirement; low detects more objects\n')
        arrayfun(@(x) fprintf('%1.3f ', x), obj.EdgeThreshold)
        fprintf('\n')
        fprintf('Radius range:')
        arrayfun(@(x,y) fprintf(' %i %i;', x, y), obj.RadiusRange(:,1),obj.RadiusRange(:,2))
        fprintf('\n')
        if obj.EliminateHighDensityEvents
            fprintf('Objects that have more than %i neighbors within a distance of %i pixels will be deleted.\n', obj.HighDensityNumberLimit, obj.HighDensityDistanceLimit);
        else
             fprintf('No checking for high-density.\n')
        end

         end

    end

    methods % GETTERS RESULTS

        function cells = getDetectedCoordinates(obj)
            cells = obj.DetectedCoordinates;
        end

    end

    methods % GETTERS GENERAL AUTOTRACKING

        function frames =       getSelectedFrames(obj)
            frames = sort(obj.SelectedFrames(:)); 
        end

        function channel =      getActiveChannel(obj)
            channel = obj.ActiveChannel;
        end


    end

    methods % GETTERS INTENSITY-RECOGNITION

       function Value =         getPreventDoubleTracking(obj)
           Value = obj.PreventDoubleTracking;
       end

       function Value =         getPreventDoubleTrackingDistance(obj)
           Value = obj.PreventDoubleTrackingDistance;
       end

    end

    methods % ACTION: performAutoDetection

        function obj =          performAutoDetection(obj)
            % PERFORMAUTODETECTION goes through each frame of the image-sequence and detects shapes in each plane;
            % sets DetectedCoordinates property with detected masks;

            fprintf('\nPMAutoCellRecognition: @performAutoDetection.\n')

            obj =       obj.printSettings;
            CollectionOfCellMasks_Frames =          cell(size(obj.ImageSequence,1),1);
            for SetFrame = (obj.SelectedFrames)'

                fprintf('Auto recognition: frame %i\n', SetFrame)
                MyImageVolume =                                 obj.ImageSequence{SetFrame, 1}(:, :, :, :, obj.ActiveChannel);
                CollectionOfCellMasks_Planes =                  obj.getCoordinatesFromImageVolume(MyImageVolume);
                PlaneDataAfterPoolingPlanes =                   obj.combinePixelsFromNeighboringPlanes(vertcat(CollectionOfCellMasks_Planes{:}));
                CollectionOfCellMasks_Frames{SetFrame,1} =      obj.createMiniMasks( PlaneDataAfterPoolingPlanes);

            end

            obj.DetectedCoordinates =     CollectionOfCellMasks_Frames;
            obj.ImageSequence =           cell(size(obj.ImageSequence,1),1); % empty memory
            fprintf('A total of %i object were detected.\n', sum(cellfun(@(x) length(x), obj.DetectedCoordinates)));

        end

    end
    
  
    methods  % GETTERS
        
       function number =           getNumberOfChannels(obj)
            assert(~isempty(obj.ImageSequence), 'No image sequence set. Unknown channel number.')
           number = size(obj.ImageSequence{1},5);
        end
        
        function number =           getNumberOfPlanes(obj)
             frames = obj.getAvailableFrames;
             if isnan(frames)
                  number = NaN;
             else
                  number = size(obj.ImageSequence{frames(1)},3);
             end

        end

        function listWithFrames =   getAvailableFrames(obj)
            if ~isempty(obj.ImageSequence)
                 listWithFrames =       find(cellfun(@(x) ~isempty(x), obj.ImageSequence));
                 listWithFrames =       listWithFrames(:);
                 if isempty(listWithFrames)
                     listWithFrames = NaN;
                 end
             
            else
                listWithFrames = NaN;
            end
        end

        function radiusRanges =     getRadiusRanges(obj)
            radiusRanges = obj.RadiusRange;
        end

        function sensitivities =    getSensitivities(obj)
            sensitivities = obj.Sensitivity;
        end

        function thresholds =       getEdgeThresholds(obj)
            thresholds = obj.EdgeThreshold; 
        end

        function thresholds =       getHighDensityNumberLimit(obj)
            thresholds = obj.HighDensityNumberLimit; 
        end

        function thresholds =       getHighDensityDistanceLimit(obj)
            thresholds = obj.HighDensityDistanceLimit; 
        end

    end
    
    methods (Access = private) % SETTERS RANGES
        
        function obj = interpolateRadiusLimits(obj)
            obj = obj.setLinearRadiusLimits(...
                [obj.RadiusRangeFirstPlane(1), obj.RadiusRangeFirstPlane(2)], [obj.RadiusRangeLastPlane(1), obj.RadiusRangeLastPlane(2)]);
        end

        function obj = interpolateSensitivityLimits(obj)
            obj = obj.setLinearSensitivityLimits(...
                obj.SensitivityMinimum, obj.SensitivityMaximum);
        end

        function obj = interpolateEdgeThresholdLimits(obj)
            obj = obj.setLinearEdgeThresholdLimits(...
                obj.EdgeThresholdMinimum, obj.EdgeThresholdMaximum);
        end
        
    end
 
    methods (Access = private)
        
        function obj = setLinearRadiusLimits(obj, RangeFirstPlane, RangeLastPlane)
            obj.RadiusRange(:,1) =      round(linspace(RangeFirstPlane(1), RangeLastPlane(1), obj.getNumberOfPlanes));
            obj.RadiusRange(:,2) =      round(linspace(RangeFirstPlane(2), RangeLastPlane(2), obj.getNumberOfPlanes));
        end
        
        %% interpolateSensitivityLimits:
        
        function obj = setLinearSensitivityLimits(obj, Min, Max)
            obj.Sensitivity(:,1) =              linspace(Min, Max, obj.getNumberOfPlanes);
        end
        
        %% interpolateEdgeThresholdLimits:
       
        
        function obj = setLinearEdgeThresholdLimits(obj, Min, Max)
             obj.EdgeThreshold(:,1) =            linspace( Min, Max, obj.getNumberOfPlanes);
        end
        
        
        
         function CollectionOfCellMasks_Planes = getCoordinatesFromImageVolume(obj, ImageVolume)
             
            CollectionOfCellMasks_Planes =      cell(size(ImageVolume,3),1);
            for  SetPlane= 1 : size(ImageVolume, 3)
                
                ImageOfCurrentPlane = ImageVolume(:, :, SetPlane);
                figure(100)
                imagesc(ImageOfCurrentPlane)
                
                    MyDetectedCoordinates =      imfindcircles( ImageOfCurrentPlane, obj.RadiusRange(SetPlane,:), ...
                                            'Sensitivity' ,  obj.Sensitivity(SetPlane), 'EdgeThreshold', obj.EdgeThreshold(SetPlane));
                    if isempty(MyDetectedCoordinates)
                    else
                        MyFilteredCoordinates = obj.removeHighDensityCoordinates(MyDetectedCoordinates, ImageVolume(:,:,SetPlane));
                        
                        if obj.ShowViewsForControl
                           obj = obj.showFollowingCoordinates(MyFilteredCoordinates);

                        end

                        MyFilteredCoordinates(:,3) =                            SetPlane;
                        CollectionOfCellMasks_Planes{SetPlane,1} =              MyFilteredCoordinates; 
                    end

            end
                    
        end
        
        
        
        function [CoordinateList] = removeHighDensityCoordinates(obj,CoordinateList,myImage)
            

            NumberOfCellsWithinLimit =      sum(pdist2(CoordinateList,CoordinateList) < obj.HighDensityDistanceLimit,2);
            RowsToDeleteBecauseToDense =    find(NumberOfCellsWithinLimit >= obj.HighDensityNumberLimit);
 
            CoordinatesToDelete =           CoordinateList(RowsToDeleteBecauseToDense,:);
            NumberOfEventsToSave =          round(length(CoordinatesToDelete) * 0.15);
            IntensityList =                 arrayfun(@(row,column) myImage(row,column), round(CoordinatesToDelete(:,1)), round(CoordinatesToDelete(:,2)));
             [~,I] =                        maxk(IntensityList, NumberOfEventsToSave);
            RowsToDeleteBecauseToDense(I,:) = []; % save brightest points from deletion;
            
            CoordinateList(RowsToDeleteBecauseToDense,:) =  [];
            
        end
        
        function obj = showFollowingCoordinates(obj, MyFilteredCoordinates)
           
            figure(20)
            imagesc(obj.ImageSequence{SetFrame,1}(:,:,SetPlane,:,obj.ActiveChannel))

            FigureNumber = 21;
            obj.showCoordinates(obj.ImageSequence{SetFrame,1}(:,:,SetPlane,:,obj.ActiveChannel),MyDetectedCoordinates,FigureNumber)


            FigureNumber = 22;
            obj.showCoordinates(obj.ImageSequence{SetFrame,1}(:,:,SetPlane,:,obj.ActiveChannel),MyFilteredCoordinates,FigureNumber)

        end
        
        function showCoordinates(obj, myImage, MyDetectedCoordinates, FigureNumber)
            
                figure(FigureNumber)
                imagesc(myImage)
                if ~isempty(MyDetectedCoordinates)
                    myLine =               line(MyDetectedCoordinates(:,1),MyDetectedCoordinates(:,2));
                    myLine.LineStyle =     'none';
                    myLine.Marker =        'x';
                    myLine.Color =         'w';
                end

        end
        
   
        function CoordinateListAfterPooling =     combinePixelsFromNeighboringPlanes(obj, ListWithRemainingTargetCoordinates)

                  CoordinateListAfterPooling =              zeros(0,4);
                  TargetCoordinatesForFirstMask =  zeros(0,3);


                  while ~isempty(ListWithRemainingTargetCoordinates)


                        ListWithRemainingTargetCoordinates =        sortrows(ListWithRemainingTargetCoordinates,3); % sort by plane so that search for neighboring planes goes from top to bottom;
                        FirstMaskInList =      ListWithRemainingTargetCoordinates(1,:);
                        ListWithRemainingTargetCoordinates(1,:) =   [];

                        XWithinLimit =         abs(FirstMaskInList(1) - ListWithRemainingTargetCoordinates(:,1)) < obj.DistanceLimitForPlaneMerging;
                        YWithinLimit =         abs(FirstMaskInList(2) - ListWithRemainingTargetCoordinates(:,2)) < obj.DistanceLimitForPlaneMerging;
                        RowsWithinLimit =      find(min([XWithinLimit YWithinLimit], [], 2));

                        %% if possible neighboring coordinates are found, shift them from the general coordinates to the reference coordinate;
                        if ~isempty(RowsWithinLimit)

                            TargetCoordinatesForFirstMask =         ListWithRemainingTargetCoordinates( RowsWithinLimit,:);
                            ListWithRemainingTargetCoordinates(RowsWithinLimit,:) =    [];

                            while 1 % not sure whether this loop is necessary;
                                ZDifferences =        round(abs(TargetCoordinatesForFirstMask(:,3) - max(FirstMaskInList(:,3))));
                                if min(ZDifferences)>1
                                    break
                                else

                                    % get and delete target coordinates that are in direct contact with current Bottom Z;
                                    TargetRowsInDirectContact =                ZDifferences <= 1;
                                    TargetCoordinatesThatAreTransferred =      TargetCoordinatesForFirstMask(TargetRowsInDirectContact,:);
                                    TargetCoordinatesForFirstMask(TargetRowsInDirectContact,:) =     [];

                                    FirstMaskInList =          [FirstMaskInList;   TargetCoordinatesThatAreTransferred ];


                                    if isempty(TargetCoordinatesForFirstMask)
                                       break 
                                    end

                                end

                            end
                            ListWithRemainingTargetCoordinates =       [ListWithRemainingTargetCoordinates; TargetCoordinatesForFirstMask]; % unused coordinates get shift back;

                        end

                        NewCoordinate(1,1) =                    round(mean(FirstMaskInList(:,1)));
                        NewCoordinate(1,2) =                    round(mean(FirstMaskInList(:,2)));
                        NewCoordinate(1,3) =                    min(FirstMaskInList(:,3));
                        NewCoordinate(1,4) =                    max(FirstMaskInList(:,3));
                        CoordinateListAfterPooling =            [CoordinateListAfterPooling;NewCoordinate];
                  end
                  CoordinateListAfterPooling =         sortrows(CoordinateListAfterPooling, [1,2,3]);
        end

        function CollectionOfCoordinates_AfterPlanePooling = createMiniMasks(obj, PlaneDataAfterPoolingPlanes);
                % convert plane upper and lower limit to "mini-pixel" list;
                % this is complicated; should be simplified;
                NumberOfCells =                                 size(PlaneDataAfterPoolingPlanes,1);
                CollectionOfCoordinates_AfterPlanePooling =     cell(NumberOfCells,1);
                for CurrentCellIndex = 1:NumberOfCells

                        % get new track ID and set LoadedMovie;
                        CurrentCoordinate =                             PlaneDataAfterPoolingPlanes(CurrentCellIndex,:);
                        PlaneRange =                                    CurrentCoordinate(1,3):CurrentCoordinate(1,4);

                        CurrentCoordinateList =                         arrayfun(@(x) [CurrentCoordinate(2), CurrentCoordinate(1), x], PlaneRange, 'UniformOutput',false);
                        MaskCoordinateList =                            vertcat(CurrentCoordinateList{:});

                        CollectionOfCoordinates_AfterPlanePooling{CurrentCellIndex,1} = MaskCoordinateList;

                end
        end
 
    end
    
      
end

