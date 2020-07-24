# Pleroma

[Pleroma](https://pleroma.social/) is a federated social networking platform, compatible with GNU social and other OStatus implementations. It is free software licensed under the AGPLv3.

It actually consists of two components: a backend, named simply Pleroma, and a user-facing frontend, named Pleroma-FE.

Its main advantages are its lightness and speed.

![Pleroma](https://i.imgur.com/VftiTlR.png)

_Pleromians trying to understand the memes_

## Features

- Based on the elixir:alpine image
- Ran as an unprivileged user
- It works great

Sadly, this is not a reusable (e.g. I can't upload it to the Docker Hub), because for now Pleroma needs to compile the configuration. 😢
Thus you will need to build the image yourself, but I explain how to do it below.

## Build-time variables

- **`PLEROMA_VER`** : Pleroma version (latest commit of the [`develop` branch](https://git.pleroma.social/pleroma/pleroma) by default)
- **`GID`**: group id (default: `911`)
- **`UID`**: user id (default: `911`)

## Usage

### Installation

Create a folder for your Pleroma instance. Inside, you should have `Dockerfile` and `docker-compose.yml` from this repo.

Here is the `docker-compose.yml`. You should change the `POSTGRES_PASSWORD` variable.

```yaml
version: '2.3'

services:
  postgres:
    image: postgres:9.6-alpine
    container_name: pleroma_postgres
    restart: always
    environment:
      POSTGRES_USER: pleroma
      POSTGRES_PASSWORD: pleroma
      POSTGRES_DB: pleroma
    volumes:
      - ./postgres:/var/lib/postgresql/data

  web:
    build: .
    image: pleroma
    container_name: pleroma_web
    restart: always
    ports:
      - '127.0.0.1:4000:4000'
    volumes:
      - ./uploads:/pleroma/uploads
    depends_on:
      - postgres
```

Create the upload and config folder and give write permissions for the uploads:

```sh
mkdir uploads config
chown -R 911:911 uploads
```

Pleroma needs the `citext` PostgreSQL extension, here is how to add it:

```sh
docker-compose up -d postgres
docker exec -i pleroma_postgres psql -U pleroma -c "CREATE EXTENSION IF NOT EXISTS citext;"
docker-compose down
```

Configure Pleroma. Copy the following to `config/secret.exs`:

```exs
use Mix.Config

config :pleroma, Pleroma.Web.Endpoint,
   http: [ ip: {0, 0, 0, 0}, ],
   url: [host: "pleroma.domain.tld", scheme: "https", port: 443],
   secret_key_base: "<use 'openssl rand -base64 48' to generate a key>"

config :pleroma, :instance,
  name: "Pleroma",
  email: "admin@email.tld",
  limit: 5000,
  registrations_open: true

config :pleroma, :media_proxy,
  enabled: false,
  redirect_on_failure: true,
  base_url: "https://cache.domain.tld"

# Configure your database
config :pleroma, Pleroma.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "pleroma",
  password: "pleroma",
  database: "pleroma",
  hostname: "postgres",
  pool_size: 10
```

You need to change at least:

- `host`
- `secret_key_base`
- `email`

Make sure your PostgreSQL parameters are ok.

You can now build the image. 2 way of doing it:

```sh
docker-compose build
# or
docker build -t pleroma .
```

I prefer the latter because it's more verbose.

Setup the database:

```sh
docker-compose run --rm web mix ecto.migrate
```

Get your web push keys and copy them to `secret.exs`:

```
docker-compose run --rm web mix web_push.gen.keypair
```

You will need to build the image again, to pick up your updated `secret.exs` file:

```
docker-compose build
# or
docker build -t pleroma .
```

You can now launch your instance:

```sh
docker-compose up -d
```

Check if everything went well with:

```sh
docker logs -f pleroma_web
```

You can now setup a Nginx reverse proxy in a container or on your host by using the [example Nginx config](https://git.pleroma.social/pleroma/pleroma/blob/develop/installation/pleroma.nginx).

### Update

By default, the Dockerfile will be built from the latest commit of the `develop` branch as Pleroma does not have releases for now.

Thus to update, just rebuild your image and recreate your containers:

```sh
docker-compose pull # update the PostgreSQL if needed
docker-compose build .
# or
docker build -t pleroma .
docker-compose run --rm web mix ecto.migrate # migrate the database if needed
docker-compose up -d # recreate the containers if needed
```

If you want to run a specific commit, you can use the `PLEROMA_VER` variable:

```sh
docker build -t pleroma . --build-arg PLEROMA_VER=develop # a branch
docker build -t pleroma . --build-arg PLEROMA_VER=a9203ab3 # a commit
docker build -t pleroma . --build-arg PLEROMA_VER=v2.0.7 # a version
```

`a9203ab3` being the hash of the commit. (They're [here](https://git.pleroma.social/pleroma/pleroma/commits/develop))

## Other Docker images

Here are other Pleroma Docker images that helped me build mine:

- [potproject/docker-pleroma](https://github.com/potproject/docker-pleroma)
- [rysiek/docker-pleroma](https://git.pleroma.social/rysiek/docker-pleroma)
- [RX14/iscute.moe](https://github.com/RX14/kurisu.rx14.co.uk/blob/master/services/iscute.moe/pleroma/Dockerfile)
