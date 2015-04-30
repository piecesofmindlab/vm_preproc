function varargout = preprocMeanLum(S,params)
% Usage: [Spreproc,params] = preprocMeanLum(S,params)
% 
% Compute Mean luminance for each image in a movie. Must be grayscale (or,
% single-channel) images. 
% 
% ML 2013.05

% Default parameters
dParams.class = 'preprocMeanLum';
dParams.scale = '0-1';
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);

S = reshape(S,[],size(S,3));
switch params.scale
    case '0-1'
        S = S-min(S(:));
        S = S/max(S(:));
end
Spreproc = mean(S,1)';

varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end