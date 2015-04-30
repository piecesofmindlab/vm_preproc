function params = preprocWaveletContrast_GetMetaParams(argNum)
% Usage: 
% Problem: need to specify (with TWO numbers!) Gabor params and intrinsic
% params. SO. Within preprocWaveletContrast.m, ALWAYS search for params.PP
% fields in the param structure fed to it. if params.PP...PP.gaborparams
% doesn't exist, throw an error.

params.class = 'preprocWaveletContrast';
switch argNum
    case 1
        params.combineMethod = 'sum';
    case 2
        params.combineMethod = 'var';
    case 3
        params.combineMethod = 'std';
    case 4
        params.combineMethod = 'min';
    case 5
        params.combineMethod = 'max';
        % to come: soft min/max?
end