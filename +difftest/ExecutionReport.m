classdef ExecutionReport < handle
    %EXECUTIONREPORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sys = [];           % Original model 
        loc = [];           % Model path, used to crate a backup model here
        
        configs;            % utility.cell of ExecConfig
        
        last_ok;            % Last ExecStatus field which completed without errors
        
        exception = [];     % Exception object
        
        shortname = 'n/a';  % Combine shortname from configs
        
        simdata;            % Simulation result
    end
    
    properties(Access=protected)
        
    end
    
    methods
        function obj = ExecutionReport()
            obj.configs = utility.cell();
            obj.last_ok = difftest.ExecStatus.Idle;
        end
        
        function ret = create_copy(obj, config)
            ret = difftest.ExecutionReport();
            
            % Copy attributes
            ret.configs = obj.configs.deep_copy();
            
            if ~isempty(config)
                ret.configs.add(config);
            end
            
        end
        
        function ret = is_ok(obj)
            ret = isempty(obj.exception);
        end
        
        function ret = get_sim_args(obj)
            snames = utility.cell(obj.configs.len);
            simargs = utility.cell(obj.configs.len);
            
            for i=1:obj.configs.len
                c = obj.configs.get(i);
                
                snames.add(c.shortname);
                simargs.add(c.configs);
                
            end
            
            obj.shortname = strjoin(snames.get_cell(), '_');
            
            ret = utility.merge_structs(simargs);
        end
    end
    
    methods (Access = protected)
        
    end
end

