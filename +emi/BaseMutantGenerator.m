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
            
            obj.implement_mutation();
            
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
        
        function init_dead_blocks_mutation(obj)
            assert(~isempty(obj.dead_blocks));
            
            obj.sample_dead_blocks_to_delete();
        end
        
        function sample_dead_blocks_to_delete(obj)
        end
    end
    
end

