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
            %% Adds a block between each source -> dest connection
            % 'simulink/Signal Attributes/Data Type Conversion'
            
            blk_type = 'simulink/Signal Attributes/Data Type Conversion';
            
            combs = emi.slsf.choose_source_dest_pairs_for_reconnection(sources, dests);
            
            for i=1:combs.len
                cur = combs.get(i);
                
                % Add new block
                % what's the type of this destination block's jth input
                % port?
                if emi.cfg.DTC_SPECIFY_TYPE
                    inport_types = obj.get_compiled_type(parent_sys, cur.d_blk, 'Inport');
                    dtc_out_type = inport_types{cur.d_prt}; % Outport type of DTC block
                    dtc_type_params = struct('OutDataTypeStr', emi.slsf.get_datatype(dtc_out_type));
                else
                    dtc_out_type = [];
                    dtc_type_params = struct;
                end

                [new_blk_name, ~] = obj.add_new_block_in_model(parent_sys, blk_type,...
                    dtc_type_params);

                obj.l.debug('Added new DTC block %s', new_blk_name);

                % add new DTC block in compiled data types registry
                obj.add_dtc_block_compiled_types(parent_sys, cur.s_blk, cur.s_prt, new_blk_name, dtc_out_type);

                % Connect DTC -> destination
                
                add_line(parent_sys, [new_blk_name '/1'], [cur.d_blk '/' int2str(cur.d_prt)],...
                        'autorouting','on');
                obj.l.debug('Connected %s/1 ---> %s/%d', new_blk_name, cur.d_blk, cur.d_prt);

                % Connect source -> DTC

                add_line(parent_sys, [cur.s_blk '/'...
                        int2str(cur.s_prt)], [new_blk_name '/1' ],...
                        'autorouting','on');
                obj.l.debug('Connected %s/%d ---> %s/1', cur.s_blk, cur.s_prt, new_blk_name);
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
                error('Block not found in compiled datatypes');
            end
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
        
        function ret = get_new_block_name(obj)
            %%
            ret = sprintf('%s_%d', obj.newly_added_block_prefix, obj.newly_added_block_counter);
            obj.newly_added_block_counter = obj.newly_added_block_counter + 1;
        end
        
        function ret = get_model_builder(obj, parent)
            %%
            if obj.model_builders.isKey(parent)
                ret = obj.model_builders(parent);
            else
                ret = emi.slsf.ModelBuilder(parent);
                ret.init();
                obj.model_builders(parent) = ret;
            end
        end
        
        function ret = get_pos_for_next_block(obj, parent)
            %%
            ret = obj.get_model_builder(parent).get_new_block_position();
        end
        
        function add_dtc_block_compiled_types(obj, parent, blkname, blkprt, dtc, dtc_out_type)
            %% Register a newly added `dtc` block's source and destination
            % types in the compiled-types database (i.e. obj.compiled_types)
            
            if ~emi.cfg.DTC_SPECIFY_TYPE
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
        
        function delete_src_to_block(obj, block_parent, this_block, sources) %#ok<INUSL>
            emi.slsf.delete_src_to_block(block_parent, this_block, sources);
        end
        
        function delete_block_to_dest(obj, block_parent, this_block, destinations, is_if_block)  %#ok<INUSL>
            emi.slsf.delete_block_to_dest(block_parent, this_block, destinations, is_if_block);
        end
        
        function delete_block(obj, blk)  %#ok<INUSL>
            delete_block(blk);
        end
        
        function add_line(obj, parent_sys, src, dest) %#ok<INUSL>
            add_line(parent_sys, src, dest, 'autorouting','on');
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

