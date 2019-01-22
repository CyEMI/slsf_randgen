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
    
    end
    
    methods
        
        function set_val(obj, val) %#ok<INUSD>
            obj.last_state = warning;
            
%             cellfun(@(p)warning(val, p), obj.w_ids,...
%                 'UniformOutput', false);
            
            % Set all off!
            warning('off');
        end
        
        function restore(obj)
            warning(obj.last_state);
        end
    end
end

