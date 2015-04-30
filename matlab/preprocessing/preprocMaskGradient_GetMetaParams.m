function params = preprocMaskGradient_GetMetaParams(Arg)
% Usage: params = preprocMaskGradient_GetMetaParams(Arg)
% 
% Function to get parameter pre-sets for preprocMaskGradient preprocessing. 
% Input "Arg" is a scalar numerical vector, specifying a numerical
% option for a set of parameters
% 
% ML 2013.05.06

params.class = 'preprocMaskGradient';
% First-stage processing presets
switch Arg
    case 1
        % Default parameters:
        params.thresh = .66; % Threshold for defining gradients as contours
end
