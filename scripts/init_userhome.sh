#!/bin/bash

git clone https://github.com/heroalex/server.git

find server/userhome/. -type f -name '*' -exec bash -c 'cp "$0" /home/${USER_NAME}/ && chown ${USER_NAME}:${USER_NAME} "/home/${USER_NAME}/$(basename "$0")";' {} \;
