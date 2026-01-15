# Command: /meta

Cycle 3 - Meta self-improvement. Analyze the 18-rule engine itself.

## When to Run
- Every 5 tasks
- When explicitly requested
- When improvement rate slows

## Process

### Step 1: Coverage Analysis
```bash
MEMORY="/etc/nixos/.claude/memory"

TOTAL=$(wc -l < "$MEMORY/interactions.jsonl" 2>/dev/null || echo 0)
AUTO=$(grep -c '"manual":false' "$MEMORY/interactions.jsonl" 2>/dev/null || echo 0)
[ "$TOTAL" -gt 0 ] && echo "Automation coverage: $((AUTO * 100 / TOTAL))%"
```

Target: >80% automation rate

### Step 2: Rule Effectiveness
```bash
echo "Most triggered rules:"
grep -oh '"[A-Z][0-9]*"' "$MEMORY/improvements.jsonl" 2>/dev/null | \
  sort | uniq -c | sort -rn | head -5

echo "Rules never triggered:"
# Compare against full list S1-S5, A1-A5, H1-H4, R1-R5, K1-K3
```

Questions:
- Which rules fire most? (valuable, maybe split)
- Which rules never fire? (dead or detection issue)
- Which rules fire but don't help? (improve action)

### Step 3: Gap Detection
```bash
# Tasks without skill triggers
grep '"skills":\[\]' "$MEMORY/interactions.jsonl" | wc -l

# Manual interventions (should be automated)
grep '"manual":true' "$MEMORY/interactions.jsonl" | \
  grep -oh '"task":"[^"]*"' | sort | uniq -c | sort -rn | head -5

# Repeated manual tasks
grep '"manual":true' "$MEMORY/interactions.jsonl" | \
  grep -oh '"task":"[^"]*"' | sort | uniq -c | awk '$1 >= 2'
```

### Step 4: Generate Proposals
For each gap, create proposal:
```json
{
  "id": "prop_[timestamp]",
  "ts": "[ISO8601]",
  "type": "skill|agent|hook|rule",
  "gap": "[description]",
  "proposal": "[solution]",
  "priority": "high|medium|low",
  "status": "proposed"
}
```
Append to `.claude/memory/proposals.jsonl`

### Step 5: Implement High-Priority
For proposals with priority=high:
1. Implement the change
2. Update proposal status to "completed"
3. Log to evolution.jsonl

### Step 6: Log Meta-Cycle
```json
{
  "ts": "[ISO8601]",
  "event": "meta_cycle",
  "coverage": "[percent]",
  "rules_analyzed": 18,
  "gaps_found": [count],
  "proposals_generated": [count],
  "proposals_implemented": [count]
}
```
Append to `.claude/memory/evolution.jsonl`

## Output
```
META SELF-IMPROVEMENT REPORT
============================
Coverage: [X]% automated (target: 80%)

Rule Effectiveness:
  Most valuable: [rules]
  Never triggered: [rules]
  Needs improvement: [rules]

Gaps Identified: [N]
  - [gap 1]
  - [gap 2]

Proposals:
  Generated: [N]
  Implemented: [N]

Recommendations:
  - [recommendation 1]
  - [recommendation 2]
```

## Invocation
User says: "meta", "/meta", "analyze improvement system"
