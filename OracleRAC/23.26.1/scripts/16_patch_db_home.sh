#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 16_patch_db_home.sh
#   Apply the GI Release Update to the RDBMS home with opatchauto. The GI RU is
#   a combo patch that carries the DB home patch too, so this home takes the
#   same zip as the GI home and there is no separate Database RU.
#
#   The RU is optional, so this is a no-op unless env.opatch_software and
#   env.gi_ru_software are both set.
#
#   Runs as root on each node, after 15 and root.sh: opatchauto needs the home
#   installed and registered in the inventory, which is only true by then.
#
#   Requires the RDBMS home to exist on EVERY cluster node before it runs on
#   ANY of them: opatchauto builds a cluster-wide topology and probes
#   ${DB_HOME}/perl/bin/perl on each node, so a node without the home fails
#   the whole session with OPATCHAUTO-72050 / "Topology creation failed".
#   runInstaller pushes the home to node2, so this holds once root.sh has run
#   on both nodes.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var DB_HOME

if ! ru_configured; then
  log_info "No Release Update configured; leaving ${DB_HOME} at base release"
  exit 0
fi

# The patch tree sits outside the RDBMS home, so runInstaller's push to node2
# does not carry it — stage it locally, on whichever node this is, and pick up
# the resulting GI_RU_PATCH_DIR.
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
# in /root and would fail here. The staged patch dir is oracle:oinstall, and is
# where Oracle's own RU README says to run this from.
(
  cd "${GI_RU_PATCH_DIR}"
  "${opatchauto}" apply "${GI_RU_PATCH_DIR}" -oh "${DB_HOME}"
)
log_success "GI RU ${GI_RU_PATCH_DIR##*/} applied to ${DB_HOME}"
