classdef Model < handle
    %MODEL CPS Model
    %   Detailed explanation goes here
    
    properties
        l;
        
        sys;
        loc;
        
        blocks;
        compiled_types;
        
        %% Manipulation
        model_builders; % map containing model builders for each subsystem
        rec; % Manipulation recorder
        
        %% Manipulation Stats
        
        newly_added_block_counter = 0;
        newly_added_block_prefix = 'cyemi';
    end
    
    methods(Abstract)
        copy_from(obj, src)
        load_model(obj)
    end
    
    methods
        function obj = Model(sys, loc, blocks, compiled_types, pp_only)
            obj.l = logging.getLogger('CPSMODEL');
            
            obj.sys = sys;
            obj.loc = loc;
            
            obj.blocks = blocks;
            obj.compiled_types = compiled_types;
            
            obj.model_builders = containers.Map();
            obj.rec = utility.cell();
            
            if ~ pp_only
                % Give a different prefix as names may conflict before pp
                % and after pp
                obj.newly_added_block_prefix = 'emi';
            end
        end
        
        function ret = filepath(obj)
            ret = [obj.loc filesep obj.sys emi.cfg.MUTANT_PREPROCESSED_FILE_EXT]; % .slx
        end
        
        function ret = filter_block_by_type(obj, blktype)
            %%
            ret = obj.blocks{strcmpi(obj.blocks.blocktype, blktype),1};
        end
        
        function ret = get_new_block_name(obj)
            %%
            ret = sprintf('%s_%d', obj.newly_added_block_prefix, obj.newly_added_block_counter);
            obj.newly_added_block_counter = obj.newly_added_block_counter + 1;
        end
        
        function ret = get_compiled_type(obj, parent, block, porttype, prt)
            %% `porttype` can be 'Inport' or 'Outport'
            % `prt` is optional. When omitted returns cell containing all ports.
            % Either use the parent, block style or set empty to parent. In
            % that case block is assumed to be the full path except the
            % model name.
            
            if isempty(parent)
                block_key = block;
            else
                block_key = utility.strip_first_split([parent '/' block], '/');
            end
            
            if ~ obj.compiled_types.isKey(block_key)
                error('Block %s not found in compiled datatypes!', block_key);
            end

            dt = obj.compiled_types(block_key);
            
            ret = dt.(porttype);
            
            if nargin >= 5
                ret = ret{prt};
            end
        end
        
        function add_block_compiled_types(obj, parent, src_blk, src_prt, n_blk, n_out_type)
            %% Register a newly added `n_blk` block's source and destination
            % types in the compiled-types database (i.e. obj.compiled_types)
            % WARNING assumes only one input and output port for the newly
            % added `n_blk`
            
            if ~emi.cfg.SPECIFY_NEW_BLOCK_DATATYPE
                return;
            end
            
            src_outtype = obj.get_compiled_type(parent, src_blk, 'Outport');
            assert(isscalar(src_prt));
            
            n_in_type = src_outtype{src_prt};
            
            s = struct;
            s(1).Inport= {n_in_type};
            s(1).Outport = {n_out_type};
            
            obj.compiled_types(utility.strip_first_split([parent '/' n_blk], '/')) = s;
        end
        
    end
end

