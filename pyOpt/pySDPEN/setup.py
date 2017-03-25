#!/usr/bin/env python

import os,sys


def configuration(parent_package='',top_path=None):
    
    from numpy.distutils.misc_util import Configuration
    
    config = Configuration('pySDPEN',parent_package,top_path)
    
    config.add_library('sdpen',
        sources=[os.path.join('source', '*.f90')])
    config.add_extension('sdpen',
        sources=['source/f2py/sdpen.pyf'],
        libraries=['sdpen'])
    config.add_data_files('LICENSE','README.md')
    
    return config
    

if __name__ == '__main__':
    from numpy.distutils.core import setup
    setup(**configuration(top_path='').todict())
    
