classdef PMInteraction
    %PMINTERACTION Performs distance quantifications of contacts between searchers and targets;
    %   Is used by PMInteractions is a helper class
    
    properties (Access = private)
        SearcherPositions
        TargetPositions
        MaximumDistance =       25; % this is just rudimntarily here; should be set PMInteractions;
        
    end
    
    properties (Access = private) % set by user, currently not in use, remove?;
       SearcherEccentricities 
       NumberOfNeighbors
       
    end
    
    properties (Access = private) % caclulated by object, stored for convenience;
        ClosestTargetPositions
        ClosestTargetPositions_TwoD
        PlaneClosestToCellCenter
  
    end
    
    methods % INITIALIZATION
        
        function obj = PMInteraction(varargin)
            %PMINTERACTION Construct an instance of this class
            %   takes 2 arguments:
            % 1: searcher positions: matrix with 4 columns
            % 2: target positions: matrix with 4 columns
            NumberOfArguments = length(varargin);
            switch NumberOfArguments                    
                case 2
                    obj.SearcherPositions = varargin{1};
                    obj.TargetPositions =   varargin{2};
                otherwise
                    error('Wrong input.')
            end
            
            obj = obj.setPlaneClosestToSearcher;
            obj = obj.setClosestTargetPosition;
            obj = obj.setClosestTargetPosition_TwoD;
        end
  
        function obj = set.SearcherPositions(obj, Value)
            assert(isnumeric(Value) && ismatrix(Value) && size(Value, 2) == 4, 'Wrong input.')
            obj.SearcherPositions = round(Value); % some of the data can be discrete, therefore non-rounded decimal numbers can lead to weird results;
        end
        
        function obj = set.TargetPositions(obj, Value)
            assert(isnumeric(Value) && ismatrix(Value) && size(Value, 2) == 4, 'Wrong input.')
            obj.TargetPositions = round(Value); % some of the data can be discrete, therefore non-rounded decimal numbers can lead to weird results;
        end
        
        function obj = set.ClosestTargetPositions(obj, Value)
            assert(isnumeric(Value) && size(Value, 2) == 4, 'Wrong input.')
            obj.ClosestTargetPositions = Value;
            
        end
               
        
    end
    
    methods % SUMMARY 
        
        function obj =          showSummary(obj)
             cellfun(@(x) fprintf('%s\n', x),   obj.getSummary);

        end
        
        function summary =      getSummary(obj)
            summary = {sprintf('This PMInteraction object measures the shortest distance between a searcher and its target.')};
            summary = [summary; sprintf('For 3D the distance measurement is straighforward.')];
            summary = [summary; sprintf('For 2D measurements, first the "matching plane" of the target is selected (e.g. plane 2 when centroid searcher is 2.1) and then the shortest distance is measured.')];
            
        end
            
    end
    
    methods % SETTERS
       
        function obj = minimizeSize(obj)
          obj.TargetPositions = zeros(0, 4);
      end
        
        
    end
    
    methods % GETTERS: BASIC
        
        function positions =        getCoordinatesOfSearcher(obj)
            positions = obj.SearcherPositions;
        end
        
        function positions =        getClosestTargetPosition(obj)
            positions = obj.ClosestTargetPositions;
        end
        
        function positions =        getClosestTargetPosition_2D(obj)
            positions = obj.ClosestTargetPositions_TwoD;
        end

        function imageOut =         getImageOf2DTarget(obj)
            image =         obj.getTargetCoordinatesInPlaneCloseToSearcher;
            targetShape =   PMShape(image(:, 2 : 4));
            imageOut =      targetShape.getImageVolume('MaximumProjection');
        end
        
    end
    
    methods % GETTERS: MAIN
        
        function [distance, position] =     getDistanceToClosestTarget(obj, varargin)
            %GETDISTANCETOCLOSESTTARGET gets shortest distance between searcher and target;
            % takes 0, or 1 arguments
            % 1: character string: '3D', or '2D'; default: '3D'
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    [distance, position] = obj.getClosestDistancesToTarget_ThreeD;
                case 1
                    assert(ischar(varargin{1}), 'Wrong input.')
                    switch varargin{1}
                        case '3D'
                            [distance, position] = obj.getClosestDistancesToTarget_ThreeD;
                        case '2D'
                            [distance, position] = obj.getClosestDistancesToTarget_TwoD;
                    end
                    
                otherwise
                    error('Wrong input.')
                    
            end
  
        end

        function netMovement =              getNetMovementTowardsTarget(obj)
            %GETNETMOVEMENTTOWARDSTARGET takes first and last position of searcher and calculates movement towards or away from target;
            % positive value: searcher moves away from target;
            
            if isempty(obj.TargetPositions)
                netMovement =           NaN;
            else
                myTargetPositions =     obj.ClosestTargetPositions;
                trackingSpeedFirst =    PMTrackingSpeed([obj.SearcherPositions(1, :); myTargetPositions(1, :)]);
                trackingSpeedLast =     PMTrackingSpeed([obj.SearcherPositions(end, :); myTargetPositions(1, :)]);
                netMovement =           trackingSpeedLast.getDistanceOfTrack  - trackingSpeedFirst.getDistanceOfTrack;
            end 
        end


    end
    
    methods (Access = private) % get closest distance
       
        function [closestDistances, closestTargetPosition] = getClosestDistancesToTarget_ThreeD(obj)
              closestTargetPosition =   obj.ClosestTargetPositions(1, :);
            closestDistances =          obj.calculateDistanceBetweenTwoCoordinates(round(obj.SearcherPositions(1, 2:4)), obj.ClosestTargetPositions(1, 2 : 4));
            if isnan(closestDistances)
               closestDistances = obj.MaximumDistance;
            end

        end

        function [closestDistances, closestTargetPosition] = getClosestDistancesToTarget_TwoD(obj)
             closestTargetPosition =     obj.ClosestTargetPositions_TwoD(1, :);
            closestDistances =          obj.calculateDistanceBetweenTwoCoordinates(round([obj.SearcherPositions(1, 2:3), 1]), [closestTargetPosition(1, 2 : 3), 1]);
            if isnan(closestDistances)
             closestDistances = obj.MaximumDistance; 
            end

        end

        function [distanceBetweenCells] = calculateDistanceBetweenTwoCoordinates(obj, First,Second)
            distances =                 Second - First;
            distanceBetweenCells =      sqrt(distances(1)^2 + distances(2)^2 + distances(3)^2);
        end

    end
    
    methods (Access = private) % SETTERS: CLOSEST POSITION
        
        function obj =      setClosestTargetPosition(obj)
          if isempty(obj.TargetPositions)
              obj.ClosestTargetPositions =          [NaN, NaN, NaN, NaN];  

          else
             obj.ClosestTargetPositions(1, :) =    obj.getClosestTargetPositionForSearcherTarget( obj.TargetPositions) ;

          end
        end

        function ClosestTargetPosition = getClosestTargetPositionForSearcherTarget(obj, MySelectedTargetPositions, varargin)
            MySearcherPositions =      obj.SearcherPositions(1, 2:4); 
            MyTargetPositions =        MySelectedTargetPositions(:, 2 : 4);

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0

                case 1
                    assert(ischar(varargin{1}), 'Wrong input.')

                    switch varargin{1}

                        case '2D'
                            MySearcherPositions(:, 3) = 0;
                            MyTargetPositions(:, 3) =   0;
                        otherwise
                            error('Wrong input.')

                    end

                otherwise
                    error('Wrong input.')

            end

            [~, ListWithAllDistances] =          dsearchn(MySearcherPositions, MyTargetPositions);
            [~, rowWithSmallestDistance] =       min(ListWithAllDistances);
            ClosestTargetPosition =              [0, MyTargetPositions(rowWithSmallestDistance, :)];

        end

        function obj =      setClosestTargetPosition_TwoD(obj)

              if isempty(obj.TargetPositions)
                  obj.ClosestTargetPositions_TwoD =         [NaN, NaN, NaN];                   
              else
                  TargetCoordinatesInRightPlane =           obj.getTargetCoordinatesInPlaneCloseToSearcher;
                  obj.ClosestTargetPositions_TwoD(1, :) =   obj.getClosestTargetPositionForSearcherTarget(TargetCoordinatesInRightPlane, '2D');
              end

        end

        function TargetPositionsInRightPlane = getTargetCoordinatesInPlaneCloseToSearcher(obj)
            TargetPositionsInRightPlane =    obj.TargetPositions;
            TargetPositionsInRightPlane(TargetPositionsInRightPlane(:, 4) ~= obj.PlaneClosestToCellCenter, :) = [];
        end

        function obj =      setPlaneClosestToSearcher(obj)
            MyTargetZs =                    obj.TargetPositions(:, 4);
            [~,closestIndex] =              min(abs(obj.SearcherPositions(1, 4) - MyTargetZs));
            obj.PlaneClosestToCellCenter =  MyTargetZs(closestIndex);
        end

    end
    
    methods (Access = private) % GETTERS: needed?
        
        function number = getNumberOfSearcherPositions(obj)
            number = size(obj.SearcherPositions, 1);
        end

        function number = getNumberOfNeighborPixels(obj)
            number = obj.NumberOfNeighbors;
        end

        function obj = setNumberOfNeighborPixels(obj, Value)
            obj.NumberOfNeighbors = Value;
        end

        function speed = getSpeeds(obj)
            speed = PMTrackingSpeed(obj.SearcherPositions).getInstantSpeeds;
        end

        function speed = getMeanSpeed(obj)
            speed = PMTrackingSpeed(obj.SearcherPositions).getMeanSpeed;
        end

        function turningAngle = getTurningAngle(obj)
            turningAngle = PMTrackingTurningAngles(obj.SearcherPositions).getResult;
        end

        function obj = setSearcherEccentricities(obj, Eccentricities)
            obj.SearcherEccentricities = Eccentricities;
        end
           
    end
end

