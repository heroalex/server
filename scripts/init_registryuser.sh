#!/bin/bash

cp -r /root/server/$1 /home/
chown -R $1:$1 /home/$1
chmod +x /home/$1/init_registry.sh

loginctl enable-linger $1
usermod --add-subuids 200000-265535 $1
usermod --add-subgids 200000-265535 $1

mkdir -p /home/$1/storage
chown -R $1:$1 /home/$1

systemctl daemon-reload
systemctl enable home-$1-storage.mount
systemctl start home-$1-storage.mount

su -c /home/$1/init_registry.sh $1
