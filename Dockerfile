# https://hub.docker.com/_/alpine
FROM alpine:latest

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
