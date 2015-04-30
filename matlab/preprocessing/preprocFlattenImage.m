function varargout = preprocFlattenImage(S,params)
% Usage: varargout = preprocFlattenImage(S,params)
% 
% Flatten a 3D (x,y,t) or 4D (x,y,rgb,t) image to 2D (t,pixels)
% 
% Inputs: 
%   S : image frame matrix (xyt or xyct)
%   params : (empty struct array) (optional)
%   
% Outputs: 
%   Spreproc : flattened version of S (t x pixels)
%   params : Dummy output to make other functions happy
% 
% ML 2014.02.24

% Inputs (kinda bullshitty, for compatiblity with STRFlab formats)
if ~exist('params','var')
    params = struct;
end
% Defaults
params.class = 'preprocFlattenImage'; 
% Very short business time
sz = size(S);
S = reshape(S,[],sz(end))';
varargout{1} = S;
if nargout==2
    varargout{2} = params;
end
% Done! This is a really stupid function!