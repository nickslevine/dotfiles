#!/usr/bin/env bash

# Robust, idempotent installer for a standard toolchain (defined in this script)
# - Detects macOS (Homebrew) vs Ubuntu/Debian (apt) automatically
# - Checks if each tool is already installed; installs only if missing
# - Provides clear logging and best-effort error handling without aborting the whole run

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------- Logging helpers ------------------------------
supports_color() {
  [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]
}

if supports_color; then
  COLOR_RESET="\033[0m"
  COLOR_BLUE="\033[34m"
  COLOR_GREEN="\033[32m"
  COLOR_YELLOW="\033[33m"
  COLOR_RED="\033[31m"
else
  COLOR_RESET=""; COLOR_BLUE=""; COLOR_GREEN=""; COLOR_YELLOW=""; COLOR_RED=""
fi

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }
log() { printf "%b[%s] %s%b\n" "${1}" "$(timestamp)" "${2}" "${COLOR_RESET}"; }
log_info() { log "${COLOR_BLUE}[INFO]" "$1"; }
log_warn() { log "${COLOR_YELLOW}[WARN]" "$1"; }
log_ok()   { log "${COLOR_GREEN}[ OK ]" "$1"; }
log_err()  { log "${COLOR_RED}[FAIL]" "$1"; }

# ------------------------------ OS detection --------------------------------
OS="unknown"
PKG_MGR=""

if [[ "$(uname -s)" == "Darwin" ]]; then
  OS="macos"
  if command -v brew >/dev/null 2>&1; then
    PKG_MGR="brew"
  else
    log_err "Homebrew is not installed. Install from https://brew.sh and re-run."
    exit 1
  fi
elif [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" == "ubuntu" ]] || [[ "${ID_LIKE:-}" == *debian* ]] || [[ "${ID_LIKE:-}" == *ubuntu* ]]; then
    OS="ubuntu"
    if command -v apt-get >/dev/null 2>&1; then
      PKG_MGR="apt"
    else
      log_err "apt-get not found. This script supports Ubuntu/Debian via apt-get."
      exit 1
    fi
  fi
fi

if [[ "${OS}" == "unknown" ]]; then
  log_err "Unsupported OS. Only macOS and Ubuntu/Debian are supported."
  exit 1
fi

log_info "Detected OS: ${OS} (package manager: ${PKG_MGR})"

# ------------------------------ Utilities -----------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_dir() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    if mkdir -p "${dir}" 2>/dev/null; then
      return 0
    else
      sudo mkdir -p "${dir}" 2>/dev/null || return 1
    fi
  fi
}

# Create alias symlink if target command exists but alias name does not
ensure_cmd_alias() {
  local source_cmd="$1"; local alias_name="$2"; local dest="/usr/local/bin/${alias_name}"
  if command_exists "${alias_name}"; then return 0; fi
  if ! command_exists "${source_cmd}"; then return 0; fi
  local source_path
  source_path="$(command -v "${source_cmd}")" || return 0
  ensure_dir "/usr/local/bin" || return 1
  if ln -sf "${source_path}" "${dest}" 2>/dev/null; then
    log_ok "Created alias '${alias_name}' -> ${source_cmd} at ${dest}"
  else
    if sudo ln -sf "${source_path}" "${dest}" 2>/dev/null; then
      log_ok "Created alias '${alias_name}' -> ${source_cmd} at ${dest} (via sudo)"
    else
      log_warn "Failed to create alias '${alias_name}'. You may want to link ${source_cmd} to ${alias_name} manually."
    fi
  fi
}

# Create a symlink from a known source path to destination, with sudo fallback
ensure_symlink_path() {
  local source_path="$1"; local dest_path="$2"
  if [[ ! -e "${source_path}" ]]; then return 1; fi
  ensure_dir "$(dirname "${dest_path}")" || return 1
  if ln -sf "${source_path}" "${dest_path}" 2>/dev/null; then
    log_ok "Linked ${dest_path} -> ${source_path}"
  else
    if sudo ln -sf "${source_path}" "${dest_path}" 2>/dev/null; then
      log_ok "Linked ${dest_path} -> ${source_path} (via sudo)"
    else
      log_warn "Failed to create symlink ${dest_path} -> ${source_path}"
      return 1
    fi
  fi
}

