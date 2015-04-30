function varargout = preprocRMS(S,params)
% Usage: [Spreproc,params] = preprocRMS(S,params)
% 
% Compute RMS contrast for each image in a movie. Must be grayscale (or,
% single-channel) images. 
% 
% ML 2013.05

% Default parameters
dParams.class = 'preprocRMS';
dParams.demean = true;
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);

S = reshape(S,[],size(S,3));
if params.demean
    S = bsxfun(@minus,S,mean(S));
end

Spreproc = rms(S,1)';

varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end