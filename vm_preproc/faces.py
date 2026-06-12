# Detect face bounding boxes with mediapipe

import mediapipe as mp
from . import options
import os

BaseOptions = mp.tasks.BaseOptions
FaceDetector = mp.tasks.vision.FaceDetector
FaceDetectorOptions = mp.tasks.vision.FaceDetectorOptions
VisionRunningMode = mp.tasks.vision.RunningMode


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
        out.append(face_detector_result)
    return out