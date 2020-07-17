#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 2018, 2020 Oracle and/or its affiliates.
#
# Since: February, 2018
# Author: sergio.leunissen@oracle.com
# Description: Installs Oracle Container Runtime for Docker using Btrfs as storage
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
echo 'Installing and configuring Oracle Container Runtime for Docker'

# install Oracle Container Runtime for Docker
yum -y install docker-engine

if [[ -b /dev/sdb || -b /dev/vdb ]]; then
    # Format spare device as Btrfs
    # Configure Btrfs storage driver
    docker-storage-config -s btrfs -d /dev/[sv]db
else
    # No spare disk, configure the appropriate driver
    fstype=$(stat -f -c %T /var/lib/docker 2>/dev/null || stat -f -c %T /var/lib)
    storage_driver=""
    case "${fstype}" in
        btrfs)
            storage_driver="btrfs"
            ;;
        xfs)
            storage_driver="overlay2"
            ;;
    esac
    if [[ -n ${storage_driver} ]]; then
        [ ! -d /etc/docker ] && mkdir -m 0700 /etc/docker && chown root:root /etc/docker
        cat > /etc/docker/daemon.json <<-EOF
			{
			    "storage-driver": "${storage_driver}"
			}
			EOF
    fi
fi

# Start and enable the container runtime
systemctl start docker
systemctl enable docker

# Add vagrant user to docker group
usermod -a -G docker vagrant

# Relax /etc/docker permissions
chmod 0770 /etc/docker

echo 'Oracle Container Runtime for Docker is ready to use'
echo 'To get started, on your host, run:'
echo '  vagrant ssh'
echo
echo 'Then, within the guest (for example):'
echo '  docker run -it --rm oraclelinux:8-slim'
echo
