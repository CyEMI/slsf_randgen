function ret = filename_suffix_filter( p, unexpected_suffix)
%FILENAME_SUFFIX_FILTER filter OUT by a suffix BEFORE the extension
%   Detailed explanation goes here

without_ext = utility.strip_last_split(p, '.');

ret = numel(strsplit(without_ext, ['_' unexpected_suffix])) == 1;

end

