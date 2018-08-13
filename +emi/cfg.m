classdef cfg
    %CFG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        
        NUM_MAINLOOP_ITER = 1;
        
        PARFOR = false;
        
        INPUT_MODEL_LIST = covcfg.RESULT_FILE
        
        INTERACTIVE_MODE = false;
        
        MUTANTS_PER_MODEL = 1;
        
        REPORTS_DIR = 'emi_results';
        
        % Remove this percentage of dead blocks
        DEAD_BLOCK_REMOVE_PERCENT = 0.1;
        
        % Force pauses for debugging
        DELETE_BLOCK_P = true;
    end
    
    methods (Static = true)
        
        function validate_configurations()
            assert(~emi.cfg.INTERACTIVE_MODE ||  ~emi.cfg.PARFOR,...
                'Cannot be both interactive and parfor');
            
        end
    end
    
end

