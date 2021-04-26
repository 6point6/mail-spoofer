FROM alpine:3.11
LABEL maintainer="Naz Markuta naz.markuta@6point6.co.uk"

# Install required packages
RUN apk add --no-cache postfix tzdata supervisor rsyslog libsasl cyrus-sasl-plain

# Set up configuration 
COPY run.sh /
# Remove the below when pushing to dockerhub
RUN chmod +x /run.sh
COPY supervisord.conf /etc/supervisord.conf
COPY rsyslog.conf /etc/rsyslog.conf
COPY header_checks /etc/postfix/header_checks

# Run supervisord
USER       root
WORKDIR    /tmp

EXPOSE     25
CMD        ["/bin/sh", "-c", "/run.sh"]
