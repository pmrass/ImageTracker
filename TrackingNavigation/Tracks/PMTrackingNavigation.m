classdef PMTrackingNavigation
    %PMTRACKINGNAVIGATION for managing tracking of cell positions in movie
    %  keep list of all tracked objects; alllow retrieval of these data;
    
    properties (Access = private)

        TrackInfoList =               cell(0,1)
        
        ActiveTrackID  =              NaN;
        ActiveFrame =                 1;
        
        SelectedTrackIDs =            zeros(0,1);

        TrackingCellForTime % by far the most important data-piece; pretty much everything else can be reconstructed or is not that important;
        TrackingCellForTimeWithDrift 
        
    end
    
    properties (Access = private) % new
        MainFolder
        
    end
    
    properties (Access = private) % autotracking
        AutoTracking =                              PMAutoTracking

    end

    properties (Access = private) % duplicate data that are just here to boost speed; should not be stored in file

        TrackImages
        OldCellMaskStructure
        TrackingAnalysis
        
        % temporary settings for auto-tracking
        AutomatedCellRecognition
     
        AutoTrackingActiveGap = 0;

    end
        
    properties ( Constant)
        
       TrackIDColumn =              1      ;
       TimeColumn =                 2;
       CentroidYColumn =            3;
       CentroidXColumn =            4;
       CentroidZColumn =            5;
       PixelColumn =                6;
       SegmentationTypeColumn =     7;
       NumberOfColumns =            7;
       
       FieldNamesForTrackingCell =   {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
       
    end
    
    methods % INITIALIZATION

        function obj = PMTrackingNavigation(varargin)
            %PMTRACKINGNAVIGATION Construct an instance of this class
            %   takes 0, 1 or 2 arguments
            % 1: tracking cell for time or main-folder ('char')
            % 2: 1: old data-format; 2: version number (just for backward compatibility, will be phased out);

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                
                case 0

                case 1

                    switch class(varargin{1})
                        case 'cell'
                            assert(isscalar(varargin{1}), 'Wrong input')
                            obj =   obj.setTrackingCellForTime(varargin{1});
                            
                        case 'char'
                            obj.MainFolder = varargin{1};
                            
                        otherwise
                            errror('Wrong input.')
                    end

                case 2

                    Data =      varargin{1};
                    Version =   varargin{2};
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

                        otherwise
                                error('Wrong input.')
                    end 

            otherwise
                error('Wrong input.')
            end

        end

        function obj = set.ActiveFrame(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && ~isnan(Value), 'Wrong input.')
            obj.ActiveFrame = Value; 
        end

        function obj = set.TrackingCellForTime(obj, Value)
            %  obj = obj.checkTrackingCellForTime(Value); % too slow
            obj.TrackingCellForTime = Value;
        end

        function obj = set.TrackingCellForTimeWithDrift(obj, Value)
            %  obj = obj.checkTrackingCellForTime(Value); % too slow
            obj.TrackingCellForTimeWithDrift = Value;

        end

        function obj = set.ActiveTrackID(obj, Value)

            if isempty(Value)
            else
                assert(obj.verifyTrackID(Value), 'Wrong argument type.')
            end
            obj.ActiveTrackID =     Value;
            obj = obj.ActiveTrackWasChanged;

        end

        function obj = set.SelectedTrackIDs(obj, Value)
            assert((isnumeric(Value) && isvector(Value)) || isempty(Value), 'Wrong argument type.')
            Value(isnan(Value)) = [];
            obj.SelectedTrackIDs = sort(unique(Value(:)));
        end

        function obj = initializeWithDrifCorrectionAndFrame(obj, DriftCorrection, MaxFrame)

            obj =       obj.setLengthOfTrackingCellForTime(MaxFrame);
            obj =       obj.FillGapsInTrackingCellForTime;
            obj =       obj.setTrackingCellForTimeWithDriftByDriftCorrection(DriftCorrection);
            obj =       obj.addMissingTrackIdsToTrackInfoList;
            obj =       obj.addSegmentationAddressToAllTrackInfos; 

        end

        function obj = set.MainFolder(obj, Value)
            assert(ischar(Value), 'Wrong input.')
            obj.MainFolder = Value;
        end
        
        function obj = set.TrackingAnalysis(obj, Value)
            assert(isa(Value, 'PMTrackingAnalysis') && isscalar(Value), 'Wrong input.')
           obj.TrackingAnalysis = Value; 
            
        end

    end
    
    methods % SETTERS FILE-MANAGEMENT

        function obj =      setMainFolder(obj, Value)
            % SETMAINFOLDER set main tracking folder
            % takes 1 argument:
            % 1: path ('char')
            obj.MainFolder =     Value;

        end

        function obj =      load(obj)
            % LOAD load tracking data from file
             obj =      obj.loadBasic;
             obj =      obj.loadMasks;
         
        end
        
        function obj =      loadBasic(obj)
            % LOADBASIC loads all data, except mask pixels;
            
            tic
            load([obj.MainFolder, '/Main.mat'], 'MainTrackingInfo')
            a = toc;

            obj.TrackInfoList =             MainTrackingInfo.TrackInfoList;

            obj.ActiveTrackID =             MainTrackingInfo.ActiveState.ActiveTrackID ;
            obj.ActiveFrame =               MainTrackingInfo.ActiveState.ActiveFrame          ;

            obj.SelectedTrackIDs =          MainTrackingInfo.ActiveState.SelectedTrackIDs;
            obj.AutoTracking =              obj.AutoTracking.set(MainTrackingInfo.AutoTracking);

            BlankSegmentation =             obj.getBlankSegmentation;
            MyTrackingCellForTime = cell(length(MainTrackingInfo.TrackingCellForTime), 1);
            for index = 1 : length(MainTrackingInfo.TrackingCellForTime)
                    MyTrackingCellForTime{index, 1} =                                   num2cell(MainTrackingInfo.TrackingCellForTime{index});
                    MyTrackingCellForTime{index, 1}(:, obj.PixelColumn) =               BlankSegmentation(obj.PixelColumn);
                    MyTrackingCellForTime{index, 1}(:, obj.SegmentationTypeColumn) =    BlankSegmentation(obj.SegmentationTypeColumn);

            end

            obj.TrackingCellForTime = MyTrackingCellForTime;


            
        end

        function obj =      loadMasks(obj)

            try
                load(obj.getFileNameForStoringMaskData, 'MaskPixels')
                for index = 1 : length(MaskPixels)
                    MaskPixelsCurrentFrame = MaskPixels{index};

                    for indexMask = 1 : length(MaskPixelsCurrentFrame)

                        MaskOfCurrentTrack = MaskPixelsCurrentFrame{indexMask};

                        if isempty(MaskOfCurrentTrack)

                        else
                             obj.TrackingCellForTime{index, 1}{indexMask, obj.PixelColumn} = MaskOfCurrentTrack;
                        end


                    end

                end
                    
            catch
                warning('Loading of mask data failed.')

            end






          end

        function obj =      save(obj)
            % SAVE save basic and detailed track information (currently not supported);
            obj =   obj.saveBasic;
            obj =   obj.saveMasks;

        end

        function obj =      saveBasic(obj)
            % SAVEBASIC save "basic" data (does not save individual pixels of segment tracks, just centroids);

            fprintf('Saving of the basic tracking: ')
            MainTrackingInfo = obj.getStructureForStorage;

            if ~isempty(obj.TrackingCellForTime)
                  if exist(obj.MainFolder) ~=7
                        mkdir(obj.MainFolder) 
                  end

                  obj = obj.setTrackingCellForTimeCorrected;

                ExportCell =                                    cellfun(@(x) cell2mat(x(:, 1:5)), obj.TrackingCellForTime, 'UniformOutput', false);
                MainTrackingInfo.TrackingCellForTime =          ExportCell;
                tic
                save(obj.getFileNameForStoringBasicTrackingData, 'MainTrackingInfo')
                ElapsedTime = toc;

                fprintf('Saving of the basic tracking in file "%s" took %10.8f seconds.\n', obj.getFileNameForStoringBasicTrackingData, ElapsedTime)

            else
                fprintf('Nothing to save. No action taken.\n')

            end

        end
      
        function obj =      saveMasks(obj)
            % SAVEMASKS saves mask pixels;
            obj =      obj.saveBasic;

             fprintf('Saving of the basic tracking: ')

            if ~isempty(obj.TrackingCellForTime)
                  if exist(obj.MainFolder) ~=7
                        mkdir(obj.MainFolder) 
                  end

               MaskPixels = cellfun(@(x) x(:, obj.PixelColumn), obj.TrackingCellForTime, 'UniformOutput', false); 

                tic
                save(obj.getFileNameForStoringMaskData, 'MaskPixels')
                ElapsedTime = toc;

                fprintf('Saving of the basic tracking in file "%s" took %10.8f seconds.\n', obj.getFileNameForStoringMaskData, ElapsedTime)

            else
                fprintf('Nothing to save. No action taken.\n')

            end



        end

    end

    methods % BASIC SETTERS
        
        function obj =          performMethod(obj, Value, varargin)
            assert(ischar(Value), 'Wrong input.')
            obj = obj.(Value)(varargin{:}); 
        end
       
        function obj =          setActiveTrackID(obj, Value) % this may not be used?
             % SETACTIVETRACKID
            obj.ActiveTrackID =     Value;
        end

        function obj =          setActiveTrackIDTo(obj, newActiveTrackID) %when do you use setActiveTrackID a and when setActiveTrackIDTo?
            % SETACTIVETRACKIDTO sets track ID to input and does some housekeeping (e.g. remove from ID from selected tracks if it is a selected track at this time);
            
            assert(isnumeric(newActiveTrackID) && isscalar(newActiveTrackID), 'Wrong input.')

            oldActive =                 obj.ActiveTrackID;
            obj =                       obj.removeTrackIDsFromSelectedTracks(newActiveTrackID);
            obj.ActiveTrackID =         newActiveTrackID; 
            if newActiveTrackID ~= oldActive
                obj =                   obj.addToSelectedTrackIds(oldActive);
            end

            SelectedReal =              obj.removeTrackIdsThatDoNotExist(obj.SelectedTrackIDs);
            obj =                       obj.setSelectedTrackIdsTo(SelectedReal);

        end

        function obj =          setActiveFrameTo(obj,Value)
            % SETACTIVEFRAMETO set active frame to input;
            obj.ActiveFrame = Value;
        end
        
        function obj =          updateWith(obj, Value)
             % UPDATEWITH update state of object with input;
             % takes 1 argument:
             % 1: 'PMAutoTrackingView' or 'PMAutoCellRecognitionView';

            switch class(Value)

             case 'PMAutoTracking'
                obj.AutoTracking = Value;
        
            otherwise
                 error('Wrong input.')

            end


         end
        
        function obj =          removeRedundantData(obj)
            % REMOVEREDUNDANTDATA remove memory intensive redundant data (typically used before storing data in file);
            obj.TrackingCellForTimeWithDrift = obj.getEmptySegmentation;
            obj.TrackingAnalysis =              '';    
            obj.TrackImages =                   '';
            if ~isempty(obj.AutomatedCellRecognition)
                obj.AutomatedCellRecognition  = obj.AutomatedCellRecognition.removeRedundantData;

            end
        end
 
        function obj =          setAutomatedCellRecognition(obj, Value)
            % SETAUTOMATEDCELLRECOGNITION simply stores the the set  AutomatedCellRecognition object;
            % seems this is not in use right now
            obj.AutomatedCellRecognition = Value; 
        end
        
    end
    
    methods % SETTERS SELECTED TRACKS
        
        function obj =          selectAllTracks(obj)
            % SELECTALLTRACKS sets all tracks (except active track) as selected tracks;
            AllTrackIDs =       obj.getListWithAllUniqueTrackIDs;
            AllTrackIDs(AllTrackIDs == obj.ActiveTrackID, :) = [];
            obj =  obj.setSelectedTrackIdsTo(AllTrackIDs);
        end
        
        function obj =          setSelectedTrackIdsTo(obj, Numbers)
            % SETSELECTEDTRACKIDSTO set selected track IDs to input;
            obj.SelectedTrackIDs =      Numbers;
        end
        
        function obj =          addToSelectedTrackIds(obj, Value)
             % ADDTOSELECTEDTRACKIDS add input to selected tracks

            OldSelectedTrackIds =       obj.getIdsOfSelectedTracks;
            IdsIWantToAdd =             Value(:);
            NewSelectedTrackIds =       unique([ OldSelectedTrackIds; IdsIWantToAdd]);  
            NewSelectedTrackIds =       obj.removeTrackIdsThatDoNotExist(NewSelectedTrackIds); 
            obj =                       obj.setSelectedTrackIdsTo(NewSelectedTrackIds);

         end
        
    end
    
    methods % BASIC GETTERS
       
        function Value =                get(obj, Input, varargin)
            assert(ischar(Input), 'Wrong input.')
            MethodName = ['get', Input];
            Value = obj.(MethodName)(varargin{:});
            
        end
        
        function Value =                getTracksExist(obj)
            % GETTRACKSEXIST determines whether at least one track has been generated;
            % returns 1 value:
            % 1: logical scalar
           Value =  obj.testForExistenceOfTracks;
        end
        
        function exist =                testForExistenceOfTracks(obj)
            % TESTFOREXISTENCEOFTRACKS determines whether at least one track has been generated;
            % returns 1 value:
            % 1: logical scalar
            exist =              obj.getNumberOfTracks >= 2;
        end

        function numberOfTracks =       getNumberOfTracks(obj)
            % GETNUMBEROFTRACKS returns how many tracks have been created;
            % returns 1 value:
            % numerical scalar with number of tracks;
            ListWithAllUniqueTrackIDs =         obj.getListWithAllUniqueTrackIDs;
            if isempty(ListWithAllUniqueTrackIDs)
                numberOfTracks =        0;
            else
                numberOfTracks =        length(ListWithAllUniqueTrackIDs);
            end
        end
        
        function ActiveFrame =          getActiveFrame(obj)
            % GETACTIVEFRAME returns active frame
            ActiveFrame =           obj.ActiveFrame;
        end
        
        function Value =                getAutoTracking(obj)
           Value = obj.AutoTracking; 
        end

         function maxFrame =            getMaxFrame(obj)
            maxFrame = length(obj.getTrackingCellForTimeForFrames(NaN));

         end
        
         function value =               getAutoTrackingActiveGap(obj)
            % GETAUTOTRACKINGACTIVEGAP
                value = obj.AutoTrackingActiveGap;
           end
        
    end
    
    methods % GETTERS TRACKING-CELL TRACK IDs

        function trackID =              getIdOfActiveTrack(obj)
            % GETIDOFACTIVETRACK
            trackID =                 obj.ActiveTrackID;
         end

        function listWithIDs =          getListWithAllUniqueTrackIDs(obj)
            % GETLISTWITHALLUNIQUETRACKIDS returns list with IDs of all tracked cells;
            listWithIDs = find(cellfun(@(x) x.getExistenceOfSegmentationAddress, obj.TrackInfoList));

        end

        function RestingTrackIDs =      getIdsOfRestingTracks(obj)
            % GETIDSOFRESTINGTRACKS returns IDs of all tracks that are neither "active" nor "selected";
            UniqueTrackIDs =          obj.getListWithAllUniqueTrackIDs;
            NonRestingTracks =         [obj.ActiveTrackID; obj.getIdsOfSelectedTracks];
            RowsOfRestingTracks =      ~ismember(UniqueTrackIDs, NonRestingTracks);
            RestingTrackIDs =          UniqueTrackIDs(RowsOfRestingTracks);
        end

        function trackIDs =             getIdsOfSelectedTracks(obj)
            % GETIDSOFSELECTEDTRACKS returns all selected track IDs;
            trackIDs =           obj.SelectedTrackIDs;
        end

        function newTrackID =           getNewTrackID(obj)
            newTrackID = obj.generateNewTrackID;
        end

        function TrackID =              getIDOfFirstSelectedTrack(obj)
            % GETIDOFFIRSTSELECTEDTRACK
            if isempty(obj.SelectedTrackIDs)
                TrackID = NaN;
            else
                TrackID = obj.SelectedTrackIDs(1);
            end

        end

        function trackIDs =             getTrackIDsOfFrame(obj, FrameNumber)
          % GETTRACKIDSOFFRAME returns list of all track IDs for input frame-number;
            trackIDs =         obj.getTrackIDsFromSegmentationList(obj.getTrackingCellForTimeForFrames(FrameNumber));
        end
        
    end  
    
    methods % GETTERS SEGMENTATION LIST
        
        function values =               getFieldNamesOfTrackingCell(obj)
             % GETFIELDNAMESOFTRACKINGCELL get fieldnames of segmentation list;
                values = obj.FieldNamesForTrackingCell;
         end

        function TrackList =            getSortedTrackingData(obj, varargin)
                    % GETSORTEDTRACKINGDATA returns pooled segmentation-list sorted by track ID and time;
                    [TrackList, ~] =        obj.getPooledTrackingData;
                    EmptyRows =             max(cellfun(@(x) isempty(x) , TrackList(:,1)));
                    if isempty(EmptyRows)
                          TrackList =        obj.getEmptySegmentation;
                    else

                    NanRows =               cellfun(@(x) isnan(x), TrackList(:, 1));
                    TrackList(NanRows, :) = [];
                    TrackList=              sortrows(TrackList, [obj.TrackIDColumn obj.TimeColumn]);  

                    end

                    switch length(varargin)

                        case 0


                        case 1
                            assert(ischar(varargin{1}),'Wrong input.')
                            switch varargin{1}

                                case ''

                                case 'Masks'

                                    TrackList = TrackList(:, obj.PixelColumn);

                                otherwise
                                    error('Wrong input.')

                            end

                        otherwise
                            error('Wrong input.')


                    end
            

             end
        
        function Segmentation =         getSegmentationForTrackID(obj, TrackID, varargin)
            % GETSEGMENTATIONFORTRACKID returns segmentation for track ID;
            % takes 1 or 2 arguments:
            % 1: track ID (numeric scalar) or NaN;
            % 2: name of method (default: 'getTrackingSegmentationForFrameRowColumn');
            % returns 1 value:
            % segmentation list for all frames where wanted TrackID was successfully tracked;
            assert(isnumeric(TrackID) && isscalar(TrackID) , 'Wrong input.')
            switch length(varargin)
                case 0
                    MethodName = 'getTrackingSegmentationForFrameRowColumn';
                case 1
                    assert(ischar(varargin), 'Wrong input.')
                    MethodName = varargin{1};
                otherwise
                    error('Wrong input.')


            end

            if isnan(TrackID)
                Segmentation =          obj.getEmptySegmentation;

            elseif size(obj.TrackInfoList, 1) < TrackID
                error('Track id is not present in the TrackInfoList.')

            else
                    Address =           obj.TrackInfoList{TrackID,1}.getSegmentationAddress;

                    Segmentation =      arrayfun(@(x, y) ...
                                        obj.(MethodName)(x, y, NaN), ...
                                        Address(:, 1), Address(:, 2), 'UniformOutput', false);

                    Segmentation =      vertcat(Segmentation{:});
            end

        end
        
        function Segmentation =         getDriftCorrectedSegementationForTrackID(obj, TrackID)
            % GETDRIFTCORRECTEDSEGEMENTATIONFORTRACKID returns drift-corrected segmentation list for track ID;
            assert(isnumeric(TrackID) && isscalar(TrackID) && ~isnan(TrackID), 'Wrong input.')
            Segmentation =          obj.getDriftCorrectedSegmentationWithSegmentAddress(obj.TrackInfoList{TrackID,1}.getSegmentationAddress);
        end

        function segmentation =         getSegmentationOfFrame(obj, Frame)
            % GETSEGMENTATIONOFFRAME returns segmentation list for input frame;
            segmentation =             obj.getTrackingCellForTimeForFrames(Frame);  
            segmentation =             obj.removeNanTracksFromSegmentation(segmentation);

        end
        
        function Segmentation =         removeNanTracksFromSegmentation(obj, Segmentation)
            Segmentation(isnan(cell2mat(Segmentation(:, obj.TrackIDColumn))), :) = [];
        end
        
        function Segmentation =         getSegmentationForFramesTrackIDs(obj, Frames, WantedTrackIDs, Drift)
            % GETSEGMENTATIONFORFRAMESTRACKIDS returns segmentation list for input;
            % takes 3 arguments
            % 1: number of wanted frames
            % 2: wanted track IDs
            % 3: PMDriftCorrection object

            assert(isnumeric(Frames) && isscalar(Frames), 'Currently only scalars supported.')
            TrackIDsInWantedFrame =    obj.getTrackIDsFromSegmentationList(obj.getTrackingCellForTimeForFrames(Frames));
             Rows=                     ismember(TrackIDsInWantedFrame, WantedTrackIDs);

            if Drift.getDriftCorrectionActive
                Segmentation =             obj.getTrackingSegmentationWithDriftForFrameRowColumn(Frames, Rows, NaN);
            else
                Segmentation =             obj.getTrackingSegmentationForFrameRowColumn(Frames, Rows, NaN);
            end


         end

        function Coordinates =          getSelectedMasksAtFramePlaneDrift(obj, Frame, Plane, Drift)
            % GETSELECTEDMASKSATFRAMEPLANEDRIFT returns coordinates of masks for input;
            % takes 3 arguments
            % 1: wanted frame number
            % 2: wanted plane numbers
            % 3: PMDriftCorrection object
            selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frame, Drift);
            selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, obj.SelectedTrackIDs);

            InputPixels =                  selectedSegmentation(:,obj.PixelColumn);

            selectedSegmentation(:, obj.PixelColumn) =          cellfun(@(x) obj.filterPixelListForPlane(x, Plane),InputPixels , 'UniformOutput', false);

            RowsWithEmptyPixels =           obj.getRowsOfTracksWithEmptyPixels(selectedSegmentation);
            selectedSegmentation(RowsWithEmptyPixels, :) = [];

            Coordinates =                   obj.extractMasksFromTrackList(selectedSegmentation);
        end
               
        function framesPerTrack =       getListOfAllFramesForTrackIDs(obj, ListWithTrackIDs)
            % GETLISTOFALLFRAMESFORTRACKIDS returns frame numbers for input track-IDs;
            % returns cell array: each cell is for a frame and contains numerical vector with all frames of input trackIDs;
            AddressesPerTrack =         arrayfun(@(x) obj.TrackInfoList{x, 1}.getSegmentationAddress, ListWithTrackIDs, 'UniformOutput', false);

            MyTrackingCellForTime         = obj.getTrackingCellForTimeForFrames(NaN);
            FrameSeries =               cellfun(@(x) obj.extractFramesFromTrackList(x), MyTrackingCellForTime, 'UniformOutput', false);
            framesPerTrack =            cellfun(@(x) obj.getContentWithAddresses(FrameSeries, x), AddressesPerTrack, 'UniformOutput', false);
        end
        
        function Content =              getContentWithAddresses(~, ContentSeries, Addresses)
               % GETCONTENTWITHADDRESSES extract content bz addresses
               % takes 2 argumentsÖ
               % 1: "content"
               % 2: address list
               % goes through each address and obtains content at frame/row

               Content = zeros(size(Addresses, 1), 1);
               for Index = 1 : size(Addresses, 1)
                   Content(Index, 1) = ContentSeries{Addresses(Index, 1)}(Addresses(Index, 2));
               end


          end
        
        function TrackIDsToRemove =     getAllTrackIDsWithLessFramesThan(obj, FrameNumberLimit)
            AllTrackIDs =               obj.getListWithAllUniqueTrackIDs;
            FramesPerTrack =            obj.getListOfAllFramesForTrackIDs(AllTrackIDs);
            NumberOfFramesPerTrack =    obj.getNumberOfFramesPerTrack(FramesPerTrack);
            SelectedRows =              NumberOfFramesPerTrack < FrameNumberLimit;
            TrackIDsToRemove =          AllTrackIDs(SelectedRows);
        end
           
        function numberOfFrames =       getNumberOfFramesPerTrack(obj,FrameLists)
             numberOfFrames =      cellfun(@(x) length(x)   , FrameLists);   
         end
         
        function ConciseList =          getConciseObjectListOfFrame(obj, FrameNumber)
            % GETCONCISEOBJECTLISTOFFRAME returns "concises" segmentation list for input frame;
            % show number of pixels instead of actual pixel values and use string-descriptor instead of segmentation object;
             if isempty(FrameNumber)
                 ConciseList =          obj.getEmptySegmentation;
             else
                 List =                 obj.removeNanTracksFromSegmentation(obj.getTrackingCellForTimeForFrames(FrameNumber));
                 ConciseList =          obj.convertObjectListIntoConciseObjectList(List);
             end
        end

        function PooledSegmentation =   getPooledSegmentation(obj)
            error('Use getPooledTrackingData instead of getPooledSegmentation.')
        end
        
         function list =  getTrackSummaryList(obj)
            list = obj.getTrackSummaryListInternal;
         end
        

    end
    
    methods % GETTERS SEGMENTATION LIST: PROCESSED CONTENTS:
       
          function Coordinates = getCoordinatesForActiveTrackPlanes(obj,  Planes, varargin)
             % GETCOORDINATESFORACTIVETRACKPLANES returns coordinates for active track;
            % takes 1 or 2 arguments:
            % 1: vector with required planes
            % 2: PMDriftCorrection object
            % returns 1 value:
            % numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;   
            % out of plane-range coordinates are replaced with NaN;
             Coordinates =       obj.getCoordinatesForTrackIDsInternal(obj.ActiveTrackID, Planes,  varargin{:});
             Coordinates = Coordinates{1};
        end
        
        function Coordinates = getCoordinatesForTrackIDsPlanes(obj, TrackIDs, Planes, varargin)
            % GETCOORDINATESFORTRACKIDSPLANES returns coordinates for specified track IDs and planes;
            % takes 2 or 3 arguments:
            % 1: vector with wanted track IDs
            % 2: vector with required planes
            % 3: PMDriftCorrection object
            % returns 1 value:
            % cell array:   one cell contains coordinates for each track:
            %               each cell contains numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;    
            Coordinates =       obj.getCoordinatesForTrackIDsInternal(TrackIDs, Planes,  varargin{:});
        end
        
    end
    
    methods % GETTERS SEGMENTATIONLIST: ACTIVE TRACK
      
        function segmentation =         getActiveTrack(obj)
              % GETACTIVETRACK returns segmentation list of active track;
            segmentation = obj.getSegementationForActiveTrack;
            
          end
        
        function Segmentation =         getSegmentationOfActiveTrack(obj)
            % GETSEGMENTATIONOFACTIVETRACK returns segmentation list of active track;
            
            if isnan(obj.ActiveTrackID)
                Segmentation =      obj.getEmptySegmentation;
            else
                  Address =           obj.TrackInfoList{obj.ActiveTrackID, 1}.getSegmentationAddress;

                  if isempty(Address)
                      Segmentation =      obj.getEmptySegmentation;
                  else
                       Segmentation =      arrayfun(@(x, y) ...
                                        obj.getTrackingSegmentationForFrameRowColumn(x, y, NaN), ...
                                        Address(:, 1), Address(:, 2), 'UniformOutput', false);

                  end



            end

        end
   
        function segmentation =         getActiveSegmentationForFrames(obj, Value)
        % GETACTIVESEGMENTATIONFORFRAMES returns segmentation of active track filtered for input frame;
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            if isempty(obj.TrackingCellForTime)
                
                 segmentation =        obj.getEmptySegmentation;
                 
            elseif length(obj.TrackingCellForTime) < Value
                segmentation =        obj.getEmptySegmentation;
            else
                SegmentationOfSelectedFrame =   obj.TrackingCellForTime{Value};  
                segmentation =                  obj.filterSegementationListForSelectedTracks(SegmentationOfSelectedFrame, obj.ActiveTrackID);

            end
            
            
           
        end

        function segmentation =         getActiveSegmentationForFramesAndPlanesWithDriftCorrection(obj, Frames, Planes, DriftCorrection)
            % GETACTIVESEGMENTATIONFORFRAMESANDPLANESWITHDRIFTCORRECTION returns segmentation list for input;
            % takes 3 arguments:
            % 1: number of wanted frame
            % 2: wanted frames
            % 3: drift-correction object
            segmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frames, DriftCorrection);
            segmentation =          obj.filterSegementationListForSelectedTracks(segmentation, obj.ActiveTrackID);
            segmentation =          obj.filterSegmentationListForPlanes(segmentation, Planes);
        end

    end
    
    methods % GETTERS SEGMENTATIONLIST: ACTIVE TRACK, PROCESSED CONTENTS;
        
        function coordinates =          getCoordinatesOfActiveTrackForFrame(obj, Frame)
            % GETCOORDINATESOFACTIVETRACKFORFRAME returns coordinate list of active track for frame;
             List =             obj.getTrackingCellForTimeForFrames(Frame);
             FilteredList =     obj.filterSegementationListForSelectedTracks(List, obj.ActiveTrackID);
             coordinates =      obj.extractCoordinatesFromTrackList(FilteredList);

        end
        
        function Coordinates =          getActiveCentroidAtFramePlaneDrift(obj, Frame, Plane, Drift)
            % GETACTIVECENTROIDATFRAMEPLANEDRIFT get centroid of active track for input;
            % takes 3 arguments:
            % 1: frame number
            % 2: plane range
            % 3: drift-correction object
            Segmentation =      obj.getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(Frame,Plane, obj.ActiveTrackID, Drift);
            Coordinates =       obj.extractCoordinatesFromTrackList(Segmentation);

        end
        
        function plane =                getPlaneOfActiveTrackForFrame(obj, Frame)
            % GETPLANEOFACTIVETRACKFORFRAME returns planes of active track for frame;
             List = obj.getTrackingCellForTimeForFrames(Frame);
             FilteredList = obj.filterSegementationListForSelectedTracks(List, obj.ActiveTrackID);
            plane =  obj.getZCoordinatesFromSegementationList(FilteredList);
            if isempty(plane)
                plane = NaN;
            end

        end 

        function pixelList =            getPixelsOfActiveTrackForFrames(obj, Frame)
             % GETPIXELSOFACTIVEMASKFROMFRAME returns pixels of active track for input frame;
             % returns 1 value:
             % 1: numerical matrix with 3 columns (one for each dimension);
                wantedRow =      obj.getRowInSegmentationForFrameTrackID(Frame, obj.ActiveTrackID);
                if isempty(wantedRow)
                    segmentationOfActiveMask =        obj.getEmptySegmentation;
                else
                    segmentationOfActiveMask =  obj.getTrackingSegmentationForFrameRowColumn(Frame, wantedRow, NaN);
                end

                 if isempty(segmentationOfActiveMask)
                     pixelList =        zeros(0, 3);
                 else
                     pixelList =       segmentationOfActiveMask{1, obj.PixelColumn};
                 end  
           end

        function Coordinates =          getActiveMasksAtFramePlaneDrift(obj, Frame, Plane, Drift)
            % GETACTIVEMASKSATFRAMEPLANEDRIFT returns coordinates of active track for input;
            % 1: wanted frame
            % 2: wanted plane
            % 3: drift-correction

            selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frame, Drift);
            selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, obj.ActiveTrackID);
            InputPixels =                   selectedSegmentation(:,obj.PixelColumn);

            selectedSegmentation(:, obj.PixelColumn) =          cellfun(@(x) obj.filterPixelListForPlane(x, Plane),InputPixels , 'UniformOutput', false);

            RowsWithEmptyPixels =           obj.getRowsOfTracksWithEmptyPixels(selectedSegmentation);
            selectedSegmentation(RowsWithEmptyPixels, :) = [];

            Coordinates =                   obj.extractMasksFromTrackList(selectedSegmentation);
            
        end
         

    end
    
    methods % GETTERS SEGMENTATIONLIST: CONCISE LIST;
       
        function ConciseList=               getConciseObjectListOfActiveTrack(obj)
            % GETCONCISEOBJECTLISTOFACTIVETRACK get "concise" segmentation list of active track;
            % show number of pixels instead of actual pixel values and use string-descriptor instead of segmentation object;
            ConciseList =       obj.convertObjectListIntoConciseObjectList(obj.getSegmentationOfActiveTrack);
        end
        
        function CurrentFrameList =         convertObjectListIntoConciseObjectList(obj, CurrentFrameList)
            % CONVERTOBJECTLISTINTOCONCISEOBJECTLIST takes "normal" segmentation-list and converts into "concise" segmenation-list and returns this modified list;
            % main difference: pixel-column shows number pixels (rather than list of all pixels);
            % also does not have segmentatin-type object in segmentation column (but a descriptor, typically a 'char');
            if isempty(CurrentFrameList)
                CurrentFrameList =    obj.getEmptySegmentation;
                else

                for index = 1 : length(CurrentFrameList)

                    CurrentFrameInfo =                                              CurrentFrameList{index};
                    assert(size(CurrentFrameInfo, 1) == 1, 'Wrong input.')

                    MyPixels =                                                      CurrentFrameInfo{1,obj.PixelColumn};
                    CurrentFrameList{index}(:,obj.PixelColumn) =                    num2cell( size(MyPixels, 1));
                    CurrentFrameList{index}(:, obj.SegmentationTypeColumn) =        obj.extractSegmentationTypeFromList(CurrentFrameInfo(:, obj.SegmentationTypeColumn));

                end

                CurrentFrameList = vertcat(CurrentFrameList{:});

            end


        end
        
        function SegmentationTypeList =     extractSegmentationTypeFromList(~, List)

            try
                SegmentationTypeList =                 cellfun(@(x) x.SegmentationType, List, 'UniformOutput', false);
            catch
                SegmentationTypeList =                 cellfun(@(x) x.getSegmentationType, List, 'UniformOutput', false);
            end

             RowsWithSegmentationCapture =                            cellfun(@(x) strcmp(class(x), 'PMSegmentationCapture'), SegmentationTypeList);
             SegmentationTypeList(RowsWithSegmentationCapture,:) =    cellfun(@(x) x.getSegmentationType, SegmentationTypeList(RowsWithSegmentationCapture,:), 'UniformOutput', false);

             EmptyRows =                                    cellfun(@(x) isempty(x), SegmentationTypeList);
             SegmentationTypeList(EmptyRows,:) =        {'Not specified'};


        end
    
    end
    
    methods % GETTERS SEGMENTATIONLIST: SELECTED TRACKS

        function Coordinates =              getSelectedCentroidsAtFramePlaneDrift(obj, Frame, Plane, Drift, varargin)
            % GETSELECTEDCENTROIDSATFRAMEPLANEDRIFT returns centroid-coordinate for selected track IDs;
            % takes 3 or more arguments:
            % 1: wanted frame;
            % 2: wanted planes;
            % 3: drift-correction object
            % 4: 'OnlyCenter';
            Segmentation =      obj.getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(Frame, Plane, obj.SelectedTrackIDs, Drift, varargin{:});
            Coordinates =       obj.extractCoordinatesFromTrackList(Segmentation);
        end

        function selectedSegmentation =     getSelectedSegmentationForFramesPlanesDriftCorrection(obj, Frames, Planes, DriftCorrection)
            % GETSELECTEDSEGMENTATIONFORFRAMESPLANESDRIFTCORRECTION returns segmentation list of selected tracks for input;
            % takes 3 arguments:
            % 1: wanted frame;
            % 2: wanted planes;
            % 3: drift-correction object
            selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frames, DriftCorrection);
            selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, obj.SelectedTrackIDs);
            selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes);


        end

    end
     
    methods % PROCESS SEGMENTATION DATA: gets segmentation list as input, and returns pertinent value;
        
        function [SegmentationData] =           getMiniMask(obj, SegmentationData)
        % GETMINIMASK converts segmentation data with "normal" masks into segmentation data with "mini-masks";
        % mini masks have just one point;
        % takes 1 argument:
        % 1: segmentation list
        % returns 1 value:
        % 1: segmentation list
        MiniCoordinateList(:,1) =    arrayfun(@(x) [round(SegmentationData{1,obj.CentroidXColumn}), round(SegmentationData{1,obj.CentroidXColumn}), x], min(SegmentationData{1,obj.PixelColumn}(:,3)):max(SegmentationData{1,obj.PixelColumn}(:,3)), 'UniformOutput',false); 
        MiniCoordinateList =         vertcat(MiniCoordinateList{:});
        assert(~isempty(MiniCoordinateList), 'Cannot corrupt database with empty coordinate list')
        SegmentationData{1,obj.PixelColumn} =        MiniCoordinateList;
        end

        function [FrameNumber, RowNumber ] =    getFrameAndRowInTrackTimeCellForMask(obj, Mask)
            % GETFRAMEANDROWINTRACKTIMECELLFORMASK gets location in tracking cell matrix for segmentation nput;
            % takes 1 argument:
            % 1: segmentation matrix
            % returns 2 values:
            % 1: frame-number
            % 2: row-number

            assert(size(Mask,1) == 1, 'This function only accepts a single mask as input.')
            FrameNumber =                   Mask{1,obj.TimeColumn};
            MyTrackingCellForTime  =        obj.getTrackingCellForTimeForFrames(FrameNumber);
            RowNumber =                     cell2mat(MyTrackingCellForTime(:,obj.TrackIDColumn)) ==  Mask{1,obj.TrackIDColumn};
            WarningText =                   sprintf('The data file or input is corrupt. There are %i repeats of track %i in frame %i. There should be 1 precisely', sum(RowNumber),  Mask{1,obj.TrackIDColumn}, FrameNumber);
            assert(sum(RowNumber) == 1, WarningText)

        end

        function [filteredList]=                filterSegmentationListForFrames(obj, List, WantedFrames)
        % FILTERSEGMENTATIONLISTFORFRAMES filters a segmentation list by specified frame-numbers;
        % takes 2 arguments:
        % 1: segmentation list
        % 1: list with wanted frames
        % returns 1 value:
        % 1: segmentation list (after removal of unwanted frames);
        AvailableFrames =       cell2mat(List(:, obj.TimeColumn));
        MatchingRows =          ismember(AvailableFrames, WantedFrames);
        filteredList =          List(MatchingRows,:);
        end

        function filteredList =                 filterMatrixByFirstColumnForValues(~, Matrix, Values)
        % FILTERMATRIXBYFIRSTCOLUMNFORVALUES filters input matrix by specified values;
        % takes 2 arguments:
        % 1: matrix
        % 2: list of values for which to filter
        % returns 1 value:
        % filtered matrix
        MatchingRows =      ismember(Matrix(:, 1), Values);
        filteredList =        Matrix(MatchingRows,:);
        end

        function coordinates =      extractCoordinatesFromTrackingCell(obj, TrackingCell)
           coordinates = cellfun(@(x) ...
            cell2mat(x(:, [obj.CentroidYColumn, obj.CentroidXColumn, obj.CentroidZColumn])), TrackingCell,...
            'UniformOutput', false);

        end
        
        
    end
    
    methods % SETTERS IMAGES
       
           function obj = setTrackImages(obj)
               % SETTRACKIMAGES sets TrackImages property
               % set "TrackImages" for all frames

                for Index = 1 : obj.getMaxFrame
                    obj = obj.updateTrackingImageForFrame(Index);
                end
                
            end

           function obj = updateTrackingImageForFrame(obj, Frame)
                % UPDATETRACKINGIMAGEFORFRAME sets TrackImages (images that show shapes of all segmented cells for input frame;
                MySegmentation =          obj.getSegmentationOfFrame(Frame);
                Coordinates =             obj.extractMasksFromTrackList(MySegmentation);
                myShape =                 PMShape(Coordinates);
                Image =                   myShape.getRawImageVolume;
                figure(1000)
                imagesc(max(Image, [], 3))

                Y = size(Image, 1);
                X= size(Image,2 );
                Z= size(Image, 3);
                obj.TrackImages(1:Y, 1:X, 1:Z) =         Image;

            end       
        
    end

    methods % TRACKINGANALYSIS
       
         function obj =     setTrackingAnalysis(obj, Value)
             % SETTRACKINGANALYSIS set PMTrackingAnalysis
             % takes 1 argument:
             % 1: scalar of 'PMTrackingAnalysis';
            obj.TrackingAnalysis = Value;
         end
         
         function Value =   getTrackingAnalysis(obj)
             % GETTRACKINGANALYSIS get PMTrackingAnalysis
             Value =    obj.TrackingAnalysis;
         end
        
    end
    
    methods % SETTERS TRACKINFOLIST
        
          function obj =      generalCleanup(obj)
            % GENERALCLEANUP cleans up tracking-info and segmentation addresses;
            % orders tracks in info list, adds missing IDs to info-list, resets segmentation addresses for all tracked information;
            obj =           obj.reorderTrackInfoList; % orders track-info list by track ID;
            obj =           obj.addMissingTrackIdsToTrackInfoList; %makes sure each possible trackID has an entry in info-list;
            obj =           obj.addSegmentationAddressToAllTrackInfos; % resets addreses for all tracks
            %                obj =           obj.setTrackImages;

        end
        
        
    end
    
    methods % SETTERS TRACKINGCELLFORTIME: ADD SEGMENTATION DELETE TRACKS;

        function obj =      addSegmentation(obj, SegmentationCapture)
        % ADDSEGMENTATION: add new tracking content to object:
        % takes one argument:
        % 1: scalar of PMSegmentationCapture;
        % Segmentation capture is added to active trackID
        % methods also updates segmentation-address of active track ID
            assert(isscalar(SegmentationCapture) && isa(SegmentationCapture, 'PMSegmentationCapture'), 'Wrong input.')
            obj =       obj.setEntryInTrackingCellForTime(SegmentationCapture);
            obj =       obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID);
        end

        function obj =      minimizeMasksOfActiveTrackAtFrame(obj, FrameNumber)
            % MINIMIZEACTIVETRACK "minimizes" masks of active track at specified frame to one point ;
            % takes 1 argument:
            % 1: number frame that should be minimized;

            MySeg =                 obj.getSegmentationForTrackID(obj.getIdOfActiveTrack);
            MiniSeg =               obj.getMiniMask(MySeg);
            MiniSeg =               obj.filterSegmentationListForFrames(MiniSeg, FrameNumber);

            MyDriftSeg =            obj.getSegmentationForTrackID(obj.getIdOfActiveTrack, 'getTrackingSegmentationWithDriftForFrameRowColumn');
            MiniSegWithDrift =      obj.getMiniMask(MyDriftSeg);
            MiniSegWithDrift =      obj.filterSegmentationListForFrames(MiniSegWithDrift, FrameNumber);

            obj =                    obj.replaceMaskInTrackingCellForTimeWith(MiniSeg, MiniSegWithDrift);
        end
        
        function obj =      removeTracksIfPixelNumberLessThan(obj, PixelNumber)
            % REMOVETRACKSIFPIXELNUMBERLESSTHAN removes all masks with pixels below limit;
            % takes 1 argument:
            % 1: numeric scalar

             MyTrackingCellForTime         =    obj.getTrackingCellForTimeForFrames(obj.ActiveFrame);

             Pixels =                   MyTrackingCellForTime(:, obj.PixelColumn);
             IndicesToDelete =          cellfun(@(x) size(x, 1) < PixelNumber, Pixels);
             TrackIDs =                 cell2mat(MyTrackingCellForTime(:, obj.TrackIDColumn));
             TrackIDsToRemove =         TrackIDs(IndicesToDelete);

               TrackIDsToRemove(isnan(TrackIDsToRemove)) = [];

                for Index = 1: length(TrackIDsToRemove)
                    obj =       obj.removeTrack(TrackIDsToRemove(Index));
                end

        end

        function obj =      removeTrackWithFramesLessThan(obj, FrameNumberLimit)
        % REMOVETRACKWITHFRAMESLESSTHAN remove all tracks with less frames than input;
        % takes 1 argument:
        % 1: numeric scalar
        assert(isnumeric(FrameNumberLimit) && isscalar(FrameNumberLimit), 'Wrong input.')

        fprintf('\nDeleting tracks with %i or less frames:\nDeleting track ', FrameNumberLimit)

        NumberBeforeDeletion =      obj.getNumberOfTracks;
        TrackIDsToRemove =          obj.getAllTrackIDsWithLessFramesThan(FrameNumberLimit);
        for Index = 1: length(TrackIDsToRemove)
            obj =       obj.removeTrack(TrackIDsToRemove(Index));
        end
        fprintf('\nBefore deletion: %i tracks. After deletion: %i tracks\n\n', NumberBeforeDeletion, obj.getNumberOfTracks);

        end

        function obj =      deleteAllSelectedTracks(obj)
            % DELETEALLSELECTEDTRACKS deletes all selected tracks
            obj =                    obj.removeTrack(obj.getIdsOfSelectedTracks);

            Selected = obj.getIdsOfSelectedTracks;
            for index = 1 : length(Selected)
                obj =               obj.updateSegmentationAddressInTrackInfoListForIDs(Selected(index));
            end

            obj.SelectedTrackIDs =   zeros(0,1);
        end
        
        function obj =      removeTrack(obj, trackID)
            % REMOVETRACK remove track with input;
            assert(isnumeric(trackID) && isvector(trackID) , 'Wrong input.')

            for Index = 1 : length(trackID)
                OldTrackID =                    trackID(Index);
                AddressOfTargetTrack =          obj.TrackInfoList{OldTrackID, 1}.getSegmentationAddress;
                obj =                           obj.setTargetAddressWithTrackID(AddressOfTargetTrack, NaN);
                obj =                           obj.updateSegmentationAddressInTrackInfoListForIDs(OldTrackID);

            end

            obj =           obj.setActiveTrackID(obj.getIDOfFirstSelectedTrack);

        end

        function obj =      deleteActiveMask(obj)
        % DELETEACTIVEMASK remove active mask (active track ID and active Frame);
        obj =          obj.removeMask(obj.ActiveTrackID, obj.ActiveFrame);
        obj =           obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID);

        end

        function obj =      removeMask(obj, TrackID, CurrentFrame)
                obj =       obj.setTrackForFrameTrackIDWithMasks(CurrentFrame, TrackID, NaN, obj.getBlankSegmentation); 
                obj =           obj.updateSegmentationAddressInTrackInfoListForIDs(TrackID);
        end
   
    end
    
    methods % SETTERS TRACKINGCELLFORTIME: setTrackingCellForTimeWithDriftByDriftCorrection;
       
        function obj =              setTrackingCellForTimeWithDriftByDriftCorrection(obj, DriftCorrection)
            % SETTRACKINGCELLFORTIMEWITHDRIFTBYDRIFTCORRECTION: it seems there is something wrong with this method: check;
            fprintf('Adding drift correction:')
            obj.TrackingCellForTimeWithDrift =  obj.getTrackingCellForTimeForFrames(NaN);

            MaximumTrackedFrame =               obj.getMaxFrame;
            assert(MaximumTrackedFrame <= DriftCorrection.getNumberOfFrames, 'Drift correction does not span tracking range.')

            tic
            coordinates =                   obj.extractCoordinatesFromTrackingCell(obj.TrackingCellForTimeWithDrift);
            UpdatedCoordinates =            obj.updateCoordinatesWithDriftCoorection(coordinates, DriftCorrection);
            obj =                           obj.applyCoordinatesToTrackingCellForTimeWithDrift(UpdatedCoordinates);

            fprintf(' %6.2f seconds.\n', toc)
        end

        function coordinates =              updateCoordinatesWithDriftCoorection(obj, coordinates, DriftCorrection)
            rowShifts =         DriftCorrection.getRowShifts;
            columnShifts=       DriftCorrection.getColumnShifts;
            planeShifts =       DriftCorrection.getPlaneShifts;

            for index = 1 : length(coordinates)

              coordinates{index}(:,1) = coordinates{index}(:,1) + rowShifts(index);
              coordinates{index}(:,2) = coordinates{index}(:,2) + columnShifts(index);
              coordinates{index}(:,2) = coordinates{index}(:,2) + planeShifts(index);

            end 
            
            
          
            
        end
        
        function obj =                      applyCoordinatesToTrackingCellForTimeWithDrift(obj, coordinates)
           
                for index = 1 : length(coordinates)
                 
                     obj.TrackingCellForTimeWithDrift{index}(:, obj.CentroidYColumn) = num2cell(coordinates{index}(:,1));
                     obj.TrackingCellForTimeWithDrift{index}(:, obj.CentroidXColumn) = num2cell(coordinates{index}(:,2));
                     obj.TrackingCellForTimeWithDrift{index}(:, obj.CentroidZColumn) = num2cell(coordinates{index}(:,3));

                 
             end
            
        end
        
    end
    
    methods % SETTERS ACTIVE TRACK: DELETE TRACK SEGMENTS, SPLIT, FILL;

        function obj =          deleteActiveTrackBeforeFrame(obj, SplitFrame)
            % DELETEACTIVETRACKBEFOREFRAME deletes all frame of active track, when frame number is lower than split frame;
            % takes 1 argument:
            % 1: split-frame
            obj = deleteActiveTrackBeforeFrameInternal(obj, SplitFrame);
        end

        function obj =          deleteActiveTrackAfterFrame(obj, SplitFrame)
            % DELETEACTIVETRACKAFTERFRAME deletes all frame of active track, when frame number is higher than split frame;
            % takes 1 argument:
            % 1: split-frame
            obj = obj.deleteActiveTrackAfterFrameInternal(SplitFrame);
        end

        function obj =          splitActiveTrackAtFrame(obj, Frame)
            % SPLITACTIVETRACKATFRAME keep active track until specified frame, all higher frame numbers will get a new track ID;
            % takes 1 argument:
            % 1: split-frame
            obj =            obj.splitTrackAtFrame(Frame, obj.ActiveTrackID, obj.generateNewTrackID);
        end

        function obj =          fillGapsOfActiveTrack(obj)
            % FILLGAPSOFACTIVETRACK fill first gap of active track with "interpolated" centroids;
            try 

                Limits =                obj.getLimitsOfFirstGapOfActiveTrackForLimitValue(NaN);
                preMask =               PMMask(obj.getActiveSegmentationForFrames(Limits(1) - 1));
                postMask =              PMMask(obj.getActiveSegmentationForFrames(Limits(2) + 1));

                Results =     obj.AutoTracking.setSegmentationCaptureListBetweenMasks(preMask, postMask);

                obj =                              obj.addSegmentationCaptureList(...
                Results, ...
                obj.AutoTracking.getFramesThatRequireClosing(preMask, postMask),  ...
                obj.AutoTracking.getActiveTrackID);

                obj =           obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID);


            catch ME
               throw(ME) 
            end
        end

    end
    
    methods % GETTERS TRACKINGCELLFORTIME: FRAMES AND FRAME-GAPS ;

            function frames =                           getFramesOfActiveTrack(obj)
                % GETFRAMESOFACTIVETRACK returns list of tracked frames for active track ID;
                % returns 1 value:
                % numerical vector
                frames =        obj.getListOfAllFramesForTrackIDs(obj.ActiveTrackID);
                frames=         frames{1};
            end

            function FrameNumbers =                     getFrameNumbersForTrackID(obj, TrackID)
                % GETFRAMENUMBERSFORTRACKID returns list with frame numbers for input track-ID;
                Segmentation = obj.getSegmentationForTrackID(TrackID);
                FrameNumbers = obj.extractFramesFromTrackList(Segmentation);
            end
            
            function FrameNumbers =         extractFramesFromTrackList(obj, TrackList) 
                % EXTRACTFRAMESFROMTRACKLIST 
                % takes 1 argument:
                % 1: SegmentationList
                % returns numerical vector that containsframe numbers 
                if isempty(TrackList)
                    FrameNumbers =       NaN;
                    else
                    FrameNumbers =        cell2mat( TrackList(:, obj.TimeColumn));  
                end

            end

        

            function Limits =                           getLimitsOfFirstGapOfActiveTrackForLimitValue(obj, Value)
                  % GETLIMITSOFFIRSTGAPOFACTIVETRACKFORLIMITVALUE returns limits of of first gap of active active tracks;
                    Limits =      PMVector(obj.getFrameNumbersForTrackID(obj.ActiveTrackID)).getLimitsOfFirstForwardGapForLimitValue(  Value);
            end

            function [Limits, ListWithTrackIDs] =       getLimitsOfFirstForwardGapOfAllTracksForLimitValue(obj, Value)
                % GETLIMITSOFFIRSTFORWARDGAPOFALLTRACKSFORLIMITVALUE returns ranges of first gap of all tracks (with gaps);
                % takes 1 argument:
                % this is typically the last frame of the entire movie (otherwise impossible to characterize "gaps" at the end of each track;
                % returns 2 values:
                % 1: cell array that contains gap range of each track;
                % 2: numerical vector that contains track IDs of returned tracks;
                [ListWithFrames, ListWithTrackIDs]=         obj.getFramesOfEachTrack;
                Limits =                    cellfun(@(x) PMVector(x).getLimitsOfFirstForwardGapForLimitValue(  Value), ListWithFrames, 'UniformOutput', false);
                EmptyRows =                 cellfun(@(x) isempty(x), Limits);
                Limits(EmptyRows, :) =      [];
                ListWithTrackIDs(EmptyRows, :) =    [];
            end
            
            function [frames, TrackIDs] =               getFramesOfEachTrack(obj)
                % GETFRAMESOFEACHTRACK returns list of tracked frames of each track;
                % returns 2 values:
                % 1: cell array that contains value of each tracked frame;
                % 2: numerical vector that contains track IDs of returned tracks;
                TrackIDs  =  obj.getListWithAllUniqueTrackIDs;
                frames =    arrayfun(@(x) obj.getFrameNumbersForTrackID(x), TrackIDs, 'UniformOutput', false);

            end
            
            function [LimitsOfEachTrack, TrackIds] =    getLimitsOfSurroundedFirstForwardGapOfAllTracks(obj)
                % GETLIMITSOFSURROUNDEDFIRSTFORWARDGAPOFALLTRACKS
                % returns 2 values:
                % 1: limits cell array with numerical of 2 each: vector contains start and end-frame of each gap;
                % 2: list with all track IDs that have IDs (corresponding to 1);
                [Frames, TrackIds]=     obj.getFramesOfEachTrack;
                LimitsOfEachTrack =                cellfun(@(x) PMVector(x).getLimitsOfSurroundedFirstForwardGap, Frames, 'UniformOutput', false);
                EmptyRows =             cellfun(@(x) isempty(x), LimitsOfEachTrack);
                LimitsOfEachTrack(EmptyRows, :) =  [];
                TrackIds(EmptyRows, :) = [];
            end

            function [ListWithGapLimitsOfEachTrack, TrackIds] =  getLimitsOfFirstGapOfAllTracksForLimitValue(obj, Value)
                % GETLIMITSOFFIRSTGAPOFALLTRACKSFORLIMITVALUE % takes 1 argument:
                % this is typically the last frame of the entire movie ;
                % returns 2 values:
                % 1: cell array that contains gap range of each track;
                % 2: numerical vector that contains track IDs of returned tracks;
                [Frames, TrackIds]=                                 obj.getFramesOfEachTrack;
                ListWithGapLimitsOfEachTrack =                      cellfun(@(x) PMVector(x).getLimitsOfFirstForwardGapForLimitValue(  Value), Frames, 'UniformOutput', false);
                EmptyRows =                                         cellfun(@(x) isempty(x), ListWithGapLimitsOfEachTrack);
                ListWithGapLimitsOfEachTrack(EmptyRows, :) =        [];
                TrackIds(EmptyRows, :) =                            [];

            end

            function [Limits, TrackIds] =               getLimitsOfFirstBackwardGapOfAllTracksForLimitValue(obj, Value)
                 % GETLIMITSOFFIRSTBACKWARDGAPOFALLTRACKSFORLIMITVALUE % takes 1 argument:
                % this is typically the last frame of the entire movie (this argument may not be used at the current verion);
                % returns 2 values:
                % 1: cell array that contains gap range of each track; if the first gap is between frame 11 and 15, for example, will return range 15 to 11;
                % 2: numerical vector that contains track IDs of returned tracks;
                [Frames, TrackIds]=         obj.getFramesOfEachTrack;
                Limits =                    cellfun(@(x) PMVector(x).getLimitsOfFirstBackwardGapForLimitValue(  Value), Frames, 'UniformOutput', false);
                EmptyRows =                 cellfun(@(x) isempty(x), Limits);
                Limits(EmptyRows, :) =      [];
                TrackIds(EmptyRows, :) =    [];

            end
            
    end
   
    methods % PROCESS: GET TRACK NUMBERS AND RETURN PROCESSED TRACK NUMBERS;

        function [TrackId, Position] =          selectTrackIdForTogglingFromList(obj, TrackIdsToToggle, ListWithGaps, GapDescriptor)
          % SELECTTRACKIDFORTOGGLINGFROMLIST 
          % takes 3 arguments:
          % 1: list with IDS of all optional tracks'
          % 2: list with gaps for each track
          % 3: gap-descriptor: 'Forward' or 'Backward'

            if isempty(TrackIdsToToggle)
                TrackId =           '';
                RowOfSelection =    '';

            else
                RowOfSelection =    find(obj.getIdOfActiveTrack == TrackIdsToToggle);
                if isempty(RowOfSelection)
                     [TrackId, RowOfSelection] = obj.getNextTrackIdAfterActiveTrackFromList(TrackIdsToToggle);
                elseif length(RowOfSelection) == 1
                     [TrackId, RowOfSelection] = obj.getTrackIdAfterCurrentRowFromList(TrackIdsToToggle, RowOfSelection);
                else
                     TrackId = '';
                     RowOfSelection = '';
                end
            end 

            assert(ischar(GapDescriptor), 'Wrong input.')
            switch GapDescriptor
                case 'Forward'
                    Position = min(ListWithGaps{RowOfSelection}) - 1;

                case 'Backward'
                    Position = max(ListWithGaps{RowOfSelection}) + 1;

                otherwise
                    error('Wrong input.')

            end

            if isempty(ListWithGaps)
                Position = NaN;

            end



        end

        function [TrackId, CandidateRow] =      getNextTrackIdAfterActiveTrackFromList(obj, TrackIdsToToggle)
             CandidateRow = find(TrackIdsToToggle > obj.getIdOfActiveTrack, 1, 'first');
             if isempty(CandidateRow)
                 CandidateRow = 1;
             end

                 TrackId = TrackIdsToToggle(CandidateRow);

        end

        function [TrackId, RowOfSelection] =    getTrackIdAfterCurrentRowFromList(~, TrackIdsToToggle, RowOfSelection)
            if RowOfSelection == length(TrackIdsToToggle)
                RowOfSelection = 1;
            else
                RowOfSelection = RowOfSelection + 1;
            end
            TrackId = TrackIdsToToggle(RowOfSelection);

        end

    end
  
    methods % SETTERS: AUTOCELLRECOGNITION
        
          function obj =                performIntensityAutoRecognition(obj, SourceSegmentationCaptures, MySelectedFrames, MyPreventDoubleTracking, MyPreventDoubleTrackingDistance)
               
             
                  for FrameIndex = 1 : MySelectedFrames

                    fprintf('\nIntensity recognition frame %i:\n', FrameIndex)
                    NumberOfAcceptedFailures =              4;
                    NumberOfCellsAdded  =                   0;
                    AccumulatedSegmentationFailures =       0;
                    sourceSegmentationCapture =             SourceSegmentationCaptures(FrameIndex);
                    ListWithSegmentationCaptures =          cell(5000, 1);
                    
                    ContinueLoop = true;
                    while ContinueLoop
                        sourceSegmentationCapture =     sourceSegmentationCapture.setActiveCoordinateByBrightestArea;
                        sourceSegmentationCapture =     sourceSegmentationCapture.generateMaskByAutoThreshold;
                        sourceSegmentationCapture =     sourceSegmentationCapture.addActivePixelsToBlackedOutPixels;

                        if sourceSegmentationCapture.testPixelValidity
                            AccumulatedSegmentationFailures =       0;
                            NumberOfCellsAdded =                    NumberOfCellsAdded + 1;
                            ListWithSegmentationCaptures{NumberOfCellsAdded, 1} = sourceSegmentationCapture;
                            fprintf('Detected mask number %i.\n', NumberOfCellsAdded)
                            
                        else 
                            
                            AccumulatedSegmentationFailures =       AccumulatedSegmentationFailures + 1;
                            fprintf('Failure count = %i of %i. (', AccumulatedSegmentationFailures, NumberOfAcceptedFailures)
                            
                            MyStringCell = sourceSegmentationCapture.getActiveShape.getShapeValidityString;
                            cellfun(@(x) fprintf('%s ', x), MyStringCell)
                            
                            fprintf(')\n')
                            
                           
                            
                        end

                        if AccumulatedSegmentationFailures > NumberOfAcceptedFailures
                            ContinueLoop = false;

                        end
                        
                    end
                    
                    
                    Remove =                                    cellfun(@(x) isempty(x), ListWithSegmentationCaptures);
                    ListWithSegmentationCaptures(Remove, :) =   [];
                    ListWithSegmentationCaptures = cellfun(@(x) x, ListWithSegmentationCaptures);
                    
                     if MyPreventDoubleTracking && ~isnan(MyPreventDoubleTrackingDistance)
                        indices =                               obj.getIndicesWithCloseNeighbors(ListWithSegmentationCaptures,MyPreventDoubleTrackingDistance);

                        if ~isempty(indices)

                            ListWithSegmentationCaptures(indices, :) = [];
                            fprintf('%i masks were removed because of double-tracking. %i cells remaining.\n', sum(indices), length(ListWithSegmentationCaptures))

                        end
                    
                     end
                    

                     obj = obj.setActiveFrameTo(MySelectedFrames(FrameIndex));
                     
                      for indexOfDetectedCells = 1 : length(ListWithSegmentationCaptures)
                            obj =   obj.setActiveTrackIDTo(obj.getNewTrackID);
                            obj =   obj.addSegmentation(ListWithSegmentationCaptures(indexOfDetectedCells));
                      end
                     
                     
                  

                end
                
               
           end
           
          function indices =            getIndicesWithCloseNeighbors(~, ListWithSegmentationCaptures, myPreventDoubleTrackingDistance)
               
             

                       Centroids = arrayfun(@(x) x.getActiveShape.getCentroid, ListWithSegmentationCaptures, 'UniformOutput', false);
                        a = repmat(Centroids, 1, length(Centroids));
                        StartRowIndex = 0;
                        distances = nan(size(a, 1), size(a, 2));
                        for index = 1 : size(a, 2)

                            StartRowIndex = StartRowIndex + 1;
                            for rowIndex = StartRowIndex + 1 : size(a, 1)

                                MyDistance = pdist([a{StartRowIndex, index}; a{rowIndex, index}]);
                                distances(rowIndex, index) = MyDistance;

                            end


                        end
                        
                         distances(isnan(distances)) = myPreventDoubleTrackingDistance + 10;
                          indices = distances <= myPreventDoubleTrackingDistance;

                          indices = max(indices, [], 2);

            

                
                       

               end
        
    end
    
    methods % SETTERS MANUAL TRACKING
   
        function obj =      truncateActiveTrackToFit(obj)
            % TRUNCATEACTIVETRACKTOFIT removes tracked frames from active track so that there is no overlap with selected track;
            % method can execute only when precisly one track is selected;
            try  
                obj =       obj.truncateActiveTrackToFitInternal; 

             catch ME
                    error('Could not truncate')
            end

        end

        function obj =      mergeSelectedTracks(obj)
            % MERGESELECTEDTRACKS merges selected tracks
            % only possible when 1 or 2 tracks are selected
            % when 1 track is selected: merging with active track;
            try
                    obj =                             obj.mergeTracks( obj.getIdsOfSelectedTracks);
                    obj.SelectedTrackIDs(2:end,:) =   [];
             catch ME
                   error('Could not merge')
            end
        end

        function obj =      mergeTracks(obj, inputTrackIDs)
                % MERGETRACKS merges tracks with input track-IDs;
                % only possible when 1 or 2 tracks are in the input
                % when 1 track is input: merging with active track;
                try
                    obj =   obj.mergeTracksInternal(inputTrackIDs);
                catch ME
                    error('Could not merge.')
                end

        end   
            
    end

    methods % SETTERS AUTOTRACKING 
       
        function obj =          autoConnectTracksWithinDistance(obj, Distance)
            % TRACKINGBYFINDINGUNIQUETARGETWITHINCONFINES connects tracks by specific criteria;
            % takes 1 argument:
            % 1: number of accepted "gap frames":
            % negative: connects tracks that show some overlap
            % positive: connects tracks that are separated by 1 or more frames;
            % 0: connects gap that fit exactly;
            assert(isnumeric(Distance) && isscalar(Distance), 'Wrong input.')
            
            obj.AutoTrackingActiveGap =         Distance;  
            obj =                               obj.autoconnectTracks;
        end
         
          function obj =              autTrackingProcedure(obj, varargin)
              % AUTTRACKINGPROCEDURE autotracking of all existing cells;
              % takes 3 arguments:
              % 1: PMDriftCorrection
              % 2: PMSpaceCalibration
              % 3: PMTimeCalibration
              % this input is required to calculate distances in absolute distances;
              % methods performs follwoing actionts:
              % 1: disconnect all tracks
              % 2: remove all "interpolations" between tracks
              % 3: actual tracking (by preferentially connecting cells that are in close proximity);
              % 4: removal of tracks with frames less than threshold
              % 5: connect tracks that are close but have gaps
              
              switch length(varargin)
                 
                  case 3
                      MyDriftCorrection = varargin{1};
                      MySpaceCalibration =  varargin{2};
                      MyTimeCalibration =  varargin{3};
                  otherwise
                      error('Wrong input.')
                  
              end
              
                obj =      obj.unTrack;
                obj =      obj.removeAllInterPolationMasks;
                obj =      obj.trackByMinimizingDistancesOfTracks(MyDriftCorrection, MySpaceCalibration, MyTimeCalibration);
                obj =      obj.removeTrackWithFramesLessThan(obj.AutoTracking.getFirstPassDeletionFrameNumber); % first delete 'remnant' tracks of just one frame, they slow down mergin and are not useful for tracking or merging
                obj =      obj.performSerialTrackReconnection;
          end
        
  
    end

    methods % SUMMARY
        
        function obj = showSummary(obj)

            fprintf('\n*** This PMTrackingNavigation object enables creation and editing of tracking information.\n')

            fprintf('This object allows addition of novel tracking content with the method:\n')
            
            
       
       
            
            fprintf('\nThe ID of the active track is "%i".\n', obj.ActiveTrackID)
            fprintf('Most procedures on individual tracks are performed on this active track.\n')

            if ~isnan(obj.ActiveTrackID)
                segmentationOfActiveMask = obj.getActiveMask.showSummary;

                activeTrack =   obj.getActiveTrack;

            end

            list =  obj.getTrackSummaryList;
        end

       

        function obj = removeActiveTrack(obj)
          obj  =     obj.removeTrack(obj.ActiveTrackID);
        end

     end
  
     
    methods (Access = private) % BASIC GETTERS
        
        function Value =                getModel(obj)
           Value = obj; 
        end
        
        function newTrackID =           generateNewTrackID(obj)
            % GENERATENEWTRACKID returns a new track ID (that is not overlapping with all existing tracks);

            CurrentTracks =         obj.getListWithAllUniqueTrackIDs;
            if isempty(CurrentTracks) 
                newTrackID = 1;

            else
                 GapRows =           find(diff(CurrentTracks) > 1);
                 if isempty(GapRows)
                     newTrackID =       max(CurrentTracks) + 1;
                 else
                     newTrackID =        CurrentTracks(GapRows(1)) + 1; 
                 end



            end

             end
        
        
    end
    
    methods (Access = private) % SETTERS AUTOTRACKING
       
        function obj =          unTrack(obj)

            answer = questdlg('You are about the disconnect connections (tracks) between all cells. The cells will remain. This is irreversible! Do you want to proceed?');
            if strcmp(answer, 'Yes')

                fprintf('Disconnecting tracks:\nBefore disconnecting: %i tracks. ', obj.getNumberOfTracks);

                CurrentStartTrackID =      1;

                for FrameIndex = 1 : obj.getMaxFrame

                    NumberOfCells =             obj.getNumberOfCellsInFrame(FrameIndex);
                    BasicTrackIDs =             num2cell(CurrentStartTrackID : CurrentStartTrackID + NumberOfCells - 1);
                    obj =                       obj.setTrackSegmentationForFrameRowColumn(FrameIndex, NaN, obj.TrackIDColumn, BasicTrackIDs);

                    CurrentStartTrackID =       CurrentStartTrackID + NumberOfCells;

                end

                fprintf('After disconnecting: %i tracks\n\n', obj.getNumberOfTracks);
            end 
        end

        function obj =          removeAllInterPolationMasks(obj)
           error('could not test this part; verify when using first time after change')
            NumberOfTracksBeforeDeletion =                              obj.getNumberOfTracks;

            [MyTrackingCellForTime, MyTrackingCellWithDrift] = obj.getTrackingCellForTimeForFrames(NaN);

            MyNewTrackingCellForTime =               cellfun(@(x) obj.removeInterpolationMasksFromSegmentationList, MyTrackingCellForTime, 'UniformOutput', false);
            MyNewTrackingCellForTimeWithDrift =      cellfun(@(x) obj.removeInterpolationMasksFromSegmentationList, MyTrackingCellWithDrift, 'UniformOutput', false);


            obj = obj.setTrackingCellForTime(MyNewTrackingCellForTime, MyNewTrackingCellForTimeWithDrift);



            fprintf('Deleting interpolation masks:\n')
            fprintf('Before deletion: %i tracks. After deletion: %i tracks\n\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);

        end

        function List =         removeInterpolationMasksFromSegmentationList(obj, List)
            SegmentationTypeNameList =     cellfun(@(x) x.SegmentationType.SegmentationType, List(:,obj.SegmentationTypeColumn), 'UniformOutput', false);
            InterPolationRows =            strcmp(SegmentationTypeNameList, 'Interpolate');
            List(InterPolationRows,:) =    obj.getBlankSegmentation;
        end

        function obj =          trackByMinimizingDistancesOfTracks(obj, MyDriftCorrection, MySpaceCalibration, MyTimeCalibration)

            NumberOfTracksBeforeDeletion =            obj.getNumberOfTracks;

            for FrameIndex = 1 : NumberOfFrames - 1

                fprintf('%i-%i; ', FrameIndex, FrameIndex+ 1);

                TrackCellForTime_MetricSpace =                          obj.getTrackingCellForTimeForMetricSpace(MyDriftCorrection, MySpaceCalibration, MyTimeCalibration);

                PreFrameSegmentationList =                              TrackCellForTime_MetricSpace{FrameIndex, 1};
                PostFrameSegmentationList =                             TrackCellForTime_MetricSpace{FrameIndex + 1, 1};
   
                [CollectedPreTrackIDs, CollectedPostTrackIDs] =         obj.AutoTracking.findMatchingTrackIDsForSegmentationLists(...
                                                                            PreFrameSegmentationList, ...
                                                                            PostFrameSegmentationList...
                                                                            );
               
                for index = 1: length(CollectedPreTrackIDs)

                    PreTrackID =                    CollectedPreTrackIDs(index);
                    OldPostTrackID =                CollectedPostTrackIDs(index);

                    obj =                           obj.setTrackForFrameTrackIDWithMasks(...
                                                        FrameIndex + 1, ...
                                                        OldPostTrackID, ...
                                                        1, ...
                                                        num2cell(PreTrackID)...
                                                        );


                end

                
                
                

            end

           

            fprintf('\nBefore tracking: %i tracks. After tracking: %i tracks.\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);


        end

        function TrackInformationPerFrame = getTrackingCellForTimeForMetricSpace(obj, Drift, Space, Time)
            myTrackingAnalysis =  PMTrackingAnalysis(...
                                    obj, ...
                                    Drift, ...
                                    Space, ...
                                    Time...
                                    );




           assert(~isempty(myTrackingAnalysis), 'Tracking analysis was not set')


          fprintf('Tracking by minimizing distances:\nProcessing frames ');



          myTrackingAnalysis =                      myTrackingAnalysis.setApplyDriftCorrection(true);
          myTrackingAnalysis =                      myTrackingAnalysis.setSpaceUnits('µm');
          myTrackingAnalysis =                      myTrackingAnalysis.setTimeUnits('frames');


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
        end
             
    end
    
    methods (Access = private) % SETTERS AUTOCONNECT TRACKS
        
         function obj =          performSerialTrackReconnection(obj)
             MyGaps = obj.AutoTracking.getAutoTrackingConnectionGaps;
            NumberOfGaps =  length(MyGaps);
            for myGapIndex= 1 : NumberOfGaps
                obj.AutoTrackingActiveGap =       MyGaps(myGapIndex);   
                obj =                                   obj.autoconnectTracks;

            end

         end
        
        function obj =          autoconnectTracks(obj)
            % AUTOCONNECTTRACKS autoconnect "track-fragments" that are separated by a specified number of frames and spatial distance;

            % usually done after automated tracking;
            % a major issue is the lack of tracks where on or a few gap frames are present;
            % this function closes gaps of a defined number of frames;

            fprintf('PMTrackingNavigation: @autoconnectTracks.\nMerge track pairs with a gap of %i frames:\n', obj.AutoTrackingActiveGap)

            TrackeNumberBefore =                            obj.getNumberOfTracks;

            
            NumberOfMergedTracks =                          0;
            RecentlyExcludedTrackID =                       NaN;

             while 1 % one round of merging (start from first track; done multiple times until all tracks are connected);

                ListWithAllAvailableTrackIDs =                  obj.getListWithAllUniqueTrackIDs;
                ListWithAllAvailableTrackIDs(ListWithAllAvailableTrackIDs < RecentlyExcludedTrackID,:)  = [];  
                for TrackIndex = 1 :  size(ListWithAllAvailableTrackIDs,1)

                    obj =                               obj.mergingInfoText(ListWithAllAvailableTrackIDs, TrackIndex);
    
                    mySourceMask =                      obj.getLastMaskOfTrack( ListWithAllAvailableTrackIDs(TrackIndex));
                    MyTargetFrame =                     mySourceMask.getFrame + obj.AutoTrackingActiveGap + 1;
                    
                                                        
                    ListWithTargetSegmentations =       obj.AutoTracking.getCandidateTargetTracks(mySourceMask, obj.getSegmentationOfFrame(MyTargetFrame));

                    CandidateTrackIDs =                 cell2mat(ListWithTargetSegmentations(:,  obj.TrackIDColumn));
                    CandidateFrames =                   arrayfun(@(x) obj.getFrameNumbersForTrackID(x), CandidateTrackIDs, 'UniformOutput', false);
                    DeleteTracks =                      cellfun(@(x) max(x == MyTargetFrame) == 0, CandidateFrames);
                    
                    ListWithTargetSegmentations(DeleteTracks, :) = [];
                    
                    
                    if  size(ListWithTargetSegmentations,1) ~= 1 
                        RecentlyExcludedTrackID =       mySourceMask.getTrackID; % exclude if not one precise target can be found:

                    else

                        myTargetMask =                  PMMask(ListWithTargetSegmentations);
                        obj =                           obj.mergingInfoTextTwo(mySourceMask.getTrackID, myTargetMask.getTrackID);
                      
                        obj =                           obj.repairTrackingCellForTimeToAllowMerginOfMasks(mySourceMask, myTargetMask);
                        obj =                           obj.mergeTracks([mySourceMask.getTrackID, myTargetMask.getTrackID]);
                        NumberOfMergedTracks =          NumberOfMergedTracks + 1;
                        break % start from beginning because original track names have changed;

                    end

                end

                if TrackIndex == size(ListWithAllAvailableTrackIDs,1) % if the loop ran until the end: exit, otherwise start from the beginning;
                    break 
                end
                
             end
             
            fprintf('A total of %i track-pairs were merged.\n', NumberOfMergedTracks)
            fprintf('Before merging: %i tracks. After merging: %i tracks.\n\n', TrackeNumberBefore, obj.getNumberOfTracks);


        end
        
        function obj =          repairTrackingCellForTimeToAllowMerginOfMasks(obj, mySourceMask, myTargetMask)
            
              if obj.AutoTrackingActiveGap >= 1
                           
                             
                Results =               obj.AutoTracking.getSegmentationCaptureListBetweenMasks(mySourceMask, myTargetMask);

                 obj =                              obj.addSegmentationCaptureList(...
                 Results, ...
                 obj.AutoTracking.getFramesThatRequireClosing(mySourceMask, myTargetMask),  ...
                 obj.AutoTracking.getActiveTrackID);

                obj =           obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID);



                elseif obj.AutoTrackingActiveGap <= -1


                    OverlappingFrames =         obj.getOverLappingFramesOfTracks([mySourceMask.getTrackID, myTargetMask.getTrackID]);
                    for Index = 1 : length(OverlappingFrames)

                            CurrentFrame =      OverlappingFrames(Index);
                            TargetRow =         obj.getTargetRowForFrameTrackID(CurrentFrame, mySourceMask.getTrackID);
                            obj =               obj.setTrackSegmentationForFrameRowColumn(CurrentFrame, TargetRow, NaN, obj.getBlankSegmentation);


                    end

                end

            
            
        end
        
        function obj =          mergingInfoText(obj, ListWithAllAvailableTrackIDs, TrackIndex)
                if obj.AutoTracking.getShowDetailedMergeInformation== 1
                    fprintf('\nTrack %i (%i of %i)', ListWithAllAvailableTrackIDs(TrackIndex), TrackIndex, size(ListWithAllAvailableTrackIDs,1))
                end
        end
        
        function obj =          mergingInfoTextTwo(obj, SourceTrackID, TargetTrackID)
            FramesOfSource =             obj.getFrameNumbersForTrackID( SourceTrackID);
            fprintf('Merge track %i (frame %i to %i)', SourceTrackID, min(FramesOfSource), max(FramesOfSource))

            FramesTarget =                      obj.getFrameNumbersForTrackID( TargetTrackID);
            fprintf(' with track %i (frame %i to %i).\n', TargetTrackID, min(FramesTarget), max(FramesTarget))

        end

        function obj =          addSegmentationCaptureList(obj, SegmentationCaptureList, varargin)
            
            switch length(varargin)
               
                case 2
                    ListWithFrames =    varargin{1};
                    TrackID =           varargin{2};
                    
                    
                otherwise
                    error('Wrong input.')
                
                
            end
            
             for FrameIndex = 1 : length(ListWithFrames)
                    obj.ActiveFrame =           ListWithFrames(FrameIndex);
                    obj.ActiveTrackID =         TrackID;
                    obj =                       obj.addSegmentation( SegmentationCaptureList{FrameIndex});
                    
              end
            
            
        end
         
    end
    
    methods (Access = private) % initialize
       
        function obj = checkTrackingCellForTime(obj, TrackingCell)
            % CHECKTRACKINGCELLFORTIME test intactness of tracking-cell
            % takes 1 argument:
            % tracking cell
            % throws error if format has unexpected content
             assert(iscell(TrackingCell) && isvector(TrackingCell), 'Wrong input.')
            
            for index = 1 : size(TrackingCell, 1)
               TrackingCellForCurrentFrame =        TrackingCell{index};
               
               arrayfun(@(x) obj.checkTrackingSegmentation(TrackingCellForCurrentFrame(x, :)), obj.getVectorWithNumberOfCells(TrackingCellForCurrentFrame));      
            end
            
        end
        
        function NumberOfCells = getVectorWithNumberOfCells(obj, TrackingCellForFrame)
            NumberOfCells = (1 : size(TrackingCellForFrame, 1))';
        end
        
        function obj = checkTrackingSegmentation(obj, TrackingForSingleCell)
            % CHECKTRACKINGSEGMENTATION throws error if mistake in tracking cell is found;
            % takes 1 argument:
            % cell array for single cell;
           
            assert(iscell(TrackingForSingleCell) && isvector(TrackingForSingleCell), 'Wrong input')
           
           for index = 1 : 5
                assert(isnumeric(TrackingForSingleCell{index}) && isscalar(TrackingForSingleCell{index}), 'Wrong input.')
           end
           
           assert(isnumeric(TrackingForSingleCell{obj.PixelColumn}) && ismatrix(TrackingForSingleCell{obj.PixelColumn}) && size(TrackingForSingleCell{obj.PixelColumn}, 2) == 3, 'Wrong input.')
           assert(isscalar(TrackingForSingleCell{obj.SegmentationTypeColumn}) && isstruct(TrackingForSingleCell{obj.SegmentationTypeColumn}), 'Wrong input.')
            
        end
             
        
       
          
    end
    
    methods (Access = private) % SUMMARY OF ALL TRACKS:
        
        function [TrackSummary] =           getTrackSummaryListInternal(obj)

            unique =                obj.getListWithAllUniqueTrackIDs;

            if isempty(unique)
                 TrackSummary =      table(  0,...
                                        0, ...
                                        0, ...
                                        0, ...
                                        0, ...
                                        0);

            else
                FramesPerTrack =        obj.getListOfAllFramesPerTrack;
                start =                 obj.getListOfStartFramesPerTrack(FramesPerTrack);
                ending =                obj.getListOfEndFramesPerTrack(FramesPerTrack);
                number =                obj.getNumberOfFramesPerTrack(FramesPerTrack);
                missing =               obj.getMissingFramesPerTrack(FramesPerTrack);
                finished =              cellfun(@(x) x.getFinishedStatus, obj.TrackInfoList(unique), 'UniformOutput', false);



                TrackSummary =      table(  unique,...
                                            start, ...
                                            ending, ...
                                            number, ...
                                            missing, ...
                                            finished);


            end

            TrackSummary.Properties.VariableNames = {'TrackIDs', 'StartFrames', 'EndFrames', 'NumberOfFrames', 'MissingFramesPerTrack', 'FinishedStats'};




        end

        function StartFrames =              getListOfStartFramesPerTrack(obj, FrameLists)
           StartFrames =        cellfun(@(x) obj.getMinimum(x)   , FrameLists);   
        end

        function Number =                   getMinimum(~, List)
            if isempty(List)
               Number = 0;
            else
               Number = min(List);
            end

        end

        function framesPerTrack =           getListOfAllFramesPerTrack(obj)
            framesPerTrack =        obj.getListOfAllFramesForTrackIDs(obj.getListWithAllUniqueTrackIDs);
        end
        
        function EndFrames =                getListOfEndFramesPerTrack(obj, Frames)
            EndFrames =    cellfun(@(x) obj.getMax(x)   ,  Frames);   
        end

        function Number =                   getMax(~, List)
            if isempty(List)
                Number = 0; 
            else
                Number = max(List);
            end

        end

        function MissingFrames =            getMissingFramesPerTrack(obj, Frames)
           tic
            StartFrames =       obj.getListOfStartFramesPerTrack(Frames); 
            toc

            tic
            EndFrames =         obj.getListOfEndFramesPerTrack(Frames); 
            toc
            tic

            NumberOfFrames =    obj.getNumberOfFramesPerTrack(Frames);   
            toc
            MissingFrames=      EndFrames -  StartFrames - NumberOfFrames + 1;
        end

   
        
        
        
    end
    
    methods (Access = private) % SETTER SETENTRYINTRACKINGCELLFORTIME
        
        function obj =              setEntryInTrackingCellForTime(obj, SegmentationCapture)

            assert(isscalar(SegmentationCapture) && isa(SegmentationCapture, 'PMSegmentationCapture'), 'Wrong input.')
            assert(~isempty(obj.TrackingAnalysis), 'Tracking analysis needed.')
            assert(obj.verifyTrackID(obj.ActiveTrackID), 'Could not add data because track ID was invalid.')
         
            obj =       obj.removeDuplicatesFromActiveSegmentation;
            if isempty(SegmentationCapture.getRawMaskCoordinateList) % when the pixels are empty: delete content:
                      obj =       obj.setTrackForFrameTrackIDWithMasks(obj.ActiveFrame, obj.ActiveTrackID, NaN, obj.getBlankSegmentation);


            else
               obj = obj.addSegmentationCaptureToActiveSegmentation(SegmentationCapture);

            end

        end

        function obj =              removeDuplicatesFromActiveSegmentation(obj)
            RowsOfActiveTrack =      obj.getRowInSegmentationForFrameTrackID(obj.ActiveFrame, obj.ActiveTrackID);
            if size(RowsOfActiveTrack,1) >= 2 % if more than one row is positive: delete all duplicate rows (this should not be the case):
                RowsToDelete = RowsOfActiveTrack(2:end);

                obj = obj.deleteTrackSegmentationForFrameRows(obj.ActiveFrame, RowsToDelete);
                warning('There was a duplicate row for the active track, which had to be removed.')
            end
        end

        function Row =              getRowInSegmentationForFrameTrackID(obj, Frame, TrackID)
            % GETROWINSEGMENTATIONFORFRAMETRACKID
            MyTrackingCell =            obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
            TrackIDsInWantedFrame =     obj.getTrackIDsFromSegmentationList(MyTrackingCell);
            Row=                        find(TrackIDsInWantedFrame == TrackID);   

        end

   
        function trackIDs =         getTrackIDsFromSegmentationList(obj, SegmentationList)
            if isempty(SegmentationList)
                trackIDs =       zeros(0,1);
            else
                trackIDs =       cell2mat(SegmentationList(:, obj.TrackIDColumn));
            end
        end

        function obj =              addSegmentationCaptureToActiveSegmentation(obj, SegmentationCapture)
            % ADDSEGMENTATIONCAPTURETOACTIVESEGMENTATION add new mask to TrackingCellForTime and TrackingCellForTimeWithDrift;
            % takes 1 argument:

            assert(isscalar(SegmentationCapture) && isa(SegmentationCapture, 'PMSegmentationCapture'), 'Wrong input.')
            [NewMask, NewMaskWithDrift] =           obj.getMasksForInput(obj.ActiveTrackID, obj.ActiveFrame, SegmentationCapture);

       

            obj =       obj.setTrackForFrameTrackIDWithMasks(obj.ActiveFrame, obj.ActiveTrackID, NaN, NewMask, NewMaskWithDrift);

        end

        function minDistance =      getMinDistanceToOtherMasksInActiveFrameForMask(obj, Mask)

            NewX =              Mask{1, obj.CentroidXColumn} ;
            NewY =              Mask{1, obj.CentroidYColumn};
            NewZ =              Mask{1, obj.CentroidZColumn} ;

            segmentation =      obj.getSegmentationOfFrame(obj.ActiveFrame);

            MatchingRow =      cell2mat(segmentation(:, obj.TrackIDColumn)) == Mask{obj.TrackIDColumn, 1};

            segmentation(MatchingRow, :) = [];
            coordinates =       obj.extractCoordinatesFromTrackList(segmentation);

            minDistance =            min(pdist2([NewX NewY NewZ], coordinates));

        end
        
    end
    
    methods (Access = private)  % SETTERS TRACKING CELL: SETTRACKFORFRAMETRACKIDWITHMASKS;
        
        function obj =      setTrackForFrameTrackIDWithMasks(obj, Frame, Track, Columns, varargin)
            % SETTRACKFORFRAMETRACKIDWITHMASKS sets TrackingCellForTime
            % takes 3  to 5 arguments:
            % 1: number of frame
            % 2: track ID
            % 3: column
            % 4: content
            % 5: content for drift matrix
            
            TargetRow =      obj.getTargetRowForFrameTrackID(Frame, Track);
            obj =            obj.setTrackSegmentationForFrameRowColumn(Frame, TargetRow, Columns, varargin{:});

        end
        
        function obj =      setTrackSegmentationForFrameRowColumn(obj, Frame, Rows, Columns, varargin)
            obj.testNumericScalar(Frame);
            obj.testNanScalarOrNumVector(Rows);
            obj.testNanScalarOrNumVector(Columns);

            switch length(varargin)

              case 1
                  NewMask =             varargin{1};
                  NewMaskWithDrift =    varargin{1};

              case 2
                  NewMask =             varargin{1};
                  NewMaskWithDrift =    varargin{2};

              otherwise
                  error('Wrong input.')

            end

            assert(iscell(NewMask) && iscell(NewMaskWithDrift), 'Wrong input.')
            assert(isvector(NewMask) && isvector(NewMaskWithDrift), 'Wrong input.')
            assert(length(NewMask) == length(NewMaskWithDrift), 'Length of mask and mask with drift do not match.')

            if isnan(Rows)
               Rows = 1 : size(obj.TrackingCellForTime{Frame, 1}, 1);
            end

            if isnan(Columns)
               Columns = 1 : obj.NumberOfColumns;

            else
              assert(isnumeric(Columns) && isscalar(Columns), 'Currently not supported.')

            end

            assert(length(NewMask) == length(Columns), 'Wrong input.')

            obj.TrackingCellForTime{Frame, 1}(Rows, Columns) =              NewMask;
            obj.TrackingCellForTimeWithDrift{Frame, 1}(Rows, Columns) =     NewMaskWithDrift;

        end
        
        function obj =      testNumericScalar(obj, Value)
            Test = isnumeric(Value) && isscalar(Value) && ~isnan(Value);
            if ~Test
                error('Wrong input.')
            end


        end

        function obj =      testNanScalarOrNumVector(obj, Value)

            assert(isnumeric(Value), 'Input must be numeric.')

            if isscalar(Value) && isnan(Value)

            elseif isvector(Value) && (min(isnan(Value)) == 0)

            else
                error('Input has to be either nan scalar or numeric vector.')

            end

        end

    end
    
    methods (Access = private) % SETTERS TRACKINGCELLFORTIME

        function obj =          setTrackingCellForTime(obj, Value, varargin)
        % SETTRACKINGCELLFORTIME set tracking cell for time
        % sets both with and without drift
        % takes 2 arguments:
        % 1: tracking cell for time (see class description for details);
        % 2: either PMDriftCorrection (to calculate tracking cell with drift);
        %        or tracking cell for time with drift
        switch length(varargin)

        case 1
           assert(isscalar(varargin{1}), 'Wrong input.')
           assert(iscell(Value) && isvector(Value) && size(Value, 2) == 1, 'Wrong argument type.')
           obj.TrackingCellForTime =   Value(:);


           switch class(varargin)
               case  'PMDriftCorrection'
                    MyDriftCorrection = varargin{1};
                     obj =                       obj.setTrackingCellForTimeWithDriftByDriftCorrection(MyDriftCorrection);
               case 'cell'
                   obj.TrackingCellForTimeWithDrift =   varargin{1}(:);
               otherwise
                   error('Wrong input.')

           end



        otherwise
           error('This method can only be performed if a drift-correction is provided.')

        end

        end

        function [Mask, MaskWithDrift] =  getMasksForInput(obj, MyTrackID, activeFrame, SegmentationCapture)

            assert(isscalar(SegmentationCapture) && isa(SegmentationCapture, 'PMSegmentationCapture'), 'Wrong input.')
            assert(~isempty(obj.TrackingAnalysis), 'Need tracking analysis to calculate drift.')
            Mask{1, obj.TrackIDColumn} =        MyTrackID;
            Mask{1, obj.TimeColumn} =           activeFrame;
            Mask{1, obj.CentroidYColumn} =      mean(SegmentationCapture.getMaskYCoordinateList);
            Mask{1, obj.CentroidXColumn} =      mean(SegmentationCapture.getMaskXCoordinateList);
            Mask{1, obj.CentroidZColumn} =      mean(SegmentationCapture.getMaskZCoordinateList);
            Mask{1, obj.PixelColumn} =          SegmentationCapture.getRawMaskCoordinateList;
            SegmentationInfo =                  SegmentationCapture.RemoveImageData;
            Mask{1, obj.SegmentationTypeColumn}.SegmentationType=         SegmentationInfo;

            MaskWithDrift =                             obj.TrackingAnalysis.addDriftCorrectionToMasks(Mask);
            MaskWithDrift{1, obj.PixelColumn} =         '';
            MaskWithDrift{1, obj.SegmentationTypeColumn}.SegmentationType=     SegmentationInfo;


        end

        function obj =          replaceMaskInTrackingCellForTimeWith(obj, Mask, DriftMask)
        % REPLACEMASKINTRACKINGCELLFORTIMEWITH replaces content of specified masks;
        % takes 2 arguments:
        % 1: segmentation mask
        % 2: segmentation mask with drift
        % method extracts location of masks by track ID and frame number;
        % all other properties will be replaced by the input masks;
        [Frame, Row ] =         obj.getFrameAndRowInTrackTimeCellForMask(Mask);
        obj =                   obj.setTrackSegmentationForFrameRowColumn(Frame, Row, NaN, Mask, DriftMask);


        end

        function obj =          deleteTrackSegmentationForFrameRows(obj, Frame, RowsToDelete)
        assert(isnumeric(Frame) && isscalar(Frame) && ~isnan(Frame), 'Wrong input.')
        obj.TrackingCellForTime{Frame, 1}(RowsToDelete,:) =                   [];
        obj.TrackingCellForTimeWithDrift{Frame, 1}(RowsToDelete,:) =                   [];

        end

          function obj = setTargetAddressWithTrackID(obj, AddressOfTargetTrack, NewTrackID)
                
                 if isnumeric(NewTrackID)
                    assert(isscalar(NewTrackID), 'Wrong input.')
                    NewTrackID = {NewTrackID};
                end
                
                 obj =                           obj.setTargetColumnOfTrackingCellWithValueAddress(...
                                                    obj.TrackIDColumn, NewTrackID, AddressOfTargetTrack);
          end
           
        function obj =          setTargetColumnOfTrackingCellWithValueAddress(obj, Column, Value, Address)
            for Index = 1: size(Address, 1)

                MyFrame =       Address(Index, 1);
                MyRow =         Address(Index, 2);
                obj =           obj.setTrackSegmentationForFrameRowColumn(MyFrame, MyRow, Column, Value);

            end
        end

     

      

 

        function TargetRow=     getTargetRowForFrameTrackID(obj, Frame, TrackID)

            TargetRow =        obj.getRowInSegmentationForFrameTrackID(Frame, TrackID);

            if isempty(TargetRow)
                MySegmentationList =        obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
                TrackIDsInWantedFrame =     obj.getTrackIDsFromSegmentationList(MySegmentationList);
                TargetRow =                 find(isnan(TrackIDsInWantedFrame), 1, 'first');

            end

            if isempty(TargetRow)
                SegmentationOfWantedFrame =     obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
                TargetRow=                      size(SegmentationOfWantedFrame, 1) + 1;

            end
            assert(isnumeric(TargetRow) && TargetRow >= 1 && ~isnan(TargetRow) && ~isempty(TargetRow), 'Wrong result')

        end

        function obj =         setTrackingCellForTimeCorrected(obj) 
            
            emptyRows = cellfun(@(x) isempty(x), obj.TrackingCellForTime);
            
             obj.TrackingCellForTime(emptyRows) = {obj.getEmptySegmentation};
        end
            
        
    end
    
    methods (Access = private) % setters TRACKINGCELLFORTIME old
        
         function obj = removeMasksByMaxPlaneLimit(obj, Value)
                  error('Change without test. Verify before using.')
                  obj.TrackingCellForTime =     cellfun(@(x) obj.removeMasksByMaxPlaneLimitForList(x, Value), obj.TrackingCellForTime , 'UniformOutput', false);
                  obj =                         obj.selectAllTracks;
         end

        function List = removeMasksByMaxPlaneLimitForList(obj, List, Value)
            rows =              cellfun(@(x) size(x,1)<= Value, List(:, obj.PixelColumn)); 
            List(rows, :) =     obj.getBlankSegmentation;
        end

    end
  
    methods (Access = private) % GETTERS SEGMENTATION-LIST

        function [pooledData, pooledDataWithDrift] =                   getPooledTrackingData(obj)

            assert(iscell(obj.getTrackingCellForTimeForFrames(NaN)), 'Wrong format.')

            if isempty(obj.TrackingCellForTime)
               obj.TrackingCellForTime =  obj.getEmptySegmentation;
            end

            pooledData =          vertcat(obj.TrackingCellForTime{:});
            if isempty(pooledData)
                pooledData =         obj.getEmptySegmentation;
            end

            if isempty(obj.TrackingCellForTimeWithDrift)
               obj.TrackingCellForTimeWithDrift =  obj.getEmptySegmentation;
            end


            pooledDataWithDrift =       vertcat(obj.TrackingCellForTimeWithDrift{:});   
            if isempty(pooledDataWithDrift)
                pooledData =         obj.getEmptySegmentation;
            end

        end

        function [TrackingCell, WithDrift] = getTrackingCellForTimeForFrames(obj, Frames)

            obj.testNanScalarOrNumVector(Frames);

            if isempty(obj.TrackingCellForTime)

                WithDrift =             obj.getEmptySegmentation;
                TrackingCell =          obj.getEmptySegmentation;
                
            elseif size(obj.TrackingCellForTime, 1) < Frames
                
                WithDrift =             obj.getEmptySegmentation;
                TrackingCell =          obj.getEmptySegmentation;

            else

                if isnan(Frames)

                    TrackingCell = obj.TrackingCellForTime;
                    if isempty(obj.TrackingCellForTimeWithDrift)
                        WithDrift = obj.getEmptySegmentation;
                    else
                        WithDrift = obj.TrackingCellForTimeWithDrift;
                    end


                elseif isscalar(Frames)


                    TrackingCell = obj.TrackingCellForTime{Frames};
                    if isempty(obj.TrackingCellForTimeWithDrift)
                        WithDrift = obj.getEmptySegmentation;
                    else
                        WithDrift = obj.TrackingCellForTimeWithDrift{Frames};
                    end

                else
                    error('Input must be scalar.')

                end

            end

        end

        function EmptyContent =             getEmptySegmentation(obj)
            EmptyContent =                      cell(0, obj.NumberOfColumns);
        end

        function Segmentation =             getTrackingSegmentationForFrameRowColumn(obj, Frame, Row, Column)
            Segmentation = obj.getTrackingSegmentationForFrameRowColumnPropertyName(Frame, Row, Column, 'TrackingCellForTime');
        end

        function Segmentation =             getTrackingSegmentationWithDriftForFrameRowColumn(obj, Frame, Row, Column)
        Segmentation = obj.getTrackingSegmentationForFrameRowColumnPropertyName(Frame, Row, Column, 'TrackingCellForTimeWithDrift');
        end

        function Segmentation =             getTrackingSegmentationForFrameRowColumnPropertyName(obj, Frame, Row, Column, Property)
            % GETTRACKINGSEGMENTATIONFORFRAMEROWCOLUMNPROPERTYNAME returns segmentation for input;
            % takes 4 arguments:
            % 1: frame number
            % 2: row number (if isnan: all rows)
            % 3: column number (if isnan: all columns)
            % 4: 'TrackingCellForTime' or 'TrackingCellForTimeWithDrift'
            % returns 1 value:
            % 1: returns cell array with all rows of selected frame and rows/columns;

            obj.testNumericScalar(Frame);
            obj.testNanScalarOrNumVector(Row);
            obj.testNanScalarOrNumVector(Column);

            if isnan(Row)
                Row = 1 : obj.getNumberOfCellsInFrame(Frame);
            end

            if isnan(Column)
               Column = 1 : obj.NumberOfColumns;

            end

            if isempty(Row) % is this necessary and doing anythign?
                Segmentation =        obj.getEmptySegmentation; 

            else
                Segmentation = obj.(Property){Frame, 1}(Row, Column);

            end


        end

        function segmentation =             getSegmentationWithAppliedDriftForFrame(obj, Frame, DriftCorrection)

         if DriftCorrection.getDriftCorrectionActive
             noDrift =                  obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);

             [~, segmentation] =        obj.getTrackingCellForTimeForFrames(Frame);


             segmentation(:, obj.PixelColumn) =       noDrift(:, obj.PixelColumn);

         else
             segmentation =      obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);

         end

        end
        
        function selectedSegmentation =     getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(obj, Frames, Planes, TrackIDs, DriftCorrection, varargin)
            selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frames, DriftCorrection);
            selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, TrackIDs);
            selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes, varargin{:});


        end

        function number =                   getNumberOfCellsInFrame(obj, Frame)
            number = size(obj.getTrackingCellForTimeForFrames(Frame), 1);
        end     
        
        function SourceMask  =              getLastMaskOfTrack(obj, MyTrackID)
            SourceTrackInformation =    obj.getSegmentationForTrackID(MyTrackID);
            [~, RowOfLastFrame] =       max(obj.extractFramesFromTrackList(SourceTrackInformation));     
            SourceMask =                PMMask(  SourceTrackInformation(RowOfLastFrame,:));
        end

        function SourceMask  =              getFirstMaskOfTrack(obj, MyTrackID)
            SourceTrackInformation =    obj.getSegmentationForTrackID(MyTrackID);
            [~, RowOfLastFrame] =       min(obj.extractFramesFromTrackList(SourceTrackInformation));     
            SourceMask =                PMMask(  SourceTrackInformation(RowOfLastFrame,:));
        end
        
    end
    
    methods (Access = private) % PROCESS: process segmentation list input;
       
        function selectedSegmentation =     filterSegmentationListForPlanes(obj, selectedSegmentation, Planes, varargin)

                InputPixels =                                       selectedSegmentation(:,obj.CentroidZColumn);

                selectedSegmentation(:, obj.PixelColumn) =          cellfun(@(x) ...
                    obj.filterPlaneListForPlane(x, Planes, varargin{:}), ...
                    InputPixels , 'UniformOutput', false);

                selectedSegmentation(obj.getRowsOfTracksWithEmptyPixels(selectedSegmentation), :) = [];

        end

        function FilteredList =             filterSegementationListForSelectedTracks(obj, List, TrackIDs)
            
            if isempty(List)
                FilteredList = List;
            else
                 Rows = ismember( cell2mat(List(:, obj.TrackIDColumn)), TrackIDs);
        FilteredList = List(Rows, :);
            end
       
        end

        function list =                     filterPixelListForPlane(~, list, SelectedPlane)
        NoMemberShip = ~ismember(list(:,3), SelectedPlane);  
        list(NoMemberShip, :) = [];
        end

        function Masks =                    extractMasksFromTrackList(obj, List)
                Masks =   cell2mat(List(:,obj.PixelColumn));
        end
        
        function [list] =                   filterPlaneListForPlane(~, list, SelectedPlane, varargin)
            % FILTERPLANELISTFORPLANE removes all Segmentation rows that do not match selected plane;
            % 3: optional 'OnlyCenter': in this case round all the coordinates and than filter for the mean;


            if isempty(list)
                           list =   zeros(0,3);
            else

               switch length(varargin)

                   case 0

                   case 1
                       assert(ischar(varargin{1}), 'Wrong input.')
                       switch varargin{1}

                           case 'OnlyCenter'
                               MeanZ = round(mean(list(:, 1)));
                               list(:, 1) = MeanZ;

                           otherwise
                               error('Wrong input.')

                       end


               end


                NoMemberShip = ~ismember(list(:,1), SelectedPlane);  
                list(NoMemberShip, :) = [];
            end




            end 

        function rowsWithEmptyPixels =      getRowsOfTracksWithEmptyPixels(obj, TrackList)
            rowsWithEmptyPixels     =           cellfun(@(x) isempty(x),   TrackList(:,obj.PixelColumn));
        end
          
    end
    
    methods (Access = private) % getters track-related
        
       
        function Tracks = getUniqueTrackIDsFromTrackingCell(obj)
            Tracks =                        unique(obj.getTrackIDsFromSegmentationList(obj.getPooledTrackingData));
            Tracks(isnan(Tracks), :) =      [];
        end
 
    end
      
    methods (Access = private) % set active track
        
       function obj = ActiveTrackWasChanged(obj)
                obj =       obj.addMissingTrackIdsToTrackInfoListForMaxTrack(obj.ActiveTrackID);
                obj =       obj.removeTrackIDsFromSelectedTracks(obj.ActiveTrackID);
                
        end
            
        function obj = removeTrackIDsFromSelectedTracks(obj, TrackIDs)
            if isempty(TrackIDs)
                
            else
                obj.SelectedTrackIDs(obj.getIdsOfSelectedTracks == TrackIDs, :) = [];
            end
            
        end
            
              
     

        function valid = verifyTrackID(~, Value)
            valid = isnumeric(Value) && isscalar(Value) ;
        end

        function TrackIds = removeTrackIdsThatDoNotExist(obj, TrackIds)
            Rows =             ismember(TrackIds, obj.getListWithAllUniqueTrackIDs);
            MissingRows =   ~Rows;
            if sum(MissingRows) >= 1
                warning('Some of tracks that should be added do not exist. These tracks were not added to the selected tracks.') 
            end

            TrackIds =         TrackIds(Rows);
        end

       

        
    end
    
    methods (Access = private)% active mask
        
        function mask = getActiveMask(obj)
            mask = PMMask(obj.getSegmentationForActiveMask);
        end
   
        function segmentationOfActiveMask = getSegmentationForActiveMask(obj)
            wantedRow =                     obj.getRowInSegmentationForFrameTrackID(obj.ActiveFrame, obj.ActiveTrackID);
            if isempty(wantedRow)
                segmentationOfActiveMask =      obj.getEmptySegmentation;
            else
                segmentationOfActiveMask =      obj.getTrackingSegmentationForFrameRowColumn(obj.ActiveFrame, wantedRow, NaN);
            end
        end
        
       
            
         
      
        
    
         
          
      
        
        
        
       
        
        function segmentation = getSegementationForActiveTrack(obj)
            segmentation = obj.getSegmentationForTrackID(obj.ActiveTrackID);
        end  
            
        
        
            
        
        
             function coordinates = getCoordinatesOfActiveTrack(obj)
                coordinates =  obj.extractCoordinatesFromTrackList(obj.getSegementationForActiveTrack);
                if isempty(coordinates)
                    coordinates = [NaN, NaN, NaN];
                end
             end
             
         
            
           
              
        
    end
    
    methods (Access = private) % GETTERS TRACKINGMATRIX getCoordinatesForTrackIDsInternal
        
        function Coordinates =      getCoordinatesForTrackIDsInternal(obj, TrackIDs, Planes, varargin)
            % GETCOORDINATESFORTRACKIDSINTERNAL returns coordinates for specified track IDs and planes;
            % takes 2 or 3 arguments:
            % 1: vector with wanted track IDs
            % 2: vector with required planes
            % 3: PMDriftCorrection object
            % returns 1 value:
            % cell array:   one cell contains coordinates for each track:
            %               each cell contains numerical matrix with 3 columns (coordinates), each row are the coordinates for a single frame;    

           if isnan(TrackIDs)
               Coordinates = zeros(0, 3);
           else

                ListWithAllCoordinates =         obj.getListWithAllCoordinatesByDriftCorrection(varargin{:});
                ListWithAllCoordinates =         cellfun(@(x) obj.roundCoordinates(x), ListWithAllCoordinates, 'UniformOutput', false);

                Addresses =                     cellfun(@(x) x.getSegmentationAddress, obj.TrackInfoList(TrackIDs, :), 'UniformOutput', false);
                Coordinates =                   cellfun(@(x) obj.filterCoordinatesBySegmentationAddress(ListWithAllCoordinates, x), Addresses,  'UniformOutput', false);
                Coordinates =                   cellfun(@(x) obj.replaceWrongPlaneWithNan(x, Planes), Coordinates, 'UniformOutput', false);

           end

        end

        function coordinates =      extractCoordinatesFromTrackList(obj, TrackList)
          % EXTRACTCOORDINATESFROMTRACKLIST extract all coordinates from segmentation list;
          % returns 1 value:
          % 1: numerical matrix with 3 columns (X, Y, Z value of centroid);
          %     % each row represents one cell
            if isempty(TrackList)
               coordinates = zeros(0,3); 
            else
                coordinates =        cell2mat( TrackList(:,   [obj.CentroidXColumn, obj.CentroidYColumn, obj.CentroidZColumn]));  
            end

        end

        function Coordinates =      roundCoordinates(obj, Coordinates)
           Coordinates(:, 3) = round(Coordinates(:, 3));
        end

        function Coordinates =      replaceWrongPlaneWithNan(obj, Coordinates, PlaneLimits)

           RowsToDeleteOne = Coordinates(:, 3) <  min(PlaneLimits) - 1; % make planes that are just barely out of view visible; otherwise tracks are just bits and pieces
           RowsToDeleteTwo = Coordinates(:, 3) >  max(PlaneLimits) + 1;

           RowsToChange = max([RowsToDeleteOne, RowsToDeleteTwo], [], 2);

           Coordinates(RowsToChange, :) = NaN;

        end

        function coordinateList =   getListWithAllCoordinatesByDriftCorrectionInput(obj, DriftCorrection)
           % gets drift corrected coordinates only when drift-correction is
           % set to active;
              switch DriftCorrection.getDriftCorrectionActive
                    case true
                        coordinateList = obj.getListWithAllDriftCorrectedCoordinates;
                    otherwise
                        coordinateList = obj.getListWithAllCoordinates;
              end

        end

         function Coordinates =     filterCoordinatesBySegmentationAddress(~, ListWithAllCoordinates, ListWithAddressesOfWantedTracks)

               Coordinates = zeros( size(ListWithAddressesOfWantedTracks, 1), 3);
               for Index = 1: size(ListWithAddressesOfWantedTracks, 1)
                   Data =                       ListWithAllCoordinates{ListWithAddressesOfWantedTracks(Index, 1)}(ListWithAddressesOfWantedTracks(Index, 2), :);
                   Coordinates(Index, 1: 3) =   Data;
               end

         end

    end
    
    methods (Access = private) % GETTERS TRACKINGMATRIX getCoordinatesForTrackIDsInternal
        
        function coordinateList =       getListWithAllCoordinatesByDriftCorrection(obj, varargin)
           % GETLISTWITHALLCOORDINATESBYDRIFTCORRECTION

                switch length(varargin)
                    case 0
                            coordinateList = obj.getListWithAllCoordinates;

                    case {1, 2}

                        ClasseTypes =   cellfun(@(x) class(x), varargin, 'UniformOutput', false);
                        if sum(strcmp(ClasseTypes, 'PMDriftCorrection')) == 1
                            DriftCorrection = varargin{strcmp(ClasseTypes, 'PMDriftCorrection')};
                           switch DriftCorrection.getDriftCorrectionActive
                                case true
                                    coordinateList = obj.getListWithAllDriftCorrectedCoordinates;
                                otherwise
                                    coordinateList = obj.getListWithAllCoordinates;
                          end

                        else
                            error('Wrong input.')

                        end

                    otherwise
                        error('Wrong input.')
                end

        end

        function coordinateList =       getListWithAllCoordinates(obj)
           % GETLISTWITHALLCOORDINATES returns list with coordinates from each segmentation;
           % returns 1 value:
           % 1: cell-array:
           %     each cell contains all data of a frame: a matrix with 3 columns for coordinates; each row contains data of a single cell;
           coordinateList = arrayfun(@(x) obj.extractCoordinatesFromTrackList(obj.getTrackingCellForTimeForFrames(x)), (1 : obj.getMaxFrame)', 'UniformOutput', false); 
        end

        function coordinateList =       getListWithAllDriftCorrectedCoordinates(obj)
          coordinateList = arrayfun(@(x) obj.extractCoordinatesFromTrackList(obj.TrackingCellForTimeWithDrift{x}), 1 : obj.getMaxFrame, 'UniformOutput', false); 
        end

    end
    
    methods (Access = private) % segmentation
        
       
        
         function Segmentation = getDriftCorrectedSegmentationWithSegmentAddress(obj, Address)
             % GETDRIFTCORRECTEDSEGMENTATIONWITHSEGMENTADDRESS returns drift-correction segmentation-list for address;
             
            Segmentation = cell(size(Address, 1), obj.NumberOfColumns);
            for Index = 1: size(Address, 1)
                MyFrame = obj.TrackingCellForTimeWithDrift{Address(Index, 1)};
                Segmentation(Index, 1 : obj.NumberOfColumns) =   MyFrame(Address(Index, 2), 1 : obj.NumberOfColumns);
            end

        end
        
        
        
        
    end
    
    methods (Access = private) % initialization for TrackingCellForTime

            function obj = setLengthOfTrackingCellForTime(obj, NumberOfFrames)
                if isempty(obj.getTrackingCellForTimeForFrames(NaN)) || obj.getMaxFrame < NumberOfFrames
                   obj = obj.setTrackSegmentationForFrameRowColumn(NumberOfFrames, 1, NaN, obj.getBlankSegmentation);
                end
            end


            function obj = FillGapsInTrackingCellForTime(obj)

                for CurrentFrame = 1 : obj.getMaxFrame

                    if isempty(obj.getTrackingCellForTimeForFrames(CurrentFrame))
                        obj = obj.setTrackSegmentationForFrameRowColumn(CurrentFrame, 1, NaN, obj.getBlankSegmentation);

                    elseif length(obj.getTrackingCellForTimeForFrames(CurrentFrame)) == 6 % if just the segmentation info column isi missing
                        obj = obj.setTrackSegmentationForFrameRowColumn(CurrentFrame, NaN, obj.SegmentationTypeColumn, {PMSegmentationCapture}, '');

                    end


                end

            end


            function segmentation =             getBlankSegmentation(obj)
                segmentation = cell(1, obj.NumberOfColumns);
                segmentation{1, obj.TrackIDColumn} = NaN;
                segmentation{1, obj.TimeColumn} = NaN;
                segmentation{1, obj.CentroidYColumn} = NaN;
                segmentation{1, obj.CentroidXColumn} = NaN;
                segmentation{1, obj.CentroidZColumn} = NaN;
                segmentation{1, obj.PixelColumn} = zeros(0, 3);
                segmentation{1, obj.SegmentationTypeColumn}.SegmentationType = PMSegmentationCapture;

            end







    end

    methods (Access = private) % GETTERS FILE-MANAGEMENT
        
        function fileName = getFileNameForStoringBasicTrackingData(obj)
            fileName = [obj.MainFolder, '/Main.mat'];
        end
        
        function fileName = getFileNameForStoringMaskData(obj)
            fileName = [obj.MainFolder, '/Masks.mat'];
        end
        
        function structure = getStructureForStorage(obj)

            structure.TrackInfoList =                                           obj.TrackInfoList;
            structure.ActiveState.ActiveTrackID  =                              obj.ActiveTrackID;
            structure.ActiveState.ActiveFrame =                                 obj.ActiveFrame;
            structure.ActiveState.SelectedTrackIDs =                            obj.SelectedTrackIDs;

            structure.AutoTracking  =                                   obj.AutoTracking.getPropertiesStructure;
          
        end
        
    end
    
    methods (Access = private) % SPLIT and DELETE
        
     
            
        function obj =      deleteActiveTrackBeforeFrameInternal(obj, SplitFrame)
            obj =           obj.splitTrackAtFrameAndDeleteFirst(SplitFrame, obj.ActiveTrackID);
        end

        function obj =      splitTrackAtFrameAndDeleteFirst(obj, SplitFrame, TrackIDToSplit)            
            AddressToDelete =          obj.TrackInfoList{TrackIDToSplit, 1}.getSegmentationAddress;
            AddressToDelete =          obj.keepInSegmentationAddressFramesLessThan(AddressToDelete, SplitFrame);
            obj =                      obj.setTargetAddressWithTrackID(AddressToDelete, NaN);
            obj =                      obj.updateSegmentationAddressInTrackInfoListForIDs(TrackIDToSplit);

        end
        
        function AddressOfTargetTrack = keepInSegmentationAddressFramesLessThan(~, AddressOfTargetTrack, SplitFrame)
            AddressOfTargetTrack(AddressOfTargetTrack(:, 1) >= SplitFrame, :) = [];
        end
        

        function obj = deleteActiveTrackAfterFrameInternal(obj, SplitFrame)
             obj =      obj.splitTrackAtFrameAndDeleteSecond(SplitFrame, obj.ActiveTrackID);   
        end
         
        function obj =                       splitTrackAtFrameAndDeleteSecond(obj, SplitFrame, SourceTrackID)
            
                AddressToDelete =          obj.TrackInfoList{SourceTrackID, 1}.getSegmentationAddress;
                AddressToDelete =          obj.keepInSegmentationAddressFramesMoreThan(AddressToDelete, SplitFrame);
                obj =                      obj.setTargetAddressWithTrackID(AddressToDelete, NaN);
                obj =                      obj.updateSegmentationAddressInTrackInfoListForIDs(SourceTrackID);
              
              
        end
        
        function AddressOfTargetTrack = keepInSegmentationAddressFramesMoreThan(~, AddressOfTargetTrack, SplitFrame)    
            AddressOfTargetTrack(AddressOfTargetTrack(:, 1) < SplitFrame + 1, :) = [];
        end
       
        %% splitTrackAtFrame:
        function obj =      splitTrackAtFrame(obj, SplitFrame, SourceTrackID, TrackIdForSecondSplitTrack)
                        
            AddressOfSourceTrack =          obj.TrackInfoList{SourceTrackID, 1}.getSegmentationAddress;
            AdressOfNewSecondTrack =        obj.keepInSegmentationAddressFramesMoreThan(AddressOfSourceTrack, SplitFrame);
            obj =                           obj.addMissingTrackIdsToTrackInfoListForMaxTrack(max([SourceTrackID, TrackIdForSecondSplitTrack]));

            obj =                           obj.setTargetAddressWithTrackID(AdressOfNewSecondTrack, TrackIdForSecondSplitTrack);
            obj =                           obj.updateSegmentationAddressInTrackInfoListForIDs(SourceTrackID);
            obj =                           obj.updateSegmentationAddressInTrackInfoListForIDs(TrackIdForSecondSplitTrack);

            obj =                           obj.addToSelectedTrackIds(TrackIdForSecondSplitTrack);

           
            
      
        end
        
         
            
        
        function rows = getRowsOfTrackIDFromList(obj, TrackList, trackID)
            assert(isnumeric(trackID) && isscalar(trackID), 'Wrong input.')
            if isempty(TrackList)
                rows = zeros(0,1);
            else
                if isnan(trackID) % get rows with nan when NaN is input;
                    ListWithTrackIDs =    cell2mat(TrackList(:, obj.TrackIDColumn));
                    rows =                isnan(ListWithTrackIDs);
                else
                     rows = cell2mat(TrackList(:, obj.TrackIDColumn)) == trackID;
                end
            end
        end
 
    end
    
    methods (Access = private) % TRACKINFO-LIST reorderTrackInfoList;
        
        function obj =      deleteFromInfoListTrackIDs(obj, TrackIds)   
            warning('Deleting extra tracks from info list')
            obj.TrackInfoList{TrackIds,1} =      {''};
        end

        function obj =      reorderTrackInfoList(obj)
            
              CopyOfInfoList =    obj.TrackInfoList;
             
              OldIndices =        arrayfun(@(x)      obj.getRowInTrackInfoForTrackID(x), obj.getListWithAllUniqueTrackIDs);
              MyTargetRows =      obj.getListWithAllUniqueTrackIDs;
              
              for Index = 1: length(OldIndices)
                  CopyOfInfoList{MyTargetRows(Index), 1} = obj.TrackInfoList{OldIndices(Index), 1};
              end
              
              obj.TrackInfoList = CopyOfInfoList;
            
        end
        
        function row =      getRowInTrackInfoForTrackID(obj, myWantedTrackID)              
               
              MatchingRows =                   find(obj.getTrackIDsInTrackInfoList == myWantedTrackID);
                if length(MatchingRows) == 1
                    row = MatchingRows;

                elseif isempty(MatchingRows)
                    row = NaN;

                elseif length(MatchingRows) >= 2
                    row = MatchingRows(1);
                    warning('Duplicate track found. Only the first one is used.')

                else
                    error('Track-info list is corrupted. Unknown problem.')
                end
          end
          
        function TrackIdOfCurrentInfoList = getTrackIDsInTrackInfoList(obj)
            TrackIdOfCurrentInfoList  =     cellfun(@(x) x.TrackID, obj.TrackInfoList); 
        end   
        
       
        
    end
    
    methods (Access = private) % TRACKINFO-LIST addMissingTrackIdsToTrackInfoList;
        
          
        
        function obj =      addMissingTrackIdsToTrackInfoList(obj)
            MaximumTrack =   max(obj.getUniqueTrackIDsFromTrackingCell);
            obj =            obj.addMissingTrackIdsToTrackInfoListForMaxTrack(MaximumTrack);
        end
        
        function obj =      addMissingTrackIdsToTrackInfoListForMaxTrack(obj, MaximumTrack)
            if size(obj.TrackInfoList, 1) < MaximumTrack
                obj.TrackInfoList{MaximumTrack, 1} = ''; 
            end

            WrongRows =                             find(cellfun(@(x) ~isa(x, 'PMTrackInfo'), obj.TrackInfoList));
            obj.TrackInfoList(WrongRows, :) =       arrayfun(@(x) PMTrackInfo(x), WrongRows, 'UniformOutput', false);

        end
            
    end
    
    methods (Access = private) % TRACKINFO-LIST: addSegmentationAddressToAllTrackInfos;
         
        function obj = addSegmentationAddressToAllTrackInfos(obj)
            % ADDSEGMENTATIONADDRESSTOALLTRACKINFOS resets tracking-addresses for all tracks in library;
            for TrackID =  (obj.getUniqueTrackIDsFromTrackingCell)'
                obj = obj.updateSegmentationAddressInTrackInfoListForIDs(TrackID);
            end
        end
         
        function obj =          updateSegmentationAddressInTrackInfoListForIDs(obj, TrackID)

            WrongAddressList =                      obj.getListOfCorruptAddressesForTrackID(TrackID);
            obj =                                   obj.removeDuplicateAddressesFromTrackingCell(WrongAddressList);
            FinalizedAddressListOfCurrentTrack =    obj.getFinalizedTrackingAddressesForTrackID(TrackID);

            if isempty(FinalizedAddressListOfCurrentTrack)
                obj.TrackInfoList{TrackID, 1} =                 obj.TrackInfoList{TrackID, 1}.resetDefaults;
            else
                obj.TrackInfoList{TrackID, 1} =                 obj.TrackInfoList{TrackID, 1}.setSegmentationAddress(FinalizedAddressListOfCurrentTrack);  
            end

        end

        function FinalizedAddressListOfCurrentTrack = getFinalizedTrackingAddressesForTrackID(obj, TrackID)
            % GETFINALIZEDTRACKINGADDRESSESFORTRACKID returns segmentation addresses for track ID;
            % takes 1 argument: track ID
            % returns 1 value:
            % numerical matrix with 2 columns: first column: frame numbers; second column: row numbers in tracking cell for time;

          FinalizedAddressListOfCurrentTrack =            obj.getRawSegmentationAddressFromTrackingMatrixForTrackID(TrackID);

        Results = cellfun(@(x) isscalar(x), FinalizedAddressListOfCurrentTrack(:, 2));
        if min(Results) == 0
            error('At least one address is not a scalar, which should not be the case.')
        end

        FinalizedAddressListOfCurrentTrack =            cell2mat(FinalizedAddressListOfCurrentTrack);

        end

    
        function obj =                  removeDuplicateAddressesFromTrackingCell(obj, WrongAddresList)
                
                for Index = 1 : size(WrongAddresList, 1)
                    
                    WrongAddress =                      WrongAddresList(Index, :);
                    FrameNumberOfInspectedTrack =       WrongAddress{1, 1};
                    AllTargetRowsForCurrentFrame =      WrongAddress{1, 2};

                    DuplicateRows =                         AllTargetRowsForCurrentFrame(2 : end);
                    
                    for InternalIndex = 1: length(DuplicateRows)
                        RowThatShouldBeBlankedOut =     DuplicateRows(InternalIndex);
                        obj =                           obj.setTrackSegmentationForFrameRowColumn(FrameNumberOfInspectedTrack, RowThatShouldBeBlankedOut, NaN, obj.getBlankSegmentation);
                    end

                end
            end

     end
     
    methods (Access = private) % TRACKINFO-LIST: verifySegmentationAddresses;
        
        function obj =                                              verifySegmentationAddresses(obj)
            
            for TrackID =  (obj.getUniqueTrackIDsFromTrackingCell)'

                WrongAddressList =                      obj.getListOfCorruptAddressesForTrackID(TrackID);

                if isempty(WrongAddressList)
                else
                    fprintf('There are a problems with track %i. Take a look at the content of this track to find the mistake.\n', TrackID)
                    fprintf('To fix the problem you can call addSegmentationAddressToAllTrackInfos. This will start the address list of all tracks from scratch.\n')
                   AddressList =            obj.getRawSegmentationAddressFromTrackingMatrixForTrackID(TrackID);
                   cellfun(@(x, y)  PMMask(obj.getTrackingSegmentationForFrameRowColumn(x, y, NaN)).showTable, AddressList(:, 1), AddressList(:, 2));
                end

            end

        end

        function ListWithDuplicateSegmentationAddresses =           getListOfCorruptAddressesForTrackID(obj, TrackID)
            ListWithSegmentationAddresses =                      obj.getRawSegmentationAddressFromTrackingMatrixForTrackID(TrackID);
            ListWithDuplicateSegmentationAddresses =             obj.getListOfCorruptAddressList(ListWithSegmentationAddresses);
        end

        function  ListWithSegmentationAddresses =                   getRawSegmentationAddressFromTrackingMatrixForTrackID(obj, TrackID)
            % GETRAWSEGMENTATIONADDRESSFROMTRACKINGMATRIXFORTRACKID returns raw segmentation addresses for track ID;
            % takes 1 argument: track ID
            % returns 1 value:
            % cell array with 2 columns: first column: frame numbers; second column: row numbers in tracking cell for time;
            assert(isnumeric(TrackID) && ~isnan(TrackID) && mod(TrackID, 	1) == 0, 'Wrong input.')

            TargetRowsForEachFrame =                                    arrayfun(@(x) ...
                                    obj.getRowInSegmentationForFrameTrackID(x, TrackID), ...
                                    1 : obj.getMaxFrame, 'UniformOutput', false);
                                
            ListWithSegmentationAddresses(1 : obj.getMaxFrame, 2) =     TargetRowsForEachFrame;
            ListWithSegmentationAddresses(:, 1) =                       num2cell(1 : obj.getMaxFrame);

            EmptyRows =                                                 cellfun(@(x) isempty(x), ListWithSegmentationAddresses(:, 2));
            ListWithSegmentationAddresses(EmptyRows, :) =               [];



        end

        function WrongAddressList =                                 getListOfCorruptAddressList(obj, ListWithSegmentationAddresses)

            IndicesWithMultipleTargetRows =     cellfun(@(x) length(x) > 1, ListWithSegmentationAddresses(:, 2));
            WrongAddressList =                  ListWithSegmentationAddresses(IndicesWithMultipleTargetRows, :);

        end
  
    end
    
    methods (Access = private) % SETTERS: TRUNCATE TRACKS
       
        function obj =                  truncateActiveTrackToFitInternal(obj)
        assert(length(obj.getIdsOfSelectedTracks) == 1, 'Can only truncate with one track selected.')


        obj =                   obj.truncateTrackToFitMask([obj.ActiveTrackID,   obj.SelectedTrackIDs]);
        obj =                   obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID); 
        end

        function obj =                  truncateTrackToFitMask(obj, mySelectedTrackIDs)
        OverlappingFrames =         obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
        for Index = 1 : length(OverlappingFrames)

            TargetRow =      obj.getTargetRowForFrameTrackID(OverlappingFrames(Index), mySelectedTrackIDs(1));
            obj =            obj.setTrackSegmentationForFrameRowColumn(OverlappingFrames(Index), TargetRow, NaN, obj.getBlankSegmentation);


        end

        end

        function [OverlappingFrames] =  getOverLappingFramesOfTracks(obj, mySelectedTrackIDs)
           assert(length(mySelectedTrackIDs)==2, 'Overlapping frames can be only detected for two tracks')
           FramesOfTrackOne =         obj.getFrameNumbersForTrackID(mySelectedTrackIDs(1));  
           FramesOfTrackTwo =         obj.getFrameNumbersForTrackID(mySelectedTrackIDs(2));  
           OverlappingFrames =        intersect(FramesOfTrackOne, FramesOfTrackTwo);

        end

    end
    
    methods (Access = private) % SETTERS: MERGE TRACKS
       
          function obj = mergeTracksInternal(obj, mySelectedTrackIDs)

                if length(mySelectedTrackIDs) == 1
                    mySelectedTrackIDs(2) = obj.ActiveTrackID;
                end
                assert(length(mySelectedTrackIDs) == 2, 'Can only merge two tracks.')
                
                OverlappingFrames =         obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
                
                if isempty(OverlappingFrames)
                    
                    OldTrackID =    max(mySelectedTrackIDs);
                    NewTrackID =    min(mySelectedTrackIDs);

                    AddressOfTargetTrack =          obj.TrackInfoList{OldTrackID, 1}.getSegmentationAddress;
                
                    obj =                           obj.setTargetAddressWithTrackID(AddressOfTargetTrack, NewTrackID);
               
                    obj =       obj.updateSegmentationAddressInTrackInfoListForIDs(NewTrackID);
                    obj =       obj.updateSegmentationAddressInTrackInfoListForIDs(OldTrackID);
                    obj =       obj.setActiveTrackIDTo(NewTrackID);

                else
                    
                    text1 =     sprintf('Merging was not allowed, because frames ');
                    text2 =     arrayfun(@(x) sprintf('%i ', x), OverlappingFrames, 'UniformOutput', false);
                    text2 =     horzcat(text2{:});

                    text3 =     sprintf('are overlapping.\n');
                    msgtext =   [ text1 , text2, text3];

                    myException =  MException('MATLAB:mergeError', msgtext);
                    throw(myException)
                    
                end

            end
            

        
    end
    
    methods (Access = private) % SETTERS: CONVERT FORMAT:
       
        function [obj]=                         convertOldCellMaskStructureIntoTrackingCellForTime(obj)
            
            
               %% this function converts the "segmentation data" from the migration structure to cell-format:

               myCellMaskStructure =            obj.OldCellMaskStructure;
               targetFieldNames =               obj.FieldNamesForTrackingCell;
               numberOfColumns =                obj.NumberOfColumns;
               
             
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

                            CurrentTargetCell = obj.getEmptySegmentation;
                              
                        end
                        
                        ListWithMasksPerTime{CurrentTimePointIndex,1} =  CurrentTargetCell;
                               
                    end

                    obj.TrackingCellForTime =                       ListWithMasksPerTime;
                    
                    warning('TrackingCellForTimeWithDrift is identical to TrackingCellForTime. Make sure to set it with drift correction if this is desired.')
                    obj.TrackingCellForTimeWithDrift     =          obj.TrackingCellForTime;
                    
                end

        end
 
    end
    
    methods (Access = private) % GETTERS: SEGMENTATION LIST, CURRENTLY NOT IN USE:
       
            function coordinates =      getXCoordinatesOfFrame(obj, Frame)

            if obj.getMaxFrame >= Frame
                coordinates = obj.getXCoordinatesFromSegementationList(obj.getTrackingCellForTimeForFrames(Frame));
            else
                coordinates =   zeros(0,1);
            end


            end

            function coordinates =      getXCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.CentroidXColumn));
            end

            function coordinates =      getYCoordinatesOfFrame(obj, Frame)

            if obj.getMaxFrame >= Frame
                coordinates =  getYCoordinatesFromSegementationList(obj, obj.getTrackingCellForTimeForFrames(Frame));
            else
                coordinates =   zeros(0,1);
            end


            end

            function coordinates =      getYCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.CentroidYColumn));
            end

            function coordinates =      getZCoordinatesOfFrame(obj, Frame)
              if obj.getMaxFrame >= Frame
                    coordinates =  obj.getZCoordinatesFromSegementationList(obj.getTrackingCellForTimeForFrames(Frame));
                else
                    coordinates =   zeros(0,1);
              end
            end

            function coordinates =      getZCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.CentroidZColumn));
            end
 
    end
    
    methods(Access= private) % CURRENTLY NOT IN USE:
      
        function GapFrames =                        getNumberOfGapFramesForTrackIDs(obj, mySelectedTrackIDs)
          assert(length(mySelectedTrackIDs)==2, 'Overlapping frames can be only detected for two tracks')
          [OverlappingFrames] = obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
          if ~isempty(OverlappingFrames)
              GapFrames = -OverlappingFrames;
          else
              [SourceMask, TargetMask] =    obj.getSourceAndTargetMaskFromTrackIDs(mySelectedTrackIDs);


          end


        end

        function [SourceMask, TargetMask] =         getSourceAndTargetMaskFromTrackIDs(obj, mySelectedTrackIDs)

          assert(length(mySelectedTrackIDs)==2, 'Overlapping frames can be only detected for two tracks')
           FramesOfTrackOne =         obj.getFrameNumbersForTrackID(mySelectedTrackIDs(1));  
           FramesOfTrackTwo =         obj.getFrameNumbersForTrackID(mySelectedTrackIDs(2));  

           MinOne = min(FramesOfTrackOne);
           MaxOne = max(FramesOfTrackOne);

           MinTwo = min(FramesOfTrackTwo);
           MaxTwo = max(FramesOfTrackTwo);

           if MaxOne < MinTwo
               SourceMask = obj.getLastMaskOfTrack(mySelectedTrackIDs(1));
               TargetMask =  obj.getFirstMaskOfTrack(mySelectedTrackIDs(2));
           elseif  MaxTwo < MinOne
                SourceMask = obj.getLastMaskOfTrack(mySelectedTrackIDs(2));
               TargetMask =  obj.getFirstMaskOfTrack(mySelectedTrackIDs(1));
           else
               SourceMask = '';
               TargetMask = '';
           end


        end

        function Value =                            getNumberOfGapFramesBetweenMasks(~, mySourceMask, myTargetMask)
        Value =      mySourceMask.getFrame + 1 : myTargetMask.getFrame - 1;
        end

        function ReconstructedTimeSpecificList =    separatePooledDataIntoTimeSpecific(obj, ListOfSourceData)

            TimeData =  cell2mat(ListOfSourceData(:, obj.TimeColumn));
            ReconstructedTimeSpecificList =          cell(obj.getMaxFrame, 1);
            for CurrentTimePointIndex =  1 : obj.getMaxFrame

                if size(ListOfSourceData, 2) < obj.TimeColumn
                    dataForCurrentFrame =    obj.getEmptySegmentation;
                else
                    dataForCurrentFrame =    ListOfSourceData(TimeData == CurrentTimePointIndex,:);
                end

                ReconstructedTimeSpecificList{CurrentTimePointIndex,1 } =             dataForCurrentFrame;
            end

        end

        function obj =                              setInfoOfActiveTrackInternal(obj, input)
            
            obj =               obj.addMissingTrackIdsToTrackInfoList;
            switch input
                case 'Finished'
                    newTrackInfo =         obj.TrackInfoList{obj.ActiveTrackID, 1}.setTrackAsFinished;
                case 'Unfinished'
                    newTrackInfo =         obj.TrackInfoList{obj.ActiveTrackID, 1}.setTrackAsUnfinished;
                otherwise
                   error('Wrong input type')
            end
            
            obj.TrackInfoList{obj.ActiveTrackID, 1} =        newTrackInfo;
            
        end
        
        function segmentationOfCurrentFrame =       getDriftCorrectedSegmentationOfFrame(obj, Value)
                if obj.testExistenceOfDriftCorrectionForFrame(Value)
                    segmentationOfCurrentFrame =      obj.TrackingCellForTimeWithDrift{Value,1};
                else
                    segmentationOfCurrentFrame =      obj.getEmptySegmentation;
                end   
         end
        
        function value =                            testExistenceOfDriftCorrectionForFrame(obj, Value)
             value= isempty(obj.getTrackingCellForTimeForFrames(Na)) || obj.getMaxFrame < Value || isempty(obj.getTrackingCellForTimeForFrames(Value));
                value = ~ value;
        end
        
        function ResultTrackIDs =                   getTrackIdsWithLimitedMaskData(obj)
            ResultTrackIDs =         NaN;
            CountOfIncomplete =      0;
            
            UniqueTrackIDs =        obj.getListWithAllUniqueTrackIDs;
            for TrackIndex = 1 : size(UniqueTrackIDs,1)
                RelevantMaskData =          obj.getSegmentationForTrackID(UniqueTrackIDs(TrackIndex));
                if ~obj.determineIfSegmentationListIsComplete(RelevantMaskData)
                   CountOfIncomplete =                  CountOfIncomplete + 1;
                   ResultTrackIDs(CountOfIncomplete, 1) =     UniqueTrackIDs(TrackIndex);
                end
                
            end
            fprintf('\n%i of %i tracks remain poorly masked.\n', CountOfIncomplete, size(UniqueTrackIDs,1));
        end

        function Complete =                         determineIfSegmentationListIsComplete(obj, RelevantMaskData)
            
            NumberOfPlanes =                16; % maximum number of "one point" masks;

            NumberOfMasks =             size(RelevantMaskData,1);
            DetailedMask =              cellfun(@(x) size(x,1) > NumberOfPlanes + 10, RelevantMaskData(:,obj.PixelColumn));
            Fraction =                  sum(DetailedMask) / NumberOfMasks;

            if Fraction <= 0.5
                fprintf('Track %i has %1.1f fraction detailed masks.\n', RelevantMaskData{1, obj.TrackIDColumn}, Fraction);
                Complete = false;
            else
                 Complete = true;
            end
        end
        
        function [obj] =                            splitSelectedTrackAtActiveFrame(obj)
            obj =                       obj.splitTrackAtFrame(obj.getActiveFrame, obj.getIdsOfSelectedTracks, obj.generateNewTrackID);
        end
         
    end
end

