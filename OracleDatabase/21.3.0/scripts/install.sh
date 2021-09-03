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
dnf install -y oracle-database-preinstall-21c openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

# create directories
mkdir -p "$ORACLE_HOME"
mkdir -p /u01/app
ln -s "$ORACLE_BASE" /u01/app/oracle
inventory_location=$(realpath "$ORACLE_BASE"/../oraInventory)
mkdir -p "$inventory_location"

echo 'INSTALLER: Oracle directories created'

# set environment variables
# shellcheck disable=SC2153
cat >> /home/oracle/.bashrc << EOF
export ORACLE_BASE=$ORACLE_BASE
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export PATH=\$PATH:\$ORACLE_HOME/bin
EOF

echo 'INSTALLER: Environment variables set'

# Install Oracle

unzip /vagrant/LINUX.X64_213000_db_home.zip -d "$ORACLE_HOME"/
cp /vagrant/ora-response/db_install.rsp.tmpl /tmp/db_install.rsp
sed -i -e "s|###INVENTORY_LOCATION###|$inventory_location|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /tmp/db_install.rsp
sed -i -e "s|###ORACLE_EDITION###|$ORACLE_EDITION|g" /tmp/db_install.rsp
chown oracle:oinstall -R "$ORACLE_BASE" "$inventory_location"

# runInstaller should return 6 (successful with warnings) when prereqs are ignored
su -l oracle -c "yes | $ORACLE_HOME/runInstaller -silent -ignorePrereqFailure -waitforcompletion -responseFile /tmp/db_install.rsp" || {
  ret=$?
  if [[ $ret -ne 6 ]]; then
    echo 'Oracle Database installer exited with error!'
    exit $ret;
  fi;
}

"$inventory_location"/orainstRoot.sh
"$ORACLE_HOME"/root.sh
rm /tmp/db_install.rsp

echo 'INSTALLER: Oracle software installed'

# create sqlnet.ora, listener.ora and tnsnames.ora
network_admin_dir=$("$ORACLE_HOME"/bin/orabasehome)/network/admin
su -l oracle -c "mkdir -p $network_admin_dir"
su -l oracle -c "echo 'NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)' > $network_admin_dir/sqlnet.ora"

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
' > $network_admin_dir/listener.ora"

su -l oracle -c "echo '$ORACLE_SID=localhost:$LISTENER_PORT/$ORACLE_SID' > $network_admin_dir/tnsnames.ora"
# shellcheck disable=SC2153
su -l oracle -c "echo '$ORACLE_PDB=
(DESCRIPTION =
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_PDB)
  )
)' >> $network_admin_dir/tnsnames.ora"

# Start LISTENER
su -l oracle -c 'lsnrctl start'

echo 'INSTALLER: Listener created'

# Create database

# Auto generate ORACLE PWD if not passed in
export ORACLE_PWD=${ORACLE_PWD:-"$(openssl rand -base64 8)1"}

cp /vagrant/ora-response/dbca.rsp.tmpl /tmp/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" /tmp/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" /tmp/dbca.rsp
sed -i -e "s|###EM_EXPRESS_PORT###|$EM_EXPRESS_PORT|g" /tmp/dbca.rsp

# Create DB
su -l oracle -c 'dbca -silent -createDatabase -responseFile /tmp/dbca.rsp'

# Post DB setup tasks
su -l oracle -c "sqlplus / as sysdba << EOF
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   ALTER SYSTEM SET LOCAL_LISTENER = '(ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = $LISTENER_PORT))' SCOPE=BOTH;
   ALTER SYSTEM REGISTER;
   exit
EOF"

rm /tmp/dbca.rsp

echo 'INSTALLER: Database created'

sed -i -e "\$s|${ORACLE_SID}:${ORACLE_HOME}:N|${ORACLE_SID}:${ORACLE_HOME}:Y|" /etc/oratab
echo 'INSTALLER: Oratab configured'

# configure systemd to start oracle instance on startup
cp /vagrant/scripts/oracle-rdbms.service /etc/systemd/system/
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" /etc/systemd/system/oracle-rdbms.service
systemctl daemon-reload
systemctl enable oracle-rdbms
systemctl start oracle-rdbms
echo "INSTALLER: Created and enabled oracle-rdbms systemd's service"

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
