#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: January, 2018
# Author: gerald.venzl@oracle.com
# Description: Installs Oracle database software
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

echo 'INSTALLER: Started up'

# get up to date
yum upgrade -y

echo 'INSTALLER: System updated'

yum install -y bc oracle-database-server-12cR2-preinstall

# fix locale warning
yum reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

echo 'INSTALLER: Oracle directories created'

# install Oracle
unzip /vagrant/oracle-xe-11.2.0-1.0.x86_64.rpm.zip -d /vagrant
sudo rpm -i /vagrant/Disk1/oracle-xe-11.2.0-1.0.x86_64.rpm
rm -rf /vagrant/Disk1

echo 'INSTALLER: Oracle software installed'

sudo /etc/init.d/oracle-xe configure responseFile=/vagrant/ora-response/xe.rsp

echo 'INSTALLER: Database created'

# set environment variables
echo "export ORACLE_BASE=/u01/app/oracle" >> /home/oracle/.bashrc && \
echo "export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe" >> /home/oracle/.bashrc && \
echo "export ORACLE_SID=XE" >> /home/oracle/.bashrc   && \
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

echo 'INSTALLER: Installation complete, database ready to use!'
