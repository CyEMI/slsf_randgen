classdef AddVirtualChild < emi.livedecs.Decorator
    %DECWRAPINCHILDMODEL Adds a new virtual subsystem at the same position
    %of the block to be mutated
    %   Detailed explanation goes here
    
    properties
        child_type = 'simulink/Ports & Subsystems/Subsystem';
    end
    
    methods
        function obj = AddVirtualChild(varargin)
            %DECWRAPINCHILDMODEL Construct an instance of this class
            obj = obj@emi.livedecs.Decorator(varargin{:});
        end
        
        function go(obj )
            prev_pos = get_param(obj.hobj.blk_full, 'Position');
            
            [obj.hobj.new_ss, obj.hobj.new_ss_h] = obj.mutant.add_new_block_in_model(...
                obj.hobj.parent, 'simulink/Ports & Subsystems/Subsystem',...
                struct('Position', prev_pos));
            
            % New subsystem is created with some input-output ports. Delete
            % these.
            Simulink.SubSystem.deleteContents(obj.hobj.new_ss_h);
        end
    end
end

