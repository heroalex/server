#!/bin/bash
set -e

echo "Setting up Caddy container..."
source /root/.secrets

set -x

# Create container configuration directory
mkdir -p /mnt/volume1/caddy/{data,config,etc,site,wg0}

if [ ! -f "/mnt/volume1/caddy/site/index.html" ]; then
    echo "creating public dummy index.html..."
    echo "Hello World!" > /mnt/volume1/caddy/site/index.html
fi

if [ ! -f "/mnt/volume1/caddy/wg0/index.html" ]; then
    echo "creating wg0 dummy index.html..."
    echo "Hello WG0!" > /mnt/volume1/caddy/wg0/index.html
fi

cat > /mnt/volume1/caddy/etc/Caddyfile << EOF
(hetzner_acme_dns) {
	tls {
		dns hetzner ${HETZNER_DNS_TOKEN}
		propagation_timeout -1
		propagation_delay 30s
	}
}

(abort_n_wg0) {
  @n_wg0 {
    not remote_ip ${WG0_IP_PREFIX}.0/24
  }
  abort @n_wg0
}

${ROOT_DOMAIN_1} {
  import hetzner_acme_dns
	root * /usr/share/caddy/site
	file_server
}

${WG0_DOMAIN_1} {
  import hetzner_acme_dns
  bind ${WG0_IP_PREFIX}.1
  import abort_n_wg0
	root * /usr/share/caddy/wg0
	file_server
}

${GRAFANA_DOMAIN_1} {
  import hetzner_acme_dns
  bind ${WG0_IP_PREFIX}.1
  import abort_n_wg0
  reverse_proxy 127.0.0.1:3000
}

${OMADA_DOMAIN_1} {
  import hetzner_acme_dns
  bind ${WG0_IP_PREFIX}.1
  import abort_n_wg0
  reverse_proxy 127.0.0.1:8043 {
    transport http {
      tls_insecure_skip_verify
    }
      header_up Host {host}:8043
      header_down Location :8043 :443
  }
}

${VAULT_DOMAIN_1} {
  import hetzner_acme_dns
  bind ${WG0_IP_PREFIX}.1
  import abort_n_wg0

#  log {
#    level INFO
#    output file {\$LOG_FILE} {
#      roll_size 10MB
#      roll_keep 10
#    }
#  }

  # Uncomment to improve security (WARNING: only use if you understand the implications!)
  # If you want to use FIDO2 WebAuthn, set X-Frame-Options to "SAMEORIGIN" or the Browser will block those requests
  # header / {
  #	# Enable HTTP Strict Transport Security (HSTS)
  #	Strict-Transport-Security "max-age=31536000;"
  #	# Disable cross-site filter (XSS)
  #	X-XSS-Protection "0"
  #	# Disallow the site to be rendered within a frame (clickjacking protection)
  #	X-Frame-Options "DENY"
  #	# Prevent search engines from indexing (optional)
  #	X-Robots-Tag "noindex, nofollow"
  #	# Disallow sniffing of X-Content-Type-Options
  #	X-Content-Type-Options "nosniff"
  #	# Server name removing
  #	-Server
  #	# Remove X-Powered-By though this shouldn't be an issue, better opsec to remove
  #	-X-Powered-By
  #	# Remove Last-Modified because etag is the same and is as effective
  #	-Last-Modified
  # }

  # Proxy everything to Rocket
  # if located at a sub-path the reverse_proxy line will look like:
  #   reverse_proxy /subpath/* <SERVER>:80
  reverse_proxy 127.0.0.1:8880 {
       # Send the true remote IP to Rocket, so that Vaultwarden can put this in the
       # log, so that fail2ban can ban the correct IP.
       header_up X-Real-IP {remote_host}
       # If you use Cloudflare proxying, replace remote_host with http.request.header.Cf-Connecting-Ip
       # See https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/
       # and https://caddy.community/t/forward-auth-copy-headers-value-not-replaced/16998/4
  }
}

# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile
EOF

# Create container definition using quadlet
cat > /etc/containers/systemd/caddy.container << EOF
[Unit]
Description=Caddy Container
After=network-online.target mnt-volume1.mount
Requires=mnt-volume1.mount

[Container]
Image=ghcr.io/heroalex/caddy-docker:master
Volume=/mnt/volume1/caddy/etc/:/etc/caddy/
Volume=/mnt/volume1/caddy/config/:/config/
Volume=/mnt/volume1/caddy/data/:/data/
Volume=/mnt/volume1/caddy/site/:/usr/share/caddy/site/
Volume=/mnt/volume1/caddy/wg0/:/usr/share/caddy/wg0/
Network=host
PublishPort=80:80
PublishPort=443:443
Label=io.containers.autoupdate=registry

[Service]
Restart=on-failure
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chmod 644 /mnt/volume1/caddy/etc/Caddyfile
chmod 644 /etc/containers/systemd/caddy.container

# Reload systemd and enable container
systemctl daemon-reload
systemctl start caddy