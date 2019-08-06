function f = zerodiv(x,y,val)

% function f = zerodiv(x,y,val)
% 
% <x>,<y> are matrices
% <val> (optional) is the value to use when <y> is 0.
%   default: 0.
%
% calculate x./y but use <val> when y is 0.
% also, we do it in such a way that warnings are not issued.

if ~exist('val','var') || isempty(val)
  val = 0;
end

bad = y==0;
y(bad) = 1;
f = x./y;
f(bad) = val;
