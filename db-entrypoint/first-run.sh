#!/bin/bash
# Create users and schema for PostgREST connection
psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
<<-EOSQL
    CREATE ROLE ${API_USER} WITH PASSWORD '${API_PASSWORD}' LOGIN;
    CREATE ROLE ${API_ANON_USER} NOLOGIN;
    GRANT ${API_ANON_USER} TO ${API_USER};
    CREATE SCHEMA IF NOT EXISTS ${API_SCHEMA};
    GRANT ALL ON SCHEMA ${API_SCHEMA} TO ${API_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${API_ANON_USER};
    CREATE TABLE ${API_SCHEMA}.predictions
      (
      id SERIAL PRIMARY KEY,
      team_id integer NOT NULL,
      user_id integer NOT NULL,
      datediff integer NOT NULL,
      quantity integer NOT NULL,
      correct boolean
    )
    WITH (
      OIDS = FALSE
    );
    GRANT INSERT ON ${API_SCHEMA}.predictions TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.predictions_id_seq TO ${API_ANON_USER};
    CREATE ROLE ${RESULTS_USER} WITH PASSWORD '${RESULTS_PASSWORD}' LOGIN;
    CREATE SCHEMA IF NOT EXISTS ${RESULTS_SCHEMA};
    GRANT USAGE ON SCHEMA ${RESULTS_SCHEMA} TO ${RESULTS_USER};
    GRANT SELECT ON ALL TABLES IN SCHEMA ${RESULTS_SCHEMA} TO ${RESULTS_USER};
EOSQL

psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" \
<<-EOSQL
    CREATE ROLE ${DASHBOARD_DB_USER} WITH PASSWORD '${DASHBOARD_DB_PASSWORD}' LOGIN;
    CREATE DATABASE ${DASHBOARD_DB_DATABASE};
    GRANT CONNECT ON DATABASE ${DASHBOARD_DB_DATABASE} TO ${DASHBOARD_DB_USER};
EOSQL

# GRANT ALL ON SCHEMA ${DASHBOARD_DB_DATABASE}.public TO ${DASHBOARD_DB_USER};
exit 0
