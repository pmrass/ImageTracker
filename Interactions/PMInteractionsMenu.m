classdef PMInteractionsMenu
    %PMINTERACTIONSMENU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        MainFigure
        Main
        ShowInteractionsView
    end
    
    methods
        function obj = PMInteractionsMenu(varargin)
            %PMINTERACTIONSMENU Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                    obj.MainFigure = varargin{1};
                    
                otherwise
                    error('Wrong input.')
                
            end
            
            obj =   obj.setMenu;
            
        end
        
        function obj = setCallbacks(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 1
                     obj.ShowInteractionsView.MenuSelectedFcn =                  varargin{1};
                otherwise
                    error('Wrong input.')
                
            end
        end
        
       
    end
    
    methods (Access = private)
        
        function obj = setMenu(obj)
            
            
                obj.Main=                                            uimenu(obj.MainFigure);
                obj.Main.Label=                                      'Interactions';

                obj.ShowInteractionsView=                                            uimenu(obj.Main);
                obj.ShowInteractionsView.Label=                                      'Set interaction parameters';
               
        end
        
        
            
            
        
    end
end

