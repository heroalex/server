#!/bin/bash
set -e

echo "Creating sshd_config..."
source /root/.secrets

set -x

usermod -p '*' ${SSH_USERNAME}

cat > /etc/ssh/sshd_config.d/40-sshd-harden.conf << EOF
Port 22
Protocol 2
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
#UsePAM no
X11Forwarding no
AllowTcpForwarding yes
AllowAgentForwarding no
PermitTunnel no
PrintMotd yes
AcceptEnv LANG LC_*
AllowUsers ${SSH_USERNAME}
ListenAddress ${WG0_IP_PREFIX}.1
EOF

chmod 0600 /etc/ssh/sshd_config.d/40-sshd-harden.conf