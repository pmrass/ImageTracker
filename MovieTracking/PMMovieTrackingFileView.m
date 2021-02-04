classdef PMMovieTrackingFileView
    %PMMOVIETRACKINGSETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        MainFigure
        Tag =           'PMMovieTrackingFileView'
        
        NickName
        Keywords
        
        Folder
        FolderAnnotation
        AttachedFiles
        
        ListWithPaths
        PointersPerFile
        FileCouldNotBeRead
        
        ImageMap
        
        TrackNumber
        DriftCorrectionPerformed
        MetaData
        
    end
    
    methods

        
        function obj = PMMovieTrackingFileView(varargin)
            %PMMOVIETRACKINGSETTINGS Construct an instance of this class
            %   Detailed explanation goes here
            
            %% define dimensions and create figure
            ScreenSize =                    get(0,'screensize');

            Height =                        ScreenSize(4)*0.8;
            Left =                          ScreenSize(3)*0.5;
            Width =                         ScreenSize(3)*0.45;
            
            RightColumnPosition     =       0.3;
            RightColumWidth =               0.68;
            
            LeftColumnPosition =            0.05;
            LeftColumWidth =               0.18;
            
            
           
             fig =                           uifigure;

                    fig.Position =                  [Left 0 Width Height];


                    fig.Tag =                       obj.Tag;

                    NickNameTitle =                         uilabel(fig);
                    KeywordsTitle =                         uilabel(fig);

                    FolderTitle =                            uilabel(fig);
                    FolderAnnotationTitle =                  uilabel(fig);

                    ImageMapTitle =                     uilabel(fig);
                    TrackNumberTitle =                     uilabel(fig);
                    DriftCorrectionPerformedTitle =                   uilabel(fig);
                    MetaDataTitle =                uilabel(fig);







                    AttachedFileTitle =                     uilabel(fig);
                    ListWithPathsTitle =                     uilabel(fig);
                    PointersPerFileTitle =                   uilabel(fig);
                    FileCouldNotBeReadTitle =                uilabel(fig);



                    obj.NickName =                          uieditfield(fig);
                    obj.Keywords =                          uieditfield(fig);

                    obj.Folder =                            uilistbox(fig);
                    obj.FolderAnnotation =                  uilistbox(fig);

                    obj.AttachedFiles =                     uilistbox(fig);
                    obj.ListWithPaths =                     uilistbox(fig);
                    obj.PointersPerFile =                   uilistbox(fig);
                    obj.FileCouldNotBeRead =                uilabel(fig);


                    obj.ImageMap =                          uitable(fig);
                    obj.TrackNumber =                       uilabel(fig);
                    obj.DriftCorrectionPerformed =          uicheckbox(fig);
                    obj.MetaData =                          uilistbox(fig);








                    %% position fields:
                    NickNameTitle.Position =                         [Width*LeftColumnPosition Height - 30  Width*LeftColumWidth 20 ];
                    KeywordsTitle.Position =                         [Width*LeftColumnPosition Height - 60  Width*LeftColumWidth 20 ];;

                    FolderTitle.Position =                            [Width*LeftColumnPosition Height - 110  Width*LeftColumWidth 20 ];;
                    FolderAnnotationTitle.Position =                  [Width*LeftColumnPosition Height - 150  Width*LeftColumWidth 20 ];;

                    AttachedFileTitle.Position =                     [Width*LeftColumnPosition Height - 200  Width*LeftColumWidth 40 ];;
                    ListWithPathsTitle.Position =                    [Width*LeftColumnPosition Height - 250  Width*LeftColumWidth 40 ];;
                    PointersPerFileTitle.Position =                  [Width*LeftColumnPosition Height - 300  Width*LeftColumWidth 40 ];;
                    FileCouldNotBeReadTitle.Position =               [Width*LeftColumnPosition Height - 320  Width*LeftColumWidth 20 ];;

                    ImageMapTitle.Position  =                     [Width*LeftColumnPosition Height - 450  Width*LeftColumWidth 20 ];;
                    TrackNumberTitle.Position  =                    [Width*LeftColumnPosition Height - 470  Width*LeftColumWidth 20 ];;
                    DriftCorrectionPerformedTitle.Position  =       [Width*LeftColumnPosition Height - 500  Width*LeftColumWidth 20 ];;
                    MetaDataTitle.Position  =                       [Width*LeftColumnPosition Height - 560  Width*LeftColumWidth 20 ];;




                    obj.NickName.Position =                  [Width*RightColumnPosition Height - 30  Width*RightColumWidth 20 ];;
                    obj.Keywords.Position =                  [Width*RightColumnPosition Height - 60  Width*RightColumWidth 20 ];;

                    obj.Folder.Position =                    [Width*RightColumnPosition Height - 110  Width*RightColumWidth 40 ];;
                    obj.FolderAnnotation.Position =          [Width*RightColumnPosition Height - 150  Width*RightColumWidth 40 ];;

                    obj.AttachedFiles.Position =             [Width*RightColumnPosition Height - 200  Width*RightColumWidth 40 ];;
                    obj.ListWithPaths.Position =             [Width*RightColumnPosition Height - 250  Width*RightColumWidth 40 ];;
                    obj.PointersPerFile.Position =           [Width*RightColumnPosition Height - 300  Width*RightColumWidth 40 ];;
                    obj.FileCouldNotBeRead.Position =        [Width*RightColumnPosition Height - 320  Width*RightColumWidth 20 ];;

                    obj.ImageMap.Position =                          [Width*RightColumnPosition Height - 450  Width*RightColumWidth 90 ];;
                    obj.TrackNumber.Position =                       [Width*RightColumnPosition Height - 470  Width*RightColumWidth 20 ];;
                    obj.DriftCorrectionPerformed.Position =          [Width*RightColumnPosition Height - 500  Width*RightColumWidth 20 ];;
                    obj.MetaData.Position =                          [Width*RightColumnPosition Height - 560  Width*RightColumWidth 50 ];;


                    %% default contents:
                    NickNameTitle.Text =                         'Nickname:';
                    KeywordsTitle.Text =                         'Keyword:';

                    FolderTitle.Text =                            'Movie folder:';
                    FolderAnnotationTitle.Text =                  'Annotation folder';

                    AttachedFileTitle.Text =                    'Attached files:';
                    ListWithPathsTitle.Text =                    'Attached paths:';
                    PointersPerFileTitle.Text =                   'Attached pointers:';
                    FileCouldNotBeReadTitle.Text =               'File could not be read status:';

                    ImageMapTitle.Text  =                     'Image map:';
                    TrackNumberTitle.Text  =                    'Number of tracks:';
                    DriftCorrectionPerformedTitle.Text  =       'Drif correction was performed:';
                    MetaDataTitle.Text  =                       'Meta-data from file';


                    obj.MainFigure =                fig;

           
            
          
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

