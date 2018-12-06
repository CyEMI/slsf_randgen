classdef SignalLoggerExecutor < difftest.DecoratedExecutor
    %SIGNALLOGGEREXECUTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function pre_execution(obj)
            emi.slsf.signal_logging_setup(obj.hobj.sys);
            save_system(obj.hobj.sys);
            
            simu_args = struct('SignalLogging', 'on');
            
            obj.hobj.sim_command(simu_args);
        end
        
        function retrieve_sim_result(obj)
            obj.hobj.exec_report.simdata = obj.hobj.simOut.get('logsout');
        end
        
        function decorate_sim_args(obj) 
            obj.hobj.sim_args_cache.SignalLogging = 'on';
        end
    end
    

end

