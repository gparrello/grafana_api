#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "Gerardo Parrello"
__version__ = "0.0.1"
__status__ = "Prototype"
"""
create_token.py: Description of what create_token.py does.
"""
# import logging
# logging.basicConfig(level=logging.DEBUG)
# logger = logging.getLogger(__name__)

# Just add logger.debug('My message with %s', 'variable data') where you need data

# import requests as re
import configparser as cfg
import jwt

config = cfg.ConfigParser('./.config.ini')

def create_token(config, team):

    secret = config['DEFAULT']['secret']

    token = jwt.encode(
        {
            'role': team,
            'exp': '100000000000000'  # unix epoch here
        },
        secret,
        algorithm = 'HS256'
    )

    return(token)
