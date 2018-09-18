function ret = pause_for_ss(ss)
%PAUSE_FOR_SS pause for subsystem `ss`
ret = isfield(emi.cfg.DEBUG_SUBSYSTEM, utility.strip_root_sys(ss));
end

