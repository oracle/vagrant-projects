#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
#
# Since: August, 2024
# Author: ruggero.citton@oracle.com
# Description: 01_install_os_packages.sh
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
. /vagrant/config/setup.env

## get up to date
#echo "-----------------------------------------------------------------"
#echo -e "${INFO}`date +%F' '%T`: INSTALLER: System update"
#echo "-----------------------------------------------------------------"
#dnf upgrade -y


# fix locale warning
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Locale set"
echo "-----------------------------------------------------------------"
dnf reinstall -y glibc-common
echo 'LANG=en_US.utf-8' >> /etc/environment
echo 'LC_ALL=en_US.utf-8' >> /etc/environment


# Install Oracle Database preinstall and openssl packages
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Oracle preinstall, openssl, parted and expect"
echo "-----------------------------------------------------------------"
dnf install -y oracle-database-preinstall-23ai openssl parted expect


# Install Podman
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Podman setup"
echo "-----------------------------------------------------------------"
dnf config-manager --enable ol9_appstream
dnf install -y podman
dnf install -y selinux-policy-devel

dnf install -y oracle-epel-release-el9
dnf install -y podman-compose

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: disabling the firewall"
echo "-----------------------------------------------------------------"
systemctl stop firewalld
systemctl disable firewalld

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: set SELinux to permissive"
echo "-----------------------------------------------------------------"
sed -i -e "s|SELINUX=enforcing|SELINUX=permissive|g" /etc/selinux/config
setenforce permissive
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

