function varargout = preprocMaskGradient(S,params)
% Usage: varargout = preprocMaskGradient(S,params)
% 
% Simple gradient computation + thresholding on "AllMask" images
% 
% ML 2013.05.06

% Defaults
dParams.thresh = .66;
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
    return
end

[x,y,nFrames] = size(S);
Spreproc = zeros(x,y,nFrames,class(S)); 
for ii = 1:nFrames; 
    progressdot(ii,100,1000,nFrames);
    [tmp,~] = compute_gradients(S(:,:,ii)); 
    Spreproc(:,:,ii) = sqrt(tmp)>params.thresh;
end

varargout{1} = Spreproc;
if nargout==2
    varargout{2} = params;
end