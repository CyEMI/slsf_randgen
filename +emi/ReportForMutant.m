classdef ReportForMutant < handle
    %REPORTFORMUTANT Report for a single mutant
    %   Detailed explanation goes here
    
    properties
        mutant_id;
        
        timedout = [];
        exception = [];
        
        preprocess_error = false;
        
        exception_id = [] ;
        exception_ob = [] ;
        
    end
    
    methods
        function obj = ReportForMutant( mutant_id)
            obj.mutant_id = mutant_id;
        end
        
        function ret = get_report(obj)
            ret = utility.get_struct_from_object(obj);
        end
        
        function ret = is_ok(obj)
            is_to = obj.timedout;
            is_ex = obj.exception;
            
            if isempty(obj.timedout)
                is_to = false;
            end
            
            if isempty(obj.exception)
                is_ex = false;
            end
            
            ret = ~obj.preprocess_error && ~is_to && ~is_ex;
        end
        
    end
    
end

