function dU = makeUniform(data,CDFres,xdp)
% Usage: dU = makeUniform(data,Opts)
%
% Convert data to the probability of each data point assuming a uniform
% distribution. Useful as the first step of Gaussianizing data.
% 
% Example:
% x = rand(1000,1);
% xU = makeUniform(x); % Already almost uniform b/c of "rand"; make it exactly so  
% xN = norminv(xU); % Take inverse normal distribution (given probabilities) 
% hist(x,25); figure; hist(xN,25);
% t = 1:1000;
% figure; plot(t,x,'b',t,xN,'ro');
% 
% Modified slightly from Dustin Stansbury's class method
% gaussianize.makeUniform by ML on 2013.03.06

% Inputs
if ~exist('CDFres','var');
    CDFres = 1000; % resolution of uniform distribution to compute
end
if ~exist('xdp','var'); 
    xdp = 1; 
end

% TRANSFORM DATA TO UNIFORM DISTRIBUTION
% BASED ON CUMULATIVE DISTRIBUTION FUNCTION
maxx = max(data); minn = min(data);
xOffset = (xdp/100)*abs(maxx - minn);
xGrid = linspace(minn,maxx,sqrt(numel(data))+1);
xGrid = mean([xGrid(1:end-1);xGrid(2:end)]);

[counts,bins] = hist(data,xGrid);

% CALCULATE CUMULATIVE DISTRIBUTION
CDF = cumsum(counts);
N = max(CDF);
CDF = CDF/N*(1-1/N);

% ENSURE SUPPORT AT EXTREMUM OF CDF
dX = mean(diff(bins))/2;
xCDF = [minn-xOffset minn (bins + dX) maxx + xOffset + dX];
yCDF = [0 1/N CDF 1];

% STORE CDF PARAMS
%self.xForm(self.iterCnt).dims(self.dimCnt).yCDF = yCDF;
%self.xForm(self.iterCnt).dims(self.dimCnt).xCDF = xCDF;

% UPSAMPLE CDF FOR LOOKUP/TRANSFORM
xUpsample = linspace(xCDF(1),xCDF(end),CDFres);
cdfUpsample = interp1(xCDF,yCDF,xUpsample);
cdfUpsample = ensureMonotonic(cdfUpsample);

% SCALE TO ENSURE MAX OF CDF IS ONE
cdfUpsample = cdfUpsample/max(cdfUpsample);

% TRANSFORM DATA TO UNIFORM DISTRIBUTION
dU = interp1(xUpsample,cdfUpsample,data);


function x = ensureMonotonic(x)
% ENSURES THE ENTRY OF DATA ARE MONOTONICALLY
% INCREASING
    for iI = 2:numel(x)
        if (x(iI) <= x(iI-1))
            if abs(x(iI-1)) > 1e-14
                x(iI) = x(iI-1) + 1e-14;
            elseif x(iI-1) == 0
                x(iI) = 1e-80;
            else
                x(iI) = x(iI-1) + 10^(log10(abs(x(iI-1))));
            end
        end
    end
end
end
