#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "Gerardo Parrello"
__version__ = "0.0.1"
__status__ = "Prototype"
"""
client.py: Description of what client.py does.
"""
# import logging
# logging.basicConfig(level=logging.DEBUG)
# logger = logging.getLogger(__name__)

# Just add logger.debug('My message with %s', 'variable data') where you need data

import configparser as cfg
import pandas as pd
import requests as re
import datetime as dt
import json


def submit_validations():

    config = cfg.ConfigParser()
    config.read('.config.ini')

    protocol = 'http://'
    host = config['DEFAULT']['host']
    token = config['DEFAULT']['token']

    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer {}".format(token),
    }

    # if df.empty():
        # quit()
    # add unique usernum constrain!

    endpoint = 'validate'
    url = protocol + host + '/' + endpoint
    r = re.get(url, headers=headers)
    if len(r.json()) == 0:
        print('nothing to validate here, bye!')
        return(0)

    df = pd.DataFrame.from_dict(r.json(), orient='columns')
    df['correct'] = True  # this is to be defined by the validator algorithm
    payload = df.to_json(orient='records')
    headers['Prefer'] = 'resolution=merge-duplicates'
    r = re.post(url, data=payload, headers=headers)

    return(r.status_code)


status = submit_validations()
print(status)
