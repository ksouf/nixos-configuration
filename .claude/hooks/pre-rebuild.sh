#!/usr/bin/env bash
# Pre-rebuild hook: Validates NixOS configuration before nixos-rebuild
# Input: JSON on stdin from Claude Code hooks API (PreToolUse on Bash)

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Read stdin (hook JSON input)
INPUT=$(cat)

# Extract the command being run
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"$//')

# Only run for nixos-rebuild switch/test commands
case "$COMMAND" in
    *nixos-rebuild\ switch*|*nixos-rebuild\ test*)
        ;;
    *)
        exit 0
        ;;
esac

echo ""
echo "PRE-REBUILD VALIDATION"
echo "======================"

# 1. Syntax check all modified .nix files
ERRORS=""
for file in $(git -C /etc/nixos diff --name-only HEAD -- "*.nix" 2>/dev/null); do
    filepath="/etc/nixos/$file"
    if [ -f "$filepath" ]; then
        if ! nix-instantiate --parse "$filepath" > /dev/null 2>&1; then
            ERRORS="$ERRORS\n  - $file"
        fi
    fi
done

if [ -n "$ERRORS" ]; then
    echo "BLOCKED: Nix syntax errors in:$ERRORS"
    echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"pre-rebuild-blocked\", \"reason\": \"nix-syntax\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true
    exit 1
fi
echo "  Syntax: OK"

# 2. Flake check
if ! nix flake check /etc/nixos 2>/dev/null; then
    echo "BLOCKED: nix flake check failed"
    echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"pre-rebuild-blocked\", \"reason\": \"flake-check\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true
    exit 1
fi
echo "  Flake check: OK"

echo "  Validation passed - proceeding with rebuild"
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"pre-rebuild-passed\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true

exit 0
