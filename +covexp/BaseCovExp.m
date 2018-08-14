classdef BaseCovExp < handle
    %BASECOVEXP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant = true)
        
    end
    
    properties
        models; % cell of model names
        
        models_path; % cell of model locations, can be empty
        
        % add individual model paths before analyzing the model?
        USE_MODELS_PATH = covcfg.USE_MODELS_PATH;
        
        result;
        l; % logger
        
        exp_start_time;
        report_log_filename;
        
        % If Expmode is SUBGROUP, then use following configurations
        subgroup_begin;
        subgroup_end;
        
        CUR_EXP_DIR;
    end
    
    methods
        
        function obj = BaseCovExp(varargin)
            covexp.addpaths();
            
            obj.l = logging.getLogger('BaseCovExp');
            obj.l.info('Calling BaseCovExp constructor');
            
            if nargin == 2
                obj.subgroup_begin = varargin{1};
                obj.subgroup_end = varargin{2};
            else
                obj.subgroup_begin = covcfg.SUBGROUP_BEGIN;
                obj.subgroup_end = covcfg.SUBGROUP_END;
            end
        end
        
        function init_data(obj)
            obj.models = {'slvnvdemo_cv_small_controller',...
                'sldemo_mdlref_conversionz',...
                'sldemo_mdlref_variants_enum'};
        end
        
        function manage_subgroup_auto(obj)
            if covcfg.EXP_MODE ~= covexp.Expmode.SUBGROUP_AUTO
                return;
            end
            
            obj.l.info('SUBGROUP AUTO mode...');
            
            restart = false;
            
            try
                load(covcfg.SUBGROUP_AUTO_DATA);
                
                sga_begin = sga_end + 1; %#ok<NODEF>
                sga_end = sga_begin + covcfg.MAX_NUM_MODEL - 1;
                
                if sga_begin > numel(obj.models)
                    restart = true;
                end
                
            catch
                obj.l.info('Data file missing, create new');
                restart = true;
            end
            
            if restart
                obj.l.info('SUBGROUP AUTO mode: restarting');
                sga_begin = 1;
                sga_end = covcfg.MAX_NUM_MODEL;
            end
            
            sga_end = min(sga_end, numel(obj.models));
            
            save(covcfg.SUBGROUP_AUTO_DATA, 'sga_begin', 'sga_end');
            
            obj.subgroup_begin = sga_begin;
            obj.subgroup_end = sga_end;
        end
        
        function do_analysis(obj)
            % Analyze ALL models
            all_models = obj.models;
            all_models_path = obj.models_path;
            
            if ~ obj.USE_MODELS_PATH
                all_models_path = cell(size(all_models));
            end
            
            obj.manage_subgroup_auto();
            
            obj.report_log_filename = obj.get_logfile_name(obj.exp_start_time);
            
            obj.l.info('Loading Simulink...');
            load_system('simulink');
            
            if covcfg.EXP_MODE.is_subgroup
                all_models = all_models(obj.subgroup_begin:obj.subgroup_end);
                log_append = sprintf('[%d - %d]', obj.subgroup_begin, obj.subgroup_end);
                model_id_offset = obj.subgroup_begin - 1;
            else
                log_append = '';
                model_id_offset = 0;
            end
            
            loop_count = min(numel(all_models), covcfg.MAX_NUM_MODEL);
            
            cur_exp_dir = obj.CUR_EXP_DIR;
                        
            if covcfg.PARFOR
                obj.l.info('USING PARFOR');
                parfor i = 1:loop_count
                    fprintf('%s Analyzing %d of %d models\n', log_append, i, loop_count );
                    model_id = model_id_offset + i;
                    try
                        res(i) = covexp.get_single_model_coverage(all_models{i}, model_id, all_models_path{i}, cur_exp_dir);
                    catch 
                        res(i) = covexp.single_model_result_error(all_models{i}, model_id, all_models_path{i}, cur_exp_dir);
                    end
                end
            else
                obj.l.info('Using Simple For Loop');
                for i = 1:loop_count
                    obj.l.info(sprintf('%s Analyzing %d of %d models', log_append, i, loop_count ));
                    model_id = model_id_offset + i;
                    
                    try
                        res(i) = covexp.get_single_model_coverage(all_models{i}, model_id, all_models_path{i}, cur_exp_dir); %#ok<AGROW>
                    catch
                        res(i) = covexp.single_model_result_error(all_models{i}, model_id, all_models_path{i}, cur_exp_dir); %#ok<AGROW>
                    end
                    % Save
                    obj.save_result(res, []);
                end
            end
            
            obj.result = res;
            
            obj.l.info(sprintf('Done... analyzed %d models', loop_count));
        end

        
        function covexp_result = go(obj)
            obj.exp_start_time = datestr(now, covcfg.DATETIME_DATE_TO_STR);
            obj.CUR_EXP_DIR = [covcfg.RESULT_DIR_COVEXP filesep obj.exp_start_time];
            
            mkdir(obj.CUR_EXP_DIR);
            mkdir([obj.CUR_EXP_DIR filesep covcfg.TOUCHED_MODELS_DIR]);
            
            % Backup previous report 
            try
                movefile([covcfg.RESULT_FILE '.mat'], [covcfg.RESULT_FILE '.bkp.mat']);
            catch
            end
            
            % Delete cluster jobs
            utility.delete_cluster_jobs(covcfg.PARFOR);
            
            % Add path to corpus
            if ~obj.USE_MODELS_PATH && ( isempty(covcfg.CORPUS_GROUP) || ~ strcmp(covcfg.CORPUS_GROUP, 'tutorial') )
                CORPUS_LOC = covcfg.CORPUS_HOME;

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
            covexp_result = obj.save_result(obj.result, total_time);
            
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
        
        function ret = get_logfile_name(obj, ~)
            ret = [obj.CUR_EXP_DIR filesep covcfg.RESULT_FILENAME];
            if covcfg.EXP_MODE.is_subgroup
                ret = sprintf('%s_%d_%d', ret, obj.subgroup_begin, obj.subgroup_end);
            end
        end
    end
    
end

