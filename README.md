# Dotfiles

Idempotent developer environment bootstrap for macOS and Ubuntu.

What this does
- Clone/update the repo and prefer SSH if available.
- Optionally configure GitHub SSH + Google Cloud auth when creds are present.
- Install core CLI tools (Homebrew on macOS; apt on Ubuntu).
- Place editor/shell configs (Helix, Starship, shell rc files).

Quick start
1) Ensure prerequisites
- macOS: Install Homebrew from https://brew.sh
- Ubuntu/Debian: `apt-get` available with sudo privileges

2) Remote bootstrap (one‑liner)
Run this to clone/update and execute `setup.sh`:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/nickslevine/dotfiles/main/bootstrap.sh)"
```

Options:
- Use SSH when cloning: `USE_SSH=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/nickslevine/dotfiles/main/bootstrap.sh)"`
- Choose directory: `DOTFILES_DIR=~/work/dotfiles bash -c "$(curl -fsSL https://raw.githubusercontent.com/nickslevine/dotfiles/main/bootstrap.sh)"`
- Include shell extras: `RUN_SHELL_SETUP=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/nickslevine/dotfiles/main/bootstrap.sh)"`

Alternative: clone manually
```bash
git clone https://github.com/nickslevine/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

3) (Optional) Place credentials so auth can run
- `~/devbox_github` for GitHub SSH
- `~/sa-key.json` for Google Cloud

4) Bootstrap
```bash
make bootstrap
# or
./setup.sh
```

Optional targets
- `make install` — install CLI packages only
- `make link` — copy dotfiles into `~/.config` and `$HOME`
- `make auth` — configure GitHub SSH and GCP auth (if creds exist)
- `make shell-setup` — run optional shell setup via `setup.sh`

Notes
- `setup.sh` auto-detects SSH readiness and switches the Git remote to SSH when possible.
- To include shell extras, run: `RUN_SHELL_SETUP=1 ./setup.sh` (or `make shell-setup`).
- Helix and Starship config files land in `~/.config/helix` and `~/.config/starship.toml`.

Troubleshooting
- Homebrew missing on macOS: install it first, then re-run.
- If SSH auth isn’t ready, cloning uses HTTPS; you can re-run after `make auth`.
