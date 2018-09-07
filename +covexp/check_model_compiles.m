function ret = check_model_compiles(sys, ~, ret)
%CHECK_MODEL_COMPILES Summary of this function goes here
%   Detailed explanation goes here
    ret.compiles = true;
    ret.compile_exp = [];
    
    l = logging.getLogger('singlemodel');
    
    simob = utility.TimedSim(sys, covcfg.SIMULATION_TIMEOUT, l);
    
    try
        simob.start(true);
    catch e
        ret.compiles = false;
        ret.compile_exp = e;
    end
end

