export PATH="$HOME/.local/bin:$PATH"
export TERM="xterm-256color"
export COLORTERM=truecolor
export HF_TOKEN=$(gcloud secrets versions access latest --secret="HF_TOKEN" 2>/dev/null || echo "")
export WANDB_API_KEY=$(gcloud secrets versions access latest --secret="WANDB_API_KEY" 2>/dev/null || echo "")
alias sshconf="$EDITOR ~/.ssh/config"


eval "$(starship init zsh)"

