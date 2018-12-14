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
        
        function obj = cell(varargin)
            % Single scalar argument denotes capacity
            % Single cell arugments create a new object using the cell
            % elements for initialization
            % 3 Arguments (len, data, capacity) is used to make a deep copy
            % by the `deep_copy` method.
            capacity = 1;
            
            if nargin == 1
                capacity = varargin{1};
            elseif nargin == 3 % Deep Copy
                obj.len = varargin{1};
                obj.data = varargin{2};
                obj.capacity = varargin{3};
                return;
            end
            

            if iscell(capacity)
                % capacity is actually the initialization data
                obj.data = capacity;
                obj.len = numel(capacity);
                obj.capacity = obj.len;
            else
                obj.capacity = capacity;
                
                obj.data = cell(1, obj.capacity);

                obj.len = 0;
            end
        end
        
        function ret = deep_copy(obj)
            ret = utility.cell(obj.len, obj.data, obj.capacity);
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
            if isscalar(indx)
                ret = obj.data{indx};
            else
                ret = obj.get_cell();
                ret = ret(indx);
            end
        end
        
        function ret = get_cell(obj)
            % Returns row vector
            ret = obj.data(1:obj.len);
        end
        
        function ret = get_mat(obj)
            % Returns column vector
            ret = reshape(...
                    cell2mat(obj.data(1:obj.len)),...
                obj.len, 1);
        end
        
        function ret = get_cell_T(obj)
            % Returns column vector
            ret = reshape(obj.get_cell(), obj.len, 1);
        end
        
        function obj = extend(obj, other_cell)
            for i=1:other_cell.len
                obj.add(other_cell.get(i));
            end
        end
        
        function ret = empty(obj)
            ret = obj.len == 0;
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

