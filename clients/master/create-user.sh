#!/bin/bash

# To be run from the same host docker compose is deployed!
source .env

# Ask for user input to get team name here!
TEAM_USER="lolos"

# Create role and grant permissions in database
psql -v ON_ERROR_STOP=1 \
"postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}" \
<<-EOSQL
    CREATE ROLE ${TEAM_USER} NOLOGIN;
    GRANT ${TEAM_USER} TO ${API_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${TEAM_USER};
    GRANT INSERT ON ${API_SCHEMA}.predictions TO ${TEAM_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.predictions_id_seq TO ${TEAM_USER};
EOSQL

# Create JWT here!

exit 0
