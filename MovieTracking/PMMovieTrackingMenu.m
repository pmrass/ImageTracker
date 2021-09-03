classdef PMMovieTrackingMenu
    %PMMOVIETRACKINGMENU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        
        
    end
    
    properties (Access = private)
        
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
        
        ExportImage
        ExportMovie
        ExportTrackCoordinates
        ShowCompleteMetaData
        ShowMetaDataSummary
    end
    
    methods
        function obj = PMMovieTrackingMenu(MainFigure)
            %PMMOVIETRACKINGMENU Construct an instance of this class
            %   Detailed explanation goes here
            obj.MainFigure = MainFigure;
            obj = obj.createMovieMenu;
            
        end
        
              function obj = setCallbacks(obj, varargin)
             
                NumberOfArguments = length(varargin);
             switch NumberOfArguments
                 case 10
                    obj.MovieSettings.MenuSelectedFcn =                  varargin{1};
                    obj.RenameLinkedMovies.MenuSelectedFcn =             varargin{2};
                    obj.RelinkMovies.MenuSelectedFcn =                    varargin{3};

                    obj.MapSourceFiles.MenuSelectedFcn =                 varargin{4};
                    obj.DeleteImageCache.MenuSelectedFcn =                varargin{5};

                    obj.ExportImage.MenuSelectedFcn =                     varargin{6};
                    obj.ExportMovie.MenuSelectedFcn =                     varargin{7};
                    obj.ExportTrackCoordinates.MenuSelectedFcn =           varargin{8};
                    obj.ShowCompleteMetaData.MenuSelectedFcn =             varargin{9};
                    obj.ShowMetaDataSummary.MenuSelectedFcn =             varargin{10};
                 otherwise
                     error('Wrong input.')
                 
             end
             
         end
        
        
        
    end
    
    methods (Access = private)

         function obj = createMovieMenu(obj)
            
            MainMovieMenu=                            uimenu(obj.MainFigure);
            MainMovieMenu.Label=                      'Movie';

            obj.MovieSettings=                        uimenu(MainMovieMenu);
            obj.MovieSettings.Label=                  'File settings';
            obj.MovieSettings.Tag=                    'MovieSettings';
            obj.MovieSettings.Enable=                 'on';
            
            obj.RenameLinkedMovies=                   uimenu(MainMovieMenu);
            obj.RenameLinkedMovies.Label=             'Rename linke movie files';
            obj.RenameLinkedMovies.Tag=               'Movies_RenameLinkedMovies';
            obj.RenameLinkedMovies.Enable=            'on';
             obj.RenameLinkedMovies.Separator=        'on';
            
            obj.RelinkMovies=                         uimenu(MainMovieMenu);
            obj.RelinkMovies.Label=                   'Relink movies';
            obj.RelinkMovies.Tag=                     'Movies_LinkMovies';
            obj.RelinkMovies.Enable=                  'on';
            
            obj.MapSourceFiles=                       uimenu(MainMovieMenu);
            obj.MapSourceFiles.Label=                 'Remap image files';
            obj.MapSourceFiles.Tag=                   'ReapplySourceFiles';
            obj.MapSourceFiles.Separator=             'on';
            obj.MapSourceFiles.Enable=                'on';

            obj.DeleteImageCache=                     uimenu(MainMovieMenu);
            obj.DeleteImageCache.Label=               'Delete image cache';
            obj.DeleteImageCache.Tag=                 'DeleteImageCache';
            obj.DeleteImageCache.Separator=           'off';
            obj.DeleteImageCache.Enable=              'on';
            
            obj.ExportMovie =                      uimenu(MainMovieMenu);
            obj.ExportMovie.Label=                 'Export active movie into mp4 file';
            obj.ExportMovie.Tag=                   'Movies_ExportMovie';
            obj.ExportMovie.Enable=                'on';
            obj.ExportMovie.Separator=             'on';
            
            obj.ExportImage =                      uimenu(MainMovieMenu);
            obj.ExportImage.Label=                 'Export active image into jpg file';
            obj.ExportImage.Enable=                'on';
            obj.ExportImage.Separator=             'off';
             
            obj.ExportTrackCoordinates=            uimenu(MainMovieMenu);
            obj.ExportTrackCoordinates.Label=      'Export track coodinates into csv file';
            obj.ExportTrackCoordinates.Separator=  'off';
            obj.ExportTrackCoordinates.Enable=     'on';
            
            obj.ShowCompleteMetaData=              uimenu(MainMovieMenu);
            obj.ShowCompleteMetaData.Label=        'Export detailed meta-data into txt file';
            obj.ShowCompleteMetaData.Tag=          'ShowCompleteMetaData';
            obj.ShowCompleteMetaData.Separator=    'off';
            obj.ShowCompleteMetaData.Enable=       'on';

              
            obj.ShowMetaDataSummary=              uimenu(MainMovieMenu);
            obj.ShowMetaDataSummary.Label=        'Show meta-data summary in info text box';
            obj.ShowMetaDataSummary.Separator=    'off';
            obj.ShowMetaDataSummary.Enable=       'on';
              
         end
        
   
        
    end
end

