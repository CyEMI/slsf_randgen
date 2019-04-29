function p = c(p)
%C Makes `p` a cell if it is not.
%   Detailed explanation goes here

if ~iscell(p)
    p = {p};
end

end

