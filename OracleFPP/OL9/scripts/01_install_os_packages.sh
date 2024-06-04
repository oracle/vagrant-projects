#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      02_install_os_packages.sh
#
#    DESCRIPTION
#      Install and update OS packages
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Ruggero Citton - RAC Pack, Cloud Innovation and Solution Engineering Team
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/03/23 - OL8 support
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     11/06/18 - Creation
#
#    REVISION
#    20240603 - $Revision: 2.0.2.2 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
. /vagrant/config/setup.env
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Install base packages"
echo "-----------------------------------------------------------------"
dnf config-manager --enable ol9_addons
dnf install -y dnf-utils expect openssl parted tree unzip zip
dnf install -y oracle-database-preinstall-23ai

if [ "${ASM_LIB_TYPE}" == "ASMLIB" ]
then
  dnf install -y oracleasm-support
fi

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Add extra OS packages"
echo "-----------------------------------------------------------------"
dnf install -y bc
dnf install -y binutils
dnf install -y compat-openssl11
dnf install -y elfutils-libelf
dnf install -y glibc
dnf install -y glibc-devel
dnf install -y ksh
dnf install -y libaio
dnf install -y libXrender
dnf install -y libX11
dnf install -y libXau
dnf install -y libXi
dnf install -y libXtst
dnf install -y libgcc
dnf install -y libnsl
dnf install -y libstdc++
dnf install -y libxcb
dnf install -y libibverbs
dnf install -y make
dnf install -y policycoreutils
dnf install -y policycoreutils-python-utils
dnf install -y unixODBC
dnf install -y smartmontools
dnf install -y sysstat
dnf install -y chrony

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

#echo "-----------------------------------------------------------------"
#echo -e "${INFO}`date +%F' '%T`: Perform yum update"
#echo "-----------------------------------------------------------------"
#yum -y update

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

