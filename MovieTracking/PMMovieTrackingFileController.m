classdef PMMovieTrackingFileController
    %PMMOVIETRACKINGCONTROLLER View of the file aspects of PMMovieTracking
    %   mediates interaction between PMMovieTrackingFileView and PMMovieTracking to ; 
    
    properties (Access = private)
        Model
        View
    end
    
    methods % initialize
        
        function obj =      PMMovieTrackingFileController(varargin)
            %PMMOVIETRACKINGCONTROLLER Construct an instance of this class
            %   takes 0 or 2 arguments
            % 1: PMMovieTrackingFileView
            % 2: PMMovieTracking
            
            switch length(varargin)
               
                case 0
                    obj.View = PMMovieTrackingFileView;
                    obj.Model = PMMovieTracking;
                    
                case 2
                    obj.View = varargin{1};
                    obj.Model = varargin{2};
                    
                otherwise
                    error('Wrong input.')
                
            end
            
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
        
      
        function obj =      show(obj)
            %SHOW creates view or brings view to forefront;
            % Also creates new view if currently no valide view available;
          
            if ~isempty(obj.View) && ~isempty(obj.View.getFigure)   && isvalid(obj.View.getFigure)
            
            else
                obj.View =       obj.View.setMainFigure;
                obj.View =       obj.View.setPanels;
               
            end
            obj =       obj.updateView;
            
        end
        
        function view = getView(obj)
           view = obj.View; 
        end
        
        function obj = updateWith(obj, varargin)
            % UPDATEWITH updates view with new content
            % takes 1 argument
            % 1: PMMovieTracking;
            
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
        
        
     
        
         function obj = setCallbacks(obj, varargin)
             obj.View = obj.View.setCallbacks(varargin{:});
         end
         
        function NickName =  getNickNameFromView(obj)
            NickName = obj.View.getNickName;
        end
        
        function Keyword =  getKeywordFromView(obj)
            Keyword =   obj.View.getKeywords;
        end
        
        function obj =   updateView(obj)
                
            if ~isempty(obj.View) && isa(obj.View, 'PMMovieTrackingFileView') && ~isempty(obj.View.getFigure) && isvalid(obj.View.getFigure)
                 figure(obj.View.getFigure)
                 obj.View =     obj.View.updateWith(obj.Model);
                 
            end
           
           
           end
        
         
      
        

    end
    
    methods (Access = private)
        
        function FigureHandle = getFigureHandle(obj)
           FigureHandle = obj.View.getFigure;
        end
        
     
        
    end
end

