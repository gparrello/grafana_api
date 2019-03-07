#!/bin/bash

thehost="$1"

n=1000
i=1
data="["
while [ $i -le $n ]
do
  data+='{"team_id": '"$RANDOM"', "user_id": '"$RANDOM"', "datediff": '"$RANDOM"', "quantity": '"$RANDOM"'}'
  if [ $i -lt $n ]
    then data+=','
  fi
  i=$((i+1))
done
data+="]"

# https://jwt.io/
token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoid2ViX2Fub24ifQ.fVeM01NuFk7rKb8m9oVRyxZziAQbD72bdFcsKcQk-kA"
curl "http://$thehost/predictions" \
  -X POST \
  -H "Authorization: Bearer $token" \
  -H "Prefer: return=minimal" \
  -H "Content-Type: application/json" \
  -d "$data"

exit 0
