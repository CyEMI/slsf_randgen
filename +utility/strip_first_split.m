function [ ret ] = strip_first_split( p, split_arg, join_str )
%STRIP_LAST_SPLIT To remove first element from `p`
%   Detailed explanation goes here
ret = strsplit(p, split_arg);
ret = strjoin(ret(2:end), join_str);

end

