function ret = scaling(result, l)
%SCALING Summary of this function goes here
%   Detailed explanation goes here
ret = true;

try
    l.info('--- Scaling Reports ---');
    
    m = struct2table(result.models);
    
    % models without exception
    m_wo_e = m((~m.exception & m.compiles), : );
    
%     blks = m_wo_e.blocks;
%     blks_sz = cellfun(@(p) length(p), blks);
%     sorted_blks_sz = sort(blks_sz);
        
    emi_r = load(emi.cfg.RESULT_FILE);
    
    emi_stats = emi_r.stats_table;
    
    merged = outerjoin(m_wo_e, emi_stats);
    
    assert(all(merged.m_id_m_wo_e == merged.m_id_emi_stats));
    
    blks_sz = cellfun(@(p) length(p), merged.blocks);
    
    l.info('Average block size: %f', mean(blks_sz));
    
    blks_per_model_label = 'Number of Blocks/Model';
    
    %%% Plot Durations %%%
    
    durations = {'simdur', 'duration', 'compile_dur', 'avg_mut_dur'};
    dur_legends = {'Run seed', 'Get Coverage', 'Get DataType', 'Mutant Gen (Avg)'};
    
    % merged.duration is a cell, convert it to double
    
    merged.duration = cellfun(@(p)p, merged{:, 'duration'});
    
    utility.plot(blks_sz, merged{:,durations}, dur_legends,...
        blks_per_model_label, 'Runtime (sec)');
    
    % Mutation Stats
    
    utility.plot(blks_sz, merged{:, 'avg_mut_ops'}, {'Mutation Operation (Avg)'},...
        blks_per_model_label, 'Operation Count');
    
 
    %%% Others %%%
    
    
catch e
    utility.print_error(e);
end

end
