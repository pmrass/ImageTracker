classdef PMImageSource
    %PMIMAGESOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ImageMapPerFile
        Settings
        Navigation
        
    end
    
    properties (Constant)
         TimeColumn =                                    10;
    end
    
    methods
        function obj = PMImageSource(varargin)
            %PMIMAGESOURCE Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments= length(varargin);
            switch NumberOfArguments
                case 2
                    obj.ImageMapPerFile = varargin{1};
                    obj.Navigation =      varargin{2};
                case 3
                    obj.ImageMapPerFile = varargin{1};
                    obj.Navigation =      varargin{2};
                    obj.Settings =        varargin{3};    
                otherwise
                    error('Wrong number of arguments.')
            end
            
            
        end
        
        function ImageVolume = getImageVolume(obj)
            %getImageVolume getImageVolume
            %   Detailed explanation goes here
             %% first filter the image map: only images that meet the defined source numbers will be kept;
             FilteredImageMap =              obj.getImageMap;   
            
             FilteredImageMap =              obj.removeUnwantedEntriesFromImageMap(FilteredImageMap);   
             FilteredImageMap =              obj.resetPositionsOfImageMap(FilteredImageMap);   
             FilteredImageMap(1,:) =         [];
        
             ImageVolume =                  obj.initializeImageFromImageMap(FilteredImageMap);
             

            for IndexOfDirectory = 1 : size(FilteredImageMap,1)
                directory =             PMImageDirectory(FilteredImageMap(IndexOfDirectory,:));
                ImageVolume =           directory.drawOnImageVolume(ImageVolume);
            end
            
        end
        
         %% get final image map:
          function MergedImageMap = getImageMap(obj)
                switch obj.getImageOrderType

                    case 'MatchOfNavigationAndImageMapFrames'
                        FramesPerMap =           cellfun(@(x) max(cell2mat(x(2:end, obj.TimeColumn))), obj.ImageMapPerFile);
                        CumulativeTemp =         cumsum(FramesPerMap);
                        adjustingTimeFrames =    [0; CumulativeTemp(1:end-1)];
                    case 'EachChannelHasAnEntry'
                        adjustingTimeFrames =    linspace(0,obj.Navigation.getMaxFrame-1,obj.Navigation.getMaxFrame);
                        adjustingTimeFrames =    repmat(adjustingTimeFrames, obj.Navigation.getMaxChannel,1);
                        adjustingTimeFrames =    adjustingTimeFrames(:);
                    case 'NavigationAndImageMaxFrameMatch'
                        adjustingTimeFrames =   '';
                    otherwise
                        error('Unknown pattern.')
                end

                ImageMap =                  obj.adjustFramesOfImageMap(adjustingTimeFrames);
                ImageMapsWithoutTitles =    cellfun(@(x) x(2:end,:), ImageMap, 'UniformOutput', false);
                MergedImageMap =            [obj.ImageMapPerFile{1,1}(1,:); vertcat(ImageMapsWithoutTitles{:})];
          end
          
        
             
    end
    
    methods(Access = private)
      
       
          
          %% get image order-type:
           function type = getImageOrderType(obj)
                if obj.Navigation.getMaxFrame ==  obj.getNumberOfFramesInImageMap
                    type = 'MatchOfNavigationAndImageMapFrames';
                elseif obj.Navigation.getMaxFrame == obj.getNumberOfEntriesInImageMap / obj.Navigation.getMaxChannel
                    type = 'EachChannelHasAnEntry';
                elseif obj.Navigation.getMaxFrame == obj.getMaximumFrameOfImageMap
                    type = 'NavigationAndImageMaxFrameMatch';
                else
                    error('Cannot interpret time-series')  
                end
            end
            
            function frameNumber = getNumberOfFramesInImageMap(obj)
                frameNumber =     sum(obj.getMaximumFramesPerImageMap);
            end
            
            function maximumFrames = getMaximumFramesPerImageMap(obj)
                 maximumFrames =           cellfun(@(x) max(cell2mat(x(2:end, obj.TimeColumn))), obj.ImageMapPerFile);
            end
            
            function value = getNumberOfEntriesInImageMap(obj)
                value = size( obj.getPooledImageMapWithoutTitle,1);
            end
            
            function maximumFrame = getMaximumFrameOfImageMap(obj)
               maximumFrame =  max(obj.getFramesFromImageMap);
            end
            
            function frames = getFramesFromImageMap(obj)
                pooledImageMap =        obj.getPooledImageMapWithoutTitle;
                frames =                cell2mat(pooledImageMap(:, obj.TimeColumn));
            end
            
             function pooledImageMap = getPooledImageMapWithoutTitle(obj)
                pooledImageMap =        cellfun(@(x) x(2:end,:), obj.ImageMapPerFile, 'UniformOutput', false);
                pooledImageMap =        vertcat(pooledImageMap{:});
            end
            
          %% adjust frames of image map:
          function ImageMap = adjustFramesOfImageMap(obj, adjustingTimeFrames)
                 if ~isempty(adjustingTimeFrames)
                    ImageMap = obj.ImageMapPerFile;
                    for CurrentMapIndex = 1: obj.getNumberOfImageMaps 
                        OldMapNumbers =                   cell2mat(obj.ImageMapPerFile{CurrentMapIndex,1}(2:end, obj.TimeColumn));
                        ImageMap{CurrentMapIndex,1}(2:end, obj.TimeColumn) =         num2cell(OldMapNumbers + adjustingTimeFrames(CurrentMapIndex));
                    end
                end
          end
            
          function number = getNumberOfImageMaps(obj)
                 number =     size(obj.ImageMapPerFile,1);
          end
        
          %% edit image map:
          function ImageMap =  removeUnwantedEntriesFromImageMap(obj, ImageMap)
                if ~isempty(obj.Settings)
                    [ImageMap] =                        obj.removeUnwantedImageMapRows(ImageMap, obj.Settings,'TargetFrameNumber'); % filter for frames
                    [ImageMap] =                        obj.removeUnwantedImageMapRows(ImageMap, obj.Settings,'TargetPlaneNumber'); % filter for planes
                    [ImageMap] =                        obj.removeUnwantedImageMapRows(ImageMap, obj.Settings,'TargetChannelIndex'); % filter for channels
                end 
          end
          
          function [NewImageMap] =                               removeUnwantedImageMapRows(obj, ImageMap, Settings, FilterCode)
                switch FilterCode
                    case 'TargetFrameNumber'
                        ListWithWantedNumbers =         Settings.SourceFrames;
                    case 'TargetPlaneNumber'
                        ListWithWantedNumbers =         Settings.SourcePlanes;
                    case 'TargetChannelIndex'
                         ListWithWantedNumbers =         Settings.SourceChannels;   
                end
                FilteredImageMap =          ImageMap(2:end,:);
                if ~isempty(ListWithWantedNumbers)
                    ColumnWithWantedParameter =                                 strcmp('TargetFrameNumber', obj.getColumnTitles);
                    RowsThatShouldBeKept =                                      false(size(FilteredImageMap,1), length(ListWithWantedNumbers));
                    for CurrentIndex = 1 : length(ListWithWantedNumbers)
                        RowsThatShouldBeKept(:, CurrentIndex) =                  cell2mat(FilteredImageMap(:,ColumnWithWantedParameter)) == ListWithWantedNumbers(CurrentIndex);
                    end
                    RowsThatShouldBeKept =                                      max(RowsThatShouldBeKept, [], 2);
                    FilteredImageMap=                                       FilteredImageMap(RowsThatShouldBeKept,:);
                end
                NewImageMap = [obj.getColumnTitles; FilteredImageMap];
         end
        
           
        function ColumnTitles = getColumnTitles(obj)
            ColumnTitles =                           obj.ImageMapPerFile{1}(1,:);
        end
        
      function ImageMap =  resetPositionsOfImageMap(obj, ImageMap)
         if ~isempty(obj.Settings)
             %% then reset the numbers of the images in the file to rearrange if needed;
             % for example, you may want to change time frame from 10 to 1 if you want just a single image volume rather than a time-series;
            [ImageMap] =                        obj.resetImageMap(ImageMap, obj.Settings,'TargetFrameNumber'); % replace source frame numbers wiht target frame numbers
            [ImageMap] =                        obj.resetImageMap(ImageMap, obj.Settings,'TargetPlaneNumber'); 
            [ImageMap] =                        obj.resetImageMap(ImageMap, obj.Settings,'TargetChannelIndex');
         end   

      end
          
        function [ImageMap] =                       resetImageMap(obj, ImageMap, Settings, FilterCode)
            switch FilterCode
                case 'TargetFrameNumber'
                    SourceNumbers =                 Settings.SourceFrames;
                    TargetNumbers =                 Settings.TargetFrames;

                case 'TargetPlaneNumber'
                    SourceNumbers =                 Settings.SourcePlanes;
                    TargetNumbers =                 Settings.TargetPlanes;

                case 'TargetChannelIndex'
                    SourceNumbers =                 Settings.SourceChannels;
                    TargetNumbers =                 Settings.TargetChannels;
            end

            WantedColumn =                      strcmp(FilterCode, obj.getColumnTitles);
            ImageMapForFiltering =              ImageMap(2:end,:);
            for ChangeIndex = 1 :  length(SourceNumbers)
                oldValue =                      SourceNumbers(ChangeIndex);
                newValue =                      TargetNumbers(ChangeIndex);
                RowsThatNeedChange =                                        cell2mat(ImageMapForFiltering(:,WantedColumn)) == oldValue;
                ImageMapForFiltering(RowsThatNeedChange,WantedColumn) =        {newValue};

            end
            ImageMap = [obj.getColumnTitles; ImageMapForFiltering];
        end

        
        function [NonObjectImageMap] =                       ResetChannelsInImageMap(obj, NonObjectImageMap, oldValue, newValue)
            myImageMap =       obj.getImageMap; 
            WantedColumn =                                              strcmp('TargetChannelIndex', myImageMap(1,:));
            RowsThatNeedChange =                                        cell2mat(NonObjectImageMap(:,WantedColumn)) == oldValue;
            NonObjectImageMap(RowsThatNeedChange,WantedColumn) =        {newValue};
            
        end
        
        function [NonObjectImageMap] =                       ResetFramesInImageMap(obj, NonObjectImageMap, oldValue, newValue)
            myImageMap =       obj.getImageMap; 
            WantedColumn =                                              strcmp('TargetFrameNumber', myImageMap(1,:));
            RowsThatNeedChange =                                        cell2mat(NonObjectImageMap(:,WantedColumn)) == oldValue;
            NonObjectImageMap(RowsThatNeedChange,WantedColumn) =        {newValue};
        end
        
        function [NonObjectImageMap] =                       ResetPlanesInImageMap(obj, NonObjectImageMap, oldValue, newValue)
            myImageMap =       obj.getImageMap; 
            WantedColumn =                                              strcmp('TargetPlaneNumber', myImageMap(1,:));
            RowsThatNeedChange =                                        cell2mat(NonObjectImageMap(:,WantedColumn)) == oldValue;
            NonObjectImageMap(RowsThatNeedChange,WantedColumn) =        {newValue};
        end
        
        
        
        function numberOfRows = getNumberOfRowsFromImageMap(obj, FilteredImageMap)
            if isempty(FilteredImageMap)
                numberOfRows = 1;
            else
                TotalRowsOfImageList =              unique(cell2mat(FilteredImageMap(:,9)));
                assert(length(TotalRowsOfImageList)==1, 'Cannot read file. Reason: precision of different image elements is not identical')
                numberOfRows =                  TotalRowsOfImageList(1,1);
            end 
        end
        
        function numberOfColumns = getNumberOfColumnsFromImageMap(obj, FilteredImageMap)
            if isempty(FilteredImageMap)
                numberOfColumns = 1;
            else
                 TotcalColumnsOfImageList =         unique(cell2mat(FilteredImageMap(:,8)));
                assert(length(TotcalColumnsOfImageList)==1, 'Cannot read file. Reason: precision of different image elements is not identical')
                numberOfColumns =             TotcalColumnsOfImageList(1,1);
            end
        end
        
        function numberOfPlanes = getNumberOfPlanesFromImageMap(obj, FilteredImageMap)
             if isempty(FilteredImageMap)
                 numberOfPlanes = 1;
             else
                 ColumnForPlanes =                           strcmp(getColumnTitles(obj), 'TargetPlaneNumber');
                numberOfPlanes =                               max(cell2mat(FilteredImageMap(:,ColumnForPlanes)));
             end
             
        end
        
        function numberOfChannels = getNumberOfChannelsFromImageMap(obj, FilteredImageMap)
             if isempty(FilteredImageMap)
                 numberOfChannels = 1;
             else
                 numberOfChannels =                     max(cell2mat(FilteredImageMap(:,15)));
            
             end
             
        end
        
        function numberOfFrames = getNumberOfFramesFromImageMap(obj, FilteredImageMap)
             if isempty(FilteredImageMap)
                 numberOfFrames = 1;
             else
                 ColumnForFrames =                           strcmp(getColumnTitles(obj), 'TargetFrameNumber');
                numberOfFrames =                               max(cell2mat(FilteredImageMap(:,ColumnForFrames)));
            
             end
             
        end
        
        
        function Precision = getPrecisionFromImageMap(obj, FilteredImageMap)
            if isempty(FilteredImageMap)
                Precision =                   'uint8';
            else
                PrecisionList =                     unique(FilteredImageMap(:,6));
                assert(length(PrecisionList)==1, 'Cannot read file. Reason: precision of different image elements is not identical')
                Precision =                         PrecisionList{1,1};
            end
        end
        
          
            
           function image =        initializeImageFromImageMap(obj, ImageMap)
            image=                         cast(uint8(0), obj.getPrecisionFromImageMap(ImageMap));
            image(obj.getNumberOfRowsFromImageMap(ImageMap), ...
                                    obj.getNumberOfColumnsFromImageMap(ImageMap), ...
                                    obj.getNumberOfPlanesFromImageMap(ImageMap), ...
                                    obj.getNumberOfFramesFromImageMap(ImageMap), ...
                                    obj.getNumberOfChannelsFromImageMap(ImageMap))=                          0;


            end
            
            
        
     
        
    end
end

