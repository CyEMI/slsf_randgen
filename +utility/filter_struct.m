function [ ret ] = filter_struct( S, field_to_group, field_to_return, group_to_return )
%FILTER_STRUCT Retrive values of field `field_to_return` from struct array `S`
%   Output is returned in a cell
%   Filter logic: S.field_to_group == group_to_return

group_cols = {S.(field_to_group)};

[groups, unique_group_names] = findgroups(group_cols);

split_results = splitapply(@(arg){arg}, {S.(field_to_return)}, groups);

desired_group_index = find(strcmp(unique_group_names, group_to_return));

ret = split_results{desired_group_index}; %#ok<FNDSB>

end

