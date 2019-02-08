function [dur_vals] = scaling(result, l)
%SCALING Summary of this function goes here
%   Detailed explanation goes here
if nargin < 2
    l = logging.getLogger('report');
end

if nargin < 1
    result_file = covcfg.RESULT_FILE;
else
    result_file = [covcfg.RESULT_DIR_COVEXP filesep result];
end

result = load(result_file);
result = result.covexp_result;

try
    l.info('--- Scaling Reports ---');
    
    m = struct2table(result.models);
    
    % models without exception
    m_wo_e = m((~m.exception & m.compiles & ~m.peprocess_skipped), : );
        
    emi_r = load(emi.cfg.RESULT_FILE);
    
    emi_stats = emi_r.stats_table;
    
    merged = outerjoin(m_wo_e, emi_stats);
    
    % Turns out a model might not get selected for mutation at lot, the
    % following line raises error in these cases.
%     assert(all(merged.m_id_m_wo_e == merged.m_id_emi_stats));
    
    blks_sz = cellfun(@(p) length(p), merged.blocks);
    
    l.info('block cnt:%d \t avg:\t %f min:%d \t max:%d',...
        numel(blks_sz), mean(blks_sz), min(blks_sz), max(blks_sz));
    
    blks_per_model_label = 'Blocks/Model';
    
    %%% Plot Durations %%%
    
    durations = {'simdur', 'duration', 'compile_dur', 'avg_mut_dur', 'avg_compile_dur', 'avg_difftest_dur'};
    dur_legends = {'Run seed', 'Get Coverage', 'Get DataType', 'Mutant Gen', 'Mutant Compile', 'Diff. Test'};
    
    % merged.duration is a cell, convert it to double
    
    merged.duration = cellfun(@(p)p, merged{:, 'duration'});
    
    utility.plot(blks_sz, merged{:,durations}, dur_legends,...
        blks_per_model_label, 'Runtime (sec)', 'log', 'log');
    
    % Mutation Stats
    
    utility.plot(blks_sz, merged{:, 'avg_mut_ops'}, [],...
        blks_per_model_label, 'Mutations (mean)', 'log', 'log');
    
 
    %%% Others %%%
    
    l.info('Mutant gen + compile + Difftest runtime: %f (avg); %f (max) sec',...
        (mean(merged.avg_mut_dur) + mean(merged.avg_compile_dur) + mean(merged.avg_difftest_dur)),...
        (max(merged.avg_mut_dur) + max(merged.avg_compile_dur) + max(merged.avg_difftest_dur)) );
    
    % Phase Duration Percentage
    
    % Filtering out those did not mutated
    
    blks_sz = cellfun(@(p) length(p), merged{~isnan(merged.m_id_emi_stats), 'blocks'});
    
    dur_vals = merged{~isnan(merged.m_id_emi_stats), durations};
    tot_durs = sum(dur_vals, 2);
    dur_fracs = (dur_vals ./ tot_durs) .* 100;
    
    utility.plot(blks_sz, dur_fracs, [],...
        blks_per_model_label, 'Experiment Duration (%)', 'log');
    
    % max phase
    
    [~, i] = max(dur_vals, [], 2);
    l.info('Which phase took maximum duration?')
    tabulate(i);
    
    [~, i] = min(dur_vals, [], 2);
    l.info('Which phase took minimum duration?')
    tabulate(i);
    
    % Average durations
    i = mean(dur_fracs, 1);
    l.info('Average duration-fractions:');
    disp(i);
    
    l.info('Total duration (sec): %f', sum(tot_durs));
    
    l.info('Phases:');
    disp(durations);
    
    l.info('Each seed mutated %f times', mean(emi_stats.count_mutants));
    
    %%% Total Runtime as if linear 
    
    % Fill missing vals
    
    merged.count_mutants = fillmissing(merged.count_mutants, 'constant', 0);
    merged.avg_mut_dur = fillmissing(merged.avg_mut_dur, 'constant', 0);
    merged.emi_gen_tot_dur = merged.count_mutants .* merged.avg_mut_dur;
    
    dur_vals = merged{:,...
        {'simdur', 'duration', 'compile_dur', 'emi_gen_tot_dur'}};
    
    l.info('Total linear duration: %f minutes', sum(sum(dur_vals)) / 60);
    
catch e
    utility.print_error(e);
end

end
