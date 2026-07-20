#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 11_gi_root.sh
#   Run orainstRoot.sh + root.sh on both SEHA cluster nodes.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var ORA_INVENTORY
require_var GI_HOME
require_var NODE2_HOSTNAME
require_var ASM_DISK_NUM

wait_for_data_disk_discovery() {
  local attempts="${1:-30}"
  local delay="${2:-2}"
  local attempt disk kfod_out missing

  log_section "Waiting for ASM DATA disk discovery"
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    udevadm control --reload-rules || true
    udevadm trigger --subsystem-match=block || true
    udevadm settle || true

    missing=0
    for ((disk = 1; disk <= ASM_DISK_NUM; disk++)); do
      if [[ ! -b "/dev/ORCL_DISK${disk}_p1" ]]; then
        missing=1
        break
      fi
    done

    if (( missing == 0 )); then
      kfod_out="$(
        su - grid -c "export ORACLE_HOME='${GI_HOME}'; export PATH='${GI_HOME}/bin':\$PATH; kfod op=disks disks=all asm_diskstring='/dev/ORCL_DISK*_p1'" 2>&1
      )"
      missing=0
      for ((disk = 1; disk <= ASM_DISK_NUM; disk++)); do
        if ! grep -q "/dev/ORCL_DISK${disk}_p1" <<< "${kfod_out}"; then
          missing=1
          break
        fi
      done
      if (( missing == 0 )); then
        log_success "ASM DATA disks are visible to kfod"
        return 0
      fi
    fi

    sleep "${delay}"
  done

  log_error "ASM DATA disks were not visible to kfod after ${attempts} attempts"
  printf '%s\n' "${kfod_out:-}" >&2
  return 1
}

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

wait_for_data_disk_discovery

log_section "Running root.sh on local node"
sh "${GI_HOME}/root.sh"

run_remote_orainst_root "${NODE2_HOSTNAME}"
log_section "Running root.sh on ${NODE2_HOSTNAME}"
ssh -o StrictHostKeyChecking=no "root@${NODE2_HOSTNAME}" "sh ${GI_HOME}/root.sh"
