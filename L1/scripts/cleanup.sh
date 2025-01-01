#!/usr/bin/env bash

set -eux

clean_cloud_init() {
  cloud-init clean --logs --machine-id --seed

  rm -rf /run/cloud-init/*
  rm -rf /var/lib/cloud/*
}

clean_ssh_keys() {
  rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
}

clean_logs() {
  journalctl --flush
  journalctl --rotate --vacuum-time=0

  find /var/log -type f -exec truncate --size 0 {} \; # truncate system logs
  find /var/log -type f -name '*.[1-9]' -delete # remove archived logs
  find /var/log -type f -name '*.gz' -delete # remove compressed archived logs
}

clean_cloud_init
#clean_ssh_keys
clean_logs
