function delete_src_to_block(parent,block, sources)
% Delete source -> block connections
rowfun(@(a,b,c) emi.slsf.delete_connection(parent, get_param(b, 'Name'),...
    int2str(c + 1), block, str2double(a), false),...
    sources, 'ExtractCellContents', true);

end

