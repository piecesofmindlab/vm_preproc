# Utility functions
import os
import six
import h5py
import tqdm
import time
import inspect
import file_io
import imageio
import numpy as np
from scipy.interpolate import interp1d
from functools import reduce

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


def list_reduce(my_list): 
    """Convenience function to reduce a list of lists to a single list

    Parameters
    ----------
    my_list : list
        list of lists to be reduced to a single list
    """
    return reduce(lambda x, y: x+y, my_list)

    
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

    def load(self, variable_name=None, idx=None, **kwargs):
        """Load data into memory"""
        if self._data is None:
            if variable_name is None:
                variable_name = self.variable_name
            return file_io.load_array(self.fpath, variable_name, idx=idx, **kwargs)
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
                sz = file_io.var_size(self.fpath, variable_name=self.variable_name)
                frames = sz[0]
            else:
                # Assume (y, x, [c], t) array
                frames = self._data.shape[0]
            self._n_frames = frames
        return self._n_frames

class MultiPartDataSet(object):
    """loader for multi-part data for functions with multiple inputs"""
    def __init__(self, fpaths=None, variable_names=None, data=None):
        """All inputs are dicts of {variable_name:value}

        You must specify EITHER fpaths and variable_names (keys must match)
        OR data, with all values specified.


        Parameters:
        fpaths
        """
        self.fpaths = fpaths
        self._n_frames = None
        self._data = data
        if variable_names is None:
            if data is None:
                # Rely on fpaths to be a dict
                assert isinstance(fpaths, dict), '`fpaths` input must be a dict if data is None!'
                self.variable_names = dict((k, None) for k in fpaths.keys())
            else:
                # Rely on data to be a dict
                assert isinstance(data, dict), '`data` input must be a dict!'
                self.variable_names = dict((k, None) for k in data.keys())
        else:
            self.variable_names = variable_names
    
    def load(self, idx=None, **kwargs):
        if self._data is None:
            return dict((k, file_io.load_array(self.fpaths[k], variable_name=self.variable_names[k], idx=idx, **kwargs)) for k in self.fpaths.keys())
        else:
            return dict((k, v[idx[0]:idx[1]]) for k, v in self._data.items())
    
    @property
    def n_frames(self):
        if self._n_frames is None:
            if self._data is None:
                frames = dict((k, file_io.var_size(self.fpaths[k], variable_name=self.variable_names[k])[0]) for k in self.fpaths.keys())
            else:
                frames = dict((k, v.shape[0]) for k, v in self._data.items())
            self._n_frames = frames
        return self._n_frames


