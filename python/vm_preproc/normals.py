# Compute 3D scene structure features as in Lescroart & Gallant 2017

import numpy as np
import matplotlib.pyplot as plt

from matplotlib import cm,colors
from matplotlib import transforms as mtransforms
from matplotlib.patches import FancyBboxPatch
from matplotlib.collections import LineCollection
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

from skimage import color as skcol
try:
    import cv2 as cv
except:
    print("cv2 import failed; attempting to import cv3!")
    import cv3 as cv
from . import utils 

# Colormap(s)
from matplotlib.colors import LinearSegmentedColormap
RET = LinearSegmentedColormap.from_list('RET', 
        [(1, 0, 0), (1., 1., 0), (0, 0, 1), (0, 1., 1), (1., 0, 0)])


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


# NOTE: It is not a terribly easy problem to place equi-distant points
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
# Note that the depth divisions will depend on the depth input. If absolute
# depth is used, this scaling makes sense. If some measure of relative
# depth in the scene is used, this makes much less sense (unless that
# relative depth is scaled 0-100 or some such)
N_BINS_DIST = 10
MAX_DIST = 100
DIST_BIN_EDGES = np.logspace(np.log10(1), np.log10(MAX_DIST), N_BINS_DIST)
DIST_BIN_EDGES = np.hstack([0, DIST_BIN_EDGES[:-1], 999])


# (There must be a better solution for this...)
from matplotlib.colors import LinearSegmentedColormap

List = ([(1,0,0),(1.,.5,0),(1,.85,1),(0,.5,1),(0,0,1)][::-1])
BCWOR = LinearSegmentedColormap.from_list('BCWOR',List)
List = ([(1,0,0,1.),(1.,.5,0,.625),(1,.85,1,.25,),(0,.5,1,.625),(0,0,1,1.)][::-1])
BCWORa = LinearSegmentedColormap.from_list('BCWORa',List)
List = ([(1,0,0,1.),(1.,.5,0,.5),(1,.85,1,0,),(0,.5,1,.5),(0,0,1,1.)][::-1])
BCWORaa = LinearSegmentedColormap.from_list('BCWORaa',List)

# Supporting functions 

def vector2camMatrix(cVec,IgnoreRotXYZ=(False,True,False)):
    """Gets the camera (perspective) transformation, given a vector from camera->fixation
    
    Optionally, sets one (or more) axes of rotation for the camera to zero
    
    This provides a matrix that "un-rotates" the camera perspective, but leaves whatever
    axes are set to "true" untouched (i.e., in their original image space). 
    
    Parameters
    ----------
    IgnoreRot : 3-vector
    [false,true,false] by default (there should be no y rotation [roll] of cameras)    
    """

    # Vector to Euler angles:
    if IgnoreRotXYZ[0]:
       xR = 0
    else:
       #xR = rad2deg(np.arctan2(cVec[2],(cVec[0]**2+cVec[1]**2)**.5))
       xR = np.arctan2(cVec[2],(cVec[0]**2+cVec[1]**2)**.5)
    if IgnoreRotXYZ[1]:
       yR = 0. # ASSUMED - no roll of camera 
    else:
       raise Exception('fix me! (I don''t know how to compute y rotations! consult wikipedia!)')
    if IgnoreRotXYZ[2]:
       zR = 0.
    else:
       #zR = -rad2deg(np.arctan2(cVec[0],cVec[1]))
       zR = -np.arctan2(cVec[0],cVec[1])

    # Rotation matrices, given Euler angles:
    # X rotation
    xRot = np.array([[1., 0., 0.],
       [0., np.cos(xR),np.sin(xR)],
       [0., -np.sin(xR), np.cos(xR)]])
    # Y rotation
    yRot = np.array([[np.cos(yR), 0., -np.sin(yR)],
       [0., 1., 0.],
       [np.sin(yR), 0., np.cos(yR)]])
    # Z rotation
    zRot = np.array([[np.cos(zR),np.sin(zR), 0.],
       [-np.sin(zR), np.cos(zR), 0.],
       [0., 0., 1.]])

    CamMat = xRot.dot(yRot).dot(zRot)
    return CamMat

