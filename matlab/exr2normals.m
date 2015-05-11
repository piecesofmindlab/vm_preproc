function N = exr2normals(exrIm,AdjustToBlenderWorld)
% Usage: N = exr2normals(exrIm,AdjustToBlenderWorld)
% 
% Gets and properly normalizes normal vectors from an EXR image. Normals
% can have negative values, but none of the image formats output by Blender
% store negative values; instead, we store a high dynamic range .EXR
% image, with values from 0 to 2. This function converts those to -1 to 1
% (or from 0 to 1 for the Z channel, since no backward-facing norms will be
% available).  
% 
% exrIm can be numeric (read in via exrread) or a character file string
% (for an .exr file). 
% 
% NOTE: for some odd reason, some normals output by Blender are > 1
% (~1.02). I have no idea why this is the case, but that is a reasonably
% small error (if an error it is). Visual inspection of the normals looks
% consistent and reasonable.
% 
% ML 2012.01.18
% Updated 2012.05.10

if ~exist('AdjustToBlenderWorld','var')
    AdjustToBlenderWorld = false;
end

if ischar(exrIm)
    N = exrread(exrIm);
else
    N = exrIm;
end
if AdjustToBlenderWorld
    % UPDATE! Normals are given back in X = Left / Right, Y = Up / Down, Z =
    % toward / away from camera. This is NOT the same coordinate system that
    % Blender uses natively. Adjust!
    N = N(:,:,[1,3,2]);
    y = 2;
    z = 3;
else
    y = 3;
    z = 2;    
end

N = -N+1; %rescale: 0:2 -> -1:1
[H,W,nDim] = size(N);
nr = reshape(N,H*W,nDim);
% Blender spits out normal values outside the expected range 
% (-1 to 1 for x,y, 0 to 1 for z). - so fix it!
% (This is a LITTLE alarming, but values are quite close - ML judged this
% to be a tolerable error, 2012.05.11)
nr(nr(:,1)<-1,1) = -1;
nr(nr(:,1)>1,1) = 1;
nr(nr(:,z)<-1,z) = -1;
nr(nr(:,z)>1,z) = 1;
nr(nr(:,y)<0,y) = 0;
nr(nr(:,y)>1,y) = 1;
% Assure that normals are normalized (all have length = 1) (Blender is also
% not 100% reliable with this, for some reason... but again, errors seem to
% be small - on the order of +/-.003)
L2nrm = sum(nr.^2,2).^.5;
% Set all normals close to zero back to exactly zero
nThresh = .1;
nr(L2nrm<nThresh,:) = 0;
% Set all other normals to vector length = 1
nr = bsxfun(@rdivide,nr,sum(nr.^2,2).^.5+1e-10); % +1e-10 to avoid 0/0 division
N = reshape(nr,[H,W,nDim]);
