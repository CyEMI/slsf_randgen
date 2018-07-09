classdef BaseCovExp < handle
    %BASECOVEXP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant = true)
        
    end
    
    properties
        models;
        result;
        l; % logger
        
        exp_start_time;
        report_log_filename;
        
        % If Expmode is SUBGROUP, then use following configurations
        subgroup_begin;
        subgroup_end;
    end
    
    methods
        
        function obj = BaseCovExp()
            obj.l = logging.getLogger('BaseCovExp');
            obj.l.info('Calling BaseCovExp constructor');
            
            obj.subgroup_begin = covcfg.SUBGROUP_BEGIN;
            obj.subgroup_end = covcfg.SUBGROUP_END;
        end
        
        function init_data(obj)
            obj.models = {'slvnvdemo_cv_small_controller',...
                'sldemo_mdlref_conversionz',...
                'sldemo_mdlref_variants_enum'};
        end
        
        function do_analysis(obj)
            % Analyze ALL models
            all_models = obj.models;
            
            if covcfg.EXP_MODE.is_subgroup
                all_models = all_models(obj.subgroup_begin:obj.subgroup_end);
                log_append = sprintf('[%d - %d]', obj.subgroup_begin, obj.subgroup_end);
            else
                log_append = '';
            end
            
            loop_count = min(numel(all_models), covcfg.MAX_NUM_MODEL);
                        
            if covcfg.PARFOR
                obj.l.info('USING PARFOR');
                parfor i = 1:loop_count
                    fprintf('%s Analyzing %d of %d models\n', log_append, i, loop_count );
                    res(i) = covexp.get_single_model_coverage(all_models{i});
                end
            else
                obj.l.info('Using Simple For Loop');
                for i = 1:loop_count
                    obj.l.info(sprintf('%s Analyzing %d of %d models', log_append, i, loop_count ));
                    res(i) = covexp.get_single_model_coverage(all_models{i}); %#ok<AGROW>
                end
            end
            
            obj.result = res;
            
            obj.l.info(sprintf('Done... analyzed %d models', loop_count));
        end

        
        function covexp_result = go(obj)
            obj.exp_start_time = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
            obj.report_log_filename = obj.get_logfile_name(obj.exp_start_time);
            
            obj.l.info('Loading Simulink...');
            load_system('simulink');
            
            % Backup previous report 
            try
                movefile([covcfg.RESULT_FILE '.mat'], [covcfg.RESULT_FILE '.bkp.mat']);
            catch
            end
            
            % Add path to corpus
            if isempty(covcfg.CORPUS_GROUP) || ~ strcmp(covcfg.CORPUS_GROUP, 'tutorial')
                CORPUS_LOC = getenv('SLSFCORPUS');
                if isempty(CORPUS_LOC)
                    error('Set up environment variable SLSFCORPUS');
                end

                addpath(genpath(CORPUS_LOC));
                obj.l.info(['Corpus located at ' CORPUS_LOC]);
            end
            
            % Start counting time
            begin_timer = tic;
            
            % Start experiment
            obj.init_data();
            obj.do_analysis();
            % End experiment
            
            total_time = toc(begin_timer);
            obj.l.info(sprintf('Total runtime %f second ', total_time));
            
            % covexp_result contains everything to be saved in disc
            covexp_result = save_result(obj.result, total_time);
            
            % Save Result
            if ~ isempty(covcfg.RESULT_FILE)
                save(covcfg.RESULT_FILE, 'covexp_result');
            end
            
            obj.l.info(sprintf('Report saved in %s', obj.report_log_filename));
            
            % Run report generation
            covexp.report();
        end
        
        function covexp_result = save_result(obj, models, total_time)
            covexp_result = struct(...
                'parfor', covcfg.PARFOR,...
                'group', covcfg.CORPUS_GROUP,...
                'expmode', covcfg.EXP_MODE,...
                'subgroup_begin', obj.subgroup_begin,...
                'subgroup_end', obj.subgroup_end,...
                'total_duration', total_time);
            
            covexp_result.models = models;
            
            save(obj.report_log_filename, 'covexp_result');
        end
        
        function ret = get_logfile_name(obj, exp_start_time)
            ret = [covcfg.RESULT_DIR_COVEXP filesep exp_start_time];
            if covcfg.EXP_MODE.is_subgroup
                ret = sprintf('%s_%d_%d', ret, obj.subgroup_begin, obj.subgroup_end);
            end
        end
    end
    
end

