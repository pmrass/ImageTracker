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
        ListWithCompleteMaskInformation =               cell(0,7)
        ListWithCompleteMaskInformationWithDrift =      cell(0,7) % drift information is in duplicate, this makes it easier to switch between drift-corrected and non-drift corrected data with acceptable overhead
        MaskFilter =                                    true(0,1) % the mask filter filters for masks and determines on what mask;

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

                        TrackingAnalysisBasis =         varargin{1};
                        DriftCorrection =               varargin{2};

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

                        
                    case 4
                        
                         TrackingAnalysisBasis =         varargin{1};
                        DriftCorrection =               varargin{2};
                        obj.MetaData =                  varargin{3};
                        
                         obj.DriftCorrection =           DriftCorrection;
                         obj =                           obj.createListWithCompleteMaskInformation(TrackingAnalysisBasis);
                        
                    otherwise
                        error('Only 0 or to input arguments supported')


                end

        end


        function [ obj ] =                                                  createListWithCompleteMaskInformation(obj, TrackingAnalysisBasis)
        %CONVERTTRACKINGSTRUCTURETOCELL Summary of this function goes here
        %   Detailed explanation goes here

            if isempty(TrackingAnalysisBasis) ||   TrackingAnalysisBasis.NumberOfTracks == 0  
               return 
            end


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
            AddedMaskFilter =                                           ismember(cell2mat(obj.ListWithCompleteMaskInformation(:,ColumnWithFrameNumber)), AcceptedFrames);
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

        
            CoordinateList =                                                obj.ListWithCompleteMaskInformationWithDrift;
            CoordinateListColumnTitles =                                    obj.FieldNamesOfMaskInformation;

            switch OldDistanceUnits

                case 'pixels'


                    ColumnWithCentroidZ =                                           strcmp(CoordinateListColumnTitles, 'CentroidZ');
                    ColumnWithCentroidY =                                            strcmp(CoordinateListColumnTitles, 'CentroidY');
                    ColumnWithCentroidX =                                           strcmp(CoordinateListColumnTitles, 'CentroidX');

                  
                   
                    
                    Xoordinates_pixel =                                             cell2mat(CoordinateList(:,ColumnWithCentroidX));
                    Yoordinates_pixel =                                             cell2mat(CoordinateList(:,ColumnWithCentroidY));
                    Zoordinates_pixel =                                             cell2mat(CoordinateList(:,ColumnWithCentroidZ));
                    
                    
                     [pixelList_um] =                                               obj.convertPixelsIntoUm([Yoordinates_pixel Xoordinates_pixel Zoordinates_pixel]);
                  
                    CoordinateList_um=                                              CoordinateList;

                    CoordinateList_um(:,ColumnWithCentroidX)=                       num2cell(pixelList_um(:,2));   % µm 
                    CoordinateList_um(:,ColumnWithCentroidY)=                        num2cell(pixelList_um(:,1));  % µm
                    CoordinateList_um(:,ColumnWithCentroidZ)=                       num2cell(pixelList_um(:,3));

                    obj.ListWithCompleteMaskInformationWithDrift =                  CoordinateList_um;



                case 'um'




            end






        end
        
        function [pixelList_um] =                                           convertPixelsIntoUm(obj, pixelList)
            
            
            MetaDataInternal =                                              obj.MetaData;



            Meta_DistanceBetweenPixels_Z=                                   MetaDataInternal.EntireMovie.VoxelSizeZ*10^6;
            Meta_DistanceBetweenPixels_Y=                                   MetaDataInternal.EntireMovie.VoxelSizeY*10^6;
            Meta_DistanceBetweenPixels_X=                                   MetaDataInternal.EntireMovie.VoxelSizeX*10^6;


            pixelList_um(:,1) =                                               pixelList(:,1)*Meta_DistanceBetweenPixels_X;
            pixelList_um(:,2) =                                               pixelList(:,2)*Meta_DistanceBetweenPixels_Y;       
            pixelList_um(:,3) =                                               pixelList(:,3)*Meta_DistanceBetweenPixels_Z;

            
            
        end
        
        
            function [RatioBetweenXAndZSpace] = calculateRatioBetweenZAndXPixelSize(obj)
                
                     MetaDataInternal =                                              obj.MetaData;

                
               Meta_DistanceBetweenPixels_Z=                                   MetaDataInternal.EntireMovie.VoxelSizeZ*10^6;
          
            Meta_DistanceBetweenPixels_X=                                   MetaDataInternal.EntireMovie.VoxelSizeX*10^6;
               
            
            RatioBetweenXAndZSpace = Meta_DistanceBetweenPixels_Z/Meta_DistanceBetweenPixels_X;
               
           end
        
        function [pixelList] =                                              convertUmIntoPixels(obj, pixelList_um)
            
             MetaDataInternal =                                              obj.MetaData;


            Meta_DistanceBetweenPixels_Z=                                   MetaDataInternal.EntireMovie.VoxelSizeZ*10^6;
            Meta_DistanceBetweenPixels_Y=                                   MetaDataInternal.EntireMovie.VoxelSizeY*10^6;
            Meta_DistanceBetweenPixels_X=                                   MetaDataInternal.EntireMovie.VoxelSizeX*10^6;


            pixelList(:,1) =                                               pixelList_um(:,1)/Meta_DistanceBetweenPixels_X;
            pixelList(:,2) =                                               pixelList_um(:,2)/Meta_DistanceBetweenPixels_Y;       
            pixelList(:,3) =                                               pixelList_um(:,3)/Meta_DistanceBetweenPixels_Z;

            
            
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


           
     
        %% extract track information from TrackCell:
        function [speeds] =                                                 getAverageTrackSpeeds(obj)
            
            
            inputTrackCell =                            obj.TrackCell;
            deleteRows =                                cellfun(@(x) size(x,1)<=1,inputTrackCell ); % need at least two frames to calculate meaningful displacement
            inputTrackCell(deleteRows,:) =              [];
            
             speeds =                                   cellfun(@(x) obj.getAverageTrackSpeed(x),  inputTrackCell);
           
        end
        
        function [displacements] =                                          getTotalTrackDisplacements(obj)
            
            
            inputTrackCell =                            obj.TrackCell;
                deleteRows =                                cellfun(@(x) size(x,1)<=1,inputTrackCell ); % want the same like for speed;
            inputTrackCell(deleteRows,:) =              [];
            displacements =             cellfun(@(x) obj.getDisplacementOfTrack(x),  inputTrackCell);
            
            
        end
        
        function speeds =                                                   getAverageTrackSpeed(obj, Track)
            
          if size(cell2mat(Track(:,3)),1) <= 1
              speeds = zeros(0,1);
              
          else
              
           
            
            speeds =                        obj.getAverageSpeedFromCoordinateList(Track);
              
              
          end
            
            
        end
        
      
        
        %% track analysis: stop duration
        
          function [stopDurations]=               getStopDurationsOfAllTracks(obj,StopDistanceLimit)
              
                inputTrackCell =                            obj.TrackCell;
                deleteRows =                                cellfun(@(x) size(x,1)<=1,inputTrackCell ); % need at least two frames to calculate meaningful displacement
                inputTrackCell(deleteRows,:) =              [];

                stopDurations =                                   cellfun(@(x) obj.getStopDurationOfTrack(x,StopDistanceLimit),  inputTrackCell, 'UniformOutput', false);

            
          end
        
        function stopDurations =                                             getStopDurationOfTrack(obj, Track, StopDistanceLimit)
            
   
            TrackMatrix =                       cell2mat(Track(:,1:5));
            
            TrackMatrix(:,2) =      TrackMatrix(:,2)/60;
            
           
            
            NumberOfFrames =                    size(Track,1);
             stopDurations = nan(NumberOfFrames,1);
            CurrentFrame =                      1;
            NumberOfStops =     0;
            while CurrentFrame < NumberOfFrames
                
                StartFrame =    CurrentFrame;
                
                while 1
                    
                    CurrentFrame =                  CurrentFrame + 1;
                    
                    XDistances =                    TrackMatrix(CurrentFrame,3)-TrackMatrix(StartFrame,3);
                    YDistances =                    TrackMatrix(CurrentFrame,4)-TrackMatrix(StartFrame,4);
                    ZDistances =                    TrackMatrix(CurrentFrame,5)-TrackMatrix(StartFrame,5);

                    Distance3DUm =                  sqrt(XDistances^2 + YDistances^2 + ZDistances^2);

                    if Distance3DUm>StopDistanceLimit || CurrentFrame == NumberOfFrames
                        
                        % the stop durations is measured when
                        % a) the current distance exceeds the "stop-distance";
                        % b) the track has arrived the end (in this case the value will be an underestimate, but important to keep because otherwise all persistenly non-motile cells would be excluded);
                        
                        TimeInterval =  TrackMatrix(CurrentFrame,2)-TrackMatrix(StartFrame,2);
                        NumberOfStops =     NumberOfStops + 1;
                        
                        stopDurations(NumberOfStops,1) =    TimeInterval;
                        
                        break
                        
                    
                    end
                    
                end
                
                
                
            end

            if NumberOfStops == 0 
                stopDurations = zeros(0,1);
            elseif NumberOfStops<NumberOfFrames
                stopDurations(NumberOfStops+1:end,:) =     [];
                
            end

            
              
            
        end
        
        
        
        
        
        %% track analysis: MSD analysis;
        function [msdList, deltaTimeList]=              getTimeVsMSDLists(obj,XVsYSettings, MovieName)
            
                tic
                inputTrackCell =                                    obj.TrackCell;
                deleteRows =                                        cellfun(@(x) size(x,1)<=1,inputTrackCell ); % need at least two frames to calculate meaningful displacement
                inputTrackCell(deleteRows,:) =                      [];
            
                fprintf('PMTrackingAnalysis for movie "%s".\ncalculateTimeVsMSDLists for track#', MovieName)
                [msdList, deltaTimeList] =                                   cellfun(@(track, counter) obj.getTimeVsMSDList(track, XVsYSettings,counter),  inputTrackCell, (num2cell(1:size(inputTrackCell,1)))', 'UniformOutput', false);
            
                finalTime = toc;
                fprintf('\nAnalysis finished. Duration: %6.2f seconds.\n', finalTime)
             
             
             
        end
        
        function [ DeltaTimeVersusXYZDisplSquared_Binned, ListWithAllTimeIntervals ] = getTimeVsMSDList(obj, CoordinateList, XVsYSettings, Count )
                    %GENERATETIMEVSPARAMETERLIST get delta-time versus input parameters;

                    % input:
                    % TimeList: list with absolute time values
                    % ParameterList: list with x,y or z coordinates:

                    % output:
                    % column 1-2: start and end frames of analyzed interval
                    % column 3: difference of start and end frame of interval
                    % column 4: delta time0
                    % column 5: X-coorindate at beginning of interval
                    % column 6: X-coorindate at end of interval
                    % column 7: Y-coorindate at beginning of interval
                    % column 8: Y-coorindate at end of interval
                    % column 9: Z-coorindate at beginning of interval
                    % column 10: Z-coorindate at end of interval

                    if (mod(Count,10)) == 0
                       fprintf(' %i', Count) 
                        
                    end

                    TimeList =                                  cell2mat(CoordinateList(:,2));
                    YCoordinateList =                           cell2mat(CoordinateList(:,3));
                    XCoordinateList =                           cell2mat(CoordinateList(:,4));
                    ZCoordinateList =                           cell2mat(CoordinateList(:,5));
                    
                    assert(min(size(TimeList)== size(TimeList)), 'Size of input lists does not match')

                    NumberOfIntervals=                          size(TimeList,1);

                    NumberOfOutputMeasurements=                 NumberOfIntervals*(NumberOfIntervals+1)/2;


                    %% initialize "BeforeAfterList";
                    CoordinateListAtIntervals(:,1)=               TimeList;
                    CoordinateListAtIntervals(:,2)=               TimeList;
                    CoordinateListAtIntervals(:,3)=               YCoordinateList;
                    CoordinateListAtIntervals(:,4)=               YCoordinateList;
                    CoordinateListAtIntervals(:,5)=               XCoordinateList;
                    CoordinateListAtIntervals(:,6)=               XCoordinateList;
                    CoordinateListAtIntervals(:,7)=               ZCoordinateList;
                    CoordinateListAtIntervals(:,8)=               ZCoordinateList;

                    FrameNumberList=                                1:length(TimeList);
                    CoordinateListAtIntervals(:,9)=                 FrameNumberList;
                    CoordinateListAtIntervals(:,10)=               FrameNumberList;

                    StartRow_Export=                                1;



                    TimeDifferenceList=                 CoordinateListAtIntervals(:,2)-CoordinateListAtIntervals(:,1);
                    NumberOfTimeIntervals=               size(TimeDifferenceList,1);

                    %% zero time-differential data:

                    ListWithAllTimeIntervals=                                                                       zeros(NumberOfOutputMeasurements,3);
                    ListWithAllTimeIntervals(StartRow_Export:StartRow_Export+NumberOfTimeIntervals-1,1:2)=          CoordinateListAtIntervals(:,9:10);
                    ListWithAllTimeIntervals(StartRow_Export:StartRow_Export+NumberOfTimeIntervals-1,4)=            TimeDifferenceList;
                    ListWithAllTimeIntervals(StartRow_Export:StartRow_Export+NumberOfTimeIntervals-1,5:6)=          CoordinateListAtIntervals(:,3:4);

                    for CurrentMeasurement=1:NumberOfIntervals

                        %% reset start row:
                        StartRow_Export=                                                                                StartRow_Export+NumberOfTimeIntervals;

                        %% shift "late" columns one row up and then erase last row: this way all possible combinations of measurements are achieved;
                        CoordinateListAtIntervals(1:end-1,2)=                                                                     CoordinateListAtIntervals(2:end,2);
                        CoordinateListAtIntervals(1:end-1,4)=                                                                     CoordinateListAtIntervals(2:end,4);
                        CoordinateListAtIntervals(1:end-1,6)=                                                                     CoordinateListAtIntervals(2:end,6);
                        CoordinateListAtIntervals(1:end-1,8)=                                                                     CoordinateListAtIntervals(2:end,8);
                        CoordinateListAtIntervals(1:end-1,10)=                                                                     CoordinateListAtIntervals(2:end,10);
                        
                        CoordinateListAtIntervals(end,:)=                                                                         [];
                        TimeDifferenceList=                                                                             CoordinateListAtIntervals(:,2)-CoordinateListAtIntervals(:,1);


                        %% add shifted data to export matrix:
                        NumberOfTimeIntervals=                                                                          size(TimeDifferenceList,1);

                        ListWithAllTimeIntervals(StartRow_Export:StartRow_Export+NumberOfTimeIntervals-1,1:2)=          CoordinateListAtIntervals(:,9:10);
                        ListWithAllTimeIntervals(StartRow_Export:StartRow_Export+NumberOfTimeIntervals-1,4)=            TimeDifferenceList; 
                        ListWithAllTimeIntervals(StartRow_Export:StartRow_Export+NumberOfTimeIntervals-1,5:10)=          CoordinateListAtIntervals(:,3:8);


                    end

                    ListWithAllTimeIntervals(:,3)=                      ListWithAllTimeIntervals(:,2)-ListWithAllTimeIntervals(:,1);

                    [ ListWithAllTimeIntervals ] =                      obj.removeOverLappingTimeIntervals(ListWithAllTimeIntervals );
                    
                    
                    DeltaTimeVersusCoordinateDifference_X=              ListWithAllTimeIntervals(:,6)-ListWithAllTimeIntervals(:,5);
                    DeltaTimeVersusCoordinateDifference_Y=              ListWithAllTimeIntervals(:,8)-ListWithAllTimeIntervals(:,7);
                    DeltaTimeVersusCoordinateDifference_Z=              ListWithAllTimeIntervals(:,10)-ListWithAllTimeIntervals(:,9);

                    DeltaTimeVersusXYZDisplSquared(:,1)=                power(DeltaTimeVersusCoordinateDifference_X,2)+power(DeltaTimeVersusCoordinateDifference_Y,2)+power(DeltaTimeVersusCoordinateDifference_Z,2);

                    ListWithAllTimeIntervals(:,11) =                    DeltaTimeVersusXYZDisplSquared;

                    TimeIntervals_Seconds =                             ListWithAllTimeIntervals(:,4);
                    DisplacementXYZSquared=                             DeltaTimeVersusXYZDisplSquared;
                    
                    

                
                    [DeltaTimeVersusXYZDisplSquared_Binned] =           obj.generateXVersusYList(TimeIntervals_Seconds/60, DisplacementXYZSquared,XVsYSettings );

         
        end
                
        
        function [ ListWithAllTimeIntervals ] =     removeOverLappingTimeIntervals(obj, ListWithAllTimeIntervals )
            
                %TIMEDIFFERENTIAL_REMOVEOVERLAPPINGELEMENTS: remove all rows that contain measurements from overlapping frames:
                %   Detailed explanation goes here


                ColumnWithFrameNumberDifference=                3;

                TotalNumberOfRows=                              size(ListWithAllTimeIntervals,1);
                ListWithRowsThatShouldBeKept=                   zeros(TotalNumberOfRows,1);

                ListWithAllFrameDifferenceValues=               unique(ListWithAllTimeIntervals(:,ColumnWithFrameNumberDifference));

                TotalNumberOfFrameDifferences=                  length(ListWithAllFrameDifferenceValues);
                for CurrentFrameDifferenceIndex=1:TotalNumberOfFrameDifferences

                    % get current time-interval:
                    CurrentFrameDifferenceValue=                ListWithAllFrameDifferenceValues(CurrentFrameDifferenceIndex);

                    % generate false matrix for all rows corresponding to current time interval;
                    StartRow=                                   find(ListWithAllTimeIntervals(:,ColumnWithFrameNumberDifference)==CurrentFrameDifferenceValue, 1, 'first');
                    LastRow=                                    find(ListWithAllTimeIntervals(:,ColumnWithFrameNumberDifference)==CurrentFrameDifferenceValue, 1, 'last');
                    NumberOfRowsWithCurrentFrameDifference=     LastRow-StartRow+1;
                    RowsToKeep=                                 false(NumberOfRowsWithCurrentFrameDifference,1);

                    % count rows that need to be erased:
                    if CurrentFrameDifferenceValue== 0
                        ToKeep= 1:NumberOfRowsWithCurrentFrameDifference;
                    else
                        ToKeep= 1:CurrentFrameDifferenceValue:NumberOfRowsWithCurrentFrameDifference; % depending on the interval every row, every other row, every third row, etc. is kept;
                    end
                    RowsToKeep(ToKeep)= 1;

                    % add results for current time-frame interval to general matrix;
                    ListWithRowsThatShouldBeKept(StartRow:LastRow,1)= RowsToKeep;

                end

                % remove all rows that contain overlapping frame-rates:
                ListWithAllTimeIntervals(~ListWithRowsThatShouldBeKept,:)=[];

        end


        function [ ListWithXYAnalysis ] =           generateXVersusYList(obj, IndependentParameters, DependentParameters, XVsYSettings )
                    %GENERATEXVERSUSY get binned x (IndependentParameters) vs. parameter
                    %(DependentParameters)
                    %   Detailed explanation goes here

                    DefineXRange =                                              XVsYSettings.BinRange;
                    MyType =                                                    XVsYSettings.Type;
                
                    %% check for size of input variables
                    assert(size(IndependentParameters,2)== 1, 'Number of columns of independent parameter must be 1')
                    assert(max(strcmp(MyType, {'Mean', 'Median', 'Spearman', 'MeanCosine', 'Individual'})), 'Parameter not supported for XY anlaysis')

                    switch MyType

                        case {'Mean', 'Median', 'Individual'}

                            assert(size(DependentParameters,2)== 1, 'Number of columns of dependent parameter must be 1')

                        case 'Spearman'

                            assert(size(DependentParameters,2)== 2, 'Number of columns of dependent parameter must be 2')

                        case 'MeanCosine'

                            assert(size(DependentParameters,2)== 4, 'Number of columns of dependent parameter must be 4')

                    end

                    %% get bin settings:

                    StartValue=                 DefineXRange.XLimMin;
                    EndValue=                   DefineXRange.XLimMax;
                    StepSize=                   DefineXRange.BinSize;

                    StartMidBin=                StartValue;
                    StartLowBin=                StartValue-StepSize/2;
                    StartHighBin=               StartValue+StepSize/2;

                    StartValues_LowBin=         StartLowBin:StepSize:EndValue-StepSize/2;
                    StartValues_CenterBin=      StartMidBin:StepSize:EndValue;
                    StartValues_HighBin=        StartHighBin:StepSize:EndValue+StepSize/2;


                    %% for each bin: compute desired parameter (mean, correlation, cosine)
                    NumberOfBins=               length(StartValues_LowBin);

                    switch MyType

                         case 'Individual'

                             ListWithXYAnalysis=                            cell(NumberOfBins,1);

                        otherwise

                            ListWithXYAnalysis=                             zeros(NumberOfBins,1);

                    end



                    for BinIndex=1:NumberOfBins

                        % get all dependent parameters for current bin (and remove them from the ist):
                        RowsThatExceedLow=                                          IndependentParameters >= StartValues_LowBin(BinIndex);
                        RowsThatAreLowerThanHigh=                                   IndependentParameters < StartValues_HighBin(BinIndex);
                        RowsWithinBin=                                              min([RowsThatExceedLow,RowsThatAreLowerThanHigh], [], 2);
                        DependentParametersInCorrectBin=                            DependentParameters(RowsWithinBin,:);
                        IndependentParameters(RowsWithinBin,:)=                     [];
                        DependentParameters(RowsWithinBin,:)=                       [];

                        NumberOfEventsInBin=                                        sum(RowsWithinBin);

                         if isempty(DependentParametersInCorrectBin)

                            DependentValueInCurrentBin=                             NaN;
                            ErrorInCurrentBin=                                      NaN;

                         else

                            switch MyType

                                case 'Mean' 

                                    DependentValueInCurrentBin=                     nanmean(DependentParametersInCorrectBin);
                                    ErrorInCurrentBin=                              nanstd(DependentParametersInCorrectBin)/sqrt(NumberOfEventsInBin);

                                case 'Median'

                                    DependentValueInCurrentBin=                     nanmedian(DependentParametersInCorrectBin);
                                    ErrorInCurrentBin=                              0;

                                case 'Spearman'

                                    CorrelationCoefficient=                         corr(DependentParametersInCorrectBin,'type','Spearman');
                                    DependentValueInCurrentBin=                     CorrelationCoefficient(1,2);
                                    ErrorInCurrentBin=                              NaN;

                                case 'MeanCosine'

                                    ListWithXVectors_BeforeAfter=                   DependentParametersInCorrectBin(:,1:2);
                                    ListWithYVectors_BeforeAfter=                   DependentParametersInCorrectBin(:,3:4);

                                    ListWithDotProductsBetweenVectors=              dot([ListWithXVectors_BeforeAfter(:,1), ListWithYVectors_BeforeAfter(:,1)], [ListWithXVectors_BeforeAfter(:,2), ListWithYVectors_BeforeAfter(:,2)],2);
                                    ListWithMagnitudesOfEarlyVectors=               sqrt(power(ListWithXVectors_BeforeAfter(:,1),2)+power(ListWithYVectors_BeforeAfter(:,1),2));
                                    ListWithMagnitudesOfLateVectors=                sqrt(power(ListWithXVectors_BeforeAfter(:,2),2)+power(ListWithYVectors_BeforeAfter(:,2),2));

                                    ListWithCosinesBetweenVectors=                  ListWithDotProductsBetweenVectors./(ListWithMagnitudesOfEarlyVectors.*ListWithMagnitudesOfLateVectors);

                                    DependentValueInCurrentBin=                     nanmean(ListWithCosinesBetweenVectors);
                                    ErrorInCurrentBin=                              nanstd(ListWithCosinesBetweenVectors)/sqrt(NumberOfEventsInBin);

                            end

                         end

                         switch MyType

                             case 'Individual'

                                 ListWithXYAnalysis{BinIndex,1}=                      StartValues_CenterBin(BinIndex);
                                 ListWithXYAnalysis{BinIndex,2}=                      DependentParametersInCorrectBin;

                             otherwise

                                ListWithXYAnalysis(BinIndex,1)=                       StartValues_CenterBin(BinIndex);
                                ListWithXYAnalysis(BinIndex,2)=                       DependentValueInCurrentBin;
                                ListWithXYAnalysis(BinIndex,3)=                       ErrorInCurrentBin;
                                ListWithXYAnalysis(BinIndex,4)=                       NumberOfEventsInBin;

                         end

                    end

        end

        function [MSDList_AverageOfAllTracks, MSDList_AllIndividualValues] =                getAverageMsd(obj,CellWithTrackMsds)
            
            
                % rearrange: each track gets its own column; each row is for a time interval;
                ColumnForDeltaTime=                                     1;
                CellWithDeltaTimeOnly=                                  cellfun(@(x) x(:,ColumnForDeltaTime), CellWithTrackMsds, 'UniformOutput', false);
                DeltaTimeMatrix=                                        horzcat(CellWithDeltaTimeOnly{:});
                DeltaTimeMatrix=                                        DeltaTimeMatrix';

                ColumnForDisplacementXYZ=                               2;          
                CellWithXYZDisplacementOnlY=                            cellfun(@(x) x(:,ColumnForDisplacementXYZ), CellWithTrackMsds, 'UniformOutput', false);
                DisplacementXYZMatrix=                                  horzcat(CellWithXYZDisplacementOnlY{:});
                DisplacementXYZMatrix=                                  DisplacementXYZMatrix';


                %% list with average of bins for all tracks:
                DeltaTime_FirstTrack=                                   (DeltaTimeMatrix(1,:))';
                MSD_MeanOfAllTracks =                                   (nanmean(DisplacementXYZMatrix,1))';
                MSD_semOfAllTracks=                                     (nanstd(DisplacementXYZMatrix)/sqrt(length(MSD_MeanOfAllTracks)))';

                MSDList_AverageOfAllTracks=                             [DeltaTime_FirstTrack  MSD_MeanOfAllTracks MSD_semOfAllTracks];


                %% each row contains time-bin value and corresponding average displacement for single track:
                DeltaTimeListOneColumn=                                 reshape(DeltaTimeMatrix,[],1);
                DisplacementXYZListOneColumn=                           reshape(DisplacementXYZMatrix,[],1);

                MSDList_AllIndividualValues=                          [DeltaTimeListOneColumn DisplacementXYZListOneColumn];



            
            
        end

        function [ LinearRegressionLine, LinearRegressionErrorArea, MotilityCoefficientStructure] = msdLinearRegression(obj, SingleValueMatrix_Group1, TimeRange)

                tic
                %LINEARREGRESSIONANALYSISFORTIMEVSMSD Summary of this function goes here
                %   Detailed explanation goes here

                %% 1: clean up input data, ;
                ColumnWithTimeIntervals =                                   1;
                ColumnWithXYZDisplacement =                                 2;

                ZeroTimeRows=                                               SingleValueMatrix_Group1(:,ColumnWithTimeIntervals)==0;
                SingleValueMatrix_Group1(ZeroTimeRows,:)=                   [];
                NaNDisplacementRows=                                        isnan(SingleValueMatrix_Group1(:,ColumnWithXYZDisplacement));
                SingleValueMatrix_Group1(NaNDisplacementRows,:)=            [];

                NumberOfIndividualValues =                                  size(SingleValueMatrix_Group1(:,ColumnWithTimeIntervals));  

                MinimumTime=                                                TimeRange(1);
                MaximumTime=                                                TimeRange(2);

                %% 2: compute linear regression:

                [LinearRegressionLineData,LinearRegressionErrorData] =      regress(SingleValueMatrix_Group1(:,ColumnWithXYZDisplacement) , [ones(NumberOfIndividualValues), SingleValueMatrix_Group1(:,ColumnWithTimeIntervals)]);
                RegressLine_MinimumXYZ=                                     LinearRegressionLineData(1);
                RegressLine_SlopeXYZ_IThink =                               LinearRegressionLineData(2);

                RegressionAreaLow_MinimumXYZ =                              LinearRegressionErrorData(1,1);
                RegressionAreaLow_SlowXYZ =                                 LinearRegressionErrorData(2,1);

                RegressionAreaHigh_MinimumXYZ =                             LinearRegressionErrorData(1,2);
                RegressionAreaHigh_SlowXYZ =                                LinearRegressionErrorData(2,2);

                %% 3: get coordinates for linear regression line:
                RegressLine_MaximumXYZ=                                     RegressLine_MinimumXYZ+RegressLine_SlopeXYZ_IThink*MaximumTime;

                RegressLine_TimeLimits=                                     [MinimumTime MaximumTime];
                RegressLine_XYZLimits=                                      [RegressLine_MinimumXYZ RegressLine_MaximumXYZ];

                LinearRegressionLine(1,:)=                                  RegressLine_XYZLimits;
                LinearRegressionLine(2,:)=                                  RegressLine_TimeLimits;

                %% get coordinates for error-area of linear regression:

                RegressionAreaLow_MaximumXYZ=                               RegressionAreaLow_MinimumXYZ + RegressionAreaLow_SlowXYZ * MaximumTime;
                RegressionAreaHigh_MaximumXYZ=                              RegressionAreaHigh_MinimumXYZ + RegressionAreaHigh_SlowXYZ * MaximumTime;

                Time_ErrorArea=                                             [MinimumTime MaximumTime MaximumTime MinimumTime];
                XYZ_ErrorArea=                                              [RegressionAreaLow_MinimumXYZ RegressionAreaLow_MaximumXYZ RegressionAreaHigh_MaximumXYZ RegressionAreaHigh_MinimumXYZ];   

                LinearRegressionErrorArea(1,:)=                             XYZ_ErrorArea;
                LinearRegressionErrorArea(2,:)=                             Time_ErrorArea;

                %% 
                Dimension=                                                  3;
                MotilityCoefficient3D=                                      RegressLine_SlopeXYZ_IThink/(2*Dimension);

                fprintf('Motility coefficient=')
                fprintf('%6.2f µm^2 min^-^1', MotilityCoefficient3D)

                MotilityCoefficientStructure.DiffusionCoefficient3D=        MotilityCoefficient3D;
                MotilityCoefficientStructure.LinearRegressionPoints=        [  MinimumTime RegressLine_MinimumXYZ; MaximumTime RegressLine_MaximumXYZ];

        end

        

        %% speed analysis
        function speeds =                                                   getAverageSpeedFromCoordinateList(obj,Track)
            
             TotalTimeSeconds =              max(cell2mat(Track(:,2))) - min(cell2mat(Track(:,2))) ;
            
             XDistances =                    sum(abs(diff(cell2mat(Track(:,3)))));
            YDistances =                    sum(abs(diff(cell2mat(Track(:,4)))));
            ZDistances =                    sum(abs(diff(cell2mat(Track(:,5)))));

            Distance3DUm =                  sqrt(XDistances^2 + YDistances^2 + ZDistances^2);
           
            speeds =                         Distance3DUm/TotalTimeSeconds*60;

            
            
            
        end
        
        function speeds =                                                   getInstantSpeedsFromCoordinateList(obj,Track)
            
         
            
            displacementList =              obj.getDisplacementsFromTrack(Track);
            timeIntervals =                 diff(cell2mat(Track(:,2))); % make sure it is set to seconds
            speeds =                         displacementList./timeIntervals;

            
            
        end
        
        function displacementList =                                         getDisplacementsFromTrack(obj, Track)
            
            XDistances =                    diff(cell2mat(Track(:,3)));
            YDistances =                    diff(cell2mat(Track(:,4)));
            ZDistances =                    diff(cell2mat(Track(:,5)));

            displacementList =                  sqrt(XDistances.^2 + YDistances.^2 + ZDistances.^2);
     
        end
        
        function distanceOfTrack =                                          getDistanceOfTrack(obj, Track)
            
            displacementList =              obj.getDisplacementsFromTrack(Track);
            
            distanceOfTrack =               sum(displacementList);
            
            
        end
        
        
        function displacement =                                             getDisplacementOfTrack(obj,Track)
            
            
              if size(cell2mat(Track(:,3)),1) <=1
                    displacement = zeros(0,1);
              else
                  
                     startEndTrack =         Track([1 end],:);
            
                     displacement =              obj.getDisplacementsFromTrack(startEndTrack);
                  
              end
           
            
            
        end
        
   
        
        function jumpStatistics =                                           getJumpStatisticsOfTracks(obj,SpeedLimit)
            
             NumberOfTracks =               size(obj.TrackCell,1);
            jumpStatistics =                cell(NumberOfTracks,1);
            
            for CurrentTrack = 1:NumberOfTracks
                
                DataOfCurrentTrack =                        obj.TrackCell{CurrentTrack,1};
                jumpStatistics{CurrentTrack,1} =          obj.getJumpStatisticsOfTrack(DataOfCurrentTrack,SpeedLimit);
                
            end
            
            
            
        end
        
        
        function jumpStatistics =                                           getJumpStatisticsOfTrack(obj, CurrentSourceTrack, SpeedLimit)
            
              
              speeds =                        obj.getInstantSpeedsFromCoordinateList(CurrentSourceTrack);
              
              noStop =                      speeds>SpeedLimit;
              
              
              NumberOfSpeeds = length(speeds);
              
              jumpStatistics =      zeros(NumberOfSpeeds,1);
              PositionIndex = 1;
              JumpIndex = 0;
              
              while PositionIndex <= NumberOfSpeeds
                  
                  currentMovementList =                 noStop(PositionIndex:end);
                  JumpStartFrameWithinSegment =                      find(currentMovementList==1, 1, 'first');
                  endOfRun =                            find(currentMovementList(JumpStartFrameWithinSegment:end)==0, 1, 'first') - 1;
              
                  if isempty(endOfRun)
                      JumpEndFrameWithinSegment =  length(currentMovementList);
                      
                  else
                      JumpEndFrameWithinSegment = JumpStartFrameWithinSegment + endOfRun - 1;
                      
                  end
                  
                  
                  
                  
                  %% 
                  JumpStartFrameWithinSourceTrack =         PositionIndex - 1 + JumpStartFrameWithinSegment;
                  JumpEndFrameWithinSourceTrack =           PositionIndex - 1 + JumpEndFrameWithinSegment + 1;
                  
                  if JumpEndFrameWithinSourceTrack>= size(CurrentSourceTrack,1)
                      
                  end
                  
                  MovementTrack =                           CurrentSourceTrack(JumpStartFrameWithinSourceTrack:JumpEndFrameWithinSourceTrack,:);
                  
                  if isempty(JumpStartFrameWithinSourceTrack)
                      break
                      
                  end
                  
                      JumpIndex =                               JumpIndex + 1;
                      jumpStatistics(JumpIndex,1) =             JumpIndex;
                      jumpStatistics(JumpIndex,2) =             JumpStartFrameWithinSourceTrack;
                      jumpStatistics(JumpIndex,3) =             JumpEndFrameWithinSourceTrack;
                      jumpStatistics(JumpIndex,4) =             JumpEndFrameWithinSourceTrack-JumpStartFrameWithinSourceTrack;
                      jumpStatistics(JumpIndex,5) =             obj.getDisplacementOfTrack(MovementTrack);
                      jumpStatistics(JumpIndex,6) =             obj.getDistanceOfTrack(MovementTrack);
                  
                  
                  PositionIndex =                           JumpEndFrameWithinSourceTrack + 1;
                  
              end
            
            
            
         


            jumpStatistics(jumpStatistics(:,1) == 0,: ) = [];

           
 
          end
        
        
        function stopAnalysis =                                             createStopAnalysisForTracks(obj, StopDistanceLimit)

            NumberOfTracks =            size(obj.TrackCell,1);
            stopAnalysis =              cell(NumberOfTracks,1);
            
            for CurrentTrack = 1:NumberOfTracks
                
                DataOfCurrentTrack =                    obj.TrackCell{CurrentTrack,1};
                stopAnalysis{CurrentTrack,1} =          obj.createStopAnalysisForTrack(DataOfCurrentTrack, StopDistanceLimit);
                
            end

            
        end
        
        
        function ListWithStopDurations =                                    createStopAnalysisForTrack(obj, CurrentTrack, DistanceLimit)
            
            ColumnWithYCoordinates =                3;
            ColumnWithXCoordinates =                4;
            ColumnWithZCoordinates =                5;
            
            XCoordinates =                          cell2mat(CurrentTrack(:,ColumnWithXCoordinates));
            YCoordinates =                          cell2mat(CurrentTrack(:,ColumnWithYCoordinates));
            ZCoordinates =                          cell2mat(CurrentTrack(:,ColumnWithZCoordinates));
            
            
            NumberOfPositions =                                 size(YCoordinates, 1);
    
            ListWithStopDurations =                             zeros(NumberOfPositions,1);
            PositionIndex = 1;
            RowIndex =          0;
            while PositionIndex <= NumberOfPositions

                CurrentPositionX =                              XCoordinates(PositionIndex,1);
                CurrentPositionY =                              YCoordinates(PositionIndex,1);
                CurrentPositionZ =                              ZCoordinates(PositionIndex,1);

                XDistancesFromCurrentStartPosition =            CurrentPositionX- XCoordinates;
                YDistancesFromCurrentStartPosition =            CurrentPositionY- YCoordinates;
                ZDistancesFromCurrentStartPosition =            CurrentPositionZ- ZCoordinates;

                DistancesFromCurrentStartPosition =             sqrt(XDistancesFromCurrentStartPosition.^2 + YDistancesFromCurrentStartPosition.^2 + ZDistancesFromCurrentStartPosition.^2);
                
                RowsThatAreWithinStopDistance =                 DistancesFromCurrentStartPosition <= DistanceLimit;
                RowsWithinStopPositionForFutureRows=            RowsThatAreWithinStopDistance(PositionIndex:end);

                FirstRowThatIsBeyondStopLimit =                 find(RowsWithinStopPositionForFutureRows==0, 1,'first') + PositionIndex -1 ;

                if isempty(FirstRowThatIsBeyondStopLimit)
                    StopDuration =                                  NumberOfPositions-PositionIndex+1;
                    PositionIndexNew =                              NumberOfPositions + 1;

                else
                    StopDuration =                                  FirstRowThatIsBeyondStopLimit-PositionIndex;
                    PositionIndexNew =                              FirstRowThatIsBeyondStopLimit;

                end


                RowIndex =                                  RowIndex + 1;
                ListWithStopDurations(RowIndex, 1) =        RowIndex;
                ListWithStopDurations(RowIndex, 2) =        PositionIndex;
                ListWithStopDurations(RowIndex, 3) =        StopDuration;

                PositionIndex =                             PositionIndexNew;



            end


            ListWithStopDurations(ListWithStopDurations(:,1) == 0,: ) = [];

 
        end
        
        
        
        
        %% create displacement coordinate list:
        
        function [tracksWithPolarCoordinates] =                             getTracksWithPolarCoordinates(obj)
            
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


         
         
         function [DisplacementZScore, RandomizedZScore] =                  caculateDisplacementZScoreForTrack(obj, polarCoordinates)
             
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
         
         function [TotalXYDisplacement]=                                    calculateDisplacementFromPolarCoordinateList(obj, polarCoordinates)
             
                % based on angle convert magnitude back to X- and Y-components;
                XDisplacements=             polarCoordinates(:,1).*cos(polarCoordinates(:,2));
                YDisplacements=             polarCoordinates(:,1).*sin(polarCoordinates(:,2));
                
                TotalXDisplacement =        sum(XDisplacements);
                TotalYDisplacement =        sum(YDisplacements);
                
                TotalXYDisplacement =       sqrt(TotalXDisplacement^2 + TotalYDisplacement^2);
             
         end
         
         
         function [ ZScore ] =                                              calculateZScore(obj, AnalyzedValue,  ComparisonPopulation)
            %COMPUTEDEVIATIONFROMPOPULATION Summary of this function goes here
            %   Detailed explanation goes here

            MeanOfPopulation=           mean(ComparisonPopulation);
            StdOfPopulation=            std(ComparisonPopulation);
            ZScore=             (AnalyzedValue-MeanOfPopulation)/StdOfPopulation;


         end
        
      
        %% filemanagement for data export:
        
        
        
        function exportTracksIntoCSVFile(obj,exportFileName,NickName)
            
            
            
            %% target filename and write data from data source:
            datei =                         fopen(exportFileName, 'w');
            ExportData =                    obj.ListWithCompleteMaskInformationWithDrift(obj.MaskFilter,:);
            
            NickName(NickName=='(') = '_';
            NickName(NickName==')') = '_';
            NickName(NickName=='µ') = 'u';
            NickName(NickName==' ') = '';
            
            fprintf(datei, '%s\n', 'Filename or nickname');
            fprintf(datei, '%s\n', NickName);

            TotalNumberOfRows=          size(ExportData,1);     
            for CurrentRow=1:TotalNumberOfRows
                
                dataInRow =    ExportData(CurrentRow,:); 
                fprintf(datei, '%12.0f,%10.5f,%10.5f,%10.5f,%14.5f \n', dataInRow{1}, dataInRow{3}, dataInRow{4}, dataInRow{5}, dataInRow{2} );
            
            end
           
            fclose(datei);
            
            
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

