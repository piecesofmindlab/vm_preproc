# Tools for preprocessing stimuli

__version__ = '0.2.0'

import file_io

from . import utils
from . import options
from . import general
from . import image
from . import normals
from . import anonymize
from . import motion_energy

__all__ = ['options', 
			'utils', 
			'general',
			'image',
			'anonymize', 
			'normals', 
			'motion_energy']

# Soft imports of torch / GPU dependent code
try:
    from . import alexnet_pyt
    from . import resnet_pyt
    __all__ += ['alexnet_pyt', 'resnet_pyt']
except ImportError:
    print("No pytorch modules available.")