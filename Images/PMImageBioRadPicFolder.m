classdef PMImageBioRadPicFolder
    %  primarily for getting files within pic-folder;
    %   for detailed analysis of files use PMImageBioRadPicFile;
    
    properties
        FolderName % pic file is a folder that contains files with the actual image information;
        FileNameList
        
        
      
        
    end
    
    methods
        
        function obj = PMImageBioRadPicFolder(FolderName)
            %P Construct an instance of this class
            %   Detailed explanation goes here
            
            
            obj. FolderName=                        FolderName;
            obj =                                   obj.getFileNames;
      

        end
        
        
        function pointer = getPointer(obj)
            pointer =                      fopen(obj.FolderName,'r','l');
            
           
            
        end
        
        function obj = getFileNames(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
              %% manual settings: (could not get step-size from meta-data); 
                

                %% read all files in currently selected directory
                SourceDirectory =                       obj.FolderName;
                FilesInCurrentDirectory_Struct=         dir(SourceDirectory);
                FilesInCurrentDirectory_Matrix=         struct2cell(FilesInCurrentDirectory_Struct).';
               

                %% remove all directories (keep only files);
                [IsADirectory] = cellfun(@(x) x==1, FilesInCurrentDirectory_Matrix(:,4));
                FilesInCurrentDirectory_Matrix(IsADirectory,:)=[];

                %% remove all filenames that do not contain ".pic";
                IndexC =            strfind( FilesInCurrentDirectory_Matrix(:,1), '.pic');
                IsNotAPicFile =     cellfun('isempty', IndexC);
                FilesInCurrentDirectory_Matrix(IsNotAPicFile,:)=[];
                
                

                IsASystemFile=                                         cellfun(@(x) (strcmp(x(1,1), '.')), FilesInCurrentDirectory_Matrix(:,1));   
                FilesInCurrentDirectory_Matrix(IsASystemFile,:)=             [];

    
   
                

                %% get positions of all numeric characters in filenames;
                 ShowIfFileNameCharacterIsString_Cell =     isstrprop(FilesInCurrentDirectory_Matrix(:,1), 'digit');
                 ShowIfFileNameCharacterIsString_Matrix=    cell2mat(ShowIfFileNameCharacterIsString_Cell);
                
                 %% assert the "channel" positions (before extension) are numeric:
                 PositionsForChannelCode=                   ShowIfFileNameCharacterIsString_Matrix(:,end-5:end-4);
                 ChannelPositionsAreAllNumerical=           all(PositionsForChannelCode(:));
                 assert(ChannelPositionsAreAllNumerical, 'Filename has wrong format! Check source data.')

                 [~,b,~] =                              fileparts(SourceDirectory);
                 
                 FileNames =                            cellfun(@(x) [b, '/', x], FilesInCurrentDirectory_Matrix(:,1), 'UniformOutput', false);
                 
                  obj.FileNameList =                    FileNames;


        end
        
        
        function FilteredFileNames = filterFileNamesByChannel(obj,ChannelCode)
            
            FilesInCurrentDirectory_Matrix =       obj.FileNameList;
            
            StringOfFiles=                          cell2mat(FilesInCurrentDirectory_Matrix(:,1));
            CodeForChannel=                         StringOfFiles(:,end-4:end-4);

            ListWithStringsToErase=                 CodeForChannel==ChannelCode;
            FilteredFileNames =                     FilesInCurrentDirectory_Matrix(ListWithStringsToErase,:);

        end
        
        
        
        
        
    end
end