def batch_run(fn, inpt, 
    batch_size=None, 
    output_file=None, 
    multiple_outputs='discard', 
    output_fps=None,
    output_resolution=None,
    batch_combine_fn=np.vstack,
    sleep_time=0.3,
    load_kws=None,
    #first_frame=None, # TO DO?
    #last_frame=None, # TO DO? 
    **kwargs):
    """Cycle through a file too long to load into memory at once
    
    Parameters
    ----------
    fn : function to call
        if a string, then fn should be the full modular path to the 
        function
    inpt : string, array-like, or DataSet
        The input to be processed. 
        A string can be used to specify a file path to e.g. a movie or hdf file. 
        An array input should have time on the first axis
        Strings and arrays are both passed to vmp.utils.DataSet to create 
        iterable objects
    output_file : string or None
        If a string is provided, output is written the file specified by the string
        Specified files currently must be .hdf or .mp4
    multiple_outputs : string
        Specifies how to handle multiple out puts from `fn`. Currently WIP; only 
        currently available option is to take first output ('discard' the rest)
    output_fps : scalar or None
        if output is an mp4, specifies frame rate
    output_resolution : tuple or None
        if output is an mp4, specifies spatial resolution
    batch_combine_fn : function
        function to use to combine outputs of multiple batches. Must take a list
        as input, do something to it to convert it to the desired output. Two main
        options are `np.vstack` (default) to concatenate arrays computed by each 
        batch along their first dimension and `list_reduce` to concatenate multiple
        lists into a single list.
    sleep_time : scalar 
        Time in seconds to sleep between batches 
    
    Other Parameters
    ----------------
    kwargs are all mapped to the call to `fn` 

    Notes
    -----
    TO DO: processing of large movie files in multiple batches should be embarassingly
    parallel; thus, they could & should be distributed over multiple threads or jobs. 
    TO DO: Implement running on only a subset of input frames, maybe.
    TO DO: compute batch size based on memory use, given size of array input
    """
    
    ## Handle inputs
    # Get function to call
    if isinstance(fn, six.string_types):
        fn = get_function(fn)
    # Manage input type, map to DataSet or MultiPartDataSet class if necessary
    if not hasattr(inpt, 'load'):
        if isinstance(inpt, dict):
            # Deal with multiple inputs
            inpt = MultiPartDataSet(**inpt)
        else:
            # Deal with single input
            if isinstance(inpt, six.string_types):
                inpt = DataSet(inpt)
            else:
                inpt = DataSet(None, data=inpt)
    # Get full number of frames for video (or other) input
    n_frames = inpt.n_frames
    if isinstance(n_frames, dict):
        n_fr_ = np.array(list(n_frames.values()))
        if not np.all(n_fr_[0]==n_fr_[1:]):
            mx_diff = np.max(n_fr[1:] - n_fr_[0])
            if mx_diff == 1:
                # Off-by-one error. Shit. Maybe disallow. for now, allow... (SHADY)
                pass # See min below
            else:
                raise ValueError('Number of frames for different parts of input to batch_run does not match!')
        n_frames = min(list(n_frames.values()))
    # Compute number of batches to run
    if batch_size is None:
        batch_size = n_frames
    elif batch_size == 'auto':
        #raise NotImplemented('Not Yet!')
        # bytes for different data types
        dtype_bytes = dict(uint8=1,
            float32=4, 
            float64=8,
            )
        # Load first frame
        tmp = inpt.load(idx=(0, 1))
        if isinstance(tmp, dict):
            n_bytes = np.sum([np.prod(v.shape) * dtype_bytes[str(v.dtype)] for v in tmp.values()])
        else:
            n_bytes = np.prod(tmp.shape)
        # Make me an input, or a part of batch size, or whatever
        max_batch_bytes = 1024**3 * 4 # 4 GB
        batch_size = int(np.floor(max_batch_bytes / n_bytes))
    n_batches = int(np.ceil(n_frames / batch_size))

    ## Handle output options: write to file (mp4 or hdf) or save to array
    output_option = 'array'
    if output_file is not None:
        fnm, ext = os.path.splitext(output_file)
        if ext in ('.mp4',):
            output_option = 'video'
            # initialize video writer object
            if (output_fps is None) and (output_resolution is None):
                # try to read input file; assume fps & size are same
                if '.mp4' in inpt.fpath:
                    vid = imageio.get_reader(inpt.fpath,  'ffmpeg') 
                    meta = vid.get_meta_data()
                    output_fps = meta['fps']
                    output_resolution = meta['size'][::-1]
                else:
                    raise ValueError("Please specify `output_fps` for movie")
            outpt = file_io.VideoEncoderFFMPEG(output_file, output_resolution, output_fps) 
        elif ext in file_io.HDF_EXTENSIONS:
            output_option = 'hdf'
            outpt = h5py.File(output_file, mode='w')
            # Create output variable dataset in hdf file?
        else:
            raise ValueError('Unsupported output type.')
    else:
        # TO DO: Preallocate...?
        # outpt = np.array(n_frames, ...)
        outpt = []

    # Try loop to make sure output file is not left dangling & open
    # Consider replacing with `with` call?
    try:
        kws = get_default_kwargs(inpt.load)
        kws_fn = get_default_kwargs(fn)
        if load_kws is None:
            load_kws = {}
        # Remove progress bar kwarg if not supported
        if (not 'progress_bar' in kws_fn) and ('progress_bar' in kwargs):
            _ = kwargs.pop('progress_bar')
        print('Running %d batches'%n_batches)
        for ibatch in range(n_batches):
            print(f"Running batch {ibatch} / {n_batches}")
            # Get indices for this batch
            st = ibatch * batch_size
            fin = np.min([(ibatch + 1) * batch_size, n_frames])
            idx = (st, fin)
            # Load input
            if 'variable_name' in kws:
                stim = inpt.load(idx=idx, variable_name=kws['variable_name'], **load_kws)
            else:
                stim = inpt.load(idx=idx, **load_kws)
            if ('progress_bar' not in kws) and ('progress_bar' in kwargs):
                _ = kwargs.pop('progress_bar')
            # Run function on this batch
            if isinstance(stim, dict):
                out = fn(**stim, **kwargs)
            else:        
                out = fn(stim, **kwargs)
            # Store output
            if isinstance(out, tuple) and (len(out) > 1):
                if multiple_outputs in (False, 'discard', None):
                    # Keep only first output
                    out = out[0]
                elif isinstance(multiple_outputs, (list, tuple)):
                    assert len(out) == len(multiple_outputs)
                    out = dict((k, v) for k, v in zip(multiple_outputs, out))
                else:
                    # ASSUME integer index; needs check / assertion statement here
                    out = out[multiple_outputs]
            # Map output to file if desired
            if output_option=='video':
                # Write frames to video writer object
                for o_ in out:
                    outpt.write(o_)
            elif output_option=='hdf':
                # Write indices to hdf file object
                if ibatch==0:
                    # For first batch, create dataset
                    # First, check for downsampling of data:
                    if isinstance(stim, dict):
                        n_frames_batch = list(stim.values())[0].shape[0]
                    else: 
                        n_frames_batch = stim.shape[0]
                    n_frames_output = out.shape[0]
                    if n_frames_output < n_frames_batch:
                        if 'extra_frame_threshold' in kwargs:
                            ds_factor = int(np.floor(kwargs['input_hz'] / kwargs['output_hz']))
                            extra_frames = n_frames % ds_factor
                            to_add = 1 if extra_frames > kwargs['extra_frame_threshold'] else 0
                            n_frames_out = n_frames // ds_factor + to_add
                        else:
                            # If present, compute downsampling factor
                            ds_factor = n_frames_batch / n_frames_output
                            tolerance = 1e-6
                            if ds_factor % 1 > tolerance:
                                raise ValueError("Downsampling by non-integer factor detected; I die now.")
                            n_frames_out = int(n_frames / ds_factor)
                    else:
                        ds_factor = 1.0
                        n_frames_out = n_frames
                    # Create dataset output
                    dshape = (n_frames_out, *out.shape[1:])
                    outpt.create_dataset('data', dtype=out.dtype, shape=dshape, compression='gzip')
                
                oidx = [int(st / ds_factor), int(st / ds_factor) + n_frames_output]
                outpt['data'][oidx[0]:oidx[1]] = out
            else:
                # No file output; concatenate results as array
                outpt.append(out)
            # Stall (maybe (?) helps some sub-processes complete)
            time.sleep(sleep_time)
        # Having finished batches, manage output
        if output_file is None:
            return batch_combine_fn(outpt)
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
        raise Exception("Failed during run!")
