function f = makeindex2(msize,dim)

% function f = makeindex2(msize,dim)
%
% <msize> is a matrix size
% <dim> is the dimension along which we collapsed
%
% return <msize> but with a 1 at position <dim>.

f = ones(1,max(length(msize),dim));
f(1:length(msize)) = msize;
f(dim) = 1;
