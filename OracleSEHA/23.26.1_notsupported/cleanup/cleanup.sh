#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# cleanup.sh
#   Tear down the SEHA lab and remove the shared ASM disks (and per-node u01
#   disks on VirtualBox) that `vagrant destroy` intentionally leaves behind —
#   shared media isn't auto-deleted because it can belong to multiple VMs, but
#   in this project it's always project-scoped, so full cleanup is desired.
#------------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG=./config/vagrant.yml
[[ -f Vagrantfile ]] || { echo "ERROR: Vagrantfile not found; run from project root" >&2; exit 1; }
[[ -f "$CONFIG"   ]] || { echo "ERROR: $CONFIG not found" >&2; exit 1; }

# Minimal YAML scalar reader for the flat 2-level structure vagrant.yml uses
# (top-level section, then 2-space-indented key: value lines). Avoids a ruby /
# pyyaml dependency — Vagrant's embedded Ruby isn't on PATH.
yaml_get() {
  local section="$1" key="$2"
  awk -v s="$section" -v k="$key" '
    /^[A-Za-z_][A-Za-z0-9_]*:/ { cur = $1; sub(/:.*/, "", cur); next }
    cur == s {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (line == "" || line ~ /^#/) next
      idx = index(line, ":")
      if (idx == 0) next
      if (substr(line, 1, idx-1) != k) next
      val = substr(line, idx+1)
      sub(/#.*$/, "", val)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
      print val
      exit
    }
  ' "$CONFIG"
}

PROVIDER=$(yaml_get env provider)
PREFIX=$(yaml_get env prefix_name)
ASM_NUM=$(yaml_get env asm_disk_num)
ASM_PATH=$(yaml_get env asm_disk_path)
POOL=$(yaml_get env storage_pool_name)

if [[ -z "$PROVIDER" || -z "$PREFIX" || -z "$ASM_NUM" ]]; then
  echo "ERROR: env.provider / env.prefix_name / env.asm_disk_num must be set in $CONFIG" >&2
  exit 1
fi

FORCE=0
case "${1-}" in
  -f|--force) FORCE=1 ;;
  -h|--help)  cat <<EOF
Usage: $0 [-f|--force]
  Runs 'vagrant destroy -f' and removes shared ASM disks for the configured
  provider ($PROVIDER). Pass -f to skip the confirmation prompt.
EOF
              exit 0 ;;
esac

if [[ $FORCE -eq 0 ]]; then
  cat <<EOF
This will:
  1. vagrant destroy -f
  2. delete ${ASM_NUM} shared ASM disk(s) (provider: ${PROVIDER})
EOF
  [[ "$PROVIDER" == "virtualbox" ]] && echo "  3. delete per-node u01 disks (node1_u01.vdi, node2_u01.vdi)"
  echo ""
  read -rp "Continue? [y/N] " ans
  [[ "$ans" =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }
fi

echo "=== vagrant destroy -f ==="
vagrant destroy -f || true

vbox_close_and_delete() {
  local path="$1"
  if VBoxManage list hdds 2>/dev/null | grep -Fq "$path"; then
    VBoxManage closemedium disk "$path" --delete 2>/dev/null \
      || VBoxManage closemedium disk "$path" 2>/dev/null \
      || true
  fi
  rm -f "$path"
}

case "$PROVIDER" in
  libvirt)
    POOL="${POOL:-default}"
    echo "=== removing ASM volumes from libvirt pool '$POOL' ==="
    for ((i=0; i<ASM_NUM; i++)); do
      vol="${PREFIX}_asm_${i}"
      if virsh vol-info --pool "$POOL" "$vol" >/dev/null 2>&1; then
        virsh vol-delete --pool "$POOL" "$vol"
      else
        echo "  skip: $vol (not present)"
      fi
    done
    virsh pool-refresh "$POOL" >/dev/null 2>&1 || true
    ;;
  virtualbox)
    dir="${ASM_PATH%/}"
    [[ -z "$dir" ]] && dir="."
    echo "=== removing VirtualBox shared ASM disks from $dir ==="
    for ((i=0; i<ASM_NUM; i++)); do
      vbox_close_and_delete "$(realpath -m "$dir/asm_disk${i}.vdi")"
    done
    echo "=== removing per-node u01 disks ==="
    for node_disk in node1_u01.vdi node2_u01.vdi; do
      vbox_close_and_delete "$(realpath -m "./$node_disk")"
    done
    ;;
  *)
    echo "ERROR: unknown provider '$PROVIDER' in $CONFIG" >&2
    exit 1
    ;;
esac

echo "Cleanup complete."
