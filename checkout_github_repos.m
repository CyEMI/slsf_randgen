% Make sure you have set up environment variable SLSFCORPUS
% To run in TACC you can create checkout_github_repos.job which is in
% .gitignore

addpath slsf;
CORPUS_HOME = getenv('SLSFCORPUS');

if isempty(CORPUS_HOME)
    error('Please set up environet variable SLSFCORPUS');
end

corpus.checkout_github_repos([ filesep 'github']);