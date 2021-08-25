import numpy as np
import cv2
import tqdm


def arraydict_to_dictlist(arraydict):
    """Convert from dict of arrays to pupil format list of dicts"""
    dict_fields = list(arraydict.keys())
    first_key = dict_fields[0]
    n = len(arraydict[first_key])
    out = []
    for j in range(n):
        frame_dict = {}
        for k in dict_fields:
            value = arraydict[k][j]
            if isinstance(value, np.ndarray):
                value = value.tolist()
            frame_dict[k] = value
        out.append(frame_dict)
    return out


def detect_checkerboard(timestamps, video_data, checkerboard_size=(6, 8), scale=None, progress_bar=tqdm.tqdm):
    """Use opencv to detect checkerboard pattern

    """
    rows, cols = checkerboard_size
    n_frames, vdim, hdim = video_data.shape[:3]
    
    times = [] # frame timestamps for detected keypoints
    locations = []  # 2d points in image plane.
    mean_locations = [] # Mean 2d points in image plane

    # termination criteria: Make inputs?
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

    n_iter = min([len(timestamps), len(video_data)])
    for frame_time, frame in progress_bar(zip(timestamps, video_data), total=n_iter):
        if np.ndim(video_data) == 4:
            # Color image; remove color
            # TODO: add option for BGR image?
            frame = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
        if scale is not None:
            scale_x, scale_y = scale
            frame = cv2.resize(frame, None, fx=scale_x, fy=scale_y)
            vdim, hdim = frame.shape[:2]
        # Find the chess board corners
        ret, corners = cv2.findChessboardCorners(frame, checkerboard_size, None)
        # If found, add object points, image points (after refining them)
        if ret:
            times.append(frame_time)
            corners = np.squeeze(corners)
            locations.append(corners)
            marker_position = np.mean(corners, axis=0)
            mean_locations.append(marker_position)
            
    return (np.asarray(x) for x in [times, mean_locations, locations])


def find_checkerboard(
    video_data, timestamps=None, checkerboard_size=(6, 8), scale=None, progress_bar=None
):
    """Use opencv to detect checkerboard pattern"""
    if progress_bar is None:
        progress_bar = lambda x, total=0: x
    if scale is None:
        scale = 1.0
    rows, cols = checkerboard_size
    n_frames, vdim, hdim = video_data.shape[:3]
    times = []  # frame timestamps for detected keypoints
    locations = []  # 2d points in image plane.
    norm_pos = []  # 2d normalized points in image plane.
    mean_locations = []  # Mean 2d points in image plane
    mean_norm_pos = []  # Mean 2d normalized points in image plane
    
    # termination criteria: Make inputs?
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

    n_iter = min([len(timestamps), len(video_data)])
    for frame_time, frame in progress_bar(zip(timestamps, video_data), total=n_iter):
        if np.ndim(video_data) == 4:
            # Color image; remove color
            # TODO: add option for BGR image?
            # color_frame = copy.deepcopy(cv2.resize(frame, None, fx=scale, fy=scale))
            # color_frame = cv2.cvtColor(color_frame, cv2.COLOR_RGB2BGR)
            frame = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
        if isinstance(scale, (list,tuple)):
            scale_x, scale_y =  scale
            scale_factor_x = scale_x / frame.shape[1]
            scale_factor_y = scale_y / frame.shape[0]
            assert scale_factor_x == scale_factor_y
            scale_factor = scale_factor_x
            frame = cv2.resize(frame, None, fx=scale_x, fy=scale_y)
        else:
            if scale < 1:
                frame = cv2.resize(frame, None, fx=scale, fy=scale)
            scale_factor = scale
            vdim, hdim = frame.shape[:2]
        # Find the chess board corners
        ret, corners = cv2.findChessboardCorners(frame, checkerboard_size, None)
        # If found, add object points, image points (after refining them)
        if ret:
            corners2 = cv2.cornerSubPix(frame, corners, (11, 11), (-1, -1), criteria)
            times.append(frame_time)
            corners = np.squeeze(corners2)
            # Draw and display the corners
            # frame = cv2.drawChessboardCorners(color_frame, (6, 8), corners, ret)
            # corners[:, 0] = corners[:, 0] * (1 / scale)
            # corners[:, 1] = corners[:, 1] * (1 / scale)
            locations.append(corners * 1 / scale_factor)
            marker_position = np.mean(corners * 1 / scale_factor, axis=0)
            mean_locations.append(marker_position)
            corners_normalized = corners / np.array([hdim, vdim])
            norm_pos.append(corners_normalized)
            marker_position_normalized = np.mean(corners_normalized, axis=0)
            mean_norm_pos.append(marker_position_normalized)

    reference_dict = {}
    reference_dict['location_full_checkerboard'] = np.asarray(locations)
    reference_dict['norm_pos_full_checkerboard'] = np.asarray(norm_pos)
    reference_dict['location'] = np.asarray(mean_locations)
    reference_dict['norm_pos'] = np.asarray(mean_norm_pos)
    reference_dict['timestamp'] = np.asarray(times)
    out = arraydict_to_dictlist(reference_dict)
    return out
