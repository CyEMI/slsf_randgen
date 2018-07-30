function [ ret ] = strip_last_split( p, split_arg )
%STRIP_LAST_SPLIT To remove extension from file name `p`
% set `split_arg` = '.' 
%   Detailed explanation goes here
ret = strsplit(p, split_arg);
ret = strjoin(ret(1:end-1), split_arg);

end

