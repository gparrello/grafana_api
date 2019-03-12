#!/bin/bash
# Create users and schema for PostgREST connection
psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
<<-EOSQL
    /***********
    create roles
    ***********/
    CREATE ROLE ${API_USER} WITH PASSWORD '${API_PASSWORD}' LOGIN NOINHERIT;
    CREATE ROLE ${API_ANON_USER} NOLOGIN;
    CREATE ROLE ${RESULTS_USER} WITH PASSWORD '${RESULTS_PASSWORD}' LOGIN;
    CREATE ROLE ${DASHBOARD_USER} WITH PASSWORD '${DASHBOARD_PASSWORD}' LOGIN;
    /***********
    grant permissions on schemas
    ***********/
    GRANT ${API_ANON_USER} TO ${API_USER};
    GRANT ${RESULTS_USER} TO ${API_USER};
    GRANT ${DASHBOARD_USER} TO ${API_USER};
    CREATE SCHEMA IF NOT EXISTS ${API_SCHEMA};
    GRANT ALL ON SCHEMA ${API_SCHEMA} TO ${API_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${API_ANON_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${RESULTS_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${DASHBOARD_USER};
    /***********
    create tables
    ***********/
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.real
      (
      customer INTEGER PRIMARY KEY,
      date DATE NOT NULL,
      billing NUMERIC(20, 2) NOT NULL
    ) WITH (OIDS = FALSE);
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.predictions
      (
      id SERIAL PRIMARY KEY,
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      team VARCHAR(64) DEFAULT CURRENT_SETTING('request.jwt.claim.team', TRUE),
      customer INTEGER REFERENCES ${API_SCHEMA}.real NOT NULL,
      date DATE NOT NULL,
      billing NUMERIC(20, 2) NOT NULL,
      correct BOOLEAN
    ) WITH (OIDS = FALSE);
    ALTER TABLE ${API_SCHEMA}.predictions ENABLE ROW LEVEL SECURITY;
    /***********
    create views
    ***********/
    CREATE OR REPLACE VIEW ${API_SCHEMA}.results AS (
      SELECT
        p.timestamp,
        p.team,
        p.date AS predicted_date,
        r.date AS real_date,
        p.billing AS predicted_billing,
        r.billing AS real_billing,
        (p.date = r.date AND ABS(p.billing - r.billing) <= 10) AS correct
      FROM ${API_SCHEMA}.predictions p
        LEFT JOIN ${API_SCHEMA}.real r ON (p.customer = r.customer)
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.last_submitter AS (
      SELECT
        p.team AS team,
        p.timestamp AS time
      FROM ${API_SCHEMA}.predictions p
      GROUP BY team, time
      ORDER BY time DESC
      LIMIT 1
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.metrics AS (
      SELECT
        r.timestamp AS time,
        r.team,
	      SUM(CASE WHEN r.correct IS TRUE THEN 1 ELSE 0 END)::FLOAT/COUNT(r.correct) AS accuracy
      FROM ${API_SCHEMA}.results r
      GROUP BY r.team, r.timestamp
      ORDER BY accuracy DESC
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.total_submissions AS (
      SELECT
        team,
        COUNT(DISTINCT timestamp) AS total_submissions
      FROM ${API_SCHEMA}.predictions
      GROUP BY team
      ORDER BY total_submissions DESC
    );
    /***********
    create policy for row level security
    **********/
    CREATE POLICY is_team ON ${API_SCHEMA}.predictions FOR ALL TO ${API_ANON_USER}
      USING (team = CURRENT_SETTING('request.jwt.claim.team', TRUE))
      WITH CHECK (team = CURRENT_SETTING('request.jwt.claim.team', TRUE))
    ;
    /***********
    grant permissions on tables and views
    **********/
    GRANT SELECT, INSERT ON ${API_SCHEMA}.predictions TO ${API_ANON_USER};
    GRANT ALL ON ${API_SCHEMA}.real TO ${RESULTS_USER};
    GRANT SELECT ON ALL TABLES IN SCHEMA ${API_SCHEMA} TO ${DASHBOARD_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.predictions_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.predictions_id_seq TO ${RESULTS_USER};
EOSQL

psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" \
<<-EOSQL
    CREATE ROLE ${DASHBOARD_DB_USER} WITH PASSWORD '${DASHBOARD_DB_PASSWORD}' LOGIN;
    CREATE DATABASE ${DASHBOARD_DB_DATABASE};
    REVOKE CONNECT ON DATABASE ${DASHBOARD_DB_DATABASE} FROM PUBLIC;
    GRANT CONNECT ON DATABASE ${DASHBOARD_DB_DATABASE} TO ${DASHBOARD_DB_USER};
EOSQL

exit 0
