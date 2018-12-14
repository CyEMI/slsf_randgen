classdef TypeAnnotateEveryBlock < emi.decs.DecoratedMutator
    %TYPEANNOTATEEVERYBLOCK Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function preprocess_phase(obj) 
            %% Insert DTC before all blocks all input ports
            target_blocks = obj.mutant.blocks{2:end,1}; % First one is the model itself?
            
            function ret = helper(blkname)
                blkname = [obj.mutant.sys '/' blkname];
                
                [~,sources,~] = emi.slsf.get_connections(blkname, true, false);
                
                self_as_destination = emi.slsf.create_port_connectivity_data(blkname, size(sources, 1), 0);
                ret = obj.mutant.add_DTC_before_block(blkname, sources, self_as_destination);
            end
            
            cellfun(@helper,target_blocks);
        end
    end
end

