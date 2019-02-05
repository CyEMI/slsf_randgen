function [emi_result, stats_table] = report(report_loc)
% Aggregates all reports in `report_loc` directory

    l = logging.getLogger('emi_report');

    if nargin == 0
        report_loc = utility.get_latest_directory(emi.cfg.REPORTS_DIR);
        
        if isempty(report_loc)
            l.warn('Nothing found in %s', emi.cfg.REPORTS_DIR);
            return;
        end
        
        l.info('Collected report from "latest" directory: %s', report_loc);
    end

    emi_result = utility.batch_process(report_loc, 'modelreport',... % variable name and file name should be 'modelreport'
        {{@(p) strcmp(p, 'modelreport.mat')}}, @process_data, '', true, true); % explore subdirs; uniform output
    
    % Num mutants and duration per experiment
    
%     utility.tabulate('exception', ret, 'Exception?', l);
    utility.tabulate('is_ok', emi_result, 'No Exception and mutant error?', l);
    
    emi_result = struct2table(emi_result);
    
    stats_table = [];
    
    try
        % Only works if creating one mutant per model. Generalize later
        stats_table = get_stats(emi_result);
    catch e
        l.error('Error getting stats!');
        utility.print_error(e);
    end
    
    % Write in disc
    
    save(emi.cfg.RESULT_FILE, 'emi_result', 'stats_table');
end

function ret = process_data(data)
    ret = data;
    ret.is_ok = isempty(data.exception) && all(...
        cellfun(@(p)isempty(p.exception), data.mutants));
    
    ret.num_mutants = 0;
    
    ret.n_mut_ops = [];
    ret.durations = [];
    
    if ~ isempty(data.exception)
        return;
    end
    
    ret.num_mutants = numel(data.mutants);
    ret.n_mut_ops = cellfun(@(m)m.num_mutation, data.mutants);
    ret.durations = cellfun(@(m)m.duration, data.mutants);
end

function [mutants, ops, dur] = multi_stats(m, o, d)
    % May not work when inputs are not numeric arrays
    mutants = sum(m);  
    ops = mean(o);
    dur = mean(d);
end

function [stats_table] = get_stats(ret)
    [G, m_id] = findgroups(ret.m_id);
    [count_mutants, avg_mut_ops, avg_mut_dur] = splitapply(@multi_stats, ret.num_mutants, ret.n_mut_ops, ret.durations, G);
    
    stats_table = table(m_id, count_mutants, avg_mut_ops, avg_mut_dur);
end