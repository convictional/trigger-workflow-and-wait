FROM alpine:3.15.0

RUN apk update
RUN apk --no-cache add curl jq coreutils

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
