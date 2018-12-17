function ret = merge_structs(p)
%MERGE_STRUCTS Summary of this function goes here
%   p is utility.cell containing many structs which we want to merge to a
%   single struct

ret = struct;

for j=1:p.len
    s2 = p.get(j);
    f = fieldnames(s2);
    
    for i = 1:length(f)
        ret.(f{i}) = s2.(f{i});
    end
end

end

