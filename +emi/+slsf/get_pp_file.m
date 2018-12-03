function preprocessed_file_name = get_pp_file(sys, loc_input)
%GET_PP_FILE Summary of this function goes here
%   Detailed explanation goes here

preprocessed_file_name = sprintf('%s_%s', sys, emi.cfg.MUTANT_PREPROCESSED_FILE_SUFFIX);
            
if ~ utility.file_exists(loc_input, [preprocessed_file_name '.' emi.slsf.get_extension(sys)])
    error('Preprocessed version %s not found!', preprocessed_file_name);
end

end

