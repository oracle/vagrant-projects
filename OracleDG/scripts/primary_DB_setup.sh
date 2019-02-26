#!/bin/bash
#
# $Header: /home/rcitton/CVS/vagrant_dg-2.0.1/scripts/primary_DB_setup.sh,v 2.0.1.1 2018/11/18 23:12:36 rcitton Exp $
#
# Copyright © 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#    FILE NAME
#      primary_DB_setup.sh
#
#    DESCRIPTION
#      Primary node DB setup
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
echo -e "${INFO}`date +%F' '%T`: Primary database creation"
echo "-----------------------------------------------------------------"
if [ "${CDB}" == "true" ]
then
${DB_HOME}/bin/dbca -silent -createDatabase                           \
    -templateName General_Purpose.dbc                                 \
    -gdbname ${DB_NAME} -sid ${DB_NAME}                               \
    -responseFile NO_VALUE                                            \
    -characterSet AL32UTF8                                            \
    -sysPassword ${SYS_PASSWORD}                                      \
    -systemPassword ${SYS_PASSWORD}                                   \
    -createAsContainerDatabase true                                   \
    -numberOfPDBs 1                                                   \
    -pdbName ${PDB_NAME}                                              \
    -pdbAdminPassword ${PDB_PASSWORD}                                 \
    -databaseType MULTIPURPOSE                                        \
    -automaticMemoryManagement false                                  \
    -totalMemory 4196                                                 \
    -storageType FS                                                   \
    -datafileDestination "/u02/oradata"                               \
    -redoLogFileSize 50                                               \
    -emConfiguration NONE                                             \
    -ignorePreReqs
else
${DB_HOME}/bin/dbca -silent -createDatabase                           \
    -templateName General_Purpose.dbc                                 \
    -gdbname ${DB_NAME} -sid ${DB_NAME}                               \
    -responseFile NO_VALUE                                            \
    -characterSet AL32UTF8                                            \
    -sysPassword ${SYS_PASSWORD}                                      \
    -systemPassword ${SYS_PASSWORD}                                   \
    -createAsContainerDatabase false                                  \
    -databaseType MULTIPURPOSE                                        \
    -automaticMemoryManagement false                                  \
    -totalMemory 4196                                                 \
    -storageType FS                                                   \
    -datafileDestination "/u02/oradata"                               \
    -redoLogFileSize 50                                               \
    -emConfiguration NONE                                             \
    -ignorePreReqs
fi

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Primary database destination setup"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/sqlplus / as sysdba <<EOF
ALTER SYSTEM SET db_create_file_dest='/u02/oradata';
ALTER SYSTEM SET db_create_online_log_dest_1='/u02/oradata';
ALTER SYSTEM SET local_listener='LISTENER';
ALTER SYSTEM SET db_recovery_file_dest_size=20G;
ALTER SYSTEM SET db_recovery_file_dest='/u01/app/oracle';
exit;
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Configuring archivelog mode, standby logs and flashback"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/sqlplus / as sysdba <<EOF
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

ALTER DATABASE FORCE LOGGING;
ALTER SYSTEM SWITCH LOGFILE;

ALTER DATABASE ADD STANDBY LOGFILE SIZE 50M;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 50M;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 50M;
ALTER DATABASE ADD STANDBY LOGFILE SIZE 50M;

ALTER DATABASE FLASHBACK ON;

ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;
exit;
EOF

echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Enabling DG broker"
echo "-----------------------------------------------------------------"
${DB_HOME}/bin/sqlplus / as sysdba <<EOF
ALTER SYSTEM SET dg_broker_start=TRUE;
exit;
EOF

#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------
