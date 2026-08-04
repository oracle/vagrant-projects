#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 09_patch_db_home.sh
#   Apply the optional Database Release Update to the RDBMS home with
#   'opatch apply'. Data Guard runs a single-instance database on each node
#   with no Grid Infrastructure, so there is no opatchauto and no cluster
#   topology: opatch is enough.
#
#   The RU is optional, so this is a no-op unless env.opatch_software and
#   env.db_ru_software are both set.
#
#   Runs as the oracle user, on BOTH primary and standby, after the software
#   install and root.sh but BEFORE the database is created. Patching before
#   database creation means no instance is ever running when opatch applies the
#   binary patch, and both nodes reach the same patch level before redo starts
#   flowing between them.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
require_var DB_HOME

if ! ru_configured; then
  log_info "No Release Update configured; leaving ${DB_HOME} at base release"
  exit 0
fi

# Both patch zips are verified against db_installer.sha256 on the host (Vagrantfile,
# verify_installer!) before this VM boots, so they are not re-checked here.

# Stage the RU and refresh OPatch inside the home, then pick up DB_RU_PATCH_DIR.
prepare_db_ru_patch "${DB_HOME}"
require_var DB_RU_PATCH_DIR

opatch="${DB_HOME}/OPatch/opatch"
[[ -x "${opatch}" ]] || {
  log_error "opatch not found or not executable at ${opatch}"
  exit 1
}

export ORACLE_HOME="${DB_HOME}"

log_section "Applying Database RU ${DB_RU_PATCH_DIR##*/} to ${DB_HOME}"
# opatch wants the current directory to be the patch tree, and it must be one
# the home owner can write to. The staged tree is oracle:oinstall, which is
# where Oracle's own RU README says to run this from.
(
  cd "${DB_RU_PATCH_DIR}"
  "${opatch}" apply -silent -oh "${DB_HOME}"
)
log_success "Database RU ${DB_RU_PATCH_DIR##*/} applied to ${DB_HOME}"
