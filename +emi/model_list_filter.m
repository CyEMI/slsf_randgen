function models = model_list_filter(models)
%MODEL_LIST_FILTER 
models = models(rowfun(@(e, z, c, pp)...
    ~e && ~pp && c &&...        % No exception, compiles, ~preprocess_error
    ~isempty(z) && z>0,...   % num_zero_cov > 0
    models, 'InputVariables', {'exception', 'numzerocov', 'compiles', 'preprocess_error'},...
    'ExtractCellContents', true, 'OutputFormat', 'uniform'), :);
end

