#!/usr/bin/env bash
# Post-edit hook: Triggered after Claude Code edits a file
# Records the edit in memory and validates Nix syntax
# Input: JSON on stdin from Claude Code hooks API

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Read JSON from stdin
INPUT=$(cat)

# Extract file_path from tool_input using grep/sed (no jq dependency)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"$//')
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | sed 's/"tool_name":"//;s/"$//')
: "${FILE_PATH:=unknown}"
: "${TOOL_NAME:=Edit}"

# Log the edit event
echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"edit\", \"file\": \"$FILE_PATH\", \"tool\": \"$TOOL_NAME\"}" >> "$MEMORY_DIR/events.jsonl" 2>/dev/null || true

# Syntax check for .nix files
case "$FILE_PATH" in
    *.nix)
        if [ -f "$FILE_PATH" ] && command -v nix-instantiate &> /dev/null; then
            echo ""
            echo "POST-EDIT: $FILE_PATH"
            if nix-instantiate --parse "$FILE_PATH" > /dev/null 2>&1; then
                echo "Syntax: OK"
            else
                echo "Syntax: ERROR"
                nix-instantiate --parse "$FILE_PATH" 2>&1 | head -5
                echo ""
                echo "Fix syntax before continuing!"
            fi
            echo "---"
        fi
        ;;
esac

# Exit successfully to not block Claude
exit 0
