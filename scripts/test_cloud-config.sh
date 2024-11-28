#!/bin/bash

USER_NAME=user_name
SSH_KEY=sshkey
WG_PRIV_KEY=wg_priv_key
WG_PUB_KEY=wg_pub_key

cat <<EOF | lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: ""
  project: default
storage_pools:
- config:
    size: 14GiB
  description: ""
  name: default
  driver: zfs
storage_volumes: []
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
EOF

lxc init ubuntu:22.04 u1
lxc config set u1 user.user-data "$(envsubst < "server/scripts/cloud-config.yaml")"
lxc config set u1 security.nesting=true
lxc config set u1 security.privileged=true
lxc start u1
lxc exec u1 -- bash
