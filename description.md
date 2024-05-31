![RedMica logo](https://github.com/redmica/redmica-logo/raw/master/horizontal/redmica-logo-horizontal-small.png "RedMica logo")


# latest

- [3.0.0](https://github.com/redmica/redmica_docker/blob/master/3.0.0/Dockerfile), [3.0](https://github.com/redmica/redmica_docker/blob/master/3.0.0/Dockerfile), [latest](https://github.com/redmica/redmica_docker/blob/master/3.0.0/Dockerfile)
- [3.0.0-alpine](https://github.com/redmica/redmica_docker/blob/master/3.0.0/alpine/Dockerfile)

# How to use this image

This image is made as a RedMica version based on [Redmine of Docker official images](https://hub.docker.com/_/redmine). This image can be used in the same way as [Redmine of Docker official images](https://hub.docker.com/_/redmine).

Where to file issues: https://github.com/redmica/redmica_docker/issues

## Run RedMica with SQLite3

This is the simplest setup; just run RedMica.

```console
$ docker run -d -p 8000:3000 --name some-redmica redmica/redmica
```

Access http://localhost:8000

> not for multi-user production use ([redmine wiki](http://www.redmine.org/projects/redmine/wiki/RedmineInstall#Supported-database-back-ends))

## Run RedMica with a Database Container

Running RedMica with a database server is the recommended way.

1. start a database container

  - PostgreSQL

    ```console
    $ docker run -d --name some-postgres --network some-network -e POSTGRES_PASSWORD=secret -e POSTGRES_USER=redmine postgres
    ```

  - MySQL (replace `-e REDMINE_DB_POSTGRES=some-postgres` with `-e REDMINE_DB_MYSQL=some-mysql` when running RedMica)

    ```console
    $ docker run -d --name some-mysql --network some-network -e MYSQL_USER=redmine -e MYSQL_PASSWORD=secret -e MYSQL_DATABASE=redmine -e MYSQL_RANDOM_ROOT_PASSWORD=1 mysql:5.7
    ```

2. start RedMica

  ```console
  $ docker run -d --name some-redmica --network some-network -e REDMINE_DB_POSTGRES=some-postgres -e REDMINE_DB_USERNAME=redmine -e REDMINE_DB_PASSWORD=secret redmica/redmica
  ```

## ... via [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or [`docker-compose`](https://github.com/docker/compose)

Example `stack.yml` for `redmica`:

```yaml
version: '3.1'

services:

  redmica:
    image: redmica/redmica
    restart: always
    ports:
      - 8080:3000
    environment:
      REDMINE_DB_MYSQL: db
      REDMINE_DB_PASSWORD: example
      REDMINE_SECRET_KEY_BASE: supersecretkey

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: redmine
```

Run `docker stack deploy -c stack.yml redmica` (or `docker-compose -f stack.yml up`), wait for it to initialize completely, and visit `http://swarm-ip:8080`, `http://localhost:8080`, or `http://host-ip:8080` (as appropriate).

## Alternative Web Server

The other tags in this repository, like those with `passenger`, use the same environment and `--links` as the default tags that use WEBrick (`rails s`) but instead give you the option of a different web and application server. `passenger` uses [Phusion Passenger](https://www.phusionpassenger.com/). [`tini`](https://github.com/krallin/tini) is used for reaping [zombies](https://en.wikipedia.org/wiki/Zombie_process).

## Accessing the Application

Currently, the default user and password from upstream is admin/admin ([logging into the application](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-10-Logging-into-the-application)).

## Where to Store Data

Important note: There are several ways to store data used by applications that run in Docker containers. We encourage users of the `redmica` images to familiarize themselves with the options available, including:

- Let Docker manage the storage of your files [by writing the files to disk on the host system using its own internal volume management](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
- Create a data directory on the host system (outside the container) and [mount this to a directory visible from inside the container](https://docs.docker.com/engine/tutorials/dockervolumes/#mount-a-host-directory-as-a-data-volume). This places the database files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists, and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

The Docker documentation is a good starting point for understanding the different storage options and variations, and there are multiple blogs and forum postings that discuss and give advice in this area. We will simply show the basic procedure here for the latter option above:

1. Create a data directory on a suitable volume on your host system, e.g. `/my/own/datadir`.
2. Start your `redmica` container like this:

  ```console
  $ docker run -d --name some-redmica -v /my/own/datadir:/usr/src/redmine/files --link some-postgres:postgres redmica/redmica
  ```

The `-v /my/own/datadir:/usr/src/redmine/files` part of the command mounts the `/my/own/datadir` directory from the underlying host system as `/usr/src/redmine/files` inside the container, where RedMica will store uploaded files.

## Port Mapping

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used. Just add `-p 3000:3000` to the `docker run` arguments and then access either `http://localhost:3000` or `http://host-ip:3000` in a browser.

## Environment Variables

When you start the `redmica` image, you can adjust the configuration of the instance by passing one or more environment variables on the `docker run` command line.

### `REDMINE_DB_MYSQL` or `REDMINE_DB_POSTGRES`

These two variables allow you to set the hostname or IP address of the MySQL or PostgreSQL host, respectively. These values are mutually exclusive so it is undefined behavior if both are set. If neither variable is set, the image will fall back to using SQLite.

### `REDMINE_DB_PORT`

This variable allows you to specify a custom database connection port. If unspecified, it will default to the regular connection ports: 3306 for MySQL, 5432 for PostgreSQL, and empty string for SQLite.

### `REDMINE_DB_USERNAME`

This variable sets the user that RedMica and any rake tasks use to connect to the specified database. If unspecified, it will default to `root` for MySQL, `postgres` for PostgreSQL, or `redmine` for SQLite.

### `REDMINE_DB_PASSWORD`

This variable sets the password that the specified user will use in connecting to the database. There is no default value.

### `REDMINE_DB_DATABASE`

This variable sets the database that RedMica will use in the specified database server. If not specified, it will default to `redmine` for MySQL, the value of `REDMINE_DB_USERNAME` for PostgreSQL, or `sqlite/redmine.db` for SQLite.

### `REDMINE_DB_ENCODING`

This variable sets the character encoding to use when connecting to the database server. If unspecified, it will use the default for the `mysql2` library ([`UTF-8`](https://github.com/brianmario/mysql2/tree/18673e8d8663a56213a980212e1092c2220faa92#mysql2---a-modern-simple-and-very-fast-mysql-library-for-ruby---binding-to-libmysql)) for MySQL, `utf8` for PostgreSQL, or `utf8` for SQLite.

### `REDMINE_NO_DB_MIGRATE`

This variable allows you to control if `rake db:migrate` is run on container start. Just set the variable to a non-empty string like `1` or `true` and the migrate script will not automatically run on container start.

`db:migrate` will also not run if you start your image with something other than the default `CMD`, like `bash`. See the current `docker-entrypoint.sh` in your image for details.

### `REDMINE_PLUGINS_MIGRATE`

This variable allows you to control if `rake redmine:plugins:migrate` is run on container start. Just set the variable to a non-empty string like `1` or `true` and the migrate script will be automatically run on every container start. It will be run after `db:migrate`.

`redmine:plugins:migrate` will not run if you start your image with something other than the default `CMD`, like `bash`. See the current `docker-entrypoint.sh` in your image for details.

### `REDMINE_SECRET_KEY_BASE`

This variable is required when using Docker Swarm replicas to maintain session connections when being loadbalanced between containers. It will create an initial `config/secrets.yml` and set the `secret_key_base` value, which is "used by Rails to encode cookies storing session data thus preventing their tampering. Generating a new secret token invalidates all existing sessions after restart" ([session store](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-5-Session-store-secret-generation)). If you do not set this variable or provide a `secrets.yml` one will be generated using `rake generate_secret_token`.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run -d --name some-redmica -e REDMINE_DB_MYSQL_FILE=/run/secrets/mysql-host -e REDMINE_DB_PASSWORD_FILE=/run/secrets/mysql-root redmica/redmica:tag
```

Currently, this is only supported for `REDMINE_DB_MYSQL`, `REDMINE_DB_POSTGRES`, `REDMINE_DB_PORT`, `REDMINE_DB_USERNAME`, `REDMINE_DB_PASSWORD`, `REDMINE_DB_DATABASE`, `REDMINE_DB_ENCODING`, and `REDMINE_SECRET_KEY_BASE`.

# Image Variants

The `redmica` images come in many flavors, each designed for a specific use case.

## `redmica/redmica:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `redmica/redmica:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is highly recommended when final image size being as small as possible is desired. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so certain software might run into issues depending on the depth of their libc requirements. However, most software doesn't have an issue with this, so this variant is usually a very safe choice. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

[RedMica](https://github.com/redmica/redmica) is open source and released under the terms of the [GNU General Public License v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) (GPL).

This Dockerfile is developed by [redmica/redmica_docker repository](https://github.com/redmica/redmica_docker).  
[redmica/redmica_docker repository](https://github.com/redmica/redmica_docker) is a fork of [docker-library/redmine](https://github.com/docker-library/redmine). [docker-library/redmine](https://github.com/docker-library/redmine) is licensed under the [GNU General Public License v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) (GPL).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
