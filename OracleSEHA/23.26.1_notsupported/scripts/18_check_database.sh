#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 18_check_database.sh
#   Report srvctl config/status for the freshly-created SEHA database.
#   Read-only.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
require_var DB_HOME
require_var DB_NAME

export ORACLE_HOME="${DB_HOME}"

log_section "srvctl config database -d ${DB_NAME}"
if ! "${DB_HOME}/bin/srvctl" config database -d "${DB_NAME}"; then
  log_error "Oracle SEHA configuration reported an error"
  exit 1
fi

log_section "srvctl status database -d ${DB_NAME}"
"${DB_HOME}/bin/srvctl" status database -d "${DB_NAME}"

log_success "Oracle SEHA on Vagrant has been created successfully"
