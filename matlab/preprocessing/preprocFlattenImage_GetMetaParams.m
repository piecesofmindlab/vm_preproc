function params = preprocFlattenImage_GetMetaParams(ArgNum)
% Usage: params = preprocFlattenImage_GetMetaParams(ArgNum)
% 
% Get numbered arguments for preprocFlattenImage
% 
% ML 2014.02.23

params = preprocPCA;
params.class = 'preprocPCA';

% All you need is the class... it does what it DOES.