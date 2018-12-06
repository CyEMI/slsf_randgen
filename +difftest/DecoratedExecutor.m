classdef DecoratedExecutor < utility.Decorator
    %DECORATEDEXECUTOR Summary of this class goes here
    
    methods(Abstract)
        pre_execution(obj)
        
        % Retrieve simulation result and store it in ExecutionReport
        retrieve_sim_result(obj)
        
    end
    
    methods
         
        function decorate_sim_args(obj)  %#ok<MANU>
        end
        
    end
end

