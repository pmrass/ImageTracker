classdef PMChannel
    %PMCHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Visible =               true
        IntensityLow =          0
        IntensityHigh =         0.7
        Color =                 [0 1 0]
        Comment =               'No comment'
        ReconstructionType =    'Raw'
    end
    
    properties (Constant, Access = private)
       PossibleFilterTypes = {'Raw','Median', 'Complex'};
        
    end
    
    methods % initialization
        
         function obj = PMChannel(varargin)
            %PMCHANNEL Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                case 1
                    assert(length(varargin{1}) == 6 && isscalar(varargin{1}), 'Wrong argument type.')
                    obj.Visible =               varargin{1}{1};
                    obj.IntensityLow =          varargin{1}{2};
                    obj.IntensityHigh =         varargin{1}{3};
                    obj.Color =                 varargin{1}{4};
                    obj.Comment =               varargin{1}{5};
                    obj.ReconstructionType =    varargin{1}{6};
                otherwise
                    error('Wrong number of arguments')
                
            end
         end
        
          function obj = set.IntensityLow(obj,Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~(isnumeric(Value) && isscalar(Value)) || isnan(Value) || Value >= obj.getIntensityHigh
               error('Wrong channel input.')
            else
                obj.IntensityLow = Value;
                
            end
            
            
          end
          
           function obj = set.IntensityHigh(obj,Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if ~(isnumeric(Value) && isscalar(Value)) || isnan(Value) || Value <= obj.getIntensityLow
              error('Wrong channel input.')
            else
                obj.IntensityHigh = Value;
            end
           end
         
              
          function obj = set.ReconstructionType(obj,Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj = obj.verifyFilterType(Value);
            obj.ReconstructionType = Value;
        end
        
        

        function obj = set.Visible(obj,Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(islogical(Value) && isscalar(Value), 'Wrong argument type.')
            obj.Visible = Value;
        end
        
       
        
       
        
        function obj = set.Color(obj,Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(isnumeric(Value) && isvector(Value) && length(Value) == 3, 'Wrong argument type.')
            obj.Color = Value;
        end
        
        function obj = set.Comment(obj,Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(ischar(Value) , 'Wrong argument type.')
            obj.Comment = Value;
        end
        
      
        
         
        
        
    end
    
    methods (Access = private) % intialization
        
        function obj = verifyFilterType(obj, Value)
           assert(ischar(Value), 'Wrong input.')
           assert(max(strcmp(obj.PossibleFilterTypes, Value)), 'Wrong input.')

            
        end
        
    end
    
    methods % summary
       
        function obj = showSummary(obj)
            
                fprintf('This PMChannel object manages the state of a single channel:\n')

                if obj.Visible
                    fprintf('The channel is visible.\n')
                else
                    fprintf('The channel is not visible.\n')
                end

                fprintf('The bottom intensity is %6.4f\n', obj.IntensityLow)
                fprintf('The top intensity is %6.4f\n', obj.IntensityHigh)
                fprintf('The color is red: %6.4f green: %6.4f blue: %6.4f\n', obj.Color(1), obj.Color(2), obj.Color(3));
                fprintf('The comment is "%s".\n', obj.Comment)
                fprintf('The reconstruction type is "%s".\n', obj.ReconstructionType)
                
        end
        
        
    end
    
    methods % setters
        
        function obj = setVisible(obj, Value)
            obj.Visible = Value;
        end
        
        function obj = setIntensityLow(obj, Value)
            obj.IntensityLow = Value;
        end
        
        function obj = setIntensityHigh(obj, Value)
            obj.IntensityHigh = Value;
        end
        
        function obj = setColor(obj, Value)
            if ischar(Value)
                FinalValue = obj.convertStringIntoColorVector(Value);
            else
                FinalValue = Value;
            end
            obj.Color = FinalValue;
            
        end
        
         function obj = setComment(obj, Value)
            obj.Comment = Value;
        end
        
        function obj = setReconstructionType(obj, Value)
            obj.ReconstructionType = Value;
        end
        
        
        
        
    end
    
    methods
       
        function Value = getVisible(obj)
            Value = obj.Visible ;
        end

        function Value = getIntensityLow(obj)
            Value = obj.IntensityLow ;
        end

        function Value = getIntensityHigh(obj)
            Value = obj.IntensityHigh ;
        end

        function Value = getComment(obj)
            Value = obj.Comment ;
        end

        function Value = getColor(obj)
            Value = obj.Color ;
        end

        function Value = getColorString(obj)    
            Value = convertColorVectorIntoString(obj, obj.Color);
        end

        function Value = getReconstructionType(obj)
            Value = obj.ReconstructionType ;
        end
        
    end
    
    methods (Access = private)
        
        
         function code = convertStringIntoColorVector(~, String)
            switch String
                case 'Red'
                    code = [1 0 0];
                case 'Green'
                    code = [0 1 0];
                case 'Blue'
                    code = [0 0 1];
                case 'Yellow'
                    code = [1 1 0];
                case 'Magenta'
                    code = [1 0 1];
                case 'Cyan'
                     code = [0 1 1];
                case 'White'
                       code = [1 1 1];  
                otherwise
                    error('Color not supported')
            end
         end
         
           function code = convertColorVectorIntoString(~, Vector)
                if isequal(Vector, [1 0 0])
                    
                    code = 'Red';
                elseif isequal(Vector, [1 0 0])
                        
                    elseif isequal(Vector, [0 1 0])
                        code = 'Green';
                    elseif isequal(Vector, [0 0 1])
                        code = 'Blue';
                    elseif isequal(Vector, [1 1 0])
                        code = 'Yellow';
                    elseif isequal(Vector, [1 0 1])
                        code = 'Magenta';
                    elseif isequal(Vector, [0 1 1])
                         code = 'Cyan';
                    elseif isequal(Vector, [1 1 1]) 
                           code = 'White';  
                elseif isequal(Vector, [0 0 0])
                      code = 'Black';  
                else
                       code = 'UnknownColor';
                end
           end
        
        
         
         
        
    end
end

