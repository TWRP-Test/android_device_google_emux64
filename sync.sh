#!/bin/bash
# Sync this device tree to the WSL TWRP source tree.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
DEST=${DEST:-/home/yukonga/twrp-16.0/device/google/emux64}

mkdir -p "$DEST"
rsync -a --delete \
  --exclude artifacts \
  --exclude .git \
  "$SCRIPT_DIR/" "$DEST/"

echo "Synced to $DEST"