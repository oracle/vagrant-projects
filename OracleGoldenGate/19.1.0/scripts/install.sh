#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
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

# set system time zone
sudo timedatectl set-timezone $SYSTEM_TIMEZONE
echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

# Install Oracle Database prereq and openssl packages
yum install -y oracle-database-preinstall-19c openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

# Create Directories
mkdir -p /u01/ogg-installer
mkdir -p /u01/oggbd
mkdir -p /u01/ogg
mkdir -p /vagrant/oggbd
mkdir -p /usr/local/kafka

chown oracle:oinstall -R /u01/oggbd


# create directories
mkdir -p $ORACLE_HOME
mkdir -p /u01/app
ln -s $ORACLE_BASE /u01/app/oracle

echo 'INSTALLER: Oracle directories created'

# set environment variables
echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bashrc
echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bashrc
echo "export ORACLE_SID=$ORACLE_SID" >> /home/oracle/.bashrc
echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bashrc

echo 'INSTALLER: Environment variables set'

# Install Java 8
echo 'INSTALLER: Install Java 8'
yum install -y java-$JAVA_VERSION-openjdk

# Install Apache Kafka
KAFKA_SCALA_VERSION="$SCALA_VERSION-$KAFKA_VERSION"
echo "Downloading Apache Kafka Version $KAFKA_VERSION"
curl "https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_$KAFKA_SCALA_VERSION.tgz" -# -o /tmp/kafka_$KAFKA_SCALA_VERSION.tgz

echo "Extracting Kafka to /usr/local/kafka/kafka_$KAFKA_SCALA_VERSION"
sudo tar -xzf /tmp/kafka_$KAFKA_SCALA_VERSION.tgz -C /usr/local/kafka/
rm /tmp/kafka_$KAFKA_SCALA_VERSION.tgz

sudo sed -i -e 's|^#advertised\.listeners=*.*$|advertised.listeners=PLAINTEXT://'$MACHINE_IP':9092|g' /usr/local/kafka/kafka_$KAFKA_SCALA_VERSION/config/server.properties
sudo cp /vagrant/scripts/services/zookeeper.service /etc/systemd/system/
sudo cp /vagrant/scripts/services/kafka.service /etc/systemd/system/

su -l oracle -c "echo 'export PATH=\$PATH:/usr/local/kafka/kafka_'$KAFKA_SCALA_VERSION'/bin/:' >> /home/oracle/.bashrc"

echo 'Creating Zookeeper and Kafka System Services'

sudo sed -i -e "s|###KAFKA_VERSION###|$KAFKA_SCALA_VERSION|g" /etc/systemd/system/zookeeper.service

sudo sed -i -e "s|###JAVA_VERSION###|$JAVA_VERSION|g" /etc/systemd/system/kafka.service
sudo sed -i -e "s|###KAFKA_VERSION###|$KAFKA_SCALA_VERSION|g" /etc/systemd/system/kafka.service

sudo systemctl daemon-reload
sudo systemctl enable zookeeper
sudo systemctl enable kafka

sudo systemctl start zookeeper
sudo systemctl start kafka

echo 'INSTALLER: Apache Kafka Installed and Started'

# Install Oracle

unzip /vagrant/$ORACLE_DB_SETUP_FILE -d $ORACLE_HOME/
cp /vagrant/ora-response/db_install.rsp.tmpl /tmp/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /tmp/db_install.rsp
chown oracle:oinstall -R $ORACLE_BASE
su -l oracle -c "yes | $ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -waitforcompletion -responseFile /tmp/db_install.rsp"
$ORACLE_BASE/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh
rm -rf /tmp/database
rm /tmp/db_install.rsp

echo 'INSTALLER: Oracle software installed'

# create sqlnet.ora, listener.ora and tnsnames.ora
su -l oracle -c "mkdir -p $ORACLE_HOME/network/admin"
su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $ORACLE_HOME/network/admin/sqlnet.ora"

# Listener.ora
su -l oracle -c "echo 'LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
' > $ORACLE_HOME/network/admin/listener.ora"

su -l oracle -c "echo '$ORACLE_SID=localhost:$LISTENER_PORT/$ORACLE_SID' > $ORACLE_HOME/network/admin/tnsnames.ora"
su -l oracle -c "echo '$ORACLE_PDB= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)' >> $ORACLE_HOME/network/admin/tnsnames.ora"

# Start LISTENER
su -l oracle -c "lsnrctl start"

echo 'INSTALLER: Listener created'

# Create database

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${ORACLE_PWD:-"`openssl rand -base64 8`1"}

cp /vagrant/ora-response/dbca.rsp.tmpl /tmp/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /tmp/dbca.rsp
sed -i -e "s|###EM_EXPRESS_PORT###|$EM_EXPRESS_PORT|g" /tmp/dbca.rsp

# Create DB
su -l oracle -c "dbca -silent -createDatabase -responseFile /tmp/dbca.rsp"

# Post DB setup tasks
su -l oracle -c "sqlplus / as sysdba <<EOF
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   ALTER SYSTEM SET LOCAL_LISTENER = '(ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))' SCOPE=BOTH;
   ALTER SYSTEM REGISTER;
   exit;
EOF"
rm /tmp/dbca.rsp

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
sudo cp /vagrant/scripts/services/oracle-rdbms.service /etc/systemd/system/
sudo sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
sudo systemctl daemon-reload
sudo systemctl enable oracle-rdbms
sudo systemctl start oracle-rdbms
echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

echo 'INSTALLER: Started GG installation'
  #oracle-goldengate-1910-vagrant: ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: 8t8aUcnLhAE=1
# Install Golden Gate For Oracle
sudo unzip /vagrant/$ORACLE_GG_SETUP_FILE -d /u01/ogg-installer
sudo chown 
cp /vagrant/ora-response/ogg_install.rsp.tmpl /tmp/oggresponse.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /tmp/oggresponse.rsp
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /tmp/oggresponse.rsp

chown oracle:oinstall -R /u01/ogg-installer
chown oracle:oinstall -R /u01/ogg

su -l oracle -c "/u01/ogg-installer/fbo_ggs_Linux_x64_shiphome/Disk1/runInstaller -silent -waitforcompletion -responseFile /tmp/oggresponse.rsp"
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib" >> /home/oracle/.bashrc
rm -rf /u01/ogg-installer
rm /tmp/oggresponse.rsp

echo 'INSTALLER: Oracle Golden Gate Installed'

# Install Golden Gate For Big Data
echo 'Installer: Install GG for Big Data'
unzip /vagrant/$ORACLE_GG_BD_SETUP_FILE -d /tmp/oggbd
sudo tar -xvf /tmp/oggbd/*BigData_Linux*.tar -C /u01/oggbd/
rm -rf /tmp/oggbd
chown -R oracle:oinstall /u01/oggbd/
echo 'INSTALLER: Oracle GG For Big Data Installed.'


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


echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

echo "INSTALLER: Installation complete, database ready to use!";