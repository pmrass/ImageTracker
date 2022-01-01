classdef PMMovieTrackingSummary
    %PMMOVIETRACKINGSUMMARY summary of PMMovieTracking object
    %   This summary is used to to add key features that are needed for filtering etc. from PMMovieTracking;
    
    properties
        
        % core data: unique identifier plus connected movies;
          
    end
    
    properties (Access = private)
        Folder =                        '' % movie-folder 
        Keywords =                      cell(0,1);
        
        
        % data are stored but are typically derived and reset from outside;
        % however resets can be time-consuming, therefore they are also stored in this object;
        NickName =                      ''
        DataType =                      ''
        DriftCorrectionWasPerformed =   false
        TrackingWasPerformed =          false
        MappingWasPerformed =           false
        ChannelSettingsAreOk =          true
        
        
    end
    
    methods
        
        function obj = PMMovieTrackingSummary(varargin)
            %PMMOVIETRACKINGSUMMARY Construct an instance of this class
            %   Detailed explanation goes here
            
            switch length(varargin)
                case 0
                    
                case 1
                        
                    movieTrackingObject = varargin{1};
                    fprintf('Create @PMMovieTrackingSummary for')
                    if isempty(movieTrackingObject)
                    else
                        fprintf('PMMovieTracking object "%s".\n', movieTrackingObject.getNickName)     
                        obj.NickName =                          movieTrackingObject.getNickName;
                        obj.Folder =                            movieTrackingObject.getMovieFolder;
                        obj.DataType =                          movieTrackingObject.getDataType;
                        obj.Keywords =                          movieTrackingObject.getKeywords;

                        obj.DriftCorrectionWasPerformed =       movieTrackingObject.testForExistenceOfDriftCorrection;
                        obj.TrackingWasPerformed =              movieTrackingObject.testForExistenceOfTracking;

                        

                        
                    end
                   
                case 2
                

            
                
            end
           
        end
        
        %% accessor:
        function type = getDataType(obj)
           type = obj.DataType; 
        end
        
        function type = getTrackingWasPerformed(obj)
           type = obj.TrackingWasPerformed; 
        end
        
        
       
           
        
           
           function [Value] =            getMovieFolder(obj)
              Value = obj.Folder;
           end
           
         
            function [Value] =            getKeywords(obj)
              Value = obj.Keywords;
           end
           
           
            function String =            getNickName(obj)
                String = obj.NickName;
           end
           
           function [obj] =            setNickName(obj, String)
                obj.NickName =       String;
           end
            
        function obj = set.NickName(obj, Value)
            assert(ischar(Value), 'Wrong argument type.')
            obj.NickName =   Value; 
        end
        
          function obj = setMovieFolder(obj, Value)
              obj.Folder = Value;   
          end
          
          function obj = set.Folder(obj, Value)
              assert(ischar(Value), 'Invalid argument type.')
              obj.Folder = Value;   
          end
          
           function obj =        setKeywords(obj, Value)
                obj.Keywords{1,1} =                   Value;
           end
          
           function obj = set.Keywords(obj, Value)
               assert(iscellstr(Value), 'Invalid argument type.')
               obj.Keywords =   Value;
           end
   

    end
    

end