# Run apt-get update once per run
APT_UPDATED=0
apt_update_once() {
  if [[ "${APT_UPDATED}" -eq 0 ]]; then
    log_info "Running: sudo apt-get update"
    if sudo apt-get update -y; then
      APT_UPDATED=1
    else
      log_warn "apt-get update failed; continuing, but installs may fail."
    fi
  fi
}

# Run brew update once per run
BREW_UPDATED=0
brew_update_once() {
  if [[ "${BREW_UPDATED}" -eq 0 ]]; then
    log_info "Running: brew update"
    if brew update; then
      BREW_UPDATED=1
    else
      log_warn "brew update failed; continuing, but installs may fail."
    fi
  fi
}

# Official uv installer (always used on all platforms)
install_uv_official() {
  log_info "Installing uv using the official installer script"
  if curl -fsSL https://astral.sh/uv/install.sh | sh; then
    return 0
  else
    return 1
  fi
}

# --------------------------- Package checks ---------------------------------
command_for_package() {
  local pkg="$1"
  case "${pkg}" in
    "zellij") echo "zellij" ;;
    "helix") echo "hx" ;;
    "ripgrep") echo "rg" ;;
    "eza") echo "eza" ;;
    "bat") echo "bat" ;;
    "fd-find") echo "fd" ;;
    "uv") echo "uv" ;;
    "google cloud cli") echo "gcloud" ;;
    "npm") echo "npm" ;;
    "vim") echo "vim" ;;
    *) echo "" ;;
  esac
}

# --------------------------- Install routines --------------------------------
install_on_macos() {
  local pkg="$1"
  brew_update_once
  case "${pkg}" in
    "zellij") brew install zellij ;;
    "helix") brew install helix ;;
    "ripgrep") brew install ripgrep ;;
    "eza") brew install eza ;;
    "bat") brew install bat ;;
    "fd-find") brew install fd ;;
    "uv") install_uv_official ;;
    "google cloud cli") brew install --cask google-cloud-sdk ;;
    "npm") 
      # npm typically comes with Node.js on macOS via brew
      if ! command_exists node; then
        brew install node
      fi
      ;;
    "vim") brew install vim ;;
    *) log_warn "No macOS installer mapping for '${pkg}'. Skipping."; return 2 ;;
  esac
}

