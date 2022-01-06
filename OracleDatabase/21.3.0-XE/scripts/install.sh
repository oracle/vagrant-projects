#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2018
# Author: gerald.venzl@oracle.com
# Description: Installs Oracle database software
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Abort on any error
set -Eeuo pipefail

echo 'INSTALLER: Started up'

# get up to date
dnf upgrade -y

echo 'INSTALLER: System updated'

# fix locale warning
dnf reinstall -y glibc-common
echo 'LANG=en_US.utf-8' >> /etc/environment
echo 'LC_ALL=en_US.utf-8' >> /etc/environment

echo 'INSTALLER: Locale set'

# set system time zone
timedatectl set-timezone "$SYSTEM_TIMEZONE"
echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

# Install Oracle Database prereq and openssl packages
# (preinstall is pulled automatically with 21c XE rpm, but it
#  doesn't create /home/oracle unless it's installed separately)
dnf install -y oracle-database-preinstall-21c openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

# set environment variables
cat >> /home/oracle/.bashrc << EOF
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export ORACLE_SID=XE
export PATH=\$PATH:\$ORACLE_HOME/bin
EOF

echo 'INSTALLER: Environment variables set'

# Install Oracle
# if installer doesn't exist, download it
db_installer='oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm'
if [[ ! -f /vagrant/"${db_installer}" ]]; then
  echo 'INSTALLER: Downloading Oracle Database software'
  (
    cd /vagrant || exit 1
    curl -LOs https://download.oracle.com/otn-pub/otn_software/db-express/"${db_installer}"
  )
fi

dnf -y localinstall /vagrant/"${db_installer}"

if [[ "${KEEP_DB_INSTALLER,,}" == 'false' ]]; then
  rm -f /vagrant/"${db_installer}"
fi

echo 'INSTALLER: Oracle software installed'

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"$(openssl rand -base64 8)1"}

# Create database
mv /etc/sysconfig/oracle-xe-21c.conf /etc/sysconfig/oracle-xe-21c.conf.original
cp /vagrant/ora-response/oracle-xe-21c.conf.tmpl /etc/sysconfig/oracle-xe-21c.conf
chmod g+w /etc/sysconfig/oracle-xe-21c.conf

sed -i -e "s|###LISTENER_PORT###|$LISTENER_PORT|g" /etc/sysconfig/oracle-xe-21c.conf
sed -i -e "s|###EM_EXPRESS_PORT###|$EM_EXPRESS_PORT|g" /etc/sysconfig/oracle-xe-21c.conf
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /etc/sysconfig/oracle-xe-21c.conf
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /etc/sysconfig/oracle-xe-21c.conf
/etc/init.d/oracle-xe-21c configure

chmod o+r /opt/oracle/homes/OraDBHome21cXE/network/admin/tnsnames.ora

# add tnsnames.ora entry for PDB
cat >> /opt/oracle/homes/OraDBHome21cXE/network/admin/tnsnames.ora << EOF
XEPDB1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = $LISTENER_PORT))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = XEPDB1)
    )
  )
EOF

echo 'INSTALLER: Database created'

# enable global port for EM Express
su -l oracle -c 'sqlplus / as sysdba << EOF
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   exit
EOF'

echo 'INSTALLER: Global EM Express port enabled'

# configure systemd to start oracle instance on startup
systemctl daemon-reload
systemctl enable oracle-xe-21c
systemctl start oracle-xe-21c
echo "INSTALLER: Created and enabled oracle-xe-21c systemd's service"

cp /vagrant/scripts/setPassword.sh /home/oracle/
chown oracle:oinstall /home/oracle/setPassword.sh
chmod u=rwx,go=r /home/oracle/setPassword.sh

echo 'INSTALLER: setPassword.sh file setup'

# run user-defined post-setup scripts
echo 'INSTALLER: Running user-defined post-setup scripts'

for f in /vagrant/userscripts/*
  do
    case "${f,,}" in
      *.sh)
        echo "INSTALLER: Running $f"
        # shellcheck disable=SC1090
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

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD"

echo 'INSTALLER: Installation complete, database ready to use!'
