classdef PMInteractionsCapture
    %PMINTERACTIONSETTINGS helps PMInteractionsManager to perform the actual distance measurements between tracked cells and a target structure ;
    %   a PMMovieTracking needs to be set as a datasource for performing these calculations;
    
    
    properties (Access = private) % properties for 
        ShowThresholdedImage = false % this determins whether the thresholded image is visible or not;;    
        MyMovieTracking
           
    end
    
    properties (Access = private) % properties that determine thresholding of target area;
        ThresholdsForImageVolumes
        SourceFramesForImageVolumes =       1
        MinimumSizesOfTarget =              25
        ChannelNumbersForTarget =           1
        FilterTypeForTargetChannel =        'Median'
        
    end
    
    properties (Access = private) % properties that determine interaction analysis;
        MaximumDistanceToTarget =       1000
        XYLimitForNeighborArea =        13
        ZLimitForNeighborArea =         0
        MaxPlane =                      1000
        
    end
    
    properties (Access = private)
        ExportFolder
        
    end
    
    properties (Access = private)
       
    end
    
    
    methods % INITIALIZATION 

        function obj =      PMInteractionsCapture(varargin)
            %PMINTERACTIONSETTINGS Construct an instance of this class
            %   takes 0 arguments
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                    
                otherwise
                    error('Input not supported.')
                
            end
               
         end
        
        function obj =      set.MyMovieTracking(obj, Value)
             assert(isa(Value, 'PMMovieTracking'), 'Wrong input.')
            obj.MyMovieTracking = Value;
        end
        
        function obj =      set.ThresholdsForImageVolumes(obj, Value)
            assert(isnumeric(Value) && isvector(Value) , 'Wrong input.')
            obj.ThresholdsForImageVolumes = Value; 
        end

        function obj =      set.SourceFramesForImageVolumes(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) , 'Wrong input.')
            obj.SourceFramesForImageVolumes = Value; 
        end

        function obj =      set.MinimumSizesOfTarget(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) , 'Wrong input.')
            obj.MinimumSizesOfTarget = Value; 
         end

        function obj =      set.ChannelNumbersForTarget(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) , 'Wrong input.')
            obj.ChannelNumbersForTarget = Value; 
        end
        
        function obj =      set.FilterTypeForTargetChannel(obj, Value)
            assert(ischar(Value), 'Wrong input.')
           obj.FilterTypeForTargetChannel = Value; 
        end

        function obj =      set.MaximumDistanceToTarget(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
            obj.MaximumDistanceToTarget = Value; 
        end

        function obj =      set.ShowThresholdedImage(obj, Value)
            assert(islogical(Value) && isscalar(Value), 'Wrong input.')
            obj.ShowThresholdedImage = Value;
        end
        
        function obj =      set.ExportFolder(obj, Value)
           assert(ischar(Value), 'Wrong input.')
           obj.ExportFolder = Value;
            
        end
        
        function obj =      set.XYLimitForNeighborArea(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
           obj.XYLimitForNeighborArea = Value; 
        end
        
        function obj =      set.ZLimitForNeighborArea(obj, Value)
            assert(isnumeric(Value) && isscalar(Value), 'Wrong input.')
           obj.ZLimitForNeighborArea = Value; 
        end
        
    end
    
    methods % SUMMARY
        
        function obj =      showSummary(obj)
            cellfun(@(x) fprintf('%s', x), obj.getSummary);
        end
        
        function Text =     getSummary(obj)
               
            obj =            obj.setChannelSettingsInMovieTracking;
            
            Text = {sprintf('\n*** The main method of this PMInteractionsCapture object is "getInteractionsMap".\n')};
            Text = [Text; sprintf('It returns a "map" with all target distances for each tracked cell at each instant.\n')];
            Text = [Text; sprintf('This is achieved by creating a PMInteractions object and then calling its function getInteractionsMap.\n')];
            Text = [Text; sprintf('Thus the actual measurement of distances is made by PMInteractions not by PMInteractionsCapture.\n')];
            Text = [Text; sprintf('\n* A) To create the PMInteractions object, PMInteractionsCapture first creates a "target-volume with the following algorithm:\n')];
           
            Text =   [      Text;          obj.getSummaryForCreatingTargetImageVolume];

            Text = [Text; sprintf('\n* B) It also provides the searcher positions from the movie controller and limits the target volume for search of targets to the following volume:\n')];
            Text = [Text; sprintf('For each cell a volume around the cell center +/- %6.2f µm in XY plane and +/- %6.2f µm in Z-axis will be created.\n', obj.XYLimitForNeighborArea,  obj.ZLimitForNeighborArea)];

           
             
        end
        
        function text =     getSummaryForCreatingTargetImageVolume(obj)

              text = { sprintf('This PMInteractionsCapture object creates the image-volume for the target in the following way:\n')};
              text = [text; sprintf('It uses its movie-controller method "getActiveImageVolumeForChannel" to retrieve the image-volume for frame "%i". and channel "%i".\n', obj.SourceFramesForImageVolumes, obj.ChannelNumbersForTarget)];
              text = [text; sprintf('This image was filtered with method "%s" by the movie controller.', obj.getReconstructionType)];
              text = [text; sprintf('This image is used to create a PM5DImageVolume object\n')];
              text = [text; sprintf('This PM5DImageVolume is then processed with two additional steps:\n')];
              text = [text; sprintf('Step 1: Thresholding with the following cutoffs for the different planes:\n')];
              text = [ text; arrayfun(@(x) sprintf('%6.2f ', x), obj.ThresholdsForImageVolumes, 'UniformOutput', false)];
              text = [text; sprintf('\nStep 2: Removal of all objects with a size of less than"%i".\n', obj.MinimumSizesOfTarget)];

          end

        
    end
    
     methods % SETTERS complex
       
        function obj =      setMovieTracking(obj, Value)
            % SETMOVIECONTROLLER sets object with content of input
            % takes 1 argument
            % 1: scalar of PMMovieTracking
            % it is required that the movie-controller already contains a PMInteractionsCapture object, which will be used for setting;
            % in addition default thresholds will be set;
            % also active channel and reconstruction type (e.g. filters) of movie in controller will be updated;
            
            assert(isa(Value, 'PMMovieTracking') && isscalar(Value), 'Wrong input.')
             
            obj.MyMovieTracking =     Value;
            obj =                     obj.setChannelSettingsInMovieTracking;
           
          end

        function obj =      setWith(obj, Value)
            % SETWITH setter;
            % takes 1 argument: PMMovieTracking object or PMInteractionsManager;
            
            switch class(Value)
                
                case 'PMMovieTracking'
                    obj = obj.setMovieTracking(Value);
                   
                case 'PMInteractionsManager'   
                    obj = obj.set(Value.getModel.getContent{:}); 

                otherwise
                    error('Wrong input')
            end
                  
        end
        
        function obj =      set(obj, varargin)
            %SET sets thresholds and limits;
            % takes 6 arguments:
            % 1: image-volume thresholds
            % 2: source frames
            % 3: minimum target sizes
            % 4: target channel numbers
            % 5: maximum distance to target
            % 6: show thresholded image
            
                NumberOfArguments = length(varargin);

                switch NumberOfArguments
                    case 6
                        obj.ThresholdsForImageVolumes =     varargin{1};
                        obj.SourceFramesForImageVolumes =   varargin{2};
                        obj.MinimumSizesOfTarget =          varargin{3};
                        obj.ChannelNumbersForTarget =       varargin{4};
                        obj.MaximumDistanceToTarget =       varargin{5};
                        obj.ShowThresholdedImage =          varargin{6};

                    otherwise
                        error('Wrong input.')

                end
             
          end
          
        
     end
     
     methods % SETTERS simple
         
         function obj = setShowThresholdedImage(obj, Value)
            obj.ShowThresholdedImage = Value; 
         end
      
        function obj =      setThresholdsForImageVolumeOfTarget(obj, Value)
            obj.ThresholdsForImageVolumes = Value;
        end
        
        function obj =      setSourceFrameForImageVolumeOfTarget(obj, Value)
            obj.SourceFramesForImageVolumes = Value;
        end
        
        function obj =      setMinimumSizeOfTarget(obj, Value)
            obj.MinimumSizesOfTarget = Value;
        end
        
        function obj =      setChannelNumberForTarget(obj, Value)
            obj.ChannelNumbersForTarget = Value;
        end
        
        function obj =      setMaximumDistanceToTarget(obj, Value)
           obj.MaximumDistanceToTarget = Value; 
        end
        
        function obj =      setExportFolder(obj, Value)
           obj.ExportFolder = Value; 
        end

        function obj =      setXYLimitForNeighborArea(obj, Value)
           obj.XYLimitForNeighborArea = Value; 
        end
        
        function obj =      setZLimitForNeighborArea(obj, Value)
           obj.ZLimitForNeighborArea = Value; 
        end
          
     
     end
    
     
     methods % GETTERS
    
        function Image =                getImageVolume(obj) 
            % getImageVolume
           Volume =     obj.getImageVolumeObjectOfTarget;
           Image =      Volume.getImageVolume;

        end 
   
        function ExportFileNames =      getFileNamesForExportImages(obj)
                  exportFolderName = [obj.ExportFolder, '/Movie_', obj.MyMovieTracking.getNickName ];
               ExportFileNames = cellfun(@(x) [exportFolderName, '/TargetVolume_Plane_', num2str(index), '_', PMTime().getCurrentTimeString, '.jpg'], (1 : size(TargetVolume, 3))');
        
            
        end
        
        function mini =                 getMiniObject(obj)
              mini = obj;
              mini.MyMovieTracking = PMMovieTracking;
         end
             
     end

    methods  % GETTERS: used for updating PMInteractionsView;

        function controller =       getMovieTracking(obj)
            controller = obj.MyMovieTracking;
        end

        function Value =            getThresholdsForImageVolumes(obj)
            Value = obj.ThresholdsForImageVolumes;
        end

        function Value =            getSourceFramesForImageVolumes(obj)
            Value = obj.SourceFramesForImageVolumes;
        end

        function Value =            getChannelNumbersForTarget(obj)
            Value = obj.ChannelNumbersForTarget;
        end

        function Value =            getMinimumSizesOfTarget(obj)
            Value = obj.MinimumSizesOfTarget;
        end

        function Value =            getMaximumDistanceToTarget(obj)
            Value = obj.MaximumDistanceToTarget;
        end

        function Value =            getShowThresholdedImage(obj)
            Value = obj.ShowThresholdedImage;
            if isempty(Value)
                Value = true;
            end
        end

    end


    methods % ACTION getters

        function Map =                  getInteractionsMap(obj)  
            % GETINTERACTIONSMAP
            MyInteractionsObject =     obj.getInteractionsObject;

             if ~isempty(obj.ExportFolder)
                 obj.exportSummaryOfMapIntoFile;               
             end

            Map =                       MyInteractionsObject.getInteractionsMap;

        end

        function myInteractions =       getInteractionsObject(obj, varargin)
             % GETINTERACTIONSOBJECT returns a PMInteractions object;

              obj.MyMovieTracking =                       obj.MyMovieTracking.setFrameTo(obj.SourceFramesForImageVolumes);


             switch length(varargin)

                 case 0


                            myInteractions =                    PMInteractions(...
                                        obj.getMetricTargetShape, ...
                                        obj.getPixelTargetShape,...
                                        obj.getMetricSearcherTrackingAnalysis, ...
                                        obj.getPixelSearcherTrackingAnalysis, ...
                                        obj.getMetricDriftCorrection, ...
                                        obj.XYLimitForNeighborArea, ...
                                        obj.ZLimitForNeighborArea...
                                    );


                 case 1

                 switch varargin{1}

                     case 'SuppressMetric'

                           myInteractions =                    PMInteractions(...
                                        obj.getPixelTargetShape, ...
                                        obj.getPixelTargetShape,...
                                        obj.getPixelSearcherTrackingAnalysis, ...
                                        obj.getPixelSearcherTrackingAnalysis, ...
                                        obj.getPixelDriftCorrection, ...
                                        obj.XYLimitForNeighborArea, ...
                                        obj.ZLimitForNeighborArea...
                                    );


                     otherwise
                         error('Wrong input.')




                 end

                 otherwise

                     error('Wrong input.')



             end




            myInteractions =                    myInteractions.setExportFolder(obj.ExportFolder);
            myInteractions =                    myInteractions.setMovieName(obj.MyMovieTracking.getNickName);

        end

        function obj =                  showTargetImage(obj)
           
            MyTargetShape = obj.getPixelTargetShape;
            MyImage = MyTargetShape.getRawImageVolume('MaximumProjection');
            figure
            imagesc(MyImage)
            
        end
        
    end

    methods % EXPORT:

        function obj = exportDetailedInteractionInfoForTrackIDs(obj, TrackIDs, varargin)

            MyInteractionsObject =      obj.getInteractionsObject(varargin{:});
            MyInteractionsObject.exportDetailedInteractionInfoForTrackIDs(TrackIDs);
        end

    end

    
    


    methods (Access = private) % EXPORT
        
        function obj = exportSummaryOfMapIntoFile(obj)
            % EXPORTSUMMARYOFMAPINTOFILE
            % the object is always creating the "target image map" from scratch;
            % this is just done so that user can visually verify how the thresholded image is created;
            % the information created here is not "read back" from this file;


            exportFolderName = [obj.ExportFolder, '/Movie_', obj.MyMovieTracking.getNickName ];
            if exist(exportFolderName) ~=7
                mkdir(exportFolderName)
            end


            PMFile(exportFolderName, ['PMInteractionsCaptureSummary_', PMTime().getCurrentTimeString,  '.txt']).writeCellString(obj.getSummary);
            TargetVolume = obj.getImageVolumeObjectOfTarget.getImageVolume;

            ExportFileNames = obj.getFileNamesForExportImages;

            TargetVolume(TargetVolume >= 1) = 255;
            for index = 1 : size(TargetVolume, 3)
                imwrite(TargetVolume(: , :, index), ExportFileNames{index})

            end

        end

    end
    
    methods (Access = private) % GET SEARCHER TRACKING ANALYSIS:
        
        function MyTrackingAnalysis_Metric =    getMetricSearcherTrackingAnalysis(obj)
                    MyTrackingAnalysis_Metric  =                obj.MyMovieTracking.getMetricTrackingAnalysis;
                    MyTrackingAnalysis_Metric =                 MyTrackingAnalysis_Metric.setApplyDriftCorrection(false);

        end
        
          function MyTrackingAnalysis_Metric =  getPixelSearcherTrackingAnalysis(obj)
                    MyTrackingAnalysis_Metric  =                obj.MyMovieTracking.getPixelTrackingAnalysis;
                    MyTrackingAnalysis_Metric =                 MyTrackingAnalysis_Metric.setApplyDriftCorrection(false);

        end
        
    end

    methods (Access = private) % GETTERS: DRIFT-CORRECTION:

        function MyDriftCorrection_Metric =     getMetricDriftCorrection(obj)
            MyDriftCorrection =                 obj.getPixelDriftCorrection;
            MyDriftCorrection_Metric =          MyDriftCorrection.convertToMetricBySpaceCalibration(obj.MyMovieTracking.getSpaceCalibration);
        end
        
        function MyDriftCorrection =            getPixelDriftCorrection(obj)
            MyDriftCorrection =                 obj.MyMovieTracking.getDriftCorrection;
        end


    end

    methods (Access = private) % GETTERS TARGET SHAPES:

        function myFluShape_Metric =            getMetricTargetShape(obj)
            myFluShape_Pixels =                 obj.getPixelTargetShape;
            myFluShape_Metric =                 myFluShape_Pixels.convertPixelToUmWithCalibration(obj.MyMovieTracking.getSpaceCalibration);
        end
        
        function myFluShape_Pixels =            getPixelTargetShape(obj)
            myFluShape_Pixels =                 PMShape(obj.getImageVolumeObjectOfTarget.getSpaceCoordinates);
       end
        
        function fluObj_Final =                 getImageVolumeObjectOfTarget(obj)
            % make sure that the filter type is specified correctly:
            % this will influence how exactly the 
            fluObj=                         PM5DImageVolume(obj.getImageVolumeOfTarget);
            fluObj_thresholded =            fluObj.threshold(obj.ThresholdsForImageVolumes);
            fluObj_Final =                  fluObj_thresholded.removeSmallObjects(obj.MinimumSizesOfTarget);
        end

        function  FluVolumeOfCurrentFrame =     getImageVolumeOfTarget(obj)
            activeVolume =                  obj.MyMovieTracking.getActiveImageVolume; 
            FluVolumeOfCurrentFrame =       obj.MyMovieTracking.filterImageVolumeForChannel(activeVolume, obj.ChannelNumbersForTarget);
        end
        
        function obj =                          setChannelSettingsInMovieTracking(obj)
                assert(~isempty(obj.MyMovieTracking), 'Need to set movie-controller before proceeding.')
                obj.MyMovieTracking =                 obj.MyMovieTracking.setActiveChannel(obj.ChannelNumbersForTarget);
                obj.MyMovieTracking =                 obj.MyMovieTracking.setReconstructionType(obj.FilterTypeForTargetChannel);


        end

    end

    methods (Access = private) % tracking analysis of searchers:

        function reconstructionType = getReconstructionType(obj)
          
            if isempty(obj.MyMovieTracking)
                reconstructionType = 'Reconstruction type not known because active movie-controller not set.';

            else

                  MyLoadedMovie = obj.MyMovieTracking;
                  if isempty(MyLoadedMovie)
                        reconstructionType =    'Reconstruction type not known because no movie loaded.';
                  else
                        reconstructionType =    obj.MyMovieTracking.getReconstructionTypesOfChannels{obj.ChannelNumbersForTarget} ;
                  end

            end
          
      end

    end

    methods (Access = private) % getters

        function values = getContent(obj)
            % GETCONTENT returns main properties of object as cell vector;
            values{1} = obj.ThresholdsForImageVolumes;
            values{2} = obj.SourceFramesForImageVolumes;
            values{3} = obj.MinimumSizesOfTarget;
            values{4} = obj.ChannelNumbersForTarget;
            values{5} = obj.MaximumDistanceToTarget;
            values{6} = obj.ShowThresholdedImage;

        end

    end


    
end

