#!/bin/bash

find /root/server/$1 -type f -exec bash -c 'echo "Processing: $0"; cp "$0" "/home/$1/" && chown "$1:$1" "/home/$1/$(basename "$0")";' {} "$1" \;
chmod +x /home/$1/init_nginx.sh
