
set -euo pipefail

# Setup logging
LOGFILE="$HOME/devbox-setup.log"
exec 1> >(tee -a "$LOGFILE")
exec 2> >(tee -a "$LOGFILE" >&2)

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
}

cleanup() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Setup failed at line $1. Check $LOGFILE for details." >&2
    exit 1
}

trap 'cleanup $LINENO' ERR

log_info "🚀 Starting devbox setup..."
log_info "Logging to: $LOGFILE"

# 1. Setup GitHub SSH authentication
log_info "🔑 Setting up GitHub SSH authentication..."

if [[ ! -f ~/devbox_github ]]; then
    log_error "SSH key file ~/devbox_github not found"
    exit 1
fi

mkdir -p ~/.ssh || {
    log_error "Failed to create ~/.ssh directory"
    exit 1
}

mv ~/devbox_github ~/.ssh/devbox_github || {
    log_error "Failed to move SSH key"
    exit 1
}

chmod 600 ~/.ssh/devbox_github || {
    log_error "Failed to set SSH key permissions"
    exit 1
}

# Add SSH key to agent and configure for GitHub
eval "$(ssh-agent -s)" || {
    log_error "Failed to start SSH agent"
    exit 1
}

ssh-add ~/.ssh/devbox_github || {
    log_error "Failed to add SSH key to agent"
    exit 1
}

# Configure SSH for GitHub
cat >> ~/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/devbox_github
    IdentitiesOnly yes
EOF

if [[ $? -ne 0 ]]; then
    log_error "Failed to configure SSH for GitHub"
    exit 1
fi

chmod 600 ~/.ssh/config || {
    log_error "Failed to set SSH config permissions"
    exit 1
}

log_success "GitHub SSH authentication configured"

# Verify SSH key is loaded
log_info "Verifying SSH key is loaded..."
ssh-add -l || {
    log_error "No SSH keys loaded in agent"
    exit 1
}

# 2. Setup Google Cloud authentication
log_info "☁️  Setting up Google Cloud authentication..."

if [[ ! -f ~/sa-key.json ]]; then
    log_error "Service account key ~/sa-key.json not found"
    exit 1
fi

export GOOGLE_APPLICATION_CREDENTIALS=$HOME/sa-key.json


# Activate service account
gcloud auth activate-service-account --key-file=$HOME/sa-key.json || {
    log_error "Failed to activate service account"
    exit 1
}

log_success "Google Cloud authentication configured"
