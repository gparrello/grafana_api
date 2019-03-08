#!/bin/bash
# Create users and schema for PostgREST connection
psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
<<-EOSQL
    /***********
    create roles
    ***********/
    CREATE ROLE ${API_USER} WITH PASSWORD '${API_PASSWORD}' LOGIN;
    CREATE ROLE ${API_ANON_USER} NOLOGIN;
    CREATE ROLE ${RESULTS_USER} NOLOGIN;
    /*CREATE ROLE ${RESULTS_USER} WITH PASSWORD '${RESULTS_PASSWORD}' LOGIN;*/
    /***********
    grant permissions on schemas
    ***********/
    GRANT ${API_ANON_USER} TO ${API_USER};
    GRANT ${RESULTS_USER} TO ${API_USER};
    CREATE SCHEMA IF NOT EXISTS ${API_SCHEMA};
    GRANT ALL ON SCHEMA ${API_SCHEMA} TO ${API_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${API_ANON_USER};
    GRANT USAGE ON SCHEMA ${API_SCHEMA} TO ${RESULTS_USER};
    /***********
    create tables
    ***********/
    CREATE TABLE ${API_SCHEMA}.teams
      (
      id SERIAL PRIMARY KEY,
      name VARCHAR(64) NOT NULL UNIQUE
    ) WITH (OIDS = FALSE);
    /*CREATE TABLE ${API_SCHEMA}.test
      (
      id SERIAL PRIMARY KEY,
      team_id INTEGER REFERENCES ${API_SCHEMA}.teams NOT NULL,
      test INTEGER NOT NULL
    ) WITH (OIDS = FALSE);*/
    CREATE TABLE ${API_SCHEMA}.submissions
      (
      id SERIAL PRIMARY KEY,
      team_id INTEGER REFERENCES ${API_SCHEMA}.teams NOT NULL,
      records_num INTEGER NOT NULL,
      timestamp TIMESTAMP NOT NULL
    ) WITH (OIDS = FALSE);
    CREATE TABLE ${API_SCHEMA}.results
      (
      id SERIAL PRIMARY KEY,
      submission_id INTEGER REFERENCES ${API_SCHEMA}.submissions NOT NULL,
      usernum INTEGER NOT NULL,
      datediff INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      correct BOOLEAN
    ) WITH (OIDS = FALSE);
    /***********
    create views
    ***********/
    CREATE OR REPLACE VIEW ${API_SCHEMA}.predictions AS (
      SELECT submission_id, usernum, datediff, quantity
      FROM ${API_SCHEMA}.results
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.validate AS (
      SELECT *
      FROM ${API_SCHEMA}.results
      WHERE correct IS NULL
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.validation_check AS (
      SELECT
	      s.id AS submission_id,
	      t.name AS team_name,
	      (s.records_num - p.total)::int AS submission_error,
	      p.validated::int,
      	p.pending::int,
      	p.total::int
      FROM ${API_SCHEMA}.submissions s
        LEFT JOIN (
		      SELECT
      			submission_id,
      			SUM(CASE WHEN p.correct IS NULL THEN 0 ELSE 1 END) AS validated,
      			SUM(CASE WHEN p.correct IS NULL THEN 1 ELSE 0 END) AS pending,
      			COUNT(p.id) AS total
		      FROM ${API_SCHEMA}.results p
		      GROUP BY submission_id
	      ) p ON (s.id = p.submission_id)
      LEFT JOIN ${API_SCHEMA}.teams t ON (s.team_id = t.id)
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.last_submitter AS (
      SELECT t.name AS team_name
      FROM ${API_SCHEMA}.submissions s
  	    LEFT JOIN ${API_SCHEMA}.teams t ON (s.team_id = t.id)
      ORDER BY s.id DESC
      LIMIT 1
    );
    CREATE OR REPLACE VIEW ${API_SCHEMA}.metrics AS (
      SELECT
	     r.submission_id,
	     t.name AS team_name,
	     SUM(CASE WHEN r.correct IS TRUE THEN 1 ELSE 0 END)::FLOAT/COUNT(r.id) AS accuracy
      FROM ${API_SCHEMA}.results r
	     LEFT JOIN ${API_SCHEMA}.submissions s ON (r.submission_id = s.id)
	     LEFT JOIN ${API_SCHEMA}.teams t ON (s.team_id = t.id)
      GROUP BY t.name, r.submission_id
      ORDER BY accuracy DESC
    );
    /***********
    grant permissions on tables and views
    **********/
    /*GRANT INSERT ON ${API_SCHEMA}.test TO ${API_ANON_USER};*/
    GRANT SELECT ON ${API_SCHEMA}.teams TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.teams TO ${RESULTS_USER};
    GRANT SELECT, INSERT ON ${API_SCHEMA}.submissions TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.submissions TO ${RESULTS_USER};
    GRANT INSERT ON ${API_SCHEMA}.predictions TO ${API_ANON_USER};
    GRANT SELECT ON ${API_SCHEMA}.results TO ${RESULTS_USER};
    GRANT SELECT, INSERT, UPDATE ON ${API_SCHEMA}.validate TO ${RESULTS_USER};
    /*GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.test_id_seq TO ${API_ANON_USER};*/
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.teams_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.teams_id_seq TO ${RESULTS_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.submissions_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.submissions_id_seq TO ${RESULTS_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.results_id_seq TO ${API_ANON_USER};
    GRANT USAGE, SELECT ON SEQUENCE ${API_SCHEMA}.results_id_seq TO ${RESULTS_USER};
    insert into ${API_SCHEMA}.teams (name) values ('lolos'), ('knns'), ('data_wizards'); /* remove this line */
EOSQL

psql -v ON_ERROR_STOP=1 \
--username "${POSTGRES_USER}" \
<<-EOSQL
    CREATE ROLE ${DASHBOARD_DB_USER} WITH PASSWORD '${DASHBOARD_DB_PASSWORD}' LOGIN;
    CREATE DATABASE ${DASHBOARD_DB_DATABASE};
    GRANT CONNECT ON DATABASE ${DASHBOARD_DB_DATABASE} TO ${DASHBOARD_DB_USER};
EOSQL

exit 0
