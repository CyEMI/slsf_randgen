classdef BaseComparator < handle
    %BASECOMPARATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        r;                  % My Report
        
        data;
        refined_data;
    end
    
    methods
        function obj = BaseComparator(inputArg1,inputArg2)
            %BASECOMPARATOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

