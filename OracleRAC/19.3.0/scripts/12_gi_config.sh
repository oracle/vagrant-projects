#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 12_gi_config.sh
#   Run gridSetup.sh -executeConfigTools to finalise the cluster (or ORestart)
#   configuration after the root scripts have completed.
#   Runs as the grid user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user grid
for v in GI_HOME GRID_BASE ORA_INVENTORY ORA_LANGUAGES \
         CLUSTER_NAME SCAN_NAME SCAN_PORT \
         NOMGMTDB ORESTART SYS_PASSWORD; do
  require_var "${v}"
done

data_disks="$(ls -dm $(asm_disk_glob p1) | tr -d ' \n')"
# Partitions only: if the whole-disk /dev/ORCL_DISK<n> links are in the
# discovery set, ASM opens them read-write and udev re-reads the partition
# table on close, so the _p1/_p2 nodes briefly vanish mid-discovery.
discovery_string='/dev/ORCL_DISK*_p*'

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

if [[ "${ORESTART}" == "true" ]]; then
  rsp_args+=(oracle.install.option=HA_CONFIG)
else
  rsp_args+=(
    oracle.install.option=CRS_CONFIG
    oracle.install.crs.config.scanType=LOCAL_SCAN
    oracle.install.crs.config.gpnp.scanName="${SCAN_NAME}"
    oracle.install.crs.config.gpnp.scanPort="${SCAN_PORT}"
    oracle.install.crs.config.clusterName="${CLUSTER_NAME}"
  )
fi

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

# INS-43080 above only says "some assistant failed"; it does not say which.
# The one nothing downstream can live without is asmca, so confirm that it
# really left the DATA diskgroup online instead of letting a later step trip
# over a missing ASM instance (ORA-01034 in 13_make_reco_dg.sh).
log_section "Verifying the DATA diskgroup is online"
export ORACLE_HOME="${GI_HOME}"
dg_status="$("${GI_HOME}/bin/srvctl" status diskgroup -diskgroup DATA 2>&1 || true)"
log_info "${dg_status}"
if ! grep -q 'is running' <<<"${dg_status}"; then
  log_error "DATA diskgroup is not online: the ASM configuration assistant (asmca) failed"
  asmca_log="$(ls -t "${GRID_BASE}"/cfgtoollogs/asmca/asmca-*.log 2>/dev/null | head -n 1 || true)"
  if [[ -n "${asmca_log}" ]]; then
    log_error "asmca errors from ${asmca_log}:"
    grep -E '^(ORA|DBT|PRC[A-Z]|CRS)-[0-9]+|\[FATAL\]' "${asmca_log}" | sort -u >&2 || true
  fi
  log_error "installer logs: $(ls -dt "${ORA_INVENTORY}"/logs/GridSetupActions* 2>/dev/null | head -n 1 || true)"
  exit 1
fi
log_success "DATA diskgroup is online"
