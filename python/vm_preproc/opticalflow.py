import vm_tools as vmt
import vm_preproc as vmp
import vedb_store
import numpy as np
import matplotlib.pyplot as plt
import skimage.transform as skt
import skimage.color as skcol
import glob
import os
import cv2
import file_io
# For animation rendering in notebook
from IPython.display import HTML
from vm_preproc import opticalflow  


def patch_length_fn(im, receptive_field_dim=(15, 20), radius_range=(1, 24)):
    """Calculate the exact length base on how many patches we want (receptive field dimensions) 
    and the image resolution.

    Parameters
    ----------
    im : array
        image/frame array from which patch length is to be calculated

    receptive_field_dim : tuple (y, x)
        (y, x) defines receptive field's dimension given y rows x columns, also could be used to define 
        variable grid_x, grid_y in the code, which refers to total # of grid points on x y axis respectively    

    radius_range : tuple, optional
        for determining edge_buffer which prevents patch comparision process fall out of the frame

    Returns
    -------
    patch_length 

    Deleted Parameters
    ------------------
    edge_buffer : scalar
        prevent the patch comparision processes fall outside of the image, equals to the np.max(radius)
    """
    edge_buffer = radius_range[1]
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    # horizontal_size: total pixels on x axis; vertical_size: total pixels on y axis
    vertical_size, horizontal_size = im.shape[0], im.shape[1]
    total_patches = grid_x * grid_y
    patch_length = np.sqrt((horizontal_size - 2 * edge_buffer)
                           * (vertical_size - 2 * edge_buffer) / total_patches)
    return patch_length


