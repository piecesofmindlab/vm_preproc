function [ws cmode] = ridgemulti(X, Y, as)
% function ws = ridgemulti(X, Y, as)
% A simple multi-input multi-output ridge regressor
%    Input:
%          X: stimuli (SxN matrix, S is sample size, N is feature
%          size)
%          Y: responses (SxV matrix, V is model size)
%        as: an array of regularization parameters (Ax1 vector)
%    Output:
%        ws: estimated weights (NxVxA matrix)
%
% Reference: see Tikhonov regularization in Wikipedia
% SN, June 2009
%

if size(X,2)>size(X,1)
  cmode = 1;
  cnum = size(X,1);
else
  cmode = 0;
  cnum = size(X,2);
end

%  fprintf('calculating ridge regression (%dx%d)...', cnum, cnum);

if cmode
  [U S] = eig(X*X');
else
  [U S] = eig(X'*X);
end

ds = diag(S);

ws = zeros(size(X,2),size(Y,2),length(as),'single');

for ii=1:length(as)
   Sd = diag(1./(ds+as(ii)));
   rc = (U*Sd*U');
   if cmode
     ws(:,:,ii) = X'*rc*Y;
   else
	 ws(:,:,ii) = rc*X'*Y;
   end
end

%  fprintf('done.\n');

return
