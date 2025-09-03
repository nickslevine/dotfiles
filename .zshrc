export PATH="/root/.local/bin:$PATH"
export TERM="xterm-256color"
export COLORTERM=truecolor
export HF_TOKEN=$(gcloud secrets versions access latest --secret="HF_TOKEN" 2>/dev/null || echo "")
export WANDB_API_KEY=$(gcloud secrets versions access latest --secret="WANDB_API_KEY" 2>/dev/null || echo "")
ssh-add ~/.ssh/devbox_github


ZSH_DISABLE_COMPFIX=true

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search themes)

source $ZSH/oh-my-zsh.sh
eval "$(starship init zsh)"
