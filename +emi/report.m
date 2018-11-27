function ret = report(report_loc)
% Aggregates all reports in `report_loc` directory

    l = logging.getLogger('emi_report');

    ret = utility.batch_process(report_loc, 'modelreport',... % variable name and file name should be 'modelreport'
        {{@(p,~) strcmp(p, 'modelreport.mat'),{}}}, @process_data, '', true, true); % explore subdirs; uniform output
    
%     utility.tabulate('exception', ret, 'Exception?', l);
    utility.tabulate('is_ok', ret, 'Exception OR mutant Compilation error?', l);
end

function ret = process_data(data)
    ret = data;
    ret.is_ok = isempty(data.exception) && all(...
        cellfun(@(p)p.is_ok(), data.mutants));
end