# Grafana + API

Exposes a simple API from a database. Then exposes the data the database receives through the API in a dashboard.

## First run

```
$ cp env.sample .env
$ docker-compose up
```

## To-do

* ~~Configure Grafana container, use [this](http://docs.grafana.org/installation/docker/), [this](http://docs.grafana.org/installation/configuration/) and [this](http://docs.grafana.org/administration/provisioning/)~~ Done
* ~~Check [this ticket](https://github.com/PostgREST/postgrest/issues/256) on updates to upsert method so we can use PostgREST as an input too~~ Solved [here](https://github.com/PostgREST/postgrest/pull/1048)
* ~~Provision datasource to Grafana~~ Done, can't use [environment variables](https://github.com/grafana/grafana/issues/12896) though
* ~~Provision dashboard to Grafana~~ Done
* ~~Create script to add users to Postgres that have INSERT permission to the API schema in the postgres database~~ Done
* ~~Give select permissions to grafana user in api table~~ Done
* ~~Separate results boolean from api table~~ Done
* Add JWK generation to team creation script
* Add send credentials by email to team creation script
* ~~Add test table and verification (being able to post to the API with generated token) in team creation script~~ Doesn't seem useful anymore
* Add SSL with nginx container and [Let's Encrypt](https://letsencrypt.org/)
* Compare audit team with submitted team in a plot in grafana
* ~~Count submission lines in a plot too~~ Done, created metrics views
* Add trigger to write team in submission or use default value (wrap ```current_setting('request.jwt.claim.team', true)``` in [function](https://github.com/PostgREST/postgrest/issues/990)?)
