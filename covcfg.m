classdef covcfg
    %COVCFG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant = true)
        BASE_DIR = '';
        
        % Which corpus group to analyze
        CORPUS_GROUP = 'tutorial';
        
        OPEN_MODELS = false;
        CLOSE_MODELS = true;
        
        % Upper limit on how many models to process
        MAX_NUM_MODEL = 10000;
        
        % Will use parfor
        PARFOR = false;
        
        % Write experiment result in this file
        RESULT_FILE = 'cov_exp_result';
        
        % save corpus meta in this file
        CORPUS_COV_META = 'corpuscoverage';
    end
    
    methods
    end
    
end

