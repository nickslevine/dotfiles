cd ~
git clone https://github.com/nickslevine/dotfiles.git
cd dotfiles
bash setup-auth.sh
bash install-packages.sh
bash copy-dotfiles.sh
bash setup-shell.sh
bash setup-api-keys.sh
source ~/.zshrc