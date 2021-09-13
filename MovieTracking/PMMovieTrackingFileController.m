classdef PMMovieTrackingFileController
    %PMMOVIETRACKINGCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Model
        View
    end
    
    methods % initialize
        
        function obj =      PMMovieTrackingFileController
            %PMMOVIETRACKINGCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function obj = set.View(obj, Value)
            assert(isa(Value, 'PMMovieTrackingFileView') && isscalar(Value), 'Invalid argument type.')
            obj.View =      Value;
        end
        
        function obj = set.Model(obj, Value)
            assert(isa(Value, 'PMMovieTracking') && isscalar(Value), 'Invalid argument type.')
            obj.Model =      Value;
        end
         
    end
    
    
    methods
        
        function obj =      setView(obj)
            obj.View =      PMMovieTrackingFileView;
        end
        
        function obj =      resetView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
          
            if ~isempty(obj.View) && isvalid(obj.View.getFigure)
            
            else
                obj =       obj.setView;
                obj =       obj.updateView;
            end
            
        end
        
        function obj = updateWith(obj, varargin)
            
            switch length(varargin)
                case 1
                    Type = class(varargin{1});
                    switch Type
                        case 'PMMovieTracking'
                            obj.Model = varargin{1};
                        otherwise
                            error('Wrong input.')
                    end
                otherwise
                    error('Wrong input.')
            end
            obj =   obj.updateView;
        end
        
        
        function obj =   updateView(obj)
                
            if ~isempty(obj.View) && isvalid(obj.View.getFigure)
                 figure(obj.View.getFigure)
                 obj.View =     obj.View.updateWith(obj.Model);
                 
            end
           
           
        end
        
         function obj = setCallbacks(obj, varargin)
             obj.View = obj.View.setCallbacks(varargin{:});
         end
         
        function FigureHandle = getFigureHandle(obj)
           FigureHandle = obj.View.getFigure;
        end
        
        function NickName =  getNickNameFromView(obj)
            NickName = obj.View.getNickName;
        end
        
        function Keyword =  getKeywordFromView(obj)
            Keyword =   obj.View.getKeywords;
        end
        

    end
    
    methods (Access = private)
        
        
        
    end
end

