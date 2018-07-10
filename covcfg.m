classdef covcfg
    %COVCFG Configure `covcollect` - collecting coverage of models 
    %   Detailed explanation goes here
    
    properties(Constant = true)
        
        EXP_MODE = covexp.Expmode.SUBGROUP;
        SUBGROUP_BEGIN = 251;
        SUBGROUP_END = 272;
        
        % Upper limit on how many models to process
        % For SUBGROUP_AUTO, process these many models 
        MAX_NUM_MODEL = 50;
        
        SIMULATION_TIMEOUT = 150;   % seconds
        
        BASE_DIR = '';
        
        % Which corpus group to analyze (e.g. tutorial)
%         CORPUS_GROUP = 'tutorial';
        CORPUS_GROUP = []; % Analyze all corpus groups.
        
        OPEN_MODELS = false;
        CLOSE_MODELS = true;
        
        % Will use parfor
        PARFOR = false;
        
        % Model IDs to skip, start with x
        SKIP_LIST = struct(...
            'x494', ''...   
            );
        
        % Write experiment result in this file
        RESULT_FILE = 'cov_exp_result';
        
        % save corpus meta in this file
        CORPUS_COV_META = 'corpuscoverage';
        
        % Save coverage experiment results in this directory
        RESULT_DIR_COVEXP = 'covexp_results';
        
        % Expmode.SUBGROUP_AUTO
        SUBGROUP_AUTO_DATA = 'cov_exp_subgroup';
   
    end
    
    methods
    end
    
end

