function params = preprocRMS_GetMetaParams(argNum)
% Usage: params = preprocRMS_GetMetaParams(argNum)
% 
% 
% ML 2013.05

params.class = 'preprocRMS';

switch argNum
    case 1
        params.demean = true;
end