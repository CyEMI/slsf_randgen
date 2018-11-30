function ret = get_model_simulates(sys, h, ret)
    l = logging.getLogger('singlemodel');
    ret = covexp.get_cov_reporttype(ret);
    
    % Does it run within timeout limit?
    sys_src = [ret.loc_input filesep sys covcfg.MODEL_SAVE_EXT];
    
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
        
        if covcfg.SAVE_SUCCESS_MODELS
            copyfile(sys_src, covcfg.SAVE_SUCCESS_DIR, 'f');
        end
        
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        ret.exception_ob = e;
        
        if covcfg.SAVE_ERROR_MODELS
            copyfile(sys_src, covcfg.SAVE_ERROR_DIR, 'f');
        end
     
        covexp.sys_close(sys);
    end 
end
