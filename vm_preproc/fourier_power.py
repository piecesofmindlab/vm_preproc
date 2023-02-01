# Code to compute average Fourier power in orientation x frequency bins

import numpy as np
import copy
from .utils import circ_dist


def compute_fourier_bins(data,
                         angle_bin_centers=(0, 45, 90, 135),
                         angle_bin_widths=(45, 45, 45, 45),
                         screen_degrees=20,
                         sf_bin_edges=(0, 5, 100000),
                         normalize_by_sf=False,
                         normalize_by_image='L2',
                         keep_contrast_channel=True):
    """Computes binned Fourier transform of a stimulus

    Parameters
    ----------
    data : array-like
    
    angle_bin_centers : array-like, optional
        orientation centers of bins, in degrees, by default (0, 45, 90, 135)
    angle_bin_widths : array-like, optional
        widths of orientation bins in degrees, by default (45, 45, 45, 45)
    screen_degrees : float, optional
        visual degree span of screen, by default 20
    sf_bin_edges : array-like, optional
        bin edges for spatial frequency bins; last bin is large 
        to indicate up to (max), by default (0, 5, 100000)
    normalize_by_sf : bool, optional
        whether to normalize each image by (IDK what), by default False
    normalize_by_image : str, optional
        how to normalize each image, by default 'L2'
    keep_contrast_channel : bool, optional
        whether to keep a channel for overall image contrast, by default True

    Returns
    -------
    array
        processed stimulus, (n_frames x n_features)

    Raises
    ------
    ValueError
        _description_
    """    

    aa, ssff = np.meshgrid(angle_bin_centers, sf_bin_edges[:-1])
    bin_params = np.vstack([aa.flatten(), ssff.flatten()]).T

    # For visualization...
    make_bin_image = True

    # Set up bins in Fourier space
    n_frames, y, x = data.shape
    # Compute pixels per degree for this size image
    if x != y:
        raise ValueError("Can't handle non-square images yet!")

    fx = np.arange(-x / 2, (x / 2))
    fy = np.arange(-y / 2, (y / 2))
    xg, yg = np.meshgrid(fx, fy)
    theta = np.arctan2(xg, yg)
    rho = (xg**2 + yg**2)**0.5
    # Convert rho from cycles per image to cycles per degree
    rho /= (screen_degrees / 2)
    # Mirror top / bottom of image (for symmetrical parts of fft)
    theta[theta > 0] = np.pi - theta[theta > 0]  # was 180 - ...
    # Rotate 90 degrees so 0 degrees corresponds to horizontal orientations in Fourier space
    #theta = abs(imrotate(theta, 90))
    theta = np.abs(theta.T)
    #return rho, theta

    # Fourier transform of stimulus
    #s_ff = sqrt(abs(fft2(data)));
    s_ff = np.sqrt(np.abs(np.fft.fft2(data)))
    s_ff = np.fft.fftshift(s_ff, axes=[-2, -1])

    # Get DC
    centerx = int(np.floor(x / 2) + 1)
    centery = int(np.floor(y / 2) + 1)
    dc = s_ff[:, centery, centerx]
    # Mask out DC
    #s_ff[centery, centerx, :] = np.nan
    #s_ff = reshape(s_ff,[],N);
    s_ff = s_ff.reshape(n_frames, -1)  # unclear if this does the thing.

    if normalize_by_image is not False:
        if normalize_by_image == 'zscore':
            gm = np.nanmean(s_ff, axis=1)
            gs = np.nanstd(s_ff, axis=1)
            s_ff -= gm
            # Avoid /0
            gs[gs == 0] = np.inf
            s_ff /= gs
            contrast = gm
        elif normalize_by_image == 'L2':
            L2 = np.nansum(s_ff**2, axis=1)**0.5
            L2n = copy.copy(L2)
            # Avoid /0
            L2n[L2n == 0] = np.inf
            s_ff /= L2n[:, None]
            contrast = L2
        elif normalize_by_image == 'L1':
            L1 = np.nanmax(s_ff, axis=1)
            L1n = copy.copy(L1)
            # Avoid /0
            L1n[L1n == 0] = inf
            s_ff /= L1n
            contrast = L1
        elif normalize_by_image == 'demean':
            gm = np.nanmean(s_ff, axis=1)
            s_ff -= gm
            contrast = gm
    # Preallocate output
    output = np.zeros(
        (n_frames, len(angle_bin_centers), len(sf_bin_edges) - 1))
    # For visualization
    if make_bin_image:
        bin_image = np.zeros(data.shape[1:])

    ct = 1
    # Loop over orientation / SF bins
    for i, (bin_angle, bin_width) in enumerate(zip(angle_bin_centers, angle_bin_widths)):
        angle_index = np.abs(circ_dist(theta, np.radians(bin_angle))) <= (
            np.radians(bin_width) / 2)
        for j, (sfmin, sfmax) in enumerate(zip(sf_bin_edges[:-1], sf_bin_edges[1:])):
            sf_index = (rho >= sfmin) & (rho < sfmax)
            idx = angle_index & sf_index
            tmp = s_ff[:, idx.flatten()]
            output[:, i, j] = np.nanmean(tmp, axis=1)
            # For display
            if make_bin_image:
                bin_image[idx] = ct
                ct += 1

    # Reshape output
    output = output.reshape(n_frames, -1)
    # Spatial frequency normalization
    if normalize_by_sf:
        for isf in range(len(sf_bin_edges) - 1):
            sf = sf_bin_edges[isf]
            idx = params.bin_params[2, :] == sf
            # divide by L2 norm for each spaital frequency
            n = np.sqrt(np.sum(output[:, idx]**2, axis=1))
            output[:, idx] /= n

    if keep_contrast_channel:
        output = np.hstack([contrast[:, np.newaxis], output])

    params = dict(angle_bin_centers=angle_bin_centers,
                  angle_bin_widths=angle_bin_widths,
                  keep_contrast_channel=keep_contrast_channel,
                  sf_bin_edges=sf_bin_edges,
                  normalize_by_sf=normalize_by_sf,
                  normalize_by_image=normalize_by_image,
                  )
    if make_bin_image:
        params['bin_image'] = bin_image
    # Output
    return output, params
