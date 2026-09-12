#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE="/home/yukonga/Documents/twrp-16.0/out/target/product/emux64/ramdisk-recovery.cpio"
SOURCE="${1:-${DEFAULT_SOURCE}}"
DEST_DIR="${SCRIPT_DIR}/artifacts"
DEST="${DEST_DIR}/ramdisk-recovery.cpio"
TEMP="${DEST}.tmp.$$"

cleanup() {
    rm -f -- "${TEMP}"
}
trap cleanup EXIT

if [[ ! -f "${SOURCE}" ]]; then
    echo "Missing source ramdisk: ${SOURCE}" >&2
    exit 1
fi

mkdir -p "${DEST_DIR}"
cp -- "${SOURCE}" "${TEMP}"
mv -f -- "${TEMP}" "${DEST}"

echo "Updated: ${DEST}"
ls -lh -- "${DEST}"
