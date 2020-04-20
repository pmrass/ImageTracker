classdef PMDriftCorrection
    %PMDRIFTCORRECTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        

        % this is a list of points clicked by the user: it is possible to build a drift correction from this;
        
        ManualDriftCorrectionColumnTitles =         {'Frame#','X-cooordinate (pixel)', 'Y-cooordinate (pixel)' 'Z-cooordinate (pixel)'};
        ManualDriftCorrectionValues =               zeros(0,4);
        
        % this collectes detailed information about how the drift correction was generated;
        % it can be created fromt the manual drift correction or with and automated algorithm;
        % it is used to create the "final" drift correction (RowShiftsAbsolute etc.);
        ListWithBestAlignmentPositionsLabel =       {'Frame # (comparison)', 'Row of reference image', 'Row of comparison image', 'Column of reference image', ...
            'Column of comparison image', 'Plane of reference image', 'Plane of comparison image', 'RHO',  'Frame # (reference)'};
        ListWithBestAlignmentPositions = cell(0,9);

        
        % final drift correction
        RowShiftsAbsolute = zeros(0,1);
        ColumnShiftsAbsolute = zeros(0,1);
        PlaneShiftsAbsolute = zeros(0,1);
        

 
    end
    
    
    
    methods
        
        function obj = PMDriftCorrection(Data, Version)
            %PMDRIFTCORRECTION Construct an instance of this class
            %   Detailed explanation goes here
            
            switch Version
                
                case 2
                        obj =       obj.conversionFromVersionTwoToThree(Data);
                          
            end
            
        end
        
        
        function obj = conversionFromVersionTwoToThree(obj,Data)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            

             if ~isempty(fieldnames(Data.DriftCorrection)) && ~isempty (fieldnames(Data.ManualDriftCorrection))
                DriftCorrectionStatus = 'Manual and complete';
            elseif ~isempty(fieldnames(Data.DriftCorrection))
                DriftCorrectionStatus = 'Only complete';
            elseif isempty(Data.ManualDriftCorrection)
                DriftCorrectionStatus = 'No drift correction';
            elseif ~isempty(fieldnames(Data.ManualDriftCorrection))
                
                if max(max(Data.ManualDriftCorrection.Values(:,2:4)))
                    DriftCorrectionStatus = 'No drift correction';
                else
                    DriftCorrectionStatus = 'Only manual';
                end
             else
                 DriftCorrectionStatus = 'Unknown drift correction';
                 
             end
            
             switch DriftCorrectionStatus
                 
                 case {'Manual and complete', 'Only manual'}
                     
                     % to add: if there is a calibration field that is not zero: correct manual drift correction values;
                     obj.ManualDriftCorrectionValues =         Data.ManualDriftCorrection.Values;
                    
                     if Data.ManualDriftCorrection.Calibration.YCoordinates ~= 1 || Data.ManualDriftCorrection.Calibration.XCoordinates ~= 1
                         error('Unsupported drift correction')
                     end
                         
                     
                 case {'No drift correction'}
                     
                      % do nothing: it is ok if there is no default drift correction;
                      % "white" drift correction needs just to be added when the movie sequence is added (then we'll know how many frames the movie has);
                      
                 otherwise
                    error('Unsupported drift correction')
                 
                 
             end
   
        end
        
      
        function obj =  updateByManualDriftCorrection(obj, MetaData)
            
            fprintf('PMDriftCorrection:@updateByManualDriftCorrection.\n')
            
            manualDriftCorrectionExists =           obj.testForExistenceOfManualDriftCorrection;
            if ~manualDriftCorrectionExists
                [obj] =                             obj.autoPopulateDefaultManualValues(MetaData);

            end
                
            obj =           obj.createDetailedDriftAnalysisFromManualAnalysis; 
            obj =           obj.createFinalDriftAnalysisFromDetailedAnalysis;

             
        end
        
       
        
        function [obj] =                        autoPopulateDefaultManualValues(obj, MetaData)
            
            
            NumberOfFrames =                                                            MetaData.EntireMovie.NumberOfTimePoints;
            MiddleColumn =                                                              round(MetaData.EntireMovie.NumberOfColumns/2);
            MiddleRow =                                                                 round(MetaData.EntireMovie.NumberOfRows/2);
            MiddlePlane =                                                               round(MetaData.EntireMovie.NumberOfPlanes/2);
            
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,1)=                       1:NumberOfFrames;
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,2)=                       MiddleColumn;
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,3)=                       MiddleRow;
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,4)=                       MiddlePlane;
     
        end
        
        
        
        function [obj] =    smoothenOutManualDriftCorrection(obj)
            
            % currently not used:
            
            
            ManualDriftCorrection =  obj.ManualDriftCorrectionValues;
            NumberOfFrames =            size(ManualDriftCorrection,1);
            
               for FrameIndex = 2:NumberOfFrames-1
        
                    PreviousX =                                 ManualDriftCorrection(FrameIndex-1,2);
                    PreviousY =                                 ManualDriftCorrection(FrameIndex-1,3);
                    PreviousZ =                                 ManualDriftCorrection(FrameIndex-1,4);

                    CurrentX =                                  ManualDriftCorrection(FrameIndex,2);
                    CurrentY =                                  ManualDriftCorrection(FrameIndex,3);
                    CurrentZ =                                  ManualDriftCorrection(FrameIndex,4);
                    
                    
                    NextX =                                     ManualDriftCorrection(FrameIndex+1,2);
                    NextY =                                     ManualDriftCorrection(FrameIndex+1,3);
                    NextZ =                                     ManualDriftCorrection(FrameIndex+1,4);


                    
                    obj.ManualDriftCorrectionValues(FrameIndex,2)=        (PreviousX + NextX)/2;
                    obj.ManualDriftCorrectionValues(FrameIndex,3)=        (PreviousY + NextY)/2;
                    obj.ManualDriftCorrectionValues(FrameIndex,4)=        round((PreviousZ + NextZ)/2);


               end
                
               
               obj.ManualDriftCorrectionValues =ManualDriftCorrection;

            
            
        end
        
        
  
        
         function obj =                         update(obj, MetaData)
            
 
                %% a manual drift-correction is necessary so that the user can edit manual drift correction data if necessary;
                % if it does not exist, create one:
                manualDriftCorrectionExists =           obj.testForExistenceOfManualDriftCorrection;
                if ~manualDriftCorrectionExists
                    [obj] =                             obj.autoPopulateDefaultManualValues(MetaData);
                    
                end
                
                     
                %% in order to create a final drift-analysis, a detailed drift-analysis is necessary;
                % if it does not exist, create one from manual values:
                detailedDriftCorrectionExists =     obj.testForExistenceOfDetailedDriftCorrection;
                if ~detailedDriftCorrectionExists
                    obj =           obj.createDetailedDriftAnalysisFromManualAnalysis;

                end
                
                obj =           obj.createFinalDriftAnalysisFromDetailedAnalysis;

         end
        
         
         function [obj] =                       createDetailedDriftAnalysisFromManualAnalysis(obj)
             
             
               %% collect relevant data from manual-drift correction entry:
                ManualDriftCorrection=                                                      obj.ManualDriftCorrectionValues;


                %% process manual drift correction into "regular" drift correction;
                ReferenceX=                                                                 ManualDriftCorrection(1,2);
                ReferenceY=                                                                 ManualDriftCorrection(1,3);
                ReferenceZ=                                                                 ManualDriftCorrection(1,4);

                NumberOfFrames=                                                             size(ManualDriftCorrection,1);


                %% transfer manual drift correction to drift-correction matrix:
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,1)=                   1:NumberOfFrames;
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,2)=                   ReferenceY;
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,4)=                   ReferenceX;
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,6)=                   ReferenceZ;

                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,3)=                   ManualDriftCorrection(:,3);
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,5)=                   ManualDriftCorrection(:,2);
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,7)=                   ManualDriftCorrection(:,4);

                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,8)=                   NaN;
                ListWithBestAlignmentPositionsInside(1:NumberOfFrames,9)=                   1;


                %% transfer drift-correction matrix to correct entry in movie-list:

                obj.ListWithBestAlignmentPositions=              ListWithBestAlignmentPositionsInside;



         end
        

         
         function [ obj ] =                   createFinalDriftAnalysisFromDetailedAnalysis(obj )
            %CONVERTDRIFTCORRECTIONINTOFINALFORMAT Summary of this function goes here
            %   Detailed explanation goes here

            %% read object data:
            IntraMovie_ListWithBestAlignmentPositions =                 obj.ListWithBestAlignmentPositions;

            %% process:
            RowsOfReference=                                            IntraMovie_ListWithBestAlignmentPositions(:,2);
            RowsOfComparison=                                           IntraMovie_ListWithBestAlignmentPositions(:,3);
            ColumnsOfReference=                                         IntraMovie_ListWithBestAlignmentPositions(:,4);
            ColumnsOfComparison=                                        IntraMovie_ListWithBestAlignmentPositions(:,5);
            PlanesOfReference=                                          IntraMovie_ListWithBestAlignmentPositions(:,6);
            PlanesOfComparison=                                         IntraMovie_ListWithBestAlignmentPositions(:,7);


            % positive values indicate upward or left shift
            RowShift=                                                   RowsOfReference- RowsOfComparison;
            ColumnShift=                                                ColumnsOfReference- ColumnsOfComparison;
            PlaneShift=                                                 PlanesOfReference- PlanesOfComparison;

            [ RowShiftsAbsoluteInternal ]=                              obj.TranslateMinimumValueToZero(RowShift);
            [ ColumnShiftsAbsoluteInternal ]=                           obj.TranslateMinimumValueToZero(ColumnShift);
            [ PlaneShiftsAbsoluteInternal ]=                            obj.TranslateMinimumValueToZero(PlaneShift);

            %% put results back to object;
            obj.RowShiftsAbsolute=                                      round(RowShiftsAbsoluteInternal);
            obj.ColumnShiftsAbsolute=                                   round(ColumnShiftsAbsoluteInternal);
            obj.PlaneShiftsAbsolute=                                    round(PlaneShiftsAbsoluteInternal);
            


         end

         
         function [obj ] =                      eraseDriftCorrection(obj, MetaData)
             
             [obj] =                        obj.autoPopulateDefaultManualValues(MetaData);
              obj =                         obj.createDetailedDriftAnalysisFromManualAnalysis;
              obj =                         obj.createFinalDriftAnalysisFromDetailedAnalysis;
              
         end
         
         function [obj] =               updateManualDriftCorrectionByValues(obj,xEnd, yEnd,  planeWithoutDrift, frame)
             
             
             obj.ManualDriftCorrectionValues(frame,2) = xEnd;
             obj.ManualDriftCorrectionValues(frame,3) = yEnd;
             obj.ManualDriftCorrectionValues(frame,4) = planeWithoutDrift;
             
         end

         
         %% helper functions:
         
         function [structure] = calculateEmptyShifts(~, MetaData)
             
             NumberOfFrames =                                                            MetaData.EntireMovie.NumberOfTimePoints;
             
            structure.RowShiftsAbsolute(1:NumberOfFrames,1)=                                      0;
            structure.ColumnShiftsAbsolute(1:NumberOfFrames,1)=                                      0;
            structure.PlaneShiftsAbsolute(1:NumberOfFrames,1)=                                      0;
           
             
         end
         
        %% test state of class:
        function manualOrDetailedExists = testForExistenceOfDriftCorrection(obj)
            
            
            manualExists =  obj.testForExistenceOfManualDriftCorrection;
            detailedExists =  obj.testForExistenceOfDetailedDriftCorrection;
            
            manualOrDetailedExists = manualExists || detailedExists;
            
        end
        
        
        function trueManualDriftCorrectionExists = testForExistenceOfManualDriftCorrection(obj)
            
            ManualDrift = obj.ManualDriftCorrectionValues;
            if isempty(ManualDrift)
                trueManualDriftCorrectionExists = false;
            else
                
                ColumnsAreDifferent =   length(unique(ManualDrift(:,2)));
                RowsAreDifferent =      length(unique(ManualDrift(:,3)));
                PlanesAreDifferent =    length(unique(ManualDrift(:,4)));    
                
                
                trueManualDriftCorrectionExists = ColumnsAreDifferent > 1 || RowsAreDifferent > 1 || PlanesAreDifferent > 1;
            end
            
            
        end
        
        
        function detailedDriftCorrectionExists = testForExistenceOfDetailedDriftCorrection(obj)
            
            DriftCorr = obj.ListWithBestAlignmentPositions;
            
            if isempty(DriftCorr)
                
                detailedDriftCorrectionExists = false;
            else
           
                RowsAreDifferent = sum(diff([DriftCorr(:,2), DriftCorr(:,3)], [], 2));
                ColumnsAreDifferent = sum(diff([DriftCorr(:,4), DriftCorr(:,5)], [], 2));
                PlanesAreDifferent = sum(diff([DriftCorr(:,6), DriftCorr(:,7)], [], 2));

                detailedDriftCorrectionExists = ColumnsAreDifferent > 1 || RowsAreDifferent > 1 || PlanesAreDifferent > 1;

            end
            
        end
        
        
        function [ TranslatedMatrix ] = TranslateMinimumValueToZero(~, InputMatrix )
            
            %TRANSLATEMINIMUMVALUETOZERO: linear translation so that lowest value
            % in defined column equals zero:
          
          
            CorrectionValue=                min(InputMatrix);
            TranslatedMatrix=               InputMatrix-CorrectionValue;



        end

       
        
    end
end

