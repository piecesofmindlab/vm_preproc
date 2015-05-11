function CamMat = vector2camMatrix(cVec,IgnoreRotXYZ)
% Usage: CamMat = vector2camMatrix(cVec,IgnoreRotXYZ)
% 
% Gets the camera (perspective) transformation, given a vector (from
% camera->fixation).  Optionally, sets one (or more) axes of rotation for
% the camera to zero (this provides a matrix that "un-rotates" the camera
% perspective, but leaves whatever axes are set to "true" untouched (i.e.,
% in their original image space). 
% 
% Deals with ONE VECTOR AT A TIME
% 
% IgnoreRot = [false,true,false] by default (there should be no y rotation
%   [roll] of cameras anyway!)
% 
% ML 2012.10.25

if ~exist('IgnoreRotXYZ','var')||isempty(IgnoreRotXYZ)
    IgnoreRotXYZ = [false,true,false];
end

% Vector to Euler angles:
if IgnoreRotXYZ(1)
    xR = 0;
else
    %if cVec(3)>0; % BUT: This rotation swaps Y and Z somehow...
    %    xR = -rad2deg(atan(-(cVec(1).^2+cVec(2).^2).^.5/cVec(3)));
    %else
    %    xR = -rad2deg(atan((cVec(1).^2+cVec(2).^2).^.5/cVec(3)));
    %end
    xR = rad2deg(atan2(cVec(3),(cVec(1).^2+cVec(2).^2).^.5));
end
if IgnoreRotXYZ(2)
    yR = 0.; % ASSUMED - no roll of camera    
else
    error('fix me! (I don''t know how to compute y rotations! consult wikipedia!')
end
if IgnoreRotXYZ(3)
    zR = 0; 
else
    zR = -rad2deg(atan2(cVec(1),cVec(2)));
end


cTheta = [xR,yR,zR];
%disp(cTheta)
% Rotation matrices, given Euler angles:
% X rotation
xRot = [1., 0., 0.
    0., cosd(cTheta(1)),sind(cTheta(1))
    0., -sind(cTheta(1)), cosd(cTheta(1))];
% Y rotation
yRot = [cosd(cTheta(2)), 0., -sind(cTheta(2))
    0., 1., 0.
    sind(cTheta(2)), 0., cosd(cTheta(2))];
% Z rotation
zRot = [cosd(cTheta(3)),sind(cTheta(3)), 0.
    -sind(cTheta(3)), cosd(cTheta(3)), 0.
    0., 0., 1.];

CamMat = xRot*yRot*zRot;
