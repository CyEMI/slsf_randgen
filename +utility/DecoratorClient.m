classdef DecoratorClient < handle
    %DECORATORCONTAINER This class uses decorators i.e. subclasses of
    %utility.AbstractDecorator.
    % WARNING make sure to call create_decorators!
    
    properties
        decorators = [];
    end
    
    methods
        function obj = DecoratorClient(decorators)
            %DECORATORCONTAINER Construct an instance of this class
            assert(iscell(decorators));
            obj.decorators = decorators;
        end
        
        function create_decorators(obj)
            %%
            obj.decorators = cellfun(@(p)p(obj), obj.decorators);
            % obj.decorators is now a matrix
        end
        
        function call_fun(obj, fun, varargin)
            %%
            for i=1:numel(obj.decorators)
                dec = obj.decorators(i);
                fun(dec, varargin{:});
            end
        end
        
        function delete(obj)
            %% Destructor. Address cyclic dependencies
            try
                for i=1:numel(obj.decorators)
                    try
                        dec = obj.decorators(i);
                        dec.hobj = [];
                    catch
                    end
                end
                obj.decorators = [];
            catch me
                fprintf('Error in destructor of DecoratorClient!\n');
                disp(me);
            end
        end
    end
end

