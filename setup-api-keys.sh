# Set HF_TOKEN from Google Cloud Secret Manager
if ! grep -q "export HF_TOKEN=" ~/.zshrc 2>/dev/null; then
    echo 'export HF_TOKEN=$(gcloud secrets versions access latest --secret="HF_TOKEN" 2>/dev/null || echo "")' >> ~/.zshrc || {
        log_error "Failed to add HF_TOKEN variable to zshrc"
        exit 1
    }
fi

# Set WANDB_API_KEY from Google Cloud Secret Manager
if ! grep -q "export WANDB_API_KEY=" ~/.zshrc 2>/dev/null; then
    echo 'export WANDB_API_KEY=$(gcloud secrets versions access latest --secret="WANDB_API_KEY" 2>/dev/null || echo "")' >> ~/.zshrc || {
        log_error "Failed to add WANDB_API_KEY variable to zshrc"
        exit 1
    }
fi