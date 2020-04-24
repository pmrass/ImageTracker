classdef PMMovieTrackingSummary
    %PMMOVIETRACKINGSUMMARY summary of PMMovieTracking object
    %   This summary is used to to add key features that are needed for filtering etc. from PMMovieTracking;
    
    properties
        
        NickName =                      ''
        Folder =                        '' % movie-folder
        AttachedFiles =                 '' % attached files
        DataType =                      ''
        Keywords =                      cell(0,1);
        DriftCorrectionWasPerformed =   false
        TrackingWasPerformed =          false
        MappingWasPerformed =           false
        ChannelSettingsAreOk =          false
        
        
        
    end
    
    methods
        
        function obj = PMMovieTrackingSummary(movieTrackingObject)
            %PMMOVIETRACKINGSUMMARY Construct an instance of this class
            %   Detailed explanation goes here
            
            fprintf('Create @PMMovieTrackingSummary for')
            
            
            if isempty(movieTrackingObject)
                
                fprintf('empty default object.\n')
                
            else
                
                fprintf('PMMovieTracking object "%s".\n', movieTrackingObject.NickName)
                     
                obj.NickName =                          movieTrackingObject.NickName;
                obj.AttachedFiles =                     movieTrackingObject.AttachedFiles;
                obj.Folder =                            movieTrackingObject.Folder;
                obj.DataType =                          movieTrackingObject.getDataType;
                obj.Keywords =                          movieTrackingObject.Keywords;
                
                if isempty(movieTrackingObject.DriftCorrection)
                     obj.DriftCorrectionWasPerformed =       false;
                    
                else
                     obj.DriftCorrectionWasPerformed =       movieTrackingObject.DriftCorrection.testForExistenceOfDriftCorrection;
                    
                end
                
               if isempty(movieTrackingObject.Tracking) || isempty(movieTrackingObject.Tracking.Tracking)
                   obj.TrackingWasPerformed =               false;
               else
                    obj.TrackingWasPerformed =              movieTrackingObject.Tracking.NumberOfTracks>=1;
               end
               
               
                obj.MappingWasPerformed =               ~isempty(movieTrackingObject.MetaData);
                
                if ~isempty(movieTrackingObject.MetaData)
                    NumberOfChannels =                      movieTrackingObject.MetaData.EntireMovie.NumberOfChannels;
                    obj.ChannelSettingsAreOk =              movieTrackingObject.verifyChannels(NumberOfChannels);
                else
                    obj.ChannelSettingsAreOk =              false;
                end
                
                
            end
           
        end
        
          function [obj] =                            resetFolder(obj, Folder)
            obj.Folder =                            Folder;
            
            
        end
        
        
    end
end

