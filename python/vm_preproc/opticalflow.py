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

# all the Chinese characters serve as a temporary reminder that there is something I need to double 
# check on
# variables could be included at the final one line code:
# 1. receptive fields' resolution: receptive_field_dim = (15, 20)
# 2. frame size: size = (270, 480)
# 3. should I switch all gridx, gridy to receptive_field_dim[1], and receptive_field_dim[0]

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
    """
    # Angles should rotate clockwise from top; thus, need -angle + 90 in here:
    dx = np.cos(np.radians(-angle+90)) * radius
    dy = np.sin(np.radians(-angle+90)) * radius
    return dx, dy


# 目前这里已经变成包括所有frames,后面的indexing需要改变
def compute_radius_angle_dResidual_dMotion(movie, grid_x=20, 
                                            grid_y=15, 
                                            edge_length=edge_length_fn(),
                                            radii=np.linspace(1, 24, 7), # 7 radii mentioned in the paper
                                            n_angles=12,
                                            edge_buffer=24, # max patch-comparision radii
                                            use_luminance=True, nth_percentile= 0.05
                                            ):
    
    """
    Parameters
    ----------
    nth_percentile: 
        the threshold that exclude the top 5% radius length and dResdual(是不是还有bottom 5% radius length?因为是为了排除极其小的vector以及比较长的vector)
    
    Returns
    -------
    output_radius_angle_dResidual_dMotion: 
        a (n_frames-1)*300*4 3-dimensional array, contains radius, angle, dResidual, dMotion for each patch and each frame
    real_flowfield:
        a (n_frames-1)*300*2 3-dimensional array, dx dy

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
    output_radius_angle_dResidual_dMotion = np.zeros((n_frames-1, grid_x * grid_y, 4)) # radius, angle, dResidual, dMotion
    # loop over n_frames-1
