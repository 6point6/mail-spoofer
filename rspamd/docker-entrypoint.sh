#!/bin/sh

# DNS Name for DKIM selector e.g. default._domainkey.example.com
dns_name=${DKIM_TAG}._domainkey.${DOMAIN}

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
echo " Domain: ${DOMAIN}"
echo " DKIM Selector: ${DKIM_TAG}"

# Get the public key and remove new lines
record=$(awk -F '"' '{ print $2 $4 }' /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.pub | tr -d '\n')

# Get Cloudflare Zone ID
zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

echo " ADDING TXT DNS RECORD TO CLOUDFLARE "

# Add new TXT type DNS Record
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"TXT\",\"name\":\"$dns_name\",\"content\":\"$record\",\"ttl\":120,\"proxied\":false}" | jq

echo "############## END #################"

# Execute the CMD from the Dockerfile:
exec "$@"
