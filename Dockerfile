##############
# LITESTREAM #
##############

FROM litestream/litestream:0.3.13 AS litestream

#########
# MECAB #
#########

FROM ghcr.io/ruslandoga/mecab-alpine:mecab AS mecab

#########
# BUILD #
#########

FROM hexpm/elixir:1.17.3-erlang-27.1-alpine-3.20.3 AS build

# install build dependencies
RUN apk add --no-cache --update git build-base nodejs npm

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/
RUN mix deps.get
RUN mix deps.compile

# build project
COPY priv priv
COPY lib lib
RUN mix compile
RUN mix sentry.package_source_code
COPY config/runtime.exs config/

# build assets
COPY assets assets
RUN mix assets.deploy

# build release
RUN mix release

#######
# APP #
#######

FROM alpine:3.20.3 AS app

RUN adduser -S -H -u 999 -G nogroup sentence-mining

RUN apk add --no-cache --update openssl libgcc libstdc++ ncurses

COPY --from=build --chmod=a+rX /app/_build/prod/rel/m /app
COPY --from=litestream --chmod=a+X /usr/local/bin/litestream /usr/local/bin/litestream
COPY --from=mecab --chmod=a+X /usr/local /usr/local
COPY litestream.yml /etc/litestream.yml

RUN mkdir -p /data && chmod ugo+rw -R /data
RUN wget -O /data/jmdict.db 'https://github.com/ruslandoga/jp-sqlite/releases/download/jmdict/jmdict.db' && chmod a+rw /data/jmdict.db

USER 999
WORKDIR /app
ENV HOME=/app
ENV DB_PATH=/data/m_prod.db
ENV JMDICT_DB_PATH=/data/jmdict.db
VOLUME /data

CMD litestream restore -if-db-not-exists -if-replica-exists $DB_PATH && litestream replicate -exec "/app/bin/m start"
