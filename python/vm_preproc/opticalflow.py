import vm_tools as vmt
import vm_preproc as vmp
import vedb_store
import numpy as np
import matplotlib.pyplot as plt
import skimage.transform as skt
import skimage.color as skcol
import glob
import os
import file_io 
# For animation rendering in notebook
from IPython.display import HTML
# from vm_preproc import opticalflow  (this is when the optical flow module is done and ready to be imported)

# all the Chinese characters serve as a temporary reminder that there is something I need to double 
# check on

# Variables could be included at the final one line code,最终在这个终极oneline code之外找不到任何magic number, 输出的是(nframe-1)*receptive fields' resolution*(至少是3)的三维矩阵,因为这个矩阵有dMotion, dGlobal, dLocal;并且能够画图得到三个不同颜色的向量在每一个gridpoint上显示出来:
# 1. receptive fields' resolution: receptive_field_dim = (15, 20)
# 2. frame size: size = (270, 480)
# 3. switch all gridx, gridy to: receptive_field_dim[1], and receptive_field_dim[0]
# 4. edge_buffer = 24
# 5. compute_radius_angle_dMotion...函数里的所有parameter都应该变成 manipulative variables

def edge_length_fn (horizontal_size = 480, vertical_size = 270, receptive_field_dim = (15, 20)):
    """Calculate the exact length base on how many patches we want (receptive field dimensions) 
    and the image resolution
    Parameters
    ----------
    horizontal_size = int
        total pixels on x axis
    vertical_size = int
        total pixels on y axis
    receptive_field_dim= tuple
        (y, x) gives total receptive fields given y rows x columns

    Returns
    -------
    edge_length 
    """
    total_patches = receptive_field_dim[0] * receptive_field_dim[1]
    edge_length = np.sqrt (horizontal_size * vertical_size / total_patches)
    return edge_length

def get_patch_fn(im, center=None, edge_length=edge_length_fn()):
    """Get a patch from an image
    
    Parameters
    ----------
    im : array
        image from which patch is to be extracted
    center : tuple
        (i,j) index for pixel at center of patch
    edge_length : scalar
        length of patch edge
        
    Returns
    -------
    im[top:bottom, left:right]:
        select the area of the receptive field given the center

    Notes
    -----
    SQUARE PATCHES ONLY FOR NOW
    """
    ic, jc = center
    top = np.int(ic) - np.round(edge_length/2).astype(np.int)
    bottom = np.int(ic) + np.round(edge_length/2).astype(np.int)
    left = np.int(jc) - np.round(edge_length/2).astype(np.int)
    right = np.int(jc) + np.round(edge_length/2).astype(np.int)
    # the first output, indexing, is of our interest here 
    return im[top:bottom, left:right]

# (unimportant) this is a sanity check function that displays the receptive field patch
def show_rect(im, loc, edge_length=edge_length_fn(), ax=None):
    rect = plt.Rectangle([loc[1]-edge_length/2, loc[0]-edge_length/2], edge_length, edge_length, 
    edgecolor='y', 
    facecolor='none')
    if ax is None:
        fig, ax = plt.subplots()
        ax.imshow(im)
    ax.add_patch(rect)
    
def get_grid(im, grid_x=20, grid_y=15, edge_length=edge_length_fn(), edge_buffer=24):
    """it outputs the pixel coordinates of each grid on an image in flattened formant"""
    imy, imx, _ = im.shape
    ix = np.linspace(edge_buffer + np.ceil(edge_length/2), 
                     imx - (edge_buffer + np.ceil(edge_length /2)),
                     grid_x)
    iy = np.linspace(edge_buffer + np.ceil(edge_length/2), 
                     imy - (edge_buffer + np.ceil(edge_length /2)),
                     grid_y)

    gx, gy = np.meshgrid(ix, iy)
    return gx.flatten(), gy.flatten()

