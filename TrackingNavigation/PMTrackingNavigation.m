classdef PMTrackingNavigation
    %PMTRACKINGNAVIGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        
        ActiveTrackID  =                                                NaN;
        SelectedTrackIDs =                                              zeros(0,1);
        ActiveFrame =                                                   NaN;
        
        FieldNamesForTrackingCell =                                     {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        TrackingCellForTime =                                           cell(0,1);
        TrackingCellForTimeWithDrift =                                  cell(0,1);
        
        MaximumDistanceForTracking =                                    50;
        
        FieldNamesForTrackingInfo =                                     {''};
        TrackingInfoCellForTime=                                        cell(0,1);
        
        OldCellMaskStructure
        
        ColumnsInTrackingCell
        Tracking
        TrackingWithDriftCorrection
        
        %% auto cell recognition:
        AutomatedCellRecognition
        
        
    end
    
    properties (Access = private) % for connecting tracks
       
        %% presets for auto tracking::
        FirstPassDeletionFrameNumber =                                  3;
        
        AutoTrackingConnectionGaps =                                    [-1 0 -2 1  -3 ]; 
        
        MaximumAcceptedDistanceForAutoTracking =                        30;
        DistanceLimitXYForTrackMerging =                                30;
        DistanceLimitZForTrackingMerging =                              2; % all tracks that show some overlap are accepted; positive values extend overlap
        ShowDetailedMergeInformation =                                  false

        %% other settings
        AutoTrackingActiveGap = 0;
        
        TrackingAnalysis
        TrackInfoList =                                                 cell(0,1)

    end
    
    methods
        
        
        function obj = PMTrackingNavigation(varargin)
            %PMTRACKINGNAVIGATION Construct an instance of this class
            %   Detailed explanation goes here
            
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                case 1
                    obj.TrackingCellForTime =   varargin{1};
                case 2
                    
                        Data = varargin{1};
                        Version = varargin{2};
                        switch Version
                        case 2
                            if ~isempty(fieldnames(Data))
                                obj.OldCellMaskStructure = Data;
                                if isfield(Data, 'Segmentation')
                                    if ~isempty(Data.Segmentation)
                                        obj.OldCellMaskStructure =      Data.Segmentation; 
                                        obj =      obj.convertOldCellMaskStructureIntoTrackingCellForTime;
                                    end 
                                end
                            end  
                        end       
                
            end
            
            
            
        end
        
        %% accessor autotracking:
        function obj = setAutomatedCellRecognition(obj, Value)
           obj.AutomatedCellRecognition = Value; 
        end
        
        function obj = setTrackingAnalysis(obj, Value)
           obj.TrackingAnalysis = Value;
            
        end
        function [obj] =  setMaximumAcceptedDistanceForAutoTracking(obj, Value)
            obj. MaximumAcceptedDistanceForAutoTracking =                        Value;
        end

        function value = getMaximumAcceptedDistanceForAutoTracking(obj)
            value = obj.MaximumAcceptedDistanceForAutoTracking;
        end
        
        function [obj] =  setFirstPassDeletionFrameNumber(obj, Value)
            obj. FirstPassDeletionFrameNumber =                        Value;
        end
        
        function value = getAutoTrackingActiveGap(obj)
            value = obj.AutoTrackingActiveGap;
        end

        function [obj] =  setAutoTrackingConnectionGaps(obj, Value)
            obj. AutoTrackingConnectionGaps =                        Value;
        end

        function value = getFirstPassDeletionFrameNumber(obj)
            value = obj.FirstPassDeletionFrameNumber;
        end
        
        function value = getAutoTrackingConnectionGaps(obj)
            value = obj.AutoTrackingConnectionGaps;
        end
        
        function value = getDistanceLimitXYForTrackMerging(obj)
            value = obj.DistanceLimitXYForTrackMerging;
        end
        
        function value = getDistanceLimitZForTrackingMerging(obj)
            value = obj.DistanceLimitZForTrackingMerging;
        end
        
        function value = getShowDetailedMergeInformation(obj)
            value = obj.ShowDetailedMergeInformation;
        end
        
        
        %% set state with complex input
        function obj = updateWith(obj, Value)
            
             switch class(Value)
                 
                 case 'PMTrackingNavigationAutoTrackView'
                     
                    obj.FirstPassDeletionFrameNumber =              Value.getFirstPassDeletionFrameNumber;
                    obj.AutoTrackingConnectionGaps =                Value.getAutoTrackingConnectionGaps;
                    obj.MaximumAcceptedDistanceForAutoTracking =    Value.getMaximumAcceptedDistanceForAutoTracking;
                    obj.DistanceLimitXYForTrackMerging  =           Value.getDistanceLimitXYForTrackMerging;
                    obj.DistanceLimitZForTrackingMerging =          Value.getDistanceLimitZForTrackingMerging;
                    obj.ShowDetailedMergeInformation =              Value.getShowDetailedMergeInformation;
 
                otherwise
                     error('Wrong input.')
                 
            end
            
            
        end
       
             
        
        %% accessor:
         function [obj] =  setDistanceLimitXYForTrackMerging(obj, Value)
            obj. DistanceLimitXYForTrackMerging =                        Value;
        end

        function [obj] =  setDistanceLimitZForTrackingMerging(obj, Value)
            obj. DistanceLimitZForTrackingMerging =                        Value;
        end

        function [obj] =  setShowDetailedMergeInformation(obj, Value)
            obj. ShowDetailedMergeInformation =                        Value;
        end
        
        
        function obj = set.TrackingCellForTime(obj, Value)
            assert(iscell(Value) && size(Value, 2) == 1, 'Wrong argument type.')
            obj.TrackingCellForTime = Value;
        end
        
        function obj = setActiveTrackID(obj, Value)
            obj.ActiveTrackID =     Value;
        end
        
        
        function obj = set.ActiveTrackID(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong argument type.')
            obj.ActiveTrackID =     Value;
        end

        function exist = testForExistenceOfTracks(obj)
            exist =              obj.getNumberOfTracks>=1;
        end
        
         function [ActiveFrame] =                    getActiveFrame(obj)
            ActiveFrame =           obj.ActiveFrame;
         end
        
        function numberOfTrackColumns = getNumberOfTrackColumns(obj)
            numberOfTrackColumns =  length(obj.FieldNamesForTrackingCell);
        end

        function trackIDColumn = getTrackIDColumn(obj)
            trackIDColumn=                             strcmp('TrackID', obj.FieldNamesForTrackingCell);
        end

        function absoluteFrameColumn = getAbsoluteFrameColumn(obj)
            absoluteFrameColumn=                       strcmp('AbsoluteFrame', obj.FieldNamesForTrackingCell);
        end

        function centroidYColumn = getCentroidYColumn(obj)
            centroidYColumn=                           strcmp('CentroidY', obj.FieldNamesForTrackingCell);
        end

        function centroidXColumn = getCentroidXColumn(obj)
            centroidXColumn=                           strcmp('CentroidX', obj.FieldNamesForTrackingCell);
        end

        function centroidZColumn = getCentroidZColumn(obj)
            centroidZColumn=                           strcmp('CentroidZ', obj.FieldNamesForTrackingCell);
        end

        function pixelListColumn = getPixelListColumn(obj)
            pixelListColumn =                          strcmp('ListWithPixels_3D', obj.FieldNamesForTrackingCell);
        end

        function segementationInfoColumn = getSegmentationInfoColumn(obj)
            segementationInfoColumn =                          strcmp('SegmentationInfo', obj.FieldNamesForTrackingCell);
        end

        function pooledData = getPooledSegmentation(obj)
            pooledData =          vertcat(obj.TrackingCellForTime{:});
            if isempty(pooledData)
                    pooledData =         cell(0,7);
            end
        end
           
        %% initialize:
        function obj = initializeWithDrifCorrectionAndFrame(obj, DriftCorrection, MaxFrame)
              obj =        obj.setTrackingCellForTimeWithDriftByDriftCorrection(DriftCorrection);
              obj =        obj.fillEmptySpaceOfTrackingCellTime(MaxFrame);
              obj =        obj.updateTrackInfoList;    
            
        end
        
    
      function obj = setTrackingCellForTimeWithDriftByDriftCorrection(obj, DriftCorrection)
            
                NumberOfFrames =           DriftCorrection.getNumberOfFrames;
                MaximumTrackedFrame =      obj.getMaximumTrackedFrame;
             
                assert(MaximumTrackedFrame <= NumberOfFrames, 'Drift correction does not span tracking range.')
             
                rowShifts =    DriftCorrection.getRowShifts;
                columnShifts=  DriftCorrection.getColumnShifts;
                planeShifts =   DriftCorrection.getPlaneShifts;
                obj.TrackingCellForTimeWithDrift = obj.TrackingCellForTime;
            
             for Index = 1 : MaximumTrackedFrame
                 
                  CorrectedY = cell2mat(obj.TrackingCellForTime{Index}(:, obj.getCentroidYColumn)) + rowShifts(Index);
                    obj.TrackingCellForTimeWithDrift{Index}(:, obj.getCentroidYColumn) =  num2cell(CorrectedY);
                   
                   CorrectedX =  cell2mat(obj.TrackingCellForTime{Index}(:, obj.getCentroidXColumn)) + columnShifts(Index);
                    obj.TrackingCellForTimeWithDrift{Index}(:, obj.getCentroidXColumn) = num2cell(CorrectedX);
                    
                    CorrectedZ = cell2mat(obj.TrackingCellForTime{Index}(:, obj.getCentroidZColumn)) + planeShifts(Index);
                    obj.TrackingCellForTimeWithDrift{Index}(:, obj.getCentroidZColumn) = num2cell(CorrectedZ);

             end
             
            
            
      end
           
        function MaxEndFrame = getMaximumTrackedFrame(obj)
            MaxEndFrame = max(obj.getListOfEndFramesPerTrack);
            if isempty(MaxEndFrame)
               MaxEndFrame = 0; 
            end
        end

        function EndFrames = getListOfEndFramesPerTrack(obj)
            EndFrames =    cellfun(@(x) max(x)   ,  obj.getListOfAllFramesPerTrack);   
        end
        
        function frames = getListOfAllFramesPerTrack(obj)
            frames =                arrayfun(@(x) obj.getAllFrameNumbersOfTrackID(x), obj.getListWithAllUniqueTrackIDs, 'UniformOutput', false);
        end
               
        function frames =                       getAllFrameNumbersOfTrackID(obj, trackID)
            pooledTrackingData =            obj.poolAllTimeFramesOfTrackingCellForTime;
            RowsWithTrackID =                           obj.getRowsOfTrackID(trackID);
            frames =                                   cell2mat(pooledTrackingData(RowsWithTrackID,2));
        end
        
               
       function ListWithAllUniqueTrackIDs =    getListWithAllUniqueTrackIDs(obj)
            TrackColumn =                               strcmp(obj.FieldNamesForTrackingCell, 'TrackID');
            [pooledData, ~] =                           obj.poolAllTimeFramesOfTrackingCellForTime;
            if ~isempty(pooledData)
                ListWithAllUniqueTrackIDs =             unique(cell2mat(pooledData(:,TrackColumn)));  
            else
                ListWithAllUniqueTrackIDs =             [];
            end

       end  
       
       
         function values = getFieldNamesOfTrackingCell(obj)
            values = obj.FieldNamesForTrackingCell;
         end
         
        
        
        %% get resting track Ids:
          function [RestingTrackIDs] =            getIdsOfRestingTracks(obj)
             NonRestingTracks =                     [obj.getIdOfActiveTrack; obj.getIdsOfSelectedTracks];
             RowsOfRestingTracks =                  ~ismember(obj.getListWithAllUniqueTrackIDs, NonRestingTracks);
             Unique = obj.getListWithAllUniqueTrackIDs;
             RestingTrackIDs = Unique(RowsOfRestingTracks);
          end
         
        function [IdOfActiveTrack] =        getIdOfActiveTrack(obj)
            IdOfActiveTrack =                 obj.ActiveTrackID;
        end

       
       %% get coordinates:
      function [Coordinates] =              getCoordinatesForTrackID(obj, trackID, varargin)
          
          NumberOfArguments = length(varargin);
          switch NumberOfArguments
              case 0
                     FilteredTrackList =             obj.getObjectListForTrackID(trackID);
              case 1
                    assert(isa(varargin{1}, 'PMDriftCorrection'), 'Wrong input.')
                  
                    if varargin{1}.getDriftCorrectionActive
                        FilteredTrackList =      obj.getDriftCorrectedObjectListForTrackID(trackID);
                    else
                        FilteredTrackList =             obj.getObjectListForTrackID(trackID);
                    end
          end
          Coordinates = obj.extractCoordinatesFromTrackList(FilteredTrackList);
      end
      
     
        
      %% get selected tracks:
        function [IdsOfSelectedTracks] =                 getIdsOfSelectedTracks(obj)
            IdsOfSelectedTracks =           obj.SelectedTrackIDs;
        end
        
        
        %% get number of tracks:
       function numberOfTracks =   getNumberOfTracks(obj)
            ListWithAllUniqueTrackIDs =         obj.getListWithAllUniqueTrackIDs;
            if isempty(ListWithAllUniqueTrackIDs)
                numberOfTracks =    0;
            else
                numberOfTracks =                    length(ListWithAllUniqueTrackIDs);
            end
       end
       
       function obj = removeRedundantData(obj)
            if ~isempty(obj.AutomatedCellRecognition)
                obj.AutomatedCellRecognition  = obj.AutomatedCellRecognition.removeRedundantData;
          
            end
       end
        
       function Model = getTrackModel(obj)
        Model = obj.Tracking;
       end
       
       %% get segmentation of frame:
         function segmentationOfCurrentFrame = getSegmentationOfFrame(obj, Value)
               segmentationOfCurrentFrame =      obj.TrackingCellForTime{Value,1};  
         end
         
         function selectedSegmentation = getSelectedSegmentationForFramesPlanesDriftCorrection(obj, Frames, Planes, DriftCorrection)
                selectedSegmentation =          obj.getSelectedSegmentationForFramesDriftCorrection(Frames, DriftCorrection);
                selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation);
                selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes);
         end
           
         
         function selectedSegmentation = getActiveSegmentationForFramesAndPlanesWithDriftCorrection(obj, Frames, Planes, DriftCorrection)
                selectedSegmentation =          obj.getSelectedSegmentationForFramesDriftCorrection(Frames, DriftCorrection);
                selectedSegmentation =          obj.filterSegementationListForActiveTrack(selectedSegmentation);
                selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes);
         end
         
         function selectedSegmentation = getSelectedSegmentationForFramesDriftCorrection(obj, Frames, DriftCorrection)
              if DriftCorrection.getDriftCorrectionActive
                 selectedSegmentation =          obj.getDriftCorrectedSegmentationOfFrame(Frames); 
             else
                selectedSegmentation =          obj.getSegmentationOfFrame(Frames); 
             end
         end
                  
         function segmentationOfActiveTrack = getActiveSegmentationForFrames(obj, Frames)
                segmentationOfActiveTrack =    obj.getSegmentationOfFrame(Frames);
                segmentationOfActiveTrack =    obj.filterSegementationListForActiveTrack(segmentationOfActiveTrack);
         end

         function list =  getTrackSummaryList(obj)
             list = obj.getTrackSummaryListInternal;
         end

        function [ConciseList]=     getConciseObjectListOfActiveTrack(obj)
            [ConciseList] =                     convertObjectListIntoConciseObjectList(obj, obj.filterTrackListForActiveTrack);
        end

        function [CurrentFrameList] =        convertObjectListIntoConciseObjectList(obj, CurrentFrameList)

            % not sure what it does, seems just to convert info column into PMSegmentationCapture;
            SegmentationColumn =                            PMTrackingNavigation(0,0).getSegmentationInfoColumn;
             CurrentFrameList(:,obj.getPixelListColumn) =   cellfun(@(x) size(x,1), CurrentFrameList(:,obj.getPixelListColumn), 'UniformOutput', false);

             %% 1: old data
             SegmentationTypeList =                         cellfun(@(x) x.SegmentationType, CurrentFrameList(:,SegmentationColumn), 'UniformOutput', false);

             %% 2: current data:
             ClassRows =                                    cellfun(@(x) strcmp(class(x), 'PMSegmentationCapture'), SegmentationTypeList);
             SegmentationTypeList(ClassRows,:) =            cellfun(@(x) x.getSegmentationType, SegmentationTypeList(ClassRows,:), 'UniformOutput', false);

             %% 3: very old data with no information:
             EmptyRows =                                    cellfun(@(x) isempty(x), SegmentationTypeList);
             SegmentationTypeList(EmptyRows,:) =        {'Not specified'};


            CurrentFrameList(:,SegmentationColumn) =        SegmentationTypeList;


        end

        %% getConciseObjectListOfFrame
         function [ConciseList] =        getConciseObjectListOfFrame(obj,FrameNumber)
             if isempty(FrameNumber)
                 ConciseList =          cell(0, 7);
             else
                CurrentFrameList =                   obj.TrackingCellForTime{FrameNumber};
                [ConciseList] =                     obj.convertObjectListIntoConciseObjectList(CurrentFrameList);
             end
         end
        
      
        %% other:
        function coordinates = getAllCentroidXCoordinates(obj)
            coordinates = obj.getXCoordinatesFromSegementationList(obj.getPooledSegmentation);
        end

        function coordinates = getAllCentroidYCoordinates(obj)
            coordinates = obj.getYCoordinatesFromSegementationList(obj.getPooledSegmentation);
        end

        function coordinates = getAllCentroidZCoordinates(obj)
            coordinates = obj.getZCoordinatesFromSegementationList(obj.getPooledSegmentation);
        end
            
      
        
       
        
         %% other:
        function obj = selectAllTracks(obj)
            obj =  obj.setSelectedTrackIdsTo(obj.getListWithAllUniqueTrackIDs);
        end
        
        function [obj] =   setActiveFrameTo(obj,Value)
            obj.ActiveFrame = Value;

        end
       
        function coordinates = getAllMaskCoordinates(obj)
            list =          obj.getPooledSegmentation;
            coordinates =   cell2mat(list(:,obj.getPixelListColumn));
        end
        
        %% setActiveTrackIDTo:
        function obj =      setActiveTrackIDTo(obj, newActiveTrackID) 
            oldActive =   obj.getIdOfActiveTrack;
            obj =          obj.removeTrackIDsFromSelectedTracks(newActiveTrackID);
            obj =          obj.setActiveTrackID(newActiveTrackID);  
            if newActiveTrackID ~= oldActive
                obj =          obj.addToSelectedTrackIds(oldActive);
            end
            
            fprintf('New active track ID = %i.\n', obj.getIdOfActiveTrack);
            
        end
        
        function obj = addToSelectedTrackIds(obj, New)
            MyOldSelectedIds = obj.getIdsOfSelectedTracks;
            MyNewSelectedIds =  New(:);
            MyCombinedIds =    unique([ MyOldSelectedIds; MyNewSelectedIds]);
                AllTrackIDs = obj.getListWithAllUniqueTrackIDs;
            
                Rows = ismember(MyCombinedIds, AllTrackIDs);
            MyCombinedIds = MyCombinedIds(Rows);
                
            obj =  obj.setSelectedTrackIdsTo(MyCombinedIds);
            
        
            
        end

        function obj =  setSelectedTrackIdsTo(obj, Numbers)
            obj.SelectedTrackIDs =      Numbers;
        end
        
        function obj = set.SelectedTrackIDs(obj, Value)
           assert((isnumeric(Value) && isvector(Value)) || isempty(Value), 'Wrong argument type.')
           Value(isnan(Value)) = [];
           obj.SelectedTrackIDs = sort(unique(Value(:)));
        end
        
        
        function TrackList = cleanPooledSegmentation(obj, TrackList)
            
              Column_TrackID=                             find(strcmp('TrackID', obj.getFieldNamesOfTrackingCell));
               
            
              TrackList(cell2mat(TrackList(:,Column_TrackID))==0,:)=          []; % remove untracked masks;
                TrackList(isnan(cell2mat(TrackList(:,Column_TrackID))),:)=      []; % remove untrackable masks

                Column_CentroidY =                          strcmp('CentroidY', obj.getFieldNamesOfTrackingCell);
                RowsWithInvalidYCoordinate =                                 cellfun(@(x) isnan(x), TrackList(:,Column_CentroidY));
                TrackList(RowsWithInvalidYCoordinate,:) =            [];

            
        end
        
        %% removeMasksWithNoPixels
         function obj =                                      removeMasksWithNoPixels(obj)
            rows =                                      obj.getRowsOfEmptyMasksInPooledData;
            obj =                                      obj.deleteRowsFromPooledAndRecreateTrackingCells(rows);
         end
        
       %% removeInvalidSegmentationFromeFrame
        function obj = removeInvalidSegmentationFromeFrame(obj, Frame)
            if ~isempty(obj.TrackingCellForTime) 
                RowsWithNoValidID =            isnan(cell2mat(obj.TrackingCellForTime{Frame, 1}(:,obj.getTrackIDColumn)));
                obj.TrackingCellForTime{Frame,1}(RowsWithNoValidID,:) = [];

            end
        end
                
        %% generateNewTrackID
        function newTrackID =                   generateNewTrackID(obj)
            newTrackID =                        max(obj.getListWithAllUniqueTrackIDs) + 1; 
            if isempty(newTrackID) || isnan(newTrackID)
                newTrackID = 1;
            end
        end
        
        %% addSegmentation
        function obj =   addSegmentation(obj, SegmentationCapture)
                obj =     obj.setEntryInTrackingCellForTime(SegmentationCapture);
                obj =     obj.updateTrackInfoList;  
        end
        
        function [obj] =          setEntryInTrackingCellForTime(obj, SegmentationCapture)

                Index =        obj.getRowOfActiveSegmentationInFrame(obj.getActiveFrame);

                if size(Index,1) >= 2 % if more than one row is positive: delete all duplicate rows (this should not be the case):
                    obj.TrackingCellForTime{obj.ActiveFrame, 1}(Index(2:end),:) =                   [];
                    Index =                                                                     Index(1,:);
                end

                if isempty(SegmentationCapture.getMaskCoordinateList) % when the pixels are empty: delete content:
                    obj.TrackingCellForTime{obj.ActiveFrame, 1}(Index,:) =                          [];
                    obj.TrackingCellForTimeWithDrift{obj.ActiveFrame, 1}(Index,:) =                 [];
                else
                    [NewMask, NewMaskWithDrift] =                                       obj.getMasksForInput(obj.ActiveTrackID, obj.ActiveFrame, SegmentationCapture);
                    obj.TrackingCellForTime{obj.ActiveFrame, 1}(Index,:) =              NewMask;
                    obj.TrackingCellForTimeWithDrift{obj.ActiveFrame, 1}(Index,:) =     NewMaskWithDrift;

                end

        end
         
            function [RowForCurrentTrack]=          getRowOfActiveSegmentationInFrame(obj, WantedFrame)
                    SegmentationList =    obj.getTrackIDsFromSegmentationList(obj.getSegmentationOfFrame(WantedFrame));
                    if isempty(SegmentationList)
                        RowForCurrentTrack=     1; 
                    else
                        RowForCurrentTrack=                     find(SegmentationList == obj.getIdOfActiveTrack);
                        if isempty(RowForCurrentTrack)
                            RowForCurrentTrack=                 size(SegmentationList,1) + 1;
                        end
                    end
            end
               
        
           function [Mask, MaskWithDrift] =  getMasksForInput(obj, MyTrackID, activeFrame, SegmentationCapture)
               
                    %% regular mask:
                    Mask{1, obj.getTrackIDColumn} =           MyTrackID;
                    Mask{1, obj.getAbsoluteFrameColumn} =     activeFrame;
                    Mask{1, obj.getCentroidYColumn} =         mean(SegmentationCapture.getMaskYCoordinateList);
                    Mask{1, obj.getCentroidXColumn} =         mean(SegmentationCapture.getMaskXCoordinateList);
                    Mask{1, obj.getCentroidZColumn} =         mean(SegmentationCapture.getMaskZCoordinateList);
                    Mask{1, obj.getPixelListColumn} =         SegmentationCapture.getMaskCoordinateList;
                    SegmentationInfo =                        SegmentationCapture.RemoveImageData;
                    Mask{1,PMTrackingNavigation(0,0).getSegmentationInfoColumn}.SegmentationType=         SegmentationInfo;

                    %% need to make sure that TrackingAnalysis is set: may throw an error if this is not the case;
                    if isempty(obj.TrackingAnalysis)
                        MaskWithDrift =     Mask;
                    else
                        MaskWithDrift =     obj.TrackingAnalysis.addDriftCorrectionToMasks(Mask);
                    end
                    MaskWithDrift{1, obj.getPixelListColumn} =                                                                  '';
                    MaskWithDrift{1, PMTrackingNavigation(0,0).getSegmentationInfoColumn}.SegmentationType=                    SegmentationInfo;
                   
               
           end
          
           
        
          %% deleteAllSelectedTracks
         function obj = deleteAllSelectedTracks(obj)
            obj =                    obj.removeTrack(obj.getIdsOfSelectedTracks);
            obj.SelectedTrackIDs =   zeros(0,1);
         end
         
         function obj =       removeTrack(obj, trackID)
            [pooled, pooledDrift] =       obj.getPooledDataAfterDeletingTrack(trackID);
            obj =                         obj.reconstructTrackCellForTimeFromPooledData(pooled, pooledDrift);
         end
        
         
    
         function obj =                          trackingByFindingUniqueTargetWithinConfines(obj, Distance)
                obj.AutoTrackingActiveGap =       Distance;  
                obj =                          obj.trackingByFindingUniqueTargetWithinConfinesInteral;
         end
      
         %% filterTrackListForFrame
        function [filteredTrackingData] =     filterTrackListForFrame(obj, FrameNumber)
            pooledTrackingData =               obj.poolAllTimeFramesOfTrackingCellForTime;            
            FrameColumn =                           2;
            WantedRows =                   cell2mat(pooledTrackingData(:,FrameColumn)) == FrameNumber;
            filteredTrackingData =         pooledTrackingData(WantedRows,:);  
        end
         
        %% removeFromTrackListTrackWithID
        function TrackList = removeFromTrackListTrackWithID(obj, TrackList, MySourceTrackID)
            TrackColumn =                                   1;
            RowOfSourceTrack =                             cell2mat(TrackList(:,TrackColumn)) == MySourceTrackID; 
            TrackList(RowOfSourceTrack,:) =                                         [   ];
        end
        
        %% fillEmptySpaceOfTrackingCellTime
           function obj =                                      fillEmptySpaceOfTrackingCellTime(obj, NumberOfFrames)
               obj = obj.setLengthOfTrackingCellForTime(NumberOfFrames);
               obj = obj.FillGapsInTrackingCellForTime(NumberOfFrames);
           end
           
    
    end
    
    methods(Access= private)
        
        %% extract coordinates for specific tracks:
         function [coordinates] =       getDriftCorrectedCoordinatesForTrackID(obj, trackID)
                FilteredTrackList =      obj.getDriftCorrectedObjectListForTrackID(trackID);
                coordinates =             obj.extractCoordinatesFromTrackList(FilteredTrackList);
         end
        
                
        function FilteredDriftCorrectedList = getDriftCorrectedObjectListForTrackID(obj, trackID)
            [TrackList, DriftCorrectedTrackList] =          obj.poolAllTimeFramesOfTrackingCellForTime;
            FilteredTrackList =                             TrackList(obj.getRowsOfTrackID(trackID),:);
            FilteredDriftCorrectedList =                    DriftCorrectedTrackList(obj.getRowsOfTrackID(trackID),:);

            FilteredDriftCorrectedList(:, obj.getPixelListColumn) =                  FilteredTrackList(:, obj.getPixelListColumn);
            FilteredDriftCorrectedList(:, obj.getSegmentationInfoColumn) =          FilteredTrackList(:, obj.getSegmentationInfoColumn);
            
        end
        
          function rows =         getRowsOfTrackID(obj,trackID)
                rows =            obj.getRowsOfTrackIDFromList(obj.poolAllTimeFramesOfTrackingCellForTime, trackID);
         end
        
         function rows = getRowsOfTrackIDFromList(obj, TrackList, trackID)
             if isempty(TrackList)
                    rows = zeros(0,1);
             else
                    if isscalar(trackID) && isnan(trackID) % don't fully understand this
                         ListWithTrackIDs =                obj.extractTrackIDsFromTrackList(TrackList);
                        rows = isnan(ListWithTrackIDs);
                    else
                         rows =      obj.getRowsInTrackListThatBelongToTrackIds(TrackList, trackID);
                    end
             end
             
         end
         
          function ListWithTrackIDs = extractTrackIDsFromTrackList(obj, TrackList)
                TrackColumn =                           1;
                ListWithTrackIDs =  cell2mat(TrackList(:,TrackColumn));
          end
         
         
         function rows = getRowsInTrackListThatBelongToTrackIds(obj, TrackList, IDOfTargetTrack)
              ListWithTrackIDs =        obj.extractTrackIDsFromTrackList(TrackList);
              rows =                    arrayfun(@(x) find(ListWithTrackIDs == x), IDOfTargetTrack, 'UniformOutput', false);
              rows =                    cell2mat(rows);
         end
         
         
        
         
         
        function [pooledData, pooledDataWithDrift] =                   poolAllTimeFramesOfTrackingCellForTime(obj)
            pooledData =                obj.getPooledSegmentation;
              pooledDataWithDrift =     vertcat(obj.TrackingCellForTimeWithDrift{:});   
        end
        
         function coordinates = extractCoordinatesFromTrackList(obj, TrackList)
           coordinates =                   TrackList(:,   [find(obj.getCentroidXColumn), find(obj.getCentroidYColumn), find(obj.getCentroidZColumn)]);  
         end
      
        
          function segmentationOfCurrentFrame = getDriftCorrectedSegmentationOfFrame(obj, Value)
                if obj.testExistenceOfDriftCorrectionForFrame(Value)
                    segmentationOfCurrentFrame =      obj.TrackingCellForTimeWithDrift{Value,1};
                else
                    segmentationOfCurrentFrame =      obj.getEmptySegmentationList;
                end   
         end
        
        
        function value = testExistenceOfDriftCorrectionForFrame(obj, Value)
             value= isempty(obj.TrackingCellForTime) || size(obj.TrackingCellForTime,1) < Value || isempty(obj.TrackingCellForTime{Value});
                value = ~ value;
        end
        
         function FilteredList = filterSegementationListForSelectedTracks(obj, List)
                  FilteredList = List(obj.getRowsOfTrackIDFromList(List, obj.SelectedTrackIDs), :);      
         end
             
         
        %% replace this with initializeWithDrifCorrectionAndFrame;
            function obj =                          resetTrackingCellForTimeWithDriftFromScratch(obj)

                if ~isempty(obj.TrackingAnalysis)
                [pooledData, ~] =                           obj.poolAllTimeFramesOfTrackingCellForTime;
                pooledWithDrift     =                       obj.TrackingAnalysis.addDriftCorrectionToMasks(pooledData);

                pooledWithDrift(:,6) =                      {''};
                pooledWithDrift(:,7) =                      {''};

                obj.TrackingCellForTimeWithDrift     =       obj.separatePooledDataIntoTimeSpecific(pooledWithDrift);

                end
            end
        
        %% initialize:
           
           
        
           
           function EmptyContent = getEmptyTrackingContent(obj)
                EmptyContent =                      cell(0, obj.getNumberOfTrackColumns);
           end
           
           function obj = setLengthOfTrackingCellForTime(obj, NumberOfFrames)
                 if isempty(obj.TrackingCellForTime) || size(obj.TrackingCellForTime,1) < NumberOfFrames
                    obj.TrackingCellForTime{NumberOfFrames,1} =      obj.getEmptyTrackingContent;
                    obj.TrackingCellForTimeWithDrift{NumberOfFrames,1} =      obj.getEmptyTrackingContent;
                end
           end
           
           function obj = FillGapsInTrackingCellForTime(obj, NumberOfFrames)
                  
               for CurrentFrame = 1:NumberOfFrames
                    if isempty(obj.TrackingCellForTime{CurrentFrame,1})
                            obj.TrackingCellForTime{CurrentFrame,1} =                 obj.getEmptyTrackingContent;
                            obj.TrackingCellForTimeWithDrift{CurrentFrame,1} =       obj.getEmptyTrackingContent;
                         
                    elseif size(obj.TrackingCellForTime{CurrentFrame,1},2) == 6 % if just the segmentation info column isi missing
                            obj.TrackingCellForTime{CurrentFrame,1}(:,PMTrackingNavigation(0,0).getSegmentationInfoColumn) =        {PMSegmentationCapture};
                            obj.TrackingCellForTimeWithDrift{CurrentFrame,PMTrackingNavigation(0,0).getSegmentationInfoColumn} =         '';                 
                         
                       
                    end


                end
               
           end
           
           
            function obj =  updateTrackInfoList(obj)

                obj = obj.cleanupTrackInfoList;

                missingTrackIDs = setdiff(obj.getListWithAllUniqueTrackIDs, obj.getTrackIDsInTrackInfoList);
                if isempty(missingTrackIDs)

                else
                    NumberOfMissingTracks = size(missingTrackIDs,1);
                     ListWithRowsToAdd =     size(obj.TrackInfoList) + 1 :  size(obj.TrackInfoList) + NumberOfMissingTracks;
                    for Index = 1 : NumberOfMissingTracks
                        obj.TrackInfoList{ListWithRowsToAdd(Index), 1} = PMTrackInfo(missingTrackIDs(Index));
                    end
                end



            end
            
          function obj = cleanupTrackInfoList(obj)
                obj =       obj.removeTrack(NaN);
                obj =       obj.removeNanFromTrackInfoList;
                obj =       obj.deleteFromInfoListTrackIDs(obj.getExtraTrackIDsInInfoList); 
          end
          
          function obj = removeNanFromTrackInfoList(obj)
               obj.TrackInfoList(isnan(obj.getTrackIDsInTrackInfoList)) =            [];
          end
          
          function TrackIdsThatAreExtraInInfoList = getExtraTrackIDsInInfoList(obj)
               TrackIdsThatAreExtraInInfoList =         setdiff(obj.getTrackIDsInTrackInfoList, obj.getListWithAllUniqueTrackIDs);
          end
          
          function obj = deleteFromInfoListTrackIDs(obj, TrackIds)
                  rowsToDelete =                           arrayfun(@(x) find(x == obj.getTrackIDsInTrackInfoList), TrackIds);
               obj.TrackInfoList(rowsToDelete,:) =      [];
          end
          
           
    
           
           
           
           %% set active track ID          
        function obj = removeTrackIDsFromSelectedTracks(obj, TrackIDs)
            obj.SelectedTrackIDs(obj.getIdsOfSelectedTracks == TrackIDs, :) = [];
        end

     
        
        function pooledDataWithDrift = poolCompleteSegmentationWithDrift(obj)
            pooledDataWithDrift =                   vertcat(obj.TrackingCellForTimeWithDrift{:});     
        end
        
        function segmentationList = getEmptySegmentationList(obj)
            segmentationList =    cell(0,length(obj.FieldNamesForTrackingCell));
            
        end
        
        
        function ReconstructedTimeSpecificList =       separatePooledDataIntoTimeSpecific(obj, list)
            
            numberOfFrames =                    size(obj.TrackingCellForTime,1);
            columnWithTime =                    2;
            
            ReconstructedTimeSpecificList =          cell(numberOfFrames,1);
            
             for CurrentTimePointIndex =  1:numberOfFrames
  
                 if size(list,2)<columnWithTime
                     dataOfCurrentFrame = cell(0,7);
                 else
                     rowsForCurrentFrame =                                                 cell2mat(list(:,columnWithTime)) == CurrentTimePointIndex;
                  dataOfCurrentFrame =                                                  list(rowsForCurrentFrame,:);
                 end
                  
                  ReconstructedTimeSpecificList{CurrentTimePointIndex,1 } =             dataOfCurrentFrame;
                                  
            end
    
            
        end

        function rowsWithEmptyPixels =          getRowsOfTracksWithEmptyPixels(obj, TrackList)
            rowsWithEmptyPixels     =           cellfun(@(x) isempty(x),   TrackList(:,obj.getPixelListColumn));
            
        end
        
        
      
            function [pooledTrackingData, pooledTrackingDataWithDrift] =      getPooledDataAfterDeletingRows(obj, RowsToDelete)
            
             [pooledTrackingData, pooledTrackingDataWithDrift] =         obj.poolAllTimeFramesOfTrackingCellForTime;
            
            
            pooledTrackingData(RowsToDelete,:) =                     [];
            pooledTrackingDataWithDrift(RowsToDelete,:) =            [];
            
        end
        
        
        
        function [pooledTrackingData, pooledTrackingDataWithDrift] =         getPooledDataAfterDeletingTrack(obj, trackID)            
            [pooledTrackingData, pooledTrackingDataWithDrift] =             obj.poolAllTimeFramesOfTrackingCellForTime;
            RowsWithTrackID =                                               obj.getRowsOfTrackID(trackID);
            pooledTrackingData(RowsWithTrackID,:) =                         [];
            pooledTrackingDataWithDrift(RowsWithTrackID,:) =                [];

        end
        
         %% get specific rows from pooled Data        
        function RowsForFramesOfFirstTrack =              getRowsForTrackSplitFirst(obj,SplitFrame,SourceTrackID)
            
                 pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
            
                 RowsForAllFrames =                                                              obj.getRowsOfTrackID(SourceTrackID);
                RowsForAllFramesOfFirstTrack =                                                 cell2mat(pooledTrackingData(:,obj.getAbsoluteFrameColumn)) <    SplitFrame;

                % apply AND filter so that only tracks of second track are there;
                RowsForFramesOfFirstTrack =                                                    min([RowsForAllFrames RowsForAllFramesOfFirstTrack], [], 2);

            
            
            
        end
        
        function RowsForFramesOfSecondTrack =           getRowsForTrackSplitSecond(obj,SplitFrame,SourceTrackID)
            
             pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
            
             % get all rows of track
                RowsForAllFrames =                                                              obj.getRowsOfTrackID(SourceTrackID);
                RowsForAllFramesOfNewSecondTrack =                                                 cell2mat(pooledTrackingData(RowsForAllFrames,obj.getAbsoluteFrameColumn)) >=    SplitFrame;

                % apply AND filter so that only tracks of second track are there;
                RowsForFramesOfSecondTrack =                                                    RowsForAllFrames(RowsForAllFramesOfNewSecondTrack,:);

            
            
        end
        
        
       
     

       
        
        
       
        
        
     
        

         
           
      
           
          function TrackIdOfCurrentInfoList = getTrackIDsInTrackInfoList(obj)
             emptyRows =                        cellfun(@(x) isempty(x), obj.TrackInfoList);
             obj.TrackInfoList(emptyRows) =     [];
             TrackIdOfCurrentInfoList  =        cellfun(@(x) x.TrackID, obj.TrackInfoList); 
         end
        
       
        
        function TrackIds =                 getTrackIdsWithLimitedMaskData(obj)
            
            
            NumberOfPlanes =                16; % maximum number of "one point" masks;
            TrackIds =                      NaN;
            pooledTrackingData =            obj.poolAllTimeFramesOfTrackingCellForTime;

            ListWithAllUniqueTrackIDs =    obj.getListWithAllUniqueTrackIDs;
            
            myNumberOfTracks =              size(ListWithAllUniqueTrackIDs,1);
            CountOfIncomplete =             0;
            
            for TrackIndex = 1:myNumberOfTracks
               
                myTrackId =                 ListWithAllUniqueTrackIDs(TrackIndex);
                RowsWithTrackID =           obj.getRowsOfTrackID(myTrackId);
                
                RelevantMaskData =          pooledTrackingData(RowsWithTrackID,:);
                
                NumberOfMasks =             size(RelevantMaskData,1);
                
                DetailedMask =              cellfun(@(x) size(x,1)>NumberOfPlanes+10, RelevantMaskData(:,6));
                
                Fraction =                  sum(DetailedMask)/NumberOfMasks;
                
                if Fraction<= 0.5
                   fprintf('Track %i has %1.1f fraction detailed masks.\n', myTrackId, Fraction);
                   CountOfIncomplete = CountOfIncomplete + 1;
                end
            end
            fprintf('\n%i of %i tracks remain poorly masked.\n', CountOfIncomplete,myNumberOfTracks);
        end
        
        
     
        
        
        
       
     
        
        
        
        function FilteredTrackList =             getObjectListForTrackID(obj, trackID)
            [TrackList, ~] =             obj.poolAllTimeFramesOfTrackingCellForTime;
            FilteredTrackList =          TrackList(obj.getRowsOfTrackID(trackID),:);
        end
        

        
        
   
        
     
        
        
        
        
        
        function [objectList]=          filterObjectListForFrames(obj,Frames,List)
            
            
            AvailableFrames = cell2mat(List(:,2));
           
            MatchingRows =  ismember(AvailableFrames, Frames);
            
            objectList = List(MatchingRows,:);
        end
        
        
       
        
        function FilteredTrackList =               filterTrackListForActiveTrack(obj)
            
                trackID =                           obj.ActiveTrackID;
                FilteredTrackList =                 obj.getObjectListForTrackID(trackID);
   
          end
        
         
    

    
        
        %% get track summary list
       function [TrackSummary] =               getTrackSummaryListInternal(obj)
          
           obj =          obj.removeInvalidEntriesFromTrackInfo;
           
            TrackSummary =      table(obj.getListWithAllUniqueTrackIDs,...
                obj.getListOfStartFramesPerTrack, obj.getListOfEndFramesPerTrack, ...
                obj.getNumberOfFramesPerTrack, obj.getMissingFramesPerTrack, ...
                obj.getFinishedStatusOfTracks);
                
       end
       
       function obj =          removeInvalidEntriesFromTrackInfo(obj)
            WrongTypeRows =                             cellfun(@(x) ~isa(x, 'PMTrackInfo'), obj.TrackInfoList);
            obj.TrackInfoList(WrongTypeRows) =          [];
            RowsWithNaNTrack =                          cellfun(@(x) isnan(x.TrackID), obj.TrackInfoList);
            obj.TrackInfoList(RowsWithNaNTrack) =       [];
       end
       
    
     
     function finishedStatus = getFinishedStatusOfTracks(obj)
          trackInfos=         arrayfun(@(x) obj.getTrackinInfoForTrackID(x), obj.getListWithAllUniqueTrackIDs, 'UniformOutput', false);
            finishedStatus =    cellfun(@(x) x.getFinishedStatus, trackInfos, 'UniformOutput', false);
         
         
     end
         
     function trackInfo=  getTrackinInfoForTrackID(obj,myWantedTrackID)
           row =            obj.getRowInTrackInfoForTrackID(myWantedTrackID);
           if isnan(row)
               trackInfo = '';
           else
               trackInfo = obj.TrackInfoList{row,1};
           end
     end
        
       
       function MissingFrames = getMissingFramesPerTrack(obj)
           StartFrames =       obj.getListOfStartFramesPerTrack;                
            EndFrames =         obj.getListOfEndFramesPerTrack;   
            NumberOfFrames =    obj.getNumberOfFramesPerTrack;   
            MissingFrames=      EndFrames -  StartFrames - NumberOfFrames + 1;
       end
       
       %% getListOfStartFramesPerTrack:
       function StartFrames = getListOfStartFramesPerTrack(obj)
           FrameLists =         obj.getListOfAllFramesPerTrack;
           StartFrames =        cellfun(@(x) min(x)   , FrameLists);   
       end
       
   
       
   
        
       
       
       
        function numberOfFrames = getNumberOfFramesPerTrack(obj)
             FrameLists =         obj.getListOfAllFramesPerTrack;
             numberOfFrames =         cellfun(@(x) length(x)   , FrameLists);   
        end
        
        
        
   

         function row =   getRowInTrackInfoForTrackID(obj,myWantedTrackID)              
                ExistingTrackIds  =              obj.getTrackIDsInTrackInfoList;  
                MatchingRows =                   find(ExistingTrackIds == myWantedTrackID);
                if length(MatchingRows) == 1
                    row = MatchingRows;
                elseif isempty(MatchingRows)
                    row = NaN;
                else
                    error('Track-info list is corrupted. More than one match for single TrackID.')
                end
          end
      
      

       %% setters: basic:
 
  
        
        
        
      
        
        
        function [obj]=                         convertOldCellMaskStructureIntoTrackingCellForTime(obj)
            
            
               %% this function converts the "segmentation data" from the migration structure to cell-format:

               myCellMaskStructure =            obj.OldCellMaskStructure;
               targetFieldNames =               obj.FieldNamesForTrackingCell;
               numberOfColumns =                length(obj.FieldNamesForTrackingCell);
               
               NumberOfColumnsPerMaskCell =     length(targetFieldNames);
               
                if isfield(myCellMaskStructure, 'TimePoint')

                    NumberOfTimePointsSegmented=                            length(myCellMaskStructure.TimePoint);
                    ListWithMasksPerTime =                                  cell(NumberOfTimePointsSegmented, 1);
                    
                    for CurrentTimePointIndex =  1:NumberOfTimePointsSegmented
  
                        CurrentStructure =                  myCellMaskStructure.TimePoint(CurrentTimePointIndex,1).CellMasksInEntireZVolume;
                        
                        if ~isempty(CurrentStructure)
                            
                            fieldNames =                        fieldnames(CurrentStructure);
                            CurrentSourceCell =                 struct2cell(CurrentStructure)';

                            NanRows =                           isnan(cell2mat(CurrentSourceCell(:,4)));
                            CurrentSourceCell(NanRows,:) =      [];

                            if isempty(CurrentSourceCell)
                                CurrentTargetCell = cell(0,numberOfColumns);
                            else

                                NumberOfEntries =       size(CurrentSourceCell,1);
                                CurrentTargetCell =     cell(NumberOfEntries,numberOfColumns);
                                for CurrentColumn = 1:numberOfColumns
                                    SourceColumn =                          strcmp(fieldNames, targetFieldNames{CurrentColumn});
                                    
                                    OldContents =                               CurrentSourceCell(:,SourceColumn);
                                    
                                    if strcmp(targetFieldNames{CurrentColumn}, 'CentroidZ') && (max(isnan(cell2mat(OldContents))) == 1)
                                        TopPlaneColumn =                    strcmp(fieldNames, 'TopZPlane');
                                        BottomPlaneColumn =                 strcmp(fieldNames, 'BottomZPlane');
                                        TopContents =                       cell2mat(CurrentSourceCell(:,TopPlaneColumn));
                                        BottomContents =                    cell2mat(CurrentSourceCell(:,BottomPlaneColumn));
                                        OldContents =                    num2cell(median([TopContents BottomContents], 2));
                                        
                                    end
                                    
                                    CurrentTargetCell(:,CurrentColumn) =        OldContents;

                                end

                            end   
                        else

                            CurrentTargetCell = cell(0,NumberOfColumnsPerMaskCell);
                              
                        end
                        
                        ListWithMasksPerTime{CurrentTimePointIndex,1} =  CurrentTargetCell;
                               
                    end

                    obj.TrackingCellForTime =                       ListWithMasksPerTime;
                    
                    obj =                                           obj.resetTrackingCellForTimeWithDriftFromScratch;
                    
                end

        end
        

      
 
        %% deleteActiveMask:
         function obj =                             deleteActiveMask(obj)
            obj  =                  obj.removeMask( obj.getIdOfActiveTrack, obj.getActiveFrame);
         end
         
        
        
        

            
        function obj =                          removeMask(obj, TrackID, CurrentFrame)
            TrackColumn = 1;
            CurrentData =                                                           obj.TrackingCellForTime{CurrentFrame,1};
            AllTracks =                                                             cell2mat(CurrentData(:,TrackColumn));
            RowToDelete =                                                           AllTracks  ==    TrackID;
            obj.TrackingCellForTime{CurrentFrame,1}(RowToDelete,:) =                [];
            obj.TrackingCellForTimeWithDrift{CurrentFrame,1}(RowToDelete,:) =       [];
            
        end
        
        
     
        
    
   
   
        
        
        
        function obj =                          removeTrackWithFramesLessThan(obj,FrameNumberLimit)
            
                fprintf('\nDeleting tracks with %i or less frames:\nDeleting track ', FrameNumberLimit)
            
                NumberOfTracksBeforeDeletion =        obj.getNumberOfTracks;
            
                % actually less than or equal the indiated frame number;
               
            
              
             
                %% get rows in PooledDataThat should be deleted:
                UniqueTrackIDs =                                        obj.getListWithAllUniqueTrackIDs;
             
                rowsToDelete =                                          arrayfun(@(x) obj.getRowsOfTrackID(x), UniqueTrackIDs, 'UniformOutput', false);
                FrameNumberForEachTrack =                               cellfun(@(x) length(x),       rowsToDelete);        
             
                RescueRowsFromDeletion =                                FrameNumberForEachTrack>FrameNumberLimit;
                rowsToDelete(RescueRowsFromDeletion,:) =                [];
                rowsToDelete =                                          cell2mat(rowsToDelete);
            
                [pooled, pooledDrift] =                                 obj.getPooledDataAfterDeletingRows(rowsToDelete);
            
                obj =                                                   obj.reconstructTrackCellForTimeFromPooledData(pooled, pooledDrift);

                fprintf('\nBefore deletion: %i tracks. After deletion: %i tracks\n\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);
                   
        end
        
        
        %% setters: tracking;
        function obj =                          reconstructTrackCellForTimeFromPooledData(obj, pooled, pooledDrift)
            obj.TrackingCellForTime =                                   obj.separatePooledDataIntoTimeSpecific(pooled);
            obj.TrackingCellForTimeWithDrift =                          obj.separatePooledDataIntoTimeSpecific(pooledDrift);  
        end
        
        
        function obj =                          deleteRowsFromPooledAndRecreateTrackingCells(obj, rows)
            [pooled, pooledDrift] =                 obj.poolAllTimeFramesOfTrackingCellForTime;
            pooled(rows,:) =                        [];
            pooledDrift(rows,:) =                   [];
            obj =                                   reconstructTrackCellForTimeFromPooledData(obj, pooled, pooledDrift);
        end
        
        
        function obj =                          replacePooledContentAtRowsColumnWithAndRecreate(obj,rows,column,content)
            [pooled, pooledDrift] =             obj.poolAllTimeFramesOfTrackingCellForTime;
            pooled(rows,column) =               {content};
            pooledDrift(rows,column) =          {content};
                
           obj =                                reconstructTrackCellForTimeFromPooledData(obj, pooled, pooledDrift);
                
            
        end
        
        
      

        
        
        
         %% setters: resulting in changes of track ID;
         
       
        
        
        
         function [obj] =                                    splitSelectedTrackAtActiveFrame(obj)
                SourceTrackID =                             obj.getIdsOfSelectedTracks;
                SplitTrackID =                              obj.generateNewTrackID;
                SplitFrame =                                obj.getActiveFrame;
                obj =                                       obj.splitTrackAtFrame(SplitFrame,SourceTrackID,SplitTrackID);
         end
        
      
        
      
        function obj =                                      splitTrackAtFrame(obj, SplitFrame,SourceTrackID,TrackIdForSecondSplitTrack)
            
                % convert to list with all time-frames:
                RowsForFramesOfSecondTrack =        obj.getRowsForTrackSplitSecond( SplitFrame,SourceTrackID);
                obj =                               obj.replacePooledContentAtRowsColumnWithAndRecreate(RowsForFramesOfSecondTrack,obj.getTrackIDColumn,TrackIdForSecondSplitTrack);
                      
                obj =                                       obj.updateTrackInfoList;
                
        end
        
         function obj =                                     splitTrackAtFrameAndDeleteSecond(obj, SplitFrame,SourceTrackID)
            
                % convert to list with all time-frames:
                RowsForFramesOfSecondTrack =                                    obj.getRowsForTrackSplitSecond( SplitFrame,SourceTrackID);
                obj =                                                           obj.deleteRowsFromPooledAndRecreateTrackingCells(RowsForFramesOfSecondTrack);
                    
         end
        
          function obj =                                    splitTrackAtFrameAndDeleteFirst(obj, SplitFrame,SourceTrackID)
            
                % convert to list with all time-frames:
                RowsForFramesOfFirstTrack =                                    obj.getRowsForTrackSplitFirst( SplitFrame,SourceTrackID);
                obj =                                                           obj.deleteRowsFromPooledAndRecreateTrackingCells(RowsForFramesOfFirstTrack);

          end
        
        %% mergeSelectedTracks
          function obj = mergeSelectedTracks(obj)
              obj =              obj.mergeTracks( obj.getIdsOfSelectedTracks);
          end

        function obj =                          mergeTracks(obj, mySelectedTrackIDs)
            
               [OverlappingFrames] =            obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
               if isempty(OverlappingFrames)
                     %fprintf('Merging of tracks ')
                   %arrayfun(@(x) fprintf('%i ', x), SelectedTrackIDs);
                   %fprintf('was successful. Merged track ranges from frame %i to %i.\n', min(TargetFramesPerTrack), max(TargetFramesPerTrack))
                     [pooledData, pooledWithDrift] =         obj.poolAllTimeFramesOfTrackingCellForTime;
                       [NewTrackID, ~] =                     min(mySelectedTrackIDs);
                       pooledData(obj.getRowsForTrackIds(mySelectedTrackIDs) ,obj.getTrackIDColumn) =              {NewTrackID};
                       pooledWithDrift(obj.getRowsForTrackIds(mySelectedTrackIDs),obj.getTrackIDColumn) =         {NewTrackID};
                       obj =              obj.reconstructTrackCellForTimeFromPooledData(pooledData, pooledWithDrift);
                       obj =              obj.updateTrackInfoList;
                   
               else
                  
                  fprintf('Merging was not allowed, because frames ')  
                   arrayfun(@(x) fprintf('%i ', x), OverlappingFrames);
                   fprintf('are overlapping.\n')
               end
               
              
              
            
        end
        
              function [OverlappingFrames] = getOverLappingFramesOfTracks(obj, mySelectedTrackIDs)
            
                assert(length(mySelectedTrackIDs)==2, 'Overlapping frames can be only detected for two tracks')
            
                [pooledData, ~] =         obj.poolAllTimeFramesOfTrackingCellForTime;
            
               TargetRowsPerTrack =      arrayfun(@(x) obj.getRowsOfTrackID(x), mySelectedTrackIDs, 'UniformOutput', false);
               FramesOfTrackOne =         cell2mat(pooledData(TargetRowsPerTrack{1}, obj.getAbsoluteFrameColumn));  
               FramesOfTrackTwo =         cell2mat(pooledData(TargetRowsPerTrack{2}, obj.getAbsoluteFrameColumn));
               
               OverlappingFrames =        intersect(FramesOfTrackOne, FramesOfTrackTwo);
            
              end
        
        
       
        
        
        function PooledTargetRows = getRowsForTrackIds(obj, SelectedTrackIDs)
             TargetRowsPerTrack =                    arrayfun(@(x) obj.getRowsOfTrackID(x), SelectedTrackIDs, 'UniformOutput', false);
                PooledTargetRows =                      vertcat(TargetRowsPerTrack{:});
              
        end
        
        

      
        %% addFramesToSourceTrackToLinkToTargetMask
        function [obj] =           addFramesToSourceTrackToLinkToTargetMask(obj,MySourceTrackID,TargetMask)
            
            % get information requiredfor interpolation:
            mySourceMask  =               obj.getLastMaskOfTrack(MySourceTrackID);
            % get frame number information for interpolation:
            
            FrameOfPostMask =                                   TargetMask{2};      
            
            if FrameOfPostMask<=mySourceMask.getFrame+1
                error('Cannot add frames when Target mask is not separated by Source Track temporally.')
            end
            
            FramesThatRequireClosing =                          mySourceMask.getFrame + 1 : FrameOfPostMask - 1;
            NumberOfFramesToClose=                              length(FramesThatRequireClosing);
            
            
            % do linear interpolation of coordinates betwee end points and delete start and end points (covered by already existing tracks); 
            
            StartY =                                            SourcePreMask{3};
            StartX =                                            SourcePreMask{4};
            StartZ =                                            SourcePreMask{5};

            EndY =                                              TargetMask{3};
            EndX =                                              TargetMask{4};
            EndZ =                                              TargetMask{5};

           XList =                                              linspace(StartX,EndX,NumberOfFramesToClose+2);
           YList =                                              linspace(StartY,EndY,NumberOfFramesToClose+2); 
           ZList =                                              linspace(StartZ,EndZ,NumberOfFramesToClose+2); 

           XList([1 end]) = [];
           YList([1 end]) = [];
           ZList([1 end]) = [];

           % add interpolated frames to "pre-track";
            for FrameIndex = 1:NumberOfFramesToClose

                XForCurrentGap =         round(XList(FrameIndex));
                YForCurrentGap =         round(YList(FrameIndex));
                ZForCurrentGap =         round(ZList(FrameIndex));
                newPixelList =           [YForCurrentGap, XForCurrentGap, ZForCurrentGap];
                
                SegmentationCapture =    PMSegmentationCapture();
                SegmentationCapture.SegmentationType =              'Interpolate';
                SegmentationCapture.getMaskCoordinateList = newPixelList;
                
                obj.ActiveFrame =       FramesThatRequireClosing(FrameIndex);
                obj.ActiveTrackID =     MySourceTrackID;
                obj =                   obj.setEntryInTrackingCellForTime( SegmentationCapture);

            end
  
        end
        

        function [SourceMask]  = getLastMaskOfTrack(obj, MyTrackID)
            FrameColumn = 2;

            SourceTrackInformation =          obj.filterTrackListForTrackID(MyTrackID, obj.poolAllTimeFramesOfTrackingCellForTime);
            [~, RowOfLastFrame] =     max(cell2mat(SourceTrackInformation(:,FrameColumn)));     
            SourceMask =                    PMMask(  SourceTrackInformation(RowOfLastFrame,:));


        end
        
         function filteredTrackingData =                         filterTrackListForTrackID(obj, trackID, pooledTrackingData)
            rows =                                              obj.getRowsOfTrackID(trackID);
            filteredTrackingData =                              pooledTrackingData(rows,:);
         end
        
        
        
            
   
      
        function [obj] =                                    truncateTrackToFitMask(obj,MySourceTrackID,CandidatePostMasks_StartAtRightFrame)
            
            [mySourceMask]  =           obj.getLastMaskOfTrack(MySourceTrackID);
            FrameOfTargetMask =                        CandidatePostMasks_StartAtRightFrame{2};
            
            if FrameOfTargetMask>mySourceMask.getFrame
               error('There is no overlap between source track and target mask.') 
            end
            

            for ClearFrame = FrameOfTargetMask:mySourceMask.getFrame
                % delete the target masks at the specified frames (remove overlap so that merging will be allowed);
                obj =                          obj.removeMask(MySourceTrackID,ClearFrame);

            end
            
        end
        
       
        
         function RowsWithNoPixels =                getRowsOfEmptyMasksInPooledData(obj)
            pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
            RowsWithNoPixels =                         cellfun(@(x) isempty(x), pooledTrackingData(:, obj.getPixelListColumn)); 
         end
         
        
        function obj = removeMasksByMaxPlaneLimit(obj, Value)
            rows =           obj.getRowsOfMasksByMaxPlaneLimit(Value);
            obj =            obj.deleteRowsFromPooledAndRecreateTrackingCells(rows);
            
             obj =              obj.selectAllTracks;
        end
        
          function RowsWithinMaxPlaneLimit =                getRowsOfMasksByMaxPlaneLimit(obj, Value)
            pooledTrackingData =        obj.poolAllTimeFramesOfTrackingCellForTime;
            RowsWithinMaxPlaneLimit =          cellfun(@(x) size(x,1)<= Value, pooledTrackingData(:, obj.getPixelListColumn)); 
         end
        
       
        
     

        
          function obj =                                resetColorOfAllTracks(obj, color)
             
              % this should probably be done in purely as a view: not
              % written directly into model:
             %% read:
             MyTrackModel =                                     obj.Tracking;
             
             %process
             ColumnWithLineThickness =                          strcmp(obj.ColumnsInTrackingCell, 'LineColor');
             MyTrackModel(:,ColumnWithLineThickness) =          {color};
             
             %% apply
             obj.Tracking =                                     MyTrackModel;
                
             
          end
          
          function obj =                                unTrack(obj)
             
              
               answer = questdlg('You are about the disconnect connections (tracks) between all cells. The cells will remain. This is irreversible! Do you want to proceed?');
                
               
                if strcmp(answer, 'Yes')
                    
                    fprintf('Disconnecting tracks:\nBefore disconnecting: %i tracks. ', obj.getNumberOfTracks);
                    
                    TrackStart =      1;
                    
                    NumberOfFrames =            size(obj.TrackingCellForTime,1);

                    for FrameIndex =1:NumberOfFrames

                        NumberOfCells =                                                 size(obj.TrackingCellForTime{FrameIndex,1},1);
                        obj.TrackingCellForTime{FrameIndex,1}(1:NumberOfCells,1) =      num2cell(TrackStart:TrackStart+NumberOfCells-1);
                        TrackStart =                                                    TrackStart + NumberOfCells;

                    end

                    fprintf('After disconnecting: %i tracks\n\n', obj.getNumberOfTracks);
                     
                end
            
            
            
            
          end
              
          function obj =                                replaceMaskInTrackingCellForTimeWith(obj, Mask)
              [Frame,Row ] =                                   obj.getFrameAndRowInTrackTimeCellForMask(Mask);
              obj.TrackingCellForTime{Frame, 1}(Row,:) =       Mask; 
          end
          
         function [FrameNumber, RowNumber ] =     getFrameAndRowInTrackTimeCellForMask(obj, Mask)
        
            assert(size(Mask,1) == 1, 'This function only accepts a single mask as input.')
            FrameNumber =                   Mask{1,obj.getAbsoluteFrameColumn};
            RowNumber =                     cell2mat(obj.TrackingCellForTime{FrameNumber,1}(:,obj.getTrackIDColumn)) ==  Mask{1,obj.getTrackIDColumn};
            WarningText =                   sprintf('The data file or input is corrupt. There are %i repeats of track %i in frame %i. There should be 1 precisely', sum(RowNumber),  Mask{1,obj.getTrackIDColumn}, FrameNumber);
            assert(sum(RowNumber)==1, WarningText)
            
        end
         
        
      
        %% autTrackingProcedure:
          function obj =                                autTrackingProcedure(obj)
                obj =      obj.unTrack;
                obj =      obj.removeAllInterPolationMasks;
                obj =      obj.trackByMinimizingDistancesOfTracks;
                obj =      obj.removeTrackWithFramesLessThan(obj.FirstPassDeletionFrameNumber); % first delete 'remnant' tracks of just one frame, they slow down mergin and are not useful for tracking or merging
                obj =      obj.performSerialTrackReconnection;
          end
          
            function obj =                          removeAllInterPolationMasks(obj)

                NumberOfTracksBeforeDeletion =                              obj.getNumberOfTracks;
                [pooledTrackingData, pooledTrackindDataWithDrift] =         obj.poolAllTimeFramesOfTrackingCellForTime;

                % remove track
                SegmentationTypeNameList =                                          cellfun(@(x) x.SegmentationType.SegmentationType, pooledTrackingData(:,obj.getSegmentationInfoColumn), 'UniformOutput', false);
                InterPolationRows =                                                 strcmp(SegmentationTypeNameList, 'Interpolate');
                pooledTrackingData(InterPolationRows,:) =                            [];
                pooledTrackindDataWithDrift(InterPolationRows,:) =                   [];

                obj =                                                       obj.reconstructTrackCellForTimeFromPooledData(pooledTrackingData, pooledTrackindDataWithDrift);
                fprintf('Deleting interpolation masks:\n')
                fprintf('Before deletion: %i tracks. After deletion: %i tracks\n\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);

            end
            
                %% trackByMinimizingDistancesOfTracks
          function obj =                                trackByMinimizingDistancesOfTracks(obj)
              
               myTrackingAnalysis =                 obj.TrackingAnalysis;
               MaximumAcceptedDistance =            obj.MaximumAcceptedDistanceForAutoTracking;
               
               assert(~isempty(myTrackingAnalysis), 'Tracking analysis was not set')
              
              
              fprintf('Tracking by minimizing distances:\nProcessing frames ');
              % need to create a ascond TrackingCellForTime with drift correction;
               
              NumberOfTracksBeforeDeletion =            obj.getNumberOfTracks;
              myTrackingAnalysis =                      myTrackingAnalysis.convertDistanceUnitsIntoUm;
              TrackInformationPooled =                  myTrackingAnalysis.getDriftCorrectedMasks;
              
              % convert tracking list into per time cell (so that it is
              % compatible with PMTracking side
              % this is clumsy: there should be another class that is taking care of this:
              NumberOfFrames =                          max(cell2mat(TrackInformationPooled(:,2)));
              TrackInformationPerFrame =                cell(NumberOfFrames,1);
              for FrameIndex = 1:NumberOfFrames
                   rowsWithWantedTrack =                        cell2mat(TrackInformationPooled(:,2))==FrameIndex;
                   TrackInformationPerFrame{FrameIndex,1} =     TrackInformationPooled(rowsWithWantedTrack,:);
                  
              end
              
             
              
              
            %% go trhough each frame and find closest neighbors between two consecutive frames;
            for FrameIndex = 1 : NumberOfFrames-1
                
                fprintf('%i-%i; ', FrameIndex, FrameIndex+ 1);

                PreFrameInfo =                  TrackInformationPerFrame{FrameIndex, 1};
                PostFrameInfo =                 TrackInformationPerFrame{FrameIndex + 1, 1};
                
                while ~isempty(PostFrameInfo) && ~isempty(PreFrameInfo) % when all cells in post-frame have been tracked (or we ran out of pre cells stop this pair;

                    % calculate minimum distance between consecutive tracks (and continue only if below limit);
                    ListWithAllDistances =            pdist2(cell2mat(PreFrameInfo(:,3:5)), cell2mat(PostFrameInfo(:,3:5)));
                    minDistance =                     min(ListWithAllDistances(:));
                    
                   
                    
                    % link all pairs of minimum distance (their may be several pairs with identical distance);
                    [rowInPreTrack, rowInPostTrack] =                     find(ListWithAllDistances == minDistance);
                    
                     if minDistance > MaximumAcceptedDistance
                        break
                     end
                    

                    NumberOfEqualDistances =    size(rowInPreTrack,1);
                    for CurrentPair = 1 : NumberOfEqualDistances

                        PreTrackID =                            PreFrameInfo{rowInPreTrack(CurrentPair),1};
                        OldPostTrackID =                        PostFrameInfo{rowInPostTrack(CurrentPair),1};

                        % all that needs to be done is overwrite the "old track ID" in the consecutive frame with the new one (both tracking matrix and PMTrackingNavigation);
                        RowToChangeForTempData =                   cell2mat(TrackInformationPerFrame{FrameIndex+1,1}(:,1)) == OldPostTrackID;
                        TrackInformationPerFrame{FrameIndex + 1,1}(RowToChangeForTempData,1) = num2cell(PreTrackID);

                        RowToChangeForSourceData =                   cell2mat(obj.TrackingCellForTime{FrameIndex + 1,1}(:,1)) == OldPostTrackID;
                        obj.TrackingCellForTime{FrameIndex + 1, 1}(RowToChangeForSourceData,1) = num2cell(PreTrackID);
  
                        
                    end
                    
                    % remove previously tracked temporary data to avoid double tracking;
                    PreFrameInfo(rowInPreTrack,:) =           [];
                    PostFrameInfo(rowInPostTrack,:) =          [];

                end
 
            end
            fprintf('\nBefore tracking: %i tracks. After tracking: %i tracks.\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);

          end
          
          
        
          %% performSerialTrackReconnection:
          function [obj] =                              performSerialTrackReconnection(obj)
                NumberOfGaps =  length(obj.AutoTrackingConnectionGaps);
                for myGapIndex= 1:NumberOfGaps
                    obj.AutoTrackingActiveGap =       obj.AutoTrackingConnectionGaps(myGapIndex);   
                    obj =                                   obj.trackingByFindingUniqueTargetWithinConfinesInteral;
               
                end

          end
          
        function obj =                          trackingByFindingUniqueTargetWithinConfinesInteral(obj)

            % usually done after automated tracking;
            % a major issue is the lack of tracks where on or a few gap frames are present;
            % this function closes gaps of a defined number of frames;

            fprintf('PMTrackingNavigation: @trackingByFindingUniqueTargetWithinConfinesInteral.\nMerge track pairs with a gap of %i frames:\n', obj.AutoTrackingActiveGap)

            NumberOfTracksBeforeDeletion =                  obj.getNumberOfTracks;

            TrackColumn =                                   1;
            NumberOfMergedTracks =                          0;
            ListWithExcludedTrackIDs =                       NaN;
             %% get list of all track IDs that should be deleted
             while 1 % one round of merging (start from first track; done multiple times until all tracks are connected);


                    %% create pooled tracks, then go through every single track until you find one that is a target for conncetion;

                    ListWithAllAvailableTrackIDs =                  obj.getListWithAllUniqueTrackIDs;
                    ListWithAllAvailableTrackIDs(ListWithAllAvailableTrackIDs < ListWithExcludedTrackIDs,:)  = [];  
                    for TrackIndex = 1 :  size(ListWithAllAvailableTrackIDs,1)

                            obj =                       obj.mergingInfoText(ListWithAllAvailableTrackIDs, TrackIndex);
                            
                            mySourceMask  =             obj.getLastMaskOfTrack(ListWithAllAvailableTrackIDs(TrackIndex));
                            trackLinking =              PMTrackLinking(obj, mySourceMask,  obj.AutoTrackingActiveGap, obj.DistanceLimitXYForTrackMerging, obj.DistanceLimitZForTrackingMerging, obj.ShowDetailedMergeInformation);
                            CandidateTargetMasks =      trackLinking.getCandidateTargetTracks;

                            if  size(CandidateTargetMasks,1) ~= 1 
                                ListWithExcludedTrackIDs =   ListWithAllAvailableTrackIDs(TrackIndex); % exclude if not one precise target can be found:

                            else

                                FramesOfSource =             obj.getAllFrameNumbersOfTrackID( ListWithAllAvailableTrackIDs(TrackIndex));
                                fprintf('Merge track %i (frame %i to %i)', ListWithAllAvailableTrackIDs(TrackIndex), min(FramesOfSource), max(FramesOfSource))

                                FramesTarget =                      obj.getAllFrameNumbersOfTrackID( CandidateTargetMasks{1});
                                fprintf(' with track %i (frame %i to %i).\n', CandidateTargetMasks{1}, min(FramesTarget),max(FramesTarget))

                                if obj.AutoTrackingActiveGap >= 1
                                    obj =           obj.addFramesToSourceTrackToLinkToTargetMask(ListWithAllAvailableTrackIDs(TrackIndex),CandidateTargetMasks);

                                elseif obj.AutoTrackingActiveGap <= -1
                                    obj =        truncateTrackToFitMask(obj,ListWithAllAvailableTrackIDs(TrackIndex), CandidateTargetMasks);

                                end
                                                                
                                % b) after filling gap, merge the two tracks;
                                obj =                          obj.mergeTracks([ListWithAllAvailableTrackIDs(TrackIndex), CandidateTargetMasks{1, TrackColumn}]);
                                NumberOfMergedTracks =         NumberOfMergedTracks + 1;
                                break % start from beginning because original track names have changed;

                            end

                    end

                    if TrackIndex == size(ListWithAllAvailableTrackIDs,1) % if the loop ran until the end: exit, otherwise start from the beginning;
                        break 
                    end
             end
             
            fprintf('A total of %i track-pairs were merged.\n', NumberOfMergedTracks)
            fprintf('Before merging: %i tracks. After merging: %i tracks.\n\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);


        end
        
        
        function obj = mergingInfoText(obj, ListWithAllAvailableTrackIDs, TrackIndex)
                if obj.ShowDetailedMergeInformation == 1
                    fprintf('\nTrack %i (%i of %i)', ListWithAllAvailableTrackIDs(TrackIndex), TrackIndex, size(ListWithAllAvailableTrackIDs,1))
                end
        end
        
    
          
       
        
         

       
        
         
        
 
       
         
            
            %%getMiniMask
          
          function [SegmentationData] =       getMiniMask(obj, SegmentationData)
               MiniCoordinateList(:,1) =    arrayfun(@(x) [round(SegmentationData{1,obj.getCentroidXColumn}), round(SegmentationData{1,obj.getCentroidXColumn}), x], min(SegmentationData{1,obj.getPixelListColumn}(:,3)):max(SegmentationData{1,obj.getPixelListColumn}(:,3)), 'UniformOutput',false); 
               MiniCoordinateList =         vertcat(MiniCoordinateList{:});
               assert(~isempty(MiniCoordinateList), 'Cannot corrupt database with empty coordinate list')
               SegmentationData{1,obj.getPixelListColumn} =        MiniCoordinateList;
          end
          
          
             function row =       getActiveRowInTrackInfoList(obj)
                                      
                   if isnan(obj.getIdOfActiveTrack) 
                       row = NaN;
                   elseif isempty(obj.Tracking.TrackInfoList)
                       row = 1;
                   else
                       
                       MatchingRows =        obj.getRowInTrackInfoForTrackID(obj.getIdOfActiveTrack);
                        if isnan(MatchingRows) 
                            row = size(obj.TrackInfoList,1) + 1;
                        else
                            row= MatchingRows;
                        end
                        
                   end
                       
                   
             end
            
             function content = getActiveTrackInfo(obj)
                activeRow =              obj.Tracking.getActiveRowInTrackInfoList;
                if size(obj.Tracking.TrackInfoList,1) < activeRow
                    content =            PMTrackInfo(obj.getIdOfActiveTrack);
                else
                    content =            obj.Tracking.TrackInfoList{activeRow,1};
                end
               
                 
             end
             
             function obj = setInfoOfActiveTrack(obj)
                infoOfActiveTrack =    obj.getActiveTrackInfo;
                switch input
                    case 'Finished'
                        infoOfActiveTrack =         infoOfActiveTrack.setTrackAsFinished;
                    case 'Unfinished'
                        infoOfActiveTrack =         infoOfActiveTrack.setTrackAsUnfinished;
                    otherwise
                       error('Wrong input type')
                end

                obj.TrackInfoList{activeRow,1} =        infoOfActiveTrack;
             end
             
             
             
           
             
             function FilteredList = filterSegementationListForActiveTrack(obj, List)
                  FilteredList = List(obj.getRowsOfTrackIDFromList(List, obj.ActiveTrackID), :);      
             end
             
          
             
            function selectedSegmentation = filterSegmentationListForPlanes(obj, selectedSegmentation, Planes)
                selectedSegmentation(:, obj.getPixelListColumn) =                cellfun(@(x) obj.filterPixelListForPlane(x, Planes), selectedSegmentation(:,obj.getPixelListColumn), 'UniformOutput', false);
                selectedSegmentation(obj.getRowsOfTracksWithEmptyPixels(selectedSegmentation), :) = [];

            end
              
                function [list] =               filterPixelListForPlane(obj, list, SelectedPlane)
                   
                   if isempty(list)
                           list =   zeros(0,3);
                        else
                            NoMemberShip = ~ismember(list(:,3), SelectedPlane);  
                            list(NoMemberShip, :) = [];
                   end
                        
                end 
                
                function segmentationOfTrack = getSegmentationOfAllWithTrackID(obj, TrackID)
                       
                    if length(TrackID) ~= 1 || isnan(TrackID)
                        segmentationOfTrack =    obj.getEmptySegmentationList;
                    else

                        AllTracking =             obj.getPooledSegmentation;
                        segmentationOfTrack =     AllTracking(cell2mat(AllTracking(:,1))==    TrackID, :);
                    end
                    
                end
                
          
                
                 function trackIDs =                                 getTrackIDsOfFrame(obj, FrameNumber)

                    TrackDataOfSpecifiedFrame =                obj.getSegmentationOfFrame(FrameNumber);
                    trackIDs =                                 obj.getTrackIDsFromSegmentationList(TrackDataOfSpecifiedFrame);
                 end
        
                 
                 function trackIDs =                                 getTrackIDsFromSegmentationList(obj, SegmentationList)
                    if isempty(SegmentationList)
                        trackIDs =                                  zeros(0,1);
                    else
                        trackIDs =                                  cell2mat(SegmentationList(:, obj.getTrackIDColumn));
                    end
                 end
                 
                 
            
                
                     
        function pixelList =                                getPixelsOfActiveMaskFromFrame(obj, Frame)
            wantedRow =         obj.getRowOfActiveSegmentationInFrame(Frame);
            pixelList =         obj.TrackingCellForTime{Frame, 1}{wantedRow, obj.getPixelListColumn};
        end
                
        function obj = setXCoordinatesOfFrame(obj, Frame, XCoordinates)
            if isempty(XCoordinates)
                XCoordinates = NaN;
            end
            assert(isnumeric(XCoordinates) && isvector(XCoordinates), 'Invalid argument type.')
            obj.TrackingCellForTime{Frame}(:, obj.getCentroidXColumn) = num2cell(XCoordinates);
        end
        
        function obj = setYCoordinatesOfFrame(obj, Frame, YCoordinates)
            if isempty(YCoordinates)
                YCoordinates = NaN;
            end
            assert(isnumeric(YCoordinates) && isvector(YCoordinates), 'Invalid argument type.')
            obj.TrackingCellForTime{Frame}(:, obj.getCentroidYColumn) = num2cell(YCoordinates);
        end
        
        function obj = setZCoordinatesOfFrame(obj, Frame, ZCoordinates)
             if isempty(ZCoordinates)
                ZCoordinates = NaN;
            end
            assert(isnumeric(ZCoordinates) && isvector(ZCoordinates), 'Invalid argument type.')
            obj.TrackingCellForTime{Frame}(:, obj.getCentroidZColumn) = num2cell(ZCoordinates);
        end
        
        function coordinates = getXCoordinatesOfFrame(obj, Frame)
            
            if size(obj.TrackingCellForTime, 1) >= Frame
                coordinates = obj.getXCoordinatesFromSegementationList(obj.TrackingCellForTime{Frame});
            else
                coordinates =   zeros(0,1);
            end
            
            
        end
        
        function coordinates = getXCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.getCentroidXColumn));
        end
        
          function coordinates = getYCoordinatesOfFrame(obj, Frame)
              
            if size(obj.TrackingCellForTime, 1) >= Frame
                coordinates =  getYCoordinatesFromSegementationList(obj, obj.TrackingCellForTime{Frame});
            else
                coordinates =   zeros(0,1);
            end

            
          end
          
         function coordinates = getYCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.getCentroidYColumn));
         end
        
        function coordinates = getZCoordinatesOfFrame(obj, Frame)
              if size(obj.TrackingCellForTime, 1) >= Frame
                    coordinates =  getZCoordinatesFromSegementationList(obj, obj.TrackingCellForTime{Frame});
                else
                    coordinates =   zeros(0,1);
              end
        end
            
        function coordinates = getZCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.getCentroidZColumn));
        end
        
        function TrackID = getIDOfFirstSelectedTrack(obj)
            if isempty(obj.SelectedTrackIDs)
                TrackID = NaN;
            else
                TrackID = obj.SelectedTrackIDs(1);
            end
            
        end
        
    end
end

