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
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.teams (
      id SERIAL PRIMARY KEY,
      enabled BOOLEAN NOT NULL DEFAULT TRUE,
      name VARCHAR(64),
      is_tester BOOLEAN NOT NULL DEFAULT FALSE,
      submissions_limit INTEGER DEFAULT 20
    );
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.real (
      customer VARCHAR(6) PRIMARY KEY,
      date DATE NOT NULL,
      billing NUMERIC(20, 2) NOT NULL
    ) WITH (OIDS = FALSE);
    CREATE TABLE IF NOT EXISTS ${API_SCHEMA}.predictions (
      id SERIAL PRIMARY KEY,
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      team_id INTEGER REFERENCES ${API_SCHEMA}.teams DEFAULT CURRENT_SETTING('request.jwt.claim.team_id', TRUE)::int,
      customer VARCHAR(6) REFERENCES ${API_SCHEMA}.real NOT NULL,
      date DATE NOT NULL,
      billing NUMERIC(20, 2) NOT NULL
    ) WITH (OIDS = FALSE);
    ALTER TABLE ${API_SCHEMA}.predictions ENABLE ROW LEVEL SECURITY;
    /***********
    create views
    ***********/
    CREATE OR REPLACE VIEW ${API_SCHEMA}.results AS (
      SELECT
        p.timestamp,
        t.name AS team,
        p.date AS predicted_date,
        r.date AS real_date,
        p.billing AS predicted_billing,
        r.billing AS real_billing,
        (p.date = r.date AND ABS(p.billing - r.billing) <= 10) AS correct
      FROM ${API_SCHEMA}.predictions p
        LEFT JOIN ${API_SCHEMA}.real r ON (p.customer = r.customer)
        LEFT JOIN ${API_SCHEMA}.teams t ON (p.team_id = t.id)
      WHERE t.is_tester IS FALSE
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.last_submitter AS (
      SELECT
        t.name AS team,
        p.timestamp AS time
      FROM ${API_SCHEMA}.predictions p
        LEFT JOIN ${API_SCHEMA}.teams t ON (p.team_id = t.id)
      WHERE t.is_tester IS FALSE
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
      ORDER BY accuracy DESC, time
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.total_submissions AS (
      SELECT
        t.name AS team,
        COUNT(DISTINCT timestamp) AS total_submissions
      FROM ${API_SCHEMA}.predictions p
        LEFT JOIN ${API_SCHEMA}.teams t ON (p.team_id = t.id)
      WHERE t.is_tester IS FALSE
      GROUP BY team
      ORDER BY total_submissions DESC
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.total_real AS (
      SELECT COUNT(customer) AS total FROM ${API_SCHEMA}.real
    );
    /***********
    create functions
    ***********/
    CREATE OR REPLACE FUNCTION ${API_SCHEMA}.get_team_id()
    RETURNS int AS \$\$
    BEGIN
      RETURN CURRENT_SETTING('request.jwt.claim.team_id', TRUE)::int;
    END;
    \$\$ LANGUAGE plpgsql STABLE COST 100000;
    CREATE OR REPLACE FUNCTION ${API_SCHEMA}.get_enabled(in teamid int)
    RETURNS bool AS \$\$
      SELECT enabled
      FROM ${API_SCHEMA}.teams t
      WHERE t.id = \$1
    \$\$ LANGUAGE sql;
    CREATE OR REPLACE FUNCTION ${API_SCHEMA}.count_submissions(in teamid int)
    RETURNS int AS \$\$
      SELECT COUNT(DISTINCT timestamp)::int
      FROM ${API_SCHEMA}.predictions p
      WHERE p.team_id = \$1
    \$\$ LANGUAGE sql;
    CREATE OR REPLACE FUNCTION ${API_SCHEMA}.get_submissions_limit(in teamid int)
    RETURNS int AS \$\$
      SELECT submissions_limit
      FROM ${API_SCHEMA}.teams t
      WHERE t.id = \$1
    \$\$ LANGUAGE sql;
    CREATE OR REPLACE FUNCTION ${API_SCHEMA}.count_real()
    RETURNS int AS \$\$
      SELECT COUNT(customer)::int
      FROM ${API_SCHEMA}.real r
    \$\$ LANGUAGE sql;
    CREATE OR REPLACE FUNCTION ${API_SCHEMA}.check_row_count()
    RETURNS bool AS \$\$
      DECLARE
        v_cnt int;
   	    v_real int;
    BEGIN
      GET DIAGNOSTICS v_cnt = row_count;
      SELECT total INTO v_real FROM ${API_SCHEMA}.total_real;
      RETURN v_cnt = v_real;
    END;
    \$\$ LANGUAGE plpgsql STABLE COST 100000;
    /***********
    create policy for row level security
    **********/
    CREATE POLICY is_team ON ${API_SCHEMA}.predictions
    FOR ALL
    TO ${API_ANON_USER}
      USING (
            team_id = ${API_SCHEMA}.get_team_id()
        AND ${API_SCHEMA}.get_enabled(${API_SCHEMA}.get_team_id()) IS TRUE
      )
      WITH CHECK (
            team_id = ${API_SCHEMA}.get_team_id()
        AND ${API_SCHEMA}.get_enabled(${API_SCHEMA}.get_team_id()) IS TRUE
        AND timestamp = CURRENT_TIMESTAMP
        /*AND ${API_SCHEMA}.check_row_count() IS TRUE*/
        AND (
          ${API_SCHEMA}.get_submissions_limit(${API_SCHEMA}.get_team_id()) IS NULL  /* if limit is empty, no limit */
          OR
          ${API_SCHEMA}.count_submissions(${API_SCHEMA}.get_team_id()) <= ${API_SCHEMA}.get_submissions_limit(${API_SCHEMA}.get_team_id())
        )
      )
    ;
    /***********
    grant permissions on tables and views
    **********/
    GRANT SELECT ON ${API_SCHEMA}.teams TO ${API_ANON_USER};
    GRANT SELECT, INSERT ON ${API_SCHEMA}.predictions TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.total_real TO ${API_ANON_USER};
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
