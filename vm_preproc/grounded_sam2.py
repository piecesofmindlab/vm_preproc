"""Text to mask code, depends on Grounded SAM version 2: 
https://github.com/IDEA-Research/Grounded-SAM-2?tab=readme-ov-file#grounded-sam-2-florence-2-image-demo-updating
"""
import time
from PIL import Image
import numpy as np
try:
    import pathlib
    # Relaxing hard-coded location would be better.
    CODE_DIR = pathlib.Path('~/Code/Grounded-SAM-2').expanduser()
    if not CODE_DIR.exists():
        raise ImportError('No Grounded-SAM-2.')
    import sys
    sys.path.append(str(CODE_DIR ))
    # Soft dependencies 
    import torch
    import supervision as sv
    from torchvision.ops import box_convert
    # SAM 2
    from sam2.build_sam import build_sam2
    from sam2.sam2_image_predictor import SAM2ImagePredictor
    # Grounding Dino
    from grounding_dino.groundingdino.util.inference import load_model, predict
    from grounding_dino.groundingdino.datasets import transforms as T
except:
    print("Some imports failed.")
    raise
# Silence extremely verbose output by default
import logging
logger = logging.getLogger()
logger.setLevel(logging.ERROR)

def _process_image(image, scale_to=425, max_size=425):
    """Process inputs by scaling, normalizing, and converting to tensor
    
    Scale is arbtirary, scaled for NSD dataset. RandomResize is following
    a demo online here (), but seems like the wrong move. 
    
    Parameters
    ----------
    """
    transform = T.Compose(
        [
            T.RandomResize([scale_to], max_size=max_size),
            T.ToTensor(),
            T.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
        ]
    )
    image_transformed, _ = transform(Image.fromarray(image), None)
    return image, image_transformed

def text_to_mask(images, 
              text = "sky.",
              text_extra_categories='',
              combine_instances=True,
              fixed_size=True,
              sam2_checkpoint=str(CODE_DIR / "checkpoints/sam2_hiera_large.pt"),
              sam2_config_path = "sam2_hiera_l.yaml",
              # Renameme: this is grounding dino checkpoint
              gdino_checkpoint_path=str(CODE_DIR / "gdino_checkpoints/groundingdino_swint_ogc.pth"),
              gdino_config_path=str(CODE_DIR / "grounding_dino/groundingdino/config/GroundingDINO_SwinT_OGC.py"),
              #model_id = "IDEA-Research/grounding-dino-tiny",
              progress_bar=None,
             ):
    if progress_bar is None:
        progress_bar = lambda x: x
    # Outputs
    masks_out = []
    scores_out = []
    logits_out = []
    labels_out = []
    # Prep
    device = "cuda" if torch.cuda.is_available() else "cpu"
    # Build grounding dino model
    grounding_model = load_model(
        model_config_path=gdino_config_path, 
        model_checkpoint_path=gdino_checkpoint_path,
        device=device
    )
    # Build SAM model
    sam2_model = build_sam2(sam2_config_path, sam2_checkpoint, device="cuda")
    # Make IMAGE mask generator based on that model
    sam2_predictor = SAM2ImagePredictor(sam2_model)
    n_images = images.shape[0]
    for fr in progress_bar(range(n_images)):
        image_input = images[fr]
        image_source, image = _process_image(image_input)
       
        # Grounding dino model
    
        try:
            t0b = time.time()
            boxes, confidences, labels = predict(
                model=grounding_model,
                image=image,
                caption=text,
                box_threshold=0.35,
                text_threshold=0.25)
            t1b = time.time()
            
            # process the box prompt for SAM 2
            h, w, _ = image_source.shape
            boxes = boxes * torch.Tensor([w, h, w, h])
            input_boxes = box_convert(boxes=boxes, in_fmt="cxcywh", out_fmt="xyxy").numpy()
            confidences = confidences.numpy().tolist()
            class_names = labels
            #class_ids = np.array(list(range(len(class_names))))
            labels = [
                f"{class_name} {confidence:.2f}"
                for class_name, confidence
                in zip(class_names, confidences)
            ]

            t0i = time.time()
            # Feed image to image mask generator
            sam2_predictor.set_image(image_source)
            t1i = time.time()
            #print(f'Image processed in {t1b-t0b:.2f}, {t1i-t0i:.2f} seconds')

            # FIXME: figure how does this influence the G-DINO model
            with torch.autocast(device_type="cuda", dtype=torch.bfloat16):
                if torch.cuda.get_device_properties(0).major >= 8:
                    # turn on tfloat32 for Ampere GPUs (https://pytorch.org/docs/stable/notes/cuda.html#tensorfloat-32-tf32-on-ampere-devices)
                    torch.backends.cuda.matmul.allow_tf32 = True
                    torch.backends.cudnn.allow_tf32 = True

                masks, scores, logits = sam2_predictor.predict(
                    point_coords=None,
                    point_labels=None,
                    box=input_boxes,
                    multimask_output=False,
                )
            # convert the shape to (n, H, W)
            if masks.ndim == 4:
                masks = masks.squeeze(1)
            masks_out.append(masks)
            scores_out.append(scores)
            logits_out.append(logits)
            labels_out.append(labels)
        except:
            masks_out.append(None)
            scores_out.append(None)
            logits_out.append(None)
            labels_out.append(None)
    # Concatenate masks for output
    # TODO: filter by confidence?
    # TODO: option to sensibly reinforce flicker-y masks across frames?
    # Split labels at periods
    all_labels = [x.strip() for x in text.split('.')]
    all_labels = [x for x in all_labels if len(x) > 1]
    # Preallocate output
    output = np.zeros((len(masks_out), len(all_labels), h, w), dtype=bool)
    for j, (msk, lab) in enumerate(zip(masks_out, labels_out)):
        if msk is None:
            continue
        for li, ll in enumerate(lab):
            mi, = np.nonzero([x in ll for x in all_labels])
            output[j, mi] = msk[li] > 0 
    return output #masks_out, scores_out, logits_out, labels_out
