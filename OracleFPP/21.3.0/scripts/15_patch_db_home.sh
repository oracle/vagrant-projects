#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 15_patch_db_home.sh
#   Apply the GI Release Update to the RDBMS home with opatchauto. The GI RU is
#   a combo patch that carries the DB home patch too, so this home takes the
#   same zip as the GI home and there is no separate Database RU.
#
#   The RU is optional, so this is a no-op unless env.opatch_software and
#   env.gi_ru_software are both set.
#
#   Runs as root on the FPP server, after 14 and root.sh: opatchauto needs the
#   home installed and registered in the inventory, which is only true by then.
#   It also runs before 16_setup_gimr.sh, so mgmtca builds the GIMR from an
#   already-patched home rather than one opatchauto would later have to
#   shut down.
#
#   This home belongs to grid, not oracle: on an FPP server the RDBMS home
#   exists to host the GIMR rather than a user database.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var DB_HOME

if ! ru_configured; then
  log_info "No Release Update configured; leaving ${DB_HOME} at base release"
  exit 0
fi

prepare_db_ru_patch "${DB_HOME}"
require_var GI_RU_PATCH_DIR

opatchauto="${DB_HOME}/OPatch/opatchauto"
[[ -x "${opatchauto}" ]] || {
  log_error "opatchauto not found or not executable at ${opatchauto}"
  exit 1
}

log_section "Applying GI RU ${GI_RU_PATCH_DIR##*/} to ${DB_HOME}"
# opatchauto rejects '/' and '/root' as the current directory and wants one the
# home owner can write to, so don't inherit the caller's cwd — 'sudo su -' lands
# in /root and would fail here. The staged patch dir is grid:oinstall, and is
# where Oracle's own RU README says to run this from.
(
  cd "${GI_RU_PATCH_DIR}"
  "${opatchauto}" apply "${GI_RU_PATCH_DIR}" -oh "${DB_HOME}"
)
log_success "GI RU ${GI_RU_PATCH_DIR##*/} applied to ${DB_HOME}"
