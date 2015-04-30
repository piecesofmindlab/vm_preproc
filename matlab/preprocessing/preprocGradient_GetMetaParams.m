function params = preprocGradient_GetMetaParams(argNum)
% Usage: params = preprocGradient_GetMetaParams(argNum)
% 
% Get preset parameters for preprocNormalGradient.m
% 
% ML 2013.04.08

params.class = 'preprocGradient';
switch argNum
    case 1
        % 
        params.normalize = '0-1';
        params.returnOri = false;
        params.thirdDim = 'time';
        params.ceiling = nan;
        params.floor = nan;
        % params passed to compute_gradients
        params.gradParams.method = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
    % TO DO: play with normalization parameters. Does normalizing each
    % image to the same range hurt? (maybe there are just low values in
    % some images...)
    % maybe a squashing function instead?
    % The square rooting is totally arbitrary...
    case 2
        params.normalize = '0-1';
        params.returnOri = false;
        params.thirdDim = 'time';
        params.ceiling = .15;
        params.floor = nan;
        % params passed to compute_gradients
        params.gradParams.method = 'max';
        params.gradParams.IsSqrt = true;
        params.gradParams.IsLAB = false;
end