classdef TesterReport < handle
    %TESTERREPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %% Prior to comparison
        % utility.cell elements contain report for each SUT configuration executions
        executions;   
        
        oks;    % cell. Executions which did not errored.
        
        is_ok = false; % ALL executions RAN successfully (NOT checking comparisons)
        
        exception;      % utility.cell
        
        % Which execution # caused the exception? (indices)
        exc_config;     % utility.cell
        exc_shortname;  % utility.cell
        
        % is_ok value of the execution report which caused error. If no
        % error has occured, this should have ExecStatus.Done
        exc_last_ok;    % utility.cell
        
        %% During Comparison
        % Work on `oks` cell: each element is a running configuration for
        % which you can get logged signal.
        
        % Aggregators: coverage and comparison errors
        cov_diffs;         % map of coverage errors (cov diffs)
        comp_diffs;        % map of comparison errors 

        % Are followings used? Looks like they are not!
        
        is_comp_ok = false; 
        
        comp_error_indices;
        comp_okay_indices;
    end
 
    
    methods
        
        function obj = TesterReport()       
            obj.exception = utility.cell();
            obj.exc_config = utility.cell();
            obj.exc_shortname = utility.cell();
            
            obj.exc_last_ok = utility.cell();
            
            obj.cov_diffs = containers.Map;
            obj.comp_diffs = containers.Map;
        end
        
        function ret = are_oks_ok(obj)
            %%
            ret = all(cellfun(@(p)p.is_ok() , obj.oks));
        end
        
        function aggregate_before_comp(obj)
            %% Computes result before running the comparison framework
            % Currently we stop differential testing when meeting the first
            % exception. Change this function to return array if we allow
            % running after the first exception 
            
            okays = utility.cell(obj.executions.len);
            
            for i=1:obj.executions.len
                cur = obj.executions.get(i);
                obj.exc_last_ok = cur.last_ok;
                
                if ~ cur.is_ok()
                    obj.exception.add( cur.exception);
                    obj.exc_config.add( i);
                    obj.exc_shortname.add( cur.shortname);
                else
                    okays.add(i);
                end
            end
            
            obj.oks = obj.executions.get(okays.get_mat());
            
            obj.is_ok = okays.len == obj.executions.len;
        end
    end
 
end

