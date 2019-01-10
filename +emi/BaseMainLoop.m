classdef BaseMainLoop < handle
    %BASEMAINLOOP The "main loop" of an EMI experiment
    %   Detailed explanation goes here
    
    properties
        model_list = emi.cfg.INPUT_MODEL_LIST;
        
        models; 
        
        data_var_name = 'covexp_result';
        
        l = logging.getLogger('emi.BaseMainLoop');
        
        exp_start_time;
        
        exp_data;
        
    end
    
    properties(Access = protected)
    end
    
    properties(Constant = true)
        
    end
    
    methods
        
        function go(obj)
            obj.l.info('--- Starting Main Loop! ---')
            
            sw = utility.SuppressWarnings();
            sw.set_val('off');
            
            emi.cfg.validate_configurations();
            
            obj.init();
            
            obj.handle_random_number_seed();
            
            obj.save_rng_state_for_model_list(true);
            
            obj.load_models_list();
            obj.models = emi.model_list_filter(obj.models);
            
            obj.choose_models();
            ret = obj.process_all_models();
            
            % Save the current state if we don't need to reproduce the
            % experiment in next run
            
            if ~ emi.cfg.REPLICATE_EXP_IF_ANY_ERROR || all(ret) 
                % No need to reproduce; save RNG state
                obj.l.info('Will NOT reproduce the experiment next time!');
                obj.save_rng_state_for_model_list(true);
            end
            
            sw.restore();
            
            obj.l.info('--- Returning from Main Loop! ---');
        end
    end
    
    methods(Access = protected)
        
        function load_models_list(obj)
            % % takes ~50 sec for 50MB file!
            obj.l.info('Reading cached data from disc...');
            read_data = load(obj.model_list);
            obj.l.info('Read completed.');
            
            models_data = read_data.(obj.data_var_name);
            obj.models = models_data.models;
            
        end
        
        function init(obj)
            % Init exp start time and create directories 
            obj.exp_start_time = datestr(now, covcfg.DATETIME_DATE_TO_STR);
            
            obj.exp_data = struct();
            
            obj.exp_data.REPORTS_BASE = [emi.cfg.REPORTS_DIR filesep obj.exp_start_time];
            mkdir(obj.exp_data.REPORTS_BASE);
            
            copyfile(['+emi' filesep 'cfg.m'], obj.exp_data.REPORTS_BASE);
        end
        
        function handle_random_number_seed(obj)
            if emi.cfg.LOAD_RNG_STATE
                % Backup the variable first
                try
                    copyfile(emi.cfg.WS_FILE_NAME, obj.exp_data.REPORTS_BASE);
                catch 
                    emi.error(obj.l, ['Did not find previously saved state'...
                        ' of `random number generator (RNG)`. Are you'...
                        ' running this script for the first time in this'...
                        ' machine? Then set `LOAD_RNG_STATE = false` in '...
                        '`+emi/cfg.m` file before first-time run.']);
                end
                
                obj.l.info('Restoring random number generator state from disc');
                
                vars_read = load(emi.cfg.WS_FILE_NAME);
                rng(vars_read.(emi.cfg.MODELS_RNG_VARNAME_IN_WS));
            else
                obj.l.info('Starting new random number state...');
                rng(0,'twister');
                % Create the file so that append does not error later
                obj.save_rng_state_for_model_list(false);
            end
        end
        
        function save_rng_state_for_model_list(~, do_append)
            rng_state_models = rng; %#ok<NASGU>
            
            if do_append
                save(emi.cfg.WS_FILE_NAME,...
                    emi.cfg.MODELS_RNG_VARNAME_IN_WS, '-append');
            else
                save(emi.cfg.WS_FILE_NAME,...
                    emi.cfg.MODELS_RNG_VARNAME_IN_WS);
            end
        end
        
        function choose_models(obj)
            obj.models = obj.models(...
                randi([1, size(obj.models, 1)], 1, emi.cfg.NUM_MAINLOOP_ITER), :);
        end
        
        function ret = process_all_models(obj)
            models_cpy = obj.models;
            
            num_models = size(models_cpy, 1);
            
            ret = zeros(num_models, 1);
            
            if emi.cfg.PARFOR
                error('TODO');
            else
                for i=1:num_models
                    obj.l.info(sprintf('Processing %d of %d models', i, num_models));
                    a_result = emi.mutate_single_model(i, models_cpy(i, :), obj.exp_data);
                    
                    ret(i) = a_result.is_ok() &&...
                        a_result.are_mutants_ok() && ...
                        a_result.difftest_ok();
                    
                    if emi.cfg.STOP_IF_ERROR && ~ret(i)
                        obj.l.error('Breaking from MAIN LOOP since model/mutant error');
                        break;
                    end
                    
                end
            end
        end
    end
    
end

