classdef LiveMutation < emi.decs.DecoratedMutator
    %DEADBLOCKDELETESTRATEGY Summary of this class goes here
    %   Detailed explanation goes here
    
%     methods(Abstract)
%         % Implement re-connection logic
%         post_delete_strategy(obj, sources, dests, parent_sys);
%     end
    
    methods
        
        function obj = LiveMutation(varargin)
            obj = obj@emi.decs.DecoratedMutator(varargin{:});
        end
        
        function main_phase(obj)
            %% 
            
            
            %% prev code
            if size(obj.r.live_blocks, 1) == 0
                obj.l.warn('No live blocks in the original model! Returning from Decorator.');
                return;
            end
            
            live_blocks = obj.r.sample_live_blocks();
            live_blocks = cellfun(@(p) [obj.mutant.sys '/' p],...
                live_blocks, 'UniformOutput', false);
            
            % blocks may have repeated contents. Use the following if you
            % want to not mutate with replacement.
%             [live_blocks, blk_idx] = unique(live_blocks);
            blk_idx = ones(length(live_blocks), 1); % repeatation allowed
            
            cellfun( ...
                        @(p, op) obj.mutate_a_block(p, [], op) ...
                    , live_blocks, obj.r.live_ops(blk_idx));
            
        end
        
        function ret = mutate_a_block(obj, block, contex_sys, mut_op_id)
            %% MUTATE A BLOCK `block` using `mut_op`
            
            ret = true;
            
            if iscell(block)
                % Recursive call when `block` is a cell
                for b_i = 1:numel(block)
                    obj.mutate_a_block([contex_sys '/' block{b_i}], contex_sys);
                end
                return;
            end
            
%             if emi.cfg.SKIP_DELETES.isKey(get_param(block, 'BlockType'))
%                 obj.l.debug('Not deleting as pre-configured %s', block);
%                 obj.r.num_skip_delete = obj.r.num_skip_delete + 1;
%                 return;
%             end
            
            try
                [connections,sources,destinations] = emi.slsf.get_connections(block, true, true);
            catch e
                disp(e);
            end
            
            is_block_not_action_subsystem = all(...
                ~strcmpi(connections{:, 'Type'}, 'ifaction'));
            
            is_if_block = strcmp(get_param(block, 'blockType'), 'If');
            
            if is_if_block || ~is_block_not_action_subsystem
                obj.r.n_live_skipped = obj.r.n_live_skipped + 1;
                return;
            end

            obj.r.n_live_mutated = obj.r.n_live_mutated + 1;
            
            [block_parent, this_block] = utility.strip_last_split(block, '/');
            
%             hilite_system(block);
            
            % Pause for containing (parent) subsystem or the block iteself?
            pause_d = emi.pause_for_ss(block_parent, block);
            
            if pause_d
                % Enable breakpoints
                disp('Pause for debugging');
            end
            
            % To enable hilighting and pausing, uncomment the following:
%             emi.hilite_system(block, emi.cfg.DELETE_BLOCK_P || pause_ss);
%             emi.pause_interactive(emi.cfg.DELETE_BLOCK_P || pause_ss, 'Delete block %s', block);

            mut_op = emi.cfg.LIVE_MUT_OPS{mut_op_id} ;
            
            bl = mut_op(obj.r, block_parent, this_block,...
                connections, sources, destinations, is_if_block);
            
            bl.go();
            
            emi.pause_interactive(emi.cfg.DELETE_BLOCK_P, 'Block %s Live Mutation completed', block);
            
        end
        
    end
end

