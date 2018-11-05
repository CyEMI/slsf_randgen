classdef covcfg
    %COVCFG Configure `covcollect` - collecting coverage of models 
    %   Detailed explanation goes here
    
    properties(Constant = true)
        
        EXP_MODE = covexp.Expmode.ALL;
        
        % Instead of corpus models, analyze a directory to discover models
        EXPLORE_A_DIRECTORY = true;
        
        % Upper limit on how many models to process
        % For SUBGROUP_AUTO, process these many models 
        
        % WARNING if you are adding a new type of experiment, it's easy to
        % have bug in the code initially. Please experiment with 1-2 models
        % first so that you do not discard many of the cached results for
        % ALL of your models!
        MAX_NUM_MODEL = 500;
        
        % Subgrouping is not used for Expmode.All
        SUBGROUP_BEGIN = 101;
        SUBGROUP_END = 210;
        
        USE_MODELS_PATH = true;
        
        %%%%%%%%%% Caching Result %%%%%%%%%%%%%
        
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
        
        %%%%%%%%% Experiments to Perform %%%%%%%%%%%
        
        % List of all available experiments
        EXPERIMENTS = {...
            @covexp.get_coverage,...            % 1
            @covexp.check_model_compiles,...     % 2
            @emi.preprocess_models,...           % 3
            @covexp.get_model_simulates...      % 4
        };
        
        % Will only run these experiments. Elements are index of EXPERIMENTS
        DO_THESE_EXPERIMENTS = [1 2 3]; % Multiple experiments
%         DO_THESE_EXPERIMENTS = 4;   % Single experiment
        
        % Generate lists of models before experiment
        GENERATE_MODELS_LIST = false;
        
        GENERATE_MODELS_FILENAME = ['workdata' filesep 'generated_model_list'];
        
        SIMULATION_TIMEOUT = 150;   % seconds
        
        SAVE_RESULT_AS_JSON = false;
        
        BASE_DIR = '';
        
        % Which corpus group to analyze (e.g. tutorial)
%         CORPUS_GROUP = 'tutorial';
        CORPUS_GROUP = []; % Analyze all corpus groups.
        
        OPEN_MODELS = false;
        CLOSE_MODELS = true;
        
        % Will use parfor
        PARFOR = false;
        
        
        % Model IDs to skip, start with x
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
        
        % Write experiment result in this file
        RESULT_FILE = ['workdata' filesep 'cov_exp_result'];
        
        % save corpus meta in this file
        CORPUS_COV_META = ['workdata' filesep 'corpuscoverage'];
        
        % Save coverage experiment results in this directory
        RESULT_DIR_COVEXP = 'covexp_results';
        
        USE_MODEL_PATH_AS_CACHE_LOCATION = true;
        CACHE_DIR = 'covexp_results_cache';
        
        % For each experiment, save COMBINED result in following file
        
        RESULT_FILENAME = 'covexp_result';
        
        TOUCHED_MODELS_DIR = 'touched';
        
        % Expmode.SUBGROUP_AUTO
        SUBGROUP_AUTO_DATA = ['workdata' filesep 'cov_exp_subgroup'];
        
        % MATLAB uses different formats for month and minute in from and to
        % coversion to date and string!
        
        DATETIME_STR_TO_DATE = 'yyyy-MM-dd-HH-mm-ss';
        DATETIME_DATE_TO_STR = 'yyyy-mm-dd-HH-MM-SS';
   
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
    end
    
end

