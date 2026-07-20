#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 17_Setup_FPP.sh
#   Setup FPP server
#   Runs as root; drops to the grid user for asmcmd.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
for v in GI_HOME GI_VERSION GNS_IP HA_VIP; do
  require_var "${v}"
done

log_section "Setting DATA disk group compatible.asm to ${GI_VERSION}"
su - grid -c "'${GI_HOME}/bin/asmcmd' setattr -G DATA compatible.asm '${GI_VERSION}'"

log_section "Adding and starting GNS (vip=${GNS_IP})"
"${GI_HOME}/bin/srvctl" add gns -vip "${GNS_IP}"
"${GI_HOME}/bin/srvctl" start gns

log_section "Adding RHP HAVIP (address=${HA_VIP})"
"${GI_HOME}/bin/srvctl" add havip -id rhphavip -address "${HA_VIP}"

# Replace the default rhpserver resource with one backed by /rhp_storage.
# The stop/remove may be a no-op on a fresh install (if the resource isn't
# registered or isn't running), so don't let them abort the ERR trap.
log_section "Reconfiguring rhpserver on /rhp_storage (DATA)"
"${GI_HOME}/bin/srvctl" stop rhpserver   || true
"${GI_HOME}/bin/srvctl" remove rhpserver || true
"${GI_HOME}/bin/srvctl" add rhpserver -storage /rhp_storage -diskgroup DATA
"${GI_HOME}/bin/srvctl" start rhpserver
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------
