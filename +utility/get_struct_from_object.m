function ret = get_struct_from_object( p )
%GET_STRUCT_FROM_OBJECT Get p's properties in a struct
%   Detailed explanation goes here
ret = struct;

prop_names = properties(p);

for i=1:length(prop_names)
    ret.(prop_names{i}) = p.(prop_names{i});
end

end

