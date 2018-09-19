function x = negRectifySquare(x)

x(x>0) = 0;
x = x.^2;