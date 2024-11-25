#!/bin/bash

# Hetzner API endpoint
API_URL="https://api.hetzner.cloud/v1/servers"

# Construct JSON payload
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
  "user_data": "#cloud-config\nusers:\n  - name: ${user_name}\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    shell: /bin/bash\n    ssh_authorized_keys:\n      - \"${SSH_KEY}\"\n\npackage_upgrade: true\npackages:\n  - wireguard\n  - podman\n\nwrite_files:\n  - path: /etc/wireguard/wg0.conf\n    content: |\n      [Interface]\n      PrivateKey = ${WG_PRIV_KEY}\n      ListenPort = 13231\n      Address = 172.16.16.1/24\n\n      [Peer]\n      PublicKey = ${WG_PUB_KEY}\n      AllowedIPs = 172.16.16.90/32\n    permissions: '0600'\n\n  - path: /etc/systemd/system/wg-quick@.service.d/override.conf\n    content: |\n      [Unit]\n      Before=sshd.service\n      \n      [Service]\n      Type=oneshot\n      RemainAfterExit=yes\n    permissions: '0644'\n\n  - path: /etc/ssh/sshd_config\n    content: |\n      Port 22\n      Protocol 2\n      PermitRootLogin no\n      PubkeyAuthentication yes\n      PasswordAuthentication no\n      ChallengeResponseAuthentication no\n      UsePAM no\n      X11Forwarding no\n      AllowTcpForwarding no\n      AllowAgentForwarding no\n      PermitTunnel no\n      PrintMotd no\n      AcceptEnv LANG LC_*\n      AllowUsers ${user_name}\n      ListenAddress 172.16.16.1\n\nruncmd:\n  - usermod -p '*' ${user_name}\n  - systemctl daemon-reload\n  - systemctl enable wg-quick@wg0\n  - systemctl start wg-quick@wg0\n  - systemctl restart ssh\n  - reboot\n"
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
