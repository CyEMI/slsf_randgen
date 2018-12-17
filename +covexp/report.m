function [ ret ] = report( varargin )
%REPORT See reports for covcollect
%   varargin{1}: file to load for report
covexp.addpaths();

ret = [];

l = logging.getLogger('report');

if nargin < 1
    result_file = covcfg.RESULT_FILE;
else
    result_file = [covcfg.RESULT_DIR_COVEXP filesep varargin{1}];
end

clear covexp_result;

load(result_file); %#ok<LOAD>

models = covexp_result.models;

% General stats

utility.tabulate('opens', models, 'Does Model Open?', l);

utility.tabulate('compiles', models, 'Does Model Compile?', l);

% Timeout should now appear as exception. The previously reported boolean
% field should now be meaningless to report.
% utility.tabulate('timedout', models, 'Does Model time-out?', l);

utility.tabulate('exception', models, 'Does Model error?', l);

utility.tabulate('peprocess_skipped', models, 'Preprocess: skipped?', l);
utility.tabulate('preprocess_error', models, 'Preprocess: error?', l);

covexp.experiments.reports.do_difftest(models, l);

% Number of zero blocks

if ~ isfield(models, 'numzerocov')
    return;
end

numzero = [models.numzerocov];

if ~isempty(numzero)
    % Remove the empty cells from `{models.blocks}`
    model_blocks = {models.blocks};
    model_blocks = model_blocks(cellfun(@(p)~isempty(p), model_blocks));

    total_blocks = arrayfun(@(p)numel(p{1}) - 1, model_blocks);
    
    numzero_ratio = arrayfun(@(p,q) p/q*100.0, numzero, total_blocks);
    
    boxplot(numzero_ratio);
    title('Total blocks with no coverage / number of blocks');

else
    l.info('No dead blocks!!!');
end

l.info('Does model has at least one block with no cov?');
haszero = arrayfun(@(p)p>0, numzero);
tabulate(haszero);

end

