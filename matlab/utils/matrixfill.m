function f = matrixfill(v,msize,dim)

% function f = matrixfill(v,msize,dim)
%
% <v> is a vector of length msize(dim).
%   does not have to be a flat vector.
% <msize> is a matrix size
% <dim> is the dimension along which <v> is oriented
%
% return a matrix of size <msize> filled with <v>.

f = repmat(reshape(v,makeindex1(msize,dim)),makeindex2(msize,dim));
