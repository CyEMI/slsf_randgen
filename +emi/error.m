function error( err_msg, l )
%FATAL log the error and end script.
%   Detailed explanation goes here
l.critical(err_msg);
error('FATAL ERROR!');
end

