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
        
        
        function [obj]= convertOldCellMaskStructureIntoTrackingCellForTime(obj)
            
            
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
        
        
        
        
        function obj =  calculateNumberOfTracks(obj)
            
         
            ListWithAllUniqueTrackIDs =         obj.getListWithAllUniqueTrackIDs;
            
            if isempty(ListWithAllUniqueTrackIDs)
                
                obj.NumberOfTracks =    0;
                

            else
                
               
                obj.NumberOfTracks =                    length(ListWithAllUniqueTrackIDs);
                
            end
             
            
                    
            
        end
        
        
        function ListWithAllUniqueTrackIDs = getListWithAllUniqueTrackIDs(obj)
            
            
            targetFieldNames =                          obj.FieldNamesForTrackingCell;

            TrackColumn =                           strcmp(targetFieldNames, 'TrackID');
            ListWithAllMasks =                      vertcat(obj.TrackingCellForTime{:});
            ListWithAllUniqueTrackIDs =             unique(cell2mat(ListWithAllMasks(:,TrackColumn)));          

            
            
        end
        
        
        function newTrackID =   generateNewTrackID(obj)
            
            ListWithAllUniqueTrackIDs =     obj.getListWithAllUniqueTrackIDs;
            newTrackID =   max(ListWithAllUniqueTrackIDs) + 1;
            
            
        end
        
       
        function obj = removeMask(obj,TrackID,CurrentFrame)
            
            TrackColumn = 1;
            
            CurrentData = obj.TrackingCellForTime{CurrentFrame,1};
            
            AllTracks =     cell2mat(CurrentData(:,TrackColumn));
            
            
            RowToDelete =   AllTracks  ==    TrackID;
            
             
            obj.TrackingCellForTime{CurrentFrame,1}(RowToDelete,:) = [];
            
        end
        
        
        function obj = removeTrack(obj, trackID)
            
            

            % concatenate time-specific data:
            pooledTrackingData =                    obj.poolAllTimeFramesOfTrackingCellForTime;
 
            % remove track
            
            RowsWithTrackID =                       obj.getRowsOfTrackID(pooledTrackingData, trackID);
            
            
            pooledTrackingData(RowsWithTrackID,:) = [];
          
            
            % convert pooled list back into time-specific list
            separateList =                          obj.separatePooledDataIntoTimeSpecific(pooledTrackingData);
            obj.TrackingCellForTime =               separateList;
            
  
        end
        
        function rows = getRowsOfTrackID(obj,pooledTrackingData,trackID)
            
            TrackColumn =                           1;
            ListWithTrackIDs =                      cell2mat(pooledTrackingData(:,TrackColumn));
            rows =                                  ListWithTrackIDs == trackID;
            
            
        end
        
        
      
        
        function pooledData =          poolAllTimeFramesOfTrackingCellForTime(obj)
            
            pooledData =                            vertcat(obj.TrackingCellForTime{:});
                   
            
        end
        
        
        function NewTrackingCellForTime = separatePooledDataIntoTimeSpecific(obj, list)
            
            
            numberOfFrames =        size(obj.TrackingCellForTime,1);
            columnWithTime =        2;
            
            NewTrackingCellForTime =          cell(numberOfFrames,1);
            
             for CurrentTimePointIndex =  1:numberOfFrames
  
                  rowsForCurrentFrame =                                     cell2mat(list(:,columnWithTime)) == CurrentTimePointIndex;
                  dataOfCurrentFrame =                                             list(rowsForCurrentFrame,:);
                  NewTrackingCellForTime{CurrentTimePointIndex,1 } =        dataOfCurrentFrame;
                  
                  
                             
            end
    
            
            
        end
        
        
        
        
        
       
    end
end

