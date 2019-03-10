#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "Gerardo Parrello"
__version__ = "0.0.1"
__status__ = "Prototype"

"""
example.py: Description of what example.py does.
"""

import pandas as pd
import client

df = pd.read_csv('./data.csv')
status = client.submit_predictions('./config.ini.sample', df)
print(status)
