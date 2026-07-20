#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 12_gi_config.sh
#   Run gridSetup.sh -executeConfigTools to finalise the SEHA cluster
#   configuration after the root scripts have completed.
#   Runs as the grid user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user grid
for v in GI_HOME GRID_BASE ORA_INVENTORY ORA_LANGUAGES \
         CLUSTER_NAME SCAN_NAME SCAN_PORT \
         NOMGMTDB SYS_PASSWORD; do
  require_var "${v}"
done

data_disks="$(ls -dm $(asm_disk_glob p1) | tr -d ' \n')"
if [[ -z "${data_disks}" ]]; then
  log_error "no DATA disks found using glob '$(asm_disk_glob p1)'"
  exit 1
fi
# asm_diskstring must cover every partition any diskgroup is built from, not
# just DATA's: RECO is created later from the P2 partitions, and ASM rejects a
# CREATE DISKGROUP path outside its discovery set with ORA-15014.
discovery_string="$(asm_disk_glob all)"

log_info "Using ASM discovery string '${discovery_string}'"
log_info "Using ASM DATA disks '${data_disks}'"

rsp_args=(
  INVENTORY_LOCATION="${ORA_INVENTORY}"
  SELECTED_LANGUAGES="${ORA_LANGUAGES}"
  ORACLE_BASE="${GRID_BASE}"
  oracle.install.asm.OSDBA=asmdba
  oracle.install.asm.OSOPER=asmoper
  oracle.install.asm.OSASM=asmadmin
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

rsp_args+=(
  oracle.install.option=CRS_CONFIG
  oracle.install.crs.config.scanType=LOCAL_SCAN
  oracle.install.crs.config.gpnp.scanName="${SCAN_NAME}"
  oracle.install.crs.config.gpnp.scanPort="${SCAN_PORT}"
  oracle.install.crs.config.clusterName="${CLUSTER_NAME}"
)

if [[ "${NOMGMTDB}" == "true" ]]; then
  rsp_args+=(oracle_install_crs_ConfigureMgmtDB=false)
else
  rsp_args+=(oracle_install_crs_ConfigureMgmtDB=true)
fi

log_section "Running gridSetup.sh -executeConfigTools"
gridsetup_log="$(mktemp /tmp/gridSetup-executeConfigTools.XXXXXX.log)"
if "${GI_HOME}/gridSetup.sh" \
     -silent -executeConfigTools \
     -responseFile "${GI_HOME}/install/response/gridsetup.rsp" \
     "${rsp_args[@]}" 2>&1 | tee "${gridsetup_log}"; then
  rc=0
else
  rc=$?
fi

case "${rc}" in
  0) log_success "gridSetup.sh -executeConfigTools completed" ;;
  6) log_info    "gridSetup.sh -executeConfigTools completed with warnings (exit=6)" ;;
  255)
    if grep -Fq '[INS-43080]' "${gridsetup_log}" \
       && grep -Fq 'Some of the configuration assistants failed, were cancelled or skipped.' "${gridsetup_log}"; then
      log_info "gridSetup.sh -executeConfigTools reported INS-43080 (exit=255); continuing and letting subsequent GI checks validate the stack"
    else
      log_error "gridSetup.sh -executeConfigTools failed with exit=${rc}"
      exit "${rc}"
    fi
    ;;
  *) log_error   "gridSetup.sh -executeConfigTools failed with exit=${rc}"; exit "${rc}" ;;
esac
