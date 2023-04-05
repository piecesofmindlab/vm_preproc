"""
Stuff for running openpose
Will probably go in vm_preproc
Currently only works for default hard-coded body parts (faces, torsos, arms, hands, legs, feet).
Increasing flexibility shouldn't be too much work if needed.
Currently very slow--significant optimization will need to be done before VEDB application
"""
import os
import sys

try:
    path = os.path.expanduser('~/Code/openpose/build/python/') # add to config file
    if path not in sys.path:
        sys.path.append(path)
except:
    print("~/Code/openpose/build/python not found, may break some functions")
import os
from IPython.display import clear_output
import time
import datetime
import numpy as np
import skimage.transform as skt
import glob
import cv2
from scipy.ndimage import gaussian_filter

body_kpts = ["Nose", "Neck",
             "RShoulder", "RElbow", "RWrist",
             "LShoulder", "LElbow", "LWrist",
             "MidHip",
             "RHip", "RKnee", "RAnkle",
             "LHip", "LKnee", "LAnkle",
             "REye", "LEye", "REar", "LEar",
             "LBigToe", "LSmallToe", "LHeel",
             "RBigToe", "RSmallToe", "RHeel", ]

hand_kpts = ['Palm1', 'Palm2',
             'Thumb1', 'Thumb2', 'Thumb3',
             'Index1', 'Index2', 'Index3', 'Index4',
             'Middle1', 'Middle2', 'Middle3', 'Middle4',
             'Ring1', 'Ring2', 'Ring3', 'Ring4',
             'Pinky1', 'Pinky2', 'Pinky3', 'Pinky4']

face_kpts = ['Face0', 'Face1', 'Face2', 'Face3', 'Face4', 'Face5', 'Face6', 'Face7', 'Face8', 'Face9',
             'Face10', 'Face11', 'Face12', 'Face13', 'Face14', 'Face15', 'Face16', 'Face17', 'Face18', 'Face19',
             'Face20', 'Face21', 'Face22', 'Face23', 'Face24', 'Face25', 'Face26', 'Face27', 'Face28', 'Face29',
             'Face30', 'Face31', 'Face32', 'Face33', 'Face34', 'Face35', 'Face36', 'Face37', 'Face38', 'Face39',
             'Face40', 'Face41', 'Face42', 'Face43', 'Face44', 'Face45', 'Face46', 'Face47', 'Face48', 'Face49',
             'Face50', 'Face51', 'Face52', 'Face53', 'Face54', 'Face55', 'Face56', 'Face57', 'Face58', 'Face59',
             'Face60', 'Face61', 'Face62', 'Face63', 'Face64', 'Face65', 'Face66', 'Face67', 'Face68', 'Face69']

kpts_parts_dict = dict(
    face=['Face18', 'Face12', 'Face15', 'Face2', 'Face7', 'Face6', 'Face1', 'Face26', 'Face20', 'Face3', 'Face9',
          'Face21', 'Face0', 'Face17', 'Face25', 'Face22', 'Face11', 'Face19', 'Face5', 'Face4', 'Face23', 'Face16',
          'Face13', 'Face10', 'Face14', 'Face8', 'Face24'],
    trunks=['RShoulder', 'LHip', 'Neck', 'RHip', 'LShoulder', 'LHip', 'RHip', 'RShoulder', 'Neck', 'LShoulder'],
    arms=['LShoulder', 'LElbow', 'LWrist', 'break', 'RShoulder', 'RElbow', 'RWrist', ],
    hands=['Palm1', 'Palm2', 'Thumb1', 'Index1', 'Middle1', 'Ring1', 'Pinky1', 'Palm1', 'break',
           'Palm1', 'Thumb1', 'Palm2', 'Thumb1', 'Thumb2', 'Thumb3', 'break',
           'Palm1', 'Index1', 'Palm2', 'Index1', 'Index2', 'Index3', 'Index4', 'break',
           'Palm1', 'Middle1', 'Palm2', 'Middle1', 'Middle2', 'Middle3', 'Middle4', 'break',
           'Palm1', 'Ring1', 'Palm2', 'Ring1', 'Ring2', 'Ring3', 'Ring4', 'break',
           'Palm1', 'Pinky1', 'Palm2', 'Pinky1', 'Pinky2', 'Pinky3', 'Pinky4', 'break', ],
    legs=['LHip', 'LKnee', 'LAnkle', 'break', 'RHip', 'RKnee', 'RAnkle'],
    feet=['LHeel', 'LBigToe', 'LSmallToe', 'LHeel', 'LAnkle', 'LBigToe', 'LAnkle', 'LSmallToe', 'break',
          'RHeel', 'RBigToe', 'RSmallToe', 'RHeel', 'RAnkle', 'RBigToe', 'RAnkle', 'RSmallToe'],
)


