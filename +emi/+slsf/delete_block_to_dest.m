function delete_block_to_dest(parent,block,destinations,is_if_block)
% Delete block -> destination connections

rowfun(@(a,b,c) emi.slsf.delete_connection(parent, block, a, get_param(b, 'Name'), c + 1, is_if_block),...
    destinations, 'ExtractCellContents', true, 'ErrorHandler', @utility.rowfun_eh);
end

