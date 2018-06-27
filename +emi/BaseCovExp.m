classdef BaseCovExp < handle
    %BASECOVEXP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant = true)
        
    end
    
    properties
        models;
        result;
        l; % logger
    end
    
    methods
        
        function obj = BaseCovExp()
            obj.l = logging.getLogger('SomeName');
        end
        
        function init_data(obj)
            obj.models = {'slvnvdemo_cv_small_controller',...
                'sldemo_mdlref_conversionz',...
                'sldemo_mdlref_variants_enum'};
        end
        
        function do_analysis(obj)
            all_models = obj.models;
            
            loop_count = min(numel(all_models), covcfg.MAX_NUM_MODEL);
                        
            if covcfg.PARFOR
                obj.l.info('USING PARFOR');
                parfor i = 1:loop_count
                    fprintf('Analyzing %d of %d models\n', i, loop_count );
                    res(i) = emi.get_single_model_coverage(all_models{i});
                end
            else
                obj.l.info('Using Simple For Loop');
                for i = 1:loop_count
                    obj.l.info(sprintf('Analyzing %d of %d models', i, loop_count ));
                    res(i) = emi.get_single_model_coverage(all_models{i}); %#ok<AGROW>
                end
            end
            
            obj.result = res;
            
            obj.l.info(sprintf('Done... analyzed %d models', loop_count));
        end

        
        function covexp_result = go(obj)
            obj.init_data();
            obj.do_analysis();
            covexp_result = obj.result;
            
            % Save Result
            if ~ isempty(covcfg.RESULT_FILE)
                save(covcfg.RESULT_FILE, 'covexp_result');
            end
        end
    end
    
end

