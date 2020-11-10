import numpy as np
import cv2
import json
import glob

# faces--fill
faces_fill_idxs = (1,17,15,16,18,)
    
# trunks==fill
trunks_lines_idxs = (
    (1,2),
    (1,5),
    (1,8),
)
trunks_fill_idxs = (1,5,12,8,9,2,)
    
# arms--lines
arms_lines_idxs = (
(5,6),
(6,7),
(2,3),
(3,4),
)
    
# hands--circle
hands_point_idxs = (4,7,)
    
# legs--lines
legs_lines_idxs = (
(9,10),
(10,11),
(12,13),
(13,14),
)
    
# feet--fill
left_feet_fill_idxs = (11,23,22,24,)
right_feet_fill_idxs = (14,20,19,21,)

# Code to generate keypoint jsons should be something like this:
# ./build/examples/openpose/openpose.bin --video /hdd01/hdd_space/stimuli/VEDB/2020_08_23_22_27_12.mp4 --write_json /hdd01/matthew_sync/space/matt/BioMotion/features/VEDB/openpose/keypoints/ --face --hand --part_candidates --net_resolution 240x240 && ./build/examples/openpose/openpose.bin --video /hdd01/hdd_space/stimuli/VEDB/2020_09_14_13_54_11.mp4 --write_json /hdd01/matthew_sync/space/matt/BioMotion/features/VEDB/openpose/keypoints/ --face --hand --part_candidates --net_resolution 240x240

def kpts_to_parts(keypoints_dir, image_dims):
    jsons = sorted(glob.glob(keypoints_dir))
    print(len(jsons), "jsons found")
    pafs = np.empty((len(jsons), 1350))
    for filenum, filename in enumerate(jsons):
        with open(filename, "r") as f:
            kpts = f.read()
        exec(f"kpts = {kpts}")
        parts = np.zeros((6, image_dims[1], image_dims[0]))

        for person in kpts['people']:
            pose_kpts = np.array(person['pose_keypoints_2d']).astype(int)

            # Faces
            faces_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1]) for pt in faces_fill_idxs]
            faces_fill_pts = np.array([pts for pts in faces_fill_pts if 0 not in pts])
            if len(faces_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[0], points=np.array(faces_fill_pts).astype('int32'), color=(1,1,1));

            # Trunks
            for pair in trunks_lines_idxs:
                pt1=(pose_kpts[pair[0]*3],pose_kpts[pair[0]*3+1])
                pt2=(pose_kpts[pair[1]*3],pose_kpts[pair[1]*3+1])
                if not 0 in (*pt1, *pt2):
                    thickness = max(1, int(np.sum(np.diff((pt2,pt1),axis=0)**2)**.5/2))
                    cv2.line(img=parts[1], pt1=pt1, pt2=pt2, color=(1, 1, 1), thickness=thickness, )

            trunks_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1]) for pt in trunks_fill_idxs]
            trunks_fill_pts = np.array([pts for pts in trunks_fill_pts if 0 not in pts])
            if len(trunks_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[1], points=np.array(trunks_fill_pts).astype('int32'), color=(1,1,1));

            # Arms
            for pair in arms_lines_idxs:
                pt1=(pose_kpts[pair[0]*3],pose_kpts[pair[0]*3+1])
                pt2=(pose_kpts[pair[1]*3],pose_kpts[pair[1]*3+1])
                if not 0 in (*pt1, *pt2):
                    thickness = max(1, int(np.sum(np.diff((pt2,pt1),axis=0)**2)**.5/2.5))
                    cv2.line(img=parts[2], pt1=pt1, pt2=pt2, color=(1, 1, 1), thickness=thickness, )

            # Hands
            for hand in hands_point_idxs:
                pt=(pose_kpts[hand*3],pose_kpts[hand*3+1])
                if 0 not in pt:
                    cv2.circle(parts[3], pt, 10, color=(1, 1, 1), thickness=thickness)

            # Legs
            for pair in legs_lines_idxs:
                pt1=(pose_kpts[pair[0]*3],pose_kpts[pair[0]*3+1])
                pt2=(pose_kpts[pair[1]*3],pose_kpts[pair[1]*3+1])
                if not 0 in (*pt1, *pt2):
                    thickness = max(1, int(np.sum(np.diff((pt2,pt1),axis=0)**2)**.5/2))
                    cv2.line(img=parts[4], pt1=pt1, pt2=pt2, color=(1, 1, 1), thickness=thickness, )

            # Feet
            left_feet_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1]) for pt in left_feet_fill_idxs]
            left_feet_fill_pts = np.array([pts for pts in left_feet_fill_pts if 0 not in pts])
            if len(left_feet_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[5], points=np.array(left_feet_fill_pts).astype('int32'), color=(1,1,1));

            right_feet_fill_pts = [(pose_kpts[pt*3], pose_kpts[pt*3+1]) for pt in right_feet_fill_idxs]
            right_feet_fill_pts = np.array([pts for pts in right_feet_fill_pts if 0 not in pts])
            if len(right_feet_fill_pts) != 0:
                cv2.fillConvexPoly(img=parts[5], points=np.array(right_feet_fill_pts).astype('int32'), color=(1,1,1));
        pafs[filenum] = np.array([cv2.resize(part, (15,15), interpolation=cv2.INTER_AREA).flatten() for part in parts]).flatten()
    return pafs