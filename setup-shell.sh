#!/usr/bin/env bash
set -euo pipefail

ZSH=~/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom

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

RUNZSH=yes CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

# If running in an interactive terminal, replace the current process with zsh
if [ -t 1 ]; then
  exec "${zsh_path}"
else
  echo "Default shell set to zsh. Start a new terminal or run: exec zsh"
fi

