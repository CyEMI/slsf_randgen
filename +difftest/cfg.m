classdef cfg
    %CFG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        EXECUTOR = {@difftest.SignalLoggerExecutor};
        COMPARATOR = @difftest.FinalValueComparator;
        
        SIMULATION_TIMEOUT = covcfg.SIMULATION_TIMEOUT;
        
        PRE_EXEC_SUFFIX = 'difftest';
        DELETE_PRE_EXEC_MODELS = false;
        
        % Don't create the pre-exec file if one already exists
        PRE_EXEC_SKIP_CREATE_IF_EXISTS = false;
        
    end
    
    
end

