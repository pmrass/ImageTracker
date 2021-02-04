classdef PMMovieTrackingMenu
    %PMMOVIETRACKINGMENU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        MainFigure
        
        MovieSettings
        
        Keyword
        Nickname
        RenameLinkedMovies
        RelinkMovies
        
        MapSourceFiles
        DeleteImageCache
        
        ShowMetaData
        ShowAttachedFiles
        
        ExportMovie
        ExportTrackCoordinates
        ShowCompleteMetaData
        
    end
    
    methods
        function obj = PMMovieTrackingMenu(MainFigure)
            %PMMOVIETRACKINGMENU Construct an instance of this class
            %   Detailed explanation goes here
            obj.MainFigure = MainFigure;
            obj = obj.createMovieMenu;
            
        end
        
         function obj = createMovieMenu(obj)
            
            MainMovieMenu=                                                      uimenu(obj.MainFigure);
            MainMovieMenu.Label=                                                'Movie';

            obj.MovieSettings=                                                   uimenu(MainMovieMenu);
            obj.MovieSettings.Label=                                             'File settings';
            obj.MovieSettings.Tag=                                               'MovieSettings';
            obj.MovieSettings.Enable=                                            'on';
            
           
            
            
            obj.RenameLinkedMovies=                                                   uimenu(MainMovieMenu);
            obj.RenameLinkedMovies.Label=                                             'Rename linke movie files';
            obj.RenameLinkedMovies.Tag=                                               'Movies_RenameLinkedMovies';
            obj.RenameLinkedMovies.Enable=                                            'on';
             obj.RenameLinkedMovies.Separator=                                              'on';
            
            
            obj.RelinkMovies=                                                   uimenu(MainMovieMenu);
            obj.RelinkMovies.Label=                                             'Relink movies';
            obj.RelinkMovies.Tag=                                               'Movies_LinkMovies';
            obj.RelinkMovies.Enable=                                            'on';
            
            obj.MapSourceFiles=                                        uimenu(MainMovieMenu);
            obj.MapSourceFiles.Label=                                  'Remap image files';
            obj.MapSourceFiles.Tag=                                    'ReapplySourceFiles';
            obj.MapSourceFiles.Separator=                              'on';
            obj.MapSourceFiles.Enable=                                 'on';

            obj.DeleteImageCache=                                          uimenu(MainMovieMenu);
            obj.DeleteImageCache.Label=                                    'Delete image cache';
            obj.DeleteImageCache.Tag=                                      'DeleteImageCache';
            obj.DeleteImageCache.Separator=                                'off';
            obj.DeleteImageCache.Enable=                                   'on';
            
           
            % access movie file
            
         
        
            
            %%
            
         
            obj.ExportMovie =                                                  uimenu(MainMovieMenu);
            obj.ExportMovie.Label=                                             'Export active movie into mp4 file';
            obj.ExportMovie.Tag=                                               'Movies_ExportMovie';
            obj.ExportMovie.Enable=                                             'on';
            obj.ExportMovie.Separator=                                        'on';
             
              
            obj.ExportTrackCoordinates=                                   uimenu(MainMovieMenu);
            obj.ExportTrackCoordinates.Label=                             'Export track coodinates into csv file';
            obj.ExportTrackCoordinates.Separator=                         'off';
            obj.ExportTrackCoordinates.Enable=                            'on';
            
            obj.ShowCompleteMetaData=                                              uimenu(MainMovieMenu);
            obj.ShowCompleteMetaData.Label=                                        'Export complete meta-data into txt file';
            obj.ShowCompleteMetaData.Tag=                                          'ShowCompleteMetaData';
            obj.ShowCompleteMetaData.Separator=                                    'off';
            obj.ShowCompleteMetaData.Enable=                                       'on';

            

            
        end
        
        
    end
end

