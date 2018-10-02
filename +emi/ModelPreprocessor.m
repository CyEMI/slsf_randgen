classdef ModelPreprocessor < emi.BaseModelMutator
    %MODELPREPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ModelPreprocessor(model_data)
            %MODELPREPROCESSOR Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@emi.BaseModelMutator([], 1, model_data);
            
            obj.disable_saving_result = true;
            obj.dont_preprocess = false;
        end
        
        function ret = go(obj)
            ret = false;
            
            obj.init();
            
            if ~ obj.open_model()
                return;
            end
            
            ret = obj.process_single_model(true);

            obj.close_model();
        end
    end
    
    methods(Access=protected)
        function init(obj)
            obj.model_data = table2struct(obj.model_data);
            obj.sys = obj.model_data.sys;
            obj.m_id = obj.model_data.m_id;
            
            obj.choose_num_mutants(1);
            
            obj.result = emi.ReportForModel(obj.exp_no, obj.m_id);
            
            obj.REPORT_DIR_FOR_THIS_MODEL = obj.model_data.loc_input;
        end
    end
end

