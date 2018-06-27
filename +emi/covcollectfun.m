function [ result ] = covcollectfun
%COVCOLLECTFUN Summary of this function goes here
%   Detailed explanation goes here

    load_system('simulink');
    
    exp = emi.CorpusCovExp();
%     exp = emi.BaseCovExp(); % only for testing purpose
    
    result = exp.go();

end

