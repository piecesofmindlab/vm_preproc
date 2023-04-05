"""Gist feature computation

Based on Oliva & Torralba, 

also on this implementation of same algorithm:

https://github.com/Kalafinaian/python-img_gist_feature/tree/master/img_gist_feature


"""

import numpy as np
from skimage.measure import block_reduce
import matplotlib.pyplot as plt
from matplotlib import cm, colors, transforms
from matplotlib.collections import LineCollection
from matplotlib.colors import Normalize
#import tqdm
import cv2


def compute_gist(S, 
    image_size=None, 
    orientations_per_scale=(8,8,8,8),
    number_blocks=4,
    fc_prefilt=4,
    fc_boundary_extension=5,
    boundary_extension=None,
    downsample_fn='mean'):
    #progress_bar=tqdm.tqdm):
    """ compute gist features a la Oliva & Torralba 2001

    Preprocess image stack with gist model. Based on A. Oliva & A. Torralba's
    LMgist code (WEB SITE), see references below

    Parameters
    ----------
    S : 3D image matrix (time, x, y)
        Stack of images to be processed, should be luminance images
    image_size : None
        Size to which to resize images; if None, no resizing
    orientations_per_scale : list or tuple
        Number of orientation at each scale. Scales are determined by...
        what, again?
    number_blocks : int
        Number of blocks on each side into which to downsample the image; 
        i.e. 4 yeilds a 4 x 4 grid of block downsampling
    fc_prefilt : int
        frequency cutoff for pre-filtering (low frequencies below this
        number of cycles per image are removed prior to gist Gabor filtering)
    boundary_extension : int
        number of pixels to pad before computing Fourier transform. If None, 
        defaults to 1/16 of `image_size` (for 512 px images, 32 px padding)

    Returns
    -------

    Notes
    -----

    References
    ----------
    Modeling the shape of the scene: a holistic representation of the spatial envelope
    Aude Oliva, Antonio Torralba
    International Journal of Computer Vision, Vol. 42(3): 145-175, 2001.
    
    Much copying from:
    https://github.com/Kalafinaian/python-img_gist_feature/tree/master/img_gist_feature
    ... with much reorganization.
    """

    # resize and crop image to make it square
    if image_size is None:
        image_size = S.shape[1:3]
        img = S
    else:
        # TO DO.
        img = imresizecrop(S, image_size, 'bilinear')

    if boundary_extension is None:
        # Default to 1/16 of image size
        boundary_extension = image_size[0] // 16

    ds_fn = getattr(np, downsample_fn)
    
    # Note that image must be odd in dimensions for fft filtering to work
    # correctly.
    image_size_pad = image_size[0] + 2 * boundary_extension + image_size[0] % 2
    # Define Gabors
    gist_gabors = create_gabor(orientations_per_scale, image_size_pad)

    # scale intensities to be in the range [0 255]
    #img -= img.min()
    #img = 255 * img / img.max()
    # Better: for each image (OOPS should have done this for earlier papers)
    img -= img.min(-1).min(-1)[:,np.newaxis, np.newaxis]
    img = 255 * img / img.max(-1).max(-1)[:, np.newaxis, np.newaxis]
    # prefiltering: local contrast scaling
    print('filtering out low spatial frequencies...')
    output = prefilt(img, fc_prefilt, pad_pixels=fc_boundary_extension)
    # compute gist:
    print('computing gist features...')
    output = gist_gabor(output, boundary_extension, gist_gabors, number_blocks, downsample_fn=ds_fn)
    params = dict(
        orientations_per_scale=orientations_per_scale,
        boundary_extension=boundary_extension,
        fc_boundary_extension=fc_boundary_extension,
        number_blocks=number_blocks,
        downsample_fn=downsample_fn,
        )
    return output, params


