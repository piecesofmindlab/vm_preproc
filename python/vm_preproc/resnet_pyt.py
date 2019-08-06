#!/usr/bin/python
from __future__ import print_function, division
from collections import defaultdict
import numpy as np
import torch
import torch.nn as nn
from torch.autograd import Variable
from torchvision import models as pytmodels

import time

# Module-ify me
from . import file_io as fio


def get_layer(ims, layers=('maxpool',), model=None, image_transform=None, 
    use_gpu=False, num_workers=3, data_loader=None):
    """Retrieves activations of ResNet for specified layer(s)

    Only works for top-level layers (for now). 

    Parameters
    ----------
    ims : list image file names or an array of images
        Input image to process. Array of images should be RGB images w/ 
        pixel values in [0-1]
    layers : tuple or list
        list of layers to include in output. Best done one layer at a time for
        memory's sake, maybe.
    model : resnet model from torchvision.models
        if None defaults to resnet34; not pre-loaded to save memory

    """

    all_outputs = defaultdict(list)
    # Convert data to pytorch variable
    if isinstance(ims, list):
        if data_loader is None:
            data_loader = fio.pil_loader
        ds = fio.ImageList(ims, classes=None, transform=image_transform, loader=data_loader)
    else:
        ds = fio.ImageArray(ims, classes=None, transform=image_transform)
    # Make modifiable?
    data_loader = fio.DataLoader(ds, batch_size=50, shuffle=False, num_workers=num_workers)
    # Get nn model
    if model is None:
        model = pytmodels.resnet34(pretrained=True)
    # Hook function
    def layer_hook(module, input, output):
        layer_outputs.append(output)
    # Graphics card or no
    if use_gpu:
        model = model.cuda()
    # Turn off training mode (unclear if this is necessary)
    _ = model.train(False)
    # Preallocate variables & start timing    
    last_tic = time.time()
    iter_times = []
    all_outputs = defaultdict(list)
    for ibatch, data in enumerate(data_loader):
        # Add hooks for layers
        layer_outputs = [] # Define in loop to over-write previous values
        hooks = []
        # Instantiate specific hook for each layer (?)
        for layer in layers:
            tmp = getattr(model, layer).register_forward_hook(layer_hook)
            hooks.append(tmp)
        #print('n hooks:', len(hooks))
        # Not strictly necessary for most purposes here to have labels right here with data...
        inputs, labels = data
        if use_gpu:
            inputs, labels = Variable(inputs.cuda(0), volatile=True), Variable(labels.cuda(0), volatile=True)
        else:
            inputs, labels = Variable(inputs), Variable(labels)
        final_output = model(inputs)
        for h in hooks:
            h.remove()
        # print('len(layer_outputs):', len(layer_outputs))
        for layer, o in zip(layers, layer_outputs):
            all_outputs[layer].append(o.data.cpu().clone())
        # Print progress every {20} iterations
        if (ibatch > 0) and (ibatch % 20 == 0):
            #pdb.set_trace()
            iter_times.append(time.time() - last_tic)
            last_tic = time.time()
            avg_iter = np.mean(iter_times)
            print("{:06d}/{:06d}: t/20i = {:.2f}".format(ibatch, len(data_loader), avg_iter))
    features = {}
    for layer in layers:
        features[layer] = torch.cat(all_outputs[layer], dim=0).numpy()
        features[layer] = np.squeeze(features[layer])
    if len(layers)==1:
        # Return single if only one requested
        features = features[layer]
    return features
