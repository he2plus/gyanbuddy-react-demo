"""
Settings package for gyaan_buddy project.
"""

import os

environment = os.environ.get('DJANGO_ENV', 'development')

if environment == 'production':
    from .production import *
else:
    from .development import *
