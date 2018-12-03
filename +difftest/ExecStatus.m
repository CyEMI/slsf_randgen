classdef ExecStatus < uint32
    %EXECSTATUS Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Idle        (0)      % Inception
        Load        (10)           % model loaded successfully
        PreExec     (20)  
        Exec        (30)
        Done        (100)
    end
end

