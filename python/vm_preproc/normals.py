# Compute 3D scene structure features as in Lescroart & Gallant 2017

def compute_normal_gradient(normals, nonlinexp=1):
    """Computes distances between normals in a pixelwise normal image.

    Differences between normal vectors are expressed as the average of the
    cosines of the angles between normals of adjacent pixels. X and Y
    directional gradients are computed, in a way analogous to the HoG
    (histogram of gradients) algorithm, but this function subtracts the full
    3D-vectors instead of 1-D pixel values. 

    Parameters
    ----------
    normals : 

    nonlinexp : scalar
        Raise whole image to this power (to adjust contrast)
    """

    # X derivative 
    norms_left = normals[:, :-2, :] 
    norms_center = normals[:, 1:-1, :] 
    norms_right = normals[:, 2:, :] 
    dx1 = np.arccos(np.sum(norms_left * norms_center, axis=2))
    dx2 = np.arccos(np.sum(norms_right * norms_center, axis=2))
    # Y derivative. 
    norms_top = normals[:-2, :, :]
    norms_middle = normals[1:-1, :, :]
    norms_bottom = normals[2:, :, :]
    dy1 = np.arccos(np.sum(norms_top * norms_middle, axis=2))
    dy2 = np.arccos(np.sum(norms_bottom * norms_middle, axis=2))
    # Take average of two gradients (e.g. center-left/center-right)
    x_grad = np.real(np.pad((dx1 + dx2) / 2, [(0, 0), (1, 1)], 'edge'))
    y_grad = np.real(np.pad((dy1 + dy2) / 2, [(1, 1), (0, 0)], 'edge'))
    # Compute magnitude and orientation of gradients
    grad_mag = x_grad**2 + y_grad**2
    grad_ori = np.arctan2(y_grad, x_grad)

    return grad_mag, grad_ori



# 4 in-plane axes:
# 4 45 deg. cube corners
# straight-ahead
# NOTE! It is not a terribly easy problem to place equi-distant points
# around a sphere or half-sphere. See:
# http://www.math.niu.edu/~rusin/known-math/95/sphere.faq
# ...for potential improvements in selecting normal bin centers
# All are x, y, z vectors; +Y is up, +Z is toward viewer
NORM_BIN_CENTERS = np.array([[-1, 0, 0],  # Cardinal directions
                             [0, 1, 0],
                             [1, 0, 0],
                             [0, -1, 0],
                             [-1, -1, 1],  # Oblique directions
                             [-1, 1, 1],
                             [1, 1, 1],
                             [1, -1, 1],
                             [0, 0, 1]])  # Straight ahead
# The following value for DIST_BIN_EDGES comes out to:
# (0,1.0000, 3.1623, 10.0000, 31.6228,np.inf), which is a reasonable
# division of space
# Note that the depth divisions will depend on the depth input. If absolute
# depth is used, this scaling makes sense. If some measure of relative
# depth in the scene is used, this makes much less sense (unless that
# relative depth is scaled 0-100 or some such)
N_BINS_DIST = 10
DIST_BIN_EDGES = np.logspace(np.log10(1), np.log10(100), N_BINS_DIST)
DIST_BIN_EDGES = np.hstack([0, DIST_BIN_EDGES(:-1), np.inf])


