function result = file_exists(parent_dir,varargin)
%FILE_EXISTS Summary of this function goes here
%   Detailed explanation goes here

if nargin == 2
    parent_dir = [parent_dir filesep varargin{1}];
end

result = isfile(parent_dir);

end

