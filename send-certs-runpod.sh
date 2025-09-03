PEM_FILE="/Users/nlevine/.ssh/id_ed25519"

# Usage: ./send-certs.sh <DEVBOX_IP>
DEVBOX_IP="${1:-}"
if [[ -z "${DEVBOX_IP}" ]]; then
echo "Usage: $0 <DEVBOX_IP>"
exit 1
fi

echo "📁 Copying credentials..."
scp -P 11462 -i "${PEM_FILE}"  ~/.ssh/devbox_github root@"${DEVBOX_IP}":devbox_github
scp -P 11462 -i "${PEM_FILE}"  ~/.devbox/sa-key.json root@"${DEVBOX_IP}":sa-key.json
scp -P 11462 -i "${PEM_FILE}"  ~/Dev/dotfiles/setup.sh root@"${DEVBOX_IP}":setup.sh
