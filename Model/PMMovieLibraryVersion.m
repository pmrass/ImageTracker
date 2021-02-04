classdef PMMovieLibraryVersion
    %PMMOVIELIBRARYVERSION for version conversion
    %   copied and pasted from PMMovieLibrary: not functional right now;
    
    properties
        Property1
    end
    
    methods
        function obj = PMMovieLibraryVersion(inputArg1,inputArg2)
            %PMMOVIELIBRARYVERSION Construct an instance of this class
            %   Detailed explanation goes here
            
            switch obj.Version
                
             case 2
                        obj.UnsupportedVersion =            0;

                        obj.FileName =                      ImagingProject.Files_ProjectName;
                        obj.FileName =                      FileNameForLoadingNewObject;

                        obj =                               obj.convertVersionTwoToThree(ImagingProject);
                        obj.Version =                       3;
                        OldFilename =                       obj.FileName;
                        NewFilename =                       [OldFilename(1:end-4) '_Version3.mat'];
                        obj.FileName =                      NewFilename; % now the file will be saved as version 3, but with a new filename do prevent overwriteing

                        if size(obj.ListWithFilteredNicknames,1) >= 1
                            obj.SelectedNickname=               obj.ListWithFilteredNicknames{1, 1};
                        end

                    case 3 % 
                         obj =   ImagingProject;
                         obj.FileName =                     FileNameForLoadingNewObject;
                         obj =                              obj.convertVersionThreeToFour;
                case 4
                    fprinf('The version is up to date. No actions taken.')
                         
            end
        end
        
          function [obj] =                convertVersionTwoToThree(obj,ImagingProject)
            obj.PathOfMovieFolder =             ImagingProject.Files_MovieFolder;
            obj.PathForExport =                 ImagingProject.Files_DataExport;
            NumberOfMovies =                    size(ImagingProject.ListWithMovies,1);
            obj.ListhWithMovieObjects =         cell(NumberOfMovies,1);
            for MovieIndex=1:NumberOfMovies
                MovieStructure =                                ImagingProject.ListWithMovies(MovieIndex,1);
                obj.ListhWithMovieObjects{MovieIndex,1} =       PMMovieTracking(MovieStructure, ImagingProject.Files_MovieFolder, obj.Version);    
            end
        end

        function [obj] =                convertVersionThreeToFour(obj) 
            MainFolder =                                            obj.getMainFolder;
            numberOfMovies =                                        size(obj.ListhWithMovieObjects,1);
            for MovieIndex=1:numberOfMovies
                CurrentMovieObject =                                obj.ListhWithMovieObjects{MovieIndex,1};
                %CurrentMovieObject.Folder =                         MainFolder;
                CurrentMovieObject.FolderAnnotation =               MainFolder;
                CurrentMovieObjectSummary =                         PMMovieTrackingSummary(CurrentMovieObject);
                obj.ListWithMovieObjectSummary{MovieIndex,1} =      CurrentMovieObjectSummary;
                CurrentMovieObject.saveMovieData
            end
            
            obj.Version = 4;
            obj =                   obj.addPostFixToFileName('_Version4');
            obj =                   obj.saveMovieLibraryToFile;
            
        end
        
        
    end
end

