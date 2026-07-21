#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 09_TrueCache_setup.sh
#   Creates the Oracle True Cache instance:
#     * stages the source-DB password file,
#     * writes the instance pfile with TRUE_CACHE=true,
#     * starts the instance NOMOUNT and issues CREATE TRUE CACHE,
#     * verifies the instance opens READ ONLY WITH APPLY.
#
#   Runs as the oracle user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
require_var DB_HOME
require_var INSTANCE_NAME
require_var DB_FILES
require_var DB_UNIQUE_NAME
require_var FAL_CLIENT
require_var FAL_SERVER
require_var LOCAL_LISTENER
require_var SGA_TARGET
require_var SDB_HOST_NAME
require_var SDB_SERVICE_NAME
require_var SDB_SERVICE_PORT

export ORACLE_HOME="${DB_HOME}"
export ORACLE_SID="${INSTANCE_NAME}"

log_section "Managing SDB password file"
shopt -s nullglob
sdb_pwfiles=( /vagrant/SDB_files/orapw* )
shopt -u nullglob
if (( ${#sdb_pwfiles[@]} == 0 )); then
  log_error "no source-DB password file found under /vagrant/SDB_files/ (expected orapw<SID>)"
  exit 1
fi
cp "${sdb_pwfiles[0]}" "${DB_HOME}/dbs/orapw${INSTANCE_NAME}"

log_section "Writing instance pfile"
pfile="${DB_HOME}/dbs/init_${INSTANCE_NAME}.ora"
cat > "${pfile}" <<EOF
*.DB_CREATE_FILE_DEST=/u02/oradata
*.DB_FILES=${DB_FILES}
*.DB_UNIQUE_NAME=${DB_UNIQUE_NAME}
*.INSTANCE_NAME=${INSTANCE_NAME}
*.ENABLE_PLUGGABLE_DATABASE=TRUE
*.FAL_CLIENT=${FAL_CLIENT}
*.FAL_SERVER=${FAL_SERVER}
*.LOCAL_LISTENER=${LOCAL_LISTENER}
*.SGA_TARGET=${SGA_TARGET}G
*.TRUE_CACHE=true
EOF

log_section "Starting True Cache instance (NOMOUNT)"
"${DB_HOME}/bin/sqlplus" -s / as sysdba <<EOF
STARTUP NOMOUNT PFILE=${pfile}
exit;
EOF

log_info "Waiting 30 seconds for the instance to settle..."
sleep 30

# Query DATABASE_ROLE / OPEN_MODE. Captured (not piped) so a non-match never
# trips the shared ERR trap; '|| true' guards the rare sqlplus non-zero exit.
tc_query_state() {
  "${DB_HOME}/bin/sqlplus" -s / as sysdba <<'EOF' || true
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT DATABASE_ROLE || ' / ' || OPEN_MODE FROM V$DATABASE;
exit;
EOF
}

log_section "Creating True Cache"
# CREATE TRUE CACHE reaches out to the source (primary) database. Early in
# provisioning that connection can transiently fail — ORA-61857 /
# 'ORA-61852: CREATE TRUE CACHE failed' with an underlying TNS-12541 'no
# listener' — when the source DB listener is not reachable yet. It succeeds on a
# later retry, so attempt it in a loop instead of failing the whole provision.
# Before each retry we re-check the live state: if a previous attempt actually
# created the cache (partial success, or a re-provision), we stop and treat it as
# done rather than erroring on "already a True Cache".
create_attempts=10
create_delay=30
created=0
for (( attempt=1; attempt<=create_attempts; attempt++ )); do
  log_info "CREATE TRUE CACHE attempt ${attempt}/${create_attempts}"
  if "${DB_HOME}/bin/sqlplus" -s / as sysdba <<'EOF'
WHENEVER SQLERROR EXIT FAILURE
CREATE TRUE CACHE;
exit;
EOF
  then
    created=1
    log_success "CREATE TRUE CACHE succeeded on attempt ${attempt}"
    break
  fi

  # The statement errored — but it may already be a True Cache from an earlier
  # attempt. Confirm against the live state before deciding to retry.
  if grep -q 'READ ONLY WITH APPLY' <<< "$(tc_query_state)"; then
    created=1
    log_success "True Cache already present — treating CREATE TRUE CACHE as done"
    break
  fi

  if (( attempt < create_attempts )); then
    log_info "CREATE TRUE CACHE not ready yet (source DB '${SDB_SERVICE_NAME}' at ${SDB_HOST_NAME}:${SDB_SERVICE_PORT} may be unreachable); waiting ${create_delay}s before retry"
    sleep "${create_delay}"
  fi
done

if (( created == 0 )); then
  log_error "CREATE TRUE CACHE failed after ${create_attempts} attempts — verify the source database '${SDB_SERVICE_NAME}' (${SDB_HOST_NAME}:${SDB_SERVICE_PORT}) listener/service is reachable from this node"
  exit 1
fi

log_section "Checking True Cache instance state"
ready=0
for (( check=1; check<=6; check++ )); do
  tc_state="$(tc_query_state)"
  log_info "V\$DATABASE reports: ${tc_state}"
  if grep -q 'READ ONLY WITH APPLY' <<< "${tc_state}"; then
    ready=1
    break
  fi
  sleep 10
done

if (( ready == 1 )); then
  log_success "True Cache instance is ready!"
else
  log_error "True Cache instance did not reach 'READ ONLY WITH APPLY' — check the source DB configuration and alert log"
fi

# /etc/oratab is written (as root, with correct ownership) by 09_setup_autostart.sh.
