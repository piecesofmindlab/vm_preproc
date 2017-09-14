#!/usr/bin/python
from __future__ import print_function, division

import numpy as np
import torch
import torch.nn as nn
from torch.autograd import Variable
from torchvision import models as pytmodels

import time

# Module-ify me
from . import file_io as fio

### --- Base AlexNet model --- ###
alexnet_model = pytmodels.alexnet(pretrained=True)

class AlexNetLayer(nn.Module):
    """Allows feature output from different layers of Alexnet"""
    def __init__(self, layer, base_network=alexnet_model):
        """
        Parameters
        ----------
        base_network allows specification of modifications of AlexNet (e.g. fine tuning
        on other data)
        """
        super(AlexNetLayer, self).__init__()
        self.layer = layer
        #55 27
        if layer == 1:
            self.features = nn.Sequential(*(list(base_network.features.children())[:3]))
        elif layer == 2:
            self.features = nn.Sequential(*(list(base_network.features.children())[:6]))
        elif layer == 3:
            self.features = nn.Sequential(*(list(base_network.features.children())[:8]))
        elif layer == 4:
            self.features = nn.Sequential(*(list(base_network.features.children())[:10]))
        elif layer == 5:
            self.features = nn.Sequential(*(list(base_network.features.children())[:13]))
        # UNTESTED
        elif layer == 6:
            self.features = base_network.features
            self.classifier = nn.Sequential(*(list(base_network.classifier.children())[:3]))
        elif layer == 7:
            self.features = base_network.features
            self.classifier = nn.Sequential(*(list(base_network.classifier.children())[:-1]))
        else:
            raise NotImplementedError("Layer not supported")
       
    def forward(self, x):
        if self.layer <=5:
            x = self.features(x)
            #x = x.view(x.size(0), -1)
        else:
            x = self.features(x)
            x = x.view(x.size(0), -1)
            x = self.classifier(x)
            #x = x.view(x.size(0), -1)
        return x

def get_layer(ims, layer=1, model_class=AlexNetLayer, image_transform=None, 
    use_gpu=False, num_workers=3, **kwargs):
    """Currently for pre-trained alexnet only

    retrieves activations of alexnet for specified layer

    ims is a list of image file names"""

    # Get data (list of images)
    if isinstance(ims, list):
        ds = fio.ImageList(ims, classes=None, transform=image_transform)
    else:
        # Array
        ds = fio.ImageArray(ims, classes=None, transform=image_transform)
    data_loader = fio.DataLoader(ds, batch_size=50, shuffle=False, num_workers=num_workers)
    # Get nn model
    model = model_class(layer, **kwargs)
    if use_gpu:
        model = model.cuda()
    # Turn off training mode (unclear if this is necessary)
    model.train(False)
    # Preallocate variables & start timing    
    last_tic = time.time()
    iter_times = []
    all_outputs = []
    for ibatch, data in enumerate(data_loader):
        # Not strictly necessary for most purposes here to have labels right here with data...
        inputs, labels = data
        if use_gpu:
            inputs, labels = Variable(inputs.cuda(0)), Variable(labels.cuda(0))
        else:
            inputs, labels = Variable(inputs), Variable(labels)
        outputs = model(inputs)
        all_outputs.append(outputs.data.cpu().clone())
        # Print progress every {20} iterations
        if (ibatch > 0) and (ibatch % 20 == 0):
            #pdb.set_trace()
            iter_times.append(time.time() - last_tic)
            last_tic = time.time()
            avg_iter = np.mean(iter_times)
            print("{:06d}/{:06d}: t/20i = {:.2f}".format(ibatch, len(data_loader), avg_iter))

    features = torch.cat(all_outputs, dim=0).numpy()
    features = np.squeeze(features)
    return features
