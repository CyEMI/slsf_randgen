function [ covdata ] = get_single_model_coverage( sys, model_id, model_path, cur_exp_dir )
%GET_SINGLE_MODEL_COVERAGE Gets coverage and other information for a model
%   Potentially to be called from a parfor loop

    if covcfg.USE_MODEL_PATH_AS_CACHE_LOCATION
        assert(~isempty(model_path), 'Model path can not be empty if using model location as cache directory');
        report_loc = [model_path filesep sys '__covdata'];
    else
        report_loc = [covcfg.CACHE_DIR filesep num2str(model_id)];
    end

    do_append = false;
    
    if covcfg.USE_CACHED_RESULTS
        try
            covdata = load(report_loc);
            do_append = true;
            if ~ covcfg.FORCE_UPDATE_CACHED_RESULT
                return;
            end
        catch
        end
    end
    
    if ~isempty(model_path)
        addpath(model_path);
    end
    
    cur_datetime = datestr(now, covcfg.DATETIME_DATE_TO_STR);
    touch_loc = [cur_exp_dir filesep covcfg.TOUCHED_MODELS_DIR...
        filesep cur_datetime '___' num2str(model_id) '.txt'];
    
    dummy = 'a'; %#ok<NASGU>
    save(touch_loc, 'dummy');
    
    [covdata, h] = covexp.check_model_opens(sys, model_id, model_path);
    
    if ~ covdata.skipped && covdata.opens
        for i = 1:numel(covcfg.DO_THESE_EXPERIMENTS)
            cur_experi = covcfg.EXPERIMENTS{covcfg.DO_THESE_EXPERIMENTS(i)};
            covdata = cur_experi(sys, h, covdata);
        end
    end
    
    if do_append
        save(report_loc, '-append', '-struct', 'covdata');
    else
        save(report_loc, '-struct', 'covdata');
    end
    
    % Delete the touched file
    delete(touch_loc);
    
    if ~isempty(model_path)
        rmpath(model_path);
    end
end

