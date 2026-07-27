# Compute optic flow using RAFT model

# Imports
import tqdm
import numpy as np
from matplotlib import colors
# PoM Lab Code
import file_io
from .normals import RET

# Soft imports
try:
    import torch
    import torchvision
except:
    # Soft import, just won't work
    pass

def run_optical_flow(s, center_crop=None, scale=512, tensor=True, normalize=False, device=None):
    """Compute optical flow with torchvision RAFT model

    By default uses large RAFT model. 

    Parameters:
    -----------
    s : array
        Input on which to compute optical flow (n_frames x vert x horiz x 3)
    center_crop : array-like or None
        center_crop to feed to torch transform of input (see file_io.get_xfm, 
        which creates a torch transform)
    scale : scalar
        scale parameter to pass to torch transform
    normalize : bool
        True or False, also passed to torch transform
    device : str or None
        'cuda' or 'cpu', if None defaults to 'cuda' if cuda is available

    Notes
    -----
    TBH not confident in my understanding of torch transforms and params passed to them.
    Default values here seem o do sensible things. Worth further exploration.
    
    """
    try:
        w = torchvision.models.optical_flow.Raft_Large_Weights.DEFAULT
    except:
        raise ImportError("You haven't got torchvision or the right version of torchvision installed to use this function!")
    transform_load = file_io.get_xfm(scale=scale,
                                     center_crop=center_crop, 
                                     tensor=tensor,
                                     normalize=normalize,
                                    )
    #F.resize(img1_batch, size=[520, 960], antialias=False
    transform_raft = w.transforms()
    if device is None:
        device = "cuda" if torch.cuda.is_available() else "cpu"
    net = torchvision.models.optical_flow.raft_large(weights=w, progress=True)
    _ = net.to(device)
    _ = net.eval()
    
    # Load data
    data_loader = file_io.ImageArray(s, transform=transform_load)
    x = torch.stack([data_loader[j][0] for j in range(len(s))])
    #print(x.shape)
    a, b = transform_raft(x[:-1], x[1:])
    #print(a.shape, b.shape)
    out = []
    for j in tqdm.tqdm(range(len(a))):
        list_of_flows = net(a[j:j+1].to(device), b[j:j+1].to(device))
        if device == 'cuda':
            out.append(list_of_flows[-1].detach().cpu().numpy())
        else:
            out.append(list_of_flows[-1].detach().numpy())
    return np.vstack(out)



def make_motion_image(mot, mot_max=None, cmap=RET):
    """Make a colorized visualization of pixelwise optical flow
    
    Parameters:
    -----------
    mot : array
        (2 x height x width) array of motion vectors per pixel; 
        first dimension is x, y motion
    mot_max : scalar or array
        maximum motion value for color mapping
    
    """
    x, y = mot
    flow_angle = np.arctan2(x,y)
    flow_mag = np.sqrt(x**2 + y**2)
    nrm_ang = colors.Normalize(vmin=-np.pi, vmax=np.pi)
    flow_angle_rgb = cmap(nrm_ang(flow_angle))
    
    if mot_max is None:
        mot_max = np.percentile(flow_mag, 99)
    nrm_mag = colors.Normalize(vmin=0, vmax=mot_max)
    flow_mag_value = nrm_mag(flow_mag)
    # Alternative 1: un-saturate colors based on flow magnitude
    #flow_angle_hsv = colors.rgb_to_hsv(flow_angle_rgb[...,:3])
    #flow_angle_hsv[...,1] = flow_mag_value
    # (would need to convert back to RGB here)

    # Alternative 2: add an alpha channel (only useful depending on what's behind it, so disfavored)
    #aa_im = np.dstack([flow_angle_rgb[...,:3], flow_mag_value])

    # Alternative 3: Manually alpha-blend in gray image based on flow magnitude (more flow, more saturation)
    aa_im = flow_angle_rgb[...,:3] * flow_mag_value[..., np.newaxis] +\
        np.ones_like(flow_angle_rgb[...,:3]) * 0.5 * (1-flow_mag_value[...,np.newaxis])
    # Add alpha channel to get rid of any nans
    aa_im = np.dstack([aa_im, 1-np.isnan(flow_mag_value).astype(np.float32)])
    return aa_im
    
