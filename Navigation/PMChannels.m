classdef PMChannels
    %PMCHANNELS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       ActiveChannel = 1
       Channels
        
    end
    
    methods % initizlization
        
        
        function obj = PMChannels(varargin)
            %PMCHANNELS Construct an instance of this class
            %   Detailed explanation goes here
            NumberOfArguments = length(varargin);
            switch NumberOfArguments
                case 0
                case 1
                    obj = setDefaultChannelsForChannelCount(obj, varargin{1});
                otherwise
                    error('Wrong number of arguments')
            end
            
        end
        
         function obj = set.ActiveChannel(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) , 'Invalid argument type')
            obj.ActiveChannel = Value;
         end
        
         function obj = set.Channels(obj, Value)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            assert(isa(Value, 'PMChannel') && isvector(Value), 'Wrong argument type')
            
             obj.Channels =      Value;
            
        end
        
        
    end
    
    methods (Access = private) % initialization
        
          function obj = setDefaultChannelsForChannelCount(obj, Value)
            assert(isnumeric(Value) && isscalar(Value) && Value >= 1, 'Wrong argument type.')
            ChannelArray(1:Value, 1) = PMChannel;
            ChannelArray(1) =   ChannelArray(1).setColor('Blue');
            
            if Value>=2
                ChannelArray(2) =   ChannelArray(2).setColor('Green');
            end
            
            if Value>=3
                ChannelArray(3) =   ChannelArray(3).setColor('Red');
            end
            
            if Value>=4
                ChannelArray(4) =   ChannelArray(4).setColor('White');
            end
            obj.Channels =      ChannelArray;
            
        end
        
        
    end
    
    methods % summary
       
        function obj = showChannelSummary(obj)
            fprintf('\n*** This PMChannels object keeps track of channel settings for %i channels.\n', obj.getNumberOfChannels)
            for index = 1 : obj.getNumberOfChannels
                fprintf('\nChannel %i:\n', index)
                obj.Channels(index).showSummary;
            end  
        end
        
        
    end
    
    methods % setters
        
         function obj = setActiveChannel(obj, Value)
            assert( Value <= length(obj.Channels), 'Wrong type')
            obj.ActiveChannel = Value;
         end
        
        
        
    end
    
    methods % setters by active channel
        
           function obj = setVisible(obj, Value)
            obj.Channels(obj.ActiveChannel) = obj.Channels(obj.ActiveChannel).setVisible(Value);
        end
        
        function obj = setIntensityLow(obj, Value)
             obj.Channels(obj.ActiveChannel) = obj.Channels(obj.ActiveChannel).setIntensityLow(Value);
        end
        
        function obj = setIntensityHigh(obj, Value)
             obj.Channels(obj.ActiveChannel) = obj.Channels(obj.ActiveChannel).setIntensityHigh(Value);
        end
        
        function obj = setColor(obj, Value)
            obj.Channels(obj.ActiveChannel) = obj.Channels(obj.ActiveChannel).setColor(Value);
        end
        
        function obj = setComment(obj, Value)
            obj.Channels(obj.ActiveChannel) = obj.Channels(obj.ActiveChannel).setComment(Value);
        end
        
        function obj = setReconstructionType(obj, Value)
           obj.Channels(obj.ActiveChannel) = obj.Channels(obj.ActiveChannel).setReconstructionType(Value);
        end
 
    end
    
    methods % getters
        
        function index = getActiveChannelIndex(obj)
            index = obj.ActiveChannel;
        end
        
        function index = getIndexOfActiveChannel(obj, Value)
            index = obj.ActiveChannel;
        end
        
        function number = getNumberOfChannels(obj)
            number = length(obj.Channels);
        end
        
        
    end
    
    methods % getters by active channel
        
        
    end
    
    methods % getters for all channels
        
         function types = getReconstructionTypesOfChannels(obj)
             types = arrayfun(@(x) x.getReconstructionType, obj.Channels, 'UniformOutput', false);
        end
        
    end
    
    methods % gettters for visible channels: this is called by PMMovieTracking when processing image volume for display;
        
        function intensities = getIntensityLowOfVisibleChannels(obj)
            intensities = arrayfun(@(x) x.getIntensityLow, obj.Channels(obj.getIndicesOfVisibleChannels));
        end
        
        function indices = getIndicesOfVisibleChannels(obj)
            indices = find(arrayfun(@(x) x.getVisible, obj.Channels));
        end
        
        
        function intensities = getIntensityHighOfVisibleChannels(obj)
             intensities = arrayfun(@(x) x.getIntensityHigh, obj.Channels(obj.getIndicesOfVisibleChannels));
        end

        function intensities = getColorOfVisibleChannels(obj)
             intensities = arrayfun(@(x) x.getColor, obj.Channels(obj.getIndicesOfVisibleChannels), 'UniformOutput', false);
        end
        
        function intensities = getColorStringOfVisibleChannels(obj)
            intensities = arrayfun(@(x) x.getColorString, obj.Channels(obj.getIndicesOfVisibleChannels), 'UniformOutput', false);
        end
        

        function intensities = getCommentOfVisibleChannels(obj)
             intensities = arrayfun(@(x) x.getComment, obj.Channels(obj.getIndicesOfVisibleChannels), 'UniformOutput', false);
        end

        function intensities = getReconstructionTypeOfVisibleChannels(obj)
            intensities = arrayfun(@(x) x.getComment, obj.Channels(obj.getReconstructionType), 'UniformOutput', false);
        end
        
        
    end
    
    methods
        
        function description = getDescriptionOfActiveChannel(obj)
            activeChannel = obj.Channels(obj.getActiveChannelIndex);
            description = activeChannel.getComment;
        end

        function intensities = getVisibleOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getVisible;
        end
        
        function intensities = getIntensityLowOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getIntensityLow;
        end
        
        function intensities = getIntensityHighOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getIntensityHigh;
        end

        function intensities = getColorOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getColor;
        end
        
        function intensities = getColorStringOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getColorString;
        end
        
        function intensities = getCommentOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getComment;
        end

        function intensities = getReconstructionTypeOfActiveChannel(obj)
            intensities = obj.Channels(obj.ActiveChannel).getReconstructionType;
        end
  
    end
    
    methods % set channels by index
        
         function obj = setVisibleOfChannelIndex(obj, index, Value)
             obj.Channels(index) = obj.Channels(index).setVisible(Value);
         end
        
        function visible = getVisibleOfChannelIndex(obj, Value)
            visible = obj.Channels(Value).getVisible;
        end
        
        function obj = setVisibleForAllChannels(obj, Value)
            obj.Channels = arrayfun(@(x) x.setVisible(Value), obj.Channels);
        end
 
    end
end

