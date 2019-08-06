#! /usr/bin/env python
#
# Copyright (C) 2016 Mark Lescroart
# <mark.lescroart@gmail.com>

import os
import sys
from distutils.command.install import install

# Get config parser
try:
    import configparser
except:
    import ConfigParser as configparser

# Choose which setuptools to use
if len(set(('develop', 'bdist_egg', 'bdist_rpm', 'bdist', 'bdist_dumb',
            'bdist_wininst', 'install_egg_info', 'egg_info', 'easy_install',
            )).intersection(sys.argv)) > 0:
    # For fancy install commands
    from setuptools import setup
else:
    # Use standard
    from distutils.core import setup

# Get version from __init__ file
version = None
with open(os.path.join('vm_preproc', '__init__.py'), 'r') as fid:
    for line in (line.strip() for line in fid):
        if line.startswith('__version__'):
            version = line.split('=')[1].strip().strip('\'')
            break
if version is None:
    raise RuntimeError('Could not determine version')


# Set up custom installer with config file
def set_default_options(optfile):
    config = configparser.ConfigParser()
    config.read(optfile)
    with open(optfile, 'w') as fp:
        config.write(fp)

class my_install(install):
    def run(self):
        install.run(self)
        optfile = [f for f in self.get_outputs() if 'defaults.cfg' in f]
        set_default_options(optfile[0])


# Basic module data, formatted so it can be imported by other modules
DISTNAME = 'vm_preproc'
DESCRIPTION = """A set of tools for extracting features from (image) stimuli."""
MAINTAINER = 'Mark Lescroart'
MAINTAINER_EMAIL = 'mark.lescroart@gmail.com'
URL = 'https://github.com/marklescroart/vm_preproc'
LICENSE = 'Regents of the University of California'
DOWNLOAD_URL = 'https://github.com/marklescroart/vm_preproc'
VERSION = version

if not 'extra_setuptools_args' in globals():
    extra_setuptools_args = dict()

# Setup function
def main(**kwargs):
    setup(name=DISTNAME,
          version=VERSION,
          description=DESCRIPTION,
          long_description=open('README.md').read(),
          maintainer=MAINTAINER,
          maintainer_email=MAINTAINER_EMAIL,          
          license=LICENSE,
          url=URL,
          download_url=DOWNLOAD_URL,
          classifiers=['Intended Audience :: Science/Research',
                       'Intended Audience :: Developers',
                       'License :: OSI Approved',
                       'Programming Language :: Python',
                       'Topic :: Software Development',
                       'Topic :: Scientific/Engineering',
                       'Operating System :: OSX'],
          platforms='any',
          
          zip_safe=False,  # the package can run out of an .egg file
          packages=['vm_preproc',
                    ],
          requires=['numpy', 'sklearn', 'torch'], # how does this play with requirements.txt??
          include_package_data = True,
          package_data={
              'vm_preproc':[
                'defaults.cfg',
                  ],
              },
          scripts=[],
          **kwargs)


if __name__ == "__main__":
    if os.path.exists('MANIFEST'):
        os.remove('MANIFEST')
    main(**extra_setuptools_args)