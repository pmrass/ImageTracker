function [myMovieController] = ReadAndViewImage
%READANDVIEWIMAGE introduction into using PMMovieTracking
%   Detailed explanation goes here
% Use this as way to learn how to use PMMovieTracking;
% Set setpoints at specific locations to learn how specifically this class is working;
% This is just a simple example of how to use PMMovieTracking;
% Once you are familar with this class feel free to use it at your convenience;

% them ain output is myFavoriteMovieObject:
% Of particular interest are:
% ImageMapPerFile: contains information of how to read images from file;
% MetaData: they contain time and spatial dimension;


        %% user adds movie-path and file/folder names;
        PathOfMovieFolder =                                                     '/Volumes/PM57_NewData/PublishedData/2017_NatComm_Lung/Cannon_Raw_BRaIN_BioRAD/BasicCharacterization_BRAIN/';
        FileOrFolderNames =                                                     {'20140926_LPS_Day1_Movie_No1a';'20140926_LPS_Day1_Movie_No1b';'20140926_LPS_Day1_Movie_No1c';'20140926_LPS_Day1_Movie_No1d';''};

        %% user can select channels; (make sure they are not out of range
        ChannelNumberIWantToSee =                                               1;
        FrameNumberIWantToSee =                                                 1;

        
        %% do not change settings below (unless you want to experiment);

        % the function will create a simple PMMovieTracking;
        % and show a maximum proction of selected frame and channel;
        % default settings for creating a simple PMMovieTracking object:

        Version =                                                                   0;
        MovieStructure.AttachedFiles =                                              FileOrFolderNames;
        MovieStructure.NickName =                                                   'MyFavoriteMovie';

        % create simple object            
        myFavoriteMovieObect=                                                       PMMovieTracking(MovieStructure, PathOfMovieFolder, Version); 
        myFavoriteMovieObect =                                                      myFavoriteMovieObect.AddImageMap;

        % create movie viewer;
        MyFigure =                                                                  figure;
        MyAxes =                                                                    axes;
        myMovieViewer =                                                             PMMovieControllerView(MyAxes);
  
        
        % with movie object and movie viewer, create movie controller;
        myMovieController =                                                         PMMovieController(myMovieViewer, myFavoriteMovieObect);
    
        % adjust plane views (in this case get maximum projection);
        myMovieController.LoadedMovie.CollapseAllPlanes   =                         true;    
     
        % indicate what channels should be visible
        myMovieController.LoadedMovie.SelectedChannels(1:myMovieController.LoadedMovie.MetaData.EntireMovie.NumberOfChannels,1) = false;
        myMovieController.LoadedMovie.SelectedChannels(ChannelNumberIWantToSee) =     true;
        
        % update frame number you want to view:
        myMovieController  =                                                        myMovieController.resetFrame( FrameNumberIWantToSee);

        % use the controller to show updated image;
        myMovieController.updateImageView;

       
end