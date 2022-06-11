classdef PMDriftCorrection
    %PMDRIFTCORRECTION For managing drift of captured movie-sequences;
    %   Detailed explanation goes here
    
    properties
         
    end
    
    properties (Access = private)
        
        Navigation
        
        
        ManualDriftCorrectionValues =               zeros(0,4);
        
        
        
        % this is a list of points clicked by the user: it is possible to build a drift correction from this;
        ManualDriftCorrectionColumnTitles =         {'Frame#','X-cooordinate (pixel)', 'Y-cooordinate (pixel)' 'Z-cooordinate (pixel)'};
       
        
        % this collectes detailed information about how the drift correction was generated;
        % it can be created fromt the manual drift correction or with and automated algorithm;
        % these values are used to actually correct for drift artifacts;
        ListWithBestAlignmentPositionsLabel =       {'Frame # (comparison)', 'Row of reference image', 'Row of comparison image', 'Column of reference image', ...
            'Column of comparison image', 'Plane of reference image', 'Plane of comparison image', 'RHO',  'Frame # (reference)'};
        
        ListWithBestAlignmentPositions = cell(0,9);
        
        DriftCorrectionIsOn = false
        
    end
    
    
    
    methods % initialize:
       
       function obj =      PMDriftCorrection(varargin)
            %PMDRIFTCORRECTION Construct an instance of this class
            %   Takes 0, 1, or 2 arguments: 
            % 1: PMNavigationSeries object
            % 2: 1: "old version" drift-correction; 2: number of input version (currently only "2" supported);
            
            NumberOfArgments = length(varargin);
            switch NumberOfArgments
                
                case 0
                    
                case 1
                    obj.Navigation =    varargin{1};
                    obj =               obj.setBlankDriftCorrection;
                   
                case 2
                     switch varargin{2}
                        case 2
                                obj =       obj.conversionFromVersionTwoToThree(varargin{1});  
                                
                         otherwise
                             error('Wrong input')
                    end
                otherwise
                    error('Invalid number of arguments')
            end
            
           
            
         end
         
       function obj =       set.Navigation(obj, Value)
            assert(isa(Value, 'PMNavigationSeries'), 'Wrong argument type')
            obj.Navigation = Value;
       end
        
    end

    methods % SETTERS

        function obj =      update(obj) % it would be good to always use this internally when necessary so that it doesn't have to be called from the outside:;
            obj =    obj.updateManualDriftCorrection;
            if ~ obj.testForExistenceOfDetailedDriftCorrection
                obj =           obj.createDetailedDriftAnalysisFromManualAnalysis;
            end
        end

        function obj =      setDriftCorrectionActive(obj, Value)
            assert((islogical(Value) || isnumeric(Value)) && isscalar(Value), 'Wrong input type')
            obj.DriftCorrectionIsOn = Value;

        end

        function obj =      setNavigation(obj, Value)
            obj.Navigation = Value;
        end

        function obj =      convertToMetricBySpaceCalibration(obj, SpaceCalibration)
            % CONVERTTOMETRICBYSPACECALIBRATION uses Calibration input to convert current pixel values into µm;

            obj.ListWithBestAlignmentPositions(:, 4:5) =    SpaceCalibration.convertXPixelsIntoUm(obj.ListWithBestAlignmentPositions(:, 4:5));
            obj.ListWithBestAlignmentPositions(:, 2:3) =    SpaceCalibration.convertYPixelsIntoUm(obj.ListWithBestAlignmentPositions(:, 2:3));
            obj.ListWithBestAlignmentPositions(:, 6:7) =    SpaceCalibration.convertZPixelsIntoUm(obj.ListWithBestAlignmentPositions(:, 6:7));

            obj.ManualDriftCorrectionValues(:, 2) =        SpaceCalibration.convertXPixelsIntoUm(obj.ManualDriftCorrectionValues(:, 2));
            obj.ManualDriftCorrectionValues(:, 3) =        SpaceCalibration.convertYPixelsIntoUm(obj.ManualDriftCorrectionValues(:, 3));
            obj.ManualDriftCorrectionValues(:, 4) =        SpaceCalibration.convertZPixelsIntoUm(obj.ManualDriftCorrectionValues(:, 4));

        end

        function obj =    updateManualDriftCorrectionByValues(obj,xEnd, yEnd,  planeWithoutDrift, frame)

             ListWithFrames = frame(:);

             for frame = ListWithFrames'
                obj.ManualDriftCorrectionValues(frame,2) = xEnd;
                obj.ManualDriftCorrectionValues(frame,3) = yEnd;
                obj.ManualDriftCorrectionValues(frame,4) = planeWithoutDrift;
             end

        end

        function obj =      setByManualDriftCorrection(obj)
            obj =        obj.updateManualDriftCorrection;
            obj =        obj.createDetailedDriftAnalysisFromManualAnalysis; 
        end

        function obj =      eraseDriftCorrection(obj)
            error('Use setBlankDriftCorrection')
            obj =      obj.autoPopulateDefaultManualValues;
            obj =      obj.createDetailedDriftAnalysisFromManualAnalysis;
        end

        function obj =      setBlankDriftCorrection(obj)
            obj =      obj.autoPopulateDefaultManualValues;
            obj =      obj.createDetailedDriftAnalysisFromManualAnalysis;
        end

    end

    
    
    methods % GETTERS:
       
         function rowShifts =           getRowShifts(obj)
            RowsOfReference=                    obj.ListWithBestAlignmentPositions(:,2);
            RowsOfComparison=                   obj.ListWithBestAlignmentPositions(:,3);
            RowShift=                           RowsOfReference- RowsOfComparison;
            [ RowShiftsAbsoluteInternal ]=      obj.TranslateMinimumValueToZero(RowShift);
            rowShifts =                         round(RowShiftsAbsoluteInternal);
             
         end
         
         function columnShifts =        getColumnShifts(obj)
            ColumnsOfReference=                     obj.ListWithBestAlignmentPositions(:,4);
            ColumnsOfComparison=                    obj.ListWithBestAlignmentPositions(:,5);
            ColumnShift=                            ColumnsOfReference- ColumnsOfComparison;
            [ ColumnShiftsAbsoluteInternal ]=       obj.TranslateMinimumValueToZero(ColumnShift);
            columnShifts =                          round(ColumnShiftsAbsoluteInternal);
             
         end
         
         function planeShifts =         getPlaneShifts(obj)
            PlanesOfReference=                  obj.ListWithBestAlignmentPositions(:,6);
            PlanesOfComparison=                 obj.ListWithBestAlignmentPositions(:,7);
            PlaneShift=                         PlanesOfReference- PlanesOfComparison;
            [ PlaneShiftsAbsoluteInternal ]=    obj.TranslateMinimumValueToZero(PlaneShift);
            planeShifts =                       round(PlaneShiftsAbsoluteInternal);
         end
         
         function numberOfFrames =      getNumberOfFrames(obj)
             numberOfFrames = size(obj.ListWithBestAlignmentPositions, 1);
         end
         
         function shiftCorrdinates =    shiftCoordinatesInFrameRelativeToFrame(obj, SourceCoordinates, Frame, ReferenceFrame)
            
                shiftCorrdinates(1, 1)=         SourceCoordinates(1, 1) + getColumnShiftBetweenFrames(obj, Frame, ReferenceFrame);
                shiftCorrdinates(1, 2)=         SourceCoordinates(1, 2) + getRowShiftBetweenFrames(obj, Frame, ReferenceFrame);
                shiftCorrdinates(1, 3)=         SourceCoordinates(1, 3) + getPlaneShiftBetweenFrames(obj, Frame, ReferenceFrame);
         end
        
    end
    
    methods % GETTERS
        
        function shifts =       getAppliedColumnShifts(obj)
                % GETAPPLIEDCOLUMNSHIFTS returns column-drift corrections;
                % considers whether drift-correction is "on"
                % if "off" returns zero-vector
             switch obj.getDriftCorrectionActive
                case true
                    shifts =       obj.getColumnShifts;
                case false
                    shifts =           obj.getEmptyColumnShifts;
              end
            end
        
        function Value =        getDriftCorrectionActive(obj)
         Value = obj.DriftCorrectionIsOn;
         if isempty(Value)
            Value = false; 
         end
      end
        
        function shifts =       getAppliedRowShifts(obj)
            % GETAPPLIEDROWSHIFTS returns row-drift corrections;
                % considers whether drift-correction is "on"
                % if "off" returns zero-vector
             switch obj.getDriftCorrectionActive
                case true
                     shifts =       obj.getRowShifts;
                case false
                    shifts =    obj.getEmptyRowShifts;
              end
        end
        
        function shifts =       getAplliedPlaneShifts(obj)
            % GETAPLLIEDPLANESHIFTS returns plane-drift corrections;
                % considers whether drift-correction is "on"
                % if "off" returns zero-vector
            switch obj.getDriftCorrectionActive
                case true
                    shifts =     obj.getPlaneShifts;
                case false
                    shifts =    obj.getEmptyPlaneShifts;
            end
        end
        
        function Values =       getManualDriftCorrectionValues(obj)
             obj =          obj.updateManualDriftCorrection;
             Values =       obj.ManualDriftCorrectionValues;
         end
         
        function manualOrDetailedExists = testForExistenceOfDriftCorrection(obj) 
            manualExists =          obj.testForExistenceOfManualDriftCorrection;
            detailedExists =        obj.testForExistenceOfDetailedDriftCorrection;
            manualOrDetailedExists = manualExists || detailedExists;

        end
            
    end
    

    methods (Access = private) 
        
        %%
        
        function myShift = getRowShiftBetweenFrames(obj, Frame, ReferenceFrame)
             shifts = getRowShifts(obj);
             myShift = shifts(Frame) - shifts(ReferenceFrame);
        end
        
        function myShift = getColumnShiftBetweenFrames(obj, Frame, ReferenceFrame)
            shifts = getColumnShifts(obj);
             myShift = shifts(Frame) - shifts(ReferenceFrame);
        end
        
        function myShift = getPlaneShiftBetweenFrames(obj, Frame, ReferenceFrame)
             shifts = getPlaneShifts(obj);
              myShift = shifts(Frame) - shifts(ReferenceFrame);
        end
        
        
        %% update manual drift correction
        function obj = updateManualDriftCorrection(obj)
             if isempty(obj.ManualDriftCorrectionValues)
                    obj =            obj.autoPopulateDefaultManualValues;
             end
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
        
        function [obj] =                        autoPopulateDefaultManualValues(obj)
            
            NumberOfFrames =            obj.Navigation.getMaxFrame;
            MiddleColumn =              round(obj.Navigation.getMaxColumn/2);
            MiddleRow =                 round(obj.Navigation.getMaxRow/2);
            MiddlePlane =               round(obj.Navigation.getMaxPlane/2);
            
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,1)=   1:NumberOfFrames;
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,2)=   MiddleColumn;
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,3)=   MiddleRow;
             obj.ManualDriftCorrectionValues(1:NumberOfFrames,4)=   MiddlePlane;
     
        end
       
        
        %% conversion
        function obj = conversionFromVersionTwoToThree(obj, Data)
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
        
        
  
  
        
         
         
         %% create drift correction from manual choices:
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
        
        
   
    
     

         
         %% helper functions:
         

         
         function shifts = getEmptyRowShifts(obj)
             shifts(1 : obj.Navigation.getMaxFrame, 1)=           0;
         end
         
         function shifts = getEmptyColumnShifts(obj)
             shifts(1 : obj.Navigation.getMaxFrame, 1)=        0;
         end
         
         function shifts = getEmptyPlaneShifts(obj)
             shifts(1 : obj.Navigation.getMaxFrame, 1)=         0;  
         end
         
        %% test state of class:
     
      
        
        
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

