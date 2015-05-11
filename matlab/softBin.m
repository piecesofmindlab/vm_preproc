function b = softBin(x,binCenters,binWidth,circMax)
% Usage: b = softBin(x,binCenters,binWidth,circMax)
%
% "Soft" histogramming means that values in a vector can be apportioned to
% more than one bin in a histgram if they fall between bin centers. For
% example, if there are two bins centers at 0 and 10, then a value of 5
% will be assigned to both bins with a weight of .5
% 
% Inputs: 
% out_hist(:,x,y) is non-negative and sums to 1 and
% out_hist(A,x,y) is the fraction of the gradient angle at pixel (x,y) that falls in bin A



% Distance function
if exist('circMax','var')
    distFn = @(a,b,mx) min(abs(a-b), mx - abs(a-b));
else
    circMax = 0;
    distFn = @(a,b,xx) min(abs(a-b),2);
end

binCenters = repmat(binCenters,size(x,1),1);
bin_dist = bsxfun(@(x,binCenters) distFn(x,binCenters,circMax),x,binCenters);
b = max(0,bsxfun(@rdivide,bsxfun(@minus,binWidth,bin_dist),binWidth));