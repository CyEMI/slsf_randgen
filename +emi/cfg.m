classdef cfg
    %CFG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        
        NUM_MAINLOOP_ITER = 1;
        
        PARFOR = false;
        
        INPUT_MODEL_LIST = covcfg.RESULT_FILE
        
        % Load previously saved random number seed. This would NOT
        % reproduce previous experiment results, but useful for actually
        % running this tool 24/7 and doing new stuff everytime the script
        % is run.
        
        LOAD_RNG_STATE = false;
        
        INTERACTIVE_MODE = false;
        
        MUTANTS_PER_MODEL = 1;
        
        REPORTS_DIR = 'emi_results';
        
        % Remove this percentage of dead blocks
        DEAD_BLOCK_REMOVE_PERCENT = 0.5;
        
        % Force pauses for debugging
        DELETE_BLOCK_P = false;
        
        % No need to change the followings
        
        % Save random number seed and others
        WORK_DATA_DIR = 'workdata';
        WS_FILE_NAME_ = 'savedws.mat';
        
        % Name of the variable for storing random number generator state
        RNG_VARNAME_IN_WS = 'rng_state';
        
        % file name for results of a model
        % report will be saved in
        % `REPORTS_DIR`/{EXP_ID}/`REPORT_FOR_A_MODEL_FILENAME`
        REPORT_FOR_A_MODEL_FILENAME = 'modelreport';
        REPORT_FOR_A_MODEL_VARNAME = 'modelreport';
    end
    
    methods (Static = true)
        
        function validate_configurations()
            assert(~emi.cfg.INTERACTIVE_MODE ||  ~emi.cfg.PARFOR,...
                'Cannot be both interactive and parfor');
            
        end
        
        function ret = WS_FILE_NAME()
            ret = [emi.cfg.WORK_DATA_DIR filesep emi.cfg.WS_FILE_NAME_];
        end
    end
    
end

