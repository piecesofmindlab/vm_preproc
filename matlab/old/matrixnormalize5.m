function [f,mn,sd] = matrixnormalize5(m,dim,flag)

% function [f,mn,sd] = matrixnormalize5(m,dim,flag)
%
% <m> is a matrix
% <dim> (optional) is the dimension along which data
%   series lie.  if [] or not supplied, then default 
%   to 2 if <m> is a vector and to 1 if not.
% <flag> (optional) is
%   0 means subtract mean, divide by std using N-1 [vector length sqrt(N-1)]
%   1 means subtract mean, divide by std using N [vector length sqrt(N)]
%   2 means subtract mean, divide so that [vector length 1]
%   -1 means subtract mean
%   -2 means divide so that [vector length sqrt(N)]
%   if [] or not supplied, default to 0.
%
% when <flag> is not -1 and not -2, then if <m> has no variance in some case,
% set the respective values to 0.  when <flag> is -2, if a case is all zeros,
% leave it at all zeros.
%
% we also return the mean and divisor matrices in <mn> and <sd>.
% these have the same dimensions as <m> except they are collapsed
% along <dim>.  in the special case of -1, <sd> is returned as [].
% in the special case of -2, <mn> is returned as [].
%
% we use nanmean and nanstd to avoid NaN problems.
%
% note that NaNs in the input are preserved as such in the output!

% deal with input
if ~exist('dim','var') || isempty(dim)
  if isflatvector(m)
    dim = 2;
  else
    dim = 1;
  end
end
if ~exist('flag','var') || isempty(flag)
  flag = 0;
end

% calc
msize = size(m);

% do it
idx = makeindex1(msize,dim);
switch flag
case -2
  mn = [];
  sd = sqrt(zerodiv(nansum(m.^2,dim),size(m,dim) - sum(isnan(m),dim),0));
  f = zerodiv(m,repmat(sd,idx),0);
  f(isnan(m)) = NaN;
case -1
  mn = nanmean(m,dim);
  f = m - repmat(mn,idx);
  sd = [];
case {0 1 2}
  mn = nanmean(m,dim);
  if flag==2
    sd = nanstd(m,0,dim) .* sqrt(size(m,dim)-1 - sum(isnan(m),dim));
  else
    sd = nanstd(m,flag,dim);
  end
  f = m - repmat(mn,idx);  % like this to help memory
  f = zerodiv(f,repmat(sd,idx),0);  % let's be explicit!
  f(isnan(m)) = NaN;  % let's be explicit!
end
