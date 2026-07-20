#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 14_extract_db.sh
#   Verify and extract the RDBMS zip into DB_HOME. Runs as root so it can
#   chown the result to oracle:oinstall.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var DB_HOME
require_var DB_SOFTWARE

log_section "Extracting ${DB_SOFTWARE} into ${DB_HOME}"
mkdir -p "${DB_HOME}"
(
  cd "${DB_HOME}"
  unzip -oq "/vagrant/ORCL_software/${DB_SOFTWARE}"
)
chown -R oracle:oinstall "${DB_HOME}"
log_success "RDBMS software extracted into ${DB_HOME}"

prepare_db_ru_patch "${DB_HOME}"
