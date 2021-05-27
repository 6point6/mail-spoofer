#!/bin/sh

zone=${DOMAIN}
track_dnsrecord=${TRACK_DOMAIN}

# Replace ALL domain name records within Caddyfile
sed -i "s/REPLACE_DOMAIN/$zone/"g /etc/caddy/Caddyfile
sed -i "s/REPLACE_TRACK_DOMAIN/$track_dnsrecord/"g /etc/caddy/Caddyfile

# Get the current external IP address
ip=$(curl -s -X GET https://checkip.amazonaws.com)

# Get the zone id for the requested zone
zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
-H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

# Add A record
add_a_record() {
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$1\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}" | jq
}

# Add MX record
add_mx_record() {
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
     --data "{\"type\":\"MX\",\"name\":\"$1\",\"content\":\"$1\",\"ttl\":120,\"priority\":0,\"proxied\":false}" | jq
}

# Check Cloudflare API Token is set
if [[ -z "${CLOUDFLARE_API_TOKEN}" ]]; then
    echo "YOU NEED TO MANUALLY UPDATE DNS RECORDS"
    echo "WARNING: CERTIFICATES MAY NOT BE ISSUED PROPERLY!"
    echo "A root @ record for $zone with value $ip"
    echo "A record for $track_dnsrecord with value $ip"
    # Continue with running Caddy
    exec "$@"
else
    echo "Adding records to Cloudflare..."
fi

# Check @ root name points to server IP address
if host $zone | grep "has address" | grep "$ip"; then
    echo "Record exists."
else
    add_a_record $zone
    add_mx_record $zone
fi

# Check track domain points to server IP address
if host $track_dnsrecord | grep "has address" | grep "$ip"; then
    echo "Record Exists"
else
    add_a_record $track_dnsrecord
fi

echo "All DNS records are up-to-date."
# Continue with Caddy:
exec "$@"