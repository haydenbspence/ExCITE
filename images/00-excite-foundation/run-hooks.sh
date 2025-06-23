#!/bin/bash
set -euo pipefail

# Define _log only if it hasn't been declared
if ! declare -F _log > /dev/null; then
    _log() {
        if [[ "$*" == "ERROR:"* || "$*" == "WARNING:"* || -z "${EXC_VERBOSE:-}" ]]; then
            echo "$@" >&2
        fi
    }
fi

# Validate argument count
if [[ $# -ne 1 ]]; then
    _log "ERROR: Expected exactly one argument: the directory to scan for hooks"
    exit 1
fi

HOOK_DIR="$1"

# Validate directory existence
if [[ ! -d "$HOOK_DIR" ]]; then
    _log "ERROR: Provided path '$HOOK_DIR' is not a directory or doesn't exist"
    exit 1
fi

_log "Running hooks in: $HOOK_DIR as uid: $(id -u) gid: $(id -g)"

# Loop over all files in the hook directory
for f in "$HOOK_DIR"/*; do
    [[ -e "$f" ]] || continue
    case "$f" in
        *.sh)
            _log "Sourcing shell script: $f"
            # shellcheck disable=SC1090
            source "$f" || _log "ERROR: $f failed, continuing"
            ;;
        *)
            if [[ -x "$f" ]]; then
                _log "Running executable: $f"
                "$f" || _log "ERROR: $f failed, continuing"
            else
                _log "Ignoring non-executable file: $f"
            fi
            ;;
    esac
done

_log "Done running hooks in: $HOOK_DIR"