def get_patch_fn(im, center=None, receptive_field_dim=(15, 20), radius_range=(1, 24)):
    """
    Get a patch from an image

    Parameters
    ----------
    im : array
        image from which patch is to be extracted
    center : tuple
        (i,j) index for pixel at center of patch
    receptive_field_dim
        used by patch_length function
    radius_range : tuple, optional
        Description

    Returns
    -------
    im[top:bottom, left:right]:
        select the area of the receptive field given the center

    Notes
    -----
    SQUARE PATCHES ONLY FOR NOW

    Deleted Parameters
    ------------------
    edge_buffer:
        used by patch_length function
    """
    ic, jc = center
    patch_length = patch_length_fn(
        im, receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    top = np.int(ic) - np.round(patch_length/2).astype(np.int)
    bottom = np.int(ic) + np.round(patch_length/2).astype(np.int)
    left = np.int(jc) - np.round(patch_length/2).astype(np.int)
    right = np.int(jc) + np.round(patch_length/2).astype(np.int)
    # the first output, indexing, is of our interest here
    return im[top:bottom, left:right]

# (unimportant)


def show_rect(im, loc, ax=None, horizontal_size=480, vertical_size=270,
              receptive_field_dim=(15, 20)):
    """
    A sanity check function that displays the receptive field of a patch from an image

    Parameters
    ----------
    im : array
        image/frame from which patch is to be extracted
    loc : TYPE
        Description
    ax : None, optional
        Description
    horizontal_size, vertical_size, receptive_field_dim
        used by patch_length function

    Deleted Parameters
    ------------------
    center : tuple
        (i,j) index for pixel at center of patch
    edge_buffer:
        used by patch_length function

    """

    patch_length = patch_length_fn(
        im, receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    rect = plt.Rectangle([loc[1]-patch_length/2, loc[0]-patch_length/2], patch_length, patch_length,
                         edgecolor='y',
                         facecolor='none')
    if ax is None:
        fig, ax = plt.subplots()
        ax.imshow(im)
    ax.add_patch(rect)


def get_grid(im, receptive_field_dim=(15, 20), radius_range=(1, 24)):
    """
    it outputs the pixel coordinates of each grid on an image in flattened formant

    Parameters
    ----------
    receptive_field_dim: tuple (y, x)
        (y, x) defines receptive field's dimension given y rows x columns, also could be used to define 
        variable grid_x, grid_y in the code, which refers to total # of grid points on x y axis respectively 

    receptive_field_dim, edge_buffer: 
        used by patch_length function



    Returns
    -------
    gx: array
        flattened array of the pixel coordinates on x axis, coordinate can be floats
    gy:
        flattened array of the pixel coordinates on y axis
    """
    edge_buffer = radius_range[1]
    patch_length = patch_length_fn(
        im, receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    imy, imx = im.shape[0], im.shape[1]
    # numbers of grid in x and y dimension
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    ix = np.linspace(edge_buffer + np.ceil(patch_length/2),
                     imx - (edge_buffer + np.ceil(patch_length / 2)),
                     grid_x)
    iy = np.linspace(edge_buffer + np.ceil(patch_length/2),
                     imy - (edge_buffer + np.ceil(patch_length / 2)),
                     grid_y)
    gx, gy = np.meshgrid(ix, iy)
    gx, gy = gx.flatten(), gy.flatten()
    return gx, gy


def compare_patches_fn(p0, p1, method='dTotal'):
    """
    Parameters
    ----------
    p0, p1 = arrays
        both are 2d arrays, generated from the get_patch_fn

    Returns
    -------
    err
        error value that determines whether patch "p1" is the best match translational patch for patch "p0"
    """
    if method == 'euclidean':
        err = np.sum((p0.flatten()-p1.flatten())**2)
    # dTotal= the total motion of that patch
    elif method == 'dTotal':
        err = np.mean(np.abs(p0-p1))
    elif method == 'boo':
        pass  # do something else
    else:
        raise ValueError('Unknown method!')
    return err

# calculates dx and dy


def angle_to_uv_fn(radius, angle):
    """
    calculate and return dx, dy for patches(which is u, v for quiverplot), 
    0 degree angle points at 12 o'clock, it rotates clockwise


    Parameters
    ----------
    radius : TYPE
        Description
    angle : TYPE
        Description

    Returns
    -------
    dx: array u
    dy: array v
    """
    # Angles should rotate clockwise from top; thus, need -angle + 90 in here:
    dx = np.cos(np.radians(-angle+90)) * radius
    dy = np.sin(np.radians(-angle+90)) * radius
    return dx, dy


def compute_rad_ang_dRes_dMot_dTot(movie, receptive_field_dim=(15, 20), radius_range=(1, 24), n_radii=7, n_angles=12,
                                   use_luminance=True, outlier_rejection=True, threshold1_dRes=True, threshold2_radius=True,
                                   threshold3_veclength_divide_dMot=True, z_score_threshold=3):
    """
    Computes radius angle dResidual dMotion and dTotal for every frame.
    
    Parameters
    ----------
    movie : array
        Description
    receptive_field_dim : tuple, optional
        used by patch_length function
    radius_range : tuple, optional
        Description
    n_radii : int, optional
        total number of radius needed for patch comparision
    n_angles : int, optional
        total number of angle needed for patch comparision
    use_luminance : bool, optional
        whether convert CIE video to LGB and only use luminance for computation
    outlier_rejection : bool, optional
        controls whether to use z score for clipping outliers.
    threshold1_dRes : bool, optional
        first threshold targets dRes using z score
    threshold2_radius : bool, optional
        second threshold targets vector length(radius) using z score
    threshold3_veclength_divide_dMot : bool, optional
        third threshold targets "radius/dMot" (radius=vector length) using z score, "radius/dMot" indicates whether radius is a 
        good match to its dMot
    z_score_threshold : int, optional
        used in outlier rejection
    
    Returns
    -------
    out_dic : dictionary
        contains 7 key-value pairs.
            'rad_ang_dRes_dMot_dTot' : a (n_frames-1)*300*5   3-dimensional array
                contains radius, angle, dResidual, dMotion, dTotal for each patch and each frame
    
            'real_flowfield' : (n_frames-1)*300*2     3-dimensional array
                (n_frames-1)--total frame; 300--total grid points; 2--vstacked by dx, dy, whcih is the amount of pixels shifted 
                in x and y direction
    
            'zero_value_quantity'  : (n_frames-1)*1   1-dimensional array 
                total numbers of patches that were set to zero in a frame. Its relationship with outlier_quantity and original_dMot_zeros_quantity is below:
                zero_value_quantity = outlier_quantity + original_dMot_zeros_quantity
    
            'outlier_quantity' : (n_frames-1)*1   1-dimensional array
                total numbers of patches that were considered as outlier of each frame. It's an empty array if outlier rejection was set to False
    
            'original_dMot_zeros_quantity'  : (n_frames-1)*1   1-dimensional array 
                total numbers of patches that were set to zero in a frame before outlier rejection, should equal to 'zero_value_quantity'
                if outlier rejection was set to False
    
            'rad_ang_dRes_dMot_dTot_original' :  (n_frames-1)*300*5   3-dimensional array
                storing the original output that has not been thresholded with outlier rejection 
    
            'use_outlier_rejection' : bool, optional
                in case we have forgotten if we set outlier_rejection to True or False, this serve as a reminder.
    
    Deleted Parameters
    ------------------
    threshold4_dMot_is0 : bool, optional
        fourth threshold (more of a sanity check), if any dMotion=zero, discard as outlier
    """
    # Get first frame to set up grid, etc
    patch_length = patch_length_fn(
        movie[0], receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    gx, gy = get_grid(
        movie[0], receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    radii = np.linspace(radius_range[0], radius_range[1], n_radii)
    n_frames = len(movie)
    angles = np.arange(0, 360., 360./n_angles)
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    # create a blank array for storing radius, angle, dResidual, dMotion, dTotal
    rad_ang_dRes_dMot_dTot = np.zeros((n_frames-1, grid_x * grid_y, 5))
    # preset a list to store zero values' quantity for every frame, zero_value_quantity = outlier_quantity + original_dMot_zeros_quantity
    zero_value_quantity = []
    # preset a list to store original_dMot_zeros_quantity for every frame
    original_dMot_zeros_quantity = [] 
    # loop over n_frames-1
    for ifr, frame in enumerate(movie):
        if ifr == len(movie)-1:
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
            patch0 = get_patch_fn(this_frame, center=(
                gy_, gx_), receptive_field_dim=receptive_field_dim, radius_range=radius_range)
            # Get patch from next frame
            next_patch0 = get_patch_fn(next_frame, center=(
                gy_, gx_), receptive_field_dim=receptive_field_dim, radius_range=radius_range)
            # Compute dTotal(mean luminance change of every pixel in a patch)
            dTotal_patch = np.mean(np.abs(patch0 - next_patch0))
            # Preallocate error measurements
            dResidual_patch = np.zeros((n_radii, n_angles))
            for iradius, radius in enumerate(radii):
                # Get secondary patch locations,circle_pos() default circle at BotCCW(bottom counter clockwise)but after transposition, it became right-headed clockwise
                cx, cy = vmt.plot_utils.circle_pos(
                    radius, n_angles, x_center=gx_, y_center=gy_).T
                # Loop over secondary patches 
                for iangle, (cy_, cx_) in enumerate(zip(cy, cx)):
                    patch1 = get_patch_fn(next_frame, center=(
                        cy_, cx_), receptive_field_dim=receptive_field_dim, radius_range=radius_range)
                    # Make our comparison!
                    err = compare_patches_fn(patch0, patch1, method='dTotal')
                    # storing this value for each angle and radius
                    dResidual_patch[iradius, iangle] = err
            # gives the indicis of the best radius and anglefor each patch
            i_best_radius, i_best_angle = np.nonzero(
                dResidual_patch == np.min(dResidual_patch))
            # in case the length of best_radius > 1
            i_best_radius = i_best_radius[0]
            i_best_angle = i_best_angle[0]
            this_radius = radii[i_best_radius]
            this_angle = angles[i_best_angle]
            dResidual_patch = dResidual_patch[i_best_radius, i_best_angle]
            dMotion_patch = dTotal_patch - dResidual_patch
            rad_ang_dRes_dMot_dTot[ifr, igrid, 0] = this_radius
            rad_ang_dRes_dMot_dTot[ifr, igrid, 1] = this_angle
            rad_ang_dRes_dMot_dTot[ifr, igrid, 2] = dResidual_patch
            rad_ang_dRes_dMot_dTot[ifr, igrid, 3] = dMotion_patch
            rad_ang_dRes_dMot_dTot[ifr, igrid, 4] = dTotal_patch
        # storing the original output that has not been thresholded with outlier rejection.
        rad_ang_dRes_dMot_dTot_original = rad_ang_dRes_dMot_dTot
        

        # outlier rejection/zero indices counting step
        # find the indices of patches that already has dMot set to zero
        dMot_zeros_indices = np.nonzero(
                rad_ang_dRes_dMot_dTot[ifr, :, 3] == 0)
        # find the number of patches that already has dMot set to zero
        original_dMot_zeros_quantity.append(np.sum(rad_ang_dRes_dMot_dTot[ifr, :, 3] == 0))
        # when dMot is 0, there shouldn't be any flowfield in that patch regardless
        for i_dMot_zeros_indices in dMot_zeros_indices:
            # radius, angle, and dMot are set to zero
            rad_ang_dRes_dMot_dTot[ifr, i_dMot_zeros_indices, 0] = 0
            rad_ang_dRes_dMot_dTot[ifr, i_dMot_zeros_indices, 1] = 0
            rad_ang_dRes_dMot_dTot[ifr, i_dMot_zeros_indices, 3] = 0
            # since dMot is set to zero, dTot=dRes+dMot, dRes is set to equal to dTot
            rad_ang_dRes_dMot_dTot[ifr, i_dMot_zeros_indices,
                                   2] = rad_ang_dRes_dMot_dTot[ifr, i_dMot_zeros_indices, 4]

        # If outlier_rejection=false, we simply output the flowfiled without outlier rejection
        if outlier_rejection:
            ifr_radius, ifr_dRes, ifr_dMot = (rad_ang_dRes_dMot_dTot[ifr, :, 0],
                                              rad_ang_dRes_dMot_dTot[ifr, :, 2],
                                              rad_ang_dRes_dMot_dTot[ifr, :, 3])
            # dMot/radius evaluates whether dMot is a good description of its radius, this was not present in the Bartel's paper
            with np.errstate(divide='ignore', invalid='ignore'):
                dMot_radius = np.nan_to_num(np.divide(ifr_dMot, ifr_radius))
            ifr_dRes_mean, ifr_dRes_std = np.mean(
                ifr_dRes), np.std(ifr_dRes)
            ifr_radius_mean, ifr_radius_std = np.mean(
                ifr_radius), np.std(ifr_radius)
            dMot_radius_mean, dMot_radius_std = np.mean(
                dMot_radius), np.std(dMot_radius)
            # first threshold only targets large dRes
            if threshold1_dRes:
                for i_ifr_dRes, ifr_dRes in enumerate(ifr_dRes):
                    z = (ifr_dRes - ifr_dRes_mean) / ifr_dRes_std
                    if z > z_score_threshold:
                        # radius, angle and dMot are set to zero
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_dRes, 0] = 0
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_dRes, 1] = 0
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_dRes, 3] = 0
                        # since dMot is set to zero, dTot=dRes+dMot, dRes is set to equal to dTot
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_dRes,
                                               2] = rad_ang_dRes_dMot_dTot[ifr, i_ifr_dRes, 4]

            # second threshold targets unusually long and short vector length(radius)
            if threshold2_radius:
                for i_ifr_radius, ifr_radius in enumerate(ifr_radius):
                    z = (ifr_radius - ifr_radius_mean) / ifr_radius_std
                    if np.abs(z) > z_score_threshold:
                        # radius, angle and dMot are set to zero
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_radius, 0] = 0
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_radius, 1] = 0
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_radius, 3] = 0
                        # since dMot is set to zero, dTot=dRes+dMot, dRes is set to equal to dTot
                        rad_ang_dRes_dMot_dTot[ifr, i_ifr_radius,
                                               2] = rad_ang_dRes_dMot_dTot[ifr, i_ifr_radius, 4]

            # third threshold targets radius / dMot (radius=vector length)
            if threshold3_veclength_divide_dMot:
                for i_dMot_radius, dMot_radius in enumerate(dMot_radius):
                    z = (dMot_radius - dMot_radius_mean) / dMot_radius_std
                    if np.abs(z) > z_score_threshold:
                        # radius, angle and dMot are set to zero
                        rad_ang_dRes_dMot_dTot[ifr, i_dMot_radius, 0] = 0
                        rad_ang_dRes_dMot_dTot[ifr, i_dMot_radius, 1] = 0
                        rad_ang_dRes_dMot_dTot[ifr, i_dMot_radius, 3] = 0
                        # since dMot is set to zero, dTot=dRes+dMot, dRes is set to equal to dTot
                        rad_ang_dRes_dMot_dTot[ifr, i_dMot_radius,
                                               2] = rad_ang_dRes_dMot_dTot[ifr, i_dMot_radius, 4]

          
            zero_value_quantity.append(
                np.sum(rad_ang_dRes_dMot_dTot[ifr, :, 0] == 0))
        else:
            zero_value_quantity.append(
                np.sum(rad_ang_dRes_dMot_dTot[ifr, :, 3] == 0))
            

    dx, dy = angle_to_uv_fn(rad_ang_dRes_dMot_dTot[:, :, 0].reshape((n_frames-1, grid_x*grid_y, 1)),
                            rad_ang_dRes_dMot_dTot[:, :, 1].reshape((n_frames-1, grid_x*grid_y, 1)))
    out_dict = {}
    # zero_value_quantity = outlier_quantity + original_dMot_zeros_quantity
    out_dict['zero_value_quantity'] = np.array(zero_value_quantity)
    out_dict['outlier_quantity'] = np.subtract(zero_value_quantity, original_dMot_zeros_quantity)
    out_dict['original_dMot_zeros_quantity'] = np.array(original_dMot_zeros_quantity)
    out_dict['rad_ang_dRes_dMot_dTot'] = rad_ang_dRes_dMot_dTot
    out_dict['real_flowfield'] = np.dstack((dx, dy))
    # this is the original value without setting any values to zero through outlier rejection
    out_dict['rad_ang_dRes_dMot_dTot_original'] = rad_ang_dRes_dMot_dTot_original
    # this serves as a reminder of whether we used outlier rejection
    out_dict['use_outlier_rejection'] = outlier_rejection
    return out_dict


