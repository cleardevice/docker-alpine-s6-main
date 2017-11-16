FROM alpine:3.6

MAINTAINER cd <cleardevice@gmail.com>

ENV TERM=xterm
RUN apk add --no-cache bash git wget curl nano ca-certificates && \
    rm -rf /var/cache/apk/*

ENV S6_VER=1.21.2.1

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_VER}/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ENTRYPOINT ["/init"]
