function params = preprocGist_GetMetaParams(Arg)
% Usage: params = preprocGist_GetMetaParams(Arg)
% 
% ML 2012.11.16

params.class = 'preprocGist';
switch Arg
    case 1
        % Same as preprocGist defaults
        params.imageSize = nan;
        params.orientationsPerScale = [8 8 8 8];
        params.numberBlocks = 4;
        params.fc_prefilt = 4;
        params.boundaryExtension = 32; % number of pixels to pad    
%     case 2
%         % ?
%         params.imageSize = nan;
%         params.orientationsPerScale = [8 8 8 8];
%         params.numberBlocks = 4;
%         params.fc_prefilt = 4;
%         params.boundaryExtension = 32; % number of pixels to pad    
    otherwise
        error('Unknown parameter configuration!');
end
