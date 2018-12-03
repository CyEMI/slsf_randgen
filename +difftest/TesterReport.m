classdef TesterReport < handle
    %TESTERREPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %%
        % utility.cell elements contain report for each SUT configuration executions
        executions;   
        
        is_ok = false;
        
        exception;
        
        % Which execution # caused the exception?
        exc_config;
        exc_shortname;
        
        % is_ok value of the execution report which caused error. If no
        % error has occured, this should have ExecStatus.Done
        exc_last_ok;
    end
 
    
    methods
        
        function aggregate(obj)
            %% Computes result
            % Currently we stop differential testing when meeting the first
            % exception. Change this function to return array if we allow
            % running after the first exception 
            for i=1:obj.executions.len
                cur = obj.executions.get(i);
                obj.exc_last_ok = cur.last_ok;
                
                if ~ cur.is_ok()
                    obj.exception = cur.exception;
                    obj.exc_config = i;
                    obj.exc_shortname = cur.shortname;
                    return;
                end
            end
            
            obj.is_ok = true;
        end
    end
    
    methods (Access = protected)
        
    end
end

