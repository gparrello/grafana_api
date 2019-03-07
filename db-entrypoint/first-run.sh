#!/bin/bash
# Create users and schema for PostgREST connection
psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
<<-EOSQL
    CREATE ROLE ${API_USER} WITH PASSWORD '${API_PASSWORD}' LOGIN;
    CREATE ROLE ${API_ANON_USER} NOLOGIN;
    CREATE ROLE ${RESULTS_USER} WITH PASSWORD '${RESULTS_PASSWORD}' LOGIN;
    GRANT ${API_ANON_USER} TO ${API_USER};
    CREATE SCHEMA IF NOT EXISTS ${API_SCHEMA};
    GRANT ALL ON SCHEMA ${API_SCHEMA} TO ${API_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${API_ANON_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${RESULTS_USER};
    CREATE TABLE ${API_SCHEMA}.test
      (
      id SERIAL PRIMARY KEY,
      team_id INTEGER NOT NULL,
      test INTEGER NOT NULL
    )
    WITH (
      OIDS = FALSE
    );
    CREATE TABLE ${API_SCHEMA}.teams
      (
      id SERIAL PRIMARY KEY,
      name char NOT NULL
    )
    WITH (
      OIDS = FALSE
    );
    CREATE TABLE ${API_SCHEMA}.submissions
      (
      id SERIAL PRIMARY KEY,
      team_id INTEGER NOT NULL,
      timestamp TIMESTAMP NOT NULL
    )
    WITH (
      OIDS = FALSE
    );
    CREATE TABLE ${API_SCHEMA}.predictions
      (
      id SERIAL PRIMARY KEY,
      submission_id INTEGER NOT NULL,
      usernum INTEGER NOT NULL,
      datediff INTEGER NOT NULL,
      quantity INTEGER NOT NULL
    )
    WITH (
      OIDS = FALSE
    );
    CREATE TABLE ${API_SCHEMA}.results
      (
      id SERIAL PRIMARY KEY,
      submission_id INTEGER NOT NULL,
      usernum INTEGER NOT NULL,
      correct BOOLEAN NOT NULL
    )
    WITH (
      OIDS = FALSE
    );
    GRANT INSERT ON ${API_SCHEMA}.test TO ${API_ANON_USER};
    GRANT INSERT ON ${API_SCHEMA}.predictions TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.predictions TO ${RESULTS_USER};
    GRANT ALL ON ${API_SCHEMA}.results TO ${RESULTS_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.test_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.predictions_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.predictions_id_seq TO ${RESULTS_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.results_id_seq TO ${RESULTS_USER};
EOSQL

psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" \
<<-EOSQL
    CREATE ROLE ${DASHBOARD_DB_USER} WITH PASSWORD '${DASHBOARD_DB_PASSWORD}' LOGIN;
    CREATE DATABASE ${DASHBOARD_DB_DATABASE};
    GRANT CONNECT ON DATABASE ${DASHBOARD_DB_DATABASE} TO ${DASHBOARD_DB_USER};
EOSQL

exit 0
