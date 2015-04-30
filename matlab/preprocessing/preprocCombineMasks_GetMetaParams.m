function params = preprocCombineMasks_GetMetaParams(argNum)
% Usage: params = preprocCombineMasks_GetMetaParams(argNum)
% 
% Get parameters for preprocCombineMasks.m
% 
% 2013.06 ML

params.class = 'preprocCombineMasks';
switch argNum
    case 1
        % Z stack
        params.finSz = [128,128];
        params.Color = nan;
        params.Zstack = true;
        params.Consistent = false; % Does nothing yet! as of 2012.05.07
    case 2
        % combine all
        params.finSz = [128,128];
        params.Color = nan;
        params.Zstack = false;
        params.Consistent = false; % Does nothing yet! as of 2012.05.07
    case 3
        % Z stack, colorize
        params.finSz = [128,128];
        params.Color = 1;
        params.Zstack = true;
        params.Consistent = false; % Does nothing yet! as of 2012.05.07
end        