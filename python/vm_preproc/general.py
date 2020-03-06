# General preprocessing steps
from __future__ import division

import numpy as np
from skimage import color as skcol
from .utils import make_uniform, norm_std_mean

def convert_color(S, conversion='rgb2lab', keep_colors=False, **kwargs):
    """Wholescale color conversion of (x, y, c, t) arrays
    
    Generally intended to convert RGB images to luminance images. 
    Default conversion is to L*A*B colors space (discarding A and B
    channels). 

    Parameters
    ----------
    S : 

    Notes
    -----
    Could probably use some more intelligent memory management

    """
    try:
        fn = getattr(skcol, conversion)
    except AttributeError:
        raise AttributeError('Unknown color function "%s" (not a function in skimage.color)'%conversion)
    if keep_colors:
        out = np.asarray([fn(s[:3].T, **kwargs).T for s in S.T]).T
    else:
        out = np.asarray([fn(s[:3].T, **kwargs)[..., 0].T for s in S.T]).T
    params = dict(conversion=conversion, keep_colors=keep_colors, **kwargs)
    return out, params


def output_nonlinearity(S, method='log', **kwargs):
    """Output nonlinearity on each channel of a model. 

    Generally done BEFORE (zscore or other) normalization. 

    Parameters
    ----------
    S : array
        array of values to process, (frames x channels)
    method : string
        One of: 'log', 'exponent'

    Other Parameters
    ----------------
    * Specified in kwargs
    exponents : scalar
        exponent to which to raise each channel value, thus: abs(S).^x .*sign(S)
        Multiple values (e.g. [.5,2]) raise each column to each different
        exponent, and concatenate the results (here, doubling the number of channels). 
    delta : scalar
        tiny offset to avoid log(0), if not supplied defaults to 1e-5

    Returns
    -------
    spreproc : array
        processed version of S
    params : dict
        dict of preprocessing params

    Notes
    -----
    Modfied from Shinji Nishimoto's code [CITE github for motion energy]
    """

    params = dict(method=method,
              **kwargs
              )
    if S is None:
        return params

    if method in ('log', 'logmean', 'logstd'):
        # For log, delta is a small value to add to assure no -Inf channels.
        delta = kwargs['delta'] if 'delta' in kwargs else 1e-5
        spreproc = np.log(S + delta)
        if method == 'logstd':
            std = kwargs['std'] if 'std' in kwargs else np.nanstd(S, axis=0)
            params['std'] = std
            spreproc /= std
        elif method == 'logmean':
            mean = kwargs['mean'] if 'mean' in kwargs else np.nanmean(S, axis=0)
            params['mean'] = mean
            spreproc /= mean
    elif method=='exponent':
        exponents = kwargs['exponents'] if 'exponents' in kwargs else [0.5]
        if not isinstance(exponents, (list, tuple)):
            exponents = [exponents]
        spreproc = np.hstack([abs(S)**ee * np.sign(S) for ee in exponents])
    elif method=='linear':
        spreproc = S
    else:
        raise NotImplementedError("Other variants still WIP")
    # Does not seem necessary...
    params['n_channels'] = spreproc.shape[1]

    return spreproc, params


