classdef SuppressWarnings < handle
    %SUPPRESSWARNINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        w_ids = {
            'SimulinkBlocks:Delay:DelayLengthValueIsNotInteger'
            'SimulinkFixedPoint:util:fxpParameterPrecisionLoss'
            'SimulinkFixedPoint:util:Overflowoccurred'
            'Simulink:DataType:WarningOverflowDetected'
        };
    
        last_state;
    
%         prev_states;
    end
    
    methods
        
        function set_val(obj, val)
%             obj.prev_states = cellfun(@(p)warning(val, p), obj.w_ids,...
%                 'UniformOutput', false);
            obj.last_state = warning;
            
            cellfun(@(p)warning(val, p), obj.w_ids,...
                'UniformOutput', false);
        end
        
        function restore(obj)
            warning(obj.last_state);
%             cellfun(@(p)warning(p.state, p.identifier), obj.prev_states,...
%                 'UniformOutput', false);
        end
    end
end

