classdef PMImageTrackingDataRetrieval
    %PMIMAGETRACKINGDATARETRIEVAL for convenient manipulation and retrieval of tracking data;
    %   after specifying library, selected nicknames per group, allows retrieval of appropriate PMTrackingGroups;
    
    properties (Access = private) % keys for data access
        
        LibraryFileNamePerGroup
        InteractionFolderNamePerGroup
        
        GroupNames
        NicknamesPerGroup
        
        PlaneFilters
        
    end
    
    properties (Access = private)% set data
        GroupData
        
    end
    
    methods % initialize
        
        function obj = PMImageTrackingDataRetrieval(varargin)
            %PMIMAGETRACKINGDATARETRIEVAL Construct an instance of this class
            % takes 4 or 5 arguments:
            % 1: library filenames (for each group)
            % 2: interaction-folder names (for each group)
            % 3: group names
            % 4: nicknames per group
            % 5: plane filters

            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                
                case 4
                    
                    obj.GroupNames =                        varargin{3};

                    obj.LibraryFileNamePerGroup =           varargin{1};

                    obj.InteractionFolderNamePerGroup =     varargin{2};

                    obj.NicknamesPerGroup =                 varargin{4};
                    
                case 5
                    
                    obj.GroupNames =                        varargin{3};
                    obj.LibraryFileNamePerGroup =           varargin{1};
                    obj.InteractionFolderNamePerGroup =     varargin{2};
                    
                    obj.NicknamesPerGroup =                 varargin{4};
                    obj.PlaneFilters=                        varargin{5};
                    
                otherwise
                    error('Wrong input.')

            end
            
            obj = obj.setGroupData;
            
        end
        
        function obj = set.GroupNames(obj, Value)
            assert(iscellstr(Value) && isvector(Value), 'Wrong input.')
            obj.GroupNames = Value(:);
        end
        
        function obj = set.LibraryFileNamePerGroup(obj, Value)
            assert(iscellstr(Value) && isvector(Value) && length(Value) == obj.getNumberOfGroups, 'Wrong input.')
            obj.LibraryFileNamePerGroup = Value(:);
        end
        
        function obj = set.InteractionFolderNamePerGroup(obj, Value)
            assert(isempty(Value) || (iscell(Value) && isvector(Value) && length(Value) == obj.getNumberOfGroups), 'Wrong input.')
            obj.InteractionFolderNamePerGroup = Value(:);
        end
        
        function obj = set.NicknamesPerGroup(obj, Value)
            assert(iscell(Value) && isvector(Value) && length(Value) == obj.getNumberOfGroups, 'Wrong input.')
            obj.NicknamesPerGroup = Value(:);
        end
        
        function obj = set.PlaneFilters(obj, Value)
             assert(iscell(Value) && isvector(Value), 'Wrong input.')
             for index = 1 : length(Value)
                 CurrentGroup = Value{index};
                 assert(iscell(CurrentGroup) && isvector(CurrentGroup), 'Wrong input.')
                 cellfun(@(x) assert( isnumeric(x) && isvector(x), 'Wrong input.'), CurrentGroup);
                 
             end
             
            
             obj.PlaneFilters = Value(:);
        end
        
    end
    
    methods % SUMMARY
        
          function obj = showSummary(obj)
              
              fprintf('\n*** This PMImageTrackingDataRetrieval object serves as a data-source for quantitative data obtained from live imaging experimetns.\n')
              fprintf('\nIt has %i groups.\n', obj.getNumberOfGroups)
              
              FileNames = obj.getInteractionMapFileNamesPerGroup;
              
              for index = 1 : obj.getNumberOfGroups
                 
                  fprintf('\nGroup %i:\n', index)
                  fprintf('\nGroup name = "%s".\n', obj.GroupNames{index});
                  fprintf('Library name = "%s".\n', obj.LibraryFileNamePerGroup{index});
                  
                  fprintf('\nNick names:\n')
                  cellfun(@(x) fprintf('%s\n', x), obj.NicknamesPerGroup{index});
                  fprintf('\nInteraction folder = "%s".\n', obj.InteractionFolderNamePerGroup{index});
                  fprintf('Interaction file-names:\n')
                  cellfun(@(x) fprintf('%s\n', x), FileNames{index});
        
                  fprintf('\nWith these settings the object has created the following PMTrackingGroups object:\n')
                  obj.GroupData.showSummary;
        
        
              end
              
          end
    end

    methods % GETTERS:
        
        function libraries = getMovieLibraries(obj)
            libraries =  cellfun(@(x) PMMovieLibrary(x), obj.LibraryFileNamePerGroup);
        end
        
            
        function MyGroupData =          getGroupData(obj)
            %GETGROUPDATA returns PMTrackingGroups
            MyGroupData = obj.GroupData;
        end
        
        function TrackingSuites =       getTrackingSuites(obj)
            % GETTRACKINSUITES returns TrackingSuites vector;
            % each group has each on TrackingSuites object
            TrackingSuites = obj.GroupData.getTrackingSuites;
        end
         
        function GroupNames =           getGroupNames(obj)
            GroupNames = obj.GroupNames;
        end
        
        function NicknamesPerGroup =    getNicknamesPerGroup(obj)
            NicknamesPerGroup = obj.NicknamesPerGroup;
        end
        
        function Images =               getInteractionImageVolumes(obj)

            FileNames = obj.getInteractionMapFileNamesPerGroup;
            for index = 1 : obj.getNumberOfGroups
                FilenamesForCurrentGroup = FileNames{index};
                Images{index, 1} = cellfun(@(x) imread(x), obj.NicknamesPerGroup{index}, 'UniformOutput', false); 

            end

        end

        function FileNames =            getInteractionMapFileNamesPerGroup(obj)
            % GETINTERACTIONMAPFILENAMESPERGROUP returns cell array with file-names of interaction maps;

            FileNames = cell(obj.getNumberOfGroups, 1);
            for index = 1 : obj.getNumberOfGroups
                FileNames{index, 1} = cellfun(@(x) [obj.InteractionFolderNamePerGroup{index}, x, '_Map.mat'], obj.NicknamesPerGroup{index}, 'UniformOutput', false);  
            end

        end

    end
    
    methods (Access = private)
    
        function obj = setGroupData(obj)
                                    
            if isempty(obj.InteractionFolderNamePerGroup)
                
                  MyTrackingSuites =          cellfun(@(file, x, y) PMTrackingSuite(file, x, y), ...
                                            num2cell(obj.getMovieLibraries), ...
                                            obj.GroupNames, ...
                                            obj.NicknamesPerGroup  ...
                                            );
                
                                        
            elseif isempty(obj.PlaneFilters)
                
                    MyTrackingSuites =          cellfun(@(file, x, y, z) PMTrackingSuite(file, x, y, z), ...
                                            num2cell(obj.getMovieLibraries), ...
                                            obj.GroupNames, ...
                                            obj.NicknamesPerGroup,  ...
                                            obj.getInteractionMapFileNamesPerGroup...
                                            );
                
             
                
            else

                     MyTrackingSuites =          cellfun(@(file, x, y, z, plane) PMTrackingSuite(file,x,y, z, plane), ...
                        MovieLibraries, ...
                        obj.GroupNames, ...
                        obj.NicknamesPerGroup,  ...
                        obj.getInteractionMapFileNamesPerGroup, ...
                        obj.PlaneFilters...
                        );
                                        
            end
            obj.GroupData =             PMTrackingGroups(MyTrackingSuites);

        end
        
    

        function number = getNumberOfGroups(obj)
           number = length(obj.GroupNames); 
        end
    
    end
    
    
end

