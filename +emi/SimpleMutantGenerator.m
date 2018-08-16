classdef SimpleMutantGenerator < emi.BaseMutantGenerator
    %SIMPLEMUTANTGENERATOR Implements a MutantGenerator
    
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
    
    methods(Access = protected)
    end
    
end

