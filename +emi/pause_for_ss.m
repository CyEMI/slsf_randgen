function ret = pause_for_ss(ss)
%PAUSE_FOR_SS pause for subsystem `ss`
ret = emi.cfg.DEBUG_SUBSYSTEM.isKey(utility.strip_root_sys(ss));
end

