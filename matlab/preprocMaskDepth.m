function S = preprocMaskDepth(MaskF,DepthF,OptIn)
% Usage: S = preprocMaskNormals(MaskF,DepthF,Opts)
% 
% Mask out normals associated with objects / backgrounds.
% 
% Inputs:
%   MaskF = string filename for mask file with which to mask the depth
%       images (produced by preprocCombineMasks, w/ Opt.Zstack = false);
%       OR: provide a directory of masks. Function does the rest, based on
%       some STRONG ASSUMPTIONS that you are basically Mark Lescroart, or
%       are following his conventions TO A T. (Note: fix this later, ML!)
%   DepthF = string filename for concatenated depth image stacks (produced
%       by preprocConcatStim.m, w/ Opt.type = 'Zabs') 
%   Opts = struct array w/ fields: 
%     .fgbg = 'fg'; % 'fg' = foreground, 'bg' = background, 'both' = both,
%       in separate channels (doubles the size of stimulus matrix) % BOTH
%       IS NOT IMPLEMENTED YET! Not even sure this is a good idea...
%     .sName = file name to save. Nothing is saved if this is omitted.
% 
% BEWARE mask files and normal files that are not the same size! 
% 
% STILL A WIP as of 2012.12.05!!
% 
% ML 2012.05.07
% TO DO: mask out both fg and bg in separate channels ?
% Build more flexibility into code to deal with mask / normal image size??

error('Unfinished!')
dOpt.fgbg = 'fg'; 
if exist('OptIn','var')
    Opt = defaultOpt(OptIn,dOpt);
end
if ischar(DepthF)
    N = load(DepthF);
    N = N.S;
else
    N = DepthF;
end
if ischar(MaskF);
    M = load(MaskF);
    M = M.S;
else
    M = MaskF;
end

M = reshape(M,[size(M,1),size(M,2),1,size(M,3)]);
S = bsxfun(@times,M,N);

if isfield(dOpt,'sName')
    fprintf('saving %s...\n',dOpt.sName)
    save(dOpt.sName,'S','-v7.3');
end