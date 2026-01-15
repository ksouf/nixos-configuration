#!/usr/bin/env bash
# Post-edit hook: Triggered after Claude Code edits a file
# Records the edit in memory and validates Nix syntax

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Get file info from environment (if provided by Claude Code hooks)
FILE_PATH="${CLAUDE_EDIT_FILE:-unknown}"
TOOL_NAME="${CLAUDE_TOOL_NAME:-Edit}"

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
