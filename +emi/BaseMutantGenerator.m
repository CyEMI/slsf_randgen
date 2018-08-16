classdef BaseMutantGenerator < handle
    %BASEMUTANTGENERATOR Create a mutant
    %   Detailed explanation goes here
    
    properties
        %%
        result;
        
        dead_blocks;        % Of original model
        live_blocks;        % Of original model
    end
    
    properties(Access = protected)
        %%
        original_sys;
        
        my_id;
        
        sys; % mutant
        
        l = logging.getLogger('MutantGenerator');
        
        exp_data;
        base_dir_for_this_model;
        
        % This many dead blocks will be deleted
        num_dead_blocks_to_remove;
        
        newly_added_block_counter = 0;
        newly_added_block_prefix = 'cyemi';
    end
    
    methods (Abstract)
        %% To be implemented by sub-classes
        implement_mutation(obj)
    end
    
    methods
        %% Public Methods
        
        function obj = BaseMutantGenerator(my_id, original_sys, exp_data, base_dir_for_this_model)
            %% Constructor
            obj.my_id = my_id;
            obj.original_sys = original_sys;
            obj.exp_data = exp_data;
            obj.base_dir_for_this_model = base_dir_for_this_model;
            
            obj.sys = sprintf('%s_%d', original_sys, my_id);
            
            obj.result = emi.ReportForMutant(my_id);
        end
        
        function go(obj)
            %%
            obj.init();
            
            obj.l.info(['Begin mutant generation ' obj.sys]);
            
            % Create Mutant!
            
            try
                obj.implement_mutation();
            catch e
                obj.close_model();
                obj.l.error(['Error while mutant generation: '  e.identifier]);
                rethrow(e);
            end
            
            % run mutant
            if ~ obj.compile_and_run()
                obj.l.error('Mutant %d did not compile/run', obj.my_id);
                
                if emi.cfg.KEEP_ERROR_MUTANT_OPEN
                    open_system(obj.sys);
                end
            else
                % Close Model
                obj.close_model();
            end
            
            obj.l.info(['End mutant generation: ' obj.sys]);
        end
    end
    
    methods(Access = protected)
        %% Protected Methods
        
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
                    return;
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
        
        function ret = delete_a_block(obj, block, sys_for_context)
            %% DELETE A BLOCK `block`
            
            ret = true;
            
            if iscell(block)
                for b_i = 1:numel(block)
                    obj.delete_a_block([sys_for_context '/' block{b_i}], sys_for_context);
                end
                return;
            end
            
            try
                connections = struct2table(get_param(block, 'PortConnectivity'));
            catch e
                % the block was not found. Was it already deleted?
                error(e.identifier);
            end
                
            
            emi.hilite_system(block, emi.cfg.DELETE_BLOCK_P);
            
            emi.pause_interactive(emi.cfg.DELETE_BLOCK_P, 'Delete block %s', block);
            
            
            % See 'PortConnectivity' in https://www.mathworks.com/help/simulink/slref/common-block-parameters.html
            % if block is action-subsystem, don't inclue the `ifaction`
            % port in sources
            sources = connections(rowfun(@(q, p) ~isempty(p) && ~strcmpi(q, 'ifaction'),...
                connections(:,{'Type', 'SrcPort'}), 'OutputFormat', 'uniform',...
                'ExtractCellContents', true), {'Type','SrcBlock', 'SrcPort'});
            
            destinations = connections(cellfun(@(p) ~isempty(p), connections{:, 'DstPort'}), {'Type','DstBlock', 'DstPort'});
            
            is_if_block = strcmp(get_param(block, 'blockType'), 'If');
            
            
            % Delete existing lines
            function ret = delete_connection(sys, s_b, s_p, d_b, d_p, is_if)
                %% Delete a connection
                if ~ iscell(d_b)
                    d_b = {d_b};
                end
                
                for i=1:numel(d_b)
                    if is_if
                        dest_port = 'ifaction';
                    else
                        dest_port = int2str(d_p(i));
                    end
                    
                    try
                        delete_line(sys, [s_b '/' s_p], [d_b{i} '/' dest_port]);
                    catch err
                        error(err.identifier)
                    end
                end
                
                ret = true;
            end
            
            try
                [block_parent, this_block] = utility.strip_last_split(block, '/');
            catch e
                getReport(e)
                obj.l.error('Input was: %s', block);
                error(e.identifier);
            end
            
            % Delete source -> block connections
            rowfun(@(a,b,c) delete_connection(block_parent, get_param(b, 'Name'),...
                int2str(c + 1), this_block, str2double(a), false),...
                sources, 'ExtractCellContents', true);
            
            % Delete block -> destination connections
            rowfun(@(a,b,c) delete_connection(block_parent, this_block, a, get_param(b, 'Name'), c + 1, is_if_block),...
                destinations, 'ExtractCellContents', true, 'ErrorHandler', @utility.rowfun_eh);
            
            % Delete if not Action subsystem
            is_block_not_action_subsystem = all(...
                ~strcmpi(connections{:, 'Type'}, 'ifaction'));
            
            emi.hilite_system(block, emi.cfg.DELETE_BLOCK_P, 'fade');
           
            
            if is_block_not_action_subsystem
                try
                    delete_block(block);
                catch e
                    error(e.identifier);
                end
            end
            
            emi.pause_interactive(emi.cfg.DELETE_BLOCK_P, 'Block %s Deleted', block);
            
            if is_if_block
                % Delete successors? Just first one in the path?
                % Note: should not apply `delete_a_block` recursively to
                % successors.
