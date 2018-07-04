classdef CorpusCovExp < covexp.BaseCovExp
    %CORPUSCOVEXP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function init_data(obj)
            class(obj)
            load(covcfg.CORPUS_COV_META);
            obj.models = utility.filter_struct(cov_meta, 'group', 'sys', covcfg.CORPUS_GROUP);
        end
        
    end
    
end

