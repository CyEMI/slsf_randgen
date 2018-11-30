function ret = check_model_compiles(sys, h, ret)
%CHECK_MODEL_COMPILES Summary of this function goes here
%   Detailed explanation goes here
    ret.compiles = true;
    ret.compile_exp = [];
    ret.datatypes = [];
    
    l = logging.getLogger('singlemodel');
    
    simob = utility.TimedSim(sys, covcfg.SIMULATION_TIMEOUT, l);
    
    try
        simob.start(true);
    catch e
        ret.compiles = false;
        ret.compile_exp = e;
    end
    
    
    if ret.compiles
        % Collect compiled data types for blocks
        
        try
            blocks = covexp.get_all_blocks(h);

            all_blocks = struct;

            for i=1:numel(blocks)
                cur_blk = blocks(i);

                cur_blk_name = getfullname(cur_blk);
                
                all_blocks(i).fullname = cur_blk_name;
                all_blocks(i).datatype = [];
                
                try
                    datatype = get_param(cur_blk_name, 'CompiledPortDataTypes');
                    all_blocks(i).datatype = datatype;
                catch 
                end

            end
                        
            ret.datatypes = all_blocks;
            
        catch e
            disp(e);
            simob.term();
            error(e.identifier);
        end
        
        % Terminate
        simob.term();
        
    end % compiles
    
end

