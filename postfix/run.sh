#!/bin/sh

# Make and reown postfix folders
mkdir -p /var/spool/postfix/ && mkdir -p /var/spool/postfix/pid
chown root: /var/spool/postfix/
chown root: /var/spool/postfix/pid

# Blackhole return path domain to stop postfix bounce loop
echo "72.5.65.111 $DOMAIN" >> /etc/hosts
echo "no-reply:         /dev/null" >> /etc/postfix/aliases
postalias /etc/postfix/aliases

# Disable SMTPUTF8, because libraries (ICU) are missing in alpine
postconf -e "smtputf8_enable=no"

# Resolve DNS using /etc/hosts
postconf -e "smtp_host_lookup=native"

# Enable local mail delivery (Bounced Messages)
postconf -e "mydestination=localhost"

# Hostname
postconf -e "myhostname=$DOMAIN"

# Don't relay for any domains
#postconf -e relay_domains=
postconf -e "message_size_limit=0"
postconf -e "header_size_limit=4096000"
postconf -e "mailbox_size_limit=0"

# Reject invalid HELOs
#postconf -e smtpd_delay_reject=yes
#postconf -e smtpd_helo_required=yes
#postconf -e "smtpd_helo_restrictions=permit_mynetworks,reject_invalid_helo_hostname,permit"
#postconf -e "smtpd_sender_restrictions=permit_mynetworks"

# Mail user agent restrictions adapted from https://askubuntu.com/a/1132874
postconf -e "smtpd_restriction_classes = mua_sender_restrictions,mua_client_restrictions,mua_helo_restrictions"
postconf -e "mua_sender_restrictions = permit_sasl_authenticated,reject"
postconf -e "mua_client_restrictions = permit_sasl_authenticated,reject"
postconf -e "mua_helo_restrictions = permit_mynetworks,reject_non_fqdn_hostname,reject_invalid_hostname,permit"

# No Authentication
postconf -e "smtpd_sasl_auth_enable = no"

# Enabled encryption
postconf -e "smtp_tls_security_level = encrypt"

# Rspamd Milter configuration
postconf -e "milter_default_action = accept"
postconf -e "milter_protocol = 6"
#milter_mail_macros = i {mail_addr} {client_addr} {client_name} {auth_authen}
postconf -e "smtpd_milters = inet:rspamd:11332"
postconf -e "non_smtpd_milters = inet:rspamd:11332"

# Return-Path (MFrom address)
if [ ! -z "$RETURN_PATH_ADDRESS" ]; then
	postconf -e "sender_canonical_maps = static:$RETURN_PATH_ADDRESS"
else
	postconf -# sender_canonical_maps
fi

# Set up a Relay Host using SendGrid API
if [ ! -z "$SENDGRID_API_KEY" ]; then

        echo "$RELAYHOST apikey:$SENDGRID_API_KEY" > /etc/postfix/sasl_passwd
        postmap /etc/postfix/sasl_passwd
        postconf -e "relayhost=$RELAYHOST"
        postconf -e "smtp_sasl_auth_enable=yes"
        postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
        postconf -e "smtp_sasl_security_options = noanonymous"
        postconf -e "smtp_sasl_tls_security_options = noanonymous"
        postconf -e "header_size_limit = 4096000"

else
        postconf -# relayhost
        postconf -# smtp_sasl_auth_enable
        postconf -# smtp_sasl_password_maps
        postconf -# smtp_sasl_security_options
fi

# MyNetworks
if [ ! -z "$MYNETWORKS" ]; then
	postconf -e "mynetworks=$MYNETWORKS"
else
    # Use default networks
	postconf -e "mynetworks=127.0.0.0/8,172.16.0.0/12"
fi

# Remove headers before sending Mail
postconf -e "smtp_header_checks=regexp:/etc/postfix/header_checks"

# Start Postfix service with Supervisor Daemon
exec supervisord -c /etc/supervisord.conf