install_on_ubuntu() {
  local pkg="$1"
  case "${pkg}" in
    "zellij")
      # Prefer official release tarball for supported architectures; fallback to apt otherwise
      local arch url tmp_dir tarball bin_path
      arch="$(uname -m)"
      case "${arch}" in
        aarch64|arm64)
          url="https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-aarch64-unknown-linux-musl.tar.gz"
          ;;
        x86_64|amd64)
          url="https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-x86_64-unknown-linux-musl.tar.gz"
          ;;
        *)
          url=""
          ;;
      esac
      if [[ -n "${url}" ]]; then
        tmp_dir="$(mktemp -d)" || return 1
        tarball="${tmp_dir}/zellij.tar.gz"
        if command_exists wget; then
          if ! wget -qO "${tarball}" "${url}"; then
            log_warn "Failed to download zellij via wget; falling back to apt."
            rm -rf "${tmp_dir}"
            apt_update_once
            sudo apt-get install -y zellij || return 1
            return 0
          fi
        else
          if ! curl -fsSL -o "${tarball}" "${url}"; then
            log_warn "Failed to download zellij via curl; falling back to apt."
            rm -rf "${tmp_dir}"
            apt_update_once
            sudo apt-get install -y zellij || return 1
            return 0
          fi
        fi
        # Extract and locate the binary (archive may contain a folder)
        if tar -xzf "${tarball}" -C "${tmp_dir}" >/dev/null 2>&1; then
          bin_path="$(find "${tmp_dir}" -maxdepth 3 -type f -name zellij | head -n 1)"
          if [[ -n "${bin_path}" && -f "${bin_path}" ]]; then
            chmod +x "${bin_path}" || true
            if sudo install -m 0755 "${bin_path}" /usr/local/bin/zellij; then
              rm -rf "${tmp_dir}"
              return 0
            else
              log_warn "Failed to install zellij binary to /usr/local/bin; falling back to apt."
            fi
          else
            log_warn "zellij binary not found in extracted archive; falling back to apt."
          fi
        else
          log_warn "Failed to extract zellij archive; falling back to apt."
        fi
        rm -rf "${tmp_dir}"
      fi
      apt_update_once
      sudo apt-get install -y zellij || return 1
      ;;
    "helix")
      # Download and install official .deb package
      local tmp_dir deb_file
      tmp_dir="$(mktemp -d)" || return 1
      deb_file="${tmp_dir}/helix.deb"
      
      log_info "Downloading helix .deb package..."
      if command_exists wget; then
        if ! wget -qO "${deb_file}" "https://github.com/helix-editor/helix/releases/download/25.07.1/helix_25.7.1-1_amd64.deb"; then
          log_err "Failed to download helix .deb package"
          rm -rf "${tmp_dir}"
          return 1
        fi
      else
        if ! curl -fsSL -o "${deb_file}" "https://github.com/helix-editor/helix/releases/download/25.07.1/helix_25.7.1-1_amd64.deb"; then
          log_err "Failed to download helix .deb package"
          rm -rf "${tmp_dir}"
          return 1
        fi
      fi
      
      log_info "Installing helix from .deb package..."
      if sudo apt install -y "${deb_file}"; then
        rm -rf "${tmp_dir}"
        return 0
      else
        log_err "Failed to install helix .deb package"
        rm -rf "${tmp_dir}"
        return 1
      fi
      ;;
    "ripgrep")
      apt_update_once
      sudo apt-get install -y ripgrep || return 1
      ;;
    "eza")
      # Configure official eza APT repo if not already present, then install
      if [[ ! -f /etc/apt/sources.list.d/gierens.list ]]; then
        ensure_dir "/etc/apt/keyrings" || true
        # Ensure required tools are present
        if ! command_exists wget; then sudo apt-get install -y wget || true; fi
        if ! command_exists gpg; then sudo apt-get install -y gnupg || true; fi
        # Add signing key and repository
        if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg; then
          echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
          sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list || true
        else
          log_warn "Failed to configure eza APT keyring; attempting install from default repos."
        fi
      fi
      # Refresh package lists to include new repo (if added) and install
      sudo apt-get update -y || true
      sudo apt-get install -y eza || return 1
      ;;
    "bat")
      apt_update_once
      sudo apt-get install -y bat || return 1
      ;;
    "fd-find")
      apt_update_once
      sudo apt-get install -y fd-find || return 1
      ;;
    "uv")
      install_uv_official || return 1
      ;;
    "google cloud cli")
      if command_exists snap; then
        if sudo snap install google-cloud-cli --classic; then
          return 0
        fi
      fi
      apt_update_once
      # Try apt if repo already configured; otherwise this will fail gracefully.
      sudo apt-get install -y google-cloud-cli || return 1
      ;;
    "npm")
      # Install Node.js and npm using nvm
      local nvm_dir="${HOME}/.nvm"
      local nvm_version="v0.40.3"
      local node_version="22"
      
      # Check if nvm is already installed
      if [[ ! -d "${nvm_dir}" ]]; then
        log_info "Installing nvm ${nvm_version}..."
        if curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash; then
          log_ok "nvm installed successfully"
        else
          log_err "Failed to install nvm"
          return 1
        fi
      fi
      
      # Source nvm for current session
      if [[ -s "${nvm_dir}/nvm.sh" ]]; then
        \. "${nvm_dir}/nvm.sh"
      else
        log_err "nvm.sh not found after installation"
        return 1
      fi
      
      # Install Node.js using nvm
      log_info "Installing Node.js ${node_version} via nvm..."
      if nvm install ${node_version}; then
        log_ok "Node.js ${node_version} installed successfully"
        
        # Verify installations
        local node_ver npm_ver
        node_ver="$(node -v 2>/dev/null)" || node_ver="unknown"
        npm_ver="$(npm -v 2>/dev/null)" || npm_ver="unknown"
        log_info "Node.js version: ${node_ver}"
        log_info "npm version: ${npm_ver}"
      else
        log_err "Failed to install Node.js ${node_version}"
        return 1
      fi
      ;;
    "vim")
      apt_update_once
      sudo apt-get install -y vim || return 1
      ;;
    *) log_warn "No Ubuntu installer mapping for '${pkg}'. Skipping."; return 2 ;;
  esac
}

