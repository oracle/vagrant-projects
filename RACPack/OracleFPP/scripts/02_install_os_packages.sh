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
#      DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#      ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     10/01/19 - Creation
#
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Install base packages"
echo "-----------------------------------------------------------------"
yum install -y deltarpm expect tree unzip zip 
yum install -y oracle-database-preinstall-18c
yum install -y oracleasm-support

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Add extra OS packages"
echo "-----------------------------------------------------------------"
yum install -y bc
yum install -y binutils
yum install -y compat-libcap1
yum install -y compat-libstdc++-33
yum install -y compat-libstdc++-33.i686
yum install -y fontconfig-devel
yum install -y glibc.i686
yum install -y glibc
yum install -y glibc-devel.i686
yum install -y glibc-devel
yum install -y ksh
yum install -y libaio.i686
yum install -y libaio
yum install -y libaio-devel.i686
yum install -y libaio-devel
yum install -y libX11.i686
yum install -y libX11
yum install -y libXau.i686
yum install -y libXau
yum install -y libXi.i686
yum install -y libXi
yum install -y libXtst.i686
yum install -y libXtst
yum install -y libgcc.i686
yum install -y libgcc
yum install -y librdmacm-devel
yum install -y libstdc++.i686
yum install -y libstdc++
yum install -y libstdc++-devel.i686
yum install -y libstdc++-devel
yum install -y libxcb.i686
yum install -y libxcb
yum install -y make
yum install -y nfs-utils
yum install -y net-tools
yum install -y python
yum install -y python-configshell
yum install -y python-rtslib
yum install -y python-six
yum install -y smartmontools
yum install -y sysstat
yum install -y targetcli
yum install -y unixODBC
yum install -y chrony

#echo "-----------------------------------------------------------------"
#echo -e "${INFO}`date +%F' '%T`: Perform yum update"
#echo "-----------------------------------------------------------------"
#yum -y update

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Disabling firewalld"
echo "-----------------------------------------------------------------"
systemctl stop  firewalld
systemctl disable  firewalld
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

