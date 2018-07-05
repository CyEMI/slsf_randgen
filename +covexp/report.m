function [ ret ] = report( varargin )
%REPORT See reports for covcollect
%   Detailed explanation goes here
covexp.addpaths();

ret = [];

l = logging.getLogger('report');

result_file = covcfg.RESULT_FILE;

clear covexp_result;

load(result_file);


models = covexp_result.models;

% Number of zero blocks

numzero = [models.numzerocov];

% Remove the empty cells from `{models.blocks}`
model_blocks = {models.blocks};
model_blocks = model_blocks(cellfun(@(p)~isempty(p), model_blocks));

total_blocks = arrayfun(@(p)numel(p{1}) - 1, model_blocks);

numzero_ratio = arrayfun(@(p,q) p/q*100.0, numzero, total_blocks);

boxplot(numzero_ratio);
title('Total blocks with no coverage / number of blocks');

l.info('Does model has at least one block with no cov?');
haszero = arrayfun(@(p)p>0, numzero);
tabulate(haszero);

l.info('Does Model Open?');
tabulate([models.opens]);

l.info('Does Model error?');
tabulate([models.exception]);


end

