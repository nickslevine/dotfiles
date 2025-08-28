#!/usr/bin/env bash
set -euo pipefail

zsh_path="$(command -v zsh || true)"
if [ -z "${zsh_path}" ]; then
  echo "zsh not found in PATH" >&2
  exit 1
fi

# Ensure zsh is listed in /etc/shells
if ! grep -qx "${zsh_path}" /etc/shells 2>/dev/null; then
  echo "${zsh_path}" | sudo tee -a /etc/shells >/dev/null
fi

# Set default shell to zsh for the current user
if [ "${SHELL:-}" != "${zsh_path}" ]; then
  sudo chsh -s /usr/bin/zsh "$USER"
fi

# If running in an interactive terminal, replace the current process with zsh
if [ -t 1 ]; then
  exec "${zsh_path}"
else
  echo "Default shell set to zsh. Start a new terminal or run: exec zsh"
fi
