# Tools for preprocessing stimuli

__version__ = '0.2.0'

import file_io


from . import utils
from . import options

#from . import anonymize # Crappy opencv version bug
from . import fourier_power
from . import general
from . import gist
from . import gridlike_code
from . import heading
from . import image
from . import motion_energy
from . import marker_detection
from . import normals
from . import openpose

__all__ = ['utils', 
	'options', 
	'fourier_power',

	#'anonymize', 
	'general',
	'gist',
	'gridlike_code',
	'heading',
	'image',
	'motion_energy',
	'marker_detection',
	'normals', 
	'openpose']

# Soft imports of torch / GPU dependent code
try:
    from . import alexnet_pyt
    from . import resnet_pyt
    __all__ += ['alexnet_pyt', 'resnet_pyt']
except ImportError:
    print("No pytorch modules available.")