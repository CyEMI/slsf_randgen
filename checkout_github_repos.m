% Before running this, copy github_data.mat from slsf/+corpus directory to
% the current directory.

addpath slsf;
CORPUS_HOME = envcfg.CORPUS_HOME;

if isempty(CORPUS_HOME)
    error('Please set up environet variable SLSFCORPUS');
end

corpus.checkout_github_repos([ filesep 'github']);