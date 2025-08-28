PEM_FILE="/Users/nlevine/.ssh/vintage-lm.pem"

# Usage: ./send-certs.sh <DEVBOX_IP>
DEVBOX_IP="${1:-}"
if [[ -z "${DEVBOX_IP}" ]]; then
echo "Usage: $0 <DEVBOX_IP>"
exit 1
fi

echo "📁 Copying credentials..."
scp -i "${PEM_FILE}" ~/.ssh/devbox_github ubuntu@"${DEVBOX_IP}":devbox_github
scp -i "${PEM_FILE}" ~/.devbox/sa-key.json ubuntu@"${DEVBOX_IP}":sa-key.json
scp -i "${PEM_FILE}" ~/Dev/dotfiles/setup.sh ubuntu@"${DEVBOX_IP}":setup.sh
