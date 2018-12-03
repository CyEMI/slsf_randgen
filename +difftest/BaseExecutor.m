classdef BaseExecutor < handle
    %BASEEXECUTOR Executes a single model using a  config and logs signals
    %   WARNING make sure to call cleanup()
    
    properties
        exec_report;
        l;
        
        sys; % This is a new model (possibly after making changes in pre-execution)
        
        resuse_pre_exec = true;    % Won't run pre-execution
        
        sim_args = [];
    end
    
    properties(Access=protected)
        simOut = [];
    end
    
    methods(Abstract, Access=protected)
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
        
        function init(obj)
            obj.sim_args = obj.decorate_sim_args(obj.exec_report.get_sim_args());
            obj.l.info('STARTING %s ::w/CONFIG:: %s', obj.exec_report.sys, obj.exec_report.shortname);
            
            % Load/Open System
            emi.open_or_load_model(obj.exec_report.sys);
        end
        
        function go(obj)
            obj.exec_report.validate_input();
            obj.init();
            obj.create_and_open_sys();
            if ~ obj.exec_report.is_ok()
                obj.l.error('Error during loading model');
                return;
            end
            
            obj.pre_execution_wrapper();
            if ~ obj.exec_report.is_ok()
                obj.l.error('Error during pre-execution');
                return;
            end
            
            obj.execution_wrapper();
            if ~ obj.exec_report.is_ok()
                obj.l.error('Error during execution');
                return;
            end
            
            obj.retrieve_sim_result();
            
            if obj.exec_report.is_ok()
                obj.exec_report.last_ok = difftest.ExecStatus.Done;
            end
            
            % Don't bother cleaning up, it's object owner's responsibility
        end
        
        function cleanup(obj)
            % Will not be called by this object, but the owner of `obj`
            bdclose(obj.sys);
        end
        
    end
    
    methods (Access = protected)
        
        function create_and_open_sys(obj)
            try
                obj.sys = sprintf('%s_%s', obj.exec_report.sys, difftest.cfg.PRE_EXEC_SUFFIX);

                if ~ obj.resuse_pre_exec
                    ext = emi.slsf.get_extension(obj.exec_report.sys);
                    
                    if difftest.cfg.PRE_EXEC_SKIP_CREATE_IF_EXISTS &&...
                            utility.file_exists(obj.exec_report.loc, [obj.sys '.' ext])
                        obj.l.info('Pre-exec file already exists. Skip creating.');
                    else
                        obj.exec_report.preexec_file = emi.slsf.copy_model(...
                            obj.exec_report.sys, obj.exec_report.loc, obj.sys, ext);
                    end
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
            obj.l.info('Executing...');
            obj.simOut = obj.sim_command(obj.sim_args);
        end
        
        function ret = sim_command(obj, varargin)
            % varargin{1}: simulation arguments (struct)
            simob = utility.TimedSim(obj.sys, difftest.cfg.SIMULATION_TIMEOUT, obj.l, varargin{:});
            simob.start();
            ret = simob.simOut;
        end

        
        function ret= decorate_sim_args(obj, sim_args) %#ok<INUSL>
            ret = sim_args;
            ret.SignalLogging = 'off';
        end
    end
end

