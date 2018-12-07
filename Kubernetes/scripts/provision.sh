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

# Install the yum-utils package for repo selection
yum install -y yum-utils

# Disable Preview and Developer channels
yum-config-manager --disable ol7_preview ol7_developer\* > /dev/null

Insecure=""

# Parse arguments
while [ $# -gt 0 ]
do
  case "$1" in
    "--preview")
      yum-config-manager --enable ol7_preview > /dev/null
      shift
      ;;
    "--dev")
      yum-config-manager --enable ol7_developer > /dev/null
      shift
      ;;
    "--insecure")
      if [ $# -lt 2 ]
      then
        echo "Missing parameter"
	exit 1
      fi
      Insecure="$2"
      shift; shift
      ;;
    *)
      echo "Invalid parameter"
      exit 1
      ;;
  esac
done

echo "Installing and configuring Docker Engine"

# Install Docker
yum install -y docker-engine btrfs-progs

# Create and mount a BTRFS partition for docker.
docker-storage-config -f -s btrfs -d /dev/sdb

# Kubernetes: Docker should not touch iptables -- See Orabug 26641724/26641807
# Alternatively you could use firewalld as described in the Kubernetes User's Guide
# On the ol74 box, firewalld is installed but disabled by default.
sed -i "s/^OPTIONS='\(.*\)'/OPTIONS='\1 --iptables=false'/" /etc/sysconfig/docker

# Configure insecure (non-ssl) registry if needed
if [ -n "${Insecure}" ]
then
  sed -i "s/\"$/\",\n    \"insecure-registries\": [\"${Insecure}\"]/" /etc/docker/daemon.json
fi

# Add vagrant user to docker group
usermod -a -G docker vagrant

# Enable and start Docker
systemctl enable docker
systemctl start docker

echo "Installing and configuring Kubernetes packages"

# Install Kubernetes packages from the "preview" channel fulfil pre-requisites
yum install -y  kubeadm kubelet kubectl
# Set SeLinux to Permissive
/usr/sbin/setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
# Bridge filtering
modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
sysctl -p /etc/sysctl.d/k8s.conf
# Ensure kubelet uses the right IP address
IP=$(ip addr | awk -F'[ /]+' '/192.168.99.255/ {print $3}')
KubeletNode="/etc/systemd/system/kubelet.service.d/90-node-ip.conf"
ExecStart=$(grep ExecStart=/ /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | sed -e 's/\$KUBELET_EXTRA_ARGS/\$KUBELET_EXTRA_ARGS \$KUBELET_NODE_IP_ARGS/')
cat <<-EOF >${KubeletNode}
	[Service]
	Environment="KUBELET_NODE_IP_ARGS=--node-ip=${IP}"
	ExecStart=
	${ExecStart}
EOF
chmod 644 ${KubeletNode}
systemctl daemon-reload

echo "Your Kubernetes VM is ready to use!"
