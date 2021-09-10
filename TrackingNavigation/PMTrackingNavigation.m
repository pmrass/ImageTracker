classdef PMTrackingNavigation
    %PMTRACKINGNAVIGATION Summary of this class goes here
    %   Detailed explanation goes here
    
  
    
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
    

    
    properties (Access = private) % for connecting tracks
        
        PreventDoubleTracking =                     false
        DistanceForDoubleTracking =                 2
        
        FirstPassDeletionFrameNumber =              3;
        AutoTrackingConnectionGaps =                [-1 0 -2 1  -3 ]; 
        
        MaximumAcceptedDistanceForAutoTracking =     30;
        DistanceLimitXYForTrackMerging =             30;
        DistanceLimitZForTrackingMerging =           2; % all tracks that show some overlap are accepted; positive values extend overlap
          
    end
    
    properties (Access = private) % duplicate data that are just here to boost speed; should not be stored in file

        TrackImages
        OldCellMaskStructure
        TrackingAnalysis
        
        % temporary settings for auto-tracking
        AutomatedCellRecognition
        ShowDetailedMergeInformation =               false
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
    
    methods % initialization
       
        function obj = PMTrackingNavigation(varargin)
            %PMTRACKINGNAVIGATION Construct an instance of this class
            %   Detailed explanation goes here
            
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

        function obj = set.PreventDoubleTracking(obj, Value)
                assert(islogical(Value) && isscalar(Value), 'Wrong input.')
                obj.PreventDoubleTracking = Value;
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
        
        function obj = addSegmentationAddressToAllTrackInfos(obj)
             fprintf('Creating segmentation addresses from scratch for track:')
             for TrackID =  (obj.getUniqueTrackIDsFromTrackingCell)'
                 fprintf('%i ', TrackID)
                 obj = obj.updateSegmentationAddressInTrackInfoListForIDs(TrackID);
             end
             fprintf('\n')
        end
         
        function obj = verifySegmentationAddresses(obj)
            fprintf('Verifying segmentation addresses for track ID:')
            for TrackID =  (obj.getUniqueTrackIDsFromTrackingCell)'
                fprintf('%i: ', TrackID)
                WrongAddressList =                      obj.getListOfCorruptAddressesForTrackID(TrackID);

                if isempty(WrongAddressList)
                    fprintf('ok\n')
                else
                    fprintf('There are a problems with this track. Take a look at the content of this track to find the mistake.\n')
                    fprintf('To fix the problem you can call addSegmentationAddressToAllTrackInfos. This will start the address list of all tracks from scratch.\n')
                   AddressList =            obj.getRawSegmentationAddressFromTrackingMatrixForTrackID(TrackID);
                   cellfun(@(x, y)  PMMask(obj.getTrackingSegmentationForFrameRowColumn(x, y, NaN)).showTable, AddressList(:, 1), AddressList(:, 2));
                end

            end
            
            
         
        end

        function obj = set.MainFolder(obj, Value)
           assert(ischar(Value), 'Wrong input.')
            obj.MainFolder = Value;
        end
        
    end
    
    methods (Access = private) % initialize
       
        function obj = checkTrackingCellForTime(obj, Value)
             assert(iscell(Value) && isvector(Value), 'Wrong input.')
            
            for index = 1 : size(Value, 1)
                CurrentTime = Value{index};
               arrayfun(@(x) obj.checkTrackingSegmentation(CurrentTime(x, :)), (1 : size(CurrentTime, 1))');      
            end
            
        end
        
        function obj = checkTrackingSegmentation(obj, Value)
           
            assert(iscell(Value) && isvector(Value), 'Wrong input')
           
           for index = 1 : 5
                assert(isnumeric(Value{index}) && isscalar(Value{index}), 'Wrong input.')
           end
           
           assert(isnumeric(Value{6}) && ismatrix(Value{6}) && size(Value{6}, 2) == 3, 'Wrong input.')
           assert(isscalar(Value{7}) && isstruct(Value{7}), 'Wrong input.')
            
        end
             
        function obj = addMissingTrackIdsToTrackInfoList(obj)
           MaximumTrack =   max(obj.getUniqueTrackIDsFromTrackingCell);
           obj =            obj.addMissingTrackIdsToTrackInfoListForMaxTrack(MaximumTrack);
        end
        
       
          
    end
    
    methods % summary
        
        function obj = showSummary(obj)

            fprintf('\n*** This PMTrackingNavigation object enables creation and editing of tracking information.\n')

            fprintf('\nThe ID of the active track is "%i".\n', obj.ActiveTrackID)
            fprintf('Most procedures on individual tracks are performed on this active track.\n')

            if ~isnan(obj.ActiveTrackID)
                segmentationOfActiveMask = obj.getActiveMask.showSummary;

                activeTrack =   obj.getActiveTrack;

            end

            list =  obj.getTrackSummaryList;
        end

        function list =  getTrackSummaryList(obj)
            list = obj.getTrackSummaryListInternal;
        end

        function frames = getFramesOfActiveTrack(obj)
            frames =        obj.getListOfAllFramesForTrackIDs(obj.ActiveTrackID);
            frames=         frames{1};
        end

        function framesPerTrack = getListOfAllFramesForTrackIDs(obj, MyTracks)
            AddressesPerTrack =         arrayfun(@(x) obj.TrackInfoList{x, 1}.getSegmentationAddress, MyTracks, 'UniformOutput', false);

            MyTrackingCellForTime         = obj.getTrackingCellForTimeForFrames(NaN);
            FrameSeries =               cellfun(@(x) obj.extractFramesFromTrackList(x), MyTrackingCellForTime, 'UniformOutput', false);
            framesPerTrack =            cellfun(@(x) obj.getContentWithAddresses(FrameSeries, x), AddressesPerTrack, 'UniformOutput', false);
        end

        function FrameNumbers = getFrameNumbersForTrackID(obj, TrackID)
            Segmentation = obj.getSegmentationForTrackID(TrackID);
            FrameNumbers = obj.extractFramesFromTrackList(Segmentation);
        end

        function obj = removeActiveTrack(obj)
          obj  =     obj.removeTrack(obj.ActiveTrackID);
        end

    end
    
    methods (Access = private) % summary
        
           
       function [TrackSummary] =               getTrackSummaryListInternal(obj)
       
          
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
                finished =              obj.getFinishedStatusOfAllTracks;



                TrackSummary =      table(  unique,...
                                            start, ...
                                            ending, ...
                                            number, ...
                                            missing, ...
                                            finished);

            end
            
            
            
       end
       
   
        % getListOfStartFramesPerTrack:
       function StartFrames = getListOfStartFramesPerTrack(obj, FrameLists)
           StartFrames =        cellfun(@(x) obj.getMinimum(x)   , FrameLists);   
       end
       
        function framesPerTrack = getListOfAllFramesPerTrack(obj)
            framesPerTrack =        obj.getListOfAllFramesForTrackIDs(obj.getListWithAllUniqueTrackIDs);
        end
        
      
        
       
       function Content = getContentWithAddresses(~, ContentSeries, Addresses)
           
           Content = zeros(size(Addresses, 1), 1);
           for Index = 1 : size(Addresses, 1)
               Content(Index, 1) = ContentSeries{Addresses(Index, 1)}(Addresses(Index, 2));
           end
           
           
       end
       
        function FrameNumbers = extractFramesFromTrackList(obj, TrackList) 
            if isempty(TrackList)
                FrameNumbers =       NaN;
            else
                FrameNumbers =        cell2mat( TrackList(:, obj.TimeColumn));  
            end

        end
        

        
      
        
         
        
       
       function Number = getMinimum(~, List)
           if isempty(List)
               Number = 0;
           else
               Number = min(List);
           end
           
       end
       
       % getListOfEndFramesPerTrack:
        function EndFrames = getListOfEndFramesPerTrack(obj, Frames)
            EndFrames =    cellfun(@(x) obj.getMax(x)   ,  Frames);   
        end
        
        function Number = getMax(~, List)
            if isempty(List)
                Number = 0; 
            else
                Number = max(List);
            end
            
        end
        
        % getNumberOfFramesPerTrack:
         function numberOfFrames = getNumberOfFramesPerTrack(obj,FrameLists)
           
             numberOfFrames =      cellfun(@(x) length(x)   , FrameLists);   
         end
         
       % getMissingFramesPerTrack:
       function MissingFrames = getMissingFramesPerTrack(obj, Frames)
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
        
  
         

        function [CurrentFrameList] =        convertObjectListIntoConciseObjectList(obj, CurrentFrameList)
            if isempty(CurrentFrameList)
                CurrentFrameList =    obj.getEmptySegmentation;
            else
                 CurrentFrameList(:,obj.PixelColumn) =                  cellfun(@(x) size(x,1), CurrentFrameList(:,obj.PixelColumn), 'UniformOutput', false);
                CurrentFrameList(:, obj.SegmentationTypeColumn) =        obj.extractSegmentationTypeFromList(CurrentFrameList(:, obj.SegmentationTypeColumn));
            end
            
           
        end
        
        function SegmentationTypeList = extractSegmentationTypeFromList(~, List)
            
            List{1, 1}.SegmentationType
            try
                SegmentationTypeList =                 cellfun(@(x) x.SegmentationType, List, 'UniformOutput', false);
            catch
                     SegmentationTypeList =                 cellfun(@(x) x.getSegmentationType, List, 'UniformOutput', false);
            end
            
                
           

            
             %% 2: current data:
             RowsWithSegmentationCapture =                            cellfun(@(x) strcmp(class(x), 'PMSegmentationCapture'), SegmentationTypeList);
             SegmentationTypeList(RowsWithSegmentationCapture,:) =    cellfun(@(x) x.getSegmentationType, SegmentationTypeList(RowsWithSegmentationCapture,:), 'UniformOutput', false);

             %% 3: very old data with no information:
             EmptyRows =                                    cellfun(@(x) isempty(x), SegmentationTypeList);
             SegmentationTypeList(EmptyRows,:) =        {'Not specified'};


        end
        
        
        
        
    end
     
    methods % methods with bad names that are currently called from outside;
       
             function pixelList =                                getPixelsOfActiveMaskFromFrame(obj, Frame)
                  wantedRow =      obj.getRowInSegmentationForFrameTrackID(Frame, obj.ActiveTrackID);
                if isempty(wantedRow)
                    segmentationOfActiveMask =        obj.getEmptySegmentation;
                else

                    segmentationOfActiveMask =  obj.getTrackingSegmentationForFrameRowColumn(Frame, wantedRow);
                    
                    
                end
                 
                 if isempty(segmentationOfActiveMask)
                     pixelList =        zeros(0, 3);
                 else
                   
                     pixelList =       segmentationOfActiveMask{1, obj.PixelColumn};
                 end
                 
                 
            end
        
        
    end
    
    methods % setter TRACKINGCELLFORTIME
        
        
        function obj = setTrackingCellForTimeWithDriftByDriftCorrection(obj, DriftCorrection)

                    MaximumTrackedFrame =      obj.getMaxFrame;

                    assert(MaximumTrackedFrame <= DriftCorrection.getNumberOfFrames, 'Drift correction does not span tracking range.')

                    rowShifts =         DriftCorrection.getRowShifts;
                    columnShifts=       DriftCorrection.getColumnShifts;
                    planeShifts =       DriftCorrection.getPlaneShifts;
                    
                
                    obj.TrackingCellForTimeWithDrift = obj.getTrackingCellForTimeForFrames(NaN);

                    fprintf('Adding drift correction to frame: ')
                    for FrameIndex = 1 : MaximumTrackedFrame

                        fprintf('%i ', FrameIndex)
                        
                     
                        [X]=    obj.getTrackingSegmentationForFrameRowColumn(FrameIndex, NaN, [obj.CentroidYColumn, obj.CentroidXColumn, obj.CentroidZColumn]);
                    
                        
                      
                        
                   
                        obj.TrackingCellForTimeWithDrift{FrameIndex}(:, obj.CentroidYColumn) =  num2cell(cell2mat(X(:, 1)) + rowShifts(FrameIndex));
                        obj.TrackingCellForTimeWithDrift{FrameIndex}(:, obj.CentroidXColumn) =  num2cell(cell2mat(X(:, 2)) + columnShifts(FrameIndex));
                        obj.TrackingCellForTimeWithDrift{FrameIndex}(:, obj.CentroidZColumn) =  num2cell(cell2mat(X(:, 3)) + planeShifts(FrameIndex));
                        
                      
                    end
                    fprintf('\n');

        end
        
        
        
    end
    
    methods (Access = private) % setters for TrackingCellForTime with and without drift;
      
        function obj = setTrackingCellForTime(obj, Value, varargin)
           
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
               
        function obj = setTrackSegmentationForFrameRowColumn(obj, Frame, Rows, Columns, varargin)

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
               error('Currently not supported.')

            end

            assert(length(NewMask) == length(Columns), 'Wrong input.')

            obj.TrackingCellForTime{Frame, 1}(Rows, Columns) =              NewMask;
            obj.TrackingCellForTimeWithDrift{Frame, 1}(Rows, Columns) =     NewMaskWithDrift;

        end

            function obj = testNumericScalar(obj, Value)
                Test = isnumeric(Value) && isscalar(Value) && ~isnan(Value);
                if ~Test
                    error('Wrong input.')
                end
                
                
            end
            
            function obj = testNanScalarOrNumVector(obj, Value)
                
                assert(isnumeric(Value), 'Input must be numeric.')
                
                if isscalar(Value) && isnan(Value)
                    
                elseif isvector(Value) && (min(isnan(Value)) == 0)
                   
                else
                    error('Input has to be either nan scalar or numeric vector.')
                    
                end
                
            end
            
            function obj = deleteTrackSegmentationForFrameRows(obj, Frame, RowsToDelete)
                assert(isnumeric(Frame) && isscalar(Frame) && ~isnan(Frame), 'Wrong input.')
                obj.TrackingCellForTime{Frame, 1}(RowsToDelete,:) =                   [];
                obj.TrackingCellForTimeWithDrift{Frame, 1}(RowsToDelete,:) =                   [];
                
            end
          
           
            function obj = setTargetColumnOfTrackingCellWithValueAddress(obj, Column, Value, Address)
                for Index = 1: size(Address, 1)
                    
                    MyFrame =       Address(Index, 1);
                    MyRow =         Address(Index, 2);
                    obj =           obj.setTrackSegmentationForFrameRowColumn(MyFrame, MyRow, Column, Value);
                    
                end
            end
            
            
               

         % deleteActiveMask:
         function obj =         deleteActiveMask(obj)
             
                  TargetRow =      obj.getTargetRowForFrameTrackID(obj.ActiveFrame, obj.ActiveTrackID);
               obj =            obj.setTrackSegmentationForFrameRowColumn(obj.ActiveFrame, TargetRow, NaN, obj.getBlankSegmentation);
             
             
         end
         
        function [obj] =              truncateTrackToFitMask(obj, mySelectedTrackIDs)
            OverlappingFrames =         obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
            for Index = 1 : length(OverlappingFrames)
                
                   TargetRow =      obj.getTargetRowForFrameTrackID(OverlappingFrames(Index), mySelectedTrackIDs(1));
               obj =            obj.setTrackSegmentationForFrameRowColumn(OverlappingFrames(Index), TargetRow, NaN, obj.getBlankSegmentation);
               
                
            end

        end

        function obj =                          removeMask(obj, TrackID, CurrentFrame)
             obj =       obj.setTrackForFrameTrackIDWithMasks(CurrentFrame, TrackID, obj.getBlankSegmentation); 
        end

          function obj = setTrackForFrameTrackIDWithMasks(obj, Frame, Track, varargin)
              
               TargetRow =      obj.getTargetRowForFrameTrackID(Frame, Track);
               obj =            obj.setTrackSegmentationForFrameRowColumn(Frame, TargetRow, NaN, varargin{:});
               
          end
          
        
          
          
               function [TargetRow]=          getTargetRowForFrameTrackID(obj, Frame, TrackID)
   
                   TargetRow =        obj.getRowInSegmentationForFrameTrackID(Frame, TrackID);
                   
                    if isempty(TargetRow)
                        MySegmentationList =        obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
                        TrackIDsInWantedFrame =     obj.getTrackIDsFromSegmentationList(MySegmentationList);
                        TargetRow =                 find(isnan(TrackIDsInWantedFrame), 1, 'first');

                    end

                    if isempty(TargetRow)
                        SegmentationOfWantedFrame =             obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
                        TargetRow=                      size(SegmentationOfWantedFrame, 1) + 1;

                    end
                    assert(isnumeric(TargetRow) && TargetRow >= 1 && ~isnan(TargetRow) && ~isempty(TargetRow), 'Wrong result')
                    
               end
               
                function Row = getRowInSegmentationForFrameTrackID(obj, Frame, TrackID)
                    MyTrackingCell =            obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
                    TrackIDsInWantedFrame =     obj.getTrackIDsFromSegmentationList(MyTrackingCell);
                    Row=                        find(TrackIDsInWantedFrame == TrackID);   
                    
                end
          
          
                
      
    end
    
    methods (Access = private) % setters TRACKINGCELLFORTIME old
        
         function obj = removeMasksByMaxPlaneLimit(obj, Value)
                  error('Change without test. Verify before using.')
                  obj.TrackingCellForTime =     cellfun(@(x) obj.removeMasksByMaxPlaneLimitForList(x, Value), obj.TrackingCellForTime , 'UniformOutput', false);
                  obj =                         obj.selectAllTracks;
         end

    end
  
    methods (Access = private) % getters TrackingCellForTime

        function number = getNumberOfCellsInFrame(obj, Frame)
            
            number = size(obj.getTrackingCellForTimeForFrames(Frame), 1);
            
        end
        
        function [TrackingCell, TrackingCellDrift] = getTrackingCellForTimeForFrames(obj, Frames)

            obj.testNanScalarOrNumVector(Frames);
            if isnan(Frames)
                TrackingCell = obj.TrackingCellForTime;
                if isempty(obj.TrackingCellForTimeWithDrift)
                    TrackingCellDrift = cell(0, 1);
                else
                    TrackingCellDrift = obj.TrackingCellForTimeWithDrift;
                end
                
                
            elseif isscalar(Frames)
                
                if isempty(obj.TrackingCellForTime)
                    TrackingCellDrift = cell(0, 7);
                    TrackingCell = cell(0,7);
                else
                        TrackingCell = obj.TrackingCellForTime{Frames};
                 if isempty(obj.TrackingCellForTimeWithDrift)
                     TrackingCellDrift = cell(0, 7);
                 else
                    TrackingCellDrift = obj.TrackingCellForTimeWithDrift{Frames};
                 end
                    
                end
                
             
                            
            else
                error('Not yest supported.')

            end

        end

        function Segmentation = getTrackingSegmentationForFrameRowColumn(obj, Frame, Row, Column)
            Segmentation = obj.getTrackingSegmentationForFrameRowColumnPropertyName(Frame, Row, Column, 'TrackingCellForTime');
        end
        
        function Segmentation = getTrackingSegmentationWithDriftForFrameRowColumn(obj, Frame, Row, Column)
            Segmentation = obj.getTrackingSegmentationForFrameRowColumnPropertyName(Frame, Row, Column, 'TrackingCellForTimeWithDrift');
        end
        
        function Segmentation = getTrackingSegmentationForFrameRowColumnPropertyName(obj, Frame, Row, Column, Property)
            
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

       
    end
  
    methods (Access = private) % getter TrackingSegmentation
        
        function [pooledData, pooledDataWithDrift] =                   getPooledTrackingData(obj)

            assert(iscell(obj.getTrackingCellForTimeForFrames(NaN)), 'Wrong format.')

            pooledData =          vertcat(obj.TrackingCellForTime{:});
            if isempty(pooledData)
                pooledData =         obj.getEmptySegmentation;
            end

            pooledDataWithDrift =       vertcat(obj.TrackingCellForTimeWithDrift{:});   
            if isempty(pooledDataWithDrift)
                pooledData =         obj.getEmptySegmentation;
            end
            
        end

         function segmentation = getSegmentationWithAppliedDriftForFrame(obj, Frame, DriftCorrection)
             
             if DriftCorrection.getDriftCorrectionActive
                 noDrift =                  obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);
                 segmentation =             obj.TrackingCellForTimeWithDrift{Frame,1};
                 segmentation(:, 6) =       noDrift(:, 6);

             else
                 segmentation =      obj.getTrackingSegmentationForFrameRowColumn(Frame, NaN, NaN);

             end
             
         end


    
        
    end
  
    
    methods % getters track-related
        
         function maxFrame = getMaxFrame(obj)
            maxFrame = length(obj.getTrackingCellForTimeForFrames(NaN));
            
        end
        
        
        
    end
    
    methods (Access = private) % getters track-related
        
       
        function Tracks = getUniqueTrackIDsFromTrackingCell(obj)
            Tracks =                        unique(obj.getTrackIDsFromSegmentationList(obj.getPooledTrackingData));
            Tracks(isnan(Tracks), :) =      [];
        end
 
    end
    
    methods % setters
        
        function obj = setActiveTrackID(obj, Value) % this may not be used?
            obj.ActiveTrackID =     Value;
        end

        function obj =      setActiveTrackIDTo(obj, newActiveTrackID) %when do you use setActiveTrackID a and when setActiveTrackIDTo?

            assert(isnumeric(newActiveTrackID) && isscalar(newActiveTrackID), 'Wrong input.')

            oldActive =                 obj.ActiveTrackID;
            obj =                       obj.removeTrackIDsFromSelectedTracks(newActiveTrackID);
            obj.ActiveTrackID =         newActiveTrackID; 
            if newActiveTrackID ~= oldActive
                obj =                   obj.addToSelectedTrackIds(oldActive);
            end

            SelectedReal =              obj.removeTrackIdsThatDoNotExist(obj.SelectedTrackIDs);
            obj =                       obj.setSelectedTrackIdsTo(SelectedReal);
            fprintf('New active track ID = %i.\n', obj.ActiveTrackID);

        end

        function [obj] =   setActiveFrameTo(obj,Value)
            obj.ActiveFrame = Value;
        end

        function obj =  setSelectedTrackIdsTo(obj, Numbers)
            obj.SelectedTrackIDs =      Numbers;
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
            
              
        function obj = addMissingTrackIdsToTrackInfoListForMaxTrack(obj, MaximumTrack)
            if size(obj.TrackInfoList, 1) < MaximumTrack
                obj.TrackInfoList{MaximumTrack, 1} = ''; 
            end

            WrongRows =                             find(cellfun(@(x) ~isa(x, 'PMTrackInfo'), obj.TrackInfoList));
            obj.TrackInfoList(WrongRows, :) =       arrayfun(@(x) PMTrackInfo(x), WrongRows, 'UniformOutput', false);
            
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

        function obj = addToSelectedTrackIds(obj, Value)

            OldSelectedTrackIds =       obj.getIdsOfSelectedTracks;
            IdsIWantToAdd =             Value(:);
            NewSelectedTrackIds =       unique([ OldSelectedTrackIds; IdsIWantToAdd]);  
            NewSelectedTrackIds =       obj.removeTrackIdsThatDoNotExist(NewSelectedTrackIds); 
            obj =                       obj.setSelectedTrackIdsTo(NewSelectedTrackIds);

        end

        
    end
    
    methods % active track
        
         function segmentation = getActiveTrack(obj)
            segmentation = obj.getSegementationForActiveTrack;
            
        end
        
    end
    
    methods % active mask
        
        function coordinates = extractCoordinatesFromTrackList(obj, TrackList)
                if isempty(TrackList)
                   coordinates = zeros(0,3); 
                else
                    coordinates =        cell2mat( TrackList(:,   [obj.CentroidXColumn, obj.CentroidYColumn, obj.CentroidZColumn]));  
                end
            
            end
        
        
        
    end
    
    methods (Access = private)% active mask
        
        function mask = getActiveMask(obj)
            mask = PMMask(obj.getSegmentationForActiveMask);
        end
   
        function segmentationOfActiveMask = getSegmentationForActiveMask(obj)
            wantedRow =                     obj.getRowInSegmentationForFrameTrackID(obj.ActiveFrame, obj.ActiveTrackID);
            segmentationOfActiveMask =      obj.getTrackingSegmentationForFrameRowColumn(obj.ActiveFrame, wantedRow, NaN);
        end
        
       
            
         
        function EmptyContent = getEmptySegmentation(obj)
                EmptyContent =                      cell(0, obj.NumberOfColumns);
        end
               
        
    
         
          
      
        
           function trackIDs =                                 getTrackIDsFromSegmentationList(obj, SegmentationList)
                if isempty(SegmentationList)
                    trackIDs =       zeros(0,1);
                else
                    trackIDs =       cell2mat(SegmentationList(:, obj.TrackIDColumn));
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
             
         
            
            function Masks = extractMasksFromTrackList(obj, List)
                Masks =   cell2mat(List(:,obj.PixelColumn));
            end
              
        
    end
    
    methods % get coordinates
        
        function Coordinates = getCoordinatesForActiveTrackPlanes(obj,  Planes, varargin)
             Coordinates =       obj.getCoordinatesForTrackIDsInternal(obj.ActiveTrackID, Planes,  varargin{:});
             Coordinates = Coordinates{1};
        end
        
        function Coordinates = getCoordinatesForTrackIDsPlanes(obj, TrackIDs, Planes, varargin)
            Coordinates =       obj.getCoordinatesForTrackIDsInternal(TrackIDs, Planes,  varargin{:});
        end

    end
    
    methods (Access = private) % get coordinates;
        
       function Coordinates = getCoordinatesForTrackIDsInternal(obj, TrackIDs, Planes, varargin)
        
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
       
       function ListWithAllCoordinates = getListWithAllCoordinatesByDriftCorrection(obj, varargin)
           
                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 0
                            ListWithAllCoordinates = obj.getListWithAllCoordinates;

                    case {1, 2}

                        ClasseTypes =   cellfun(@(x) class(x), varargin, 'UniformOutput', false);
                        if sum(strcmp(ClasseTypes, 'PMDriftCorrection')) == 1
                            DriftCorrection = varargin{strcmp(ClasseTypes, 'PMDriftCorrection')};
                           switch DriftCorrection.getDriftCorrectionActive
                                case true
                                    ListWithAllCoordinates = obj.getListWithAllDriftCorrectedCoordinates;
                                otherwise
                                    ListWithAllCoordinates = obj.getListWithAllCoordinates;
                          end
                           
                        else
                            error('Wrong input.')
                            
                        end
                        
                    otherwise
                        error('Wrong input.')
                end
           
       end
       
       function ListWithAllCoordinates = getListWithAllCoordinates(obj)
            ListWithAllCoordinates = arrayfun(@(x) obj.extractCoordinatesFromTrackList(obj.getTrackingCellForTimeForFrames(x)), (1 : obj.getMaxFrame)', 'UniformOutput', false); 
       end
       
       function ListWithAllCoordinates = getListWithAllDriftCorrectedCoordinates(obj)
          ListWithAllCoordinates = arrayfun(@(x) obj.extractCoordinatesFromTrackList(obj.TrackingCellForTimeWithDrift{x}), 1 : obj.getMaxFrame, 'UniformOutput', false); 
       end
       
       function Coordinates = roundCoordinates(obj, Coordinates)
           Coordinates(:, 3) = round(Coordinates(:, 3));
       end
       
       function Coordinates = replaceWrongPlaneWithNan(obj, Coordinates, PlaneLimits)
           
           RowsToDeleteOne = Coordinates(:, 3) <  min(PlaneLimits) - 1; % make planes that are just barely out of view visible; otherwise tracks are just bits and pieces
           RowsToDeleteTwo = Coordinates(:, 3) >  max(PlaneLimits) + 1;
           
           RowsToChange = max([RowsToDeleteOne, RowsToDeleteTwo], [], 2);
           
           Coordinates(RowsToChange, :) = NaN;
           
       end
       
       
       function ListWithAllCoordinates = getListWithAllCoordinatesByDriftCorrectionInput(obj, DriftCorrection)
           % gets drift corrected coordinates only when drift-correction is
           % set to active;
              switch DriftCorrection.getDriftCorrectionActive
                    case true
                        ListWithAllCoordinates = obj.getListWithAllDriftCorrectedCoordinates;
                    otherwise
                        ListWithAllCoordinates = obj.getListWithAllCoordinates;
              end
           
       end
       
     
         function Coordinates = filterCoordinatesBySegmentationAddress(~, ListWithAllCoordinates, ListWithAddressesOfWantedTracks)
           
               Coordinates = zeros( size(ListWithAddressesOfWantedTracks, 1), 3);
               for Index = 1: size(ListWithAddressesOfWantedTracks, 1)
                   Data =                       ListWithAllCoordinates{ListWithAddressesOfWantedTracks(Index, 1)}(ListWithAddressesOfWantedTracks(Index, 2), :);
                   Coordinates(Index, 1: 3) =   Data;
               end
           
         end
       
       
       
        
        
    end
    
    methods % get segmentation
        
          function Segmentation = getDriftCorrectedSegementationForTrackID(obj, TrackID)
                assert(isnumeric(TrackID) && isscalar(TrackID) && ~isnan(TrackID), 'Wrong input.')
                Segmentation =          obj.getDriftCorrectedSegmentationWithSegmentAddress(obj.TrackInfoList{TrackID,1}.getSegmentationAddress);
          end
       
          function filteredList = filterMatrixByFirstColumnForValues(~, Matrix, Values)
               MatchingRows =      ismember(Matrix(:, 1), Values);
            filteredList =        Matrix(MatchingRows,:);
          end
          
         function [objectList]=          filterObjectListForFrames(obj, WanteFrames, List)
            AvailableFrames =   cell2mat(List(:, obj.TimeColumn));
            MatchingRows =      ismember(AvailableFrames, WanteFrames);
            objectList =        List(MatchingRows,:);
        end
        
    end
    
    methods (Access = private) % segmentation
        
       
        
         function Segmentation = getDriftCorrectedSegmentationWithSegmentAddress(obj, Address)
             
            Segmentation = cell(size(Address, 1), obj.NumberOfColumns);
            for Index = 1: size(Address, 1)
                MyFrame = obj.TrackingCellForTimeWithDrift{Address(Index, 1)};
                Segmentation(Index, 1 : obj.NumberOfColumns) =   MyFrame(Address(Index, 2), 1 : obj.NumberOfColumns);
            end

        end
        
        
        
        
    end
    
    methods (Access = private) % segmentation addresses
         
         function obj = updateSegmentationAddressInTrackInfoListForIDs(obj, TrackID)
             
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
              FinalizedAddressListOfCurrentTrack =            obj.getRawSegmentationAddressFromTrackingMatrixForTrackID(TrackID);
            
            Results = cellfun(@(x) isscalar(x), FinalizedAddressListOfCurrentTrack(:, 2));
            if min(Results) == 0
                error('At least one address is not a scalar, which should not be the case.')
            end
            
            FinalizedAddressListOfCurrentTrack =            cell2mat(FinalizedAddressListOfCurrentTrack);
             
         end
         
         function WrongAddressList = getListOfCorruptAddressesForTrackID(obj, TrackID)
            AdressListOfCurrentTrack =                      obj.getRawSegmentationAddressFromTrackingMatrixForTrackID(TrackID);
            WrongAddressList =                              obj.getListOfCorruptAddressList(AdressListOfCurrentTrack);
         end
         

            function  ListWithSegmentationAddresses = getRawSegmentationAddressFromTrackingMatrixForTrackID(obj, TrackID)

                TargetRowsForAllFrames_ShouldBeCorrect =                        arrayfun(@(x) obj.getRowInSegmentationForFrameTrackID(x, TrackID), 1 : obj.getMaxFrame, 'UniformOutput', false);
                ListWithSegmentationAddresses(1 : obj.getMaxFrame, 2) =         TargetRowsForAllFrames_ShouldBeCorrect;
                ListWithSegmentationAddresses(:, 1) =                           num2cell(1 : obj.getMaxFrame);
                
                EmptyRows =                                         cellfun(@(x) isempty(x), ListWithSegmentationAddresses(:, 2));
                ListWithSegmentationAddresses(EmptyRows, :) =                   [];
            
                
               
            end
            
            
        
          
            
            
            
           
            
            function WrongAddressList = getListOfCorruptAddressList(obj, ListWithSegmentationAddresses)
 
                IndicesWithMultipleTargetRows =     cellfun(@(x) length(x) > 1, ListWithSegmentationAddresses(:, 2));
                WrongAddressList =                  ListWithSegmentationAddresses(IndicesWithMultipleTargetRows, :);
                
            end
            
            function obj = removeDuplicateAddressesFromTrackingCell(obj, WrongAddresList)
                
                for Index = 1 : length(WrongAddresList)
                    
                    WrongAddress =                      WrongAddresList(Index, :);
                    FrameNumberOfInspectedTrack =       WrongAddress{1, 1};
                    AllTargetRowsForCurrentFrame =      WrongAddress{1, 2};

                    NotOkRows =                         AllTargetRowsForCurrentFrame(2:end);
                    
                    for InternalIndex = 1: length(NotOkRows)
                        RowThatShouldBeBlankedOut =     NotOkRows(InternalIndex);
                        obj =                           obj.setTrackSegmentationForFrameRowColumn(FrameNumberOfInspectedTrack, RowThatShouldBeBlankedOut, NaN, obj.getBlankSegmentation);
                    end

                end
            end
            


        
        
        
    end
    
    methods % active track

        function [IdOfActiveTrack] =        getIdOfActiveTrack(obj)
            IdOfActiveTrack =                 obj.ActiveTrackID;
        end

           function Coordinates = getActiveCentroidAtFramePlaneDrift(obj, Frame, Plane, Drift)
                Segmentation =      obj.getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(Frame,Plane, obj.ActiveTrackID, Drift);
                Coordinates =       obj.extractCoordinatesFromTrackList(Segmentation);

           end

             function Coordinates = getActiveMasksAtFramePlaneDrift(obj, Frame, Plane, Drift)
                Segmentation =      obj.getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(Frame, Plane, obj.ActiveTrackID, Drift);
                Coordinates =       obj.extractMasksFromTrackList(Segmentation);
             end

              function Segmentation =             getSegmentationOfActiveTrack(obj)
                if isnan(obj.ActiveTrackID)
                    Segmentation =      obj.getEmptySegmentation;
                else
                      Address =           obj.TrackInfoList{obj.ActiveTrackID, 1}.getSegmentationAddress;
                       Segmentation =      arrayfun(@(x, y) ...
                                            obj.getTrackingSegmentationForFrameRowColumn(x, y, NaN), ...
                                            Address(:, 1), Address(:, 2), 'UniformOutput', false);
                end

              end

                  function Limits =  getLimitsOfFirstGapOfActiveTrackForLimitValue(obj, Value)
                Limits =      PMVector(obj.getFrameNumbersForTrackID(obj.ActiveTrackID)).getLimitsOfFirstForwardGapForLimitValue(  Value);
            end




    end

    methods % filter centroids for plane-requirement

            function Coordinates = getSelectedCentroidsAtFramePlaneDrift(obj, Frame, Plane, Drift, varargin)
                Segmentation =      obj.getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(Frame,Plane, obj.SelectedTrackIDs, Drift, varargin{:});
                Coordinates =       obj.extractCoordinatesFromTrackList(Segmentation);
            end

            function selectedSegmentation =        getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(obj, Frames, Planes, TrackIDs, DriftCorrection, varargin)
                selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frames, DriftCorrection);
                selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, TrackIDs);
                selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes, varargin{:});


            end


            function selectedSegmentation =        getSelectedSegmentationForFramesPlanesDriftCorrection(obj, Frames, Planes, DriftCorrection)
                selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frames, DriftCorrection);
                selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, obj.SelectedTrackIDs);
                selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes);


            end

              function selectedSegmentation = filterSegmentationListForPlanes(obj, selectedSegmentation, Planes, varargin)
                selectedSegmentation(:, obj.PixelColumn) =                cellfun(@(x) obj.filterPixelListForPlane(x, Planes, varargin{:}), selectedSegmentation(:,obj.CentroidZColumn), 'UniformOutput', false);
                selectedSegmentation(obj.getRowsOfTracksWithEmptyPixels(selectedSegmentation), :) = [];

            end

           function [list] =               filterPixelListForPlane(~, list, SelectedPlane, varargin)


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








    end

    methods % minimize track:

       function obj = minimizeActiveTrack(obj)

            MySeg =                 obj.getSegmentationForTrackID(obj.getIdOfActiveTrack);
            MiniSeg =               obj.getMiniMask(MySeg);

            MyDriftSeg =            obj.getSegmentationForTrackID(obj.getIdOfActiveTrack, 'getTrackingSegmentationWithDriftForFrameRowColumn');
            MiniSegWithDrift =      obj.getMiniMask(MyDriftSeg);

            obj =                    obj.replaceMaskInTrackingCellForTimeWith(MiniSeg, MiniSegWithDrift);

       end

         function Segmentation = getSegmentationForTrackID(obj, TrackID, varargin)
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
                    Address =               obj.TrackInfoList{TrackID,1}.getSegmentationAddress;

                        Segmentation =      arrayfun(@(x, y) ...
                                            obj.(MethodName)(x, y, NaN), ...
                                            Address(:, 1), Address(:, 2), 'UniformOutput', false);
                end

         end


         function [SegmentationData] =       getMiniMask(obj, SegmentationData)
               MiniCoordinateList(:,1) =    arrayfun(@(x) [round(SegmentationData{1,obj.CentroidXColumn}), round(SegmentationData{1,obj.CentroidXColumn}), x], min(SegmentationData{1,obj.PixelColumn}(:,3)):max(SegmentationData{1,obj.PixelColumn}(:,3)), 'UniformOutput',false); 
               MiniCoordinateList =         vertcat(MiniCoordinateList{:});
               assert(~isempty(MiniCoordinateList), 'Cannot corrupt database with empty coordinate list')
               SegmentationData{1,obj.PixelColumn} =        MiniCoordinateList;
         end





        function obj =                                replaceMaskInTrackingCellForTimeWith(obj, Mask)
            [Frame, Row ] =         obj.getFrameAndRowInTrackTimeCellForMask(Mask);
            obj =                   obj.setTrackSegmentationForFrameRowColumn(Frame, Row, NaN, Mask, DriftMask);


        end


         function [FrameNumber, RowNumber ] =     getFrameAndRowInTrackTimeCellForMask(obj, Mask)

            assert(size(Mask,1) == 1, 'This function only accepts a single mask as input.')
            FrameNumber =                   Mask{1,obj.TimeColumn};


            MyTrackingCellForTime  =        obj.getTrackingCellForTimeForFrames(FrameNumber);
            RowNumber =                     cell2mat(MyTrackingCellForTime(:,obj.TrackIDColumn)) ==  Mask{1,obj.TrackIDColumn};
            WarningText =                   sprintf('The data file or input is corrupt. There are %i repeats of track %i in frame %i. There should be 1 precisely', sum(RowNumber),  Mask{1,obj.TrackIDColumn}, FrameNumber);
            assert(sum(RowNumber) == 1, WarningText)

         end






    end

    methods % file-management
        
        function obj = setMainFolder(obj, Value)
           obj.MainFolder = Value; 
        end
        
        function obj = load(obj)
           
            tic
            load([obj.MainFolder, '/Main.mat'], 'MainTrackingInfo')
            a = toc;
            
            obj.TrackInfoList = MainTrackingInfo.TrackInfoList;

            obj.ActiveTrackID = MainTrackingInfo.ActiveState.ActiveTrackID ;
            obj.ActiveFrame = MainTrackingInfo.ActiveState.ActiveFrame          ;

            obj.SelectedTrackIDs = MainTrackingInfo.ActiveState.SelectedTrackIDs;

            obj.PreventDoubleTracking = MainTrackingInfo.DoubleTracking.PreventDoubleTracking;
            obj.DistanceForDoubleTracking = MainTrackingInfo.DoubleTracking.DistanceForDoubleTracking;

            obj.FirstPassDeletionFrameNumber= MainTrackingInfo.AutoTracking.FirstPassDeletionFrameNumber  ;
            obj.AutoTrackingConnectionGaps = MainTrackingInfo.AutoTracking.AutoTrackingConnectionGaps ;

             obj.MaximumAcceptedDistanceForAutoTracking = MainTrackingInfo.AutoTracking.MaximumAcceptedDistanceForAutoTracking ;
            obj.DistanceLimitXYForTrackMerging = MainTrackingInfo.AutoTracking.DistanceLimitXYForTrackMerging ;
             obj.DistanceLimitZForTrackingMerging = MainTrackingInfo.AutoTracking.DistanceLimitZForTrackingMerging  ;

             BlankSegmentation = obj.getBlankSegmentation;
             MyTrackingCellForTime = cell(length(MainTrackingInfo.TrackingCellForTime), 1);
             for index = 1 : length(MainTrackingInfo.TrackingCellForTime)
                 MyTrackingCellForTime{index, 1} = num2cell(MainTrackingInfo.TrackingCellForTime{index});
                 
                 MyTrackingCellForTime{index, 1}(:, 6) = BlankSegmentation(6);
                 MyTrackingCellForTime{index, 1}(:, 7) = BlankSegmentation(7);
                 
             end
             
             obj.TrackingCellForTime = MyTrackingCellForTime;
             
             
        end
        
        function obj = save(obj)
            obj =   obj.saveBasic;
            obj =   obj.saveDetailed;
            
        end
        
        function obj = saveBasic(obj)
            
           if exist(obj.MainFolder) ~=7
              mkdir(obj.MainFolder) 
           end
           
            MainTrackingInfo = obj.getStructureForStorage;
            
            if ~isempty(obj.TrackingCellForTime)
            ExportCell = cellfun(@(x) cell2mat(x(:, 1:5)), obj.TrackingCellForTime, 'UniformOutput', false);
            MainTrackingInfo.TrackingCellForTime = ExportCell;
            tic
            save([obj.MainFolder, '/Main.mat'], 'MainTrackingInfo')
           a = toc;
           
            fprintf('Saving of the basic tracking file took %6.1f seconds.', a)
            
            end
        end
        
        function obj = saveDetailed(obj)
            
              if exist(obj.MainFolder) ~=7
                mkdir(obj.MainFolder) 
              end
           
              
           tic
           MaskPixels = cellfun(@(x) x(:, 6), obj.TrackingCellForTime, 'UniformOutput', false);
           
           
            SegmentationInfo = cellfun(@(x) x(:, 7), obj.TrackingCellForTime, 'UniformOutput', false);
           for index = 1 : length(obj.TrackingCellForTime)
              for CellIndex = 1 : size(obj.TrackingCellForTime{index}, 1)
              
                SegmentationInfo{index}{CellIndex, 1} = obj.TrackingCellForTime{index}{CellIndex, 7}.SegmentationType.getSummaryStructure;
              end
           end
           
           toc
           
           toc
           
            
        end
        
    end
    
    methods (Access = private) % file management
        
        function structure = getStructureForStorage(obj)

            structure.TrackInfoList =               obj.TrackInfoList;

            structure.ActiveState.ActiveTrackID  =              obj.ActiveTrackID;
            structure.ActiveState.ActiveFrame =                 obj.ActiveFrame;

            structure.ActiveState.SelectedTrackIDs =           obj.SelectedTrackIDs;


            structure.DoubleTracking.PreventDoubleTracking =            obj.PreventDoubleTracking;
            structure.DoubleTracking.DistanceForDoubleTracking =        obj.DistanceForDoubleTracking;

            structure.AutoTracking.FirstPassDeletionFrameNumber  =      obj.FirstPassDeletionFrameNumber;
            structure.AutoTracking.AutoTrackingConnectionGaps =         obj.AutoTrackingConnectionGaps;

            structure.AutoTracking.MaximumAcceptedDistanceForAutoTracking  =    obj.MaximumAcceptedDistanceForAutoTracking;
            structure.AutoTracking.DistanceLimitXYForTrackMerging =             obj.DistanceLimitXYForTrackMerging;
            structure.AutoTracking.DistanceLimitZForTrackingMerging  =          obj.DistanceLimitZForTrackingMerging;

        end
        
    end
    
    
    methods
        
            
       function obj = setDistanceForDoubleTracking(obj, Value)
          obj.DistanceForDoubleTracking = Value;
       end
         
            function obj = setPreventDoubleTracking(obj, Value, Value2)
               obj.PreventDoubleTracking = Value;
                obj.DistanceForDoubleTracking = Value2;
            end
            
           
            
            
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

        
          %% updateWith
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
            function values = getFieldNamesOfTrackingCell(obj)
                values = obj.FieldNamesForTrackingCell;
            end

            function [obj] =  setDistanceLimitXYForTrackMerging(obj, Value)
                obj. DistanceLimitXYForTrackMerging =                        Value;
            end

            function [obj] =  setDistanceLimitZForTrackingMerging(obj, Value)
            obj. DistanceLimitZForTrackingMerging =                        Value;
            end

            function [obj] =  setShowDetailedMergeInformation(obj, Value)
            obj. ShowDetailedMergeInformation =                        Value;
            end


           
            

       


            function PooledSegmentation = getPooledSegmentation(obj)
                error('Use getPooledTrackingData instead of getPooledSegmentation.')
            end

            
          %% getPooledTrackingData
            
            function TrackList = getSortedTrackingData(obj)
                [TrackList, ~] =        obj.getPooledTrackingData;
                EmptyRows = max(cellfun(@(x) isempty(x) , TrackList(:,1)));
                
             
                
                if EmptyRows
                    warning('Cannot sort track list because there are empty rows.')
                else
                    NanRows =    cellfun(@(x) isnan(x), TrackList(:, 1));

                    TrackList(NanRows, :) = [];
                    
                    TrackList=              sortrows(TrackList,[obj.TrackIDColumn obj.TimeColumn]);  
                end
                
            end
            
          





          

          

           


          
            
        
            function exist = testForExistenceOfTracks(obj)
            exist =              obj.getNumberOfTracks >= 1;
            end

            function [ActiveFrame] =    getActiveFrame(obj)
            ActiveFrame =           obj.ActiveFrame;
            end

          %% generalCleanup
          function obj =   generalCleanup(obj)
                obj =           obj.reorderTrackInfoList;
                obj =           obj.addMissingTrackIdsToTrackInfoList;
                obj =           obj.addSegmentationAddressToAllTrackInfos; 