def draw_between(datum, img_dims, *args):
    """Given an openpose datum object and some body keypoints,
    creates an array filled with lines connecting the specified keypoints

    Parameters
    ----------
    datum : datum object
        output of openpose emplace and pop
    img_dims : tuple, list
        Dimensions of output image
    *args
        Description

    Returns
    -------
    combined_grid : np.ndarray
        Array with lines drawn between keypoints
    """
    # TODO: lots of images excluede still?  Fix all the if/then stuff
    from skimage.draw import line_aa
    from scipy.ndimage.filters import gaussian_filter
    # grid of combined body parts
    combined_grid = np.zeros(img_dims)
    if args[0] in body_kpts:
        kpts = datum.poseKeypoints
        kpts_list = body_kpts
    elif args[0] in hand_kpts:
        kpts = datum.handKeypoints
        kpts_list = hand_kpts
    elif args[0] in face_kpts:
        kpts = datum.faceKeypoints
        kpts_list = face_kpts
    # Checks whether kpts are not available (part not detected in image)
    try:
        for person in range(len(kpts)):
            person_kpts = kpts[person]
            if person_kpts.ndim == 2:
                person_kpts = person_kpts[np.newaxis, :, :]
            # loops through both parts when there are two (only needed for R vs L hand)
            for rl_part in range(person_kpts.shape[0]):
                rl_part_kpts = person_kpts[rl_part]
                # loops through each keypoint pair
                for i in range(len(args) - 1):
                    if args[i] == 'break' or args[i + 1] == 'break':
                        pass
                    else:
                        # row and col of max value (for interpolation)
                        col_1, row_1, score1 = rl_part_kpts[kpts_list.index(args[i])]
                        # row and col of max value (for interpolation)
                        col_2, row_2, score2 = rl_part_kpts[kpts_list.index(args[i + 1])]
                        # fill empty array with line between both keypoints
                        interp_grid = np.zeros(combined_grid.shape)
                        # Prevents drawing lines to default coordinates of (0,0)
                        if row_1 * col_1 * row_2 * row_2 != 0:
                            rr, cc, val = line_aa(int(row_1), int(col_1), int(row_2), int(col_2))
                            mask = (rr < img_dims[0]) * (cc < img_dims[1])
                            rr = rr[mask]
                            cc = cc[mask]
                            val = val[mask]
                            interp_grid[rr, cc] = val * 255
                            # Blurs grid
                            blurred_grid = gaussian_filter(interp_grid, sigma=10)
                            # Combine interpolated grid with grid from other kpts for part
                            combined_grid = np.maximum(combined_grid, blurred_grid)
    except:
        pass
    return combined_grid

### Note to mark: I know there are much better/simpler/premade ways to do this, I made it a long time ago..
def list_file_names(input_paths, file_type='', sort=True):
    """Converts a directory or list/tuple of directories into a combined list of sorted file names

    Parameters
    ----------
    input_paths : str or tuple
        tuple of >= 1 directory locations or string of one location
        can be directory or path to specific image
    file_type : str, optional
        filetype of files to use
        ignores all others
    sort : bool, optional
        Whether to sort images or not

    Returns
    -------
    image_paths
        List of full file paths for each file
    """
    if isinstance(input_paths, str):
        # Checks whether a directory or single image is specified
        if not input_paths.endswith('/'):
            image_paths = [input_paths]
        # If directory has been specified
        else:
            image_paths = glob.glob(input_paths + '*')
    # If tuple of directories specified, gets paths for all images in each
    elif isinstance(input_paths, (tuple, list)):
        image_paths = []
        for image_path in input_paths:
            if not image_path.endswith('/'):
                # Checks whether a directory or single image is specified
                image_paths.append(image_path)
            # If directory has been specified
            else:
                new_paths = glob.glob(image_path + '*')
                for new_path in new_paths:
                    image_paths.append(new_path)
    if sort:
        image_paths = sorted(image_paths)
    return image_paths


