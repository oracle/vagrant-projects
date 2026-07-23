#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 17_create_database.sh
#   Create the SEHA database via dbca (silent). Runs as oracle.
#
#   23.26.1's dbca knows SEHA natively: -databaseConfigType accepts SEHA, and
#   -sehaNodeList takes the candidate node list, so dbca registers the failover
#   configuration itself and no follow-up srvctl call is needed.
#
#   This is release-specific. The 19c and 21c projects have to create the
#   database as SINGLE and then add the node list with
#   'srvctl modify database -node', because their dbca accepts only
#   < SINGLE | RAC | RACONENODE > and has no -sehaNodeList.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
for v in DB_HOME DB_NAME CDB SYS_PASSWORD \
         NODE1_HOSTNAME NODE2_HOSTNAME \
         DB_RECOVERY_FILE_DEST_SIZE; do
  require_var "${v}"
done

log_info "Using DBCA fast recovery area size '${DB_RECOVERY_FILE_DEST_SIZE}'"

dbca_args=(
  -silent -createDatabase
  -templateName General_Purpose.dbc
  -initParams "db_recovery_file_dest_size=${DB_RECOVERY_FILE_DEST_SIZE}"
  -responseFile NO_VALUE
  -gdbname "${DB_NAME}"
  -sid "${DB_NAME}"
  -characterSet AL32UTF8
  -sysPassword    "${SYS_PASSWORD}"
  -systemPassword "${SYS_PASSWORD}"
  -databaseType MULTIPURPOSE
  -automaticMemoryManagement false
  -totalMemory 2048
  -redoLogFileSize 50
  -emConfiguration NONE
  -ignorePreReqs
  -storageType ASM
  -diskGroupName +DATA
  -recoveryGroupName +RECO
  -asmsnmpPassword "${SYS_PASSWORD}"
  -databaseConfigType SEHA
  -sehaNodeList "${NODE1_HOSTNAME},${NODE2_HOSTNAME}"
)

if [[ "${CDB}" == "true" ]]; then
  require_var PDB_NAME
  require_var PDB_PASSWORD
  dbca_args+=(
    -createAsContainerDatabase true
    -numberOfPDBs 1
    -pdbName "${PDB_NAME}"
    -pdbAdminPassword "${PDB_PASSWORD}"
  )
fi

log_section "Running dbca (silent, create SEHA database on ${NODE1_HOSTNAME},${NODE2_HOSTNAME})"
"${DB_HOME}/bin/dbca" "${dbca_args[@]}"
log_success "SEHA database ${DB_NAME} created"
