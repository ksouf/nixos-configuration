#!/usr/bin/env bash
# On-tool-use hook: Triggered when Claude uses any tool
# Tracks tool usage patterns for learning

set -euo pipefail

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Tool info from Claude Code
TOOL_NAME="${1:-unknown}"
TOOL_INPUT="${2:-}"

# Log tool usage
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"tool-use\", \"tool\": \"$TOOL_NAME\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true

exit 0
