#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Bootstrap dotfiles setup (idempotent)
# - Clones or updates this repo, preferring SSH if available
# - Runs auth setup (if credentials are present)
# - Installs packages and copies dotfiles
# - Sources the appropriate shell config (zsh or bash)
# -----------------------------------------------------------------------------
#
#
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates gnupg curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install google-cloud-cli

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
HOME_DIR="${HOME}"
REPO_DIR="${HOME_DIR}/dotfiles"
REPO_HTTPS="https://github.com/nickslevine/dotfiles.git"
REPO_SSH="git@github.com:nickslevine/dotfiles.git"

# ----------------------------- Logging helpers ------------------------------
supports_color() {
  [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]
}

if supports_color; then
  C0="\033[0m"; C1="\033[34m"; C2="\033[32m"; C3="\033[33m"; C4="\033[31m"
else
  C0=""; C1=""; C2=""; C3=""; C4=""
fi
ts() { date "+%Y-%m-%d %H:%M:%S"; }
log_info() { printf "%b[%s] [INFO] %s%b\n"  "$C1" "$(ts)" "$1" "$C0"; }
log_ok()   { printf "%b[%s] [ OK ] %s%b\n" "$C2" "$(ts)" "$1" "$C0"; }
log_warn() { printf "%b[%s] [WARN] %s%b\n" "$C3" "$(ts)" "$1" "$C0"; }
log_err()  { printf "%b[%s] [FAIL] %s%b\n" "$C4" "$(ts)" "$1" "$C0"; }

# ------------------------------ Helpers -------------------------------------
ssh_ready_for_github() {
  command -v ssh >/dev/null 2>&1 || return 1
  # BatchMode avoids passphrase prompts; exit codes: 1 means auth ok for GitHub banner, 255 means failure
  local out
  out=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
  grep -qi "successfully authenticated" <<<"$out"
}

ensure_repo() {
  local url="$1"
  if [[ -d "${REPO_DIR}/.git" ]]; then
    log_info "Updating repo at ${REPO_DIR}"
    if git -C "${REPO_DIR}" pull --ff-only >/dev/null 2>&1; then
      log_ok "Repo updated"
    else
      log_warn "Failed to pull; continuing with existing checkout"
    fi
  else
    log_info "Cloning repo into ${REPO_DIR}"
    if git clone "$url" "${REPO_DIR}" >/dev/null 2>&1; then
      log_ok "Cloned ${url}"
    else
      log_err "Clone failed from ${url}"
      exit 1
    fi
  fi
}

maybe_switch_remote_to_ssh() {
  if ssh_ready_for_github; then
    if git -C "${REPO_DIR}" remote set-url origin "${REPO_SSH}" >/dev/null 2>&1; then
      log_ok "Switched git remote to SSH"
    fi
  else
    log_info "GitHub SSH not ready; keeping HTTPS remote"
  fi
}

run_if_exists() {
  local script_path="$1"
  local name
  name="$(basename "$script_path")"
  if [[ -f "$script_path" ]]; then
    log_info "Running ${name}"
    bash "$script_path"
    log_ok "${name} completed"
  else
    log_warn "Skipping ${name} (not found)"
  fi
}

source_shell_rc() {
  # Source the appropriate shell rc non-interactively if present
  local shell_basename
  shell_basename="$(basename "${SHELL:-}")"
  set +e
  case "${shell_basename}" in
    zsh)
      [[ -f "${HOME_DIR}/.zshrc" ]] && { log_info "Sourcing ~/.zshrc"; . "${HOME_DIR}/.zshrc"; }
      ;;
    bash|* )
      [[ -f "${HOME_DIR}/.bashrc" ]] && { log_info "Sourcing ~/.bashrc"; . "${HOME_DIR}/.bashrc"; }
      ;;
  esac
  set -e
}

# ------------------------------- Main ---------------------------------------
log_info "Starting setup"

# Choose clone URL: prefer SSH if ready
CLONE_URL="${REPO_HTTPS}"
if ssh_ready_for_github; then
  log_ok "GitHub SSH authentication detected; using SSH clone URL"
  CLONE_URL="${REPO_SSH}"
else
  log_info "Using HTTPS clone URL (SSH not ready)"
fi

ensure_repo "$CLONE_URL"

# After initial clone/update, attempt to switch remote to SSH if auth is now configured
maybe_switch_remote_to_ssh || true

# Run auth setup if expected credential files exist
if [[ -f "${HOME_DIR}/devbox_github" || -f "${HOME_DIR}/sa-key.json" ]]; then
  run_if_exists "${REPO_DIR}/setup-auth.sh"
  # Re-check SSH and switch remote if auth succeeded
  maybe_switch_remote_to_ssh || true
else
  log_info "Auth credentials not found; skipping setup-auth.sh"
fi

# Install packages and copy dotfiles
run_if_exists "${REPO_DIR}/install-packages.sh"
run_if_exists "${REPO_DIR}/copy-dotfiles.sh"

# Optional: run shell setup if explicitly enabled
if [[ "${RUN_SHELL_SETUP:-0}" == "1" ]]; then
  run_if_exists "${REPO_DIR}/setup-shell.sh"
fi

# Source shell configuration for current shell
source_shell_rc

log_ok "Setup complete"
