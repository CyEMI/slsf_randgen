classdef covcfg < handle
    %COVCFG Configure `covcollect` - collecting coverage of models 
    %   Detailed explanation goes here
    
    properties(Constant = true)
        
        % Instead of corpus models, analyze a directory to discover models
        EXPLORE_A_DIRECTORY = true;
        
        % Generate lists of models before experiment. If false, will reuse
        % the list generated during last experiment.
        GENERATE_MODELS_LIST = true;
        
        %% Experiment Mode (see covexp.Expmode)
        
        EXP_MODE = covexp.Expmode.ALL;
        
        % Upper limit on how many models to process
        % For SUBGROUP_AUTO, process these many models 
        
        % WARNING if you are adding a new type of experiment, it's easy to
        % have bug in the code initially. Please experiment with 1-2 models
        % first so that you do not discard many of the cached results for
        % ALL of your models!
        MAX_NUM_MODEL = 5000;
        
        % Subgrouping is not used for Expmode.All
        SUBGROUP_BEGIN = 101;
        SUBGROUP_END = 210;
        
        
        %% %%%%%%%% Caching Result %%%%%%%%%%%%%
        
        % Global turn on/off caching results. Even if you turn off, we will
        % save the results as cache, just won't use it next time. This can
        % be helpful if cached data becomes inconsistent; setting it to
        % false would rewrite the caches.
        % If you run into errors when merging reports for all
        % models, including 'Subscripted assignment between dissimilar
        % structures', then try setting it to false.
        % Note: this does not depend on any other caching configuration
        % variables.
        USE_CACHED_RESULTS = true;
        
        % Perform experiments even if cached data is found. Useful when we
        % want to recompute. If you just want to aggregate previously
        % stored caches, set to false. 
        FORCE_UPDATE_CACHED_RESULT = true;
        
        % When force update is on, instead of throwing away previously
        % cached results try to reuse it FOR THE EXPERIMENTS WHICH WILL NOT
        % BE RUN. 
        REUSE_CACHED_RESULT = true;
        
        % If get error for any model, delete cached result and retry. This
        % is useful when MATLAB craches/gets killed and the result was not
        % cached properly.
        DELETE_CACHE_IF_ERROR = false;
        
        %% %%%%%%% Experiments to Perform %%%%%%%%%%%
        
        % List of all available experiments. 
        % See at the bottom of this file for details
        EXPERIMENTS = {...
            @covexp.experiments.get_coverage,...            % 1
            @covexp.experiments.check_model_compiles,...     % 2
            @emi.preprocess_models,...           % 3
            @covexp.experiments.get_model_simulates,...      % 4
            @covexp.experiments.fix_input_loc    % 5
        };
        
        % Will only run these experiments. Elements are index of EXPERIMENTS
%         DO_THESE_EXPERIMENTS = [1 2 3]; % Multiple experiments
        DO_THESE_EXPERIMENTS = 5;   % Single experiment
        
        %% Others
        
        SIMULATION_TIMEOUT = 150;   % seconds
        
        SAVE_RESULT_AS_JSON = false;
        
        
        % Which corpus group to analyze (e.g. tutorial)
%         CORPUS_GROUP = 'tutorial';
        CORPUS_GROUP = []; % Analyze all corpus groups.
        
        OPEN_MODELS = false;
        CLOSE_MODELS = true;
        
        % Will use parfor
        PARFOR = false;        
        
        %% Experiment 4 (Checking models which simulate) %%%%%%%%%%%%%%%
        
        % Models which pass simulation would be copied to a directory
        SAVE_SUCCESS_MODELS = false 
        % Models which error in simulation would be copied to a directory
        SAVE_ERROR_MODELS = false
        % While copying assume this extension for the source file
        MODEL_SAVE_EXT = '.mdl'
        
        %% Experiment 5 (Fixing input_loc data) %%%%%%%%%%%%%%%
        % `input_loc` data is the location of a file, which is an absolute
        % path. Replace it with `EXPLORE_DIR` to fix path problems. Just
        % enable experiment 5 and set FORCE_UPDATE to true.
        
        
        %% Legacy
        
        % Always set this to true. Previously, we used to set it to false
        % when corpus data did not use path
        USE_MODELS_PATH = true;
        
        %% Cache Location
        
        % cache is stored in the same directory where the model is
        USE_MODEL_PATH_AS_CACHE_LOCATION = true;
        
        % Save all caches in a different directory (not recommended, what
        % if two models have the same name?
        CACHE_DIR = 'covexp_results_cache';
        
        %% Less commonly used, very unlikely that someone would change
        
        % Write experiment result in this file
        RESULT_FILE = ['workdata' filesep 'cov_exp_result'];
        
        % save corpus meta in this file
        CORPUS_COV_META = ['workdata' filesep 'corpuscoverage'];
        
        % Save coverage experiment results in this directory
        RESULT_DIR_COVEXP = 'covexp_results';
        
        % For each experiment, save COMBINED result in following file
        
        RESULT_FILENAME = 'covexp_result';
        
        TOUCHED_MODELS_DIR = 'touched';
        
        % When exploring a directory (EXPLORE_A_DIRECTORY == true)
        GENERATE_MODELS_FILENAME = ['workdata' filesep 'generated_model_list'];
        
        % Expmode.SUBGROUP_AUTO
        SUBGROUP_AUTO_DATA = ['workdata' filesep 'cov_exp_subgroup'];
        
        % MATLAB uses different formats for month and minute in from and to
        % coversion to date and string!
        
        DATETIME_STR_TO_DATE = 'yyyy-MM-dd-HH-mm-ss';
        DATETIME_DATE_TO_STR = 'yyyy-mm-dd-HH-MM-SS';
        
        %% Model IDs to skip, start with x
        SKIP_LIST = struct();
%         SKIP_LIST = struct(...
%             'x71', '',... 
%             'x75', '',... 
%             'x77', '',... 
%             'x83', '',... 
%             'x84', '',... 
%             'x88', '',...
%             'x409', '',...
%             'x493', '',...
%             'x518', '',...
%             'x608', '',...
%             'x611', '',...
%             'x621', '',...
%             'x768', '',...
%             'x914', '',...
%             'x956', '',... 
%             'x998', '',...
%             'x1246', '',...
%             'x1391', ''...
%             );
        
    end
    
    methods(Static)
        function ret = CORPUS_HOME()
            ret = getenv('SLSFCORPUS');
            
            if isempty(ret)
                error('Please set up environment variable SLSFCORPUS');
            end
        end
        
        function ret = EXPLORE_DIR()
            ret = getenv('COVEXPEXPLORE');
            
            if isempty(ret)
                error('Please set up environment variable COVEXPEXPLORE where we look for models.');
            end
        end
        
        function ret = SAVE_SUCCESS_DIR()
            ret = getenv('COVEXPSUCCESS');
            
            if isempty(ret)
                error('Please set up environment variable COVEXPSUCCESS where we save models which ran successfully.');
            end
        end
        
        function ret = SAVE_ERROR_DIR()
            ret = getenv('COVEXPERROR');
            
            if isempty(ret)
                error('Please set up environment variable COVEXPERROR where we save models which DID NOT ran successfully.');
            end
        end
    end
    
end

