#!/bin/bash

USER_NAME=user_name
SSH_KEY=sshkey
WG_PRIV_KEY=wg_priv_key
WG_PUB_KEY=wg_pub_key

cloud_config=$(envsubst < "server/scripts/cloud-config.yaml")

lxd init --minimal
lxc init ubuntu:22.04 u1
lxc config set u1 user.user-data - < $cloud_config
lxc start u1
lxc exec u1 -- bash
