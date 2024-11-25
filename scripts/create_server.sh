#!/bin/bash

# Check if all required arguments are provided
if [ $# -ne 8 ]; then
    echo "Usage: $0 <firewall_id> <server_name> <public_ipv4_id> <ssh_key_id> <username> <ssh_public_key> <wireguard_private_key> <wireguard_public_key>"
    exit 1
fi

# Hetzner API endpoint
API_URL="https://api.hetzner.cloud/v1/servers"

# API Token - IMPORTANT: Replace this with your actual Hetzner API token
# Best practice: Use an environment variable or pass it as a parameter
API_TOKEN="${HETZNER_API_TOKEN:-YOUR_API_TOKEN_HERE}"

# Construct JSON payload
payload=$(cat <<EOF
{
  "automount": false,
  "datacenter": "nbg1-dc3",
  "firewalls": [
    {
      "firewall": "$1"
    }
  ],
  "image": "ubuntu-22.04",
  "name": "$2",
  "public_net": {
    "enable_ipv4": true,
    "enable_ipv6": false,
    "ipv4": $3
  },
  "server_type": "cx22",
  "ssh_keys": [
    $4
  ],
  "start_after_create": true,
  "user_data": "#cloud-config\nusers:\n  - name: $5\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    shell: /bin/bash\n    ssh_authorized_keys:\n      - \"$6\"\n\npackage_upgrade: true\npackages:\n  - wireguard\n  - podman\n\nwrite_files:\n  - path: /etc/wireguard/wg0.conf\n    content: |\n      [Interface]\n      PrivateKey = $7\n      ListenPort = 13231\n      Address = 172.16.16.1/24\n\n      [Peer]\n      PublicKey = $8\n      AllowedIPs = 172.16.16.90/32\n    permissions: '0600'\n\n  - path: /etc/systemd/system/wg-quick@.service.d/override.conf\n    content: |\n      [Unit]\n      Before=sshd.service\n      \n      [Service]\n      Type=oneshot\n      RemainAfterExit=yes\n    permissions: '0644'\n\n  - path: /etc/ssh/sshd_config\n    content: |\n      Port 22\n      Protocol 2\n      PermitRootLogin no\n      PubkeyAuthentication yes\n      PasswordAuthentication no\n      ChallengeResponseAuthentication no\n      UsePAM no\n      X11Forwarding no\n      AllowTcpForwarding no\n      AllowAgentForwarding no\n      PermitTunnel no\n      PrintMotd no\n      AcceptEnv LANG LC_*\n      AllowUsers $5\n      ListenAddress 172.16.16.1\n\nruncmd:\n  - usermod -p '*' $5\n  - systemctl daemon-reload\n  - systemctl enable wg-quick@wg0\n  - systemctl start wg-quick@wg0\n  - systemctl restart ssh\n  - reboot\n"
}
EOF
)

# Execute curl command
response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d "$payload" \
  "$API_URL")

# Check for errors in the response
if echo "$response" | grep -q "error"; then
    echo "Error creating server:"
    echo "$response" | jq .
    exit 1
fi

# Print server details
echo "Server creation response:"
echo "$response" | jq .
