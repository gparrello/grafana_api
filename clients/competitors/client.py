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


def submit_predictions(df):

    config = cfg.ConfigParser()
    config.read('.config.ini')

    protocol = 'http://'
    host = config['DEFAULT']['host']
    team = config['DEFAULT']['team']
    token = config['DEFAULT']['token']

    # if df.empty():
        # quit()
    # add unique usernum constrain!

    # get team id
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer {}".format(token),
        "Prefer": "return=representation",
    }
    endpoint = 'teams'
    condition = 'name=eq.{}'.format(team)
    url = protocol + host + '/' + endpoint + '?' + condition
    r = re.get(url, headers=headers)
    if len(r.json()) == 0:  # check r.json() is list of length 0
        print("error! no team with that name!")
        quit()
    elif len(r.json()) == 1:  # check r.json() is list of length 1
        team_id = r.json()[0]['id']
    else:
        print("error! more than one team with that name???")
        quit()

    # post submission and get submission id
    endpoint = 'submissions'
    url = protocol + host + '/' + endpoint
    payload = json.dumps({
        'team_id': team_id,
        'records_num': len(df),
        'timestamp': dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    })
    r = re.post(url, headers=headers, data=payload)
    if len(r.json()) == 1:
        submission_id = r.json()[0]['id']
    else:
        print("error! more than one submission posted at the same time???")
        quit()

    # post predictions
    endpoint = 'predictions'
    url = protocol + host + '/' + endpoint
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer {}".format(token),
        "Prefer": "return=minimal",
    }
    df['submission_id'] = submission_id
    payload = df[[
        'submission_id',
        'usernum',
        'datediff',
        'quantity',
    ]].to_json(orient='records')

    r = re.post(url, data=payload, headers=headers)

    return(r.status_code)


df = pd.read_csv('data.csv')
status = submit_predictions(df)
print(status)
