#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 13_make_reco_dg.sh
#   Ensure the +DATA diskgroup is mounted and create +RECO using the P2
#   partitions of each shared disk. Runs as the grid user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user grid
for v in GI_HOME GI_VERSION DB_VERSION NODE2_HOSTNAME; do
  require_var "${v}"
done

export ORACLE_HOME="${GI_HOME}"
export ORACLE_SID='+ASM1'

data_discovery_string="$(asm_disk_glob p1)"
reco_discovery_string="$(asm_disk_glob p2)"

# Build the SQL DISK clauses — one entry per ASM device.
declare -a data_disk_devices=()
for d in ${data_discovery_string}; do
  [[ -e "${d}" ]] || continue
  data_disk_devices+=("${d}")
done

if (( ${#data_disk_devices[@]} == 0 )); then
  log_error "no P1 devices found for DATA"
  exit 1
fi

declare -a reco_disk_devices=()
for d in ${reco_discovery_string}; do
  [[ -e "${d}" ]] || continue
  reco_disk_devices+=("${d}")
done

if (( ${#reco_disk_devices[@]} == 0 )); then
  log_error "no P2 devices found for RECO"
  exit 1
fi

build_disk_clause() {
  # No per-disk FORCE: the DROP DISKGROUP ... FORCE path in ensure_diskgroup
  # already wipes stale ASM headers, leaving the disks in CANDIDATE state. Oracle
  # then rejects FORCE on CANDIDATE disks with ORA-15034.
  local disk_clause=''
  local dev
  for dev in "$@"; do
    disk_clause+="  '${dev}',\n"
  done
  disk_clause="${disk_clause%,\\n}"
  printf '%b' "${disk_clause}"
}

data_disk_clause="$(build_disk_clause "${data_disk_devices[@]}")"
reco_disk_clause="$(build_disk_clause "${reco_disk_devices[@]}")"

compat_asm="${GI_VERSION}"
compat_rdbms="${DB_VERSION}"

log_info "Expanding ASM disk discovery to '${data_discovery_string}' and '${reco_discovery_string}'"
ensure_diskgroup() {
  local diskgroup_name="$1"
  local redundancy="$2"
  local content_type="$3"
  local disk_clause="$4"

  log_section "Ensuring +${diskgroup_name} diskgroup (${redundancy} redundancy)"
  "${GI_HOME}/bin/sqlplus" -S / as sysasm <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET ECHO ON
SET SERVEROUTPUT ON
DECLARE
  mounted_count PLS_INTEGER := 0;
BEGIN
  SELECT COUNT(*)
    INTO mounted_count
    FROM v\$asm_diskgroup
   WHERE name = '${diskgroup_name}'
     AND state = 'MOUNTED';

  IF mounted_count = 0 THEN
    BEGIN
      EXECUTE IMMEDIATE 'ALTER DISKGROUP ${diskgroup_name} MOUNT';
      DBMS_OUTPUT.PUT_LINE('Mounted existing diskgroup ${diskgroup_name}.');
    EXCEPTION
      WHEN OTHERS THEN
        -- MOUNT may fail because the diskgroup doesn't exist (ORA-15001) or
        -- because stale/incomplete headers block assembly (ORA-15017/15040).
        -- In the Vagrant context the shared disks are disposable, so drop any
        -- phantom registration and recreate; DISK ... FORCE in the CREATE
        -- clause overwrites any stale headers on the devices themselves.
        DBMS_OUTPUT.PUT_LINE('MOUNT of ${diskgroup_name} failed (SQLCODE=' || SQLCODE || '); recreating.');
        BEGIN
          EXECUTE IMMEDIATE 'DROP DISKGROUP ${diskgroup_name} FORCE INCLUDING CONTENTS';
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        EXECUTE IMMEDIATE q'[
CREATE DISKGROUP ${diskgroup_name} ${redundancy} REDUNDANCY
 DISK
${disk_clause}
 ATTRIBUTE
   'compatible.asm'   = '${compat_asm}',
   'compatible.rdbms' = '${compat_rdbms}',
   'sector_size'      = '512',
   'AU_SIZE'          = '4M',
   'content.type'     = '${content_type}'
]';
        DBMS_OUTPUT.PUT_LINE('Created diskgroup ${diskgroup_name}.');
    END;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Diskgroup ${diskgroup_name} is already mounted.');
  END IF;
END;
/
EXIT;
EOF
}

log_section "Ensuring ASM disk discovery and diskgroups"
"${GI_HOME}/bin/sqlplus" -S / as sysasm <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET ECHO ON
ALTER SYSTEM SET asm_diskstring='${data_discovery_string}','${reco_discovery_string}' SCOPE=BOTH SID='*';
EXIT;
EOF

ensure_diskgroup DATA EXTERNAL data "${data_disk_clause}"
ensure_diskgroup RECO NORMAL recovery "${reco_disk_clause}"

ensure_remote_diskgroups_mounted() {
  local host="$1"
  local asm_sid="$2"

  log_section "Ensuring ASM diskgroups are mounted on ${host}"
  ssh -o StrictHostKeyChecking=no "${host}" \
    env ORACLE_HOME="${GI_HOME}" ORACLE_SID="${asm_sid}" \
    "${GI_HOME}/bin/sqlplus" -S / as sysasm <<'EOF'
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET ECHO ON
SET SERVEROUTPUT ON
DECLARE
  PROCEDURE ensure_mounted(p_diskgroup IN VARCHAR2) IS
    mounted_count PLS_INTEGER := 0;
  BEGIN
    SELECT COUNT(*)
      INTO mounted_count
      FROM v$asm_diskgroup
     WHERE name = p_diskgroup
       AND state = 'MOUNTED';

    IF mounted_count = 0 THEN
      EXECUTE IMMEDIATE 'ALTER DISKGROUP ' || p_diskgroup || ' MOUNT';
      DBMS_OUTPUT.PUT_LINE('Mounted diskgroup ' || p_diskgroup || '.');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Diskgroup ' || p_diskgroup || ' is already mounted.');
    END IF;
  END;
BEGIN
  ensure_mounted('DATA');
  ensure_mounted('RECO');
END;
/
EXIT;
EOF
}

ensure_remote_diskgroups_mounted "${NODE2_HOSTNAME}" '+ASM2'

log_success "ASM diskgroups DATA and RECO are ready"
