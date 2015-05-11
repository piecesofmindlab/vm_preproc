function sq = mlSquash(ToSquash,Min,Max,Mu,STD)
% Usage: sq = mlSquash(ToSquash,Min,Max,Mu,STD)
%
% Sigmoid squashing function to curtail extreme values in a matrix or
% vector. 
% 
% Maps the vector to a cumulative normal distribution, between the values
% of Min and Max, w/ mean Mu (by default, 1/2 the distance between Min and
% Max) and standard deviation STD (by default, 1/3 the range from Min to
% Max). This seems to give "good" behavior, i.e. only the values close to
% the extrema are substantially changed.
% 
% 

if nargin==1
    % Base squashing on the distribution of the data:
    STD = nanstd(ToSquash(:));
    Mu = nanmean(ToSquash(:));
    Min = nanmean(ToSquash(:))-STD*3;
    Max = nanmean(ToSquash(:))+STD*3;
end
if exist('Min','var') && isnumeric(Min) && isinf(Min) && Min<0
    Min = -3*nanstd(ToSquash(:));
elseif exist('Min','var') && ischar(Min)
    fn = eval(Min);
    Min = fn(ToSquash);
end
if exist('Max','var') && isnumeric(Max) && isinf(Max) && Max>0
    Max = 3*nanstd(ToSquash(:));
elseif exist('Max','var') && ischar(Max)
    fn = eval(Max);
    Max = fn(ToSquash);
end
if ~exist('Min','var')||~exist('Max','var')
    error('You must supply BOTH min and max (or no arguments but ToSquash)')
end 
if ~exist('Mu','var')||isempty(Mu)
    Mu = (Max-Min)/2 + Min;
end
if ~exist('STD','var')||isempty(STD)
    STD = (Max-Min)/3;
end
% Original: 
%sq =  (Max-Min) * (1+exp(-(ToSquash-Mu)/STD)).^-1 + Min;
n = normcdf(ToSquash,Mu,STD);
sq = (Max-Min) * n + Min;
