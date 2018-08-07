classdef BaseModelMutator < handle
    %BASEMODELMUTATOR Mutates a single model to create k mutants
    %   Actual mutants are created by calling instances of
    %   BaseMutantGenerator
    
    properties
        
        exp_data;
        REPORT_DIR_FOR_THIS_MODEL;
        
        exp_no = []; % loop counter value of MAIN_LOOP
        model_data = []; % input
        
        sys;
        m_id;
        result;
        
        num_mutants;
        mutants;
        
        l = logging.getLogger('emi.BaseModelMutator');
        
        dead;
        live;
    end
    
    methods
        
        function obj = BaseModelMutator(exp_data)
            obj.exp_data = exp_data;
        end
        
        function go(obj)
            
            assert(~isempty(obj.model_data));
            assert(~isempty(obj.exp_no));
            
            obj.init();
            
            if ~ obj.open_model()
                return;
            end
            
            try
                obj.process_single_model();
            catch e
                obj.add_exception_in_result(e);
                obj.l.error(getReport(e, 'extended'));
            end
            
            obj.close_model();
        end
        
        
        function init(obj)
            obj.model_data = table2struct(obj.model_data);
            obj.sys = obj.model_data.sys;
            obj.m_id = obj.model_data.m_id;
            
            obj.choose_num_mutants();
            
            obj.result = emi.get_report_datatype(obj.exp_no, obj.m_id);
            
            % Create Directories
            obj.REPORT_DIR_FOR_THIS_MODEL = [obj.exp_data.REPORTS_BASE filesep int2str(obj.exp_no)];
            mkdir(obj.REPORT_DIR_FOR_THIS_MODEL);
        end
        
        function choose_num_mutants(obj)
            obj.num_mutants = emi.cfg.MUTANTS_PER_MODEL;
            obj.mutants = cell(obj.num_mutants, 1);
        end
        
        function add_exception_in_result(obj, e)
            obj.l.error(['Exception: ' e.identifier]);
            obj.result.exception = true;
            obj.result.exception_ob = e;
            obj.result.exception_id = e.identifier;
        end
        
        function opens = open_model(obj)
            opens = true;
            addpath(obj.model_data.loc_input);
            try
                emi.open_or_load_model(obj.sys);
            catch e
                opens = false;
                obj.l.error('Model did not open');
                obj.add_exception_in_result(e);
            end
            
            obj.result.opens = opens;
            rmpath(obj.model_data.loc_input);
        end
        
        function process_single_model(obj)
            obj.get_dead_and_live_blocks();
            
            obj.enable_signal_logging();
            
            obj.create_mutants();
        end
        
        function create_mutants(obj)
            for i=1:obj.num_mutants
                a_mutant = emi.SimpleMutantGenerator(i, obj.sys,...
                    obj.exp_data, obj.REPORT_DIR_FOR_THIS_MODEL);
                a_mutant.live_blocks = obj.live;
                a_mutant.dead_blocks = obj.dead;
                a_mutant.go()
                obj.mutants{i} = a_mutant.result;
            end
        end
        
        function get_dead_and_live_blocks(obj)
            blocks = struct2table(obj.model_data.blocks);
            blocks = blocks(rowfun(@(~,p,~) ~isempty(p{1}) , blocks(:,:),...
                'OutputFormat', 'uniform'), :);
            
            % remove model name from the blocks
            blocks(:, 'fullname') = cellfun(@(p) utility.strip_first_split(...
                p, {'/', '\'}, filesep) ,blocks{:, 'fullname'}, 'UniformOutput', false);
            
            deads = cellfun(@(p) p <0 ,blocks{:,'percentcov'});
            
            obj.dead = blocks(deads, :);
            obj.live = blocks(~deads, :);
        end
        
        function enable_signal_logging(obj)
            
        end
        
        function close_model(obj)
            emi.pause_interactive();
            bdclose(obj.sys);
        end
    end
    
end

