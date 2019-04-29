classdef LiveMutation < emi.decs.DecoratedMutator
    %DEADBLOCKDELETESTRATEGY Summary of this class goes here
    %   Detailed explanation goes here
    

    properties
        % skip mutation op if filter returns true.
        % key: mut_op_id, val: lambda
        mutop_skip = containers.Map(...
        );
    
    end
    
    methods
        
        function obj = LiveMutation(varargin)
            obj = obj@emi.decs.DecoratedMutator(varargin{:});
        end
        
        function main_phase(obj)
            %% 
            e = [];
            
            try
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
            catch e
                rethrow(e);
            end
            
            if ~isempty(e)
                rethrow(e);
            end
            
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
            
            mut_op = emi.cfg.LIVE_MUT_OPS{mut_op_id} ;
            
            blacklist = emi.cfg.MUT_OP_BLACKLIST{mut_op_id};
            
            skip =  blacklist.isKey(cps.slsf.btype(block)) ;
            
            % Check if predecessor has constant sample time
            
            try
                [connections,sources,destinations] = emi.slsf.get_connections(block, true, true);
            catch e
                rethrow(e);
            end
            
            try
                if mut_op_id == 2 && ~isempty(sources)
                    skip = skip || emi.live.modelreffilter(obj.mutant, sources);
                end
            catch e
                rethrow(e);
            end
                            
            if ~skip && obj.mutop_skip.isKey(mut_op_id)
                wo_parent = utility.strip_first_split(block, '/');
                fn = obj.mutop_skip(mut_op_id);
                skip =  fn(obj, wo_parent);
            end
            
            if skip
                obj.l.debug('Not mutating %s',...
                    block);
                obj.r.n_live_skipped = obj.r.n_live_skipped + 1;
                return;
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

            
            bl = mut_op(obj.r, block_parent, this_block,...
                connections, sources, destinations, is_if_block);
            
            bl.go(obj);
            
            emi.pause_interactive(emi.cfg.DELETE_BLOCK_P, 'Block %s Live Mutation completed', block);
            
        end
        
    end
end

