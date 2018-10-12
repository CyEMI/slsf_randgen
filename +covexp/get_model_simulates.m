function ret = get_model_simulates(sys, h, ret)
    l = logging.getLogger('singlemodel');
    ret = covexp.get_cov_reporttype(ret);
    
    % Does it run within timeout limit?
    
    try
        time_start = tic;
        
        simob = utility.TimedSim(sys, covcfg.SIMULATION_TIMEOUT, l);
        ret.timedout = simob.start();

        if ret.timedout
            % Close
            covexp.sys_close(sys);
            return;
        end
        
        ret.simdur = toc(time_start);
        
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        ret.exception_ob = e;
     
        covexp.sys_close(sys);
    end 
end
