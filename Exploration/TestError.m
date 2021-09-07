function TestError
%TESTMOVIE Summary of this function goes here
%   Detailed explanation goes here
Path = '/Users/paulusmrass/Documents/GitHub/Paul/ImageTracker/Exploration'; % UPDATE FOLDER FOR YOUR SYSTEM

myLib =     PMMovieLibraryManager;
myLib =     myLib.setImageAnalysisPath(Path);
myLib =     myLib.addMovieFolder(Path);
myLib =     myLib.setExportFolder(Path);

          myLib.addNewMovie('NickNameTest', {'TestMovie.czi'});
end


%{

This is the error message that I get when I run this code on my computer:
Unrecognized function or variable 'obj'.


When changing the line 2450 to this code:     obj.Views =     updateMovieViewWith(obj.Views, obj.LoadedMovie, obj.getRbgImage);

the error disappears.

/******* Error message:

Error in PMMovieControllerView/updateMovieViewWith (line 286)
                    obj =     obj.setAnnotationWith(MyMovieTracking);

Error in PMMovieController/initializeViews (line 2450)
                    obj.Views =     obj.Views.updateMovieViewWith(obj.LoadedMovie, obj.getRbgImage);

Error in PMMovieLibrary/getActiveMovieController (line 298)
            myMovieController =     myMovieController.initializeViews;

Error in PMMovieLibraryManager/setActiveMovieByNickName (line 86)
                    obj.ActiveMovieController =             obj.MovieLibrary.getActiveMovieController(obj.Viewer);

Error in PMMovieLibraryManager/addNewMovie (line 296)
                  obj =                             obj.setActiveMovieByNickName(Nickname);

Error in TestError (line 11)
myLib =          myLib.addNewMovie('NickNameTest', {'TestMovie.czi'});
 


%}

