function [kMin,dMin,kMax,dMax] = compute_principalCurvatureFromZ(Z,f,ReturnVector)
% Usage: [kMin,dMin,kMax,dMax] = compute_principalCurvatureFromZ(Z,f,ReturnVector)
% 
% Compute principal curvatures of a surface. Mostly a wrapper for
%   compute_principalCurvature.m No normalization / binning of curvature is
%   done in this function  
% 
% Inputs: 
%   Z = a matrix of depth values from the camera. Convenience wrapper
%       function for compute_principalCurvature(X,Y,Z). Computes X and Y
%       from Z depth + params.f (focal length, assumed to be 1 for now
%       [2012.11.21]
%   f = focal length of camera (default = 1 seems to be fine)
%   ReturnVector = whether to return direction of principal curvatures
%       (dMin,dMax) as [u,v] vectors instead of as angles (from x [u] axis
%       in 2D) 
% 
% Outputs: 
%   kMin = minimum curvature at each pixel
%   dMin = direction of minimum curvature in X,Y [u,v]** plane (vector)
%   kMax = maximum curvature at each pixel
%   dMax = direction of maximum curvature in X,Y [u,v] plane (vector)
%       
% ** (x,y) maps to (u,v) because of the coordinate system in which the
%   depth values are presented - RIGHT?? (So far as I can tell
%   (2012.11.26), x,y map to u,v so long as x,y are on a regular mesh grid.
%   Othewise, this gets wacky real fast. 
% 
% Note: Gaussian curvature (K) = kMin.*kMax;
%       Mean curvature (H) = (kMin+kMax)/2;
% 
% 2012.11.21 M.L., with thanks to surfature.m by Daniel Claxton
% (http://www.mathworks.com/matlabcentral/fileexchange/11168-surface-curvature)

% Default parameters
if ~exist('f','var')||isempty(f)
    f = 1; % Assumed focal length of 1 seems to give correct depth surface
end
if ~exist('ReturnVector','var')
    ReturnVector = false; % return angle rather than vector
end
% Compute X and Y positions for each pixel from perspective projection
[X,Y] = compute_XYfromDepth(Z,f); 
% Compute curvature
[kMin,dMin,kMax,dMax] = compute_principalCurvature(X,Y,Z,ReturnVector);