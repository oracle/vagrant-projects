#!/bin/bash
#
# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl.
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

# get version to install
db_versions=/vagrant/db_versions.csv

if [[ ! -f "${db_versions}" || ! -r "${db_versions}" ]]; then
  echo "INSTALLER: Error reading ${db_versions}. Exiting."
  exit 1
fi

version_record=$(grep "^${DB_VERSION,,}," "${db_versions}") || {
  echo "INSTALLER: Version ${DB_VERSION} not found in ${db_versions}. Exiting."
  exit 1
}

# shellcheck disable=SC2034
IFS=',' read -r version baseurl db_installer sha256 <<< "${version_record}"

# if the database installer exists, set parameter to keep it
# otherwise, download it
if [[ -f /vagrant/"${db_installer}" ]]; then
  KEEP_DB_INSTALLER='true'
else
  echo 'INSTALLER: Downloading Oracle Database software'
  curl -Ls -o /vagrant/"${db_installer}" "${baseurl}${db_installer}"
fi

# verify that database installer is valid
echo 'INSTALLER: Verifying database installer file'

if [[ $(sha256sum /vagrant/"${db_installer}" | awk '{print $1}') != "${sha256}" ]]; then
  cat << EOF

INSTALLER: The database installer file is invalid.
           Destroy this VM (vagrant destroy) and delete the
           ${db_installer}
           file before running vagrant up again.

EOF
  exit 1
fi

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

# Install Oracle Database preinstall and openssl packages
dnf install -y oracle-database-preinstall-23ai openssl

echo 'INSTALLER: Oracle preinstall and openssl complete'

# set environment variables
cat >> /home/oracle/.bashrc << EOF
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/23ai/dbhomeFree
export ORACLE_SID=FREE
export PATH=\$PATH:\$ORACLE_HOME/bin
EOF

echo 'INSTALLER: Environment variables set'

# Install Oracle
dnf -y install /vagrant/"${db_installer}"

if [[ "${KEEP_DB_INSTALLER,,}" == 'false' ]]; then
  rm -f /vagrant/"${db_installer}"
fi

echo 'INSTALLER: Oracle software installed'

# Auto generate ORACLE PWD if not passed in
export ORACLE_PWD=${ORACLE_PWD:-"$(openssl rand -hex 8)1"}

# Create database
cfg_file='/etc/sysconfig/oracle-free-23ai.conf'
mv "${cfg_file}" "${cfg_file}".original
cp /vagrant/ora-response/oracle-free-23ai.conf.tmpl "${cfg_file}"
chmod g+w "${cfg_file}"

sed -i -e "s|###LISTENER_PORT###|$LISTENER_PORT|g" "${cfg_file}"
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" "${cfg_file}"
(echo "${ORACLE_PWD}"; echo "${ORACLE_PWD}") | /etc/init.d/oracle-free-23ai configure

chmod o+r /opt/oracle/product/23ai/dbhomeFree/network/admin/tnsnames.ora

# add tnsnames.ora entry for PDB
cat >> /opt/oracle/product/23ai/dbhomeFree/network/admin/tnsnames.ora << EOF
FREEPDB1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = $LISTENER_PORT))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = FREEPDB1)
    )
  )
EOF

echo 'INSTALLER: Database created'

# configure systemd to start Oracle instance on startup
systemctl daemon-reload
systemctl enable oracle-free-23ai
systemctl start oracle-free-23ai
echo 'INSTALLER: Created and enabled oracle-free-23ai systemd service'

cp /vagrant/scripts/setPassword.sh /home/oracle/
chown oracle:oinstall /home/oracle/setPassword.sh
chmod u=rwx,go=r /home/oracle/setPassword.sh

echo 'INSTALLER: setPassword.sh file set up'

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
