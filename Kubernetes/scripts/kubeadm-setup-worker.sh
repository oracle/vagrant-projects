#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: July, 2017
# Author: philippe.vanhaesendonck@oracle.com
# Description: Runs kubeadm-setup on worker nodes
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

TokenFile="/vagrant/token"

if [ ${EUID} -ne 0 ]
then
  echo "$0: This script must be run as root"
  exit 1
fi

if [ ! -f "${TokenFile}" ]
then
  echo "$0: Token not found. Is the master already configured?"
  exit 1
fi
Token=$(cat "${TokenFile}")

echo "$0: Login to container registry"
docker login container-registry.oracle.com
if [ $? -ne 0 ]
then
  echo "$0: Authentication failure"
  exit 1
fi

echo "$0: Setup Worker node"
kubeadm-setup.sh join --token ${Token} 192.168.99.100:6443

echo "$0: Worker node ready"
