classdef PMInteractions
    %PMINTERACTIONS uses imported search and target shapes, drift correction, and set maximum distances to calculate;
    % getInteractionsMap is and important function; it allows calculation of the interactions map for the input;
    
    properties (Access = private)
        
        % source data:
        MovieName
        myFluShape_Metric
        myFluShape_Pixels
        MyTrackingAnalysis_Metric
        MyTrackingAnalysis_Pixels
        DriftCorrection
        
        % results
        ListWithInteractions
        
        % visualization
        Visualize = false;
        
    end
    
    properties (Access = private) % current state of loop; (to help retrieval of "current" data);
        
        FastTracking = false
        CurrentTrackIndex
        CurrentFrameIndex
        
    end
    
    properties (Access = private)  % limits:
        
        XYLimitForNeighborArea % for counting neighbor pixels in "close proximity":
        ZLimitForNeighborArea
       
    end
    
    properties (Access = private) % filemanagement
        
        ExportFolder
        
    end
    
    properties (Access = private) % VIEWS: for exporting detailed view of measurement process;
       
        ViewStructure
        
    end
    
    methods % initialization
        
         function obj = PMInteractions(varargin)
            %PMINTERACTIONS Construct an instance of this class
            %   takes 7 arguments:
            % 1: PMShape (flu metric)
            % 2: PMShape (flu pixels)
            % 3: PMTrackingAnalysis (metric)
            % 4: PMTrackingAnalysis (pixels)
            % 5: PMDriftCorrection
            % 6: numeric scalar: XYLimitForNeighborArea
            % 7: numeric scalar: ZLimitForNeighborArea
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 7
                    obj.myFluShape_Metric =             varargin{1};
                    obj.myFluShape_Pixels =             varargin{2};
                    obj.MyTrackingAnalysis_Metric =     varargin{3};
                    obj.MyTrackingAnalysis_Pixels =     varargin{4};
                    obj.DriftCorrection =               varargin{5};
                    obj.XYLimitForNeighborArea =        varargin{6};
                    obj.ZLimitForNeighborArea =         varargin{7};
 
                     
                otherwise
                    error('Wrong input.')
                
            end
            
         end
        
         function obj = set.myFluShape_Metric(obj, Value)
            assert(isa(Value, 'PMShape') && isscalar(Value), 'Wrong input.')
            obj.myFluShape_Metric = Value; 
         end
         
         function obj = set.myFluShape_Pixels(obj, Value)
             assert(isa(Value, 'PMShape') && isscalar(Value), 'Wrong input.')
            obj.myFluShape_Pixels = Value; 
         end
         
         function obj = set.MyTrackingAnalysis_Metric(obj, Value)
            assert(isa(Value, 'PMTrackingAnalysis') && isscalar(Value), 'Wrong input.')
            obj.MyTrackingAnalysis_Metric = Value; 
         end
         
         function obj = set.MyTrackingAnalysis_Pixels(obj, Value)
            assert(isa(Value, 'PMTrackingAnalysis') && isscalar(Value), 'Wrong input.')
            obj.MyTrackingAnalysis_Pixels = Value; 
         end
         
         function obj = set.DriftCorrection(obj, Value)
            assert(isa(Value, 'PMDriftCorrection') && isscalar(Value), 'Wrong input.')
            obj.DriftCorrection = Value; 
         end
         
         function obj = set.XYLimitForNeighborArea(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.XYLimitForNeighborArea = Value; 
         end
         
         function obj = set.ZLimitForNeighborArea(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.ZLimitForNeighborArea = Value; 
         end
        
         function obj = set.FastTracking(obj, Value)
             assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.FastTracking = Value; 
             
         end
      
         function obj = set.ExportFolder(obj, Value)
            assert(ischar(Value), 'Wrong input.')
             obj.ExportFolder = Value;
         end
        
    end
    
    methods % SETTERS
        
        function obj =      setExportFolder(obj, Value)
           obj.ExportFolder = Value; 
        end
        
        function obj =      setMovieName(obj, Value)
             obj.MovieName = Value; 
        end
        
    end
    
    methods % :
        
        function text = getSummary(obj)
           text = {sprintf('\n*** This PMInteractions object can measure distances between searchers and a target.\n')};
           text = [text; sprintf('Its main function is "getInteractionsMap", which returns a spreadsheet with the following columns:\n')];
            
        end
        
    end
    
    methods % ACTION
        
        
        function InteractionMapForAllTracks = getInteractionsMap(obj)
            %GETINTERACTIONSMAP main function of PMInteractions class
            % returns a cell array for each time frame, each cell has the
            % following content:
            % returns a list for each "searcher object" at each frame and gives distances and density to target relative to searcher;
            % returns matrix with the following columns;
            % column 1: track ID of searcher;
            % column 2: frame number of searcher;
            % column 3: shortest 3D distance to target;
            % column 4: number of "full target pixels" surrounding searcher;
            % column 5: shortest 2D distance to target;
            
            obj.FastTracking =                      true;
          
            obj.MyTrackingAnalysis_Metric =         obj.MyTrackingAnalysis_Metric.initializeTrackCell;
            obj.MyTrackingAnalysis_Pixels =         obj.MyTrackingAnalysis_Pixels.initializeTrackCell;
            
            InteractionMapForAllTracks =            cell(obj.MyTrackingAnalysis_Metric.getNumberOfTracks, 1);
             for TrackIndex = 1 : obj.MyTrackingAnalysis_Metric.getNumberOfTracks
                 obj.CurrentTrackIndex =                                    TrackIndex;
                 InteractionMapForAllTracks{obj.CurrentTrackIndex,1} =      obj.getInteractionMapFromAllFrames;

             end
             
             
        end
      
    end
    
    methods (Static)
       
        function InteractionMapForAllTracks = loadInteractionsMapFromFile( FileName)
           InteractionMapForAllTracks =  load(FileName);
           InteractionMapForAllTracks = InteractionMapForAllTracks.InteractionObject;
           assert(iscell(InteractionMapForAllTracks) && isvector(InteractionMapForAllTracks), 'Interactions map has invalid format.')
           
           cellfun(@(x) PMInteractions.checkIntactnessOfInteractionMap(x), InteractionMapForAllTracks)
            
        end
        
        function checkIntactnessOfInteractionMap(Map)
            assert(iscell(Map) && ismatrix(Map),  'Interactions map has invalid format.')
            assert(size(Map, 2) == 5, 'Interactions map has invalid format.')
            assert(min(min(cellfun(@(x) isnumeric(x), Map))), 'Interactions map has invalid format.')
        end
        
        function isValidInteractionType(Type)
            
            types{1, 1} = 'FractionFullPixels';
            types{2, 1} = '3D';
            types{3, 1} = '2D';
            
            value = max(strcmp(Type, types));
            assert(value, 'Invalid interaction type.')
             
        end
        
        
        
    end
    
    methods % EXPORT
       
        function obj = exportDetailedInteractionInfoForTrackIDs(obj, TrackIDs)
            % EXPORTDETAILEDINTERACTIONINFOFORTRACKIDS exports images into file that show precisely how distances are measured;
            % does not create "actual numerical data" used for quantitative figures, this is done by "getInteractionMapFromAllFrames";
           assert(isnumeric(TrackIDs) && isvector(TrackIDs), 'Wrong input')
           
            if ~isempty(obj.ExportFolder)
                obj = obj.initializeView;
            end
           
            obj.MyTrackingAnalysis_Metric =     obj.MyTrackingAnalysis_Metric.initializeTrackCell;
            obj.MyTrackingAnalysis_Pixels =     obj.MyTrackingAnalysis_Pixels.initializeTrackCell;

            for index = 1 : length(TrackIDs)
                
                 obj.CurrentTrackIndex =         obj.MyTrackingAnalysis_Metric.getIndexInTrackCellForID(TrackIDs(index));
                 
                 for FrameIndex = 1 : obj.MyTrackingAnalysis_Metric.getNumberOfFramesForTrackIndex(obj.CurrentTrackIndex) 
                        
                    obj.CurrentFrameIndex =         FrameIndex;
                    [~, InteractionObject] =       obj.getActiveInteractionMap;

                    figure( obj.ViewStructure.FigureHandle)
                    obj=                            obj.fillFigureWithInformation(InteractionObject);
                    obj =                           obj.saveImage;

                    close(obj.ViewStructure.FigureHandle)

                 end
                                
            end

        end
        
    end
    
    
   methods (Access = private) % GETTERS interaction map
       
        function [InteractionMap_CurrentTrack] =                getInteractionMapFromAllFrames(obj)
            % GETINTERACTIONMAPFROMALLFRAMES returns cell array with interaction maps for each frame;
            
             fprintf('PMInteractions is processing track %i of %i.\n', obj.CurrentTrackIndex, obj.MyTrackingAnalysis_Metric.getNumberOfTracks)
             InteractionMap_CurrentTrack =            cell(obj.MyTrackingAnalysis_Metric.getNumberOfFramesForTrackIndex(obj.CurrentTrackIndex) - 2 , 5);
                 for FrameIndex = 1 : obj.MyTrackingAnalysis_Metric.getNumberOfFramesForTrackIndex(obj.CurrentTrackIndex) 
                        
                        obj.CurrentFrameIndex =                                     FrameIndex;
                        [MapOfCurrentFrame, ~] =                                    obj.getActiveInteractionMap;
                        %  fprintf('Frame %i: Overlap = %5.4f\n', FrameIndex, MapOfCurrentFrame{4})
                        InteractionMap_CurrentTrack(obj.CurrentFrameIndex, :) =     MapOfCurrentFrame;
                        

                 end
                 
                Empty =                                            cellfun(@(x) isempty(x), InteractionMap_CurrentTrack(:, 1));
                InteractionMap_CurrentTrack(Empty, :) =            [];

            
        end
        
        function [InteractionsOfTrack, myInteractionObject] =   getActiveInteractionMap(obj)
            % GETACTIVEINTERACTIONMAP returns interaction data of active track and active frame ;
            % takes 0 arguments
            % 1 or 2 returns:
            % 1: cell array with 5 elements:
            %      1: trackID
            %      2: frame number
            %      3: optional: 3D distance to closest target 
            %      4: fraction of pixels around 
            %      5: optional: 2D distance to closest target
            % 2: PMInteraction scalar of active track and frame;
            
            InteractionsOfTrack{1, 1} =                 obj.getTrackIDOfActiveSearcher;
            InteractionsOfTrack{1, 2} =                 obj.getFrameNumberOfActiveSearcher;
            InteractionsOfTrack{1, 4} =                 obj.getFractionOfPositiveTargetVolume;

            if   obj.FastTracking
                myInteractionObject = '';
                InteractionsOfTrack{1, 3} =             NaN;
                InteractionsOfTrack{1, 5} =             NaN;

            else
                myInteractionObject =                   obj.getActiveInteractionObject;
                InteractionsOfTrack{1, 3} =             myInteractionObject.getDistanceToClosestTarget;
                InteractionsOfTrack{1, 5} =             myInteractionObject.getDistanceToClosestTarget('2D');
                
            end

               
               
        end
        
    end
    
   methods (Access = private) % GETTERS:
        
         function number =                   getNumberOfTracks(obj)
           number = size(obj.ListWithInteractions, 1);
        end
         
    end
    
   methods (Access = private) % interaction map:
        
        function myInteractionObject =      getActiveInteractionObject(obj)
            CellCoordinates =                           obj.getCoordinatesOfActiveSearcher;
            MetricCoordinatesOfTarget(:, 2 : 4) =       obj.myFluShape_Metric.getCoordinatesInSquareAroundCenter(...
                                                            CellCoordinates(1, 2:4),  ...
                                                            obj.XYLimitForNeighborArea...
                                                            );
            myInteractionObject =                       PMInteraction(CellCoordinates, MetricCoordinatesOfTarget);
            
        end
        
        function ID =                       getTrackIDOfActiveSearcher(obj)
            ID = obj.MyTrackingAnalysis_Metric.getTrackIDForTrackIndex(obj.CurrentTrackIndex);
        end
        
        function FrameNumber =              getFrameNumberOfActiveSearcher(obj)
            FrameNumber = obj.MyTrackingAnalysis_Pixels.getFrameNumberForTrackIndexFrameIndex(obj.CurrentTrackIndex, obj.CurrentFrameIndex);
        end
        
        
    end
    
   methods (Access = private) % GETTERS: getFractionOfPositiveTargetVolume;
        
        function FractionPositive =         getFractionOfPositiveTargetVolume(obj)
            
                CellCoordinates =                               obj.getCoordinatesOfActiveSearcher;
                MyFluShape =                                obj.myFluShape_Metric;
                ListOfCoordinatesInVolume =                     MyFluShape.getCoordinatesInCuboidAroundCenterSize(...
                    CellCoordinates(1, 2:4), ...
                    obj.XYLimitForNeighborArea, ...
                    obj.XYLimitForNeighborArea, ...
                    obj.ZLimitForNeighborArea, ...
                    'ClosestZPlusLimits');
  
                NumberOfNeighborTargetCoordinates =         size(ListOfCoordinatesInVolume, 1); 
                
                if isempty(obj.myFluShape_Metric.getPixelSize)
                    MyPixelSize = 1;
                else
                    MyPixelSize = obj.myFluShape_Metric.getPixelSize;
                    
                end
                Max =                                       (length(0:  MyPixelSize : obj.XYLimitForNeighborArea * 2 ))^2;
                
                FractionPositive =          NumberOfNeighborTargetCoordinates / Max;
          end
      
        function CellCoordinates_End =      getCoordinatesOfActiveSearcher(obj)
            CellCoordinates_End = obj.getCoordinatesForTrackindexFrameReferenceframe(...
                                                obj.CurrentTrackIndex, ...
                                                obj.CurrentFrameIndex, ...
                                                obj.CurrentFrameIndex);
            
        end
       
        function CellCoordinates_End =      getCoordinatesForTrackindexFrameReferenceframe(obj, TrackIndex, FrameIndex, ReferenceFrameIndex)
             
            CellCoordinates_End =             obj.MyTrackingAnalysis_Metric.getTimeSpaceCoordinatesForTrackIndexFrameIndices(TrackIndex, FrameIndex);
             
             if FrameIndex == ReferenceFrameIndex
             else
                CellCoordinates_End(1, 2:4) =     obj.DriftCorrection.shiftCoordinatesInFrameRelativeToFrame(CellCoordinates_End(1, 2:4),  FrameIndex, ReferenceFrameIndex);
             end
        end
        
    end
    
   methods (Access = private) % ACTION initializeView (for export of thresholded images into file);

        function obj= initializeView(obj)

            obj.ViewStructure.FigureHandle = figure;

            obj.ViewStructure.ImageAxes = subplot(1, 1, 1);
            obj.ViewStructure.ImageAxes.Position = [0.1300 0.1100 0.7750 0.7];
            obj.ViewStructure.ImageAxes.YDir = 'reverse';

            obj.ViewStructure.Image = image;


            obj.ViewStructure.LineForSearcherPosition =         line;  
            obj.ViewStructure.LineForClosestTargetPosition =    line;  
            obj.ViewStructure.LineFromSearcherToTarget =        line;  

            obj.ViewStructure.LineForNeighborRectangle =         line;  
       
            obj.ViewStructure.MainAxes = axes;
            obj.ViewStructure.MainAxes.Visible = 'off';
            obj.ViewStructure.MainAxes.Position = [0 0 1 1];

            obj.ViewStructure.textTrackNumber = text();
            obj.ViewStructure.textTrackNumber.String = 'Track id = ';
            obj.ViewStructure.textTrackNumber.FontSize = 18;
            obj.ViewStructure.textTrackNumber.Color = 'k';
            obj.ViewStructure.textTrackNumber.HorizontalAlignment = 'left';
            obj.ViewStructure.textTrackNumber.Position = [0.1 0.95 0 ];

            obj.ViewStructure.textFrameNumber = text();
            obj.ViewStructure.textFrameNumber.String = 'Track id = ';
            obj.ViewStructure.textFrameNumber.FontSize = 18;
            obj.ViewStructure.textFrameNumber.Color = 'k';
            obj.ViewStructure.textFrameNumber.HorizontalAlignment = 'left';
            obj.ViewStructure.textFrameNumber.Position = [0.5 0.95 0 ];
            
            obj.ViewStructure.textTrackFullness = text();
            obj.ViewStructure.textTrackFullness.String = 'Full = ';
            obj.ViewStructure.textTrackFullness.FontSize = 18;
            obj.ViewStructure.textTrackFullness.Color = 'k';
            obj.ViewStructure.textTrackFullness.HorizontalAlignment = 'left';
            obj.ViewStructure.textTrackFullness.Position = [0.1 0.9 0 ];
            
            obj.ViewStructure.textTrackDistance = text();
            obj.ViewStructure.textTrackDistance.String = 'Distance = ';
            obj.ViewStructure.textTrackDistance.FontSize = 18;
            obj.ViewStructure.textTrackDistance.Color = 'k';
            obj.ViewStructure.textTrackDistance.HorizontalAlignment = 'left';
            obj.ViewStructure.textTrackDistance.Position = [0.5 0.9 0 ];
            
        end

   end
   
   methods (Access = private) % ACTION exportDetailedInteractionInfoForTrackIDs
       
        function obj=               fillFigureWithInformation(obj, InteractionObject)

            CoordinatesOfSearcher =             InteractionObject.getCoordinatesOfSearcher;
            [~, CoordinatesOfTarget] =     InteractionObject.getDistanceToClosestTarget('2D');

            
           
            
            obj.ViewStructure.Image.CData =                                 obj.getDetailedTrackImage(InteractionObject);
            obj.ViewStructure.ImageAxes.XLim =                              [obj.getStartPositionX(InteractionObject), obj.getEndPositionX(InteractionObject)];
            obj.ViewStructure.ImageAxes.YLim =                              [obj.getStartPositionY(InteractionObject), obj.getEndPositionY(InteractionObject)];

            obj.ViewStructure.LineForSearcherPosition.XData =               CoordinatesOfSearcher(1, 2);
            obj.ViewStructure.LineForSearcherPosition.YData =               CoordinatesOfSearcher(1, 3);
            obj.ViewStructure.LineForSearcherPosition.Marker =              'x';
            obj.ViewStructure.LineForSearcherPosition.Color =               'b';
            obj.ViewStructure.LineForSearcherPosition.MarkerSize =          20;
            obj.ViewStructure.LineForSearcherPosition.LineWidth =           3;

            
            obj.ViewStructure.LineForClosestTargetPosition.XData =          CoordinatesOfTarget(1, 2);
            obj.ViewStructure.LineForClosestTargetPosition.YData =          CoordinatesOfTarget(1, 3);
            obj.ViewStructure.LineForClosestTargetPosition.Marker =         'o';
            obj.ViewStructure.LineForClosestTargetPosition.Color =          'b';
            obj.ViewStructure.LineForClosestTargetPosition.MarkerSize =     20;
            obj.ViewStructure.LineForClosestTargetPosition.LineWidth =      3;


            obj.ViewStructure.LineFromSearcherToTarget.XData =              [ CoordinatesOfSearcher(1, 2), CoordinatesOfTarget(1, 2)];
            obj.ViewStructure.LineFromSearcherToTarget.YData =              [CoordinatesOfSearcher(1, 3), CoordinatesOfTarget(1, 3)];
            obj.ViewStructure.LineFromSearcherToTarget.Marker =            'none';
            obj.ViewStructure.LineFromSearcherToTarget.Color =             'b';
            obj.ViewStructure.LineFromSearcherToTarget.LineWidth =         1;

            obj.ViewStructure.LineForNeighborRectangle.XData =              [ CoordinatesOfSearcher(1, 2) - obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 2) + obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 2) + obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 2) - obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 2) - obj.XYLimitForNeighborArea];
            obj.ViewStructure.LineForNeighborRectangle.YData =              [CoordinatesOfSearcher(1, 3) + obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 3) + obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 3) - obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 3) - obj.XYLimitForNeighborArea, CoordinatesOfSearcher(1, 3) + obj.XYLimitForNeighborArea];
            obj.ViewStructure.LineForNeighborRectangle.Marker =            'none';
            obj.ViewStructure.LineForNeighborRectangle.Color =              'b';
            obj.ViewStructure.LineForNeighborRectangle.LineWidth =          1;

            obj.ViewStructure.textTrackNumber.String =                      ['ID= ', num2str(obj.getTrackIDOfActiveSearcher)];
            obj.ViewStructure.textFrameNumber.String =                      ['Frame = ', num2str(obj.getFrameNumberOfActiveSearcher)];
            obj.ViewStructure.textTrackFullness.String =                    sprintf('Fullness = %4.3f', obj.getFractionOfPositiveTargetVolume);
            obj.ViewStructure.textTrackDistance.String =                    ['Distance= ', num2str(InteractionObject.getDistanceToClosestTarget('2D')), ' µm'];

       
            
        end
     
        function FluPixelImage =    getDetailedTrackImage(obj, InteractionObject)
             SearcherCoordinates =               InteractionObject.getCoordinatesOfSearcher;

            TargetCoordinateListInRange =           obj.myFluShape_Metric.getCoordinatesInCuboidAroundCenterSize(...
                                                            SearcherCoordinates(2:4),  ...
                                                            obj.XYLimitForNeighborArea, ...
                                                            obj.XYLimitForNeighborArea,  ...
                                                            obj.ZLimitForNeighborArea, ...
                                                            'ClosestZPlusLimits'...
                                                            );
            
             UniquePlanes =                     unique(TargetCoordinateListInRange(:,  3));
               
             rows =                             arrayfun(@(x) TargetCoordinateListInRange(:, 3) == x, UniquePlanes, 'UniformOutput', false);
            CoordinatesPerPlane =               cellfun(@(x) TargetCoordinateListInRange(x, :), rows, 'UniformOutput', false);
            Images =                            cellfun(@(x) PMShape(x).getMaximumProjection,    CoordinatesPerPlane, 'UniformOutput', false);
           
            
            Images{1}(obj.getEndPositionY(InteractionObject), obj.getEndPositionX(InteractionObject)) =              0;
            Images{2}(obj.getEndPositionY(InteractionObject), obj.getEndPositionX(InteractionObject)) =              0;
            Images{3}(obj.getEndPositionY(InteractionObject), obj.getEndPositionX(InteractionObject)) =              0;
            
            FluPixelImage =                       uint8(0);
            FluPixelImage(size(Images{1}, 1), size(Images{1}, 2),3) = 0;
            for index = 1 : length(Images)
                FluPixelImage(:,:, index) = Images{index};
            end
            
        end
        
        function XStart =           getStartPositionX(obj, InteractionObject)
            SearcherCoordinates =       InteractionObject.getCoordinatesOfSearcher;
            XStart =                    SearcherCoordinates (2) - obj.XYLimitForNeighborArea;
        end
        
        function XEnd =             getEndPositionX(obj, InteractionObject)
            SearcherCoordinates =       InteractionObject.getCoordinatesOfSearcher;
            XEnd =                      SearcherCoordinates (2) + obj.XYLimitForNeighborArea - 1;
        end
        
        function YStart =           getStartPositionY(obj, InteractionObject)
            SearcherCoordinates =       InteractionObject.getCoordinatesOfSearcher;
            YStart =                    SearcherCoordinates (3) - obj.XYLimitForNeighborArea;
        end
        
        function YEnd =             getEndPositionY(obj, InteractionObject)
            SearcherCoordinates =       InteractionObject.getCoordinatesOfSearcher;
            YEnd =                      SearcherCoordinates (3) + obj.XYLimitForNeighborArea - 1;
        end
        
        function obj =              saveImage(obj)
            
            folderName = [obj.ExportFolder, '/Movie_', obj.MovieName, '/Track_', num2str(obj.getTrackIDOfActiveSearcher)];
            if exist(folderName) ~=7
                mkdir(folderName)
            end
            
            fileName =      [folderName, '/Frame_',  num2str(obj.getFrameNumberOfActiveSearcher), '_', PMTime().getCurrentTimeString, '.jpg'];
            Image =         frame2im(getframe(obj.ViewStructure.MainAxes));

            imwrite(Image, fileName)
          
            
        end

       
   end
   

   methods (Access = private) % still in use?
        
        function results =              getData(obj, varargin)
        NumberOfArguments = length(varargin);
        switch NumberOfArguments

        case 1
        results = obj.getDataWithMethod(varargin{1});
        case 2
        if strcmp(varargin{2}, 'poolAllData')
            results = obj.getDataWithMethod(varargin{1});
            results = vertcat(results{:});
        end
        otherwise 
        error('Wrong input.')

        end


        end

        function obj =                  initialize(obj)

        if obj.Visualize
        [ViewStructure] =                 obj.initializeViews(obj.myFluShape_Pixels.getImageVolume);
        end

        obj.MyTrackingAnalysis_Metric =     obj.MyTrackingAnalysis_Metric.initializeTrackCell;
        obj.MyTrackingAnalysis_Pixels =     obj.MyTrackingAnalysis_Pixels.initializeTrackCell;

        ListWithAllInteractionsOfMovie =    cell(obj.MyTrackingAnalysis_Metric.getNumberOfTracks, 1);
        for TrackIndex = 1 : obj.MyTrackingAnalysis_Metric.getNumberOfTracks
        TrackIndex

        InteractionsOfTrack =            cell(obj.MyTrackingAnalysis_Metric.getNumberOfFramesForTrackIndex(TrackIndex) - 2 , 0);
        for FrameIndex = 1 : obj.MyTrackingAnalysis_Metric.getNumberOfFramesForTrackIndex(TrackIndex) - 2

         CellCoordinates =         obj.getCellCoordinatesForTrackindexFrame(TrackIndex, FrameIndex);

         if CellCoordinates(1,4) < obj.ZLimitForNeighborArea
             TargetCoordinates =       obj.getTargetCoordinatesForCellCoordinates(CellCoordinates);
             Eccentricities =          obj.getEccentricitiesForTrackindexFrame(TrackIndex, FrameIndex);
             TrackID =                  obj.MyTrackingAnalysis_Metric.getTrackIDForTrackIndex(TrackIndex);


             NeighboringFluCoordinates =                  obj.myFluShape_Metric.getCoordinatesInCuboidAroundCenterSize(CellCoordinates(1, 2:4), obj.XYLimitForNeighborArea, obj.XYLimitForNeighborArea, obj.ZLimitForNeighborArea);
             NumberOfNeighborTargetCoordinates = size(NeighboringFluCoordinates, 1);
             InteractionsOfTrack{FrameIndex, 1} =     obj.getInteractionObjectFor(...
                                                        CellCoordinates, ...
                                                        TargetCoordinates, ...
                                                        TrackID, ...
                                                        Eccentricities, ...
                                                        NumberOfNeighborTargetCoordinates);

            obj =                        obj.updateViewsForTrackindexFrame(TrackIndex, FrameIndex);

         end


        end

        Empty = cellfun(@(x) isempty(x), InteractionsOfTrack);
        InteractionsOfTrack(Empty, :) = [];
        ListWithAllInteractionsOfMovie{TrackIndex,1} =                               InteractionsOfTrack;

        end

        obj.ListWithInteractions =              ListWithAllInteractionsOfMovie;


        end

        function interactionObject =    getInteractionObjectFor(~, CellCoordinates, TargetCoordinates, TrackID, Eccentricities, Number)
        interactionObject =       PMInteraction(CellCoordinates, TargetCoordinates);
        interactionObject=        interactionObject.setProperties;
        interactionObject =       interactionObject.setTrackID(TrackID);
        interactionObject =       interactionObject.setSearcherEccentricities(Eccentricities);
        interactionObject =       interactionObject.setNumberOfNeighborPixels(Number);

        interactionObject =       interactionObject.minimizeSize;
        end

        function coordinates =          getCellCoordinatesForTrackindexFrame(obj, TrackIndex, ReferenceFrameIndex)
        CellCoordinates_Start =         obj.getCoordinatesForTrackindexFrameReferenceframe(TrackIndex, ReferenceFrameIndex, ReferenceFrameIndex);
        CellCoordinates_Middle =        obj.getCoordinatesForTrackindexFrameReferenceframe(TrackIndex, ReferenceFrameIndex + 1, ReferenceFrameIndex);
        CellCoordinates_End =           obj.getCoordinatesForTrackindexFrameReferenceframe(TrackIndex, ReferenceFrameIndex + 2, ReferenceFrameIndex);
        coordinates =      [ CellCoordinates_Start; CellCoordinates_Middle; CellCoordinates_End];

        end

        function targetCoordinates =    getTargetCoordinatesForCellCoordinates(obj, CellTimeSpaceCoordinates)

        FluReduced_Space_MetricNoDrift =               obj.myFluShape_Metric.getCoordinatesInSquareAroundCenter(CellTimeSpaceCoordinates(1, 2:4),  obj.XYLimitForNeighborArea);
        targetCoordinates =           FluReduced_Space_MetricNoDrift;
        targetCoordinates(:, 2:4) =   FluReduced_Space_MetricNoDrift;
        targetCoordinates(:, 1) =     CellTimeSpaceCoordinates(2, 1);


        end

        function Eccentricities =       getEccentricitiesForTrackindexFrame(obj, TrackIndex, ReferenceFrameIndex)
        MaskPixels =             arrayfun(@(x)   obj.MyTrackingAnalysis_Metric.getMaskPixelsForTrackIndexFrameIndex(TrackIndex, x), [ReferenceFrameIndex ; ReferenceFrameIndex + 1; ReferenceFrameIndex + 2], 'UniformOutput', false);
        Eccentricities =         cellfun(@(x)        PMShape(x).getEccentricity, MaskPixels);

        end

        function obj =                  minimizeSize(obj)

        obj.MyTrackingAnalysis_Pixels =     PMTrackingAnalysis();
        obj.myFluShape_Metric =             PMShape();
        obj.myFluShape_Pixels =             PMShape();
        obj.MyTrackingAnalysis_Metric  =    PMTrackingAnalysis();
        obj.DriftCorrection =               PMDriftCorrection();


        end

        function data =                 getDataWithMethod(obj, MethodName)
        data = cell(obj.getNumberOfTracks, 1);
        for trackIndex = 1: obj.getNumberOfTracks
        data{trackIndex, 1} =   cellfun(@(x) x.(MethodName),  obj.ListWithInteractions{trackIndex}, 'UniformOutput', false);
        end   
        end

        function Time =                 getTimeOfActiveSearcher(obj)
        Time = obj.MyTrackingAnalysis_Metric.getFrameNumberForTrackIndexFrameIndex(obj.CurrentTrackIndex, obj.CurrentFrameIndex); 
        end

        function obj =                  updateViewsForTrackindexFrame(obj, TrackIndex, ReferenceFrameIndex)
        if obj.Visualize

                ClosestDistance = myInteractionObject.getDistanceToClosestTarget;
                obj.updateViews(ViewStructure, ...
                    obj.myFluShape_Pixels.getImageVolume, ...
                    obj.MyTrackingAnalysis_Pixels.getTimeSpaceCoordinatesForTrackIndexFrameIndices(TrackIndex, ReferenceFrameIndex), ...
                    obj.MyTrackingAnalysis_Metric.getTrackIDForTrackIndex(TrackIndex), ...
                    ClosestDistance(1)) 
        end

        end

  
    end
    
end