def all_gff_uv_fn(receptive_field_dim=(15, 20), angle_range=(0, 360), n_trans_gffs=24, n_centr_gffs=50, n_rotat_gffs=50,
                  n_equally_spacedpoints_x=5, n_equally_spacedpoints_y=5, normalized_mean_vec_length=1):
    """
    Generate u, v value for global flowfields, the total number is determined by variables set in the function, default is 124.

    Parameters
    ----------
    receptive_field_dim : tuple, optional
        used by patch_length function
    angle_range : tuple, optional
        for finding the angle range value in translatioanl global flowfield, angle_raneg[1] will not be included
    n_trans_gffs : int, optional
        total number of translational global flowfield 
    n_centr_gffs : int, optional
        total number of centrifugal and centripetal global flowfield
    n_rotat_gffs : int, optional
        total number of left and right rotational global flowfield
    n_equally_spacedpoints_x : int, optional
        number of equally spaced points on x dimension. by calculating n_equally_spacedpoints_x*n_equally_spacedpoints_y, it 
        sets how many evenly spaced points of origin there are for centrifugal/petal and left/right rotational flowfields.
    n_equally_spacedpoints_y : int, optional
        number of equally spaced points on x dimension. by calculating n_equally_spacedpoints_x*n_equally_spacedpoints_y, it 
        sets how many evenly spaced points of origin there are for centrifugal/petal and left/right rotational flowfields.
    normalized_mean_vec_length : int, optional
        the mean vecter length of all flowfields within a frame after normalization

    Returns
    -------
    all_gff_uv : array
        124x300x2 array represents 124 total global flowfieds and its 300 pairs of u, v
    """
    n_total_gffs = n_trans_gffs + n_centr_gffs + n_rotat_gffs
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    total_patches = grid_x * grid_y
    # preallocate all_gff_uv(124x300x2)
    all_gff_uv = np.zeros((n_total_gffs, total_patches, 2)
                          )  # sets/depth, rows, columns
    # translational flowfields
    angles = np.linspace(
        angle_range[0], angle_range[1], n_trans_gffs, endpoint=False)
    for iang, ang in enumerate(angles):
        # find the g_vec_x/y (global vector length on x or y axis)
        trans_gffs_radius = normalized_mean_vec_length
        g_vec_x, g_vec_y = angle_to_uv_fn(trans_gffs_radius, ang)
        # fill the 24 translational global fields into all_gff_uv
        all_gff_uv[iang, :, :] = np.dstack((g_vec_x, g_vec_y))

    # centrifugal and centripetal flowfields + right(clockwise) and left(counterclockwise) rotational flowfield

    # how far each center point of origin would move from left to right
    center_shift_x = np.linspace(0, grid_x, n_equally_spacedpoints_x)
    # how far each center point of origin would move from top to bottom
    center_shift_y = np.linspace(0, grid_y, n_equally_spacedpoints_y)
    # starting index of the centri_ff in
    fugal_counter, petal_counter = n_trans_gffs, int(
        n_trans_gffs + n_centr_gffs/2)
    # starting index of the rotat_ff in
    R_rotat_counter, L_rotat_counter = int(
        n_trans_gffs + n_centr_gffs), int(n_trans_gffs + n_centr_gffs + n_rotat_gffs/2)
    for i_center_shift_y in center_shift_y:
        for i_center_shift_x in center_shift_x:
            x = range(0 - int(i_center_shift_x),
                      grid_x - int(i_center_shift_x))
            y = range(0 - int(i_center_shift_y),
                      grid_y - int(i_center_shift_y))
            u, v = np.meshgrid(x, y)
            # calculates the vecter length
            centri_vec_len = np.sqrt(u**2 + v**2)
            # calculates the scaling factor "k_centri" so mean vector length will be 1
            k_centri = np.mean(centri_vec_len)/normalized_mean_vec_length
            u, v = u / k_centri, v / k_centri
            all_gff_uv[fugal_counter, :, :] = np.dstack(
                (u.flatten(), -v.flatten()))
            all_gff_uv[petal_counter, :, :] = np.dstack(
                (-u.flatten(), v.flatten()))
            all_gff_uv[R_rotat_counter, :, :] = np.dstack(
                (-v.flatten(), -u.flatten()))
            all_gff_uv[L_rotat_counter, :, :] = np.dstack(
                (v.flatten(), u.flatten()))
            fugal_counter, petal_counter = fugal_counter + 1, petal_counter + 1
            R_rotat_counter, L_rotat_counter = R_rotat_counter + 1, L_rotat_counter + 1

    return all_gff_uv


