# server

#### check if ports are open
ss -tulpn | grep -E '139|445'

#### from client check if port is accessible
nc -zv 172.16.16.1 139

#### scan network
nmap -sn 172.16.16.0/24

#### test port
nc -vuz 172.16.16.1 13231
nmap -p 13231 -sU 172.16.16.1

#### tcp portscan
nmap -p- localhost

#### tcp portscan with service detection
nmap -sV -p- localhost

#### UDP port scanning
nmap -sU localhost

#### show recent selinux violations
ausearch -m AVC -ts recent

#### podman login into container
podman exec -it systemd-samba /bin/bash

#### show interfaces and ip addresses
ip addr

#### show failed systemd services
systemctl status --failed

#### show / follow log of a systemd service
journalctl -u node_exporter -f

#### Check NFS exports status
exportfs -v

#### list open files
lsof /var/mnt/storage_l1

#### show who uses a file
fuser -v /var/mnt/storage_l1

#### unmount cifs share
umount -l /var/mnt/storage_l1

#### on windows delete network mounts
net use * /delete

#### list firewall rules
nft list ruleset

#### Caddy reload Caddyfile
podman exec -w /etc/caddy systemd-caddy caddy reload

#### DEBUG Wireguard
##### enable
echo "module wireguard +p" | tee /sys/kernel/debug/dynamic_debug/control
##### watch kernel log
dmesg -wT
##### disable
echo "module wireguard -p" | tee /sys/kernel/debug/dynamic_debug/control

#### Podman remove all images
podman image prune -a

