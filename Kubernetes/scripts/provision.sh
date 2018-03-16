#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2018
# Author: philippe.vanhaesendonck@oracle.com
# Description: Installs Docker Engine, Kubernetes packages and satisfy
#              pre-requisites
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

echo "Installing and configuring Docker Engine"

# Install Docker
yum install -y docker-engine btrfs-progs

# Create and mount a BTRFS partition for docker.
docker-storage-config -f -s btrfs -d /dev/sdb

# Kubernetes: Docker should not touch iptables -- See Orabug 26641724/26641807
# Alternatively you could use firewalld as described in the Kubernetes User's Guide
# On the ol74 box, firewalld is installed but disabled by default.
sed -i "s/^OPTIONS='\(.*\)'/OPTIONS='\1 --iptables=false'/" /etc/sysconfig/docker

# Add vagrant user to docker group
usermod -a -G docker vagrant

# Enable and start Docker
systemctl enable docker
systemctl start docker

echo "Installing and configuring Kubernetes packages"

# Install Kubernetes packages from the "preview" channel fulfil pre-requisites
yum --enablerepo ol7_preview install -y  kubeadm
# Set SeLinux to Permissive
/usr/sbin/setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
# Bridge filtering
modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
sysctl -p /etc/sysctl.d/k8s.conf

echo "Your Kubernetes VM is ready to use!"
