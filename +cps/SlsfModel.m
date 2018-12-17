classdef SlsfModel < cps.Model
    %SLSFMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function copy_from(obj, src)
            %%
            try
                cps.top(false, @save_system,...
                    {src, [obj.loc filesep obj.sys]},...
                    obj.rec, 'Copying model from original');
            catch e
                utility.print_error(e, obj.l);
                obj.l.error('Could not write file probably because a model with same name is open. Closing it.');
                obj.close_model();
                rethrow(e);
            end
        end
        
        function load_model(obj)
            %%
            emi.open_or_load_model(obj.sys);
        end
        
        function ret= add_DTC_before_block(obj, blkname, sources, self_as_destination)
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
            
            obj.add_DTC_in_middle(sources, self_as_destination, parent);
        end
        
        function add_DTC_in_middle(obj, sources, dests, parent_sys)
            blk_type = 'simulink/Signal Attributes/Data Type Conversion';
            
            function ret = helper(blk_config_params, blk_out_type)
                ret = blk_config_params;
                
                if ~isempty(blk_out_type)
                    ret.OutDataTypeStr = emi.slsf.get_datatype(...
                        blk_out_type);
                end
            end
            
            obj.add_block_in_middle(sources, dests, parent_sys,...
                blk_type, @helper);
        end
        
        function add_block_in_middle(obj, sources, dests, parent_sys,...
                blk_type, fun)
            %% Adds a block between each source -> dest connection
            % Will specify the newly added block's type in the compiled
            % type registry.
            % Will call `fun` to configure the block if provided as
            % parameter.
                        
            combs = emi.slsf.choose_source_dest_pairs_for_reconnection(sources, dests);
            
            for i=1:combs.len
                cur = combs.get(i);
                
                n_blk_params = struct;
                
                % Specify the block's data type in compiled types registry
                if emi.cfg.SPECIFY_NEW_BLOCK_DATATYPE
                    inport_types = obj.get_compiled_type(parent_sys, cur.d_blk, 'Inport');
                    n_blk_out_type = inport_types{cur.d_prt};
                else
                    n_blk_out_type = [];
                end
                
                if nargin > 5
                    n_blk_params = fun(n_blk_params, n_blk_out_type);
                end
                
                [new_blk_name, ~] = obj.add_new_block_in_model(parent_sys, blk_type,...
                    n_blk_params);

                % add new block in compiled data types registry
                obj.add_block_compiled_types(parent_sys,...
                    cur.s_blk, cur.s_prt, new_blk_name, n_blk_out_type);

                % Connect n_blk -> destination
                obj.add_line(parent_sys, [new_blk_name '/1'],...
                    [cur.d_blk '/' int2str(cur.d_prt)]);
                
                % Connect source -> n_blk
                obj.add_line(parent_sys, [cur.s_blk '/'...
                        int2str(cur.s_prt)], [new_blk_name '/1' ]);
            end
            
        end
        
        function ret = get_compiled_type(obj, parent, current_block, porttype)
            %% `porttype` can be 'Inport' or 'Outport'
            try
                block_key = utility.strip_first_split([parent '/' current_block], '/', '/');
                dt = obj.compiled_types{strcmp(obj.compiled_types.fullname, block_key), 'datatype'};
                ret = dt{1}.(porttype);
            catch e
                utility.print_error(e, obj.l);
                error('Block not found in compiled datatypes!');
            end
        end
        
        function [new_blk_name, h] = add_new_block_in_model(obj, this_sys, new_blk_type, varargin)
            %%
            
            if nargin == 3
                blk_params = struct;
            else
                blk_params = varargin{1};
            end
            
            new_blk_name = obj.get_new_block_name();
            
            n_blk_full = [this_sys '/' new_blk_name];
            
            h = obj.add_block(new_blk_type, n_blk_full,...
                obj.get_pos_for_next_block(this_sys));
            
            % Configure block params
            blk_param_names = fieldnames(blk_params);
            
            for i=1:numel(blk_param_names)
                p = blk_param_names{i};
                set_param(h, p, blk_params.(p));
            end
            
            obj.l.debug('Added new %s block %s', new_blk_type, n_blk_full);
        end
        
        function ret = get_new_block_name(obj)
            %%
            ret = sprintf('%s_%d', obj.newly_added_block_prefix, obj.newly_added_block_counter);
            obj.newly_added_block_counter = obj.newly_added_block_counter + 1;
        end
        
        function ret = get_model_builder(obj, parent)
            %% Create new or get existing ModelBuilder
            if obj.model_builders.isKey(parent)
                ret = obj.model_builders(parent);
            else
                ret = emi.slsf.ModelBuilder(parent);
                ret.init();
                obj.model_builders(parent) = ret;
            end
        end
        
        function ret = get_pos_for_next_block(obj, parent)
            %% Geometric position for this block in the model
            ret = obj.get_model_builder(parent).get_new_block_position();
        end
        
        function add_block_compiled_types(obj, parent, blkname, blkprt, n_blk, dtc_out_type)
            %% Register a newly added `n_blk` block's source and destination
            % types in the compiled-types database (i.e. obj.compiled_types)
            
            if ~emi.cfg.SPECIFY_NEW_BLOCK_DATATYPE
                return;
            end
            
            src_outtype = obj.get_compiled_type(parent, blkname, 'Outport');
            assert(isscalar(blkprt));
            
            desired_type = src_outtype{blkprt};
            
            s = struct;
            s(1).Inport= {desired_type};
            s(1).Outport = {dtc_out_type};
            
            % semicolon -- doing vertcat, why?
            obj.compiled_types = [obj.compiled_types; {utility.strip_first_split([parent '/' n_blk], '/', '/'), s}];
        end
        
        %% Wrappers to Simulink APIs
        
        function h = add_block(obj, new_blk_type, new_blk_name, pos) %#ok<INUSL>
            h = add_block(new_blk_type, new_blk_name, 'Position', pos);
        end
        
        function delete_src_to_block(obj, block_parent, this_block, sources) %#ok<INUSL>
            emi.slsf.delete_src_to_block(block_parent, this_block, sources);
        end
        
        function delete_block_to_dest(obj, block_parent, this_block, destinations, is_if_block)  %#ok<INUSL>
            emi.slsf.delete_block_to_dest(block_parent, this_block, destinations, is_if_block);
        end
        
        function delete_block(obj, blk)  %#ok<INUSL>
            delete_block(blk);
        end
        
        function add_line(obj, this_sys, src, dest)
            add_line(this_sys, src, dest, 'autorouting','on');
            
            obj.l.debug('[X-->Y] In %s, connected %s ---> %s',...
                this_sys, src, dest);
        end
        
        function close_model(obj)
            %% Saves self and closes
            save_system(obj.sys);
            
            if ~ emi.cfg.INTERACTIVE_MODE
                bdclose(obj.sys);
            end
        end
    end
    
    
%     cps.top(false, @,...
%                 {},...
%                 '');
end

