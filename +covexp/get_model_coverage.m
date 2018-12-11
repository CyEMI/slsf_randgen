function [all_blocks, num_zero_cov] = get_model_coverage(h, reduce_blocks)
%GET_MODEL_COVERAGE Summary of this function goes here
%   Detailed explanation goes here

if nargin == 1
    reduce_blocks = false;
end

num_zero_cov = 0; % blocks with zero coverage

testObj  = cvtest(h);

if reduce_blocks
    warning('Setting CovForceBlockReductionOff=off')
    data = cvsim(testObj, 'CovForceBlockReductionOff', 'off');
else
    % Note: this just disables the force-off. Behavior will now depend on
    % the model's 'BlockReduction' parameter. What if is is set to 'off'?
    % Default is 'on'
    data = cvsim(testObj);
end

blocks = covexp.get_all_blocks(h);

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


end

