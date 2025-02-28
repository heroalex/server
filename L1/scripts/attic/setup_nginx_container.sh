#!/bin/bash
set -ex # no u because of nginx variables

# Create necessary directories

mkdir -p /etc/nginx/{conf.d,ssl}
chmod 755 /etc/nginx/ssl
chmod 755 /etc/nginx/conf.d

mkdir -p /var/log/nginx
chmod 755 /var/log/nginx

# Create base nginx configuration
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    # Security headers
    server_tokens off;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # SSL configuration will be added here
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF
chmod 644 /etc/nginx/nginx.conf

# Create default server configuration
cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80 default_server;
#    listen [::]:80 default_server; # ipv6 disabled
    server_name _;

    # Will be used for SSL redirect later
    location /test-html {
        root /var/www/html;
        index index.html;
    }

    # Basic health check endpoint
    location /test-health {
        access_log off;
        return 200 "healthy\n";
    }
}
EOF
chmod 644 /etc/nginx/conf.d/default.conf

cat > /etc/nginx/conf.d/nextcloud.conf << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
#    listen [::]:80;            # comment to disable IPv6

#    if ($scheme = "http") {
#        return 301 https://$host$request_uri;
#    }
#    if ($http_x_forwarded_proto = "http") {
#        return 301 https://$host$request_uri;
#    }

#    listen 443 ssl http2;      # for nginx versions below v1.25.1
#    listen [::]:443 ssl http2; # for nginx versions below v1.25.1 - comment to disable IPv6

    # listen 443 ssl;      # for nginx v1.25.1+
    # listen [::]:443 ssl; # for nginx v1.25.1+ - keep comment to disable IPv6
    # http2 on;            # uncomment to enable HTTP/2 - supported on nginx v1.25.1+

    # listen 443 quic reuseport;       # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+ - please remove "reuseport" if there is already another quic listener on port 443 with enabled reuseport
    # listen [::]:443 quic reuseport;  # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+ - please remove "reuseport" if there is already another quic listener on port 443 with enabled reuseport - keep comment to disable IPv6
    # http3 on;                                 # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+
    # quic_gso on;                              # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+
    # quic_retry on;                            # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+
    # quic_bpf on;                              # improves  HTTP/3 / QUIC - supported on nginx v1.25.0+, if nginx runs as a docker container you need to give it privileged permission to use this option
    # add_header Alt-Svc 'h3=":443"; ma=86400'; # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+

    proxy_buffering off;
    proxy_request_buffering off;

    client_max_body_size 0;
    client_body_buffer_size 512k;
    # http3_stream_buffer_size 512k; # uncomment to enable HTTP/3 / QUIC - supported on nginx v1.25.0+
    proxy_read_timeout 86400s;

    server_name nc;

    location / {
        proxy_pass http://127.0.0.1:11000$request_uri; # Adjust to match APACHE_PORT and APACHE_IP_BINDING. See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md#adapting-the-sample-web-server-configurations-below

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header Early-Data $ssl_early_data;

        # Websocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    # If running nginx on a subdomain (eg. nextcloud.example.com) of a domain that already has an wildcard ssl certificate from certbot on this machine,
    # the <your-nc-domain> in the below lines should be replaced with just the domain (eg. example.com), not the subdomain.
    # In this case the subdomain should already be secured without additional actions
#    ssl_certificate /etc/letsencrypt/live/<your-nc-domain>/fullchain.pem;   # managed by certbot on host machine
#    ssl_certificate_key /etc/letsencrypt/live/<your-nc-domain>/privkey.pem; # managed by certbot on host machine

#    ssl_dhparam /etc/dhparam; # curl -L https://ssl-config.mozilla.org/ffdhe2048.txt -o /etc/dhparam

#    ssl_early_data on;
#    ssl_session_timeout 1d;
#    ssl_session_cache shared:SSL:10m;

#    ssl_protocols TLSv1.2 TLSv1.3;
#    ssl_ecdh_curve x25519:x448:secp521r1:secp384r1:secp256r1;

#    ssl_prefer_server_ciphers on;
#    ssl_conf_command Options PrioritizeChaCha;
#    ssl_ciphers TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256;
}
EOF
chmod 644 /etc/nginx/conf.d/nextcloud.conf

# Create a sample index.html
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
</head>
<body>
    <h1>Welcome to Nginx</h1>
    <p>If you see this page, the nginx web server is successfully installed.</p>
</body>
</html>
EOF
chmod 755 /var/www/html
chmod 644 /var/www/html/index.html

# Create container definition using quadlet
mkdir -p /etc/containers/systemd
cat > /etc/containers/systemd/nginx.container << EOF
[Unit]
Description=Nginx Container
After=network-online.target
Requires=network-online.target

[Container]
Image=docker.io/library/nginx:stable
Network=host
Volume=/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:Z
Volume=/etc/nginx/conf.d:/etc/nginx/conf.d:Z
Volume=/etc/nginx/ssl:/etc/nginx/ssl:Z
Volume=/var/www/html:/var/www/html:ro,Z
Volume=/var/log/nginx:/var/log/nginx:Z
PublishPort=0.0.0.0::80
PublishPort=0.0.0.0::443
Label=io.containers.autoupdate=registry

[Service]
Restart=always
TimeoutStartSec=300
# Add extra time for container updates
TimeoutStopSec=70

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/containers/systemd/nginx.container

# Create README in ssl directory
cat > /etc/nginx/ssl/README << EOF
This directory is reserved for SSL certificates.
Place your certificates here with the following naming convention:
- example.com.crt (Certificate)
- example.com.key (Private Key)
EOF

# Reload systemd and enable container
systemctl daemon-reload
systemctl start nginx
