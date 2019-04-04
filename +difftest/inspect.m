function inspect(difftest_ob)
%INSPECT_MODEL Open up models from a difftest object
%   Detailed explanation goes here
l = logging.getLogger('inspect_models');

cellfun(@(p)utility.d(@()open_system([p.loc filesep p.sys '_' difftest.cfg.PRE_EXEC_SUFFIX])),...
    difftest_ob.executions);


l.info('--Comparison Differences--');

c_d_keys = difftest_ob.comp_diffs.keys();
for i=1:numel(c_d_keys)
    k = c_d_keys{i};
    l.info('%s', k);
    disp( difftest_ob.comp_diffs(k));
end

end

