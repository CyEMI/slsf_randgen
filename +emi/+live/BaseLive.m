classdef BaseLive < utility.DecoratorClient
    %BASELIVE Data model to implement live mutation for only a block
    %   Detailed explanation goes here
    
    properties
       r;               % Instance of Mutant Report
       
       parent;          % path of parent of block to mutate
       blk;             % block to mutate - without full path
       connections;
       sources;         % predecessors
       destinations;    % successors
       is_if_block;
       
       blk_full;        % full path
       
    end
    
    methods
        function obj = BaseLive(decs, r, parent, blk, connections,...
                sources,destinations, is_if_block)
            %BASELIVE Construct an instance of this class
            obj = obj@utility.DecoratorClient(decs);
            
            obj.r = r;
            obj.parent = parent;
            obj.blk = blk;
            obj.connections = connections;
            obj.sources = sources;
            obj.destinations = destinations;
            obj.blk_full = [parent '/' blk];
            obj.is_if_block = is_if_block;
            
        end
        
        
        function go(obj, varargin)
            obj.call_fun(@go, varargin{:});
        end
        
    end
end

