#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 2018, 2020 Oracle and/or its affiliates.
#
# Since: February, 2018
# Author: sergio.leunissen@oracle.com
# Description: Installs Docker engine using Btrfs as storage
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
echo 'Installing and configuring Docker engine'

# install Docker engine
yum -y install docker-engine

# Format spare device as Btrfs
# Configure Btrfs storage driver

docker-storage-config -s btrfs -d /dev/[sv]db

# Start and enable Docker engine
systemctl start docker
systemctl enable docker

# Add vagrant user to docker group
usermod -a -G docker vagrant

# Relax /etc/docker permissions
chmod 0770 /etc/docker

echo 'Docker engine is ready to use'
echo 'To get started, on your host, run:'
echo '  vagrant ssh'
echo
echo 'Then, within the guest (for example):'
echo '  docker run -it oraclelinux:6-slim'
echo
