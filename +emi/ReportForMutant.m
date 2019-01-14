classdef ReportForMutant < handle
    %REPORTFORMUTANT Report for a single mutant
    %   Main data structure/model for a single mutant
    
    properties
        %% 
        
        my_id;                      % mutant number
        
        original_sys;               % The model to mutate (name only)
        
        mutant;                        % Mutant
        
        base_dir_for_this_model;
        
        exp_data;
        
        l;
        
        %% Reporting
        
        exception;
        
        preprocess_error = false;
        
        %% Operation Modes
        
        dont_preprocess;    % If true, skips preprocessing
        exit_after_preprocess;    % "preprocess only" mode
        
        %% Model Maniputlation
        
        % This many dead blocks will be deleted
        num_dead_blocks_to_remove;
        
        % Data for original model
        
        dead_blocks;        % Of original model
        live_blocks;        % Of original model
        
        % stats
        num_deleted = 0;  % dead blocks which were deleted
        num_skip_delete = 0;
        
        % Total time spent (except compilation/execution)
        duration = 0;
        %% Pre-processing bookkeeping
        
        % Some blocks output data types cannot be fixated through the
        % OutDataTypeStr parameter. List here those. These blocks' output
        % types will be fixated by placing Data Type Converter
        blocks_to_annotate; % cell
    end
    
    methods
        function obj = ReportForMutant( my_id, original_sys, exp_data,...
                base_dir_for_this_model, exit_after_pp, dont_preprocess,...
                blocks, compiled_types, deads, lives)
            %% Constructor args
            obj.my_id = my_id;
            obj.original_sys = original_sys;
            obj.exp_data = exp_data;
            obj.base_dir_for_this_model = base_dir_for_this_model;
            
            obj.exit_after_preprocess = exit_after_pp;
            obj.dont_preprocess = dont_preprocess;
            
            obj.dead_blocks = deads;
            obj.live_blocks = lives;
            
            % Non constructor args
            
            obj.l = logging.getLogger('ReportForMutant');
            
            obj.exception = utility.cell();
            
            % Assuming all blocks will be type annotated by DTC. A
            % decorator may override this.
            % Skip first as it might be the model name
            obj.blocks_to_annotate = blocks{2:end,1};
            
            % Create mutant data structure
            obj.mutant = cps.SlsfModel(...
                obj.get_mutant_name(),...
                obj.base_dir_for_this_model,...
                blocks, compiled_types, exit_after_pp...
            );            
        end
        
        function ret = get_mutant_name(obj)
            %% Create Mutant Name
            if obj.exit_after_preprocess % Preprocess mode
                ret = sprintf('%s_%s', obj.original_sys, emi.cfg.MUTANT_PREPROCESSED_FILE_SUFFIX);
            else % Generate Mutant
                ret = sprintf('%s_%d_%d', obj.original_sys, obj.exp_data.exp_no, obj.my_id);
            end
        end
        
        function create_copy_of_original_and_open(obj)
            %% Init the mutant by making a copy of the original model
            obj.mutant.copy_from(obj.original_sys);
            obj.mutant.load_model();
        end
        
        function ret = sample_dead_blocks_to_delete(obj)
            %%
            obj.num_dead_blocks_to_remove = ceil(size(obj.dead_blocks, 1) * emi.cfg.DEAD_BLOCK_REMOVE_PERCENT);
            chosen_blocks = randi([1, size(obj.dead_blocks, 1)], 1, obj.num_dead_blocks_to_remove);
            ret = obj.dead_blocks{chosen_blocks, 'fullname'};
        end
        
        %% Reporting
        
        function ret = get_report(obj)
            %% 
            % calling struct constructor with non-scalars is problematic.
            % Individually assign each of the fields
            ret = struct('my_id', obj.my_id);
            ret.sys = obj.mutant.sys; 
            ret.loc = obj.mutant.loc; 
            ret.preprocess_error = obj.preprocess_error;
            ret.exception = obj.exception.get_cell_T();
            ret.num_mutation = obj.get_num_mutation_ops();
            ret.duration = obj.duration;
        end
        
        function ret = get_num_mutation_ops(obj)
            % How many mutation operations performed?
            ret = obj.num_deleted;
        end
        
        function ret = is_ok(obj)
            %%
            ret = obj.exception.empty();
        end
        
        %% Utility
        
        function hilite_all_dead(obj)
            %%
            if ~ emi.cfg.INTERACTIVE_MODE
                return;
            end
            
            d_blocks = obj.dead_blocks{:, 'fullname'};
            cellfun(@(p) emi.hilite_system([obj.mutant.sys '/' p]), d_blocks, 'UniformOutput', false);
        end
        
    end
    
    methods(Static=true)
        function ret = dummy()
            %% Get a dummy instance usefull for auto-complete in IDE
            ret = emi.ReportForMutant(1,'dummy',struct('exp_no', 3),[],[],[]);
        end
    end
    
end
