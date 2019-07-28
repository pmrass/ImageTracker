classdef PMMovieLibrary
    %PMMOVIELIBRARY manage movies for tracking analysis
    %   Detailed explanation goes here
    
    properties
        
        Version =                                   3;
        FileName
        FileCouldNotBeLoaded =                      1;
        UnsupportedVersion =                        1;
        
        PathOfMovieFolder
        PathForExport
        
        ListhWithMovieObjects =                     cell(0,1);
        
        SelectedKeywords =                          ''
        SelectedNickname =                          ''
        ListWithFilteredNicknames
        
        
        FilterSelectionIndex =                      1;
        FilterSelectionString =                     ''
        FilterList =                                true
        SortIndex =                                 1;
        
    end
    
    methods
        
     
        
        function obj = PMMovieLibrary(FileNameForLoadingNewObject)
            
            
            %% attempt to load and update load status:
            if exist(FileNameForLoadingNewObject)~=2
                return
                   
            end
            
            
            load(FileNameForLoadingNewObject, 'ImagingProject');
            obj.FileCouldNotBeLoaded =              0;

            
            %% get version:
            if ~strcmp(class(ImagingProject), 'PMMovieLibrary')
                obj.Version = 2;
  
            else
                obj.Version = ImagingProject.Version;

            end
            
            %% load file and/or update version status:
            switch obj.Version
                
                case 2
                    
                    obj.UnsupportedVersion =            0;
                    
                    obj.FileName =                      ImagingProject.Files_ProjectName;
                    obj =                               obj.convertVersionTwoToThree(ImagingProject);
                    obj.Version =                       3;
                    OldFilename =                       obj.FileName;
                    NewFilename =                       [OldFilename(1:end-4) '_Version3.mat'];
                    obj.FileName =                      NewFilename; % now the file will be saved as version 3, but with a new filename do prevent overwriteing
                    obj =                               obj.createFilterByKeywords;
             
                    if size(obj.ListWithFilteredNicknames,1) >= 1
                        obj.SelectedNickname=               obj.ListWithFilteredNicknames{1, 1};
                    end
                    
                case 3 % this is the current version: just read the file directly, that's it; no parsing required;
                    
                    obj = ImagingProject;
                    
                    
                otherwise
                    
                    
                    obj = [];
                    
                
            end
            
          
            
        end
        
     
        function [obj] =                sortByNickName(obj)
            
            
            
            AllNicknames =      cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            
            
            obj.ListhWithMovieObjects(:,2) =            AllNicknames;
            
            obj.ListhWithMovieObjects =         sortrows(obj.ListhWithMovieObjects, 2);
            
            
             obj.ListhWithMovieObjects(:,2) =       [];
            
            
        end
        
        
       
        
        function [Selection, obj] =     selectMovieObject(obj, NickName)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            MyListhWithMovieObjects =           obj.ListhWithMovieObjects;
            ListWithNickNames =                 cellfun(@(x) x.NickName, MyListhWithMovieObjects, 'UniformOutput', false);
            MatchingNickNameRow =               strcmp(ListWithNickNames, NickName);           
            Selection =                         MyListhWithMovieObjects{MatchingNickNameRow,1};
            obj.SelectedMovieObject  =            Selection;
            
        end
        
        function KeywordList =          getKeyWordList(obj)
            
                if isempty(obj.ListhWithMovieObjects)
                    KeywordList =       cell(0,1);
                    return
                end
            
                ListWithKeywords =                  cellfun(@(x) x.Keywords, obj.ListhWithMovieObjects, 'UniformOutput', false);
              
                FinalList =                         (vertcat([ListWithKeywords{:}]))';
                EmptyRows=                          cellfun(@(x) isempty(x),FinalList);
                FinalList(EmptyRows,:)=             [];      
                KeywordList=                        unique(FinalList);

        end
        
        function [obj] =                createFilterForEntireContent(obj)
            
            obj.FilterList =                        cellfun(@(x) true, obj.ListhWithMovieObjects);             
            obj.ListWithFilteredNicknames=          cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
        
            
        end
        
        
        function [obj] =                createFilterForAllMovies(obj)
            
            
            SomeMetaDataMissing =       max(cellfun(@(x) isempty(x.MetaData), obj.ListhWithMovieObjects));
            
            if SomeMetaDataMissing
                return
                
            end
            
            ListWithNumberOfPlanes =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfPlanes, obj.ListhWithMovieObjects);
            ListWithNumberOfFrames =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfTimePoints, obj.ListhWithMovieObjects);
                                   
            obj.FilterList =                    ListWithNumberOfFrames >= 2;
            ListWithAllNickNames =              cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=      ListWithAllNickNames(obj.FilterList,:);
         

        end
        
        function [obj] =                createFilterForAllZStacks(obj)
            
            
             SomeMetaDataMissing =       max(cellfun(@(x) isempty(x.MetaData), obj.ListhWithMovieObjects));
            
            if SomeMetaDataMissing
                return
                
            end
            
            
            ListWithNumberOfPlanes =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfPlanes, obj.ListhWithMovieObjects);
            ListWithNumberOfFrames =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfTimePoints, obj.ListhWithMovieObjects);
            
            IsStack =                           min([ ListWithNumberOfPlanes >= 2,  ListWithNumberOfFrames == 1], [], 2);             
            obj.FilterList =                    IsStack;
            ListWithAllNickNames =              cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=      ListWithAllNickNames(obj.FilterList,:);
          
            
        end
        
        function [obj] =                createFilterForAllSnapshots(obj)
            
            
             SomeMetaDataMissing =       max(cellfun(@(x) isempty(x.MetaData), obj.ListhWithMovieObjects));
            
            if SomeMetaDataMissing
                return
                
            end
            
            
             ListWithNumberOfPlanes =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfPlanes, obj.ListhWithMovieObjects);
            ListWithNumberOfFrames =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfTimePoints, obj.ListhWithMovieObjects);
            
            IsStack =                           min([ ListWithNumberOfPlanes == 1,  ListWithNumberOfFrames == 1], [], 2);             
            obj.FilterList =                    IsStack;
            ListWithAllNickNames =              cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=      ListWithAllNickNames(obj.FilterList,:);
          
            
        end
        
        function [obj] =                createFilterForAllUnmappedMovies(obj)
            
            
            MetaDataContent =                       cellfun(@(x) x.MetaData, obj.ListhWithMovieObjects, 'UniformOutput', false);
            NoMappingData =                         cellfun(@(x) isempty(x), MetaDataContent);
            
            obj.FilterList =                        NoMappingData;
            
            ListWithAllNickNames =                  cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=          ListWithAllNickNames(obj.FilterList,:);
       
          
            
            
        end
       
                      
                  
        function [obj] =               createFilterForAllTrackedMovies(obj)
            

            TrackingWasPerformed =              cellfun(@(x) x.Tracking.NumberOfTracks >=1, obj.ListhWithMovieObjects);
            obj.FilterList =                    TrackingWasPerformed;
            ListWithAllNickNames =              cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=      ListWithAllNickNames(obj.FilterList,:);
     
            
        end
        
        
        
        function [obj] =                createFilterByKeywords(obj)
            
            SelectedKeyword =                                           obj.SelectedKeywords;
            
            if ~isempty(SelectedKeyword)
                obj.FilterList =                                            logical(cellfun(@(x) max(strcmp(x.Keywords, SelectedKeyword)), obj.ListhWithMovieObjects));
            else
                obj.FilterList(1:size(obj.ListhWithMovieObjects,1),1)=      true;
            end
            
                ListWithAllNickNames =              cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
                obj.ListWithFilteredNicknames=      ListWithAllNickNames(obj.FilterList,:);
           

            
        end
        
        
        function [obj] =            createFilterForAllMoviesWithDriftCorrection(obj)
            
            obj.FilterList =                    cellfun(@(x) x.DriftCorrection.testForExistenceOfDriftCorrection, obj.ListhWithMovieObjects);
            ListWithAllNickNames =              cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=      ListWithAllNickNames(obj.FilterList,:);
             
        end
        
        function [obj] =        createFilterForInAccurateChannelInformation(obj)
            
            
            
            NoMetaData =                            cellfun(@(x) isempty(x.MetaData), obj.ListhWithMovieObjects);
            
            ListWithChannelNumbers(~NoMetaData,1) =              cellfun(@(x) x.MetaData.EntireMovie.NumberOfChannels, obj.ListhWithMovieObjects(~NoMetaData,1));
            ChannelsAreOK(~NoMetaData,1) =                       cellfun(@(x,y) x.verifyChannels(y), obj.ListhWithMovieObjects(~NoMetaData,1), num2cell(ListWithChannelNumbers(~NoMetaData,1)));
           
            MetaDataAndChannelsAreOk =                          min([~NoMetaData ChannelsAreOK], [], 2);
            
            obj.FilterList =                        ~MetaDataAndChannelsAreOk;
            
            ListWithAllNickNames =                  cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);
            obj.ListWithFilteredNicknames=          ListWithAllNickNames(obj.FilterList,:);
          
            
            
            
        end
        
        
        
        
        function [obj] =            updateFilterSettingsFromPopupMenu(obj,PopupMenu)
            
                if ischar(PopupMenu.String)
                    SelectedString =  PopupMenu.String;
                else
                    SelectedString = PopupMenu.String{PopupMenu.Value};                                           
                end
                
                obj.FilterSelectionIndex =             PopupMenu.Value;
                obj.FilterSelectionString =            SelectedString;
                
                obj =                                  obj.updateFilterList;
            
            
            
        end
        
        function [obj] =            updateFilterList(obj)
            
            
                     
                      
            SelectedString =        obj.FilterSelectionString;
            
              switch SelectedString
                    
                  case 'Show all movies'
                      obj =                                 obj.createFilterForAllMovies;
                      
                  case 'Show all Z-stacks'
                      obj =                                 obj.createFilterForAllZStacks;
                  case 'Show all snapshots'
                       obj =                                 obj.createFilterForAllSnapshots;     
                 case 'Show all tracked movies'
                     obj =                                 obj.createFilterForAllTrackedMovies;

                 case 'Show all movies with drift correction'    
                     obj =                                 obj.createFilterForAllMoviesWithDriftCorrection;
                     
                 case 'Show entire content'
                        obj =                              obj.createFilterForEntireContent;
                        
                        
                  case 'Show all unmapped movies'
                        obj =                               obj.createFilterForAllUnmappedMovies;
                        
                  case 'Show content with non-matching channel information'
                      obj =                               obj.createFilterForInAccurateChannelInformation;
                      
                 otherwise
                        obj.SelectedKeywords =             SelectedString;
                        obj =                              obj.createFilterByKeywords;

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
        
        
        %% helper functions:
        function [SelectedRow] = getSelectedRowInLibrary(obj)
            ListWithAllNickNames =      cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);   
            SelectedRow =               strcmp(ListWithAllNickNames, obj.SelectedNickname);

        end
        
        function [SelectedRow] = getSelectedRowInLibraryOf(obj,NickNameString)
            ListWithAllNickNames =      cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);   
            SelectedRow =               strcmp(ListWithAllNickNames, NickNameString);

        end
        
        
        function [NickNames] =  getAllNicknames(obj)
            
            
             NickNames =                        cellfun(@(x) x.NickName, obj.ListhWithMovieObjects, 'UniformOutput', false);      
            
        end
        
        function [Movie] = getMovieWithNickName(obj, Nickname)
            
            
            Nicknames =         obj.getAllNicknames;
            Row =               strcmp(Nicknames,Nickname);
            Movie  =            obj.ListhWithMovieObjects{Row};
            
        end
        
        
    end
end

