# Command: /gaps

Quick gap analysis - find what's missing in the automation system.

## Process

### Step 1: Analyze Interactions
```bash
MEMORY="/etc/nixos/.claude/memory"

echo "=== GAP ANALYSIS ==="
echo ""

# Tasks without skills
echo "Tasks without skill triggers:"
grep '"skills":\[\]' "$MEMORY/interactions.jsonl" 2>/dev/null | \
  grep -oh '"task":"[^"]*"' | sort | uniq -c | sort -rn | head -5

# Repeated manual work
echo ""
echo "Repeated manual tasks (SHOULD BE AUTOMATED):"
grep '"manual":true' "$MEMORY/interactions.jsonl" 2>/dev/null | \
  grep -oh '"task":"[^"]*"' | sort | uniq -c | sort -rn | \
  while read count task; do
    [ "$count" -ge 2 ] && echo "  $task: $count times"
  done

# Failed builds
echo ""
echo "Recent build failures:"
grep "build_failure" "$MEMORY/metrics.jsonl" 2>/dev/null | tail -5 | \
  grep -oh '"error":"[^"]*"' | sed 's/"error":"/  /; s/"$//'
```

### Step 2: Check Rule Coverage
```bash
echo ""
echo "Rules never triggered (may need fixing):"
TRIGGERED=$(grep -oh '"[A-Z][0-9]*"' "$MEMORY/improvements.jsonl" 2>/dev/null | sort -u)
for rule in S1 S2 S3 S4 S5 A1 A2 A3 A4 A5 H1 H2 H3 H4 R1 R2 R3 R4 R5 K1 K2 K3; do
  echo "$TRIGGERED" | grep -q "$rule" || echo "  $rule never triggered"
done
```

### Step 3: Identify Gap Types

| Gap Type | Indicator | Solution |
|----------|-----------|----------|
| Missing skill | Task done 2x+ without skill | Create skill |
| Incomplete skill | Skill triggered but missed | Update skill |
| Missing agent | Specialized task repeated | Create agent |
| Missing hook | Manual validation repeated | Add hook |
| Missing rule | Standard violated repeatedly | Add to CLAUDE.md |
| Dead rule | Rule never triggers | Fix or remove |
| Ineffective rule | Rule triggers, doesn't help | Improve action |

### Step 4: Generate Recommendations
For each gap found, suggest:
- What to create/update
- Priority (high/medium/low)
- Effort estimate (trivial/small/medium/large)

## Output
```
GAP ANALYSIS RESULTS
====================
Tasks without skills: [N]
Repeated manual tasks: [N]
Build failures: [N]
Dead rules: [N]

Top Gaps:
  1. [gap] - Priority: [high/medium/low]
  2. [gap] - Priority: [high/medium/low]

Recommendations:
  - Create skill for [pattern]
  - Fix detection for rule [X]
  - Add hook for [event]
```

## Invocation
User says: "gaps", "/gaps", "find gaps", "analyze gaps"
