classdef TesterReport < handle
    %TESTERREPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % utility.cell elements contain report for each SUT configuration executions
        executions;   
    end
 
    
    methods
        function ret=is_ok(obj)
            ret = all(cellfun(@(p)p.is_ok(), obj.executions.get_cell()));
        end
        
        function ret = get_exception(obj)
            % Currently we stop differential testing when meeting the first
            % exception. Change this function to return array if we allow
            % running after the first exception 
            for i=1:obj.executions.len
                cur = obj.executions{i};
                if ~ cur.is_ok()
                    ret = cur.exception;
                    return;
                end
            end
        end
    end
    
    methods (Access = protected)
        
    end
end

