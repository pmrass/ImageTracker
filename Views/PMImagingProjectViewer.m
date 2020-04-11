classdef PMImagingProjectViewer
    %PMIMAGINGPROJECTVIEWER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        Figure
        ProjectAxes
        
        FileMenu
        ProjectMenu
        HelpMenu
       
        ProjectViews
        MovieControllerViews
        TrackingViews
        
        InfoView
        
        TagForKeywordEditor =           'PMImagingProject_EditKeywordsViewer'
        
         % positioning
        WidthOfProjectViews =           0.2; 
        LeftPositionOfProjectViews =    0.01;
         
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
        
        
        
    end

    
    methods
        
        function [obj]=                                          PMImagingProjectViewer
            %PROJECTWINDOW_CREATEWINDOW Summary of this function goes here
            %   Detailed explanation goes here
                
            
                obj =                                   obj.CreateProjectFigure;
             
                obj =                                   obj.CreateFileMenu;
                obj =                                   obj.CreateProjectMenu;
                
                
                obj =                                   obj.CreateProjectViews;
                obj =                                   obj.createInfoView;
                       
                obj.MovieControllerViews =              PMMovieControllerView(obj);
                obj.TrackingViews =                     PMTrackingView(obj);
                  
                obj =                                   obj.CreateHelpMenu;  
                
                
                
                %uistack(obj.ProjectAxes, 'top')
                
              
                
                 %obj.changeAppearance;
                %obj.disableAllViews; % by default disable all views; (only when relevant data are loaded enable specific vies;
             
                
                
        end
        
        function [obj] =                            CreateProjectFigure(obj)
            
            ProjectWindowHandle=                                                    findobj('Tag', 'MainProjectWindow_V2');
            if ~isempty(ProjectWindowHandle)
                close(ProjectWindowHandle)

            end

            ProjectWindowHandle=                                            figure;
            ProjectWindowHandle.Name=                                       'MainProjectWindow_V2';
            ProjectWindowHandle.Tag=                                        'MainProjectWindow_V2';
            ProjectWindowHandle.Units=                                      'normalized';
            ProjectWindowHandle.Position=                                   [0.01 0.01 0.95 0.9];
            ProjectWindowHandle.MenuBar=                                    'none';
            ProjectWindowHandle.Color =                                     'k';

            obj.Figure=                                                     ProjectWindowHandle;
            
            obj.ProjectAxes =                                                   axes;
            obj.ProjectAxes.Parent =                                            ProjectWindowHandle;
            obj.ProjectAxes.Units =                                             'normalized';
            obj.ProjectAxes.Position =                                          [0 0 1 1];
            obj.ProjectAxes.Visible =                                           'off';

        end
        
        
        
        function [obj] =                            CreateFileMenu(obj)
            
                    FigureHandle=               obj.Figure;

                    FileMain=                                            uimenu(FigureHandle);
                    FileMain.Label=                                      'File';
                    FileMain.Tag=                                        'FileMenu';

                    File.New=                                            uimenu(FileMain);
                    File.New.Label=                                      'New';
                    File.New.Tag=                                        'Project_New';
                    
                    File.Load=                                         uimenu(FileMain);
                    File.Load.Label=                                   'Load';
                    File.Load.Tag=                                     'Project_Load';

                    File.Save=                                           uimenu(FileMain);
                    File.Save.Label=                                     'Save';
                    File.Save.Tag=                                       'Project_Save';
                    File.Save.Enable=                                    'on';
            
                    obj.FileMenu =  File;
            
        end
        
        
        function [obj] =                            CreateProjectMenu(obj)
            
            
            FigureHandle=               obj.Figure;
          
                %% Project: Management of loaded project:
                    ProjectMenuInside=                                            uimenu(FigureHandle);
                    ProjectMenuInside.Label=                                      'Project';
                    ProjectMenuInside.Tag=                                        'ProjectMenuInside';

                    
                    obj.ProjectMenu.ChangeMovieFolder=                                    uimenu(ProjectMenuInside);
                    obj.ProjectMenu.ChangeMovieFolder.Label=                              'Change movie-folder';
                    obj.ProjectMenu.ChangeMovieFolder.Tag=                                'Project_MovieFolder';
                    obj.ProjectMenu.ChangeMovieFolder.Enable=                             'on';

                   

                    obj.ProjectMenu.ChangeExportFolder=                              uimenu(ProjectMenuInside);
                    obj.ProjectMenu.ChangeExportFolder.Label=                         'Change export-folder';
                    obj.ProjectMenu.ChangeExportFolder.Tag=                           'Project_ExportFolder';
                    obj.ProjectMenu.ChangeExportFolder.Enable=                        'on';

                   

                    obj.ProjectMenu.AddCapture=                              uimenu(ProjectMenuInside);
                    obj.ProjectMenu.AddCapture.Label=                        'Add';
                    obj.ProjectMenu.AddCapture.Tag=                          'Movies_AddImage';
                    obj.ProjectMenu.AddCapture.Enable=                       'on';


                    obj.ProjectMenu.RemoveCapture=                                uimenu(ProjectMenuInside);
                    obj.ProjectMenu.RemoveCapture.Label=                          'Remove';
                    obj.ProjectMenu.RemoveCapture.Tag=                            'Movies_Remove';
                    obj.ProjectMenu.RemoveCapture.Enable=                         'on';
                    
                   
                    obj.ProjectMenu.AddAllCaptures=                       uimenu(ProjectMenuInside);
                    obj.ProjectMenu.AddAllCaptures.Label=                 'Add all images/movies in movie directory';
                    obj.ProjectMenu.AddAllCaptures.Tag=                   'Movies_AddAllImagesInDir';
                    obj.ProjectMenu.AddAllCaptures.Enable=                'on';

                      obj.ProjectMenu.ShowMissingCaptures=                       uimenu(ProjectMenuInside);
                    obj.ProjectMenu.ShowMissingCaptures.Label=                 'Show image/movie files that have not yet been imported';
                    obj.ProjectMenu.ShowMissingCaptures.Tag=                   'Movies_ShowMissingCaptures';
                    obj.ProjectMenu.ShowMissingCaptures.Enable=                'on';

                    
                    
                    obj.ProjectMenu.Mapping=                                   uimenu(ProjectMenuInside);
                    obj.ProjectMenu.Mapping.Label=                             'Map all unmapped images';
                    obj.ProjectMenu.Mapping.Separator=                         'on';
                    obj.ProjectMenu.Mapping.Enable=                            'on';
                    
                    obj.ProjectMenu.UnMapping=                                   uimenu(ProjectMenuInside);
                    obj.ProjectMenu.UnMapping.Label=                             'Unmapping all movies';
                    obj.ProjectMenu.UnMapping.Separator=                         'off';
                    obj.ProjectMenu.UnMapping.Enable=                            'on';
                   
                      
                     obj.ProjectMenu.ReplaceKeywords=                                   uimenu(ProjectMenuInside);
                    obj.ProjectMenu.ReplaceKeywords.Label=                             'Replace keywords';
                    obj.ProjectMenu.ReplaceKeywords.Separator=                         'on';
                    obj.ProjectMenu.ReplaceKeywords.Enable=                            'on';
                    
                        
                     obj.ProjectMenu.UpdateMovieSummary=                                   uimenu(ProjectMenuInside);
                    obj.ProjectMenu.UpdateMovieSummary.Label=                             'Update movie summaris from file';
                    obj.ProjectMenu.UpdateMovieSummary.Separator=                         'off';
                    obj.ProjectMenu.UpdateMovieSummary.Enable=                            'on';
                    
                    obj.ProjectMenu.Info=                                   uimenu(ProjectMenuInside);
                    obj.ProjectMenu.Info.Label=                             'Info';
                    obj.ProjectMenu.Info.Separator=                         'on';
                    obj.ProjectMenu.Info.Enable=                            'on';
                   
                   
                    %                      Movies_ApplySettings=                                  uimenu(MovieMenu);
%                     Movies_ApplySettings.Label=                            'Apply loaded settings to selected movies';
%                     Movies_ApplySettings.Callback=                         'Callback_ProjectMenu_ViewReuseSettings';
%                     Movies_ApplySettings.Tag=                              'Movies_ApplySettings';
%                     Movies_ApplySettings.Enable=                           'on';




                   
                    
                    

                    
            
            
        end
        
        
          function [obj] =                         CreateHelpMenu(obj)
            
                    HelpMenuInside=                                 uimenu(obj.Figure);
                    HelpMenuInside.Label=                           'Help';

                    obj.HelpMenu.KeyboardShortcuts=                                  uimenu(HelpMenuInside);
                    obj.HelpMenu.KeyboardShortcuts.Label=                            'Show keyboard shortcuts';
                    obj.HelpMenu.KeyboardShortcuts.Tag=                              'KeyboardShortcuts';
                    obj.HelpMenu.KeyboardShortcuts.Enable=                           'on';
                    
            
            
          end
        
          
          function [obj]=                        CreateProjectViews(obj)
            

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
                     obj.ProjectViews.RealFilterForKeywords=                               RealFilterForKeywords;
                    obj.ProjectViews.FilterForKeywords=                               FilterForKeywords;
                    obj.ProjectViews.SelectedNickname=                                SelectedNickname;
                    obj.ProjectViews.SortMovies=                                      SortMovies;
                    obj.ProjectViews.ListOfMoviesInProject=                           ListOfMoviesInProject;


        end
       
                
         function [obj] =                 createInfoView(obj)
              
                %% obtain information:
                FontSize =                      13;
                FigureHandle =                  obj.Figure;

                %% process information
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
                
        
                
                
                %% return information:
               
                obj.InfoView.List =             ListBox;   
              
         end

         
         function [obj] =                   listWithAllViews(obj)
             
             
             
             
         end
        
         function [obj] =                   disableAllViews(obj)
             
             
             allFieldNames = fieldnames(obj.ProjectViews);
              numberOfFields =  size(allFieldNames,1);
              
              
              for index = 1:numberOfFields
              
                  obj.ProjectViews.(allFieldNames{index}).Enable = 'off';
                  
              end

             
             
             
         end
         
         function [obj] =                   enableAllViews(obj)
             
             
              allFieldNames = fieldnames(obj.ProjectViews);
              numberOfFields =  size(allFieldNames,1);
              
              
              for index = 1:numberOfFields
              
                  obj.ProjectViews.(allFieldNames{index}).Enable = 'on';
                  
              end
              
              
             
         end
        
        
        
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
        
        
        function [KeywordManagerHandles]=       createKeywordEditorView(obj)
            
            
            
                FirstColumnFilter =                 0.1;
                SecondColumnFilter =                0.5;

                FirstRowFilter =                    0.9;
                SecondRowFilter =                   0.8;
                ThirdRowFilter =                    0.1;

                FilterOptions =                     {'Keywords'};

                %% figure

                FigureHandle=                                                                   findobj('Tag', obj.TagForKeywordEditor);
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

                %% finish button


                DoneField=                              uicontrol;
                DoneField.Style=                        'checkbox';
                DoneField.String=                       'Done';
                DoneField.Value =                       0;
                DoneField.Units=                        'normalized';
                DoneField.Position=                     [0.8 0.85  0.1 0.15];



                %% pre-
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

                %% target keywords:

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
end

