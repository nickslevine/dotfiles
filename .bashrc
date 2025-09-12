export PATH="$HOME/.local/bin:$PATH"
export TERM="xterm-256color"
export COLORTERM=truecolor
export HF_TOKEN=$(gcloud secrets versions access latest --secret="HF_TOKEN" 2>/dev/null || echo "")
export WANDB_API_KEY=$(gcloud secrets versions access latest --secret="WANDB_API_KEY" 2>/dev/null || echo "")
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
alias ll="eza -l"


ssh-add ~/.ssh/devbox_github

eval "$(starship init bash)"

