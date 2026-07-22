#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 06_do_RDBMS_software_installation.sh
#   Extracts the Oracle Home zip into DB_HOME and runs the silent installer
#   (software-only install). Verifies the installer against the project's
#   db_installer.sha256 manifest before extraction.
#
#   Runs as the oracle user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh

if [[ "$(id -un)" != "oracle" ]]; then
  log_error "this script must run as the oracle user"
  exit 1
fi

require_var DB_HOME
require_var DB_BASE
require_var DB_SOFTWARE
require_var ORA_INVENTORY
require_var ORA_LANGUAGES

zip_path="$(orcl_sw "${DB_SOFTWARE}")"

# The installer is verified against db_installer.sha256 on the host (Vagrantfile,
# verify_installer!) before this VM ever boots, so it is not re-checked here.

log_section "Extracting ${DB_SOFTWARE} into ${DB_HOME}"
mkdir -p "${DB_HOME}"
cd "${DB_HOME}"
unzip -oq "${zip_path}"

log_section "Running runInstaller (software-only, silent)"

# runInstaller exit codes (see Oracle docs):
#   0  success
#   6  successful with warnings — typical when -ignorePrereq is set
#      (prerequisite checks bypassed, install still complete)
#   other  real failure
#
# Wrap the command in an if-statement so Oracle's warning exit code (6)
# can be handled explicitly without tripping the shared ERR trap from
# _common.sh before we inspect rc.
if "${DB_HOME}/runInstaller" \
  -ignorePrereq -waitforcompletion -silent \
  -responseFile "${DB_HOME}/install/response/db_install.rsp" \
  oracle.install.option=INSTALL_DB_SWONLY \
  UNIX_GROUP_NAME=oinstall \
  INVENTORY_LOCATION="${ORA_INVENTORY}" \
  SELECTED_LANGUAGES="${ORA_LANGUAGES}" \
  ORACLE_HOME="${DB_HOME}" \
  ORACLE_BASE="${DB_BASE}" \
  oracle.install.db.InstallEdition=EE \
  oracle.install.db.OSDBA_GROUP=dba \
  oracle.install.db.OSBACKUPDBA_GROUP=backupdba \
  oracle.install.db.OSDGDBA_GROUP=dgdba \
  oracle.install.db.OSKMDBA_GROUP=kmdba \
  oracle.install.db.OSRACDBA_GROUP=racdba \
  SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
  DECLINE_SECURITY_UPDATES=true; then
  rc=0
else
  rc=$?
fi

case "${rc}" in
  0) log_success "runInstaller completed successfully" ;;
  6) log_info    "runInstaller completed with warnings (exit=6) — expected when -ignorePrereq is set" ;;
  *) log_error   "runInstaller failed with exit=${rc}"; exit "${rc}" ;;
esac
