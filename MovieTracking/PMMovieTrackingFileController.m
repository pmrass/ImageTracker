classdef PMMovieTrackingFileController
    %PMMOVIETRACKINGCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Model
        View
    end
    
    
    methods
        
        function obj =      PMMovieTrackingFileController
            %PMMOVIETRACKINGCONTROLLER Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function obj = setView(obj)
            obj.View = PMMovieTrackingFileView;
        end
        
        function obj = set.View(obj, Value)
            assert(isa(Value, 'PMMovieTrackingFileView'), 'Invalid argument type.')
            obj.View = Value;
        end
        
        function obj =                                  resetView(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
          
            if ~isempty(obj.View) && isvalid(obj.View.MainFigure)
            
            else
                obj =   obj.setView;
                obj =   obj.updateView;
            end
            
        end
        
        function obj = updateWith(obj, varargin)
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
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
                
            if ~isempty(obj.View) && isvalid(obj.View.MainFigure)
                 figure(obj.View.MainFigure)
            
                obj.View.NickName.Value =                   obj.Model.getNickName;
                if ~isempty(obj.Model.getKeywords)
                    % this shows only the first keyword; in a future version
                    % there should be options to show and change more than first keyword;
                    obj.View.Keywords.Value =               obj.Model.getKeywords{1}; 
                else
                    obj.View.Keywords.Value =         '';
                end
                obj.View.Folder.Items =               {obj.Model.getMovieFolder};
                obj.View.FolderAnnotation.Items =     {obj.Model.getPathOfMovieTrackingFile};
                obj.View.AttachedFiles.Items =        obj.Model.getLinkedMovieFileNames;
                obj.View.ListWithPaths.Items =        obj.Model.getPathsOfImageFiles;
                obj.View.PointersPerFile.Items =      cellfun(@(x) x, obj.Model.getPathsOfImageFiles, 'UniformOutput', false);

                obj.View.TrackNumber.Text =           num2str(obj.Model.getNumberOfTracks);
                obj.View.DriftCorrectionPerformed.Value =     obj.Model.testForExistenceOfDriftCorrection;
                InfoText =                            obj.Model.getMetaDataInfoText;

                obj.View.MetaData.Items =        InfoText;
                obj.View.ImageMap.Data =         obj.Model.getSimplifiedImageMapForDisplay;

                
            end
           
           
        end
        
    
         function obj = setCallbacks(obj, varargin)
             NumberOfArguments= length(varargin);
             switch NumberOfArguments
                 case 2 
                        obj.View.NickName.ValueChangedFcn =         varargin{1};
                        obj.View.Keywords.ValueChangedFcn =         varargin{2};
                 otherwise
                     error('Wrong input.')
             end
            
         end
         
        function FigureHandle = getFigureHandle(obj)
           FigureHandle = obj.View.MainFigure;
        end
        
        function NickName =  getNickNameFromView(obj)
            NickName = obj.View.NickName.Value;
        end
        
        function Keyword =  getKeywordFromView(obj)
            Keyword =   obj.View.Keywords.Value;
        end
        

    end
    
    methods (Access = private)
        
        
        
    end
end