def dMot_dMotG_dMotL_fn(movie, receptive_field_dim=(15, 20), radius_range=(1, 24), n_radii=7, n_angles=12, use_luminance=True,
                        outlier_rejection=False, z_score_threshold=3, angle_range=(0, 360), n_trans_gffs=24, n_centr_gffs=50, n_rotat_gffs=50,
                        n_equally_spacedpoints_x=5, n_equally_spacedpoints_y=5, normalized_mean_vec_length=1):
    """
    Mainly calculates dMot, dMotG and dMotL and its uv arrays for plotting flowfields.

    Parameters
    ----------
    movie : array
        Description
    receptive_field_dim : tuple, optional
        used by patch_length function
    radius_range : tuple, optional
        smallest and largest radius length for patch comparision
    n_radii : int, optional
        total number of radius needed for patch comparision
    n_angles : int, optional
        total number of angle needed for patch comparision
    use_luminance : bool, optional
        whether convert CIE video to LGB and only use luminance for computation
    outlier_rejection : bool, optional
        controls whether to use z score for clipping outliers.
    z_score_threshold : int, optional
        used in outlier rejection
    angle_range : tuple, optional
        for finding the angle range value in translatioanl global flowfield, angle_raneg[1] will not be included
    n_trans_gffs : int, optional
        total number of translational global flowfield 
    n_centr_gffs : int, optional
        total number of centrifugal and centripetal global flowfield
    n_rotat_gffs : int, optional
        total number of left and right rotational global flowfield
    n_equally_spacedpoints_x : int, optional
        number of equally spaced points on x dimension. by calculating n_equally_spacedpoints_x*n_equally_spacedpoints_y, it 
        sets how many evenly spaced points of origin there are for centrifugal/petal and left/right rotational flowfields.
    n_equally_spacedpoints_y : int, optional
        number of equally spaced points on x dimension. by calculating n_equally_spacedpoints_x*n_equally_spacedpoints_y, it 
        sets how many evenly spaced points of origin there are for centrifugal/petal and left/right rotational flowfields.
    normalized_mean_vec_length : int, optional
        the mean vecter length of all flowfields within a frame after normalization

    Returns
    -------
    out_dic : dictionary
        Contains 6 key-value pairs + another 3 key-value pairs merged from compute_rad_ang_dRes_dMot_dTot function. 
            'dMot_dMotG_dMotL' 
                an array of dMotion, dMotionGlobal, dMotionLocal;(n_frame-1)x300x3

            'gff_lff_rff'
                global motion, local motion, real motion vectors' flowfields in arrays of uv;(n_frame-1)x300x2x3 

            'all_ibest_gff'
                an array of the best matched global flowfield's index(start from 0) for every frame;(n_frames-1x1)

            'rad_ang_dRes_dMot_dTot' : a (n_frames-1)*300*5   3-dimensional array
                contains radius, angle, dResidual, dMotion, dTotal for each patch and each frame

            'real_flowfield' : (n_frames-1)*300*2     3-dimensional array
                (n_frames-1)--total frame; 300--total grid points; 2--vstacked by dx, dy, whcih is the amount of pixels shifted 
                in x and y direction

            'outlier_quantity' : (n_frames-1)*1   1-dimensional array
                total numbers of patches that were considered as outlier of each frame

            'n_frames' : n_frames scalar value
                total number of frames in the movie
    """
    n_total_gffs = n_trans_gffs + n_centr_gffs + n_rotat_gffs
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    total_patches = grid_x * grid_y
    n_frames = len(movie)
    # preset output arrays, later will be filled by .append()
    all_dMot, all_dMotG, all_dMotL, all_gff, all_lff, all_rff, all_ibest_gff, all_dMotGlobal_score, all_Pgr, all_zero_in_rff, all_zero_in_lff, all_zero_in_gff = [
    ], [], [], [], [], [], [], [], [], [], [], []
    # get rad_ang_dRes_dMot_dTot, output of "compute_rad_ang_dRes_dMot_dTot" is a dictionary
    output_dic_compute_rad_ang_dRes_dMot_dTot = compute_rad_ang_dRes_dMot_dTot(
        movie, receptive_field_dim=receptive_field_dim, radius_range=radius_range, n_radii=n_radii, n_angles=n_angles,
        use_luminance=use_luminance, z_score_threshold=z_score_threshold, outlier_rejection=outlier_rejection)
    rad_ang_dRes_dMot_dTot = output_dic_compute_rad_ang_dRes_dMot_dTot['rad_ang_dRes_dMot_dTot']
    real_flowfield = output_dic_compute_rad_ang_dRes_dMot_dTot['real_flowfield']
    # get "all_gff_uv"
    all_gff_uv = all_gff_uv_fn(receptive_field_dim=receptive_field_dim, angle_range=angle_range, n_trans_gffs=n_trans_gffs,
                               n_centr_gffs=n_centr_gffs, n_rotat_gffs=n_rotat_gffs, n_equally_spacedpoints_x=n_equally_spacedpoints_x,
                               n_equally_spacedpoints_y=n_equally_spacedpoints_y, normalized_mean_vec_length=normalized_mean_vec_length)
    for i_frame in range(n_frames - 1):
        dMot = rad_ang_dRes_dMot_dTot[i_frame, :, 3]
        # calculates the frame-specific scaling factor "k_rff" so mean vector length of real flowfield will be 1
        k_rff = np.mean(
            rad_ang_dRes_dMot_dTot[i_frame, :, 0])/normalized_mean_vec_length
        # To generate the rff_vec_norm matrix with shape(300, 2)
        rff_vec_norm = real_flowfield[i_frame, :, :] / k_rff
        # real flowfield vector length after normalization 300x1
        rff_vec_norm_length = rad_ang_dRes_dMot_dTot[i_frame, :, 0]/k_rff
        # this line of code would ignore all error reports regarding denominator being zero
        with np.errstate(divide='ignore', invalid='ignore'):
            # Pgr is the projection of global flowfield vector onto real vector
            # all_gff_uv  300x2 array rff_vec_norm 300x2; rff_vec_norm_length 300x1; Pgr 300x124, this would put all nan to zero
            Pgr = np.concatenate(np.nan_to_num([np.sum(all_gff_uv[i, :, :]*rff_vec_norm, axis=1) /
                                  rff_vec_norm_length for i in range(0, n_total_gffs)])).reshape(300, n_total_gffs)
        # Pgr[:,i] 300x1; dMot1x300x1 , returns dMotGlobal_score 124x1
        dMotGlobal_score = np.array([np.sum(Pgr[:, i]*dMot)
                                     for i in range(0, n_total_gffs)])
        # ibest_gff = index of the best gff in dMotGlobal_score
        ibest_gff = [i for i, j in enumerate(
            dMotGlobal_score) if j == max(dMotGlobal_score)]
        if len(ibest_gff) > 1:
            print("Attention: multiple best_matched global flowfields were found at",
                  frame_index=i_frame)
            print('total number of best matched gffs for this frame is',
                  len(ibest_gff))
            print("Please follow the following steps:\n use output 'all_ibest_gff' and the 'frame_index' to find the index for all matched gffs,")
            print("you can plot them and determine which one should be the best match and discard other index so the output 'all_ibest_gff'")
            print("should have the length of 'n_frame-1', the updated output dictionary will then work fine in plotting flowfields later")
            # in this case it should have length larger than "n_frame-1"

        if len(ibest_gff) is 1:
            pass
        # regardless of having one best matched gff or multiple, we only select the first appeared max's index for simplicity
        ibest_gff = np.argmax(dMotGlobal_score)
        # best g_ff uv 1x300x2
        g_ff_best = all_gff_uv[ibest_gff, :, :]
        # make all outlier grid points to be zero 
        g_ff_best[[i for i in np.nonzero(dMot == 0)],:] = 0
        # vector subtraction to find the local motion flowfield 1x300x2
        l_ff = np.subtract(rff_vec_norm, g_ff_best)
        with np.errstate(divide='ignore', invalid='ignore'):
            # global motion at every patch in pixel luminance value 300x1, eliminate all nan
            dMotG = np.nan_to_num(np.multiply(dMot, (Pgr[:, ibest_gff]/rff_vec_norm_length)))
        # local motion at every patch 300x1
        dMotL = np.subtract(dMot, dMotG)
        
        # quantify the number of zero vector in all ffs
        zero_in_rff = np.sum((np.abs(rff_vec_norm[:, 0])+np.abs(rff_vec_norm[:, 1]))==0)
        zero_in_lff = np.sum((np.abs(l_ff[:, 0])+np.abs(l_ff[:, 1]))==0)
        # when ibest_gff is larger than 24, gffs are centri and rotational ff with a zero vector length at the center originally. 
        # In the case when the center original zero vector points have not been clipped by our outlier rejection process, then gff
        # could be larger than rff and lff by one 
        zero_in_gff = np.sum((np.abs(g_ff_best[:, 0])+np.abs(g_ff_best[:, 1]))==0)

        # fill in all preset empty lists for every frame
        all_dMot.append(dMot)
        all_dMotG.append(dMotG)
        all_dMotL.append(dMotL)
        all_gff.append(g_ff_best)
        all_lff.append(l_ff)
        all_rff.append(rff_vec_norm)
        all_dMotGlobal_score.append(dMotGlobal_score)
        all_ibest_gff.append(ibest_gff)
        all_Pgr.append(Pgr)
        all_zero_in_rff.append(zero_in_rff) 
        all_zero_in_lff.append(zero_in_lff)
        all_zero_in_gff.append(zero_in_gff)

    # output dictionary
    out_dict = {}
    # arrays dMot dMotG and dMotL have the shape of (n_frame-1)x300
    out_dict['all_dMot'] = np.array(all_dMot)
    out_dict['all_dMotG'] = np.array(all_dMotG)
    out_dict['all_dMotL'] = np.array(all_dMotL)
    # gff, lff and rff have the shape of (n_frame-1)x300x2; 300x2 refers to 300 u,v pairs of ff vectors
    out_dict['all_gff'] = np.array(all_gff)
    out_dict['all_lff'] = np.array(all_lff)
    out_dict['all_rff'] = np.array(all_rff)
    # all_ibest_gff has the shape of (n_frame-1)x1
    out_dict['all_ibest_gff'] = np.array(all_ibest_gff)
    # all_dMotGlobal_score has the shape of (n_frame-1)x124 since dMotGlobal_score evaluates how good the gff is in capturing the
    # global motion of the video
    out_dict['all_dMotGlobal_score'] = np.array(all_dMotGlobal_score)   
    # all_Pgr has the shape of (n_frame-1)x300x124
    out_dict['all_Pgr'] = np.array(all_Pgr)
    out_dict['n_frames'] = n_frames
    # below 3 are sanity checks to see if they have the same number of zero vectors in all ffs
    out_dict['all_zero_in_rff'] = np.array(all_zero_in_rff) 
    out_dict['all_zero_in_lff'] = np.array(all_zero_in_lff)
    # gff should be equal to rff and lff or larger than rff and lff by 1
    out_dict['all_zero_in_gff'] = np.array(all_zero_in_gff)
    # merges the dictionary's key_value pairs obtained from compute_rad_ang_dRes_dMot_dTot()
    out_dict.update(output_dic_compute_rad_ang_dRes_dMot_dTot)

    return out_dict


