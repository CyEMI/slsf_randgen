classdef cell < handle
    %MYCELL Wrapper to `cell` for easy dynamically-growing array usage
    %   Usage: get(index) to return any data at particular index; add(data)
    %   to add `data` at the end of the dynamic array. In constructor, you
    %   can optionally pass capacity. the `len` property returns current
    %   size. 
    
    properties
        len;
    end
    
    properties (Access=private)
        data;
        capacity = [];
    end
    
    methods
        
        function obj = cell(capacity)
            
            if nargin < 1
                capacity = 1;
            end
            

            if iscell(capacity)
                obj.data = capacity;
                obj.len = numel(capacity);
                obj.capacity = obj.len;
            else
                obj.capacity = capacity;
                
%                 if capacity == -1
%                     obj.data = {};
%                 else
                obj.data = cell(1, obj.capacity);
%                 end

                obj.len = 0;
            end
        end
        
        
        function obj = add(obj, elem)
            
            if obj.len == obj.capacity
                obj.data(obj.capacity+1 : obj.capacity*2) = cell(1, obj.capacity);
                obj.capacity = obj.capacity * 2;
            end
            
            obj.len = obj.len + 1;
            obj.data{obj.len} = elem;
        end
        
        
        function ret = get(obj, indx)
            ret = obj.data{indx};
        end
        
        function ret = get_cell(obj)
            % Returns row vector
            ret = obj.data(1:obj.len);
        end
        
        function ret = get_cell_T(obj)
            % Returns column vector
            ret = reshape(obj.get_cell(), obj.len, 1);
        end
        
        function obj = extend(obj, other_cell)
            % TODO: This implementation is horribly inefficient
            for i=1:other_cell.len
                obj.add(other_cell.get(i));
            end
        end
        
        
        function obj = print_all(obj, header)
            
            if ~ isempty(header)
                fprintf('%s\n', header);
            end
            
            for i=1:obj.len
                fprintf('%s\t', obj.data{i});
            end
            
            fprintf('\n');
        end
        
    end
    
end