def compute_distance_orientation_bins(normals,
                                      distance,
                                      camera_vector=None,
                                      norm_bin_centers=NORM_BIN_CENTERS,
                                      dist_bin_edges=DIST_BIN_EDGES,
                                      sky_channel=True,
                                      remove_camera_rotation=False,
                                      assure_normals_equal_1=True,
                                      pixel_norm=False,
                                      dist_normalize=False,  # set to True?
                                      n_bins_x=1,
                                      n_bins_y=1,
                                      ori_norm=2,  # set to 2 for legacy code 1 is actually preferred. Will change this default later.
                                      ):
    """Compute % of pixels in specified distance & orientation bins

    Preprocessing for normal & depth map images to compute scene features
    for Lescroart & Gallant, 2018

    Parameters
    ----------
    sky_channel: bool
      If true, include a separate channel for sky (all depth values above max
      value in dist_bin_edges)

    remove_camera_rotation: bool or array of bools
        whether to remove X, Y, or Z rotation of camera. Defaults to False
        (do nothing to any rotation)

    ori_norm: scalar
        How to normalize norms (??): 1 = L1 (max), 2 = L2 (Euclidean)
    """
    bins_x = np.linspace(0, 1, n_bins_x+1)
    bins_x[-1] = np.inf
    bins_y = np.linspace(0, 1, n_bins_y+1)
    bins_y[-1] = np.inf

    # Computed parameters
    n_norm_bins = norm_bin_centers.shape[0]
    n_dist_bins = dist_bin_edges.shape[0] - 1
    # Normalize bin vectors
    L2norm = np.linalg.norm(norm_bin_centers, axis=1, ord=2)
    norm_bin_centers = norm_bin_centers / L2norm

    # Note, that the bin width for these bins will not be well-defined (or,
    # will not be uniform). For now, take the average min angle between bins
    if n_norm_bins == 1:
        # Normals can't deviate by more than 90 deg (unless they're un-
        # rotated) BUT: We don't actually want to soft bin if there is only one
        # normal, we want to assign ALL pixels EQUALLY to the ONE BIN.
        # Thus d = np.inf
        d = np.inf
    else:
        # Soft-bin normals
        d = np.arccos(norm_bin_centers.dot(norm_bin_centers.T))
        d[np.abs(d) < 0.00001] = np.nan
    norm_bin_width = np.mean(np.nanmin(d))
    # Add an extra buffer to this? We don't want "stray" pixels with normals
    # that don't fall into any bin (but we also don't want to double-count
    # pixels)

    print('Done with stim file set-up: check!')
    # Optionaly remove any camera rotations
    if remove_camera_rotation is False:
        remove_camera_rotation = np.array([False, False, False])
    if np.any(remove_camera_rotation):
        # Dis is not work for now
        normals = preprocRmRotNormals(normals,
                                      -camera_angles,
                                      is_normalize_normals=is_normalize_normals,
                                      wut=remove_camera_rotation)
    # Get number of images
    x, y, n_ims = distance.shape
    n_tiles = n_bins_y * n_bins_x
    n_dims = n_tiles * n_dist_bins * n_norm_bins
    if sky_channel:
        n_dims = n_dims + n_tiles
    else:
        n_dims = n_tiles * n_dist_bins * n_norm_bins

    output = np.zeros((n_ims, n_dims)) * np.nan
    for iS in range(n_ims):
        # if n_ims>200:
        #     progressdot(iS,200,2000,n_ims)
        # elif (n_ims < 200) and (n_ims > 1):
        #     disp('computing Scene Depth Normals...')
        # Pull single image for preprocessing
        z = distance[..., iS]  #S.(zVar)(:,:,iS)
        n = normals[..., iS]  # S.Normals(:,:,:,iS)
        height, width, nd = n.shape
        xx, yy = np.meshgrid(np.linspace(0, 1, width), np.linspace(0, 1, height))
        idx = np.arange(n_norm_bins)
        for d_st, d_fin in zip(dist_bin_edges[:-1], dist_bin_edges[1:]):
            dIdx = (z >= d_st) & (z < d_fin)
            for ix in range(n_bins_x):
                hIdx = (xx >= bins_x(ix)) & (xx < bins_x(ix+1))
                for iy in range(n_bins_y):
                    vIdx = (yy >= bins_y[iy]) & (yy < bins_y[iy + 1])
                    this_section = (dIdx & hIdx) & vIdx
                    pct_pix_this_depth = np.mean(this_section)
                    if n_norm_bins > 1:
                        nn = n[this_section, :]
                        # Compute orientation of pixelwise surface normals relative
                        # to all normal bins
                        o = nn.dot(norm_bin_centers.T)
                        #L2nn = np.linalg.norm(nn, axis=1, ord=2)
                        #o = bsxfun(@rdivide,o,Lb) # Norm of norm_bin_centers should be 1
                        o /= np.linalg.norm(nn, axis=1, ord=2)
                        if np.max(o-1) > 0.0001:
                            raise Exception('The magnitude of one of your normal bin vectors crossed with a stimulus normal is > 1 - Check on your stimulus / normal vectors!')
                        # Get rid of values barely > 1 to prevent imaginary output
                        o = np.minimum(o, 1)  
                        angles = np.arccos(o)
                        # The following is a "soft" histogramming of normals.
                        # i.e., if a given normal falls partway between two
                        # normal bins, it is partially assigned to each of the
                        # nearest bins (not exclusively to one).
                        tmp_out = np.maximum(0, norm_bin_width - angles) / norm_bin_width
                        # Sum over all pixels w/ depth in this range
                        tmp_out = np.sum(tmp_out, axis=0)
                        # Normalize across different normal orientation bins
                        tmp_out = tmp_out / np.linalg.norm(tmp_out, ord=ori_norm)
                        if pixel_norm:
                            tmp_out = tmp_out * len(nn)/len(dIdx.flatten())
                    else:
                        # Special case: one single normal bin
                        # compute the fraction of screen pixels in this screen
                        # tile at this depth
                        tmp_out = pct_pix_this_depth
                    # Illegal for more than two bins of normals within the same
                    # depth / horiz/vert tile to be == 1
                    if sum(tmp_out == 1) > 1:
                        error('Found two separate normal bins equal to 1 - that should be impossible!')
                    if dist_normalize and not (n_norm_bins == 1):
                        # normalize normals by n pixels at this depth/screen tile
                        tmp_out = tmp_out * pct_pix_this_depth
                    output[iS, idx] = tmp_out
                    idx += n_norm_bins
        # Do sky channel(s) after last depth channel, add (n tiles) sky channels
        if sky_channel and (np.max(dist_bin_edges) < np.inf):
            dSky = z >= dist_bin_edges(-1)
            skyidx = np.arange((n_dims - n_tiles + 1), n_dims)
            tmp = np.zeros(n_bins_y, n_bins_x)
            for x_st, x_fin in zip(bins_x[:-1], bins_x[1:]):
                hIdx = (xx >= x_st) & (xx < x_fin)
                for y_st, y_fin in zip(bins_y[:-1], bins_y[1:]):
                    vIdx = (yy >= y_st) & (yy < y_fin)
                    tmp[iy, ix] = np.mean(dSky & hIdx & vIdx)
            output[iS, skyidx] = tmp.flatten()

    # Cleanup
    output[np.isnan(output)] = 0
    params = dict()  # Fill me
    return output, params

