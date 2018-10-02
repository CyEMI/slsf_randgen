function [model_result, h] = check_model_opens(sys, model_id, model_path, model_result)
%CHECK_MODEL_OPENS Summary of this function goes here
%   Detailed explanation goes here

model_result.m_id = model_id;
model_result.sys = sys;
model_result.loc_input = model_path;

model_result.skipped = false;
model_result.opens = false;

if isfield(covcfg.SKIP_LIST, sprintf('x%d', model_id))
    model_result.skipped = true;
    return;
end

% Does it open?

try
    h = load_system(sys);
    if covcfg.OPEN_MODELS
        open_system(sys);
    end
    model_result.opens = true;
catch
%     ret.exception = true;
%     ret.exception_msg = e.identifier;
end

end

