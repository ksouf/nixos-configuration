#!/usr/bin/env bash
# Pre-commit hook: Validate NixOS configuration before committing
# Runs basic syntax checks and logs commit events

set -euo pipefail

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Check if nix-instantiate is available
if command -v nix-instantiate &> /dev/null; then
    # Validate Nix syntax for staged .nix files
    ERRORS=""
    for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.nix$' || true); do
        if [ -f "$file" ]; then
            if ! nix-instantiate --parse "$file" &>/dev/null; then
                ERRORS="$ERRORS\n  - $file"
            fi
        fi
    done

    if [ -n "$ERRORS" ]; then
        echo "ERROR: Nix syntax errors in:$ERRORS"
        echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"pre-commit-failed\", \"reason\": \"nix-syntax\", \"files\": \"$ERRORS\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true
        exit 1
    fi
fi

# Log successful pre-commit check
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"pre-commit-passed\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true

exit 0
