# Detect face bounding boxes with mediapipe

import mediapipe as mp
from . import options
import os

BaseOptions = mp.tasks.BaseOptions
FaceDetector = mp.tasks.vision.FaceDetector
FaceDetectorOptions = mp.tasks.vision.FaceDetectorOptions
VisionRunningMode = mp.tasks.vision.RunningMode


def run_mediapipe_faces(data, model_name='blaze_face_full_range.tflite', mode='image'):
    model_path = os.path.join(options.userdir, 'model_weights', model_name)
    if mode=='image':
        running_mode = VisionRunningMode.IMAGE
    elif mode == 'video':
        running_mode = VisionRunningMode.VIDEO
    # Create a face detector instance with the image mode:
    options = FaceDetectorOptions(
        base_options=BaseOptions(model_asset_path=model_path),
        running_mode=running_mode)
    
    detector = FaceDetector.create_from_options(options)
    n_frames = data.shape[0]
    out = []
    for fr in range(n_frames):
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=data[fr])
        face_detector_result = detector.detect(mp_image)
        out.append(face_detector_result)
    return out