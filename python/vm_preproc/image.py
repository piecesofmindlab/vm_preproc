# Functions that operate on images to produce other images

import numpy as np
from skimage import color as skcol

def convert_color(S, conversion='rgb2lab', keep_colors=False, progress_bar=None, **kwargs):
    """Wholescale color conversion of (x, y, c, t) arrays
    
    Generally intended to convert RGB images to luminance images. 
    Default conversion is to L*A*B colors space (discarding A and B
    channels). 

    Parameters
    ----------
    S : array
    	image stack, (frames, y, x, color)
    progress_bar : tqdm instance
        not yet functional; code needs rewrite to implement
        a useful progress bar
        
    Notes
    -----
    Could probably use some more intelligent memory management

    """
    try:
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