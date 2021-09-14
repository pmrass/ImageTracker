classdef PMImageFiles
    %PMIMAGEFILES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        FilePaths
        myImageDocuments
        
    end
    
    methods % initialize
        
          function obj = PMImageFiles(varargin)
                %PMIMAGEFILES Construct an instance of this class
                %   Detailed explanation goes here

                NumberOfArguments = length(varargin);
                switch NumberOfArguments
                    case 1
                        obj.FilePaths = varargin{1};
                        obj =       obj.SetImageDocuments;

                    otherwise
                        error('Wrong input.')

                end
          end
          
          function obj = set.FilePaths(obj, Value)
                assert(isvector(Value) && iscellstr(Value), 'Wrong input.')
                obj.FilePaths = Value; 
          end
        
        
    end
    
    methods
        
            function value = supportedFileType(obj)
                  FileType =      obj.getFileType;
                  if isempty(FileType)
                      value = false;
                  else
                      value = true;
                  end
              
            end
          
          
        
      
        
        function spaceCalibrationOfEachMovie = getSpaceCalibration(obj)
            MetaDataFromImage =                 obj.getMetaData;
            spaceCalibrationOfEachMovie =       PMSpaceCalibrationSeries(cellfun(@(x) PMMetaData(x).getPMSpaceCalibration, MetaDataFromImage));
        end
        
        function NavigationForEachMovie = getTimeCalibration(obj)
              MetaDataFromImage =                 obj.getMetaData;
             NavigationForEachMovie =            PMTimeCalibrationSeries(cellfun(@(x) PMMetaData(x).getPMTimeCalibration, MetaDataFromImage));
        end
        
        function Navigation = getNavigation(obj)
              MetaDataFromImage =       obj.getMetaData;
             Navigation =               PMNavigationSeries(cellfun(@(x) PMMetaData(x).getPMNavigation, MetaDataFromImage));
        end
        
        function MyImageMapsPerFile = getImageMapsPerFile(obj)
              MyImageMapsPerFile =               arrayfun(@(x) x.getImageMap, obj.myImageDocuments, 'UniformOutput', false); 
        end
        
        function MetaDataString = getMetaDataString(obj)

                switch obj.getFileType
                    case 'czi' 
                        obj.myImageDocuments =   cellfun(@(x)  PMCZIDocument(x), obj.getPathsOfImageFiles, 'UniformOutput', false);
                        FirstMovie =         obj.myImageDocuments{1,1};
                        MetaDataString =         FirstMovie.getMetaDataString;
                        
                       
                     case {'tif'}
                        paths =             obj.getPathsOfImageFiles;
                        FirstMovie =        cellfun(@(x)  PMTIFFDocument(x), paths(1), 'UniformOutput', false);
                        MetaDataString=     FirstMovie{1}.getRawMetaData;

                    case {'lsm'} % do not store ;
                        [~, MetaDataString] =            obj.getMetaDataForLsm;

                    otherwise
                        MetaDataString =                                   obj.getMetaDataSummary;

                end
            
            
        end
        
            function Summary = getMetaDataSummary(obj)
            
             fileType =                                           obj.getFileType;
            switch fileType
                case 'czi' 
                    obj.myImageDocuments =   cellfun(@(x)  PMCZIDocument(x), obj.getPathsOfImageFiles, 'UniformOutput', false);
                        Summary =          obj.myImageDocuments{1,1}.getObjectiveSummary;
                            ImageCaptureSummary = obj.myImageDocuments{1,1}.getImageCaptureSummary;
                  
                            Summary = [Summary; ImageCaptureSummary];
                    
                 case {'tif'}
                     Summary =           'No meta data summary for tif available';
                    
                case {'lsm'} % do not store ;
                    [Summary, ~] =            obj.getMetaDataForLsm;
                   
                otherwise
                    Summary =       'No meta data for undefined image type available.';
                
            end
            
            
            end
        
            function AtLeastOneTiffReadFailed = notAllFilesCouldBeRead(obj)
                AtLeastOneTiffReadFailed =          ~(min(arrayfun(@(x) x.getFileCouldBeAccessed, obj.myImageDocuments)) == true);
            end

        
        
    end
    
    
    
      
                   
                    
                    
                    
                    
    
    methods (Access = private)
        
        function obj = SetImageDocuments(obj)
                    myWaitBar =                                             waitbar(0.5, 'Mapping image file(s). This can take a few minutes for large files.'); % cannot do a proper waitbar because it is not a loop;
                    
                    switch obj.getFileExtension
                        case {'.tif', '.lsm'}
                              obj.myImageDocuments =                            cellfun(@(x)  PMTIFFDocument(x), obj.getPathsOfImageFiles);
                        
                        case '.czi'
                            obj.myImageDocuments =                              cellfun(@(x)  PMCZIDocument(x), obj.getPathsOfImageFiles);
                      
                        case '.pic'
                             obj.myImageDocuments =                             cellfun(@(x)  PMImageBioRadPicFile(x), obj.getPathsOfImageFiles);
                     
                        otherwise % need to add pic
                            error('Format of image file not supported.')
                   
                    end

                      if isvalid(myWaitBar)
                            close(myWaitBar);
                      end
        end
        
        
        function myPaths = getPathsOfImageFiles(obj)
            myPaths = obj.FilePaths;
            
        end
        
        
        
          function Extension = getFileExtension(obj)
              [~,~,Extensions] =                                      cellfun(@(x) fileparts(x), obj.getPathsOfImageFiles, 'UniformOutput', false);
                Extension =                                             unique(Extensions);
                if isempty(Extension)
                    error('List of extension is empty. No valid files were entered')
                elseif length(Extension)>1
                    error('Distinct extensions in file list. This is not allowed. All files must have the same extension')
                end

             Extension =                                             Extension{1,1};      
          end
          
      
          
        function FileType =                                  getFileType(obj)
            Extension =         obj.getFileExtension;
            switch Extension
                case '.tif'
                    FileType =        'tif';
                case '.lsm'
                    FileType =        'lsm';
                case '.czi'
                    FileType =        'czi';
                case '.pic'
                    FileType =        'unknown';
                otherwise 
                    FileType = '';
            end 
        end
         
          
          
        
          
          function MetaDataFromImage = getMetaData(obj)
               MetaDataFromImage =                 arrayfun(@(x) x.getMetaData, obj.myImageDocuments, 'UniformOutput', false);
              
          end
          
          %% meta data
          
          
         function [metaDataSummary,MetaDataString] =                  getMetaDataForLsm(obj)
             
            if isempty(obj.getPathsOfImageFiles)
                
                metaDataSummary{1,1} = 'Imaging files not connected. Could not retrieve metadata';
                MetaDataString = 'Imaging files not connected. Could not retrieve metadata';
            else
                  fileType =                                  obj.getFileType;
             switch fileType
                case 'lsm' 
                    
                    FirstMovie =                        obj.myImageDocuments{1,1};
                    MetaDataString =                    FirstMovie.getRawMetaData;
                    
                    [lsminf,scaninf,imfinf] =           cellfun(@(x) lsminfo(x), obj.getPathsOfImageFiles, 'UniformOutput',false);
                    metaDataSummary{1,1} =              ['Objective: ', lsminf{1, 1}.ScanInfo.ENTRY_OBJECTIVE];
                    metaDataSummary{2,1}  =              sprintf('Used laser sources (not track-specific):');
                    numberOfLasers =                    length( lsminf{1, 1}.ScanInfo.WAVELENGTH);
                    LaserString =  '';
                    
                    for laserIndex = 1:numberOfLasers
                        if iscell(lsminf{1, 1}.ScanInfo.WAVELENGTH)
                            NumberText = sprintf('%i, ', round(lsminf{1, 1}.ScanInfo.WAVELENGTH{laserIndex}));
                        else
                            NumberText = sprintf('%i, ', round(lsminf{1, 1}.ScanInfo.WAVELENGTH));
                        end
                         LaserString =  [LaserString , NumberText];
                    end
                    
                    LaserString(end-1:end) = [];
                    metaDataSummary  =      [metaDataSummary; LaserString];
                    metaDataSummary =       [metaDataSummary; 'Emission filters for each channel:'];
                    metaDataSummary =       [ metaDataSummary  ;(lsminf{1, 1}.ScanInfo.FILTER_NAME)'];
                    
                 otherwise
                     metaDataSummary = 'Meta data summary currently not supported for this format.';        
             end
                
                
            end
            
          
            
         end
         
        
        
    end
end

