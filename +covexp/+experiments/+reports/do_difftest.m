function models = do_difftest(models, l)
%DO_DIFFTEST Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(models, 'difftest')
    return;
end

data = {models.difftest};

skipped = ones(numel(data), 1);
is_exception = zeros(numel(data), 1);
ok_phases = zeros(numel(data), 1);

error_shortnames = utility.cell();

for i=1:numel(data)
    
    cur = data{i};
    
    if ~isempty(cur)
       skipped(i) = false;
       is_exception(i) = ~ cur.is_ok;
       ok_phases(i) = uint32(cur.exc_last_ok);
       
       if ~ cur.is_ok
           error_shortnames.add(cur.exc_shortname);
       end
       
    end
    
end

l.info('DIFFtest: Skipped?');
tabulate(skipped);


l.info('DIFFtest: Errored?');
tabulate(is_exception);

l.info('DIFFtest: completed phases (Non-Done only; not-skipped only)');
ok_phases = ok_phases(skipped == false);
tabulate(ok_phases(ok_phases ~= uint32(difftest.ExecStatus.Done)));

if error_shortnames.len > 0
    l.info('Following SUT configs caused errors:');
    disp(error_shortnames.get_cell_T());
end

end

