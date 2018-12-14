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
        function obj = Model(sys, loc, blocks, compiled_types)
            obj.l = logging.getLogger('CPSMODEL');
            
            obj.sys = sys;
            obj.loc = loc;
            
            obj.blocks = blocks;
            obj.compiled_types = compiled_types;
            
            obj.model_builders = containers.Map();
            obj.rec = utility.cell();
        end
        
        function ret = filepath(obj)
            ret = [obj.loc filesep obj.sys emi.cfg.MUTANT_PREPROCESSED_FILE_EXT]; % .slx
        end
        
        function ret = filter_block_by_type(obj, blktype)
            %%
            ret = obj.blocks{strcmpi(obj.blocks.blocktype, blktype),1};
        end
        
    end
end

