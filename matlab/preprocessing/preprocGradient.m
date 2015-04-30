function varargout = preprocGradient(S,params)
% Usage: [Spreproc,params] = preprocNormalGradient(S,params)
% 
% Compute x,y gradients across a grayscale or color image. Mostly wraps
% compute_gradients.m
% 
% Inputs: 
%   S : Stimulus matrix, 2D (X,Y),3D (X,Y,Ch) OR (X,Y,T), or 4D (X,Y,Ch,T). 
%   params : struct array, with fields: 
%       .normalize = '0-1';
%       .returnOri = false;
%       .thirdDim = 'time'; % 'color'; % 'normals'; %(?)% 
%       % params passed to compute_gradients
%       .gradParams.method = 'max';
%       .gradParams.IsSqrt = true;
%       .gradParams.IsLAB = false; 
% 
% ML 2013.04

% Default parameters
dParams.normalize = '0-1';
dParams.returnOri = false;
dParams.thirdDim = 'time'; % 'color'; % 'normals'; %(?)% 
dParams.ceiling = nan; % Threshold all values above this to be equal
dParams.floor = nan;
% params passed to compute_gradients
dParams.gradParams.method = 'max';
dParams.gradParams.IsSqrt = true;
dParams.gradParams.IsLAB = false;

if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
end
if ndims(S)==2
    [sX,sY,nIm] = size(S);
    dims = {':',':'};    
elseif ndims(S)==4
    [sX,sY,sN,nIm] = size(S);
    dims = {':',':',':'};
elseif ndims(S)==3
    switch params.thirdDim
        case 'time'
            [sX,sY,nIm] = size(S);
            dims = {':',':'};
        case 'color'
            [sX,sY,sN] = size(S);
            dims = {':',':',':'};
    end
end
Spreproc = zeros(sX,sY,nIm,'single');
if params.returnOri
    Spreproc2 = zeros(sX,sY,nIm,'single');
end
for iIm = 1:nIm
    if nIm > 500
        progressdot(iIm,200,2000,nIm)
    end
    [gm,go] = compute_gradients(S(dims{:},iIm),params.gradParams);
    % Optional return of orientation
    if params.returnOri
        Spreproc2(:,:,iIm) = go;
    end
    % Optionally set all values over "ceiling" to ceiling
    if ~isnan(params.ceiling)
        gm = min(gm,params.ceiling);
    end
    % Normalization done on gradient values
    tmp = gm;
    switch params.normalize
        case '0-1'
            rr = (max(tmp(:))-min(tmp(:)));
            if rr==0
                rr = 1;
            end
            % Scale to 255 (Necessary??)
            tmp = (tmp-min(tmp(:)))/rr;
        case {'none',[]}
            0; % do nothing
        otherwise
            error('unknown normalization parameter setting!')
    end
    Spreproc(:,:,iIm) = tmp; 
end
if params.returnOri
    varargout{1} = {Spreproc,Spreproc2};
else
    varargout{1} = Spreproc;
end
if nargout>1
    varargout{2} = params;
end