#!/usr/bin/env bash
# shellcheck shell=bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# _common.sh
#   Shared helpers for all RAC provisioning scripts.
#   Must be sourced, not executed:  . /vagrant/scripts/_common.sh
#------------------------------------------------------------------------------

# Re-entrancy guard
if [[ -n "${__RAC_COMMON_SH_LOADED:-}" ]]; then
  return 0
fi
__RAC_COMMON_SH_LOADED=1

# Strict mode (applies to every script that sources this file)
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
IFS=$'\n\t'

# ANSI colour tags (overridable)
: "${INFO:=\033[0;34mINFO: \033[0m}"
: "${ERROR:=\033[1;31mERROR: \033[0m}"
: "${SUCCESS:=\033[1;32mSUCCESS: \033[0m}"

log_info()    { printf '%b%s: %s\n' "$INFO"    "$(date '+%F %T')" "$*"; }
log_error()   { printf '%b%s: %s\n' "$ERROR"   "$(date '+%F %T')" "$*" >&2; }
log_success() { printf '%b%s: %s\n' "$SUCCESS" "$(date '+%F %T')" "$*"; }

log_section() {
  printf '%s\n' '-----------------------------------------------------------------'
  log_info "$*"
  printf '%s\n' '-----------------------------------------------------------------'
}

# ERR trap — surfaces the exact failure site
__rac_on_err() {
  local exit_code=$?
  log_error "command failed (exit=${exit_code}) at ${BASH_SOURCE[1]:-?}:${BASH_LINENO[0]:-?} — '${BASH_COMMAND}'"
  exit "${exit_code}"
}
trap __rac_on_err ERR

# Runtime env file. Lives on the guest filesystem (not /vagrant) so the
# oracle/grid users can source it without the provider-specific
# synced-folder permission quirks.
: "${RAC_SETUP_ENV_FILE:=/etc/opt/oracle-rac/setup.env}"
if [[ -r "${RAC_SETUP_ENV_FILE}" ]]; then
  # setup.env is trusted: written by this project's setup.sh
  # shellcheck disable=SC1090
  . "${RAC_SETUP_ENV_FILE}"
elif [[ -e "${RAC_SETUP_ENV_FILE}" ]]; then
  log_error "setup env '${RAC_SETUP_ENV_FILE}' is not readable by user '$(id -un)'"
  exit 1
fi

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    log_error "this script must run as root"
    exit 1
  fi
}

require_user() {
  local want="$1"
  if [[ "$(id -un)" != "${want}" ]]; then
    log_error "this script must run as user '${want}' (current: '$(id -un)')"
    exit 1
  fi
}

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    log_error "required variable '${name}' is not set"
    exit 1
  fi
}

