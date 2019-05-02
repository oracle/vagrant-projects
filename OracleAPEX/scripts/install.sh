#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright © 1982-2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    NAME
#      install.sh
#
#    DESCRIPTION
#      Execute Oracle Linux 7 update and configuration
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Simon Coter
#
#    MODIFIED   (MM/DD/YY)
#    scoter     03/19/19 - Creation
#

echo 'INSTALLER: Started up'

# get up to date
yum update -y

# run OL Yum configuration
/usr/bin/ol_yum_configure.sh

echo 'INSTALLER: System updated'

# fix locale warning
yum reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

# Install Oracle Database prereq and openssl packages
# (preinstall is pulled automatically with 18c XE rpm, but it
#  doesn't create /home/oracle unless it's installed separately)
yum install -y oracle-database-preinstall-18c openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'