def angle2dcm(r1,r2,r3,rot_order='xyz'):
    """Create rotation matrix (discrete cosine matrix) for set of Euler rotations

    Only works with rotation order r1=x,r2=y,r3=z for now!
    """
    if rot_order!='xyz':
       raise NotImplemented("Need to define other rotations!")
    # Allow for r1, r2, r3 to be arrays?
    # angles = np.vstack([r1.flatten(), r2.flatten(), r3.flatten()]).T
    angles = np.vstack([r1, r2, r3]).T
    dcm = np.zeros((3,3,angles.shape[0]))
    cang = np.cos(angles)
    sang = np.sin(angles)
    ## -- Below is all specific to x,y,z rotations -- ##
    #   [     cy*cz, sz*cx+sy*sx*cz, sz*sx-sy*cx*cz]
    #   [    -cy*sz, cz*cx-sy*sx*sz, cz*sx+sy*cx*sz]
    #   [    sy,   -cy*sx,   cy*cx]
    dcm[0,0,:] = cang[:,1]*cang[:,2]
    dcm[0,1,:] = sang[:,0]*sang[:,1]*cang[:,2] + cang[:,0]*sang[:,2]
    dcm[0,2,:] = -cang[:,0]*sang[:,1]*cang[:,2] + sang[:,0]*sang[:,2]
    dcm[1,0,:] = -cang[:,1]*sang[:,2]
    dcm[1,1,:] = -sang[:,0]*sang[:,1]*sang[:,2] + cang[:,0]*cang[:,2]
    dcm[1,2,:] = cang[:,0]*sang[:,1]*sang[:,2] + sang[:,0]*cang[:,2]   
    dcm[2,0,:] = sang[:,1]
    dcm[2,1,:] = -sang[:,0]*cang[:,1]
    dcm[2,2,:] = cang[:,0]*cang[:,1]
    return dcm


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
                                      output_channel=None,
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
    output_channel: int or none
        if provided, returns image w/ pixels in the bin provided 
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
    norm_bin_centers = norm_bin_centers / L2norm[:, np.newaxis]

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
    if output_channel is None:
        output = np.zeros((n_ims, n_dims)) * np.nan
    else:
        output = np.zeros(distance.shape, dtype=np.int16)
    for iS in range(n_ims):
        if n_ims>200:
            if iS % 200 == 0:
                print("Done to image %d / %d"%(iS, n_ims)) #progressdot(iS,200,2000,n_ims)
        elif (n_ims < 200) and (n_ims > 1):
            print('computing Scene Depth Normals...')
        # Pull single image for preprocessing
        z = distance[..., iS]  #S.(zVar)(:,:,iS)
        n = normals[..., iS]  # S.Normals(:,:,:,iS)
        height, width, nd = n.shape
        xx, yy = np.meshgrid(np.linspace(0, 1, width), np.linspace(0, 1, height))
        idx = np.arange(n_norm_bins)
        for d_st, d_fin in zip(dist_bin_edges[:-1], dist_bin_edges[1:]):
            dIdx = (z >= d_st) & (z < d_fin)
            for ix in range(n_bins_x):
                hIdx = (xx >= bins_x[ix]) & (xx < bins_x[ix+1])
                for iy in range(n_bins_y):
                    vIdx = (yy >= bins_y[iy]) & (yy < bins_y[iy + 1])
                    this_section = (dIdx & hIdx) & vIdx
                    if this_section.sum()==0:
                        output[iS, idx] = 0
                        idx += n_norm_bins
                        continue
                    if n_norm_bins > 1:
                        nn = n[this_section, :]
                        # Compute orientation of pixelwise surface normals relative
                        # to all normal bins
                        o = nn.dot(norm_bin_centers.T)
                        #print(o.shape)
                        #L2nn = np.linalg.norm(nn, axis=1, ord=2)
                        #o = bsxfun(@rdivide,o,Lb) # Norm of norm_bin_centers should be 1
                        o /= np.linalg.norm(nn, axis=1, ord=2)[:, np.newaxis]
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
                        tmp_out = np.mean(this_section)
                    # Illegal for more than two bins of normals within the same
                    # depth / horiz/vert tile to be == 1
                    if sum(tmp_out == 1) > 1:
                        error('Found two separate normal bins equal to 1 - that should be impossible!')
                    if dist_normalize and not (n_norm_bins == 1):
                        # normalize normals by n pixels at this depth/screen tile
                        tmp_out = tmp_out * pct_pix_this_depth
                    if output_channel is None:
                        output[iS, idx] = tmp_out
                    else:
                        if this_section.sum() > 0:
                            1/0
                    idx += n_norm_bins
        # Do sky channel(s) after last depth channel, add (n tiles) sky channels
        if sky_channel and (np.max(dist_bin_edges) < np.inf):
            dSky = z >= dist_bin_edges[-1]
            skyidx = np.arange((n_dims - n_tiles), n_dims)
            tmp = np.zeros((n_bins_y, n_bins_x))
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


