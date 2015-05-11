function preproc_Wrapper(S,pp,sName,varargin)
% Usage: preprocHoG_Wrapper(S,pp,sName,[otherargs])
% 
% Wrapper to allow calls of STRFlab preprocessing via slurm.
% 
% otherargs is mostly intended to be for expInfo (w/ preprocDownsample) for
%   now (2012.11.16)
% TO DO: 
%   - figure out wtf to do about fInfo field from older preproc
%       functions (and how to save intermediate files). 
%   - make compatible with couchdb storage of files
%   - update other functions to use preprocTime / nested PP structure
% 
% ML 2012.11.16
warning('Deprecated! Going away! use preprocPipeline, please')
[m.Spreproc,m.params] = feval(pp.class,S,pp,varargin{:});
save(sName,'-struct','m','-v7.3')
