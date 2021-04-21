FROM caddy:2.3.0-builder-alpine AS builder

RUN caddy-builder \
    github.com/caddy-dns/cloudflare

FROM caddy:2.3.0-alpine

RUN apk add --no-cache ca-certificates curl bind-tools jq

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY data /data/caddy
COPY run.sh /run.sh

ENTRYPOINT [ "/run.sh" ]
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]