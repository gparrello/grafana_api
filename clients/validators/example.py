#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "Gerardo Parrello"
__version__ = "0.0.1"
__status__ = "Prototype"

"""
example.py: Description of what example.py does.
"""

import client

status = client.submit_validations('./config.ini.sample')
print(status)
