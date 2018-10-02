classdef BaseMutantGenerator < handle
    %BASEMUTANTGENERATOR Create a mutant
    %   Detailed explanation goes here
    
    properties
        %%
        result;
        
        blocks;
        dead_blocks;        % Of original model
        live_blocks;        % Of original model
        compiled_types;
        
        preprocess_only;    % Exit after pre-processing
        dont_preprocess;    % Do everything after pre-processing phase
        
        % stats
        num_deleted = 0;
        num_skip_delete = 0;
    end
    
    properties(Access = protected)
        %%
        original_sys;
        
        my_id;                      % mutant number
        
        sys;                        % Mutant model name
        
        l = logging.getLogger('MutantGenerator');
        
        exp_data;
        base_dir_for_this_model;
        
        % This many dead blocks will be deleted
        num_dead_blocks_to_remove;
        
        newly_added_block_counter = 0;
        newly_added_block_prefix = 'cyemi';
        
        model_builders; % map containing model builders for each subsystem
    end
    
    methods (Abstract)
        %% To be implemented by sub-classes
        implement_mutation(obj)
    end
    
    methods
        %% Public Methods
        
        function obj = BaseMutantGenerator(my_id, original_sys, exp_data,...
                base_dir_for_this_model, preprocess_only, dont_preprocess)
            %% Constructor
            obj.my_id = my_id;
            obj.original_sys = original_sys;
            obj.exp_data = exp_data;
            obj.base_dir_for_this_model = base_dir_for_this_model;
            
            obj.preprocess_only = preprocess_only;
            obj.dont_preprocess = dont_preprocess;
            
            obj.get_sys();
            
            obj.result = emi.ReportForMutant(my_id);
            
            obj.model_builders = utility.map();
            
            obj.l.setCommandWindowLevel(emi.cfg.LOGGER_LEVEL);
            
        end
        
        function get_sys(obj)
            %%
            if obj.preprocess_only
                obj.sys = sprintf('%s_%s', obj.original_sys, emi.cfg.MUTANT_PREPROCESSED_FILE_SUFFIX);
            else
                obj.sys = sprintf('%s_%d_%d', obj.original_sys, obj.exp_data.exp_no, obj.my_id);
            end
        end
        
        function handle_preprocess_only_case(obj)
            %%
            if ~ obj.preprocess_only
                return;
            end
            
            try
                delete([obj.base_dir_for_this_model filesep obj.sys emi.cfg.MUTANT_PREPROCESSED_FILE_EXT]);
            catch
            end
        end
        
        function ret = compile_model_and_return(obj, phase, close_on_success)
            %% phase is a string for logging purpose
            % run mutant
            ret = obj.compile_and_run();
            if ~ ret
                obj.l.error('Mutant %d did not compile/run: %s', obj.my_id, phase);
                
                if emi.cfg.KEEP_ERROR_MUTANT_OPEN
                    % Model is dirty - save manually.
                    open_system(obj.sys);
                else
                    save_system(obj.sys);
                end
            elseif close_on_success
                % Close Model
                obj.close_model();
            end
        end
        
        function go(obj)
            %%
            obj.init();
            
            obj.l.info(['Begin mutant generation ' obj.sys]);
            
            if obj.handle_preprocess()
                return;
            end
            
            try
                obj.implement_mutation();
            catch e
                obj.close_model();
                obj.l.error(['Error while mutant generation (our bug?): '  e.identifier]);
                rethrow(e);
            end
            
            % TODO do this when filtering list of blocks to be efficient
            obj.l.info('Deleted: %d; Delete skipped: %d', obj.num_deleted, obj.num_skip_delete);
            
            obj.compile_model_and_return('MUTANT-GEN', true);
            
            obj.l.info(['End mutant generation: ' obj.sys]);
        end
    end
    
    methods(Access = protected)
        %% Protected Methods
        
        function return_after_this = handle_preprocess(obj)
            %%
            % `return_after_this` indicates if we should return immediately
            % from the calling method.
            return_after_this = false;
            
            if obj.dont_preprocess
                return;
            end
            
            obj.preprocess_model();
            
            pp_only = emi.cfg.RETURN_AFTER_PREPROCESSING_MUTANT || obj.preprocess_only;
            
            if ~ obj.compile_model_and_return('PREPROCESSING', pp_only)
                obj.l.error('Compile after preprocess failed');
                obj.result.preprocess_error = true;
                return_after_this = true;
                return;
            end
            
            if pp_only
                obj.l.info('Returning after preprocessing, not creating actual mutants');
                return_after_this = true;
                return;
            end
        end
        
        function create_copy_of_original(obj)
            %%
            save_system(obj.original_sys, [obj.base_dir_for_this_model filesep obj.sys]);
            
            try
                emi.open_or_load_model(obj.sys);
            catch e
                obj.l.error(e.identifier);
                error('Mutant saving failed, probably because a model with same name exists.');
            end
            
        end
        
        
        function init(obj)
            %%
            obj.handle_preprocess_only_case();
            obj.create_copy_of_original();
            
        end
        
        function is_ok = compile_and_run(obj)
            %%
            is_ok = false;
            
            try
                obj.l.info('Compiling/Running mutant...');
                
                simob = utility.TimedSim(obj.sys, covcfg.SIMULATION_TIMEOUT, obj.l);
                obj.result.timedout = simob.start();
                
                if obj.result.timedout
                    obj.l.info('Timeout occured!');
                    return; % TODO are we saving this timeout status?
                end
            catch e
                obj.result.exception = true;
                obj.result.exception_ob = e;
                
                return;
            end
            
            is_ok = true;
        end
        
        function close_model(obj)
            %%
            save_system(obj.sys);
            
            if ~ emi.cfg.INTERACTIVE_MODE
                bdclose(obj.sys);
            end
        end
        
        function ret = get_model_builder(obj, parent)
            %%
            if obj.model_builders.contains(parent)
                ret = obj.model_builders.get(parent);
            else
                ret = emi.slsf.ModelBuilder(parent);
                ret.init();
                obj.model_builders.put(parent, ret);
            end
        end
        
        function ret = get_pos_for_next_block(obj, parent)
            %%
            ret = obj.get_model_builder(parent).get_new_block_position();
        end
        
        function strategy_dead_block_removal(obj)
            %% Mutation strategy by removing dead blocks from a model
            if size(obj.dead_blocks, 1) == 0
                obj.l.warn('No dead blocks in the original model!');
                return;
            end
            
            blocks_to_delete = obj.sample_dead_blocks_to_delete();
            blocks_to_delete = cellfun(@(p) [obj.sys '/' p], blocks_to_delete, 'UniformOutput', false);
            
            % blocks_to_delete may have repeated contents
            blocks_to_delete = utility.unique(blocks_to_delete);
            
            cellfun(@(p) obj.delete_a_block(p, []), blocks_to_delete);
            
        end
        
        function ret = skip_delete(~, blk)
            %% Check whether `blk` should not be deleted.
            skips = utility.map();
            
            skips.put('Delay', 1);
            skips.put('UnitDelay', 1);
            
            ret = skips.contains(get_param(blk, 'BlockType'));
        end
        
        
        function preprocess_model(obj)
            if emi.cfg.PRE_ANNOTATE_TYPE
                obj.pre_annotate_types_all_blocks();
                %                 obj.pre_annotate_types;
            end
        end
        
        function ret = filter_block_by_type(obj, blktype)
            %%
            ret = obj.blocks{strcmpi(obj.blocks.blocktype, blktype),1};
        end
        
        function pre_annotate_types_all_blocks(obj)
            %% Insert DTC before all blocks all input ports
            target_blocks = obj.blocks{2:end,1}; % First one is the model itself?
            
            function ret = helper(blkname)
                blkname = [obj.sys '/' blkname];
                try
                    [~,sources,~] = emi.slsf.get_connections(blkname, true, false);
                catch e
                    disp(e);
                end
                
                self_as_destination = emi.slsf.create_port_connectivity_data(blkname, size(sources, 1), 0);
                ret = obj.preprocess_a_block(blkname, sources, self_as_destination);
            end
            
            cellfun(@helper,target_blocks);
        end
        
        function pre_annotate_types(obj)
            %% Filter blocks by type and then apply a function on that block
            configs = {...
                {'Delay', @preprocess_delay_blocks}...
                };
            for i=1:numel(configs)
                cur = configs{i};
                filter_fcn = cur{2};
                target_blocks = obj.filter_block_by_type(cur{1});
                cellfun(@(p)filter_fcn(obj, [obj.sys '/' p]),target_blocks);
            end
        end
        
        function ret= preprocess_a_block(obj, blkname, sources, self_as_destination)
            %% Adds a DTC block before ALL input ports
            % sources contains all predecessors of `blkname`
            % self_as_destination is a crafted port-connectivity data
            % structure which contains the `blkname` block itself as
            % destination. Since we need to put DTC as predecessor -> DTC
            % -> blkname
            ret = true; % for cellfun
            
            if isempty(sources)
                return;
            end
            
            [parent, this_block] = utility.strip_last_split(blkname, '/');
            emi.slsf.delete_src_to_block(parent, this_block, sources);
            
            try
                obj.add_dtc_block_in_middle(sources, self_as_destination, parent);
            catch e
                disp(e);
                error('Error adding block during preprocessing');
            end
        end
        
        function ret = preprocess_delay_blocks(obj, blkname)
            %% Add DTC block at the 2nd/delay port of a Delay block
            [~,sources,~] = emi.slsf.get_connections(blkname, true, false);
            sources = sources(strcmp(sources.Type, '2'), :);
            % Destination is just one port: the 2nd port at a delay block
            self_as_destination = emi.slsf.create_port_connectivity_data(blkname, 1, 1);
            ret = obj.preprocess_a_block(blkname,sources, self_as_destination);
        end
        
        function ret = delete_a_block(obj, block, sys_for_context)
            %% DELETE A BLOCK `block`
            
            ret = true;
            
            if iscell(block)
                % Recursive call when `block` is a cell
                for b_i = 1:numel(block)
                    obj.delete_a_block([sys_for_context '/' block{b_i}], sys_for_context);
                end
                return;
            end
            
            if obj.skip_delete(block)
                obj.l.debug('Not deleting as pre-configured %s', block);
                obj.num_skip_delete = obj.num_skip_delete + 1;
                return;
            end
            
            obj.num_deleted = obj.num_deleted + 1;
            
            [connections,sources,destinations] = emi.slsf.get_connections(block, true, true);
            
            [block_parent, this_block] = utility.strip_last_split(block, '/');
            
            % Pause for containing (parent) subsystem?
            pause_ss = emi.pause_for_ss(block_parent);
            
            emi.hilite_system(block, emi.cfg.DELETE_BLOCK_P || pause_ss);
            
            emi.pause_interactive(emi.cfg.DELETE_BLOCK_P || pause_ss, 'Delete block %s', block);
            
            is_if_block = strcmp(get_param(block, 'blockType'), 'If');
            
            emi.slsf.delete_src_to_block(block_parent, this_block, sources);
            emi.slsf.delete_block_to_dest(block_parent, this_block, destinations, is_if_block);
            
            % Delete if not Action subsystem
            is_block_not_action_subsystem = all(...
                ~strcmpi(connections{:, 'Type'}, 'ifaction'));
            
            emi.hilite_system(block, emi.cfg.DELETE_BLOCK_P, 'fade');
            
            
            if is_block_not_action_subsystem
                try
                    delete_block(block);
                catch e
                    disp(e.identifier);
                    error('Error deleting block!');
                end
            end
            
            emi.pause_interactive(emi.cfg.DELETE_BLOCK_P, 'Block %s Deleted', block);
            
            if is_if_block
                % Delete successors? Just first one in the path?
                % Note: should not apply `delete_a_block` recursively to
                % successors, since a successor's predecessor is this block
                obj.l.debug('(!) Deleted If Block!');
                % Do not reconnect!
                obj.address_unconnected_ports(false, true, false, sources, [], block_parent);
            elseif ~ is_block_not_action_subsystem
                obj.l.debug('(!) Did NOT delete Action Subsystem!');
                obj.address_unconnected_ports(true, true, true, sources, destinations, block_parent);
                
                %                 [my_s, my_d] = obj.get_my_block_ports(block, sources, destinations);
                %                 obj.address_unconnected_ports(true, true, true, my_d, my_s, block_parent);
            else
                obj.l.debug('(!) Deleted regular Block!');
                % Reconnect source - destinations
                % May want to do it randomly. Because leaving them
                % unconnected should not matter and can be good test
                % points. Also, re-connectig might be useful test points.
                obj.address_unconnected_ports(true, true, true, sources, destinations, block_parent);
            end
            
        end
        
        function [my_s, my_d] =  get_my_block_ports(~, blk, sources, dests)
            my_s = emi.slsf.create_port_connectivity_data(blk, size(sources, 1), 0);
            my_d = emi.slsf.create_port_connectivity_data(blk, size(dests, 1), 0);
        end
        
        
        function address_unconnected_ports(obj, reconnect, do_s, do_d, sources, dests, parent_sys)
            %%
            % TODO randomly choose a strategy
            obj.add_type_compatible_blocks(do_s, do_d, sources, dests, parent_sys, reconnect);
        end
        
        function add_type_compatible_blocks(obj, do_s, do_d, sources, dests, parent_sys, reconnect)
            %% if `do_s` is true, add a Sink-like block, and connect all
            % block-ports from `sources` --> new Sink-like block.
            % Similarly, connect all block-ports from `dests` if `do_d` is
            % true: "new Source-like block" --> \forall block-ports \in
            % `dests`.
            
            if emi.cfg.DTC_RECONNECT && reconnect && do_s && do_d
                obj.l.debug('Will put Data-type converter');
                try
                    obj.add_dtc_block_in_middle(sources, dests, parent_sys);
                catch e
                    disp(e);
                    error('Error adding block in middle');
                end
                return;
            else
                obj.l.debug('Will NOT put Data-type converter');
            end
            
            if emi.cfg.DTC_RECONNECT && ~reconnect
                % We deleted an If block and are now trying to put a
                % terminator at the If block's predecessor. Skip doing this
                % as we'd also have to choose a data-type for the
                % terminator (sink-like) for obj.compiled_types
                return;
            end
            
            % We chose not to put DTC and reconnect the predecessors and
            % successors of a deleted block. In the following code, use
            % other strategies e.g. putting "sink-like" and/or
            % "source-like" blocks for unconnected ports.
            
            function ret = helper(b, p, is_handling_source)
                %%
                ret = true;
                
                if is_handling_source
                    new_blk_type = 'simulink/Sinks/Terminator';
                else
                    new_blk_type = 'simulink/Sources/Constant';
                end
                
                [new_blk_name, ~] = obj.add_new_block_in_model(parent_sys, new_blk_type);
                
                % Connect
                
                if ~iscell(b)
                    b = {b};
                end
                
                for i=1:length(b)
                    if is_handling_source
                        s_blk = b{i};
                        s_prt = int2str(p(i));
                        d_blk = new_blk_name;
                        d_prt = '1';
                    else
                        s_blk = new_blk_name;
                        s_prt = '1';
                        d_blk = b{i};
                        d_prt = int2str(p(i));
                    end
                    
                    try
                        add_line(parent_sys, [s_blk '/' s_prt], [d_blk '/' d_prt],...
                            'autorouting','on');
                    catch e
                        disp(e);
                    end
                end
            end
            
            if do_s
                rowfun(@(~, b, p) helper(get_param(b, 'Name'), p + 1, true),sources, 'ExtractCellContents', true);
            end
            
            if do_d
                rowfun(@(~, b, p) helper(get_param(b, 'Name'), p + 1, false),dests, 'ExtractCellContents', true);
            end
        end
        
        function ret = get_compiled_type(obj, parent, current_block, porttype)
            %% `porttype` can be 'Inport' or 'Outport'
            try
                block_key = utility.strip_first_split([parent '/' current_block], '/', '/');
                dt = obj.compiled_types{strcmp(obj.compiled_types.fullname, block_key), 'datatype'};
                ret = dt{1}.(porttype);
            catch e
                error('Block not found in compiled datatypes');
            end
        end
        
        function add_dtc_block_compiled_types(obj, parent, blkname, blkprt, dtc, dtc_out_type)
            %% Register a newly added `dtc` block's source and destination
            % types in the compiled-types database (i.e. obj.compiled_types)
            
            if ~emi.cfg.DTC_RECONNECT || ~emi.cfg.DTC_SPECIFY_TYPE
                return;
            end
            
            src_outtype = obj.get_compiled_type(parent, blkname, 'Outport');
            assert(isscalar(blkprt));
            
            desired_type = src_outtype{blkprt};
            
            s = struct;
            s(1).Inport= {desired_type};
            s(1).Outport = {dtc_out_type};
            
            obj.compiled_types = [obj.compiled_types; {utility.strip_first_split([parent '/' dtc], '/', '/'), s}];
        end
        
        function add_dtc_block_in_middle(obj, sources, dests, parent_sys)
            %% Adds a Data-type Converter block between each source -> dest
            % connection
            
            source_ptr = 0;
            
            for d = 1:size(dests, 1)
                cur_d = dests{d, :};
                
                d_blk = get_param(cur_d{2}, 'Name');
                d_prt = cur_d{3} + 1;
                
                if ~ iscell(d_blk)
                    d_blk = {d_blk};
                end
                
                for j = 1: numel(d_blk)
                    
                    % Add new DTC block
                    try
                        % what's the type of this destination block's jth input
                        % port?
                        if emi.cfg.DTC_SPECIFY_TYPE
                            inport_types = obj.get_compiled_type(parent_sys, d_blk{j}, 'Inport');
                            dtc_out_type = inport_types{d_prt(j)}; % Outport type of DTC block
                            dtc_type_params = struct('OutDataTypeStr', emi.slsf.get_datatype(dtc_out_type));
                        else
                            dtc_out_type = [];
                            dtc_type_params = struct;
                        end
                        
                        [new_blk_name, ~] = obj.add_new_block_in_model(parent_sys, 'simulink/Signal Attributes/Data Type Conversion',...
                            dtc_type_params);
                        
                        obj.l.debug('Added new DTC block %s', new_blk_name);
                        
                    catch e
                        disp(e);
                        error('data type adding error');
                    end
                    
                    % Connect DTC -> destination
                    try
                        add_line(parent_sys, [new_blk_name '/1'], [d_blk{j} '/' int2str(d_prt(j))],...
                            'autorouting','on');
                        obj.l.debug('Connected %s/1 ---> %s/%d', new_blk_name, d_blk{j}, d_prt(j));
                    catch e
                        disp(e);
                        error('dtc->dest line adding error');
                    end
                    
                    % Connect source -> DTC
                    source_ptr = source_ptr +1;
                    src_i = source_ptr;
                    
                    if src_i > size(sources, 1)
                        src_i = 1; % TODO select random
                    end
                    
                    cur_src = sources(src_i, :);
                    cur_src = table2cell(cur_src);
                    
                    src_bname = get_param(cur_src{2}, 'Name');
                    src_prt = cur_src{3} + 1;
                    
                    % add new DTC block in compiled data types
                    
                    obj.add_dtc_block_compiled_types(parent_sys, src_bname, src_prt, new_blk_name, dtc_out_type);
                    
                    try
                        add_line(parent_sys, [src_bname '/'...
                            int2str(src_prt)], [new_blk_name '/1' ],...
                            'autorouting','on');
                        obj.l.debug('Connected %s/%d ---> %s/1', src_bname, src_prt, new_blk_name);
                    catch e
                        disp(e);
                        error('connecting src->dtc');
                    end
                end
            end
            
        end
        
        function reconnect_ports(~)
            %%
            
        end
        
        function hilite_all_dead(obj)
            %%
            if ~ emi.cfg.INTERACTIVE_MODE
                return;
            end
            
            d_blocks = obj.dead_blocks{:, 'fullname'};
            cellfun(@(p) emi.hilite_system([obj.sys '/' p]), d_blocks, 'UniformOutput', false);
        end
        
        function ret = sample_dead_blocks_to_delete(obj)
            %%
            obj.num_dead_blocks_to_remove = ceil(size(obj.dead_blocks, 1) * emi.cfg.DEAD_BLOCK_REMOVE_PERCENT);
            chosen_blocks = randi([1, size(obj.dead_blocks, 1)], 1, obj.num_dead_blocks_to_remove);
            ret = obj.dead_blocks{chosen_blocks, 'fullname'};
        end
        
        function ret = get_new_block_name(obj)
            %%
            ret = sprintf('%s_%d', obj.newly_added_block_prefix, obj.newly_added_block_counter);
            obj.newly_added_block_counter = obj.newly_added_block_counter + 1;
        end
        
        function [new_blk_name, h] = add_new_block_in_model(obj, parent_sys, new_blk_type, varargin)
            %%
            
            if nargin == 3
                blk_params = struct;
            else
                blk_params = varargin{1};
            end
            
            new_blk_name = obj.get_new_block_name();
            h = add_block(new_blk_type, [parent_sys '/' new_blk_name],...
                'Position', obj.get_pos_for_next_block(parent_sys));
            
            % Configure block params
            blk_param_names = fieldnames(blk_params);
            
            for i=1:numel(blk_param_names)
                p = blk_param_names{i};
                set_param(h, p, blk_params.(p));
            end
        end
    end
    
end

