# Grafana + API

Exposes a simple API from a database. Then exposes the data the database receives through the API in a dashboard.

## First run

```
$ cp env.sample .env
$ docker-compose up
```

## To-do

* Configure Grafana container, use [this](http://docs.grafana.org/installation/docker/), [this](http://docs.grafana.org/installation/configuration/) and [this](http://docs.grafana.org/administration/provisioning/)
* Add SSL with nginx container and [Let's Encrypt](https://letsencrypt.org/)
* ~~Check [this ticket](https://github.com/PostgREST/postgrest/issues/256) on updates to upsert method so we can use PostgREST as an input too~~ Solved [here](https://github.com/PostgREST/postgrest/pull/1048)
