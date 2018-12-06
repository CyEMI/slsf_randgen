classdef ExecutionReport < handle
    %EXECUTIONREPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %% General
        sys = [];           % Original model 
        loc = [];           % Model path, used to crate a backup model here
        shortname = 'n/a';  % Combine shortname from configs
        
        id;                 % Combines sys with shortname
        
        configs;            % utility.cell of ExecConfig
        
        last_ok;            % Last ExecStatus field which completed without errors
        
        %% Execution Related (prior to comparison)
        
        exception = [];     % Exception object
        
        preexec_file = [];
        
        %% Comparison Related
        
        simdata;            % Simulation result (raw form)
        
        refined;            % Simulation result (refined)
        
        %% CF Stats
        
        % total logged signals in this execution
        num_signals = [];           
        
        % my signals which were also found in comparison base signal. aka
        % Intersection of mine and base
        num_found_signals  = 0;     
        
        % Base's signals not found in me. i.e signals which only exist in
        % base aka base.num_signals - obj.num_found_signals
        num_missing_in_base = 0;    
    end
    
    properties(Access=protected)
        
    end
    
    methods
        function obj = ExecutionReport()
            %%
            obj.configs = utility.cell();
            obj.last_ok = difftest.ExecStatus.Idle;
            
        end
        
        function ret = create_copy(obj, config)
            %%
            ret = difftest.ExecutionReport();
            
            % Copy attributes
            ret.configs = obj.configs.deep_copy();
            
            if ~isempty(config)
                ret.configs.add(config);
            end
            
        end
        
        function ret = is_ok(obj, exec_status)
            %%
            % If exec_status is not passed, checks absense of execption
            % i.e. whether the last operation passed successfully.
            if nargin >=2
                ret = uint32(obj.last_ok) >= uint32(exec_status);
                return;
            end
            
            ret = isempty(obj.exception);
        end
        
        function ret = get_sim_args(obj)
            %%
            snames = utility.cell(obj.configs.len);
            simargs = utility.cell(obj.configs.len);
            
            for i=1:obj.configs.len
                c = obj.configs.get(i);
                
                snames.add(c.shortname);
                simargs.add(c.configs);
                
            end
            
            obj.shortname = strjoin(snames.get_cell(), '_');
            obj.id = [obj.sys ' ::config:: ' obj.shortname];
            
            ret = utility.merge_structs(simargs);
        end
        
        function validate_input(obj)
            %%
            assert(~isempty(obj.loc));
            assert(~isempty(obj.sys));
            assert(obj.configs.len > 0);
        end
        
        
        function ret = get_report(obj) %#ok<STOUT,MANU>
            %%
            error('Dead Code');
            ret = utility.get_struct_from_object(obj); %#ok<UNRCH>
            ret.last_ok_int = uint(obj.last_ok);
            ret.success = obj.is_ok();
        end
        
    end
    
    methods (Access = protected)
        
    end
end

