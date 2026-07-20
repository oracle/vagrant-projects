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
for v in P1_RATIO ASM_DISK_NUM NODE1_HOSTNAME NODE2_HOSTNAME ORESTART; do
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

drop_stale_partition_mappings() {
  local dev="$1"
  local attempts="${2:-30}"
  local delay="${3:-1}"
  local attempt
  local children=()

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    mapfile -t children < <(lsblk -lnpo NAME "${dev}" | tail -n +2)
    if (( ${#children[@]} == 0 )); then
      return 0
    fi

    if (( attempt == 1 )); then
      log_info "dropping stale kernel partition mappings on ${dev}: ${children[*]}"
    fi

    for child in "${children[@]}"; do
      wipefs -a -f "${child}" >/dev/null 2>&1 || true
    done
    # At this point the parent disk label has already been wiped, so rereading
    # the partition table should cause the kernel to drop stale child devices
    # instead of recreating them from an old GPT.
    /sbin/partx -d "${dev}" >/dev/null 2>&1 || true
    /sbin/partprobe "${dev}" >/dev/null 2>&1 || true
    /sbin/blockdev --rereadpt "${dev}" >/dev/null 2>&1 || true
    udevadm settle || true
    sleep "${delay}"
  done

  log_error "timed out removing stale partition mappings from ${dev}"
  lsblk -lnpo NAME,TYPE,SIZE "${dev}" || true
  return 1
}

shared_disk_has_expected_partitions() {
  local dev="$1"

  parted -m -s "${dev}" unit s print 2>/dev/null | \
    awk -F: 'BEGIN { count = 0 } $1 ~ /^[0-9]+$/ { count++ } END { exit(count == 2 ? 0 : 1) }'
}

partition_shared_disk() {
  local dev="$1"
  local rc

  if parted -s "${dev}" -- \
      mklabel gpt \
      mkpart primary 4096s "${P1_RATIO}%" \
      mkpart primary "${P1_RATIO}%" 100%; then
    return 0
  fi
  rc=$?

  if shared_disk_has_expected_partitions "${dev}"; then
    log_info "parted returned exit=${rc} for ${dev}, but the expected GPT layout is on disk; continuing with an explicit reread"
    return 0
  fi

  log_error "failed to create the expected partition layout on ${dev} (exit=${rc})"
  return "${rc}"
}

refresh_partition_devices() {
  local dev="$1"
  local attempts="${2:-45}"
  local delay="${3:-2}"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    /sbin/partprobe "${dev}" >/dev/null 2>&1 || true
    /sbin/partx -u "${dev}" >/dev/null 2>&1 || true
    udevadm settle || true

    if [[ -b "${dev}1" && -b "${dev}2" ]]; then
      return 0
    fi

    sleep "${delay}"
  done

  log_error "timed out waiting for partition devices ${dev}1 and ${dev}2"
  /sbin/partx -s "${dev}" 2>/dev/null || true
  return 1
}

# --- Which disks do we own the partition table for? -------------------------
# In cluster mode, node2 is responsible (writes propagate); in Oracle Restart
# mode there's only one node, so node1 does it.
partition_here="false"
if [[ "${ORESTART}" == "true" && "${current_host}" == "${NODE1_HOSTNAME}" ]]; then
  partition_here="true"
elif [[ "${ORESTART}" == "false" && "${current_host}" == "${NODE2_HOSTNAME}" ]]; then
  partition_here="true"
fi

# --- Enumerate the shared disks (exactly ASM_DISK_NUM of them) --------------
# Resolve each ASM disk to its real /dev path now, since on virtualbox the
# kernel may discover SATA targets out of port order and so /dev/sd<letter>
# does not necessarily follow the attachment-index order.
# The serials match the Vagrantfile's 'serial: asm_disk_<n>' (1-based), which is
# also what the udev rules below key on.
asm_devices=()
for ((i = 0; i < ASM_DISK_NUM; i++)); do
  pos=$((first_idx + i))
  asm_devices+=("$(resolve_disk_device "${pos}" "${provider}" "asm_disk_$((i + 1))")")
done

if [[ "${partition_here}" == "true" ]]; then
  for dev in "${asm_devices[@]}"; do
    clear_block_device_metadata "${dev}"
    drop_stale_partition_mappings "${dev}"
    log_info "partitioning ${dev} (P1 = ${P1_RATIO}%, P2 = remainder)"
    partition_shared_disk "${dev}"
  done
  sync
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
    {
      echo "KERNEL==\"${kname}\",  SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", ENV{ID_PART_TABLE_TYPE}==\"gpt\", SYMLINK+=\"ORCL_DISK${i}\",    OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""
      echo "KERNEL==\"${kname}1\", SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", ENV{ID_PART_ENTRY_NUMBER}==\"1\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""
      echo "KERNEL==\"${kname}2\", SUBSYSTEM==\"block\", ENV{ID_SERIAL}==\"asm_disk_${i}\", ENV{ID_PART_ENTRY_NUMBER}==\"2\", SYMLINK+=\"ORCL_DISK${i}_p2\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""
    } >> "${udev_file}"
  else
    serial="$(udevadm info --query=all --name="${dev}" | awk -F= '/^E: ID_SERIAL=/{print $2; exit}')"
    if [[ -z "${serial}" ]]; then
      log_error "could not determine ID_SERIAL for ${dev}"
      exit 1
    fi
    # Match by ID_SERIAL only — the sd<letter> kernel name is not stable
    # across nodes (or even reboots) when multiple SATA disks are attached.
    {
      echo "SUBSYSTEM==\"block\", KERNEL==\"sd*\", ENV{DEVTYPE}==\"disk\",      ENV{ID_SERIAL}==\"${serial}\", SYMLINK+=\"ORCL_DISK${i}\",    OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
      echo "SUBSYSTEM==\"block\", KERNEL==\"sd*\", ENV{DEVTYPE}==\"partition\", ENV{ID_SERIAL}==\"${serial}\", ENV{ID_PART_ENTRY_NUMBER}==\"1\", SYMLINK+=\"ORCL_DISK${i}_p1\", OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
      echo "SUBSYSTEM==\"block\", KERNEL==\"sd*\", ENV{DEVTYPE}==\"partition\", ENV{ID_SERIAL}==\"${serial}\", ENV{ID_PART_ENTRY_NUMBER}==\"2\", SYMLINK+=\"ORCL_DISK${i}_p2\", OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"0660\""
    } >> "${udev_file}"
  fi
  ((i++))
done
chmod 0644 "${udev_file}"
udevadm control --reload-rules
udevadm trigger --subsystem-match=block

log_section "Running partprobe + fixing ownership"
i=1
for dev in "${asm_devices[@]}"; do
  /sbin/partprobe "${dev}" || true
  /sbin/partx -u "${dev}" || true
  udevadm settle || true
  refresh_partition_devices "${dev}"
  chown_block_device "${dev}" grid:asmadmin
  chown_block_device "${dev}1" grid:asmadmin
  chown_block_device "${dev}2" grid:asmadmin

  wait_for_block_device "/dev/ORCL_DISK${i}_p1"
  wait_for_block_device "/dev/ORCL_DISK${i}_p2"
  if [[ "${partition_here}" == "true" ]]; then
    clear_block_device_metadata "${dev}1"
    clear_block_device_metadata "${dev}2"
  fi
  ((i++))
done
