#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/01_install_os_packages.sh,v 2.0.1.1 2018/12/10 11:15:27 rcitton Exp $
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
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
#       ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#
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

