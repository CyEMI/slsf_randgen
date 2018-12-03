classdef cfg
    %CFG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        EXECUTOR = @difftest.SignalLoggerExecutor;
        
        SIMULATION_TIMEOUT = covcfg.SIMULATION_TIMEOUT;
        
        PRE_EXEC_SUFFIX = 'difftest';
        DELETE_PRE_EXEC_MODELS = false;
        
        
    end
    
    
end

