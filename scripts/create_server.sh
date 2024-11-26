#!/bin/bash

# Hetzner API endpoint
API_URL="https://api.hetzner.cloud/v1/servers"

# Construct JSON payload
cloud_config=$(envsubst < "scripts/cloud-config.yaml" | sed ':a;N;$!ba;s/\n/\\n/g')

payload=$(cat <<EOF
{
  "automount": false,
  "datacenter": "nbg1-dc3",
  "firewalls": [
    {
      "firewall": ${FW_ID}
    }
  ],
  "image": "ubuntu-22.04",
  "name": "${server_name}",
  "public_net": {
    "enable_ipv4": true,
    "enable_ipv6": false,
    "ipv4": ${IP_ID}
  },
  "server_type": "cx22",
  "ssh_keys": [
    ${SSH_ID}
  ],
  "start_after_create": true,
  "user_data": "${cloud_config}"
}
EOF
)

# Execute curl command
response=$(curl -s -w "\n%{http_code}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -d "$payload" \
  "$API_URL")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

# Check HTTP status code
if [ "$http_code" -eq 201 ]; then
    echo "Server creation successful!"
else
    echo "Error creating server. HTTP Status Code: $http_code"
    echo "Error details:"
    echo "$body" | jq .
    exit 1
fi
