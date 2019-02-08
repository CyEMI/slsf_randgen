function ret = rt()
%RT Returns duration (hours) of running the covexp.covcollect experiments
%   How many CPU hours were spent for the EMI phases up to actual EMI
%   generation.


% compute from coverage experiments

ret = 0;

% Legacy covexp

legacy = sum(utility.batch_process(covcfg.RESULT_DIR_COVEXP, 'covexp_result',... % variable name
        [], @process_legacy, '*.mat', false, true)); %  subdirs; uniform output
ret = ret + legacy;

% Recent covexp

recent = sum( utility.batch_process(covcfg.RESULT_DIR_COVEXP, 'covexp_result',... 
        {{@(p) utility.starts_with(p, 'covexp_result')}}, @process_legacy, '', true, true) ); %  filename starts with covexp_result
    
ret = ret + recent;

% EMI exps



ret = ret / 3600; 

end

function ret = process_legacy(data)
    ret = 0;
    % Following experiments were not related to EMI
    ignore_mdl_count = 60;
    
    if ~ isfield(data, 'models') || ~isfield(data, 'total_duration')...
            || isempty(data.total_duration)
        return
    end
    
    m = data.models;
    
    if isempty(m) || length(m) > ignore_mdl_count || ~ isfield(m, 'sys')
        return ; 
    end
    
    if ~ utility.starts_with(m(1).sys, 'sampleModel')
        return
    end
    
    ret = data.total_duration;
    
end
