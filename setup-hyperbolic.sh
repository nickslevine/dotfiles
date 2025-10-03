# Install Packages
## update
sudo apt-get update

## uv
curl -fsSL https://astral.sh/uv/install.sh | sh
uv tool install pyright

## Install npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default node

npm install -g @anthropic-ai/claude-code
## Ripgrep
sudo apt-get install -y ripgrep 

## Helix
tmp_dir="$(mktemp -d)" || return 1
deb_file="${tmp_dir}/helix.deb"
sudo apt install -y "${deb_file}"

## Starship
curl -sS https://starship.rs/install.sh | sudo sh

# Dotfiles
bash ./copy-dotfiles.sh


