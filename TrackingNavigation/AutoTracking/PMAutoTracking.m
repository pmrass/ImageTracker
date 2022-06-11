classdef PMAutoTracking
    %PMAUTOTRACKING Perform autotracking
    %   Connect related track information
    % also contains parameters that are not directly used but that can be called as a standard for other tracking resources;
    
    properties (Access = private) % state properties
        MaximumAcceptedDistanceForAutoTracking =    30

        ShowDetailedMergeInformation =              true
        XYLimitForTrackMerging =                    30 
        ZLimitForTrackMerging =                     2
        ShowLog =                                   true

        FirstPassDeletionFrameNumber =              3
        AutoTrackingConnectionGaps  =               [-3 -2 -1 0 1 2 3];
         
    end
     
    properties (Access = private) % "source-data"
        ActiveTrackID
         
    end
    
  
    
    properties (Access = private, Constant)
        TrackColumn = 1;
        FrameColumn = 2;
        
    end
    
    methods

        function obj = PMAutoTracking(varargin)
            %PMAUTOTRACKING Construct an instance of this class
            %   takes 0 arguments
            switch length(varargin)
               
                case 0
                    
                otherwise
                    error('Wrong input.')
                
            end
        end
 
    end
    
    methods % SETTERS STATE
        
        function obj =      set(obj, Value)
            
                switch class(Value)

                    case 'PMAutoTrackingView'

                        obj.MaximumAcceptedDistanceForAutoTracking =    Value.getMaximumAcceptedDistanceForAutoTracking;
                        obj.XYLimitForTrackMerging  =                   Value.getDistanceLimitXYForTrackMerging;
                        obj.ZLimitForTrackMerging =                     Value.getDistanceLimitZForTrackingMerging;
                        obj.ShowLog =                                   Value.getShowDetailedMergeInformation;

                        obj.ShowDetailedMergeInformation =              Value.getShowDetailedMergeInformation;

                        obj.FirstPassDeletionFrameNumber =              Value.getFirstPassDeletionFrameNumber;
                        obj.AutoTrackingConnectionGaps =                Value.getAutoTrackingConnectionGaps;
               
           
                    case 'struct'
                
                        obj.MaximumAcceptedDistanceForAutoTracking =    Value.MaximumAcceptedDistanceForAutoTracking;
                        obj.XYLimitForTrackMerging  =                   Value.DistanceLimitXYForTrackMerging;
                        obj.ZLimitForTrackMerging =                     Value.DistanceLimitZForTrackingMerging;
                        % obj.ShowDetailedMergeInformation =              Value.getShowDetailedMergeInformation;
                        obj.FirstPassDeletionFrameNumber =              Value.FirstPassDeletionFrameNumber;
                        obj.AutoTrackingConnectionGaps =                Value.AutoTrackingConnectionGaps;

            otherwise
                 error('Wrong input.')

            end
           
            
        end
        
        function obj =  	setMaximumAcceptedDistanceForAutoTracking(obj, Value)
            obj.MaximumAcceptedDistanceForAutoTracking = Value; 
        end
        
    end
    
    methods % GETTERS STATE
        
        function structure =    getPropertiesStructure(obj)
            structure.FirstPassDeletionFrameNumber  =              obj.FirstPassDeletionFrameNumber;
            structure.AutoTrackingConnectionGaps =                 obj.AutoTrackingConnectionGaps;
            structure.MaximumAcceptedDistanceForAutoTracking  =    obj.MaximumAcceptedDistanceForAutoTracking;
            structure.DistanceLimitXYForTrackMerging =             obj.XYLimitForTrackMerging;
            structure.DistanceLimitZForTrackingMerging  =          obj.ZLimitForTrackMerging;
            
        end
        
        function Value =        getDistanceLimitXYForTrackMerging(obj)
           Value = obj.XYLimitForTrackMerging; 
        end
        
        function Value =        getDistanceLimitZForTrackingMerging(obj)
           Value = obj.ZLimitForTrackMerging;
        end
        
        function Value =        getShowDetailedMergeInformation(obj)
           Value = obj.ShowDetailedMergeInformation; 
           
           if isempty(Value)
              Value = true; 
           end
        end
        
        function Value =        getFirstPassDeletionFrameNumber(obj)
           Value = obj.FirstPassDeletionFrameNumber; 
        end
        
        function Value =        getAutoTrackingConnectionGaps(obj)
           Value = obj.AutoTrackingConnectionGaps; 
        end
        
        function Value =        getMaximumAcceptedDistanceForAutoTracking(obj)
           Value = obj.MaximumAcceptedDistanceForAutoTracking; 
        end
        
    end
    
    methods % GETTERS findMatchingTrackIDsForSegmentationLists

        function FramesThatRequireClosing =     getFramesThatRequireClosing(~, Source, Target)
        FramesThatRequireClosing =         Source.getFrame + 1 : Target.getFrame - 1;


    end

    end

    methods % ACTION: FILL UP EMPTY FRAMES BETWEEN TWO MASKS:

        function MySegmentations = getSegmentationCaptureListBetweenMasks(obj, MySourceMask, MyTargetMask)
            %SETSEGMENTATIONCAPTURELISTBETWEENMASKS sets a series of segmentations between a source and a target mask;
            %   takes 2 arguments:
            % 1: PMMask of first cell
            % 2: PMMask of second cell
            % returns vector of segmentation-captures for cells in between;
            assert(~(MyTargetMask.getFrame <= MySourceMask.getFrame + 1), 'This track has not gap. No action taken')

            [XList, YList, ZList] =         obj.getCoordinatesForInterpolationBetweenMasks(MySourceMask, MyTargetMask);
            FramesThatRequireClosing =      MySourceMask.getFrame + 1 : MyTargetMask.getFrame - 1;

            MySegmentations = cell(length(FramesThatRequireClosing), 1);

            for FrameIndex = 1 : length(FramesThatRequireClosing)
                XForCurrentGap =            round(XList(FrameIndex));
                YForCurrentGap =            round(YList(FrameIndex));
                ZForCurrentGap =            round(ZList(FrameIndex));
                newPixelList =              [YForCurrentGap, XForCurrentGap, ZForCurrentGap];

                SegmentationCapture =       PMSegmentationCapture();
                SegmentationCapture =       SegmentationCapture.setSegmentationType('Interpolate');
                SegmentationCapture =       SegmentationCapture.setMaskCoordinateList(newPixelList);

                MySegmentations{FrameIndex, 1} = SegmentationCapture;

            end

            MySegmentations = cellfun(@(x) x, MySegmentations);


        end

    end

    methods % ACTION: MATCH PRE- AND POST-SEGMENTATION LIST BY SHORTEST DISTANCE;

        function [CollectedPreTrackIDs, CollectedPostTrackIDs] = findMatchingTrackIDsForSegmentationLists(obj, PreFrameSegmentationList, PostFrameSegmentationList)
           % FINDMATCHINGTRACKIDSFORSEGMENTATIONLISTS finds matching masks by shortest distance;
           % takes 2 arguments: 
           % 1: PreFrameSegmentationList
           % 2: PostFrameSegmentationList
           % returns 2 values:
           % 1: list with "pre" track IDs
           % 2: list with "post" track IDs
           % numbers in matching rows are matching tracks;


                CollectedPreTrackIDs =          nan(10000, 1);
                CollectedPostTrackIDs =         nan(10000, 1);
                NumberOfFoundPairs =            0;


                while ~isempty(PostFrameSegmentationList) && ~isempty(PreFrameSegmentationList) % when all cells in post-frame have been tracked (or we ran out of pre cells stop this pair;

                    % calculate minimum distance between consecutive tracks (and continue only if below limit);
                    ListWithAllDistances =            pdist2(cell2mat(PreFrameSegmentationList(:,3:5)), cell2mat(PostFrameSegmentationList(:,3:5)));
                    minDistance =                     min(ListWithAllDistances(:));

                     if minDistance > obj.MaximumAcceptedDistanceForAutoTracking
                        break
                     end

                    [rowsInPreTrack, rowsInPostTrack] =   find(ListWithAllDistances == minDistance);
                    NumberOfEqualDistances =    size(rowsInPreTrack,1);
                    for PairIndex = 1 : NumberOfEqualDistances

                        PreTrackID =                    PreFrameSegmentationList{rowsInPreTrack(PairIndex),1};
                        OldPostTrackID =                PostFrameSegmentationList{rowsInPostTrack(PairIndex),1};

                        NumberOfFoundPairs = NumberOfFoundPairs + 1;
                        CollectedPreTrackIDs(NumberOfFoundPairs, 1) = PreTrackID;
                        CollectedPostTrackIDs(NumberOfFoundPairs, 1) = OldPostTrackID;



                    end

                    % remove previously tracked temporary data to avoid double tracking;
                    PreFrameSegmentationList(rowsInPreTrack,:) =             [];
                    PostFrameSegmentationList(rowsInPostTrack,:) =           [];

                end

                CollectedPreTrackIDs(NumberOfFoundPairs : end, :) = [];
                CollectedPostTrackIDs(NumberOfFoundPairs : end, :) = [];



        end

    end

    methods % ACTION: FILTER TARGETS BY XY- AND Z-DISTANCE

        function FilteredTracks = getCandidateTargetTracks(obj, MySourceMask, MyListWithPossibleTargetSegmentations)
            % GETCANDIDATETARGETTRACKS filter target-segmentations by XY and Z distance limits;

            FilteredTracks =        obj.removeFromTrackListTrackWithID(MyListWithPossibleTargetSegmentations, MySourceMask.getTrackID);

            if obj.ShowLog
                fprintf('\n***PMTrackLinking.\n')
                fprintf('%i tracks contain target frame.\n', size(FilteredTracks,1))
            end

            if ~isempty(FilteredTracks)
                FilteredTracks =      obj.filterTargetMasksByXYDistance(MySourceMask, FilteredTracks);
                 if ~isempty(FilteredTracks)
                       FilteredTracks =        obj.filterTargetMasksByZOverlap(MySourceMask, FilteredTracks);

                 end
            end



        end

    end

    
    methods (Access = private)

     function [XList, YList, ZList] = getCoordinatesForInterpolationBetweenMasks(~, mySourceMask, myTargetMask)
            StartY =                    mySourceMask.getY;
            StartX =                    mySourceMask.getX;
            StartZ =                    mySourceMask.getZ;

            EndY =                      myTargetMask.getY;
            EndX =                      myTargetMask.getX;
            EndZ =                      myTargetMask.getZ;

            NumberOfFramesToClose =     abs(mySourceMask.getFrame - myTargetMask.getFrame) - 1;

            XList =                     linspace(StartX, EndX, NumberOfFramesToClose + 2);
            YList =                     linspace(StartY, EndY, NumberOfFramesToClose + 2); 
            ZList =                     linspace(StartZ, EndZ, NumberOfFramesToClose + 2); 

            XList([1 end]) =            [];
            YList([1 end]) =            [];
            ZList([1 end]) =            [];

    end


    end

    methods (Access = private)  % GETTERS: filter segmentation list by distance relative to source mask:

     function  FilteredTargetTracks =     filterTargetMasksByXYDistance(obj, MySourceMask, FilteredTargetTracks)
        ListWithAllDistances =                pdist2(MySourceMask.getCentroidYX, cell2mat(FilteredTargetTracks(:,3:4)));
        RowsBelowLimit =                      ListWithAllDistances < obj.XYLimitForTrackMerging;
        FilteredTargetTracks =     FilteredTargetTracks(RowsBelowLimit, :);

        if obj.ShowLog == 1
                fprintf('Right XY distance: %i tracks.\n', size(FilteredTargetTracks,1))
        end

    end

    function  [CandidateMasksSucceedingZFilter] =     filterTargetMasksByZOverlap(obj, MySourceMask, FilteredTracks)

        MinZ =                  min(MySourceMask.getAllUniqueZPositions);
        MaxZ=                   max(MySourceMask.getAllUniqueZPositions);
        UniqueSourceMaskZ =     MinZ - obj.ZLimitForTrackMerging : MaxZ + obj.ZLimitForTrackMerging;

        % filter for Z:
        CandidateZs =                           cellfun(@(x) x(:,3), FilteredTracks(:, 6), 'UniformOutput', false); 
        Overlap =                               cellfun(@(x) max(ismember(unique(x),UniqueSourceMaskZ)), CandidateZs);
        CandidateMasksSucceedingZFilter =       FilteredTracks(Overlap,:);

        if obj.ShowLog
            fprintf('Right Z distance: %i tracks.\n', size(CandidateMasksSucceedingZFilter,1))
            fprintf('Source Z =')
            arrayfun(@(x) fprintf(' %i', x), UniqueSourceMaskZ)
            fprintf('\n')

            ListWithCandidateTrackIDs =             cell2mat(CandidateMasksSucceedingZFilter(:, obj.TrackColumn));
            fprintf('%i tracks (', length(ListWithCandidateTrackIDs))
            arrayfun(@(x) fprintf('%i ', x), ListWithCandidateTrackIDs)
            fprintf(') in target frame are close enough to track %i in source frame %i.\n', MySourceMask.getTrackID, MySourceMask.getFrame)

        end

    end



    end

    methods (Access = private)

        function TrackList =            removeFromTrackListTrackWithID(~, TrackList, MySourceTrackID)
            % REMOVEFROMTRACKLISTTRACKWITHID remove from input segmentation list all tracks with input track-ID;
            % takes 2 arguments:
            % 1: segmentation list
            % 2:
            RowOfSourceTrack =                 cell2mat(TrackList(:,obj.TrackIDColumn)) == MySourceTrackID; 
            assert(sum(RowOfSourceTrack) == 0, 'Target frame contains source track. This is not acceptable.')
            TrackList(RowOfSourceTrack,:) =    [   ];
        end


    end
    
end

