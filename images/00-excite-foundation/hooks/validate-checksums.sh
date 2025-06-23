#!/bin/bash
set -euo pipefail

CHECKSUM_DIR="/usr/local/checksums"
SOURCE_DIR="/usr/local/src"

_log() {
    if [[ "$*" == "ERROR:"* || "$*" == "WARNING:"* || -z "${EXC_VERBOSE:-}" ]]; then
        echo "$@" >&2
    fi
}

_log "[INFO] Validating checksums for files in ${SOURCE_DIR}"

for checksum_file in "${CHECKSUM_DIR}"/*.sha256; do
    file_name="$(basename "$checksum_file" .sha256)"
    src_file="${SOURCE_DIR}/${file_name}"

    if [[ ! -f "$src_file" ]]; then
        _log "WARNING: Source file not found: $src_file, skipping"
        continue
    fi

    _log "[INFO] Checking $file_name..."
    if ! sha256sum -c "$checksum_file"; then
        _log "ERROR: Checksum failed for $file_name"
        exit 1
    fi
done

_log "[INFO] All checksums validated successfully."
