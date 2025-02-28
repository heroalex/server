#!/bin/bash
set -eux

cat > /etc/nftables.conf << EOF
#!/usr/sbin/nft -f

# Flush existing ruleset
flush ruleset

# Define tables and chains
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop

        # Connection tracking
        ct state invalid drop
        ct state established,related accept

        # Allow loopback
        iifname "lo" accept

        # Allow Wireguard
        udp dport 13231 accept
        udp dport 13232 accept

        # Allow ICMP and ICMPv6 for basic network functionality
        # ip protocol icmp accept
        # ip6 nexthdr icmpv6 accept

        # Allow all on Wireguard interface
        iifname "wg0" accept
        iifname "wg1" accept

        # Optional: Allow HTTP/HTTPS
        tcp dport { 80, 443 } accept

        # Log dropped packets
        # log prefix "nft-input-dropped: " counter drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop

        # Allow forwarding on Wireguard interface if needed
        iifname "wg0" accept
        oifname "wg0" accept

        iifname "wg1" accept
        oifname "wg1" accept

        # Log dropped packets
        # log prefix "nft-forward-dropped: " counter drop
    }

    chain output {
        type filter hook output priority 0; policy accept
    }
}

# NAT table if needed
#table ip nat {
#    chain prerouting {
#        type nat hook prerouting priority -100
#    }
#
#    chain postrouting {
#        type nat hook postrouting priority 100
#        # Add masquerade rules if needed
#        # oifname "eth0" masquerade
#    }
#}
EOF

chmod 700 /etc/nftables.conf

cat > /etc/systemd/system/nftables.service << EOF
[Unit]
Description=nftables
Documentation=man:nft(8) http://wiki.nftables.org
Conflicts=firewalld.service
Wants=network-online.target
Wants=wg-quick.target
Wants=openvpn.target
After=network-online.target
After=wg-quick.target
After=openvpn.target
#DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
StandardInput=null
ProtectSystem=full
ProtectHome=true
ExecStart=/usr/sbin/nft -f /etc/nftables.conf
ExecReload=/usr/sbin/nft -f /etc/nftables.conf
ExecStop=/usr/sbin/nft flush ruleset
#ReadWriteDirectories=/var/lib/nftables/

[Install]
WantedBy=sysinit.target
EOF

dont() {
cat > /etc/sysctl.d/99-security.conf << EOF
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 0
EOF

# sysctl -p /etc/sysctl.d/99-security.conf
}

systemctl daemon-reload
systemctl enable nftables
systemctl start nftables
