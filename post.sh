#!/bin/bash

# https://jwt.io/
token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoid2ViX2Fub24ifQ.fVeM01NuFk7rKb8m9oVRyxZziAQbD72bdFcsKcQk-kA"
curl "http://localhost/predictions" -X POST -H "Authorization: Bearer $token" -H "Prefer: return=minimal" -H "Content-Type: application/json" -d '{"prediction": 5, "team": "data wizards"}'

exit 0
