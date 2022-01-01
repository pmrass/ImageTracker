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
            %   takes 0 arguments
            
            switch length(varargin)
               
                case 0
                    
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
        
        function obj =      setView(obj)
            obj.View =      PMMovieTrackingFileView;
        end
        
        function obj =      resetView(obj)
            %RESETVIEW resets view
            % Also creates new view if currently no valide view available;
          
            if ~isempty(obj.View) && isvalid(obj.View.getFigure)
            
            else
                obj =       obj.setView;
               
            end
            
             obj =       obj.updateView;
            
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
         
      
        

    end
    
    methods (Access = private)
        
           function obj =   updateView(obj)
                
            if ~isempty(obj.View) && isvalid(obj.View.getFigure)
                 figure(obj.View.getFigure)
                 obj.View =     obj.View.updateWith(obj.Model);
                 
            end
           
           
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
end

