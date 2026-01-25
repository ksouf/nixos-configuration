#!/usr/bin/env bash
# v3.0 - Triple iteration reminder with meta trigger

MEMORY_DIR="/etc/nixos/.claude/memory"

# Count tasks since last meta-cycle
TASK_COUNT=$(wc -l < "$MEMORY_DIR/interactions.jsonl" 2>/dev/null || echo 0)
LAST_META=$(grep -c '"event":"meta_cycle"' "$MEMORY_DIR/evolution.jsonl" 2>/dev/null || echo 0)
TASKS_SINCE_META=$((TASK_COUNT - LAST_META * 5))

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║            TRIPLE ITERATION PROTOCOL (v3.0)                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "  CYCLE 1: /iterate    - Validate changes"
echo "    • Syntax check modified .nix files"
echo "    • nix flake check"
echo "    • nixos-rebuild build"
echo ""
echo "  CYCLE 2: /improve    - Check 18 rules (S1-K3)"
echo "    • Apply improvements"
echo "    • Commit changes"

if [ "$TASKS_SINCE_META" -ge 5 ]; then
    echo ""
    echo "  ⚡ CYCLE 3: /meta     - META-IMPROVEMENT DUE!"
    echo "     ($TASKS_SINCE_META tasks since last meta-analysis)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Run /complete for all cycles"
echo ""
exit 0
