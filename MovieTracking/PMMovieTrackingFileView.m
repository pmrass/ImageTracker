classdef PMMovieTrackingFileView
    %PMMOVIETRACKINGSETTINGS To view file-properties of image-source;
    %   shows
    %   nickname
    %   keywords
    %   image-folder
    %   annotation-folder
    %   movie-filenames
    %   movie-paths
    %   movie-pointers
    %   indicate whether file could be read
    %   image-map table
    %   number of tracks
    %   whether drift correction was performed
    %   table with summary of meta-data
    

    properties (Access = private)
        
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
    
    properties (Constant, Access = private)
       
            RightColumnPosition     =       0.3;
            RightColumWidth =               0.68;

            LeftColumnPosition =            0.05;
            LeftColumWidth =               0.18;

        
    end
    
    methods

        
        function obj = PMMovieTrackingFileView(varargin)
            %PMMOVIETRACKINGSETTINGS Construct an instance of this class
            %   takes zero arguments:
            
            switch length(varargin)
               
                case 0
                    obj =       obj.setMainFigure;
                    obj =       obj.setPanels;
                    
                otherwise
                    error('Wrong input.')
                
            end
          
              
        end
        
        function Value = getFigure(obj)
            Value = obj.MainFigure;
        end
        
        function obj = updateWith(obj, Value)
            % UPDATEWITH updates states of individual view;
            % takes 1 argument:
            % 1: PMMovieTracking
            
            switch class(Value)
               
                case 'PMMovieTracking'
                    
                    assert(isscalar(Value), 'Wrong input.')
                    
                    obj.NickName.Value =                   Value.getNickName;
                    if ~isempty(Value.getKeywords)
                        % this shows only the first keyword; in a future version
                        % there should be options to show and change more than first keyword;
                        obj.Keywords.Value =                Value.getKeywords{1}; 
                    else
                        obj.Keywords.Value =                '';
                    end
                    obj.Folder.Items =                      {Value.getMovieFolder};
                    obj.FolderAnnotation.Items =            {Value.getPathOfMovieTrackingForSingleFile};
                    obj.AttachedFiles.Items =               Value.getLinkedMovieFileNames;
                    obj.ListWithPaths.Items =               Value.getPathsOfImageFiles;
                    obj.PointersPerFile.Items =             cellfun(@(x) x, Value.getPathsOfImageFiles, 'UniformOutput', false); % correct?

                    obj.TrackNumber.Text =                  num2str(Value.getNumberOfTracks);
                    obj.DriftCorrectionPerformed.Value =    Value.testForExistenceOfDriftCorrection;
                    obj.MetaData.Items =                    Value.getMetaDataInfoText;
                    obj.ImageMap.Data =                     Value.getSimplifiedImageMapForDisplay;
   
                otherwise
                    error('Wrong input.')
                
                
            end
            
            
            
            
        end
        
        function obj =   setCallbacks(obj, varargin)
             NumberOfArguments= length(varargin);
             switch NumberOfArguments
                 case 2 
                        obj.NickName.ValueChangedFcn =         varargin{1};
                        obj.Keywords.ValueChangedFcn =         varargin{2};
                 otherwise
                     error('Wrong input.')
             end
             
        end
        
        function NickName = getNickName(obj)
             NickName = obj.NickName.Value;
        end
        
        function NickName = getKeywords(obj)
             NickName = obj.Keywords.Value;
        end
        
       
       
    end
    
    methods (Access = private)
        
        function obj = setMainFigure(obj)
            
                ScreenSize =              get(0,'screensize');

                Height =                  ScreenSize(4) * 0.8;
                Left =                    ScreenSize(3)  * 0.5;
                Width =                   ScreenSize(3) * 0.45;

                fig =                     uifigure;
                fig.Position =            [Left 0 Width Height];
                fig.Tag =                 obj.Tag;
                obj.MainFigure =          fig;

        end
        
        
        function obj = setPanels(obj)
            
            ScreenSize =              get(0,'screensize');
            Height =                  ScreenSize(4) * 0.8;
            Width =                   ScreenSize(3) * 0.45;

            NickNameTitle =                         uilabel(obj.MainFigure);
            NickNameTitle.Text =                         'Nickname:';
            NickNameTitle.Position =                         [Width*obj.LeftColumnPosition Height - 30  Width*obj.LeftColumWidth 20 ];


            KeywordsTitle =                         uilabel(obj.MainFigure);
            KeywordsTitle.Position =                         [Width*obj.LeftColumnPosition Height - 60  Width*obj.LeftColumWidth 20 ];
            KeywordsTitle.Text =                         'Keyword:';


            FolderTitle =                            uilabel(obj.MainFigure);
            FolderTitle.Text =                            'Movie folder:';
            FolderTitle.Position =                            [Width*obj.LeftColumnPosition Height - 110  Width*obj.LeftColumWidth 20 ];

            FolderAnnotationTitle =                  uilabel(obj.MainFigure);
            FolderAnnotationTitle.Text =                  'Annotation folder';
            FolderAnnotationTitle.Position =                  [Width*obj.LeftColumnPosition Height - 150  Width*obj.LeftColumWidth 20 ];

            ImageMapTitle =                         uilabel(obj.MainFigure);
            ImageMapTitle.Text  =                     'Image map:';
            ImageMapTitle.Position  =                     [Width*obj.LeftColumnPosition Height - 450  Width*obj.LeftColumWidth 20 ];

            TrackNumberTitle =                      uilabel(obj.MainFigure);
            TrackNumberTitle.Text  =                    'Number of tracks:';
            TrackNumberTitle.Position  =                    [Width*obj.LeftColumnPosition Height - 470  Width*obj.LeftColumWidth 20 ];

            DriftCorrectionPerformedTitle =         uilabel(obj.MainFigure);
            DriftCorrectionPerformedTitle.Text  =       'Drif correction was performed:';
            DriftCorrectionPerformedTitle.Position  =       [Width*obj.LeftColumnPosition Height - 500  Width*obj.LeftColumWidth 20 ];

            MetaDataTitle =                         uilabel(obj.MainFigure);
            MetaDataTitle.Text  =                       'Meta-data from file';
            MetaDataTitle.Position  =                       [Width*obj.LeftColumnPosition Height - 560  Width*obj.LeftColumWidth 20 ];

            AttachedFileTitle =                     uilabel(obj.MainFigure);
            AttachedFileTitle.Text =                    'Attached files:';
            AttachedFileTitle.Position =                     [Width*obj.LeftColumnPosition Height - 200  Width*obj.LeftColumWidth 40 ];

            ListWithPathsTitle =                     uilabel(obj.MainFigure);
            ListWithPathsTitle.Text =                    'Attached paths:';
            ListWithPathsTitle.Position =                    [Width*obj.LeftColumnPosition Height - 250  Width*obj.LeftColumWidth 40 ];

            PointersPerFileTitle =                   uilabel(obj.MainFigure);
            PointersPerFileTitle.Text =                   'Attached pointers:';
            PointersPerFileTitle.Position =                  [Width*obj.LeftColumnPosition Height - 300  Width*obj.LeftColumWidth 40 ];

            FileCouldNotBeReadTitle =                uilabel(obj.MainFigure);
            FileCouldNotBeReadTitle.Text =               'File could not be read status:';
            FileCouldNotBeReadTitle.Position =               [Width*obj.LeftColumnPosition Height - 320  Width*obj.LeftColumWidth 20 ];


            obj.NickName =                          uieditfield(obj.MainFigure);
            obj.NickName.Position =                  [Width*obj.RightColumnPosition Height - 30  Width*obj.RightColumWidth 20 ];

            obj.Keywords =                          uieditfield(obj.MainFigure);
            obj.Keywords.Position =                  [Width*obj.RightColumnPosition Height - 60  Width*obj.RightColumWidth 20 ];

            obj.Folder =                            uilistbox(obj.MainFigure);
            obj.Folder.Position =                    [Width*obj.RightColumnPosition Height - 110  Width*obj.RightColumWidth 40 ];
            
            obj.FolderAnnotation =                  uilistbox(obj.MainFigure);
            obj.FolderAnnotation.Position =          [Width*obj.RightColumnPosition Height - 150  Width*obj.RightColumWidth 40 ];

            obj.AttachedFiles =                     uilistbox(obj.MainFigure);
            obj.AttachedFiles.Position =             [Width*obj.RightColumnPosition Height - 200  Width*obj.RightColumWidth 40 ];

            obj.ListWithPaths =                     uilistbox(obj.MainFigure);
            obj.ListWithPaths.Position =             [Width*obj.RightColumnPosition Height - 250  Width*obj.RightColumWidth 40 ];

            obj.PointersPerFile =                   uilistbox(obj.MainFigure);
            obj.PointersPerFile.Position =           [Width*obj.RightColumnPosition Height - 300  Width*obj.RightColumWidth 40 ];

            obj.FileCouldNotBeRead =                uilabel(obj.MainFigure);
            obj.FileCouldNotBeRead.Position =        [Width*obj.RightColumnPosition Height - 320  Width*obj.RightColumWidth 20 ];

            obj.ImageMap =                          uitable(obj.MainFigure);
            obj.ImageMap.Position =                          [Width*obj.RightColumnPosition Height - 450  Width*obj.RightColumWidth 90 ];

            obj.TrackNumber =                       uilabel(obj.MainFigure);
            obj.TrackNumber.Position =                       [Width*obj.RightColumnPosition Height - 470  Width*obj.RightColumWidth 20 ];

            obj.DriftCorrectionPerformed =          uicheckbox(obj.MainFigure);
            obj.DriftCorrectionPerformed.Position =          [Width*obj.RightColumnPosition Height - 500  Width*obj.RightColumWidth 20 ];

            obj.MetaData =                          uilistbox(obj.MainFigure);
            obj.MetaData.Position =                          [Width*obj.RightColumnPosition Height - 560  Width*obj.RightColumWidth 50 ];


            
            
            
        end
        
        

               
          
           
        
        
    end
    
end

