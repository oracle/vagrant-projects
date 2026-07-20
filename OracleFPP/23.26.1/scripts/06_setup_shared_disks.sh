#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 06_setup_shared_disks.sh
#   Partition each shared disk (P1 = DATA, P2 = RECO) on the node that owns
#   creation, and write udev rules so that both nodes expose the disks as
#   /dev/ORCL_DISK<n>[_p1|_p2] with grid:asmadmin ownership.
#
#   Args:
#     $1 = index of the first shared disk (0-based among the VM's disks)
#     $2 = provider name ('libvirt' or 'virtualbox')
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
for v in ASM_DISK_NUM NODE1_HOSTNAME NODE2_HOSTNAME; do
  require_var "${v}"
done

if [[ $# -lt 2 ]]; then
  log_error "usage: $0 <first-shared-disk-index> <provider>"
  exit 1
fi

first_idx="$1"
provider="$2"

current_host="$(hostname -s)"

clear_block_device_metadata() {
  local dev="$1"
  local wipe_mib="${2:-16}"
  local bytes seek_mib wipe_bytes

  if [[ ! -b "${dev}" ]]; then
    log_error "expected block device ${dev} is missing"
    return 1
  fi

  log_info "clearing stale partition / ASM metadata on ${dev}"
  wipefs -a -f "${dev}" >/dev/null 2>&1 || true

  dd if=/dev/zero of="${dev}" bs=1M count="${wipe_mib}" conv=fsync >/dev/null 2>&1

  bytes="$(blockdev --getsize64 "${dev}")"
  wipe_bytes=$((wipe_mib * 1024 * 1024))
  if (( bytes > wipe_bytes )); then
    seek_mib=$(((bytes / 1024 / 1024) - wipe_mib))
    if (( seek_mib > 0 )); then
      dd if=/dev/zero of="${dev}" bs=1M seek="${seek_mib}" count="${wipe_mib}" conv=fsync,notrunc >/dev/null 2>&1
    fi
  fi
}

# --- Which disks do we own the partition table for? -------------------------
# In a two-node cluster, node2 is responsible (writes propagate); in a
# single-node cluster there's only one node, so node1 does it.
partition_here="true"

# --- Enumerate the shared disks (exactly ASM_DISK_NUM of them) --------------
# Resolve each disk to its real /dev path now: the guest's device letters do not
# reliably follow the attachment order, so the serials — matching the
# Vagrantfile's 'serial: asm_disk_<n>' (1-based) — are the only stable identity.
asm_devices=()
for ((i = 0; i < ASM_DISK_NUM; i++)); do
  pos=$((first_idx + i))
  asm_devices+=("$(resolve_disk_device "${pos}" "${provider}" "asm_disk_$((i + 1))")")
done

if [[ "${partition_here}" == "true" ]]; then
  for dev in "${asm_devices[@]}"; do
    clear_block_device_metadata "${dev}"
    log_info "partitioning ${dev} (P1 = 100%)"
    parted -s "${dev}" -- \
      mklabel gpt \
      mkpart primary 4096s 100%
  done
  udevadm settle || true

  # Make sure the kernel has registered the new P1 partition on every disk, then
  # wipe those partitions — all BEFORE the ORCL_* udev rules are installed. Doing
  # every partition-table re-read and every partition write here means no
  # partprobe/partx/wipe churn happens AFTER the symlinks are created below, so
  # symlink creation is the last udev activity on these devices and cannot be
  # left half-applied at diskgroup-creation time (root.sh / ORA-15031).
  for dev in "${asm_devices[@]}"; do
    /sbin/partprobe "${dev}" || true
    /sbin/partx -u "${dev}" || true
    wait_for_block_device "${dev}1"
  done
  udevadm settle || true
  for dev in "${asm_devices[@]}"; do
    clear_block_device_metadata "${dev}1"
  done
  udevadm settle || true
fi

# --- udev rules (run on every node) -----------------------------------------
log_section "Installing udev rules for shared disks"
udev_file='/etc/udev/rules.d/70-oracle-asm.rules'
: > "${udev_file}"

i=1
for dev in "${asm_devices[@]}"; do
  kname="$(basename "${dev}")"
  if [[ "${provider}" == "libvirt" ]]; then
    # Match on KERNEL + ID_SERIAL. A partition has no native ID_SERIAL: udev's
    # 60-persistent-storage rules IMPORT{parent} it from the whole disk, so the
    # partition rule only matches once the parent's uevent has been processed and
    # its ID_SERIAL committed to the udev db. That ordering is guaranteed by the
    # parent-first / partitions-second trigger below. Keeping the serial match
    # (rather than KERNEL alone) preserves stable disk identity across reboots.
    # OWNER/GROUP/MODE are locked with := so later rules can't override.
    {
      echo "KERNEL==\"${kname}\",  SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", SYMLINK+=\"ORCL_DISK${i}\",    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
      echo "KERNEL==\"${kname}1\", SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
    } >> "${udev_file}"
  else
    serial="$(udevadm info --query=all --name="${dev}" | awk -F= '/^E: ID_SERIAL=/{print $2; exit}')"
    if [[ -z "${serial}" ]]; then
      log_error "could not determine ID_SERIAL for ${dev}"
      exit 1
    fi
    {
      echo "KERNEL==\"${kname}\",  ENV{ID_SERIAL}==\"${serial}\", SYMLINK+=\"ORCL_DISK${i}\",    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
      echo "KERNEL==\"${kname}1\", ENV{ID_SERIAL}==\"${serial}\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
    } >> "${udev_file}"
  fi
  ((i++))
done
chmod 0644 "${udev_file}"
udevadm control --reload-rules

# Create the symlinks whole-disks-first, then partitions. The partition rule's
# ENV{ID_SERIAL} is imported from the parent disk (IMPORT{parent}), so the parent
# uevent must be fully processed — its ID_SERIAL committed to the udev db —
# before the partition uevent runs. Triggering all block devices in one shot
# lets udev process parent and child in parallel; the partition can lose the race
# and see no ID_SERIAL -> the rule doesn't match -> no /dev/ORCL_DISK*_p1 symlink
# (intermittently a different disk each run). Serialising the two passes, with a
# settle between them, removes that race. Trigger only our ASM disks by sysfs
# path so the OS/u01 disks are left alone.
log_section "Triggering udev for shared disks (whole disks, then partitions)"
for dev in "${asm_devices[@]}"; do
  kname="$(basename "${dev}")"
  udevadm trigger --action=add "/sys/block/${kname}" 2>/dev/null || true
done
udevadm settle || true
for dev in "${asm_devices[@]}"; do
  kname="$(basename "${dev}")"
  udevadm trigger --action=add "/sys/block/${kname}/${kname}1" 2>/dev/null || true
done
udevadm settle || true

# Enforce ownership on the real devices directly. The udev OWNER:= rule keeps
# ownership correct across reboots; doing it explicitly here makes it
# deterministic for this boot regardless of udev event timing, so ASM (running
# as grid) can always open the partition even when only the symlink NAME came
# from udev.
log_section "Fixing ownership on shared disks"
for dev in "${asm_devices[@]}"; do
  chown_block_device "${dev}"  grid:asmadmin
  chown_block_device "${dev}1" grid:asmadmin
done

# Final barrier before returning: every P1 partition symlink must exist AND
# resolve to a device owned grid:asmadmin. The ASM instance that root.sh brings
# up discovers candidates via '/dev/ORCL_*' as the grid user; a symlink that is
# missing, or whose target reverted to root:disk, makes ASM see zero candidates
# for that exact path and fail DATA diskgroup creation with ORA-15031. Recover by
# re-triggering the specific disk parent-first, then partition; on persistent
# failure dump the real udev state so the cause is visible here in the
# provisioning log instead of surfacing later inside root.sh.
log_section "Verifying ASM disk symlinks and ownership"
i=1
for dev in "${asm_devices[@]}"; do
  link="/dev/ORCL_DISK${i}_p1"
  kname="$(basename "${dev}")"
  ok=false
  for attempt in $(seq 1 20); do
    if [[ -e "${link}" ]]; then
      target="$(readlink -f "${link}")"
      if [[ -b "${target}" && "$(stat -c '%U:%G' "${target}" 2>/dev/null)" == "grid:asmadmin" ]]; then
        ok=true
        break
      fi
    fi
    udevadm trigger --action=add "/sys/block/${kname}" 2>/dev/null || true
    udevadm settle || true
    udevadm trigger --action=add "/sys/block/${kname}/${kname}1" 2>/dev/null || true
    udevadm settle || true
    chown_block_device "${dev}1" grid:asmadmin
    sleep 1
  done

  if [[ "${ok}" != "true" ]]; then
    log_error "${link} is missing or not owned grid:asmadmin after retrigger+settle"
    log_error "diagnostics for ${link} (real device ${dev}1):"
    ls -l "${link}"  2>&1 | while read -r line; do log_error "  ${line}"; done
    ls -l "${dev}1"  2>&1 | while read -r line; do log_error "  ${line}"; done
    udevadm info --query=property --name="${dev}1" 2>&1 \
      | grep -E 'DEVNAME|DEVTYPE|ID_SERIAL|DEVLINKS' \
      | while read -r line; do log_error "  ${line}"; done
    exit 1
  fi
  log_info "verified ${link} -> $(readlink -f "${link}") ($(stat -c '%U:%G' "$(readlink -f "${link}")"))"
  ((i++))
done
