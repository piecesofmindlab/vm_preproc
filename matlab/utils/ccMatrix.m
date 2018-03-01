function [r,CI] = ccMatrix(m1,m2,dim)
% function r = ccMatrix(m1,m2,dim)
%-------------------------------------------------------------------
% Return the r values (Pearson's correlation coefficient) between
% the two matrices, calcualted along the dimension <dim>
%-------------------------------------------------------------------
%INPUT:
% <m1>,m2>:   - are matrices of the same dimensions
%
% <dim>:      - (optional) is the dimension of interest.
%               if [] or not supplied, then default to 2 if <m1>
%               is a vector and to 1 if not.
%
%OUTPUT:
% <r>:        - correlation coefficient scores
%
% <CI>:       - 95% confidence interval for <r> estimates.
%
% NOTE: if there is no variance in one of the inputs, the r value is 
% returned as 0.
%
% NaNs cause that case to be ignored.
%
% If there are no valid cases (e.g. all NaNs), then return NaN.
%-------------------------------------------------------------------
%DES

if ~exist('dim','var')||isempty(dim)
    if isflatvector(m1)
        dim = 2;
    else
        dim = 1;
    end
end

% FIRST MAKE SURE NANS ARE PROPAGATED
m1(isnan(m2)) = NaN;
m2(isnan(m1)) = NaN;

% NORMALIZE SUCH THAT VECTOR LENGTH=SQRT(N)
m1 = matrixnormalize5(m1,dim,1);
m2 = matrixnormalize5(m2,dim,1);

% TAKE DOT PRODUCT  
temp = m1.*m2;

% FIND NUMBER OF PAIRS AND SCALE
dsize = size(m1);
dsize(dim) = 1;

n = matrixfill(size(m1,dim),dsize,dim);

n = n - sum(isnan(temp),dim);
r = zerodiv(nansum(temp,dim),n,NaN);

if nargout > 1
    CI = [(tanh(atanh(r) - 1.96./sqrt(n-3))); tanh(atanh(r) + 1.96./sqrt(n-3))];
end
 

% as written, this converts to standard scores, then dot-products 
% them, and then divides by how many pairs there were.
%
% this is equivalent to subtracting mean from m1 and from m2, 
% normalizing to be unit vectors, and then taking the dot product.
%
% note that for a mean-subtracted vector, the vector length is sqrt(n) 
% times the std.
%
% Confidence interval is calculated based on Fisher transformation
% 
%
