function  pause_interactive( )
%PAUSE_INTERACTIVE Summary of this function goes here
%   Detailed explanation goes here

if emi.cfg.INTERACTIVE_MODE
    fprintf('Pausing due to interactive mode...\n');
    pause;
end

end

