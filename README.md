# Grafana + API

Exposes a simple API from a database. Then exposes the data the database receives through the API in a dashboard.

## First run

```
$ cp env.sample .env
$ docker-compose up
```

## To-do

* Configure Grafana container
* Add SSL with nginx container
* Check [this ticket](https://github.com/PostgREST/postgrest/issues/256) on updates to upsert method so we can use PostgREST as an input too
