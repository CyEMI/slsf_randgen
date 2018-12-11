classdef BaseComparator < handle
    %BASECOMPARATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        r;                  % cell of all executions
        l;
    end
    
    methods(Abstract)
        compare(obj);
        compare_single(obj, ground_exec, next_exec);
    end
    
    methods
        function obj = BaseComparator(r)
            obj.r = r;
            obj.l = logging.getLogger('BaseComparator');
        end
        
        
        function go(obj)
            
            if ~ obj.validate_input()
                obj.l.info('Only %d executions ran, not enough to compare against each other.\n Returning from Comparison Framework', numel(obj.r.oks));
                return;
            end
            
            obj.refine_all_executions();
            
            if ~ obj.r.are_oks_ok()
                obj.l.error('Exception during refining. Skipping comparison');
                return;
            end
            
            obj.compare();
            
            if obj.r.are_oks_ok()
                obj.l.info('All executions compared successfully!');
            else
                obj.l.warn('One or more comparison error occured.');
            end
            
            obj.l.info('Returning from Comparison Framework');
        end
        
        function ret = validate_input(obj)
            ret = numel(obj.r.oks) > 1;
        end
        
        function compare_wrapper(obj, ground_exec, rest_execs)
            % Call it from obj.compare
            % rest_execs is obj.oks minus ground_exec
           
            obj.l.info('Comparing all executions with %s', ground_exec.id);
            
            ground_exec.last_ok = difftest.ExecStatus.CompDone;
            
            for i = 1: numel(rest_execs)
                next_exec = rest_execs{i};
                
                next_exec.num_signals = 0;
                next_exec.num_found_signals = 0;
                next_exec.num_missing_in_base = 0;
                
                obj.l.info('Comparing Exec# %d; %s', (i+1), next_exec.id);
                
                try
                    obj.compare_single(ground_exec, next_exec, i);
                    
                    if next_exec.is_ok()
                        next_exec.last_ok = difftest.ExecStatus.CompDone;
                    else
                        disp(next_exec.get_exception_messages());
                    end
                catch e
                    obj.l.error('Exception while running comparison!');
                    utility.print_error(e);
                    next_exec.exception.add(e);
                end
                
            end
            
        end
        
        function refine_all_executions(obj)
            for i=1:numel(obj.r.oks)
                cur = obj.r.oks{i};
                cur.last_ok = difftest.ExecStatus.CompStart;
                
                try
                    obj.refine_a_execution(cur);
                    cur.last_ok = difftest.ExecStatus.CompRefine;
                catch e
                    cur.e = e;
                end
                
            end
        end
        
        function refine_a_execution(~, exec_report)
            exec_report.refined = containers.Map;
              
            for j = 1:exec_report.simdata.numElements
                % Iterates through all blocks's outputs of a particular
                % simulation
                
                new_data = struct;

                s_dataset = exec_report.simdata.getElement(j);

                new_data.Time = s_dataset.Values.Time;
                new_data.Data = s_dataset.Values.Data;

                % get block name
                bp = char(s_dataset.BlockPath.convertToCell()); 
                
                % Remove model's name
                bp = utility.strip_first_split(bp, '/', '/'); 
                
                % append port number
                exec_report.refined([bp '_' int2str(s_dataset.PortIndex)]) = new_data;
            end
        end
        
        function handle_comp_err(obj, diff_ob, blk, next_exec, ground_data, exec_data, exc, j)
            % diff_ob can be obj.r.cov_diffs
            next_exec.exception.add(exc);
            
            if ~ diff_ob.isKey(blk)
                t = cell(numel(obj.r.oks), 1);
                t{1} =  ground_data ;
                diff_ob(blk) = t;
            end
            
            t = diff_ob(blk);
            t{j} = exec_data;
            
            diff_ob(blk) = t; %#ok<NASGU>
        end
        
    end
   
end

