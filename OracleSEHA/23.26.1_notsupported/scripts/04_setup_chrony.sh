#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 04_setup_chrony.sh
#   Disable chronyd (and any stray ntpd) so Oracle's Cluster Time
#   Synchronization Service (CTSS) runs in *active* mode — the only
#   configuration that satisfies CVU PRVG-13606 on an isolated lab where
#   no external NTP peer is reachable.
#
#   Why not 'local stratum 10'?
#     chronyc tracking reports Leap=Normal with that, but the 23.26.1 CVU
#     post-crsinst check inspects the Reference ID and rejects local
#     refclocks — PRVG-13606 still fires.
#
#   Why not node-to-node peering?
#     With both nodes self-stratum 10, chrony's source selector won't prefer
#     the peer over its own local clock, so node1 at least keeps reporting
#     a local refid and CVU fails on that node.
#
#   CTSS active mode is what Oracle's own cluster Vagrant projects use, and is
#   documented as the intended path when no external time source exists.
#
#   CRITICAL: this must run BEFORE GI root.sh / executeConfigTools. CTSS's
#   mode (observer vs active) is latched at CRS startup based on whether a
#   time daemon is active at that moment. If chronyd is already running when
#   CRS starts, CTSS registers as observer and this fix won't help without
#   a CRS restart.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

log_section "Stopping, disabling and masking chronyd / ntpd"
# mask prevents dbus / socket-activation from waking the service back up —
# without this, a stray `systemctl start chronyd` (or socket activation on
# OL9) can bring chronyd up after CRS has already latched CTSS into
# observer mode.
for svc in chronyd ntpd ntp; do
  systemctl stop    "${svc}" 2>/dev/null || true
  systemctl disable "${svc}" 2>/dev/null || true
  systemctl mask    "${svc}" 2>/dev/null || true
done

log_section "Removing time-daemon config files cluvfy inspects"
# cluvfy's clocksync check probes both the systemd unit *and* the on-disk
# config. Leaving /etc/chrony.conf or /etc/ntp.conf behind makes it
# conclude a daemon "should" be running and flips the check from
# "CTSS fallback" to PRVG-13606.
#
# Rename rather than delete so an operator can still see the originals if
# they ever want to re-enable chrony/ntp.
for cfg in /etc/chrony.conf /etc/ntp.conf; do
  if [[ -f "${cfg}" && ! -f "${cfg}.rac-backup" ]]; then
    mv "${cfg}" "${cfg}.rac-backup"
  fi
  rm -f "${cfg}"
done
# /etc/sysconfig/{chronyd,ntpd} are options files; cluvfy doesn't parse
# them but leaving them can confuse later re-provisioning.
rm -f /etc/sysconfig/chronyd /etc/sysconfig/ntpd /etc/sysconfig/ntpdate 2>/dev/null || true
# Drift/keys files — harmless on their own but part of a "chrony is
# configured" signal an unlucky CVU release might read.
rm -f /var/lib/chrony/drift /etc/chrony.keys 2>/dev/null || true

log_section "Removing stale runtime artefacts (pid / socket)"
# If CTSS sees a lingering pid/socket at CRS startup it registers as
# observer rather than active.
rm -f /var/run/chrony/chronyd.pid   /var/run/chronyd.pid \
      /var/run/chrony/chronyd.sock  /var/run/chronyd.sock \
      /var/run/ntpd.pid 2>/dev/null || true

log_section "Verifying no time daemon is active"
for svc in chronyd ntpd ntp; do
  if systemctl is-active --quiet "${svc}"; then
    log_error "${svc} is still active — CTSS will register as observer, not active"
    exit 1
  fi
done
for cfg in /etc/chrony.conf /etc/ntp.conf; do
  if [[ -f "${cfg}" ]]; then
    log_error "${cfg} still present — cluvfy will expect a running daemon"
    exit 1
  fi
done
log_success "No time daemon active and no config present; CTSS will enter active mode on CRS startup"