#     for 
    # Loop over frames
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
            # Preallocate error measurements 不明白
            dResidual_patch = np.zeros((n_radii, n_angles))
            for iradius, radius in enumerate(radii):
                # Get secondary patch locations
                cx, cy = vmt.plot_utils.circle_pos(radius, n_angles, x_center=gx_, y_center=gy_).T
                # Loop over secondary patches
                for iangle, (cx_, cy_) in enumerate(zip(cx, cy)):
                    # Can cause bugs because might run off edge of image.
                    patch1 = get_patch_fn(next_frame, center=(cy_, cx_), edge_length=edge_length)
                    # Make our comparison!
                    # (you want to keep this value for each angle and radius)
                    err = compare_patches_fn (patch0, patch1, method='dTotal')
                    dResidual_patch[iradius, iangle] = err
            # gives the indicis of the best radius and anglefor each patch
            best_radius, best_angle = np.nonzero(dResidual_patch==np.min(dResidual_patch))
            # Might want to check if length of best_radius > 1
            best_radius = best_radius[0]
            best_angle = best_angle[0]
            this_radius = radii[best_radius]
            this_angle = angles[best_angle]
            dResidual_patch = dResidual_patch[best_radius, best_angle]
            dMotion_patch = dTotal_patch - dResidual_patch
            output_radius_angle_dResidual_dMotion[ifr, igrid, 0] = this_radius
            output_radius_angle_dResidual_dMotion[ifr, igrid, 1] = this_angle
            output_radius_angle_dResidual_dMotion[ifr, igrid, 2] = dResidual_patch
            output_radius_angle_dResidual_dMotion[ifr, igrid, 3] = dMotion_patch 
    
    # threshold设定需要在原先的loop以外
    for ifr, _ in enumerate(movie):
        if ifr==len(movie)-1:
            break
        ifr_dRes, ifr_radius = output_radius_angle_dResidual_dMotion[ifr, :, 2], output_radius_angle_dResidual_dMotion[ifr, :, 0]
        index_top_nth_percentile = int(np.round(grid_x * grid_y * nth_percentile * -1))
        # Method 1 directly zeroing all selected indices after i=-15
        # exclude non-motion related changes such as newly appeared objects
        # selected_indices_1 = np.argsort(ifr_dRes)[index_top_nth_percentile :] 
        # for index in selected_indices_1:
        #     output_radius_angle_dResidual_dMotion[ifr, index, 0] = 0
        #     output_radius_angle_dResidual_dMotion[ifr, index, 1] = 0
        # rule out long vectors
        selected_indices_2 = np.argsort(ifr_radius)[index_top_nth_percentile :]
        for index in selected_indices_2:
            output_radius_angle_dResidual_dMotion[ifr, index, 0] = 0
            output_radius_angle_dResidual_dMotion[ifr, index, 1] = 0
        # Method 2 finding one value and make comparisions
    #     top5th_percentile_alldRes = np.argsort(ifr_dRes)[index_top_nth_percentile] 
    #     top5th_percentile_alldMot = np.argsort(ifr_dMot)[index_top_nth_percentile]
    # #但是在这里我们还没有全部dMot的矩阵所以需要先得到全部矩阵才能在每一帧里面挑选前5%
    #     for i_ifr_dMot_patch, ifr_dMot_patch in enumerate(ifr_dMot): 
    #         if ifr_dMot_patch >= top5th_percentile_alldMot:
    #             output_radius_angle_dResidual_dMotion[ifr, i_ifr_dMot_patch, 0] = 0
    #             output_radius_angle_dResidual_dMotion[ifr, i_ifr_dMot_patch, 1] = 0
    #     for i_ifr_dRes_patch, ifr_dRes_patch in enumerate(ifr_dRes):
    #         if ifr_dRes >= top5th_percentile_alldRes:
    #             output_radius_angle_dResidual_dMotion[ifr, i_ifr_dRes_patch, 0] = 0
    #             output_radius_angle_dResidual_dMotion[ifr, i_ifr_dRes_patch, 1] = 0
    # threshold_1 = threshold_1_factor * dTotal_patch
    # threshold_2 = threshold_2_factor * dTotal_patch          
    dx, dy = angle_to_uv_fn(output_radius_angle_dResidual_dMotion[:, :, 0].reshape((n_frames-1, grid_x*grid_y, 1)), 
                         output_radius_angle_dResidual_dMotion[:, :, 1].reshape((n_frames-1, grid_x*grid_y, 1)))
    real_flowfield = np.dstack((dx, dy))
    return output_radius_angle_dResidual_dMotion, real_flowfield
            


def show_ff_quiver_plot(movie= None, g_vec_selected = None, frame_index = None, scale=1, 
                        figsize = (8, 4.5), color=(1, 0.9, 0), title= None, ax=None, grid_x = 20,
                        grid_y = 15, frame_size=(270,480,3), savefig= True, fig_title='unnamed.jpeg' ):
    """
    for visualization the quivoplot image overlaying on top of the movie frame when movie is given. The default does
    output an "unnamed.jpeg" file.
    Parameters:
    -----------
    i_gff : scalar
        index of the gff we want to plot
    """
    # should be the input
    # g_vec_selected = all_gffs[i_gff, :, :]
    u, v = g_vec_selected[:, 0].reshape(grid_x, grid_y), g_vec_selected[ :, 1].reshape(grid_x, grid_y)
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


def sanity_check_real_flowfield(movie, nth_percentile= 0.05, figsize = (8, 4.5), scale=0.1):
    """plot all real flow fields in quiver plots"""
    _, real_flowfield=compute_radius_angle_dResidual_dMotion(movie, nth_percentile= nth_percentile)
    n_frames = len(movie)
    for i in range(0, n_frames-1):
        #改成subplot格式,问题出在这里了,plots每次都会更新,
        plots =show_ff_quiver_plot(movie= movie, g_vec_selected=real_flowfield[i, :, :], frame_index=i,
                                    title=i, figsize= figsize, savefig= False, scale=scale)
    return plots