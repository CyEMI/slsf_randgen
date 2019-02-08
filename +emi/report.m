function [emi_result, stats_table] = report(report_loc, aggregate)
% Aggregates all reports in `report_loc` directory. 
% If aggregate is missing then aggregates individual cache results to a 
% file. Otherwise uses it or loades from disc if empty.

    l = logging.getLogger('emi_report');
    
    if nargin == 0 && ~isempty(report_loc)
        report_loc = utility.get_latest_directory(emi.cfg.REPORTS_DIR);
        
        if isempty(report_loc)
            l.warn('Nothing found in %s', emi.cfg.REPORTS_DIR);
            return;
        end
        l.info('Collected report from "latest" directory: %s', report_loc);
    end

    if nargin < 2 % Run aggregation
        emi_result = utility.batch_process(report_loc, 'modelreport',... % variable name and file name should be 'modelreport'
            {{@(p) strcmp(p, 'modelreport.mat')}}, @process_data, '', true, true); % explore subdirs; uniform output
        emi_result = struct2table(emi_result);
    elseif isempty(aggregate) % Use provided aggregated or load from disc
        l.info('Loading aggregated result from disc...');
        readdata = load(emi.cfg.RESULT_FILE);
        emi_result = readdata.emi_result;
    else
        emi_result = aggregate;
    end
    
    utility.tabulate('is_ok', emi_result, 'No Exception and mutant error?', l);
    
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
    
    covexp.experiments.reports.do_difftest(emi_result, l);
end

function ret = process_data(data)
    % change data during loading individuals
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
    ret.durations = cellfun(@(m)m.duration, data.mutants); % Mutant gen time
    ret.compile_dur = cellfun(@(m)m.duration, data.compile_duration); % Mutant compile time
end


function [mutants, varargout] = multi_stats(m, varargin)
    % May not work when inputs are not numeric arrays
    mutants = sum(m);  
    varargout = cellfun(@mean, varargin, 'UniformOutput', false);
end

function [stats_table] = get_stats(ret)

    cmpl_d = cellfun(@(p)p.compile_duration,ret.mutants);
    
    if ismember('difftest_r', ret.Properties.VariableNames)
        diff_d = cellfun(@(p)utility.na(p, @(q)q.total_duration),...
            ret.difftest_r);
    else
        diff_d = zeros(length(ret), 1);
    end

    % Group by seed model ids
    [G, m_id] = findgroups(ret.m_id);
    [r0, r1, r2, r3, r4] = splitapply(@multi_stats,...
        ret.num_mutants, ret.n_mut_ops, ret.durations, cmpl_d, diff_d,...
        G);
    
    stats_table = table(m_id, r0, r1, r2, r3, r4, 'VariableNames',...
        {'m_id', 'count_mutants', 'avg_mut_ops', 'avg_mut_dur',...
        'avg_compile_dur', 'avg_difftest_dur'});
end