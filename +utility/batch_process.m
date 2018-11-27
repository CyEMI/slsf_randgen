function [ ret ] = batch_process( report_dir, variable_name, filename_filters, data_filter, varargin)
%BATCH_PROCESS Explores `report_dir` using utility.dir_process
%   Loads a single variable `variable_name` from each of the files.
% Applies data_filter to the loaded variable.
% Returns concatenated result

filename_suffix = '*.mat';
explore_subdirs = false;
uniform_output = false;

if nargin >= 5
    filename_suffix = varargin{1};
end

if nargin >= 6
    explore_subdirs = varargin{2};
end

if nargin >= 7
    uniform_output = varargin{3};
end

function load_result = load_from_each_file(cur_file, cur_dir)
    load_result = load([cur_dir filesep cur_file]);
    load_result = load_result.(variable_name);
    
    if ~ isempty(data_filter)
        load_result = data_filter(load_result);
    end
end

files = utility.dir_process(report_dir, filename_suffix, explore_subdirs, filename_filters);

ret = cellfun(@load_from_each_file, files(:, 1), files(:,2), 'UniformOutput', uniform_output);

end


