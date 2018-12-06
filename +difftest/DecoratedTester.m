classdef DecoratedTester < handle
    %DECORATEDTESTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tester;
    end
    
    methods
        function obj = DecoratedTester(tester)
            obj.tester = tester;
        end
        
        function go(obj, varargin)
            obj.tester.go(varargin{:});
        end
        
        function run_comparison(obj, varargin)
            obj.tester.run_comparison(varargin{:});
        end
        
    end
end

