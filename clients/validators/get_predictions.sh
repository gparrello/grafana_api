#!/bin/bash

thehost="$1"

# https://jwt.io/
token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoicmVzdWx0cyJ9.zcSYKNc1VGtp41RkMRlDFstSGUtQ2yqdwF6GXnjIBLA"
curl "http://$thehost/predictions" \
  -X GET \
  -H "Authorization: Bearer $token" \
  -H "Content-Type: application/json" \

exit 0
