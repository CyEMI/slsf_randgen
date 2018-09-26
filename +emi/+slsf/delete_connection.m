function ret = delete_connection(sys, s_b, s_p, d_b, d_p, is_if)
%% Delete a connection
% % Delete existing lines

if ~ iscell(d_b)
    d_b = {d_b};
end

for i=1:numel(d_b)
    if is_if
        dest_port = 'ifaction';
    else
        dest_port = int2str(d_p(i));
    end
    
    try
        delete_line(sys, [s_b '/' s_p], [d_b{i} '/' dest_port]);
    catch err
        disp(err.identifier);
        error('Unexpected: Error deleting line');
    end
end

ret = true;

end