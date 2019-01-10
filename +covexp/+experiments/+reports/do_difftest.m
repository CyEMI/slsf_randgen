function models = do_difftest(models, l)
%DO_DIFFTEST Report generator for difftest experiments
%   This function is automatically called by covexp.report

if ~isfield(models, 'difftest')
    return;
end

data = {models.difftest};

n_data = numel(data);

skipped = ones(n_data, 1);
is_exception = zeros(n_data, 1); % executor ran only, no comparison
is_comp_e = zeros(n_data, 1); % Comparsion errors
% ok_phases = zeros(numel(data), 1);

for i=1:numel(data)
    
    cur = data{i};
    
    if ~isempty(cur)
       skipped(i) = false;
       is_exception(i) = ~ cur.is_ok;
       
       if ~ isempty(cur.is_comp_ok)
        is_comp_e(i) = ~ cur.is_comp_ok;
       end
       
       % cur.exc_last_ok is now a cell, following won't make sense
%        ok_phases(i) = uint32(cur.exc_last_ok);
       
       
    end
    
end

l.info('DIFFtest: Skipped?');
tabulate(skipped);


l.info('DIFFTEST (Before comp): Errored?');
tabulate(is_exception);

% l.info('DIFFtest: completed phases (Non-Done only; not-skipped only)');
% ok_phases = ok_phases(skipped == false);
% tabulate(ok_phases(ok_phases ~= uint32(difftest.ExecStatus.Done)));


l.info('DIFFTEST (After comp): Errored?');
tabulate(is_comp_e);

end

