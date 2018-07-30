function [ ret ] = batch_process( report_dir, variable_name, filename_filters, data_filter )
%BATCH_PROCESS Explores `report_dir`
%   Detailed explanation goes here

function load_result = load_from_each_file(cur_file)
    load_result = load([report_dir filesep cur_file]);
    load_result = load_result.(variable_name);
    
    if ~ isempty(data_filter)
        load_result = data_filter(load_result);
    end
end

files = utility.dir_process(report_dir, '*.mat', false, filename_filters);

ret = cellfun(@load_from_each_file, files(:, 1), 'UniformOutput', false);

end


