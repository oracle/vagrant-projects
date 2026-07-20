#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 02_setup_u01.sh
#   Partition + LVM + XFS on the dedicated u01 disk, mount on /u01.
#
#   Args:
#     $1 = index of the u01 disk among the VM disks (0-based)
#     $2 = provider name ('libvirt' or 'virtualbox')
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

if [[ $# -lt 2 ]]; then
  log_error "usage: $0 <disk-index> <provider>"
  exit 1
fi

box_disk_num="$1"
provider="$2"

device="$(resolve_disk_device "${box_disk_num}" "${provider}")"

# Idempotency: if /u01 is already mounted, skip.
if mountpoint -q /u01; then
  log_info "/u01 already mounted — skipping"
  exit 0
fi

log_section "Creating GPT + single partition on ${device}"
parted -s -a optimal "${device}" mklabel gpt -- mkpart primary 2048s 100%
udevadm settle || true

log_section "Creating LVM VolGroupU01 / LogVolU01 on ${device}1"
pvcreate -ff -y "${device}1"
vgcreate VolGroupU01 "${device}1"
lvcreate -l 100%FREE -n LogVolU01 VolGroupU01

log_section "Formatting /dev/VolGroupU01/LogVolU01 as XFS"
mkfs.xfs -f /dev/VolGroupU01/LogVolU01

log_section "Mounting /u01"
uuid="$(blkid -s UUID -o value /dev/VolGroupU01/LogVolU01)"
mkdir -p /u01

fstab_line="UUID=${uuid}  /u01  xfs  defaults  1 2"
if ! grep -q "^UUID=${uuid}[[:space:]]" /etc/fstab; then
  printf '%s\n' "${fstab_line}" >> /etc/fstab
fi
mount /u01
