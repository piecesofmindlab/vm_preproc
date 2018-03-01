function f = makeindex1(msize,dim)

% function f = makeindex1(msize,dim)
%
% <msize> is a matrix size
% <dim> is the dimension along which we collapsed
%
% return something like [1 1 1 1 msize(dim) 1 1].

f = ones(1,max(length(msize),dim));
if dim <= length(msize)
  f(dim) = msize(dim);
end
