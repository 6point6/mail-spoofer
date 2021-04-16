FROM alpine:latest
LABEL maintainer="Naz Markuta naz.markuta@6point6.co.uk"
# source https://github.com/Mailu/Mailu/tree/master/core/rspamd

ARG DOMAIN
ARG DKIM_TAG

ENV DOMAIN $DOMAIN
ENV DKIM_TAG $DKIM_TAG

# Image specific layers under this line
RUN apk add --no-cache rspamd rspamd-controller rspamd-proxy rspamd-fuzzy ca-certificates curl

RUN mkdir /run/rspamd
RUN mkdir /var/lib/rspamd/dkim/

# Config folder and start-up script
#COPY conf/ /conf
#COPY start.py /start.py

COPY local.d/ /etc/rspamd/local.d
COPY override.d/ /etc/rspamd/override.d
COPY docker-entrypoint.sh /

# Ports for Rspamd
EXPOSE 11332/tcp 11334/tcp 11335/tcp

# Generate a DKIM public key pair
# RUN echo $(ls -1 /tmp/dir)

# Move the following into the docker-entrypoint.sh
#RUN echo "###################################"
#RUN echo "# ENTER THE FOLLOWING DNS RECORDS #"
#RUN echo $(rspamadm dkim_keygen -s ${DKIM_TAG} -d ${DOMAIN} -b 2048 -k /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.key)
#RUN echo $(rspamadm dkim_keygen -s ${DKIM_TAG} -d ${DOMAIN} -b 2048 -k /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.key > /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.pub)

# Replace DKIM config
RUN sed -i "s/REPLACE_DOMAIN/${DOMAIN}/g" /etc/rspamd/local.d/dkim_signing.conf
RUN sed -i "s/DKIM_TAG/${DKIM_TAG}/g" /etc/rspamd/local.d/dkim_signing.conf
# Replace ARC config
RUN sed -i "s/REPLACE_DOMAIN/${DOMAIN}/g" /etc/rspamd/local.d/arc.conf
RUN sed -i "s/DKIM_TAG/${DKIM_TAG}/g" /etc/rspamd/local.d/arc.conf

ENTRYPOINT [ "/docker-entrypoint.sh" ]

# -i Ignore running workers as root, -f Do not daemonize main process
CMD ["rspamd", "-i", "-f"]

#HEALTHCHECK --start-period=350s CMD curl -f -L http://localhost:11334/ || exit 1
