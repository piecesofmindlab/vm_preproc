function S = preprocMaskNormals(MaskF,NormF,Opt)
% Usage: S = preprocMaskNormals(MaskF,NormF,Opts)
% 
% Mask out normals associated with objects / backgrounds.
% 
% Inputs:
%   MaskF = string filename for mask file with which to mask the normal
%       images (produced by preprocCombineMasks, w/ Opt.Zstack = false);
%   NormF = string filename for surface normal image stacks (produced by
%       preprocConcatStim.m, w/ Opt.Is_Normal = true) 
%   Opts = struct array w/ fields: 
%     .fgbg = 'fg'; % 'fg' = foreground, 'bg' = background, 'both' = both,
%       in separate channels (doubles the size of stimulus matrix) % BOTH
%       IS NOT IMPLEMENTED YET! Not even sure this is a good idea...
%     .sName = file name to save. Nothing is saved if this is omitted.
% 
% BEWARE mask files and normal files that are not the same size! 
% 
% ML 2012.05.07
% TO DO: mask out both fg and bg in separate channels ?
% Build more flexibility into code to deal with mask / normal image size??
dOpt.fgbg = 'fg'; 
if exist('oo','var')
    Opt = defaultOpt(Opt,dOpt);
end
if ischar(NormF)
    N = load(NormF);
    N = N.S;
else
    N = NormF;
end
if ischar(MaskF);
    M = load(MaskF);
    M = M.S;
else
    M = MaskF;
end
if strcmp(Opt.fgbg,'bg')
    M = 1-M;
end
M = reshape(M,[size(M,1),size(M,2),1,size(M,3)]);
S = bsxfun(@times,M,N);

if isfield(Opt,'sName')
    fprintf('saving %s...\n',Opt.sName)
    save(Opt.sName,'S','-v7.3');
end