function ret = report(report_loc)
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

    ret = utility.batch_process(report_loc, 'modelreport',... % variable name and file name should be 'modelreport'
        {{@(p,~) strcmp(p, 'modelreport.mat'),{}}}, @process_data, '', true, true); % explore subdirs; uniform output
    
%     utility.tabulate('exception', ret, 'Exception?', l);
    utility.tabulate('is_ok', ret, 'No Exception and mutant error?', l);
end

function ret = process_data(data)
    ret = data;
    ret.is_ok = isempty(data.exception) && all(...
        cellfun(@(p)isempty(p.exception), data.mutants));
end