def show_all_ff_quiver_plot(movie=None, dict_selected=None, frame_index=None, scale=0.1, headwidth=3, headlength=5,
                            headaxislength=4.5, arrow_width=None, figsize=(8, 4.5), rff_arrow_color="orange",
                            gff_arrow_color="purple", lff_arrow_color="green", grid_color='blue', receptive_field_dim=(15, 20),
                            radius_range=(1, 24), frame_size=(270, 480, 3), savefig=False, fig_title='frame_xxx_all_ff.jpeg',
                            subplot_spaceing=0.5, sharex=True, sharey=True, dpi=300):
    """
    For visualizing 4 quivoplot images in one plot includes real flowfield, global flowfield and local flowfield overlaying on top of the movie 
    frame when movie is given. The default outputs an "unnamed.jpeg" file. It outputs one image with 4 subplots.

    Parameters
    ----------
    movie : TYPE
        Description
    dict_selected : dictionary, optional
        This will be the dictionary outputed from the dMot_dMotG_dMotL_fn
    frame_index : None, optional
        only used when movie is provided, and to display the image of that frame
    scale : int, optional
        Description
    headwidth : int, optional
        controls optical flowfield triangle-shaped arrow head's width, ax.quiver() default is 3
    headlength : int, optional
        controls optical flowfield triangle-shaped arrow head's length, ax.quiver() default is 5
    headaxislength : float, optional
        Description, ax.quiver() default is 4.5
    arrow_width : float, optional
        controls optical flowfield arrow line's width default as 0.004 with plot size (16, 9)
    figsize : tuple, optional
        Description
    rff_arrow_color : str, optional
        color for real flowfield
    gff_arrow_color : str, optional
        color for global flowfield
    lff_arrow_color : str, optional
        color for local flowfield
    grid_color : str, optional
        default as 'blue'
    receptive_field_dim : tuple (y, x)
        (y, x) defines receptive field's dimension given y rows x columns, also could be used to define 
        variable grid_x, grid_y in the code, which refers to total number of grid points on x y axis respectively
    radius_range : tuple, optional
        Description
    frame_size : tuple, optional
        Description
    savefig : bool, optional
        Description
    fig_title : str, optional
        Description

    Returns
    -------
    TYPE
        Description

    """
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    # determines whether output figs title has OTR_T or OTR_F (OTR_T=outlier rejection is True in input_dict)
    outlier_rejection = dict_selected['use_outlier_rejection']
    # selecting the ff from the dictionary
    all_rff = dict_selected['all_rff'][frame_index]
    all_gff = dict_selected['all_gff'][frame_index]
    all_lff = dict_selected['all_lff'][frame_index]
    rff_u, rff_v = all_rff[:, 0].reshape(
        grid_x, grid_y), all_rff[:, 1].reshape(grid_x, grid_y)
    gff_u, gff_v = all_gff[:, 0].reshape(
        grid_x, grid_y), all_gff[:, 1].reshape(grid_x, grid_y)
    lff_u, lff_v = all_lff[:, 0].reshape(
        grid_x, grid_y), all_lff[:, 1].reshape(grid_x, grid_y)

    # set the output fig with 4 subplots
    fig, ax = plt.subplots(2, 2, figsize=figsize, sharex=sharex, sharey=sharey, dpi=dpi)
    fig.tight_layout(pad=subplot_spaceing)
    ax[0, 0].invert_yaxis()
    ax[0, 1].invert_yaxis()
    ax[1, 0].invert_yaxis()
    ax[1, 1].invert_yaxis()
    # Get first frame to set up grid, etc
    gx, gy = get_grid(
        movie[0], receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    ax[0, 0].imshow(movie[frame_index])
    ax[0, 1].imshow(movie[frame_index])
    ax[1, 0].imshow(movie[frame_index])
    ax[1, 1].imshow(movie[frame_index])

    ax[0, 0].scatter(gx, gy, marker='.', color=grid_color)
    ax[0, 1].scatter(gx, gy, marker='.', color=grid_color)
    ax[1, 0].scatter(gx, gy, marker='.', color=grid_color)
    ax[1, 1].scatter(gx, gy, marker='.', color=grid_color)

    if outlier_rejection:
        ax[0, 0].set_title('rff_OTR_T')
        ax[0, 1].set_title('gff_OTR_T')
        ax[1, 0].set_title('lff_OTR_T')
        ax[1, 1].set_title('allff_OTR_T')
    if outlier_rejection is False:
        ax[0, 0].set_title('rff_OTR_F')
        ax[0, 1].set_title('gff_OTR_F')
        ax[1, 0].set_title('lff_OTR_F')
        ax[1, 1].set_title('allff_OTR_F')

    # the first 3 plots
    ax[0, 0].quiver(
        gx, gy, rff_u, rff_v, color=rff_arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    ax[0, 1].quiver(
        gx, gy, gff_u, gff_v, color=gff_arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    ax[1, 0].quiver(
        gx, gy, lff_u, lff_v, color=lff_arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    # the fourth flot is combination of the first 3 plots
    ax[1, 1].quiver(
        gx, gy, rff_u, rff_v, color=rff_arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    ax[1, 1].quiver(
        gx, gy, gff_u, gff_v, color=gff_arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    ax[1, 1].quiver(
        gx, gy, lff_u, lff_v, color=lff_arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    plt.close()
    if savefig:
        return fig.savefig(fig_title,  bbox_inches='tight', pad_inches=0)
    else:
        return fig

def show_one_ff_quiver_plot(movie=None, vec_selected=None, frame_index=None, scale=0.1, headwidth=3, headlength=5, headaxislength=4.5,
                            arrow_width=None, figsize=(8, 4.5), arrow_color="orange", grid_color='blue', title=None,
                            receptive_field_dim=(15, 20), radius_range=(1, 24), frame_size=(270, 480, 3), savefig=False,
                            fig_title='unnamed.jpeg'):
    """
    For visualizing one quivoplot image among real flowfield, global flowfield and local flowfield. The quiver will overlay on top 
    of the movie frame when movie is not None. The default outputs an "unnamed.jpeg" file. It only outputs one image.

    Parameters
    ----------
    movie : TYPE
        Description
    vec_selected : array
        3 possible vec_selected arrays: real_flowfield[frame_index], loc_flowfield[frame_index], and 
        global_flowfield[frame_index]. should all be in the shape of (1, 300, 2), contains u, v   
    frame_index : None, optional
        only used when movie is provided, and to display the image of that frame
    scale : int, optional
        Description
    headwidth : int, optional
        controls optical flowfield triangle-shaped arrow head's width, ax.quiver() default is 3
    headlength : int, optional
        controls optical flowfield triangle-shaped arrow head's length, ax.quiver() default is 5
    headaxislength : float, optional
        Description, ax.quiver() default is 4.5
    arrow_width : float, optional
        controls optical flowfield arrow line's width default as 0.004 with plot size (16, 9)
    figsize : tuple, optional
        Description
    arrow_color : tuple, optional
        default (1, 0.9, 0) is in yellow.
    grid_color : str, optional
        default as 'blue'
    title : None, optional
        Description
    ax_value : None, optional
        determines the number of subplots we have in "fig, ax"
    receptive_field_dim : tuple (y, x)
        (y, x) defines receptive field's dimension given y rows x columns, also could be used to define 
        variable grid_x, grid_y in the code, which refers to total number of grid points on x y axis respectively
    radius_range : tuple, optional
        Description
    frame_size : tuple, optional
        Description
    savefig : bool, optional
        Description
    fig_title : str, optional
        Description


    Returns
    -------
    TYPE
        Description
    """
    # should be the input
    # if we want to show the global_ff, then vec_selected = all_gff_uv[i_gff, :, :]
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    u, v = vec_selected[:, 0], vec_selected[:, 1]
    u, v = u.reshape(grid_x, grid_y), v.reshape(grid_x, grid_y)

    fig, ax = plt.subplots(figsize=figsize)
    ax.invert_yaxis()
    if movie is not None:
        # Get first frame to set up grid, etc
        gx, gy = get_grid(
            movie[0], receptive_field_dim=receptive_field_dim, radius_range=radius_range)
        ax.imshow(movie[frame_index])
        ax.scatter(gx, gy, marker='.', color=grid_color)
    else:
        gx, gy = get_grid(np.zeros(
            frame_size), receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    if title is not None:
        ax.set_title(title)
    ax.quiver(
        gx, gy, u, v, color=arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)
    if savefig is True:
        return plt.savefig(fig_title,  bbox_inches='tight', pad_inches=0)
    else:
        return ax.quiver(
            gx, gy, u, v, color=arrow_color, scale=scale, scale_units='x', headwidth=headwidth, headlength=headlength, headaxislength=headaxislength, width=arrow_width)

# this is suggested by Arnab to use cv2 to show flowfield as an alternative
def cv2_show_ff(im, name='test', receptive_field_dim=(15, 20), radius_range=(1, 24), vec_selected=None,
                frame_index=None, arrow_thickness=1, arrow_color=[255, 0, 0], tip_length=0.5,
                screen_res=[1920, 1080], overall_scale_factor=10):
    """
    Display image with a visualisation of a flow over the top. A divisor controls the density of the quiver 
    plot.

    Parameters
    ----------
    im : array
        image/selected_frame from which patch is to be extracted (movie[frame_index])
    name : TYPE
        Description
    receptive_field_dim : tuple, optional
        Description
    edge_buffer : int, optional
        Description
    vec_selected : None, optional
        Description
    frame_index : None, optional
        Description
    arrow_thickness : int, optional
        Description
    arrow_color : list, optional
        Description
    screen_res : list, optional
        Description
    arrow_thickness: int

    Returns
    -------
    TYPE
        Description

    """
    # flattened grid coordinates
    scale_factor = im.shape[0]/270 * overall_scale_factor
    gx, gy = get_grid(
        im, receptive_field_dim=receptive_field_dim, radius_range=radius_range)
    total_patches = receptive_field_dim[0] * receptive_field_dim[1]
    grid_x, grid_y = receptive_field_dim[1], receptive_field_dim[0]
    # amount of pixel location change at each grid point
    dx, dy = vec_selected[frame_index, :, 0] * \
        scale_factor, vec_selected[frame_index, :, 1]*scale_factor
    # create a blank mask, on which lines will be drawn.
    mask = np.zeros_like(im)
    for i in range(0, total_patches):
        # start point of the flowfield cv2.arrowedLine takes in float32 rather than float64, therefore needs
        # conversion.
        x_start, y_start = np.float32(gx[i]), np.float32(gy[i])
        # end point of the flowfield
        # x_end, y_end = int(np.add(gx, dx)[i]), int(np.add(gy, dy)[i])
        x_end, y_end = np.float32(gx[i] + dx[i]), np.float32(gy[i] + dy[i])
        # add all the lines to the mask
        mask = cv2.arrowedLine(im, (x_start, y_start),
                               (x_end, y_end), arrow_color, arrow_thickness, tipLength=tip_length)
    # superpose lines onto image
    img = cv2.add(im, mask)

    # for resizing the cm2.imshow's output window size
    scale_width = screen_res[0] / im.shape[1]
    scale_height = screen_res[1] / im.shape[0]
    scale = min(scale_width, scale_height)
    # resized window width and height
    window_width = int(im.shape[1] * scale)
    window_height = int(im.shape[0] * scale)
    # cv2.WINDOW_NORMAL makes the output window resizealbe
    cv2.namedWindow(name, cv2.WINDOW_NORMAL)
    # resize the window according to the screen resolution
    cv2.resizeWindow(name, window_width, window_height)
    # # print image
    # cv2.imshow(name, im)
    # cv2.waitKey(0)
    # cv2.destroyAllWindows()
    return img

# 'FigureHTMLConverter' was written by Matt Shinkle
class FigureHTMLConverter:
    """Converts from plots added to figure objects to HTML video within ipython.
    """
    frames = []
    def add(self, fig):
        """Add new frames to video
        Parameters
        ----------
        fig : matplotlib.figure.Figure
            figure object which has images already added
        """
        fig.canvas.draw()
        data = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8, sep='')
        data = data.reshape(fig.canvas.get_width_height()[::-1] + (3,))
        self.frames.append(data)
    def clear(self):
        """Clear all frames previously added
        """
        self.frames = []
    def render(self, **kwargs):
        """Turn added frames into HTML video within jupyter notebook.
        Parameters
        ----------
        **kwargs
            Keyword arguments for vmt.plot_utils.make_image_animation
        """
        frames_array = np.moveaxis(np.array(self.frames),0,-1)
        anim = vmt.plot_utils.make_image_animation(frames_array, **kwargs)
        display(HTML(anim.to_html5_video()))



def compute_interval(fps=None):
    """
    computes the exact interval(miliseconds between frames) of a movie given its fps(frame per second), the larger fps is,
    the faster the movie plays, the smaller interval value would be
    
    Parameters
    ----------
    fps : scalar, optional
        frames rate per second
    
    Returns
    -------
    interval : scalar
        numbers of miliseconds between 2 frames at above fps value
    
    """
    # ex: 30 frames per second, would only have 29 intervals, therefore, fps-1
    interval = 1000/(fps-1)
    return interval


def video_ff_output(movie=None, input_dict=None, fps=None, scale=0.1, headwidth=3, headlength=5,
                    headaxislength=4.5, arrow_width=None, figsize=(8, 4.5), rff_arrow_color="orange",
                    gff_arrow_color="purple", lff_arrow_color="green", grid_color='blue', receptive_field_dim=(15, 20),
                    radius_range=(1, 24), frame_size=(270, 480, 3), savefig=False, fig_title='frame_xxx_all_ff.jpeg',
                    subplot_spaceing=0.5, sharex=True, sharey=True, dpi=300):
    """
    using the dictionary outputed by dMot_dMotG_dMotL_fn to generate animated ff videos
    
    Parameters
    ----------
    input_dict : dictionary, optional
        the dictionary outputed by dMot_dMotG_dMotL_fn  
    fps : None, optional
        frames rate per second
    
    Returns
    -------
    TYPE
        Description
    """
    converter = FigureHTMLConverter()
    # clear all frames previously added
    converter.clear()
    n_frames = input_dict['n_frames']
    for i in range(n_frames-1):
        fig = show_all_ff_quiver_plot(movie=movie, dict_selected=input_dict, frame_index=i, scale=scale, headwidth=headwidth, 
            headlength=headlength, headaxislength=headaxislength, arrow_width=arrow_width, figsize=figsize, 
            rff_arrow_color=rff_arrow_color, gff_arrow_color=gff_arrow_color, lff_arrow_color=lff_arrow_color, grid_color=grid_color, 
            receptive_field_dim=receptive_field_dim, radius_range=radius_range, frame_size=frame_size, savefig=savefig, fig_title=fig_title,
            subplot_spaceing=subplot_spaceing, sharex=sharex, sharey=sharey, dpi=dpi)
        converter.add(fig)
    # miliseconds
    interval = compute_interval(fps=fps)
    return converter.render(figsize=figsize, interval=interval)

def fig_fn(movie=None, n_frames=None, title=None, dpi=200, subplot_spaceing=1):
    """so the output will be able to define variable fig in ground_truth_generator function
    
    Parameters
    ----------
    movie : None, optional
        Description
    n_frames : None, optional
        Description
    title : None, optional
        Description
    dpi : int, optional
        output image resolution
    
    Returns
    -------
    fig
        matplotlib figure
    """
    fig, axs = plt.subplots(dpi=dpi)
    axs.imshow(movie[n_frames])
    axs.set_title(title)
    fig.tight_layout(pad=subplot_spaceing)
    plt.close()
    return fig

def ground_truth_generator(movie=None, frames=(0,3), fps=2, figsize=(16,9), title=None, dpi=350, subplot_spaceing=1):
    """visualize short clips of videos to know the ground truth at a certain frame
    
    Parameters
    ----------
    movie : array, optional
        Description
    n_frames : tuple, optional
        the start and the end index of frames that want to be calculated, end should be len(movie)
    fps : int, optional
        Description
    figsize : tuple, optional
        Description
    title : TYPE
        Description
    
    Returns
    -------
    TYPE
        Description
    """
    converter = FigureHTMLConverter()
    # clear all frames previously added
    converter.clear()
    frame_start, frame_end = frames
    for i in range(frame_start, frame_end):
        fig = fig_fn(movie=movie, n_frames=i, title=title, dpi=dpi, subplot_spaceing=subplot_spaceing)
        converter.add(fig)
    # miliseconds
    interval = compute_interval(fps=fps)
    return converter.render(figsize=figsize, interval=interval)