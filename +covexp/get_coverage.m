function ret = get_coverage(sys, h, ret)
    l = logging.getLogger('singlemodel');
    ret = covexp.get_cov_reporttype(ret);

    num_zero_cov = 0; % blocks with zero coverage
    
    ret.stoptime_changed = handle_stoptime(sys, l);
    ret.loc = get_model_loc(sys);
    % Does it run within timeout limit?
    
    try
        time_start = tic;
        
        simob = utility.TimedSim(sys, covcfg.SIMULATION_TIMEOUT, l);
        ret.timedout = simob.start();

        if ret.timedout
            % Close
            covexp.sys_close(sys);
            return;
        end
        
        ret.simdur = toc(time_start);
        
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        ret.exception_ob = e;
     
%         getReport(e)
        
        % Close
        covexp.sys_close(sys);
    end
    
    
    % Now collect coverage!
    
    try
        time_start = tic;
        
        testObj  = cvtest(h);
        data = cvsim(testObj);

        blocks = get_all_blocks(h);

        all_blocks = struct;

        for i=1:numel(blocks)
            cur_blk = blocks(i);

            cur_blk_name = getfullname(cur_blk);

            cov = executioninfo(data, cur_blk);
            percent_cov = [];

            if ~ isempty(cov)
                percent_cov = 100 * cov(1) / cov(2);

                if percent_cov == 0
                    num_zero_cov = num_zero_cov + 1;
                end
            end


            all_blocks(i).fullname = cur_blk_name;
            all_blocks(i).percentcov = percent_cov;
            
            try
                all_blocks(i).blocktype = get_param(cur_blk, 'blocktype');
            catch
                all_blocks(i).blocktype = [];
            end
        end
        
        ret.duration = toc(time_start);

        ret.blocks = all_blocks;
        ret.numzerocov = num_zero_cov;
        
        % Close
        covexp.sys_close(sys);
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        ret.exception_ob = e;
        
        getReport(e)
        
        % Close
        covexp.sys_close(sys);
    end

end

function ret = get_model_loc(sys)
    sys_loc = strsplit(get_param(sys, 'FileName'), filesep);
    corpus_loc = strsplit(covcfg.CORPUS_HOME, filesep);
    
    ret = sys_loc(numel(corpus_loc) + 1: end);
end

function ret = get_all_blocks(sys)
    ret = find_system(sys, 'LookUnderMasks', 'all');
%     ret = find_system(sys, 'LookUnderMasks', 'all', 'Variants', 'AllVariants');    
end

function new_st =  handle_stoptime(sys, l)
    new_st = [];
    current_st = get_param(sys, 'StopTime');
    try
        current_st = eval(current_st);
        if ~isfinite(current_st)
            l.info('StopTime will be changed');
            new_st = int2str(covcfg.SIMULATION_TIMEOUT * 2); % heuristic
            set_param(sys, 'StopTime', new_st);
        end
    catch e
        try
            getError(e)
        catch
            e %#ok<NOPRT>
        end
    end
end
