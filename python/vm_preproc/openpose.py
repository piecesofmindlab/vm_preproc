import numpy as np
import cv2
import json
import glob
import scipy
import h5py

# faces--fill
faces_fill_idxs = (1, 17, 15, 16, 18,)

# trunks==fill
trunks_lines_idxs = (
    (1, 2),
    (1, 5),
    (1, 8),
)
trunks_fill_idxs = (1, 5, 12, 8, 9, 2,)

# arms--lines
arms_lines_idxs = (
    (5, 6),
    (6, 7),
    (2, 3),
    (3, 4),
)

# hands--circle
hands_point_idxs = (4, 7,)

# legs--lines
legs_lines_idxs = (
    (9, 10),
    (10, 11),
    (12, 13),
    (13, 14),
)

# feet--fill
left_feet_fill_idxs = (11, 23, 22, 24,)
right_feet_fill_idxs = (14, 20, 19, 21,)

# Code to generate keypoint jsons should be something like this:
# ./build/examples/openpose/openpose.bin --video /stimulus/directory/2020_08_23_22_27_12.mp4 --write_json /keypoints/save/location/ --face --hand --part_candidates --net_resolution 240x240


def check_same_line(points):
    """Checks whether all rows describe points on the same line

    Parameters
    ----------
    points : np.ndarray
        n_points x 2 array of points

    Returns
    -------
    bool
        Whether or not all points lie on the same line
    """
    x0, y0 = points[0]
    points = [(x, y) for x, y in points if x !=
              x0 or y != y0]      # Other points
    slopes = [(y-y0)/(x-x0) if x != x0 else None for x,
              y in points]  # None for vertical Line
    return all(s == slopes[0] for s in slopes)


def check_convex_points(kpts):
    """Checks whether face or hand keypoints can be successfully passed
    through scipy.spatial.ConvexHull.

    Parameters
    ----------
    kpts : np.ndarray
        n_kpts X 2 array of keypoint locations

    Returns
    -------
    bool
        Whether or not keypoints can be used in scipy.spatial.ConvexHull
    """
    valid = True
    # Make sure there are at least 3 different points
    valid *= len(np.unique(kpts, axis=0)) >= 3
    # Make sure all points are not on the same line
    valid *= not check_same_line(kpts)
    return valid


