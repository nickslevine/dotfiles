export PATH="$HOME/.local/bin:$PATH"
export TERM="xterm-256color"
export COLORTERM=truecolor
export EDITOR=hx
export HF_TOKEN=$(gcloud secrets versions access latest --secret="HF_TOKEN" 2>/dev/null || echo "")
export WANDB_API_KEY=$(gcloud secrets versions access latest --secret="WANDB_API_KEY" 2>/dev/null || echo "")
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 

alias ll='eza -lha'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'


alias gs='git status'
alias gc='git commit -m'

alias rm='rm -i'   # confirm before delete
alias cp='cp -i'   # confirm before overwrite

ssh-add ~/.ssh/devbox_github

eval "$(starship init bash)"


# The next line updates PATH for the Google Cloud SDK.
# if [ -f '/Users/nlevine/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/nlevine/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
# if [ -f '/Users/nlevine/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/nlevine/google-cloud-sdk/completion.zsh.inc'; fi

