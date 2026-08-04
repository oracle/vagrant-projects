#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 18_check_database.sh
#   Report srvctl config/status for the freshly-created database.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
require_var DB_HOME
require_var DB_NAME
require_var ORESTART

export ORACLE_HOME="${DB_HOME}"

log_section "srvctl config database -d ${DB_NAME}"
if ! "${DB_HOME}/bin/srvctl" config database -d "${DB_NAME}"; then
  if [[ "${ORESTART}" == "true" ]]; then
    log_error "Oracle Restart configuration reported an error"
  else
    log_error "Oracle RAC configuration reported an error"
  fi
  exit 1
fi

log_section "srvctl status database -d ${DB_NAME}"
"${DB_HOME}/bin/srvctl" status database -d "${DB_NAME}"

if [[ "${ORESTART}" == "true" ]]; then
  log_success "Oracle Restart on Vagrant has been created successfully"
else
  log_success "Oracle RAC on Vagrant has been created successfully"
fi
