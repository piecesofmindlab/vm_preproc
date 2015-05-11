function n = png2normals(fNm)
% Usage: n = png2normals(fNm)
%
% Converts png file (0-255) output by BVP to x,y,z normals from -1 to 1
% 
% ML 2012.05.09

[n,map,alph] = imread(fNm);
tmp = (single(n)-127.5) / 127.5;
n = (tmp);
%n(:,:,1) = (tmp(:,:,1)-.5) * 2;
%n(:,:,2) = (tmp(:,:,2)-.5) * 2;
%n(:,:,3) = (tmp(:,:,3)