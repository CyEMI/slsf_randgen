function ret = na(p, fun, default_val)
%NA Returns `default_val` if `fun` - a lambda with one arg `p` throws
%   Else returns the lambda's return value.
% Useful when running cellfun where some data are missing
% E.g. cellfun(@(p)utility.na(p, @(q)q.total_duration), data) will return 0
% where the lambda will throw.

try
    ret = fun(p);
catch
    if nargin < 3
        default_val = 0;
    end
    
    ret = default_val;
end
end

