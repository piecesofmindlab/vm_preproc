# Imports

import numpy as np
from PIL import Image
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms

def pil_loader(path):
    return Image.open(path).convert('RGB')

# Transforms for data input
def get_xfm(scale=224, center_crop=None, tensor=True, normalize=True, **kwargs):
    """Get pytorch transform for input images
    
    kwargs are meant to be optional inserts into transform sequence, inserted one by one
    into the list (indices in list are given by dict keys) Not working yet.
    """
    xfmlist = []
    if (scale is not None) and (scale is not False):
        xfmlist.append(transforms.Scale(scale))
    if (center_crop is not None) and (center_crop is not False):
        xfmlist.append(transforms.CenterCrop(center_crop))
    if (tensor is not None) and (tensor is not False):
        xfmlist.append(transforms.ToTensor())
    if (normalize is not None) and (normalize is not False):
        if normalize is True:
            # Default values from ImageNet
            xfmlist.append(transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]))
        else:
            # User-specified normalization values
            xfmlist.append(transforms.Normalize(*normalize))
    xfm = transforms.Compose(xfmlist)
    return xfm

default_xfm = get_xfm()

class ImageList(Dataset):
    """Class to load images with no classes / labels, for simple feature extraction"""
    def __init__(self, images, classes=None, transform=None, target_transform=None,
                 loader=pil_loader):
        """Class to load images

        Parameters
        ----------
        images : list
            List of image file names to load
        classes : list | array
            
        transform : torch transform
            Set of operations to perform on data as it is loaded
        """
        if transform is None:
            transform = default_xfm
        if classes is None:
            classes = np.zeros((len(images),),dtype=np.int)
        self.imgs = list(zip(images, classes))
        self.transform = transform
        self.target_transform = target_transform
        self.loader = loader

    def __getitem__(self, index):
        path, target = self.imgs[index]
        img = self.loader(path)
        if self.transform is not None:
            img = self.transform(img)
        if self.target_transform is not None:
            target = self.target_transform(target)

        return img, target

    def __len__(self):
        return len(self.imgs)

class SimpleImageFolder(Dataset):
    """Class to load images with no classes / labels, for simple feature extraction"""
    def __init__(self, images, transform=default_xfm, target_transform=None,
                 loader=pil_loader):
        """Class to load images

        Parameters
        ----------
        images : list
            List of image file names to load
        transform : torch transform
            Set of operations to perform on data as it is loaded
            see module transforms.py
        """
        self.imgs = zip(images, np.zeros((len(images),),dtype=np.int))
        self.transform = transform
        self.target_transform = target_transform
        self.loader = loader

    def __getitem__(self, index):
        path, target = self.imgs[index]
        img = self.loader(path)
        if self.transform is not None:
            img = self.transform(img)
        if self.target_transform is not None:
            target = self.target_transform(target)

        return img, target

    def __len__(self):
        return len(self.imgs)

