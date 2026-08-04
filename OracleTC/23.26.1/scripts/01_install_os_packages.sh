#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 01_install_os_packages.sh
#   Installs base packages and the Oracle preinstall bundle that matches the
#   23.26.1 installer (the '26ai' preinstall package line on OL9).
#
#   If only the older oracle-database-preinstall-23ai package is available in
#   the configured repos we fall back to it, so this script runs cleanly on
#   environments that have not yet received the 26ai package.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

log_section "Installing base packages"
dnf install -y dnf-utils expect openssl parted tree unzip zip

log_section "Installing Oracle preinstall bundle"
if dnf -q list --available oracle-ai-database-preinstall-26ai >/dev/null 2>&1; then
  dnf install -y oracle-ai-database-preinstall-26ai
elif dnf -q list --available oracle-database-preinstall-23ai   >/dev/null 2>&1; then
  log_info "26ai preinstall not available; falling back to oracle-database-preinstall-23ai"
  dnf install -y oracle-database-preinstall-23ai
else
  log_error "no compatible Oracle preinstall package found (oracle-ai-database-preinstall-26ai or oracle-database-preinstall-23ai)"
  exit 1
fi

log_section "Setting SELinux to permissive"
sed -i -e 's|SELINUX=enforcing|SELINUX=permissive|g' /etc/selinux/config
setenforce permissive || true

log_section "Disabling firewalld"
systemctl stop    firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
