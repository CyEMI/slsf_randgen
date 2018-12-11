classdef CoverageDecorator < difftest.DecoratedExecutor
    %COVERAGEDECORATOR Collects Coverage
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function retrieve_sim_result(obj)
            obj.hobj.exec_report.covdata = obj.hobj.simOut;
        end
    end
end

