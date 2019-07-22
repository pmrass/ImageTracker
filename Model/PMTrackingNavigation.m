classdef PMTrackingNavigation
    %PMTRACKINGNAVIGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        NumberOfTracks =                0
        
        FieldNamesForTrackingCell =     {'TrackID'; 'AbsoluteFrame'; 'CentroidY'; 'CentroidX'; 'CentroidZ'; 'ListWithPixels_3D'};
        TrackingCellForTime =           cell(0,1);
        
        OldCellMaskStructure
        
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
               
               NumberOfColumnsPerMaskCell =     6;
               
               
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
                                    CurrentTargetCell(:,CurrentColumn) =    CurrentSourceCell(:,SourceColumn);

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
            
               targetFieldNames =           obj.FieldNamesForTrackingCell;
            
             TrackColumn =            strcmp(targetFieldNames, 'TrackID');
            Result =                        vertcat(obj.TrackingCellForTime{:});
                      
            
            if isempty(Result)
                
                obj.NumberOfTracks =    0;
                

            else
                
                ListWithUniqueTracks =          unique(cell2mat(Result(:,TrackColumn)));
                obj.NumberOfTracks =        length(ListWithUniqueTracks);
                
            end
             
            
                    
            
        end
        
       
        function obj = removeMask(obj,TrackID,CurrentFrame)
            
            TrackColumn = 1;
            
            CurrentData = obj.TrackingCellForTime{CurrentFrame,1};
            
            AllTracks =     cell2mat(CurrentData(:,TrackColumn));
            
            
            RowToDelete =   AllTracks  ==    TrackID;
            
             
            obj.TrackingCellForTime{CurrentFrame,1}(RowToDelete,:) = [];
            
        end
        
        
        
        
        function obj = removeTrack(obj, trackID)
            
            TrackColumn =                           1;

            pooledData =                            vertcat(obj.TrackingCellForTime{:});
            
           


            ListWithTrackIDs =                      cell2mat(pooledData(:,TrackColumn));
            
            
            pooledData(ListWithTrackIDs == trackID,:) = [];
            
            
            separateList =      obj.separatePooledDataIntoTimeSpecific(pooledData);
            
            obj.TrackingCellForTime = separateList;
            
            
            
            
            
        end
        
        function separateList = separatePooledDataIntoTimeSpecific(obj, list)
            
            
            numberOfFrames =    size(obj.TrackingCellForTime,1);
            columnWithTime =        2;
            
            
            separateList =      cell(numberOfFrames,1);
            
            
             for CurrentTimePointIndex =  1:numberOfFrames
  
                  
                  rightRows =     cell2mat(list(:,columnWithTime)) == CurrentTimePointIndex;
                  
                  currentData =     list(rightRows,:);
                  
                  
                  separateList{CurrentTimePointIndex,1 } = currentData;
                  
                  
                             
            end
                    
                    
            
            
            
            
            
        end
        
        
        
        
        
       
    end
end

