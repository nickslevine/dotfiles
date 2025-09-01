#!/bin/zsh

set -e
set -u
set -o pipefail

# Absolute path to the directory containing this script (portable across shells)
SCRIPT_DIR="$(cd "$(dirname -- "$0")" >/dev/null 2>&1 && pwd -P)"

HOME_DIR="${HOME}"

files=(.zshrc .gitconfig)

for file in ${files[@]}; do
  src_path="${SCRIPT_DIR}/${file}"
  dst_path="${HOME_DIR}/${file}"

  if [ ! -f "${src_path}" ]; then
    echo "Source file not found: ${src_path}" >&2
    exit 1
  fi

  echo "Copying ${src_path} -> ${dst_path}"
  cp -v "${src_path}" "${dst_path}"
done

# Helix languages.toml
helix_src="${SCRIPT_DIR}/helix/languages.toml"
helix_src_c="${SCRIPT_DIR}/helix/config.toml"
helix_dst_dir="${HOME_DIR}/.config/helix"
helix_dst_c="${helix_dst_dir}/config.toml"
helix_dst_l="${helix_dst_dir}/languages.toml"

if [ ! -f "${helix_src}" ]; then
  echo "Source file not found: ${helix_src}" >&2
  exit 1
fi

mkdir -p "${helix_dst_dir}"
cp -v "${helix_src}" "${helix_dst_l}"
cp -v "${helix_src_c}" "${helix_dst_c}"
cp -v "${SCRIPT_DIR}/starship.toml" "${HOME_DIR}/.config/starship.toml"


echo "Dotfiles copied successfully."

