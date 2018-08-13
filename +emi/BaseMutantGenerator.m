classdef BaseMutantGenerator < handle
    %BASEMUTANTGENERATOR Create a mutant
    %   Detailed explanation goes here
    
    properties
        original_sys;
        
        my_id;
        
        sys; % mutant
        
        result;
        
        dead_blocks;
        live_blocks;
        
        l = logging.getLogger('MutantGenerator');
        
        exp_data;
        base_dir_for_this_model;
        
        % Dead block deletion
        num_dead_blocks_to_remove;
    end
    
    methods (Abstract)
        implement_mutation(obj)
    end
    
    methods
        
        function obj = BaseMutantGenerator(my_id, original_sys, exp_data, base_dir_for_this_model)
            obj.my_id = my_id;
            obj.original_sys = original_sys;
            obj.exp_data = exp_data;
            obj.base_dir_for_this_model = base_dir_for_this_model;
            
            obj.sys = sprintf('%s_%d', original_sys, my_id);
            
            obj.result = struct();
        end
        
        function create_copy_of_original(obj)
            save_system(obj.original_sys, [obj.base_dir_for_this_model filesep obj.sys]);
            
            try
                emi.open_or_load_model(obj.sys);
            catch e
                obj.l.error(e.identifier);
                error('Mutant saving failed, probably because a model with same name exists.');
            end
            
        end
        
        
        function init(obj)
            obj.create_copy_of_original();
        end
        
        
        function go(obj)
            obj.init();
            
            obj.l.info(['Begin mutant generation ' obj.sys]);
            
            try
                obj.implement_mutation();
            catch e
                obj.close_model();
                obj.l.error(['Error while mutant generation: '  e.identifier]);
                rethrow(e);
            end
            
            % Close Model
            obj.close_model();
            
            obj.l.info(['End mutant generation ' obj.sys]);
        end
        
        function close_model(obj)
            save_system(obj.sys);
            
            if ~ emi.cfg.INTERACTIVE_MODE
                bdclose(obj.sys);
            end
        end
        
        function strategy_dead_block_removal(obj)
            if size(obj.dead_blocks, 1) == 0
                obj.l.warn('No dead blocks in the original model!');
                return;
            end
                        
            blocks_to_delete = obj.sample_dead_blocks_to_delete();
            blocks_to_delete = cellfun(@(p) [obj.sys '/' p], blocks_to_delete, 'UniformOutput', false);
            
            % blocks_to_delete may have repeated contents
            blocks_to_delete = utility.unique(blocks_to_delete);
            
            cellfun(@(p) obj.delete_a_block(p, []), blocks_to_delete);
            
%             if emi.cfg.INTERACTIVE_MODE
%                 emi.hilite_system(blocks_to_delete);
%             end
        end        
        
        function ret = delete_a_block(obj, block, sys_for_context)   
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
            sources = connections(rowfun(@(q, p) ~isempty(p) && ~strcmpi(q, 'ifaction'),...
                connections(:,{'Type', 'SrcPort'}), 'OutputFormat', 'uniform',...
                'ExtractCellContents', true), {'Type','SrcBlock', 'SrcPort'});
            
            destinations = connections(cellfun(@(p) ~isempty(p), connections{:, 'DstPort'}), {'Type','DstBlock', 'DstPort'});
            
            is_if_block = strcmp(get_param(block, 'blockType'), 'If');
            
            
            % Delete existing lines
            function ret = delete_connection(sys, s_b, s_p, d_b, d_p, is_if)
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
            
%             function delete_multi_blocks(blocks)
%                 obj.delete_a_block(blocks, block_parent);
%             end
            
            if is_if_block
                % Delete successors? Just first one in the path?
%                 rowfun(@(~,b,~) obj.delete_a_block(get_param(b, 'Name'), block_parent),...
%                     destinations, 'ExtractCellContents', true, 'ErrorHandler', @utility.rowfun_eh);
            else
                % Reconnect source - destinations
                % May want to do it randomly. Because leaving them
                % unconnected should not matter and can be good test
                % points. Also, re-connectig might be useful test points.
            end
            
        end
        
        function hilite_all_dead(obj)
            if ~ emi.cfg.INTERACTIVE_MODE
                return;
            end
            
            blocks = obj.dead_blocks{:, 'fullname'};
            cellfun(@(p) emi.hilite_system([obj.sys '/' p]), blocks, 'UniformOutput', false);
        end
        
        function ret = sample_dead_blocks_to_delete(obj)
            obj.num_dead_blocks_to_remove = ceil(size(obj.dead_blocks, 1) * emi.cfg.DEAD_BLOCK_REMOVE_PERCENT);
            chosen_blocks = randi([1, size(obj.dead_blocks, 1)], 1, obj.num_dead_blocks_to_remove);
            ret = obj.dead_blocks{chosen_blocks, 'fullname'};
        end
    end
    
end

