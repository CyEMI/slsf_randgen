function [ result ] = covcollect(varargin)
%COVCOLLECTFUN Summary of this function goes here
%   Detailed explanation goes here
    
if covcfg.EXPLORE_A_DIRECTORY 
    exp = covexp.ExploreCovExp(varargin{:});
else
    exp = covexp.CorpusCovExp(varargin{:});
%     exp = covexp.BaseCovExp(); % only for testing purpose
end

result = exp.go();

end

