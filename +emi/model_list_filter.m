function models = model_list_filter(models)
%MODEL_LIST_FILTER 
% No exception, num_zero_cov > 0, compiles
models = models(rowfun(@(p, q, c)~p && c && ~isempty(q) &&...
    q{1}>0, models(:, {'exception', 'numzerocov', 'compiles'}),...
    'OutputFormat', 'uniform'), :);
end

