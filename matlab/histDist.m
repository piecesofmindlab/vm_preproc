function d = histDist(a,b,fn)
% Usage: histDist(a,b,fn)
%
% Distance between two histograms. Metric is Chi^2 by default (only one for
% now - 2012.03.22)
%
% Inputs: 
% a,b = histograms to compare (should have same # of values)
% fn = 'chisq' (or TO COME other metrics)
% 
% ML


if ~exist('fn','var')
    fn = 'chisq';
end

switch fn
    case 'chisq'
        num = (a-b).^2;
        denom = (a+b);
        d = .5 * sum(num./denom);
    otherwise
        error('not ready yet!')
end