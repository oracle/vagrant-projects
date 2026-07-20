#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 13_extract_db.sh
#   Extract the RDBMS zip into DB_HOME. Runs as root so it can chown the result
#   to grid:oinstall — on an FPP server this home hosts the GIMR, so it belongs
#   to grid rather than oracle. The Vagrantfile has already verified every installer
#   checksum by the time this runs.
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
chown -R grid:oinstall "${DB_HOME}"
log_success "RDBMS software extracted into ${DB_HOME}"
