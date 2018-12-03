classdef SignalLoggerExecutor < difftest.BaseExecutor
    %SIGNALLOGGEREXECUTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end

    methods
        function obj = SignalLoggerExecutor(varargin)
            obj = obj@difftest.BaseExecutor(varargin{:});
        end
    end
    
    methods (Access=protected)
        
        function pre_execution(obj)
            emi.slsf.signal_logging_setup(obj.sys);
            save_system(obj.sys);
            
            simu_args = struct;
            simu_args = obj.decorate_sim_args(simu_args);
            
            obj.sim_command(simu_args);
        end
        
        function retrieve_sim_result(obj)
            obj.exec_report.simdata = obj.simOut.get('logsout');
        end
        
        function ret = decorate_sim_args(obj, sim_args) %#ok<INUSL>
            ret = sim_args;
            ret.SignalLogging = 'on';
        end
    end
    

end

