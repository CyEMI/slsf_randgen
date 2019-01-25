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
    
    e = []; % Do not throw the previous error which is a model issue
    
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
            % Should we not check what went wrong? Yes, at the end of this
            % file we are throwing this :-)
            utility.print_error(e, l);
        end
        
        % Terminate. Turns out a model can compile and then fail to 
        % terminate (e.g. aero_guidance) due to:
        % Error evaluating 'StopFcn' callback of block_diagram.
        try
            simob.term();
        catch e2
            ret.compiles = false;
            ret.compile_exp = e2;
        end
        
    end % compiles
    
    ret.compile_dur = toc(my_tic);
    
    if ~ isempty(e)
        rethrow(e);
    end
end