%                obj =           obj.setTrackImages;
                
            end
            
         
          
        

          function obj = setTrackImages(obj)
              
              for Index = 1 : obj.getMaxFrame
                obj = obj.updateTrackingImageForFrame(Index);
              end
              
              
              
          end
          
          function obj = updateTrackingImageForFrame(obj, Frame)
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

          

     

         

       
            function ListWithAllUniqueTrackIDs =    getListWithAllUniqueTrackIDs(obj)
                ListWithAllUniqueTrackIDs = find(cellfun(@(x) x.getExistenceOfSegmentationAddress, obj.TrackInfoList));
            end  

                     
          

          

            %% getSelectedCentroidsAtFrame


            function Segmentation = getSegmentationForFramesTrackIDs(obj, Frames, WantedTrackIDs, Drift)

                assert(isnumeric(Frames) && isscalar(Frames), 'Currently only scalars supported.')
                TrackIDsInWantedFrame =    obj.getTrackIDsFromSegmentationList(obj.getTrackingCellForTimeForFrames(Frames));
                 Rows=                      ismember(TrackIDsInWantedFrame, WantedTrackIDs);

                if Drift.getDriftCorrectionActive
                    Segmentation =             obj.getTrackingSegmentationWithDriftForFrameRowColumn(Frames, Rows, NaN);
                else
                    Segmentation =             obj.getTrackingSegmentationForFrameRowColumn(Frames, Rows, NaN);
                end


            end

            %% getActiveCentroidAtFramePlaneDrift

         


       
       

            function FilteredList = filterSegementationListForSelectedTracks(obj, List, TrackIDs)
                 Rows = ismember( cell2mat(List(:, obj.TrackIDColumn)), TrackIDs);
                FilteredList = List(Rows, :);
            end

          

            function rowsWithEmptyPixels =          getRowsOfTracksWithEmptyPixels(obj, TrackList)
            rowsWithEmptyPixels     =           cellfun(@(x) isempty(x),   TrackList(:,obj.PixelColumn));

            end

            %% getSelectedMasksAtFramePlaneDrift
            function Coordinates = getSelectedMasksAtFramePlaneDrift(obj, Frame, Plane, Drift)
            Segmentation =      obj.getSelectedSegmentationForFramesPlanesTrackIDsDriftCorrection(Frame,Plane, obj.SelectedTrackIDs, Drift);
            Coordinates =       obj.extractMasksFromTrackList(Segmentation);
            end

      



          

 

            %% getIdsOfRestingTracks:
            function [RestingTrackIDs] =            getIdsOfRestingTracks(obj)
             UniqueTrackIDs =          obj.getListWithAllUniqueTrackIDs;
             NonRestingTracks =         [obj.ActiveTrackID; obj.getIdsOfSelectedTracks];
             RowsOfRestingTracks =      ~ismember(UniqueTrackIDs, NonRestingTracks);

             RestingTrackIDs =          UniqueTrackIDs(RowsOfRestingTracks);
            end

          
            function [IdsOfSelectedTracks] =                 getIdsOfSelectedTracks(obj)
            IdsOfSelectedTracks =           obj.SelectedTrackIDs;
            end

            %% get number of tracks:
            function numberOfTracks =   getNumberOfTracks(obj)
                ListWithAllUniqueTrackIDs =         obj.getListWithAllUniqueTrackIDs;
                if isempty(ListWithAllUniqueTrackIDs)
                    numberOfTracks =        0;
                else
                    numberOfTracks =        length(ListWithAllUniqueTrackIDs);
                end
            end

            %% removeRedundantData:
            function obj = removeRedundantData(obj)
            
                obj.TrackingCellForTimeWithDrift = cell(0, obj.NumberOfColumns);
                obj.TrackingAnalysis =              '';    
                obj.TrackImages =                   '';
                if ~isempty(obj.AutomatedCellRecognition)
                    obj.AutomatedCellRecognition  = obj.AutomatedCellRecognition.removeRedundantData;
                    
                end
            end

          
    
            %% getConciseObjectListOfActiveTrack
            function ConciseList=     getConciseObjectListOfActiveTrack(obj)
                ConciseList =       obj.convertObjectListIntoConciseObjectList(obj.getSegmentationOfActiveTrack);
            end

           

            %% getConciseObjectListOfFrame
            function [ConciseList] =        getConciseObjectListOfFrame(obj, FrameNumber)
                 if isempty(FrameNumber)
                     ConciseList =          obj.getEmptySegmentation;
                 else
                     List =                 obj.removeNanTracksFromSegmentation(obj.getTrackingCellForTimeForFrames(FrameNumber));
                     ConciseList =         obj.convertObjectListIntoConciseObjectList(List);
                 end
            end
            
            function Segmentation = removeNanTracksFromSegmentation(obj, Segmentation)
                Segmentation(isnan(cell2mat(Segmentation(:, obj.TrackIDColumn))), :) = [];
            end

            %% getAllSelectedCoordinates
            function Coordinates = getAllSelectedCoordinates(obj)


            end

            %% selectAllTracks:
            function obj = selectAllTracks(obj)
                AllTrackIDs = obj.getListWithAllUniqueTrackIDs;
                AllTrackIDs(AllTrackIDs == obj.ActiveTrackID, :) = [];
                obj =  obj.setSelectedTrackIdsTo(AllTrackIDs);
            end

        
            %% generateNewTrackID
            function newTrackID =                   generateNewTrackID(obj)
                
                CurrentTracks =         obj.getListWithAllUniqueTrackIDs;
                if isempty(CurrentTracks) 
                    newTrackID = 1;
                    
                else
                     GapRows =           find(diff(CurrentTracks) > 1);
                     if isempty(GapRows)
                         newTrackID = max(CurrentTracks) + 1;
                     else
                         newTrackID =        CurrentTracks(GapRows(1)) + 1; 
                     end
                     
                     
                     
                end
                
            end

            %% addSegmentation
            function obj = addSegmentationToFrame(obj, Frame)
                
                
            end
            
            
            function obj =   addSegmentation(obj, SegmentationCapture)
                
                
                try
                obj =       obj.setEntryInTrackingCellForTime(SegmentationCapture);
             catch E
                   throw(E) 
                end
                
                
                obj =       obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID);
               
                
            end

            %% trackingByFindingUniqueTargetWithinConfines
            function obj =                          trackingByFindingUniqueTargetWithinConfines(obj, Distance)
                obj.AutoTrackingActiveGap =       Distance;  
                obj =                          obj.trackingByFindingUniqueTargetWithinConfinesInteral;
            end

            %% filterTrackListForFrame
            function [filteredTrackingData] =     filterTrackListForFrame(obj, FrameNumber)        
            filteredTrackingData =         obj.getTrackingCellForTimeForFrames(FrameNumber);  
            end

            %% removeFromTrackListTrackWithID
            function TrackList = removeFromTrackListTrackWithID(~, TrackList, MySourceTrackID)
            RowOfSourceTrack =                 cell2mat(TrackList(:,obj.TrackIDColumn)) == MySourceTrackID; 
            TrackList(RowOfSourceTrack,:) =    [   ];
            end

         

            %% deleteActiveTrackBeforeFrame:
            function obj = deleteActiveTrackBeforeFrame(obj, SplitFrame)
              obj = deleteActiveTrackBeforeFrameInternal(obj, SplitFrame);
            end

            %% deleteActiveTrackAfterFrame:
            function obj = deleteActiveTrackAfterFrame(obj, SplitFrame)
            obj = obj.deleteActiveTrackAfterFrameInternal(SplitFrame);
            end

            %% splitActiveTrackAtFrame;
            function [obj] =         splitActiveTrackAtFrame(obj, Frame)
                obj =            obj.splitTrackAtFrame(Frame, obj.ActiveTrackID, obj.generateNewTrackID);
            end

            %% getIDOfFirstSelectedTrack:
            function TrackID = getIDOfFirstSelectedTrack(obj)
            if isempty(obj.SelectedTrackIDs)
                TrackID = NaN;
            else
                TrackID = obj.SelectedTrackIDs(1);
            end

            end

            %% getTrackIDsOfFrame
            function trackIDs =        getTrackIDsOfFrame(obj, FrameNumber)
                trackIDs =         obj.getTrackIDsFromSegmentationList(obj.getTrackingCellForTimeForFrames(FrameNumber));
            end

            %% fillGapsOfActiveTrack;
            function obj = fillGapsOfActiveTrack(obj)
               
                try 
                    obj.PreventDoubleTracking = false;
                    Limits =        obj.getLimitsOfFirstGapOfActiveTrackForLimitValue(NaN);
                    preMask =       PMMask(obj.getActiveSegmentationForFrames(Limits(1) - 1));
                    postMask =      PMMask(obj.getActiveSegmentationForFrames(Limits(2) + 1));
                    obj =           obj.fillGapBetweenTwoMasks(preMask, postMask);
                    obj =           obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID);
                    obj.PreventDoubleTracking = true;
             
                catch E
                   throw(E) 
                end
            end
            
            
        

            %% getLimitsOfFirstGapOfAllTracksForLimitValue:
            function [Limits, TrackIds] =  getLimitsOfFirstGapOfAllTracksForLimitValue(obj, Value)
            [Frames, TrackIds]=         obj.getFramesOfEachTrack;
            Limits =                    cellfun(@(x) PMVector(x).getLimitsOfFirstForwardGapForLimitValue(  Value), Frames, 'UniformOutput', false);
            EmptyRows =                 cellfun(@(x) isempty(x), Limits);
            Limits(EmptyRows, :) =      [];
            TrackIds(EmptyRows, :) =    [];

            end

            function [frames, TrackIDs] = getFramesOfEachTrack(obj)
            TrackIDs  =  obj.getListWithAllUniqueTrackIDs;
            frames =    arrayfun(@(x) obj.getFrameNumbersForTrackID(x), TrackIDs, 'UniformOutput', false);

            end

            %% getLimitsOfFirstBackwardGapOfAllTracksForLimitValue:
            function [Limits, TrackIds] =  getLimitsOfFirstBackwardGapOfAllTracksForLimitValue(obj, Value)
                [Frames, TrackIds]=         obj.getFramesOfEachTrack;
                Limits =                    cellfun(@(x) PMVector(x).getLimitsOfFirstBackwardGapForLimitValue(  Value), Frames, 'UniformOutput', false);
                EmptyRows =                 cellfun(@(x) isempty(x), Limits);
                Limits(EmptyRows, :) =      [];
                TrackIds(EmptyRows, :) =    [];

            end

            function [Limits, TrackIds] = getLimitsOfSurroundedFirstForwardGapOfAllTracks(obj)
                [Frames, TrackIds]=     obj.getFramesOfEachTrack;
                Limits =                cellfun(@(x) PMVector(x).getLimitsOfSurroundedFirstForwardGap, Frames, 'UniformOutput', false);
                EmptyRows =             cellfun(@(x) isempty(x), Limits);
                Limits(EmptyRows, :) =  [];
                TrackIds(EmptyRows, :) = [];
            end

            %% getLimitsOfFirstForwardGapOfAllTracksForLimitValue:
            function [Limits, TrackIds] =  getLimitsOfFirstForwardGapOfAllTracksForLimitValue(obj, Value)
                [Frames, TrackIds]=         obj.getFramesOfEachTrack;
                Limits =                    cellfun(@(x) PMVector(x).getLimitsOfFirstForwardGapForLimitValue(  Value), Frames, 'UniformOutput', false);
                EmptyRows =                 cellfun(@(x) isempty(x), Limits);
                Limits(EmptyRows, :) =      [];
                TrackIds(EmptyRows, :) =    [];
            end

            %% setInfoOfActiveTrack:
            function obj = setInfoOfActiveTrack(obj, input)
            obj = obj.setInfoOfActiveTrackInternal(input);
            end

            %% getIndicesOfFinishedTracksFromList
            function matches = getIndicesOfFinishedTracksFromList(obj, List)
                ids =               obj.getFinishedTrackIDs;
                matches =           ismember(List, ids); 
            end

            function ids = getFinishedTrackIDs(obj)
                finishedStatus =     obj.getFinishedStatusOfAllTracks;
                FinishedRows =       strcmp('Finished', finishedStatus);
                TrackIDs =           obj.getListWithAllUniqueTrackIDs;
                ids =                TrackIDs(FinishedRows, :);
            end

            function finishedStatus = getFinishedStatusOfAllTracks(obj)
                List =                  obj.getListWithAllUniqueTrackIDs;
                finishedStatus =       arrayfun(@(x) obj.TrackInfoList{x, 1}.getFinishedStatus, List, 'UniformOutput', false);
            end
  
            %%     %% truncateActiveTrackToFit
            function obj = truncateActiveTrackToFit(obj)
                 try  
                    
                    obj =       obj.truncateActiveTrackToFitInternal; 
                                
                 catch ME
                        throw(ME)
                end

            end
         
            %% mergeSelectedTracks
            function obj = mergeSelectedTracks(obj)
                try
                        obj =                             obj.mergeTracks( obj.getIdsOfSelectedTracks);
                        obj.SelectedTrackIDs(2:end,:) =   [];
                 catch ME
                        throw(ME)
                end
            end
            

            function obj =                          mergeTracks(obj, mySelectedTrackIDs)
                try
                    obj =   obj.mergeTracksInternal(mySelectedTrackIDs);
                catch ME
                    throw(ME)
                end

            end
            
            %% getUnfinishedTrackIDs:
            function ids = getUnfinishedTrackIDs(obj)
                
                FinishedRows =  strcmp('Finished', obj.getFinishedStatusOfAllTracks);
                TrackIDs =      obj.getListWithAllUniqueTrackIDs;
                ids =           TrackIDs(~FinishedRows, :);

            end

            %% getSegmentationOfFrame
            function segmentation = getSegmentationOfFrame(obj, Frame)
                segmentation =             obj.getTrackingCellForTimeForFrames(Frame);  
                  segmentation =                 obj.removeNanTracksFromSegmentation(segmentation);
       
            end

            %% getActiveSegmentationForFramesAndPlanesWithDriftCorrection
            function selectedSegmentation = getActiveSegmentationForFramesAndPlanesWithDriftCorrection(obj, Frames, Planes, DriftCorrection)
                selectedSegmentation =          obj.getSegmentationWithAppliedDriftForFrame(Frames, DriftCorrection);
                selectedSegmentation =          obj.filterSegementationListForSelectedTracks(selectedSegmentation, obj.ActiveTrackID);
                selectedSegmentation =          obj.filterSegmentationListForPlanes(selectedSegmentation, Planes);
            end

            %% getActiveSegmentationForFrames
            function segmentationOfActiveTrack = getActiveSegmentationForFrames(obj, Value)
                assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
                SegmentationOfSelectedFrame =      obj.TrackingCellForTime{Value};  
                segmentationOfActiveTrack =         obj.filterSegementationListForSelectedTracks(SegmentationOfSelectedFrame, obj.ActiveTrackID);
            end

           
          
      
              
           
              
            function List = removeMasksByMaxPlaneLimitForList(obj, List, Value)
                rows =              cellfun(@(x) size(x,1)<= Value, List(:, obj.PixelColumn)); 
                List(rows, :) =     obj.getBlankSegmentation;
            end

            %% getCoordinatesOfActiveTrack
             function coordinates = getCoordinatesOfActiveTrackForFrame(obj, Frame)
                 List =         obj.getTrackingCellForTimeForFrames(Frame);
                 FilteredList = obj.filterSegementationListForSelectedTracks(List, obj.ActiveTrackID);
                
                 coordinates = obj.extractCoordinatesFromTrackList(FilteredList);
                
             end
            
             
       
                        
            %% getPlaneOfActiveTrack:
             function Plane =                  getPlaneOfActiveTrackForFrame(obj, Frame)
                 List = obj.getTrackingCellForTimeForFrames(Frame);
                 FilteredList = obj.filterSegementationListForSelectedTracks(List, obj.ActiveTrackID);
                Plane =  obj.getZCoordinatesFromSegementationList(FilteredList);
                if isempty(Plane)
                    Plane = NaN;
                end
                    
              end 
           
          
            
             
        
            
          
           
         
            
            %% deleteAllSelectedTracks
            function obj = deleteAllSelectedTracks(obj)
                obj =                    obj.removeTrack(obj.getIdsOfSelectedTracks);
                obj.SelectedTrackIDs =   zeros(0,1);
            end
            
            
        

    end
    
    methods(Access= private)
        

        function obj = deleteFromInfoListTrackIDs(obj, TrackIds)
           
            warning('Deleting extra tracks from info list')
            obj.TrackInfoList{TrackIds,1} =      {''};
        end

        
        %% reorderTrackInfoList: this is only needed for compatibility reasons:
        function obj = reorderTrackInfoList(obj)
              CopyOfInfoList = obj.TrackInfoList;
             
              MySourceRows =                     arrayfun(@(x)      obj.getRowInTrackInfoForTrackID(x), obj.getListWithAllUniqueTrackIDs);
              MyTargetRows = obj.getListWithAllUniqueTrackIDs;
              
              for Index = 1: length(MySourceRows)
                  CopyOfInfoList{MyTargetRows(Index), 1} = obj.TrackInfoList{MySourceRows(Index), 1};
              end
              
              obj.TrackInfoList = CopyOfInfoList;
            
        end
        
          function row =   getRowInTrackInfoForTrackID(obj, myWantedTrackID)              
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
            
      
         
 
      

         
       

      
        function obj =         truncateActiveTrackToFitInternal(obj)
            assert(length(obj.getIdsOfSelectedTracks) == 1, 'Can only truncate with one track selected.')

 
            obj =                   obj.truncateTrackToFitMask([obj.ActiveTrackID,   obj.SelectedTrackIDs]);
            obj =                   obj.updateSegmentationAddressInTrackInfoListForIDs(obj.ActiveTrackID); 
        end
        
        
            %% mergeTracksInternal
            function obj = mergeTracksInternal(obj, mySelectedTrackIDs)

                mySelectedTrackIDs =        obj.finalizeTrackIdsForMerging(mySelectedTrackIDs);
                OverlappingFrames =         obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
                
                if isempty(OverlappingFrames)
                    obj =       obj.replaceTrackIDWithTrackID(max(mySelectedTrackIDs), min(mySelectedTrackIDs));
                    obj =       obj.updateSegmentationAddressInTrackInfoListForIDs(mySelectedTrackIDs(1));
                    obj =       obj.updateSegmentationAddressInTrackInfoListForIDs(mySelectedTrackIDs(2));
                    obj =       obj.setActiveTrackIDTo(min(mySelectedTrackIDs));

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
            
            function mySelectedTrackIDs = finalizeTrackIdsForMerging(obj, mySelectedTrackIDs)
                  if length(mySelectedTrackIDs) == 1
                    mySelectedTrackIDs(2) = obj.ActiveTrackID;
                end
                assert(length(mySelectedTrackIDs) == 2, 'Can only merge two tracks.')
                
            end
            
          
            
 
              function [OverlappingFrames] = getOverLappingFramesOfTracks(obj, mySelectedTrackIDs)
                   assert(length(mySelectedTrackIDs)==2, 'Overlapping frames can be only detected for two tracks')
                   FramesOfTrackOne =         obj.getFrameNumbersForTrackID(mySelectedTrackIDs(1));  
                   FramesOfTrackTwo =         obj.getFrameNumbersForTrackID(mySelectedTrackIDs(2));  
                   OverlappingFrames =        intersect(FramesOfTrackOne, FramesOfTrackTwo);
            
              end
              
              function GapFrames = getNumberOfGapFramesForTrackIDs(obj, mySelectedTrackIDs)
                  assert(length(mySelectedTrackIDs)==2, 'Overlapping frames can be only detected for two tracks')
                  [OverlappingFrames] = obj.getOverLappingFramesOfTracks(mySelectedTrackIDs);
                  if ~isempty(OverlappingFrames)
                      GapFrames = -OverlappingFrames;
                  else
                      [SourceMask, TargetMask] =    obj.getSourceAndTargetMaskFromTrackIDs(mySelectedTrackIDs);
                      
                      
                  end
                  
                  
              end
              
              function [SourceMask, TargetMask] = getSourceAndTargetMaskFromTrackIDs(obj, mySelectedTrackIDs)
              
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
              
            function [SourceMask]  = getLastMaskOfTrack(obj, MyTrackID)
                SourceTrackInformation =    obj.getSegmentationForTrackID(MyTrackID);
                [~, RowOfLastFrame] =       max(obj.extractFramesFromTrackList(SourceTrackInformation));     
                SourceMask =                PMMask(  SourceTrackInformation(RowOfLastFrame,:));
            end
            
               function [SourceMask]  = getFirstMaskOfTrack(obj, MyTrackID)
                SourceTrackInformation =    obj.getSegmentationForTrackID(MyTrackID);
                [~, RowOfLastFrame] =       min(obj.extractFramesFromTrackList(SourceTrackInformation));     
                SourceMask =                PMMask(  SourceTrackInformation(RowOfLastFrame,:));
            end
        
              
            function Value = getNumberOfGapFramesBetweenMasks(~, mySourceMask, myTargetMask)
                Value =      mySourceMask.getFrame + 1 : myTargetMask.getFrame - 1;
            end
              

            function obj = replaceTrackIDWithTrackID(obj, OldTrackID, NewTrackID)
                AddressOfTargetTrack =          obj.TrackInfoList{OldTrackID, 1}.getSegmentationAddress;
                obj =                           obj.setTargetAddressWithTrackID(AddressOfTargetTrack, NewTrackID);
               
            end
            
            function obj = setTargetAddressWithTrackID(obj, AddressOfTargetTrack, NewTrackID)
                 obj =                           obj.setTargetColumnOfTrackingCellWithValueAddress(obj.TrackIDColumn, NewTrackID, AddressOfTargetTrack);

            end
            
   
          
        
        
        
        

            function obj =       removeTrack(obj, trackID)
                assert(isnumeric(trackID) && isvector(trackID) , 'Wrong input.')
                
                
                for Index = 1 : length(trackID)
                    obj =           obj.replaceTrackIDWithTrackID(trackID(Index), NaN);
                    obj =           obj.updateSegmentationAddressInTrackInfoListForIDs(trackID(Index));
                    
                end
                
                obj =           obj.setActiveTrackID(obj.getIDOfFirstSelectedTrack);
                
            end
            
       %% setEntryInTrackingCellForTime:
        function [obj] =          setEntryInTrackingCellForTime(obj, SegmentationCapture)

                assert(~isempty(obj.TrackingAnalysis), 'Tracking analysis needed.')
                assert(obj.verifyTrackID(obj.ActiveTrackID), 'Could not add data because track ID was invalid.')
                fprintf('Updating track ID %i for frame %i.\n', obj.ActiveTrackID, obj.ActiveFrame) 
                
                obj =       obj.removeDuplicatesFromActiveSegmentation;
                if isempty(SegmentationCapture.getMaskCoordinateList) % when the pixels are empty: delete content:
                          obj =       obj.setTrackForFrameTrackIDWithMasks(obj.ActiveFrame, obj.ActiveTrackID, obj.getBlankSegmentation);
      
                    
                else
                    try
                        obj = obj.addSegmentationCaptureToActiveSegmentation(SegmentationCapture);
                    catch E
                       throw(E) 
                    end
                    
                end

        end
        
         function obj = removeDuplicatesFromActiveSegmentation(obj)
            RowsOfActiveTrack =      obj.getRowInSegmentationForFrameTrackID(obj.ActiveFrame, obj.ActiveTrackID);
            if size(RowsOfActiveTrack,1) >= 2 % if more than one row is positive: delete all duplicate rows (this should not be the case):
                RowsToDelete = RowsOfActiveTrack(2:end);
                
                obj = obj.deleteTrackSegmentationForFrameRows(obj.ActiveFrame, RowsToDelete);
                
        
                warning('There was a duplicate row for the active track, which had to be removed.')
            end
         end
        
        
          function obj = addSegmentationCaptureToActiveSegmentation(obj, SegmentationCapture)
                
                [NewMask, NewMaskWithDrift] =           obj.getMasksForInput(obj.ActiveTrackID, obj.ActiveFrame, SegmentationCapture);
               
                if obj.PreventDoubleTracking
                    MinDistance = obj.getMinDistanceToOtherMasksInActiveFrameForMask(NewMask);
                    if MinDistance < obj.DistanceForDoubleTracking(1)
                        myException =  MException('MATLAB:trackingError', 'New mask was within the limit for double tracking. Therefore tracking was not continued.');
                        throw(myException)
                    end
                    
                end
                
                obj =       obj.setTrackForFrameTrackIDWithMasks(obj.ActiveFrame, obj.ActiveTrackID, NewMask, NewMaskWithDrift);
                
                
           
                
          end
          
        
      
         
    
       
        
          function minDistance = getMinDistanceToOtherMasksInActiveFrameForMask(obj, Mask)
              
                    NewX = Mask{1, obj.CentroidXColumn} ;
                    NewY = Mask{1, obj.CentroidYColumn};
                    NewZ = Mask{1, obj.CentroidZColumn} ;

                     
              
                    
                    segmentation =      obj.getSegmentationOfFrame(obj.ActiveFrame);
                    
                     MatchingRow =      cell2mat(segmentation(:, obj.TrackIDColumn)) == Mask{obj.TrackIDColumn, 1};
                    
                     segmentation(MatchingRow, :) = [];
                    coordinates =       obj.extractCoordinatesFromTrackList(segmentation);
                   
                    
                    
                   
                     minDistance =            min(pdist2([NewX NewY NewZ], coordinates));
                
          end
          
        
          
        function [Mask, MaskWithDrift] =  getMasksForInput(obj, MyTrackID, activeFrame, SegmentationCapture)

                 assert(~isempty(obj.TrackingAnalysis), 'Need tracking analysis to calculate drift.')
            
                Mask{1, obj.TrackIDColumn} =    MyTrackID;
                Mask{1, obj.TimeColumn} =       activeFrame;
                Mask{1, obj.CentroidYColumn} =  mean(SegmentationCapture.getMaskYCoordinateList);
                Mask{1, obj.CentroidXColumn} =  mean(SegmentationCapture.getMaskXCoordinateList);
                Mask{1, obj.CentroidZColumn} =  mean(SegmentationCapture.getMaskZCoordinateList);
                Mask{1, obj.PixelColumn} =      SegmentationCapture.getMaskCoordinateList;
                SegmentationInfo =              SegmentationCapture.RemoveImageData;
                Mask{1, obj.SegmentationTypeColumn}.SegmentationType=         SegmentationInfo;

                MaskWithDrift =     obj.TrackingAnalysis.addDriftCorrectionToMasks(Mask);
                MaskWithDrift{1, obj.PixelColumn} =                                '';
                MaskWithDrift{1, obj.SegmentationTypeColumn}.SegmentationType=     SegmentationInfo;


        end
        
               
        function segmentation = getBlankSegmentation(obj)
            segmentation = cell(1, obj.NumberOfColumns);
            segmentation{1, obj.TrackIDColumn} = NaN;
            segmentation{1, obj.TimeColumn} = NaN;
            segmentation{1, obj.CentroidYColumn} = NaN;
            segmentation{1, obj.CentroidXColumn} = NaN;
            segmentation{1, obj.CentroidZColumn} = NaN;
            segmentation{1, obj.PixelColumn} = zeros(0, 3);
            segmentation{1, obj.SegmentationTypeColumn}.SegmentationType = PMSegmentationCapture;
           
        end
        
          
     
        %% reconstructTrackCellForTimeFromPooledData
       
        function ReconstructedTimeSpecificList =       separatePooledDataIntoTimeSpecific(obj, ListOfSourceData)

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

        %%  deleteActiveTrackBeforeFrameInternal
        function obj = deleteActiveTrackBeforeFrameInternal(obj, SplitFrame)
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
        
       

        
           

        
          
         %% deleteActiveTrackAfterFrameInternal
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
                        
            AddressOfSourceTrack =       obj.TrackInfoList{SourceTrackID, 1}.getSegmentationAddress;
            AdressOfNewSecondTrack =     obj.keepInSegmentationAddressFramesMoreThan(AddressOfSourceTrack, SplitFrame);
              obj =               obj.addMissingTrackIdsToTrackInfoListForMaxTrack(max([SourceTrackID, TrackIdForSecondSplitTrack]));
              
            obj =      obj.setTargetAddressWithTrackID(AdressOfNewSecondTrack, TrackIdForSecondSplitTrack);
            
          
            obj =      obj.updateSegmentationAddressInTrackInfoListForIDs(SourceTrackID);
            obj =      obj.updateSegmentationAddressInTrackInfoListForIDs(TrackIdForSecondSplitTrack);
            
            
            obj =               obj.addToSelectedTrackIds(TrackIdForSecondSplitTrack);
            
           
            
      
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
        
        
        %% setInfoOfActiveTrackInternal:
        function obj = setInfoOfActiveTrackInternal(obj, input)
            
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
        
      
      
        
         
         
            
        

      
        
           %% getDriftCorrectedSegmentationOfFrame
          function segmentationOfCurrentFrame = getDriftCorrectedSegmentationOfFrame(obj, Value)
                if obj.testExistenceOfDriftCorrectionForFrame(Value)
                    segmentationOfCurrentFrame =      obj.TrackingCellForTimeWithDrift{Value,1};
                else
                    segmentationOfCurrentFrame =      obj.getEmptySegmentation;
                end   
         end
        
        
        function value = testExistenceOfDriftCorrectionForFrame(obj, Value)
             value= isempty(obj.getTrackingCellForTimeForFrames(Na)) || obj.getMaxFrame < Value || isempty(obj.getTrackingCellForTimeForFrames(Value));
                value = ~ value;
        end
        
        
        
        
        %% getTrackIdsWithLimitedMaskData:
        function ResultTrackIDs =                 getTrackIdsWithLimitedMaskData(obj)
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

        function Complete = determineIfSegmentationListIsComplete(obj, RelevantMaskData)
            
            NumberOfPlanes =                16; % maximum number of "one point" masks;

            NumberOfMasks =             size(RelevantMaskData,1);
            DetailedMask =              cellfun(@(x) size(x,1) > NumberOfPlanes + 10, RelevantMaskData(:,6));
            Fraction =                  sum(DetailedMask) / NumberOfMasks;

            if Fraction <= 0.5
                fprintf('Track %i has %1.1f fraction detailed masks.\n', RelevantMaskData{1, obj.TrackIDColumn}, Fraction);
                Complete = false;
            else
                 Complete = true;
            end
        end
        
       
        
   
        
        
        
        
        
        
        
        
        
        
        
       %% setters: basic:

         
        %% removeTrackWithFramesLessThan:
        function obj =                          removeTrackWithFramesLessThan(obj, FrameNumberLimit)
            
           % error('Not test after change. Review!')

            fprintf('\nDeleting tracks with %i or less frames:\nDeleting track ', FrameNumberLimit)

            NumberBeforeDeletion =      obj.getNumberOfTracks;
            AllTrackIDs =               obj.getListWithAllUniqueTrackIDs;
            FramesPerTrack =            obj.getListOfAllFramesForTrackIDs(AllTrackIDs);
            NumberOfFramesPerTrack =    obj.getNumberOfFramesPerTrack(FramesPerTrack);

            SelectedRows =              NumberOfFramesPerTrack < FrameNumberLimit;
            TrackIDsToRemove = AllTrackIDs(SelectedRows);

            for Index = 1: length(TrackIDsToRemove)
                CurrentTrackID = TrackIDsToRemove(Index);
                obj =       obj.removeTrack(CurrentTrackID);
            end


        
            fprintf('\nBefore deletion: %i tracks. After deletion: %i tracks\n\n', NumberBeforeDeletion, obj.getNumberOfTracks);
                   
        end
        
        %% setters: resulting in changes of track ID;
        function [obj] =                splitSelectedTrackAtActiveFrame(obj)
            obj =                       obj.splitTrackAtFrame(obj.getActiveFrame, obj.getIdsOfSelectedTracks, obj.generateNewTrackID);
        end
      
        
       
          
          
   
        
      
        %% autTrackingProcedure:
          function obj =                                autTrackingProcedure(obj)
                obj =      obj.unTrack;
                obj =      obj.removeAllInterPolationMasks;
                obj =      obj.trackByMinimizingDistancesOfTracks;
                obj =      obj.removeTrackWithFramesLessThan(obj.FirstPassDeletionFrameNumber); % first delete 'remnant' tracks of just one frame, they slow down mergin and are not useful for tracking or merging
                obj =      obj.performSerialTrackReconnection;
          end
          
           
          % unTrack
          function obj =                                unTrack(obj)
             
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
          
          
          % removeAllInterPolationMasks:
            function obj =                          removeAllInterPolationMasks(obj)
               error('could not test this part; verify when using first time after change')
                NumberOfTracksBeforeDeletion =                              obj.getNumberOfTracks;
                
                [MyTrackingCellForTime, MyTrackingCellWithDrift] = obj.getTrackingCellForTimeForFrames(NaN);
                
                MyNewTrackingCellForTime =               cellfun(@(x) obj.removeInterpolationMasksFromSegmentationList, MyTrackingCellForTime, 'UniformOutput', false);
                MyNewTrackingCellForTimeWithDrift =      cellfun(@(x) obj.removeInterpolationMasksFromSegmentationList, MyTrackingCellWithDrift, 'UniformOutput', false);
             
                
                obj = obj.setTrackingCellForTime(MyNewTrackingCellForTime, MyNewTrackingCellForTimeWithDrift);
                
                
                
                fprintf('Deleting interpolation masks:\n')
                fprintf('Before deletion: %i tracks. After deletion: %i tracks\n\n', NumberOfTracksBeforeDeletion, obj.getNumberOfTracks);

            end
            
            function List = removeInterpolationMasksFromSegmentationList(obj, List)
                SegmentationTypeNameList =     cellfun(@(x) x.SegmentationType.SegmentationType, List(:,obj.SegmentationTypeColumn), 'UniformOutput', false);
                InterPolationRows =            strcmp(SegmentationTypeNameList, 'Interpolate');
                List(InterPolationRows,:) =    obj.getBlankSegmentation;
            end
            
            
          % trackByMinimizingDistancesOfTracks
          function obj =                                trackByMinimizingDistancesOfTracks(obj)
              
               myTrackingAnalysis =                 obj.TrackingAnalysis;
               MaximumAcceptedDistance =            obj.MaximumAcceptedDistanceForAutoTracking;
               
               assert(~isempty(myTrackingAnalysis), 'Tracking analysis was not set')
              
              
              fprintf('Tracking by minimizing distances:\nProcessing frames ');
               
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

                PreFrameInfo =    TrackInformationPerFrame{FrameIndex, 1};
                PostFrameInfo =   TrackInformationPerFrame{FrameIndex + 1, 1};
                
                while ~isempty(PostFrameInfo) && ~isempty(PreFrameInfo) % when all cells in post-frame have been tracked (or we ran out of pre cells stop this pair;

                    % calculate minimum distance between consecutive tracks (and continue only if below limit);
                    ListWithAllDistances =            pdist2(cell2mat(PreFrameInfo(:,3:5)), cell2mat(PostFrameInfo(:,3:5)));
                    minDistance =                     min(ListWithAllDistances(:));
                    
                    % link all pairs of minimum distance (their may be several pairs with identical distance);
                    [rowInPreTrack, rowInPostTrack] =   find(ListWithAllDistances == minDistance);
                    
                     if minDistance > MaximumAcceptedDistance
                        break
                        
                     end
                    
                     LOCO
                     
                    NumberOfEqualDistances =    size(rowInPreTrack,1);
                    for PairIndex = 1 : NumberOfEqualDistances

                        PreTrackID =                    PreFrameInfo{rowInPreTrack(PairIndex),1};
                        OldPostTrackID =                PostFrameInfo{rowInPostTrack(PairIndex),1};

                        % all that needs to be done is overwrite the "old track ID" in the consecutive frame with the new one (both tracking matrix and PMTrackingNavigation);
                        RowToChangeForTempData =        cell2mat(TrackInformationPerFrame{FrameIndex+1,1}(:,1)) == OldPostTrackID;
                        TrackInformationPerFrame{FrameIndex + 1,1}(RowToChangeForTempData,1) = num2cell(PreTrackID);

                        TrackIDs =                      obj.getTrackingSegmentationForFrameRowColumn(FrameIndex, NaN,  1);
                        RowToChangeForSourceData =      cell2mat(TrackIDs) == OldPostTrackID;
                        obj = obj.setTrackSegmentationForFrameRowColumn(FrameIndex + 1, RowToChangeForSourceData, 1, num2cell(PreTrackID));
                        
                    end
                    
                    % remove previously tracked temporary data to avoid double tracking;
                    PreFrameInfo(rowInPreTrack,:) =             [];
                    PostFrameInfo(rowInPostTrack,:) =           [];

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

            TrackeNumberBefore =                  obj.getNumberOfTracks;

            
            NumberOfMergedTracks =                          0;
            ListWithExcludedTrackIDs =                       NaN;
             %% get list of all track IDs that should be deleted
             while 1 % one round of merging (start from first track; done multiple times until all tracks are connected);

                %% create pooled tracks, then go through every single track until you find one that is a target for conncetion;
                ListWithAllAvailableTrackIDs =                  obj.getListWithAllUniqueTrackIDs;
                ListWithAllAvailableTrackIDs(ListWithAllAvailableTrackIDs < ListWithExcludedTrackIDs,:)  = [];  
                for TrackIndex = 1 :  size(ListWithAllAvailableTrackIDs,1)

                    obj =                       obj.mergingInfoText(ListWithAllAvailableTrackIDs, TrackIndex);

                    mySourceMask =      obj.getLastMaskOfTrack(ListWithAllAvailableTrackIDs(TrackIndex));
                    trackLinking =      PMTrackLinking(obj, mySourceMask,  obj.AutoTrackingActiveGap, obj.DistanceLimitXYForTrackMerging, obj.DistanceLimitZForTrackingMerging, obj.ShowDetailedMergeInformation);
                    
                    CandidateTargetSegmentation =      trackLinking.getCandidateTargetTracks;
                    if  size(CandidateTargetSegmentation,1) ~= 1 
                        ListWithExcludedTrackIDs =   ListWithAllAvailableTrackIDs(TrackIndex); % exclude if not one precise target can be found:

                    else

                        myTargetMask =      PMMask(CandidateTargetSegmentation);
                        obj =               obj.mergingInfoTextTwo(ListWithAllAvailableTrackIDs, TrackIndex, myTargetMask);
                        if obj.AutoTrackingActiveGap >= 1
                            obj =           obj.fillGapBetweenTwoMasks(SourceMask, myTargetMask);

                        elseif obj.AutoTrackingActiveGap <= -1
                            obj =        obj.truncateTrackToFitMask([ListWithAllAvailableTrackIDs(TrackIndex), myTargetMask.getTrackID]);

                        end

                        % b) after filling gap, merge the two tracks;
                        obj =                          obj.mergeTracks([ListWithAllAvailableTrackIDs(TrackIndex), myTargetMask.getTrackID]);
                        NumberOfMergedTracks =         NumberOfMergedTracks + 1;
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
        
       
        
        
        
        function obj = mergingInfoText(obj, ListWithAllAvailableTrackIDs, TrackIndex)
                if obj.ShowDetailedMergeInformation == 1
                    fprintf('\nTrack %i (%i of %i)', ListWithAllAvailableTrackIDs(TrackIndex), TrackIndex, size(ListWithAllAvailableTrackIDs,1))
                end
        end
        
        function obj = mergingInfoTextTwo(obj, ListWithAllAvailableTrackIDs, TrackIndex, CandidateTargetMasks)
            FramesOfSource =             obj.getFrameNumbersForTrackID( ListWithAllAvailableTrackIDs(TrackIndex));
            fprintf('Merge track %i (frame %i to %i)', ListWithAllAvailableTrackIDs(TrackIndex), min(FramesOfSource), max(FramesOfSource))

            FramesTarget =                      obj.getFrameNumbersForTrackID( CandidateTargetMasks.getTrackID);
            fprintf(' with track %i (frame %i to %i).\n', CandidateTargetMasks.getTrackID, min(FramesTarget), max(FramesTarget))

        end
        
       
        % fillGapBetweenTwoMasks
        function [obj] =           fillGapBetweenTwoMasks(obj, mySourceMask, myTargetMask)
            if myTargetMask.getFrame <= mySourceMask.getFrame + 1
                error('This track has not gap. No action taken')
                
            else
                [XList, YList, ZList] =         obj.getCoordinatesForInterpolationBetweenMasks(mySourceMask, myTargetMask);
                FramesThatRequireClosing =      mySourceMask.getFrame + 1 : myTargetMask.getFrame - 1;
                for FrameIndex = 1 : length(FramesThatRequireClosing)

                    XForCurrentGap =            round(XList(FrameIndex));
                    YForCurrentGap =            round(YList(FrameIndex));
                    ZForCurrentGap =            round(ZList(FrameIndex));
                    newPixelList =              [YForCurrentGap, XForCurrentGap, ZForCurrentGap];

                    SegmentationCapture =       PMSegmentationCapture();
                    SegmentationCapture =       SegmentationCapture.setSegmentationType('Interpolate');
                    SegmentationCapture =       SegmentationCapture.setMaskCoordinateList(newPixelList);

                    obj.ActiveFrame =           FramesThatRequireClosing(FrameIndex);
                    obj.ActiveTrackID =         mySourceMask.getTrackID;
                    obj =                       obj.setEntryInTrackingCellForTime( SegmentationCapture);

                end

            end
           
        end
        
        
        
        
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
        
        % truncateTrackToFitMask:
     
          %% getMiniMask
         
          
      
   
        function coordinates = getXCoordinatesOfFrame(obj, Frame)
            
            if obj.getMaxFrame >= Frame
                coordinates = obj.getXCoordinatesFromSegementationList(obj.getTrackingCellForTimeForFrames(Frame));
            else
                coordinates =   zeros(0,1);
            end
            
            
        end
        
        function coordinates = getXCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.CentroidXColumn));
        end
        
          function coordinates = getYCoordinatesOfFrame(obj, Frame)
              
            if obj.getMaxFrame >= Frame
                coordinates =  getYCoordinatesFromSegementationList(obj, obj.getTrackingCellForTimeForFrames(Frame));
            else
                coordinates =   zeros(0,1);
            end

            
          end
          
         function coordinates = getYCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.CentroidYColumn));
         end
        
        function coordinates = getZCoordinatesOfFrame(obj, Frame)
              if obj.getMaxFrame >= Frame
                    coordinates =  obj.getZCoordinatesFromSegementationList(obj.getTrackingCellForTimeForFrames(Frame));
                else
                    coordinates =   zeros(0,1);
              end
        end
            
        function coordinates = getZCoordinatesFromSegementationList(obj, list)
            coordinates =  cell2mat(list(:, obj.CentroidZColumn));
        end
        
        
        
        
        %% convertOldCellMaskStructureIntoTrackingCellForTime:
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
end
