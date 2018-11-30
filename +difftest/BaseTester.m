classdef BaseTester < handle
    %BASETESTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %%
        models;
        configs;
        exec_reports;
    end
    
    methods
        function obj = BaseTester(models, configs)
            %%
            obj.models = models;
            obj.configs = configs;
            
            obj.exec_reports = utility.cell();
        end
        
        function go(obj)
            %%
            obj.init_exec_reports();
            obj.execute_all();
        end
      
        function init_exec_reports(obj)
            %%
            for i=1:numel(obj.models)
                
                all_configs = obj.cartesian_helper(1);
                
                for j = 1:all_configs.len
                    cur = all_configs.get(j);
                    temp = cur.create_copy([]);
                    temp.sys = obj.models{i};
                    obj.exec_reports.add(temp);
                end
                
            end
        end
        
        
        function ret = cartesian_helper(obj, pos)
            %%
            ret = utility.cell;
            
            % Base Case
            if pos > numel(obj.configs)
                ret.add(difftest.ExecutionReport());
                return;
            end
            
            children = obj.cartesian_helper(pos+1);
            
            for i=1:numel(obj.configs{pos})
                for j = 1:children.len
                    child = children.get(j);
                    ret.add(child.create_copy(obj.configs{pos}{i}));
                end
            end
        end
        
        function execute_all(obj)
            %%
            seen = struct;
            
            for i = obj.exec_reports.len
                cur = obj.exec_reports.get(i);
                
                reuse_pre_exec_copy = isfield(seen, cur.sys);
                seen.(cur.sys) = true;
                
                executor = difftest.cfg.EXECUTOR(cur, reuse_pre_exec_copy);
                executor.go();
            end
        end
        
    end
end

