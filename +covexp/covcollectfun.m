function [ result ] = covcollectfun
%COVCOLLECTFUN Summary of this function goes here
%   Detailed explanation goes here

    load_system('simulink');
    
    exp = covexp.CorpusCovExp();
%     exp = covexp.BaseCovExp(); % only for testing purpose
    
    result = exp.go();

end

