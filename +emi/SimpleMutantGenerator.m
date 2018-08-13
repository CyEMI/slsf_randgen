classdef SimpleMutantGenerator < emi.BaseMutantGenerator
    %SIMPLEMUTANTGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = SimpleMutantGenerator(varargin)
            obj = obj@emi.BaseMutantGenerator(varargin{:});
        end
        
        function implement_mutation(obj)
            obj.strategy_dead_block_removal();
        end
    end
    
end

