function params = preprocNormalGradient_GetMetaParams(argNum)
% Usage: params = preprocNormalGradient_GetMetaParams(argNum)
% 
% Get preset parameters for preprocNormalGradient.m
% 
% ML 2013.04.08

params.class = 'preprocNormalGradient';
switch argNum
    case 1
        params.method = 'max';
        params.gradParams.method = 'max';
        params.gradParams.nonLinExp = 1;
        params.normalize = 'none';
    case 2
        params.method = 'max';
        params.gradParams.method = 'max';
        params.gradParams.nonLinExp = .5;
        params.normalize = 'none';
    case 3
        params.method = 'max';
        params.gradParams.method = 'max';
        params.gradParams.nonLinExp = .25;
        params.normalize = 'none';
    case 4
        params.method = 'max';
        params.gradParams.method = 'max';
        params.gradParams.nonLinExp = .25;
        params.normalize = '0-1';
        
    % TO DO: play with normalization parameters. Does normalizing each
    % image to the same range hurt? (maybe there are just low values in
    % some images...)
    % maybe a squashing function instead?
    % The square rooting is totally arbitrary...
end