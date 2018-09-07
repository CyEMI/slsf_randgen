function [ret, h] = check_model_opens(sys, model_id, model_path)
%CHECK_MODEL_OPENS Summary of this function goes here
%   Detailed explanation goes here

% ret contains result for a single model
ret = struct;

ret.m_id = model_id;
ret.sys = sys;
ret.loc_input = model_path;

ret.skipped = false;
ret.opens = false;

if isfield(covcfg.SKIP_LIST, sprintf('x%d', model_id))
    ret.skipped = true;
    return;
end

% Does it open?

try
    h = load_system(sys);
    if covcfg.OPEN_MODELS
        open_system(sys);
    end
    ret.opens = true;
catch
%     ret.exception = true;
%     ret.exception_msg = e.identifier;
%     getReport(e)
end

end

