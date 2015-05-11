function vOut = crop(vIn,mn,mx)
% Usage: vOut = crop(vIn,mn,mx)
% 
% Crops large values a vector / matrix
% 
% ML 2012.05.24

vOut = vIn;
vOut(vIn<mn) = mn;
vOut(vIn>mx) = mx;