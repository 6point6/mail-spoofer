#!/bin/sh

# Set standard logging if no modification exists
if [ ! -e /etc/rspamd/local.d/logging.inc ] && [ ! -e /etc/rspamd/override.d/logging.inc ];
then
    echo 'type = "console";' > /etc/rspamd/local.d/logging.inc
fi

# Check DKIM key pair exists
if [ ! -e /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.key ];
then
    rspamadm dkim_keygen -s ${DKIM_TAG} -d ${DOMAIN} -b 2048 -k /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.key > /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.pub
fi

# Replace DKIM config
sed -i "s/REPLACE_DOMAIN/${DOMAIN}/g" /etc/rspamd/local.d/dkim_signing.conf
sed -i "s/DKIM_TAG/${DKIM_TAG}/g" /etc/rspamd/local.d/dkim_signing.conf
# Replace ARC config
sed -i "s/REPLACE_DOMAIN/${DOMAIN}/g" /etc/rspamd/local.d/arc.conf
sed -i "s/DKIM_TAG/${DKIM_TAG}/g" /etc/rspamd/local.d/arc.conf

echo "############# BEGIN ###############"
echo " ENTER THE FOLLOWING DNS RECORDS "
echo " Domain: ${DOMAIN}"
echo " DKIM Selector: ${DKIM_TAG}"
echo $(cat /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.pub)
#echo $(rspamadm dkim_keygen -s ${DKIM_TAG} -d ${DOMAIN} -b 2048 -k /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.key)
echo "############## END #################"

# Execute the CMD from the Dockerfile:
exec "$@"
