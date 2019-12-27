#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright © 1982-2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    NAME
#      ords.sh
#
#    DESCRIPTION
#      Execute Oracle Rest Data Services installation and configuration
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

. /home/oracle/.bashrc 

export ORACLE_PWD=`cat /vagrant/apex-pwd`
rm -f /vagrant/apex-pwd

# Install ORDS
mkdir $ORACLE_BASE/ords
export ORDS_HOME=$ORACLE_BASE/ords
echo "export ORDS_HOME=$ORACLE_BASE/ords" >> /home/oracle/.bashrc
cd  $ORDS_HOME
ORDS_INSTALL=`ls /vagrant/ords[_-]1*.*.zip |tail -1`
unzip $ORDS_INSTALL
chown -R oracle:oinstall $ORDS_HOME

echo 'INSTALLER: Oracle Rest Data Services extracted to ORACLE_BASE'

# Create config directory
su -l oracle -c "$ORACLE_HOME/jdk/bin/java -jar $ORDS_HOME/ords.war configdir $ORDS_HOME/config"
su -l oracle -c "mkdir -p $ORDS_HOME/config/ords/standalone"
su -l oracle -c "mkdir -p $ORDS_HOME/config/ords/doc_root"

# Configure ORDS
cat > $ORDS_HOME/params/ords_params.properties << EOF
db.hostname=localhost
db.port=1521
# CUSTOMIZE db.servicename
db.servicename=${ORACLE_PDB}
db.username=APEX_PUBLIC_USER
db.password=${ORACLE_PWD}
migrate.apex.rest=false
plsql.gateway.add=true
rest.services.apex.add=true
rest.services.ords.add=true
schema.tablespace.default=SYSAUX
schema.tablespace.temp=TEMP
sys.user=sys
sys.password=${ORACLE_PWD}
standalone.mode=TRUE
standalone.http.port=8080
standalone.use.https=false
# CUSTOMIZE standalone.static.images to point to the directory 
# containing the images directory of your APEX distribution
standalone.static.images=${ORACLE_HOME}/apex/images
user.apex.listener.password=${ORACLE_PWD}
user.apex.restpublic.password=${ORACLE_PWD}
user.public.password=oracle
user.tablespace.default=SYSAUX
user.tablespace.temp=TEMP
EOF

su -l oracle -c "cd $ORACLE_HOME/apex; sqlplus / as sysdba <<EOF
        alter session set container=$ORACLE_PDB;
        alter user APEX_LISTENER identified by \"${ORACLE_PWD}\" account unlock;
        alter user APEX_REST_PUBLIC_USER identified by \"${ORACLE_PWD}\" account unlock;
        exit;
EOF"

cat > $ORDS_HOME/config/ords/standalone/standalone.properties << EOF
jetty.port=8080
standalone.context.path=/ords
standalone.doc.root=$ORDS_HOME/config/ords/doc_root
standalone.scheme.do.not.prompt=true
standalone.static.context.path=/i
standalone.static.path=$ORACLE_HOME/apex/images
EOF

# Fix permissions on ORDS standalone directories
chown -R oracle:oinstall $ORACLE_BASE/ords

echo 'INSTALLER: Oracle Rest Data Services configuration created'

# Create and configure ORDS Database Users/Objects
su -l oracle -c "$ORACLE_HOME/jdk/bin/java -jar $ORDS_HOME/ords.war setup --parameterFile $ORDS_HOME/params/ords_params.properties --silent"

echo 'INSTALLER: Oracle Rest Data Services installation completed'

# Start ORDS service
export JAVA_HOME=$ORACLE_HOME/jdk/bin
cat > /etc/systemd/system/ords.service << EOF
[Unit]
Description=Start Oracle REST Data Services
After=oracle-xe-18c.service

[Service]
User=oracle
ExecStart=${JAVA_HOME}/java -jar ${ORDS_HOME}/ords.war
StandardOutput=syslog
SyslogIdentifier=ords

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now ords
echo 'INSTALLER: Oracle Rest Data Services started'

echo ""
echo "INSTALLER: APEX/ORDS Installation Completed";
echo "INSTALLER: You can access APEX by your Host Operating System at following URL:";
echo "INSTALLER: http://localhost:8080/ords/";
echo "INSTALLER: Access granted with:";
echo "INSTALLER: Workspace: internal";
echo "INSTALLER: Username:  admin";
echo "INSTALLER: Password:  ${ORACLE_PWD}";
echo ""
