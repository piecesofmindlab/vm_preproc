import numpy as np
import pandas as pd
import cv2 as cv
import tqdm
import time


def detect_checkerboard(timestamps, video_data, checkerboard_size=(6, 8), scale=None, progress_bar=tqdm.tqdm):
    """Use opencv to detect checkerboard pattern

    """
    rows, cols = checkerboard_size
    if np.ndim(video_data) == 3:
        vid_color = 'gray'
        n_frames, vdim, hdim = video_data.shape
    elif np.ndim(video_data) == 4:
        vid_color = 'color'
        n_frames, vdim, hdim, cdim = video_data.shape
    else:
        raise ValueError("`video_data` input must be a 3 or 4 dimensional array (")
    
    times = [] # frame timestamps for detected keypoints
    locations = []  # 2d points in image plane.
    mean_locations = [] # Mean 2d points in image plane

    # termination criteria
    criteria = (cv.TERM_CRITERIA_EPS + cv.TERM_CRITERIA_MAX_ITER, 30, 0.001)


    for frame_time, frame in progress_bar(zip(timestamps, video_data)):
        if vid_color == 'color':
            frame = cv.cvtColor(frame, cv.COLOR_RGB2GRAY)
        if scale is not None:
            scale_x, scale_y = scale
            frame = cv.resize(frame, None, fx=scale_x, fy=scale_y)
            vdim, hdim = frame.shape[:2]
        t0 = time.time()
        # Find the chess board corners
        ret, corners = cv.findChessboardCorners(frame, (6, 8), None)

        # If found, add object points, image points (after refining them)
        if ret:
            times.append(frame_time)
            corners = np.squeeze(corners)
            locations.append(corners)
            marker_position = np.mean(corners, axis=0)
            mean_locations.append(marker_position)
            
    return (np.asarray(x) for x in [times, mean_locations, locations])
