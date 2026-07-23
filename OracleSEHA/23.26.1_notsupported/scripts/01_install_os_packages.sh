#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 01_install_os_packages.sh
#   Installs base packages and the Oracle preinstall bundle for SEHA 23ai on OL9.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

log_section "Installing base packages"
base_packages=(
  expect
  lvm2
  openssl
  parted
  tree
  unzip
  xfsprogs
  zip
)

yum install -y "${base_packages[@]}"

log_section "Installing oracle-database-preinstall-23ai"
yum install -y oracle-database-preinstall-23ai

log_section "Installing Grid Infrastructure prerequisites"
yum install -y bc ksh libaio libaio-devel net-tools nfs-utils \
               policycoreutils-python-utils sysstat smartmontools chrony \
               dnsmasq bind-utils

log_section "Disabling firewalld"
systemctl stop    firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
