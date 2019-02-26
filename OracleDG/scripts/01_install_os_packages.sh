#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/01_install_os_packages.sh,v 2.0.1.1 2018/11/18 23:12:35 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      02_install_os_packages.sh
#
#    DESCRIPTION
#      Install and update OS packages
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Ruggero Citton
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup yum"
echo "-----------------------------------------------------------------"
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
cd /etc/yum.repos.d
rm -f public-yum-ol7.repo
wget --quiet https://yum.oracle.com/public-yum-ol7.repo

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Install base packages"
echo "-----------------------------------------------------------------"
yum install -y deltarpm tree unzip zip 
yum install -y oracle-database-preinstall-18c

#echo "-----------------------------------------------------------------"
#echo -e "${INFO}`date +%F' '%T`: Perform yum update"
#echo "-----------------------------------------------------------------"
#yum -y update

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------

