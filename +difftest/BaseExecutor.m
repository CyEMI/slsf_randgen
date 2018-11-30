classdef BaseExecutor < handle
    %BASEEXECUTOR Executes and logs signals
    %   Detailed explanation goes here
    
    properties
        exec_report;
        l;
        
        sys; % This is a new model
        
        resuse_pre_exec = true;    % Won't run pre-execution
    end
    
    properties(Access=protected)
        simOut = [];
    end
    
    methods(Abstract)
        pre_execution(obj)
        
        % Retrieve simulation result and store it in ExecutionReport
        retrieve_sim_result(obj)
        
    end
    
    methods
        function obj = BaseExecutor(exec_report, reuse_pre_exec)
            obj.exec_report = exec_report;
            obj.resuse_pre_exec = reuse_pre_exec;
            obj.l = logging.getLogger('BaseExecutor');
        end
        
        function go(obj)
            obj.create_and_open_sys();
            if ~ isempty(obj.exec_report.exception)
                obj.l.error('Error during loading model');
                return;
            end
            
            obj.pre_execution_wrapper();
            if ~ isempty(obj.exec_report.exception)
                obj.l.error('Error during pre-execution');
                return;
            end
            
            obj.execution_wrapper();
            if ~ isempty(obj.exec_report.exception)
                obj.l.error('Error during execution');
                return;
            end
            
            obj.retrieve_sim_result();
            
            obj.close_sys();
        end
    end
    
    methods (Access = protected)
        
        function create_and_open_sys(obj)
            try
                obj.sys = sprintf('%s_%s', obj.exec_report.sys, 'difftest');

                if ~ obj.resuse_pre_exec
                    save_system(obj.exec_report.sys, [obj.exec_report.loc filesep obj.sys]);
                end

                obj.open_sys();
                
                obj.exec_report.last_ok = difftest.ExecStatus.Load;
            catch e
                obj.exec_report.exception = e;
            end
        end
        
        function open_sys(obj)
            emi.open_or_load_model(obj.sys);
        end
        
        function close_sys(obj)
            bdclose(obj.sys);
        end
        
        function pre_execution_wrapper(obj)
            % Change/decorate model before execution 
            
            if obj.resuse_pre_exec
                return;
            end
            
            try
                obj.pre_execution();
                obj.exec_report.last_ok = difftest.ExecStatus.PreExec;
            catch e
                obj.exec_report.exception = e;
            end
        end
        
        function execution_wrapper(obj)
            % Change/decorate model before execution 
            try
                obj.execution();
                obj.exec_report.last_ok = difftest.ExecStatus.Exec;
            catch e
                obj.exec_report.exception = e;
            end
        end
        
        function execution(obj)
            sim_args = obj.decorate_sim_args(obj.exec_report.get_sim_args());
            obj.l.info('Executing %s in config: %s', obj.sys, obj.exec_report.shortname);
            obj.simOut = obj.sim_command(sim_args);
        end
        
        function ret = sim_command(obj, sim_args)
            ret = sim(obj.sys, sim_args);
        end
        
        function ret= decorate_sim_args(obj, sim_args) %#ok<INUSL>
            ret = sim_args;
            ret.SignalLogging = 'off';
        end
    end
end

