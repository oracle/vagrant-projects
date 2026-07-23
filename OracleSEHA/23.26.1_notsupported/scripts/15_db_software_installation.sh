#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 15_db_software_installation.sh
#   Silent, software-only RDBMS install (SE2, single-instance home for SEHA).
#   Runs as oracle on each node.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
for v in DB_HOME DB_BASE ORA_INVENTORY ORA_LANGUAGES DB_INSTALL_EDITION; do
  require_var "${v}"
done

rsp_args=(
  oracle.install.option=INSTALL_DB_SWONLY
  UNIX_GROUP_NAME=oinstall
  INVENTORY_LOCATION="${ORA_INVENTORY}"
  SELECTED_LANGUAGES="${ORA_LANGUAGES}"
  ORACLE_HOME="${DB_HOME}"
  ORACLE_BASE="${DB_BASE}"
  installEdition="${DB_INSTALL_EDITION}"
  oracle.install.db.OSDBA_GROUP=dba
  oracle.install.db.OSBACKUPDBA_GROUP=backupdba
  oracle.install.db.OSDGDBA_GROUP=dgdba
  oracle.install.db.OSKMDBA_GROUP=kmdba
  oracle.install.db.OSRACDBA_GROUP=racdba
  # Leave clusterNodes unset. Setting it makes OUI treat this as a RAC install,
  # which SE2 rejects with INS-35465 — SE2 RAC is desupported, and SEHA is its
  # replacement. The home is single-instance and installed per node; failover
  # comes later, from the srvctl node list set in 17_create_database.sh.
  oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
  oracle.install.db.ConfigureAsContainerDB=true
  SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
  DECLINE_SECURITY_UPDATES=true
)

log_section "Running runInstaller (${DB_INSTALL_EDITION} software-only, silent)"
installer_log="$(mktemp /tmp/db-runInstaller.XXXXXX.log)"
if "${DB_HOME}/runInstaller" \
     -ignorePrereq -waitforcompletion -silent \
     -responseFile "${DB_HOME}/install/response/db_install.rsp" \
     "${rsp_args[@]}" 2>&1 | tee "${installer_log}"; then
  rc=0
else
  rc=$?
fi

case "${rc}" in
  0) log_success "runInstaller completed successfully" ;;
  6)
    if grep -Eq '\[FATAL\]|INS-10113|Installer encountered errors' "${installer_log}"; then
      log_error "runInstaller reported fatal installer output despite exit=6; see ${installer_log}"
      exit 6
    fi
    log_info "runInstaller completed with warnings (exit=6) — expected when -ignorePrereq is set"
    ;;
  *) log_error   "runInstaller failed with exit=${rc}"; exit "${rc}" ;;
esac
