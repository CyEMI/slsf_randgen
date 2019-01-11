function ret = check_model_compiles(sys, h, ret)
%CHECK_MODEL_COMPILES Compile model to cache data-types of blocks
%   Detailed explanation goes here
    
    l = logging.getLogger('singlemodel');
    
    simob = utility.TimedSim(sys, covcfg.SIMULATION_TIMEOUT, l);
    
    my_tic = tic();
    
    try
        simob.start(true);
    catch e
        ret.compiles = false;
        ret.compile_exp = e;
    end
    
    e = [];
    
    if ret.compiles
        % Collect compiled data types for blocks
        
        try
            blocks = covexp.get_all_blocks(h);

            all_blocks = containers.Map();

            for i=1:numel(blocks)
                cur_blk = blocks(i);

                cur_blk_name = getfullname(cur_blk);
                
                try
                    datatype = get_param(cur_blk_name, 'CompiledPortDataTypes');
                    
                    cur_blk_name = utility.strip_first_split(cur_blk_name, '/');
                    
                    all_blocks(cur_blk_name) = datatype;
                catch 
                end

            end
                        
            ret.datatypes = all_blocks;
            
        catch e
            utility.print_error(e, l);
        end
        
        % Terminate
        simob.term();
        
    end % compiles
    
    ret.compile_dur = toc(my_tic);
    
    if ~ isempty(e)
        rethrow(e);
    end
end

