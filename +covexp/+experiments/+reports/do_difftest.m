function [models, cmp_e_dts] = do_difftest(models, l)
%DO_DIFFTEST Report generator for difftest experiments
%   This function is automatically called by covexp.report

l.info('--- Differential Testing (DIFFTEST) Report ---');
cmp_e_dts = [];

if isstruct(models) % struct array from covexp.report
    if ~isfield(models, 'difftest')
        l.warn('No difftest result available!');
        return;
    end
    data = {models.difftest};
else % table from emi.report
    if ~ ismember('difftest_r', models.Properties.VariableNames)
        l.warn('No difftest result available!');
        return;
    end
    data = models.difftest_r;
end

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

if sum(is_comp_e) ~= 0
    l.info('Following comps (indices, not experiment numbers) errored');
    disp(find(is_comp_e)');
    
    l.info('First exception message for each errored experiment:');
    l.info('The exception objects are also returned!');
    cmp_e_dts = models{find(is_comp_e), 'difftest_r'}; %#ok<FNDSB>
    msgs = cellfun(@difftest.comp_invest, cmp_e_dts, 'UniformOutput', false);
    l.error('%s', strjoin(cellfun(@(p)p.identifier, msgs, 'UniformOutput', false), '\n'));
end

% Strip out empty data

data = data(~ cellfun(@isempty, data));

rt(data, l);

end


function rt(difftest_data, l)
    rts = cellfun(@(p)p.total_duration,  difftest_data);
    l.info('DIFFTEST total runtime: %f hours', sum(rts)/3600 );
    
end