%                 rowfun(@(~,b,~) obj.delete_a_block(get_param(b, 'Name'), block_parent),...
%                     destinations, 'ExtractCellContents', true, 'ErrorHandler', @utility.rowfun_eh);
            elseif ~ is_block_not_action_subsystem
                obj.address_unconnected_ports(true, true, true, sources, destinations, block_parent);
                [my_s, my_d] = obj.get_my_block_ports(block, sources, destinations);
                obj.address_unconnected_ports(true, true, true, my_d, my_s, block_parent);
            else
                % Reconnect source - destinations
                % May want to do it randomly. Because leaving them
                % unconnected should not matter and can be good test
                % points. Also, re-connectig might be useful test points.
                obj.address_unconnected_ports(true, true, true, sources, destinations, block_parent);
            end
            
        end
        
        function [my_s, my_d] =  get_my_block_ports(~, blk, sources, dests)
            % Note: first column of the return types is garbage and should
            % not be used!
            my_handle = get_param(blk, 'Handle');
            
            % Sources
            
            new_blk = cell(size(sources, 1), 1);
            new_prt = cell(size(sources, 1), 1);
            
            for i=1:size(sources, 1)
                new_blk{i} = my_handle;
                new_prt{i} = i-1;
            end
            
            my_s = table(new_blk, new_blk, new_prt);
            
            % Destinations
            
            new_blk = cell(size(dests, 1), 1);
            new_prt = cell(size(dests, 1), 1);
            
            for i=1:size(dests, 1)
                new_blk{i} = my_handle;
                new_prt{i} = i-1;
            end
            
            my_d = table(new_blk, new_blk, new_prt);
        end
            
        
        function address_unconnected_ports(obj, reconnect, do_s, do_d, sources, dests, parent_sys) %#ok<INUSL>
            %%
            % TODO randomly choose a strategy
            obj.add_type_compatible_blocks(do_s, do_d, sources, dests, parent_sys);
        end
        
        function add_type_compatible_blocks(obj, do_s, do_d, sources, dests, parent_sys)
            %%
            function ret = helper(b, p, is_handling_source)
                ret = true;
                
                if is_handling_source
                    new_blk_type = 'simulink/Sinks/Terminator';
                else
                    new_blk_type = 'simulink/Sources/Ground';
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
        
        function reconnect_ports(~)
            %% 
            
        end
        
        function hilite_all_dead(obj)
            %%
            if ~ emi.cfg.INTERACTIVE_MODE
                return;
            end
            
            blocks = obj.dead_blocks{:, 'fullname'};
            cellfun(@(p) emi.hilite_system([obj.sys '/' p]), blocks, 'UniformOutput', false);
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
        
        function [new_blk_name, h] = add_new_block_in_model(obj, parent_sys, new_blk_type)
            %%
            new_blk_name = obj.get_new_block_name();
            h = add_block(new_blk_type, [parent_sys '/' new_blk_name]);
        end
    end
    
end

