FROM caddy:2.1.1-builder AS builder

RUN caddy-builder \
    github.com/caddy-dns/cloudflare

FROM caddy:2.1.1-alpine

RUN apk add --no-cache ca-certificates curl bind-tools jq

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /site
COPY run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]