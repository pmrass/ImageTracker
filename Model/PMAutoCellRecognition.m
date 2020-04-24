classdef PMAutoCellRecognition
    %PMAUTOCELLRECOGNITION Enables autodetection of roundish objects in image-sequence;
    %   Detailed explanation goes here
    
    properties
        
        ShowViewsForControl =                       0;
        
        ActiveChannel =                           false;

        % also currently misssing: information of how the image was created (e.g. was opening used?);
        
        % approach : use circle recognition to detect cells;
        % currently this is done by user defined edge-thresholds radius and sensitivty;
        % a future approach could be:;
        % 1: loop through different contrasts (e.g. 0.2 to 0.02);
        % 2: recognize cells and erase high-density cells (e.g. a cell has more than 5 neighhbors with x µm);
        % 3: then pool the different analysis; this should combine high sensitity and specificity;
        
        % after turning off median filtering, approach worked much better; therefore this is not high priority right now;
        % set these values for each plane;
        % cells get to get smaller/dimmer in deeper planes therefore size of filter/ radisu and sensitivy should be increase; 
       
        NumberOfChannels =                          NaN;
        
        NumberOfPlanes =                            NaN;
        
        NumberOfFrames =                            NaN;
        
        AnalyzedFrames =                            NaN;

        RadiusMinimumRange =                        [5,9];
        RadiusMaximumRange =                        [5,10];
        
        SensitivityMinimum=                         0.92;
        SensitivityMaximum=                         0.95;
        
        EdgeThresholdMinimum =                      0.09;
        EdgeThresholdMaximum =                      0.09;
        
        RadiusRange =                               [];

        Sensitivity =                               []% higher values make it more sensitive (more circles are detected (use between 0.85 and 0.95;

        EdgeThreshold =                             []; % higher values require higher contrast;
                                            
        HighDensityDistanceLimit =                  50; % if a cell has too many neighbors, it will be deleted;
        HighDensityNumberLimit =                    9; % this is possibly noise, or if they are cells they would be difficult to track anyway;
        
        ImageSequence
        DistanceLimitForPlaneMerging =              10;
        
        DetectedCoordinates =                       cell(0,1);

    end
    
    methods
        
        
        function obj = PMAutoCellRecognition(myImageSequence,Channel)
            %PMAUTOCELLRECOGNITION Construct an instance of this class
            %   Detailed explanation goes here
            
                assert(size(myImageSequence,1)>=1, 'ImageSequence must contain at least one frame');

                obj.ImageSequence =                 myImageSequence;
                obj.ActiveChannel =                 Channel;
                obj.NumberOfFrames =                size(myImageSequence,1);
                myAnalyzedFrames =                  find(cellfun(@(x) ~isempty(x), myImageSequence));
                obj.NumberOfPlanes =                size(myImageSequence{myAnalyzedFrames(1)},3);
                obj.AnalyzedFrames =                myAnalyzedFrames;

                obj.RadiusRange(:,1) =              round(linspace( obj.RadiusMinimumRange(1), obj.RadiusMaximumRange(1), obj.NumberOfPlanes));
                obj.RadiusRange(:,2) =              round(linspace( obj.RadiusMinimumRange(2), obj.RadiusMaximumRange(2), obj.NumberOfPlanes));
                obj.Sensitivity(:,1) =              linspace( obj.SensitivityMinimum, obj.SensitivityMaximum, obj.NumberOfPlanes);
                obj.EdgeThreshold(:,1) =            linspace( obj.EdgeThresholdMinimum, obj.EdgeThresholdMaximum, obj.NumberOfPlanes);


        end
        
        function obj = performAutoDetection(obj)
            
             fprintf('\nPMAutoCellRecognition: @performAutoDetection.\n')
             
             
            
             %% get relevant settings:
             myImageSequence =                      obj.ImageSequence;
          
             FramesOfWantedImages =                 obj.AnalyzedFrames;
             
            inRadiusRange =                         obj.RadiusRange;
            inSensitivity =                         obj.Sensitivity;
            inEdgeThreshold =                       obj.EdgeThreshold;    
            
             inShowViewsForControl =                obj.ShowViewsForControl;
            
             MyChannel =                            obj.ActiveChannel;
             
             inNumberOfFrames =                     obj.NumberOfFrames;
             inNumberOfPlanes =                     obj.NumberOfPlanes;
            
             if length(MyChannel) ~= 1
                 
                fprintf('Failure because of the following reason:\n')
                fprintf('Currently not exactly one channel is selected.\nThe following channels are currently selected:')
                arrayfun(@(x) fprintf(' %i', x), MyChannel)
                fprintf('.\n')
                error('For this reason @performAutoDetection triggered an error.')
                 
             end
             
             
         
             if size(inRadiusRange,1)~= 1 && size(inRadiusRange,1)~= inNumberOfPlanes
                 fprintf('This movie has %i planes. This does not match the number of entered radius values, which is %i.\n', inNumberOfPlanes, size(inRadiusRange,1))
                 error('For this reason @performAutoDetection triggered an error.')
             end
            
             if size(inEdgeThreshold,1)~= 1 && size(inEdgeThreshold,1)~= inNumberOfPlanes
                 fprintf('This movie has %i planes. This does not match the number of entered edge-threshold values, which is %i.\n', inNumberOfPlanes, size(inEdgeThreshold,1))
                 error('For this reason @performAutoDetection triggered an error.')
             end
             
              if size(inSensitivity,1)~= 1 && size(inSensitivity,1)~= inNumberOfPlanes
                 fprintf('This movie has %i planes. This does not match the number of entered sensitivity values, which is %i.\n', inNumberOfPlanes, size(inSensitivity,1))
                 error('For this reason @performAutoDetection triggered an error.')
             end
            
           
            
            
            fprintf('Analyzing frames')
            arrayfun(@(x)  fprintf(' %i', x), FramesOfWantedImages)
            fprintf('.\n')
            
            
            fprintf('Analyzing %i planes.',inNumberOfPlanes)
            
            fprintf('\nSensitivity settings [0,1]: 0.85 = good starting value; 0 = low ; 1 = high sensitivity; high detects more objects\n')
            arrayfun(@(x) fprintf('%1.3f ', x), inSensitivity)
            fprintf('\n')
            fprintf('EdgeThreshold [0,1]: 0.85 = good starting value; 0 = low ; 1 = high edge requirement; low detects more objects\n')
            arrayfun(@(x) fprintf('%1.3f ', x), inEdgeThreshold)
            fprintf('\n')
            fprintf('Radius range:')
            arrayfun(@(x,y) fprintf(' %i %i;', x, y), inRadiusRange(:,1),inRadiusRange(:,2))
            fprintf('\n')
            fprintf('Objects that have more than %i neighbors within a distance of %i pixels will be deleted.\n', obj.HighDensityNumberLimit, obj.HighDensityDistanceLimit);
          
           
             
            
            if size(inRadiusRange,1) == 1
                inRadiusRange(1:inNumberOfPlanes,1) = inRadiusRange(1,1);
                inRadiusRange(1:inNumberOfPlanes,2) = inRadiusRange(1,2);
            end
            
            if length(inSensitivity) == 1
                inSensitivity(1:inNumberOfPlanes) = inSensitivity;
            end
            
            if length(inEdgeThreshold) == 1
                inEdgeThreshold(1:inNumberOfPlanes) = inEdgeThreshold;
            end
            
            
            
             
            
             
            
           
            
            CollectionOfCellMasks_Frames =          cell(inNumberOfFrames,1);
            
          

              
              %% go through each image, plane-for-plane then frame-for-frame;
              for SetFrame = FramesOfWantedImages'
                  
                        fprintf('Auto recognition: frame %i\n', SetFrame)

                        CurrentImageVolume =                        myImageSequence{SetFrame,1};
                        LastPlane =                                 size(CurrentImageVolume,3);
                        CollectionOfCellMasks_Planes =              cell(LastPlane,1);
                        
                        
                        
                        
                        for  SetPlane= 1:LastPlane%

                                % get plane-specific settings:
                                 
                                myRadiusRange =                                         inRadiusRange(SetPlane,:);              
                                mySensitivity =                                         inSensitivity(SetPlane); 
                                myEdgeThreshold =                                       inEdgeThreshold(SetPlane); 
                                
                                
                              

                                % get image of current plane, filter it and find circles; 
                                myImage =                                               CurrentImageVolume(:,:,SetPlane,:,MyChannel);
                                %filteredImage =                                         medfilt2(myImage,mySizeOfMedianFilter); % not sure if this is necessary

                                
                                verifyPlaneSettings(obj, myImage)
                                
                                % add all detected coordinates into current plane cell;
                                MyDetectedCoordinates =                                 imfindcircles(myImage,myRadiusRange, 'Sensitivity' , mySensitivity, 'EdgeThreshold',myEdgeThreshold);
                                
                                
                                 % optional: show user images and results (for quality control purposes);
                               
                                
                                if isempty(MyDetectedCoordinates)
                                    continue
                                end
                                
                               
                                
                               [MyFilteredCoordinates] = removeHighDensityCoordinates(obj,MyDetectedCoordinates,myImage);
                                
                               
                                if inShowViewsForControl
                                    
                                    % show original and filtered image as a control
                                    figure(20)
                                    imagesc(myImage)
                                    
                                    FigureNumber = 21;
                                    obj.showCoordinates(myImage,MyDetectedCoordinates,FigureNumber)
                                    
                                    
                                    FigureNumber = 22;
                                    obj.showCoordinates(myImage,MyFilteredCoordinates,FigureNumber)
                                end
                               
                                    MyFilteredCoordinates(:,3) =                            SetPlane;
                                CollectionOfCellMasks_Planes{SetPlane,1} =              MyFilteredCoordinates;




                        end
                    
                        % combine coordinates from different planes (merge ;
                        AllPlaneData =                                  vertcat(CollectionOfCellMasks_Planes{:});
                        PlaneDataAfterPoolingPlanes =                   obj.combinePixelsFromNeighboringPlanes(AllPlaneData);
                    
                        
                        % convert plane upper and lower limit to "mini-pixel" list;
                        % this is complicated; should be simplified;
                        NumberOfCells =                                 size(PlaneDataAfterPoolingPlanes,1);
                        CollectionOfCoordinates_AfterPlanePooling =     cell(NumberOfCells,1);
                        for CurrentCellIndex = 1:NumberOfCells
                            
                                % get new track ID and set LoadedMovie;
                                CurrentCoordinate =                             PlaneDataAfterPoolingPlanes(CurrentCellIndex,:);
                                PlaneRange =                                    CurrentCoordinate(1,3):CurrentCoordinate(1,4);
                                
                                CurrentCoordinateList =                         arrayfun(@(x) [CurrentCoordinate(2), CurrentCoordinate(1), x], PlaneRange, 'UniformOutput',false);
                                MaskCoordinateList =                            vertcat(CurrentCoordinateList{:});
                            
                                CollectionOfCoordinates_AfterPlanePooling{CurrentCellIndex,1} = MaskCoordinateList;
                             
                        end
                        
                        CollectionOfCellMasks_Frames{SetFrame,1} =              CollectionOfCoordinates_AfterPlanePooling;
                        
              end
                
              obj.DetectedCoordinates =     CollectionOfCellMasks_Frames;

              obj.ImageSequence =           cell(size(obj.ImageSequence,1),1); % empty memory
              
              ObjectNumberList =    cellfun(@(x) length(x), CollectionOfCellMasks_Frames);
              TotalObjectNumber =   sum(ObjectNumberList);
              
              fprintf('A total of %i object were detected.\n', TotalObjectNumber);
              
        end
        
        
        
        function [CoordinateList] = removeHighDensityCoordinates(obj,CoordinateList,myImage)
            
            % currently not necesssary because approach worked much better when turning off filter;
            
            DistanceLimit =                     obj.HighDensityDistanceLimit;
            inHighDensityNumberLimit =            obj.HighDensityNumberLimit;
        
        
            Distances = pdist2(CoordinateList,CoordinateList);
            
            CutoffDistances =   Distances<DistanceLimit;
            
            NumberOfCellsWithinLimit =                sum(CutoffDistances,2);
            
            RowsToDeleteBecauseToDense =   find(NumberOfCellsWithinLimit >= inHighDensityNumberLimit);
            
            
            CoordinatesToDelete =   CoordinateList(RowsToDeleteBecauseToDense,:);
            
            NumberOfEventsToDetele =    length(CoordinatesToDelete);
            EventsToSave =              round(NumberOfEventsToDetele*0.15);
           
            
            
            IntensityList =     arrayfun(@(row,column) myImage(row,column), round(CoordinatesToDelete(:,1)), round(CoordinatesToDelete(:,2)));
           
             [B,I] = maxk(IntensityList,EventsToSave);
             
             RowsToDeleteBecauseToDense(I,:) =[]; % save brightest points from deletion;
            
            CoordinateList(RowsToDeleteBecauseToDense,:) = [];
            
        end
        
    function CoordinateListAfterPooling =     combinePixelsFromNeighboringPlanes(obj,CoordinateListBeforePooling)
              
              CoordinateListAfterPooling =              zeros(0,4);
              ListWithWithPotentialTargetCoordinates =               zeros(0,3);
              
              DistanceLimit =                           obj.DistanceLimitForPlaneMerging;
              
              
              while ~isempty(CoordinateListBeforePooling)
                  
                  
                    CoordinateListBeforePooling =                   sortrows(CoordinateListBeforePooling,3); % sort by plane so that search for neighboring planes goes from top to bottom;
                    
                    % get current source coordinate and delete;
                    CurrentlyReconstructedMask =                    CoordinateListBeforePooling(1,:);
                    CoordinateListBeforePooling(1,:) =              [];
              
                    % get rows of all target coordinates that are in the right distance;
                    TargetRowsOne =                                 abs(CurrentlyReconstructedMask(1)-CoordinateListBeforePooling(:,1))<DistanceLimit;
                    TargetRowsTwo =                                 abs(CurrentlyReconstructedMask(2)-CoordinateListBeforePooling(:,2))<DistanceLimit;
                    RowsWithShortXAndYDistance =                                    find(min([TargetRowsOne TargetRowsTwo], [], 2));
                    
                    
                    
                    %% if possible neighboring coordinates are found, shift them from the general coordinates to the reference coordinate;
                    
                    if ~isempty(RowsWithShortXAndYDistance)
                    
                        % remove all possible target rows from the source;
                        ListWithWithPotentialTargetCoordinates =                                 CoordinateListBeforePooling( RowsWithShortXAndYDistance,:);
                        CoordinateListBeforePooling(RowsWithShortXAndYDistance,:) =                 [];
                        
                        while 1 % not sure whether this loop is necessary;

                            CurrentBottomZ =                                                        max(CurrentlyReconstructedMask(:,3));
                            ZDifferences =                                                      round(abs(ListWithWithPotentialTargetCoordinates(:,3)-CurrentBottomZ));
                            
                            if min(ZDifferences)>1
                                break
                            else
                                
                                % get and delete target coordinates that are in direct contact with current Bottom Z;
                                TargetRowsThatAreInDirectContactToSource =                                  ZDifferences <= 1;
                                TargetCoordinatesThatAreTransferred =                                       ListWithWithPotentialTargetCoordinates(TargetRowsThatAreInDirectContactToSource,:);
                                ListWithWithPotentialTargetCoordinates(TargetRowsThatAreInDirectContactToSource,:) =     [];
                                
                                CurrentlyReconstructedMask =                                                [CurrentlyReconstructedMask;   TargetCoordinatesThatAreTransferred ];
                                
                                
                                if isempty(ListWithWithPotentialTargetCoordinates)
                                   break 
                                end
                                
                            end
                            
                        end
                        CoordinateListBeforePooling =       [CoordinateListBeforePooling; ListWithWithPotentialTargetCoordinates]; % unused coordinates get shift back;
                    
                    end
                    
                    
                   
                    % put together new coordinate from pooled coordinates;
                    NewCoordinate(1,1) =                    round(mean(CurrentlyReconstructedMask(:,1)));
                    NewCoordinate(1,2) =                    round(mean(CurrentlyReconstructedMask(:,2)));
                    NewCoordinate(1,3) =                    min(CurrentlyReconstructedMask(:,3));
                    NewCoordinate(1,4) =                    max(CurrentlyReconstructedMask(:,3));
                    
                    
                    CoordinateListAfterPooling =            [CoordinateListAfterPooling;NewCoordinate];
                    
                    
                    
              end
              
              CoordinateListAfterPooling =         sortrows(CoordinateListAfterPooling, [1,2,3]);
        end
          
        
        
        
        function showCoordinates(obj,myImage,MyDetectedCoordinates,FigureNumber)
            
            
                figure(FigureNumber)
                imagesc(myImage)

               

                % get coordinates
                if ~isempty(MyDetectedCoordinates)

                    a =                                     line(MyDetectedCoordinates(:,1),MyDetectedCoordinates(:,2));
                    a.LineStyle =                           'none';
                    a.Marker =                              'x';
                    a.Color =                               'w';

                end

        end
        
        function verifyPlaneSettings(obj, CurrentImage)
            
            
            
        end
    
    end
    
      
       
end

