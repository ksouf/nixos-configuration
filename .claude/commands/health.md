# Command: /health

System health dashboard - overall self-improvement metrics.

## Process

### Step 1: Gather Metrics
```bash
MEMORY="/etc/nixos/.claude/memory"

echo "SYSTEM HEALTH DASHBOARD"
echo "======================="
echo ""

# Build health
echo "BUILD HEALTH"
BUILDS=$(grep -c "build_" "$MEMORY/metrics.jsonl" 2>/dev/null || echo 0)
SUCCESS=$(grep -c "build_success" "$MEMORY/metrics.jsonl" 2>/dev/null || echo 0)
FAIL=$(grep -c "build_failure" "$MEMORY/metrics.jsonl" 2>/dev/null || echo 0)
[ "$BUILDS" -gt 0 ] && echo "  Success rate: $((SUCCESS * 100 / BUILDS))% ($SUCCESS/$BUILDS)" || echo "  No builds tracked"

# Automation health
echo ""
echo "AUTOMATION HEALTH"
TOTAL=$(wc -l < "$MEMORY/interactions.jsonl" 2>/dev/null || echo 0)
AUTO=$(grep -c '"manual":false' "$MEMORY/interactions.jsonl" 2>/dev/null || echo 0)
[ "$TOTAL" -gt 0 ] && echo "  Automation rate: $((AUTO * 100 / TOTAL))%" || echo "  No tasks tracked"

# Improvement velocity
echo ""
echo "IMPROVEMENT VELOCITY"
TOTAL_IMP=$(wc -l < "$MEMORY/improvements.jsonl" 2>/dev/null || echo 0)
echo "  Total improvements: $TOTAL_IMP"

# Knowledge growth
echo ""
echo "KNOWLEDGE GROWTH"
PATTERNS=$(find /etc/nixos/.claude/knowledge/patterns -name "*.md" 2>/dev/null | wc -l)
GOTCHAS=$(find /etc/nixos/.claude/knowledge/gotchas -name "*.md" 2>/dev/null | wc -l)
echo "  Patterns documented: $PATTERNS"
echo "  Gotchas captured: $GOTCHAS"

# Skills coverage
echo ""
echo "SKILLS COVERAGE"
SKILLS=$(find /etc/nixos/.claude/skills -name "SKILL.md" 2>/dev/null | wc -l)
echo "  Active skills: $SKILLS"

# Proposal backlog
echo ""
echo "PROPOSAL BACKLOG"
PENDING=$(grep -c '"status":"proposed"' "$MEMORY/proposals.jsonl" 2>/dev/null || echo 0)
HIGH=$(grep '"status":"proposed"' "$MEMORY/proposals.jsonl" 2>/dev/null | grep -c '"priority":"high"')
echo "  Pending: $PENDING (high priority: $HIGH)"
```

### Step 2: Calculate Health Score
```bash
echo ""
echo "======================="
SCORE=0
# Build success >80%
[ "$BUILDS" -gt 0 ] && [ "$SUCCESS" -gt "$((BUILDS * 80 / 100))" ] && SCORE=$((SCORE + 25))
# Automation >80%
[ "$TOTAL" -gt 0 ] && [ "$AUTO" -gt "$((TOTAL * 80 / 100))" ] && SCORE=$((SCORE + 25))
# Improvements made
[ "$TOTAL_IMP" -gt 10 ] && SCORE=$((SCORE + 25))
# Skills defined
[ "$SKILLS" -ge 3 ] && SCORE=$((SCORE + 25))

echo "HEALTH SCORE: $SCORE/100"
```

## Health Indicators

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Build success | >90% | 70-90% | <70% |
| Automation rate | >80% | 50-80% | <50% |
| Improvements/week | >5 | 2-5 | <2 |
| Pending proposals | <5 | 5-10 | >10 |
| Skills defined | >3 | 2-3 | <2 |

## Output
```
SYSTEM HEALTH DASHBOARD
=======================

BUILD: [status]
  Success rate: [X]%

AUTOMATION: [status]
  Automation rate: [X]%

KNOWLEDGE: [status]
  Patterns: [N]
  Gotchas: [N]
  Skills: [N]

BACKLOG: [status]
  Pending: [N]

-----------------------
HEALTH SCORE: [X]/100
```

## Invocation
User says: "health", "/health", "system health", "status"
