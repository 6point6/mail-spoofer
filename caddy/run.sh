#!/bin/sh

# Replace DOMAIN within Caddyfile
sed -i "s/REPLACE_DOMAIN/${PHISH_DOMAIN}/g" /etc/caddy/Caddyfile

# Cloudflare zone is the zone which holds the record
zone=${DOMAIN}
dnsrecord=${PHISH_DOMAIN}

# Get the current external IP address
ip=$(curl -s -X GET https://checkip.amazonaws.com)

echo "System Public IP: $ip"

if host $dnsrecord | grep "has address" | grep "$ip"; then
    echo "$dnsrecord is currently set to $ip; no changes needed"
else
    # get the zone id for the requested zone
    zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

    echo "[$zone] Zone ID: $zoneid"

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}" | jq
    
    # Change @ root record
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$zone\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}" | jq
    
fi

# Continue with Caddy:
exec "$@"