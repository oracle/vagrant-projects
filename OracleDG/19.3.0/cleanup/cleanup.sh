#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# cleanup.sh
#   Tear down the Data Guard lab and remove the disks that `vagrant destroy`
#   leaves behind:
#     * VirtualBox — the per-node u01 disks (primary_u01.vdi / standby_u01.vdi)
#       are intentionally kept across destroy/up so a re-provision is fast, and
#       the oradata disks (<role>_oradata_disk<i>.vdi) are separate media. Full
#       cleanup deletes both.
#     * libvirt — the u01 and oradata volumes are per-domain (not shared), so
#       `vagrant destroy` removes them with the domain; this script then sweeps
#       the pool(s) for any leftovers from an interrupted destroy.
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
      # Strip one layer of surrounding quotes so '' / "" resolve to empty.
      if (val ~ /^".*"$/ || val ~ /^'"'"'.*'"'"'$/) val = substr(val, 2, length(val) - 2)
      print val
      exit
    }
  ' "$CONFIG"
}

PROVIDER=$(yaml_get env provider)
PREFIX=$(yaml_get env prefix_name)
ORADATA_NUM=$(yaml_get env oradata_disk_num)
ORADATA_PATH=$(yaml_get env oradata_disk_path)

# VirtualBox per-node u01 disks (default to the Vagrantfile's own defaults).
U01_H1=$(yaml_get host1 u01_disk); U01_H1=${U01_H1:-./primary_u01.vdi}
U01_H2=$(yaml_get host2 u01_disk); U01_H2=${U01_H2:-./standby_u01.vdi}

# libvirt storage pools (u01 follows the per-host pool; oradata the env pool).
POOL_H1=$(yaml_get host1 storage_pool_name); POOL_H1=${POOL_H1:-default}
POOL_H2=$(yaml_get host2 storage_pool_name); POOL_H2=${POOL_H2:-default}
POOL_ORADATA=$(yaml_get env storage_pool_name); POOL_ORADATA=${POOL_ORADATA:-default}

if [[ -z "$PROVIDER" || -z "$PREFIX" || -z "$ORADATA_NUM" ]]; then
  echo "ERROR: env.provider / env.prefix_name / env.oradata_disk_num must be set in $CONFIG" >&2
  exit 1
fi

FORCE=0
case "${1-}" in
  -f|--force) FORCE=1 ;;
  -h|--help)  cat <<EOF
Usage: $0 [-f|--force]
  Runs 'vagrant destroy -f' and removes the Data Guard lab disks for the
  configured provider ($PROVIDER). Pass -f to skip the confirmation prompt.
EOF
              exit 0 ;;
esac

if [[ $FORCE -eq 0 ]]; then
  cat <<EOF
This will:
  1. vagrant destroy -f
EOF
  if [[ "$PROVIDER" == "virtualbox" ]]; then
    echo "  2. delete per-node u01 disks (${U01_H1##*/}, ${U01_H2##*/})"
    echo "  3. delete ${ORADATA_NUM} oradata disk(s) per node (primary/standby)"
  else
    echo "  2. sweep leftover per-domain volumes for ${PREFIX}host1/${PREFIX}host2"
  fi
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

# Delete every volume in a libvirt pool whose name starts with a domain name.
# vagrant-libvirt names a domain's disks '<default_prefix><machine>...', so the
# per-node u01 and oradata volumes all share that stem.
libvirt_sweep_domain() {
  local pool="$1" dom="$2" vol
  virsh vol-list --pool "$pool" 2>/dev/null | awk 'NR>2 && NF {print $1}' | while read -r vol; do
    case "$vol" in
      "${dom}"*) echo "  deleting $vol"; virsh vol-delete --pool "$pool" "$vol" >/dev/null 2>&1 || true ;;
    esac
  done
}

case "$PROVIDER" in
  libvirt)
    pools=$(printf '%s\n' "$POOL_H1" "$POOL_H2" "$POOL_ORADATA" | awk 'NF' | sort -u)
    for pool in $pools; do
      echo "=== sweeping leftover volumes in libvirt pool '$pool' ==="
      virsh pool-refresh "$pool" >/dev/null 2>&1 || true
      libvirt_sweep_domain "$pool" "${PREFIX}host1"
      libvirt_sweep_domain "$pool" "${PREFIX}host2"
    done
    ;;
  virtualbox)
    echo "=== removing VirtualBox per-node u01 disks ==="
    vbox_close_and_delete "$(realpath -m "$U01_H1")"
    vbox_close_and_delete "$(realpath -m "$U01_H2")"
    dir="${ORADATA_PATH%/}"
    [[ -z "$dir" ]] && dir="."
    echo "=== removing VirtualBox oradata disks from $dir ==="
    for role in primary standby; do
      for ((i=0; i<ORADATA_NUM; i++)); do
        vbox_close_and_delete "$(realpath -m "$dir/${role}_oradata_disk${i}.vdi")"
      done
    done
    ;;
  *)
    echo "ERROR: unknown provider '$PROVIDER' in $CONFIG" >&2
    exit 1
    ;;
esac

# Installer verification stamps written by the Vagrantfile cache (verify_installer!).
# Safe to drop: the next 'vagrant up' re-verifies the zip and regenerates them.
echo "=== removing installer verification stamps ==="
find ./ORCL_software -maxdepth 1 -name '.*.verified' -type f -delete 2>/dev/null || true

echo "Cleanup complete."
