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
version: "3.8"

services:
  db:
    image: postgres:12.1-alpine
    container_name: pleroma_db
    restart: always
    environment:
      POSTGRES_USER: pleroma
      POSTGRES_PASSWORD: ChangeMe!
      POSTGRES_DB: pleroma
    volumes:
      - ./postgres:/var/lib/postgresql/data

  web:
    image: pleroma
    container_name: pleroma_web
    restart: always
    ports:
      - "4000:4000"
    build:
      context: .
      # Feel free to remove or override this section
      # See 'Build-time variables' in README.md
      args:
        - "UID=911"
        - "GID=911"
        - "PLEROMA_VER=develop"
    volumes:
      - ./uploads:/var/lib/pleroma/uploads
      - ./static:/var/lib/pleroma/static
      - ./config.exs:/etc/pleroma/config.exs:ro
      # optional, see 'Config Override' section in README.md
      # - ./config-override.exs:/var/lib/pleroma/config.exs:ro
    environment:
      DOMAIN: example.com
      INSTANCE_NAME: Pleroma
      ADMIN_EMAIL: admin@example.com
      NOTIFY_EMAIL: notify@example.com
      DB_USER: pleroma
      DB_PASS: ChangeMe!
      DB_NAME: pleroma
    depends_on:
      - db
```

Create the upload and config folder and give write permissions for the uploads:

```sh
mkdir uploads config
chown -R 911:911 uploads
```

Pleroma needs the `citext` PostgreSQL extension, here is how to add it:

```sh
docker-compose up -d db
docker exec -i pleroma_db psql -U pleroma -c "CREATE EXTENSION IF NOT EXISTS citext;"
docker-compose down
```

Optionally configure Pleroma, see [Config Override](#config-override).
You can now build the image. 2 way of doing it:

```sh
docker-compose build
# or
docker build -t pleroma .
```

I prefer the latter because it's more verbose but this will ignore any build-time variables you have set in `docker-compose.yml`.

You can now launch your instance:

```sh
docker-compose up -d
```

The initial creation of the database schema will be done automatically. Check if everything went well with:

```sh
docker logs -f pleroma_web
```

Make a new admin user using docker exec (replace fakeadmin with any username you'd like):

```sh
docker exec -it pleroma_web sh ./bin/pleroma_ctl user new fakeadmin admin@test.net --admin
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

This value can also be set through `docker-compose.yml` as seen in the example file provided in this repository.

## Config Override

By default the provided `docker-compose.yml` file mounts `config.exs` in the Pleroma container, this file is a dynamic configuration that sources some values from the environment variables provided to the container (variables like `ADMIN_EMAIL` etc.).

For those that want to change configuration that is not exposed through environment variables there is the option to mount the `config-override.exs` file which can than be modified to your satisfaction. Values set in this file will override anything set in `config.exs`. The override file provided in this repository disables new registrations on your instance, as an example.

## Other Docker images

Here are other Pleroma Docker images that helped me build mine:

- [potproject/docker-pleroma](https://github.com/potproject/docker-pleroma)
- [rysiek/docker-pleroma](https://git.pleroma.social/rysiek/docker-pleroma)
- [RX14/iscute.moe](https://github.com/RX14/kurisu.rx14.co.uk/blob/master/services/iscute.moe/pleroma/Dockerfile)
