classdef ExtraBlock < emi.livedecs.Decorator
    % Appends a new block for each `inp`

    
    properties
        block_type = sprintf('simulink/Math\nOperations/Unary Minus');
        
    end
    
    methods
        function obj = ExtraBlock(varargin)
            %DECWRAPINCHILDMODEL Construct an instance of this class
            obj = obj@emi.livedecs.Decorator(varargin{:});
        end
        
        function ret = is_compat(obj, varargin)
            % Skip mutation if types are not supported
            % Currently prevents unsinged int types as not supported by the
            % unary minus block. 
            ret = ~any(...
                startsWith(...
                    obj.mutant.get_compiled(obj.hobj.blk_full, 'datatype').Inport,...
                    {'ufix', 'uint'} ... % pattern
                ) ...
            );
        end
        
        function go(obj, varargin )
            function ret = add_a_blk(inp_blk_prt)                                
                [n_b, ~] = obj.mutant.add_new_block_in_model(obj.hobj.parent, obj.block_type);
                
                % Add Connections
                try
                    for i = 1: size(inp_blk_prt, 1) % These many input ports
                        obj.mutant.add_conn(...
                            obj.hobj.parent,...
                            inp_blk_prt{i, 1},...
                            inp_blk_prt{i, 2}+1,...
                            n_b, 1 ...
                        );
                    end
                catch e
                    rethrow(e);
                end
                
                % TODO add new block in compiled registry if needed. If
                % multiple inputs, how to decide?
                
                % Since using vertcat, all of the inp blk-port would
                % remain. May need to adjust this if new change arrives in
                % the future, e.g. by config param
                ret = vertcat(inp_blk_prt, {n_b, 0}); % 1 would be added in port number
            end
            
            obj.hobj.inps = cellfun(@add_a_blk, obj.hobj.inps, 'UniformOutput', false );
        end
    end
end

