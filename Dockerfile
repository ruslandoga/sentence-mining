##############
# LITESTREAM #
##############

FROM litestream/litestream:0.3.9 AS litestream

#########
# MECAB #
#########

FROM ghcr.io/ruslandoga/mecab-alpine:mecab AS mecab

##########
# JMDICT #
##########

FROM alpine:3.16.2 AS jmdict

# TODO lz4
RUN apk add --no-cache --update curl
RUN curl 'https://github.com/ruslandoga/jp-sqlite/releases/download/jmdict/jmdict.db' -LO

#########
# BUILD #
#########

FROM hexpm/elixir:1.14.4-erlang-25.1.2-alpine-3.16.2 as build

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
RUN mix sentry_recompile
COPY config/runtime.exs config/

# build assets
COPY assets assets
RUN mix assets.deploy

# build release
RUN mix release

#######
# APP #
#######

FROM alpine:3.16.2 AS app
RUN apk add --no-cache --update bash openssl libgcc libstdc++

WORKDIR /app

RUN chown nobody:nobody /app
USER nobody:nobody

COPY --from=litestream /usr/local/bin/litestream /usr/local/bin/litestream
COPY --from=mecab /usr/local /usr/local
COPY --from=jmdict --chown=nobody:nobody /jmdict.db ./
COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/m ./
COPY litestream.yml /etc/litestream.yml

ENV HOME=/app

CMD litestream restore -if-db-not-exists -if-replica-exists $DB_PATH && litestream replicate -exec "/app/bin/m start"
