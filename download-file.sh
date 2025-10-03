#!/usr/bin/env bash
set -euo pipefail

IDENTITY_KEY_PATH="${IDENTITY_KEY_PATH:-$HOME/.ssh/id_ed25519}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") -p PORT -a ADDRESS -f REMOTE_PATH [-o OUTPUT_DIR]

Positional alternative:
  $(basename "$0") PORT ADDRESS REMOTE_PATH [OUTPUT_DIR]

Arguments:
  -p, --port          SSH port on the remote host (required)
  -a, --address       Remote host IP or hostname (required)
  -f, --file          Remote path to file, e.g. /workspace/file.png (required)
  -o, --output        Local output directory (default: current directory)
  -h, --help          Show this help and exit

Environment:
  IDENTITY_KEY_PATH   SSH identity file (default: ~/.ssh/id_ed25519)

Example:
  $(basename "$0") -p 11050 -a 205.196.17.131 -f /workspace/ocr/pdf-pngs/ia-random/afterwarreadjust00millrich_page_0000001.png -o .
EOF
}

if [[ ${#} -eq 0 ]]; then
  usage
  exit 1
fi

PORT=""
ADDRESS=""
REMOTE_PATH=""
OUTPUT_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      PORT="${2:-}"
      shift 2
      ;;
    -a|--address)
      ADDRESS="${2:-}"
      shift 2
      ;;
    -f|--file|--path)
      REMOTE_PATH="${2:-}"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -z "$PORT" ]]; then
        PORT="$1"
      elif [[ -z "$ADDRESS" ]]; then
        ADDRESS="$1"
      elif [[ -z "$REMOTE_PATH" ]]; then
        REMOTE_PATH="$1"
      elif [[ "$OUTPUT_DIR" == "." ]]; then
        OUTPUT_DIR="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$PORT" || -z "$ADDRESS" || -z "$REMOTE_PATH" ]]; then
  echo "Error: port, address, and remote file path are required." >&2
  usage
  exit 1
fi

if [[ ! -f "$IDENTITY_KEY_PATH" ]]; then
  echo "Error: identity key not found at $IDENTITY_KEY_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Downloading from root@${ADDRESS}:${REMOTE_PATH} to ${OUTPUT_DIR} via port ${PORT}..."

scp -P "$PORT" -i "$IDENTITY_KEY_PATH" "root@${ADDRESS}:${REMOTE_PATH}" "$OUTPUT_DIR"

echo "Done."
