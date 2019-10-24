function CleanupModel
%CLEANUPMODEL Summary of this function goes here
%   Detailed explanation goes here


FileName = '/Users/paulusmrass/Documents/Cannon_DataMac_Projects/Flu/LiveImaging_AntibodyStain_Version3.mat';


load(FileName)

NumberOfMovies = size(ImagingProject.ListhWithMovieObjects,1);

for MovieIndex=1:NumberOfMovies
    
    
   
    
   
        
        NumberOfFrames =    size(ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingCellForTime,1);
    
    
        for CurrentFrame = 1:NumberOfFrames
            
            if CurrentFrame<= size(ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingInfoCellForTime,1)
                
                 CurrentSegmentationInfos =   ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingInfoCellForTime{CurrentFrame,1};
            
                    

                    
                    NumberOfMasks =     size(ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingCellForTime{CurrentFrame,1},1);
                    ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingCellForTime{CurrentFrame,1}(1:NumberOfMasks,7) = CurrentSegmentationInfos(1:NumberOfMasks,1);

                
                    for CurrentMask= 1:NumberOfMasks
                        
                        
                        
                          if isempty(ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingCellForTime{CurrentFrame,1}{CurrentMask,7})

                            ImagingProject.ListhWithMovieObjects{MovieIndex, 1}.Tracking.TrackingCellForTime{CurrentFrame,1}{CurrentMask,7} = PMSegmentationCapture;
                        end
                        
                        
                    end
                  
                
            end
            
            
           
        end
        
         
    

   
    
end


end


