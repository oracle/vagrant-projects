#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 07_extract_gi.sh
#   Extract the Grid Infrastructure zip into GI_HOME. The Vagrantfile has already
#   verified every installer checksum by the time this runs.
#   Runs on the node that owns the GI install (node1 for a two-node cluster,
#   the sole node for a single-node cluster).
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
chown -R grid:oinstall "${GI_HOME}"
log_success "Grid Infrastructure extracted into ${GI_HOME}"

apply_gi_ru_patch "${GI_HOME}"
