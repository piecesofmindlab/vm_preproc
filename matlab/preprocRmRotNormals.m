function NN = preprocRmRotNormals(N,V,params)
% Usage: NN = preprocRmRotNormals(N,V,params)
% 
% Removes the rotation of a camera from pixelwise normal images (thus
% making them absolute, or at least removing some of the rotation
% components from them).
% 
% Inputs: 
% N is a X x Y x 3 x Frames matrix of pixelwise normal images
% V is a Frames x 3 matrix of camera vectors (vectors from the camera to
% the fixation point), used to compute the camera's rotation matrix.
% params is a struct array, with fields: 
%   .removeComponent = 3x1 boolean vector; whether to remove x, y, and z
%       rotation components of camera rotation (e.g., [1,0,0] [default]
%       removes only "nodding" of the camera, i.e. normalizes the normals
%       such that up is not camera-up but gravity-up
% 
% NOTE! Normals from usual normal outputs are likely to have a DIFFERENT
% coordinate system than whatever your camera vector is in. Make sure that
% the two MATCH, i.e. that x is left/right, y is forward/backward, and z is
% up/down (this is for Blender's usual coordinate system). 
% 
% ML 2012.10.25
% Updated 2012.12.05

% Defaults
pDefault.removeComponent = [1,0,0];
pDefault.Is_Normalize = true; % Normalize or not; doesn't really matter, this is all for rotation anyway
if ~exist('params','var')
    params = struct;
end
params = defaultOpt(params,pDefault);

% Load normals for test scene, w/ camera moving around square block:
[SzY,SzX,Ch,nFr] = size(N);
NN = zeros(size(N));

%vv(:,1) = 0;
if params.Is_Normalize
    V = bsxfun(@rdivide,V,sum(V.^2,2).^.5);
end

for iFr = 1:nFr
    progressdot(iFr,100,1000,nFr);
    cVec = V(iFr,:);
    CamMat = vector2camMatrix(cVec,~params.removeComponent);
    n = reshape(N(:,:,:,iFr),[],3);
    nT = CamMat*n';
    nn = reshape(nT',SzY,SzX,Ch);
    NN(:,:,:,iFr) = nn;
end

