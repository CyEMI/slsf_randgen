function [ ret ] = batch_process( report_dir, variable_name, filename_filters, data_filter )
%BATCH_PROCESS Summary of this function goes here
%   Detailed explanation goes here

function load_result = load_from_each_file(cur_file)
    load_result = load([report_dir filesep cur_file]);
    load_result = load_result.(variable_name);
    
    if ~ isempty(data_filter)
        load_result = data_filter(load_result);
    end
end

files = dir([report_dir filesep '*.mat' ]);

files = {files.name};

files = files(cellfun(@(x)all(cellfun(@(p)p{1}(x, p(2:end)), filename_filters)), files));

ret = cellfun(@load_from_each_file, files, 'UniformOutput', false);

end


