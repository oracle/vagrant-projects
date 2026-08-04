#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 10_gi_installation.sh
#   Run gridSetup.sh in silent mode — software install + cluster/HA
#   configuration up to the point where root scripts must be executed.
#   Runs as the grid user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user grid
for v in GI_HOME GRID_BASE ORA_INVENTORY ORA_LANGUAGES \
         CLUSTER_NAME SCAN_NAME SCAN_PORT \
         NODE1_HOSTNAME NODE1_FQ_HOSTNAME NODE1_FQ_VIPNAME \
         PUBLIC_SUBNET PRIVATE_SUBNET SYS_PASSWORD; do
  require_var "${v}"
done

# Network interface names (ip -br link = portable across OL7/8/9).
net_device1="$(ip -o link show | awk -F': ' 'NR==3 {print $2}' | awk '{print $1}' | sed 's/@.*$//')"
net_device2="$(ip -o link show | awk -F': ' 'NR==4 {print $2}' | awk '{print $1}' | sed 's/@.*$//')"
if [[ -z "${net_device1}" || -z "${net_device2}" ]]; then
  log_error "unable to detect NIC devices (got: '${net_device1}' / '${net_device2}')"
  exit 1
fi

# Data disks (P1 partitions) for the initial DATA diskgroup.
data_disks="$(ls -dm $(asm_disk_glob p1) | tr -d ' \n')"
if [[ -z "${data_disks}" ]]; then
  log_error "no DATA disks found using glob '$(asm_disk_glob p1)'"
  exit 1
fi

# ASM discovery string — restrict it to the P1 PARTITIONS only, never the bare
# '/dev/ORCL_*'. A broad '/dev/ORCL_*' also matches the whole-disk symlinks
# (/dev/ORCL_DISK<n>), and when ASM's discovery opens a whole disk the kernel
# revalidates it and re-reads its partition table (journal: 'vdX: vdX1'). That
# tears down and re-adds the partition device vdX1, so for a brief window the
# /dev/ORCL_DISK<n>_p1 symlink does not exist. root.sh's CREATE DISKGROUP runs
# its discovery inside exactly that window and every '/dev/ORCL_DISK*_p1' spec
# "matches no disks" -> ORA-15031 / DBT-30002, failing ASM config. Matching only
# the partitions means ASM never opens the whole disks, so nothing triggers the
# rescan and the partitions stay stable through diskgroup creation. This string
# flows into crsconfig_params (ASM_DISCOVERY_STRING) and is what root.sh uses.
discovery_string="$(asm_disk_glob p1)"

# --- Assemble rsp parameters ------------------------------------------------
rsp_args=(
  INVENTORY_LOCATION="${ORA_INVENTORY}"
  SELECTED_LANGUAGES="${ORA_LANGUAGES}"
  ORACLE_BASE="${GRID_BASE}"
  oracle.install.option=CRS_CONFIG
  oracle.install.crs.config.scanType=LOCAL_SCAN
  oracle.install.asm.OSDBA=asmdba
  oracle.install.asm.OSOPER=asmoper
  oracle.install.asm.OSASM=asmadmin
  oracle.install.crs.configureGIMR=true
  oracle.install.crs.config.gpnp.scanName="${SCAN_NAME}"
  oracle.install.crs.config.gpnp.scanPort="${SCAN_PORT}"
  oracle.install.crs.config.clusterName="${CLUSTER_NAME}"
  oracle.install.crs.config.clusterNodes="${NODE1_FQ_HOSTNAME}:${NODE1_FQ_VIPNAME}:HUB"
  oracle.install.crs.config.networkInterfaceList="${net_device1}:${PUBLIC_SUBNET}:1,${net_device2}:${PRIVATE_SUBNET}:5"
  oracle.install.crs.config.ClusterConfiguration=STANDALONE
  oracle.install.crs.config.configureAsExtendedCluster=false
  oracle.install.crs.config.gpnp.configureGNS=false
  oracle.install.crs.config.autoConfigureClusterNodeVIP=false
  oracle.install.asm.configureGIMRDataDG=false
  oracle.install.asmOnNAS.configureGIMRDataDG=false
  oracle.install.crs.config.useIPMI=false
  oracle.install.asm.storageOption=ASM
  oracle.install.asm.SYSASMPassword="${SYS_PASSWORD}"
  oracle.install.asm.monitorPassword="${SYS_PASSWORD}"
  oracle.install.asm.diskGroup.name=DATA
  oracle.install.asm.diskGroup.redundancy=EXTERNAL
  oracle.install.asm.diskGroup.AUSize=4
  oracle.install.asm.diskGroup.disks="${data_disks}"
  oracle.install.asm.diskGroup.diskDiscoveryString="${discovery_string}"
  oracle.install.asm.gimrDG.AUSize=1
  oracle.install.crs.configureRHPS=false
  oracle.install.crs.config.ignoreDownNodes=false
  oracle.install.config.managementOption=NONE
  oracle.install.config.omsPort=0
  oracle.install.crs.rootconfig.executeRootScript=false
)


gridsetup_args=( -ignorePrereq -waitforcompletion -silent )

# Only patch when an RU is configured. 07_extract_gi.sh records GI_RU_PATCH_DIR
# in the runtime env once it has staged the RU, and leaves it unset otherwise —
# gridSetup rejects an empty -applyRU, so the flag has to disappear entirely.
if [[ -n "${GI_RU_PATCH_DIR:-}" ]]; then
  log_info "Applying GI RU ${GI_RU_PATCH_DIR##*/} during gridSetup"
  gridsetup_args+=( -applyRU "${GI_RU_PATCH_DIR}" )
else
  log_info "No Release Update configured; installing GI at base release"
fi

log_section "Running gridSetup.sh (silent, -ignorePrereq)"

# gridSetup.sh exit codes:
#   0  success
#   6  success with warnings (typical when -ignorePrereq bypasses checks)
if "${GI_HOME}/gridSetup.sh" \
     "${gridsetup_args[@]}" \
     -responseFile "${GI_HOME}/install/response/gridsetup.rsp" \
     "${rsp_args[@]}"; then
  rc=0
else
  rc=$?
fi

case "${rc}" in
  0) log_success "gridSetup.sh completed successfully" ;;
  6) log_info    "gridSetup.sh completed with warnings (exit=6) — expected when -ignorePrereq is set" ;;
  *) log_error   "gridSetup.sh failed with exit=${rc}"; exit "${rc}" ;;
esac
