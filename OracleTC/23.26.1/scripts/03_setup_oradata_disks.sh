#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 03_setup_oradata_disks.sh
#   Partition + LVM + XFS on all remaining oradata disks, mount on /u02.
#
#   Args:
#     $1 = index of the first oradata disk (0-based, i.e. after /u01)
#     $2 = provider name ('libvirt' or 'virtualbox')
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

if [[ $# -lt 2 ]]; then
  log_error "usage: $0 <first-disk-index> <provider>"
  exit 1
fi

first_idx="$1"
provider="$2"

case "${provider}" in
  libvirt)    dev_prefix="vd" ;;
  virtualbox) dev_prefix="sd" ;;
  *)          log_error "unsupported provider '${provider}'"; exit 1 ;;
esac

first_letter="$(tr 0123456789 abcdefghij <<< "${first_idx}")"

# Collect all disks from the first oradata letter up to z
shopt -s nullglob
disks=( /dev/${dev_prefix}[${first_letter}-z] )
if [[ ${#disks[@]} -eq 0 ]]; then
  log_error "no oradata disks found under /dev/${dev_prefix}[${first_letter}-z]"
  exit 1
fi

log_section "Partitioning ${#disks[@]} oradata disk(s): ${disks[*]}"
for d in "${disks[@]}"; do
  parted -s -a optimal "${d}" mklabel gpt -- mkpart primary 4096s 100%
done
udevadm settle || true

log_section "Creating PVs"
for d in "${disks[@]}"; do
  pvcreate -ff -y "${d}1"
done

log_section "Creating VG VolGroupOra and LV LogVolData"
partitions=()
for d in "${disks[@]}"; do
  partitions+=( "${d}1" )
done
vgcreate VolGroupOra "${partitions[@]}"
lvcreate -l 100%FREE -n LogVolData VolGroupOra

log_section "Formatting /dev/VolGroupOra/LogVolData as XFS"
mkfs.xfs -f /dev/VolGroupOra/LogVolData

log_section "Mounting /u02"
uuid="$(blkid -s UUID -o value /dev/VolGroupOra/LogVolData)"
mkdir -p /u02
if ! grep -q "^UUID=${uuid}[[:space:]]" /etc/fstab; then
  printf '%s\n' "UUID=${uuid}  /u02  xfs  defaults  1 2" >> /etc/fstab
fi
mount /u02
