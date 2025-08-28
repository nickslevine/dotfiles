cd ~
git clone https://github.com/nickslevine/dotfiles.git
cd dotfiles
bash setup-auth.sh
bash install-packages.sh
bash copy-dotfiles.sh
sudo bash setup-shell.sh
source ~/.zshrc