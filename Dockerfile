ARG ALPINE_VERSION=3.9
ARG ELIXIR_VERSION=1.10.3

FROM elixir:${ELIXIR_VERSION}-alpine AS builder

ARG APP_NAME
ARG APP_VERSION
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME}
ENV APP_VERSION=${APP_VERSION}
ENV MIX_ENV=${MIX_ENV}

WORKDIR /opt/app

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache build-base && \
    mix local.rebar --force && \
    mix local.hex --force

COPY . .

RUN mix do deps.get, deps.compile, compile

RUN mkdir -p /opt/build && \
    mix distillery.release --verbose && \
    cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VERSION}/${APP_NAME}.tar.gz /opt/build && \
    cd /opt/build && \
    tar -xzf ${APP_NAME}.tar.gz && \
    rm ${APP_NAME}.tar.gz

FROM alpine:${ALPINE_VERSION}

ARG APP_NAME

RUN apk update && \
    apk add --no-cache bash openssl-dev python3 py3-pip py3-numpy

ENV REPLACE_OS_VARS=true
ENV APP_NAME=${APP_NAME}
ENV PYTHONPATH=/usr/lib/python3.6/site-packages

WORKDIR /opt/app

COPY --from=builder /opt/build /opt/app/requirements.txt ./
COPY --from=builder /opt/app/priv ./priv

RUN pip3 install -r requirements.txt
RUN ln -s /usr/bin/python3 /usr/bin/python

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} foreground
