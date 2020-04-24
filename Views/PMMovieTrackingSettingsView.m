classdef PMMovieTrackingSettingsView
    %PMMOVIETRACKINGSETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MainFigure
        
        FolderAnnotation
        ListWithPaths
        
        NickName
        Keywords
        
    end
    
    methods

        
        function obj = PMMovieTrackingSettingsView(varargin)
            %PMMOVIETRACKINGSETTINGS Construct an instance of this class
            %   Detailed explanation goes here
            
            ScreenSize =                get(0,'screensize');

            Height =                    ScreenSize(4)*0.8;
            Left =                      ScreenSize(3)*0.6;
            Width =                     ScreenSize(3)*0.3;
            
            fig =                       uifigure;
           
            fig.Position =              [Left 0 Width Height];
            
            obj.MainFigure =            fig;
            
            NickNameLabel =             uilabel(fig);
            obj.NickName =              uieditfield(fig);
            obj.Keywords =              uilistbox(fig);
            
            
            NickNameLabel.Text =        'Title';
            NickNameLabel.Position =    [20 Height - 30 Width - 40 30 ];
            
            
            obj.NickName.Value =        'New sample';
            obj.NickName.Position =      [Width/2 Height - 30  Width/2 - 40 30 ];
            
            obj.Keywords.Position =     [Width/2, Height-60-90, Width/2-40, 90  ];
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

