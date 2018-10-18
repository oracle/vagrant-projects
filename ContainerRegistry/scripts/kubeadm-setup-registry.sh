#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: June, 2018
# Author: philippe.vanhaesendonck@oracle.com
# Description: Clone latest Kubernetes containers
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

Registry="container-registry.oracle.com"
Repo="kubernetes"
YumOpts="--disablerepo ol7_developer"

# Parse arguments
while [ $# -gt 0 ]
do
  case "$1" in
    "--from")
      if [ $# -lt 2 ]
      then
	echo "$0: Missing parameter"
	exit 1
      fi
      Registry="$2"
      shift; shift
      ;;
    "--dev")
      # Developper release
      Repo="kubernetes_developer"
      YumOpts=""
      shift
      ;;
    *)
      echo "$0: Invalid parameter"
      exit 1
      ;;
  esac
done

echo "$0: Login to ${Registry}"
docker login ${Registry}
if [ $? -ne 0 ]
then
  echo "$0: Authentication failure"
  exit 1
fi

echo "$0: Installing kubeadm"
sudo yum install -y ${YumOpts} kubeadm

echo "$0: Cloning Kubernetes containers"
/bin/kubeadm-registry.sh --to localhost:5000/kubernetes --from ${Registry}/${Repo}

echo "$0: Clone complete!"