def normalize(S, method='zscore', crop=None, reduce_channels=None, valid_channels=None,
    **kwargs):
    """Normalize channels of a model. 

    Most commonly, z-score each channel, but other methods are available.
    
    Parameters
    ----------
    S : stimulus / preprocessed stimulus. Better be 2D (time x channels)
    method : string, one of the following: 
        'zscore' [default], 'gaussianize', 'uniform', '0to1', '-1to1' 
    reduce_channels : if scalar < 1, keep all channels with stds >
        params.reduce_channels * max std; if scalar > 1, keep n
        channels; if True, use following parameter as index to
        keep some channels. Default (None) does nothing.
    valid_channels : index of channels to keep
        (optional, only use if .reduce_channels==1)
    crop : 2-element vector [min,max] - crop values above/below
        max/min to max/min. Default (None) does nothing.
    
    Returns
    ------- 
    spreproc : array
        normalized stimulus
    params : dict
        dict of preprocessing params, potentially w/ 'mean', 'std' added (if
        normalize == 'zscore')
    
    """
    # Do we care about returning params...?
    params = dict(method=method,
                  crop=crop,
                  reduce_channels=reduce_channels,
                  **kwargs
                  ) 
    if S is None:
        return params

    # Normalize
    if method == 'zscore':
        spreproc, mean, std = norm_std_mean(S, **kwargs)
        params.update(mean = mean,
                      std = std)
    elif method == 'gaussianize':
        spreproc = np.zeros(S.shape)
        for ich in range(S.shape[1]):
            SppU = make_uniform(S[:,ich])
            spreproc[:,ich] = norminv(SppU)
    elif method == 'uniform':
        spreproc = zeros(size(S));
        for ich in range(S.shape[1]):
            spreproc[:,iCh] = make_uniform(S[:,iCh])
    elif method == '0to1':
        spreproc = S - S.min(axis=0)
        spreproc /= Sr.max(axis=0)
    elif method == '-1to1':
        spreproc = S / np.abs(S).max(axis=0)

    # Reduce the number of channels based on the standard deviation of channels, or
    # a pre-defined index (valid_channels) 
    if reduce_channels is not None:
        import warnings
        warnings.warn('Reducing channels is not well tested in re-implementation of code yet!')
        orig_nch = spreproc.shape[1]
        if valid_channels is None:
            if 'std' not in params:
                [_, std, mean] = norm_std_mean(spreproc);
            else:
                std = params['std']
            if reduce_channels < 1:
                maxstd = np.max(stds)
                valid_channels = find(stds >= maxstd*params.reduce_channels)
            else:
                d, s = np.sort(stds, 'descend');
                valid_channels = s[:np.min([len(s), params.reduce_channels])]
                valid_channels = np.sort(valid_channels)
            params['valid_channels'] = valid_channels
        spreproc = spreproc[:, valid_channels]
        # Consider adding back optional verbose output here re: how many channels 
        # have been cropped
    if crop is not None:
        spreproc = np.clip(spreproc, *crop)
    
    return spreproc, params


def downsample(S, method='box', input_hz=None, output_hz=None, 
                       frameshifts=None, **kwargs):
    """
    for method='gauss', specify sigma, units == ????? IDKWTF

    TODO: 
    implement scipy.interpolate methods for cubic / lanczos etc downsampling
    """
    params = dict(method = method,
                  input_hz = input_hz,
                  output_hz = output_hz,
                  frameshifts = frameshifts,
                  **kwargs
                  )
    if S is None:
        return params
    if input_hz is None or output_hz is None:
        raise ValueError("You must minimally specify `input_hz` and `output_hz` keyword args")
    fr_per_sample = int(input_hz / output_hz)
    if method == 'none':
        spreproc = S
    elif method in ('box','max','min'):
        if frameshifts is not None:
            raise NotImplementedError("frameshifts are still WIP")
            print('shifting %d frames...'%frameshifts)
            # FIX ME, this is non-functional old matlab-ish code
            S = circshift(S,[frameshifts, 0])
        tframes = S.shape[0] // fr_per_sample * fr_per_sample
        # Reshape to put samples over which to downsample along 2nd axis
        # (2nd, w/ 0-based indexing = 1)
        S = np.reshape(S[:tframes], (-1, fr_per_sample) + S.shape[1:])
        # Take mean, max, etc
        fn = dict(box=np.mean, max=np.max, min=np.min)[method]
        S = fn(S, axis=1)
    elif method == 'gauss':
        # Smooth and downsample
        sigma = kwargs['sigma'] if 'sigma' in kwargs else None
        sonset = kwargs['sonset'] if 'sonset' in kwargs else fr_per_sample//2
        if sigma is not None:
            ki = np.arange(-sigma*2.5, sigma*2.5, 1/fr_per_sample)
            k = np.exp(-ki**2 / (2 * sigma**2))
            S = conv2(S, k.T/sum(k), 'same')
        
        S = S[sonset::fr_per_sample, :]

    # Done
    return S, params

# Consider adding to downsample function above
# def downsample_uneven_frames(data, nframes=30):
#     n = data.shape[0]
#     extra_frames = n % nframes
#     print(extra_frames)
#     n = n // nframes * nframes
#     trs = vmt.utils.downsample(data[:n], nframes)
#     if extra_frames > 3:
#         trs = np.vstack([trs, np.mean(data[-extra_frames:], axis=0)])
#     return trs