class ImageFolder(Dataset):
    """Load images based on text file of image file names + classification categories"""
    def __init__(self, list_file, transform=default_xfm, target_transform=None,
                 loader=pil_loader, class_to_idx=None):
        """Load images based on text file of image file names + classification categories

        Parameters
        ----------
        list_file : string
            file name for list of images to load. File should be formatted as:
            image_file.ext <space> target_class
            (one row per image to be loaded)
        transform : pytorch transform series
            series of transforms (clipping, rotation, normalization, mapping to tensor, etc)
            to be applied to images at load time.
        target_tranform : transformation of target
            Map target to potential other target class
        loader : pytorch loader
            ...
        class_to_idx : dict
            dictionary to map classes to class numbers (classification target indices)
            if not provided, attempts to read from file structure; if it fails, set to None
        """
        images = []
        lines = file(list_file).read().split("\n")
        do_class_to_idx = class_to_idx is None
        if do_class_to_idx:
            class_to_idx = {}
        imgs = []
        for l in lines:
            if not l.strip():
                continue
            fname, label_num = l.split(" ")
            label_num = int(label_num)
            if do_class_to_idx:
                try:
                    fnComps = fname.split("/")
                    class_name = "_".join(fnComps[-2].split("_")[:-1])
                    class_to_idx[class_name] = label_num
                except:
                    # No class_to_idx dict definable
                    pass
            imgs.append((fname,label_num))
        try:
            classes = class_to_idx.keys()
            classes.sort(key=lambda x:class_to_idx[x])
        except:
            print("Failed to find class names")
            classes = []
        self.imgs = imgs
        self.classes = classes
        self.class_to_idx = class_to_idx
        self.transform = transform
        self.target_transform = target_transform
        self.loader = loader

    def __getitem__(self, index):
        path, target = self.imgs[index]
        img = self.loader(path)
        if self.transform is not None:
            img = self.transform(img)
        if self.target_transform is not None:
            target = self.target_transform(target)

        return img, target

    def __len__(self):
        return len(self.imgs)


class HDFDataSet(Dataset):
    """Class to load images from hdf files"""
    def __init__(self, fname, variable_name='images', ims_per_file=None):
        self.datasets = []
        self.total_count = 0
        for i, f in enumerate(hdf5_list):
            with h5py.File(f, 'r') as hf:
               dataset = hf[variable_name].value
            self.datasets.append(dataset)
            self.total_count += len(dataset)

    def __getitem__(self, index):
        '''
        Suppose each hdf5 file has 10000 samples
        '''
        dataset_index = index % 10000
        in_dataset_index = int(index / 10000)
        return self.datasets[dataset_index][in_dataset_index]

    def __len__(self):
        return len(self.total_count)
# Stubs. Good ideas, from https://discuss.pytorch.org/t/use-of-dataset-class/1620/4
# class MergedDataset(Dataset):
#     """Class to load images from hdf files"""
#     def __init__(self, hdf5_list, ims_per_file=None):
#         self.datasets = []
#         self.total_count = 0
#         for i, f in enumerate(hdf5_list):
#            h5_file = h5py.File(f, 'r')
#            dataset = h5_file['YOUR DATASET NAME']
#            self.datasets.append(dataset)
#            self.total_count += len(dataset)

#     def __getitem__(self, index):
#         '''
#         Suppose each hdf5 file has 10000 samples
#         '''
#         dataset_index = index % 10000
#         in_dataset_index = int(index / 10000)
#         return self.datasets[dataset_index][in_dataset_index]

#     def __len__(self):
#         return len(self.total_count)

# class CloudHDFDataSet(Dataset):
#   def __init__(self, cloud_paths):

#       hdf5_list = [x for x in glob.glob(os.path.join(path_patients,'*.h5'))]#only h5 files
#       print 'h5 list ',hdf5_list
#       self.datasets = []
#       self.datasets_gt=[]
#       self.total_count = 0
#       self.limits=[]
#       for f in hdf5_list:
#          h5_file = h5py.File(f, 'r')
#          dataset = h5_file['data']
#          dataset_gt = h5_file['label']
#          self.datasets.append(dataset)
#          self.datasets_gt.append(dataset_gt)
#          self.limits.append(self.total_count)
#          self.total_count += len(dataset)
#          #print 'len ',len(dataset)
#       #print self.limits   

#   def __getitem__(self, index):
     
#       dataset_index=-1
#       #print 'index ',index
#       for i in xrange(len(self.limits)-1,-1,-1):
#         #print 'i ',i
#         if index>=self.limits[i]:
#           dataset_index=i
#           break
#       #print 'dataset_index ',dataset_index
#       assert dataset_index>=0, 'negative chunk'

#       in_dataset_index = index-self.limits[dataset_index]

#       return self.datasets[dataset_index][in_dataset_index], self.datasets_gt[dataset_index][in_dataset_index]

#   def __len__(self):
#       return self.total_count
