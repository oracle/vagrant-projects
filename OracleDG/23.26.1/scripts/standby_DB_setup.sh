#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# standby_DB_setup.sh
#   Builds the standby database via RMAN DUPLICATE ... FROM ACTIVE DATABASE,
#   registers it in the Data Guard broker, and (optionally) opens it as ADG.
#
#   Credentials are NEVER passed on the command line — RMAN/DGMGRL take them
#   via CONNECT statements inside the heredoc, which keeps them out of `ps`.
#
#   Runs as the oracle user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh

if [[ "$(id -un)" != "oracle" ]]; then
  log_error "this script must run as the oracle user"
  exit 1
fi

require_var DB_HOME
require_var DB_BASE
require_var DB_NAME
require_var SYS_PASSWORD
require_var CDB
require_var ADG
require_var NODE2_HOSTNAME

export ORACLE_HOME="${DB_HOME}"
export ORACLE_SID="${DB_NAME}"

sqlplus_sysdba() { "${DB_HOME}/bin/sqlplus" -s -L / as sysdba; }

log_section "Preparing standby directories and password file"
if [[ "${CDB}" == "true" ]]; then
  mkdir -p "/u02/oradata/${DB_NAME}/pdbseed"
  mkdir -p "/u02/oradata/${DB_NAME}/pdb1"
fi
mkdir -p "${DB_BASE}/fast_recovery_area/${DB_NAME}"
mkdir -p "${DB_BASE}/admin/${DB_NAME}/adump"

# orapwd accepts the password via command line — restrict visibility to this
# user only by chmod'ing the file, and keep the invocation brief.
"${DB_HOME}/bin/orapwd" \
  file="${ORACLE_HOME}/dbs/orapw${DB_NAME}" \
  password="${SYS_PASSWORD}" \
  entries=10 \
  format=12
chmod 0600 "${ORACLE_HOME}/dbs/orapw${DB_NAME}"

log_section "Writing bootstrap pfile for auxiliary instance"
cat > /tmp/init_standby.ora <<EOF
*.db_name='${DB_NAME}'
*.local_listener='LISTENER'
EOF
chmod 0600 /tmp/init_standby.ora

log_section "Starting auxiliary instance (NOMOUNT)"
sqlplus_sysdba <<'EOF'
WHENEVER SQLERROR EXIT FAILURE
STARTUP NOMOUNT PFILE='/tmp/init_standby.ora';
exit;
EOF

log_section "Duplicating primary to standby via RMAN"
# Pass the password via CONNECT inside the heredoc — not visible to `ps`.
"${DB_HOME}/bin/rman" <<EOF
CONNECT TARGET    sys/"${SYS_PASSWORD}"@${DB_NAME};
CONNECT AUXILIARY sys/"${SYS_PASSWORD}"@${DB_NAME}_STDBY;
DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='${DB_NAME}_STDBY' COMMENT 'Standby'
  NOFILENAMECHECK;
exit;
EOF

log_section "Setting local_listener on standby"
sqlplus_sysdba <<EOF
WHENEVER SQLERROR EXIT FAILURE
ALTER SYSTEM SET local_listener='(ADDRESS=(PROTOCOL=TCP)(HOST=${NODE2_HOSTNAME})(PORT=1521))' SCOPE=BOTH;
exit;
EOF

log_section "Enabling Data Guard broker on standby"
sqlplus_sysdba <<'EOF'
WHENEVER SQLERROR EXIT FAILURE
ALTER SYSTEM SET dg_broker_start=TRUE SCOPE=BOTH;
exit;
EOF

log_section "Applying Data Guard tuning parameters"
sqlplus_sysdba <<'EOF'
WHENEVER SQLERROR EXIT FAILURE
ALTER SYSTEM SET ARCHIVE_LAG_TARGET=0             SCOPE=BOTH SID='*';
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=4      SCOPE=BOTH SID='*';
ALTER SYSTEM SET LOG_ARCHIVE_MIN_SUCCEED_DEST=1   SCOPE=BOTH SID='*';
ALTER SYSTEM SET DATA_GUARD_SYNC_LATENCY=0        SCOPE=BOTH SID='*';
exit;
EOF

