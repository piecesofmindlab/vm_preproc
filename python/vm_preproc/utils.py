# Utility functions
import numpy as np
from scipy.interpolate import interp1d


### --- Stats functions --- ###
def norm_std_mean(S, mean=None, std=None, size_thresh=None):
    """Z-scoring, with allowances for huge matrices*

    Also allows normalization based on pre-computed means/stds, which is 
    not technically z-scoring
	
	* Not yet, because this hasn't been a problem w/ modern compute infrastructure yet...

    Parameters
    ----------
    S : array
    	to be z-scored along first (0th) dimension
    mean : array
		array to subtract off of S; must be same shape as S besides first 
		dimension.
	std : array
		standard deviation by which to divide S; must be same shape as S 
		besides first dimension.
    """
    if mean is None:
        mean = S.mean(0)
    if std is None:
        std = S.std(0)
    # Add optimization for huge matrices here
    return (S-mean)/std, mean, std

def make_uniform(data, CDFres=1000, xdp=1):
    """Convert data to the probability of each data point assuming a uniform distribution.
    
    Useful as the first step of Gaussianizing data.
    
    Example:
    x = rand(1000, 1);
    xU = make_uniform(x); # Already almost uniform b/c of "rand"; make it exactly so  
    xN = norminv(xU); # Take inverse normal distribution (given probabilities) 
    hist(x, 25); figure; hist(xN, 25);
    t = 1:1000;
    figure; plot(t, x, 'b', t, xN, 'ro');
    
    Modified slightly from Dustin Stansbury's class method
    gaussianize.makeUniform by ML on 2013.03.06
    """
    # TRANSFORM DATA TO UNIFORM DISTRIBUTION
    # BASED ON CUMULATIVE DISTRIBUTION FUNCTION
    maxx = np.max(data); minn = np.min(data)
    xOffset = (xdp/100.)*np.abs(maxx - minn)
    xGrid = np.linspace(minn, maxx, np.sqrt(data.size)+1)
    binC = (xGrid[:-1]+xGrid[1:])/2.

    [counts, binE] = np.histogram(data, xGrid); # bin edges

    # CALCULATE CUMULATIVE DISTRIBUTION
    CDF = np.cumsum(counts).astype('float64')
    N = np.max(CDF);
    CDF = CDF/N*(1.-1./N);

    # ENSURE SUPPORT AT EXTREMUM OF CDF
    dX = np.mean(np.diff(binC))/2;
    xCDF = np.hstack([minn-xOffset, minn, (binC + dX), maxx + xOffset + dX])
    yCDF = np.hstack([0, 1./N, CDF, 1]);

    # UPSAMPLE CDF FOR LOOKUP/TRANSFORM
    xUpsample = np.linspace(xCDF[0], xCDF[-1], CDFres)

    spl = interp1d(xCDF, yCDF)  
    cdfUpsample = spl(xUpsample)
    cdfUpsample = ensure_monotonic(cdfUpsample)

    # SCALE TO ENSURE MAX OF CDF IS ONE
    cdfUpsample = cdfUpsample/np.max(cdfUpsample)

    # TRANSFORM DATA TO UNIFORM DISTRIBUTION
    spl2 = interp1d(xUpsample, cdfUpsample)
    dU = spl2(data)
    return dU

def ensure_monotonic(x):
    """Ensures the different entries of data are monotonically increasing 

    (adds a small delta to identical values to make them slightly different)
    """
    x = x.astype(np.float64)
    for ii in range(1, x.size):
        if x[ii] <= x[ii-1]:
            if np.abs(x[ii-1]) > 1e-14:
                x[ii] = x[ii-1] + 1e-14
            elif x[ii-1] == 0:
                x[ii] = 1e-80
            else:
                x[ii] = x[ii-1] + 10^(np.log10(np.abs(x[ii-1])))
    return x