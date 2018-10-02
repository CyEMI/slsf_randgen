function ret = preprocess_models(~, ~, ret)
%PREPROCESS_MODELS Preprocess a model for creating mutants
%   Detailed explanation goes here
ret.preprocess_error = false; % If a model is skipped, it is not error
ret.preprocess_exp = [];
ret.peprocess_skipped = true;

if ~ ret.compiles || ret.exception || ret.numzerocov == 0 
    return;
end

ret.peprocess_skipped = false;

model_data = struct2table(ret, 'AsArray', true);

mutator = emi.ModelPreprocessor(model_data);

mutator.go();

mutant_res = mutator.result.mutants{1};

ret.preprocess_error = mutant_res.preprocess_error;
ret.preprocess_exp = mutant_res.exception_ob;

end

