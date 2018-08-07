function open_or_load_model( sys )
%OPEN_OR_LOAD_MODEL Summary of this function goes here
%   Detailed explanation goes here
if emi.cfg.INTERACTIVE_MODE
    open_system(sys);
else
    load_system(sys);
end

end

