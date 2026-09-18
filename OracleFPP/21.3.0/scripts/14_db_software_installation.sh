#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 14_db_software_installation.sh
#   Silent, software-only RDBMS install (EE, cluster-aware). Runs as grid —
#   this home becomes an FPP gold image (see 17_Setup_FPP.sh), not a live
#   database, so it's provisioned by the grid/FPP-server owner, not oracle.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user grid
for v in DB_HOME DB_BASE ORA_INVENTORY ORA_LANGUAGES \
         NODE1_HOSTNAME; do
  require_var "${v}"
done

rsp_args=(
  oracle.install.option=INSTALL_DB_SWONLY
  UNIX_GROUP_NAME=oinstall
  INVENTORY_LOCATION="${ORA_INVENTORY}"
  SELECTED_LANGUAGES="${ORA_LANGUAGES}"
  ORACLE_HOME="${DB_HOME}"
  ORACLE_BASE="${DB_BASE}"
  oracle.install.db.InstallEdition=EE
  oracle.install.db.OSDBA_GROUP=dba
  oracle.install.db.OSOPER_GROUP=dbaoper
  oracle.install.db.OSBACKUPDBA_GROUP=backupdba
  oracle.install.db.OSDGDBA_GROUP=dgdba
  oracle.install.db.OSKMDBA_GROUP=kmdba
  oracle.install.db.OSRACDBA_GROUP=racdba
  oracle.install.db.rac.serverpoolCardinality=0
  oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
  oracle.install.db.ConfigureAsContainerDB=true
  oracle.install.db.CLUSTER_NODES="${NODE1_HOSTNAME}"
  oracle.install.db.isRACOneInstall=false
  SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
  DECLINE_SECURITY_UPDATES=true
)

log_section "Running runInstaller (software-only, silent)"
if "${DB_HOME}/runInstaller" \
     -ignorePrereq -waitforcompletion -silent \
     -responseFile "${DB_HOME}/install/response/db_install.rsp" \
     "${rsp_args[@]}"; then
  rc=0
else
  rc=$?
fi

case "${rc}" in
  0) log_success "runInstaller completed successfully" ;;
  6) log_info    "runInstaller completed with warnings (exit=6) — expected when -ignorePrereq is set" ;;
  *) log_error   "runInstaller failed with exit=${rc}"; exit "${rc}" ;;
esac
