#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 10_setup_autostart.sh
#   Install start/stop scripts + systemd unit for the database.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var DB_NAME
require_var DB_HOME

log_section "Installing oracle dbstart/dbshut helper scripts"
# NB: scripts must live OUTSIDE /home. On RHEL/OL with SELinux enforcing,
# files under /home get a *_home_t label that systemd (init_t) is not allowed
# to execute, which fails as status=203/EXEC "Permission denied".
SCRIPT_DIR=/opt/oracle/scripts
install -d -o oracle -g oinstall -m 0755 "${SCRIPT_DIR}"

cat > "${SCRIPT_DIR}/start_all.sh" <<'EOF'
#!/usr/bin/env bash
# NB: no 'set -u' here — sourcing /etc/profile references interactive-only
# vars (e.g. HISTCONTROL) that are unset under systemd and would abort nounset.
set -eo pipefail
. /home/oracle/.bash_profile
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbstart "${ORACLE_HOME}"
EOF

cat > "${SCRIPT_DIR}/stop_all.sh" <<'EOF'
#!/usr/bin/env bash
# NB: no 'set -u' here — sourcing /etc/profile references interactive-only
# vars (e.g. HISTCONTROL) that are unset under systemd and would abort nounset.
set -eo pipefail
. /home/oracle/.bash_profile
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbshut "${ORACLE_HOME}"
EOF

chown oracle:oinstall "${SCRIPT_DIR}/start_all.sh" "${SCRIPT_DIR}/stop_all.sh"
chmod 0755             "${SCRIPT_DIR}/start_all.sh" "${SCRIPT_DIR}/stop_all.sh"

# Ensure correct SELinux labels so systemd may execute the helpers.
if command -v restorecon >/dev/null 2>&1; then
  restorecon -R "${SCRIPT_DIR}"
fi

log_section "Writing /etc/systemd/system/dbora.service"
cat > /etc/systemd/system/dbora.service <<EOF
[Unit]
Description=Oracle Database Service
After=syslog.target network-online.target
Wants=network-online.target

[Service]
# systemd ignores PAM limits — set explicitly.
LimitMEMLOCK=infinity
LimitNOFILE=65535
Type=oneshot
RemainAfterExit=yes
User=oracle
Group=oinstall
Restart=no
ExecStart=${SCRIPT_DIR}/start_all.sh
ExecStop=${SCRIPT_DIR}/stop_all.sh

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 /etc/systemd/system/dbora.service

log_section "Writing /etc/oratab"
cat > /etc/oratab <<EOF
${DB_NAME}:${DB_HOME}:Y
EOF
chown oracle:oinstall /etc/oratab
chmod 0664             /etc/oratab

log_section "Enabling dbora.service"
systemctl daemon-reload
systemctl enable dbora.service >/dev/null
