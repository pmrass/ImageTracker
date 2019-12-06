classdef PMTrackingNavigation
    %PMTRACKINGNAVIGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        NumberOfTracks =                0
        
        FieldNamesForTrackingCell =     {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'; 'SegmentationInfo'};
        TrackingCellForTime =           cell(0,1);
        
        MaximumDistanceForTracking =    100;
        
        FieldNamesForTrackingInfo =     {''};
        TrackingInfoCellForTime=        cell(0,1);
        
        OldCellMaskStructure
        
        ColumnsInTrackingCell
        Tracking
        TrackingWithDriftCorrection
        

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

            TrackColumn =                           strcmp(targetFieldNames, 'TrackID');
            ListWithAllMasks =                      vertcat(obj.TrackingCellForTime{:});
            
            if ~isempty(ListWithAllMasks)
                ListWithAllUniqueTrackIDs =             unique(cell2mat(ListWithAllMasks(:,TrackColumn)));  
            else
                ListWithAllUniqueTrackIDs =     [];

            end
            
        end
        
        
        function newTrackID =                   generateNewTrackID(obj)
            
            ListWithAllUniqueTrackIDs =     obj.getListWithAllUniqueTrackIDs;
            newTrackID =   max(ListWithAllUniqueTrackIDs) + 1;
            
            
        end
        
       
        function frames =                       getAllFrameNumbersOfTrackID(obj, trackID)
            
             pooledTrackingData =                        obj.poolAllTimeFramesOfTrackingCellForTime;
             RowsWithTrackID =                           obj.getRowsOfTrackID(pooledTrackingData, trackID);
             
             frames =                   cell2mat(pooledTrackingData(RowsWithTrackID,2));
             
             
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
            
            
            numberOfFrames =        size(obj.TrackingCellForTime,1);
            columnWithTime =        2;
            
            NewTrackingCellForTime =          cell(numberOfFrames,1);
            
             for CurrentTimePointIndex =  1:numberOfFrames
  
                  rowsForCurrentFrame =                                     cell2mat(list(:,columnWithTime)) == CurrentTimePointIndex;
                  dataOfCurrentFrame =                                             list(rowsForCurrentFrame,:);
                  NewTrackingCellForTime{CurrentTimePointIndex,1 } =        dataOfCurrentFrame;
                  
                  
                             
            end
    
            
            
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
            
            CurrentData = obj.TrackingCellForTime{CurrentFrame,1};
            
            AllTracks =     cell2mat(CurrentData(:,TrackColumn));
            
            
            RowToDelete =   AllTracks  ==    TrackID;
            
             
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
            
            obj =                           obj.calculateNumberOfTracks;
            
  
        end
        
        
        function obj =                          mergeTracks(obj, SelectedTrackIDs)
            

               listWithAllMasks =                       obj.poolAllTimeFramesOfTrackingCellForTime;
               TargetRowsPerTrack =                     arrayfun(@(x) find(obj.getRowsOfTrackID(listWithAllMasks,x)), SelectedTrackIDs, 'UniformOutput', false);
              
               %% only allow merging when there is no overlap between the tracks
               PooledTargetRows =                       vertcat(TargetRowsPerTrack{:});
               TargetFramesPerTrack =                   arrayfun(@(x) listWithAllMasks{x,obj.getAbsoluteFrameColumn}, PooledTargetRows);
                
               UniqueTargetFramesPerTrack =             unique(TargetFramesPerTrack);
               if length(UniqueTargetFramesPerTrack) ~= length(TargetFramesPerTrack)
                   return
                   
               end
               
               %% use lowest track ID to replace all other trackIDs that should be merged;
               [NewTrackID, row] =                                              min(SelectedTrackIDs);
             
               listWithAllMasks(PooledTargetRows,obj.getTrackIDColumn) =          {NewTrackID};
               separateList =                                                   obj.separatePooledDataIntoTimeSpecific(listWithAllMasks);
               obj.TrackingCellForTime =                   separateList;
                      
               obj =                           obj.calculateNumberOfTracks;
            
        end
        
        
        function obj =                          splitTrackAtFrame(obj, SplitFrame,SourceTrackID,SplitTrackID);
            
            
               
                listWithAllMasks =                                              obj.poolAllTimeFramesOfTrackingCellForTime;

                TargetRowsForActiveTrack =                                      obj.getRowsOfTrackID(listWithAllMasks,SourceTrackID);
                TargetRowsForUpperFrames =                                      cell2mat(listWithAllMasks(:,obj.getAbsoluteFrameColumn)) >=    SplitFrame;

                TargetRows =                                                    min([TargetRowsForActiveTrack TargetRowsForUpperFrames], [], 2);

                listWithAllMasks(TargetRows,obj.getTrackIDColumn) =               {SplitTrackID};

                separateList =                                                  obj.separatePooledDataIntoTimeSpecific(listWithAllMasks);
                obj.TrackingCellForTime =                                       separateList;
 
                obj =                           obj.calculateNumberOfTracks;
                
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
                    obj.TrackingCellForTime{CurrentFrame,1}(:,obj.segementationInfoColumn) =   {PMSegmentationCapture};
                    
                end
                
                
                
                
                
            end
            
        end

        
          function obj =                             resetColorOfAllTracks(obj, color)
             
              % this should probably be done in purely as a view: not
              % written directly into model:
             %% read:
             MyTrackModel =                              obj.Tracking;
             
             %process
             ColumnWithLineThickness =                   strcmp(obj.ColumnsInTrackingCell, 'LineColor');
             MyTrackModel(:,ColumnWithLineThickness) =        {color};
             
             %% apply
             obj.Tracking =            MyTrackModel;
                
             
         end
          
       
    end
end

