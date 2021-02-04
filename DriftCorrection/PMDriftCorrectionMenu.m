classdef PMDriftCorrectionMenu
    %PMDRIFTCORRECTIONMENU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MainFigure
        ApplyManualDriftCorrection
        EraseAllDriftCorrections
        
    end
    
    methods
        function obj = PMDriftCorrectionMenu(MainFigure)
            %PMDRIFTCORRECTIONMENU Construct an instance of this class
            %   Detailed explanation goes here
            obj.MainFigure = MainFigure;
            
             MainDriftMenu=                                            uimenu(MainFigure);
            MainDriftMenu.Label=                                      'Drift correction';
            MainDriftMenu.Tag=                                        'MainDriftMenu';

            obj.ApplyManualDriftCorrection=                                uimenu(MainDriftMenu);
            obj.ApplyManualDriftCorrection.Label=                          'Apply manual drift correction';
            obj.ApplyManualDriftCorrection.Tag=                            'ApplyManualDriftCorrection';
            obj.ApplyManualDriftCorrection.Separator=                      'on';
            obj.ApplyManualDriftCorrection.Enable=                         'on';

            obj.EraseAllDriftCorrections=                                  uimenu(MainDriftMenu);
            obj.EraseAllDriftCorrections.Label=                            'Erase all drift corrections';
            obj.EraseAllDriftCorrections.Tag=                              'EraseAllDriftCorrections';
            obj.EraseAllDriftCorrections.Enable=                           'on';
            
        end
        
        function obj = method1(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
           

        end
    end
end