def tilt_slant(img, make_1d=False):
    """Convert a pixelwise surface normal image into tilt, slant values

    Parameters
    ----------
    nimg: array
        Pixelwise normal image, [x,y,3] - 3rd dimension should represent 
        the surface normal (x,y,z vector, summing to 1) at each pixel
    """
    sky = np.all(img==0, axis=2)
    # Tilt
    tau = np.arctan2(img[:,:,2], img[:,:,0])
    # Slant
    sig = np.arccos(img[:,:,1])
    tau[sky] = np.nan
    sig[sky] = np.nan
    tau = utils.circ_dist(tau, -np.pi / 2) + np.pi
    #tau = circ_dist(tau, np.pi) + np.pi
    if make_1d:
        tilt = tau[~np.isnan(tau)].flatten()
        slant = sig[~np.isnan(sig)].flatten()
        return tilt, slant
    else:
        return tau, sig


def norm_color_image(nimg, cmap=RET, vmin_t=0, vmax_t=2 * np.pi,
                    vmin_s=0, vmax_s=np.pi/2):
    """Convert normal image to colormapped normal image"""
    from matplotlib.colors import Normalize
    tilt, slant = tilt_slant(nimg, make_1d=False)
    # Normalize tilt (-pi to pi) -> (0, 1)
    norm_t = Normalize(vmin=vmin_t, vmax=vmax_t, clip=True)
    # Normalize slant (0 to pi/2) -> (0, 1)
    norm_s = Normalize(vmin=vmin_s, vmax=vmax_s, clip=True)
    # Convert normalized tilt to RGB color
    tilt_rgb_orig = cmap(norm_t(tilt))
    # Convert to HSV, replace saturation w/ normalized slant value
    tilt_hsv = skcol.rgb2hsv(tilt_rgb_orig[...,:3])
    tilt_hsv[:,:,1] = norm_s(slant)
    # Convert back to RGB
    tilt_rgb = skcol.hsv2rgb(tilt_hsv)
    tilt_rgb = np.dstack([tilt_rgb, 1-np.isnan(slant).astype(np.float)])
    # Compute better alpha
    a_im = np.dstack([tilt_rgb_orig[...,:3], norm_s(slant)])
    aa_im = tilt_rgb_orig[...,:3] * norm_s(slant)[..., np.newaxis] + np.ones_like(tilt_rgb_orig[...,:3]) * 0.5 * (1-norm_s(slant)[...,np.newaxis])
    aa_im = np.dstack([aa_im, 1-np.isnan(tilt).astype(np.float)])
    
    return aa_im


def tilt_slant_hist(tilt, slant, n_slant_bins = 30, n_tilt_bins = 90, do_log=True, 
                    vmin=None, vmax=None, H=None, ax=None, **kwargs):
    """Plot a polar histogram of tilt and slant values
    
    if H is None, computes & plots histogram of tilt & slant
    if H is True, computes histogram of tilt & slant & returns histogram count
    if H is a value, plots histogram of H"""
    if (H is None) or (H is True) or (H is False):
        return_h = H is True
        tbins = np.linspace(0, 2*np.pi, n_tilt_bins)      # 0 to 360 in steps of 360/N.
        sbins = np.linspace(0, np.pi/2, n_slant_bins) 
        H, xedges, yedges = np.histogram2d(tilt, slant, bins=(tbins,sbins), normed=True) #, weights=pwr)
        #H /= H.sum()
        if do_log:
            #print(H.shape)
            H = np.log(H)
            #H[np.isinf(H)] = np.nan
        if return_h:
            return H

    if do_log:
        if vmin is None:
            vmin=-8
        if vmax is None:
            vmax = 4

    e1 = n_tilt_bins * 1j
    e2 = n_slant_bins * 1j

    # Grid to plot your data on using pcolormesh
    theta, r = np.mgrid[0:2*np.pi:e1, 0:np.pi/2:e2]
    if ax is None:
        fig, ax = plt.subplots(figsize=(8, 8), subplot_kw=dict(projection='polar'))
    
    pc = ax.pcolormesh(theta, r, H, vmin=vmin, vmax=vmax, **kwargs)
    # Remove yticklabels, set limits
    #ax.set_yticklabels([]) 
    #ax.set_xticklabels([]) 
    ax.set_ylim([0, np.pi/2])
    ax.set_theta_offset(-np.pi/2)
    if ax is None:
        plt.colorbar(pc)


