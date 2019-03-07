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


url='http://localhost/predictions'
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoicmVzdWx0cyJ9.zcSYKNc1VGtp41RkMRlDFstSGUtQ2yqdwF6GXnjIBLA"
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer {}".format(token),
}

response = re.get(url, headers=headers)
df = pd.DataFrame.from_dict(response.json(), orient='columns')
df['correct'] = True

payload = df[['submission_id', 'usernum', 'correct']].to_json(orient='records')
url='http://localhost/results'
response = re.post(url, data=payload, headers=headers)
