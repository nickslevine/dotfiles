#!/usr/bin/env bash

set -euo pipefail

# Minimal remote bootstrapper for dotfiles
# - Clones or updates the repo into $DOTFILES_DIR (default: ~/dotfiles)
# - Prefers SSH if available or if USE_SSH=1 is set
# - Runs ./setup.sh from the repo

REPO_SLUG="nickslevine/dotfiles"
REPO_HTTPS="https://github.com/${REPO_SLUG}.git"
REPO_SSH="git@github.com:${REPO_SLUG}.git"

DOTFILES_DIR_DEFAULT="${HOME}/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-${DOTFILES_DIR_DEFAULT}}"

supports_color() { [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; }
if supports_color; then C0="\033[0m"; C1="\033[34m"; C2="\033[32m"; C3="\033[33m"; C4="\033[31m"; else C0=""; C1=""; C2=""; C3=""; C4=""; fi
ts() { date "+%Y-%m-%d %H:%M:%S"; }
log_info() { printf "%b[%s] [INFO] %s%b\n"  "$C1" "$(ts)" "$1" "$C0"; }
log_ok()   { printf "%b[%s] [ OK ] %s%b\n" "$C2" "$(ts)" "$1" "$C0"; }
log_warn() { printf "%b[%s] [WARN] %s%b\n" "$C3" "$(ts)" "$1" "$C0"; }
log_err()  { printf "%b[%s] [FAIL] %s%b\n" "$C4" "$(ts)" "$1" "$C0"; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || { log_err "Required command '$1' not found"; exit 1; }; }

ssh_ready_for_github() {
  command -v ssh >/dev/null 2>&1 || return 1
  local out
  out=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
  grep -qi "successfully authenticated" <<<"$out"
}

main() {
  require_cmd git

  local clone_url="$REPO_HTTPS"
  if [[ "${USE_SSH:-0}" == "1" ]] || ssh_ready_for_github; then
    log_info "Using SSH for cloning"
    clone_url="$REPO_SSH"
  else
    log_info "Using HTTPS for cloning"
  fi

  if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    log_info "Updating repo at ${DOTFILES_DIR}"
    if git -C "${DOTFILES_DIR}" pull --ff-only; then
      log_ok "Repo updated"
    else
      log_warn "git pull failed; continuing with existing checkout"
    fi
  else
    log_info "Cloning into ${DOTFILES_DIR}"
    git clone "$clone_url" "$DOTFILES_DIR"
    log_ok "Cloned repository"
  fi

  if [[ -f "${DOTFILES_DIR}/setup.sh" ]]; then
    log_info "Running setup.sh"
    ( cd "$DOTFILES_DIR" && bash ./setup.sh )
    log_ok "Setup completed"
  else
    log_err "setup.sh not found in ${DOTFILES_DIR}"
    exit 1
  fi
}

main "$@"

