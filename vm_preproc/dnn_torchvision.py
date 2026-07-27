import numpy as np
import gc

try:
    import torch
    import torchvision.transforms as transforms
    from torchvision import models as pyt_models
except ImportError:
    print("No pytorch")
try:
    from vwam.utils import VWAMModel
    import vwam.utils as vwamutils
except:
    print("No VWAM: please download from https://github.com/MShinkle/VWAM")
# Configuration
DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
DTYPE = torch.float32

DEFAULT_NEGATIVE_FILTERS = ['dropout', 'AuxLogits']
 
# Define preprocessing
def proc_frames(frames, 
                img_size=299, 
                img_mean=(0.485, 0.456, 0.406),
                img_std=(0.229, 0.224, 0.225),
                ):
    """I think this is standard preprocessing of uint8 BGR frames for models trained on imagenet"""
    preprocess = transforms.Compose([
        transforms.Resize(img_size),
        transforms.CenterCrop(img_size),
        transforms.Normalize(mean=list(img_mean), std=list(img_std)),
    ])

    frames = frames[:,:,:,::-1].copy() # RGB to BGR, no negative strides for torch
    frames = torch.tensor(frames, dtype=DTYPE, device=DEVICE).permute(0, 3, 1, 2)
    frames = frames.float() / 255.0  # Normalize to [0,1]
    frames = preprocess(frames)
    return frames

def get_layers(model, negative_filters=DEFAULT_NEGATIVE_FILTERS, depth=2):
    """Enumerate all available layers of a model"""
    if negative_filters is None:
        negative_filters = []
    layers = vwamutils.iterate_children(model, depth=depth)
    
    layers_x = {name: layer for name, layer in layers.items()
                     if not any(filter_str in name for filter_str in negative_filters)}
    return layers_x

# Function to go from frames to activations (features)
def run_dnn_torchvision(frames,
                        model_str='inception_v3', 
                        weight_str='Inception_V3_Weights',
                        negative_filters=DEFAULT_NEGATIVE_FILTERS,
                        layer_depth=2,
                        flatten=True,
                        combine_layers=False,
                        layers=None,):
    """Process image stack (images or movies) to extract deep neural network features
    
    Tested models include:
    'alexnet'
    'inception_v3'

    """
    frames = proc_frames(frames)
    weights = getattr(pyt_models, weight_str)
    model = getattr(pyt_models, model_str)
    dnn_model = model(weights.DEFAULT).to(DEVICE).to(DTYPE).eval()
    output_pyt = {}
    output_np = {}
    all_layers = get_layers(dnn_model,
                            negative_filters=negative_filters,
                            depth=layer_depth,
                           )
    if layers is None:
        layers = list(all_layers.keys())
    layers_to_retrieve = dict((x, all_layers[x]) for x in layers)
    # Get activations
    with torch.no_grad():
        model_to_run = vwamutils.hook_model(dnn_model, output_pyt, layers_to_retrieve)
        model_to_run.forward(frames)
        for layer in layers:
            output_pyt[layer] = output_pyt[layer].detach().cpu()
            if flatten:
                output_pyt[layer] = output_pyt[layer].flatten(1)
            if not combine_layers:
                output_np[layer] = output_pyt[layer].numpy()
        if combine_layers:
            output_pyt = torch.cat([a for a in output_pyt.values()], dim=-1)
            output_np = output_pyt.numpy()
        
    del output_pyt
    del frames
    gc.collect()
    torch.cuda.empty_cache()
    return output_np

