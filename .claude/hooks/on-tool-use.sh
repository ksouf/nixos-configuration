#!/usr/bin/env bash
# On-tool-use hook: Triggered when Claude uses any tool
# Tracks tool usage patterns for learning
# Input: JSON on stdin from Claude Code hooks API

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Read JSON from stdin
INPUT=$(cat)

# Extract tool name from JSON
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | sed 's/"tool_name":"//;s/"$//')
: "${TOOL_NAME:=unknown}"

# Log tool usage
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"tool-use\", \"tool\": \"$TOOL_NAME\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true

exit 0
