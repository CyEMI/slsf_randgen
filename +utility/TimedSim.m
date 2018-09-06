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
        
        function timed_out = start(obj, varargin)
            % First argument, if present, denotes whether to only compile
            compile_only = false;
            
            if nargin > 1
                compile_only = varargin{1};
            end
            
            timed_out = false;
            obj.sim_status = [];
            myTimer = timer('StartDelay', obj.duration, 'TimerFcn', {@utility.TimedSim.sim_timeout_callback, obj});
            start(myTimer);
            try
                if compile_only
                    % Sending the compile command results in error similar
                    % to the bug we reported for slicing. So not reporting
                    % it
                    obj.l.info('Updating %s...', obj.sys);
%                     eval([obj.sys '([], [], [], ''compile'')']);
%                     eval([obj.sys '([], [], [], ''term'')']);
                    set_param(obj.sys,'SimulationCommand','Update');
                else
                    obj.l.info('Simulating %s...', obj.sys);
                    sim(obj.sys);
                end
                
                stop(myTimer);
                delete(myTimer);
                
                obj.l.info('Compile/simulation completed');
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

