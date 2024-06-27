import numpy as np
import file_io
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


def dictlist_to_arraydict(dictlist):
    """Convert from pupil format list of dicts to dict of arrays"""
    dict_fields = list(dictlist[0].keys())
    out = {}
    for df in dict_fields:
        out[df] = np.array([d[df] for d in dictlist])
    return out


def find_checkerboard(
    video_file, 
    timestamp_file, 
    checkerboard_size=(6, 8), 
    scale=1.0, 
    start_frame=None,
    end_frame=None,
    batch_size=None,
    progress_bar=None
    ):
    """Use opencv to detect checkerboard pattern"""
    if progress_bar is None:
        def progress_bar(x, total=0): return x

    timestamps = np.load(timestamp_file)

    # termination criteria: Make inputs?
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
    n_frames_total, vdim, hdim, _ = file_io.list_array_shapes(video_file)
    if start_frame is None:
        start_frame = 0
    if end_frame is None:
        end_frame = n_frames_total
    if batch_size is None:
        # This variable might be better as an input
        max_batch_bytes = 1024**3 * 4  # 4 GB
        n_bytes = (vdim * scale) * (hdim * scale)
        batch_size = int(np.floor(max_batch_bytes / n_bytes))

    n_frames = end_frame - start_frame
    n_batches = int(np.ceil(n_frames / batch_size))
    output_dicts = []

    for batch in range(n_batches):
        print("Running batch %d/%d" % (batch+1, n_batches))
        batch_start = batch * batch_size + start_frame
        batch_end = np.minimum(batch_start + batch_size, end_frame)
        video_data = file_io.load_mp4(
            video_file, 
            frames=(batch_start, batch_end),
            size=scale,
            color='gray')

        for batch_frame, frame in enumerate(progress_bar(range(batch_start, batch_end))):
            # Find the chess board corners
            found_checkerboard, corners1 = cv2.findChessboardCorners(
                video_data[batch_frame], checkerboard_size, None)
            # If found, add object points, image points (after refining them)
            if found_checkerboard:
                # Fixed opencv parameters - revisit?
                winSize=(11, 11)
                zeroZone=(-1, -1)
                corners2 = cv2.cornerSubPix(
                    video_data[batch_frame], corners1, winSize, zeroZone, criteria)
                # Parse outputs (convert back to full-size pixels, and convert 
                # to 0-1 image coordinates for full checkerboard and centroid)
                corners = np.squeeze(corners2) / scale
                marker_position = np.mean(corners, axis=0)
                corners_normalized = corners / np.array([hdim, vdim])
                marker_position_normalized = np.mean(corners_normalized, axis=0)
                # Keep outputs
                tmp = dict(
                    timestamp=timestamps[frame],
                    location_full_checkerboard=corners,
                    norm_pos_full_checkerboard=corners_normalized,
                    location=marker_position,
                    norm_pos=marker_position_normalized,)
                output_dicts.append(tmp)
    
    return dictlist_to_arraydict(output_dicts)


def find_checkerboard_orig(
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
