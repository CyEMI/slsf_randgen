function [ ret ] = file_extension_filter( p, expected_extensions )
%FILE_EXTENSION_FILTER Returns true if `p`, which is a filename, its
%extension exists in `expected_extensions`
%   Detailed explanation goes here
p_extensions = strsplit(p, '.');
ret = any(strcmpi(p_extensions{end}, expected_extensions));
end