def show_sdn(wts, params, mn_mx=None, lw=1, cmap=BCWORa, ax=None, show_axis=False, 
             azim=-80, elev=10, dst_spacing=3, pane_scale=1, cbar=False):
    """Show scene depth/normal model channels
    """
    # forget tiled models for now - they don't work anyway.
    #if params['sky_channel']:
    #    sky = wts[-1]
    #    wts = wts[:-1]
    if mn_mx is None:
        # Default to min/max of wts, respecting zero
        mx = np.max(np.abs(wts)) * 0.8
        mn_mx = (-mx,mx)
    bin_centers = params['normBinCenters']
    nD = len(params['DepthDiv'])-1
    DstAdd = np.array([0,1,0]);
    
    # Base patch, facing -y direction
    base_patch = np.array([[-1,0,-1],[-1,0,1],[1,0,1],[1,0,-1],[-1,0,-1]])* pane_scale
    #wts[np.isnan(wts)] = 0;
    faces = []
    # Loop over different distances in DepthDiv ...
    for iD in range(nD): #= 1:nD
        # ...and vectors in normBinCenters
        for iP,bc in enumerate(bin_centers):
            #ct = iP+iD*len(bin_centers)
            xyz = -dst_spacing*bc - DstAdd*iD;
            # re-set direction of normal vector to make coordinate conventions consistent
            xyz = xyz*np.array([1,-1,1])
            # rotate patch by camera transformation
            cam_mat = vector2camMatrix(bc)
            patch_rot = cam_mat.dot(base_patch.T).T
            patch_rot_shift = xyz[None,:]+patch_rot
            # add patch to list of faces
            faces.append(patch_rot_shift)
    if params['sky_channel']:
        bc = np.array([0, 1, 0])
        xyz = -dst_spacing * bc - DstAdd*nD
        xyz = xyz * np.array([1, -1, 1])
        cam_mat = vector2camMatrix(bc)
        patch_rot = cam_mat.dot(base_patch.T * 3).T
        patch_rot_shift = xyz[None,:] + patch_rot
        faces.append(patch_rot_shift)
    ## -- Set face colors -- ##
    norm = colors.Normalize(*mn_mx)
    cmapper = plt.cm.ScalarMappable(norm=norm, cmap=cmap)
    cols = cmapper.to_rgba(wts)
    ## -- Plot poly collection -- ##
    if ax is None:
        fig = plt.figure()
        ax = plt.axes(projection='3d')
    else:
        fig = ax.get_figure()
    #print("faces are %d long"%len(faces))
    #print("colors are %d long"%len(cols))
    nfaces = len(faces)
    for ii,ff in enumerate(faces):
        polys = Poly3DCollection([ff], linewidths=lw)
        polys.set_facecolors([cols[ii]])
        polys.set_edgecolors([0.5, 0.5, 0.5])
        ax.add_collection3d(polys)
    xl,yl,zl = zip(np.min(np.vstack([f for f in faces]),axis=0),
                   np.max(np.vstack([f for f in faces]),axis=0))
    plt.setp(ax,xlim=xl,ylim=yl,zlim=zl)
    ax.view_init(azim=azim,elev=elev)
    if show_axis:
        ax.set_xlabel('x')
        ax.set_ylabel('y')
        ax.set_zlabel('z')
    else:
        ax.set_axis_off()
    if cbar:
        fig.colorbar(polys, ax=ax)

def add_border(col,im,lw=4,is_trim=False):
    """Add a border around an image."""
    L,R,T,B = im.get_extent()
    ax = im.get_axes()
    # Translate extent to bounding box
    ww =[[L, B], [R, T]]
    bb = mtransforms.Bbox(ww)
    offset = np.abs(bb.width)*.01
    p_fancy = FancyBboxPatch((bb.xmin, bb.ymin),
                             abs(bb.width), abs(bb.height),
                             boxstyle="round,pad=%0.2f"%(offset),
                             fc="none",
                             ec=col, 
                             lw=lw,
                             zorder=4)
    ax.add_patch(p_fancy)
    if is_trim:
        plt.axis('off')
        plt.setp(ax,ylim=(T+lw*offset/2.,B-lw*offset/2.),xlim=(L-lw*offset/2.,R+lw*offset/2.))
        
