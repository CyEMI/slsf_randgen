function [ ret ] = date_filter(p, other_args )
%DATE_FILTER Summary of this function goes here
%   TODO write tests

[date_from, datetime_format, split_char] = other_args{:};

if ~isempty(split_char)
    p = strsplit(p, split_char);
    p = p{1};
end

p = datetime(p,'InputFormat',datetime_format);

date_from = datetime(date_from,'InputFormat', datetime_format);

ret = p >= date_from;

end