post_install_fixes() {
  local pkg="$1"
  case "${pkg}" in
    "fd-find")
      # On Ubuntu the binary is 'fdfind'; create 'fd' alias if needed
      ensure_cmd_alias "fdfind" "fd"
      ;;
    "bat")
      # On Ubuntu the binary is 'batcat'; create 'bat' alias if needed
      ensure_cmd_alias "batcat" "bat"
      ;;
    "google cloud cli")
      if ! command_exists gcloud; then
        log_warn "'gcloud' not found in PATH after install. You may need to add it to PATH or restart your shell."
      fi
      ;;
    "uv")
      if ! command_exists uv; then
        local uv_local
        uv_local="${HOME}/.local/bin/uv"
        if [[ -x "${uv_local}" ]]; then
          ensure_symlink_path "${uv_local}" "/usr/local/bin/uv" || log_warn "Add ${HOME}/.local/bin to PATH to use 'uv'."
        else
          log_warn "uv not found on PATH. Ensure your shell PATH includes ${HOME}/.local/bin."
        fi
      fi
      ;;
    "npm")
      if [[ "${OS}" == "ubuntu" ]] && ! command_exists npm; then
        log_warn "npm not found in PATH after install. You may need to restart your shell or source ~/.bashrc"
      fi
      ;;
  esac
}

install_package() {
  local pkg="$1"; local cmd
  cmd="$(command_for_package "${pkg}")"
  if [[ -z "${cmd}" ]]; then
    log_warn "Unknown package mapping for '${pkg}'. Skipping."
    return 0
  fi

  # Consider installed if command exists (with Ubuntu-specific aliases handled later)
  if command_exists "${cmd}"; then
    log_ok "${pkg} already installed (${cmd} found)."
    return 0
  fi

  # Special checks for Ubuntu where command names differ
  if [[ "${OS}" == "ubuntu" ]]; then
    if [[ "${pkg}" == "bat" ]] && command_exists batcat; then
      log_ok "bat already installed (batcat found)."
      ensure_cmd_alias "batcat" "bat"
      return 0
    fi
    if [[ "${pkg}" == "fd-find" ]] && command_exists fdfind; then
      log_ok "fd-find already installed (fdfind found)."
      ensure_cmd_alias "fdfind" "fd"
      return 0
    fi
  fi

  log_info "Installing ${pkg}..."
  if [[ "${OS}" == "macos" ]]; then
    if install_on_macos "${pkg}"; then
      log_ok "Installed ${pkg} on macOS."
    else
      log_err "Failed to install ${pkg} on macOS."
      return 1
    fi
  else
    if install_on_ubuntu "${pkg}"; then
      log_ok "Installed ${pkg} on Ubuntu/Debian."
    else
      log_err "Failed to install ${pkg} on Ubuntu/Debian."
      return 1
    fi
  fi

  post_install_fixes "${pkg}"
}

# ------------------------------ Package list --------------------------------

# Edit this list to add/remove default packages
PACKAGES=(
  "zellij"
  "helix"
  "ripgrep"
  "eza"
  "bat"
  "fd-find"
  "uv"
  "google cloud cli"
  "npm"
  "vim"
)

# ------------------------------- Main ---------------------------------------

log_info "Installing standard toolchain packages"

FAILED_PACKAGES=()

for pkg in "${PACKAGES[@]}"; do
  install_package "${pkg}" || FAILED_PACKAGES+=("${pkg}")
done

if (( ${#FAILED_PACKAGES[@]} > 0 )); then
  log_warn "Some packages failed to install: ${FAILED_PACKAGES[*]}"
  exit 2
fi

uv tool install pyright

curl -sS https://starship.rs/install.sh | sudo sh 

# Install Claude Code CLI globally if npm is available
if command_exists npm; then
  log_info "Installing @anthropic-ai/claude-code globally..."
  if npm install -g @anthropic-ai/claude-code; then
    log_ok "@anthropic-ai/claude-code installed globally"
  else
    log_warn "Failed to install @anthropic-ai/claude-code globally"
  fi
else
  log_warn "npm not found; skipping @anthropic-ai/claude-code installation"
fi

log_ok "All requested packages are installed or already present."