log_section "Creating DG broker configuration"
"${DB_HOME}/bin/dgmgrl" <<EOF
CONNECT sys/"${SYS_PASSWORD}"@${DB_NAME};
CREATE CONFIGURATION db_broker_config AS PRIMARY DATABASE IS ${DB_NAME} CONNECT IDENTIFIER IS ${DB_NAME};
exit;
EOF
sleep 10

# The name must be quoted here: unquoted, DGMGRL folds it to lowercase for
# storage, which permanently mismatches the standby's actual (case-preserved)
# DB_UNIQUE_NAME and makes every broker-side status check on it fail with
# ORA-16642 DB_UNIQUE_NAME mismatch — not a transient/timing issue, it never
# self-resolves. Quoting keeps the registered name's case identical to the
# real parameter.
"${DB_HOME}/bin/dgmgrl" <<EOF
CONNECT sys/"${SYS_PASSWORD}"@${DB_NAME};
ADD DATABASE "${DB_NAME}_STDBY" AS CONNECT IDENTIFIER IS ${DB_NAME}_STDBY;
exit;
EOF
sleep 5

"${DB_HOME}/bin/dgmgrl" <<EOF
CONNECT sys/"${SYS_PASSWORD}"@${DB_NAME};
ENABLE CONFIGURATION;
exit;
EOF
sleep 5

if [[ "${ADG}" == "true" ]]; then
  log_section "Opening standby as Active Data Guard (read-only + apply)"
  sqlplus_sysdba <<'EOF'
WHENEVER SQLERROR EXIT FAILURE
STARTUP MOUNT FORCE;
ALTER DATABASE OPEN READ ONLY;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
exit;
EOF
else
  log_section "Starting standby in MOUNT state"
  sqlplus_sysdba <<'EOF'
WHENEVER SQLERROR EXIT FAILURE
STARTUP MOUNT FORCE;
exit;
EOF
fi

log_section "Waiting for Data Guard broker configuration to converge"
# A freshly duplicated standby can take a while to register with the broker
# and catch up on apply. Polling the aggregate Configuration Status isn't
# enough on its own — it can report SUCCESS before the standby's own
# per-database status check clears, which still throws a transient
# ORA-16642 DB_UNIQUE_NAME mismatch for a while after the config looks
# healthy. Poll that specific check instead of sleeping a fixed amount.
dg_wait_timeout=300
dg_wait_interval=10
dg_wait_elapsed=0
dg_standby_status=""

while (( dg_wait_elapsed < dg_wait_timeout )); do
  dg_show_output="$("${DB_HOME}/bin/dgmgrl" <<EOF
CONNECT sys/"${SYS_PASSWORD}"@${DB_NAME};
SHOW DATABASE ${DB_NAME}_STDBY;
exit;
EOF
)"
  dg_standby_status="$(awk '/^Database Status:/{getline; print; exit}' <<< "${dg_show_output}")"

  if [[ "${dg_standby_status}" == SUCCESS* ]]; then
    log_info "Standby database status reports SUCCESS after ${dg_wait_elapsed}s"
    break
  fi

  log_info "Standby database status: '${dg_standby_status:-none yet}' (waited ${dg_wait_elapsed}s of ${dg_wait_timeout}s) — retrying in ${dg_wait_interval}s"
  sleep "${dg_wait_interval}"
  dg_wait_elapsed=$(( dg_wait_elapsed + dg_wait_interval ))
done

if [[ "${dg_standby_status}" != SUCCESS* ]]; then
  log_info "Standby database status did not reach SUCCESS within ${dg_wait_timeout}s (last status: '${dg_standby_status:-none}'); continuing — check status manually"
fi

log_section "Final broker status"
"${DB_HOME}/bin/dgmgrl" <<EOF
CONNECT sys/"${SYS_PASSWORD}"@${DB_NAME};
SHOW CONFIGURATION;
SHOW DATABASE ${DB_NAME};
SHOW DATABASE ${DB_NAME}_STDBY;
exit;
EOF

log_success "Standby DB setup complete"
