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
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.submissions
      (
      id SERIAL PRIMARY KEY,
      team VARCHAR(64) NOT NULL,
      records_num INTEGER NOT NULL,
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) WITH (OIDS = FALSE);
    ALTER TABLE ${API_SCHEMA}.submissions ENABLE ROW LEVEL SECURITY;
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.real
      (
      customer INTEGER PRIMARY KEY,
      date DATE NOT NULL,
      billing NUMERIC(20, 2) NOT NULL
    ) WITH (OIDS = FALSE);
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.predictions
      (
      id SERIAL PRIMARY KEY,
      submission_id INTEGER REFERENCES ${API_SCHEMA}.submissions NOT NULL,
      customer INTEGER REFERENCES ${API_SCHEMA}.real NOT NULL,
      date DATE NOT NULL,
      billing NUMERIC(20, 2) NOT NULL,
      correct BOOLEAN
    ) WITH (OIDS = FALSE);
    /***********
    create views
    ***********/
    CREATE OR REPLACE VIEW ${API_SCHEMA}.results AS (
      SELECT
        p.id,
        p.submission_id,
        p.date AS predicted_date,
        r.date AS real_date,
        p.billing AS predicted_billing,
        r.billing AS real_billing,
        (p.date = r.date AND ABS(p.billing - r.billing) <= 10) AS correct
      FROM ${API_SCHEMA}.predictions p
        LEFT JOIN ${API_SCHEMA}.real r ON (p.customer = r.customer)
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.validation_check AS (
      SELECT
	      s.id AS submission_id,
        s.timestamp AS time,
	      s.team AS team,
        s.records_num,
      	p.total::int AS submitted_rows,
        (s.records_num - p.total)::int AS submission_error
      FROM ${API_SCHEMA}.submissions s
        LEFT JOIN (
		      SELECT
      			submission_id,
      			COUNT(p.id) AS total
		      FROM ${API_SCHEMA}.results p
		      GROUP BY submission_id
	      ) p ON (s.id = p.submission_id)
      ORDER BY time DESC
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.last_submitter AS (
      SELECT
        s.team AS team,
        s.timestamp AS time
      FROM ${API_SCHEMA}.submissions s
      ORDER BY s.id DESC
      LIMIT 1
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.metrics AS (
      SELECT
	      r.submission_id AS submission,
	      s.team AS team,
	      SUM(CASE WHEN r.correct IS TRUE THEN 1 ELSE 0 END)::FLOAT/COUNT(r.id) AS accuracy
      FROM ${API_SCHEMA}.results r
	      LEFT JOIN ${API_SCHEMA}.submissions s ON (r.submission_id = s.id)
      GROUP BY s.team, r.submission_id
      ORDER BY accuracy DESC
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.total_submissions AS (
      SELECT team, COUNT(id) AS total_submissions
      FROM ${API_SCHEMA}.submissions
      GROUP BY team
      ORDER BY total_submissions DESC
    );
    /***********
    create policy for row level security
    **********/
    CREATE POLICY is_team ON ${API_SCHEMA}.submissions FOR ALL TO ${API_ANON_USER}
      USING (TRUE)
      WITH CHECK (team = current_setting('request.jwt.claim.team', TRUE))
    ;
    /***********
    grant permissions on tables and views
    **********/
    GRANT SELECT, INSERT ON ${API_SCHEMA}.submissions TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.submissions TO ${RESULTS_USER};
    GRANT INSERT ON ${API_SCHEMA}.predictions TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.predictions TO ${RESULTS_USER};
    GRANT ALL ON ${API_SCHEMA}.real TO ${RESULTS_USER};
    GRANT SELECT ON ALL TABLES IN SCHEMA ${API_SCHEMA} TO ${DASHBOARD_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.submissions_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.submissions_id_seq TO ${RESULTS_USER};
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
