function models = do_difftest(models, l)
%DO_DIFFTEST Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(models, 'difftest')
    return;
end

data = {models.difftest};

skipped = ones(numel(data), 1);
is_exception = zeros(numel(data), 1);


for i=1:numel(data)
    
    cur = data{i};
    
    if ~isempty(cur)
       skipped(i) = false;
       is_exception(i) = ~ cur.is_ok();
    end
    
end

l.info('DIFFtest: Skipped?');
tabulate(skipped);


l.info('DIFFtest: Errored?');
tabulate(is_exception);

end

