# Functions that operate on images to produce other images

import numpy as np
import scipy.stats
import cv2
from skimage import color as skcol

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

def spatial_downsample(S, factor, dtype='same'):
	raise NotImplementedError('Not yet!')

def image_skewness(S, ):
    """Compute skewness of image
    
    Parameters
    ----------
    S : array
        luminance image, time x vertical x horizontal
        for now, MUST be luminace image.
    """
    assert np.dim(S) == 3 else 'Must be time x luminance image'
    n = S.shape[0]
    skewness = np.zeros((n,))
    for s in S:
        skewness[i] = scipy.stats.skewness(s.reshape(n, -1), axis=1)
    return skewness
