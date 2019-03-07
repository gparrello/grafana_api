#!/bin/bash

# https://jwt.io/
token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoid2ViX2Fub24ifQ.fVeM01NuFk7rKb8m9oVRyxZziAQbD72bdFcsKcQk-kA"
curl "http://datathon.intelliris.net/predictions"  \
  -X POST -H "Authorization: Bearer $token" -H "Prefer: return=minimal"  \
  -H "Content-Type: application/json" \
  -d '[{"team_id": '"$RANDOM"', "user_id": '"$RANDOM"', "datediff": '"$RANDOM"', "quantity": '"$RANDOM"', "correct": "FALSE"}, {"team_id": '"$RANDOM"', "user_id": '"$RANDOM"', "datediff": '"$RANDOM"', "quantity": '"$RANDOM"', "correct": "FALSE"}]'

exit 0
