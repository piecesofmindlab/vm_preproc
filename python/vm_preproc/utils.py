# Utility functions
import os
import six
import h5py
import inspect
import file_io
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
    return (S - mean) / std, mean, std


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


def circ_dist(a, b):
    """Angle between two angles, all in radians
    """
    phi = np.e**(1j*a) / np.e**(1j*b)
    ang_dist = np.arctan2(phi.imag, phi.real)
    return ang_dist


def alpha_overlay(im0, im1, alpha, center=(0,0)):
    """overlay im1 over im0 with alpha blending defined by alpha
    
    Parameters
    ----------
    im0 : array
        underlay image
    im1 : array
        overlay image
    center : tuple
        (x, y) coords, in pixels from center of image, for where to 
        center the overlay image
    """    
    
    if np.ndim(im1) == 2:
        y0, x0 = im0.shape
        y1, x1 = im1.shape
    elif np.ndim(im1) == 3:
        y0, x0, c0 = im0.shape
        y1, x1, c1 = im1.shape
        alpha = np.atleast_3d(alpha)
    if (x1 != x0) or (y1 != y0):
        # By convention, add any rounded pixels to left and top
        left = np.ceil((x0 - x1) / 2 + center[0]).astype(np.int)
        right = np.floor((x0 - x1) / 2 - center[0]).astype(np.int)
        top = np.ceil((y0 - y1) / 2 - center[1]).astype(np.int)
        bottom = np.floor((y0 - y1) / 2 + center[1]).astype(np.int)
        # Will generate errors with overflow; fix? just let it generate errors for now.
        if np.ndim(im1) == 2:
            im1 = np.pad(im1, [(top, bottom), (left, right)])
            alpha = np.pad(alpha, [(top, bottom), (left, right)])
        elif np.ndim(im1) == 3:
            im1 = np.pad(im1, [(top, bottom), (left, right), (0, 0)])
            alpha = np.pad(alpha, [(top, bottom), (left, right), (0, 0)])
    out = im0 * (1-alpha) + im1 * (alpha)
    return out.astype(im0.dtype)


def get_default_kwargs(fn):
    """Get keyword arguments and default values for a function

    Uses `inspect` module; this is a thin convenience wrapper

    Parameters
    ----------
    fn : function
        function for which to get kws
    """
    kws = inspect.getargspec(fn)
    defaults = dict(zip(kws.args[-len(kws.defaults):], kws.defaults))
    return defaults
    
def get_function(function_name):
    """Load a function to a variable by name

    Parameters
    ----------
    function_name : str
        string name for function (including module)
    """
    import importlib
    fn_path = function_name.split('.')
    module_name = '.'.join(fn_path[:-1])
    fn_name = fn_path[-1]
    module = importlib.import_module(module_name)
    func = getattr(module, fn_name)
    return func


class DataSet(object):
    """Loader for files"""
    def __init__(self, fpath, variable_name='data', data=None):
        """Parse whatever file you've got"""
        # TODO: handle list of files, total file length
        # Need to computer or specify n frames per file, store as property
        self.fpath = fpath
        self.variable_name = variable_name
        self._n_frames = None
        self._data = data

    def load(self, variable_name=None, idx=None):
        """Load data into memory"""
        if self._data is None:
            if variable_name is None:
                variable_name = self.variable_name
            return file_io.load_array(self.fpath, variable_name, idx=idx)
        else: 
            if idx is None:
                return self._data
            else:
                return self._data[idx[0]:idx[1]]

    @property
    def n_frames(self):
        """Compute how many frames across stimuli etc"""
        if self._n_frames is None:
            if self._data is None:
                fnm, ext = os.path.splitext(self.fpath)
                sz = file_io.var_size(self.fpath)
                if ext in ('.mp4',):
                    frames = sz[-1]
                else:
                    frames = sz[0]
            else:
                # Assume (y, x, [c], t) array
                frames = self._data.shape[0]
            self._n_frames = frames
        return self._n_frames
    

def batch_run(fn, inpt, batch_size=None, output_file=None, multiple_outputs='discard', **kwargs):
    """Cycle through a file too long to load into memory at once
    
    Parameters
    ----------
    fn : function to call
        if a string, then fn should be the full modular path to the 
        function ()

    Notes
    -----
    TO DO: parallelize
    """
    # Get function to call
    if isinstance(fn, six.string_types):
        fn = get_function(fn)
    # Get full n frames of video, from video module
    if not hasattr(inpt, 'load'):
        if isinstance(inpt, six.string_types):
            inpt = DataSet(inpt)
        else:
            inpt = DataSet(None, data=inpt)
        #raise ValueError('`inpt` must be either a string filepath or a class with a load method')
    n_frames = inpt.n_frames
    if batch_size is None:
        batch_size = n_frames
    n_batches = int(np.ceil(n_frames / batch_size))
    print('Running %d batches'%n_batches)
    output_option = 'array'
    if output_file is not None:
        fnm, ext = os.path.splitext(output_file)
        if ext in ('.mp4',):
            # initialize video writer object
            outpt = file_io.VideoEncoderFFMPEG(output_file) 
            output_option = 'video'
        elif ext in file_io.HDF_EXTENSIONS:
            output_option = 'hdf'
            outpt = h5py.File(output_file, mode='w')
            # Create output variable dataset in hdf file?
        else:
            raise ValueError('Unsupported output type.')
    else:
        # TO DO: Preallocate...?
        # outpt = np.array(n_frames)
        outpt = []

    try:
        kws = get_default_kwargs(inpt.load)
        for ibatch in range(n_batches):
            st = ibatch * batch_size
            fin = np.min([(ibatch + 1) * batch_size, n_frames])
            idx = (st, fin)
            if 'variable_name' in kws:
                stim = inpt.load(idx=idx, variable_name=kws['variable_name'])
            else:
                stim = inpt.load(idx=idx)
            # Function must return single array output for this to work
            out = fn(stim, **kwargs)
            if isinstance(out, tuple) and (len(out) > 1):
                if multiple_outputs in (False, 'discard', None):
                    # Keep only first output
                    out = out[0]
                else:
                    raise NotImplementedError('Cannot yet handle multiple outputs from file')
                    # Perhaps a handle_outputs() function here, e.g.
                    # out, params_etc = handle_outputs(out)
            if output_option=='video':
                # Write video
                for o_ in out:
                    outpt.write(o_)
            elif output_option=='hdf':
                # Write hdf
                if ibatch==0:
                    # For first batch, create dataset
                    dshape = (n_frames, *out.shape[1:])
                    outpt.create_dataset('data', dtype=out.dtype, shape=dshape, compression='gzip')
                outpt['data'][idx[0]:idx[1]] = out
            else:
                # Concatenate results as array
                outpt.append(out)
        if output_file is None:
            return np.vstack(outpt)
        else: 
            if output_option=='hdf':
                outpt.close()
            elif output_option=='video':
                outpt.stop()
    except:
        # Close output files
        if output_option=='hdf':
            outpt.close()
        elif output_option=='video':
            outpt.stop()
        raise