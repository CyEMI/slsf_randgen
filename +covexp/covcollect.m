function [ result ] = covcollect(varargin)
%COVCOLLECTFUN Summary of this function goes here
%   Detailed explanation goes here
    
    exp = covexp.ExploreCovExp(varargin{:});
%     exp = covexp.CorpusCovExp(varargin{:});
%     exp = covexp.BaseCovExp(); % only for testing purpose
    
    result = exp.go();

end

