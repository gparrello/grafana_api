# Grafana + API

Exposes a simple API from a database

## First run

```
$ cp env.sample .env
$ docker-compose up
```

## Usage

[PostgREST Documentation](http://postgrest.org/en/v5.1/api.html)

## To-do

* Add Grafana container
* Add SSL with nginx container
* Check [this ticket](https://github.com/PostgREST/postgrest/issues/256) on updates to upsert method so we can use PostgREST as an input too
