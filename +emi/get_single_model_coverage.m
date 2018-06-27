function [ covdata ] = get_single_model_coverage( sys )
%GET_SINGLE_MODEL_COVERAGE Summary of this function goes here
%   Detailed explanation goes here
    covdata = get_coverage(sys);
            

end

function ret = get_coverage(sys)
    ret = struct('opens', false, 'exception', false, 'exception_msg', [],...
        'blocks', [], 'numzerocov', []);

    num_zero_cov = 0; % blocks with zero coverage

    try
        h = load_system(sys);
        if covcfg.OPEN_MODELS
            open_system(sys);
        end
        ret.opens = true;
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        getReport(e)
        return;
    end

    try
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
        end

        ret.blocks = all_blocks;
        ret.numzerocov = num_zero_cov;
        
        % Close
        if covcfg.CLOSE_MODELS
            close_system(sys);
        end
    catch e
        ret.exception = true;
        ret.exception_msg = e.identifier;
        getReport(e)
    end

end

function ret = get_all_blocks(sys)
    ret = find_system(sys, 'LookUnderMasks', 'all');
%     ret = find_system(sys, 'LookUnderMasks', 'all', 'Variants', 'AllVariants');    
end