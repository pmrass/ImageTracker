classdef PMTrackInfo
    %PMTRACKINFO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       
        Finalized = false
        TrackID
    end
    
    methods
        function obj = PMTrackInfo(TrackId)
            %PMTRACKINFO Construct an instance of this class
            %   Detailed explanation goes here
            obj.TrackID = TrackId;
        end
        
        function obj = setTrackAsFinished(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Finalized = true;
        end
        
         function obj = setTrackAsUnfinished(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Finalized = false;
         end
        
         function status = getFinishedStatus(obj)
             switch obj.Finalized
                 
                 case false
                     status = 'Unfinished';
                 case true
                     status = 'Finished';
                     
             end
             
         end
         
         
         function TrackID = getTrackID(obj)
             TrackID = obj.TrackID;
             
         end
        
         
    end
end

