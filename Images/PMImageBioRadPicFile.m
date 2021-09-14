classdef PMImageBioRadPicFile
    %PMIMAGEBIORADPICFILE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        FileName 
        
        
        ParentFolder
        PicFolderContent
        TimeStampText
        StartTime_Sec
        
        TotalNumberOfChannels % of all files in relevant folder
        ChannelNumber % of current
        
        TotalNumberOfFrames % of all files in relevant folder
        FrameNumber % of current file
        
       
        
        
        
    end
    
    properties (Access = private)
        
        FilePointer
        
         PicMetaData
        CollectedNotes
        
        MetaData
        ImageMap
    end
    
    methods
        function obj = PMImageBioRadPicFile(FileName)
            %PMIMAGEBIORADPICFILE Construct an instance of this class
            %   Detailed explanation goes here
            
            fprintf('@Create PMImageBioRadPicFile for file %s.\n', FileName)
            
            obj.FileName = FileName;
            
               obj.FilePointer =                                   fopen(FileName,'r','l');
 
            if obj.FilePointer == -1
                return
            end
            
            [obj.ParentFolder, ~, ~]  =  fileparts(FileName);
            
            obj.PicFolderContent =          PMImageBioRadPicFolder(obj.ParentFolder);
              
            obj.TotalNumberOfChannels =      max(obj.getChannelCodes);    
            obj.TotalNumberOfFrames =        max(obj.getFrameCodes);
            
            obj.ChannelNumber =             obj.getChannelCode(obj.FileName);
            obj.FrameNumber =               obj.getFrameCode(obj.FileName);
            
            obj =                          obj.CreateImageMap;
            obj.MetaData =                                          obj.CreateMetaData;
            
          
            
            
        end
        
         function metaData = getMetaData(obj)
            metaData = obj.MetaData;
        end
        
        function imageMap = getImageMap(obj)
            imageMap = obj.ImageMap;
        end
        
        
      
          
          function MetaData =                                          CreateMetaData(obj)
              
                function PixelSize = getPixelSize(CollectedMetaNotes, Code) % for extracting pixel size
                  
                    RowWithX =                      cellfun(@(x) contains(x, Code), CollectedMetaNotes);
                    XData =                         CollectedMetaNotes{RowWithX,1};
                    XData =                         split(XData);
                    PixelSize =                    str2double(XData{4})*1e-6;

              end
                InternalMetaData =                                                  obj.PicMetaData;
                MetaData.EntireMovie.NumberOfRows=                                  obj.PicMetaData.Height; 
                MetaData.EntireMovie.NumberOfColumns=                               obj.PicMetaData.Width; 
                MetaData.EntireMovie.NumberOfPlanes=                                obj.PicMetaData.NumImages; 
                MetaData.EntireMovie.NumberOfTimePoints=                            1; % this is for current file only: after combining multiple files this number will be adjusted accordingly
                MetaData.EntireMovie.NumberOfChannels=                              obj.TotalNumberOfChannels; 

              
                
                MetaData.EntireMovie.VoxelSizeX=                                    getPixelSize(obj.CollectedNotes, 'AXIS_2'); 
                MetaData.EntireMovie.VoxelSizeY=                                    getPixelSize(obj.CollectedNotes, 'AXIS_3');
                MetaData.EntireMovie.VoxelSizeZ=                                    -getPixelSize(obj.CollectedNotes, 'AXIS_4');

                
                TimeDelay =             obj.getDelayForCapturingFrame(obj.FrameNumber);
               
                AbsoluteTime =              obj.StartTime_Sec + TimeDelay;
                MetaData.TimeStamp =                                                AbsoluteTime;

                MetaData.RelativeTimeStamp =                                        MetaData.TimeStamp- MetaData.TimeStamp(1);

           
              
          end
          
          
          function TimeStampText = getTimeStampText(obj)
              
              
                CompleteFileNameMetaData=               strcat(obj.ParentFolder, '/lse.xml');
                assert(exist(CompleteFileNameMetaData, 'file')==2, 'Meta data missing!')
                TimeStampText=                          fileread(CompleteFileNameMetaData);

              
              
              
          end
          
          function StartTime_Seconds = getStartTime(obj)
              
                  
              function [ Seconds ] = ConvertHourMinuteSecondsToSeconds( String )
                %CONVERTHOURMINUTESECONDSTOSECONDS Summary of this function goes here
                %   Detailed explanation goes here

                    SecondsFromHours=      str2double(String(1:2))*60*60;
                    SecondsFromMinutes=    str2double(String(4:5))*60;
                    SecondsFromSeconds=    str2double(String(7:8));

                    Seconds=SecondsFromHours+ SecondsFromMinutes+SecondsFromSeconds;

              end
              
                PositionOfCreationDate=                  strfind( obj.TimeStampText, '<CreationDate>');
                PositionOfCreationDate=                  PositionOfCreationDate(1)+length('<CreationDate>')-1;
                CreationDateString=                      obj.TimeStampText(PositionOfCreationDate+1:PositionOfCreationDate+19);

                DaysAfterAD_ExperimentStart=            datenum(CreationDateString(1:10),'yyyy-mm-dd');
                [StartOfExperiment_Seconds]=            ConvertHourMinuteSecondsToSeconds(CreationDateString(12:end));
                StartTime_Seconds=              StartOfExperiment_Seconds+DaysAfterAD_ExperimentStart*24*60*60;

              
          end
          
          function TimeSeconds = getDelayForCapturingFrame(obj,FrameNumber)
              
              StartOfTPosition =        sprintf('<T Section="%i"', FrameNumber-1);
              
              StartOfSectionOfInterest=                   strfind( obj.TimeStampText, StartOfTPosition);
              
              TextSection =                 obj.TimeStampText(StartOfSectionOfInterest:end);
              
              
              TimeGaps =                strfind(TextSection, 'TimeCompleted="');
              
              TextStartinAtWantedTime = TextSection(TimeGaps(1)+length('TimeCompleted="'):end);
              
              EndPositions =                strfind(TextStartinAtWantedTime, '"');
              
              TimeSeconds = str2double(TextStartinAtWantedTime(1:EndPositions-1));
              
          end
        
          
           function channelCode =    getChannelCode(obj, FileName)
            
                    [a,b,c] =                         fileparts( FileName);
                    name = [b c];
                    channelCode=                         str2double(name(1,end-5:end-4));
            
           end
        
           function channelCodes =  getChannelCodes(obj)
               
               myFileNameList =       obj.PicFolderContent.FileNameList;
               
               channelCodes =       cellfun(@(x) obj.getChannelCode(x), myFileNameList);
               
               
           end
           
           
            function channelCode =    getFrameCode(obj, FileName)
            
                    [a,b,c] =                         fileparts( FileName);
                    name = [b c];
                    channelCode=                         str2double(name(1,end-8:end-6));
            
           end
        
           function channelCodes =  getFrameCodes(obj)
               
               myFileNameList =       obj.PicFolderContent.FileNameList;
               
               channelCodes =       cellfun(@(x) obj.getFrameCode(x), myFileNameList);
               
               
           end
       
         function value = getFileCouldBeAccessed(obj)
            value =         obj.getPointer ~= -1;
        end
        
    end
    
    methods (Access = private)
        
        function pointer = getPointer(obj)
            pointer = fopen(obj.FileName,'r','l');    
        end 
        
        
          function obj =      CreateImageMap(obj)
            
             % get metadata and images for each file:
                obj.PicMetaData =                   impicinfo(obj.FileName);

                obj.CollectedNotes =                (cellfun(@(x) x.text, obj.PicMetaData.Note, 'UniformOutput', false))';

                obj.TimeStampText =                 getTimeStampText(obj);
                 obj.StartTime_Sec =                                                 obj.getStartTime;
            
                ImageVolume =                       readpic(obj.FileName);

                ByteOrder =                         'ieee-le';
             

                CurrentImage =                      max(ImageVolume, [], 3);

                ImageIndex =                        1;
                
                imagesc(CurrentImage)

                OffsetForData =                     76; % always 76
                
                BitsPerSample =                     obj.PicMetaData.BitDepth;
                SamplesPerPixel =                   1; % each channel has its own file;
                PixelType =                         obj.PicMetaData.ColorType;

                NumberOfPlanes =                    obj.PicMetaData.NumImages; % number of images equals number of planes
                NumberOfRows =                      obj.PicMetaData.Height;
                NumberOfColumns =                   obj.PicMetaData.Width;
                NumberOfFrames =                    1; % each file contains data from one time point; 

                DataSize =                      NumberOfRows* NumberOfColumns*NumberOfPlanes;
                
                TargetFrames =                  1; % for single image: this needs to be later adjusted when multiple images are connected;
                TargetPlanes =                  1:NumberOfPlanes;

                TargetChannelIndex =                    obj.getChannelCode(obj.FileName); 
                
                assert(strcmp(PixelType, 'grayscale') && BitsPerSample == 8, 'Data format not supported')

                Precision =             'uint8';
                
                ImageMapInternal =              cell(2,15);
                
                ImageMapInternal(1,:) =      {'ListWithStripOffsets','ListWithStripByteCounts','FilePointer',... % 1-3
                'ByteOrder','BitsPerSample','Precisision','SamplesPerPixel',... % 4-7
                'TotcalColumnsOfImage','TotalRowsOfImage',... % 8-9
                'TargetFrameNumber','TargetPlaneNumber','RowsPerStrip','TargetStartRows','TargetEndRows','TargetChannelIndex'}; % 10-15
       
            
                ImageMapInternal{ImageIndex+1,1} =   OffsetForData;
                ImageMapInternal{ImageIndex+1,2} =   DataSize;

                ImageMapInternal{ImageIndex+1,4} =   ByteOrder;
                ImageMapInternal{ImageIndex+1,5} =   BitsPerSample;
                ImageMapInternal{ImageIndex+1,6} =   Precision;
                ImageMapInternal{ImageIndex+1,7} =   SamplesPerPixel;

                ImageMapInternal{ImageIndex+1,8} =   NumberOfColumns;
                ImageMapInternal{ImageIndex+1,9} =   NumberOfRows;

                ImageMapInternal{ImageIndex+1,10} =   TargetFrames;
                ImageMapInternal{ImageIndex+1,11} =   TargetPlanes;

                ImageMapInternal{ImageIndex+1,12} =   NumberOfRows; %strip information (only one strip);
                ImageMapInternal{ImageIndex+1,13} =   1;
                ImageMapInternal{ImageIndex+1,14} =   NumberOfRows;
                ImageMapInternal{ImageIndex+1,15} =   TargetChannelIndex;

                obj.ImageMap =  ImageMapInternal;

          end
          
          
        
    end
end

