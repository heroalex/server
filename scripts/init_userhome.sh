#!/bin/bash

find /root/server/userhome -type f -exec bash -c 'echo "Processing: $0"; cp "$0" "/home/$1/" && chown "$1:$1" "/home/$1/$(basename "$0")";' {} "$1" \;

loginctl enable-linger $1
usermod --add-subuids 100000-165535 $1
usermod --add-subgids 100000-165535 $1