def compare_patches_fn (p0, p1, method='dTotal'):
    """
    Parameters
    ----------
    p0, p1 = arrays
        both are 2d arrays, generated from the get_patch_fn

    Returns
    -------
    err
        value that determines whether patch "p1" is the best match translational patch for patch "p0"
    """
    if method=='euclidean':
        err = np.sum((p0.flatten()-p1.flatten())**2)
    # dTotal= the total motion of that patch
    elif method=='dTotal': 
        err = np.mean(np.abs(p0-p1))
    elif method=='boo':
        pass # do something else
    else:
        raise ValueError('Unknown method!')
    return err

# calculates dx and dy                                                                                                                     
def angle_to_uv_fn(radius, angle):
    """
    calculate and return dx, dy for patches(which is u, v for quiverplot), 
    0 degree angle points at 12 o'clock, it rotates clockwise
    Returns
    -------
    dx: array
    dy: array
    """
    # Angles should rotate clockwise from top; thus, need -angle + 90 in here:
    dx = np.cos(np.radians(-angle+90)) * radius
    dy = np.sin(np.radians(-angle+90)) * radius
    return dx, dy


# 目前这里已经变成包括所有frames,后面的indexing需要改变
# threshold改成z-score
def compute_radius_angle_dResidual_dMotion_dTotal(movie, grid_x=20, 
                                                  grid_y=15, 
                                                  edge_length=edge_length_fn(),
                                                  radii=np.linspace(1, 24, 7), # 7 radii mentioned in the paper
                                                  n_angles=12,
                                                  edge_buffer=24, # max patch-comparision radii
                                                  use_luminance=True,
                                                  use_threshold=True, z_score_threshold=3,
                                                  nth_percentile= 0.05 # could be discarded
                                                  ):
    
    """
    Parameters
    ----------
    nth_percentile: 
        the threshold that exclude the top 5% radius length and dResdual(是不是还有bottom 5% radius length?因为是为了排除极其小的vector以及比较长的vector)
    
    Returns
    -------
    output_radius_angle_dResidual_dMotion_dTotal: a (n_frames-1)*300*5 3-dimensional array
        contains radius, angle, dResidual, dMotion, dTotal for each patch and each frame
    
    real_flowfield:a (n_frames-1)*300*2 3-dimensional array
        dx dy
    
    outlier_quantity: a (n_frames-1)*1 1-dimensional array
        total numbers of patches that were considered as outlier of each frame

    """
    # Get first frame to set up grid, etc
    first_frame = movie[0]
    gx, gy = get_grid(first_frame, 
                      grid_x=grid_x, 
                      grid_y=grid_y, 
                      edge_buffer=edge_buffer)
    n_radii = len(radii) 
    n_frames = len(movie) 
    angles = np.arange(0, 360., 360./n_angles)
    output_radius_angle_dResidual_dMotion_dTotal = np.zeros((n_frames-1, grid_x * grid_y, 5)) # radius, angle, dResidual, dMotion
    outlier_quantity = []
    # loop over n_frames-1
    for ifr, frame in enumerate(movie):
        if ifr==len(movie)-1:
            break
        if use_luminance:
            # convert rgb to luminance
            this_frame = skcol.rgb2lab(frame)
            # Keep only luminance channel
            this_frame = this_frame[:, :, 0]
            next_frame = skcol.rgb2lab(movie[ifr+1])
            # Keep only luminance channel
            next_frame = next_frame[:, :, 0]
        else:
            this_frame = frame.copy()
            next_frame = movie[ifr+1].copy()
        # Loop over grid locations
        for igrid, (gy_, gx_) in enumerate(zip(gy, gx)):
            # Get patch from this frame
            patch0 = get_patch_fn(this_frame, center=(gy_, gx_), edge_length=edge_length)
            # Get patch from next frame
            next_patch0 = get_patch_fn(next_frame, center=(gy_, gx_), edge_length=edge_length)
            # Compute dTotal(mean luminance change of every pixel in a patch)
            dTotal_patch = np.mean(np.abs(patch0 - next_patch0))
            # Preallocate error measurements 
            dResidual_patch = np.zeros((n_radii, n_angles))
            for iradius, radius in enumerate(radii):
                # Get secondary patch locations,circle_pos() default circle at BotCCW(bottom counter clockwise)but after transposition, it became right-headed clockwise
                cx, cy = vmt.plot_utils.circle_pos(radius, n_angles, x_center=gx_, y_center=gy_).T
                # Loop over secondary patches 这里原来写的是(cx, cy)
                for iangle, (cy_, cx_) in enumerate(zip(cy, cx)):
                    patch1 = get_patch_fn(next_frame, center=(cy_, cx_), edge_length=edge_length)
                    # Make our comparison!
                    err = compare_patches_fn (patch0, patch1, method='dTotal')
                    # storing this value for each angle and radius
                    dResidual_patch[iradius, iangle] = err
            # gives the indicis of the best radius and anglefor each patch
            i_best_radius, i_best_angle = np.nonzero(dResidual_patch==np.min(dResidual_patch))
            # in case the length of best_radius > 1
            i_best_radius = i_best_radius[0]
            i_best_angle = i_best_angle[0]
            this_radius = radii[i_best_radius]
            this_angle = angles[i_best_angle]
            dResidual_patch = dResidual_patch[i_best_radius, i_best_angle]
            dMotion_patch = dTotal_patch - dResidual_patch
            output_radius_angle_dResidual_dMotion_dTotal[ifr, igrid, 0] = this_radius
            output_radius_angle_dResidual_dMotion_dTotal[ifr, igrid, 1] = this_angle
            output_radius_angle_dResidual_dMotion_dTotal[ifr, igrid, 2] = dResidual_patch
            output_radius_angle_dResidual_dMotion_dTotal[ifr, igrid, 3] = dMotion_patch
            output_radius_angle_dResidual_dMotion_dTotal[ifr, igrid, 4] = dTotal_patch 
        
        # threshold设定需要在原先的loop以外
        # 1. use z units to define outliers, 2. make threshold a kwarg so it can be on and off for appropriate settings
        if use_threshold:
            # first threshold targets dRes
            ifr_radius, ifr_dRes, ifr_dMot = (output_radius_angle_dResidual_dMotion_dTotal[ifr, :, 0], 
                                              output_radius_angle_dResidual_dMotion_dTotal[ifr, :, 2], 
                                              output_radius_angle_dResidual_dMotion_dTotal[ifr, :, 3])
            dMot_radius = np.divide(ifr_dMot, ifr_radius)
            ifr_dRes_mean, ifr_dRes_std = np.mean(ifr_dRes), np.std(ifr_dRes)
            ifr_radius_mean, ifr_radius_std = np.mean(ifr_radius), np.std(ifr_radius)
            dMot_radius_mean, dMot_radius_std = np.mean(dMot_radius), np.std(dMot_radius)
            for i_ifr_dRes, ifr_dRes in enumerate(ifr_dRes):
                z = (ifr_dRes - ifr_dRes_mean) / ifr_dRes_std
                if z > z_score_threshold:
                    #radius and angle are set to zero but not dRes and dMot
                    output_radius_angle_dResidual_dMotion_dTotal[ifr, i_ifr_dRes, 0] = 0
                    output_radius_angle_dResidual_dMotion_dTotal[ifr, i_ifr_dRes, 1] = 0
    
            # second threshold targets vector length(radius)
            for i_ifr_radius, ifr_radius in enumerate(ifr_radius):
                z = (ifr_radius - ifr_radius_mean) / ifr_radius_std
                if z > z_score_threshold:
                    #radius and angle are set to zero but not dRes and dMot
                    output_radius_angle_dResidual_dMotion_dTotal[ifr, i_ifr_radius, 0] = 0
                    output_radius_angle_dResidual_dMotion_dTotal[ifr, i_ifr_radius, 1] = 0

            # third threshold targets radius / dMot (radius=vector length)
            for i_dMot_radius, dMot_radius in enumerate(dMot_radius):
                z = (dMot_radius - dMot_radius_mean) / dMot_radius_std
                if z > z_score_threshold:
                    #radius and angle are set to zero but not dRes and dMot
                    output_radius_angle_dResidual_dMotion_dTotal[ifr, i_dMot_radius, 0] = 0
                    output_radius_angle_dResidual_dMotion_dTotal[ifr, i_dMot_radius, 1] = 0    
       
           # fourth threshold (more of a sanity check), if any dMotion=zero, discard as outlier
            zeros_indices_y = np.nonzero(output_radius_angle_dResidual_dMotion_dTotal[ifr, :, 3]==0)
            for i_zeros_indices_y in zeros_indices_y:
                    #radius and angle are set to zero but not dRes and dMot
                output_radius_angle_dResidual_dMotion_dTotal[ifr, i_zeros_indices_y, 0] = 0
                output_radius_angle_dResidual_dMotion_dTotal[ifr, i_zeros_indices_y, 1] = 0
            outlier_quantity.append(np.sum(output_radius_angle_dResidual_dMotion_dTotal[ifr, :, 0]==0)) 


    dx, dy = angle_to_uv_fn(output_radius_angle_dResidual_dMotion_dTotal[:, :, 0].reshape((n_frames-1, grid_x*grid_y, 1)), 
                         output_radius_angle_dResidual_dMotion_dTotal[:, :, 1].reshape((n_frames-1, grid_x*grid_y, 1)))
    real_flowfield = np.dstack((dx, dy))
    outlier_quantity = np.array(outlier_quantity)
    return output_radius_angle_dResidual_dMotion_dTotal, real_flowfield, outlier_quantity
            


