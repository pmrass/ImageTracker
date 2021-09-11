classdef PMImagingProjectViewer
    %PMIMAGINGPROJECTVIEWER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Figure

        ProjectAxes

        ProjectViews
        MovieControllerViews
        TrackingViews

        InfoView
        TagForKeywordEditor =           'PMImagingProject_EditKeywordsViewer'

    end
    
    properties (Access = private) % menus:

        FileMenu
        ProjectMenu
        MovieMenu
        DriftMenu
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
     
        ProjectFilterList =              {'Show all movies'; 'Show all Z-stacks'; 'Show all snapshots'; 'Show all movies with drift correction'; 'Show all tracked movies'; 'Show all untracked movies'; 'Show entire content'; 'Show content with non-matching channel information'; 'Show all unmapped movies'}; 
    
        AvailableMenus = {   'FileMenu', 'ProjectMenu', 'MovieMenu', 'DriftMenu', 'InteractionsMenu', 'HelpMenu'};
          
    end
    
    
    methods % initialize:
        
          function obj =                                          PMImagingProjectViewer
                %PROJECTWINDOW_CREATEWINDOW Summary of this function goes here
                %   Detailed explanation goes here

                fprintf('\n@Create PMImagingProjectViewer:\n')

                obj =                        obj.CreateProjectFigure;


                obj.DriftMenu =              PMDriftCorrectionMenu(obj.Figure);

                obj.TrackingViews =          PMTrackingView(obj);
                obj.InteractionsMenu =       PMInteractionsMenu(obj.Figure);

                obj =                        obj.CreateHelpMenu;  

                obj =                        obj.CreateProjectViews;

                obj.MovieControllerViews =   PMMovieControllerView(obj);
                obj =                        obj.createInfoView;
            

                
          end
          
          
        
        
        
    end

    methods (Access = private) % initialize
        
        
        function obj = verifyMenuName(obj, Name)
            
            assert(ischar(Name) && max(strcmp(Name, obj.AvailableMenus)), 'Menu not supported')
            
        end
        
        
        
    end
    
    methods % setters
        
        function obj = setContentTypeFilterTo(obj, Value)
            assert(ischar(Value), 'Wrong input.') 
            WantedFilterRow =                                           strcmp(obj.ProjectViews.FilterForKeywords.String, 'Show all unmapped movies');
            obj.ProjectViews.FilterForKeywords.Value =           find(WantedFilterRow);
         
        end
        
        function obj = updateWith(obj, varargin)
            NumberOfArguments= length(varargin);
            switch NumberOfArguments
                case 1
                    Type = class(varargin{1});
                    switch Type
                        case 'PMMovieLibrary'
                            MovieLibrary = varargin{1};
                            
                            if isempty(MovieLibrary.getMovieObjectSummaries)   
                                obj.MovieControllerViews.disableAllViews;
                            end
                            
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
            
        end
        
         function obj = setInfoView(obj, String)
             obj.InfoView.List.String =       String;
             obj.InfoView.List.Value =        min([length(obj.InfoView.List.String) obj.InfoView.List.Value]);
             if obj.InfoView.List.Value == 0
                obj.InfoView.List.Value = 1; 
             end
             
           
           
             
         end
           
    end
    
    methods % create subviews
        
            function [KeywordManagerHandles]=       createKeywordEditorView(obj)


                FirstColumnFilter =                 0.1;
                SecondColumnFilter =                0.5;

                FirstRowFilter =                    0.9;
                SecondRowFilter =                   0.8;
                ThirdRowFilter =                    0.1;

                FilterOptions =                     {'Keywords'};

                FigureHandle=                          findobj('Tag', obj.TagForKeywordEditor);
                if isempty(FigureHandle)
                    FigureHandle=                                                               figure;
                else
                    clf(FigureHandle)
                end

                figure(FigureHandle)
                FigureHandle.Units=                                                             'normalized';
                FigureHandle.Position=                                                          [0.05 0.2  0.6 0.7];
                FigureHandle.MenuBar=                                                           'none';
                FigureHandle.Tag=                                                              obj.TagForKeywordEditor;

                DoneField=                              uicontrol;
                DoneField.Style=                        'checkbox';
                DoneField.String=                       'Done';
                DoneField.Value =                       0;
                DoneField.Units=                        'normalized';
                DoneField.Position=                     [0.8 0.85  0.1 0.15];

                SelectFilterTypeSource=                                           uicontrol;
                SelectFilterTypeSource.Style=                                    'popupmenu';
                SelectFilterTypeSource.String=                                    FilterOptions;
                SelectFilterTypeSource.Units=                                     'normalized';
                SelectFilterTypeSource.HorizontalAlignment=                       'left';	



                SelectFilterTypeSource.Position=                                  [FirstColumnFilter  FirstRowFilter 0.15 0.05];



                PreFilterSource=                                          uicontrol;
                PreFilterSource.Style=                                  'edit';
                PreFilterSource.String=                                  '';
                PreFilterSource.Units=                                            'normalized';
                PreFilterSource.HorizontalAlignment=                                  'left';	
                PreFilterSource.Position=                                             [FirstColumnFilter  SecondRowFilter 0.29 0.05];


                ListWithFilterWordsSource=                                           uicontrol;
                ListWithFilterWordsSource.Style=                                     'listbox';
                ListWithFilterWordsSource.String=                                    '';
                ListWithFilterWordsSource.Units=                                     'normalized';
                ListWithFilterWordsSource.Min=                                       0;
                ListWithFilterWordsSource.Max=                                       1;
                ListWithFilterWordsSource.HorizontalAlignment=                       'left';	
                ListWithFilterWordsSource.Position=                                  [FirstColumnFilter  ThirdRowFilter 0.29 0.4];


                SelectFilterTypeTarget=                                           uicontrol;
                SelectFilterTypeTarget.Style=                                    'popupmenu';
                SelectFilterTypeTarget.String=                                    ['Delete', FilterOptions];
                SelectFilterTypeTarget.Units=                                     'normalized';
                SelectFilterTypeTarget.HorizontalAlignment=                       'left';	

                SelectFilterTypeTarget.Value = 2;

                SelectFilterTypeTarget.Position=                                  [SecondColumnFilter  FirstRowFilter 0.15 0.05];



                PreFilterTarget=                                                    uicontrol;
                PreFilterTarget.Style=                                                  'edit';
                PreFilterTarget.String=                                                 '';
                PreFilterTarget.Units=                                                  'normalized';
                PreFilterTarget.HorizontalAlignment=                                    'left';	



                PreFilterTarget.Position=                                             [SecondColumnFilter  SecondRowFilter 0.29 0.05];


                ListWithFilterWordsTarget=                                           uicontrol;
                ListWithFilterWordsTarget.Style=                                     'listbox';
                ListWithFilterWordsTarget.String=                                    '';
                ListWithFilterWordsTarget.Units=                                     'normalized';
                ListWithFilterWordsTarget.Min=                                       0;
                ListWithFilterWordsTarget.Max=                                       1;
                ListWithFilterWordsTarget.HorizontalAlignment=                       'left';	


                ListWithFilterWordsTarget.Position=                                  [SecondColumnFilter  ThirdRowFilter 0.29 0.4];


                KeywordManagerHandles.FigureHandle =                                  FigureHandle;
                KeywordManagerHandles.DoneField =                                    DoneField;

                KeywordManagerHandles.SelectFilterTypeSource =                        SelectFilterTypeSource;
                KeywordManagerHandles.PreFilterSource =                               PreFilterSource;
                KeywordManagerHandles.ListWithFilterWordsSource =                     ListWithFilterWordsSource;

                KeywordManagerHandles.SelectFilterTypeTarget =                                  SelectFilterTypeTarget;
                KeywordManagerHandles.PreFilterTarget =                               PreFilterTarget;
                KeywordManagerHandles.ListWithFilterWordsTarget =                     ListWithFilterWordsTarget;

            end

     
            
          
        
        
    end
    
    methods % getters positioning
        
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
        
        function figure = getFigure(obj)
           figure = obj.Figure; 
        end
        
        function views = getProjectViews(obj)
            views = obj.ProjectViews;
        end
        
        function views = getTrackingViews(obj)
           views = obj.TrackingViews; 
        end
        
        function view = getMovieControllerView(obj)
           view = obj.MovieControllerViews; 
        end
        
        function row = getStartRowNavigation(obj)
            row = obj.StartRowNavigation;    
        end
        
        function type = getMousClickType(obj)
            type = obj.Figure.SelectionType;
        end
        
        function list = getSelectedNicknames(obj)
           list =             obj.ProjectViews.ListOfMoviesInProject.String(obj.ProjectViews.ListOfMoviesInProject.Value);  
        end
       
    end


    methods % setters for callbacks
          
        
        function obj =         setTrackingViewsCallbacks(obj, varargin)
            assert(length(varargin) == 4, 'Wrong input.')
            obj.TrackingViews.Menu.AutoCellRecognition.MenuSelectedFcn =     varargin{1};
            obj.TrackingViews.Menu.AutoTracking.MenuSelectedFcn =            varargin{2};
            obj.TrackingViews.Menu.EditAndView.MenuSelectedFcn =             varargin{3};
            obj.TrackingViews.Menu.TrackSegments.MenuSelectedFcn =          varargin{4};
            % addlistener(obj.Viewer.getMovieControllerView.Navigation.TimeSlider,'Value','PreSet', @obj.sliderActivity);
        
        end
        
        
        function obj = setCallbacks(obj, varargin)
            
            switch length(varargin)
               
                case 8
                    
                    obj.Figure.WindowKeyPressFcn =                          varargin{1};
                    obj.Figure.WindowButtonDownFcn =                         varargin{2};
                    obj.Figure.WindowButtonUpFcn =                           varargin{3};
                    obj.Figure.WindowButtonMotionFcn =                       varargin{4};

                    obj.ProjectViews.FilterForKeywords.Callback =            varargin{5};
                    obj.ProjectViews.RealFilterForKeywords.Callback =        varargin{6};
                    obj.ProjectViews.SortMovies.Callback =                   varargin{7};
                    obj.ProjectViews.ListOfMoviesInProject.Callback =        varargin{8};
                    
                otherwise
                    error('Wrong input.')
                
                
            end
            
           

                
            
        end
        
 

     

        function obj = setMovieMenuCallbacks(obj, varargin)
        obj.MovieMenu =    obj.MovieMenu.setCallbacks(varargin{:});
        end

        function obj =  setDriftMenuCallbacks(obj, varargin)

        NumberOfArguments = length(varargin);
        switch NumberOfArguments
        case 2
            obj.DriftMenu.ApplyManualDriftCorrection.MenuSelectedFcn =                          varargin{1} ;
            obj.DriftMenu.EraseAllDriftCorrections.MenuSelectedFcn =                            varargin{2} ;
        otherwise
         error('Wrong input.')

        end


        end

        function obj = setInteractionsMenuCallbacks(obj, varargin)
        obj.InteractionsMenu = obj.InteractionsMenu.setCallbacks(varargin{:});
        end

        function obj = setHelpMenuCallbacks(obj, varargin)
        NumberOfArguments = length(varargin);
        switch NumberOfArguments
         case 2
             obj.HelpMenu.KeyboardShortcuts.MenuSelectedFcn  =                  varargin{1};
             obj.HelpMenu.TrackingKeyboardshortcuts.MenuSelectedFcn  =        varargin{2};


         otherwise
             error('Wrong input.')

        end



        end
        
    end
    
    methods % set menus
       
        function obj = setMenu(obj, varargin)
            
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
    
    methods (Access = private) % create menus:
       
     

        
        

        function obj =         CreateHelpMenu(obj)

            HelpMenuInside=                       uimenu(obj.Figure);
            HelpMenuInside.Label=                 'Help';

            obj.HelpMenu.KeyboardShortcuts=              uimenu(HelpMenuInside);
            obj.HelpMenu.KeyboardShortcuts.Label=        'Show keyboard shortcuts';
            obj.HelpMenu.KeyboardShortcuts.Tag=          'KeyboardShortcuts';
            obj.HelpMenu.KeyboardShortcuts.Enable=       'on';

            obj.HelpMenu.TrackingKeyboardshortcuts=         uimenu(HelpMenuInside);
            obj.HelpMenu.TrackingKeyboardshortcuts.Label=   'Show keyboard shortcuts for tracking';
            obj.HelpMenu.TrackingKeyboardshortcuts.Enable=  'on';


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
              
         end
        
    end
    
    methods % setters project views:
       
          
        function obj =  setCurrentCharacter(obj, Value)
                obj.Figure.CurrentCharacter =                  Value;
        end
                
          function obj = adjustViews(obj, Value)
           
              obj.MovieControllerViews =       obj.MovieControllerViews.adjustViews;
                obj.InfoView.List.Position =      Value;
            
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

        function obj = setKeywordFilterView(obj, ListWithKeywordStrings)
        if iscell(ListWithKeywordStrings)
            KeywordList=                        ['Ignore keywords'; 'Movies with no keyword'; ListWithKeywordStrings];
        else
            KeywordList =                       {'Ignore keywords'; 'Movies with no keyword'; ListWithKeywordStrings}; 
        end
        KeywordList(cellfun(@(x) isempty(x), KeywordList), :) =         [];
        obj.ProjectViews.RealFilterForKeywords.String =          KeywordList;    

        if obj.ProjectViews.RealFilterForKeywords.Value == 0
            obj.ProjectViews.RealFilterForKeywords.Value = 1;
        end

        if min(obj.ProjectViews.RealFilterForKeywords.Value)> length(obj.ProjectViews.RealFilterForKeywords.String)
            obj.ProjectViews.RealFilterForKeywords.Value = length(obj.ProjectViews.RealFilterForKeywords.String);
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
        
        
        
    end
    
    
end

