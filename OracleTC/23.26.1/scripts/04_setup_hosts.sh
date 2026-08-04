#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 04_setup_hosts.sh
#   Writes /etc/hosts with the public + private addresses for the True Cache
#   node, and a minimal /etc/resolv.conf. Re-runnable.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
for v in NODE1_PUBLIC_IP NODE1_PRIV_IP \
         NODE1_HOSTNAME NODE1_FQ_HOSTNAME \
         NODE1_PRIVNAME NODE1_FQ_PRIVNAME \
         DOMAIN_NAME; do
  require_var "${v}"
done

log_section "Writing /etc/hosts"
cat > /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Public host info
${NODE1_PUBLIC_IP}  ${NODE1_FQ_HOSTNAME}  ${NODE1_HOSTNAME}

# Private host info
${NODE1_PRIV_IP}    ${NODE1_FQ_PRIVNAME}  ${NODE1_PRIVNAME}
EOF

log_section "Writing /etc/resolv.conf"
{
  printf 'search %s\n' "${DOMAIN_NAME}"
  # Only add a nameserver when one was configured (public network mode).
  if [[ -n "${DNS_PUBLIC_IP:-}" ]]; then
    printf 'nameserver %s\n' "${DNS_PUBLIC_IP}"
  fi
} > /etc/resolv.conf
