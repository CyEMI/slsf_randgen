classdef cfg
    %CFG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        %% Commonly used 
        
        NUM_MAINLOOP_ITER = 1;
        
        PARFOR = false;
        
        % Load previously saved random number seed. This would NOT
        % reproduce previous experiment results, but useful for actually
        % running this tool 24/7 and doing new stuff everytime the script
        % is run.
        
        LOAD_RNG_STATE = true;
        
        INTERACTIVE_MODE = false;
        
        % If any error occurs, replicate the experiment in next run
        REPLICATE_EXP_IF_ANY_ERROR = true;
        
        % Debug/Interactive mode for a particular subsystem
        
%         DEBUG_SUBSYSTEM = struct('cfblk164', 1);
        DEBUG_SUBSYSTEM = struct([]); % So that isempty would work
        
        %% Stopping when error
        
        % Note: when preprocessing models using the covcollect script,
        % don't keep any mutants/parents open. Change
        % followings accordingly.
        
        % don't close a mutant if it did not compile/run
        KEEP_ERROR_MUTANT_OPEN = false;
        KEEP_ERROR_MUTANT_PARENT_OPEN = false;
        
        % Break from the main loop if any model mutation errors
        STOP_IF_ERROR = false;
        
        %% Preprocessing %%
        
        % Workflow 1 (caching): Preprocess models and cache them.
        
        % Use following while caching by running covexp.covcollect.
        
        % Note: this is automatically done by the ModelPreprocessor class,
        % you don't need to change any configuration here.
        
%         DONT_PREPROCESS = false;        
        
        % Use following after caching i.e. generating mutants via the
        % emi.go script
        
        DONT_PREPROCESS = true;
        
        
        MUTANT_PREPROCESSED_FILE_SUFFIX = 'pp';
        MUTANT_PREPROCESSED_FILE_EXT = '.slx';
        
        %% Random numbers and reporting file names
        
        % Name of the variable for storing random number generator state.
        % We need to save two states because first we randomly select the
        % models we want to mutate. We save this state in
        % `MODELS_RNG_VARNAME_IN_WS`. This is required to replicate a
        % failed experiment. Next, before mutating each of the models, we
        % again save the RNG state in `RNG_VARNAME_IN_WS`
        
        % No need to change the followings
        
        REPORTS_DIR = 'emi_results';
        
        % Save random number seed and others
        WORK_DATA_DIR = 'workdata';
        WS_FILE_NAME_ = 'savedws.mat';
        
        
        % Before generating list of models
        MODELS_RNG_VARNAME_IN_WS = 'rng_state_models';
        % Before creating mutants for *a* model
        RNG_VARNAME_IN_WS = 'rng_state';
        
        % file name for results of a model
        % report will be saved in
        % `REPORTS_DIR`/{EXP_ID}/`REPORT_FOR_A_MODEL_FILENAME`
        REPORT_FOR_A_MODEL_FILENAME = 'modelreport';
        REPORT_FOR_A_MODEL_VARNAME = 'modelreport';
        
        %% Mutation: Block delete and reconnection strategies
        
        % Specify input and output data-type of a DTC block.
        % TODO may need to do it for other blocks (??)
        % Used in MutantGenerator::add_dtc_block_in_middle
        DTC_SPECIFY_TYPE = true;        
        
        %% Generic Mutation
        
        MUTANTS_PER_MODEL = 1;
        
        % Remove this percentage of dead blocks
        DEAD_BLOCK_REMOVE_PERCENT = 0.5;
        
        %% Others
        
        MUTATOR_DECORATORS = {
            @emi.decs.TypeAnnotateEveryBlock
            @emi.decs.DeleteDeadDirectReconnect
            };
        
        CPS_TOOL = @cps.SlsfModel;
        
        % Don't delete these blocks during dead block removal
        SKIP_DELETES = containers.Map({'Delay', 'UnitDelay'}, {1,1});
        
        INPUT_MODEL_LIST = covcfg.RESULT_FILE
        
        SIMULATION_TIMEOUT = covcfg.SIMULATION_TIMEOUT;
        
        % Force pauses for debugging
        DELETE_BLOCK_P = false;
        
        % logger level
        LOGGER_LEVEL = logging.logging.INFO;
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