# Resolve a disk to its current /dev path on the running guest.
#   $1 = attachment index (0-based)  — how virtualbox disks are identified
#   $2 = provider name
#   $3 = disk serial from the Vagrantfile — how libvirt disks are identified
#   $4 = attempts to wait for the by-id link (default 30)
#   $5 = delay between attempts, seconds (default 1)
#
# Neither provider guarantees that the guest's device letters follow the order
# the disks were attached in, so neither is resolved by letter math.
#
# libvirt names virtio disks vd<letter> in PCI probe order, which need not match
# the target letters in the domain XML: the same shared disk has been seen as
# vdb on one node and vdc on another. Letter math there is not merely fragile —
# it silently hands back a different disk per node, which is enough for a node
# to build /u01 on top of a shared ASM disk. The Vagrantfile stamps a serial on
# every disk and udev exposes it at /dev/disk/by-id/virtio-<serial>; that is the
# disk's own identity and cannot be reordered.
#
# virtualbox uses SATA AHCI; the kernel discovers targets asynchronously and
# may produce sd<letter> names that do not follow the SATA port order.  We
# resolve through /dev/disk/by-path/pci-*-ata-N where N = idx + 1, which the
# kernel populates from the SATA port number itself and is therefore stable.
resolve_disk_device() {
  local idx="$1"
  local provider="$2"
  local serial="${3:-}"
  local attempts="${4:-30}"
  local delay="${5:-1}"
  local path

  if ! [[ "${idx}" =~ ^[0-9]+$ ]]; then
    log_error "disk index must be a non-negative integer (got: '${idx}')"
    return 1
  fi

  case "${provider}" in
    libvirt)
      if [[ -z "${serial}" ]]; then
        log_error "a disk serial is required to resolve a libvirt disk (index ${idx})"
        return 1
      fi
      local link="/dev/disk/by-id/virtio-${serial}"
      local attempt
      for ((attempt = 1; attempt <= attempts; attempt++)); do
        [[ -e "${link}" ]] && break
        udevadm settle || true
        sleep "${delay}"
      done
      if [[ ! -e "${link}" ]]; then
        log_error "no by-id entry for disk serial '${serial}' (expected ${link}); is 'serial:' set for this disk in the Vagrantfile?"
        return 1
      fi
      path="$(readlink -f "${link}")"
      ;;
    virtualbox)
      local port=$((idx + 1))
      local matches=()
      shopt -s nullglob
      matches=( /dev/disk/by-path/pci-*-ata-"${port}" )
      shopt -u nullglob
      if (( ${#matches[@]} == 0 )); then
        log_error "no /dev/disk/by-path entry for SATA port index ${idx} (ata-${port})"
        return 1
      fi
      if (( ${#matches[@]} > 1 )); then
        log_error "multiple /dev/disk/by-path entries for ata-${port}: ${matches[*]}"
        return 1
      fi
      path="$(readlink -f "${matches[0]}")"
      ;;
    *)
      log_error "unsupported provider '${provider}'"
      return 1
      ;;
  esac

  if [[ ! -b "${path}" ]]; then
    log_error "resolved device ${path} for disk index ${idx} is not a block device"
    return 1
  fi

  printf '%s\n' "${path}"
}

wait_for_block_device() {
  local path="$1"
  local attempts="${2:-30}"
  local delay="${3:-1}"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if [[ -b "${path}" ]]; then
      return 0
    fi
    udevadm settle || true
    sleep "${delay}"
  done

  log_error "timed out waiting for block device ${path}"
  return 1
}

chown_block_device() {
  local path="$1"
  local owner_group="$2"
  local attempts="${3:-30}"
  local delay="${4:-1}"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if [[ -b "${path}" ]] && chown "${owner_group}" "${path}" 2>/dev/null; then
      return 0
    fi
    udevadm settle || true
    sleep "${delay}"
  done

  if [[ ! -b "${path}" ]]; then
    log_error "timed out waiting for block device ${path} before chown"
    return 1
  fi

  chown "${owner_group}" "${path}"
}

#------------------------------------------------------------------------------
# Release Update support (optional).
#
# Patching is opt-in: set both env.opatch_software and env.gi_ru_software in
# config/vagrant.yml to enable it, or leave both unset and every RU step below
# becomes a no-op that leaves the homes at base release.
#
# The GI RU is a combo patch carrying the RDBMS home patch as well, so one zip
# covers both homes and there is no separate Database RU. The two homes are
# patched by different mechanisms, though: the Grid home in place at install
# time by 'gridSetup.sh -applyRU', the RDBMS home afterwards by opatchauto.
#------------------------------------------------------------------------------

# Both zips are needed or neither: opatch/opatchauto from the shipped OPatch is
# too old to apply a modern RU, so a half-configured pair is a mistake worth
# failing on rather than silently skipping.
ru_configured() {
  local opatch="${OPATCH_SOFTWARE:-}"
  local ru="${GI_RU_SOFTWARE:-}"

  if [[ -n "${opatch}" && -n "${ru}" ]]; then
    return 0
  fi
  if [[ -n "${opatch}" || -n "${ru}" ]]; then
    log_error "'env.opatch_software' and 'env.gi_ru_software' must be set together (opatch_software='${opatch}', gi_ru_software='${ru}')"
    exit 1
  fi
  return 1
}

# opatch needs a central inventory pointer to exist. On the GI path this runs
# before orainstRoot.sh has ever been executed, so the pointer has to be
# created here rather than waited for.
ensure_ora_inventory_pointer() {
  require_var ORA_INVENTORY

  log_section "Preparing Oracle inventory pointer"
  mkdir -p "${ORA_INVENTORY}"
  chown -R grid:oinstall "${ORA_INVENTORY}"
  chmod -R u+rwX,g+rwX "${ORA_INVENTORY}"

  if [[ -f /etc/oraInst.loc ]]; then
    if ! grep -qxF "inventory_loc=${ORA_INVENTORY}" /etc/oraInst.loc \
       || ! grep -qxF 'inst_group=oinstall' /etc/oraInst.loc; then
      log_error "/etc/oraInst.loc already exists but does not match ${ORA_INVENTORY}/oinstall"
      return 1
    fi
  else
    {
      printf 'inventory_loc=%s\n' "${ORA_INVENTORY}"
      printf '%s\n' 'inst_group=oinstall'
    } > /etc/oraInst.loc
  fi
  chown root:oinstall /etc/oraInst.loc
  chmod 0664 /etc/oraInst.loc
}

# Unzip the RU into /u01/app/oracle-patches/<zip-stem>/ and hand back the single
# numeric patch directory Oracle packs inside it, which is what -applyRU and
# opatchauto both want.
#   $1 = name of the variable to receive the patch directory
#   $2 = owner:group the staged tree should end up as
#   $3 = name of the variable holding the RU zip filename
#   $4 = human label used in logs
stage_ru_patch() {
  local result_var="$1"
  local owner_group="$2"
  local software_var="$3"
  local patch_label="${4:-RU}"
  local ru_software

  require_var "${software_var}"
  ru_software="${!software_var}"

  if ! [[ "${ru_software}" =~ ^p[0-9]+_[0-9]+_[A-Za-z0-9_-]+\.zip$ ]]; then
    log_error "${software_var} must be an RU zip named p<bug-number>_<version>_<platform>.zip (got: ${ru_software})"
    return 1
  fi

  local zip_path="/vagrant/ORCL_software/${ru_software}"
  local patch_top="/u01/app/oracle-patches/${ru_software%.zip}"
  local patch_dirs=() candidate selected_patch_dir

  log_section "Staging ${patch_label} ${ru_software} under ${patch_top}"
  mkdir -p "${patch_top}"

  shopt -s nullglob
  for candidate in "${patch_top}"/[0-9]*; do
    [[ -d "${candidate}" ]] || continue
    [[ "${candidate##*/}" =~ ^[0-9]+$ ]] || continue
    patch_dirs+=( "${candidate}" )
  done
  shopt -u nullglob

  if (( ${#patch_dirs[@]} == 0 )); then
    (
      cd "${patch_top}"
      unzip -oq "${zip_path}"
    )

    shopt -s nullglob
    for candidate in "${patch_top}"/[0-9]*; do
      [[ -d "${candidate}" ]] || continue
      [[ "${candidate##*/}" =~ ^[0-9]+$ ]] || continue
      patch_dirs+=( "${candidate}" )
    done
    shopt -u nullglob
  else
    log_info "RU already staged at ${patch_dirs[*]}"
  fi

  if (( ${#patch_dirs[@]} != 1 )); then
    log_error "expected exactly one numeric RU patch directory under ${patch_top}, found ${#patch_dirs[@]}"
    return 1
  fi

  selected_patch_dir="${patch_dirs[0]}"
  chown -R "${owner_group}" "${patch_top}"
  chmod -R u+rwX,g+rwX "${patch_top}"

  log_success "RU staged at ${selected_patch_dir}"
  printf -v "${result_var}" '%s' "${selected_patch_dir}"
}

# Replace the home's shipped OPatch with the version the RU requires.
install_required_opatch() {
  local oracle_home="$1"
  local owner_group="$2"
  local zip_path

  require_var OPATCH_SOFTWARE
  # OPatch is always bug 6880880; only the version/platform segments move.
  if ! [[ "${OPATCH_SOFTWARE}" =~ ^p6880880_[0-9]+_[A-Za-z0-9_-]+\.zip$ ]]; then
    log_error "OPATCH_SOFTWARE must be an OPatch zip named p6880880_<version>_<platform>.zip (got: ${OPATCH_SOFTWARE})"
    return 1
  fi

  [[ -d "${oracle_home}" ]] || { log_error "Oracle home not found: ${oracle_home}"; return 1; }

  zip_path="/vagrant/ORCL_software/${OPATCH_SOFTWARE}"

  log_section "Installing required OPatch into ${oracle_home}"
  rm -rf "${oracle_home}/OPatch"
  (
    cd "${oracle_home}"
    unzip -oq "${zip_path}"
  )

  [[ -x "${oracle_home}/OPatch/opatch" ]] || {
    log_error "opatch not found or not executable after extracting ${OPATCH_SOFTWARE}"
    return 1
  }

  chown -R "${owner_group}" "${oracle_home}/OPatch"
  chmod -R u+rwX,g+rwX "${oracle_home}/OPatch"
  log_success "Required OPatch installed from ${OPATCH_SOFTWARE}"
}

# Record a value in the runtime env so later scripts — which are separate bash
# processes that source setup.env at start — can see it. Callers that also need
# the value in their own shell must export it themselves; this only writes.
write_runtime_env_export() {
  local name="$1"
  local value="$2"
  local tmp_file

  if ! [[ "${name}" =~ ^[A-Z0-9_]+$ ]]; then
    log_error "invalid runtime env variable name: ${name}"
    return 1
  fi
  [[ -f "${RAC_SETUP_ENV_FILE}" ]] || {
    log_error "runtime env file not found: ${RAC_SETUP_ENV_FILE}"
    return 1
  }

  tmp_file="$(mktemp "${RAC_SETUP_ENV_FILE}.XXXXXX")"
  awk -v name="${name}" '$0 !~ "^export " name "=" { print }' \
    "${RAC_SETUP_ENV_FILE}" > "${tmp_file}"
  printf 'export %s=%q\n' "${name}" "${value}" >> "${tmp_file}"
  chown --reference="${RAC_SETUP_ENV_FILE}" "${tmp_file}"
  chmod --reference="${RAC_SETUP_ENV_FILE}" "${tmp_file}"
  mv -f "${tmp_file}" "${RAC_SETUP_ENV_FILE}"
}

# Both entry points below publish the staged location as GI_RU_PATCH_DIR: into
# the runtime env for the scripts that run later as separate processes, and
# into the caller's own environment for anything continuing in-process. Callers
# read that one variable and do not care which of the two set it.

# Stage the RU for the Grid home and record where gridSetup should find it.
# The home itself is patched later, by 10_gi_installation.sh passing -applyRU.
# Runs on the node that owns the GI install; gridSetup pushes the patched home
# to the other node itself.
apply_gi_ru_patch() {
  local oracle_home="$1"
  local patch_dir patch_id

  require_root
  [[ -d "${oracle_home}" ]] || { log_error "GI home not found: ${oracle_home}"; return 1; }

  if ! ru_configured; then
    log_info "No Release Update configured; leaving ${oracle_home} at base release"
    return 0
  fi

  stage_ru_patch patch_dir grid:oinstall GI_RU_SOFTWARE "GI RU"
  patch_id="${patch_dir##*/}"
  install_required_opatch "${oracle_home}" grid:oinstall

  ensure_ora_inventory_pointer
  write_runtime_env_export GI_RU_PATCH_DIR "${patch_dir}"
  export GI_RU_PATCH_DIR="${patch_dir}"
  log_success "GI RU patch ${patch_id} prepared for gridSetup -applyRU"
}

# Stage the same GI RU zip for an RDBMS home, leaving GI_RU_PATCH_DIR pointing
# at the tree opatchauto should apply.
#
# Runs on every node that has a DB home. The home is a cluster home that
# runInstaller pushes from node1 to node2, but the staged tree lives outside it
# and is not pushed with it, so each node materialises its own copy.
prepare_db_ru_patch() {
  local oracle_home="$1"
  local patch_dir patch_id

  require_root
  [[ -d "${oracle_home}" ]] || { log_error "DB home not found: ${oracle_home}"; return 1; }

  if ! ru_configured; then
    log_info "No Release Update configured; leaving ${oracle_home} at base release"
    return 0
  fi

  stage_ru_patch patch_dir oracle:oinstall GI_RU_SOFTWARE "GI RU"
  patch_id="${patch_dir##*/}"
  install_required_opatch "${oracle_home}" oracle:oinstall

  ensure_ora_inventory_pointer
  write_runtime_env_export GI_RU_PATCH_DIR "${patch_dir}"
  export GI_RU_PATCH_DIR="${patch_dir}"
  log_success "GI RU patch ${patch_id} staged for opatchauto on ${oracle_home}"
}

# Return the udev-backed Oracle ASM disk glob used by this project.
#   $1 = 'p1'  → data partitions (P1)
#   $1 = 'p2'  → reco partitions (P2)
asm_disk_glob() {
  local part="$1"
  case "${part}" in
    p1) echo "/dev/ORCL_DISK*_p1" ;;
    p2) echo "/dev/ORCL_DISK*_p2" ;;
    *)
      log_error "unsupported ASM partition selector '${part}'"
      return 1
      ;;
  esac
}