def progress_bar(current, total, time_elapsed=None, show_percent=True, show_ratio=True, num_bars=50, empty_char="▯",
                 progress_char="▮"):
    """Progress bar w/ bar, ratio done, time elapsed, and estimated time remaining
    Only tested in jupyter notebooks.  May need to be removed/replaced for CLI applications (again, not tested)
    """
    progress = current / total
    percent = int(progress * 100)
    progress_bar = progress_char * int(percent / (100 / num_bars))
    progress_bar = progress_bar.ljust(num_bars, empty_char)
    full_string = "|" + str(progress_bar) + "|"
    if show_percent:
        full_string += str(percent).rjust(3, " ") + "%"
    if show_ratio:
        full_string += " " + str(current).rjust(len(str(total))) + "/" + str(total)
    if time_elapsed != None and progress != 0:
        time_remaining = time_elapsed / progress - time_elapsed
        time_hms = str(datetime.timedelta(seconds=int(time_elapsed)))
        time_remaining_hms = str(datetime.timedelta(seconds=int(time_remaining)))
        full_string += " " + time_hms + " >> " + time_remaining_hms
    clear_output(wait=True)
    print(full_string)

### I'm sure there's also a much better way to do this--made a while ago, before I realized move_axis existed
def reshape_pafs(paf_grid, grid_dims=(15, 15)):
    """Converts pafs between 2d (images X all paf locations)
    and 4d (part pafs X x X y X images).  Automatically
    detects current shape and converts to other
    
    Parameters
    ----------
    paf_grid : np.ndarray
        array of pafs, can be 2d or 4d
    grid_dims : tuple, optional
        shape of grid to which PAFs have been scaled
        required for correct reshaping
    
    Returns
    -------
    paf_grid
        Reshaped pafs based on dimensions of input paf_grid and grid_dims
    """
    if paf_grid.ndim == 2:
        num_ims = paf_grid.shape[0]
        height, width = grid_dims
        num_pafs = int(np.ma.size(paf_grid) / (height * width * num_ims))
        reshaped_pafs = np.zeros((num_pafs, height, width, num_ims))
        for im_idx in range(num_ims):
            reshaped_pafs[:, :, :, im_idx] = paf_grid[im_idx].reshape(-1, height, width)
        paf_grid = reshaped_pafs
    elif paf_grid.ndim == 4:
        paf_grid = paf_grid.swapaxes(0, 3)
        paf_ims, paf_y, paf_x, paf_parts = paf_grid.shape
        reshaped_grid = np.zeros((paf_ims, paf_y * paf_x * paf_parts))
        for im in range(paf_ims):
            for part in range(paf_parts):
                reshaped_grid[im, part * paf_y * paf_x:(part + 1) * paf_y * paf_x] = paf_grid[im, :, :, part].reshape(
                    paf_y * paf_x)
        paf_grid = reshaped_grid
    return paf_grid


def run_openpose_kpts(input_images, paf_norms=None, grid_dims=(15, 15), do_normalize=True, return_shape='2D',
                      **config_params):
    """Runs openpose on input images and uses the keypoints to return a
    downsampled grid of detected body part locations
    
    Parameters
    ----------
    input_images : list, tuple
        List of file locations of all images to run openpose on
    paf_norms : list, tuple, optional
        prespecified normalization parameters, for keeping parameters the same
        between training and validation data (i.e. use the ones returned
        when running on training images)
    grid_dims : tuple, optional
        Dimensions to downsample returned features array
    do_normalize : bool, optional
        Whether to normalize features
    return_shape : str, optional
        Either '2D' (flattened across space) or '3D' (rows x colums x images)
    **config_params
        Optional parameters used as configuration parameters for openpose
    
    Returns
    -------
    TYPE
        Description
    """
    # TODO: make work for different body part inputs
    start_time = time.time()
    input_images = list_file_names(input_images)
    num_images = len(input_images)
    # If an array of images is entered instead
    paf_grid = np.zeros((6, *grid_dims, num_images))
    params = dict(
        hand=True,
        face=True,
        heatmaps_add_parts=True,
        heatmaps_add_PAFs=True,
        model_folder=os.path.expanduser('~/Code/openpose/models/'),
    )
    params.update(config_params)
    opWrapper = op.WrapperPython()
    opWrapper.configure(params)
    opWrapper.start()
    for i, im_loc in enumerate(input_images):
        resized_grid = np.zeros((6, *grid_dims))
        datum = op.Datum()
        datum.cvInputData = cv2.imread(im_loc)
        opWrapper.emplaceAndPop([datum])
        img_dims = datum.cvInputData.shape[:2]
        for j, part in enumerate(kpts_parts_dict.keys()):
            combined_grid = draw_between(datum, img_dims, *kpts_parts_dict[part])
            resized_grid[j] = skt.resize(combined_grid, grid_dims)[np.newaxis, :, :]
        paf_grid[..., i] = resized_grid
        progress_bar(i + 1, num_images, time.time() - start_time, num_bars=50, empty_char="▯", progress_char="▮")
    opWrapper.stop()
    if do_normalize:
        make_norms = False
        if paf_norms == None:
            make_norms = True
            paf_norms = []
        for i in range(6):
            if make_norms:
                paf_norms.append(paf_grid[i].max())
            # print(paf_grid.shape, len(paf_norms))
            paf_grid[i] /= paf_norms[i]
    if return_shape.upper() == '2D':
        paf_grid = reshape_pafs(paf_grid, grid_dims=grid_dims)
    time_end = time.time()
    print('Done. Time elapsed:', str(int(time_end - start_time)) + 's')
    print(str(np.around((time_end - start_time) / num_images, decimals=2)) + 's', 'per image')
    return paf_grid, paf_norms


