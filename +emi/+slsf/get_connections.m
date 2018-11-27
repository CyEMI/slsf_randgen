function [connections,sources,destinations] = get_connections(block, get_src, get_dest)
%GET_SOURCE_DESTINATIONS Summary of this function goes here
% `sources` are those blocks, which are connected to `block`'s input ports
% (except the Action port when `block` is Action-Subsystem) `destinations`
% are those which are connected to `block`'s output ports. NOTE: SOME
% DESTINATIONS MAY HAVE MULTIPLE TARGETS, SO HANDLE PROPERLY! See
% 'PortConnectivity' in
% https://www.mathworks.com/help/simulink/slref/common-block-parameters.html

try
    connections = struct2table(get_param(block, 'PortConnectivity'),'AsArray', true);
catch e
    % the block was not found. Was it already deleted?
    disp(e.identifier);
    error('the block %s was not found. Was it already deleted?', block);
end

sources = [];
destinations = [];

if get_src
    sources = connections(rowfun(@(q, p) ~isempty(p) && ~strcmpi(q, 'ifaction'),...
        connections(:,{'Type', 'SrcPort'}), 'OutputFormat', 'uniform',...
        'ExtractCellContents', true), {'Type','SrcBlock', 'SrcPort'});
end

if get_dest
    destinations = connections(cellfun(@(p) ~isempty(p), connections{:, 'DstPort'}), {'Type','DstBlock', 'DstPort'});
end


end
