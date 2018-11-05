function models = model_list_filter(models)
%MODEL_LIST_FILTER 
models = models(rowfun(@(e, z, c, pp)...
    ~e && ~pp && c &&...        % No exception, compiles, ~preprocess_error
    ~isempty(z) && z{1}>0,...   % num_zero_cov > 0
    models(:, {'exception', 'numzerocov', 'compiles', 'preprocess_error'}),...
    'OutputFormat', 'uniform'), :);
end

