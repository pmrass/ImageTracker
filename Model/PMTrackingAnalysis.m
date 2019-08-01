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


        % this contains the entire tracking information and should be used primarily for reading data, units may be changed;
        
        CurrentDistanceUnits =                          'pixels';
        CurrentTimeUnits =                              'imageFrames';
        
        FieldNamesOfMaskInformation
        ListWithCompleteMaskInformation =               cell(0,6)
        ListWithCompleteMaskInformationWithDrift =      cell(0,6) % drift information is in duplicate, this makes it easier to switch between drift-corrected and non-drift corrected data with acceptable overhead
         MaskFilter =                                   true(0,1) % the mask filter filters for masks and determines on what mask;

        % filtered properties: allows  
        DriftCorrection
        MetaData
        
        %% track cell is created by original movie data and its main use is create track-specific quantitative data:
        
        % this is for subtrack generation: you can use it to get
        % shorter "track-children" from longer source tracks;
        NumberOfFramesInSubTracks =                     NaN % this means that the "entire" tracks whill be generated (not subtracks);
        JumpSizeBetweenSubTracks =                      NaN % how much "overlap" between subtracks is wanted
       
        
        % TrackCell is used to allow quantification of parameters per track (or subtrack);
        TrackCell =                                     cell(0,1)
        TrackCellFieldNames
        NumberOfColumnsInTrackingMatrix =               12
        NumberOfRandomizations =                        30
        
        
        
        
        %%  TrackingCell and TrackingListForMovieDisplay are quite similar and are here mostly for historic reasons;
        % nevertheless, leave for consistency, just prevent extensive proliferation of permanent properties in the future;
        % their main use is primariy for visual display of track data:
        ColumnsForTrackingCell =                        {'ParentTrackID', 'SubtrackCoordinates', ... 
                                                        'FirstTrackedFrame', 'LastTrackedFrame', 'NumberOfTrackedFrames', 'NumberOfFrameGaps', ...
                                                        'LineColor'};
        TrackingCell
        TrackingCellWithDrift
        TrackColorScheme =                          'DefinedByFirstTrackedFrame';
        
        
        % this creates a "track model" that can be used for convenient generation of track views in other contexts;
        ColumnsInTracksForMovieDisplay =        {'OrderNumber', 'TrackID', 'XCoordinateList', 'YCoordinateList', 'ZCoordinateList', ...
            'LineColor', 'LineWidth', ...
            'FirstTrackedFrame', 'LastTrackedFrame', 'NumberOfTrackedFrames', 'NumberOfFrameGaps', 'Unknown'};
        
        TrackingListForMovieDisplay
        TrackingListWithDriftForMovieDisplay
        
        DefaultTrackLineWidth =             1
        
        
        
        
    end
    
    methods
        
        
        function obj = PMTrackingAnalysis(varargin)
        %PMTRACKINGANALYSIS Construct an instance of this class
        %   Detailed explanation goes here


                NumberOfInputArguments =        length(varargin);


                switch NumberOfInputArguments

                    case 0


                    case 2

                        TrackingAnalysisBasis = varargin{1};
                        DriftCorrection =       varargin{2};

                        obj.DriftCorrection =         DriftCorrection;
                        obj =                       obj.createListWithCompleteMaskInformation(TrackingAnalysisBasis);
                        [obj]=                      obj.ConvertTrackingResultsIntoTrackCell;
                        obj =                       obj.updateTrackingResults;


                    case 3

                        TrackingAnalysisBasis =         varargin{1};
                        DriftCorrection =               varargin{2};
                        obj.MetaData =                  varargin{3};

                        obj.DriftCorrection =           DriftCorrection;
                        obj =                           obj.createListWithCompleteMaskInformation(TrackingAnalysisBasis);
                        [obj]=                          obj.ConvertTrackingResultsIntoTrackCell;
                        obj =                           obj.updateTrackingResults;

                    otherwise
                        error('Only 0 or to input arguments supported')


                end

        end


        function [ obj ] =                                                  createListWithCompleteMaskInformation(obj, TrackingAnalysisBasis)
        %CONVERTTRACKINGSTRUCTURETOCELL Summary of this function goes here
        %   Detailed explanation goes here

            ListWithFieldNames =                        TrackingAnalysisBasis.FieldNamesForTrackingCell;
            DataIn_ListWithCellMasks_Matrix =           vertcat(TrackingAnalysisBasis.TrackingCellForTime{:});

            Column_TrackID=                             find(strcmp('TrackID', ListWithFieldNames));
            Column_AbsoluteFrame=                       find(strcmp('AbsoluteFrame', ListWithFieldNames));
            Column_CentroidY =                          find(strcmp('CentroidY', ListWithFieldNames));


            %% remove untracked masks:  % not sure if this is necessary:
            if isempty(DataIn_ListWithCellMasks_Matrix)
                return
            end

            DataIn_ListWithCellMasks_Matrix(cell2mat(DataIn_ListWithCellMasks_Matrix(:,Column_TrackID))==0,:)=          []; % remove untracked masks;
            DataIn_ListWithCellMasks_Matrix(isnan(cell2mat(DataIn_ListWithCellMasks_Matrix(:,Column_TrackID))),:)=      []; % remove untrackable masks


            %% sort by track ID and time-frames:
            if ~isempty(DataIn_ListWithCellMasks_Matrix)
                DataIn_ListWithCellMasks_Matrix=                        sortrows(DataIn_ListWithCellMasks_Matrix,[Column_TrackID Column_AbsoluteFrame]);   
            end

            %% remove rows that contain nan (this should anyway not be the case);

            BadRows =                                                   cellfun(@(x) isnan(x), DataIn_ListWithCellMasks_Matrix(:,Column_CentroidY));
            DataIn_ListWithCellMasks_Matrix(BadRows,:) =                [];

            
            %% create basic mask information plus drift-correction plus reset filter:
            obj.FieldNamesOfMaskInformation =                           ListWithFieldNames;
            obj.ListWithCompleteMaskInformation =                       DataIn_ListWithCellMasks_Matrix;

            obj =                                                       obj.createDriftCorrectedMaskInformation;
            obj =                                                       obj.unFilterTracks;

        end


        
        %% manage track-filters:
         function [obj] =                                                   unFilterTracks(obj)
             
                obj.MaskFilter =                                        true(size(obj.ListWithCompleteMaskInformation,1),1);
             
         end
         
         

         function [obj] =                                                   addFilterForTrackIds(obj, AcceptedTrackIDs)
               
              
                OldMaskFilter =                                             obj.MaskFilter;
                ColumnWithTrackID =                                         strcmp(obj.FieldNamesOfMaskInformation, 'TrackID');
                AddedMaskFilter =                                           ~ismember(cell2mat(obj.ListWithCompleteMaskInformation(:,ColumnWithTrackID)), AcceptedTrackIDs);
                NewMaskFilter =                                             min([AddedMaskFilter    OldMaskFilter], [], 2);

                obj.MaskFilter =                                            NewMaskFilter;
                obj =                                                       obj.updateTrackingResults;

           end
     
         
         
         function [obj] =                                                   addFilterForTrackFrames(obj, AcceptedFrames)
             

            OldMaskFilter =                                             obj.MaskFilter;
            ColumnWithFrameNumber =                                     strcmp(obj.FieldNamesOfMaskInformation, 'AbsoluteFrame');
            AddedMaskFilter =                                           ~ismember(cell2mat(obj.ListWithCompleteMaskInformation(:,ColumnWithFrameNumber)), AcceptedFrames);
            NewMaskFilter =                                             min([AddedMaskFilter    OldMaskFilter], [], 2);

            obj.MaskFilter =                                            NewMaskFilter;
            obj =                                                       obj.updateTrackingResults;

             
         end
         
         %% manage drift correction:
          function [obj] =                                                  createDriftCorrectedMaskInformation(obj)

              
                %% read data:
                FieldNames =                                obj.FieldNamesOfMaskInformation;
                CoordinateListIn =                          obj.ListWithCompleteMaskInformation;

                RowShiftsAbsolute=                          obj.DriftCorrection.RowShiftsAbsolute;
                ColumnShiftsAbsolute=                       obj.DriftCorrection.ColumnShiftsAbsolute;
                PlaneShiftsAbsolute=                        obj.DriftCorrection.PlaneShiftsAbsolute;
                
                assert(~isempty(obj.DriftCorrection.RowShiftsAbsolute), 'Drift correction object is incomplete. Please fix')
                
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

                
                %% return coordinate list with drift correction back to object;
                obj.ListWithCompleteMaskInformationWithDrift =      CoordinateListIn;

        end

     
       
  
         %% manage units of tracking-data:

        function [obj] =                                                    convertDistanceUnitsIntoUm(obj)

            OldDistanceUnits =                                              obj.CurrentDistanceUnits;              
            obj.CurrentDistanceUnits =                                      'um';

            MetaDataInternal =                                              obj.MetaData;

            CoordinateList =                                                obj.ListWithCompleteMaskInformationWithDrift;
            CoordinateListColumnTitles =                                    obj.FieldNamesOfMaskInformation;

            switch OldDistanceUnits

                case 'pixels'


                    ColumnWithCentroidZ =                                           strcmp(CoordinateListColumnTitles, 'CentroidZ');
                    ColumnWitCentroidY =                                            strcmp(CoordinateListColumnTitles, 'CentroidY');
                    ColumnWithCentroidX =                                           strcmp(CoordinateListColumnTitles, 'CentroidX');


                    Meta_DistanceBetweenPixels_Z=                                   MetaDataInternal.EntireMovie.VoxelSizeZ*10^6;
                    Meta_DistanceBetweenPixels_Y=                                   MetaDataInternal.EntireMovie.VoxelSizeY*10^6;
                    Meta_DistanceBetweenPixels_X=                                   MetaDataInternal.EntireMovie.VoxelSizeX*10^6;

                    CoordinateList_um=                                              CoordinateList;

                    CoordinateList_um(:,ColumnWithCentroidX)=                       num2cell(cell2mat(CoordinateList(:,ColumnWithCentroidX))*Meta_DistanceBetweenPixels_X);   % µm 
                    CoordinateList_um(:,ColumnWitCentroidY)=                        num2cell(cell2mat(CoordinateList(:,ColumnWitCentroidY))*Meta_DistanceBetweenPixels_Y);  % µm
                    CoordinateList_um(:,ColumnWithCentroidZ)=                       num2cell(cell2mat(CoordinateList(:,ColumnWithCentroidZ))*Meta_DistanceBetweenPixels_Z);



                    obj.ListWithCompleteMaskInformationWithDrift =                  CoordinateList_um;



                case 'um'




            end






        end


        function [obj] =                                                    convertTimeUnitsIntoSeconds(obj)


            CoordinateListColumnTitles =                obj.FieldNamesOfMaskInformation;
            MetaDataInternal =                          obj.MetaData;
            CoordinateList =                            obj.ListWithCompleteMaskInformationWithDrift;
            ColumnWithTime =                            strcmp(CoordinateListColumnTitles, 'AbsoluteFrame');

            OldTimeUnits =                              obj.CurrentTimeUnits;

            obj.CurrentTimeUnits =                      'seconds';

            switch OldTimeUnits

                case 'imageFrames'

                    TimeInSeconds_FirstFrameZero=                                   MetaDataInternal.RelativeTimeStamps;

                    CoordinateList_seconds =                                        CoordinateList;
                    % time of each frame in seconds:
                    CoordinateList_seconds(:,ColumnWithTime)=                       num2cell(TimeInSeconds_FirstFrameZero(cell2mat(CoordinateList(:,ColumnWithTime)),:));
                    obj.ListWithCompleteMaskInformationWithDrift =                  CoordinateList_seconds;


                case 'seconds'


            end




        end

       
       
      
         %% create tracklist-model to support visual display of tracks:
         
         

        function [obj]=                                                     ConvertTrackingResultsIntoTrackCell(obj)

            
            CoordinateList =                                    obj.ListWithCompleteMaskInformationWithDrift(obj.MaskFilter,:); 
            ListWithFieldNames =                                obj.FieldNamesOfMaskInformation;

            if isempty(CoordinateList)
                TrackCellInternal =                                         cell(0,1);
               

            else
                
               
                ColumnWithTrackID =                                         find(strcmp('TrackID', ListWithFieldNames));    
                ColumnForAbsoluteFrames =                                   strcmp('AbsoluteFrame', ListWithFieldNames);

                ListWithAllTrackIDs=                                        cell2mat(CoordinateList(:,ColumnWithTrackID));
                ListWithAllAbsoluteFrameNumbers =                           cell2mat(CoordinateList(:,ColumnForAbsoluteFrames));

                [ MapOfTrackList ] =                                        obj.CreateMapOfTrackList(ListWithAllTrackIDs, ListWithAllAbsoluteFrameNumbers);
                
                NumberOfFramesInSubTracksInternal=                          obj.NumberOfFramesInSubTracks;
                JumpSize=                                                   obj.JumpSizeBetweenSubTracks;
                [TrackStartRows, TrackEndRows,  ParentTrackID] =            obj.FindPositionsOfSubTracks( MapOfTrackList , NumberOfFramesInSubTracksInternal, JumpSize);

                TrackCellInternal=                                          arrayfun(@(x,y) CoordinateList(x:y,:), TrackStartRows, TrackEndRows, 'UniformOutput', false);
                   
            end

            obj.TrackCellFieldNames =                                   ListWithFieldNames;
            obj.TrackCell =                                             TrackCellInternal;

        end
        
        
        function trackCellChildren = getTrackChildrenFromTrackCell(obj, NumberOfFramesInSubtracks_Straightness, JumpSize)
            
            TrackMap  =                                                         cellfun(@(x) obj.CreateMapOfTrackList(cell2mat(x(:,1)),0), obj.TrackCell, 'UniformOutput', false);
            [ TrackStartRows, TrackEndRows,  ~, ~] =                            cellfun(@(x) obj.FindPositionsOfSubTracks(x, NumberOfFramesInSubtracks_Straightness, JumpSize ), TrackMap,  'UniformOutput', false);
            trackCellChildren =                                                 cell(length(TrackStartRows),1);

            for ParentTrackIndex = 1:length(TrackStartRows)

                CurrentCoordinates =                                        obj.TrackCell{ParentTrackIndex,1};      
                CurrentStartRows =                                          TrackStartRows{  ParentTrackIndex,1};
                CurrentEndRows =                                            TrackEndRows{ParentTrackIndex,1};
                
                CoordinateListPerSubTrack=                                  arrayfun(@(startRow,endRow) CurrentCoordinates(startRow:endRow,:), CurrentStartRows,CurrentEndRows,  'UniformOutput', false);

                trackCellChildren{ParentTrackIndex,1} =                     CoordinateListPerSubTrack;

            end
            
            
            
        end


        
        
         
        function [obj] =                                                    updateTrackingResults(obj)         


            h=     waitbar(0, 'Creating tracks');

            % convert tracking structure into cell matrix:    %   drift correction should be added only to first frame:
            % first update the object

            % [ CoordinateListWithoutDriftCorrection ] =                                     AddDriftCorrectionToCoordinateList( CoordinateListWithoutDriftCorrection, FieldNamesOfCoordinateList, StructureWithDriftAnalysisData );


            % get subtracklocation within coordinate list and in loop convert each coordinate list to "tracking-result":
            FilteredCoordinateList =                                                    obj.ListWithCompleteMaskInformation(obj.MaskFilter,:);
            obj.TrackingCell =                                                          obj.ConvertCoordinateListIntoTrackingCell(FilteredCoordinateList);
            obj.TrackingListForMovieDisplay =                                           obj.convertTrackingCellIntoTrackListForMovie(obj.TrackingCell, h);

            FilteredCoordinateListWithDrift =                                           obj.ListWithCompleteMaskInformationWithDrift(obj.MaskFilter,:);
            obj.TrackingCellWithDrift =                                                 obj.ConvertCoordinateListIntoTrackingCell(FilteredCoordinateListWithDrift);
            obj.TrackingListWithDriftForMovieDisplay =                                  obj.convertTrackingCellIntoTrackListForMovie(obj.TrackingCellWithDrift, h);

            close(h)

        end


    
        function [ TrackingCell ] =                                         ConvertCoordinateListIntoTrackingCell( obj, CoordinateList)
        %CONVERTCOORDINATELISTINTOTRACKINGCELL Summary of this function goes here
        %   Detailed explanation goes here

            %% get relevant data from object:
            FieldNames =                                                obj.FieldNamesOfMaskInformation;
            NumberOfFramesInSubTracksInternal=                          obj.NumberOfFramesInSubTracks;
            JumpSize=                                                   obj.JumpSizeBetweenSubTracks;
            TrackColorSchemeInternal =                                  obj.TrackColorScheme;


            %% process data:
            % first map subtrack positions in entire coordinate list:
            
            ColumnForAbsoluteFrames =                                   strcmp('AbsoluteFrame', FieldNames);
           
            ListWithAllTrackIDs=                                        cell2mat(CoordinateList(:,strcmp('TrackID', FieldNames)));
            ListWithAllAbsoluteFrameNumbers =                           cell2mat(CoordinateList(:,ColumnForAbsoluteFrames));

            [ MapOfTrackList ] =                                        obj.CreateMapOfTrackList(ListWithAllTrackIDs, ListWithAllAbsoluteFrameNumbers);
            [TrackStartRows, TrackEndRows,  ParentTrackID] =            obj.FindPositionsOfSubTracks( MapOfTrackList , NumberOfFramesInSubTracksInternal, JumpSize);
            
            % then use the subtrack positions to calculate key data from ;
            CoordinateListPerSubTrack=                                  arrayfun(@(x,y) CoordinateList(x:y,:), TrackStartRows, TrackEndRows, 'UniformOutput', false);

            [MinimumFrames]=                                            cellfun(@(x) min(cell2mat(x(:,ColumnForAbsoluteFrames))), CoordinateListPerSubTrack);
            [MaximumFrames]=                                            cellfun(@(x) max(cell2mat(x(:,ColumnForAbsoluteFrames))), CoordinateListPerSubTrack);
            [TotalFrames]=                                              cellfun(@(x) length(cell2mat(x(:,ColumnForAbsoluteFrames))), CoordinateListPerSubTrack);
            [MissingFrames]=                                            (MaximumFrames-MinimumFrames+1)-TotalFrames;
            
            switch   TrackColorSchemeInternal
        
                case 'DefinedByFirstTrackedFrame'
                        [ ListWithTrackColors ] =                                   obj.DefineColorInTrackList( MinimumFrames );
                        
                        
            end

            %% transfer data back ;
            
            if isempty(ParentTrackID)
                TrackingCell =                                              cell(0,7);
                
            else
                TrackingCell(:,1)=                                          num2cell(ParentTrackID);
                TrackingCell(:,2)=                                          CoordinateListPerSubTrack;
                TrackingCell(:,3)=                                          num2cell(MinimumFrames);
                TrackingCell(:,4)=                                          num2cell(MaximumFrames);
                TrackingCell(:,5)=                                          num2cell(TotalFrames);
                TrackingCell(:,6)=                                          num2cell(MissingFrames);
                TrackingCell(:,7)=                                          ListWithTrackColors;
                
            end
            
           

            
        end
        
        
        
          function [TrackingListForMovieDisplay] =                               convertTrackingCellIntoTrackListForMovie(obj, TrackingCell, h)

                %% read object data:
                NumberOfColumnsInMatrix=                                                        obj.NumberOfColumnsInTrackingMatrix;
                Linewidth=                                                                      obj.DefaultTrackLineWidth;
                

                Column_CentroidY=                                                               strcmp('CentroidY', obj.FieldNamesOfMaskInformation);
                Column_CentroidX=                                                               strcmp('CentroidX', obj.FieldNamesOfMaskInformation);
                Column_CentroidZ=                                                               strcmp('CentroidZ', obj.FieldNamesOfMaskInformation);

                
                %% process ;
                TotalNumberOfTracks=                                                             size(TrackingCell,1);
                TrackingListForMovieDisplay=                                                     cell(TotalNumberOfTracks,NumberOfColumnsInMatrix);

                TrackingListForMovieDisplay(:,1)=                                                num2cell(1:TotalNumberOfTracks);
                TrackingListForMovieDisplay(:,2)=                                                TrackingCell(:,1);

                TrackingListForMovieDisplay(:,6)=                                                TrackingCell(:,7); % color-code
                TrackingListForMovieDisplay(:,7)=                                                {Linewidth};

                TrackingListForMovieDisplay(:,8)=                                                TrackingCell(:,3); % 'FirstTrackedFrame'
                TrackingListForMovieDisplay(:,9)=                                                TrackingCell(:,4); %  'LastTrackedFrame'
                TrackingListForMovieDisplay(:,10)=                                               TrackingCell(:,5); %  'NumberOfTrackedFrames'
                TrackingListForMovieDisplay(:,11)=                                               TrackingCell(:,6); %  'NumberOfFrameGaps'


                %% each coordinate list (x, y, and z gets its own column):
                for SubtrackIndex=1:TotalNumberOfTracks

                    waitbar(SubtrackIndex/TotalNumberOfTracks,h,'Creating tracks')

                    CoordinateListOfCurrentSubtrack=                                        TrackingCell{SubtrackIndex,2};

                    TrackingListForMovieDisplay{SubtrackIndex,3}=                           cell2mat(CoordinateListOfCurrentSubtrack(:,Column_CentroidX));
                    TrackingListForMovieDisplay{SubtrackIndex,4}=                           cell2mat(CoordinateListOfCurrentSubtrack(:,Column_CentroidY));
                    TrackingListForMovieDisplay{SubtrackIndex,5}=                           cell2mat(CoordinateListOfCurrentSubtrack(:,Column_CentroidZ));  

                end

   
         end
          
        
        
        function [ MapOfTrackList ] =                                       CreateMapOfTrackList(obj, ListWithAllTrackIDs, ListWithAllAbsoluteFrameNumbers)
             
            
                %FINDALLUNIQUETRACKIDS get duration and start for all tracks
                
                %   export: column 1: number of frames per track
                %           column 2: track ID
                %           column 3: start frame (optional)
                

                %% get unique track-IDs contained in tracking-results:
                if isempty(ListWithAllTrackIDs)
                    MapOfTrackList=                                 [];
                    return
                end


                %% get list with unique track-IDs:
                Tracks_ListWithAllUniqueTrackIDs=                  unique(ListWithAllTrackIDs(:,1));
                assert(min(isnan(Tracks_ListWithAllUniqueTrackIDs))==0, 'The analysis cannot be performed. Reason: some of the masks are NaN, i.e. they have no assigned track')

                
                %% summarize track and subtrack-information:
                MapOfTrackList=                                     nan(length(Tracks_ListWithAllUniqueTrackIDs),3);
                ExportRow=  0;
                for CurrentTrackID= Tracks_ListWithAllUniqueTrackIDs' 

                    % get number of rows that are assigned to current track:
                    RowsAssociatedWithCurrentTrackID=               ListWithAllTrackIDs(:,1)==CurrentTrackID;

                    TotalNumberOfFramesMatchingTrackID=             sum(RowsAssociatedWithCurrentTrackID);

                    FirstFrameMatchingTrack=                        find(RowsAssociatedWithCurrentTrackID==1, 1, 'first');
                    LastFrameMatchingTrack=                         find(RowsAssociatedWithCurrentTrackID==1, 1, 'last');

                    ExportRow=                                      ExportRow + 1;
                    MapOfTrackList(ExportRow,1)=                    TotalNumberOfFramesMatchingTrackID;
                    MapOfTrackList(ExportRow,2)=                    CurrentTrackID;
                    MapOfTrackList(ExportRow,3)=                    FirstFrameMatchingTrack;
                    MapOfTrackList(ExportRow,4)=                    LastFrameMatchingTrack;

                end

                
                MapOfTrackList(:,5)=                                MapOfTrackList(:,4) - MapOfTrackList(:,3) + 1;

                
                %% this is a test for whether track numbers follow certain guidelines;
                % if guidelines are not met: use throw an error:
                % it will be possible to use an alternative approach for this;
                % the guidelines are very specific and may not catch all constituencies;
                % consider optimization, potentially by using ListWithAllAbsoluteFrameNumbers to test track consistencies (e.g. are there mutliple matches for trackIDs for an identical time-frame;
                DifferenceBetweenFirstAndLastFrame =                        MapOfTrackList(:,5);
                TotalNumberOfFramesInTrack =                                MapOfTrackList(:,1);
                
                NumberOfFramesAndDifferenceBetweenFirstAndLastEqual=        DifferenceBetweenFirstAndLastFrame == TotalNumberOfFramesInTrack;  
                
                NumberOfTracks=                                             size(NumberOfFramesAndDifferenceBetweenFirstAndLastEqual,1);
                NumberOfTracksWithMatchingFrames=                           sum(NumberOfFramesAndDifferenceBetweenFirstAndLastEqual);
                assert(NumberOfTracks==NumberOfTracksWithMatchingFrames, 'Gaps between consecutive tracks. Check whether multiple movies are merged')


        end


        
               
        function [ startPositions, endPositions,  parentTrackIDs, parentStartFrames] =     FindPositionsOfSubTracks(obj, MapOfTrackList, NumberOfFramesInSubTracksInternal, JumpSize )

            
                %FINDPOSITIONSOFSUBTRACKS find start and end rows of subtracks
                %   Detailed explanation goes here

                %% default return values:
                    startPositions=                     [];
                    endPositions=                       [];
                    parentTrackIDs=                             [];
                    parentStartFrames=                   [];


                TotalNumberOfParentTracks=                              size(MapOfTrackList,1);
                if TotalNumberOfParentTracks== 0
                    return
                end


                 %% for each track: set number of desired subtrack duration and jumpsize;
                if isnan(NumberOfFramesInSubTracksInternal) ||  NumberOfFramesInSubTracksInternal== 0% if set duration is "NaN": analyzed each experimental track in its entirety
                    SubTrackDurationForEachOriginalTrack(1:TotalNumberOfParentTracks,1)=  MapOfTrackList(:,1);
                       
                else 
                    SubTrackDurationForEachOriginalTrack(1:TotalNumberOfParentTracks,1)=  NumberOfFramesInSubTracksInternal;
                end

                if isnan(JumpSize) || JumpSize== 0
                    if isnan(NumberOfFramesInSubTracksInternal) ||  NumberOfFramesInSubTracksInternal== 0
                        JumpStepsBetweenSubTracks(1:TotalNumberOfParentTracks,1) =  MapOfTrackList(:,1);
                    else
                        JumpStepsBetweenSubTracks(1:TotalNumberOfParentTracks,1) = NumberOfFramesInSubTracksInternal - 1;
                    end
                else
                    JumpStepsBetweenSubTracks(1:TotalNumberOfParentTracks,1)=  JumpSize;
                end


                %% find start- and end rows for all subtracks
                ListWithEndRowsForAllParenTracks=                   cumsum(MapOfTrackList(:,1));
                ListWithStartRowsForAllParentTracks=                ListWithEndRowsForAllParenTracks-MapOfTrackList(:,1)+1;

                StartAndEndPositionOfParentTracks=                  cell(size(ListWithStartRowsForAllParentTracks,1),1);
                for ParentTrackIndex=1:TotalNumberOfParentTracks

                    StartRowOfOriginalTrack=                        ListWithStartRowsForAllParentTracks(ParentTrackIndex);
                    EndRowOfOriginalTrack=                          ListWithEndRowsForAllParenTracks(ParentTrackIndex);

                    CurrentFramesPerSubTrack=                       SubTrackDurationForEachOriginalTrack(ParentTrackIndex);

                    CurrentJumpSteps=                               JumpStepsBetweenSubTracks(ParentTrackIndex);

                    StartRowsOfAllSubtracks=                        (StartRowOfOriginalTrack:CurrentJumpSteps:EndRowOfOriginalTrack-CurrentFramesPerSubTrack+1)';
                    EndRowsOfAllSubTracks=                          (StartRowOfOriginalTrack+CurrentFramesPerSubTrack-1:CurrentJumpSteps:EndRowOfOriginalTrack)';

                    clear ListWithParentTrackIDs ListWithStartFramesOfParentTrack
                    ListWithParentTrackIDs(1:length(EndRowsOfAllSubTracks),1)=                          MapOfTrackList(ParentTrackIndex,2);
                    parentStartFrames(1:length(EndRowsOfAllSubTracks),1)=                MapOfTrackList(ParentTrackIndex,3);

                    % if an "extra" start position was found, remove;
                    if length(StartRowsOfAllSubtracks)> length(EndRowsOfAllSubTracks)
                        StartRowsOfAllSubtracks(end)= [];
                    end

                    %% ensure that start and endrows have equal length
                    StartAndEndPositionOfParentTracks{ParentTrackIndex,1}=      StartRowsOfAllSubtracks;
                    StartAndEndPositionOfParentTracks{ParentTrackIndex,2}=      EndRowsOfAllSubTracks;
                    StartAndEndPositionOfParentTracks{ParentTrackIndex,3}=      ListWithParentTrackIDs;
                    StartAndEndPositionOfParentTracks{ParentTrackIndex,4}=      parentStartFrames;

                end


                StartAndEndPositionOfParentTracks(cellfun('isempty',StartAndEndPositionOfParentTracks(:,1)),:)=[];

                %% convert results from cell to matrix format:
                % each row contains "position info" or "parent track" ID;
                if ~isempty(StartAndEndPositionOfParentTracks)

                    startPositions=                              StartAndEndPositionOfParentTracks(:,1);
                    startPositions=                              vertcat(startPositions{:});

                    endPositions=                                StartAndEndPositionOfParentTracks(:,2);
                    endPositions=                                vertcat(endPositions{:});

                    parentTrackIDs=                                     StartAndEndPositionOfParentTracks(:,3);
                    parentTrackIDs=                                     vertcat(parentTrackIDs{:});

                    parentStartFrames=                           StartAndEndPositionOfParentTracks(:,4);
                    parentStartFrames=                           vertcat(parentStartFrames{:});


                end

        end

        

        function [ ListWithTrackColors ] =                                      DefineColorInTrackList(obj, Start )
            %DEFINECOLORINTRACKLIST Summary of this function goes here
            %   Detailed explanation goes here

            UniqueStarts=                                       unique(Start);
            ColorOptions=                                       { 'w',  'g', 'b','r',  'm', 'c', 'w',  'b','r', 'g', 'm', 'c'};

            NumberOfTracks=                                     size(Start,1);
            ListWithTrackColors=                                cell(NumberOfTracks,1);

            NumberOfDifferentStartPositions=                    length(UniqueStarts);
            NumberOfDifferentColors=                            length(ColorOptions);
            for StartIndex=1:NumberOfDifferentStartPositions

                ColorIndex=                                     mod(StartIndex-1, NumberOfDifferentColors)+1;
                Color=                                          ColorOptions{ColorIndex};
                CurrentStartPosition=                           UniqueStarts(StartIndex);
                RelevantRows=                                   Start==    CurrentStartPosition; 

                ListWithTrackColors(RelevantRows,:)=            {Color};

            end


        end


           
     
       
        
            
   
       
        
        %% extract speed information from TrackCell:
        function [speeds] =                                                 getAverageTrackSpeeds(obj)
            
            
            inputTrackCell =                            obj.TrackCell;
            deleteRows =                                cellfun(@(x) size(x,1)<=1,inputTrackCell ); % need at least two frames to calculate meaningful displacement
            inputTrackCell(deleteRows,:) =              [];
            
             speeds =                                   cellfun(@(x) obj.getAverageTrackSpeed(x),  inputTrackCell);
           
        end
        

        
        function speed =                getAverageTrackSpeed(obj, Track)
            
          if size(cell2mat(Track(:,3)),1) <= 1
              speed = zeros(0,1);
              
          else
              
            XDistances =                    sum(abs(diff(cell2mat(Track(:,3)))));
            YDistances =                    sum(abs(diff(cell2mat(Track(:,4)))));
            ZDistances =                    sum(abs(diff(cell2mat(Track(:,5)))));

            Distance3DUm =                  sqrt(XDistances^2 + YDistances^2 + ZDistances^2);
            TotalTimeSeconds =              max(cell2mat(Track(:,2))) - min(cell2mat(Track(:,2))) ;

            speed =                         Distance3DUm/TotalTimeSeconds*60;

              
              
          end
            
            
        end
        
        %% create displacement coordinate list:
        
        
        function [tracksWithPolarCoordinates] =                                    getTracksWithPolarCoordinates(obj)
            
            inputTrackCell =                                                    obj.TrackCell;
            deleteRows =                                                        cellfun(@(x) size(x,1)<=1,inputTrackCell ); % need at least two frames to calculate polar coordinates
            inputTrackCell(deleteRows,:) =                                      [];

            tracksWithPolarCoordinates =                                        cellfun(@(x) obj.getTrackWithPolarCoordinates(x),  inputTrackCell, 'UniformOutput', false);

               
        end
        
        
        
        function [listWithPolarCoordinates] =                              getTrackWithPolarCoordinates(obj, Track)


                XPositions =                                    cell2mat(Track(:,4));
                XVectors=                                       diff(XPositions);

                YPositions =                                    cell2mat(Track(:,3));
                YVectors=                                       diff(YPositions);

                AbsoluteDistances =                             sqrt(power(XVectors,2)+power(YVectors,2));
                Angles =                                        atan2(YVectors,XVectors);
               listWithPolarCoordinates =                      [AbsoluteDistances, Angles];

        end
        
        %% create randomized coordinateLists
        
         function [listWithDisplacementZScores, random] =                  caculateDisplacementZScoreForTracks(obj, polarCoordinateList)
            
                [listWithDisplacementZScores, random] =               cellfun(@(x) obj.caculateDisplacementZScoreForTrack(x),  polarCoordinateList);
           
         end


         
         
         function [DisplacementZScore, RandomizedZScore] =             caculateDisplacementZScoreForTrack(obj, polarCoordinates)
             
             actualDisplacement =                   obj.calculateDisplacementFromPolarCoordinateList(polarCoordinates);
             
             numberOfRandomizations =               obj.NumberOfRandomizations;
             numberOfSteps=                         size(polarCoordinates,1);
             
             randomizedCoordinateMatrix =           polarCoordinates;   
             randomizedDisplacements =              nan(numberOfSteps,1);
             
             for currentRandomization = 1:numberOfRandomizations
                  rng(currentRandomization) % reset seed
                  randomizedCoordinateMatrix(:,2)=                                    rand([numberOfSteps 1])*2*pi;
                  randomizedDisplacements(currentRandomization,1) =         calculateDisplacementFromPolarCoordinateList(obj, randomizedCoordinateMatrix);
                  
             end
             
             
             DisplacementZScore =       obj.calculateZScore(actualDisplacement, randomizedDisplacements);
             RandomizedZScore =         obj.calculateZScore(randomizedDisplacements(1), randomizedDisplacements);
    
             
         end
         
         function [TotalXYDisplacement]=                  calculateDisplacementFromPolarCoordinateList(obj, polarCoordinates)
             
                % based on angle convert magnitude back to X- and Y-components;
                XDisplacements=             polarCoordinates(:,1).*cos(polarCoordinates(:,2));
                YDisplacements=             polarCoordinates(:,1).*sin(polarCoordinates(:,2));
                
                TotalXDisplacement =        sum(XDisplacements);
                TotalYDisplacement =        sum(YDisplacements);
                
                TotalXYDisplacement =       sqrt(TotalXDisplacement^2 + TotalYDisplacement^2);
             
         end
         
         
         function [ ZScore ] = calculateZScore(obj, AnalyzedValue,  ComparisonPopulation)
            %COMPUTEDEVIATIONFROMPOPULATION Summary of this function goes here
            %   Detailed explanation goes here

            MeanOfPopulation=           mean(ComparisonPopulation);
            StdOfPopulation=            std(ComparisonPopulation);
            ZScore=             (AnalyzedValue-MeanOfPopulation)/StdOfPopulation;


        end
        
      
        
        %% currently unused: consider deletion:
        
             function [ CoordinateList ] =                                           AddDriftCorrectionToCoordinateList(CoordinateList, FieldNames, StructureWithDriftAnalysisData )
            %ADDDRIFTCORRECTIONTOCOORDINATELIST Summary of this function goes here
            %   currently not in use: consider deletion:
            
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



          
        
    end
end

