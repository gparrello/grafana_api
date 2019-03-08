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

    # get not validated submissions
    endpoint = 'submissions'
    condition = 'validated=is.false'
    url = protocol + host + '/' + endpoint + '?' + condition
    r = re.get(url, headers=headers)
    submissions = tuple([v['id'] for v in r.json()])

    # get not validated predictions
    endpoint = 'predictions'
    if len(submissions) == 1:
        condition = 'id=eq.{}'.format(submissions[0])
    else:
        condition = 'id=in.{}'.format(submissions)
    url = protocol + host + '/' + endpoint + '?' + 'submission_' + condition
    r = re.get(url, headers=headers)
    if len(r.json()) == 0:
        print('nothing to validate here, bye!')
        return

    # validate predictions
    ## add clause to check length of predictions agains record_num in submission
    df = pd.DataFrame.from_dict(r.json(), orient='columns')
    df['correct'] = True  # this is to be defined by the validator algorithm

    # submit results
    endpoint = 'results'
    url = protocol + host + '/' + endpoint
    payload = df[['submission_id', 'usernum', 'correct']].to_json(orient='records')
    r = re.post(url, data=payload, headers=headers)

    # update submissions as validated
    endpoint = 'submissions'
    url = protocol + host + '/' + endpoint + '?' + condition
    payload = json.dumps([{'validated': 'TRUE'}]*len(submissions))
    headers["Prefer"] = "return=representation"
    r = re.patch(url, headers=headers, data=payload)

    return


submit_validations()
