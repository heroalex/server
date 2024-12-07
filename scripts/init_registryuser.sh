#!/bin/bash

cp -r /root/server/$1 /home/
chown -R $1:$1 /home/$1
chmod +x /home/$1/init_registry.sh

loginctl enable-linger $1
usermod --add-subuids 200000-265535 $1
usermod --add-subgids 200000-265535 $1

su -c /home/$1/init_registry.sh $1
