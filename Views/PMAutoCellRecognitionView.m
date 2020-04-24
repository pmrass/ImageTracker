classdef PMAutoCellRecognitionView
    %PMMOVIETRACKINGSETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MainFigure
        
        FolderAnnotation
        ListWithPaths
        
        ListWithChannels
        ListWithFrames
        ListWithPlaneSettings
        
        FilterForHighDensityDistance
        FilterForHighDensityNumber
        
    end
    
    methods

        
        function obj = PMAutoCellRecognitionView(varargin)
            %PMMOVIETRACKINGSETTINGS Construct an instance of this class
            %   Detailed explanation goes here
            
            
            InputArguments =                            length(varargin);
           
            
            ScreenSize =                                get(0,'screensize');

            Height =                                    ScreenSize(4)*0.8;
            Left =                                      ScreenSize(3)*0.6;
            Width =                                     ScreenSize(3)*0.3;
            
            fig =                                       uifigure;
           
            fig.Position =                              [Left 0 Width Height];
            
            obj.MainFigure =                            fig;
            
            ListWithChannelsTitle =                       uilabel(fig);
            obj.ListWithChannels =                        uitable(fig);
            
            ListWithFramesTitle =                       uilabel(fig);
            obj.ListWithFrames =                        uitable(fig);
            
            ListWithPlaneSettingsTitle =                uilabel(fig);
            obj.ListWithPlaneSettings =                 uitable(fig);
            
            FilterForHighDensityTitle =                 uilabel(fig);
            
            obj.FilterForHighDensityDistance =              uieditfield(fig);
            FilterForHighDensityDistanceTitle =                  uilabel(fig);
            obj.FilterForHighDensityNumber =                uieditfield(fig);
            FilterForHighDensityNumberTitle =                  uilabel(fig);
            
            
            switch InputArguments
                
                case 1 
                
                
                
            end

            ListWithChannelsTitle.Text =                        'Channels';   
            ListWithChannelsTitle.Position =                    [Width*0.05 Height - 30  Width*0.4 20 ];
            
             obj.ListWithChannels.Position =                    [Width*0.05 Height - 80  Width*0.4 50 ];
            
            
            ListWithFramesTitle.Text =                          'Loaded frames:';
            ListWithFramesTitle.Position =                      [Width*0.05 Height - 100 Width*0.2 20 ];

            % obj.ListWithFrames.Value =                        'New sample';
            obj.ListWithFrames.Position =                       [Width*0.05 Height - 120-200  Width*0.2 200 ];
            obj.ListWithFrames.ColumnName =                     {'Available frames'};

            ListWithPlaneSettingsTitle.Text =                   'Plane settings:';
            ListWithPlaneSettingsTitle.Position =               [Width*0.3, Height-100, Width*0.65, 20  ];

            obj.ListWithPlaneSettings.Position =                [Width*0.3, Height-120-200, Width*0.65, 200  ];

            obj.ListWithPlaneSettings.ColumnName =              {'Minimum radius', 'Maximum radius', 'Sensitivity', 'EdgeThreshold'};

             FilterForHighDensityTitle.Position =               [Width*0.05 Height - 340 Width*0.9 20 ]; 
             FilterForHighDensityTitle.Text =                  'Filter out dense events:';
            
             obj.FilterForHighDensityDistance.Position =         [Width*0.3 Height - 360 Width*0.2 20 ];     
            obj.FilterForHighDensityNumber.Position =           [Width*0.8 Height - 360 Width*0.2 20 ];     
            
            FilterForHighDensityDistanceTitle.Position =          [Width*0.05 Height - 360 Width*0.2 20 ];   
            FilterForHighDensityDistanceTitle.Text =            'Diameter (radius)';

            FilterForHighDensityNumberTitle.Position =           [Width*0.55 Height - 360 Width*0.2 20 ];   
            FilterForHighDensityNumberTitle.Text =              'Maximum number:';
            
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

