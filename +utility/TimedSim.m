classdef TimedSim
    %TIMEDSIM Simulate for a specific time, kill after it.
    %   Detailed explanation goes here
    
    properties
        sys;
        duration;
        sim_status;
        l;                  % logger
    end
    
    methods
        function obj = TimedSim(sys, duration, loggerOb)
            obj.sys = sys;
            obj.duration = duration;
            obj.l = loggerOb;
        end
        
        function timed_out = start(obj)
            timed_out = false;
            obj.sim_status = [];
            myTimer = timer('StartDelay', obj.duration, 'TimerFcn', {@utility.TimedSim.sim_timeout_callback, obj});
            start(myTimer);
            try
                sim(obj.sys);
                
                stop(myTimer);
                delete(myTimer);
            catch e
                throw(e);
            end
            
            if ~isempty(obj.sim_status) && ~strcmp(obj.sim_status, 'stopped')
                obj.l.info(['Simulation timed-out for ' obj.sys]);
                timed_out = true;
            end
        end
    end
    
    methods(Static)
        function sim_timeout_callback(~, ~, extraData)
            try
                extraData.sim_status = get_param(extraData.sys,'SimulationStatus');
                if strcmp(extraData.sim_status, 'running')
                    set_param(extraData.sys, 'SimulationCommand', 'stop');
                end
            catch e
                % Do Nothing
            end
        end
    end
    
end

