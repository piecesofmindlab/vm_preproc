import os
import configparser 
from setuptools import setup, find_packages


# Get requirements
with open('requirements.txt') as fid:
  requirements = fid.readlines()
  requirements = [x.strip() for x in requirements]

# Get version from __init__ file
version = None
with open(os.path.join('vm_preproc', '__init__.py'), 'r') as fid:
    for line in (line.strip() for line in fid):
        if line.startswith('__version__'):
            version = line.split('=')[1].strip().strip('\'')
            break
if version is None:
    raise RuntimeError('Could not determine version')

# Set up config file at install? Or wait till first import of code? 
# def set_default_options(optfile):
#     config = configparser.ConfigParser()
#     config.read(optfile)
#     with open(optfile, 'w') as fp:
#         config.write(fp)
        
setup(
    name='vm_preproc',
    version=version,
    maintainer='Mark Lescroart',
    packages=find_packages(),
    description="A set of tools for extracting features from (image) stimuli.",
    long_description=open('README.md').read(),
    url='https://github.com/piecesofmindlab/vm_preproc',
    download_url='https://github.com/piecesofmindlab/vm_preproc',
    #install_requires=requirements,
    zip_safe=False,
    include_package_data = True,
    package_data={
        'vm_preproc':[
          'defaults.cfg',
            ],
        },
    #include_package_data=True, # ? 
    # classifiers=['Intended Audience :: Science/Research',
    #              'Intended Audience :: Developers',
    #              'License :: OSI Approved',
    #              'Programming Language :: Python',
    #              'Topic :: Software Development',
    #              'Topic :: Scientific/Engineering',
    #              'Operating System :: OSX',
    #              'Operating System :: Linux'],
)


