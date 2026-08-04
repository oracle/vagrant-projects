#!/usr/bin/env bash
# shellcheck shell=bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# _common.sh
#   Shared helpers for all provisioning scripts in this project.
#   Must be sourced, not executed:  . /vagrant/scripts/_common.sh
#------------------------------------------------------------------------------

# Re-entrancy guard
if [[ -n "${__DG_COMMON_SH_LOADED:-}" ]]; then
  return 0
fi
__DG_COMMON_SH_LOADED=1

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

# Logging helpers
log_info()    { printf '%b%s: %s\n' "$INFO"    "$(date '+%F %T')" "$*"; }
log_error()   { printf '%b%s: %s\n' "$ERROR"   "$(date '+%F %T')" "$*" >&2; }
log_success() { printf '%b%s: %s\n' "$SUCCESS" "$(date '+%F %T')" "$*"; }

log_section() {
  printf '%s\n' '-----------------------------------------------------------------'
  log_info "$*"
  printf '%s\n' '-----------------------------------------------------------------'
}

# ERR trap — surfaces the exact failure site
__dg_on_err() {
  local exit_code=$?
  log_error "command failed (exit=${exit_code}) at ${BASH_SOURCE[1]:-?}:${BASH_LINENO[0]:-?} — '${BASH_COMMAND}'"
  exit "${exit_code}"
}
trap __dg_on_err ERR

# Source the runtime env file if present (not available during its own generation).
# It lives on the guest filesystem so it does not depend on /vagrant mount
# semantics, which vary between providers.
: "${DG_SETUP_ENV_FILE:=/etc/opt/oracle-dg/setup.env}"
if [[ -r "${DG_SETUP_ENV_FILE}" ]]; then
  # setup.env is trusted: written by this project's setup.sh
  # shellcheck disable=SC1090
  . "${DG_SETUP_ENV_FILE}"
elif [[ -e "${DG_SETUP_ENV_FILE}" ]]; then
  log_error "setup env '${DG_SETUP_ENV_FILE}' is not readable by user '$(id -un)'"
  exit 1
fi

# Helpers used by several scripts
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

#------------------------------------------------------------------------------
# Release Update support (optional).
#
# Patching is opt-in: set both env.opatch_software and env.db_ru_software in
# config/vagrant.yml to enable it, or leave both unset and every RU step below
# becomes a no-op that leaves the RDBMS home at base release.
#
# Data Guard runs a single-instance database on each node with no Grid
# Infrastructure, so the home is patched with 'opatch apply' as the oracle user
# (not opatchauto). Each node stages and applies its own copy — primary and
# standby must reach the same patch level, and the patch is applied before the
# database is created so no instance is ever running when opatch runs.
#------------------------------------------------------------------------------

# Both zips are needed or neither: the opatch shipped inside the home is too old
# to apply a modern RU, so a half-configured pair is a mistake worth failing on
# rather than silently skipping.
ru_configured() {
  local opatch="${OPATCH_SOFTWARE:-}"
  local ru="${DB_RU_SOFTWARE:-}"

  if [[ -n "${opatch}" && -n "${ru}" ]]; then
    return 0
  fi
  if [[ -n "${opatch}" || -n "${ru}" ]]; then
    log_error "'env.opatch_software' and 'env.db_ru_software' must be set together (opatch_software='${opatch}', db_ru_software='${ru}')"
    exit 1
  fi
  return 1
}

# Unzip the RU into /u01/app/oracle-patches/<zip-stem>/ and hand back the single
# numeric patch directory Oracle packs inside it, which is what opatch apply
# wants.
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

  local zip_path="$(orcl_sw "${ru_software}")"
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

  zip_path="$(orcl_sw "${OPATCH_SOFTWARE}")"

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

# Stage the Database RU for the RDBMS home and leave DB_RU_PATCH_DIR pointing at
# the tree opatch should apply. Runs as the oracle user, which owns the home and
# /u01/app, so no root and no inventory-pointer bootstrap are needed: the central
# inventory already exists (orainstRoot.sh ran during the software install). The
# staging happens in this same process, so the result is exported rather than
# persisted to setup.env.
prepare_db_ru_patch() {
  local oracle_home="$1"
  local patch_dir patch_id

  [[ -d "${oracle_home}" ]] || { log_error "DB home not found: ${oracle_home}"; return 1; }

  if ! ru_configured; then
    log_info "No Release Update configured; leaving ${oracle_home} at base release"
    return 0
  fi

  stage_ru_patch patch_dir oracle:oinstall DB_RU_SOFTWARE "Database RU"
  patch_id="${patch_dir##*/}"
  install_required_opatch "${oracle_home}" oracle:oinstall

  export DB_RU_PATCH_DIR="${patch_dir}"
  log_success "Database RU patch ${patch_id} staged for opatch on ${oracle_home}"
}

# --- Shared Oracle software repository ---------------------------------------
# Large installer zips live once in a host-side repo mounted read-only at
# /software (see the Vagrantfile). Resolve each zip central-first, then fall
# back to the project-local /vagrant/ORCL_software (which still works and
# overrides the shared copy).
orcl_sw() {
  local name="$1"
  if [[ -n "${name}" && -f "/software/${name}" ]]; then
    printf '%s\n' "/software/${name}"
  else
    printf '%s\n' "/vagrant/ORCL_software/${name}"
  fi
}
