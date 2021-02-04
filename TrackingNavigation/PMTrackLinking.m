classdef PMTrackLinking
    %PMTRACKMATCHING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        TrackingObject
        
        SourceMask
        
        TrackingGap
        DistanceLimitXY
        DistanceLimitZ
        ShowLog
    end
    
    properties (Access = private, Constant)
        TrackColumn = 1;
        FrameColumn = 2;
        
    end
    
    methods
        function obj = PMTrackLinking(varargin)
            %PMTRACKMATCHING Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArgumengts = length(varargin);
            
            switch NumberOfArgumengts
                case 0 
                case 6
                    obj.TrackingObject =    varargin{1};
                    obj.SourceMask =        varargin{2};
                    obj.TrackingGap =       varargin{3};
                    obj.DistanceLimitXY =   varargin{4};
                    obj.DistanceLimitZ =    varargin{5};
                    obj.ShowLog =           varargin{6};
                    
                otherwise
                    error('Wrong input.')
                
            end
            
            
        end
        
     
        
        function FilteredTracks = getCandidateTargetTracks(obj)
            
                obj =                   obj.showEndStartFrameForEndFrame(obj.SourceMask.getFrame);
                FilteredTracks =        obj.TrackingObject.filterTrackListForFrame(obj.getStartFrameOfTargetTrack);
                
                % this seems counterproductive: why do I want to remove my own track: does this lead to double-tracking? check!;
                FilteredTracks =        obj.TrackingObject.removeFromTrackListTrackWithID(FilteredTracks, obj.SourceMask.getTrackID);

                if obj.ShowLog
                     fprintf('\n***PMTrackLinking.\n')
                        fprintf('%i tracks contain target frame.\n', size(FilteredTracks,1))
                end

                if ~isempty(FilteredTracks)
                    FilteredTracks =      obj.filterTargetMasksByXYDistance(FilteredTracks);
                     if ~isempty(FilteredTracks)
                           FilteredTracks =        obj.filterTargetMasksByZOverlap(FilteredTracks);
                            if ~isempty(FilteredTracks)
                               FilteredTracks =      obj.filterForMasksThatStartAtFrame(FilteredTracks);
                            end
                     end
                end
                
            
            
        end
        
        
       function  FilteredTargetTracks =     filterTargetMasksByXYDistance(obj, FilteredTargetTracks)
                ListWithAllDistances =                pdist2(obj.SourceMask.getCentroidYX, cell2mat(FilteredTargetTracks(:,3:4)));
                RowsBelowLimit =                      ListWithAllDistances < obj.DistanceLimitXY;
                FilteredTargetTracks =     FilteredTargetTracks(RowsBelowLimit, :);
                
                    if obj.ShowLog == 1
                            fprintf('Right XY distance: %i tracks.\n', size(FilteredTargetTracks,1))
                    end
                    
        end
        
        
           function  [CandidateMasksSucceedingZFilter] =     filterTargetMasksByZOverlap(obj, FilteredTracks)

                MinZ =                  min(obj.SourceMask.getAllUniqueZPositions);
                MaxZ=                   max(obj.SourceMask.getAllUniqueZPositions);
                UniqueSourceMaskZ =     MinZ - obj.DistanceLimitZ : MaxZ + obj.DistanceLimitZ;

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
                        fprintf(') in target frame %i are close enough to track %i in source frame %i.\n', obj.getStartFrameOfTargetTrack, obj.SourceMask.getTrackID, obj.getEndFrameOfSourceTrack)

                end

           end
         
              function FilteredTracks =      filterForMasksThatStartAtFrame(obj, FilteredTracks)

                    StartFramesOfCandidates =           arrayfun(@(x) min(x), obj.getFramesOfTrackList(FilteredTracks));
                    if obj.ShowLog
                        fprintf('Start frames of candidate =')
                        arrayfun(@(x) fprintf(' %i', x), StartFramesOfCandidates)
                        fprintf('\n')
                    end

                    MatchingRows =          StartFramesOfCandidates == obj.getStartFrameOfLinkedTrack;
                    FilteredTracks =        FilteredTracks(MatchingRows,:);
                    
                      if obj.ShowLog
                          
                            ListWithTrackIDs_StartAtRightFrame =     cell2mat(FilteredTracks(:,obj.TrackColumn));
                           
                             fprintf('Right start frame: %i tracks.\n', size(ListWithTrackIDs_StartAtRightFrame,1))
                            if ~isempty(ListWithTrackIDs_StartAtRightFrame)
                                fprintf('Tracks ')
                                arrayfun(@(x) fprintf('%i ', x), ListWithTrackIDs_StartAtRightFrame)
                                fprintf(') start at target frame %i.\n', obj.getStartFrameOfTargetTrack)

                            end
                        
                        end

                        
                                
              end
 
    end
    
    methods (Access = private)
        

        function frame = getEndFrameOfSourceTrack(obj)
            frame = obj.SourceMask.getFrame;
        end
        
          function frame = getStartFrameOfLinkedTrack(obj)
                frame  =                     obj.SourceMask.getFrame + obj.TrackingGap + 1;
          end
          
          function frames = getFramesOfTrackList(obj, FilteredTrack)
                frames =             cell2mat(FilteredTrack(:, obj.FrameColumn));
          end
          
       
          
          
          function obj = showEndStartFrameForEndFrame(obj, EndFrame)
                if obj.ShowLog == 1
                    %input('Press key to continue')
                    fprintf(' ends in frame%i.\n',  EndFrame)
                    fprintf('Target track must start at frame %i.\n', obj.getStartFrameRelativeToEndFrame(EndFrame))
                end
          end
          
          function StartFrame = getStartFrameOfTargetTrack(obj)
              StartFrame = obj.getStartFrameRelativeToEndFrame(obj.SourceMask.getFrame);
          end
          
        function frame = getStartFrameRelativeToEndFrame(obj, EndFrame)
            frame  =                     EndFrame + obj.TrackingGap + 1;
        end
            
    end
    
end

