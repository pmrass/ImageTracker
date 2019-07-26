classdef PMTrackingAnalysis
    %PMTRACKINGANALYSIS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        
        % fields that could be of interest for future use:
%             ListhWithCurrentDefaultFields=      {'MaskID', 'TrackID', 'AbsoluteFrame', 'CentroidY', 'CentroidX', 'CentroidZ', 'TopZPlane', 'BottomZPlane', 'NumberOfZPlanes', ... 
%                                         'ListWithPixels_3D', 'ListWithPixels', 'NumberOfPixels', 'NumberOfPixels_3D', 'MeanPixelIntensity', ...
%                                         'MergeIndex', 'NumberOfFollowUpCells_Interpretation', 'DesignationOfFollowUpCell_Interpretation', ...
%                                         'NumberOfFollowUpCells', 'IDsOfFollowUpCells', 'NumberOfPrecedingCells', 'IDsOfPrecedingCells', 'DesignationOfTrackingScenario', ...
%                                         'I', 'PrincipalI_1', 'PrincipalI_2',  'PrincipalI_3','UX_MinI', 'UY_MinI', 'UZ_MinI', 'PolarityIndex'};
% 

        
        % this contains the entire tracking information and should be used primarily for reading data;
        FieldNamesOfMaskInformation
        ListWithCompleteMaskInformation
        ListWithCompleteMaskInformationWithDrift
        
        ListWithFilteredMaskInformation
        ListWithFilteredMaskInformationWithDrift
        
        DriftCorrection
        
        % track cell is created by original movie data and can be used to filter for specific data (specific track, time-frames etc.);
        TrackCell
        TrackCellFieldNames
        NumberOfColumnsInTrackingMatrix =       12
        
        NumberOfFramesInSubTracks =             NaN % this means that the "entire" tracks whill be generated (not subtracks);
        JumpSizeBetweenSubTracks =              NaN % how much "overlap" between subtracks is wanted
        
        TrackingCell
        TrackingCellWithDrift
        
        TrackingListForMovieDisplay
        TrackingListWithDriftForMovieDisplay
        
        
        
    end
    
    methods
        
        function obj = PMTrackingAnalysis(TrackingAnalysisBasis, DriftCorrection)
            %PMTRACKINGANALYSIS Construct an instance of this class
            %   Detailed explanation goes here
            
            
                    obj.DriftCorrection =         DriftCorrection;
                     obj =                      obj.createListWithCompleteMaskInformation(TrackingAnalysisBasis);
                    [obj]=                      obj.ConvertTrackingResultsIntoTrackCell;
                    obj =                       obj.updateTrackingResults;
                    
                    
               
                
        end
        
        
        
        
          function [ obj ] =                                                createListWithCompleteMaskInformation(obj, TrackingAnalysisBasis)
            %CONVERTTRACKINGSTRUCTURETOCELL Summary of this function goes here
            %   Detailed explanation goes here

                ListWithFieldNames =                        TrackingAnalysisBasis.FieldNamesForTrackingCell;
                DataIn_ListWithCellMasks_Matrix =           vertcat(TrackingAnalysisBasis.TrackingCellForTime{:});

                Column_TrackID=                             find(strcmp('TrackID', ListWithFieldNames));
                Column_AbsoluteFrame=                       find(strcmp('AbsoluteFrame', ListWithFieldNames));
                Column_CentroidY =                          find(strcmp('CentroidY', ListWithFieldNames));
                
                
                %% remove untracked masks:  % not sure if this is necessary:
                DataIn_ListWithCellMasks_Matrix(cell2mat(DataIn_ListWithCellMasks_Matrix(:,Column_TrackID))==0,:)=          []; % remove untracked masks;
                DataIn_ListWithCellMasks_Matrix(isnan(cell2mat(DataIn_ListWithCellMasks_Matrix(:,Column_TrackID))),:)=      []; % remove untrackable masks

                
                %% sort by track ID and time-frames:
                if ~isempty(DataIn_ListWithCellMasks_Matrix)
                    DataIn_ListWithCellMasks_Matrix=                        sortrows(DataIn_ListWithCellMasks_Matrix,[Column_TrackID Column_AbsoluteFrame]);   
                end
                
                %% remove rows that contain nan (this should anyway not be the case);
                
                BadRows =                                                   cellfun(@(x) isnan(x), DataIn_ListWithCellMasks_Matrix(:,Column_CentroidY));
                DataIn_ListWithCellMasks_Matrix(BadRows,:) =                [];
                
                obj.FieldNamesOfMaskInformation =                           ListWithFieldNames;
                obj.ListWithCompleteMaskInformation =                       DataIn_ListWithCellMasks_Matrix;
                
                obj =                                                       obj.addDriftCorrectionToMaskInformation;
                
                
                obj.ListWithFilteredMaskInformation =                       obj.ListWithCompleteMaskInformation;
                obj.ListWithFilteredMaskInformationWithDrift =              obj.ListWithCompleteMaskInformationWithDrift;
        

        end


        
          function [obj]=                                                   ConvertTrackingResultsIntoTrackCell(obj)
              
              
              
            

                 DataIn_ListWithCellMasks_Matrix =              obj.ListWithFilteredMaskInformation;
                 ListWithFieldNames  =                          obj.FieldNamesOfMaskInformation;
                 
                if isempty(DataIn_ListWithCellMasks_Matrix)
                    TrackCellInternal = [];
                    ListWithFieldNames = [];
                    
                else
                    
                    FieldNames =                                    obj.FieldNamesOfMaskInformation;
                    
                    
                    Column_TrackID =                                find(strcmp('TrackID', FieldNames));    
                    Column_AbsoluteFrame=                           find(strcmp('AbsoluteFrame', FieldNames));
                    Column_CentroidY=                               find(strcmp('CentroidY', FieldNames));
                    Column_CentroidX=                               find(strcmp('CentroidX', FieldNames));
                    Column_CentroidZ=                               find(strcmp('CentroidZ', FieldNames));


                    % reorganize track-data, so that each track is stored in a specific cell;
                    ListWithUniqueTrackIDs =                        unique(cell2mat(DataIn_ListWithCellMasks_Matrix(:,Column_TrackID)));
                    ListWithAllTrackIDs =                           DataIn_ListWithCellMasks_Matrix(:,Column_TrackID);
                    
                    NumberOfTracks =                                size(ListWithUniqueTrackIDs,1);
                    TrackCellInternal =                             cell(NumberOfTracks,1);
                    for TrackIndex=1:NumberOfTracks
                        RowsWithCurrenTrack =                       cell2mat(ListWithAllTrackIDs)== ListWithUniqueTrackIDs(TrackIndex);
                        TrackCellInternal{TrackIndex,1} =           DataIn_ListWithCellMasks_Matrix(RowsWithCurrenTrack,:);

                    end

                    NumberOfSteps =                                 cellfun(@(x) size(x,1), TrackCellInternal);
                    TrackCellInternal(NumberOfSteps==1,:) =         [];

                
                    
                    
                end
                
                
                obj.TrackCellFieldNames =           ListWithFieldNames;
                obj.TrackCell =                     TrackCellInternal;

          end
        
          
          function [obj] =                                                  addDriftCorrectionToMaskInformation(obj)
              
             %% read data:
            FieldNames =                                obj.FieldNamesOfMaskInformation;
            CoordinateListIn =                          obj.ListWithCompleteMaskInformation;
            
            RowShiftsAbsolute=                          obj.DriftCorrection.RowShiftsAbsolute;
            ColumnShiftsAbsolute=                       obj.DriftCorrection.ColumnShiftsAbsolute;
            PlaneShiftsAbsolute=                        obj.DriftCorrection.PlaneShiftsAbsolute;


            Column_AbsoluteFrame=                       find(strcmp('AbsoluteFrame', FieldNames));
            Column_CentroidY=                           find(strcmp('CentroidY', FieldNames));
            Column_CentroidX=                           find(strcmp('CentroidX', FieldNames));
            Column_CentroidZ=                           find(strcmp('CentroidZ', FieldNames));

           
            ListWithXCoordinates=                       cell2mat(CoordinateListIn(:,Column_CentroidX));  
            ListWithYCoordinates=                       cell2mat(CoordinateListIn(:,Column_CentroidY));
            ListWithZCoordinates=                       cell2mat(CoordinateListIn(:,Column_CentroidZ));

            ListWithAbsoluteFrames=                     cell2mat(CoordinateListIn(:,Column_AbsoluteFrame));

            
            
            %% get drift-correction results:
            
            ListWithFrames=                                     unique(ListWithAbsoluteFrames);
            NumberOfUniqueFrames=                               length(ListWithFrames); 
            for CurrentFrameDriftCorrection=1:NumberOfUniqueFrames

                CurrentFrameNumber=                             ListWithFrames(CurrentFrameDriftCorrection);

                RowShiftForCurrentFrame=                        RowShiftsAbsolute(CurrentFrameNumber);
                ColumnShiftForCurrentFrame=                     ColumnShiftsAbsolute(CurrentFrameNumber);
                PlaneShiftForCurrentFrame=                      PlaneShiftsAbsolute(CurrentFrameNumber);

               
                RelevantRows =                                  ListWithAbsoluteFrames==CurrentFrameNumber;
                
                ListWithXCoordinates(RelevantRows)=             ListWithXCoordinates(RelevantRows)+ColumnShiftForCurrentFrame;
                ListWithYCoordinates(RelevantRows)=             ListWithYCoordinates(RelevantRows)+RowShiftForCurrentFrame;
                ListWithZCoordinates(RelevantRows)=             ListWithZCoordinates(RelevantRows)+PlaneShiftForCurrentFrame;

            end


            CoordinateListIn(:,Column_CentroidX)=               num2cell(ListWithXCoordinates);  
            CoordinateListIn(:,Column_CentroidY)=               num2cell(ListWithYCoordinates);  
            CoordinateListIn(:,Column_CentroidZ)=               num2cell(ListWithZCoordinates);  

            obj.ListWithCompleteMaskInformationWithDrift =      CoordinateListIn;
            
          end
          
          
         function [obj] =                                                   updateTrackingResults(obj)         
             

            h=     waitbar(0, 'Creating tracks');

            % convert tracking structure into cell matrix:    %   drift correction should be added only to first frame:
            % first update the object
            
          % [ CoordinateListWithoutDriftCorrection ] =                                     AddDriftCorrectionToCoordinateList( CoordinateListWithoutDriftCorrection, FieldNamesOfCoordinateList, StructureWithDriftAnalysisData );


           
        
        
            % get subtracklocation within coordinate list and in loop convert each coordinate list to "tracking-result":
            obj.TrackingCell =                                                       obj.ConvertCoordinateListIntoTrackingCell(obj.ListWithFilteredMaskInformation);
            obj.TrackingListForMovieDisplay =                                       obj.convertTrackingCellIntoTrackListForMovie(obj.TrackingCell, h);
            
            
            obj.TrackingCellWithDrift =                                              obj.ConvertCoordinateListIntoTrackingCell(obj.ListWithFilteredMaskInformationWithDrift);
            obj.TrackingListWithDriftForMovieDisplay =                              obj.convertTrackingCellIntoTrackListForMovie(obj.TrackingCellWithDrift, h);
            
             close(h)
             
         end
         
         
         
     
         
         function [obj] =                                                   filterTracksByTimeFrames(obj, AcceptedFrames)
             
             
             OkRows =                                               ismember(cell2mat(obj.ListWithCompleteMaskInformation(:,2)), AcceptedFrames);
             
              
            obj.ListWithFilteredMaskInformation =                   obj.ListWithCompleteMaskInformation(OkRows,:);
            obj.ListWithFilteredMaskInformationWithDrift =          obj.ListWithCompleteMaskInformationWithDrift(OkRows,:);

             obj =                                                  obj.updateTrackingResults;
             
            
             
             
         end
         
       
       
         
     
         function [TrackingListForMovieDisplay] =                               convertTrackingCellIntoTrackListForMovie(obj, TrackingCell, h)

             
                 NumberOfColumnsInMatrix=                                      obj.NumberOfColumnsInTrackingMatrix;
             
             
                Column_CentroidY=                                                      strcmp('CentroidY', obj.FieldNamesOfMaskInformation);
                Column_CentroidX=                                                       strcmp('CentroidX', obj.FieldNamesOfMaskInformation);
                Column_CentroidZ=                                                       strcmp('CentroidZ', obj.FieldNamesOfMaskInformation);

                Linewidth=                                                              1;
                TotalNumberOfTracks=                                                    size(TrackingCell,1);
                NewTrackingResults=                                                     cell(TotalNumberOfTracks,NumberOfColumnsInMatrix);

                NewTrackingResults(:,1)=                                                num2cell(1:TotalNumberOfTracks);
                NewTrackingResults(:,2)=                                                TrackingCell(:,1);

                NewTrackingResults(:,6)=                                                TrackingCell(:,7); % color-code
                NewTrackingResults(:,7)=                                                {Linewidth};

                NewTrackingResults(:,8)=                                                TrackingCell(:,3);
                NewTrackingResults(:,9)=                                                TrackingCell(:,4);
                NewTrackingResults(:,10)=                                               TrackingCell(:,5);
                NewTrackingResults(:,11)=                                               TrackingCell(:,6);


                %% get coordinates for each track:
                for SubtrackIndex=1:TotalNumberOfTracks % analyze either entire track or (non-overlapping) pieces (subtracks) of current track;

                    waitbar(SubtrackIndex/TotalNumberOfTracks,h,'Creating tracks')

                    CoordinateListOfCurrentSubtrack=                                    TrackingCell{SubtrackIndex,2};

                    NewTrackingResults{SubtrackIndex,3}=                          cell2mat(CoordinateListOfCurrentSubtrack(:,Column_CentroidX));
                    NewTrackingResults{SubtrackIndex,4}=                          cell2mat(CoordinateListOfCurrentSubtrack(:,Column_CentroidY));
                    NewTrackingResults{SubtrackIndex,5}=                          cell2mat(CoordinateListOfCurrentSubtrack(:,Column_CentroidZ));  

                end


                TrackingListForMovieDisplay =                                       NewTrackingResults;


             
             
         end
          
        
        
         
         
            
        function [ TrackingCell ] =                                      ConvertCoordinateListIntoTrackingCell( obj, CoordinateList)
        %CONVERTCOORDINATELISTINTOTRACKINGCELL Summary of this function goes here
        %   Detailed explanation goes here

            %% get relevant data from object:
            FieldNames =                                obj.FieldNamesOfMaskInformation;
            
            Set_NumberOfFramesInAnalyzedTracks=         obj.NumberOfFramesInSubTracks;
            JumpSize=                                   obj.JumpSizeBetweenSubTracks;


            %% process information:
            
            [ Tracks_ListWithSourceTrackData ] =        obj.FindAllUniqueTrackIDsInside(FieldNames, CoordinateList);
            [Start, End,  SourceTrackID] =              obj.FindPositionsOfSubTracks( Tracks_ListWithSourceTrackData , Set_NumberOfFramesInAnalyzedTracks, JumpSize);
            
            StartCell=                                  num2cell(Start);
            EndCell=                                    num2cell(End);
            SourceTrackIDCell=                          num2cell(SourceTrackID);


            %% transfer track IDs and coordinate lists into track cell;
            NumberOfSubtracks=                          size(Start,1);
            TrackListCell(1:NumberOfSubtracks,1)=       SourceTrackIDCell;
            TrackListCell(1:NumberOfSubtracks,2)=       cellfun(@(x,y) CoordinateList(x:y,:), StartCell, EndCell, 'UniformOutput', false);



            %% transfer track-range parameters and track color into track cell:
             Column_AbsoluteFrame=                       find(strcmp('AbsoluteFrame', FieldNames));
            if isempty(Column_AbsoluteFrame)
                Column_AbsoluteFrame= 2;
            end
            TrackListCellSpecific=                      TrackListCell(:,2);

            [MinimumFrames]=                            cellfun(@(x) min(cell2mat(x(:,Column_AbsoluteFrame))), TrackListCellSpecific);
            [MaximumFrames]=                            cellfun(@(x) max(cell2mat(x(:,Column_AbsoluteFrame))), TrackListCellSpecific);
            [TotalFrames]=                              cellfun(@(x) length(cell2mat(x(:,Column_AbsoluteFrame))), TrackListCellSpecific);
            [MissingFrames]=                            (MaximumFrames-MinimumFrames+1)-TotalFrames;
            [ ListWithTrackColors ] =                   obj.DefineColorInTrackList( MinimumFrames );

            TrackListCell(:,3)=                         num2cell(MinimumFrames);
            TrackListCell(:,4)=                         num2cell(MaximumFrames);
            TrackListCell(:,5)=                         num2cell(TotalFrames);
            TrackListCell(:,6)=                         num2cell(MissingFrames);
            TrackListCell(:,7)=                         ListWithTrackColors;

            TrackingCell =                              TrackListCell;

        end
        
        
        
        function [ ExportTrackInformation ] =                           FindAllUniqueTrackIDsInside(obj, FieldNamesOfMaskInformation, DataIn_ListWithCellMasks_Matrix)
                %FINDALLUNIQUETRACKIDS get duration and start for all tracks
                

                %   export: column 1: number of frames per track
                %           column 2: track ID
                %           column 3: start frame (optional)
                
                

                Column_TrackID=                             find(strcmp('TrackID', FieldNamesOfMaskInformation));

                ListWithAllTrackIDs=                   cell2mat(DataIn_ListWithCellMasks_Matrix(:,Column_TrackID));


                %% get unique track-IDs contained in tracking-results:
                if isempty(ListWithAllTrackIDs)
                    ExportTrackInformation=                   [];
                    return
                end

                if size(ListWithAllTrackIDs,2)<2
                    ListWithAllTrackIDs(1:end,2)=  NaN;
                end

                %% get list with unique track-IDs:
                Tracks_ListWithAllUniqueTrackIDs=                  unique(ListWithAllTrackIDs(:,1));
                assert(min(isnan(Tracks_ListWithAllUniqueTrackIDs))==0, 'Non-track associated masks present. Please fix')



                %% summarize track and subtrack-information:
                ExportTrackInformation=                         nan(length(Tracks_ListWithAllUniqueTrackIDs),3);
                ExportRow=  0;
                for CurrentTrackID= Tracks_ListWithAllUniqueTrackIDs' 

                    % get number of rows that are assigned to current track:
                    RowsAssociatedWithCurrentTrackID=               ListWithAllTrackIDs(:,1)==CurrentTrackID;

                    TotalNumberOfFramesMatchingTrackID=             sum(RowsAssociatedWithCurrentTrackID);

                    FirstFrameMatchingTrack=                        find(RowsAssociatedWithCurrentTrackID==1, 1, 'first');
                    LastFrameMatchingTrack=                         find(RowsAssociatedWithCurrentTrackID==1, 1, 'last');

                    ExportRow=                                      ExportRow+ 1;
                    ExportTrackInformation(ExportRow,1)=            TotalNumberOfFramesMatchingTrackID;
                    ExportTrackInformation(ExportRow,2)=            CurrentTrackID;
                    ExportTrackInformation(ExportRow,3)=            FirstFrameMatchingTrack;
                    ExportTrackInformation(ExportRow,4)=            LastFrameMatchingTrack;

                end


                ExportTrackInformation(:,5)=        ExportTrackInformation(:,4)-ExportTrackInformation(:,3)+1;
                TrackDurationConsistent=            ExportTrackInformation(:,1)==ExportTrackInformation(:,5);  
                TotalNumberOfTracks=                size(TrackDurationConsistent,1);
                NumberOfConsistentTracks=           sum(TrackDurationConsistent);
                assert(TotalNumberOfTracks==NumberOfConsistentTracks, 'Gaps between consecutive tracks. Check whether multiple movies are merged')


        end


        
               
        function [ Start, End,  ExpTrackID, StartFrameOfOriTrack] =     FindPositionsOfSubTracks(obj, Tracks_ListWithSourceTrackData, Set_NumberOfFramesInAnalyzedTracks, JumpSize )

                %FINDPOSITIONSOFSUBTRACKS find start and end rows of subtracks
                %   Detailed explanation goes here

                %% default return values:
                    Start=                  [];
                    End=                    [];
                    ExpTrackID=             [];
                    StartFrameOfOriTrack=   [];


                Tracks_TotalNumberOfOriginalTracks=                 size(Tracks_ListWithSourceTrackData,1);
                if Tracks_TotalNumberOfOriginalTracks== 0
                    return
                end


                 %% for each track: set number of desired subtrack duration and jumpsize;
                if isnan(Set_NumberOfFramesInAnalyzedTracks) ||  Set_NumberOfFramesInAnalyzedTracks== 0% if set duration is "NaN": analyzed each experimental track in its entirety
                    SubTrackDurationForEachOriginalTrack(1:Tracks_TotalNumberOfOriginalTracks,1)=  Tracks_ListWithSourceTrackData(:,1);
                else 
                    SubTrackDurationForEachOriginalTrack(1:Tracks_TotalNumberOfOriginalTracks,1)=  Set_NumberOfFramesInAnalyzedTracks;
                end

                if isnan(JumpSize) || JumpSize== 0
                     JumpStepsBetweenSubTracks(1:Tracks_TotalNumberOfOriginalTracks,1)=  Tracks_ListWithSourceTrackData(:,1);
                else
                    JumpStepsBetweenSubTracks(1:Tracks_TotalNumberOfOriginalTracks,1)=  JumpSize;
                end


                clear Tracks_NumberOfExperimentalTracks


                %% find start- and endrow
                ListWithEndRowOfEachOriginalTrack=            cumsum(Tracks_ListWithSourceTrackData(:,1));
                ListWithStartRowOfEachOriginalTrack=          ListWithEndRowOfEachOriginalTrack-Tracks_ListWithSourceTrackData(:,1)+1;

                StartAndEndPositionOfAnalyticTracks=          cell(size(ListWithStartRowOfEachOriginalTrack,1),1);
                for CurrentOriginalTrack=1:Tracks_TotalNumberOfOriginalTracks

                    StartRowOfOriginalTrack=                    ListWithStartRowOfEachOriginalTrack(CurrentOriginalTrack);
                    EndRowOfOriginalTrack=                      ListWithEndRowOfEachOriginalTrack(CurrentOriginalTrack);

                    CurrentFramesPerSubTrack=                   SubTrackDurationForEachOriginalTrack(CurrentOriginalTrack);

                    CurrentJumpSteps=                           JumpStepsBetweenSubTracks(CurrentOriginalTrack);

                    StartRowsOfSubTrack=                        (StartRowOfOriginalTrack:CurrentJumpSteps:EndRowOfOriginalTrack-CurrentFramesPerSubTrack+1)';
                    EndRowsOfSubTrack=                          (StartRowOfOriginalTrack+CurrentFramesPerSubTrack-1:CurrentJumpSteps:EndRowOfOriginalTrack)';

                    clear DesignationOfExpTrack StartFrameOfOriTrack
                    DesignationOfExpTrack(1:length(EndRowsOfSubTrack),1)=       Tracks_ListWithSourceTrackData(CurrentOriginalTrack,2);
                    StartFrameOfOriTrack(1:length(EndRowsOfSubTrack),1)=        Tracks_ListWithSourceTrackData(CurrentOriginalTrack,3);

                    %% ensure that start and endrows have equal length
                    if length(StartRowsOfSubTrack)> length(EndRowsOfSubTrack)
                        StartRowsOfSubTrack(end)= [];
                    end

                    StartAndEndPositionOfAnalyticTracks{CurrentOriginalTrack,1}=  StartRowsOfSubTrack;
                    StartAndEndPositionOfAnalyticTracks{CurrentOriginalTrack,2}=  EndRowsOfSubTrack;
                    StartAndEndPositionOfAnalyticTracks{CurrentOriginalTrack,3}=  DesignationOfExpTrack;
                    StartAndEndPositionOfAnalyticTracks{CurrentOriginalTrack,4}=  StartFrameOfOriTrack;

                end


                StartAndEndPositionOfAnalyticTracks(cellfun('isempty',StartAndEndPositionOfAnalyticTracks(:,1)),:)=[];

                %% convert results from cell to matrix format:
                % each row contains "position info" or "parent track" ID;
                if ~isempty(StartAndEndPositionOfAnalyticTracks)

                    Start=                              StartAndEndPositionOfAnalyticTracks(:,1);
                    Start=                              vertcat(Start{:});

                    End=                                StartAndEndPositionOfAnalyticTracks(:,2);
                    End=                                vertcat(End{:});

                    ExpTrackID=                         StartAndEndPositionOfAnalyticTracks(:,3);
                    ExpTrackID=                         vertcat(ExpTrackID{:});

                    StartFrameOfOriTrack=               StartAndEndPositionOfAnalyticTracks(:,4);
                    StartFrameOfOriTrack=               vertcat(StartFrameOfOriTrack{:});


                end

        end

        

        function [ ListWithTrackColors ] =                              DefineColorInTrackList(obj, Start )
            %DEFINECOLORINTRACKLIST Summary of this function goes here
            %   Detailed explanation goes here

            UniqueStarts=                       unique(Start);
            ColorOptions=                       { 'w',  'g', 'b','r',  'm', 'c', 'w',  'b','r', 'g', 'm', 'c'};

            NumberOfTracks=                     size(Start,1);
            ListWithTrackColors=                cell(NumberOfTracks,1);

            NumberOfDifferentStartPositions=    length(UniqueStarts);
            NumberOfDifferentColors=            length(ColorOptions);
            for StartIndex=1:NumberOfDifferentStartPositions

                ColorIndex=                     mod(StartIndex-1, NumberOfDifferentColors)+1;
                Color=                          ColorOptions{ColorIndex};
                CurrentStartPosition=           UniqueStarts(StartIndex);
                RelevantRows=                   Start==    CurrentStartPosition; 

                ListWithTrackColors(RelevantRows,:)=  {Color};

            end


        end


            
        function [ CoordinateList ] =                                   AddDriftCorrectionToCoordinateList(CoordinateList, FieldNames, StructureWithDriftAnalysisData )
            %ADDDRIFTCORRECTIONTOCOORDINATELIST Summary of this function goes here
            %   Detailed explanation goes here

            
                %% get parameters for each column:

                Column_AbsoluteFrame=                       find(strcmp('AbsoluteFrame', FieldNames));
                Column_CentroidY=                           find(strcmp('CentroidY', FieldNames));
                Column_CentroidX=                           find(strcmp('CentroidX', FieldNames));
                Column_CentroidZ=                           find(strcmp('CentroidZ', FieldNames));

                Column_TopZ=                                find(strcmp('TopZPlane', FieldNames));
                Column_BottomZ=                             find(strcmp('BottomZPlane', FieldNames));

                ListWithXCoordinates=                       cell2mat(CoordinateList(:,Column_CentroidX));  
                ListWithYCoordinates=                       cell2mat(CoordinateList(:,Column_CentroidY));

                ZTop=                                       cell2mat(CoordinateList(:,Column_TopZ));
                ZBottom=                                    cell2mat(CoordinateList(:,Column_BottomZ));
                ListWithZCoordinates=                       mean([ ZTop, ZBottom], 2); 

                ListWithAbsoluteFrames=                     cell2mat(CoordinateList(:,Column_AbsoluteFrame));

                %% get drift-correction results:
                RowShiftsAbsolute=                          StructureWithDriftAnalysisData.RowShiftsAbsolute;
                ColumnShiftsAbsolute=                       StructureWithDriftAnalysisData.ColumnShiftsAbsolute;
                PlaneShiftsAbsolute=                        StructureWithDriftAnalysisData.PlaneShiftsAbsolute;

                ListWithFrames=                             unique(ListWithAbsoluteFrames);
                NumberOfUniqueFrames=                       length(ListWithFrames); 
                for CurrentFrameDriftCorrection=1:NumberOfUniqueFrames

                    CurrentFrameNumber=                     ListWithFrames(CurrentFrameDriftCorrection);

                    RowShiftForCurrentFrame=                RowShiftsAbsolute(CurrentFrameNumber);
                    ColumnShiftForCurrentFrame=             ColumnShiftsAbsolute(CurrentFrameNumber);
                    PlaneShiftForCurrentFrame=              PlaneShiftsAbsolute(CurrentFrameNumber);

                    ListWithXCoordinates(ListWithAbsoluteFrames==CurrentFrameNumber)=   ListWithXCoordinates(ListWithAbsoluteFrames==CurrentFrameNumber)+ColumnShiftForCurrentFrame;
                    ListWithYCoordinates(ListWithAbsoluteFrames==CurrentFrameNumber)=   ListWithYCoordinates(ListWithAbsoluteFrames==CurrentFrameNumber)+RowShiftForCurrentFrame;
                    ListWithZCoordinates(ListWithAbsoluteFrames==CurrentFrameNumber)=   ListWithZCoordinates(ListWithAbsoluteFrames==CurrentFrameNumber)+PlaneShiftForCurrentFrame;

                end


                CoordinateList(:,Column_CentroidX)=    num2cell(ListWithXCoordinates);  
                CoordinateList(:,Column_CentroidY)=    num2cell(ListWithYCoordinates);  
                CoordinateList(:,Column_CentroidZ)=    num2cell(ListWithZCoordinates);  

                
        end



        function [TrackSegment] =                                       extractTrackSegment(obj, TrackID, FrameNumbers)
            
            
            
        end

          
        
    end
end

