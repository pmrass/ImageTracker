classdef PMInteractionContacts
    %PMINTERACTINCONTACTS Quantifies number of contacts between searchers and targets;
    %   uses two PMTrackingNavigation objects as datasource
    % the difference to PMInteractionsCapture is that the target is not just a "structure" of positive pixels;
    % instead both search and targets are defined as "masks" (which are retrieved from PMMovieTracking);
    
    properties (Access = private)
        
        MovieTrackingSearchers
        MovieTrackingTargets
        
        SearcherSquareSize =    100;
        
        DistanceLimit =         30;
        
        SegmentLength
        
    end
    
    methods
        
        function obj = PMInteractionContacts(varargin)
            %PMINTERACTINCONTACTS Construct an instance of this class
            %   takes 2 arguments:
            % 1: PMTrackingNavigation of searchers
            % 2: PMTrackingNavigation of targets
            switch length(varargin)
                
                case 1
                    obj.MovieTrackingSearchers =    varargin{1};
                    
                case 2
                    obj.MovieTrackingSearchers =    varargin{1};
                    obj.MovieTrackingTargets =      varargin{2};
 
                otherwise
                    error('Wrong input.')
                
                
            end
        end
        
     
    end
    
    methods % GETTERS contact number
        
           function ListWithContactNumbers =    getNumberOfContactsForAllTargets(obj)
            %GETNUMBEROFCONTACTSFORALLTARGETS returns a list of the contacts;
            % vector, each row for each "target", number of searchers that are within defined proximity;
                    TargetSegmentations =        obj.MovieTrackingSearchers.getSortedTrackingData;
                    
                    SearcherSegmentations =      obj.MovieTrackingTargets.getSortedTrackingData;
                   
                     
                    ListWithContactNumbers = nan(size(TargetSegmentations,1 ), 1);
                    
                    for TargetIndex = 1 : size(TargetSegmentations,1 )
                        
                        CurrentTargetSegmentation =             TargetSegmentations(TargetIndex, :);
                        
                        MyMask =                                PMMask(CurrentTargetSegmentation);
                        
                        PrefilteredSearcherSegmentations =      obj.preFilterSearchersByTargetDistance(...
                                                                        SearcherSegmentations, ...
                                                                        MyMask.getX, ...
                                                                        MyMask.getY ...
                                                                        );

                        NumberOfContacts =                      obj.getNumberOfContactsBetweenTargetAndSearcherList(...
                                                                    MyMask.getMaskPixels,...
                                                                    PrefilteredSearcherSegmentations...
                                                                );
                  
                        ListWithContactNumbers(TargetIndex, 1) =           NumberOfContacts;
                        
                    end
           end
        
    end
    
    methods % GETTERS: 
       
           function ListWithContactNumbers =    getNumberOfContactsForBoundaryList(obj, BoundaryList, SegmentLength)
               % GETNUMBEROFCONTACTSFORBOUNDARYLIST seems I used that at the begining;
               % seems this is the worse method of the two; consider deletion;
            
               % BoundaryList:
               
              % Row and column coordinates of boundary pixels, 
              % returned as a p-by-1 cell array, 
              % where p is the number of objects and holes. 
              % Each cell in the cell array contains a q-by-2 matrix. 
              % Each row in the matrix contains the row and column coordinates of a boundary pixel. 
              % q is the number of boundary pixels for the corresponding region.
               
               SearcherSegmentations =       obj.MovieTrackingSearchers.getSortedTrackingData;
               obj.SegmentLength =      SegmentLength;
               
               ListWithContactNumbers = cell(length(BoundaryList), 1);
                for targetIndex = 1 : length(BoundaryList)
                   
                    CurrentBoundary = BoundaryList{targetIndex};
                    
                    
                    SegmentLimits = 1 : obj.SegmentLength : size(CurrentBoundary, 1);
                    ListWithContactNumbersChild =   nan(length(SegmentLimits) - 1, 1);
                    
                    for index = 1 : length(SegmentLimits) - 1
                        
                        TargetPixels =                                  CurrentBoundary(SegmentLimits(index) : SegmentLimits(index + 1), :); 
                        TargetXPosition =                               round(mean(TargetPixels(:, 2)));
                        TargetYPosition =                               round(mean(TargetPixels(:, 1)));

                        PrefilteredSearcherSegmentations =              obj.preFilterSearchersByTargetDistance(SearcherSegmentations, TargetXPosition, TargetYPosition);

                        NumberOfContacts =                              obj.getNumberOfContactsBetweenTargetAndSearcherList(TargetPixels, PrefilteredSearcherSegmentations);

                        ListWithContactNumbersChild(index, 1) =         NumberOfContacts;

                    end
                    
                    
                    ListWithContactNumbers{targetIndex, 1} =            ListWithContactNumbersChild;
                    
                    
                end
                
                ListWithContactNumbers = vertcat(ListWithContactNumbers{:});
                
            
        end
        
    end
    
    methods (Access = private)
        
        function SelectedSearchers =    preFilterSearchersByTargetDistance(obj, SearcherTracking, TargetX, TargetY)
            % PREFILTERSEARCHERSBYTARGETDISTANCE filteres out searchers that are too distance from pre-filter rectangle;
            
                SearchXList =               cell2mat(SearcherTracking(:, 4));
                DistanceXTooHigh =          abs(TargetX - SearchXList) > obj.SearcherSquareSize;

                SearchYList =               cell2mat(SearcherTracking(:, 3));
                DistancyYTooHigh =          abs(TargetY - SearchYList) > obj.SearcherSquareSize;

                DistanceTooHigh =           max([DistanceXTooHigh, DistancyYTooHigh], [], 2);

                SelectedSearchers =         SearcherTracking;
                
                SelectedSearchers(DistanceTooHigh, :) = [];
                        
        end
        
        function NumberOfContacts =     getNumberOfContactsBetweenTargetAndSearcherList(obj, TargetPixels, SelectedSearchers)
            % GETNUMBEROFCONTACTSBETWEENTARGETANDSEARCHERLIST ;
            
                CandidateCellDistances = nan(size(SelectedSearchers, 1), 1);
                for SearchPixelIndex = 1 : size(SelectedSearchers, 1)
                    PixelsOfCurrentSearcher =                           SelectedSearchers{SearchPixelIndex, 6};
                    CandidateCellDistances(SearchPixelIndex, 1) =       obj.getShortestDistanceForPixels(...
                                                                            TargetPixels, PixelsOfCurrentSearcher);

                end

                CandidateCellDistances(CandidateCellDistances > obj.DistanceLimit, :) =     [];
                NumberOfContacts =                                                          length(CandidateCellDistances);
                        
        end
       
        function Minimum =              getShortestDistanceForPixels(obj, PixelListOne, PixelListTwo)
                AllDistances =      pdist2(PixelListOne(:, 1:2), PixelListTwo(:, 1:2));
                Minimum =           min(min(AllDistances));
                
                
        end
        
        
    end
end

