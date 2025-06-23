#!/bin/bash
set -euo pipefail

_log () {
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${EXC_VERBOSE:-}" == "" ]]; then
        echo "${timestamp} $@" >&2
    fi
}

_log "Entered start.sh with args: $*"

HOOK_DIR="/usr/local/bin/hooks"
HOOK_SCRIPT="/usr/local/bin/run-hooks.sh"

if [[ -d "${HOOK_DIR}" ]]; then
    if [[ ! -x "${HOOK_SCRIPT}" ]]; then
        _log "ERROR: Expected hook script ${HOOK_SCRIPT} not found or not executable"
        exit 1
    fi
    _log "Running hooks in ${HOOK_DIR}"
    source "${HOOK_SCRIPT}" "${HOOK_DIR}"
else
    _log "No hooks directory found at ${HOOK_DIR}; skipping hook execution"
fi

if [[ $# -eq 0 ]]; then
    _log "No command provided. Starting interactive bash shell."
    exec bash
else
    _log "Executing command: $*"
    exec "$@"
fi
