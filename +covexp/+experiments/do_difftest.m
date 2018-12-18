function ret = do_difftest(sys,~, ret)
%DO_DIFFTEST Summary of this function goes here
%   Detailed explanation goes here

l = logging.getLogger('do_difftest');

if covcfg.EXP6_USE_PRE_PROCESSED
    if ret.peprocess_skipped || ret.preprocess_error
        l.info('Skipping difftest of %s since preprocessed skipped/errored', sys);
        return;
    end
    
    sys = emi.slsf.get_pp_file(sys, ret.loc_input);
    
    h = load_system(sys); %#ok<NASGU>
end

difftest_exception = [];

try
    
    dt = difftest.BaseTester({sys}, {ret.loc_input}, covcfg.EXP6_CONFIGS);
    dt.go();
    ret.difftest = dt.r;
catch e
    difftest_exception = e;
end

% clean up

if covcfg.EXP6_USE_PRE_PROCESSED
    bdclose(sys);
end

% Throw any unexpected exception

if ~ isempty(difftest_exception)
    throw(difftest_exception);
end

end

