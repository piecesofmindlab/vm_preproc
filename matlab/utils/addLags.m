function Xx = addLags(X,Lags,toEnd)
% Usage: Xx = addLags(X,Lags,toEnd)
%
% Add lags to a design matrix
% 
% Inputs:
%      X : original design matrix
%   Lags : array of time points (integer count) at which to add lagged
%          predictors 
%  toEnd : T/F, whether to concatenate lagged predictors at one end of the
%          design matrix (T, default) or after each individual channel (F)
% ML 2012.07.15
% Updated 2013.02.12

if ~exist('toEnd','var')
    toEnd = true;
end
if toEnd
    Xx = [];
    for iLag = Lags
        xt = [zeros(iLag-1,size(X,2));X(1:end-iLag+1,:)];
        Xx = [Xx,xt];
    end
else
    nLags = length(Lags);
    Xx = zeros(size(X,1),size(X,2)*nLags);
    for iLag = 1:nLags
        xt = [zeros(Lags(iLag)-1,size(X,2));X(1:end-Lags(iLag)+1,:)];
        Xx(:,iLag:nLags:end) = xt;
    end
end