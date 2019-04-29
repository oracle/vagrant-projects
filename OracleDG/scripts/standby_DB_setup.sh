#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/standby_DB_setup.sh,v 2.0.1.2 2018/11/18 23:23:30 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      standby_DB_setup.sh
#
#    DESCRIPTION
#      Standby node DB setup
#
#    NOTES
#       DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#       Ruggero Citton
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     11/06/18 - Creation
#
. /vagrant_config/setup.env

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setup standby env"
echo "-----------------------------------------------------------------"
if [ "${CDB}" == "true" ]
then
  mkdir -p /u02/oradata/${DB_NAME}/pdbseed
  mkdir -p /u02/oradata/${DB_NAME}/pdb1
fi

mkdir -p ${DB_BASE}/fast_recovery_area/${DB_NAME}
mkdir -p ${DB_BASE}/admin/${DB_NAME}/adump

orapwd file=$ORACLE_HOME/dbs/orapw${DB_NAME} password=${SYS_PASSWORD} entries=10 format=12

cat > /tmp/init_standby.ora <<EOF
*.db_name='${DB_NAME}'
*.local_listener='LISTENER'
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Making auxillary instance"
echo "-----------------------------------------------------------------"
export ORACLE_SID=${DB_NAME}
${DB_HOME}/bin/sqlplus / as sysdba <<EOF
--SHUTDOWN IMMEDIATE;
STARTUP NOMOUNT PFILE='/tmp/init_standby.ora';
exit;
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Making the standby DB "
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/rman TARGET sys/${SYS_PASSWORD}@${DB_NAME} AUXILIARY sys/${SYS_PASSWORD}@${DB_NAME}_STDBY <<EOF
DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='${DB_NAME}_STDBY' COMMENT 'Standby'
  NOFILENAMECHECK;
exit;
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Enabling DG Broker"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/sqlplus / as sysdba <<EOF
ALTER SYSTEM SET dg_broker_start=true;
exit;
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Enabling DG Broker"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/sqlplus / as sysdba <<EOF
ALTER SYSTEM SET ARCHIVE_LAG_TARGET=0 SCOPE=BOTH  SID='*';
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=4 SCOPE=BOTH SID='*';
ALTER SYSTEM SET LOG_ARCHIVE_MIN_SUCCEED_DEST=1 SCOPE=BOTH SID='*';
ALTER SYSTEM SET DATA_GUARD_SYNC_LATENCY=0 SCOPE=BOTH SID='*';
exit;
EOF


echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Primary DG Broker setup"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/dgmgrl sys/${SYS_PASSWORD}@${DB_NAME} <<EOF
CREATE CONFIGURATION db_broker_config AS PRIMARY DATABASE IS ${DB_NAME} CONNECT IDENTIFIER IS ${DB_NAME};
exit;
EOF
sleep 10

${DB_HOME}/bin/dgmgrl sys/${SYS_PASSWORD}@${DB_NAME} <<EOF
ADD DATABASE ${DB_NAME}_STDBY AS CONNECT IDENTIFIER IS ${DB_NAME}_STDBY MAINTAINED AS PHYSICAL;
exit;
EOF
sleep 5

${DB_HOME}/bin/dgmgrl sys/${SYS_PASSWORD}@${DB_NAME} <<EOF
ENABLE CONFIGURATION;
exit;
EOF
sleep 5

${DB_HOME}/bin/sqlplus / as sysdba <<EOF
STARTUP MOUNT FORCE;
exit;
EOF

sleep 60
${DB_HOME}/bin/dgmgrl sys/${SYS_PASSWORD}@${DB_NAME} <<EOF
SHOW CONFIGURATION;
SHOW DATABASE ${DB_NAME};
SHOW DATABASE ${DB_NAME}_STDBY;
exit;
EOF

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------
