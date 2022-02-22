# https://hub.docker.com/_/alpine
FROM alpine:latest

RUN apk update
RUN apk --no-cache add curl jq coreutils

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
