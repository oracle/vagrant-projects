#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: March, 2018
# Author: philippe.vanhaesendonck@oracle.com
# Description: Runs kubeadm-setup on the master node and save the token for
#              the worker nodes
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

JoinCommand="/vagrant/join-command.sh"
LogFile="kubeadm-setup.log"
Registry="${KUBE_REPO_PREFIX:-container-registry.oracle.com}"
Registry="${Registry%%/*}"
NoLogin=""

# Parse arguments
while [ $# -gt 0 ]
do
  case "$1" in
    "--no-login")
      NoLogin=1
      shift
      ;;
    *)
      echo "Invalid parameter"
      exit 1
      ;;
  esac
done

if [ ${EUID} -ne 0 ]
then
  echo "$0: This script must be run as root"
  exit 1
fi

if [ "$0" = "${SUDO_COMMAND%% *}" ]
then
  echo "$0: This script should not be called directly with 'sudo'"
  exit 1
fi

if [ -z "${NoLogin}" ]
then
  echo "$0: Login to ${Registry}"
  docker login ${Registry}
  if [ $? -ne 0 ]
  then
    echo "$0: Authentication failure"
    exit 1
  fi
fi

echo "$0: Setup Master node -- be patient!"
kubeadm-setup.sh up > "${LogFile}" 2>&1

if [ $? -ne 0 ]
then
  echo "$0: kubeadm-setup.sh did not complete successfully"
  echo "Last lines of ${LogFile}:"
  tail -10 "${LogFile}"
  exit 1
fi

echo "$0: Copying admin.conf for vagrant user"
mkdir -p ~vagrant/.kube
cp /etc/kubernetes/admin.conf ~vagrant/.kube/config
chown vagrant: ~vagrant/.kube/config

echo "$0: Copying admin.conf into host directory"
sed -e 's/192.168.99.100/127.0.0.1/' </etc/kubernetes/admin.conf >/vagrant/admin.conf

echo "$0: Saving token for worker nodes"
# 'token list' doesn't provide token hash, we have re-issue a new token to
# capture the hash -- See https://github.com/kubernetes/kubeadm/issues/519
kubeadm token create --print-join-command |
  sed -e 's/kubeadm/kubeadm-setup.sh/' > "${JoinCommand}"

echo "$0: Master node ready, run"
echo -e "\t/vagrant/scripts/kubeadm-setup-worker.sh"
echo "on the worker nodes"
