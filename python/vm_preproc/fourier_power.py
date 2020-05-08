# Code to compute average Fourier power in orientation x frequency bins

import numpy as np
import copy
from vm_preproc.utils import circ_dist


def compute_fourier_bins(data, angle_bin_centers=(0, 45, 90, 135), angle_bin_widths=(45, 45, 45, 45), screen_degrees=20, 
    sf_bin_edges=(0, 5, 100000), normalize_by_sf=False, normalize_by_image='L2', keep_contrast_channel=True):
    """
    Fourier transform of a stimulus, plus assignment of Fourier magnitude
    into particular spatial frequency bins

    Parameters
    ----------
    data : 3D array, (x,y,frames)
      Stimulus to be preprocessed. Take care of color before coming here,
      please.
    params : struct array of parameters, with fields:
      .(see code)

    Returns 
    -------
    Spreproc : Preprocessed stimulus
    params : filled-out param struct
    """

    aa, ssff = np.meshgrid(angle_bin_centers, sf_bin_edges[:-1])
    #params.bin_params = [aa(:),ssff(:)]';
    bin_params = np.vstack([aa.flatten(), ssff.flatten()]).T

    # For visualization...
    make_bin_image = True

    # Helper function for orientation bins
    #circ_dist = @(a,b,mx) min(abs(a-b),mx-abs(a-b));

    # Set up bins in Fourier space
    y, x, N = data.shape
    # Compute pixels per degree for this size image
    if x != y:
        raise ValueError("Can't handle non-square images yet!")

    #fx = -x/2:(x/2-1);
    fx = np.arange(-x / 2, (x / 2))
    #fy = -y/2:(y/2-1);
    fy = np.arange(-y / 2, (y / 2))
    X, Y = np.meshgrid(fx, fy)
    X = X.T # matlab vs python meshgrid seem different...
    Y = Y.T
    theta = np.arctan2(X, Y)
    rho = (X**2 + Y**2)**0.5
    #theta, rho = cart2pol(X, Y)
    # Convert rho from cycles per image to cycles per degree
    rho /= screen_degrees
    #theta = np.degrees(theta) # stick with radians - see below
    # Mirror top / bottom of image (for symmetrical parts of fft)
    theta[theta>0] = np.pi - theta[theta>0] # was 180 - ... 
    # Rotate 90 degrees so 0 degrees corresponds to horizontal orientations in Fourier space
    #theta = abs(imrotate(theta, 90))
    theta = np.abs(theta.T[::-1])

    # Fourier transform of stimulus
    #Sf = sqrt(abs(fft2(data)));
    Sf = np.sqrt(np.abs(np.fft.fft2(data)))
    # Lame; must be a better way to do this...
    for ii in range(N): #= 1:N:
        Sf[:,:,ii] = np.fft.fftshift(Sf[:,:,ii])

    # Get DC
    centerx = int(np.floor(x / 2) + 1)
    centery = int(np.floor(y / 2) + 1)
    dc = Sf[centery,centerx,:]
    # Mask out DC
    #Sf[centery, centerx, :] = np.nan
    #Sf = reshape(Sf,[],N);
    Sf = Sf.reshape(-1, N) # unclear if this does the thing.

    if normalize_by_image is not False:
        if normalize_by_image == 'zscore':
            gm = np.nanmean(Sf, axis=0)
            gs = np.nanstd(Sf, axis=0)
            Sf -= gm
            # Avoid /0
            gs[gs==0] = np.inf 
            Sf /= gs
            contrast = gm
        elif normalize_by_image == 'L2':
            L2 = np.nansum(Sf**2, axis=0)**0.5
            L2n = copy.copy(L2)
            # Avoid /0
            L2n[L2n==0] = np.inf 
            Sf /= L2n
            contrast = L2
        elif normalize_by_image == 'L1':
            L1 = np.nanmax(Sf, axis=0);
            L1n = copy.copy(L1)
            # Avoid /0
            L1n[L1n==0] = inf 
            Sf /= L1n
            contrast = L1
        elif normalize_by_image == 'demean':
            gm = np.nanmean(Sf, axis=0);
            Sf -= gm
            contrast = gm
    # Preallocate Spreproc
    Spreproc = np.zeros((N, len(angle_bin_centers), len(sf_bin_edges) - 1))
    # For visualization
    if make_bin_image:
        bin_image = np.zeros(data.shape[:2])

    ct = 1;
    # Loop over orientation / SF bins
    #for iOri = 1:size(params.angle_bins,1)
    for i, (bin_angle, bin_width) in enumerate(zip(angle_bin_centers, angle_bin_widths)):
        #omin = params.angle_bins(iOri,1);
        #omax = params.angle_bins(iOri,2);
        #if params.angle_bin_centers
        #aidx = circ_dist(theta, omin, 180) <= omax / 2;
        aidx = circ_dist(theta, np.radians(bin_angle)) <= (np.radians(bin_width) / 2)
        #else
        #    aidx = theta>=omin & theta<omax;
        #end
        #for iSF=1:size(params.sfreq_bins,1)
        for j, (sfmin, sfmax) in enumerate(zip(sf_bin_edges[:-1], sf_bin_edges[1:])): 
            #sfmin = params.sfreq_bins(iSF,1);
            #sfmax = params.sfreq_bins(iSF,2);
            sfidx = (rho >= sfmin) & (rho < sfmax)
            Idx = aidx & sfidx
            #tmp = Sf(Idx(:),:);
            tmp = Sf[Idx.flatten(),:]
            Spreproc[:, i, j] = np.nanmean(tmp, axis=0) #-gm;
            # For display
            if make_bin_image:
                bin_image[Idx] = ct
                ct = ct+1;

    # Reshape Spreproc
    Spreproc = Spreproc.reshape(N, -1) #reshape(Spreproc,N,[]);
    if normalize_by_sf:
        for isf in range(len(sf_bin_edges) - 1): #= 1:size(params.sfreq_bins,1)
            #sf = params.sfreq_bins(isf,1);
            sf = sf_bin_edges[isf]
            #idx = params.bin_params(2,:)==sf;
            idx = params.bin_params[2,:]==sf
            # divide by L2 norm for each spaital frequency
            n = np.sqrt(np.sum(Spreproc[:,idx]**2, axis=1))
            Spreproc[:,idx] /= n

    if keep_contrast_channel:
        Spreproc = np.hstack([contrast[:, np.newaxis], Spreproc])

    params = dict(angle_bin_centers=angle_bin_centers,
                  angle_bin_widths=angle_bin_widths,
                  keep_contrast_channel=keep_contrast_channel,
                  sf_bin_edges=sf_bin_edges,
                  normalize_by_sf=normalize_by_sf, 
                  normalize_by_image=normalize_by_image, 
                  )
    # Output
    return Spreproc, params