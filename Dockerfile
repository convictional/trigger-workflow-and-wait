# https://hub.docker.com/_/alpine
FROM alpine:3.15.0

RUN apk update && \
    apk --no-cache add curl jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
