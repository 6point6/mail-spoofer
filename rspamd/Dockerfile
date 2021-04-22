FROM alpine:latest
LABEL maintainer="Naz Markuta naz.markuta@6point6.co.uk"
# source https://github.com/Mailu/Mailu/tree/master/core/rspamd

#ARG DOMAIN
#ARG DKIM_TAG

#ENV DOMAIN $DOMAIN
#ENV DKIM_TAG $DKIM_TAG

# Image specific layers under this line
RUN apk add --no-cache rspamd rspamd-proxy rspamd-fuzzy ca-certificates curl bind-tools jq

RUN mkdir /run/rspamd
RUN mkdir /var/lib/rspamd/dkim/

# Config folder and start-up script
#COPY conf/ /conf
#COPY start.py /start.py

COPY local.d/ /etc/rspamd/local.d
COPY override.d/ /etc/rspamd/override.d
COPY docker-entrypoint.sh /
COPY lua_auth_results.lua /usr/share/rspamd/lualib/lua_auth_results.lua
RUN chmod +x /docker-entrypoint.sh

# Ports for Rspamd
EXPOSE 11332/tcp 11334/tcp 11335/tcp

# Initialise configuration files and update DNS records
ENTRYPOINT [ "/docker-entrypoint.sh" ]

# -i Ignore running workers as root, -f Do not daemonize main process
CMD ["rspamd", "-i", "-f"]

#HEALTHCHECK --start-period=350s CMD curl -f -L http://localhost:11334/ || exit 1
