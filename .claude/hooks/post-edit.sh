#!/usr/bin/env bash
# Post-edit hook: Triggered after Claude Code edits a file
# Records the edit in memory for pattern analysis

set -euo pipefail

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Get file info from environment (if provided by Claude Code hooks)
FILE_PATH="${CLAUDE_EDIT_FILE:-unknown}"
TOOL_NAME="${CLAUDE_TOOL_NAME:-Edit}"

# Log the edit event
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"edit\", \"file\": \"$FILE_PATH\", \"tool\": \"$TOOL_NAME\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true

# Exit successfully to not block Claude
exit 0
