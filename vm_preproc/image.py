# Functions that operate on images to produce other images

import numpy as np
import scipy.stats
import cv2
from skimage import color as skcol
from .utils import get_function

def convert_color(S, conversion='rgb2lab', keep_colors=False, **kwargs):
    """Wholescale color conversion of (x, y, c, t) arrays
    
    Generally intended to convert RGB images to luminance images. 
    Default conversion is to L*A*B colors space (discarding A and B
    channels). 

    Parameters
    ----------
    S : array
    	image stack, (frames, y, x, color)

    Notes
    -----
    Could probably use some more intelligent memory management

    """
    try:
        if conversion[:6] == 'COLOR_':
            cv_conversion = getattr(cv2, conversion)
            fn =  lambda im: cv2.cvtColor(im, cv_conversion)
        else:
            fn = getattr(skcol, conversion)
    except AttributeError:
        raise AttributeError('Unknown color function "%s" (not a function in skimage.color)'%conversion)
    if keep_colors:
        out = np.asarray([fn(s[..., :3], **kwargs) for s in S])
    else:
        out = np.asarray([fn(s[..., :3], **kwargs)[..., 0] for s in S])
    params = dict(conversion=conversion, keep_colors=keep_colors, **kwargs)
    return out, params

def image_skewness(S, ):
    """Compute skewness of image
    
    Parameters
    ----------
    S : array
        luminance image, time x vertical x horizontal
        for now, MUST be luminace image.
    """
    assert np.dim(S) == 3, 'Must be time x luminance image'
    n = S.shape[0]
    skewness = np.zeros((n,))
    for s in S:
        skewness[i] = scipy.stats.skewness(s.reshape(n, -1), axis=1)
    return skewness

def spatial_downsample(S,
                       dtype='same',
                       method='block_reduce',
                       flatten=True,
                       func_name='numpy.mean',
                       progress_bar=None,
                       **kwargs):
    """Spatially downsample an array of image frames"""
    if progress_bar is None:
        def progress_bar(x): return x
    if method == 'block_reduce':
        from skimage.measure import block_reduce
        func = get_function(func_name)
        if 'func' in kwargs:
            raise ValueError(
                'Please specify downsampling function with string `func_name` kwarg')
        if 'block_size' in kwargs:
            kwargs['block_size'] = tuple(kwargs['block_size'])
        out = block_reduce(S, func=func, **kwargs)
        if flatten:
            dim = np.prod(out.shape[1:])
            out = out.reshape(-1, dim)
    elif method == 'opencv':
        raise NotImplementedError('Not yet!')
        #out = np.asarray([cv2.resize()])
    else:
        raise ValueError('Unknown method "%s"' % method)
    return out

def compute_gradient(S, dimensions=(1, 2), return_type='magnitude', threshold=None):
    """Compute gradient of input array (image or stack of images)
    
    Defaults assume a stack of images with time as first dimension and take 
    gradients over next two dimensions (presumably, Y and X)

    Parameters
    ----------
    S : array
        input image, image stack, or other array
    dimensions : tuple, optional
        Axes over which to compute gradient, by default (1,2)
    return_type : str, optional
        'magnitude' or 'orientation', by default 'magnitude'
    threshold : None or scalar, optional
        threshold for gradient; if set, all gradients greater than this value 
        are set to 1, by default None

    Returns
    -------
    output
        gradient array, same size as input
    """
    # This is horrible but there's no good way to do this sort of check in numpy;
    # see https://github.com/numpy/numpy/issues/17325
    if not np.issubdtype(S.dtype, float):
        print('converting to float')
        S = S.astype(float)
    # Compute gradients
    gx, gy = np.gradient(S, axis=dimensions)
    if return_type == 'magnitude':
        out = np.sqrt(gx**2 + gy**2)
    elif return_type == 'orientation':
        out = np.arctan2(gx, gy)
    if threshold is not None:
        out = (out > threshold).astype(float)
    return out
