function ret = sampletimes(~, ~, ret)
%SAMPLETIMES Collect sample time stats
%   Assumes you have already collected coverage (Experiment 1)

if ~ isfield(ret, 'blocks')
    return;
%     error('sampletimes experiment depends on coverage collection!');
end

st_param = cellfun(@(p) utility.na(p, @(q)get_param(q, 'SampleTime'), []),...
    {ret.blocks.fullname}, 'UniformOutput', false);

[ret.blocks.st_param] = st_param{:};

end

