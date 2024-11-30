#!/bin/bash

podman login docker.io
systemctl --user daemon-reload
systemctl --user start nginx
