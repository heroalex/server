#!/bin/bash

find /root/server/userhome/. -type f -name '*' -exec bash -c 'cp "$0" /home/$1/ && chown $1:$1 "/home/$1/$(basename "$0")";' {} \;
