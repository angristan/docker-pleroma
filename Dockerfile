FROM elixir:1.14-alpine

ARG PLEROMA_VER=develop
ARG UID=911
ARG GID=911

ENV MIX_ENV=prod
ENV VIX_COMPILATION_MODE=PLATFORM_PROVIDED_LIBVIPS

RUN echo "http://nl.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && apk update \
    && apk add git gcc g++ musl-dev make cmake file-dev vips-dev \
    exiftool imagemagick vips libmagic ncurses postgresql-client ffmpeg \
    openssl-dev

RUN addgroup -g ${GID} pleroma \
    && adduser -h /pleroma -s /bin/false -D -G pleroma -u ${UID} pleroma

ARG DATA=/var/lib/pleroma
RUN mkdir -p /etc/pleroma \
    && chown -R pleroma /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R pleroma ${DATA}

USER pleroma
WORKDIR /pleroma

RUN git clone -b develop https://git.pleroma.social/pleroma/pleroma.git /pleroma \
    && git checkout ${PLEROMA_VER}

RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /pleroma

COPY --chown=pleroma --chmod=640 ./config.exs /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
