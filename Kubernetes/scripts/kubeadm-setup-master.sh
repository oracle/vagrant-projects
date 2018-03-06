#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: July, 2017
# Author: philippe.vanhaesendonck@oracle.com
# Description: Runs kubeadm-setup on the master node and save the token for
#              the worker nodes
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

TokenFile="/vagrant/token"

if [ ${EUID} -ne 0 ]
then
  echo "$0: This script must be run as root"
  exit 1
fi

echo "$0: Login to container registry"
docker login container-registry.oracle.com
if [ $? -ne 0 ]
then
  echo "$0: Authentication failure"
  exit 1
fi

echo "$0: Setup Master node"
kubeadm-setup.sh up

echo "$0: Copying admin.conf for vagrant user"
mkdir -p ~vagrant/.kube
cp /etc/kubernetes/admin.conf ~vagrant/.kube/config
chown vagrant: ~vagrant/.kube/config

echo "$0: Copying admin.conf into host directory"
sed -e 's/192.168.99.100/127.0.0.1/' </etc/kubernetes/admin.conf >/vagrant/admin.conf

echo "$0: Saving token for worker nodes"
kubeadm token list | grep default | cut -d ' ' -f 1 > "${TokenFile}"

echo "$0: Master node ready, run"
echo -e "\t/vagrant/scripts/kubeadm-setup-worker.sh"
echo "on the worker nodes"
