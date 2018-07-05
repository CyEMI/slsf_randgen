function [ ret ] = filter_struct( S, field_to_group, field_to_return, group_to_return )
%FILTER_STRUCT Retrive values of field `field_to_return` from struct array `S`
%   Output is returned in a cell
%   Filter logic: S.field_to_group == group_to_return
%   Actually , `group_comparison_fun` is used based on data type of
%   `group_to_return`, which can be character vector or boolean (tested).
%   However, any type supporting == should work, though not tested.
%   As an example, see the Struct_filterTest test case.

if ischar(group_to_return)
    group_comparison_fun = @strcmp; % fun used to find the desired group index
    group_cols = {S.(field_to_group)};
else
    group_comparison_fun = @(p, q) p==q;
    group_cols = [S.(field_to_group)];
end

[groups, unique_group_names] = findgroups(group_cols);

split_results = splitapply(@(arg){arg}, {S.(field_to_return)}, groups);

desired_group_index = find(group_comparison_fun(unique_group_names, group_to_return));

ret = split_results{desired_group_index}; %#ok<FNDSB>

end

