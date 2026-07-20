#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 18_configure_root_ssh.sh
#   Idempotently set sshd's PermitRootLogin policy. Used by setup.sh to keep
#   password-based root SSH available only during SEHA bootstrap, then switch
#   back to key-only once root SSH equivalence is established.
#
#   Args:
#     $1 = PermitRootLogin mode (yes | prohibit-password)
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

if [[ $# -ne 1 ]]; then
  log_error "usage: $0 <yes|prohibit-password>"
  exit 1
fi

mode="$1"
sshd_config='/etc/ssh/sshd_config'
sshd_dropin_dir='/etc/ssh/sshd_config.d'
sshd_override="${sshd_dropin_dir}/00-oracle-seha-bootstrap.conf"

case "${mode}" in
  yes|prohibit-password) ;;
  *)
    log_error "unsupported PermitRootLogin mode '${mode}'"
    exit 1
    ;;
esac

set_sshd_option() {
  local key="$1" value="$2"
  if grep -Eq "^[#[:space:]]*${key}[[:space:]]+" "${sshd_config}"; then
    sed -ri "s/^[#[:space:]]*${key}[[:space:]]+.*/${key} ${value}/" "${sshd_config}"
  else
    printf '\n%s %s\n' "${key}" "${value}" >> "${sshd_config}"
  fi
}

sshd_uses_dropins() {
  grep -Eq '^[#[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf([[:space:]]|$)' "${sshd_config}"
}

# Keep PasswordAuthentication in lock-step with PermitRootLogin. The bootstrap
# provisioner turned it on so sshUserSetup.sh could seed keys; once we're in
# prohibit-password mode the whole cluster is key-only and password SSH for
# oracle/grid would just be an unnecessary attack surface.
case "${mode}" in
  yes)               password_mode='yes' ;;
  prohibit-password) password_mode='no'  ;;
esac

if sshd_uses_dropins; then
  mkdir -p "${sshd_dropin_dir}"
  cat > "${sshd_override}" <<EOF
# Managed by the Oracle SEHA Vagrant provisioner.
# On OL9, sshd commonly reads sshd_config.d before later directives in the main
# config, and the first value wins. Keep the bootstrap toggle in an early
# drop-in so password auth really changes for the provisioning window.
PermitRootLogin ${mode}
PasswordAuthentication ${password_mode}
EOF
  chmod 0644 "${sshd_override}"
else
  set_sshd_option PermitRootLogin "${mode}"
  set_sshd_option PasswordAuthentication "${password_mode}"
fi

/usr/sbin/sshd -t -f "${sshd_config}"
systemctl restart sshd

log_success "Configured sshd: PermitRootLogin ${mode}"
