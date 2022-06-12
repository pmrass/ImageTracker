classdef PMImagingProjectViewer
    %PMIMAGINGPROJECTVIEWER for viewing and editing movie library (PMMovieLibrary) and associated movies;
    %   allows creation and updating of view, works together with PMMovieLibraryManager;
    
    properties (Access = private)
        
        Figure
        ProjectAxes
        ProjectViews
        TrackingViews
        InfoView
        TagForKeywordEditor =           'PMImagingProject_EditKeywordsViewer'

    end
    
    properties (Access = private) % menus:

        FileMenu
        ProjectMenu
        MovieMenu
        DriftMenu
        TrackingMenu
        InteractionsMenu
        HelpMenu

    end

    properties (Constant, Access = private)
        
        StartRowNavigation =            1;
        StartRowChannels =              0.77;
        StartRowAnnotation =            0.65;  
        StartRowTracking =              0.47;
        RowShift =                      0.03;
        
        LeftColumn =                    0.8;
        ColumnShift =                   0.11;
        WidthOfFirstColumn =            0.1;
        WidthOfSecondColumn =           0.08;
        ViewHeight =                    0.02;
        
         WidthOfProjectViews =           0.2; 
        LeftPositionOfProjectViews =    0.01;
     
        ProjectFilterList =              {'Show all movies'; 'Show all Z-stacks'; 'Show all snapshots'; 'Show all movies with drift correction'; 'Show all tracked movies'; 'Show all untracked movies'; 'Show entire content';  'Show all unmapped movies'}; 
    
        AvailableMenus =                {   'FileMenu', 'ProjectMenu', 'MovieMenu', 'DriftMenu', 'TrackingMenu', 'InteractionsMenu', 'HelpMenu'};
          
    end
    
    
    methods % initialize:
        
          function obj =           PMImagingProjectViewer(varargin)
                %PROJECTWINDOW_CREATEWINDOW Summary of this function goes here
                %   takes 0 arguments;
                switch length(varargin)
                    case 0
                          

                    otherwise
                        error('Wrong input.')
                    
                end

          end
        
    end
    
    methods % setters for callbacks

        function obj = setCallbacks(obj, varargin)
            % SETCALLBACKS sets callbacks for key- and mouse activity, and for filter-, sort-, and movielist- guis; 
            % takes 8 arguments:
            % 1: keypress
            % 2: button down
            % 3: button up
            % 4: button motion
            % 5: filter
            % 6: keywords filter
            % 7: sort
            % 8: movie-list

            switch length(varargin)

                case 8

                    if ~isempty( obj.Figure) && isvalid( obj.Figure)
                        obj.Figure.WindowKeyPressFcn =                          varargin{1};
                        obj.Figure.WindowButtonDownFcn =                         varargin{2};
                        obj.Figure.WindowButtonUpFcn =                           varargin{3};
                        obj.Figure.WindowButtonMotionFcn =                       varargin{4};

                        obj.ProjectViews.FilterForKeywords.Callback =            varargin{5};
                        obj.ProjectViews.RealFilterForKeywords.Callback =        varargin{6};
                        obj.ProjectViews.SortMovies.Callback =                   varargin{7};
                        obj.ProjectViews.ListOfMoviesInProject.Callback =        varargin{8};
                    
                    end

                otherwise
                    error('Wrong input.')


            end

        end

    end

    methods % set menus
        
        function set = MenusAlreadySet(obj)
            
            if isempty(obj.FileMenu)
                set = false;
            else
                set = ~isempty(obj.FileMenu.Main) && isvalid(obj.FileMenu.Main);
            end
           
               
        end
        
        function obj = setMenu(obj, varargin)
            % SETMENU this creates and specifies a new menu;
            % 4 or 5 arguments:
            % 1: name of main menu: must match list of allowed menu options;
            % 2: tag of main menu:
            % 3: list of "sub-menu" labels
            % 4: list of callbacks for each "sub-menu"
            % 5: list of separators ("on", "off", for each "sub-menu")

            
            
            switch length(varargin)

                case 4
                    MainMenuName =  varargin{1};
                    MainMenuLabel = varargin{2};
                    MenuLabels =    varargin{3};
                    MyCallbacks =   varargin{4};
                    SeparatorList = repmat({'off'}, length(MenuLabels), 1);

                case 5
                    MainMenuName =  varargin{1};
                    MainMenuLabel = varargin{2};
                    MenuLabels =    varargin{3};
                    MyCallbacks =   varargin{4};
                    SeparatorList = varargin{5};

                otherwise
                    error('Wrong input')




            end



            obj = obj.verifyMenuName(MainMenuName);
            assert(ischar(MainMenuLabel), 'Wrong input.')
            assert(isvector(MenuLabels) && iscellstr(MenuLabels), 'Wrong input.')
            assert(isvector(MyCallbacks) && iscell(MyCallbacks), 'Wrong input.')
            assert(isvector(SeparatorList) && iscellstr(SeparatorList), 'Wrong input.')
            assert(length(MenuLabels) == length(MyCallbacks), 'Wrong input.')
            assert(length(MenuLabels) == length(SeparatorList), 'Wrong input.')


            obj.(MainMenuName).Main=            uimenu(obj.Figure);
            obj.(MainMenuName).Main.Label=      MainMenuLabel;

            for index = 1 : length(MenuLabels)
                 Name = ['Menu', num2str(index)];
                obj.(MainMenuName).(Name) =                     uimenu(obj.(MainMenuName).Main);
                obj.(MainMenuName).(Name).Label =               MenuLabels{index};
                obj.(MainMenuName).(Name).Enable =              'on';
                obj.(MainMenuName).(Name).Separator=            SeparatorList{index};
                obj.(MainMenuName).(Name).MenuSelectedFcn=      MyCallbacks{index};

            end


        end
        
    end

    methods % setters
        
        function obj = updateWith(obj, varargin)
                % UPDATEWITH update views with input:
                % 1 argument: PMMovieLibrary:
                % methods leads to update of nickname view, movie-filter, keyword-filter, image-source list, info-view;
                
                if ~isempty(obj.Figure) && isvalid(obj.Figure)
                    
                    
                    
                    NumberOfArguments= length(varargin);
                    switch NumberOfArguments
                        case 1
                            Type = class(varargin{1});
                            switch Type
                                case 'PMMovieLibrary'

                                    MovieLibrary = varargin{1};
                                    assert(isscalar(MovieLibrary), 'Wrong input.');

                                    obj =    obj.setNickNameView(MovieLibrary.getSelectedNickname);
                                    obj =    obj.setImageSourceTypeFilterView(MovieLibrary.getFilterSelectionIndex);
                                    obj =    obj.setKeywordFilterView(MovieLibrary.getKeyWordList);

                                    obj =    obj.setImageSourceListView(MovieLibrary.getListWithFilteredNicknames);
                                    obj =    obj.setInfoView(MovieLibrary.getProjectInfoText);

                                otherwise
                                    error('Wrong input.')

                            end
                        otherwise
                            error('Wrong input.')

                    end

                else
                    
                end
            
          end
      
        function obj = show(obj)
            % SHOW shows figure:
            % either puts figure in foreground (if it exists) or creates new figure from scracth;
            
            FigureWasThere = ~isempty(obj.Figure) && isvalid(obj.Figure);
            if FigureWasThere
                figure(obj.Figure);
                
            else
                obj = obj.initializeViews;

            end

        end

        function obj = setContentTypeFilterTo(obj, Value)
            assert(ischar(Value), 'Wrong input.') 
            WantedFilterRow =                                           strcmp(obj.ProjectViews.FilterForKeywords.String, 'Show all unmapped movies');
            obj.ProjectViews.FilterForKeywords.Value =           find(WantedFilterRow);
         
        end
        
        function obj = setInfoView(obj, String)
            
            if ~isempty(obj.InfoView) && isvalid(obj.InfoView.List)
             obj.InfoView.List.String =       String;
             obj.InfoView.List.Value =        min([length(obj.InfoView.List.String) obj.InfoView.List.Value]);
             if obj.InfoView.List.Value == 0
                obj.InfoView.List.Value = 1; 
             end
            end
           
           
             
        end

    end
    
    methods % SETTERS POSITIONING
        
        function obj = setPositions(obj)
              
            obj.InfoView.List.Units = 'normalized';
            obj.InfoView.List.Position =      [0.25 0.01 0.73 0.15];
        end
        
        
    end
    
    methods % GETTERS positioning
        
        function row = getStartRowTracking(obj)
           row  = obj.StartRowTracking; 
        end
        
        function row = getLeftColumn(obj)
           row  = obj.LeftColumn; 
        end
        
        function row = getColumnShift(obj)
           row  = obj.ColumnShift; 
        end
        
        function row = getViewHeight(obj)
           row  = obj.ViewHeight; 
        end
        
        function row = getWidthOfFirstColumn(obj)
           row  = obj.WidthOfFirstColumn; 
        end
        
        function row = getWidthOfSecondColumn(obj)
           row  = obj.WidthOfSecondColumn; 
        end
        
        function row = getRowShift(obj)
           row  = obj.RowShift; 
        end
        
        function row = getStartRowChannels(obj)
           row = obj.StartRowChannels; 
        end
        
        function row = getStartRowAnnotation(obj)
           row = obj.StartRowAnnotation; 
        end
        
        
        
        
    end
    
    methods % getters
        
        function list = getSelectedNicknames(obj)
           % GETSELECTEDNICKNAMES:
           % returns list of all selected (highlighted) nicknames in movie-list;
           list =             obj.ProjectViews.ListOfMoviesInProject.String(obj.ProjectViews.ListOfMoviesInProject.Value);  
         end
                
        function figure = getFigure(obj)
           figure = obj.Figure;

        end
        
        function views = getProjectViews(obj)
            views = obj.ProjectViews;

        end
        
        function views = getTrackingViews(obj)
           views = obj.TrackingViews;

        end

        function row = getStartRowNavigation(obj)
            row = obj.StartRowNavigation;   

        end
        
        function type = getMousClickType(obj)
            type = obj.Figure.SelectionType;

        end
        
       
       
    end

    methods % setters project views:
       
        function obj =  setCurrentCharacter(obj, Value)
                obj.Figure.CurrentCharacter =                  Value;
        end
                
      
    end
  
    methods (Access = private) % initialize
        
        
        function obj = verifyMenuName(obj, Name)
            
            assert(ischar(Name) && max(strcmp(Name, obj.AvailableMenus)), 'Menu not supported')
            
        end
        
        
        
     end
  
    methods (Access = private) % initialize
       
         function obj = initializeViews(obj)
            
                obj =                        obj.CreateProjectFigure;
                obj =                        obj.CreateProjectViews;
                obj =                        obj.createInfoView;
                
                obj =                      obj.setKeywordFilterView('');
            
        end
        
    end
    
    methods (Access = private) % create project views
        
         function obj =     CreateProjectFigure(obj)
            
            fprintf('PMImagingProjectViewer:@CreateProjectFigure.\n')
            
            ProjectWindowHandle=             figure;
            ProjectWindowHandle.Name=        'MainProjectWindow_V2';
            ProjectWindowHandle.Tag=         'MainProjectWindow_V2';
            ProjectWindowHandle.Units=       'normalized';
            ProjectWindowHandle.Position=    [0.01 0.01 0.95 0.9];
            ProjectWindowHandle.MenuBar=     'none';
            ProjectWindowHandle.Color =      'k';

            obj.Figure=                      ProjectWindowHandle;
            
            obj.ProjectAxes =                axes;
            obj.ProjectAxes.Parent =         ProjectWindowHandle;
            obj.ProjectAxes.Units =          'normalized';
            obj.ProjectAxes.Position =       [0 0 1 1];
            obj.ProjectAxes.Visible =        'off';

        end
        
         function obj =      CreateProjectViews(obj)
            
                 fprintf('PMImagingProjectViewer:@CreateProjectViews.\n')

                    ViewHeightInternal =                                            obj.ViewHeight;
                    WidthOfContents =                                               obj.WidthOfProjectViews;
                    LeftPositionOfContents =                                        obj.LeftPositionOfProjectViews;
                    
                    TitleRowForProjectViews =                                       0.95;
                    FirstRowForProjectViews =                                       0.91;
                    SecondRowForProjectViews =                                      0.87;
                    ThirdRowForProjectViews =                                       0.83;
                    FourthRowForProjectViews =                                      0.01;
                    

                     %% Selected NickName =
                    SelectedNickname=                                              uicontrol;
                    SelectedNickname.Style=                                        'Text';
                    SelectedNickname.Units=                                        'normalized';
                    SelectedNickname.Position=                                     [LeftPositionOfContents TitleRowForProjectViews WidthOfContents ViewHeightInternal];
                    SelectedNickname.String=                                       '';
                    SelectedNickname.Tag=                                          'KeywordFilter';
                    SelectedNickname.ForegroundColor =                              'c';
                    SelectedNickname.BackgroundColor =                              [0 0.1 0.2];
                    
                    
                    %% menus:
                    FilterForKeywords=                                              uicontrol;
                    FilterForKeywords.Style=                                        'PopupMenu';
                    FilterForKeywords.Units=                                        'normalized';
                    FilterForKeywords.Position=                                     [LeftPositionOfContents FirstRowForProjectViews WidthOfContents ViewHeightInternal];
                    FilterForKeywords.String=                                       {'Show all movies'};
                    FilterForKeywords.Tag=                                          'KeywordFilter';
                    FilterForKeywords.ForegroundColor =                              'r';
                    FilterForKeywords.BackgroundColor =                              [0 0.1 0.2];

                    
                      RealFilterForKeywords=                                              uicontrol;
                    RealFilterForKeywords.Style=                                        'PopupMenu';
                    RealFilterForKeywords.Units=                                        'normalized';
                    RealFilterForKeywords.Position=                                     [LeftPositionOfContents SecondRowForProjectViews WidthOfContents ViewHeightInternal];
                    RealFilterForKeywords.String=                                       {'Do not filter for keywords'};
                    RealFilterForKeywords.Tag=                                          'RealKeywordFilter';
                    RealFilterForKeywords.ForegroundColor =                              'r';
                    RealFilterForKeywords.BackgroundColor =                              [0 0.1 0.2];

                    

                    SortMovies=                                                     uicontrol;
                    SortMovies.Style=                                               'PopupMenu';
                    SortMovies.Units=                                               'normalized';
                    SortMovies.Position=                                            [LeftPositionOfContents ThirdRowForProjectViews WidthOfContents ViewHeightInternal];
                    SortMovies.String=                                              {'Sort by movie name'};
                    SortMovies.Tag=                                                 'FilterForGroups';
                     SortMovies.ForegroundColor =                              'r';
                    SortMovies.BackgroundColor =                              [0 0.1 0.2];
                    
                    
                    %% movie-list:
                    
                    ListOfMoviesInProject=                                          uicontrol;
                    ListOfMoviesInProject.Style=                                    'Listbox';
                    ListOfMoviesInProject.Units=                                    'normalized';
                    ListOfMoviesInProject.Position=                                 [LeftPositionOfContents FourthRowForProjectViews WidthOfContents 0.74];
                    ListOfMoviesInProject.String=                                   {'Empty'};
                    ListOfMoviesInProject.Min=                                      0;
                    ListOfMoviesInProject.Max=                                      2;
                    ListOfMoviesInProject.Tag=                                      'ListOfMoviesInProject';
                    ListOfMoviesInProject.ForegroundColor =                              'c';
                    ListOfMoviesInProject.BackgroundColor =                              [0 0.1 0.2];

                    %% add handle of project-window:
                    obj.ProjectViews.SelectedNickname=                                SelectedNickname;
                    obj.ProjectViews.RealFilterForKeywords=                               RealFilterForKeywords;
                    obj.ProjectViews.FilterForKeywords=                               FilterForKeywords;
                    obj.ProjectViews.SortMovies=                                      SortMovies;
                    obj.ProjectViews.ListOfMoviesInProject=                           ListOfMoviesInProject;


        end
           
         function obj =       createInfoView(obj)
              
                FontSize =                          13;
                FigureHandle =                      obj.Figure;

                ListBox=                            uicontrol;
                ListBox.Style =                     'listbox';
                ListBox.Units=                      'centimeters';
                ListBox.HorizontalAlignment=        'left';
                ListBox.FontSize=                   FontSize;
                ListBox.Tag=                        'Content';
                ListBox.String =                    {'Empty'};
                ListBox.Parent =                    FigureHandle;
                ListBox.ForegroundColor =           'c';
                ListBox.BackgroundColor =           [0.1 0 0.25];
                ListBox.Min =                       0;
                ListBox.Max =                       2;
                
                obj.InfoView.List =             ListBox;   
               obj = obj.setPositions;
                
                
              
              
         end
        
    end
    
    methods (Access = private) % SETTERS KEYWORD FILTER
       
        function obj = setKeywordFilterView(obj, ListWithKeywordStrings)
            
           
          
            obj.ProjectViews.RealFilterForKeywords.String =          obj.getKeywordFilterList(ListWithKeywordStrings);    

            if obj.ProjectViews.RealFilterForKeywords.Value == 0
                obj.ProjectViews.RealFilterForKeywords.Value = 1;
            end

            if min(obj.ProjectViews.RealFilterForKeywords.Value)> length(obj.ProjectViews.RealFilterForKeywords.String)
                obj.ProjectViews.RealFilterForKeywords.Value = length(obj.ProjectViews.RealFilterForKeywords.String);
            end

        end
        
        function KeywordList = getKeywordFilterList(obj, ListWithKeywordStrings)
            
             if iscell(ListWithKeywordStrings)
                KeywordList=                        ['Ignore keywords'; 'Movies with no keyword'; ListWithKeywordStrings];
            else
                KeywordList =                       {'Ignore keywords'; 'Movies with no keyword'; ListWithKeywordStrings}; 
             end
            
               KeywordList(cellfun(@(x) isempty(x), KeywordList), :) =         [];
            
        end

        
    end
    
    methods (Access = private) % setters project views:
        
      
        function obj = setImageSourceTypeFilterView(obj, SelectedIndex)
            obj.ProjectViews.FilterForKeywords.Enable=     'on';
            obj.ProjectViews.FilterForKeywords.String=     obj.ProjectFilterList;
            obj.ProjectViews.FilterForKeywords.Value =     SelectedIndex;
            if obj.ProjectViews.FilterForKeywords.Value == 0
                obj.ProjectViews.FilterForKeywords.Value = 1;
            end
            if min(obj.ProjectViews.FilterForKeywords.Value)> length(obj.ProjectViews.FilterForKeywords.String)
                obj.ProjectViews.FilterForKeywords.Value = length(obj.ProjectViews.FilterForKeywords.String);
            end

        end

     
        function obj = setImageSourceListView(obj, ListWithSelectedNickNames)
                if ~isempty(ListWithSelectedNickNames)
                    ListWithSelectedNickNames =                                     sort(ListWithSelectedNickNames);
                    obj.ProjectViews.ListOfMoviesInProject.String=                  ListWithSelectedNickNames;
                    obj.ProjectViews.ListOfMoviesInProject.Value=                    min([length(ListWithSelectedNickNames)    obj.ProjectViews.ListOfMoviesInProject.Value]);
                    obj.ProjectViews.ListOfMoviesInProject.Enable=                  'on';

                else
                    obj.ProjectViews.ListOfMoviesInProject.String=                  'No movies selected';
                    obj.ProjectViews.ListOfMoviesInProject.Value=                   1;
                    obj.ProjectViews.ListOfMoviesInProject.Enable=                  'off';
                end

        end

        function obj = setNickNameView(obj, String)
            obj.ProjectViews.SelectedNickname.String =                   String;
        end

        function obj =  disableAllViews(obj)

         allFieldNames = fieldnames(obj.ProjectViews);
          numberOfFields =  size(allFieldNames,1);


          for index = 1:numberOfFields

              obj.ProjectViews.(allFieldNames{index}).Enable = 'off';

          end




        end

        function obj =  enableAllViews(obj)


          allFieldNames = fieldnames(obj.ProjectViews);
          numberOfFields =  size(allFieldNames,1);


          for index = 1:numberOfFields

              obj.ProjectViews.(allFieldNames{index}).Enable = 'on';

          end



        end   

      
               
    end
    
    methods (Access = private) % currently not used: consider deletion;
    
         function [obj]=                      CurrentUnusedMenus(obj)
                %CREATEMENUFORPROJECTWINDOW Summary of this function goes here
                %   Detailed explanation goes here

                    %% Movies: all functions related to movies/ movie lists

                    MovieMenu=                                   uimenu(FigureHandle);
                    MovieMenu.Label=                             'Movies';
                    
 

                    Movies_LoadExportedMovies=                          uimenu(MovieMenu);
                    Movies_LoadExportedMovies.Label=                    'Load exported movies';
                    Movies_LoadExportedMovies.Tag=                      'Movies_LoadExportedMovies';
                    
                    Movies_LoadExportedMovies.Enable=                                'off';

                    Movies_LoadMeasurements=                           uimenu(MovieMenu);
                    Movies_LoadMeasurements.Label=                     'Load measurements';
                    Movies_LoadMeasurements.Tag=                       'Movies_LoadMeasurements';
                    
                    Movies_LoadMeasurements.Enable=                                'off';

                    Movies_LoadCoordinates=                            uimenu(MovieMenu);
                    Movies_LoadCoordinates.Label=                      'Load coordinates';
                    Movies_LoadCoordinates.Tag=                        'Movies_LoadCoordinates';
                    
                    Movies_LoadCoordinates.Enable=                                'off';

                    Movies_LoadEnvironmentAnalysis=                     uimenu(MovieMenu);
                    Movies_LoadEnvironmentAnalysis.Label=               'Load environment analysis';
                    Movies_LoadEnvironmentAnalysis.Separator=           'on';
                    Movies_LoadEnvironmentAnalysis.Tag=                 'Movies_LoadEnvironmentAnalysis';
                    
                    Movies_LoadEnvironmentAnalysis.Enable=                                'off';

                    
                    % movie: remapping of movie:
                    
   
                    %% Batch: these probably should be incorporated into movies menu;
                    Batch_Main=                                 uimenu(FigureHandle);
                    Batch_Main.Label=                           'Batch';

                    KeyboardShortcuts=                                  uimenu(Batch_Main);
                    KeyboardShortcuts.Label=                            'Run';
                    KeyboardShortcuts.Tag=                              'Batch_Run';
                    KeyboardShortcuts.Enable=                           'off';


                    Batch_Mig_ReduceSize=                       uimenu(Batch_Main);
                    Batch_Mig_ReduceSize.Label=                 'Reduce image size';
                    Batch_Mig_ReduceSize.Separator=             'on';
                    Batch_Mig_ReduceSize.Tag=                   'Batch_Mig_ReduceSize';
                    Batch_Mig_ReduceSize.Enable=                'off';



                    Batch_Drift=                                uimenu(Batch_Main);
                    Batch_Drift.Label=                          'Drift correction';
                    Batch_Drift.Separator=                      'on';
                    Batch_Drift.Tag=                            'Drift correction';
                    Batch_Drift.Enable=                          'off';

                    Batch_RemoveDrift=                          uimenu(Batch_Main);
                    Batch_RemoveDrift.Label=                    'Remove drift verification images';
                    Batch_RemoveDrift.Separator=                'off';
                    Batch_RemoveDrift.Tag=                      'Batch_RemoveDriftCorrection';
                    Batch_RemoveDrift.Enable=                                'off';



                    Batch_Track_Erase=                          uimenu(Batch_Main, 'label', 'Erase background');
                    Batch_Track_Erase.Tag=                      'Erase background';
                    Batch_Track_Erase.Separator=                'on';
                    Batch_Track_Erase.Enable=                   'off';
                    Batch_Track_Erase.Enable=                   'off';


                    Batch_Track_Segment=                        uimenu(Batch_Main);
                    Batch_Track_Segment.Label=                  'Cell segmentation';
                    Batch_Track_Segment.Tag=                    'Cell segmentation';
                    Batch_Track_Segment.Enable=                  'off';


                    Batch_Tracking=                             uimenu(Batch_Main);
                    Batch_Tracking.Label=                       'Tracking';
                    Batch_Tracking.Tag=                         'Tracking';
                    Batch_Tracking.Enable=                      'off';
                    Batch_Tracking.Enable=                                'off';

                    Batch_MeasureSubtracks=                     uimenu(Batch_Main);
                    Batch_MeasureSubtracks.Label=               'Measure subtracks';
                    Batch_MeasureSubtracks.Separator=           'on';
                    Batch_MeasureSubtracks.Tag=                 'MeasureSubtracks';
                    Batch_MeasureSubtracks.Enable=                                'off';


                    Batch_Mig_DirField=                         uimenu(Batch_Main);
                    Batch_Mig_DirField.Label=                   'Environment correlation';
                    Batch_Mig_DirField.Tag=                                 'Environment correlation';
                    Batch_Mig_DirField.Enable=                                'off';

                    
                     KeyboardShortcuts.Callback=                         'BatchProcessingMain';
                    Batch_Drift.Callback=                       'ToggleMenuSetting(''Drift correction'')';
                     Batch_RemoveDrift.Callback=                 'ToggleMenuSetting(''Batch_RemoveDriftCorrection'')';
                    Batch_Track_Erase.Callback=                 'ToggleMenuSetting(''Erase background'')';
                    Batch_Track_Segment.Callback=               'ToggleMenuSetting(''Cell segmentation'')';
                    Batch_Tracking.Callback=                    'ToggleMenuSetting(''Tracking'')';
                    Batch_MeasureSubtracks.Callback=            'ToggleMenuSetting(''MeasureSubtracks'')';
                    Batch_Mig_DirField.Callback=                'ToggleMenuSetting(''Environment correlation'')';
                    
                    
                    Batch_OverViewList=                                       uimenu(Batch_Main);
                    Batch_OverViewList.Label=                                   'Show overview of selected movies';
                    
                    Batch_OverViewList.Tag=                                     'Batch_OverViewList';
                    Batch_OverViewList.Enable=                                  'on';


                    
                    Batch_ExportSelectedNicknames=                              uimenu(Batch_Main);
                    Batch_ExportSelectedNicknames.Label=                        'Export selected nicknames in cell-format';
                    Batch_ExportSelectedNicknames.Tag=                          'Batch_ExportSelectedNicknames';
                    Batch_ExportSelectedNicknames.Enable=                       'on';



                    %% Export: incorporate from navigation window:
                    ExportMenu=                                                 uimenu(FigureHandle);
                    ExportMenu.Label=                                           'Export';

                    OpenExportWindow=                                           uimenu(ExportMenu);
                    OpenExportWindow.Label=                                     'Open export window'; 
                    OpenExportWindow.Tag=                                       'ExportOneDimensionalData';
                    
                    OpenExportWindow.Enable=                                    'off';

                    SortMovies.Callback=                                            'CallbackForSortMovieList';
                    
               
                   
                    Movies_LoadExportedMovies.Callback=                 'LoadExportedMovie(''Movies'',''*.avi'')';
                    Movies_LoadMeasurements.Callback=                  'LoadExportedMovie(''Measurements'',''*.fig'')';
                    Movies_LoadCoordinates.Callback=                   'LoadExportedMovie(''Coordinates'',''*.mat'')';
                    Movies_LoadEnvironmentAnalysis.Callback=                    'LoadExportedMovie(''Environment'',''*.*'')';
                    
                    
                 
                  

                    Batch_Mig_ReduceSize.Callback=                                  'ToggleMenuSetting(''Batch_Mig_ReduceSize'')';
                    
                    Batch_OverViewList.Callback=                                    'Callback_ProjectMenuOverViewList';
                    Batch_ExportSelectedNicknames.Callback=                         'Callback_ProjectMenu_ExportNicknames';
                    OpenExportWindow.Callback=                                      'LoadEnvironmentAnalysis_All';
                    
                    
                    
                   
                
                %% collect:
                
                % file-menu:  
                
                
              
                
                
                
                

                ProjectMenuStructure.Batch.Run=                               KeyboardShortcuts;
                ProjectMenuStructure.Batch.ReduceMovieSize=                   Batch_Mig_ReduceSize;
                ProjectMenuStructure.Batch.PerformDriftCorrection=            Batch_Drift;
                ProjectMenuStructure.Batch.RemoveDriftCorrectionFiles=        Batch_RemoveDrift;
                ProjectMenuStructure.Batch.EraseBackground=                   Batch_Track_Erase;
                ProjectMenuStructure.Batch.Segmentation=                      Batch_Track_Segment;
                ProjectMenuStructure.Batch.AutomatedTracking=                 Batch_Tracking;
                ProjectMenuStructure.Batch.MigrationAnalysis=                 Batch_MeasureSubtracks;
                ProjectMenuStructure.Batch.EnvironmentCorrelation=            Batch_Mig_DirField;

                
    

         end
        
         function obj = setMovieMenuCallbacks(obj, varargin)
            error('Not supported anymore.')
            obj.MovieMenu =    obj.MovieMenu.setCallbacks(varargin{:});
        end

        function obj =  setDriftMenuCallbacks(obj, varargin)
            error('Not supported anymore.')
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
            case 2
                obj.DriftMenu.ApplyManualDriftCorrection.MenuSelectedFcn =                          varargin{1} ;
                obj.DriftMenu.EraseAllDriftCorrections.MenuSelectedFcn =                            varargin{2} ;
            otherwise
             error('Wrong input.')

            end


        end

        
        
        
    end
    
    
end

