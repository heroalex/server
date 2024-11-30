#!/bin/bash


cp -r /root/server/$1/* /home/$1/
chown -R $1:$1 /home/$1/
chmod +x /home/$1/init_nginx.sh
