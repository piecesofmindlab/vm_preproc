function [X,Y] = compute_XYfromDepth(Z,f)
% Usage: [X,Y] = compute_XYfromDepth(Z,f)
% 
% Compute x and y positions given depth (Z) and camera focal length (f)
% Focal length assumed to be 1 for now (2012.11.20)
%
%

if ~exist('f','var')
    f = 1; %.035; % 35 mm?
    warning(sprintf('Assuming fixed camera focal length @(%.2f)! fix me later!',f))
end

sz = size(Z);
[x,y] = meshgrid(linspace(-1,1,sz(2)),linspace(-1,1,sz(1)));

X = x.*Z/f;
Y = y.*Z/f;
