#!/bin/bash

find /root/server/userhome -type f -exec bash -c 'echo "Processing: $0"; cp "$0" "/home/$1/" && chown "$1:$1" "/home/$1/$(basename "$0")";' {} "$1" \;