kpts_angles_dict = dict(
    r_head=["REar", "Neck", "RShoulder"],
    l_head=["LEye", "Neck", "LShoulder"],
    r_arm=["RHip", "RShoulder", "RElbow"],
    l_arm=["LHip", "LShoulder", "LElbow"],
    r_forearm=["RShoulder", "RElbow", "RWrist"],
    l_forearm=["LShoulder", "LElbow", "LWrist"],
    r_leg=["RShoulder", "RHip", "RKnee"],
    l_leg=["LShoulder", "LHip", "LKnee"],
    r_calf=["RHip", "RKnee", "RAnkle"],
    l_calf=["LHip", "LKnee", "LAnkle"],
    r_foot=["RKnee", "RAnkle", "RBigToe"],
    l_foot=["LKnee", "LAnkle", "LBigToe"],
)

### WIP code for the version we talked about w/ Naselaris that measures angles between keypoints
# def angle_between(datum, *args):
#     """WIP code for body model based on angles between body keypoints,
#     rather than their spatial location.
#     """
#     # grid of combined body parts
#     combined_grid = np.zeros((500, 500))
#     kpts_list = body_kpts
#
#     # Checks whether kpts are not available (part not detected in image)
#     try:
#         for person in range(len(kpts)):
#             person_kpts = kpts[person]
#             if person_kpts.ndim == 2:
#                 person_kpts = person_kpts[np.newaxis, :, :]
#             # loops through both parts when there are two (only needed for R vs L hand)
#             for rl_part in range(person_kpts.shape[0]):
#                 rl_part_kpts = person_kpts[rl_part]
#                 # loops through each keypoint pair
#                 for i in range(len(args) - 1):
#                     if args[i] == 'break' or args[i + 1] == 'break':
#                         pass
#                     else:
#                         # row and col of max value (for interpolation)
#                         col_1, row_1, score1 = rl_part_kpts[kpts_list.index(args[i])]
#                         # row and col of max value (for interpolation)
#                         col_2, row_2, score2 = rl_part_kpts[kpts_list.index(args[i + 1])]
#                         # fill empty array with line between both keypoints
#                         interp_grid = np.zeros(combined_grid.shape)
#                         # Prevents drawing lines to default coordinates of (0,0)
#                         if row_1 * col_1 * row_2 * row_2 != 0:
#                             rr, cc, val = line_aa(int(row_1), int(col_1), int(row_2), int(col_2))
#                             mask = (rr < 500) * (cc < 500)
#                             rr = rr[mask]
#                             cc = cc[mask]
#                             val = val[mask]
#                             interp_grid[rr, cc] = val * 255
#                             # Blurs grid
#                             blurred_grid = gaussian_filter(interp_grid, sigma=10)
#                             # Combine interpolated grid with grid from other kpts for part
#                             combined_grid = np.maximum(combined_grid, blurred_grid)
#     except:
#         pass
#     return combined_grid


def quick_openpose(input_image):
    """Returns an openpose datum object generated w/ default values
    ran on a single image location.  Mostly for testing.
    
    Parameters
    ----------
    input_image : str
        Image filepath
    
    Returns
    -------
    datum object
        Openpose output
    """
    from openpose import pyopenpose as op
    params = dict(
        hand=True,
        face=True,
        heatmaps_add_parts=True,
        heatmaps_add_PAFs=True,
        model_folder=os.path.expanduser('~/Code/openpose/models/'),
    )

    opWrapper = op.WrapperPython()
    opWrapper.configure(params)
    opWrapper.start()
    datum = op.Datum()
    if isinstance(input_image, str):
        datum.cvInputData = cv2.imread(input_image)
    else:
        datum.cvInputData = input_image.copy()
    opWrapper.emplaceAndPop([datum])
    opWrapper.stop()
    return datum
