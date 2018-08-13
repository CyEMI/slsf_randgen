classdef covcfg
    %COVCFG Configure `covcollect` - collecting coverage of models 
    %   Detailed explanation goes here
    
    properties(Constant = true)
        
        EXP_MODE = covexp.Expmode.GROUP;
        
        % Instead of corpus models, analyze a directory to discover models
        EXPLORE_A_DIRECTORY = true;
        
        SUBGROUP_BEGIN = 1;
        SUBGROUP_END = 3;
        
        USE_MODELS_PATH = true;
        
        % Generate lists of models before experiment
        GENERATE_MODELS_LIST = true;
        GENERATE_MODELS_FILENAME = ['workdata' filesep 'generated_model_list'];
        
        % Upper limit on how many models to process
        % For SUBGROUP_AUTO, process these many models 
        MAX_NUM_MODEL = 5000;
        
        SIMULATION_TIMEOUT = 150;   % seconds
        
        BASE_DIR = '';
        
        % Which corpus group to analyze (e.g. tutorial)
%         CORPUS_GROUP = 'tutorial';
        CORPUS_GROUP = []; % Analyze all corpus groups.
        
        OPEN_MODELS = false;
        CLOSE_MODELS = true;
        
        % Will use parfor
        PARFOR = true;
        
        % Model IDs to skip, start with x
        SKIP_LIST = struct();
%         SKIP_LIST = struct(...
%             'x226', '',...
%             'x494', '',... 
%             'x719', '',...
%             'x762', '',...
%             'x800', '',...
%             'x852', '',...
%             'x860', '',...
%             'x838', ''...
%             );
        
        % Write experiment result in this file
        RESULT_FILE = ['workdata' filesep 'cov_exp_result'];
        
        % save corpus meta in this file
        CORPUS_COV_META = ['workdata' filesep 'corpuscoverage'];
        
        % Save coverage experiment results in this directory
        RESULT_DIR_COVEXP = 'covexp_results';
        CACHE_DIR = 'covexp_results_cache';
        USE_CACHED_RESULTS = true;
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

