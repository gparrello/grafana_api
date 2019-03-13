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


def submit_predictions(config_file, df):

    """
    """

    if df.empty:
        return("you passed an empty dataframe")

    total_customer = 3 #1000
    if len(df.customer) < total_customer:
        return("you have less customer than needed")

    if len(df.customer) != len(df.customer.unique()):
        return("you have non-unique customer")

    config = cfg.ConfigParser()
    config.read(config_file)

    protocol = 'http://'
    host = config['DEFAULT']['host']
    token = config['DEFAULT']['token']

    # post predictions
    endpoint = '/predictions'
    url = protocol + host + endpoint
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer {}".format(token),
        "Prefer": "return=representation",
    }
    payload = df[[
        'customer',
        'date',
        'billing',
    ]].to_json(orient='records', date_format='iso')
    r = re.post(url, data=payload, headers=headers)

    return(r.status_code)
