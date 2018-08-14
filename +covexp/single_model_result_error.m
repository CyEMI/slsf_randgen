function [ ret ] = single_model_result_error( sys, model_id, model_path, cur_exp_dir )
%SINGLE_MODEL_RESULT_ERROR delete cached result and try again.
%   Detailed explanation goes here

ret = covexp.get_report_datatype();

ret.m_id = model_id;
ret.sys = sys;

if covcfg.USE_CACHED_RESULTS
    report_loc = [covcfg.CACHE_DIR filesep num2str(model_id)];
    delete(report_loc);
    try
        ret = covexp.get_single_model_coverage(sys, model_id, model_path, cur_exp_dir);
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        ret.exception_ob = e;
    end
end

end

