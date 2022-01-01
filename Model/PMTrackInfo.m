classdef PMTrackInfo
    %PMTRACKINFO manages main logistics information of track
    %   has track ID, tells whether track is finished and contains "address";
    % address: matrix with two columns: 
    % column 1: all frame numbers of track; column 2: "row" where track is located at each frame;
    
    properties
       
        Finalized = false
        TrackID
        
    end
    
    properties (Access = private)
       SegmentationAddress 
    end
    
    methods % initialize
        
        function obj = PMTrackInfo(TrackId)
            %PMTRACKINFO Construct an instance of this class
            %  takes 1 argument:
            % 1: track ID
            obj.TrackID = TrackId;
        end
        
         function obj = set.SegmentationAddress(obj, Value)
            
            if isempty(Value)
                 
            else
                 assert(isnumeric(Value) && ismatrix(Value) && size(Value, 2) == 2, 'Wrong input.')
            end
            obj.SegmentationAddress = Value;
            
         end
        
        
        
    end
    
    methods
      
        function obj = resetDefaults(obj)
            obj = obj.setTrackAsUnfinished;
            
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
            obj.SegmentationAddress = '';
         end
        
         function status = getFinishedStatus(obj)
              
              switch obj.Finalized
                  
                  case true
                      status = 'Finished';
                  otherwise
                      status = 'Unfinished';
              end
 
                    
             
         end
         
         
         function TrackID = getTrackID(obj)
             TrackID = obj.TrackID;
             
         end
         
         function obj = setSegmentationAddress(obj, Value)
            obj.SegmentationAddress = Value; 
         end
         
         function value = getSegmentationAddress(obj)
             % GETSEGMENTATIONADDRESS returns segmentation address;
             % segmentation address is matrix with two columns:
             value = obj.SegmentationAddress;
         end
         
         function value = getExistenceOfSegmentationAddress(obj)
             if isempty(obj.SegmentationAddress)
                value = false; 
             else
                 value = true;
             end
         end
         
        
        
         
    end
end