def prefilt(img, fc_prefilt=4, pad_pixels=5):
    """Summary
    
    Parameters
    ----------
    img : array
        image stack to be pre-filtered
    fc_prefilt : int, optional
        Description
    pad_pixels : int, optional
        Number of pixels with which to pad the image on each side
        before taking Fourier transform
    
    Returns
    -------
    array
        filtered image stack
    """
    image_size_orig, _, n_frames = img.shape
    log_img = np.log(img + 1.0)
    pad_img = np.pad(log_img, ((0, 0), (pad_pixels, pad_pixels), (pad_pixels, pad_pixels)), 'symmetric')
    n_frames, _, image_size_pad = pad_img.shape
    # This defines the standard deviation of the Gaussian function below
    low_freq_sigma = fc_prefilt / np.sqrt(np.log(2))
    # Create filter (`gf`) for .... local contrast? 
    t = np.linspace(-image_size_pad // 2, image_size_pad // 2 - 1, image_size_pad)
    np_fx, np_fy = np.meshgrid(t, t)
    # Exponential function - a Gaussian - with standard deviation `low_freq_sigma`
    low_freq_gauss = np.fft.fftshift(np.exp( -(np_fx **2 + np_fy **2) / (low_freq_sigma ** 2)))
    # Approximation to whitening: removing low frequencies
    out = pad_img - np.real(np.fft.ifft2(np.fft.fft2(pad_img) * low_freq_gauss))
    # Local contrast normalization
    local = np.sqrt(np.abs(np.fft.ifft2(np.fft.fft2(out ** 2) * low_freq_gauss)))
    # What is this 0.2? 
    out = out / (0.2 + local)
    # Crop output to have same size as the input
    out = out[:, pad_pixels: image_size_pad - pad_pixels, pad_pixels : image_size_pad - pad_pixels]
    return out


def gist_gabor(img, pad_pixels, gist_gabors, number_blocks, downsample_fn=np.mean):
    """Summary
    
    Parameters
    ----------
    pad_pixels : TYPE
        Description
    gist_gabors : TYPE
        Description
    
    Returns
    -------
    TYPE
        Description
    """
    # Pad image
    n_frames, image_size, _ = img.shape
    img_padded = np.pad(img, 
        ((0, 0), (pad_pixels, pad_pixels), (pad_pixels, pad_pixels)), 
        'symmetric')
    # Take Fourier transform of image
    img_fft = np.fft.fft2(img_padded)
    # Assumes symmetric (square)    
    image_size_pad, _, n_filter = gist_gabors.shape
    nb = number_blocks**2 # n blocks
    n_features = n_filter * nb
    gist_features = np.zeros((n_frames, n_features), dtype=np.float32)
    for i in range(n_filter):
        np_res = np.abs(np.fft.ifft2(img_fft * gist_gabors[:,:,i]))
        # Clip padding
        np_res = np_res[:, pad_pixels:-pad_pixels, pad_pixels:-pad_pixels]
        #print(np_res.shape)
        # Downsample by blocks; assume square for now
        block_size = image_size / number_blocks
        if block_size % 1 != 0:
            raise ValueError('Image size does not divide evenly into %d blocks!'%number_blocks)
        block_size = int(block_size)
        #print(block_size)
        gist_ft = block_reduce(np_res, (1, block_size, block_size), func=downsample_fn)
        gist_features[:,i*nb:(i+1)*nb] = gist_ft.reshape(-1, nb)
    
    return gist_features


def create_gabor(orientations_per_scale, gabor_size):
    """Summary
    
    Parameters
    ----------
    orientations_per_scale : TYPE
        Description
    gabor_size : TYPE
        Description
    
    Returns
    -------
    array
        array of filters in Fourier space at different sizes 
        and orientations
    """
    ori_per_sc = orientations_per_scale
    
    n_scales = len(ori_per_sc)
    n_filters = sum(ori_per_sc)
    
    gabor_params = np.zeros((n_filters, 4), dtype = np.float64)
    iparam = 0
    for i in range(n_scales):
        for j in range(0, ori_per_sc[i]):
            gabor_params[iparam, 0] = 0.35
            gabor_params[iparam, 1] = 0.3 / (1.85**i)
            gabor_params[iparam, 2] = 16 *(ori_per_sc[i]**2) / (32**2)
            gabor_params[iparam, 3] = np.pi / ori_per_sc[i] * j
            
            iparam += 1
    
    t = np.linspace(-gabor_size // 2, gabor_size // 2 - 1, gabor_size)
    np_fx, np_fy = np.meshgrid(t, t)
    np_res_A = np.fft.fftshift(np.sqrt(np_fx ** 2 + np_fy**2))
    np_res_B = np.fft.fftshift(np.angle(np_fx + 1j * np_fy))
    
    gist_gabors = np.zeros((gabor_size, gabor_size, n_filters), dtype = np.float64)
    for i in range(n_filters):
        np_tr = np_res_B + gabor_params[i,3]
        np_A  = (np_tr < -np.pi) + 0.0
        np_B  = (np_tr > np.pi) + 0.0
        
        np_tr = np_tr + 2 *np.pi * np_A - 2*np.pi*np_B
        np_every_gabor = np.exp(-10 * gabor_params[i,0] * ((np_res_A / gabor_size /gabor_params[i,1] - 1) **2) - 2*gabor_params[i,2]*np.pi*(np_tr **2))
        
        gist_gabors[:,:,i] = np_every_gabor

    return gist_gabors


## Hmmm - resizing...
def img_resize(np_img_in, ln_resize, run_log=None, b_print=False):
    try:
        np_img_resize = cv2.resize(np_img_in, ln_resize, fx=0.5, fy=0.5, interpolation=cv2.INTER_AREA)
        return np_img_resize, 0
    except Exception as e:
        s_msg = 'resize err:%s' % str(e)
        run_log and run_log.error(s_msg)
        b_print and print(s_msg)
        return None, -3

def show_gist(gist_vec, n_oris=8, n_scales=4, n_loc=4, im=None, vmin=None, vmax=None, 
              figsize=(7, 7), cmap=plt.cm.viridis, ax=None):
    """Show gist features for a given gist vector
    
    Parameters"""
    n_lines_per_scale = np.round(np.linspace(11, 1, n_scales)).astype(np.int) # [11, 7, 3, 1]
    lw_per_scale = np.linspace(0.3, 10.0, n_scales)
    delta = (1. / n_loc) /2.
    dd = delta / np.sqrt(2)
    oris = np.linspace(np.pi/2, 1.5*np.pi, n_oris, endpoint=False)
    xlocs = np.linspace(1./n_loc, 1, n_loc) - delta
    ylocs = np.linspace(1./n_loc, 1, n_loc) - delta
    ylocs = ylocs[::-1]
    #print(ylocs)
    if vmin is None:
        vmin = gist_vec.min()
    if vmax is None:
        vmax = gist_vec.max()
    nrm = Normalize(vmin=vmin, vmax=vmax, clip=True)
    gv = nrm(gist_vec)
    colors = []
    edges = []
    linewidths = []
    # Define figure
    if ax is None:
        fig, ax = plt.subplots(figsize=figsize)
    if im is not None:
        ax.imshow(im, extent=[0, 1, 0, 1])
    i = 0
    # Scales
    for n_lines, lw in zip(n_lines_per_scale, lw_per_scale):
        # Orientations
        for ori in oris:
            # Positions
            for yloc in ylocs:
                for xloc in xlocs:
                    # Define a set of vertical lines
                    x = np.array([[-delta, delta]] * n_lines)
                    x /= np.sqrt(2.0)
                    if n_lines > 1:
                        y = np.array([np.linspace(-delta, delta, n_lines)]*2).T
                    else:
                        y = np.array([[0., 0.]])
                    y /= np.sqrt(2.0)
                    base = ax.transData
                    rot = transforms.Affine2D()
                    rot.rotate(ori)
                    rot.translate(xloc, yloc)
                    xy = np.vstack([x.flatten(), y.flatten()]).T
                    xyt = rot.transform_affine(xy)
                    xt, yt = xyt.T
                    xt = np.reshape(xt, (n_lines, 2))
                    yt = np.reshape(yt, (n_lines, 2))
                    edges_ = [list(zip(x_, y_)) for x_, y_ in zip(xt,  yt)]
                    lw_ = [lw]*n_lines
                    a = np.array([gv[i]]*n_lines)
                    colors_ = cmap(a)
                    #if colors_.shape[1] < 4:
                    #    colors_ = np.hstack([colors_, np.ones((colors.shape[0], )) * gv[i]])
                    if vmin==-vmax:
                        # assume absolute scale
                        alpha = (np.abs(gv[i]-0.5) * 2)**2
                    else:
                        alpha = gv[i]**2   
                    colors_[:, 3] = np.ones((colors_.shape[0], )) * alpha
                    colors.append(colors_)
                    edges += edges_
                    linewidths += (lw_)
                    i += 1
    colors = np.vstack(colors)
    lc = LineCollection(edges, colors=colors, linewidth=linewidths) #[tuple(c) for c in colors])
    ax.add_collection(lc)
    ax.set_xlim([0, 1])
    ax.set_ylim([0, 1])