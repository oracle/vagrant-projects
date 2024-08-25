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

# Abort on any error
set -e

echo 'INSTALLER: Started up'

# verify that database installer is present and valid
echo 'INSTALLER: Verifying database installer file'

sha256sum --check /vagrant/db_installer.sha256 || {
  cat << EOF

INSTALLER: Database installer file missing or invalid.
           Destroy this VM (vagrant destroy), then
           make sure that the database installer file
           is in the same directory as the Vagrantfile,
           and that its SHA-256 digest matches the
           value in the db_installer.sha256 file,
           before running vagrant up again.

EOF
  exit 1
}

# get up to date
yum upgrade -y

echo 'INSTALLER: System updated'

yum install -y bc oracle-database-server-12cR2-preinstall openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

# fix locale warning
yum reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

# set system time zone
sudo timedatectl set-timezone $SYSTEM_TIMEZONE
echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

echo 'INSTALLER: Oracle directories created'

# install Oracle
unzip /vagrant/oracle-xe-11.2.0-1.0.x86_64.rpm.zip -d /tmp
sudo rpm -i /tmp/Disk1/oracle-xe-11.2.0-1.0.x86_64.rpm
chmod -R u+w /tmp/Disk1
rm -rf /tmp/Disk1
sudo ln -s /u01/app/oracle /opt/oracle

echo 'INSTALLER: Oracle software installed'

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -hex 8`"}

cp /vagrant/ora-response/xe.rsp.tmpl /tmp/xe.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /tmp/xe.rsp
sed -i -e "s|###LISTENER_PORT###|$LISTENER_PORT|g" /tmp/xe.rsp
sudo /etc/init.d/oracle-xe configure responseFile=/tmp/xe.rsp
rm /tmp/xe.rsp

echo 'INSTALLER: Database created'

# set environment variables
echo "export ORACLE_BASE=/u01/app/oracle" >> /home/oracle/.bashrc
echo "export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe" >> /home/oracle/.bashrc
echo "export ORACLE_SID=XE" >> /home/oracle/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

sudo cp /vagrant/scripts/setPassword.sh /home/oracle/
sudo chmod a+rx /home/oracle/setPassword.sh

echo "INSTALLER: setPassword.sh file setup";

# run user-defined post-setup scripts
echo 'INSTALLER: Running user-defined post-setup scripts'

for f in /vagrant/userscripts/*
  do
    case "${f,,}" in
      *.sh)
        echo "INSTALLER: Running $f"
        . "$f"
        echo "INSTALLER: Done running $f"
        ;;
      *.sql)
        echo "INSTALLER: Running $f"
        su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
        echo "INSTALLER: Done running $f"
        ;;
      /vagrant/userscripts/put_custom_scripts_here.txt)
        :
        ;;
      *)
        echo "INSTALLER: Ignoring $f"
        ;;
    esac
  done

echo 'INSTALLER: Done running user-defined post-setup scripts'

echo "ORACLE PASSWORD FOR SYS AND SYSTEM: $ORACLE_PWD";

echo "INSTALLER: Installation complete, database ready to use!";
