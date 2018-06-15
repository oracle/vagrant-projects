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

# fix locale warning
yum reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

# Install Oracle Database prereq and openssl packages
yum install -y oracle-database-server-12cR2-preinstall openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

# Create Directories
mkdir /u01/ogg-installer && \
mkdir /u01/oggbd && \
mkdir /u01/ogg && \
mkdir /vagrant/oggbd && \
chown -R oracle:oinstall /u01/oggbd && \
chown -R oracle:oinstall /u01/ogg

# create directories
mkdir $ORACLE_BASE && \
chown oracle:oinstall -R $ORACLE_BASE && \
mkdir /u01/app && \
ln -s $ORACLE_BASE /u01/app/oracle

echo 'INSTALLER: Oracle directories created'

# set environment variables
echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc && \
echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc && \
echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc   && \
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

# Install Oracle

unzip /vagrant/linux*122*.zip -d /vagrant
cp /vagrant/ora-response/db_install.rsp.tmpl /vagrant/ora-response/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/ora-response/db_install.rsp && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /vagrant/ora-response/db_install.rsp && \
sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /vagrant/ora-response/db_install.rsp
su -l oracle -c "/vagrant/database/runInstaller -silent -showProgress -ignorePrereq -waitforcompletion -responseFile /vagrant/ora-response/db_install.rsp"
$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh
rm -rf /vagrant/database
rm /vagrant/ora-response/db_install.rsp

echo 'INSTALLER: Oracle software installed'

# create sqlnet.ora, listener.ora and tnsnames.ora
su -l oracle -c "mkdir -p $ORACLE_HOME/network/admin"
su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $ORACLE_HOME/network/admin/sqlnet.ora"

# Listener.ora
su -l oracle -c "echo 'LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
' > $ORACLE_HOME/network/admin/listener.ora"

su -l oracle -c "echo '$ORACLE_SID=localhost:1521/$ORACLE_SID' > $ORACLE_HOME/network/admin/tnsnames.ora"
su -l oracle -c "echo '$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)' >> $ORACLE_HOME/network/admin/tnsnames.ora"

# Start LISTENER
su -l oracle -c "lsnrctl start"

echo 'INSTALLER: Listener created'

echo 'INSTALLER: Started GG installation'

# Install Java 8
echo 'INSTALLER: Install Java 8'
yum install -y java-$JAVA_VERSION-openjdk

# Install Confluent
echo 'INSTALLER: Install Confluent'
rpm --import https://packages.confluent.io/rpm/4.1/archive.key && \
sudo cp /vagrant/yum/confluent.repo /etc/yum.repos.d/ && \
yum install -y confluent-platform-oss-$CONFLUENT_VERSION && \
sudo cp /vagrant/scripts/confluent.service /etc/systemd/system/
sed -i -e 's|^#advertised\.listeners=*.*$|advertised.listeners=PLAINTEXT://'$MACHINE_IP':9092|g' /etc/kafka/server.properties
sudo systemctl enable confluent && \
sudo systemctl start confluent

echo 'INSTALLER: Confluent Installed and Started'



# Create database

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}

cp /vagrant/ora-response/dbca.rsp.tmpl /vagrant/ora-response/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /vagrant/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /vagrant/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /vagrant/ora-response/dbca.rsp && \
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /vagrant/ora-response/dbca.rsp
su -l oracle -c "dbca -silent -createDatabase -responseFile /vagrant/ora-response/dbca.rsp"
su -l oracle -c "sqlplus / as sysdba <<EOF
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   exit;
EOF"
rm /vagrant/ora-response/dbca.rsp

echo 'INSTALLER: Database created'

echo 'INSTALLER: Enabling Database-level Supplemental Logging'
su -l oracle -c "sqlplus / as sysdba <<EOF
    ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
    ALTER DATABASE FORCE LOGGING;
    SHUTDOWN IMMEDIATE
    STARTUP MOUNT
    ALTER DATABASE ARCHIVELOG;
    ALTER DATABASE OPEN;
    ALTER SYSTEM SWITCH LOGFILE;
    ALTER SYSTEM SET ENABLE_GOLDENGATE_REPLICATION=TRUE SCOPE=BOTH;
    exit;
EOF"

sed '$s/N/Y/' /etc/oratab | sudo tee /etc/oratab > /dev/null
echo 'INSTALLER: Oratab configured'

# configure systemd to start oracle instance on startup
sudo cp /vagrant/scripts/oracle-rdbms.service /etc/systemd/system/ && \
sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service && \
sudo systemctl daemon-reload && \
sudo systemctl enable oracle-rdbms && \
sudo systemctl start oracle-rdbms && \
echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

# Install Golden Gate For Big Data
echo 'Installer: Install GG for Big Data'
unzip /vagrant/*Adapters_Linux*.zip -d /vagrant/oggbd && \
sudo tar -xvf /vagrant/oggbd/*Adapters_Linux*.tar -C /u01/oggbd/ && \
rm -rf /vagrant/oggbd && \
chown -R oracle:oinstall /u01/oggbd/
echo 'INSTALLER: Oracle GG For Big Data Installed.'

# Install Golden Gate For Oracle
sudo unzip /vagrant/*ggs_Linux*.zip -d /u01/ogg-installer
cp /vagrant/ora-response/ogg_install.rsp.tmpl /vagrant/ora-response/oggresponse.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /vagrant/ora-response/oggresponse.rsp && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /vagrant/ora-response/oggresponse.rsp && \
su -l oracle -c "/u01/ogg-installer/fbo_ggs_Linux_x64_shiphome/Disk1/runInstaller -silent -waitforcompletion -responseFile /vagrant/ora-response/oggresponse.rsp" && \
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib" >> /home/oracle/.bashrc && \
rm -rf /u01/ogg-installer && \
rm /vagrant/ora-response/oggresponse.rsp && \
chown -R oracle:oinstall /u01/ogg

echo 'INSTALLER: Oracle Golden Gate Installed'

sudo cp /vagrant/scripts/setPassword.sh /home/oracle/ && \
sudo chmod a+rx /home/oracle/setPassword.sh

echo "INSTALLER: setPassword.sh file setup";

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

echo "INSTALLER: Installation complete, database ready to use!";