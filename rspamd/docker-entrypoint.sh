#!/bin/sh

# DNS name for DKIM selector e.g. default._domainkey.example.com
dkim_name=${DKIM_TAG}._domainkey.${DOMAIN}
# DNS name for DMARC record e.g. _dmarc.example.com
dmarc_name=_dmarc.${DOMAIN}
# DNS name for SPF record
spf_name=${DOMAIN}

# Get IP address
ip=$(curl -s -X GET https://checkip.amazonaws.com)
sed -i "s/DYNAMIC_IP_ADDRESS/$ip/g" /usr/share/rspamd/lualib/lua_auth_results.lua

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
echo " Domain: ${DOMAIN} "

# Get the public key and remove new lines
dkim_record=$(awk -F '"' '{ print $2 $4 }' /var/lib/rspamd/dkim/${DOMAIN}.${DKIM_TAG}.pub | tr -d '\n')
# Add a strict DMARC policy for our own domain
dmarc_record="v=DMARC1; p=reject; adkim=s; aspf=s;"
# Add a current IP address to SPF record 
spf_record="v=spf1 ip4:$ip -all"

echo " ADDING DNS RECORDS TO CLOUDFLARE "
echo " DMARC value: $dmarc_record "
echo " DKIM value: $dkim_record"
echo " SPF value: $spf_record "

# Get Cloudflare Zone ID
zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

# Add new DKIM TXT type DNS Record
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"TXT\",\"name\":\"$dkim_name\",\"content\":\"$dkim_record\",\"ttl\":120,\"proxied\":false}" | jq

# Add new DMARC TXT type DNS Record
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"TXT\",\"name\":\"$dmarc_name\",\"content\":\"$dmarc_record\",\"ttl\":120,\"proxied\":false}" | jq

# Add new SPF TXT type DNS Record
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"TXT\",\"name\":\"$spf_name\",\"content\":\"$spf_record\",\"ttl\":120,\"proxied\":false}" | jq

echo "############## END #################"

# Execute the CMD from the Dockerfile:
exec "$@"
