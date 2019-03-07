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
import datetime as dt
import json

protocol = 'http://'
host = 'localhost'

team = 'lolos'
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoid2ViX2Fub24ifQ.fVeM01NuFk7rKb8m9oVRyxZziAQbD72bdFcsKcQk-kA"

df = pd.read_csv('data.csv')
if df.empty():
    quit()
# add unique usernum constrain!

# get team id
endpoint = 'teams'
condition = 'name=eq.{}'.format(team)
url = protocol + host + '/' + endpoint + '?' + condition
r = re.get(url)
if len(r.json()) == 1: # check r.json() is list of length 1
    team_id = r.json()[0]['id']
else:
    print("error! more than one team with that name???")
    quit()

endpoint = 'submissions'
url = protocol + host + '/' + endpoint
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer {}".format(token),
    "Prefer": "return=representation",
}
payload = json.dumps({
    'team_id': team_id,
    'timestamp': dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
})
r = re.post(url, headers=headers, data=payload)
if len(r.json()) == 1:
    submission_id = r.json()[0]['id']
else:
    print("error! more than one submission posted at the same time???")
    quit()

quit()


headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer {}".format(token),
    "Prefer": "return=minimal",
}
payload = df.to_json(orient='records')
url='http://localhost/predictions'

# r = re.get(url)
r = re.post(url, data=payload, headers=headers)
print(r.status_code)
