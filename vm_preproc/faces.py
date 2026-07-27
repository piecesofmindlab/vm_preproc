# Detect face bounding boxes with mediapipe
import matplotlib.pyplot as plt
import mediapipe as mp
import numpy as np
from . import options
from . import image
import copy
import os

BaseOptions = mp.tasks.BaseOptions
FaceDetector = mp.tasks.vision.FaceDetector
FaceDetectorOptions = mp.tasks.vision.FaceDetectorOptions
VisionRunningMode = mp.tasks.vision.RunningMode


def _process_detection(detections, image_size):
    """process detections from mediapipe bounding boxes
    """
    out = []
    for d in detections:
        this_detection = dict(
            bbox=[d.bounding_box.origin_x / image_size[1], 
                  d.bounding_box.origin_y / image_size[0],
                  d.bounding_box.width / image_size[1],
                  d.bounding_box.height / image_size[0]],
            kpts=[(d.x, d.y) for d in d.keypoints],
                  )
        out.append(this_detection)
    return out

def run_mediapipe_faces(data, model_name='blaze_face_full_range.tflite', mode='image'):
    """Detect faces using mediapipe

    Parameters
    ----------
    data : array
        image data to be processed, (frames, ht, wid, color)
    model_name : str, optional
        mediapipe model to use, by default 'blaze_face_full_range.tflite'
    mode : str, optional
        mediapipe mode, by default 'image'

    Returns
    -------
    output
        list of mediapipe outputs
    """
    model_path = os.path.join(options.userdir, 'model_weights', model_name)
    if mode=='image':
        running_mode = VisionRunningMode.IMAGE
    elif mode == 'video':
        running_mode = VisionRunningMode.VIDEO
    # Create a face detector instance with the image mode:
    mp_options = FaceDetectorOptions(
        base_options=BaseOptions(model_asset_path=model_path),
        running_mode=running_mode)
    
    detector = FaceDetector.create_from_options(mp_options)
    n_frames = data.shape[0]
    out = []
    for fr in range(n_frames):
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=data[fr])
        face_detector_result = detector.detect(mp_image)
        out.append(_process_detection(face_detector_result.detections, data[fr].shape))

    return out

def scale_detections(result, scale_factor):
    """Resize face bounding box in results

    Parameters
    ----------
    result : list
        output from run_mediapipe_faces
    scale_factor : scalar
        scaling factor for bounding boxes

    Returns
    -------
    result
        same as input but w/ scaled bounding boxes
    """
    out = []
    for j in range(len(result)):
        d = result[j]
        tmp = copy.deepcopy(d)
        x, y, w, h = tmp['bbox']
        x = x - w * (scale_factor - 1) * 0.5
        y = y - h * (scale_factor - 1) * 0.5
        w = w * scale_factor
        h = h * scale_factor
        tmp['bbox'] = [x, y, w, h]
        out.append(tmp)
    return out



def show_face_boxes(stimulus, result, ax=None,
                    scale_factor=1, extent=(0, 1, 1, 0)):
    """visualize bounding boxes for faces detected by run_mediapipe_faces

    Parameters
    ----------
    stimulus : array (image)
        array to display, or None if no display is desired
    result : list
        output of run_mediapipe_faces
    ax : axis, optional
        axis into which to plot, by default None
    scale_factor : int, optional
        scaling factor for face boxes, by default 1
    extent : tuple, optional
        extent of space into which to plot, as in plt.imshow, by default (0, 1, 1, 0)
    """
    if ax is None:
        fig, ax = plt.subplots()
    if stimulus is not None:
        ax.imshow(stimulus, extent=extent)
    tmp = scale_detections(result, scale_factor)
    for d in tmp:
        x, y, w, h = d['bbox']
        rect = plt.Rectangle([x,y], w, h, edgecolor=(1,0.95, 0), facecolor=(0,0,0,0))
        ax.add_patch(rect)

def separate_face_masks(body_masks, faces, scale=(15,15), face_scale_factor=2, 
                        func_name='numpy.max', flatten=False):
    """Use face boxes to separate out face masks from body masks

    Parameters
    ----------
    body_masks : array
        (frames x v x h), bool array of masks for bodies
    faces : list
        output of `run_mediapipe_faces`, bounding boxes and keypoints for faces
    scale : tuple, optional
        size in units of output, by default (15,15)
    face_scale_factor : int, optional
        how much to scale face boxes by, by default 2
    func_name : str, optional
        downsampling function for boxes, by default 'numpy.max'
    flatten : bool, optional
        whether to flatten output array, by default False

    Returns
    -------
    body_model
        (time x 2 x [scale]) masks for faces and bodies
    """
    block_size=(np.asarray(body_masks.shape[1:3]) / np.asarray(scale)).astype(int).tolist()
    out = []
    for bmask, fbox in zip(body_masks, faces):
        face_mask = bboxes_to_masks(bmask, fbox, scale_factor=face_scale_factor)
        bm_tmp = bmask.copy()
        bm_tmp[face_mask] = False
        face_grid = image.spatial_downsample(face_mask, flatten=flatten, block_size=block_size, func_name=func_name)
        body_grid = image.spatial_downsample(bm_tmp, flatten=flatten, block_size=block_size, func_name=func_name)
        if flatten:
            out.append(np.hstack([face_grid, body_grid]))
        else:
            out.append(np.dstack([face_grid, body_grid]))
    return np.asarray(out)