def kpts_to_parts(keypoints_dir, image_shape, parts_dim=15, use_face_kpts=True, use_hand_kpts=True, use_body_face_kpts=False, use_body_hand_kpts=False, downsampling='max_pooling'):
    """Converts a directory of saved openpose keypoints into a 3d array of downsampled body features.

    Parameters
    ----------
    keypoints_dir : str
        Location from which to read all keypoint jsons.
    image_shape : tuple
        Tuple of (n_row_pixels, n_col_pixels)
    parts_dim : int, optional
        Dimension of body features--e.g. 15 will yield 6 x 15 x 15 = 1350 features.
    use_face_kpts : bool, optional
        Whether to draw faces based on more detailed face keypoints. Openpose call must have included --face
    use_hand_kpts : bool, optional
        Whether to draw hands based on more detailed hand keypoints. Openpose call must have included --hand
    use_body_face_kpts : bool, optional
        Whether to use body keypoints (neck, ears, etc) to draw faces.  If used with use_face_kpts, both will be drawn.
        Not preferred, due to counting of sides/backs of heads as faces.
    use_body_hand_kpts : bool, optional
        Whether to use body keypoints (wrists) to draw hands.  If used with use_hand_kpts, both will be drawn.
        Less precise than use_hand_kpts, simply drawing a circle at the wrist location rather than relying on actual
        'hand' features (fingers, etc).
    downsampling : str, optional
        Downsampling method from full-res to 15x15 body features.
        Leave default for max pooling, any other value will result in cv2.INTER_AREA downsampling.

    Returns
    -------
    TYPE
        Description
    """
    jsons = sorted(glob.glob(keypoints_dir +
                             ('*' if keypoints_dir[-1] == '/' else '/*')))
    print(len(jsons), "jsons found")
    part_features = np.empty((len(jsons), 6 * parts_dim**2))
    for filenum, filename in enumerate(jsons):
        with open(filename, "r") as f:
            kpts = f.read()
        json_acceptable_string = kpts.replace("'", "\"")
        kpts = json.loads(json_acceptable_string)
        parts = np.zeros((6, image_shape[1], image_shape[0]))

        for person in kpts['people']:
            pose_kpts = np.array(person['pose_keypoints_2d']).astype(int)
            # Faces
            if use_face_kpts:
                if len(person['face_keypoints_2d']) != 0:
                    face_kpts = person['face_keypoints_2d']
                    if len(face_kpts) != 0 and not np.all(np.array(face_kpts) == 0):
                        face_kpts = np.array(
                            face_kpts).reshape(-1, 3)[:, :2].astype(int)
                        if check_convex_points(face_kpts):
                            hull = scipy.spatial.ConvexHull(face_kpts)
                            cv2.fillConvexPoly(
                                img=parts[0], points=face_kpts[hull.vertices.T], color=(1, 1, 1))
            if use_body_face_kpts:
                faces_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1])
                                  for pt in faces_fill_idxs]
                faces_fill_pts = np.array(
                    [pts for pts in faces_fill_pts if 0 not in pts])
                if len(faces_fill_pts) != 0:
                    cv2.fillConvexPoly(img=parts[0], points=np.array(
                        faces_fill_pts).astype('int32'), color=(1, 1, 1))

            # Trunks
            for pair in trunks_lines_idxs:
                pt1 = (pose_kpts[pair[0]*3], pose_kpts[pair[0]*3+1])
                pt2 = (pose_kpts[pair[1]*3], pose_kpts[pair[1]*3+1])
                if not 0 in (*pt1, *pt2):
                    thickness = max(
                        1, int(np.sum(np.diff((pt2, pt1), axis=0)**2)**.5/2))
                    cv2.line(img=parts[1], pt1=pt1, pt2=pt2,
                             color=(1, 1, 1), thickness=thickness, )

            trunks_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1])
                               for pt in trunks_fill_idxs]
            trunks_fill_pts = np.array(
                [pts for pts in trunks_fill_pts if 0 not in pts])
            if len(trunks_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[1], points=np.array(
                    trunks_fill_pts).astype('int32'), color=(1, 1, 1))

            # Arms
            for pair in arms_lines_idxs:
                pt1 = (pose_kpts[pair[0]*3], pose_kpts[pair[0]*3+1])
                pt2 = (pose_kpts[pair[1]*3], pose_kpts[pair[1]*3+1])
                if not 0 in (*pt1, *pt2):
                    thickness = max(
                        1, int(np.sum(np.diff((pt2, pt1), axis=0)**2)**.5/2.5))
                    cv2.line(img=parts[2], pt1=pt1, pt2=pt2,
                             color=(1, 1, 1), thickness=thickness, )

            # Hands
            if use_hand_kpts:
                left_hand_kpts = person['hand_left_keypoints_2d']
                right_hand_kpts = person['hand_right_keypoints_2d']
                if len(left_hand_kpts) != 0 and not np.all(np.array(left_hand_kpts) == 0):
                    left_hand_kpts = np.array(
                        left_hand_kpts).reshape(-1, 3)[:, :2].astype(int)
                    if check_convex_points(left_hand_kpts):
                        hull = scipy.spatial.ConvexHull(left_hand_kpts)
                        cv2.fillConvexPoly(
                            img=parts[3], points=left_hand_kpts[hull.vertices.T], color=(1, 1, 1))
                if len(right_hand_kpts) != 0 and not np.all(np.array(right_hand_kpts) == 0):
                    right_hand_kpts = np.array(
                        right_hand_kpts).reshape(-1, 3)[:, :2].astype(int)
                    if check_convex_points(right_hand_kpts):
                        hull = scipy.spatial.ConvexHull(right_hand_kpts)
                        cv2.fillConvexPoly(
                            img=parts[3], points=right_hand_kpts[hull.vertices.T], color=(1, 1, 1))
            if use_body_hand_kpts:
                for hand in hands_point_idxs:
                    pt = (pose_kpts[hand*3], pose_kpts[hand*3+1])
                    if 0 not in pt:
                        cv2.circle(parts[3], pt, 10, color=(
                            1, 1, 1), thickness=thickness)

            # Legs
            for pair in legs_lines_idxs:
                pt1 = (pose_kpts[pair[0]*3], pose_kpts[pair[0]*3+1])
                pt2 = (pose_kpts[pair[1]*3], pose_kpts[pair[1]*3+1])
                if not 0 in (*pt1, *pt2):
                    thickness = max(
                        1, int(np.sum(np.diff((pt2, pt1), axis=0)**2)**.5/2))
                    cv2.line(img=parts[4], pt1=pt1, pt2=pt2,
                             color=(1, 1, 1), thickness=thickness, )

            # Feet
            left_feet_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1])
                                  for pt in left_feet_fill_idxs]
            left_feet_fill_pts = np.array(
                [pts for pts in left_feet_fill_pts if 0 not in pts])
            if len(left_feet_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[5], points=np.array(
                    left_feet_fill_pts).astype('int32'), color=(1, 1, 1))
            right_feet_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1])
                                   for pt in right_feet_fill_idxs]
            right_feet_fill_pts = np.array(
                [pts for pts in right_feet_fill_pts if 0 not in pts])
            if len(right_feet_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[5], points=np.array(
                    right_feet_fill_pts).astype('int32'), color=(1, 1, 1))
        # Downsampling
        if downsampling == 'max_pooling':
            downsampled = np.empty((6, parts_dim, parts_dim))
            splits = [np.array_split(split, parts_dim, axis=2)
                      for split in np.array_split(parts, parts_dim, axis=1)]
            for i in range(parts_dim):
                for j in range(parts_dim):
                    downsampled[:, i, j] = splits[i][j].max(1).max(1)
            part_features[filenum] = downsampled.flatten()
        else:
            part_features[filenum] = np.array([cv2.resize(
                part, (parts_dim, parts_dim), interpolation=cv2.INTER_AREA).flatten() for part in parts]).flatten()
    return part_features


def bvp_to_parts(session, parts_dim, basedir, downsampling='max_pooling'):
    part_features = []
    files = sorted(glob.glob(f'{basedir}/*x150x*{session}*'))
    for filename in files:
        with h5py.File(filename, "r") as f:
            full_data = np.array(f['data']).reshape(-1,6,150,150)
        for parts in full_data:
            downsampled = np.empty((6,parts_dim,parts_dim))
            splits = [np.array_split(split, parts_dim, axis=2) for split in np.array_split(parts, parts_dim, axis=1)]
            if downsampling == 'max_pooling':
                for i in range(parts_dim):
                    for j in range(parts_dim):
                        downsampled[:,i,j] = (splits[i][j].max(1).max(1) > 0).astype(int)
            else:
                for i, part in enumerate(parts):
                    downsampled[i] = cv2.resize(part, (parts_dim, parts_dim), interpolation=cv2.INTER_AREA)
            part_features.append(downsampled.flatten())
    return np.array(part_features)