#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "Gerardo Parrello"
__version__ = "0.0.1"
__status__ = "Prototype"
"""
client.py: Description of what client.py does.
"""
import logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Just add logger.debug('My message with %s', 'variable data') where you need data

import pandas as pd
import requests as re

df = pd.read_csv('data.csv')

payload = df.to_json(orient='records')
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoid2ViX2Fub24ifQ.fVeM01NuFk7rKb8m9oVRyxZziAQbD72bdFcsKcQk-kA"
headers = {
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
    "Authorization": "Bearer {}".format(token),
}
url='http://localhost/predictions'

# response = re.get(url)
response = re.post(url, data=payload, headers=headers)
print(response.status_code)