def show_ff_quiver_plot(movie= None, vec_selected = None, frame_index = None, scale=1, 
                        figsize = (8, 4.5), color=(1, 0.9, 0), title= None, ax=None, grid_x = 20,
                        grid_y = 15, frame_size=(270,480,3), savefig= True, fig_title='unnamed.jpeg' ):
    """
    for visualization the quivoplot image overlaying on top of the movie frame when movie is given. The 
    default outputs an "unnamed.jpeg" file.
    
    Parameters
    ----------
    i_gff : scalar
        index of the gff we want to plot
    """
    # should be the input
    # if we want to show the global_ff, then vec_selected = all_gffs[i_gff, :, :]
    # 这里我把原来的vec_selected[:, 1]改成了vec_selected[:, :, 1], 可能在呈现global flowfield的时候要小心
    u, v = vec_selected[frame_index, :, 0], vec_selected[frame_index, :, 1] 
    u, v = u.reshape(grid_x, grid_y), v.reshape(grid_x, grid_y)
    # Get first frame to set up grid, etc
    if movie is not None:
        first_frame = movie[0]
        gx, gy = get_grid(first_frame)
    else:
        gx, gy = get_grid(np.zeros(frame_size))
    if ax is None: # if else? ax是不是根本不需要设为一个parameters
        fig, ax = plt.subplots(figsize = figsize)
    if movie is not None:
        ax.imshow(movie[frame_index])
        ax.scatter(gx, gy, marker='.', color='blue')
    if title is not None:
        ax.set_title(title)
    ax.quiver(gx, gy, u, v, color = color, scale=scale, scale_units='x')
    if savefig is True: 
        return plt.savefig(fig_title,  bbox_inches='tight',pad_inches = 0)
    else:
        return ax.quiver(gx, gy, u, v, color = color, scale=scale, scale_units='x')


def sanity_check_real_flowfield(movie, vec_selected,
                                nth_percentile= 0.05, figsize = (8, 4.5), 
                                scale=0.1):
    """plot every real flow fields for everu frame in quiver plots"""
    _, real_flowfield=compute_radius_angle_dResidual_dMotion_dTotal(movie, nth_percentile= nth_percentile)
    n_frames = len(movie)
    for i in range(n_frames -1):
        #改成subplot格式,问题出在这里了,plots每次都会更新,
        plots =show_ff_quiver_plot(movie= movie, vec_selected=vec_selected, frame_index=i,
                                    title=i, figsize= figsize, savefig= False, scale=scale)
    return plots