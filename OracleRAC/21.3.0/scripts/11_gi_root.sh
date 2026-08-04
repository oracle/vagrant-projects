#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 11_gi_root.sh
#   Run orainstRoot.sh + root.sh on both cluster nodes (or just locally for
#   Oracle Restart).
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var ORA_INVENTORY
require_var GI_HOME
require_var ORESTART

# orainstRoot.sh creates /etc/oraInst.loc and fixes up the inventory
# permissions. OUI only generates it when there is no central inventory yet, so
# it is absent whenever a Release Update is configured: staging the RU has to
# create the inventory pointer up front (opatch, which gridSetup -applyRU runs,
# needs it), which leaves OUI with nothing for the script to do. Skip it when it
# was not generated rather than failing the run.
run_local_orainst_root() {
  local script="${ORA_INVENTORY}/orainstRoot.sh"

  if [[ -f "${script}" ]]; then
    log_section "Running orainstRoot.sh on local node"
    sh "${script}"
  else
    log_section "Skipping orainstRoot.sh on local node"
    log_info "${script} was not generated; central inventory is already initialized"
  fi
}

run_remote_orainst_root() {
  local node="$1"

  log_section "Running orainstRoot.sh on ${node} if present"
  ssh -o StrictHostKeyChecking=no "root@${node}" \
    "if [ -f '${ORA_INVENTORY}/orainstRoot.sh' ]; then sh '${ORA_INVENTORY}/orainstRoot.sh'; else echo '${ORA_INVENTORY}/orainstRoot.sh was not generated; skipping'; fi"
}

run_local_orainst_root

log_section "Running root.sh on local node"
sh "${GI_HOME}/root.sh"

if [[ "${ORESTART}" == "true" ]]; then
  log_section "Running roothas.pl (Oracle Restart)"
  "${GI_HOME}/perl/bin/perl" \
    -I "${GI_HOME}/perl/lib" -I "${GI_HOME}/crs/install" \
    "${GI_HOME}/crs/install/roothas.pl"
else
  require_var NODE2_HOSTNAME
  run_remote_orainst_root "${NODE2_HOSTNAME}"
  log_section "Running root.sh on ${NODE2_HOSTNAME}"
  ssh -o StrictHostKeyChecking=no "root@${NODE2_HOSTNAME}" "sh ${GI_HOME}/root.sh"
fi
