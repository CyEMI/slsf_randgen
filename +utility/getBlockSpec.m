function ret = getBlockSpec(libnames, force_update)
%GETBLOCKSPEC Summary of this function goes here
%   Detailed explanation goes here

load_system('simulink');

sys = 'getBlockSpecSys';

if nargin == 1
    force_update = false;
end

if ~ iscell(libnames)
    libnames = {libnames};
end

new_system(sys);
open_system(sys);

e = [];

try
    ret = get_data(sys, libnames, force_update);
catch e
    utility.print_error(e);
end

bdclose(sys);

if ~ isempty(e)
    rethrow(e);
end

end


function ret = get_data(sys, libnames, force_update)

data_file = 'GetBlockSpecCached';

if ~ force_update
   ret = load(data_file);
   ret = ret.ret;
   return;
end

ret = utility.cell();

for i = 1:numel(libnames)
    libn = libnames{i};
    blocks = utility.getBlocksOfLibrary(libn);

    for j=2:numel(blocks)
        blk = blocks{j};

        try
            h = add_block(blk, [sys '/b' int2str(ret.len)] ,'MakeNameUnique','on');
        catch f
            % Block not allowed in root level
            utility.print_error(f);
            continue;
        end

        % Num out ports
        portHs = get_param(h, 'PortHandles');
        n_outports = numel(portHs.Outport);

        % OutDataTypeStr

        ob_params = get_param(h, 'ObjectParameters');

        is_odts = isfield(ob_params, 'OutDataTypeStr');

        % Block Type
        blktype = get_param(h, 'BlockType');

        ret.extend({libn, blk, blktype, n_outports, is_odts, ob_params});
    end
end

var_names = {'Lib', 'Block', 'BlockType', 'NumOutports', 'OutDataTypeStr', 'Params'};
n_cols = length(var_names);

ret = cell2table(ret.get_cell2D([], n_cols));
ret.Properties.VariableNames = var_names;

fprintf('Caching...\n');
save(data_file, 'ret');

end

