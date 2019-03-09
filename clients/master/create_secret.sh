#!/bin/bash

< /dev/urandom tr -dc A-Za-z0-9 | head -c32

exit 0
