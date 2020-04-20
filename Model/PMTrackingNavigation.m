classdef PMTrackingNavigation
    %PMTRACKINGNAVIGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        NumberOfTracks =                0
        
        FieldNamesForTrackingCell =     {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        TrackingCellForTime =           cell(0,1);
        
        MaximumDistanceForTracking =    50;
        
        FieldNamesForTrackingInfo =     {''};
        TrackingInfoCellForTime=        cell(0,1);
        
        OldCellMaskStructure
        
        ColumnsInTrackingCell
        Tracking
        TrackingWithDriftCorrection
        
        FirstPassDeletionFrameNumber =                                  3;
        AutoTrackingConnectionGaps =                                    [-1 0 -2 1  -3 ];   
        MaximumAcceptedDistanceForAutoTracking =                        30;
        DistanceLimitXYForTrackMerging =                                30;
        DistanceLimitZForTrackingMerging =                              2; % all tracks that show some overlap are accepted; positive values extend overlap
        ShowDetailedMergeInformation =                                  false
        
        TrackInfoList = cell(0,1)
        

    end
    
    methods
        
        function obj = PMTrackingNavigation(Data,Version)
            %PMTRACKINGNAVIGATION Construct an instance of this class
            %   Detailed explanation goes here
            
            
            switch Version
                
                case 2
                    
                    if ~isempty(fieldnames(Data))
                        
                        obj.OldCellMaskStructure = Data;
                        
                        if isfield(Data, 'Segmentation')
                            
                            if ~isempty(Data.Segmentation)

                                obj.OldCellMaskStructure =      Data.Segmentation; 
                                obj =                           obj.convertOldCellMaskStructureIntoTrackingCellForTime;
                                obj =                           obj.calculateNumberOfTracks;
                            
                            end
                            
                            
                        end
                        
                    end
                    
                    
                    
            end
            
            
        end
        
        
     
        %% getters:
        
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
                
        

        function ListWithAllUniqueTrackIDs =    getListWithAllUniqueTrackIDs(obj)
            
            targetFieldNames =                          obj.FieldNamesForTrackingCell;

            TrackColumn =                               strcmp(targetFieldNames, 'TrackID');
            ListWithAllMasks =                          vertcat(obj.TrackingCellForTime{:});
            
            if ~isempty(ListWithAllMasks)
                ListWithAllUniqueTrackIDs =             unique(cell2mat(ListWithAllMasks(:,TrackColumn)));  
            else
                ListWithAllUniqueTrackIDs =     [];
            end
            
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
                RowsWithTrackID =           obj.getRowsOfTrackID(pooledTrackingData, myTrackId);
                
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
        
        
     
        
        function newTrackID =                   generateNewTrackID(obj)
            
            ListWithAllUniqueTrackIDs =         obj.getListWithAllUniqueTrackIDs;
            newTrackID =                        max(ListWithAllUniqueTrackIDs) + 1;
            
            
        end
        
       
        function frames =                       getAllFrameNumbersOfTrackID(obj, trackID)
            
             pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
             RowsWithTrackID =                           obj.getRowsOfTrackID(pooledTrackingData, trackID);
             frames =                                   cell2mat(pooledTrackingData(RowsWithTrackID,2));
    
        end
        
        
        
        function [filteredTrackingData, ListWithTrackIDs] = filterTrackListForFrame(obj, FrameNumber,pooledTrackingData)
            
            TrackColumn =                           1;
            FrameColumn =                           2;
            
            ListWithFrames =                        cell2mat(pooledTrackingData(:,FrameColumn));
            rows =                                  ListWithFrames == FrameNumber;
            
            
            
            
            filteredTrackingData =                  pooledTrackingData(rows,:);
            
            
            ListWithTrackIDs =                  cell2mat(filteredTrackingData(:,TrackColumn));  

            
        end
        
        function filteredTrackingData = filterTrackListForTrackID(obj, trackID, pooledTrackingData)
            
            rows =                         obj.getRowsOfTrackID(pooledTrackingData,trackID);
            filteredTrackingData =          pooledTrackingData(rows,:);
            
        end
        
        function rows =                         getRowsOfTrackID(obj,pooledTrackingData,trackID)
            
            TrackColumn =                           1;
            ListWithTrackIDs =                      cell2mat(pooledTrackingData(:,TrackColumn));
            rows =                                  ListWithTrackIDs == trackID;
             
        end
        
          function FilteredTrackList =                                filterTrackListForActiveTrack(obj,TrackList,trackID)
            
              rows =                            obj.getRowsOfTrackID(TrackList,trackID);
              FilteredTrackList =               TrackList(rows,:);
                 
          end
        
         
          
        function pooledData =                   poolAllTimeFramesOfTrackingCellForTime(obj)
            
            pooledData =                            vertcat(obj.TrackingCellForTime{:});
                   
            
        end
        
        
        function NewTrackingCellForTime =       separatePooledDataIntoTimeSpecific(obj, list)
            
            
            numberOfFrames =                    size(obj.TrackingCellForTime,1);
            columnWithTime =                    2;
            
            NewTrackingCellForTime =          cell(numberOfFrames,1);
            
             for CurrentTimePointIndex =  1:numberOfFrames
  
                  rowsForCurrentFrame =                                         cell2mat(list(:,columnWithTime)) == CurrentTimePointIndex;
                  dataOfCurrentFrame =                                          list(rowsForCurrentFrame,:);
                  NewTrackingCellForTime{CurrentTimePointIndex,1 } =            dataOfCurrentFrame;
                                  
            end
    
             obj =                                                           obj.calculateNumberOfTracks;
            
        end
        
        
        function [FrameNumber, RowNumber ] =     getFrameAndRowInTrackTimeCellForMask(obj,Mask)
        
            assert(size(Mask,1) == 1, 'This function only accepts a single mask as input.')
            
            
            FrameNumber =                   Mask{1,obj.getAbsoluteFrameColumn};
            TrackId     =                   Mask{1,obj.getTrackIDColumn};
            
            TimeData =                      obj.TrackingCellForTime{FrameNumber,1};
            RowNumber =                     cell2mat(TimeData(:,obj.getTrackIDColumn)) == TrackId;

            WarningText =                   sprintf('The data file or input is corrupt. There are %i repeats of track %i in frame %i. There should be 1 precisely', sum(RowNumber), TrackId, FrameNumber);
            assert(sum(RowNumber)==1, WarningText)
            
        end
        
        
        function rowsWithEmptyPixels =          getRowsOfTracksWithEmptyPixels(obj, TrackList)
        
            rowsWithEmptyPixels     =           cellfun(@(x) isempty(x),   TrackList(:,obj.getPixelListColumn));
            
        end

        


        %% setter:
         function obj =                          calculateNumberOfTracks(obj)
            
         
            ListWithAllUniqueTrackIDs =         obj.getListWithAllUniqueTrackIDs;
            
            if isempty(ListWithAllUniqueTrackIDs)
                obj.NumberOfTracks =    0;

            else
                
                obj.NumberOfTracks =                    length(ListWithAllUniqueTrackIDs);
                
            end
             
            
                    
            
         end
        
        
        function [obj]=                         convertOldCellMaskStructureIntoTrackingCellForTime(obj)
            
            
               %% this function converts the "segmentation data" from the migration structure to cell-format:

               myCellMaskStructure =            obj.OldCellMaskStructure;
               targetFieldNames =               obj.FieldNamesForTrackingCell;
               numberOfColumns =                length(obj.FieldNamesForTrackingCell);
               
               NumberOfColumnsPerMaskCell =     length(targetFieldNames);
               
               
                if isfield(myCellMaskStructure, 'TimePoint')

                    NumberOfTimePointsSegmented=                length(myCellMaskStructure.TimePoint);
                    CellContent =                               cell(NumberOfTimePointsSegmented, 1);
                    
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
                        
                        
                        
                        
                        
                        CellContent{CurrentTimePointIndex,1} =  CurrentTargetCell;
                               
                    end
                    
                    
                    obj.TrackingCellForTime =       CellContent;
                    
                end

              
           end
        

        
        function obj =                          removeMask(obj,TrackID,CurrentFrame)
            
            TrackColumn = 1;
            
            CurrentData =                   obj.TrackingCellForTime{CurrentFrame,1};
            
            AllTracks =                     cell2mat(CurrentData(:,TrackColumn));
            
            
            RowToDelete =                   AllTracks  ==    TrackID;
            
             
            obj.TrackingCellForTime{CurrentFrame,1}(RowToDelete,:) = [];
            
            obj =                           obj.calculateNumberOfTracks;
            
        end
        
        
        function obj =                          removeTrack(obj, trackID)

            % concatenate time-specific data:
            pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
 
            % remove track
            RowsWithTrackID =                           obj.getRowsOfTrackID(pooledTrackingData, trackID);

            pooledTrackingData(RowsWithTrackID,:) =     [];
          
            % convert pooled list back into time-specific list
            separateList =                              obj.separatePooledDataIntoTimeSpecific(pooledTrackingData);
            obj.TrackingCellForTime =                   separateList;
            
            obj =                                       obj.calculateNumberOfTracks;
            
  
        end
        
        function obj =                      removeAllInterPolationMasks(obj)
            
            NumberOfTracksBeforeDeletion =                  obj.NumberOfTracks;

            pooledTrackingData =                            obj.poolAllTimeFramesOfTrackingCellForTime;

            % remove track
            SegmentationTypeNameList =                      cellfun(@(x) x.SegmentationType.SegmentationType, pooledTrackingData(:,obj.getSegmentationInfoColumn), 'UniformOutput', false);
            InterPolationRows =                             strcmp(SegmentationTypeNameList, 'Interpolate');
            pooledTrackingData(InterPolationRows,:) =       [];

            % convert pooled list back into time-specific list
            separateList =                                  obj.separatePooledDataIntoTimeSpecific(pooledTrackingData);
            obj.TrackingCellForTime =                       separateList;

            obj =                                           obj.calculateNumberOfTracks;
            NumberOfTracksAfterDeletion =                   obj.NumberOfTracks;

            fprintf('Deleting interpolation masks:\n')
            fprintf('Before deletion: %i tracks. After deletion: %i tracks\n\n', NumberOfTracksBeforeDeletion, NumberOfTracksAfterDeletion);

        end
        
        
        
        function obj =                      removeTrackWithFramesLessThan(obj,FrameNumberLimit)
            
            fprintf('\nDeleting tracks with %i or less frames:\nDeleting track ', FrameNumberLimit)
            
            NumberOfTracksBeforeDeletion =        obj.NumberOfTracks;
            
            % actually less than or equal the indiated frame number;
            TrackColumn = 1;
            
            %% get pooled track data (for ease of manipulation split into time matrix at end of procedure;
             pooledTrackingData =                           obj.poolAllTimeFramesOfTrackingCellForTime;
            
             %% get list of all track IDs that should be deleted
             UniqueTrackIDs =                               obj.getListWithAllUniqueTrackIDs;
             ListWithTrackIDs =                             cell2mat(pooledTrackingData(:,TrackColumn));
            TrackDurationsForAllTrackIDs =                 arrayfun(@(x) sum(ListWithTrackIDs == x), UniqueTrackIDs);
            RowsForTracksToDelete =                         TrackDurationsForAllTrackIDs<=FrameNumberLimit;
            TrackIdsToDelete =  UniqueTrackIDs(RowsForTracksToDelete);
             
            %% go trough each track ID and delete all linked masks;
            NumberOfTracksToDelete = size(TrackIdsToDelete,1);
            for TrackIndex = 1:NumberOfTracksToDelete
                
                fprintf('%i of %i..., ', TrackIndex, NumberOfTracksToDelete);
               
                MyTrackID =                                     TrackIdsToDelete(TrackIndex);
                TrackRowsToDelete =                             cell2mat(pooledTrackingData(:,TrackColumn)) == MyTrackID;
                pooledTrackingData(TrackRowsToDelete,:) =       [];
                
            end

             separateList =                                                   obj.separatePooledDataIntoTimeSpecific(pooledTrackingData);
             obj.TrackingCellForTime =                                        separateList;
       
             
                 obj =                                                               obj.calculateNumberOfTracks;
             
                 
                 NumberOfTracksAfterDeletion =        obj.NumberOfTracks;
                 
                  fprintf('\nBefore deletion: %i tracks. After deletion: %i tracks\n\n', NumberOfTracksBeforeDeletion, NumberOfTracksAfterDeletion);
                 
                 
        end
        
        function obj =                          mergeTracks(obj, SelectedTrackIDs)
            

               listWithAllMasks =                       obj.poolAllTimeFramesOfTrackingCellForTime;
               TargetRowsPerTrack =                     arrayfun(@(x) find(obj.getRowsOfTrackID(listWithAllMasks,x)), SelectedTrackIDs, 'UniformOutput', false);
              
               FramesOfTrackOne =                       cell2mat(listWithAllMasks(TargetRowsPerTrack{1},obj.getAbsoluteFrameColumn));  
                FramesOfTrackTwo =                      cell2mat(listWithAllMasks(TargetRowsPerTrack{2},obj.getAbsoluteFrameColumn));
               
                OverlappingFrames =                     intersect(FramesOfTrackOne, FramesOfTrackTwo);
                
                MaximumFrameTrackOne =          max(FramesOfTrackOne);
               MinimumFrameTrackTwo =              min(FramesOfTrackTwo);
                
               %% only allow merging when there is no overlap between the tracks
               PooledTargetRows =                       vertcat(TargetRowsPerTrack{:});
               %TargetFramesPerTrack =                   arrayfun(@(x) listWithAllMasks{x,obj.getAbsoluteFrameColumn}, PooledTargetRows);
                
              
               if MaximumFrameTrackOne>=MinimumFrameTrackTwo
                   fprintf('Merging was not allowed, because frames ')
                   arrayfun(@(x) fprintf('%i ', x), OverlappingFrames);
                   fprintf('are overlapping. Track 1 ends frame %i and track 2 start frame %i.\n', MaximumFrameTrackOne, MinimumFrameTrackTwo)
                   return
                   
               else
                   %fprintf('Merging of tracks ')
                   %arrayfun(@(x) fprintf('%i ', x), SelectedTrackIDs);
                   %fprintf('was successful. Merged track ranges from frame %i to %i.\n', min(TargetFramesPerTrack), max(TargetFramesPerTrack))
                   
               end
               
               %% use lowest track ID to replace all other trackIDs that should be merged;
               [NewTrackID, row] =                                              min(SelectedTrackIDs);
             
               listWithAllMasks(PooledTargetRows,obj.getTrackIDColumn) =          {NewTrackID};
               separateList =                                                   obj.separatePooledDataIntoTimeSpecific(listWithAllMasks);
               obj.TrackingCellForTime =                                        separateList;
                      
               obj =                                                            obj.calculateNumberOfTracks;
            
        end
        
        function obj =                      mergeDisconnectedTracks(obj,RequiredFrameGap)
              
            % usually done after automated tracking;
            % a major issue is the lack of tracks where on or a few gap frames are present;
            % this function closes gaps of a defined number of frames;
            
             DistanceLimitXY =              obj.DistanceLimitXYForTrackMerging ;
                DistanceLimitZ  =                               obj.DistanceLimitZForTrackingMerging;                                            0; % all tracks that show some overlap are accepted;

            
            ShowDetails =       obj.ShowDetailedMergeInformation;
            
            fprintf('PMTrackingNavigation: @mergeDisconnectedTracks.\nMerge track pairs with a gap of %i frames:\n', RequiredFrameGap)
            
            NumberOfTracksBeforeDeletion =        obj.NumberOfTracks;
                 
            Count =                 0;
            
            TrackColumn =           1;
            FrameColumn =           2;
            
            NumberOfMergedTracks =                          0;
            
            PreviouslyMergedTrackID =       NaN;
             %% get list of all track IDs that should be deleted
             while 1 % one round of merging (start from first track; done multiple times until all tracks are connected);
             
                 
                    %% create pooled tracks, then go through every single track until you find one that is a target for conncetion;
                    pooledTrackingData =                            obj.poolAllTimeFramesOfTrackingCellForTime;
                    UniqueTrackIDs =                                obj.getListWithAllUniqueTrackIDs;
                    

                    UniqueTrackIDs(UniqueTrackIDs<PreviouslyMergedTrackID,:)  = [];        
                    myNumberOfTracks =                              size(UniqueTrackIDs,1);
                    
                    for TrackIndex = 1:myNumberOfTracks

                             
                                
                               
                               %% 1: collect information of 'pre-track', i.e. track that should get connected;
                               MyTrackID =                                          UniqueTrackIDs(TrackIndex);
                                [SourcePreMask,LastFrameOfPreCell]  =               obj.getLastMaskOfTrack(MyTrackID, pooledTrackingData);

                               
                              
                                
                                
                                %% 2: filter out target tracks that do not 'go through' target frame;
                                RequiredStartFrameForPostMasks  =                     LastFrameOfPreCell + RequiredFrameGap + 1;
                                if ShowDetails == 1
                                    %input('Press key to continue')
                                     fprintf('\nTrack %i (%i of %i) ends in frame%i.\n', MyTrackID, TrackIndex, myNumberOfTracks, LastFrameOfPreCell)
                                    fprintf('Target track must start at frame %i.\n', RequiredStartFrameForPostMasks)
                                end
                                
                                [CandidatePostMasks_ThatContainTargetFrame, ListWithTrackIDs_ThatContainTargetFrame] =                  obj.filterTrackListForFrame(RequiredStartFrameForPostMasks,pooledTrackingData);
                               
                                RowOfSourceTrack =                                                                                      cell2mat(CandidatePostMasks_ThatContainTargetFrame(:,TrackColumn)) == MyTrackID; 
                                CandidatePostMasks_ThatContainTargetFrame(RowOfSourceTrack,:) =                                         [   ];

                               
                                if ShowDetails == 1
                                        fprintf('%i tracks contain target frame.\n', size(CandidatePostMasks_ThatContainTargetFrame,1))
                                end
                                    
                                if isempty(CandidatePostMasks_ThatContainTargetFrame)
                                    
                                     continue
                                end
                                
                               %% 3: filter out target cells that do not match distance requirements
                                
                                [CandidatePostMasks_RightXYDistance, ~] =        obj.filterTargetMasksByXYDistance(SourcePreMask,CandidatePostMasks_ThatContainTargetFrame,DistanceLimitXY);

                                
                                if ShowDetails == 1
                                        fprintf('Right XY distance: %i tracks.\n', size(CandidatePostMasks_RightXYDistance,1))
                                end
                                    
                                 if isempty(CandidatePostMasks_RightXYDistance)
                                     continue
                                end
                                
                               [CandidatePostMasks_RightDistance, ListWithCandidateTrackIDs_RightDistance] =        obj.filterTargetMasksByZOverlap(SourcePreMask,CandidatePostMasks_RightXYDistance, DistanceLimitZ);

                                if ShowDetails == 1
                                        fprintf('Right Z distance: %i tracks.\n', size(CandidatePostMasks_RightDistance,1))
                                end
                               
                                if isempty(CandidatePostMasks_RightDistance)
                                     continue
                                end
                                 
                               %% 4: filter out target cells that do not start at target frame (this is done at the end because computationally intensive);
                                
                               [CandidatePostMasks_StartAtRightFrame, ListWithTrackIDs_StartAtRightFrame] =                               obj.filterForMasksThatStartAtFrame(RequiredStartFrameForPostMasks,CandidatePostMasks_RightDistance);
                               
                             
                               if ShowDetails == 1
                                   fprintf('Right start frame: %i tracks.\n', size(ListWithTrackIDs_StartAtRightFrame,1))
 
                                   
                               end
                                if isempty(CandidatePostMasks_StartAtRightFrame)
                                     continue
                                else
                                    
                                       
                                    FramesOfSource =             obj.getAllFrameNumbersOfTrackID( MyTrackID);
                                    
                                 
                                   if ShowDetails == 1

                                       
                                        fprintf('%i tracks (', length(ListWithCandidateTrackIDs_RightDistance))
                                        arrayfun(@(x) fprintf('%i ', x), ListWithCandidateTrackIDs_RightDistance)
                                        fprintf(') in target frame %i are close enough to track %i in source frame %i.\n',RequiredStartFrameForPostMasks,MyTrackID,LastFrameOfPreCell)

                                        fprintf('%i tracks (', length(ListWithTrackIDs_StartAtRightFrame))
                                        arrayfun(@(x) fprintf('%i ', x), ListWithTrackIDs_StartAtRightFrame)
                                        fprintf(') start at target frame %i.\n',RequiredStartFrameForPostMasks)

                                   end
                                    
                                end
                                 
                              
                                      
                               
                               % 3: require that precisely one single match
                               % is there; (do not connect ambiguous tracks);
                               % another possibility would be to choose closest track here;
                                if  size(CandidatePostMasks_StartAtRightFrame,1) == 1 % if precisely one cell has the required

                                    
                                     fprintf('Merge track %i (frame %i to %i)', MyTrackID, min(FramesOfSource), LastFrameOfPreCell)
                                   
                                    FramesTarget =                      obj.getAllFrameNumbersOfTrackID( ListWithTrackIDs_StartAtRightFrame);
                                    fprintf(' with track %i (frame %i to %i).\n', ListWithTrackIDs_StartAtRightFrame, min(FramesTarget),max(FramesTarget))
                                    
                                 

                                    PreviouslyMergedTrackID =   MyTrackID;
                                    
                                    if RequiredFrameGap == 0
                                        
                                        
                                    elseif RequiredFrameGap >= 1
                                        
                                        % get all frame numbers that require gap-closing; 
                                        FramesThatRequireClosing = LastFrameOfPreCell + 1 : RequiredStartFrameForPostMasks - 1;
                                        
                                        
                                        % do linear interpolation of
                                        % coordinates betwee end points; 
                                        StartY = SourcePreMask{3};
                                        StartX = SourcePreMask{4};
                                        StartZ = SourcePreMask{5};
                                        
                                        EndY =  CandidatePostMasks_StartAtRightFrame{3};
                                        EndX =  CandidatePostMasks_StartAtRightFrame{4};
                                        EndZ =  CandidatePostMasks_StartAtRightFrame{5};
                                        
                                        
                                       XList =  linspace(StartX,EndX,RequiredFrameGap+2);
                                       YList =  linspace(StartY,EndY,RequiredFrameGap+2); 
                                       ZList =  linspace(StartZ,EndZ,RequiredFrameGap+2); 
                                       
                                       XList([1 end]) = [];
                                       YList([1 end]) = [];
                                       ZList([1 end]) = [];
                                        
                                        for FrameIndex = 1:RequiredFrameGap
                                            
                                            
                                            CurrentGapFrame =                                   FramesThatRequireClosing(FrameIndex);
                                            RowInCell =                                         size(obj.TrackingCellForTime{CurrentGapFrame,1},1)+1;

                                            SegmentationCapture =                               PMSegmentationCapture();
                                            SegmentationCapture.SegmentationType =              'Interpolate';

                                            XForCurrentGap =                                    round(XList(FrameIndex));
                                            YForCurrentGap =                                    round(YList(FrameIndex));
                                            ZForCurrentGap =                                    round(ZList(FrameIndex));
                                            gapPixels =                                         [YForCurrentGap,XForCurrentGap,ZForCurrentGap];

                                            obj =                                               obj.addPixelsToTrackingCellForTime(CurrentGapFrame,RowInCell,MyTrackID,gapPixels,SegmentationCapture);

                                        end

                                      
                                        
                                    elseif RequiredFrameGap <= -1
                                        
                                        % minues values mean overlap between track: have to remove the overlapping frames to allow connection;
                                        % frame(s) are removed from target track; 
                                        
                                        % remove overlap (masks:)
                                        TrackIDOfMergedCell =                       CandidatePostMasks_StartAtRightFrame{1,TrackColumn};
                                      
                                        FirstFrameWhereMaskIsDeleted =              LastFrameOfPreCell + RequiredFrameGap +1 ;
                                        LastFrameWhereMaskIsDeleted =               LastFrameOfPreCell;

                                        for ClearFrame = FirstFrameWhereMaskIsDeleted:LastFrameWhereMaskIsDeleted
                                            % delete the target masks at the specified frames (remove overlap so that merging will be allowed);
                                            obj =                          obj.removeMask(TrackIDOfMergedCell,ClearFrame);

                                        end
                                        
                                    end
                                       

                                        % b) after filling gap, merge the two tracks;
                                        obj =                                               obj.mergeTracks([MyTrackID,CandidatePostMasks_StartAtRightFrame{1,TrackColumn}]);

                                        NumberOfMergedTracks = NumberOfMergedTracks + 1;
                                       
                                        break % start from beginning because original track names have changed;

                                end

                    end

                    if TrackIndex == myNumberOfTracks % if the loop ran until the end: exit, otherwise start from the beginning;
                        break 
                    end
             end
             
             
            obj =                                                               obj.calculateNumberOfTracks;
            NumberOfTracksAfterDeletion =                                       obj.NumberOfTracks;

            fprintf('A total of %i track-pairs were merged.\n', NumberOfMergedTracks)
            fprintf('Before merging: %i tracks. After merging: %i tracks.\n\n', NumberOfTracksBeforeDeletion, NumberOfTracksAfterDeletion);

             
        end
        
        function [FilteredMasks, ListWithTracksWithCorrectStartFrame] =      filterForMasksThatStartAtFrame(obj, WantedStartFrame, CandidatePostMasks)
        
             TrackColumn = 1;
          
                  ShowDetails =       obj.ShowDetailedMergeInformation;
             
            ListWithCandidateTrackIDs =                                             cell2mat(CandidatePostMasks(:,TrackColumn));
            
            ListOfALlFramesPerCandidateMasks =                                          arrayfun(@(x) obj.getAllFrameNumbersOfTrackID(x), ListWithCandidateTrackIDs, 'UniformOutput',false);
            ListOfFirstFramesOfPostCandidateMasks =                                     cellfun(@(x) min(x), ListOfALlFramesPerCandidateMasks);
            if ShowDetails
               fprintf('Start frames of candidate =')
               arrayfun(@(x) fprintf(' %i', x), ListOfFirstFramesOfPostCandidateMasks)
                fprintf('\n')
            end
            
            RowsOfTracksWithRightFirstFrame =                                           ListOfFirstFramesOfPostCandidateMasks == WantedStartFrame;
           
            ListWithTracksWithCorrectStartFrame =                                       ListWithCandidateTrackIDs(RowsOfTracksWithRightFirstFrame);
            
            FilteredMasks =                                                             CandidatePostMasks(RowsOfTracksWithRightFirstFrame,:);
            
        end
        
        function obj =                      mergOverlappingTracks(obj,NumberOfFramesOverlapAllowed,DistanceLimitXY, DistanceLimitZ)
            
            Count = 0;
            
            TrackColumn = 1;
            FrameColumn = 2;
            
            
            PreviouslyMergedTrackID =       NaN;
            DifferenceBetweenComparisonFrames = 0;
             %% get list of all track IDs that should be deleted
             while 1
             
                    pooledTrackingData =                           obj.poolAllTimeFramesOfTrackingCellForTime;
                    UniqueTrackIDs =                               obj.getListWithAllUniqueTrackIDs;
                    

                    
                    UniqueTrackIDs(UniqueTrackIDs<PreviouslyMergedTrackID,:)  = [];   
                    myNumberOfTracks = size(UniqueTrackIDs,1);
                    
                    
                    for TrackIndex = 1:myNumberOfTracks

                        % 1: find target masks that show correct physical proximity;
                        MyTrackID =                                                                     UniqueTrackIDs(TrackIndex);
                        
                        [CandidateConnectingCellsAfterXYFilter] =      obj.filterTargetMasksByXYDistance(SourcePreMask,CandidatePostMasks_WantedStartFrame,DistanceLimitXY);

                        
                        [CandidateConnectingCellsAfterZFilter] =     obj.filterTargetMasksByXYDistance(SourceMask,CandidateConnectingCellsAfterXYFilter,DistanceLimitZ);
       
                        
                        % 2: keep only overlapping target tracks;
                       if  ~isempty(CandidateConnectingCellsAfterZFilter) % if some tracks have the minimum allowed Z distance

                            %fprintf('Merge overlapping: Track %i has the spatial requirements for merging with %i\n and potentially other tracks\n', MyTrackID, CandidateConnectingCellsAfterZFilter{1,TrackColumn});
                            % keep only tracks where the first frame is precisely two frames after the last frame of the source frame;
                            CandidateTrackIDs =                             cell2mat(CandidateConnectingCellsAfterZFilter(:,TrackColumn));

                            FirstFramesOfTargetMasks =                      arrayfun(@(x) min(obj.getAllFrameNumbersOfTrackID(x)), CandidateTrackIDs);
                            RowsOfTracksWithRightFirstFrame =               FirstFramesOfTargetMasks >= LastFrameOfSourceMask - NumberOfFramesOverlapAllowed + 1;
                            CandidateConnectingCellsAfterZFilter(~RowsOfTracksWithRightFirstFrame,:) =   [];  
  
                            if size(CandidateConnectingCellsAfterZFilter,1) == 1
                                
                                Overlap =   LastFrameOfSourceMask-FirstFramesOfTargetMasks+1;
                                
                                PreviouslyMergedTrackID = MyTrackID;
                                fprintf('Merge overlapping: Merge track %i with track %i. (Overlap = %i frames.)\n', MyTrackID, CandidateConnectingCellsAfterZFilter{1,TrackColumn}, Overlap);
                                %fprintf('Merge overlapping: It is accepted because precisely one other track had the required overlap requireemnts\n')
                            else
                                %fprintf('Merge overlapping: Not accepted because %i tracks have the required overlap characteristics\n', size(CandidateConnectingCellsAfterZFilter,1) )
                            end

                       end


                          % 3: if precisly one candidate was found: merge tracks;
                          if  size(CandidateConnectingCellsAfterZFilter,1) == 1 % if precisely one cell has the required

                             

                                %% merge the tracks:
                                obj =                               obj.mergeTracks([MyTrackID,TrackIDOfMergedCell]);

                                break % start from beginning because original track names have changed;

                           end


                    end

                     if TrackIndex == myNumberOfTracks % if the loop ran until the end: exit, otherwise start from the beginning;
                        break 
                     end
             
             end
            
        end
        
        
        function [SourceMask,LastFrame]  = getLastMaskOfTrack(obj, MyTrackID, pooledTrackingData)
            
             FrameColumn = 2;
            
                SourceTrackInformation =                        obj.filterTrackListForTrackID(MyTrackID, pooledTrackingData);
                [LastFrame, RowOfLastFrame] =                   max(cell2mat(SourceTrackInformation(:,FrameColumn)));     
                SourceMask =                                   SourceTrackInformation(RowOfLastFrame,:);

            
        end
        
        function  [CandidateMasksSuccedingXYFilter, ListWithCandidateTrackIDs] =     filterTargetMasksByXYDistance(obj,SourceMask,CandidateMasks,DistanceLimitXY)
            

                TrackColumn = 1;
                FrameColumn = 2;

                
                
                % filter for XY:
                ListWithAllDistances =                          pdist2(cell2mat(SourceMask(1,3:4)),cell2mat(CandidateMasks(:,3:4)));
                RowsBelowLimit =                                ListWithAllDistances<DistanceLimitXY;
                CandidateMasksSuccedingXYFilter =               CandidateMasks(RowsBelowLimit,:);

              
                ListWithCandidateTrackIDs =                     cell2mat(CandidateMasksSuccedingXYFilter(:,TrackColumn));

                 
                 
            
        end
        
         function  [CandidateMasksSucceedingZFilter, ListWithCandidateTrackIDs] =     filterTargetMasksByZOverlap(obj,SourceMask,CandidateMasks, DistanceLimitZ)
       
                TrackColumn = 1;
                FrameColumn = 2;
             
                
                  ShowDetails =       obj.ShowDetailedMergeInformation;
                
                UniqueSourceMaskZ =                                   unique(SourceMask{6}(:,3));  
               MinZ =    min(UniqueSourceMaskZ);
               MaxZ=    max(UniqueSourceMaskZ);
                UniqueSourceMaskZ = MinZ-DistanceLimitZ:MaxZ+DistanceLimitZ;
                
                
                % filter for Z:
                CandidateZs =                                   cellfun(@(x) x(:,3), CandidateMasks(:,6), 'UniformOutput', false); 
                Overlap =                                       cellfun(@(x) max(ismember(unique(x),UniqueSourceMaskZ)), CandidateZs);
                CandidateMasksSucceedingZFilter =               CandidateMasks(Overlap,:);

                ListWithCandidateTrackIDs =                     cell2mat(CandidateMasksSucceedingZFilter(:,TrackColumn));

                if ShowDetails
                    fprintf('Source Z =')
                    arrayfun(@(x) fprintf(' %i', x), UniqueSourceMaskZ)
                   fprintf('\n')
                   
                    NumberOfCandidates =    size(CandidateZs,1);
                    
                    for Candidate =1:NumberOfCandidates
                        fprintf('Target Z =')
                        arrayfun(@(x) fprintf(' %i', x), CandidateZs{Candidate})
                        fprintf('; ')
                    end
                    fprintf('\n')
                end
             
         end
        
        
        function obj =                      removeMasksWithNoPixels(obj)
            
              % concatenate time-specific data:
            pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
 
            % remove track
            RowsWithNoPixels =                         cellfun(@(x) isempty(x), pooledTrackingData(:, obj.getPixelListColumn));
            
            
            pooledTrackingData(RowsWithNoPixels,:) =     [];
          
            
            % convert pooled list back into time-specific list
            separateList =                              obj.separatePooledDataIntoTimeSpecific(pooledTrackingData);
            obj.TrackingCellForTime =                   separateList;
            
            obj =                                       obj.calculateNumberOfTracks;
            
            
            
        end
        
        
        function RowsForFramesOfFirstTrack =              getRowsForTrackSplitFirst(obj,listWithAllMasks,SplitFrame,SourceTrackID)
            
            
                 RowsForAllFrames =                                                              obj.getRowsOfTrackID(listWithAllMasks,SourceTrackID);
                RowsForAllFramesOfFirstTrack =                                                 cell2mat(listWithAllMasks(:,obj.getAbsoluteFrameColumn)) <    SplitFrame;

                % apply AND filter so that only tracks of second track are there;
                RowsForFramesOfFirstTrack =                                                    min([RowsForAllFrames RowsForAllFramesOfFirstTrack], [], 2);

            
            
            
        end
        
        function RowsForFramesOfSecondTrack =           getRowsForTrackSplitSecond(obj, listWithAllMasks,SplitFrame,SourceTrackID)
            
             % get all rows of track
                RowsForAllFrames =                                                              obj.getRowsOfTrackID(listWithAllMasks,SourceTrackID);
                RowsForAllFramesOfSecondTrack =                                                 cell2mat(listWithAllMasks(:,obj.getAbsoluteFrameColumn)) >    SplitFrame;

                % apply AND filter so that only tracks of second track are there;
                RowsForFramesOfSecondTrack =                                                    min([RowsForAllFrames RowsForAllFramesOfSecondTrack], [], 2);

            
            
        end
        
        
        function obj =                          splitTrackAtFrame(obj, SplitFrame,SourceTrackID,TrackIdForSecondSplitTrack);
            
            
                % convert to list with all time-frames:
                listWithAllMasks =                                                              obj.poolAllTimeFramesOfTrackingCellForTime;
                RowsForFramesOfSecondTrack =                                                    obj.getRowsForTrackSplitSecond(listWithAllMasks, SplitFrame,SourceTrackID);
                listWithAllMasks(RowsForFramesOfSecondTrack,obj.getTrackIDColumn) =             {TrackIdForSecondSplitTrack};
                obj.TrackingCellForTime =                                                       obj.separatePooledDataIntoTimeSpecific(listWithAllMasks);;
 
              
                
        end
        
         function obj =                          splitTrackAtFrameAndDeleteSecond(obj, SplitFrame,SourceTrackID);
            
                  % convert to list with all time-frames:
                listWithAllMasks =                                              obj.poolAllTimeFramesOfTrackingCellForTime;
                RowsForFramesOfSecondTrack =                                    obj.getRowsForTrackSplitSecond(listWithAllMasks, SplitFrame,SourceTrackID);
                
                listWithAllMasks(RowsForFramesOfSecondTrack,:) =               [];

                obj.TrackingCellForTime =                                       obj.separatePooledDataIntoTimeSpecific(listWithAllMasks);;
 
              
             
         end
        
          function obj =                          splitTrackAtFrameAndDeleteFirst(obj, SplitFrame,SourceTrackID)
            
              
              
              
                  % convert to list with all time-frames:
                listWithAllMasks =                                              obj.poolAllTimeFramesOfTrackingCellForTime;
                RowsForFramesOfFirstTrack =                                    obj.getRowsForTrackSplitFirst(listWithAllMasks, SplitFrame,SourceTrackID);
                
                listWithAllMasks(RowsForFramesOfFirstTrack,:) =               [];

                obj.TrackingCellForTime =                                       obj.separatePooledDataIntoTimeSpecific(listWithAllMasks);;
 
              
             
         end
        
        
        
        function obj =                          fillEmptySpaceOfTrackingCellTime(obj,NumberOfFrames)
            
            
            EmptyContent =                      cell(0,obj.getNumberOfTrackColumns);
             

            if isempty(obj.TrackingCellForTime) || size(obj.TrackingCellForTime,1) < NumberOfFrames
                obj.TrackingCellForTime{NumberOfFrames,1} =      EmptyContent;
       
            end
            
            for CurrentFrame = 1:NumberOfFrames
                
                if isempty(obj.TrackingCellForTime{CurrentFrame,1})
                    
                    obj.TrackingCellForTime{CurrentFrame,1} =                                  EmptyContent;
                elseif size(obj.TrackingCellForTime{CurrentFrame,1},2) == 6
                    obj.TrackingCellForTime{CurrentFrame,1}(:,PMTrackingNavigation(0,0).getSegmentationInfoColumn) =   {PMSegmentationCapture};
                    
                end
                
                
                
                
                
            end
            
        end

        
          function obj =                             resetColorOfAllTracks(obj, color)
             
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
          
          function obj =                unTrack(obj)
             
              
               answer = questdlg('You are about the disconnect connections (tracks) between all cells. The cells will remain. This is irreversible! Do you want to proceed?');
                
               
                if strcmp(answer, 'Yes')
                    
                    fprintf('Disconnecting tracks:\nBefore disconnecting: %i tracks. ', obj.NumberOfTracks);
                    
                    TrackStart =      1;
                    
                    NumberOfFrames =            size(obj.TrackingCellForTime,1);

                    for FrameIndex =1:NumberOfFrames

                        NumberOfCells =                                                 size(obj.TrackingCellForTime{FrameIndex,1},1);
                        obj.TrackingCellForTime{FrameIndex,1}(1:NumberOfCells,1) =      num2cell(TrackStart:TrackStart+NumberOfCells-1);
                        TrackStart =                                                    TrackStart + NumberOfCells;

                    end
                    
                    obj =                                                               obj.calculateNumberOfTracks;
                    
                    fprintf('After disconnecting: %i tracks\n\n', obj.NumberOfTracks);
                     
                end
            
            
            
            
          end
              
          
          function obj =                replaceMaskInTrackingCellForTimeWith(obj, Mask)
              
              [Frame,Row ] =                                        obj.getFrameAndRowInTrackTimeCellForMask(Mask);
              obj.TrackingCellForTime{Frame, 1}(Row,:) =             Mask;
          end
         
          %% helper functions
         function [obj] =           addPixelsToTrackingCellForTime(obj,activeFrame,RowInCell,MyTrackID,newPixels,SegmentationCapture)
            
                  
                if size(RowInCell,1)>=2
                    
                    obj.TrackingCellForTime{activeFrame, 1}(RowInCell(2:end),:) =       [];
                    RowInCell =                                                         RowInCell(1,:);
                    
                end
                
                if isempty(newPixels)
                    obj.TrackingCellForTime{activeFrame, 1}(RowInCell,:) =              [];
                    
                else

                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.getTrackIDColumn} =                   MyTrackID;
                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.getAbsoluteFrameColumn} =             activeFrame;
                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.getCentroidYColumn} =                 mean(newPixels(:,1));
                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.getCentroidXColumn} =                 mean(newPixels(:,2));
                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.getCentroidZColumn} =                 mean(newPixels(:,3));
                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,obj.getPixelListColumn} =                 newPixels;

                    SegmentationInfo =                                                                                                         SegmentationCapture.RemoveImageData;
                    obj.TrackingCellForTime{activeFrame, 1}{RowInCell,PMTrackingNavigation(0,0).getSegmentationInfoColumn}.SegmentationType=        SegmentationInfo;
                     
                end
                
                obj =                           obj.calculateNumberOfTracks;
            
        end
          
          
          function obj =            trackByMinimizingDistancesOfTracks(obj,myTrackingAnalysis,MaximumAcceptedDistance)
              
              
              fprintf('Tracking by minimizing distances:\nProcessing frames ');
              % need to create a ascond TrackingCellForTime with drift correction;
               
              NumberOfTracksBeforeDeletion =        obj.NumberOfTracks;
             
              % 1: tracking analysis is imported so that the closest neighbor can be calculated by using physical units;;
              myTrackingAnalysis =                      myTrackingAnalysis.convertDistanceUnitsIntoUm;
              TrackInformationPooled =                  myTrackingAnalysis.ListWithCompleteMaskInformationWithDrift;
              
              % convert tracking list into per time cell (so that it is compatible with PMTracking side (can this be simplified?;
              NumberOfFrames =                          max(cell2mat(TrackInformationPooled(:,2)));
              TrackInformationPerFrame =                cell(NumberOfFrames,1);
              for FrameIndex = 1:NumberOfFrames
                  
                   rowsWithWantedTrack =                        cell2mat(TrackInformationPooled(:,2))==FrameIndex;
                   TrackInformationPerFrame{FrameIndex,1} =     TrackInformationPooled(rowsWithWantedTrack,:);
                  
              end
              
             
              
              
            %% go trhough each frame and find closest neighbors between two consecutive frames;
            for FrameIndex = 1:NumberOfFrames-1
                
                fprintf('%i-%i; ', FrameIndex, FrameIndex+ 1);
                
                
                PreFrameInfo =                  TrackInformationPerFrame{FrameIndex,1};
                PostFrameInfo =                 TrackInformationPerFrame{FrameIndex+1,1};
                
                while ~isempty(PostFrameInfo) && ~isempty(PreFrameInfo) % when all cells in post-frame have been tracked (or we ran out of pre cells stop this pair;

                    % calculate minimum distance between consecutive tracks (and continue only if below limit);
                    ListWithAllDistances =          pdist2(cell2mat(PreFrameInfo(:,3:5)),cell2mat(PostFrameInfo(:,3:5)));

                    minDistance =                     min(ListWithAllDistances(:));
                    if minDistance > MaximumAcceptedDistance
                        break
                    end
                    
                    % link all pairs of minimum distance (their may be several pairs with identical distance);
                    [row,col] =                     find(ListWithAllDistances==minDistance);

                    NumberOfEqualDistances =    size(row,1);
                    for CurrentPair = 1:NumberOfEqualDistances

                        PreTrackID =                            PreFrameInfo{row(CurrentPair),1};
                        OldPostTrackID =                        PostFrameInfo{col(CurrentPair),1};

                        % all that needs to be done is overwrite the "old track ID" in the consecutive frame with the new one (both tracking matrix and PMTrackingNavigation);
                        RowToChangeForTempData =                   cell2mat(TrackInformationPerFrame{FrameIndex+1,1}(:,1)) == OldPostTrackID;
                        TrackInformationPerFrame{FrameIndex+1,1}(RowToChangeForTempData,1) = num2cell(PreTrackID);

                        RowToChangeForSourceData =                   cell2mat(obj.TrackingCellForTime{FrameIndex+1,1}(:,1)) == OldPostTrackID;
                        obj.TrackingCellForTime{FrameIndex+1,1}(RowToChangeForSourceData,1) = num2cell(PreTrackID);
  
                        
                    end
                    
                    % remove previously tracked temporary data to avoid double tracking;
                    PreFrameInfo(row,:) =           [];
                    PostFrameInfo(col,:) =          [];

                end
 
            end
            
                obj =                                   obj.calculateNumberOfTracks;
                NumberOfTracksAfterDeletion =        obj.NumberOfTracks;
                 
                  fprintf('\nBefore tracking: %i tracks. After tracking: %i tracks.\n', NumberOfTracksBeforeDeletion, NumberOfTracksAfterDeletion);
             
          
              
       
          end
          
        
          
          function obj =            autTrackingProcedure(obj, TrackingAnalysis)

              
                inFirstPassDeletionFrameNumber =                  obj.FirstPassDeletionFrameNumber;
                myConnectionGaps =                              obj.AutoTrackingConnectionGaps;   
                MaximumAcceptedDistanceForBasicTracking =       obj.MaximumAcceptedDistanceForAutoTracking;
                inDistanceLimitXYForTrackMerging =              obj.DistanceLimitXYForTrackMerging ;
                DistanceLimitZ  =                               obj.DistanceLimitZForTrackingMerging;                                            0; % all tracks that show some overlap are accepted;

              
                % settings for first for tracking and basic track-elimination;
                
                % disconnect all current 'tracks' (all masks remain) 
                % and then reconnect the masks (from scratch) them by finding nearest neighbors;

                obj =                                      obj.unTrack;
                obj =                                      obj.removeAllInterPolationMasks;
                obj =                                      obj.trackByMinimizingDistancesOfTracks(TrackingAnalysis, MaximumAcceptedDistanceForBasicTracking);
                obj =                                     obj.removeTrackWithFramesLessThan(inFirstPassDeletionFrameNumber); % first delete 'remnant' tracks of just one frame, they slow down mergin and are not useful for tracking or merging

                % merging of tracks
                
                NumberOfGaps =  length(myConnectionGaps);
                for myGapIndex= 1:NumberOfGaps
                    
                    CurrentGapDuration =        myConnectionGaps(myGapIndex);
                     obj =                                     obj.mergeDisconnectedTracks(CurrentGapDuration);
               
                end
                
               

                % when everything is done delete all frames with a certain number (too few conseutive masks implies low quality tracks);
                %obj.LoadedMovie.Tracking =                                  obj.LoadedMovie.Tracking.removeTrackWithFramesLessThan(FrameNumberAtWhichTracksAreDeleted);

              
              
              
              
              
              
              
              
          end
          
          function [SegmentationOfActiveTrack] =       getSegmentationWithPointXY(obj,SegmentationOfActiveTrack)
              
              XCoordinate =             round(SegmentationOfActiveTrack{1,obj.getCentroidXColumn});
              YCoordinate  =            round(SegmentationOfActiveTrack{1,obj.getCentroidYColumn});
              OldPixelList =           SegmentationOfActiveTrack{1,obj.getPixelListColumn};
              
        
        
              
              PlaneRange =      min(OldPixelList(:,3)):max(OldPixelList(:,3));
              
               MiniCoordinateList(:,1) =                 arrayfun(@(x) [YCoordinate, XCoordinate, x], PlaneRange, 'UniformOutput',false);
                    
               MiniCoordinateList =         vertcat(MiniCoordinateList{:});
               
               assert(~isempty(MiniCoordinateList), 'Cannot corrupt database with empty coordinate list')
               
               SegmentationOfActiveTrack{1,obj.getPixelListColumn} =        MiniCoordinateList;
               
              
          end
          
    end
end

