#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright © 1982-2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    NAME
#      database.sh
#
#    DESCRIPTION
#      Install and Configure Oracle Database XE 18.4
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

# remove fake entry to hostname pointing to 127.0.0.1
sed -i -e "/$HOSTNAME/d" /etc/hosts
echo "10.0.2.15 $HOSTNAME" >> /etc/hosts

# set environment variables
echo "export ORACLE_BASE=/opt/oracle" >> /home/oracle/.bashrc && \
echo "export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE" >> /home/oracle/.bashrc && \
echo "export ORACLE_SID=XE" >> /home/oracle/.bashrc && \
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

timedatectl set-timezone "$SYSTEM_TIMEZONE"
echo 'INSTALLER: Timezone updated'

echo 'INSTALLER: Environment variables set'

echo 'INSTALLER: Oracle Database Installation Started up'

# Install Oracle
yum -y localinstall /vagrant/oracle-database-xe-18c-*.x86_64.rpm

echo 'INSTALLER: Oracle software installed'

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}

# Create database
mv /etc/sysconfig/oracle-xe-18c.conf /etc/sysconfig/oracle-xe-18c.conf.original && \
cp /vagrant/ora-response/oracle-xe-18c.conf.tmpl /etc/sysconfig/oracle-xe-18c.conf && \
chmod g+w /etc/sysconfig/oracle-xe-18c.conf && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /etc/sysconfig/oracle-xe-18c.conf && \
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /etc/sysconfig/oracle-xe-18c.conf

# required for database creation
. /home/oracle/.bashrc
su - oracle -c "mkdir -p $ORACLE_BASE/admin"

# start listener and datbase configuration
/etc/init.d/oracle-xe-18c configure

echo 'INSTALLER: Database created'

# add tns entry for XEPDB1
chmod o+r /opt/oracle/product/18c/dbhomeXE/network/admin/tnsnames.ora

# add tnsnames.ora entry for PDB
echo 'XEPDB1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-18c-apex)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = XEPDB1)
    )
  )
' >> /opt/oracle/product/18c/dbhomeXE/network/admin/tnsnames.ora

echo 'INSTALLER: TNS entry added'

#clean up temporary entry in /etc/hosts
sed -i -e "s/10.0.2.15/127.0.0.1/" /etc/hosts

# configure systemd to start oracle instance on startup
systemctl daemon-reload
systemctl enable oracle-xe-18c
systemctl restart oracle-xe-18c
echo "INSTALLER: Created and enabled oracle-xe-18c systemd's service"

# enable global port for EM Express
su -l oracle -c 'sqlplus / as sysdba <<EOF
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   exit
EOF'

echo 'INSTALLER: Global EM Express port enabled'

echo $ORACLE_PWD > /vagrant/apex-pwd

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

echo "INSTALLER: Installation complete, database ready to use!";
