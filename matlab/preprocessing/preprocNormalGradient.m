function varargout = preprocNormalGradient(S,params)
% Usage: [Spreproc,params] = preprocNormalGradient(S,params)
% 
% Convert an image of normals (x,y,z channels) to a gradient image
% 
% ML 2013.04

% method
dParams.method = '3D';
dParams.normalize = '0-1';
% params passed to compute_normalGradients
dParams.gradParams.method = 'max';
dParams.gradParams.nonLinExp = .5;

if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,dParams);
if ~nargin
    varargout{1} = params;
end

[sX,sY,sN,nIm] = size(S);
Spreproc = zeros(sX,sY,nIm,'single');
for iIm = 1:nIm
    if nIm > 500
        progressdot(iIm,200,2000,nIm)
    end
    switch lower(params.method)
        case 'max'
            [gm,go] = compute_gradients(S(:,:,:,iIm));
            tmp = gm;
        case '3d'
            [gm,go] = compute_normalGradients(S(:,:,:,iIm),params.gradParams);
            tmp = gm;
            
    end
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
varargout{1} = Spreproc;
if nargout>1
    varargout{2} = params;
end