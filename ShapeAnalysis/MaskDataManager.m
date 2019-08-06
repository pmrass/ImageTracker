classdef MaskDataManager
    %Author, Rishi Tikare Yan: Judy Cannons Lab, with Paulus Mrass
    %This Class was created to create lists of Cell-Masks for analysis.
    %Outputs Cell arrays containing Masks, and is originally inteneded to
    %be used with a PMMovieLibrary file and the output to be fed to
    %MotilityAnalyzer
    
    properties
        MovieLibrary
        Movie = 46;%46 is just a movie I know had tracks for development
        Frame = 1; 
    end
    
    methods
        function obj = MaskDataManager(PMMovieLibrary)
            %Class requires a PMMovieLibrary
            obj.MovieLibrary = PMMovieLibrary;
        end
        
        function obj = SetMovie(mov)
            %set current movie
            %the movie number is for PMMovieLibrary
            %sets movie to corresponding movie in ListWithMovieObjects 
            obj.Movie = mov;
        end
        function obj = SetFrame(fr)
            %set current frame
            %the frame number is for PMMovieLibrary
            %sets frame to corresponding frame in movie
            obj.Frame = fr;
        end
        function obj = SetMovieLibrary(lib)
            %set current Library
            obj.MovieLibrary = lib;
        end
        
        function [MaskList,CentroidList] = GetMaskDataOfFrame(obj)
            %Returns a cell array of masks and array of Centroids
            %Gets all masks/centroids of a single frame
            MaskDataAtFrame = obj.MovieLibrary.ListhWithMovieObjects{obj.Movie,1}.Tracking.TrackingCellForTime{obj.Frame,1};
            MaskList = MaskDataAtFrame(:,6);
            yList = cell2mat(MaskDataAtFrame(:,3));
            xList = cell2mat(MaskDataAtFrame(:,4));
            zList = cell2mat(MaskDataAtFrame(:,5));
            CentroidList = [xList,yList,zList];
        end
        function [MaskList,CentroidList] = GetMaskDataOfCellOverMovie(obj, CellID)
            %Gets all masks/centroids of a single track over an entire movie
            %Returns a cell array of masks and number array of Centroids
            
            testrow = MaskDataManager.GetRowOfCell(CellID, obj.Frame, obj.Movie, obj.MovieLibrary);
             if isempty(testrow)
                 MaskList = [];
                 CentroidList = [];
                 return
             end
            ListOfFrames = obj.MovieLibrary.ListhWithMovieObjects{obj.Movie,1}.Tracking.TrackingCellForTime;
            
            CentroidList = zeros(size(ListOfFrames,1),3);
            MaskList = cell(size(ListOfFrames,1), 1);
            for i = 1:size(ListOfFrames,1)
                row = MaskDataManager.GetRowOfCell(CellID, obj.Frame, obj.Movie, obj.MovieLibrary);
                MaskList{i,1} = ListOfFrames{i,1}{row,6};
                
                CentroidList(i,1) = cell2mat(ListOfFrames{i,1}(row,4));%xcor
                CentroidList(i,2) = cell2mat(ListOfFrames{i,1}(row,3));%ycor
                CentroidList(i,3) = cell2mat(ListOfFrames{i,1}(row,5));%zcor
            end
        end
    end
    methods(Static)
        function row = GetRowOfCell(ID, Frame, Movie, PMMovieLibrary)
            %returns row of a cell with a certain Track-ID in the 
            %current-frame of the current-movie
            MaskDataAtFrame = PMMovieLibrary.ListhWithMovieObjects{Movie,1}.Tracking.TrackingCellForTime{Frame,1};
            ar = cell2mat(MaskDataAtFrame(:,1));
            row = find((ar == ID));
            
        end
        
    
    end
end

