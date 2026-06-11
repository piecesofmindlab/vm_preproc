from ultralytics import YOLO
import numpy as np
import pathlib
import cv2

from . import options


WEIGHT_PATH = pathlib.Path(options.usercfg).parent / 'model_weights'




def get_masks_from_result(r, H=600, W=600,
                          separate_instances=False,
                          mask_threshold=0.25,
                          ):
    mask = np.zeros((H, W)) > 1
    if r.masks is not None and len(r.masks.data) > 0:
        sm = r.masks.data.detach().cpu().numpy()  # (n_instances, mask_h, mask_w)
        if separate_instances:
            raise NotImplementedError("separate_instances=True not implemented yet")
            n_masks = len(sm)
            mask = np.zeros((n_masks, H, W))
        for inst in sm:
            if inst.shape != (H, W):
                inst = cv2.resize(inst, (W, H), interpolation=cv2.INTER_NEAREST)
            mask |= (inst > MASK_THRESHOLD)
    return mask

def run_yolov12_bodies(data, 
                       person_class=0,
                       H=600,
                       W=600,
                       model_str='yolov12x-seg.pt',
                       mask_threshold=0.25,
                       verbose=False):
   # Segmentation model
    yolo_model_path = WEIGHT_PATH / model_str
    assert yolo_model_path.exists(), 'You have to download yolov12x-seg.pt into ~/.config/vm_preproc/model_weights/ for this to work!\nfind it here: https://github.com/sunsmarterjie/yolov12'
    model = YOLO(str(yolo_model_path))

    result = model.predict(list(data), classes=[person_class], verbose=verbose)
    
    masks = np.asarray([get_masks_from_result(r, H=H, W=W, mask_threshold=mask_threshold) for r in result])
    return masks