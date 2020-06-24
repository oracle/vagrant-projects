#!/usr/bin/env bash
#
# Provisioning script for the Container Tools module
#
# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Description: Installs the podman, buildah and skopeo Container Tools
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
echo 'Installing Container Tools module'

dnf -y module install container-tools:ol8

echo 'Container Tools are ready to use'
echo 'To get started, on your host, run:'
echo '  vagrant ssh'
echo
echo 'Then, within the guest (for example):'
echo '  podman run -it --rm oraclelinux:8-slim'
echo
