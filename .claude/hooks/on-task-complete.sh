#!/usr/bin/env bash
# v3.1 - Triple iteration reminder with automatic improvement logging

MEMORY_DIR="/etc/nixos/.claude/memory"
TIMESTAMP=$(date -Iseconds)

# Log task completion event
echo "{\"ts\":\"$TIMESTAMP\",\"event\":\"task_complete\"}" >> "$MEMORY_DIR/metrics.jsonl" 2>/dev/null || true

# Count tasks since last meta-cycle
TASK_COUNT=$(grep -c '"task_complete"' "$MEMORY_DIR/metrics.jsonl" 2>/dev/null || echo 0)
META_COUNT=$(grep -c '"meta_cycle"' "$MEMORY_DIR/metrics.jsonl" 2>/dev/null || echo 0)
TASKS_SINCE_META=$((TASK_COUNT - META_COUNT * 5))

echo ""
echo "TASK COMPLETE - Run /complete for full iteration cycles"

if [ "$TASKS_SINCE_META" -ge 5 ]; then
    echo ""
    echo "  META-IMPROVEMENT DUE! ($TASKS_SINCE_META tasks since last meta-analysis)"
    echo "  Run /meta to trigger meta-improvement cycle"
fi

echo ""
exit 0
