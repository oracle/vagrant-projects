#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 07_extract_gi.sh
#   Extract the Grid Infrastructure zip into GI_HOME. The Vagrantfile has already
#   verified every installer checksum by the time this runs.
#   Runs on the node that owns the GI install (node1 for cluster,
#   the sole node for Oracle Restart).
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var GI_HOME
require_var GI_SOFTWARE

log_section "Extracting ${GI_SOFTWARE} into ${GI_HOME}"
mkdir -p "${GI_HOME}"
(
  cd "${GI_HOME}"
  unzip -oq "$(orcl_sw "${GI_SOFTWARE}")"
)

patch_ssh_user_setup_bits() {
  local script_path="$1"

  [[ -f "${script_path}" ]] || return 0

  # Oracle still ships sshUserSetup.sh with 1024-bit RSA keys, but OL9's
  # system crypto policy requires RSA keys to be at least 2048 bits.
  if grep -qx 'BITS=1024' "${script_path}"; then
    sed -ri 's/^BITS=1024$/BITS=2048/' "${script_path}"
    log_info "Patched ${script_path} to generate 2048-bit RSA keys"
  elif grep -qx 'BITS=2048' "${script_path}"; then
    log_info "${script_path} already generates 2048-bit RSA keys"
  else
    log_error "unexpected sshUserSetup.sh key-size stanza in ${script_path}"
    exit 1
  fi
}

patch_ssh_user_setup_bits "${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh"
patch_ssh_user_setup_bits "${GI_HOME}/deinstall/sshUserSetup.sh"

chown -R grid:oinstall "${GI_HOME}"
log_success "Grid Infrastructure extracted into ${GI_HOME}"

apply_gi_ru_patch "${GI_HOME}"
