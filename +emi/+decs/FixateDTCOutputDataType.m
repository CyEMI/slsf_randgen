classdef FixateDTCOutputDataType < emi.decs.DecoratedMutator
    %FIXATEDTCOUTPUTDATATYPE Fix output data-type of existing DTC blocks
    % The original model's Data-Type Converter (DTC) blocks may get new 
    % output data-type in a mutant and hence change model semantics (e.g.
    % uints becoming doubles). Prevent such type inference
    
    methods
        function preprocess_phase(obj)
            
            function ret = helper(blk)
                % blk is a DTC block
                ret = true;
                
                full_blk = [obj.mutant.sys '/' blk];
                
                out_type = obj.mutant.compiled_types(blk).Outport{1}; 
                
                obj.mutant.set_param(full_blk, 'OutDataTypeStr',...
                    emi.slsf.get_datatype(out_type));
            end
            
            cellfun(@helper,obj.mutant.blocks{strcmp(...
                obj.mutant.blocks.blocktype, 'DataTypeConversion'), 1});
        end
    end
end

